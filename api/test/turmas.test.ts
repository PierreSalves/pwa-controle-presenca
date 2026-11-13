import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { REGRAS_PADRAO_TURMA } from '../src/regras/configuracao-turma';
import { obterHojeEmSaoPaulo } from '../src/regras/presenca';
import { somarDiasNaData } from '../src/util/datas';
import { comToken, criarTenant, criarUsuario, entrar, requisitar } from './apoio';

const HOJE = obterHojeEmSaoPaulo();
const JSON_HEADERS = { 'Content-Type': 'application/json' };

interface Academia {
  tenantId: string;
  professor: { id: string; token: string };
  assistente: { id: string; token: string };
}

async function montarAcademia(nome = 'Academia'): Promise<Academia> {
  const tenantId = await criarTenant(nome);
  const professor = await criarUsuario({ tenantId, tipo: 'professor' });
  const assistente = await criarUsuario({ tenantId, tipo: 'assistente' });
  return {
    tenantId,
    professor: { id: professor.id, token: (await entrar(professor.email, professor.senha)).tokenAcesso },
    assistente: { id: assistente.id, token: (await entrar(assistente.email, assistente.senha)).tokenAcesso },
  };
}

function chamar(token: string, metodo: string, caminho: string, corpo?: unknown): Promise<Response> {
  return requisitar(
    caminho,
    comToken(token, {
      method: metodo,
      headers: JSON_HEADERS,
      body: corpo === undefined ? undefined : JSON.stringify(corpo),
    }),
  );
}

async function criarTurmaPelaApi(token: string, nome: string, extras: object = {}): Promise<string> {
  const resposta = await chamar(token, 'POST', '/api/turmas', { nome, ...extras });
  expect(resposta.status).toBe(201);
  return (await resposta.json<{ turma: { id: string } }>()).turma.id;
}

async function listarIdsTurmas(token: string): Promise<string[]> {
  const resposta = await chamar(token, 'GET', '/api/turmas');
  expect(resposta.status).toBe(200);
  return (await resposta.json<{ turmas: { id: string }[] }>()).turmas.map((t) => t.id);
}

async function puxar(token: string) {
  const resposta = await chamar(token, 'GET', '/api/sync/pull?desde=0');
  expect(resposta.status).toBe(200);
  return resposta.json<{
    turmas_permitidas: string[];
    turmas: { id: string; regras: typeof REGRAS_PADRAO_TURMA }[];
    quadros_aulas: { turma_id: string; vigencia_inicio: string; vigencia_fim: string | null }[];
  }>();
}

describe('turmas: permissões e isolamento', () => {
  it('exige login e recusa o superadmin', async () => {
    expect((await requisitar('/api/turmas')).status).toBe(401);
    const admin = await criarUsuario({ tenantId: null, tipo: 'superadmin' });
    const { tokenAcesso } = await entrar(admin.email, admin.senha);
    expect((await chamar(tokenAcesso, 'GET', '/api/turmas')).status).toBe(403);
  });

  it('quem cria ganha acesso; a assistente só vê as turmas liberadas e o professor vê todas', async () => {
    const a = await montarAcademia();
    const daAssistente = await criarTurmaPelaApi(a.assistente.token, 'Kids');
    const doProfessor = await criarTurmaPelaApi(a.professor.token, 'Adulto');

    expect(await listarIdsTurmas(a.assistente.token)).toEqual([daAssistente]);
    expect((await listarIdsTurmas(a.professor.token)).sort()).toEqual([daAssistente, doProfessor].sort());
    expect((await chamar(a.assistente.token, 'GET', `/api/turmas/${doProfessor}`)).status).toBe(404);

    const pull = await puxar(a.assistente.token);
    expect(pull.turmas_permitidas).toEqual([daAssistente]);
  });

  it('não lê nem altera turma de outra academia', async () => {
    const a = await montarAcademia('A');
    const b = await montarAcademia('B');
    const turmaB = await criarTurmaPelaApi(b.professor.token, 'Turma B');
    const caminho = `/api/turmas/${turmaB}`;

    expect(await listarIdsTurmas(a.professor.token)).not.toContain(turmaB);
    expect((await chamar(a.professor.token, 'GET', caminho)).status).toBe(404);
    expect((await chamar(a.professor.token, 'PUT', caminho, { nome: 'Invadida' })).status).toBe(404);
    expect((await chamar(a.professor.token, 'DELETE', caminho)).status).toBe(404);
    expect(
      (await chamar(a.professor.token, 'POST', `${caminho}/quadros`, { vigencia_inicio: HOJE, dias: {} }))
        .status,
    ).toBe(404);
    expect(
      (await chamar(a.professor.token, 'PUT', `${caminho}/regras`, { alunos_sumidos: { semanas: 2 } }))
        .status,
    ).toBe(404);
    expect((await chamar(a.professor.token, 'PUT', `${caminho}/acessos`, { usuario_ids: [] })).status).toBe(
      404,
    );

    const turma = await env.DB.prepare('SELECT nome, excluido FROM turmas WHERE id = ?1')
      .bind(turmaB)
      .first();
    expect(turma).toEqual({ nome: 'Turma B', excluido: 0 });
  });
});

