// Sincronização da presença (online primeiro, offline de reserva). Veja docs/arquitetura/README.md.
//
// GET  /api/sync/pull?desde=<server_version>  → tudo que mudou nas turmas do usuário
// POST /api/sync/push { operacoes: [...] }     → grava aulas e presenças vindas da outbox do app
//
// Para caber no limite de consultas por requisição do D1, as leituras e gravações são feitas em lote
// (json_each), e todas as linhas aceitas num push recebem o mesmo server_version.
import { Hono } from 'hono';
import { autenticar, exigirPermissao } from '../middleware/autenticar';
import { calcularRegrasDaTurma } from '../regras/configuracao-turma';
import {
  calcularTipoDoDia,
  ehDataFutura,
  ehDataValida,
  estaMatriculadoNaData,
  gerarIdAulaDoQuadro,
  obterHojeEmSaoPaulo,
  type QuadroAulas,
} from '../regras/presenca';
import type { Contexto } from '../tipos';
import { responderErro } from '../util/erros';
import { obterAgoraIso } from '../util/tempo';

export const MAXIMO_OPERACOES_POR_PUSH = 500;
const TOLERANCIA_RELOGIO_MS = 5 * 60 * 1000;
const PADRAO_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export const rotasSync = new Hono<Contexto>();
rotasSync.use('*', autenticar, exigirPermissao('lancar_presenca'));

async function obterTurmasPermitidas(db: D1Database, usuarioId: string, tenantId: string): Promise<string[]> {
  const { results } = await db
    .prepare(
      `SELECT tu.turma_id
         FROM turma_usuarios tu
         JOIN turmas t ON t.id = tu.turma_id AND t.tenant_id = tu.tenant_id
        WHERE tu.usuario_id = ?1 AND tu.tenant_id = ?2 AND tu.excluido = 0 AND t.excluido = 0`,
    )
    .bind(usuarioId, tenantId)
    .all<{ turma_id: string }>();
  return results.map((r) => r.turma_id);
}

// ---------------------------------------------------------------------------------------------
// PULL
// ---------------------------------------------------------------------------------------------

/** Parâmetros (JSON) da regra mais recente da turma em vigor hoje (?4). */
function sqlRegraDaTurma(tipo: 'lista_lancamento' | 'alunos_sumidos'): string {
  return `(SELECT r.parametros FROM regras r
            WHERE r.tenant_id = turmas.tenant_id AND r.escopo = 'turma' AND r.escopo_id = turmas.id
              AND r.tipo = '${tipo}' AND r.excluido = 0 AND r.vigencia_inicio <= ?4
            ORDER BY r.vigencia_inicio DESC LIMIT 1)`;
}

interface LinhaTurmaPull {
  lista_lancamento: string | null;
  alunos_sumidos: string | null;
  [coluna: string]: unknown;
}

