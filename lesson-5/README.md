# Lesson 5: Terraform и AWS

Проект создаёт сеть VPC и репозиторий ECR, используя S3 для хранения состояния Terraform и DynamoDB для блокировки. Нужны Terraform >= 1.5, AWS credentials с необходимыми правами и уникальное во всём AWS имя S3-бакета. Регион по умолчанию — `us-west-2`.

## Структура

- `bootstrap/` — отдельный проект с локальным состоянием для создания backend.
- `modules/s3-backend/` — S3 с версионированием, шифрованием и закрытым публичным доступом; DynamoDB с ключом `LockID`.
- `modules/vpc/` — VPC, три публичные и три приватные подсети в разных зонах, Internet Gateway, один NAT Gateway и таблицы маршрутов.
- `modules/ecr/` — репозиторий со сканированием при загрузке и политикой доступа для текущего аккаунта. Пользователям также необходимы соответствующие IAM-разрешения; для авторизации Docker требуется `ecr:GetAuthorizationToken`.
- `main.tf`, `backend.tf`, `variables.tf`, `outputs.tf` — конфигурация основной инфраструктуры.

Один NAT Gateway обслуживает все приватные подсети; при отказе его зоны исходящий доступ из них пропадёт. NAT Gateway и другие ресурсы могут тарифицироваться.

## Создание backend

Из каталога `lesson-5` (примеры для PowerShell):

```powershell
cd bootstrap
terraform init
terraform plan -var="bucket_name=YOUR-UNIQUE-BUCKET"
terraform apply -var="bucket_name=YOUR-UNIQUE-BUCKET"
cd ..
```

Сохраните `bootstrap/terraform.tfstate` в защищённом месте: в нём состояние ресурсов backend. Не добавляйте его в Git. При другом регионе укажите одинаковый `aws_region` при всех командах bootstrap, а также соответствующий регион и зоны доступности в основной конфигурации.

## Запуск инфраструктуры

Скопируйте `backend.hcl.example` в `backend.hcl` и замените имя бакета; регион и имя таблицы должны совпадать с bootstrap. Backend-файл не использует Terraform-переменные. Затем:

```powershell
Copy-Item backend.hcl.example backend.hcl
# Отредактируйте backend.hcl
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
terraform output
```

При изменении региона задайте также `aws_region` и три разные `availability_zones`, например через `terraform.tfvars`. Параметр `dynamodb_table` используется по условию задания; блокировка DynamoDB в современных версиях Terraform объявлена устаревшей.

## Удаление

Сначала удалите основную инфраструктуру командой `terraform destroy` из `lesson-5`, пока backend существует. ECR не удалится, пока в нём есть образы: удалите их заранее. Затем из `bootstrap` выполните `terraform destroy -var="bucket_name=YOUR-UNIQUE-BUCKET"` с теми же параметрами, что при создании. Версионированный S3-бакет не удалится, пока в нём есть версии состояния и маркеры удаления: сохраните нужные данные и удалите все версии и маркеры вручную перед удалением backend. Удаление backend уничтожит удалённое состояние; локальное состояние bootstrap необходимо сохранить до завершения очистки.
