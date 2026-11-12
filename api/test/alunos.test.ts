import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { obterHojeEmSaoPaulo } from '../src/regras/presenca';
import { somarDiasNaData } from '../src/util/datas';
import { comToken, criarTenant, criarUsuario, entrar, requisitar } from './apoio';

const HOJE = obterHojeEmSaoPaulo();

interface Academia {
  tenantId: string;
  professor: string;
  assistente: { id: string; token: string };
}

async function montarAcademia(nome = 'Academia'): Promise<Academia> {
  const tenantId = await criarTenant(nome);
  const professor = await criarUsuario({ tenantId, tipo: 'professor' });
  const assistente = await criarUsuario({ tenantId, tipo: 'assistente' });
  return {
    tenantId,
    professor: (await entrar(professor.email, professor.senha)).tokenAcesso,
    assistente: { id: assistente.id, token: (await entrar(assistente.email, assistente.senha)).tokenAcesso },
  };
}

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

async function criarAluno(token: string, codigo: string, nome: string, extras: object = {}): Promise<string> {
  const resposta = await chamar(token, 'POST', '/api/alunos', { codigo, nome, ...extras });
  expect(resposta.status).toBe(201);
  return (await resposta.json<{ aluno: { id: string } }>()).aluno.id;
}

async function criarTurma(token: string, nome: string): Promise<string> {
  const resposta = await chamar(token, 'POST', '/api/turmas', { nome });
  expect(resposta.status).toBe(201);
  return (await resposta.json<{ turma: { id: string } }>()).turma.id;
}

describe('alunos: cadastro', () => {
  it('cria, busca, altera e exclui; o código é único na academia sem diferenciar maiúsculas', async () => {
    const a = await montarAcademia();
    const id = await criarAluno(a.assistente.token, '10A', 'Ana Souza', { cpf: '111.111.111-11' });
    await criarAluno(a.assistente.token, '11', 'Bruno Lima');

    const repetido = await chamar(a.assistente.token, 'POST', '/api/alunos', {
      codigo: '10a',
      nome: 'Outra',
    });
    expect(repetido.status).toBe(409);
    expect(await repetido.json()).toEqual({ erro: 'codigo_ja_existe' });

    const busca = await chamar(a.assistente.token, 'GET', '/api/alunos?busca=souza');
    expect((await busca.json<{ alunos: { id: string }[] }>()).alunos.map((x) => x.id)).toEqual([id]);
    const porCodigo = await chamar(a.assistente.token, 'GET', '/api/alunos?busca=10a');
    expect((await porCodigo.json<{ alunos: unknown[] }>()).alunos).toHaveLength(1);

    const alterado = await chamar(a.assistente.token, 'PUT', `/api/alunos/${id}`, {
      codigo: '10A',
      nome: 'Ana Souza Lima',
      telefone: '(11) 99999-0000',
      data_nascimento: '2015-03-20',
    });
    expect(alterado.status).toBe(200);
    const corpo = await alterado.json<{ aluno: Record<string, unknown> }>();
    expect(corpo.aluno).toMatchObject({ nome: 'Ana Souza Lima', telefone: '(11) 99999-0000', cpf: null });

    expect((await chamar(a.assistente.token, 'DELETE', `/api/alunos/${id}`)).status).toBe(204);
    expect((await chamar(a.assistente.token, 'GET', `/api/alunos/${id}`)).status).toBe(404);
    // O código fica livre de novo.
    await criarAluno(a.assistente.token, '10A', 'Nova Ana');
  });

  it('sugere o próximo código numérico livre', async () => {
    const a = await montarAcademia();
    await criarAluno(a.professor, '09', 'Ana');
    await criarAluno(a.professor, '10A', 'Bruno');
    const resposta = await chamar(a.professor, 'GET', '/api/alunos/proximo-codigo');
    expect(await resposta.json()).toEqual({ codigo: '10' });
  });

  it('valida os dados', async () => {
    const a = await montarAcademia();
    for (const corpo of [
      { codigo: '', nome: 'Ana' },
      { codigo: '1', nome: '   ' },
      { codigo: '1', nome: 'Ana', data_nascimento: '20/03/2015' },
      { codigo: '1', nome: 'Ana', ativo: 2 },
      { codigo: '1', nome: 'Ana', cpf: 123 },
    ]) {
      expect((await chamar(a.professor, 'POST', '/api/alunos', corpo)).status).toBe(400);
    }
  });

  it('isola as academias e recusa o superadmin', async () => {
    const a = await montarAcademia('A');
    const b = await montarAcademia('B');
    const idB = await criarAluno(b.professor, '1', 'Aluno de B', { cpf: '222' });

    expect(
      (await (await chamar(a.professor, 'GET', '/api/alunos')).json<{ alunos: unknown[] }>()).alunos,
    ).toEqual([]);
    expect((await chamar(a.professor, 'GET', `/api/alunos/${idB}`)).status).toBe(404);
    expect((await chamar(a.professor, 'PUT', `/api/alunos/${idB}`, { codigo: '1', nome: 'X' })).status).toBe(
      404,
    );
    expect((await chamar(a.professor, 'DELETE', `/api/alunos/${idB}`)).status).toBe(404);
    expect(
      (
        await chamar(a.professor, 'POST', `/api/alunos/${idB}/graduacoes`, {
          faixa: 'Azul',
          data_graduacao: HOJE,
        })
      ).status,
    ).toBe(404);
    // Mesmo código em outra academia é permitido.
    await criarAluno(a.professor, '1', 'Aluno de A');

    const admin = await criarUsuario({ tenantId: null, tipo: 'superadmin' });
    const { tokenAcesso } = await entrar(admin.email, admin.senha);
    expect((await chamar(tokenAcesso, 'GET', '/api/alunos')).status).toBe(403);
  });

  it('registra e exclui graduações', async () => {
    const a = await montarAcademia();
    const id = await criarAluno(a.professor, '1', 'Ana');
    const resposta = await chamar(a.professor, 'POST', `/api/alunos/${id}/graduacoes`, {
      faixa: 'Cinza',
      grau: 2,
      data_graduacao: '2026-06-05',
    });
    expect(resposta.status).toBe(201);
    const { graduacoes } = await resposta.json<{
      graduacoes: { id: string; faixa: string; grau: number }[];
    }>();
    expect(graduacoes).toMatchObject([{ faixa: 'Cinza', grau: 2 }]);
    const caminho = `/api/alunos/${id}/graduacoes/${graduacoes[0]?.id}`;
    expect((await chamar(a.professor, 'DELETE', caminho)).status).toBe(204);
    expect((await chamar(a.professor, 'DELETE', caminho)).status).toBe(404);
  });
});