/** Troca as colunas de regra pelo objeto `regras`, já com os valores padrão. */
function montarTurmaComRegras({ lista_lancamento, alunos_sumidos, ...turma }: LinhaTurmaPull) {
  const gravadas = [
    { tipo: 'lista_lancamento', parametros: lista_lancamento },
    { tipo: 'alunos_sumidos', parametros: alunos_sumidos },
  ].filter((r): r is { tipo: string; parametros: string } => r.parametros !== null);
  return { ...turma, regras: calcularRegrasDaTurma(gravadas) };
}
rotasSync.get('/pull', async (c) => {
  const { id: usuarioId, tenantId } = c.get('usuario');
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');
  const desde = Number(c.req.query('desde') ?? '0');
  if (!Number.isInteger(desde) || desde < 0) return responderErro(c, 400, 'cursor_invalido');

  const db = c.env.DB;
  const turmas = await obterTurmasPermitidas(db, usuarioId, tenantId);
  const lista = JSON.stringify(turmas);
  const naLista = 'IN (SELECT value FROM json_each(?2))';

  const [cursor, rTurmas, rAcessos, rQuadros, rMatriculas, rAlunos, rAulas, rPresencas] = await db.batch([
    db.prepare('SELECT ultima_versao FROM controle_versao WHERE id = 1'),
    db
      .prepare(
        `SELECT id, nome, frequencia_minima, cabecalho_impressao, excluido, updated_at, server_version,
                ${sqlRegraDaTurma('lista_lancamento')} AS lista_lancamento,
                ${sqlRegraDaTurma('alunos_sumidos')} AS alunos_sumidos
           FROM turmas WHERE tenant_id = ?1 AND id ${naLista} AND (?3 = 0 OR server_version > ?3)`,
      )
      .bind(tenantId, lista, desde, obterHojeEmSaoPaulo()),
    db
      .prepare(
        `SELECT id, turma_id, usuario_id, excluido, updated_at, server_version
           FROM turma_usuarios WHERE tenant_id = ?1 AND turma_id ${naLista} AND usuario_id = ?4 AND (?3 = 0 OR server_version > ?3)`,
      )
      .bind(tenantId, lista, desde, usuarioId),
    db
      .prepare(
        `SELECT id, turma_id, vigencia_inicio, vigencia_fim, domingo, segunda, terca, quarta, quinta, sexta, sabado,
                excluido, updated_at, server_version
           FROM quadros_aulas WHERE tenant_id = ?1 AND turma_id ${naLista} AND (?3 = 0 OR server_version > ?3)`,
      )
      .bind(tenantId, lista, desde),
    db
      .prepare(
        `SELECT id, aluno_id, turma_id, data_inicio, data_fim, situacao, excluido, updated_at, server_version
           FROM matriculas WHERE tenant_id = ?1 AND turma_id ${naLista} AND (?3 = 0 OR server_version > ?3)`,
      )
      .bind(tenantId, lista, desde),
    // Só as colunas mínimas do aluno saem do servidor (LGPD).
    db
      .prepare(
        `SELECT DISTINCT a.id, a.codigo, a.nome, a.ativo, a.excluido, a.updated_at, a.server_version
           FROM alunos a
           JOIN matriculas m ON m.aluno_id = a.id AND m.tenant_id = a.tenant_id
          WHERE a.tenant_id = ?1 AND m.turma_id ${naLista}
            AND (?3 = 0 OR a.server_version > ?3 OR m.server_version > ?3)`,
      )
      .bind(tenantId, lista, desde),
    db
      .prepare(
        `SELECT id, turma_id, data_aula, tipo, excluido, updated_at, server_version
           FROM aulas WHERE tenant_id = ?1 AND turma_id ${naLista} AND (?3 = 0 OR server_version > ?3)`,
      )
      .bind(tenantId, lista, desde),
    db
      .prepare(
        `SELECT p.id, p.aula_id, p.aluno_id, p.excluido, p.updated_at, p.updated_by, p.server_version
           FROM presencas p
           JOIN aulas a ON a.id = p.aula_id AND a.tenant_id = p.tenant_id
          WHERE p.tenant_id = ?1 AND a.turma_id ${naLista} AND (?3 = 0 OR p.server_version > ?3)`,
      )
      .bind(tenantId, lista, desde),
  ]);

  return c.json({
    cursor: (cursor?.results[0] as { ultima_versao: number } | undefined)?.ultima_versao ?? 0,
    // desde=0 devolve tudo (primeira carga). Se a lista de turmas mudar, o app apaga o que não está aqui e refaz o pull desde 0.
    turmas_permitidas: turmas,
    turmas: ((rTurmas?.results ?? []) as LinhaTurmaPull[]).map(montarTurmaComRegras),
    turma_usuarios: rAcessos?.results ?? [],
    quadros_aulas: rQuadros?.results ?? [],
    matriculas: rMatriculas?.results ?? [],
    alunos: rAlunos?.results ?? [],
    aulas: rAulas?.results ?? [],
    presencas: rPresencas?.results ?? [],
  });
});

// ---------------------------------------------------------------------------------------------
// PUSH
// ---------------------------------------------------------------------------------------------
interface OperacaoAula {
  id: string;
  turma_id: string;
  data_aula: string;
  tipo: 'regular' | 'reposicao';
  excluido: 0 | 1;
  updated_at: string;
}

interface OperacaoPresenca {
  id: string;
  aula_id: string;
  aluno_id: string;
  excluido: 0 | 1;
  updated_at: string;
}

