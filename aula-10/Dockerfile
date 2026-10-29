# ─── Estágio 1: build e instalação de deps ───────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

# Copia manifests primeiro para aproveitar o cache de camadas
COPY technova-api/package*.json ./

# Instala todas as dependências (incluindo devDependencies para a etapa build)
RUN npm ci

# Copia o código fonte
COPY technova-api/src ./src

# ─── Estágio 2: imagem de produção (lean) ────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

# Variáveis de ambiente
ENV NODE_ENV=production
# GITHUB_SHA é injetada pelo CD pipeline via --build-arg e depois ENV
ARG GITHUB_SHA=local
ENV GITHUB_SHA=${GITHUB_SHA}

# Copia apenas os manifests e instala somente dependências de produção
COPY technova-api/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copia o código gerado no estágio de build
COPY --from=build /app/src ./src

EXPOSE 3000

# Roda como usuário sem privilégios
USER node

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/index.js"]
