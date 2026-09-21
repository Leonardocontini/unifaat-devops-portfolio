# Aula 06 — Terraform Modules

Projeto da Aula 06 da disciplina de DevOps, utilizando **Terraform Modules** para organizar e reutilizar a infraestrutura da aplicação TechNova.

## Objetivo

O objetivo deste projeto é criar uma infraestrutura modular utilizando Terraform, separando os principais recursos em módulos reutilizáveis:

* VPC
* Security Groups
* EC2
* RDS PostgreSQL

O projeto possui dois ambientes independentes:

* `dev`
* `staging`

A infraestrutura é composta a partir dos módulos, permitindo reutilização e padronização entre os ambientes.

---

## Arquitetura

```text
                         AWS
                          │
              ┌───────────┴───────────┐
              │        VPC             │
              │                        │
              │   ┌──────────────┐     │
              │   │ Public Subnet│     │
              │   │              │     │
              │   │ EC2 API      │     │
              │   │ Lab Role     │     │
              │   └──────┬───────┘     │
              │          │              │
              │      Security Group     │
              │          │              │
              │   ┌──────▼───────┐      │
              │   │Private Subnet│      │
              │   │              │      │
              │   │ RDS PostgreSQL│     │
              │   └──────────────┘      │
              │                         │
              └─────────────────────────┘

                    Terraform
                        │
          ┌─────────────┼─────────────┐
          │             │             │
        VPC            SG            EC2
          │             │             │
          └─────────────┼─────────────┘
                        │
                       RDS
```

---

## Estrutura do projeto

