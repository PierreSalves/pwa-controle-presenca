-- 0001_inicial.sql
-- Esquema inicial do servidor (Cloudflare D1 / SQLite) — Fase 1: presença.
--
-- Convenções (docs/desenvolvimento.md):
--   * ids: TEXT com UUID v7 gerado no cliente (exceto onde indicado).
--   * timestamps (created_at, updated_at, ...): ISO 8601 em UTC, ex.: 2026-11-12T13:45:00.000Z.
--   * datas de calendário (data_aula, data_inicio, ...): 'AAAA-MM-DD', sem fuso.
--   * exclusão é lógica: excluido = 1. Unicidades "de negócio" valem só para excluido = 0.
--   * isolamento de tenant e coerência entre tenants (ex.: aluno e turma do mesmo tenant)
--     são garantidos pela API, que sempre filtra por tenant_id vindo do token.
--
-- Tabelas sincronizadas com o app (presença offline de reserva) têm também:
--   server_version: número crescente atribuído pela API a cada gravação; cursor do pull.
-- O banco local do app (drift) usa um subconjunto deste esquema, SEM colunas sensíveis
-- (CPF, RG, endereço, telefones, responsáveis), que nunca saem do servidor.

-- Chaves estrangeiras: o D1 já as aplica por padrão (não é preciso PRAGMA aqui).

-- ---------------------------------------------------------------------------
-- Controle do cursor de sincronização (uma linha só).
-- A API faz, na mesma transação da gravação:
--   UPDATE controle_versao SET ultima_versao = ultima_versao + 1 WHERE id = 1 RETURNING ultima_versao;
-- ---------------------------------------------------------------------------
CREATE TABLE controle_versao (
  id            INTEGER PRIMARY KEY CHECK (id = 1),
  ultima_versao INTEGER NOT NULL DEFAULT 0
);
INSERT INTO controle_versao (id, ultima_versao) VALUES (1, 0);

-- ---------------------------------------------------------------------------
-- Tenants (academia / equipe). Só o superadmin cadastra. Online.
-- ---------------------------------------------------------------------------
CREATE TABLE tenants (
  id                  TEXT PRIMARY KEY,
  nome                TEXT NOT NULL CHECK (length(trim(nome)) > 0),
  subdominio          TEXT,                       -- opcional, futuro (ex.: 'equipejuniao')
  cabecalho_impressao TEXT,                       -- opcional, aparece nos relatórios impressos
  ativo               INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
  created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido            INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  created_by          TEXT,
  updated_by          TEXT
);
CREATE UNIQUE INDEX ux_tenants_subdominio ON tenants (subdominio COLLATE NOCASE)
  WHERE subdominio IS NOT NULL AND excluido = 0;

-- ---------------------------------------------------------------------------
-- Usuários. tipo define as permissões (matriz fixa no código):
--   superadmin (sem tenant) | professor | assistente
-- Login por e-mail, único no sistema inteiro (o login identifica o tenant).
-- senha_hash no formato 'pbkdf2-sha256$<iteracoes>$<salt_base64>$<hash_base64>'.
-- ---------------------------------------------------------------------------
CREATE TABLE usuarios (
  id              TEXT PRIMARY KEY,
  tenant_id       TEXT REFERENCES tenants (id),
  tipo            TEXT NOT NULL CHECK (tipo IN ('superadmin', 'professor', 'assistente')),
  nome            TEXT NOT NULL CHECK (length(trim(nome)) > 0),
  email           TEXT NOT NULL COLLATE NOCASE,
  senha_hash      TEXT NOT NULL,
  ativo           INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
  ultimo_login_em TEXT,
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido        INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  created_by      TEXT,
  updated_by      TEXT,
  CHECK ((tipo = 'superadmin') = (tenant_id IS NULL))
);
CREATE UNIQUE INDEX ux_usuarios_email ON usuarios (email COLLATE NOCASE) WHERE excluido = 0;
CREATE INDEX ix_usuarios_tenant ON usuarios (tenant_id);

