import { Hono } from 'hono';

const app = new Hono<{ Bindings: Env }>().basePath('/api');

app.get('/saude', async (c) => {
  const resultado = await c.env.DB.prepare('SELECT ultima_versao FROM controle_versao WHERE id = 1').first();
  return c.json({ status: 'ok', banco: resultado ? 'ok' : 'sem_migracao' });
});

app.notFound((c) => c.json({ erro: 'rota_nao_encontrada' }, 404));

app.onError((erro, c) => {
  console.error(erro.message);
  return c.json({ erro: 'erro_interno' }, 500);
});

export default app;
