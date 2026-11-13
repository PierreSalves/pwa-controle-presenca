import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { comToken, criarTenant, criarUsuario, entrar, requisitar, SENHA_PADRAO } from './apoio';

function chamar(token: string, metodo: string, caminho: string, corpo?: unknown): Promise<Response> {
  return requisitar(
    caminho,
    comToken(token, {
      method: metodo,
      headers: { 'Content-Type': 'application/json' },
      body: corpo === undefined ? undefined : JSON.stringify(corpo),
    }),
  );
}

async function entrarComo(tenantId: string | null, tipo: 'superadmin' | 'professor' | 'assistente') {
  const usuario = await criarUsuario({ tenantId, tipo });
  return { ...usuario, token: (await entrar(usuario.email, usuario.senha)).tokenAcesso };
}

let sequencia = 0;
function novoEmail(): string {
  sequencia += 1;
  return `pessoa-${Date.now()}-${sequencia}@exemplo.test`;
}

describe('usuários da academia', () => {
  it('só o professor gerencia usuários', async () => {
    const tenantId = await criarTenant();
    const assistente = await entrarComo(tenantId, 'assistente');
    const admin = await entrarComo(null, 'superadmin');
    expect((await chamar(assistente.token, 'GET', '/api/usuarios')).status).toBe(403);
    expect((await chamar(admin.token, 'GET', '/api/usuarios')).status).toBe(403);
  });

  it('cria assistente com senha inicial e turmas; ela entra e recebe só essas turmas', async () => {
    const tenantId = await criarTenant();
    const professor = await entrarComo(tenantId, 'professor');
    const turma = await (
      await chamar(professor.token, 'POST', '/api/turmas', { nome: 'Kids' })
    ).json<{
      turma: { id: string };
    }>();
    await chamar(professor.token, 'POST', '/api/turmas', { nome: 'Adulto' });

    const email = novoEmail();
    const resposta = await chamar(professor.token, 'POST', '/api/usuarios', {
      nome: 'Maria',
      email: email.toUpperCase(),
      tipo: 'assistente',
      senha: 'senha-inicial-1',
      turma_ids: [turma.turma.id],
    });
    expect(resposta.status).toBe(201);
    const { usuario } = await resposta.json<{ usuario: { email: string; turmas: { nome: string }[] } }>();
    expect(usuario).toMatchObject({ email, tipo: 'assistente', ativo: 1, turmas: [{ nome: 'Kids' }] });

    const login = await entrar(email, 'senha-inicial-1');
    expect(login.resposta.status).toBe(200);
    const pull = await (
      await chamar(login.tokenAcesso, 'GET', '/api/sync/pull?desde=0')
    ).json<{
      turmas_permitidas: string[];
    }>();
    expect(pull.turmas_permitidas).toEqual([turma.turma.id]);

    const repetido = await chamar(professor.token, 'POST', '/api/usuarios', {
      nome: 'Outra',
      email,
      tipo: 'assistente',
      senha: 'senha-inicial-1',
    });
    expect(repetido.status).toBe(409);
  });

  it('valida os dados e recusa turma de outra academia', async () => {
    const tenantId = await criarTenant();
    const outro = await criarTenant('Outra');
    const professor = await entrarComo(tenantId, 'professor');
    const professorOutro = await entrarComo(outro, 'professor');
    const turmaOutra = await (
      await chamar(professorOutro.token, 'POST', '/api/turmas', { nome: 'X' })
    ).json<{
      turma: { id: string };
    }>();
    const base = { nome: 'Ana', email: novoEmail(), tipo: 'assistente', senha: 'senha-inicial-1' };
    for (const corpo of [
      { ...base, email: 'sem-arroba' },
      { ...base, tipo: 'superadmin' },
      { ...base, senha: 'curta' },
      { ...base, turma_ids: [turmaOutra.turma.id] },
    ]) {
      expect((await chamar(professor.token, 'POST', '/api/usuarios', corpo)).status).toBe(400);
    }
  });

  it('desativar encerra as sessões na hora; o professor não se desativa nem muda o próprio tipo', async () => {
    const tenantId = await criarTenant();
    const professor = await entrarComo(tenantId, 'professor');
    const email = novoEmail();
    const criado = await (
      await chamar(professor.token, 'POST', '/api/usuarios', {
        nome: 'Prof 2',
        email,
        tipo: 'professor',
        senha: SENHA_PADRAO,
      })
    ).json<{ usuario: { id: string } }>();
    const id = criado.usuario.id;
    const prof2 = await entrar(email, SENHA_PADRAO);

    // Prof 2 tenta se rebaixar e se desativar.
    for (const mudanca of [
      { tipo: 'assistente', ativo: 1 },
      { tipo: 'professor', ativo: 0 },
    ]) {
      const resposta = await chamar(prof2.tokenAcesso, 'PUT', `/api/usuarios/${id}`, {
        nome: 'Prof 2',
        email,
        ...mudanca,
      });
      expect(resposta.status).toBe(409);
    }

    const resposta = await chamar(professor.token, 'PUT', `/api/usuarios/${id}`, {
      nome: 'Prof 2',
      email,
      tipo: 'assistente',
      ativo: 0,
    });
    expect(resposta.status).toBe(200);
    expect((await chamar(prof2.tokenAcesso, 'GET', '/api/eu')).status).toBe(401);
    expect((await entrar(email, SENHA_PADRAO)).resposta.status).toBe(401);
  });

  it('redefine a senha de outro usuário e encerra as sessões dele', async () => {
    const tenantId = await criarTenant();
    const professor = await entrarComo(tenantId, 'professor');
    const email = novoEmail();
    const { usuario } = await (
      await chamar(professor.token, 'POST', '/api/usuarios', {
        nome: 'Ana',
        email,
        tipo: 'assistente',
        senha: SENHA_PADRAO,
      })
    ).json<{ usuario: { id: string } }>();
    const sessao = await entrar(email, SENHA_PADRAO);

    expect(
      (await chamar(professor.token, 'POST', `/api/usuarios/${usuario.id}/senha`, { senha: 'x' })).status,
    ).toBe(400);
    const resposta = await chamar(professor.token, 'POST', `/api/usuarios/${usuario.id}/senha`, {
      senha: 'nova-senha-123',
    });
    expect(resposta.status).toBe(204);
    expect((await chamar(sessao.tokenAcesso, 'GET', '/api/eu')).status).toBe(401);
    expect((await entrar(email, 'nova-senha-123')).resposta.status).toBe(200);
  });

  it('define as turmas do usuário e isola as academias', async () => {
    const a = await criarTenant('A');
    const b = await criarTenant('B');
    const professorA = await entrarComo(a, 'professor');
    const professorB = await entrarComo(b, 'professor');
    const kids = await (
      await chamar(professorA.token, 'POST', '/api/turmas', { nome: 'Kids' })
    ).json<{
      turma: { id: string };
    }>();
    const { usuario } = await (
      await chamar(professorA.token, 'POST', '/api/usuarios', {
        nome: 'Ana',
        email: novoEmail(),
        tipo: 'assistente',
        senha: SENHA_PADRAO,
      })
    ).json<{ usuario: { id: string } }>();

    let resposta = await chamar(professorA.token, 'PUT', `/api/usuarios/${usuario.id}/turmas`, {
      turma_ids: [kids.turma.id],
    });
    expect(await resposta.json()).toMatchObject({ usuario: { turmas: [{ nome: 'Kids' }] } });
    resposta = await chamar(professorA.token, 'PUT', `/api/usuarios/${usuario.id}/turmas`, { turma_ids: [] });
    expect(await resposta.json()).toMatchObject({ usuario: { turmas: [] } });

    const caminho = `/api/usuarios/${usuario.id}`;
    expect((await chamar(professorB.token, 'PUT', `${caminho}/turmas`, { turma_ids: [] })).status).toBe(404);
    expect(
      (await chamar(professorB.token, 'POST', `${caminho}/senha`, { senha: 'senha-invasora' })).status,
    ).toBe(404);
    expect(
      (
        await chamar(professorB.token, 'PUT', caminho, {
          nome: 'X',
          email: novoEmail(),
          tipo: 'assistente',
          ativo: 0,
        })
      ).status,
    ).toBe(404);
    const lista = await (
      await chamar(professorB.token, 'GET', '/api/usuarios')
    ).json<{ usuarios: { id: string }[] }>();
    expect(lista.usuarios.map((u) => u.id)).toEqual([professorB.id]);
  });
});

