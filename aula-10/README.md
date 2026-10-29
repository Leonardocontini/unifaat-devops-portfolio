# Aula 10 — GitOps Terraform + CD Pipeline

> **TechNova DevOps Portfolio** | Pipeline GitOps completo: Terraform automatizado via PRs e Continuous Delivery com health check.

---

## Visão Geral

Este projeto implementa dois fluxos automatizados para a TechNova API:

1. **GitOps Terraform**: infraestrutura gerenciada exclusivamente via Pull Requests — `plan` automático como comentário no PR, `apply` automático no merge.
2. **CD Pipeline**: lint → test → build → push (ECR) → deploy Recreate na EC2 → health check pós-deploy.

---

## Estrutura

```
aula-10/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # Plan automático em PRs (comenta no PR)
│       ├── terraform-apply.yml   # Apply automático no merge para main
│       └── cd.yml                # Pipeline CD: lint→test→build→push→deploy
├── terraform/
│   ├── provider.tf               # Provider AWS + backend S3
│   ├── main.tf                   # ECR, VPC, Security Groups, EC2
│   ├── variables.tf              # Variáveis configuráveis
│   ├── outputs.tf                # Outputs (IP, URL ECR, health URL)
│   ├── user_data.sh.tpl          # Script de inicialização da EC2
│   └── terraform.tfvars.example  # Exemplo de valores — copie para terraform.tfvars
├── technova-api/
│   ├── src/index.js              # Aplicação Express (/, /health, /api/info)
│   ├── __tests__/api.test.js     # Testes Jest + Supertest
│   ├── package.json              # Dependências e scripts
│   └── .eslintrc.json            # Configuração ESLint
├── Dockerfile                    # Multi-stage: build + produção
├── gitops-cd-analise.md          # Análise técnica dos conceitos
├── docs/
│   └── runbook-rollback.md       # Procedimento de rollback documentado
├── screenshots/                  # Evidências (inserir após execução)
└── README.md                     # Este arquivo
```

---

## Pré-requisitos

- Conta AWS (Learner Lab com sessão ativa)
- GitHub com secrets configurados (ver seção abaixo)
- Terraform >= 1.5 (apenas para execução local)
- Docker (apenas para testes locais)
- Bucket S3 para o backend do Terraform

---

## Configuração dos Secrets e Variáveis

### GitHub Secrets (Settings → Secrets → Actions)

| Secret | Descrição |
|--------|-----------|
| `AWS_ACCESS_KEY_ID` | Credencial temporária do Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Credencial temporária do Learner Lab |
| `AWS_SESSION_TOKEN` | Token de sessão do Learner Lab |
| `EC2_HOST` | IP público da EC2 (após apply do Terraform) |
| `EC2_USER` | Usuário SSH (normalmente `ec2-user`) |
| `EC2_SSH_KEY` | Conteúdo da chave privada PEM |

> ⚠️ As credenciais do Learner Lab expiram com a sessão. Atualize os três secrets `AWS_*` toda vez que reiniciar o Lab.

### GitHub Variables (Settings → Variables → Actions)

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `ECR_REPOSITORY` | Nome do repositório ECR | `technova-aula10-api` |
| `AWS_ACCOUNT_ID` | ID da conta AWS | `123456789012` |

---

## Como Reproduzir

### 1. Provisionar infraestrutura via GitOps

```bash
# Clone o repositório e crie uma branch
git checkout -b feature/infra-aula10

# Configure as variáveis do Terraform
cp aula-10/terraform/terraform.tfvars.example aula-10/terraform/terraform.tfvars
# Edite terraform.tfvars com seus valores

# Faça commit e abra um PR
git add aula-10/terraform/
git commit -m "feat(aula-10): provisionar infraestrutura ECR + EC2"
git push origin feature/infra-aula10
```

O workflow `terraform-plan.yml` vai disparar automaticamente e postar o plan como comentário no PR.

Após aprovação e merge, o `terraform-apply.yml` provisionará a infraestrutura.

### 2. Atualizar os secrets com os outputs do Terraform

Após o apply, pegue o IP da EC2:

```bash
cd aula-10/terraform
terraform output ec2_public_ip
terraform output ecr_repository_url
```

Atualize os secrets `EC2_HOST` e a variável `AWS_ACCOUNT_ID` no GitHub.

### 3. Fazer deploy da aplicação

```bash
# Qualquer push em main que altere aula-10/technova-api/ ou aula-10/Dockerfile
# dispara o pipeline cd.yml automaticamente

git add aula-10/technova-api/ aula-10/Dockerfile
git commit -m "feat(aula-10): deploy inicial TechNova API"
git push origin main
```

### 4. Verificar o health check

```bash
curl http://<EC2_PUBLIC_IP>:3000/health
```

---

## Testes Locais

```bash
cd aula-10/technova-api

# Instalar dependências
npm install

# Lint
npm run lint

# Testes
npm test

# Build Docker local
cd ..
docker build -f Dockerfile -t technova-api:local .

# Rodar localmente
docker run -p 3000:3000 technova-api:local
curl http://localhost:3000/health
```

---

## Autenticação: Learner Lab vs. Produção

| Aspecto | Learner Lab (este projeto) | Produção (ideal) |
|---------|---------------------------|------------------|
| Método | 3 secrets de sessão temporária | OIDC + IAM Role |
| Validade | Expira com a sessão do Lab | Token de curta duração por execução |
| Rotação | Manual (atualizar secrets) | Automática |
| Chaves armazenadas | Sim (GitHub Secrets) | Não |
| Viável no Lab | ✅ Sim | ❌ Lab não permite criar OIDC/roles |

Ver detalhes no [gitops-cd-analise.md](./gitops-cd-analise.md).

---

## Rollback

Em caso de deploy problemático, consulte o [runbook de rollback](./docs/runbook-rollback.md).

Resumo rápido:
```bash
# Na EC2 — login ECR antes do pull é obrigatório
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com
docker pull <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/technova-aula10-api:sha-<STABLE>
docker stop technova-api && docker rm technova-api
docker run -d --name technova-api -p 3000:3000 <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/technova-aula10-api:sha-<STABLE>
```
