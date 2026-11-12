// Testes das migrações SQL com o SQLite embutido no Node (node:sqlite).
// Rodar: node --test db/
import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readdirSync, readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const pastaMigracoes = join(dirname(fileURLToPath(import.meta.url)), '..', 'migrations');

function criarBancoMigrado() {
  const banco = new DatabaseSync(':memory:');
  banco.exec('PRAGMA foreign_keys = ON;'); // o D1 aplica FKs por padrão; aqui ligamos à mão
  const arquivos = readdirSync(pastaMigracoes).filter((f) => f.endsWith('.sql')).sort();
  for (const arquivo of arquivos) {
    banco.exec(readFileSync(join(pastaMigracoes, arquivo), 'utf8'));
  }
  return banco;
}

function inserir(banco, tabela, dados) {
  const colunas = Object.keys(dados);
  const sql = `INSERT INTO ${tabela} (${colunas.join(', ')}) VALUES (${colunas.map(() => '?').join(', ')})`;
  return banco.prepare(sql).run(...Object.values(dados));
}

describe('migrações', () => {
  test('aplicam do zero sem erro, em ordem', () => {
    const banco = criarBancoMigrado();
    const tabelas = banco
      .prepare("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name")
      .all()
      .map((t) => t.name);
    for (const esperada of [
      'alunos', 'aulas', 'controle_versao', 'graduacoes', 'matriculas', 'presencas',
      'quadros_aulas', 'regras', 'sessoes', 'tenants', 'turma_usuarios', 'turmas', 'usuarios',
    ]) {
      assert.ok(tabelas.includes(esperada), `tabela ${esperada} não foi criada`);
    }
  });

  test('0002 preserva os quadros de aulas já cadastrados', () => {
    const banco = new DatabaseSync(':memory:');
    banco.exec('PRAGMA foreign_keys = ON;');
    banco.exec(readFileSync(join(pastaMigracoes, '0001_inicial.sql'), 'utf8'));
    inserir(banco, 'tenants', { id: 't1', nome: 'Academia' });
    inserir(banco, 'turmas', { id: 'tu1', tenant_id: 't1', nome: 'Adulto' });
    inserir(banco, 'quadros_aulas', {
      id: 'q1', tenant_id: 't1', turma_id: 'tu1', vigencia_inicio: '2026-02-01', terca: 1, quinta: 1, server_version: 7,
    });
    banco.exec(readFileSync(join(pastaMigracoes, '0002_quadro_reposicao_e_identidade.sql'), 'utf8'));
    const quadro = banco.prepare("SELECT terca, quinta, sabado, server_version FROM quadros_aulas WHERE id = 'q1'").get();
    assert.deepEqual({ ...quadro }, { terca: 1, quinta: 1, sabado: 0, server_version: 7 });
    assert.equal(banco.prepare('PRAGMA foreign_key_check').all().length, 0);
  });

  test('integridade das chaves estrangeiras e do banco', () => {
    const banco = criarBancoMigrado();
    assert.equal(banco.prepare('PRAGMA integrity_check').get().integrity_check, 'ok');
    assert.equal(banco.prepare('PRAGMA foreign_key_check').all().length, 0);
  });
});

