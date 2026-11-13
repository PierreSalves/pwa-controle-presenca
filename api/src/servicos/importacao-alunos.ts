// Importação da lista de alunos das planilhas (código + nome). Usada pela academia
// (POST /api/alunos/importacao) e, na carga inicial, pelo administrador do sistema.
import {
  calcularRelatorioImportacao,
  normalizarCodigoImportado,
  type LinhaImportacao,
  type RelatorioImportacao,
} from '../regras/alunos';
import { gerarUuidV7 } from '../util/ids';
import { obterAgoraIso } from '../util/tempo';
import { prepararIncrementoVersao, SQL_VERSAO_ATUAL } from '../util/versao';

export const MAXIMO_LINHAS_IMPORTACAO = 2000;

export type ResultadoImportacao =
  | { tipo: 'dados_invalidos' }
  | { tipo: 'relatorio'; relatorio: RelatorioImportacao }
  | { tipo: 'importado'; relatorio: RelatorioImportacao; importados: number };

/** Lê as linhas enviadas pelo app: [{ codigo, nome }], numeradas a partir de 1. */
export function lerLinhasImportacao(valor: unknown): LinhaImportacao[] | null {
  if (!Array.isArray(valor) || valor.length === 0 || valor.length > MAXIMO_LINHAS_IMPORTACAO) return null;
  const linhas: LinhaImportacao[] = [];
  for (const [indice, item] of valor.entries()) {
    const dados = (typeof item === 'object' && item !== null ? item : {}) as Record<string, unknown>;
    const codigo = typeof dados.codigo === 'string' ? normalizarCodigoImportado(dados.codigo) : '';
    const nome = typeof dados.nome === 'string' ? dados.nome.trim().replace(/\s+/g, ' ') : '';
    if (codigo.length > 20 || nome.length > 120) return null;
    linhas.push({ linha: indice + 1, codigo, nome });
  }
  return linhas;
}

/**
 * Sem `confirmar`, só devolve o relatório. Com `confirmar: true`, grava se o relatório permitir;
 * caso contrário devolve o relatório sem gravar nada.
 */
export async function importarAlunos(
  db: D1Database,
  tenantId: string,
  usuarioId: string,
  corpo: Record<string, unknown> | null,
): Promise<ResultadoImportacao> {
  const linhas = lerLinhasImportacao(corpo?.alunos);
  if (!linhas) return { tipo: 'dados_invalidos' };

  const { results: existentes } = await db
    .prepare('SELECT codigo, nome FROM alunos WHERE tenant_id = ?1 AND excluido = 0')
    .bind(tenantId)
    .all<{ codigo: string; nome: string }>();
  const relatorio = calcularRelatorioImportacao(linhas, existentes);
  if (corpo?.confirmar !== true || !relatorio.pode_importar) return { tipo: 'relatorio', relatorio };

  const agora = obterAgoraIso();
  const novos = linhas.map((l) => ({ id: gerarUuidV7(), codigo: l.codigo, nome: l.nome }));
  await db.batch([
    prepararIncrementoVersao(db),
    db
      .prepare(
        `INSERT INTO alunos (id, tenant_id, codigo, nome, created_at, updated_at, server_version, created_by, updated_by)
         SELECT json_extract(value, '$.id'), ?1, json_extract(value, '$.codigo'), json_extract(value, '$.nome'),
                ?2, ?2, ${SQL_VERSAO_ATUAL}, ?3, ?3
           FROM json_each(?4)`,
      )
      .bind(tenantId, agora, usuarioId, JSON.stringify(novos)),
  ]);
  return { tipo: 'importado', relatorio, importados: novos.length };
}
