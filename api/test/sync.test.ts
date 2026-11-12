import { env } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';
import { gerarIdAulaDoQuadro, obterHojeEmSaoPaulo, obterDiaDaSemana } from '../src/regras/presenca';
import { gerarUuidV7 } from '../src/util/ids';
import { comToken, criarTenant, criarUsuario, entrar, liberarTurma, requisitar } from './apoio';

// Datas relativas a hoje (fuso de São Paulo), para o teste não depender do dia em que roda.
function somarDias(data: string, dias: number): string {
  const [a, m, d] = data.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(a, m - 1, d + dias)).toISOString().slice(0, 10);
}
const HOJE = obterHojeEmSaoPaulo();
const ONTEM = somarDias(HOJE, -1);
const AMANHA = somarDias(HOJE, 1);
const DIA_REPOSICAO = somarDias(HOJE, -2);
const DIA_SEM_AULA = somarDias(HOJE, -3);
const DIAS_COLUNA = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'] as const;

interface Cenario {
  tenantId: string;
  turmaId: string;
  outraTurmaId: string;
  alunoId: string;
  alunoForaId: string;
  token: string;
  usuarioId: string;
}

async function inserir(sql: string, ...valores: unknown[]) {
  await env.DB.prepare(sql)
    .bind(...valores)
    .run();
}

/** Turma com quadro: hoje e ontem regulares, anteontem reposição, 3 dias atrás sem aula. */
async function montarCenario(): Promise<Cenario> {
  const tenantId = await criarTenant();
  const turmaId = gerarUuidV7();
  const outraTurmaId = gerarUuidV7();
  await inserir('INSERT INTO turmas (id, tenant_id, nome) VALUES (?1, ?2, ?3)', turmaId, tenantId, 'Adulto');
  await inserir(
    'INSERT INTO turmas (id, tenant_id, nome) VALUES (?1, ?2, ?3)',
    outraTurmaId,
    tenantId,
    'Kids',
  );

  const dias: Record<string, number> = Object.fromEntries(DIAS_COLUNA.map((d) => [d, 0]));
  dias[obterDiaDaSemana(HOJE)] = 1;
  dias[obterDiaDaSemana(ONTEM)] = 1;
  dias[obterDiaDaSemana(DIA_REPOSICAO)] = 2;
  dias[obterDiaDaSemana(DIA_SEM_AULA)] = 0;
  await inserir(
    `INSERT INTO quadros_aulas (id, tenant_id, turma_id, vigencia_inicio, ${DIAS_COLUNA.join(', ')})
     VALUES (?1, ?2, ?3, ?4, ${DIAS_COLUNA.map((_, i) => `?${i + 5}`).join(', ')})`,
    gerarUuidV7(),
    tenantId,
    turmaId,
    somarDias(HOJE, -60),
    ...DIAS_COLUNA.map((d) => dias[d]),
  );

  const alunoId = gerarUuidV7();
  const alunoForaId = gerarUuidV7();
  await inserir(
    'INSERT INTO alunos (id, tenant_id, codigo, nome, cpf) VALUES (?1, ?2, ?3, ?4, ?5)',
    alunoId,
    tenantId,
    '01',
    'Aluno Matriculado',
    '111.111.111-11',
  );
  await inserir(
    'INSERT INTO alunos (id, tenant_id, codigo, nome) VALUES (?1, ?2, ?3, ?4)',
    alunoForaId,
    tenantId,
    '02',
    'Aluno Sem Matricula',
  );
  await inserir(
    'INSERT INTO matriculas (id, tenant_id, aluno_id, turma_id, data_inicio, server_version) VALUES (?1, ?2, ?3, ?4, ?5, 1)',
    gerarUuidV7(),
    tenantId,
    alunoId,
    turmaId,
    somarDias(HOJE, -30),
  );

  const assistente = await criarUsuario({ tenantId, tipo: 'assistente' });
  await liberarTurma(tenantId, turmaId, assistente.id);
  const { tokenAcesso } = await entrar(assistente.email, assistente.senha);
  return {
    tenantId,
    turmaId,
    outraTurmaId,
    alunoId,
    alunoForaId,
    token: tokenAcesso,
    usuarioId: assistente.id,
  };
}

