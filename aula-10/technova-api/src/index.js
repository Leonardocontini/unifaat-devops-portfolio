'use strict';

const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Rota raiz
app.get('/', (req, res) => {
  res.json({
    message: 'TechNova API — Aula 10',
    version: process.env.npm_package_version || '1.0.0',
    env: process.env.NODE_ENV || 'development',
    sha: process.env.GITHUB_SHA || 'local',
  });
});

// Health check — usado pelo pipeline CD para verificar o deploy
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// Informações da aplicação
app.get('/api/info', (req, res) => {
  res.json({
    project: 'TechNova',
    environment: process.env.NODE_ENV || 'development',
    server: 'Node.js',
    sha: process.env.GITHUB_SHA || 'local',
  });
});

// Rota 404 genérica
app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  process.stdout.write(`TechNova API rodando na porta ${PORT}\n`);
});

module.exports = { app, server };
