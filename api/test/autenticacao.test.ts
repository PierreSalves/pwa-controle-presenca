import { env } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';
import {
  comToken,
  criarTenant,
  criarTurma,
  criarUsuario,
  entrar,
  extrairCookie,
  liberarTurma,
  requisitar,
  SENHA_PADRAO,
} from './apoio';

let tenantId: string;

beforeAll(async () => {
  tenantId = await criarTenant();
});

describe('POST /api/autenticacao/entrar', () => {
  it('entra com e-mail e senha corretos e devolve token e cookie de renovação', async () => {
    const usuario = await criarUsuario({ tenantId, tipo: 'professor' });
    const { resposta, tokenAcesso, cookieRenovacao } = await entrar(
      usuario.email.toUpperCase(),
      usuario.senha,
    );
    expect(resposta.status).toBe(200);
    expect(tokenAcesso.split('.')).toHaveLength(3);
    expect(cookieRenovacao).toMatch(/^cp_renovacao=.+/);
    const setCookie = resposta.headers.get('Set-Cookie') ?? '';
    expect(setCookie).toContain('HttpOnly');
    expect(setCookie).toContain('Secure');
    expect(setCookie).toContain('SameSite=Strict');
    const corpo = await resposta.json<{ usuario: { tipo: string; tenant_id: string } }>();
    expect(corpo.usuario).toMatchObject({ tipo: 'professor', tenant_id: tenantId });
  });

  it('recusa senha errada, e-mail inexistente e corpo inválido sem revelar qual foi', async () => {
    const usuario = await criarUsuario({ tenantId, tipo: 'assistente' });
    const senhaErrada = await entrar(usuario.email, 'outra-senha-qualquer');
    const emailInexistente = await entrar('ninguem@exemplo.test', SENHA_PADRAO);
    expect(senhaErrada.resposta.status).toBe(401);
    expect(emailInexistente.resposta.status).toBe(401);
    expect(await senhaErrada.resposta.json()).toEqual({ erro: 'credenciais_invalidas' });
    expect(await emailInexistente.resposta.json()).toEqual({ erro: 'credenciais_invalidas' });

    const semCorpo = await requisitar('/api/autenticacao/entrar', { method: 'POST', body: 'x' });
    expect(semCorpo.status).toBe(400);
  });

  it('recusa usuário inativo e usuário de academia desativada', async () => {
    const inativo = await criarUsuario({ tenantId, tipo: 'assistente', ativo: 0 });
    expect((await entrar(inativo.email, inativo.senha)).resposta.status).toBe(401);

    const tenantDesativado = await criarTenant('Academia Desativada', 0);
    const usuario = await criarUsuario({ tenantId: tenantDesativado, tipo: 'professor' });
    expect((await entrar(usuario.email, usuario.senha)).resposta.status).toBe(401);
  });

  it('superadmin entra sem academia', async () => {
    const admin = await criarUsuario({ tenantId: null, tipo: 'superadmin' });
    const { resposta } = await entrar(admin.email, admin.senha);
    expect(resposta.status).toBe(200);
  });
});

