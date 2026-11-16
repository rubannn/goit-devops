# Встановлення інструментів DevOps

`install_dev_tools.sh` встановлює Docker Engine, Docker Compose, Python 3.9+
і Django на Ubuntu / Debian. Потрібні доступ до інтернету та права sudo
(або запуск від root). Використовуйте підтримуваний випуск ОС із Python 3.9+
у стандартному репозиторії та підтримкою офіційного репозиторію Docker.

```bash
chmod u+x install_dev_tools.sh
./install_dev_tools.sh
```

Запускайте від звичайного користувача: скрипт сам викликає sudo для системних
операцій. Уже встановлені інструменти пропускаються. Docker встановлюється
з офіційного apt-репозиторію; Compose доступний командою `docker compose`.
Наявний `docker-compose` також враховується. Скрипт не видаляє конфліктні
пакети автоматично: якщо apt повідомляє про конфлікт, його потрібно вирішити
перед повторним запуском.

Django встановлюється через pip у `.venv` поруч зі скриптом, якщо він ще
не доступний у Python або цьому середовищі. Віртуальне середовище не потрапляє
в Git. Для роботи з ним:

```bash
source .venv/bin/activate
python -m django --version
```

Інший шлях можна задати змінною `DEV_TOOLS_VENV`. Не запускайте скрипт через
sudo, якщо хочете створити середовище від свого користувача. Для Docker за
потреби використовуйте `sudo docker`; скрипт не змінює групи користувача.

Приклад налаштувань з описом змінних міститься у `.env.example`.
Скрипт не читає `.env` автоматично. Щоб передати налаштування, виконайте в Bash:

```bash
cp .env.example .env
# За потреби змініть DEV_TOOLS_VENV у .env.
set -a
source .env
set +a
./install_dev_tools.sh
```

Порожнє значення `DEV_TOOLS_VENV` залишає стандартний шлях `.venv` поруч
зі скриптом. Сам файл `.env` ігнорується Git.

Під час підготовки цього завдання скрипт не запускався, перевірки Bash
та ShellCheck не виконувалися згідно з побажанням користувача.

Джерела: [Docker для Ubuntu](https://docs.docker.com/engine/install/ubuntu/),
[Docker для Debian](https://docs.docker.com/engine/install/debian/),
[Python venv](https://docs.python.org/3/library/venv.html).