async function enviar(token: string, operacoes: unknown[]) {
  const resposta = await requisitar(
    '/api/sync/push',
    comToken(token, { method: 'POST', body: JSON.stringify({ operacoes }) }),
  );
  return {
    status: resposta.status,
    corpo: await resposta.json<{ aceitos: string[]; rejeitados: { id: string; erro: string }[] }>(),
  };
}

async function receber(token: string, desde = 0) {
  const resposta = await requisitar(`/api/sync/pull?desde=${desde}`, comToken(token));
  return {
    status: resposta.status,
    corpo: await resposta.json<Record<string, unknown[]> & { cursor: number; turmas_permitidas: string[] }>(),
  };
}

function opAula(
  id: string,
  turmaId: string,
  data: string,
  tipo: 'regular' | 'reposicao',
  updatedAt = new Date().toISOString(),
) {
  return {
    id: `op-${gerarUuidV7()}`,
    tabela: 'aulas',
    registro: { id, turma_id: turmaId, data_aula: data, tipo, excluido: 0, updated_at: updatedAt },
  };
}

function opPresenca(aulaId: string, alunoId: string, excluido: 0 | 1, updatedAt = new Date().toISOString()) {
  return {
    id: `op-${gerarUuidV7()}`,
    tabela: 'presencas',
    registro: { id: gerarUuidV7(), aula_id: aulaId, aluno_id: alunoId, excluido, updated_at: updatedAt },
  };
}

describe('sync: pull', () => {
  let cenario: Cenario;
  beforeAll(async () => {
    cenario = await montarCenario();
  });

  it('devolve só as turmas liberadas e o aluno sem colunas sensíveis', async () => {
    const { status, corpo } = await receber(cenario.token);
    expect(status).toBe(200);
    expect(corpo.turmas_permitidas).toEqual([cenario.turmaId]);
    expect((corpo.turmas as { id: string }[]).map((t) => t.id)).toEqual([cenario.turmaId]);
    const alunos = corpo.alunos as Record<string, unknown>[];
    expect(alunos.map((a) => a.id)).toEqual([cenario.alunoId]);
    expect(Object.keys(alunos[0] ?? {}).sort()).toEqual([
      'ativo',
      'codigo',
      'excluido',
      'id',
      'nome',
      'server_version',
      'updated_at',
    ]);
    expect(corpo.quadros_aulas).toHaveLength(1);
    expect(corpo.matriculas).toHaveLength(1);
  });

  it('recusa cursor inválido e superadmin', async () => {
    expect((await requisitar('/api/sync/pull?desde=-1', comToken(cenario.token))).status).toBe(400);
    const admin = await criarUsuario({ tenantId: null, tipo: 'superadmin' });
    const { tokenAcesso } = await entrar(admin.email, admin.senha);
    expect((await requisitar('/api/sync/pull', comToken(tokenAcesso))).status).toBe(403);
  });

  it('não vaza nada de outra academia', async () => {
    const outra = await montarCenario();
    const { corpo } = await receber(cenario.token);
    const ids = JSON.stringify(corpo);
    expect(ids).not.toContain(outra.turmaId);
    expect(ids).not.toContain(outra.alunoId);
  });
});