type Rejeicao = { id: string; erro: string };

function ehUuid(valor: unknown): valor is string {
  return typeof valor === 'string' && PADRAO_UUID.test(valor);
}

/** Normaliza o updated_at do aparelho: precisa ser ISO; se estiver no futuro além da tolerância, vira agora. */
function normalizarAtualizadoEm(valor: unknown, agora: number): string | null {
  if (typeof valor !== 'string') return null;
  const instante = Date.parse(valor);
  if (Number.isNaN(instante)) return null;
  return new Date(Math.min(instante, agora + TOLERANCIA_RELOGIO_MS)).toISOString();
}

function lerOperacaoAula(registro: Record<string, unknown>, agora: number): OperacaoAula | null {
  const atualizadoEm = normalizarAtualizadoEm(registro.updated_at, agora);
  if (
    !ehUuid(registro.id) ||
    !ehUuid(registro.turma_id) ||
    !ehDataValida(registro.data_aula) ||
    (registro.tipo !== 'regular' && registro.tipo !== 'reposicao') ||
    (registro.excluido !== 0 && registro.excluido !== 1) ||
    !atualizadoEm
  ) {
    return null;
  }
  return {
    id: registro.id,
    turma_id: registro.turma_id,
    data_aula: registro.data_aula,
    tipo: registro.tipo,
    excluido: registro.excluido,
    updated_at: atualizadoEm,
  };
}

function lerOperacaoPresenca(registro: Record<string, unknown>, agora: number): OperacaoPresenca | null {
  const atualizadoEm = normalizarAtualizadoEm(registro.updated_at, agora);
  if (
    !ehUuid(registro.id) ||
    !ehUuid(registro.aula_id) ||
    !ehUuid(registro.aluno_id) ||
    (registro.excluido !== 0 && registro.excluido !== 1) ||
    !atualizadoEm
  ) {
    return null;
  }
  return {
    id: registro.id,
    aula_id: registro.aula_id,
    aluno_id: registro.aluno_id,
    excluido: registro.excluido,
    updated_at: atualizadoEm,
  };
}

interface LinhaQuadro {
  turma_id: string;
  vigencia_inicio: string;
  vigencia_fim: string | null;
  domingo: number;
  segunda: number;
  terca: number;
  quarta: number;
  quinta: number;
  sexta: number;
  sabado: number;
}

function agruparQuadrosPorTurma(linhas: LinhaQuadro[]): Map<string, QuadroAulas[]> {
  const mapa = new Map<string, QuadroAulas[]>();
  for (const l of linhas) {
    const lista = mapa.get(l.turma_id) ?? [];
    lista.push({
      vigencia_inicio: l.vigencia_inicio,
      vigencia_fim: l.vigencia_fim,
      dias: {
        domingo: l.domingo,
        segunda: l.segunda,
        terca: l.terca,
        quarta: l.quarta,
        quinta: l.quinta,
        sexta: l.sexta,
        sabado: l.sabado,
      },
    });
    mapa.set(l.turma_id, lista);
  }
  return mapa;
}

async function validarAula(
  aula: OperacaoAula,
  turmasPermitidas: Set<string>,
  quadros: Map<string, QuadroAulas[]>,
  hoje: string,
): Promise<string | null> {
  if (!turmasPermitidas.has(aula.turma_id)) return 'turma_sem_acesso';
  if (ehDataFutura(aula.data_aula, hoje)) return 'data_futura';
  const tipoDoDia = calcularTipoDoDia(aula.data_aula, quadros.get(aula.turma_id) ?? []);
  if (aula.tipo === 'regular') {
    if (tipoDoDia !== 'regular') return 'dia_sem_aula_regular';
    if (aula.id !== (await gerarIdAulaDoQuadro(aula.turma_id, aula.data_aula, 'regular')))
      return 'id_aula_invalido';
    return null;
  }
  // Reposição: a fixa (dia "reposição" do quadro) tem id determinístico; a avulsa pode ser em qualquer dia.
  const idReposicaoFixa = await gerarIdAulaDoQuadro(aula.turma_id, aula.data_aula, 'reposicao');
  if (aula.id === idReposicaoFixa && tipoDoDia !== 'reposicao') return 'dia_sem_reposicao_fixa';
  return null;
}

