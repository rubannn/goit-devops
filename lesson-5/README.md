# Урок 5: Terraform та AWS

Проєкт створює мережу VPC і репозиторій ECR, використовуючи S3 для зберігання стану Terraform і DynamoDB для блокування. Потрібні Terraform >= 1.5, облікові дані AWS із необхідними правами та глобально унікальне ім’я S3-бакета. Типовий регіон — `us-west-2`.

## Структура

- `bootstrap/` — окремий проєкт із локальним станом для створення backend.
- `modules/s3-backend/` — S3 з версіюванням, шифруванням і заблокованим публічним доступом; DynamoDB із ключем `LockID`.
- `modules/vpc/` — VPC, три публічні та три приватні підмережі в різних зонах, Internet Gateway, один NAT Gateway і таблиці маршрутів.
- `modules/ecr/` — репозиторій зі скануванням під час завантаження та політикою доступу для поточного облікового запису. Користувачам також потрібні відповідні дозволи IAM; для авторизації Docker потрібен `ecr:GetAuthorizationToken`.
- `main.tf`, `backend.tf`, `variables.tf`, `outputs.tf` — конфігурація основної інфраструктури.

Один NAT Gateway обслуговує всі приватні підмережі; у разі відмови його зони вихідний доступ із них зникне. NAT Gateway та інші ресурси можуть тарифікуватися.

## Навіщо потрібен bootstrap

S3-бакет і таблиця DynamoDB мають існувати до запуску `terraform init` із віддаленим backend. Тому `bootstrap/` окремо створює їх через модуль `s3-backend`, зберігаючи власний стан локально. Основний проєкт потім використовує створені ресурси. Це додатковий каталог для початкового налаштування, який усуває циклічну залежність.

## Створення backend

Із каталогу `lesson-5` (приклади для PowerShell):

```powershell
cd bootstrap
terraform init
terraform plan -var="bucket_name=YOUR-UNIQUE-BUCKET"
terraform apply -var="bucket_name=YOUR-UNIQUE-BUCKET"
cd ..
```

Збережіть `bootstrap/terraform.tfstate` у захищеному місці: він містить стан ресурсів backend. Не додавайте його до Git. Для іншого регіону вказуйте однаковий `aws_region` в усіх командах bootstrap, а також відповідні регіон і зони доступності в основній конфігурації.

## Запуск інфраструктури

Скопіюйте `backend.hcl.example` у `backend.hcl` і замініть ім’я бакета; регіон та ім’я таблиці мають збігатися з bootstrap. Файл backend не використовує змінні Terraform. Далі:

```powershell
Copy-Item backend.hcl.example backend.hcl
# Відредагуйте backend.hcl
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
terraform output
```

Змінюючи регіон, задайте також `aws_region` і три різні `availability_zones`, наприклад через `terraform.tfvars`. Параметр `dynamodb_table` використано за умовою завдання; блокування DynamoDB у сучасних версіях Terraform оголошено застарілим.

## Видалення

Спочатку видаліть основну інфраструктуру командою `terraform destroy` із `lesson-5`, поки backend існує. ECR не видалиться, доки в ньому є образи: видаліть їх заздалегідь. Потім із `bootstrap` виконайте `terraform destroy -var="bucket_name=YOUR-UNIQUE-BUCKET"` із тими самими параметрами, що й під час створення. Бакет S3 з увімкненим версіюванням не видалиться, доки в ньому є версії стану та маркери видалення: збережіть потрібні дані й видаліть усі версії та маркери вручну перед видаленням backend. Видалення backend знищить віддалений стан; локальний стан bootstrap потрібно зберігати до завершення очищення.