-- ---------------------------------------------------------------------------
-- Sessões (refresh tokens). Revogar = preencher revogado_em.
-- Guarda só o hash do token, nunca o token.
-- ---------------------------------------------------------------------------
CREATE TABLE sessoes (
  id            TEXT PRIMARY KEY,
  usuario_id    TEXT NOT NULL REFERENCES usuarios (id),
  token_hash    TEXT NOT NULL UNIQUE,
  expira_em     TEXT NOT NULL,
  revogado_em   TEXT,
  ultimo_uso_em TEXT,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
CREATE INDEX ix_sessoes_usuario ON sessoes (usuario_id);

-- ---------------------------------------------------------------------------
-- Turmas. Sincronizada.
-- frequencia_minima: % mínimo para graduação (0 a 100), configurado na turma.
-- ---------------------------------------------------------------------------
CREATE TABLE turmas (
  id                  TEXT PRIMARY KEY,
  tenant_id           TEXT NOT NULL REFERENCES tenants (id),
  nome                TEXT NOT NULL CHECK (length(trim(nome)) > 0),
  descricao           TEXT,
  frequencia_minima   INTEGER CHECK (frequencia_minima BETWEEN 0 AND 100),
  cabecalho_impressao TEXT,
  created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido            INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version      INTEGER NOT NULL DEFAULT 0,
  created_by          TEXT,
  updated_by          TEXT
);
CREATE UNIQUE INDEX ux_turmas_nome ON turmas (tenant_id, nome COLLATE NOCASE) WHERE excluido = 0;
CREATE INDEX ix_turmas_sync ON turmas (tenant_id, server_version);

-- ---------------------------------------------------------------------------
-- Acesso usuário × turma (N:N). Sincronizada (o app precisa saber suas turmas).
-- Só professor cadastra.
-- ---------------------------------------------------------------------------
CREATE TABLE turma_usuarios (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL REFERENCES tenants (id),
  turma_id       TEXT NOT NULL REFERENCES turmas (id),
  usuario_id     TEXT NOT NULL REFERENCES usuarios (id),
  created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido       INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version INTEGER NOT NULL DEFAULT 0,
  created_by     TEXT,
  updated_by     TEXT
);
CREATE UNIQUE INDEX ux_turma_usuarios ON turma_usuarios (turma_id, usuario_id) WHERE excluido = 0;
CREATE INDEX ix_turma_usuarios_usuario ON turma_usuarios (usuario_id);
CREATE INDEX ix_turma_usuarios_sync ON turma_usuarios (tenant_id, server_version);

-- ---------------------------------------------------------------------------
-- Alunos. Sincronizada SÓ com as colunas mínimas (id, codigo, nome, ativo + colunas de sync).
-- As demais colunas são sensíveis e ficam só no servidor.
-- codigo: código manual do professor (ex.: '10A'), único por tenant.
-- ---------------------------------------------------------------------------
CREATE TABLE alunos (
  id              TEXT PRIMARY KEY,
  tenant_id       TEXT NOT NULL REFERENCES tenants (id),
  codigo          TEXT NOT NULL CHECK (length(trim(codigo)) > 0),
  nome            TEXT NOT NULL CHECK (length(trim(nome)) > 0),
  ativo           INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0, 1)),
  -- sensíveis (nunca sincronizadas):
  data_nascimento TEXT CHECK (data_nascimento IS NULL OR data_nascimento GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  sexo            TEXT,
  cpf             TEXT,
  rg              TEXT,
  telefone        TEXT,
  email           TEXT,
  endereco        TEXT,
  nome_pai        TEXT,
  telefone_pai    TEXT,
  nome_mae        TEXT,
  telefone_mae    TEXT,
  observacoes     TEXT,
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido        INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version  INTEGER NOT NULL DEFAULT 0,
  created_by      TEXT,
  updated_by      TEXT
);
CREATE UNIQUE INDEX ux_alunos_codigo ON alunos (tenant_id, codigo COLLATE NOCASE) WHERE excluido = 0;
CREATE INDEX ix_alunos_nome ON alunos (tenant_id, nome COLLATE NOCASE);
CREATE INDEX ix_alunos_sync ON alunos (tenant_id, server_version);