describe('renovar e sair', () => {
  it('renova o token trocando o token de renovação (rotação)', async () => {
    const usuario = await criarUsuario({ tenantId, tipo: 'professor' });
    const login = await entrar(usuario.email, usuario.senha);

    const renovada = await requisitar('/api/autenticacao/renovar', {
      method: 'POST',
      headers: { Cookie: login.cookieRenovacao },
    });
    expect(renovada.status).toBe(200);
    const novoCookie = extrairCookie(renovada);
    expect(novoCookie).not.toBe(login.cookieRenovacao);

    // o token antigo não serve mais
    const reuso = await requisitar('/api/autenticacao/renovar', {
      method: 'POST',
      headers: { Cookie: login.cookieRenovacao },
    });
    expect(reuso.status).toBe(401);
  });

  it('sair revoga a sessão: renovar e usar o token de acesso deixam de funcionar', async () => {
    const usuario = await criarUsuario({ tenantId, tipo: 'assistente' });
    const login = await entrar(usuario.email, usuario.senha);

    const saida = await requisitar('/api/autenticacao/sair', {
      method: 'POST',
      headers: { Cookie: login.cookieRenovacao },
    });
    expect(saida.status).toBe(204);

    const renovar = await requisitar('/api/autenticacao/renovar', {
      method: 'POST',
      headers: { Cookie: login.cookieRenovacao },
    });
    expect(renovar.status).toBe(401);
    expect((await requisitar('/api/eu', comToken(login.tokenAcesso))).status).toBe(401);
  });

  it('desativar o usuário bloqueia o token de acesso na hora', async () => {
    const usuario = await criarUsuario({ tenantId, tipo: 'assistente' });
    const login = await entrar(usuario.email, usuario.senha);
    expect((await requisitar('/api/eu', comToken(login.tokenAcesso))).status).toBe(200);

    await env.DB.prepare('UPDATE usuarios SET ativo = 0 WHERE id = ?1').bind(usuario.id).run();
    expect((await requisitar('/api/eu', comToken(login.tokenAcesso))).status).toBe(401);
  });
});

describe('GET /api/eu', () => {
  it('exige token', async () => {
    expect((await requisitar('/api/eu')).status).toBe(401);
    expect((await requisitar('/api/eu', comToken('token.falso.qualquer'))).status).toBe(401);
  });

  it('devolve só as turmas liberadas para o usuário, e nunca turmas de outra academia', async () => {
    const outraAcademia = await criarTenant('Outra Academia');
    const turmaLiberada = await criarTurma(tenantId, 'Adulto');
    await criarTurma(tenantId, 'Kids (sem acesso)');
    const turmaDeOutraAcademia = await criarTurma(outraAcademia, 'Turma alheia');

    const assistente = await criarUsuario({ tenantId, tipo: 'assistente' });
    await liberarTurma(tenantId, turmaLiberada, assistente.id);
    // acesso indevido gravado com o tenant errado não pode aparecer
    await liberarTurma(outraAcademia, turmaDeOutraAcademia, assistente.id);

    const login = await entrar(assistente.email, assistente.senha);
    const resposta = await requisitar('/api/eu', comToken(login.tokenAcesso));
    const corpo = await resposta.json<{ tenant: { id: string }; turmas: { id: string }[] }>();
    expect(corpo.tenant.id).toBe(tenantId);
    expect(corpo.turmas.map((t) => t.id)).toEqual([turmaLiberada]);
  });
});

describe('POST /api/eu/senha', () => {
  it('troca a senha, exige a senha atual e encerra as outras sessões', async () => {
    const usuario = await criarUsuario({ tenantId, tipo: 'professor' });
    const sessaoA = await entrar(usuario.email, usuario.senha);
    const sessaoB = await entrar(usuario.email, usuario.senha);

    const errada = await requisitar(
      '/api/eu/senha',
      comToken(sessaoA.tokenAcesso, {
        method: 'POST',
        body: JSON.stringify({ senha_atual: 'nao-e-essa', senha_nova: 'nova-senha-segura' }),
      }),
    );
    expect(errada.status).toBe(400);

    const curta = await requisitar(
      '/api/eu/senha',
      comToken(sessaoA.tokenAcesso, {
        method: 'POST',
        body: JSON.stringify({ senha_atual: usuario.senha, senha_nova: '123' }),
      }),
    );
    expect(curta.status).toBe(400);

    const ok = await requisitar(
      '/api/eu/senha',
      comToken(sessaoA.tokenAcesso, {
        method: 'POST',
        body: JSON.stringify({ senha_atual: usuario.senha, senha_nova: 'nova-senha-segura' }),
      }),
    );
    expect(ok.status).toBe(204);

    expect((await requisitar('/api/eu', comToken(sessaoA.tokenAcesso))).status).toBe(200);
    expect((await requisitar('/api/eu', comToken(sessaoB.tokenAcesso))).status).toBe(401);
    expect((await entrar(usuario.email, usuario.senha)).resposta.status).toBe(401);
    expect((await entrar(usuario.email, 'nova-senha-segura')).resposta.status).toBe(200);
  });
});
