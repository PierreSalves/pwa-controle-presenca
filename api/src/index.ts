import { Hono } from 'hono';
import { secureHeaders } from 'hono/secure-headers';
import { rotasAutenticacao } from './rotas/autenticacao';
import { rotasEu } from './rotas/eu';
import { rotasAcademia } from './rotas/academia';
import { rotasManifesto } from './rotas/manifesto';
import { rotasAdmin } from './rotas/admin';
import { rotasAlunos } from './rotas/alunos';
import { rotasMatriculas } from './rotas/matriculas';
import { rotasSync } from './rotas/sync';
import { rotasTurmas } from './rotas/turmas';
import { rotasUsuarios } from './rotas/usuarios';
import type { Contexto } from './tipos';

const app = new Hono<Contexto>().basePath('/api');

app.use('*', secureHeaders());
app.use('*', async (c, next) => {
  await next();
  c.header('Cache-Control', 'no-store');
});

app.get('/saude', async (c) => {
  const resultado = await c.env.DB.prepare('SELECT ultima_versao FROM controle_versao WHERE id = 1').first();
  return c.json({ status: 'ok', banco: resultado ? 'ok' : 'sem_migracao' });
});

app.route('/autenticacao', rotasAutenticacao);
app.route('/eu', rotasEu);
app.route('/sync', rotasSync);
app.route('/turmas', rotasTurmas);
app.route('/alunos', rotasAlunos);
app.route('/matriculas', rotasMatriculas);
app.route('/usuarios', rotasUsuarios);
app.route('/academia', rotasAcademia);
app.route('/manifesto', rotasManifesto);
app.route('/admin', rotasAdmin);

app.notFound((c) => c.json({ erro: 'rota_nao_encontrada' }, 404));

app.onError((erro, c) => {
  console.error(erro.message);
  return c.json({ erro: 'erro_interno' }, 500);
});

export default app;
