# Урок 7: Kubernetes (EKS), ECR і Helm

Проєкт розгортає кластер EKS у власній мережі VPC, репозиторій ECR для Docker-образу
Django-застосунку (з теми 4) та Helm-чарт, що розгортає цей застосунок у кластері з
автомасштабуванням подів. Потрібні Terraform >= 1.5, AWS CLI, kubectl, Helm 3 та
облікові дані AWS із необхідними правами. Типовий регіон — `us-east-1`.

## Структура

- `bootstrap/` — окремий проєкт із локальним станом для створення S3/DynamoDB backend.
- `modules/s3-backend/` — S3 з версіюванням, шифруванням і заблокованим публічним доступом; DynamoDB із ключем `LockID`.
- `modules/vpc/` — VPC, три публічні та три приватні підмережі в різних зонах, Internet Gateway, один NAT Gateway, таблиці маршрутів і теги для EKS/ELB (`kubernetes.io/cluster/...`, `kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`).
- `modules/ecr/` — репозиторій зі скануванням під час завантаження та політикою доступу для поточного облікового запису.
- `modules/eks/` — кластер EKS (control plane у публічних і приватних підмережах) та managed node group у приватних підмережах з IAM-ролями для кластера й нод (`AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`).
- `charts/django-app/` — Helm-чарт застосунку: `Deployment`, `Service` (LoadBalancer), `HorizontalPodAutoscaler`, `ConfigMap`.
- `main.tf`, `backend.tf`, `variables.tf`, `outputs.tf` — конфігурація основної інфраструктури.

Один NAT Gateway обслуговує всі приватні підмережі; у разі відмови його зони вихідний
доступ із них зникне. EKS, NAT Gateway та інші ресурси тарифікуються постійно, доки існують.

## Навіщо потрібен bootstrap

S3-бакет і таблиця DynamoDB мають існувати до запуску `terraform init` із віддаленим
backend. Тому `bootstrap/` окремо створює їх через модуль `s3-backend`, зберігаючи
власний стан локально. Основний проєкт потім використовує створені ресурси — це
усуває циклічну залежність «стейт для стейту».

## Створення backend

Значення бакета, регіону й таблиці задані в `bootstrap/variables.tf`. Ім'я бакета має
бути глобально унікальним. Із каталогу `lesson-7`:

```powershell
cd bootstrap
terraform init
terraform plan
terraform apply
cd ..
```

Збережіть `bootstrap/terraform.tfstate` у захищеному місці — він містить стан ресурсів
backend. Не додавайте його до Git. Якщо змінюєте параметри backend, оновіть відповідні
значення в `backend.tf`: блок backend не підтримує змінні Terraform.

## Розгортання інфраструктури

Після успішного `terraform apply` у bootstrap виконайте з каталогу `lesson-7`:

```powershell
terraform init
terraform plan
terraform apply
terraform output
```

Це створить VPC, ECR-репозиторій і кластер EKS. Після застосування налаштуйте доступ
`kubectl`:

```powershell
aws eks update-kubeconfig --region us-east-1 --name devops-rnn-eks-lesson7
kubectl get nodes
```

## Збірка та завантаження Docker-образу Django в ECR

Образ Django-застосунку з теми 4 завантажується в репозиторій, створений модулем `ecr`
(`terraform output ecr_repository_url`):

```powershell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr_repository_url>
docker build -t <ecr_repository_url>:latest <шлях до проєкту lesson-4>
docker push <ecr_repository_url>:latest
```

## Розгортання Helm-чарта

Змінні середовища застосунку (з `.env.example` теми 4: `DJANGO_SECRET_KEY`,
`DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`, `POSTGRES_DB`, `POSTGRES_USER`,
`POSTGRES_PASSWORD`) перенесені у `charts/django-app/values.yaml` → `configMap` і
підключаються до контейнера через `envFrom.configMapRef` у `templates/deployment.yaml`.
У продакшн-середовищі значення `DJANGO_SECRET_KEY` і `POSTGRES_PASSWORD` варто тримати
в Kubernetes `Secret`, а не в `ConfigMap`.

Перед встановленням чарта вкажіть реальний образ і за потреби інші параметри (можна
через `--set` або власний `my-values.yaml`):

```powershell
helm upgrade --install django-app ./charts/django-app `
  --set image.repository=<ecr_repository_url> `
  --set image.tag=latest
```

Компоненти чарта:

- **Deployment** (`templates/deployment.yaml`) — подні з образом Django з ECR, env-змінні підключені через `envFrom.configMapRef`.
- **Service** (`templates/service.yaml`) — тип `LoadBalancer`, зовнішній доступ через публічну IP/DNS AWS ELB.
- **HPA** (`templates/hpa.yaml`) — масштабує Deployment від `autoscaling.minReplicas` (2) до `autoscaling.maxReplicas` (6) при середньому завантаженні CPU понад `autoscaling.targetCPUUtilizationPercentage` (70%).
- **ConfigMap** (`templates/configmap.yaml`) — змінні середовища застосунку.
- **values.yaml** — параметри образу, сервісу, ConfigMap, ресурсів та autoscaler.

Перевірка результату:

```powershell
kubectl get deployments,svc,hpa,configmap
kubectl get svc django-app-django-app -o wide
```

## Видалення

Спочатку видаліть застосунок і дочекайтесь видалення ELB, щоб не залишити висячі ресурси:

```powershell
helm uninstall django-app
```

Потім видаліть основну інфраструктуру (EKS, VPC, ECR) з `lesson-7`, поки backend існує:

```powershell
terraform destroy
```

ECR не видалиться, доки в ньому є образи — видаліть їх заздалегідь. Потім із `bootstrap`
виконайте `terraform destroy` з тими самими значеннями змінних, що й під час створення.
Бакет S3 з увімкненим версіюванням не видалиться, доки в ньому є версії стану та маркери
видалення — видаліть їх вручну перед видаленням backend.
