# 11 — Frequência mínima e limite de faltas

**Objetivo:** definir quantas faltas o aluno pode ter para poder graduar, e acompanhar quem está abaixo.
**Quem pode:** professor e assistente.

## Como o sistema pensa o "limite de faltas"
Em vez de um número fixo de faltas, você define a **frequência mínima (%)** da turma. O limite de faltas sai da conta, e se ajusta sozinho ao número de aulas que realmente aconteceram (feriado não conta).

**Frequência** = (presenças em aulas regulares + presenças em reposições) ÷ aulas regulares lançadas no semestre.
- Semestre: **janeiro a junho** e **julho a dezembro** (graduações no início de junho e de dezembro).
- Conta só o período em que o aluno estava matriculado: quem entrou em setembro é avaliado a partir de setembro.
- Reposição soma presença e não aumenta o total de aulas ([manual 09](09-aula-de-reposicao.md)).
- Limite de 100%.

### Quantas faltas o aluno pode ter?
1. Presenças necessárias = mínimo × aulas do semestre ÷ 100, **arredondando para cima**.
2. Faltas permitidas = aulas do semestre − presenças necessárias.
3. Cada presença em reposição compensa uma falta.

| Frequência mínima | Aulas regulares no semestre | Precisa vir | Pode faltar |
|---|---|---|---|
| 75% | 48 (3 por semana) | 36 | 12 |
| 75% | 24 (2 por semana) | 18 | 6 |
| 70% | 48 | 34 | 14 |
| 80% | 48 | 39 | 9 |

> Quer pensar em "no máximo 12 faltas por semestre" numa turma de 3 aulas por semana? Isso é cerca de **75%**.

## Definir a frequência mínima
1. Menu → **Turmas** → toque na turma.
2. Em **Frequência mínima (%)**, digite o número (ex.: `75`).
3. **Salvar**.

Cada turma tem a sua (ex.: Kids 70%, Adulto 75%). Sem valor, ninguém aparece como abaixo do mínimo.

## Acompanhar quem está abaixo
- **Início:** aparece o aviso "**N alunos abaixo do mínimo para graduação**". Toque nele para ver a frequência do semestre de cada aluno (abaixo do mínimo em vermelho).
- **Relatório "Frequência para graduação"** ([manual 10](10-relatorios.md)): aulas, presenças, reposições e frequência de cada aluno, com impressão. Use **Até** = o dia da graduação.
- **Relatório "Presença mensal":** a frequência do período, mês a mês.

## O sistema bloqueia o aluno abaixo do mínimo?
Não. Ele continua podendo treinar e ser marcado. O sistema só **avisa e mostra**; a decisão de graduar é sua. Registre a graduação no cadastro do aluno ([manual 13](13-registrar-graduacao.md)).

## Outras duas configurações da turma

### Quem aparece direto na lista do lançamento
"Frequentes: ao menos **30** % das últimas **8** aulas". Quem está abaixo disso vai para "Pouco frequentes", para a lista do dia ficar curta. Aluno novo sempre aparece. Aumente o percentual se a lista estiver longa demais; diminua se muita gente que vem estiver ficando de fora.

### Quando avisar que um aluno sumiu
"Avisar sumidos após **4** semanas". O Início lista quem não vem há mais tempo que isso, com o botão para encerrar a matrícula ([manual 12](12-aluno-que-parou-de-vir.md)).