describe('turmas: cadastro', () => {
  it('valida os dados e recusa nome repetido na academia, sem diferenciar maiúsculas', async () => {
    const a = await montarAcademia();
    expect((await chamar(a.professor.token, 'POST', '/api/turmas', { nome: '  ' })).status).toBe(400);
    expect(
      (await chamar(a.professor.token, 'POST', '/api/turmas', { nome: 'X', frequencia_minima: 101 })).status,
    ).toBe(400);
    await criarTurmaPelaApi(a.professor.token, 'Adulto');
    const repetida = await chamar(a.professor.token, 'POST', '/api/turmas', { nome: 'adulto' });
    expect(repetida.status).toBe(409);
    expect(await repetida.json()).toEqual({ erro: 'nome_ja_existe' });

    // Outra academia pode ter turma com o mesmo nome.
    const b = await montarAcademia('B');
    await criarTurmaPelaApi(b.professor.token, 'Adulto');
  });

  it('altera, mostra a turma completa e exclui (some do pull de quem acessava)', async () => {
    const a = await montarAcademia();
    const id = await criarTurmaPelaApi(a.assistente.token, 'Kids', { frequencia_minima: 75 });

    const alterada = await chamar(a.assistente.token, 'PUT', `/api/turmas/${id}`, {
      nome: 'Kids 2',
      frequencia_minima: 80,
      cabecalho_impressao: 'Prof. Fulano',
    });
    expect(alterada.status).toBe(200);

    const completa = await (
      await chamar(a.assistente.token, 'GET', `/api/turmas/${id}`)
    ).json<{
      turma: { nome: string; frequencia_minima: number; cabecalho_impressao: string };
      quadros: unknown[];
      regras: unknown;
      acessos: { id: string }[];
    }>();
    expect(completa.turma).toMatchObject({
      nome: 'Kids 2',
      frequencia_minima: 80,
      cabecalho_impressao: 'Prof. Fulano',
    });
    expect(completa.quadros).toEqual([]);
    expect(completa.regras).toEqual(REGRAS_PADRAO_TURMA);
    expect(completa.acessos.map((u) => u.id)).toEqual([a.assistente.id]);

    expect((await chamar(a.assistente.token, 'DELETE', `/api/turmas/${id}`)).status).toBe(204);
    expect(await listarIdsTurmas(a.assistente.token)).toEqual([]);
    expect((await puxar(a.assistente.token)).turmas_permitidas).toEqual([]);
  });
});

describe('turmas: quadro de aulas', () => {
  it('novo quadro encerra o anterior na véspera; mesma data corrige; data anterior é recusada', async () => {
    const a = await montarAcademia();
    const id = await criarTurmaPelaApi(a.professor.token, 'Adulto');
    const caminho = `/api/turmas/${id}/quadros`;
    const inicio = somarDiasNaData(HOJE, -30);

    let resposta = await chamar(a.professor.token, 'POST', caminho, {
      vigencia_inicio: inicio,
      dias: { terca: 1, quarta: 1, quinta: 1 },
    });
    expect(resposta.status).toBe(201);

    resposta = await chamar(a.professor.token, 'POST', caminho, {
      vigencia_inicio: HOJE,
      dias: { terca: 1, quinta: 1, sabado: 2 },
    });
    let quadros = (await resposta.json<{ quadros: Record<string, unknown>[] }>()).quadros;
    expect(quadros).toHaveLength(2);
    expect(quadros[0]).toMatchObject({
      vigencia_inicio: inicio,
      vigencia_fim: somarDiasNaData(HOJE, -1),
      quarta: 1,
    });
    expect(quadros[1]).toMatchObject({ vigencia_inicio: HOJE, vigencia_fim: null, quarta: 0, sabado: 2 });

    resposta = await chamar(a.professor.token, 'POST', caminho, {
      vigencia_inicio: HOJE,
      dias: { segunda: 1 },
    });
    quadros = (await resposta.json<{ quadros: Record<string, unknown>[] }>()).quadros;
    expect(quadros).toHaveLength(2);
    expect(quadros[1]).toMatchObject({ segunda: 1, terca: 0, sabado: 0 });

    resposta = await chamar(a.professor.token, 'POST', caminho, {
      vigencia_inicio: somarDiasNaData(HOJE, -1),
      dias: { segunda: 1 },
    });
    expect(resposta.status).toBe(409);
    expect(await resposta.json()).toEqual({ erro: 'vigencia_anterior_ao_quadro_atual' });

    const pull = await puxar(a.professor.token);
    expect(pull.quadros_aulas.filter((q) => q.turma_id === id)).toHaveLength(2);
  });

  it('recusa data inválida e valor de dia fora de 0, 1 e 2', async () => {
    const a = await montarAcademia();
    const id = await criarTurmaPelaApi(a.professor.token, 'Adulto');
    const caminho = `/api/turmas/${id}/quadros`;
    expect(
      (await chamar(a.professor.token, 'POST', caminho, { vigencia_inicio: '2026-02-30', dias: {} })).status,
    ).toBe(400);
    expect(
      (await chamar(a.professor.token, 'POST', caminho, { vigencia_inicio: HOJE, dias: { segunda: 3 } }))
        .status,
    ).toBe(400);
  });
});

