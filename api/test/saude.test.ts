import { exports } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

describe('GET /api/saude', () => {
  it('responde ok com o banco migrado', async () => {
    const resposta = await exports.default.fetch('https://exemplo.test/api/saude');
    expect(resposta.status).toBe(200);
    expect(await resposta.json()).toEqual({ status: 'ok', banco: 'ok' });
  });
});

describe('rotas inexistentes da API', () => {
  it('respondem 404 em JSON', async () => {
    const resposta = await exports.default.fetch('https://exemplo.test/api/nao-existe');
    expect(resposta.status).toBe(404);
    expect(await resposta.json()).toEqual({ erro: 'rota_nao_encontrada' });
  });
});
