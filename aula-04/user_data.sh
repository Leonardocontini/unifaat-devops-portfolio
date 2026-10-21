#!/bin/bash

# Atualizar o sistema
dnf update -y

# Instalar Node.js e Git
dnf install -y nodejs git

# Criar diretório da aplicação
mkdir -p /opt/technova

# Entrar no diretório
cd /opt/technova

# Clonar o repositório
git clone https://github.com/Leonardocontini/unifaat-devops-portfolio.git

# Entrar na pasta da API
cd unifaat-devops-portfolio/aula-04/API/technova-api

# Instalar dependências
npm install

# Iniciar a API
npm start