describe('turmas: regras', () => {
  it('grava as regras da turma e o app recebe no pull', async () => {
    const a = await montarAcademia();
    const id = await criarTurmaPelaApi(a.assistente.token, 'Kids');
    expect((await puxar(a.assistente.token)).turmas[0]?.regras).toEqual(REGRAS_PADRAO_TURMA);

    const resposta = await chamar(a.assistente.token, 'PUT', `/api/turmas/${id}/regras`, {
      lista_lancamento: { percentual_minimo: 50, ultimas_aulas: 10 },
    });
    expect(resposta.status).toBe(200);
    const esperado = {
      lista_lancamento: { percentual_minimo: 50, ultimas_aulas: 10 },
      alunos_sumidos: { semanas: 4 },
    };
    expect(await resposta.json()).toEqual({ regras: esperado });

    // Alterar de novo no mesmo dia atualiza a mesma linha.
    await chamar(a.assistente.token, 'PUT', `/api/turmas/${id}/regras`, { alunos_sumidos: { semanas: 6 } });
    const linhas = await env.DB.prepare('SELECT COUNT(*) AS n FROM regras WHERE escopo_id = ?1')
      .bind(id)
      .first();
    expect(linhas).toEqual({ n: 2 });

    const pull = await puxar(a.assistente.token);
    expect(pull.turmas[0]?.regras).toEqual({ ...esperado, alunos_sumidos: { semanas: 6 } });
  });

  it('recusa parâmetros fora dos limites ou corpo sem nenhuma regra', async () => {
    const a = await montarAcademia();
    const id = await criarTurmaPelaApi(a.professor.token, 'Adulto');
    const caminho = `/api/turmas/${id}/regras`;
    expect((await chamar(a.professor.token, 'PUT', caminho, {})).status).toBe(400);
    expect(
      (
        await chamar(a.professor.token, 'PUT', caminho, {
          lista_lancamento: { percentual_minimo: 30, ultimas_aulas: 0 },
        })
      ).status,
    ).toBe(400);
    expect(
      (await chamar(a.professor.token, 'PUT', caminho, { alunos_sumidos: { semanas: 'quatro' } })).status,
    ).toBe(400);
  });
});

describe('turmas: acessos', () => {
  it('só o professor define quem acessa; quem perde o acesso deixa de receber a turma', async () => {
    const a = await montarAcademia();
    const id = await criarTurmaPelaApi(a.professor.token, 'Adulto');
    const caminho = `/api/turmas/${id}/acessos`;

    // A assistente não tem acesso à turma (404) e, mesmo com acesso, não pode alterar acessos (403).
    expect(
      (await chamar(a.assistente.token, 'PUT', caminho, { usuario_ids: [a.assistente.id] })).status,
    ).toBe(403);

    let resposta = await chamar(a.professor.token, 'PUT', caminho, {
      usuario_ids: [a.professor.id, a.assistente.id],
    });
    expect(resposta.status).toBe(200);
    expect((await puxar(a.assistente.token)).turmas_permitidas).toEqual([id]);

    resposta = await chamar(a.professor.token, 'PUT', caminho, { usuario_ids: [a.professor.id] });
    const { acessos } = await resposta.json<{ acessos: { id: string }[] }>();
    expect(acessos.map((u) => u.id)).toEqual([a.professor.id]);
    expect((await puxar(a.assistente.token)).turmas_permitidas).toEqual([]);

    // Pode liberar de novo depois de retirar.
    resposta = await chamar(a.professor.token, 'PUT', caminho, {
      usuario_ids: [a.professor.id, a.assistente.id],
    });
    expect(resposta.status).toBe(200);
    expect((await puxar(a.assistente.token)).turmas_permitidas).toEqual([id]);
  });

  it('recusa usuário de outra academia e o superadmin', async () => {
    const a = await montarAcademia('A');
    const b = await montarAcademia('B');
    const admin = await criarUsuario({ tenantId: null, tipo: 'superadmin' });
    const id = await criarTurmaPelaApi(a.professor.token, 'Adulto');
    const caminho = `/api/turmas/${id}/acessos`;

    for (const intruso of [b.assistente.id, admin.id]) {
      const resposta = await chamar(a.professor.token, 'PUT', caminho, {
        usuario_ids: [a.professor.id, intruso],
      });
      expect(resposta.status).toBe(400);
      expect(await resposta.json()).toEqual({ erro: 'usuario_invalido' });
    }
    const acessos = await env.DB.prepare(
      'SELECT COUNT(*) AS n FROM turma_usuarios WHERE turma_id = ?1 AND excluido = 0',
    )
      .bind(id)
      .first();
    expect(acessos).toEqual({ n: 1 });
  });
});
