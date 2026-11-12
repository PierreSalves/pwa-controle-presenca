-- 0002_quadro_reposicao_e_identidade.sql
-- Aprovado com os wireframes v1 (docs/telas/README.md, 12/11/2026).
--
-- 1) Quadro de aulas: cada dia da semana passa de 0/1 para
--      0 = sem aula, 1 = regular, 2 = reposição (dia fixo de reposição).
--    O SQLite não altera CHECK de coluna existente, então a tabela é recriada
--    preservando os dados (nenhuma tabela aponta para quadros_aulas).
-- 2) Identidade da academia: logotipo, nome curto do app instalado e ícones gerados (R2).

-- 1) quadros_aulas ------------------------------------------------------------
CREATE TABLE quadros_aulas_nova (
  id              TEXT PRIMARY KEY,
  tenant_id       TEXT NOT NULL REFERENCES tenants (id),
  turma_id        TEXT NOT NULL REFERENCES turmas (id),
  vigencia_inicio TEXT NOT NULL CHECK (vigencia_inicio GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  vigencia_fim    TEXT CHECK (vigencia_fim IS NULL OR vigencia_fim GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
  domingo         INTEGER NOT NULL DEFAULT 0 CHECK (domingo IN (0, 1, 2)),
  segunda         INTEGER NOT NULL DEFAULT 0 CHECK (segunda IN (0, 1, 2)),
  terca           INTEGER NOT NULL DEFAULT 0 CHECK (terca IN (0, 1, 2)),
  quarta          INTEGER NOT NULL DEFAULT 0 CHECK (quarta IN (0, 1, 2)),
  quinta          INTEGER NOT NULL DEFAULT 0 CHECK (quinta IN (0, 1, 2)),
  sexta           INTEGER NOT NULL DEFAULT 0 CHECK (sexta IN (0, 1, 2)),
  sabado          INTEGER NOT NULL DEFAULT 0 CHECK (sabado IN (0, 1, 2)),
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  excluido        INTEGER NOT NULL DEFAULT 0 CHECK (excluido IN (0, 1)),
  server_version  INTEGER NOT NULL DEFAULT 0,
  created_by      TEXT,
  updated_by      TEXT,
  CHECK (vigencia_fim IS NULL OR vigencia_fim >= vigencia_inicio)
);

INSERT INTO quadros_aulas_nova
  (id, tenant_id, turma_id, vigencia_inicio, vigencia_fim,
   domingo, segunda, terca, quarta, quinta, sexta, sabado,
   created_at, updated_at, excluido, server_version, created_by, updated_by)
SELECT
   id, tenant_id, turma_id, vigencia_inicio, vigencia_fim,
   domingo, segunda, terca, quarta, quinta, sexta, sabado,
   created_at, updated_at, excluido, server_version, created_by, updated_by
FROM quadros_aulas;

DROP TABLE quadros_aulas;
ALTER TABLE quadros_aulas_nova RENAME TO quadros_aulas;

CREATE INDEX ix_quadros_aulas_turma ON quadros_aulas (turma_id, vigencia_inicio);
CREATE INDEX ix_quadros_aulas_sync ON quadros_aulas (tenant_id, server_version);

-- 2) tenants: identidade ------------------------------------------------------
ALTER TABLE tenants ADD COLUMN nome_curto TEXT CHECK (nome_curto IS NULL OR length(trim(nome_curto)) BETWEEN 1 AND 15);
ALTER TABLE tenants ADD COLUMN logotipo_key TEXT;    -- chave do logotipo original no R2
ALTER TABLE tenants ADD COLUMN icone_192_key TEXT;   -- ícone 192x192 (com margem de segurança) no R2
ALTER TABLE tenants ADD COLUMN icone_512_key TEXT;   -- ícone 512x512 (com margem de segurança) no R2
