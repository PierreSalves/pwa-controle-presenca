// server_version: cursor do pull da sincronização (docs/arquitetura/README.md).
// Toda gravação numa tabela sincronizada roda num batch que começa incrementando o contador;
// as linhas gravadas no mesmo batch usam SQL_VERSAO_ATUAL e recebem o mesmo número.

export const SQL_VERSAO_ATUAL = '(SELECT ultima_versao FROM controle_versao WHERE id = 1)';

export function prepararIncrementoVersao(db: D1Database): D1PreparedStatement {
  return db.prepare('UPDATE controle_versao SET ultima_versao = ultima_versao + 1 WHERE id = 1');
}
