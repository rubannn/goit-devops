# Запуск Django + PostgreSQL + Nginx

Потрібні Docker Engine та Docker Compose. На Windows запустіть Docker Desktop
з Linux-контейнерами.

1. Скопіюйте `.env.example` у `.env` (`cp .env.example .env` у Bash
   або `Copy-Item .env.example .env` у PowerShell).
2. За потреби змініть налаштування в `.env`. Для публічного розгортання
   замініть приклади ключа Django та пароля PostgreSQL власними значеннями.
3. Запустіть сервіси:

```bash
docker compose up -d --build --wait
```

Compose автоматично читає `.env`. Спочатку запускається PostgreSQL,
потім виконуються міграції Django та запускається Gunicorn. Nginx чекає
готовності застосунку й передає йому запити через мережевий псевдонім `django`.

Відкрийте http://localhost. Очікувана відповідь:

```json
{"status": "ok", "app": "Django", "database": "PostgreSQL"}
```

Сторінка виконує SQL-запит до PostgreSQL; якщо база недоступна, повертає HTTP 503.
Якщо порт 80 зайнятий, задайте `HTTP_PORT=8080` у `.env` і відкрийте
http://localhost:8080. Для старої окремої версії Compose команда має назву
`docker-compose`; якщо вона не підтримує `--wait`, приберіть цей параметр.

Перевірка стану та журналів:

```bash
docker compose ps
docker compose logs web db nginx
docker compose exec web python manage.py check
docker compose exec db psql -U devops -d devops -c "SELECT 1;"
```

В останній команді замініть `devops`, якщо змінювали користувача або назву бази.
Дані зберігаються в томі `postgres_data` після зупинки й повторного запуску.
Зміна пароля в `.env` не змінює пароль уже створеної бази.

За наявності GNU Make можна користуватися короткими командами:

```bash
make run     # Зібрати та запустити сервіси.
make stop    # Зупинити контейнери.
make status  # Показати всі контейнери проєкту, включно із зупиненими.
make clean   # Видалити контейнери, мережу та образи сервісів Compose.
```

`make clean` видаляє образ Django та образи PostgreSQL і Nginx, вказані
в Compose. Том із даними PostgreSQL зберігається. Образи, які використовують
інші контейнери, Docker не дозволить видалити; кеш збірки не очищується.

Зупинка зі збереженням даних:

```bash
docker compose down
```

Це навчальний локальний запуск: лише Nginx доступний з комп'ютера,
PostgreSQL і Gunicorn доступні всередині мережі Compose.

Документація: [Gunicorn у Django](https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/gunicorn/),
[порядок запуску Compose](https://docs.docker.com/compose/how-tos/startup-order/),
[образ PostgreSQL](https://hub.docker.com/_/postgres).