describe('sync: push de aulas e presenças', () => {
  let cenario: Cenario;
  beforeAll(async () => {
    cenario = await montarCenario();
  });

  it('aceita aula regular com id determinístico e a presença de aluno matriculado', async () => {
    const aulaId = await gerarIdAulaDoQuadro(cenario.turmaId, HOJE, 'regular');
    const aula = opAula(aulaId, cenario.turmaId, HOJE, 'regular');
    const presenca = opPresenca(aulaId, cenario.alunoId, 0);
    const { status, corpo } = await enviar(cenario.token, [aula, presenca]);
    expect(status).toBe(200);
    expect(corpo.rejeitados).toEqual([]);
    expect(corpo.aceitos.sort()).toEqual([aula.id, presenca.id].sort());

    const gravada = await env.DB.prepare(
      'SELECT created_by, server_version FROM presencas WHERE aula_id = ?1 AND aluno_id = ?2',
    )
      .bind(aulaId, cenario.alunoId)
      .first<{ created_by: string; server_version: number }>();
    expect(gravada?.created_by).toBe(cenario.usuarioId);
    expect(gravada?.server_version).toBeGreaterThan(0);
  });

  it('recusa aula regular com id errado, em dia sem aula, futura ou de turma sem acesso', async () => {
    const idErrado = gerarUuidV7();
    const opIdErrado = opAula(idErrado, cenario.turmaId, ONTEM, 'regular');
    const opDiaSemAula = opAula(
      await gerarIdAulaDoQuadro(cenario.turmaId, DIA_SEM_AULA, 'regular'),
      cenario.turmaId,
      DIA_SEM_AULA,
      'regular',
    );
    const opFutura = opAula(gerarUuidV7(), cenario.turmaId, AMANHA, 'reposicao');
    const opSemAcesso = opAula(gerarUuidV7(), cenario.outraTurmaId, ONTEM, 'reposicao');
    const { corpo } = await enviar(cenario.token, [opIdErrado, opDiaSemAula, opFutura, opSemAcesso]);
    expect(corpo.aceitos).toEqual([]);
    const erros = Object.fromEntries(corpo.rejeitados.map((r) => [r.id, r.erro]));
    expect(erros).toEqual({
      [opIdErrado.id]: 'id_aula_invalido',
      [opDiaSemAula.id]: 'dia_sem_aula_regular',
      [opFutura.id]: 'data_futura',
      [opSemAcesso.id]: 'turma_sem_acesso',
    });
  });

  it('aceita reposição fixa no dia de reposição e avulsa em qualquer dia passado', async () => {
    const fixa = opAula(
      await gerarIdAulaDoQuadro(cenario.turmaId, DIA_REPOSICAO, 'reposicao'),
      cenario.turmaId,
      DIA_REPOSICAO,
      'reposicao',
    );
    const fixaDiaErrado = opAula(
      await gerarIdAulaDoQuadro(cenario.turmaId, DIA_SEM_AULA, 'reposicao'),
      cenario.turmaId,
      DIA_SEM_AULA,
      'reposicao',
    );
    const avulsa = opAula(gerarUuidV7(), cenario.turmaId, DIA_SEM_AULA, 'reposicao');
    const { corpo } = await enviar(cenario.token, [fixa, fixaDiaErrado, avulsa]);
    expect(corpo.aceitos.sort()).toEqual([fixa.id, avulsa.id].sort());
    expect(corpo.rejeitados).toEqual([{ id: fixaDiaErrado.id, erro: 'dia_sem_reposicao_fixa' }]);
  });

  it('recusa presença de aluno fora da matrícula e de aula inexistente', async () => {
    const aulaId = await gerarIdAulaDoQuadro(cenario.turmaId, ONTEM, 'regular');
    const fora = opPresenca(aulaId, cenario.alunoForaId, 0);
    const semAula = opPresenca(gerarUuidV7(), cenario.alunoId, 0);
    const { corpo } = await enviar(cenario.token, [
      opAula(aulaId, cenario.turmaId, ONTEM, 'regular'),
      fora,
      semAula,
    ]);
    const erros = Object.fromEntries(corpo.rejeitados.map((r) => [r.id, r.erro]));
    expect(erros[fora.id]).toBe('fora_da_matricula');
    expect(erros[semAula.id]).toBe('aula_inexistente');
  });

  it('reenvio é idempotente e a última edição vence (desmarcar e remarcar)', async () => {
    const aulaId = await gerarIdAulaDoQuadro(cenario.turmaId, ONTEM, 'regular');
    const base = Date.now();
    const marcar = opPresenca(aulaId, cenario.alunoId, 0, new Date(base).toISOString());
    await enviar(cenario.token, [opAula(aulaId, cenario.turmaId, ONTEM, 'regular'), marcar]);
    expect((await enviar(cenario.token, [marcar])).corpo.aceitos).toEqual([marcar.id]);

    const desmarcar = opPresenca(aulaId, cenario.alunoId, 1, new Date(base + 1000).toISOString());
    await enviar(cenario.token, [desmarcar]);
    // uma edição mais antiga, chegando atrasada de outro aparelho, não desfaz a mais nova
    const atrasada = opPresenca(aulaId, cenario.alunoId, 0, new Date(base + 500).toISOString());
    await enviar(cenario.token, [atrasada]);

    const linhas = await env.DB.prepare('SELECT excluido FROM presencas WHERE aula_id = ?1 AND aluno_id = ?2')
      .bind(aulaId, cenario.alunoId)
      .all<{ excluido: number }>();
    expect(linhas.results).toEqual([{ excluido: 1 }]);
  });

  it('dois aparelhos offline abrindo a mesma aula geram um registro só', async () => {
    const outro = await criarUsuario({ tenantId: cenario.tenantId, tipo: 'professor' });
    await liberarTurma(cenario.tenantId, cenario.turmaId, outro.id);
    const tokenOutro = (await entrar(outro.email, outro.senha)).tokenAcesso;

    const data = DIA_REPOSICAO;
    const idAula = await gerarIdAulaDoQuadro(cenario.turmaId, data, 'reposicao');
    await enviar(cenario.token, [
      opAula(idAula, cenario.turmaId, data, 'reposicao'),
      opPresenca(idAula, cenario.alunoId, 0),
    ]);
    await enviar(tokenOutro, [
      opAula(idAula, cenario.turmaId, data, 'reposicao'),
      opPresenca(idAula, cenario.alunoId, 0),
    ]);

    const aulas = await env.DB.prepare('SELECT COUNT(*) AS n FROM aulas WHERE id = ?1')
      .bind(idAula)
      .first<{ n: number }>();
    const presencas = await env.DB.prepare('SELECT COUNT(*) AS n FROM presencas WHERE aula_id = ?1')
      .bind(idAula)
      .first<{ n: number }>();
    expect(aulas?.n).toBe(1);
    expect(presencas?.n).toBe(1);
  });

  it('pull com cursor devolve só o que mudou depois', async () => {
    const { corpo: inicial } = await receber(cenario.token);
    const aulaId = await gerarIdAulaDoQuadro(cenario.turmaId, HOJE, 'regular');
    await enviar(cenario.token, [opPresenca(aulaId, cenario.alunoId, 1)]);
    const { corpo: depois } = await receber(cenario.token, inicial.cursor);
    expect(depois.cursor).toBeGreaterThan(inicial.cursor);
    expect(depois.presencas).toHaveLength(1);
    expect(depois.turmas).toEqual([]);
  });

  it('recusa corpo inválido, tabela não permitida e lote grande demais', async () => {
    const r = await requisitar('/api/sync/push', comToken(cenario.token, { method: 'POST', body: '{}' }));
    expect(r.status).toBe(400);
    const { corpo } = await enviar(cenario.token, [{ id: 'op-x', tabela: 'alunos', registro: {} }]);
    expect(corpo.rejeitados).toEqual([{ id: 'op-x', erro: 'tabela_nao_permitida' }]);
    const grande = Array.from({ length: 501 }, (_, i) => ({
      id: `op-${i}`,
      tabela: 'presencas',
      registro: {},
    }));
    const r2 = await requisitar(
      '/api/sync/push',
      comToken(cenario.token, { method: 'POST', body: JSON.stringify({ operacoes: grande }) }),
    );
    expect(r2.status).toBe(413);
  });
});
