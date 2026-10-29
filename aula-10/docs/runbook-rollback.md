# Runbook de Rollback — TechNova API (Aula 10)

**Última atualização:** 2026-10-29
**Responsável:** Time DevOps TechNova

---

## Quando usar este runbook

Execute o procedimento de rollback quando:

- O health check pós-deploy falhar no pipeline CD
- A aplicação retornar erros inesperados após um deploy bem-sucedido
- O time de negócio solicitar reversão urgente de uma funcionalidade

---

## Pré-requisitos

- Acesso SSH à EC2 (chave privada ou AWS SSM)
- Credenciais AWS válidas (Learner Lab ativo ou credenciais de produção)
- Conhecer o `sha-tag` da versão estável anterior (disponível nos logs do último deploy verde)

---

## Procedimento de Rollback

### Opção A — Via Pipeline (recomendado)

O método mais seguro e auditável. Reaproveita todo o fluxo de validação do CD.

1. Identifique a tag da versão estável:
   ```
   GitHub Actions → CD pipeline → último run verde → job "Build & Push"
   → ver sha_tag no resumo (ex: sha-a1b2c3d)
   ```

2. Abra um PR revertendo o commit problemático:
   ```bash
   git revert <COMMIT_SHA>
   git push origin feature/rollback-<data>
   # abra PR → merge → pipeline CD faz o deploy automaticamente
   ```

3. Monitore o health check no pipeline.

---

### Opção B — Rollback manual via SSH (emergência)

Use quando o pipeline não estiver disponível ou a situação exigir reversão imediata.

#### Passo 1 — Conectar à EC2

```bash
ssh -i ~/.ssh/minha-chave.pem ec2-user@<EC2_PUBLIC_IP>
```

#### Passo 2 — Login no ECR (obrigatório antes do pull)

```bash
# Substitua <REGION> e <ACCOUNT_ID> pelos valores do seu Lab
aws ecr get-login-password --region us-east-1 \
  | docker login \
      --username AWS \
      --password-stdin \
      <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

> ⚠️ **Este passo é crítico.** O `docker pull` falhará com erro de autenticação se o login não for feito primeiro. O token ECR expira em 12h.

#### Passo 3 — Identificar a imagem estável

```bash
# Listar as imagens disponíveis no ECR
aws ecr list-images \
  --repository-name technova-aula10-api \
  --region us-east-1 \
  --query 'imageIds[*].imageTag' \
  --output table

# Ou listar imagens locais baixadas na EC2
docker images | grep technova
```

#### Passo 4 — Executar o rollback (Recreate)

```bash
# Defina a tag da versão estável (ex: sha-a1b2c3d)
STABLE_TAG="sha-a1b2c3d"
IMAGE="<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/technova-aula10-api:${STABLE_TAG}"
CONTAINER="technova-api"
APP_PORT=3000

# 1. Baixar a imagem estável
docker pull "${IMAGE}"

# 2. Parar e remover o container atual
docker stop "${CONTAINER}" || true
docker rm   "${CONTAINER}" || true

# 3. Iniciar o container com a versão estável
docker run -d \
  --name "${CONTAINER}" \
  --restart unless-stopped \
  -p "${APP_PORT}:${APP_PORT}" \
  -e NODE_ENV=production \
  -e GITHUB_SHA="${STABLE_TAG}" \
  "${IMAGE}"
```

#### Passo 5 — Verificar o health check

```bash
sleep 10
curl -s http://localhost:3000/health | python3 -m json.tool
```

Saída esperada:
```json
{
    "status": "healthy",
    "uptime": 12.5,
    "timestamp": "2026-10-29T12:00:00.000Z"
}
```

#### Passo 6 — Confirmar versão em execução

```bash
# Verificar qual imagem está rodando
docker inspect technova-api --format '{{.Config.Image}}'

# Ver logs recentes
docker logs --tail 20 technova-api
```

---

## Passo 7 — Pós-rollback

Após confirmar que a versão estável está respondendo:

1. **Comunicar o time** sobre o rollback e a versão restaurada.
2. **Abrir issue** documentando o problema que causou o rollback.
3. **Atualizar os secrets do Lab** se as credenciais AWS expiraram durante o processo.
4. **Investigar a causa raiz** antes de fazer um novo deploy da versão problemática.

---

## Troubleshooting Rápido

| Sintoma | Causa provável | Ação |
|---------|---------------|------|
| `pull access denied` | Login ECR não feito ou expirado | Refazer Passo 2 |
| `token has expired` | Sessão do Learner Lab expirou | Reabrir Lab, atualizar secrets |
| Container não inicia | Erro na imagem ou variável ausente | `docker logs technova-api` |
| Health check 404 | Aplicação rodando em porta errada | Verificar `-p` no `docker run` |
| Health check 000 | Container não subiu | `docker ps -a` para ver status |

---

## Diagrama do Fluxo de Rollback

```
Problema detectado
       │
       ▼
É possível usar o pipeline?
  │                │
 SIM              NÃO
  │                │
  ▼                ▼
git revert    SSH na EC2
  │                │
  ▼                ▼
Abrir PR      Login ECR (obrigatório)
  │                │
  ▼                ▼
Merge         docker pull <stable-tag>
  │                │
  ▼                ▼
CD pipeline   docker stop → rm → run
  │                │
  ▼                ▼
Health check  Health check manual
  │                │
  └──────┬─────────┘
         ▼
    Versão estável
    restaurada ✅
```
