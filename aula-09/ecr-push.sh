
#!/usr/bin/env bash
set -Eeuo pipefail

# Configurações
REGION="us-east-1"
REPOSITORY="technova-api"

# Verifica dependências
for cmd in aws docker git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Erro: '$cmd' não está instalado."
    exit 1
  fi
done

# Detecta o socket Docker disponível.
# Prefere o socket do Docker Desktop quando existir;
# caso contrário usa o socket padrão do Docker Engine.
DESKTOP_SOCK="${HOME}/.docker/desktop/docker.sock"
if [ -S "$DESKTOP_SOCK" ]; then
  DOCKER_HOST="unix://${DESKTOP_SOCK}"
else
  DOCKER_HOST="unix:///var/run/docker.sock"
fi
export DOCKER_HOST

# Usa diretório de configuração temporário para evitar erros de
# credential helper (pass, keychain) que podem não estar configurados.
DOCKER_CONFIG_DIR="$(mktemp -d)"
trap 'rm -rf "$DOCKER_CONFIG_DIR"' EXIT
# Copia somente o config.json base (contexts, plugins) sem credenciais.
if [ -f "${HOME}/.docker/config.json" ]; then
  # Remove credHelpers/credsStore para forçar armazenamento em arquivo
  python3 -c "
import json, sys
cfg = json.load(open('${HOME}/.docker/config.json'))
cfg.pop('credsStore', None)
cfg.pop('credHelpers', None)
json.dump(cfg, open('${DOCKER_CONFIG_DIR}/config.json', 'w'))
"
fi
export DOCKER_CONFIG="$DOCKER_CONFIG_DIR"

# Confirma que o Docker está acessível
docker info >/dev/null 2>&1 || {
  echo "Erro: Docker não está acessível (DOCKER_HOST=${DOCKER_HOST})."
  echo "Verifique se o daemon está em execução e tente novamente."
  exit 1
}

# Obtém o Account ID da sessão AWS
ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text)

REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${REPOSITORY}"

# Obtém o SHA curto do commit
GIT_SHA=$(git rev-parse --short HEAD)
SHA_TAG="sha-${GIT_SHA}"

echo "Conta AWS: ${ACCOUNT_ID}"
echo "Região: ${REGION}"
echo "Repositório: ${REPOSITORY}"

# Cria o repositório caso ainda não exista
if ! aws ecr describe-repositories \
  --repository-names "$REPOSITORY" \
  --region "$REGION" >/dev/null 2>&1; then

  aws ecr create-repository \
    --repository-name "$REPOSITORY" \
    --region "$REGION" \
    --image-scanning-configuration scanOnPush=true

  # Lifecycle policy: mantém as 10 imagens tagged mais recentes;
  # remove imagens untagged com mais de 1 dia.
  aws ecr put-lifecycle-policy \
    --repository-name "$REPOSITORY" \
    --region "$REGION" \
    --lifecycle-policy-text '{
      "rules": [
        {
          "rulePriority": 1,
          "description": "Remove imagens sem tag com mais de 1 dia",
          "selection": {
            "tagStatus": "untagged",
            "countType": "sinceImagePushed",
            "countUnit": "days",
            "countNumber": 1
          },
          "action": { "type": "expire" }
        },
        {
          "rulePriority": 2,
          "description": "Mantém as 10 imagens tagged mais recentes",
          "selection": {
            "tagStatus": "tagged",
            "tagPrefixList": ["sha-"],
            "countType": "imageCountMoreThan",
            "countNumber": 10
          },
          "action": { "type": "expire" }
        }
      ]
    }'
fi

# Login no ECR usando o mesmo contexto e configuração
aws ecr get-login-password --region "$REGION" |
  docker login \
    --username AWS \
    --password-stdin "$REGISTRY"

# Build da imagem
docker build \
  -f Dockerfile \
  -t "${IMAGE}:${SHA_TAG}" \
  .

# Tags principais
docker tag \
  "${IMAGE}:${SHA_TAG}" "${IMAGE}:latest"

TAGS=("$SHA_TAG" "latest")

# Tags SemVer quando HEAD corresponde a vX.Y.Z
if VERSION=$(git describe --tags --exact-match HEAD 2>/dev/null); then
  if [[ "$VERSION" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"

    for TAG in "${MAJOR}.${MINOR}.${PATCH}" "${MAJOR}.${MINOR}" "$MAJOR"; do
      docker tag \
        "${IMAGE}:${SHA_TAG}" "${IMAGE}:${TAG}"
      TAGS+=("$TAG")
    done
  else
    echo "Aviso: tag Git '$VERSION' não está no formato vX.Y.Z."
  fi
fi

# Publica todas as tags
for TAG in "${TAGS[@]}"; do
  docker push "${IMAGE}:${TAG}"
done

echo
echo "Publicação concluída!"
echo "Imagem: ${IMAGE}"
echo "Tags publicadas: ${TAGS[*]}"
