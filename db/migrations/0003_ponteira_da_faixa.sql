-- 0003_ponteira_da_faixa.sql
-- Aprovado com o wireframe das faixas da CBJJ (docs/telas/wireframes-faixas.html, 14/11/2026).
-- Na faixa preta, a ponteira: 'vermelha' (professor) ou 'branca' (competidor). Nas outras faixas
-- fica nula. As regras de faixa e grau são validadas na API (api/src/regras/faixas.ts); graduações
-- já gravadas continuam como estão.
ALTER TABLE graduacoes ADD COLUMN ponteira TEXT CHECK (ponteira IS NULL OR ponteira IN ('vermelha', 'branca'));
