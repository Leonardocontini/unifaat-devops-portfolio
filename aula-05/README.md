# Trabalho de Fixação — Aula 05
## RDS PostgreSQL + Remote State com S3 e DynamoDB

Projeto desenvolvido em Terraform para provisionamento de uma infraestrutura AWS com banco de dados PostgreSQL utilizando Amazon RDS, uma instância EC2 para acesso à aplicação/banco e armazenamento remoto do estado do Terraform em Amazon S3 com controle de lock através do DynamoDB.

---

## Arquitetura

```mermaid
flowchart TB

    Internet((Internet))

    subgraph AWS["AWS — us-east-1"]

        subgraph VPC["VPC — 10.0.0.0/16"]

            IGW["Internet Gateway"]

            subgraph AZ1["Availability Zone 1"]

                PUB1["Public Subnet\n10.0.1.0/24"]

                EC2["EC2\nAmazon Linux 2023"]

                PRIV1["Private Subnet\n10.0.2.0/24"]
            end

            subgraph AZ2["Availability Zone 2"]

                PRIV2["Private Subnet\n10.0.4.0/24"]
            end

            RDS["Amazon RDS\nPostgreSQL 15\nPrivate"]

            SGEC2["Security Group\nEC2"]
            SGRDS["Security Group\nRDS"]
        end

        subgraph TerraformState["Terraform Remote State"]

            S3["Amazon S3\nTerraform State\nEncryption + Versioning\nBlock Public Access"]

            DDB["Amazon DynamoDB\nState Lock"]
        end
    end

    Internet --> IGW
    IGW --> PUB1
    PUB1 --> EC2

    EC2 --> SGEC2
    SGEC2 --> SGRDS
    SGRDS --> RDS

    RDS --- PRIV1
    RDS --- PRIV2

    TerraformState -. "terraform.tfstate" .-> S3
    TerraformState -. "State Lock" .-> DDB