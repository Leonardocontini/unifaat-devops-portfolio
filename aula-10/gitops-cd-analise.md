# GitOps Terraform + CD Pipeline — Análise Técnica

**Aula 10 | TechNova DevOps Portfolio**

---

## 1. Fluxo GitOps: Plan no PR, Apply no Merge

O GitOps trata a infraestrutura como código e o repositório Git como a **fonte única de verdade**. Nenhuma mudança de infraestrutura ocorre sem passar por um Pull Request revisado.

### Por que postar o plan no PR?

O `terraform plan` é uma pré-visualização do que *vai* acontecer na infraestrutura antes de qualquer recurso ser tocado. Postá-lo como comentário no PR serve para:

- **Revisão humana**: o time vê exatamente o que será criado, modificado ou destruído antes de aprovar o merge.
- **Prevenção de surpresas**: um plan que mostra `5 to destroy` em um PR que deveria só adicionar um recurso chama atenção imediatamente.
- **Rastreabilidade**: cada PR tem o histórico do plan, conectando decisão de negócio ↔ mudança de infraestrutura ↔ commit.

### Por que aplicar somente no merge para main?

O apply em `push` para `main` significa que apenas código *aprovado e mergeado* altera a infraestrutura real. Isso garante:

1. **Controle de acesso**: nenhum desenvolvedor executa `terraform apply` na máquina local contra produção.
2. **Auditoria automática**: todo apply tem um run do GitHub Actions associado, com logs, executor identificado e timestamp.
3. **Ambiente limpo**: o runner parte sempre de um estado conhecido, sem "drifts" por variáveis locais.

---

## 2. Autenticação no Learner Lab vs. Produção Real

### Como funciona no Learner Lab

O AWS Academy Learner Lab emite **credenciais temporárias de sessão** a cada vez que o Lab é iniciado. Essas credenciais são compostas por três variáveis:

| Secret | Descrição |
|--------|-----------|
| `AWS_ACCESS_KEY_ID` | Identificador da chave de acesso temporária |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta associada |
| `AWS_SESSION_TOKEN` | Token de sessão obrigatório para credenciais temporárias |

As três são armazenadas como **GitHub Secrets** e injetadas via `aws-actions/configure-aws-credentials@v4`.

**Limitação crítica**: as credenciais expiram junto com a sessão do Lab (geralmente em 4h). Toda vez que o Lab é reiniciado, os três secrets precisam ser atualizados manualmente.

### Por que o Lab não permite OIDC

O AWS Identity and Access Management exige a criação de um **OIDC Provider** e uma **IAM Role** para que o GitHub Actions autentique sem chaves. O Learner Lab restringe permissões IAM — não é possível criar providers OIDC nem roles customizadas — tornando esse fluxo inviável no ambiente acadêmico.

### O padrão ideal em produção (OIDC + IAM Role)

Em um ambiente de produção real, a autenticação seguiria este modelo:

```hcl
# oidc.tf (NÃO aplicável no Learner Lab)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["<thumbprint>"]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:ORG/REPO:*"
        }
      }
    }]
  })
}
```

No workflow:
```yaml
permissions:
  id-token: write
  contents: read

- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT:role/github-actions-role
    aws-region: us-east-1
```

**Vantagens do OIDC**: nenhuma chave de longa duração armazenada; permissões mínimas por repositório; sem rotação manual de secrets; auditoria nativa via CloudTrail.

---

## 3. Estratégia de Deploy: Recreate

A estratégia **Recreate** é a mais simples entre as estratégias de deploy:

```
STOP  → RM  → PULL  → RUN
```

### Como funciona

1. `docker stop <container>` — para o container atual (se existir)
2. `docker rm <container>` — remove o container parado
3. `docker pull <nova-imagem>` — baixa a nova versão
4. `docker run ...` — inicia o novo container

### Prós

- **Simplicidade**: fácil de entender, implementar e depurar.
- **Sem conflito de portas**: apenas uma versão roda por vez.
- **Estado limpo**: cada deploy parte de um container zerado.
- **Custo zero**: não requer múltiplas instâncias ou load balancer.

### Contras

- **Downtime**: há um intervalo entre o stop e o start do novo container em que a aplicação fica indisponível.
- **Sem rollback automático instantâneo**: se o novo container falhar, é preciso fazer um novo deploy da versão anterior.
- **Sem tráfego gradual**: 100% dos usuários migram de uma vez para a nova versão.

### Quando usar

Recreate é adequado para:
- Ambientes de desenvolvimento e staging
- Aplicações com janela de manutenção aceita
- Serviços internos sem SLA de alta disponibilidade
- Fases iniciais de um produto onde a simplicidade tem mais valor que o zero downtime

Para produção com alta disponibilidade, as próximas aulas cobrem **Blue-Green** (Aula 11) e **Canary** (Aula 12).

---

## 4. Continuous Delivery vs. Continuous Deployment

| Aspecto | Continuous Delivery | Continuous Deployment |
|---------|--------------------|-----------------------|
| **Definição** | O código está sempre *pronto* para ir a produção | O código vai *automaticamente* a produção a cada commit aprovado |
| **Aprovação humana** | Necessária antes do deploy em produção | Não existe — o pipeline decide |
| **Risco** | Menor — humano ainda valida | Maior — exige testes altamente confiáveis |
| **Velocidade** | Alta, mas com "botão de deploy" | Máxima |
| **Exemplo neste projeto** | Workflow `cd.yml` com `workflow_dispatch` ou gate de Environment | Workflow `cd.yml` com push direto para main |
| **Quando usar** | Ambientes regulados, produtos com releases planejadas | SaaS com alta cobertura de testes, iteração rápida |

Este projeto implementa o ponto intermediário: o deploy é automático no merge para `main`, mas o merge em si exige o plan aprovado (controle humano no PR). Isso é **Continuous Delivery** com automação do deploy.

---

## 5. Limitações Identificadas e Melhorias

### Limitações atuais

1. **Credenciais expiram com o Lab**: os três secrets precisam ser atualizados a cada sessão. Em produção, isso não seria aceitável.
2. **Downtime no Recreate**: a aplicação fica indisponível entre stop e start (estimativa: 10–30s).
3. **Sem estado remoto protegido por lock**: o backend S3 sem DynamoDB para state locking pode causar race condition se dois applies rodarem simultaneamente.
4. **Chave SSH exposta como secret**: a `EC2_SSH_KEY` dá acesso direto à máquina. Em produção, o ideal é usar AWS Systems Manager Session Manager (sem SSH exposto).
5. **IP do runner não restrito**: `allowed_ssh_cidr = "0.0.0.0/0"` permite SSH de qualquer IP.

### O que melhoraria

- **OIDC + IAM Role** para eliminar chaves de longa duração (quando fora do Lab).
- **DynamoDB para state locking** no backend S3.
- **Blue-Green deploy** (Aula 11) para eliminar o downtime.
- **GitHub Environments com protection rules** para exigir aprovação manual antes do apply em produção.
- **Infracost** para estimar custo das mudanças de infra diretamente no comentário do PR.
- **AWS SSM Session Manager** para deploy sem SSH exposto.
- **terraform fmt -check** integrado ao CI como gate bloqueante (já incluído no `terraform-plan.yml`).

---

## 6. Referências

- [HashiCorp — GitOps with Terraform](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [GitHub Docs — OIDC with AWS](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS — Deploying to Amazon ECS](https://docs.aws.amazon.com/codepipeline/latest/userguide/ecs-cd-pipeline.html)
- [Continuous Delivery vs Deployment — Martin Fowler](https://martinfowler.com/bliki/ContinuousDelivery.html)
