'use strict';

const request = require('supertest');
const { app, server } = require('../src/index');

afterAll((done) => {
  server.close(done);
});

describe('GET /', () => {
  it('retorna status 200 e mensagem da API', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message');
  });
});

describe('GET /health', () => {
  it('retorna status 200 e healthy', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('healthy');
  });
});

describe('GET /api/info', () => {
  it('retorna informações do projeto', async () => {
    const res = await request(app).get('/api/info');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('project', 'TechNova');
  });
});

describe('GET /rota-inexistente', () => {
  it('retorna 404', async () => {
    const res = await request(app).get('/rota-inexistente');
    expect(res.statusCode).toBe(404);
  });
});
