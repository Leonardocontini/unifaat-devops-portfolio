# TechNova

Infraestrutura da API TechNova provisionada na AWS com Terraform.

## Diagrama da arquitetura

```mermaid
flowchart TB
    client[Cliente / Internet]

    subgraph aws[AWS - us-east-1]
        subgraph vpc[VPC technova-vpc - 10.0.0.0/16]
            igw[Internet Gateway]
            routes[Route Table pública<br/>0.0.0.0/0]

            subgraph az1[Availability Zone 1]
                pub1[Subnet pública 1<br/>10.0.1.0/24]
                priv1[Subnet privada 1<br/>10.0.2.0/24]
            end

            subgraph az2[Availability Zone 2]
                pub2[Subnet pública 2<br/>10.0.3.0/24]
                priv2[Subnet privada 2<br/>10.0.4.0/24]
            end

            subgraph ec2zone[Camada de aplicação]
                ec2[EC2 t2.micro<br/>Amazon Linux 2023<br/>IP público]
                api[API Node.js / Express<br/>porta 3000]
            end

            subgraph security[Controles de acesso]
                apiSg[Security Group da API<br/>SSH 22 e API 3000<br/>entrada: 0.0.0.0/0]
                dbSg[Security Group do banco<br/>PostgreSQL 5432<br/>origem: 10.0.0.0/16]
            end
        end
    end

    client -->|HTTP :3000| igw
    igw --> routes
    routes --> pub1
    routes --> pub2
    pub1 --> ec2
    ec2 --> api
    apiSg -. protege .-> ec2
    dbSg -. reservado para acesso interno .-> priv1
    dbSg -. reservado para acesso interno .-> priv2

    classDef network fill:#e8f1fb,stroke:#2463a6,color:#102a43
    classDef compute fill:#e8f7ef,stroke:#238b5b,color:#123524
    classDef security fill:#fff4df,stroke:#b7791f,color:#4a2c0a
    class vpc,igw,routes,pub1,pub2,priv1,priv2 network
    class ec2,api compute
    class apiSg,dbSg security
```

## Componentes

| Camada | Recursos | Função |
| --- | --- | --- |
| Rede | VPC `10.0.0.0/16` | Rede isolada do projeto |
| Alta disponibilidade | 2 Availability Zones | Distribuição das sub-redes em duas zonas |
| Entrada pública | Internet Gateway e route table pública | Permite tráfego externo para as sub-redes públicas |
| Aplicação | EC2 `t2.micro` na subnet pública 1 | Executa a API Node.js |
| API | Express na porta `3000` | Endpoints `/`, `/health` e `/api/info` |
| Segurança | Security Groups da API e do banco | Controla SSH, HTTP da API e PostgreSQL interno |
| Acesso administrativo | Key Pair `technova-key` | Acesso SSH à EC2 |

## Inicialização da aplicação

O arquivo `user_data.sh` executado pela EC2:

1. Atualiza o Amazon Linux e instala Node.js e Git.
2. Clona o repositório da aplicação.
3. Instala as dependências com `npm install`.
4. Inicia a API com `npm start`.

## Endpoints

Depois do `terraform apply`, a URL é exibida pelo output `api_url`:

- `GET /` - status da API
- `GET /health` - health check
- `GET /api/info` - informações do projeto

Exemplo:

```text
http://<IP_PUBLICO_DA_EC2>:3000/health
```

## Terraform

```bash
terraform init
terraform plan
terraform apply
```

Outputs úteis:

- `ec2_public_ip`
- `api_url`
- `ssh_command`
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`

## Observação sobre o banco de dados

A configuração atual cria as sub-redes privadas e o security group que permite PostgreSQL na porta `5432` dentro da VPC, mas ainda não cria uma instância ou serviço de banco de dados. A camada privada está preparada para uma expansão futura.
