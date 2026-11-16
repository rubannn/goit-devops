#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "Installation failed at line %s.\n" "$LINENO" >&2' ERR

log() {
    printf '\n%s\n' "$*"
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

[[ -r /etc/os-release ]] || die 'This script requires Ubuntu or Debian.'
# shellcheck source=/dev/null
source /etc/os-release
case "$ID" in
    ubuntu|debian) ;;
    *) die 'Only Ubuntu and Debian are supported.' ;;
esac
[[ -n "${VERSION_CODENAME:-}" ]] || die 'Cannot determine the OS release codename.'

# Run as the regular user; elevate only system package operations.
SUDO=()
if (( EUID != 0 )); then
    command -v sudo >/dev/null 2>&1 || die 'Install sudo or run as root.'
    SUDO=(sudo)
    sudo -v
fi

APT_UPDATED=false
apt_install() {
    if [[ "$APT_UPDATED" == false ]]; then
        "${SUDO[@]}" apt-get update
        APT_UPDATED=true
    fi
    "${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

DOCKER_REPO_READY=false
prepare_docker_repository() {
    [[ "$DOCKER_REPO_READY" == false ]] || return 0
    apt_install ca-certificates curl
    "${SUDO[@]}" install -m 0755 -d /etc/apt/keyrings
    "${SUDO[@]}" curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
        -o /etc/apt/keyrings/docker.asc
    "${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.asc
    printf '%s\n' \
        'Types: deb' \
        "URIs: https://download.docker.com/linux/$ID" \
        "Suites: $VERSION_CODENAME" \
        'Components: stable' \
        "Architectures: $(dpkg --print-architecture)" \
        'Signed-By: /etc/apt/keyrings/docker.asc' \
        | "${SUDO[@]}" tee /etc/apt/sources.list.d/docker.sources >/dev/null
    APT_UPDATED=false
    DOCKER_REPO_READY=true
}

if command -v docker >/dev/null 2>&1; then
    log 'Docker is already installed; skipping.'
else
    log 'Installing Docker Engine...'
    prepare_docker_repository
    apt_install docker-ce docker-ce-cli containerd.io
    if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
        "${SUDO[@]}" systemctl enable --now docker
    elif command -v service >/dev/null 2>&1; then
        "${SUDO[@]}" service docker start
    else
        log 'Start the Docker daemon manually using your init system.'
    fi
fi

if docker compose version >/dev/null 2>&1; then
    log 'Docker Compose plugin is already installed; skipping.'
elif command -v docker-compose >/dev/null 2>&1; then
    log 'Standalone Docker Compose is already installed; skipping.'
else
    log 'Installing Docker Compose plugin...'
    prepare_docker_repository
    apt_install docker-compose-plugin
fi

if command -v python3 >/dev/null 2>&1 \
    && python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'; then
    log 'Python 3.9 or newer is already installed; skipping.'
else
    log 'Installing Python 3...'
    apt_install python3
    python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' \
        || die 'The OS repository provides Python older than 3.9. Upgrade Ubuntu/Debian.'
fi

# Avoid changing the distribution-managed Python environment (PEP 668).
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${DEV_TOOLS_VENV:-$SCRIPT_DIR/.venv}"
if python3 -m django --version >/dev/null 2>&1; then
    log 'Django is already available in Python 3; skipping.'
elif [[ -x "$VENV_DIR/bin/python" ]] \
    && "$VENV_DIR/bin/python" -m django --version >/dev/null 2>&1; then
    log "Django is already installed in $VENV_DIR; skipping."
else
    if [[ ! -x "$VENV_DIR/bin/python" ]]; then
        log "Creating Python virtual environment at $VENV_DIR..."
        # A matching venv package is required for Debian/Ubuntu's default Python.
        PYTHON_MINOR="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
        if ! dpkg-query -W -f='${Status}' "python${PYTHON_MINOR}-venv" 2>/dev/null \
            | grep -qx 'install ok installed'; then
            apt_install "python${PYTHON_MINOR}-venv"
        fi
        python3 -m venv "$VENV_DIR"
    fi
    if ! "$VENV_DIR/bin/python" -m pip --version >/dev/null 2>&1; then
        "$VENV_DIR/bin/python" -m ensurepip --upgrade
    fi
    log 'Installing Django through pip...'
    "$VENV_DIR/bin/python" -m pip install Django
fi

log 'Development tools are installed.'
if [[ -x "$VENV_DIR/bin/python" ]]; then
    printf 'To activate the Python environment: source %q\n' "$VENV_DIR/bin/activate"
fi
