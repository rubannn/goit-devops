#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/os-release ]]; then
    echo "Цей скрипт призначений для Ubuntu та Debian." >&2
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
    echo "Потрібна Ubuntu або Debian." >&2
    exit 1
fi

# Пакети встановлюємо з правами root, а середовище Python — від користувача.
as_root() {
    if [[ "$EUID" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

as_root apt-get update

# Репозиторій Docker потрібен лише тоді, коли бракує Docker або Compose.
if ! command -v docker >/dev/null 2>&1 \
    || { ! docker compose version >/dev/null 2>&1 \
         && ! command -v docker-compose >/dev/null 2>&1; }; then
    echo "Додаємо репозиторій Docker..."
    as_root apt-get install -y ca-certificates curl
    as_root install -m 0755 -d /etc/apt/keyrings
    as_root curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
        -o /etc/apt/keyrings/docker.asc
    as_root chmod a+r /etc/apt/keyrings/docker.asc

    as_root tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$ID
Suites: ${VERSION_CODENAME:?Не вдалося визначити версію ОС}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    as_root apt-get update
fi

if command -v docker >/dev/null 2>&1; then
    echo "Docker уже встановлено."
else
    echo "Встановлюємо Docker..."
    as_root apt-get install -y docker-ce docker-ce-cli containerd.io
    if [[ -d /run/systemd/system ]]; then
        as_root systemctl enable --now docker
    elif command -v service >/dev/null 2>&1; then
        as_root service docker start
    else
        echo "Запустіть службу Docker вручну."
    fi
fi

if docker compose version >/dev/null 2>&1 \
    || command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose уже встановлено."
else
    echo "Встановлюємо Docker Compose..."
    as_root apt-get install -y docker-compose-plugin
fi

if command -v python3 >/dev/null 2>&1 \
    && python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'; then
    echo "Python 3.9 або новіший уже встановлено."
else
    echo "Встановлюємо Python..."
    as_root apt-get install -y python3
    if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'; then
        echo "У репозиторії цієї ОС Python старіший за 3.9. Потрібно оновити ОС." >&2
        exit 1
    fi
fi

# Django ставимо у venv, щоб не змінювати системні пакети Python.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
venv_dir="${DEV_TOOLS_VENV:-$script_dir/.venv}"

if python3 -m django --version >/dev/null 2>&1; then
    echo "Django уже доступний у Python."
elif [[ -x "$venv_dir/bin/python" ]] \
    && "$venv_dir/bin/python" -m django --version >/dev/null 2>&1; then
    echo "Django уже встановлено у $venv_dir."
else
    if [[ ! -x "$venv_dir/bin/python" ]]; then
        python_version="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
        if ! dpkg-query -W -f='${Status}' "python$python_version-venv" 2>/dev/null \
            | grep -qx 'install ok installed'; then
            as_root apt-get install -y "python$python_version-venv"
        fi
        python3 -m venv "$venv_dir"
    fi
    if ! "$venv_dir/bin/python" -m pip --version >/dev/null 2>&1; then
        "$venv_dir/bin/python" -m ensurepip --upgrade
    fi
    echo "Встановлюємо Django..."
    "$venv_dir/bin/python" -m pip install Django
fi

echo "Готово!"
if [[ -x "$venv_dir/bin/python" ]]; then
    printf 'Для роботи з Python активуйте середовище: source %q\n' "$venv_dir/bin/activate"
fi
