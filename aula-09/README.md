# Aula 09 — Docker Registry e IA no CI/CD

[![CI — Build e Push no Amazon ECR](https://github.com/leonardocontini/unifaat-devops-portfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/leonardocontini/unifaat-devops-portfolio/actions/workflows/ci.yml)
[![AI Code Review](https://github.com/leonardocontini/unifaat-devops-portfolio/actions/workflows/ai-review.yml/badge.svg)](https://github.com/leonardocontini/unifaat-devops-portfolio/actions/workflows/ai-review.yml)

## Objetivo

Implementar um pipeline para construir e publicar imagens Docker no Amazon ECR e analisar alterações de código em Pull Requests utilizando um script de análise estática.

## Estrutura do projeto

```text
aula-09/
├── .github/
│   ├── workflows/
│   │   └── ai-review.yml
│   └── scripts/
│       └── ai-review.js
├── screenshots/
├── Dockerfile
├── .dockerignore
├── ecr-push.sh
├── ia-cicd-analise.md
└── README.md
```

## Pré-requisitos

- Git
- Docker
- AWS CLI
- Node.js 20 ou superior
- Conta AWS Academy Learner Lab
- Credenciais temporárias válidas do laboratório

## Publicação no Amazon ECR

Entre na pasta do projeto:

```bash
cd aula-09
```

Configure as credenciais temporárias do Learner Lab conforme as instruções fornecidas pela disciplina.

Confira a identidade AWS:

```bash
aws sts get-caller-identity
```

Verifique se o Docker está funcionando:

```bash
docker --version
```

Dê permissão de execução ao script:

```bash
chmod +x ecr-push.sh
```

Execute a publicação:

```bash
./ecr-push.sh
```

O script cria ou utiliza o repositório `technova-api`, constrói a imagem e publica as tags SHA e `latest`. Quando o commit corresponde a uma tag Git SemVer válida, também publica as tags de versão.

## Versionamento SemVer

Para criar uma versão:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Execute o script no commit correspondente à tag para publicar as versões `1.2.3`, `1.2` e `1`.

## Baixar uma imagem do ECR

Após a publicação, consulte o Account ID:

```bash
aws sts get-caller-identity --query Account --output text
```

Configure o endereço do registry:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
```

Faça login e baixe uma versão:

```bash
aws ecr get-login-password --region us-east-1 |
  docker login --username AWS --password-stdin "$REGISTRY"

docker pull "$REGISTRY/technova-api:latest"
```

Para rollback, substitua `latest` por uma tag SHA ou SemVer que já tenha sido publicada.

## AI Review

O workflow `.github/workflows/ai-review.yml` é executado quando um Pull Request é aberto, atualizado ou reaberto, desde que haja alterações em `aula-09/`.

O script `.github/scripts/ai-review.js` procura padrões como:

- Segredos hardcoded
- Uso de `eval()`
- Possível SQL injection
- Uso de `console.log()`
- Blocos `catch` vazios
- Outros padrões potencialmente inseguros

O resultado é publicado como comentário no Pull Request.

## Quality gate

O pipeline bloqueia a conclusão bem-sucedida do job quando encontra achados `CRITICAL` ou quando a análise falha.

Achados `WARNING` não bloqueiam o job automaticamente, mas devem ser revisados.

Para impedir efetivamente o merge, configure uma regra de proteção da branch que exija a aprovação do status check do workflow.

## Evidências

Salvar na pasta `screenshots/`:

1. `ecr-console.png` — repositório ECR com as tags publicadas.
2. `ai-review-comment.png` — comentário do AI Review no Pull Request.
3. `ecr-push-ok.png` — publicação concluída com sucesso.
4. `quality-gate-block.png` — workflow bloqueado por um achado CRITICAL.

## Documentação complementar

Consulte `ia-cicd-analise.md` para conhecer a estratégia de versionamento, os padrões analisados, as regras de decisão e as limitações da análise estática.