describe('alunos: importação', () => {
  it('mostra o relatório sem gravar e só grava com confirmação e sem códigos duplicados', async () => {
    const a = await montarAcademia();
    await criarAluno(a.professor, '20', 'Carla');

    const comProblema = {
      alunos: [
        { codigo: '(10A)', nome: 'Ana' },
        { codigo: '10a', nome: 'Bruno' },
        { codigo: '20', nome: 'Carla' },
      ],
    };
    let resposta = await chamar(a.professor, 'POST', '/api/alunos/importacao', {
      ...comProblema,
      confirmar: true,
    });
    expect(resposta.status).toBe(200);
    const { relatorio, importados } = await resposta.json<{
      relatorio: Record<string, unknown>;
      importados: number;
    }>();
    expect(importados).toBe(0);
    expect(relatorio).toMatchObject({
      pode_importar: false,
      codigos_repetidos: [{ codigo: '10A', linhas: [1, 2] }],
      codigos_existentes: [{ codigo: '20', linha: 3 }],
    });

    const valido = {
      alunos: [
        { codigo: '(10A)', nome: 'Ana' },
        { codigo: '11', nome: '  Bruno   Lima ' },
      ],
    };
    resposta = await chamar(a.professor, 'POST', '/api/alunos/importacao', valido);
    expect(await resposta.json()).toMatchObject({ importados: 0, relatorio: { pode_importar: true } });

    resposta = await chamar(a.professor, 'POST', '/api/alunos/importacao', { ...valido, confirmar: true });
    expect(resposta.status).toBe(201);
    expect(await resposta.json()).toMatchObject({ importados: 2 });
    const gravados = await env.DB.prepare(
      'SELECT codigo, nome FROM alunos WHERE tenant_id = ?1 ORDER BY codigo',
    )
      .bind(a.tenantId)
      .all();
    expect(gravados.results).toEqual([
      { codigo: '10A', nome: 'Ana' },
      { codigo: '11', nome: 'Bruno Lima' },
      { codigo: '20', nome: 'Carla' },
    ]);
  });

  it('recusa lista vazia ou que não é lista', async () => {
    const a = await montarAcademia();
    expect((await chamar(a.professor, 'POST', '/api/alunos/importacao', { alunos: [] })).status).toBe(400);
    expect((await chamar(a.professor, 'POST', '/api/alunos/importacao', { alunos: 'x' })).status).toBe(400);
  });
});