-- ---------------------------------------------------------------------------
-- Graduações (faixa e grau). Online.
-- ---------------------------------------------------------------------------
CREATE TABLE graduacoes (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL REFERENCES tenants (id),
  aluno_id       TEXT NOT NULL REFERENCES alunos (id),
  faixa          TEXT NOT NULL CHECK (length(trim(faixa)) > 0),
  grau           INTEGER NOT NULL DEFAULT 0 CHECK (grau >= 0),
  data_graduacao TEXT NOT NULL CHECK (data_graduacao GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  observacoes    TEXT,
  created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido       INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  created_by     TEXT,
  updated_by     TEXT
);
CREATE INDEX ix_graduacoes_aluno ON graduacoes (aluno_id, data_graduacao);

-- ---------------------------------------------------------------------------
-- Matrículas (aluno × turma com período). Sincronizada.
-- data_fim NULL = matrícula em aberto.
-- ---------------------------------------------------------------------------
CREATE TABLE matriculas (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL REFERENCES tenants (id),
  aluno_id       TEXT NOT NULL REFERENCES alunos (id),
  turma_id       TEXT NOT NULL REFERENCES turmas (id),
  data_inicio    TEXT NOT NULL CHECK (data_inicio GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  data_fim       TEXT CHECK (data_fim IS NULL OR data_fim GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  situacao       TEXT NOT NULL DEFAULT 'matriculado'
                 CHECK (situacao IN ('matriculado', 'remanejado', 'encerrado')),
  created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido       INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version INTEGER NOT NULL DEFAULT 0,
  created_by     TEXT,
  updated_by     TEXT,
  CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);
CREATE INDEX ix_matriculas_turma ON matriculas (turma_id, data_inicio);
CREATE INDEX ix_matriculas_aluno ON matriculas (aluno_id);
CREATE INDEX ix_matriculas_sync ON matriculas (tenant_id, server_version);

-- ---------------------------------------------------------------------------
-- Quadro de aulas da turma: dias da semana habilitados, com vigência.
-- Vários quadros por turma em ordem cronológica. Sincronizada.
-- ---------------------------------------------------------------------------
CREATE TABLE quadros_aulas (
  id              TEXT PRIMARY KEY,
  tenant_id       TEXT NOT NULL REFERENCES tenants (id),
  turma_id        TEXT NOT NULL REFERENCES turmas (id),
  vigencia_inicio TEXT NOT NULL CHECK (vigencia_inicio GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  vigencia_fim    TEXT CHECK (vigencia_fim IS NULL OR vigencia_fim GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  domingo         INTEGER NOT NULL DEFAULT 0 CHECK (domingo IN (0, 1)),
  segunda         INTEGER NOT NULL DEFAULT 0 CHECK (segunda IN (0, 1)),
  terca           INTEGER NOT NULL DEFAULT 0 CHECK (terca IN (0, 1)),
  quarta          INTEGER NOT NULL DEFAULT 0 CHECK (quarta IN (0, 1)),
  quinta          INTEGER NOT NULL DEFAULT 0 CHECK (quinta IN (0, 1)),
  sexta           INTEGER NOT NULL DEFAULT 0 CHECK (sexta IN (0, 1)),
  sabado          INTEGER NOT NULL DEFAULT 0 CHECK (sabado IN (0, 1)),
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido        INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version  INTEGER NOT NULL DEFAULT 0,
  created_by      TEXT,
  updated_by      TEXT,
  CHECK (vigencia_fim IS NULL OR vigencia_fim >= vigencia_inicio)
);
CREATE INDEX ix_quadros_aulas_turma ON quadros_aulas (turma_id, vigencia_inicio);
CREATE INDEX ix_quadros_aulas_sync ON quadros_aulas (tenant_id, server_version);

-- ---------------------------------------------------------------------------
-- Aulas. Sincronizada.
--   regular: só em dia habilitado pelo quadro vigente; no máximo uma por turma e data.
--            O id da aula regular é DETERMINÍSTICO (UUID v5 de turma_id + data_aula),
--            para dois aparelhos offline criarem a mesma aula com o mesmo id.
--   reposicao: aula extra, em qualquer dia; pode haver mais de uma na mesma data.
-- ---------------------------------------------------------------------------
CREATE TABLE aulas (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL REFERENCES tenants (id),
  turma_id       TEXT NOT NULL REFERENCES turmas (id),
  data_aula      TEXT NOT NULL CHECK (data_aula GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  tipo           TEXT NOT NULL DEFAULT 'regular' CHECK (tipo IN ('regular', 'reposicao')),
  created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido       INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version INTEGER NOT NULL DEFAULT 0,
  created_by     TEXT,
  updated_by     TEXT
);
CREATE UNIQUE INDEX ux_aulas_regular ON aulas (turma_id, data_aula)
  WHERE tipo = 'regular' AND excluido = 0;
CREATE INDEX ix_aulas_turma_data ON aulas (turma_id, data_aula);
CREATE INDEX ix_aulas_sync ON aulas (tenant_id, server_version);

-- ---------------------------------------------------------------------------
-- Presenças: registra só quem veio. Sincronizada.
-- Uma linha por (aula, aluno), mesmo excluída: desmarcar = excluido 1, remarcar = excluido 0.
-- A API grava por upsert na chave natural (aula_id, aluno_id).
-- ---------------------------------------------------------------------------
CREATE TABLE presencas (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL REFERENCES tenants (id),
  aula_id        TEXT NOT NULL REFERENCES aulas (id),
  aluno_id       TEXT NOT NULL REFERENCES alunos (id),
  created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido       INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version INTEGER NOT NULL DEFAULT 0,
  created_by     TEXT,
  updated_by     TEXT,
  UNIQUE (aula_id, aluno_id)
);
CREATE INDEX ix_presencas_aluno ON presencas (aluno_id);
CREATE INDEX ix_presencas_sync ON presencas (tenant_id, server_version);

-- ---------------------------------------------------------------------------
-- Regras configuráveis (tipos pré-definidos + parâmetros JSON). Online.
--   escopo 'tenant' (escopo_id NULL) é o padrão; 'turma' e 'usuario' sobrescrevem.
--   Ex.: tipo 'frequencia_minima_graduacao', parametros
--        {"periodos":[["01-01","06-30"],["07-01","12-31"]],"meses_graduacao":[6,12],"conta_reposicao":true}
--   (o percentual mínimo fica em turmas.frequencia_minima)
-- ---------------------------------------------------------------------------
CREATE TABLE regras (
  id              TEXT PRIMARY KEY,
  tenant_id       TEXT NOT NULL REFERENCES tenants (id),
  escopo          TEXT NOT NULL CHECK (escopo IN ('tenant', 'turma', 'usuario')),
  escopo_id       TEXT,
  tipo            TEXT NOT NULL CHECK (length(trim(tipo)) > 0),
  parametros      TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(parametros)),
  vigencia_inicio TEXT NOT NULL CHECK (vigencia_inicio GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido        INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  created_by      TEXT,
  updated_by      TEXT,
  CHECK ((escopo = 'tenant') = (escopo_id IS NULL))
);
CREATE UNIQUE INDEX ux_regras ON regras (tenant_id, escopo, coalesce(escopo_id, ''), tipo, vigencia_inicio)
  WHERE excluido = 0;