describe('restrições do modelo', () => {
  let banco;

  beforeEach(() => {
    banco = criarBancoMigrado();
    inserir(banco, 'tenants', { id: 't1', nome: 'Academia Teste' });
    inserir(banco, 'tenants', { id: 't2', nome: 'Outra Academia' });
    inserir(banco, 'turmas', { id: 'tu1', tenant_id: 't1', nome: 'Adulto' });
    inserir(banco, 'alunos', { id: 'a1', tenant_id: 't1', codigo: '10A', nome: 'Aluno Um' });
  });

  test('superadmin não tem tenant; professor e assistente têm', () => {
    inserir(banco, 'usuarios', { id: 'u0', tipo: 'superadmin', nome: 'Admin', email: 'admin@x.test', senha_hash: 'h' });
    inserir(banco, 'usuarios', { id: 'u1', tenant_id: 't1', tipo: 'professor', nome: 'Prof', email: 'prof@x.test', senha_hash: 'h' });
    assert.throws(() =>
      inserir(banco, 'usuarios', { id: 'u2', tenant_id: 't1', tipo: 'superadmin', nome: 'X', email: 'x@x.test', senha_hash: 'h' }));
    assert.throws(() =>
      inserir(banco, 'usuarios', { id: 'u3', tipo: 'assistente', nome: 'Y', email: 'y@x.test', senha_hash: 'h' }));
  });

  test('e-mail de usuário é único sem diferenciar maiúsculas', () => {
    inserir(banco, 'usuarios', { id: 'u1', tenant_id: 't1', tipo: 'professor', nome: 'Prof', email: 'prof@x.test', senha_hash: 'h' });
    assert.throws(() =>
      inserir(banco, 'usuarios', { id: 'u2', tenant_id: 't2', tipo: 'professor', nome: 'P2', email: 'PROF@x.test', senha_hash: 'h' }));
  });

  test('código do aluno é único por tenant, mas pode repetir em outro tenant', () => {
    assert.throws(() => inserir(banco, 'alunos', { id: 'a2', tenant_id: 't1', codigo: '10a', nome: 'Duplicado' }));
    inserir(banco, 'alunos', { id: 'a3', tenant_id: 't2', codigo: '10A', nome: 'Outro tenant' });
  });

  test('código de aluno excluído pode ser reutilizado', () => {
    banco.prepare("UPDATE alunos SET excluido = 1 WHERE id = 'a1'").run();
    inserir(banco, 'alunos', { id: 'a2', tenant_id: 't1', codigo: '10A', nome: 'Novo dono do código' });
  });

  test('só uma aula regular por turma e data; reposições podem repetir', () => {
    inserir(banco, 'aulas', { id: 'au1', tenant_id: 't1', turma_id: 'tu1', data_aula: '2026-11-10', tipo: 'regular' });
    assert.throws(() =>
      inserir(banco, 'aulas', { id: 'au2', tenant_id: 't1', turma_id: 'tu1', data_aula: '2026-11-10', tipo: 'regular' }));
    inserir(banco, 'aulas', { id: 'au3', tenant_id: 't1', turma_id: 'tu1', data_aula: '2026-11-10', tipo: 'reposicao' });
    inserir(banco, 'aulas', { id: 'au4', tenant_id: 't1', turma_id: 'tu1', data_aula: '2026-11-10', tipo: 'reposicao' });
  });

  test('presença é única por aula e aluno, mesmo excluída', () => {
    inserir(banco, 'aulas', { id: 'au1', tenant_id: 't1', turma_id: 'tu1', data_aula: '2026-11-10' });
    inserir(banco, 'presencas', { id: 'p1', tenant_id: 't1', aula_id: 'au1', aluno_id: 'a1' });
    banco.prepare("UPDATE presencas SET excluido = 1 WHERE id = 'p1'").run();
    assert.throws(() => inserir(banco, 'presencas', { id: 'p2', tenant_id: 't1', aula_id: 'au1', aluno_id: 'a1' }));
  });

  test('presença exige aula e aluno existentes', () => {
    assert.throws(() => inserir(banco, 'presencas', { id: 'p1', tenant_id: 't1', aula_id: 'nao-existe', aluno_id: 'a1' }));
  });

  test('datas de calendário no formato AAAA-MM-DD', () => {
    assert.throws(() =>
      inserir(banco, 'aulas', { id: 'au1', tenant_id: 't1', turma_id: 'tu1', data_aula: '10/11/2026' }));
  });

  test('matrícula: fim não pode ser antes do início', () => {
    inserir(banco, 'matriculas', { id: 'm1', tenant_id: 't1', aluno_id: 'a1', turma_id: 'tu1', data_inicio: '2026-02-05' });
    assert.throws(() =>
      inserir(banco, 'matriculas', {
        id: 'm2', tenant_id: 't1', aluno_id: 'a1', turma_id: 'tu1', data_inicio: '2026-02-05', data_fim: '2026-01-01',
      }));
  });

  test('frequência mínima da turma entre 0 e 100', () => {
    assert.throws(() => inserir(banco, 'turmas', { id: 'tu2', tenant_id: 't1', nome: 'Kids', frequencia_minima: 120 }));
    inserir(banco, 'turmas', { id: 'tu3', tenant_id: 't1', nome: 'Kids', frequencia_minima: 75 });
  });

  test('regras: escopo tenant sem escopo_id, parâmetros em JSON válido e sem duplicar', () => {
    const regra = { tenant_id: 't1', escopo: 'tenant', tipo: 'frequencia_minima_graduacao', vigencia_inicio: '2026-01-01' };
    inserir(banco, 'regras', { id: 'r1', ...regra, parametros: '{"conta_reposicao":true}' });
    assert.throws(() => inserir(banco, 'regras', { id: 'r2', ...regra }));
    assert.throws(() => inserir(banco, 'regras', { id: 'r3', ...regra, vigencia_inicio: '2026-07-01', parametros: 'nao-json' }));
    assert.throws(() => inserir(banco, 'regras', { id: 'r4', ...regra, escopo_id: 'tu1', vigencia_inicio: '2026-07-01' }));
  });

  test('quadro de aulas aceita 0 (sem aula), 1 (regular) e 2 (reposição)', () => {
    inserir(banco, 'quadros_aulas', {
      id: 'q1', tenant_id: 't1', turma_id: 'tu1', vigencia_inicio: '2026-02-01',
      terca: 1, quarta: 1, quinta: 1, sabado: 2,
    });
    assert.throws(() =>
      inserir(banco, 'quadros_aulas', { id: 'q2', tenant_id: 't1', turma_id: 'tu1', vigencia_inicio: '2026-02-01', sabado: 3 }));
  });

  test('tenant: nome curto do app entre 1 e 15 caracteres', () => {
    banco.prepare("UPDATE tenants SET nome_curto = 'Equipe Junião', logotipo_key = 'logos/t1.png' WHERE id = 't1'").run();
    assert.throws(() => banco.prepare("UPDATE tenants SET nome_curto = 'Nome curto grande demais' WHERE id = 't1'").run());
  });

  test('cursor de sincronização começa em zero e incrementa', () => {
    const { ultima_versao } = banco
      .prepare('UPDATE controle_versao SET ultima_versao = ultima_versao + 1 WHERE id = 1 RETURNING ultima_versao')
      .get();
    assert.equal(ultima_versao, 1);
  });
});