describe('matrículas', () => {
  it('matricula, encerra e o app recebe aluno e matrícula no pull (sem dados sensíveis)', async () => {
    const a = await montarAcademia();
    const turmaId = await criarTurma(a.assistente.token, 'Kids');
    const alunoId = await criarAluno(a.assistente.token, '1', 'Ana', { cpf: '111.111.111-11' });
    const inicio = somarDiasNaData(HOJE, -60);

    let resposta = await chamar(a.assistente.token, 'POST', '/api/matriculas', {
      aluno_id: alunoId,
      turma_id: turmaId,
      data_inicio: inicio,
    });
    expect(resposta.status).toBe(201);
    const { matricula } = await resposta.json<{ matricula: { id: string; situacao: string } }>();
    expect(matricula).toMatchObject({ situacao: 'matriculado', turma_nome: 'Kids' });

    const pull = await (
      await chamar(a.assistente.token, 'GET', '/api/sync/pull?desde=0')
    ).json<{
      alunos: Record<string, unknown>[];
      matriculas: { id: string }[];
    }>();
    expect(pull.matriculas.map((m) => m.id)).toEqual([matricula.id]);
    expect(pull.alunos).toHaveLength(1);
    expect(pull.alunos[0]).not.toHaveProperty('cpf');

    const fim = somarDiasNaData(HOJE, -10);
    resposta = await chamar(a.assistente.token, 'PUT', `/api/matriculas/${matricula.id}`, {
      data_inicio: inicio,
      data_fim: fim,
    });
    expect(resposta.status).toBe(200);
    expect(await resposta.json()).toMatchObject({ matricula: { data_fim: fim, situacao: 'encerrado' } });

    // Depois de encerrada, pode rematricular a partir do dia seguinte ao fim.
    resposta = await chamar(a.assistente.token, 'POST', '/api/matriculas', {
      aluno_id: alunoId,
      turma_id: turmaId,
      data_inicio: fim,
    });
    expect(resposta.status).toBe(409);
    expect(await resposta.json()).toEqual({ erro: 'matricula_sobreposta' });
    resposta = await chamar(a.assistente.token, 'POST', '/api/matriculas', {
      aluno_id: alunoId,
      turma_id: turmaId,
      data_inicio: somarDiasNaData(fim, 1),
    });
    expect(resposta.status).toBe(201);

    const completo = await (
      await chamar(a.assistente.token, 'GET', `/api/alunos/${alunoId}`)
    ).json<{
      matriculas: unknown[];
    }>();
    expect(completo.matriculas).toHaveLength(2);
  });

  it('valida período e situação', async () => {
    const a = await montarAcademia();
    const turmaId = await criarTurma(a.professor, 'Adulto');
    const alunoId = await criarAluno(a.professor, '1', 'Ana');
    for (const extra of [
      { data_inicio: '2026-13-01' },
      { data_inicio: '2026-05-10', data_fim: '2026-05-09' },
      { data_inicio: '2026-05-10', situacao: 'trancado' },
    ]) {
      const resposta = await chamar(a.professor, 'POST', '/api/matriculas', {
        aluno_id: alunoId,
        turma_id: turmaId,
        ...extra,
      });
      expect(resposta.status).toBe(400);
    }
  });

  it('exige acesso à turma e isola as academias', async () => {
    const a = await montarAcademia('A');
    const b = await montarAcademia('B');
    const turmaDoProfessor = await criarTurma(a.professor, 'Adulto');
    const alunoA = await criarAluno(a.professor, '1', 'Ana');
    const alunoB = await criarAluno(b.professor, '1', 'Bia');
    const turmaB = await criarTurma(b.professor, 'Turma B');

    // A assistente não acessa a turma criada pelo professor.
    let resposta = await chamar(a.assistente.token, 'POST', '/api/matriculas', {
      aluno_id: alunoA,
      turma_id: turmaDoProfessor,
      data_inicio: HOJE,
    });
    expect(resposta.status).toBe(404);

    resposta = await chamar(a.professor, 'POST', '/api/matriculas', {
      aluno_id: alunoB,
      turma_id: turmaDoProfessor,
      data_inicio: HOJE,
    });
    expect(await resposta.json()).toEqual({ erro: 'aluno_nao_encontrado' });
    resposta = await chamar(a.professor, 'POST', '/api/matriculas', {
      aluno_id: alunoA,
      turma_id: turmaB,
      data_inicio: HOJE,
    });
    expect(await resposta.json()).toEqual({ erro: 'turma_nao_encontrada' });

    resposta = await chamar(b.professor, 'POST', '/api/matriculas', {
      aluno_id: alunoB,
      turma_id: turmaB,
      data_inicio: HOJE,
    });
    const { matricula } = await resposta.json<{ matricula: { id: string } }>();
    expect(
      (await chamar(a.professor, 'PUT', `/api/matriculas/${matricula.id}`, { data_inicio: HOJE })).status,
    ).toBe(404);
    expect((await chamar(a.professor, 'DELETE', `/api/matriculas/${matricula.id}`)).status).toBe(404);
    expect((await chamar(b.professor, 'DELETE', `/api/matriculas/${matricula.id}`)).status).toBe(204);
  });
});
