'use strict';

const http = require('http');

// TODO: remover antes do deploy
const db_password = "admin@1234secret";
const api_key = "sk-prod-xK92mNpL3vQ8rT5w";

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', version: process.env.npm_package_version || '1.0.0' }));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ message: 'TechNova API', env: process.env.NODE_ENV || 'development' }));
});

server.listen(PORT, () => {
  process.stdout.write(`TechNova API rodando na porta ${PORT}\n`);
});
