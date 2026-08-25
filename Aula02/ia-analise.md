# Análise do Uso de IA — Aula 02 TF

## Prompt Utilizado

[
    preciso modificar o docker-compose.yml
    Serviço api construído a partir do Dockerfile local
    Serviço postgres usando imagem postgres:15-alpine com volume nomeado
    Serviço redis usando imagem redis:7-alpine
    Rede customizada conectando os 3 serviços
    Variáveis de ambiente interpoladas do .env (não hardcoded)
    depends_on com condições de healthcheck
    Healthchecks no PostgreSQL e Redis
    Restart policy unless-stopped
    Comentários explicativos em cada seção

]

## Output Original do Kiro

[
    # =============================================================================
# Docker Compose - TechNova API
# Stack: Node.js 20 + PostgreSQL 15 + Redis 7
# =============================================================================
# Como usar:
#   docker compose up -d          (lê o .env automaticamente)
#   docker compose logs -f api    (acompanhar logs da API)
#   docker compose down -v        (remover containers e volumes)
# =============================================================================

services:

  # ---------------------------------------------------------------------------
  # PostgreSQL 15 - Banco de dados relacional
  # Volume nomeado garante persistência dos dados entre reinicializações
  # ---------------------------------------------------------------------------
  postgres:
    image: postgres:15-alpine
    container_name: technova-postgres
    restart: unless-stopped

    # Credenciais lidas do .env — nunca hardcoded aqui
    environment:
      POSTGRES_DB:       ${POSTGRES_DB}
      POSTGRES_USER:     ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

    # Volume nomeado para persistência dos dados
    volumes:
      - postgres_data:/var/lib/postgresql/data

    # Healthcheck: verifica se o PostgreSQL está aceitando conexões
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 20s

    networks:
      - technova_network

  # ---------------------------------------------------------------------------
  # Redis 7 - Cache em memória
  # Modo append-only ativo para maior durabilidade dos dados
  # ---------------------------------------------------------------------------
  redis:
    image: redis:7-alpine
    container_name: technova-redis
    restart: unless-stopped

    # Healthcheck: verifica se o Redis está respondendo ao PING
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

    networks:
      - technova_network

  # ---------------------------------------------------------------------------
  # API Node.js 20 com Express - TechNova
  # Construída a partir do Dockerfile local
  # Só inicia após postgres e redis estarem saudáveis (depends_on)
  # ---------------------------------------------------------------------------
  api:
    # Constrói a imagem a partir do Dockerfile na raiz do projeto
    build:
      context: .
      dockerfile: Dockerfile

    container_name: technova-api
    restart: unless-stopped

    # Expõe a porta da API para o host
    ports:
      - "${PORT:-3000}:3000"

    # Variáveis de ambiente interpoladas do .env
    environment:
      # Configuração geral da aplicação
      NODE_ENV: ${NODE_ENV:-development}
      PORT:     ${PORT:-3000}

      # Conexão com o PostgreSQL (nomes que o app.js espera)
      DB_HOST:     ${DB_HOST:-postgres}
      DB_PORT:     ${DB_PORT:-5432}
      DB_NAME:     ${DB_NAME}
      DB_USER:     ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}

      # Conexão com o Redis (nomes que o app.js espera)
      REDIS_HOST: ${REDIS_HOST:-redis}
      REDIS_PORT: ${REDIS_PORT:-6379}

    # Aguarda postgres e redis passarem no healthcheck antes de iniciar
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

    # Healthcheck: chama o endpoint /health da própria API
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:3000/health || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 30s

    networks:
      - technova_network

# =============================================================================
# Volumes nomeados
# postgres_data persiste os dados do banco mesmo após "docker compose down"
# Para remover os dados: docker compose down -v
# =============================================================================
volumes:
  postgres_data:
    name: technova_postgres_data

# =============================================================================
# Rede bridge customizada
# Isola os serviços e permite comunicação pelo nome do container
# =============================================================================
networks:
  technova_network:
    name: technova_network
    driver: bridge

]

## Alterações que Fiz Manualmente

| O que mudei | Por quê |
|------------|---------|
Adicionei security_opt: no-new-privileges:true em todos os containers.
Adicionei cap_drop: ALL na API para remover capacidades Linux desnecessárias.
Adicionei init: true na API para melhor gerenciamento de processos.
Adicionei rotação de logs (max-size e max-file) em todos os serviços.
Corrigi o Redis para realmente usar persistência com --appendonly yes.
Adicionei o volume redis_data para persistir os dados do Redis.
Mantive PostgreSQL e Redis sem portas expostas ao host.
Melhorei o healthcheck da API, usando o próprio Node.js em vez de wget.
Ajustei o healthcheck do PostgreSQL para usar as variáveis internas do container com $$.
Adicionei restart: true nas dependências da API.
Adicionei tmpfs em /tmp para arquivos temporários da API.
Mantive a API dependente dos healthchecks do PostgreSQL e Redis.
Organizei a configuração de volumes persistentes para PostgreSQL e Redis.
Mantive todos os serviços em uma rede Docker dedicada (technova_network).
Mantive as credenciais e configurações sensíveis usando variáveis do .env.
| ... | ... |

## O que o Kiro Acertou

[
    O código original já tinha uma boa estrutura, com serviços separados, variáveis .env, volumes, healthchecks e rede dedicada.
    Também já protegia PostgreSQL e Redis ao não expor suas portas diretamente ao host.
]

## O que o Kiro Errou ou Omitiu

[
    Faltavam algumas medidas de segurança e rotação de logs para evitar crescimento excessivo.
]

## Minha Avaliação

- **Tempo economizado usando IA:** [360min]
- **Tempo gasto validando/corrigindo:** [60min]
- **Nota para o output da IA (1-10):** [7,5]
- **Usaria novamente para este tipo de tarefa?** [Sim, ajuda bastante na estrutura inicial do docker]