describe('dados da academia', () => {
  it('o professor altera nome, nome curto e cabeçalho; a assistente não', async () => {
    const tenantId = await criarTenant();
    const professor = await entrarComo(tenantId, 'professor');
    const assistente = await entrarComo(tenantId, 'assistente');
    expect((await chamar(assistente.token, 'GET', '/api/academia')).status).toBe(403);

    expect(
      (await chamar(professor.token, 'PUT', '/api/academia', { nome: 'X', nome_curto: 'Nome curto demais!' }))
        .status,
    ).toBe(400);
    const resposta = await chamar(professor.token, 'PUT', '/api/academia', {
      nome: 'Equipe Junião',
      nome_curto: 'Junião',
      cabecalho_impressao: 'Prof. Junião',
    });
    expect(await resposta.json()).toMatchObject({
      academia: { id: tenantId, nome: 'Equipe Junião', nome_curto: 'Junião', tem_logotipo: 0 },
    });
  });
});

describe('administrador do sistema', () => {
  it('só o superadmin acessa', async () => {
    const tenantId = await criarTenant();
    const professor = await entrarComo(tenantId, 'professor');
    expect((await chamar(professor.token, 'GET', '/api/admin/academias')).status).toBe(403);
  });

  it('cria a academia com o primeiro professor, que entra e cadastra o resto', async () => {
    const admin = await entrarComo(null, 'superadmin');
    const email = novoEmail();
    const resposta = await chamar(admin.token, 'POST', '/api/admin/academias', {
      nome: 'Academia Nova',
      professor: { nome: 'Prof. Novo', email, senha: 'senha-inicial-1' },
    });
    expect(resposta.status).toBe(201);
    const { academia } = await resposta.json<{ academia: { id: string; usuarios: number } }>();
    expect(academia).toMatchObject({ nome: 'Academia Nova', ativo: 1, usuarios: 1, alunos: 0 });

    const login = await entrar(email, 'senha-inicial-1');
    expect(login.resposta.status).toBe(200);
    expect((await chamar(login.tokenAcesso, 'GET', '/api/usuarios')).status).toBe(200);

    const lista = await (
      await chamar(admin.token, 'GET', '/api/admin/academias')
    ).json<{ academias: { id: string }[] }>();
    expect(lista.academias.map((a) => a.id)).toContain(academia.id);

    // E-mail já usado não cria a academia pela metade.
    const antes = await env.DB.prepare('SELECT COUNT(*) AS n FROM tenants').first<{ n: number }>();
    const repetido = await chamar(admin.token, 'POST', '/api/admin/academias', {
      nome: 'Outra',
      professor: { nome: 'X', email, senha: 'senha-inicial-1' },
    });
    expect(repetido.status).toBe(409);
    expect(await env.DB.prepare('SELECT COUNT(*) AS n FROM tenants').first()).toEqual(antes);
  });

  it('cria mais professores, desativa professor e a academia, e faz a carga inicial de alunos', async () => {
    const admin = await entrarComo(null, 'superadmin');
    const { academia } = await (
      await chamar(admin.token, 'POST', '/api/admin/academias', {
        nome: 'Academia',
        professor: { nome: 'Prof. 1', email: novoEmail(), senha: SENHA_PADRAO },
      })
    ).json<{ academia: { id: string } }>();
    const base = `/api/admin/academias/${academia.id}`;

    const email2 = novoEmail();
    let resposta = await chamar(admin.token, 'POST', `${base}/professores`, {
      nome: 'Prof. 2',
      email: email2,
      senha: SENHA_PADRAO,
    });
    expect(resposta.status).toBe(201);
    const { professor } = await resposta.json<{ professor: { id: string } }>();
    const sessao = await entrar(email2, SENHA_PADRAO);
    const professores = await (
      await chamar(admin.token, 'GET', `${base}/professores`)
    ).json<{ professores: unknown[] }>();
    expect(professores.professores).toHaveLength(2);

    expect((await chamar(admin.token, 'DELETE', `${base}/professores/${professor.id}`)).status).toBe(204);
    expect((await chamar(sessao.tokenAcesso, 'GET', '/api/eu')).status).toBe(401);

    resposta = await chamar(admin.token, 'POST', `${base}/alunos/importacao`, {
      alunos: [
        { codigo: '(1)', nome: 'Ana' },
        { codigo: '2', nome: 'Bruno' },
      ],
      confirmar: true,
    });
    expect(resposta.status).toBe(201);
    expect(await resposta.json()).toMatchObject({ importados: 2 });

    const login1 = await entrar(email2, SENHA_PADRAO);
    expect(login1.resposta.status).toBe(401);

    resposta = await chamar(admin.token, 'PUT', base, { nome: 'Academia', ativo: 0 });
    expect(await resposta.json()).toMatchObject({ academia: { ativo: 0, alunos: 2 } });
  });

  it('valida os dados e responde 404 para academia inexistente', async () => {
    const admin = await entrarComo(null, 'superadmin');
    expect(
      (await chamar(admin.token, 'POST', '/api/admin/academias', { nome: 'Sem professor' })).status,
    ).toBe(400);
    const inexistente = '/api/admin/academias/01900000-0000-7000-8000-000000000000';
    expect((await chamar(admin.token, 'PUT', inexistente, { nome: 'X', ativo: 1 })).status).toBe(404);
    expect((await chamar(admin.token, 'GET', `${inexistente}/professores`)).status).toBe(404);
  });
});