```text
aula-06/
├── README.md
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── terraform.tfvars
│   │
│   └── staging/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── terraform.tfvars
│
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security-group/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── ec2/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── rds/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Módulos

| Módulo           | Responsabilidade                                                    |
| ---------------- | ------------------------------------------------------------------- |
| `vpc`            | Criação da VPC, subnets, Internet Gateway e tabela de rotas pública |
| `security-group` | Criação de Security Groups e regras de entrada                      |
| `ec2`            | Criação das instâncias EC2                                          |
| `rds`            | Criação do PostgreSQL RDS e DB Subnet Group                         |

### VPC

O módulo VPC recebe um mapa de subnets e utiliza `for_each` para criá-las.

São utilizadas subnets:

* Públicas
* Privadas
* Distribuídas em duas Availability Zones

Outputs principais:

```text
vpc_id
public_subnet_ids
private_subnet_ids
```

### Security Group

O módulo permite definir as regras de entrada através de uma lista de objetos.

Exemplo:

```hcl
ingress_rules = [
  {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
```

O tráfego de saída é permitido por padrão.

Output:

```text
sg_id
```

### EC2

O módulo EC2 permite configurar:

* AMI
* Tipo da instância
* Subnet
* Security Groups
* Key Pair
* User Data
* IAM Instance Profile

As instâncias utilizadas no projeto são `t2.micro`.

No ambiente AWS Academy, a EC2 utiliza o:

```text
LabInstanceProfile
```

Outputs:

```text
instance_id
public_ip
private_ip
```

### RDS

O módulo RDS cria um PostgreSQL utilizando as subnets privadas.

Configuração utilizada:

```text
Engine: PostgreSQL
Instance Class: db.t3.micro
Port: 5432
Publicly Accessible: false
```

Outputs:

```text
endpoint
db_name
db_port
```

A senha do banco é definida como variável sensível.

---

## Ambientes

### Development

Configuração:

```text
VPC: 10.0.0.0/16

Public:
10.0.1.0/24
10.0.2.0/24

Private:
10.0.3.0/24
10.0.4.0/24
```

Recursos principais:

```text
EC2: t2.micro
RDS: db.t3.micro
Database: technova_dev
```

Nomenclatura:

```text
technova-dev-*
```

### Staging

Configuração:

```text
VPC: 10.1.0.0/16

Public:
10.1.1.0/24
10.1.2.0/24

Private:
10.1.3.0/24
10.1.4.0/24
```

Recursos principais:

```text
EC2: t2.micro
RDS: db.t3.micro
Database: technova_staging
```

Nomenclatura:

```text
technova-staging-*
```

---

## Tags

Os recursos criados pelo Terraform utilizam as seguintes tags:

```text
Name
Environment
Project
ManagedBy
```

Exemplo:

```hcl
tags = {
  Name        = "technova-dev-api"
  Project     = "technova"
  Environment = "dev"
  ManagedBy   = "Terraform"
}
```

---

## Pré-requisitos

Para executar o projeto é necessário ter:

* Terraform >= 1.5
* AWS CLI
* Conta/acesso AWS Academy Learner Lab
* Credenciais temporárias da AWS
* Key Pair disponível na região utilizada
* AMI válida na região `us-east-1`

Verificar Terraform:

```bash
terraform version
```

Verificar AWS CLI:

```bash
aws --version
```

Verificar credenciais:

```bash
aws sts get-caller-identity
```

---

## Configuração das variáveis

Antes de executar o projeto, configure o arquivo:

```text
environments/dev/terraform.tfvars
```

e o arquivo:

```text
environments/staging/terraform.tfvars
```

Exemplo:

```hcl
aws_region   = "us-east-1"
vpc_cidr     = "10.0.0.0/16"
project_name = "technova"
environment  = "dev"

ami_id  = "AMI_ID"
key_name = "technova-key"

db_username = "technova_admin"
db_password = "SUA_SENHA"
```

Para o ambiente `staging`, utilize o CIDR e os valores correspondentes ao ambiente.

> Os arquivos `terraform.tfvars` não devem ser versionados quando contiverem senhas ou outras informações sensíveis.

---

## Inicialização

Cada ambiente possui sua própria configuração Terraform.

### Dev

```bash
cd environments/dev
terraform init
```

### Staging

```bash
cd environments/staging
terraform init
```

---

## Validação

Antes de criar qualquer recurso:

```bash
terraform validate
```

O resultado esperado é:

```text
Success! The configuration is valid.
```

Também é possível formatar todos os arquivos Terraform:

```bash
terraform fmt -recursive
```

---

## Planejamento

Para visualizar os recursos que serão criados:

### Dev

```bash
cd environments/dev
terraform plan
```

### Staging

```bash
cd environments/staging
terraform plan
```

O `terraform plan` permite verificar as alterações antes da aplicação da infraestrutura.

---

## Aplicação na AWS

Depois de validar o plano:

```bash
terraform apply
```

Confirme a execução digitando:

```text
yes
```

Após a aplicação, os outputs podem ser consultados com:

```bash
terraform output
```

---

## Destruição da infraestrutura

Caso os recursos tenham sido criados apenas para testes no AWS Academy:

```bash
terraform destroy
```

Confirme com:

```text
yes
```

A destruição deve ser realizada após os testes para evitar consumo desnecessário dos recursos do laboratório.

---

## Validação da infraestrutura

Após o `apply`, podem ser utilizados os outputs para verificar os recursos criados.

Exemplo:

```bash
terraform output vpc_id
```

Verificar a instância:

```bash
terraform output instance_id
```

Verificar o IP público:

```bash
terraform output public_ip
```

Verificar o endpoint do RDS:

```bash
terraform output db_endpoint
```

---

## Evidências

As evidências da atividade incluem:

* Estrutura dos módulos Terraform
* Estrutura dos ambientes `dev` e `staging`
* Execução do `terraform validate`
* Execução do `terraform plan`
* Uso de `for_each` no módulo VPC
* Composição entre os módulos
* Configuração do `LabInstanceProfile` na EC2
* Execução da infraestrutura na AWS Academy, quando aplicável

---

## Conceitos utilizados

Neste projeto foram utilizados:

* Terraform Modules
* Infrastructure as Code (IaC)
* `for_each`
* Variáveis Terraform
* Outputs
* AWS VPC
* AWS Subnets
* Internet Gateway
* Route Tables
* Security Groups
* Amazon EC2
* IAM Instance Profile
* AWS RDS
* PostgreSQL
* Ambientes `dev` e `staging`
* Reutilização de infraestrutura
* Separação de ambientes