rotasSync.post('/push', async (c) => {
  const { id: usuarioId, tenantId } = c.get('usuario');
  if (!tenantId) return responderErro(c, 403, 'sem_permissao');

  const corpo = await c.req.json().catch(() => null);
  const operacoes: unknown = corpo?.operacoes;
  if (!Array.isArray(operacoes)) return responderErro(c, 400, 'dados_invalidos');
  if (operacoes.length > MAXIMO_OPERACOES_POR_PUSH) return responderErro(c, 413, 'operacoes_demais');

  const agora = Date.now();
  const hoje = obterHojeEmSaoPaulo(new Date(agora));
  const rejeitados: Rejeicao[] = [];
  const aulasLidas: { opId: string; aula: OperacaoAula }[] = [];
  const presencasLidas: { opId: string; presenca: OperacaoPresenca }[] = [];

  for (const bruta of operacoes) {
    const op = bruta as { id?: unknown; tabela?: unknown; registro?: unknown };
    const opId = typeof op?.id === 'string' ? op.id : '';
    const registro = (typeof op?.registro === 'object' && op.registro !== null ? op.registro : {}) as Record<
      string,
      unknown
    >;
    if (!opId) continue;
    if (op.tabela === 'aulas') {
      const aula = lerOperacaoAula(registro, agora);
      if (aula) aulasLidas.push({ opId, aula });
      else rejeitados.push({ id: opId, erro: 'dados_invalidos' });
    } else if (op.tabela === 'presencas') {
      const presenca = lerOperacaoPresenca(registro, agora);
      if (presenca) presencasLidas.push({ opId, presenca });
      else rejeitados.push({ id: opId, erro: 'dados_invalidos' });
    } else {
      rejeitados.push({ id: opId, erro: 'tabela_nao_permitida' });
    }
  }

  const db = c.env.DB;
  const turmasPermitidas = new Set(await obterTurmasPermitidas(db, usuarioId, tenantId));
  const listaTurmas = JSON.stringify([...turmasPermitidas]);
  const idsAulasDasPresencas = JSON.stringify([...new Set(presencasLidas.map((p) => p.presenca.aula_id))]);
  const idsAlunos = JSON.stringify([...new Set(presencasLidas.map((p) => p.presenca.aluno_id))]);

  const [rQuadros, rAulasExistentes, rMatriculas] = await db.batch([
    db
      .prepare(
        `SELECT turma_id, vigencia_inicio, vigencia_fim, domingo, segunda, terca, quarta, quinta, sexta, sabado
           FROM quadros_aulas
          WHERE tenant_id = ?1 AND excluido = 0 AND turma_id IN (SELECT value FROM json_each(?2))`,
      )
      .bind(tenantId, listaTurmas),
    db
      .prepare(
        `SELECT id, turma_id, data_aula, excluido FROM aulas
          WHERE tenant_id = ?1 AND id IN (SELECT value FROM json_each(?2))`,
      )
      .bind(tenantId, idsAulasDasPresencas),
    db
      .prepare(
        `SELECT aluno_id, turma_id, data_inicio, data_fim FROM matriculas
          WHERE tenant_id = ?1 AND excluido = 0 AND aluno_id IN (SELECT value FROM json_each(?2))`,
      )
      .bind(tenantId, idsAlunos),
  ]);

  const quadros = agruparQuadrosPorTurma((rQuadros?.results ?? []) as unknown as LinhaQuadro[]);

  // Aulas
  const aulasAceitas: { opId: string; aula: OperacaoAula }[] = [];
  for (const item of aulasLidas) {
    const erro = await validarAula(item.aula, turmasPermitidas, quadros, hoje);
    if (erro) rejeitados.push({ id: item.opId, erro });
    else aulasAceitas.push(item);
  }

  // Presenças: a aula pode já existir no servidor ou ter sido aceita neste mesmo push.
  const aulasConhecidas = new Map<string, { turma_id: string; data_aula: string; excluido: number }>();
  for (const a of (rAulasExistentes?.results ?? []) as {
    id: string;
    turma_id: string;
    data_aula: string;
    excluido: number;
  }[]) {
    aulasConhecidas.set(a.id, a);
  }
  for (const { aula } of aulasAceitas) aulasConhecidas.set(aula.id, aula);

  const matriculas = (rMatriculas?.results ?? []) as {
    aluno_id: string;
    turma_id: string;
    data_inicio: string;
    data_fim: string | null;
  }[];

  const presencasAceitas: { opId: string; presenca: OperacaoPresenca }[] = [];
  for (const item of presencasLidas) {
    const { presenca } = item;
    const aula = aulasConhecidas.get(presenca.aula_id);
    let erro: string | null = null;
    if (!aula) erro = 'aula_inexistente';
    else if (!turmasPermitidas.has(aula.turma_id)) erro = 'turma_sem_acesso';
    else if (ehDataFutura(aula.data_aula, hoje)) erro = 'data_futura';
    else if (presenca.excluido === 0 && aula.excluido === 1) erro = 'aula_excluida';
    else if (
      presenca.excluido === 0 &&
      !matriculas.some(
        (m) =>
          m.aluno_id === presenca.aluno_id &&
          m.turma_id === aula.turma_id &&
          estaMatriculadoNaData(aula.data_aula, m),
      )
    ) {
      erro = 'fora_da_matricula';
    }
    if (erro) rejeitados.push({ id: item.opId, erro });
    else presencasAceitas.push(item);
  }

  if (aulasAceitas.length > 0 || presencasAceitas.length > 0) {
    const gravadoEm = obterAgoraIso(new Date(agora));
    const versao = '(SELECT ultima_versao FROM controle_versao WHERE id = 1)';
    const comandos: D1PreparedStatement[] = [
      db.prepare('UPDATE controle_versao SET ultima_versao = ultima_versao + 1 WHERE id = 1'),
    ];
    if (aulasAceitas.length > 0) {
      comandos.push(
        db
          .prepare(
            `INSERT INTO aulas (id, tenant_id, turma_id, data_aula, tipo, excluido, created_at, updated_at,
                                server_version, created_by, updated_by)
             SELECT json_extract(value, '$.id'), ?1, json_extract(value, '$.turma_id'),
                    json_extract(value, '$.data_aula'), json_extract(value, '$.tipo'),
                    json_extract(value, '$.excluido'), ?2, json_extract(value, '$.updated_at'),
                    ${versao}, ?3, ?3
               FROM json_each(?4) WHERE true
             ON CONFLICT (id) DO UPDATE SET
                    excluido = excluded.excluido, updated_at = excluded.updated_at,
                    server_version = excluded.server_version, updated_by = excluded.updated_by
              WHERE excluded.updated_at > aulas.updated_at AND aulas.tenant_id = excluded.tenant_id`,
          )
          .bind(tenantId, gravadoEm, usuarioId, JSON.stringify(aulasAceitas.map((a) => a.aula))),
      );
    }
    if (presencasAceitas.length > 0) {
      comandos.push(
        db
          .prepare(
            `INSERT INTO presencas (id, tenant_id, aula_id, aluno_id, excluido, created_at, updated_at,
                                    server_version, created_by, updated_by)
             SELECT json_extract(value, '$.id'), ?1, json_extract(value, '$.aula_id'),
                    json_extract(value, '$.aluno_id'), json_extract(value, '$.excluido'), ?2,
                    json_extract(value, '$.updated_at'), ${versao}, ?3, ?3
               FROM json_each(?4) WHERE true
             ON CONFLICT (aula_id, aluno_id) DO UPDATE SET
                    excluido = excluded.excluido, updated_at = excluded.updated_at,
                    server_version = excluded.server_version, updated_by = excluded.updated_by
              WHERE excluded.updated_at > presencas.updated_at
             ON CONFLICT DO NOTHING`,
          )
          .bind(tenantId, gravadoEm, usuarioId, JSON.stringify(presencasAceitas.map((p) => p.presenca))),
      );
    }
    await db.batch(comandos);
  }

  return c.json({
    aceitos: [...aulasAceitas, ...presencasAceitas].map((a) => a.opId),
    rejeitados,
  });
});
