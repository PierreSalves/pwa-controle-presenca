# Regras de desenvolvimento

Valem para qualquer pessoa (ou agente) que altere este repositório.

## 1. Idioma e nomes

**Nomes do domínio em português**, sem acentos nem cedilha em identificadores. Termos técnicos do framework continuam em inglês (`Widget`, `Repository`, `build`, `fetch`).

| Onde | Padrão | Exemplo |
|---|---|---|
| Tabelas (D1 / drift) | `snake_case`, plural | `alunos`, `matriculas`, `turma_usuarios` |
| Colunas | `snake_case` | `frequencia_minima`, `data_inicio`, `tenant_id` |
| JSON da API | `snake_case`, igual às colunas | `{ "aula_id": "...", "aluno_id": "..." }` |
| Rotas da API | `kebab-case`, plural | `GET /turmas/:id/aulas`, `POST /sync/push` |
| Dart: classes | `UpperCamelCase` | `Matricula`, `LancamentoPresencaPage` |
| Dart: variáveis e funções | `lowerCamelCase` | `frequenciaMinima`, `calcularFrequencia()` |
| Dart: arquivos | `snake_case.dart` | `lancamento_presenca_page.dart` |
| TypeScript: variáveis e funções | `camelCase` | `calcularFrequencia()` |
| TypeScript: tipos | `PascalCase` | `Matricula`, `PushRequest` |
| TypeScript: arquivos | `kebab-case.ts` | `regras-frequencia.ts` |

Textos da interface, mensagens de erro para o usuário, commits, PRs e documentação: **português (Brasil)**.

### 1.1 Nomes de funções

**Uma função faz uma coisa só, e o nome diz exatamente qual** (princípio da responsabilidade única, o "S" do SOLID).

- **Começa com verbo de ação no infinitivo**: `salvarPresenca`, `calcularFrequencia`, `excluirMatricula`.
- **Revela a intenção**: quem lê o nome não precisa abrir a função nem de comentário para saber o que ela faz.
- **Sem "e" / "ou" no nome**: `calcularFrequenciaEEnviarRelatorio` faz duas coisas; divida em `calcularFrequencia` e `enviarRelatorio`.
- **Sem verbos genéricos**: `processar`, `gerenciar`, `tratar`, `manipular`, `fazer` escondem o que a função faz e costumam indicar que ela faz coisas demais. Diga a ação real (`validarMatricula`, `enviarOutbox`).

**Prefixos padronizados** (equivalentes em português dos prefixos `get` / `fetch` / `is` / `has` / `can` / `set`):

| Prefixo | Uso | Exemplo |
|---|---|---|
| `obter…` | ler dado já disponível (banco local, memória) | `obterAlunosDaTurma()` |
| `buscar…` | buscar dado remoto (API, rede) | `buscarAlteracoesDesde(cursor)` |
| `definir…` | alterar um valor | `definirFrequenciaMinima(turma, 75)` |
| `eh…` / `esta…` | retorna booleano sobre um estado | `ehDiaFuturo(data)`, `estaMatriculado(aluno, data)` |
| `tem…` | retorna booleano sobre posse | `temAcessoATurma(usuario, turma)` |
| `pode…` | retorna booleano sobre permissão | `podeCadastrarUsuario(usuario)` |
| `criar…` / `salvar…` / `excluir…` | gravar (exclusão é sempre lógica, `excluido = 1`) | `salvarPresenca()`, `excluirAula()` |
| `calcular…` | derivar um valor sem efeito colateral | `calcularFrequencia(aluno, periodo)` |
| `validar…` | conferir regra e lançar/retornar erro | `validarPeriodoMatricula(aluno, aula)` |

Variáveis e campos booleanos seguem a mesma ideia: `ativo`, `excluido`, `temPendencias`, `podeLancar`.

## 2. Estrutura do repositório (monorepo)

```
app/            App Flutter Web (PWA)
api/            Cloudflare Worker (TypeScript, Hono)
db/migrations/  Migrações SQL numeradas do servidor (D1); o drift usa um subconjunto sem colunas sensíveis
db/testes/      Testes das migrações (node --test db/)
docs/           Documentação e decisões
```

## 3. Fluxo git

- A `main` é protegida: só recebe código por **Pull Request** e está sempre funcionando.
- Uma branch por tarefa, a partir da `main` atualizada:
  `feat/…`, `fix/…`, `docs/…`, `refactor/…`, `test/…`, `chore/…` (ex.: `feat/lancamento-presenca`).
- PRs **pequenos e focados** (uma funcionalidade ou correção por PR).
- Para entrar na `main`: CI verde + revisão aprovada.
- Merge por **squash**; a branch é apagada depois do merge.
- Descrição do PR: o que muda, por quê, como testar e, se houver, prints da tela no celular.

## 4. Commits

[Conventional Commits](https://www.conventionalcommits.org/pt-br/) com descrição em português, no presente, em minúsculas:

```
<tipo>(<escopo opcional>): <descrição curta>
```

| Tipo | Uso |
|---|---|
| `feat` | nova funcionalidade |
| `fix` | correção de bug |
| `docs` | só documentação |
| `refactor` | mudança de código sem mudar comportamento |
| `test` | testes |
| `chore` | build, dependências, configuração, CI |

Escopos sugeridos: `app`, `api`, `db`, `sync`. Exemplos:
- `feat(app): adiciona tela de lançamento de presença`
- `fix(sync): reenvia itens da outbox após token renovado`
- `docs: registra regra de frequência para graduação`

## 5. Testes

**Obrigatórios** (o PR não entra sem eles):
- **Regras de negócio**: frequência mínima, período de matrícula, dia futuro, quadro de aulas, reposição.
  - As regras existem no app (Dart) e na API (TypeScript). Os casos de teste ficam num **arquivo JSON compartilhado** (`docs/casos-regras/` ou equivalente) e os dois lados rodam os mesmos casos, para nunca divergirem.
- **Sincronização**: outbox, push/pull, cursor `server_version`, conflitos, token expirado offline.
- **API**: cada endpoint testa permissão por `tipo` de usuário e **isolamento de tenant** (um usuário nunca lê nem grava dados de outro tenant ou de turma sem acesso).
- **Migrações**: aplicam do zero sem erro.

**Recomendados**: testes de widget dos fluxos principais (login, lançamento de presença).

Correção de bug vem com um teste que falhava antes da correção.

## 6. Qualidade de código

- **Dart**: `dart format` e `flutter analyze` sem avisos (regras do `flutter_lints`).
- **TypeScript**: `strict: true`, ESLint e Prettier.
- O CI (GitHub Actions) roda formatação, análise, checagem de tipos e testes em todo PR.
- Sem código comentado "para depois" e sem `print`/`console.log` de depuração no PR.

## 7. Banco de dados

- Toda mudança de esquema é uma **nova migração** em `db/migrations/` (`0001_inicial.sql`, `0002_…`). Migração já aplicada nunca é editada.
- Toda migração atualiza, no mesmo PR, o **MER e o dicionário de dados** em [`docs/banco-de-dados.md`](banco-de-dados.md) e os testes em `db/testes/`.
- Toda tabela sincronizada tem as colunas de sync (`id` UUID v7, `tenant_id`, `created_at`, `updated_at`, `excluido`, `server_version`, `created_by`, `updated_by`).
- Nada é apagado de verdade: exclusão é `excluido = 1`.
- Na API, **toda consulta filtra por `tenant_id` vindo do token** e, quando for o caso, pelas turmas a que o usuário tem acesso.
- Totais de relatório nunca são gravados; são calculados.

## 8. Datas e valores

- Data e hora (`created_at`, `updated_at`): ISO 8601 em **UTC** no banco e na API.
- Datas de calendário (`data_aula`, `data_inicio`, `data_pagamento`): texto `AAAA-MM-DD`, **sem fuso** (é o dia local da academia).
- Exibição: `dd/mm/aaaa`, fuso `America/Sao_Paulo`.
- Dinheiro: inteiro em **centavos** no banco e na API; exibido como `R$ 1.234,56`.

## 9. Segurança

- Nenhum segredo no repositório: segredos da API via `wrangler secret`; local em `.dev.vars` (ignorado pelo git).
- Dados sensíveis (CPF, RG, endereço, telefones, responsáveis) nunca entram no payload de sync nem no banco local.
- Nada de dados pessoais em logs.
- Planilhas e dados reais de alunos não entram no repositório (use dados fictícios em testes e exemplos).
- Dependências novas precisam de justificativa no PR.

## 10. Interface

- **Wireframe antes de código:** tela nova ou mudança visual relevante só é implementada depois de wireframe **aprovado** e registrado em [`docs/telas/`](telas/README.md) (imagem, objetivo, quem acessa, regras e linha na tabela de aprovação).
- A tela implementada segue o wireframe aprovado; se precisar mudar, atualiza-se o wireframe e pede-se nova aprovação.
- Mobile-first: pensada primeiro para celular em pé, uma mão.
- Áreas de toque de no mínimo 48 px; textos simples, sem jargão técnico.
- Toda ação que depende de internet avisa claramente quando não há conexão.
- A tela de lançamento sempre mostra o status de envio.
- **Wireframes em HTML:** todo wireframe ou proposta de tela é um arquivo HTML em `docs/telas/`; as imagens de `docs/telas/img/` são geradas dele (`bash docs/telas/gerar-imagens.sh`).

### 10.1 Revisão de interface (web-design-guidelines)

Toda tela nova ou mudança visual passa pela skill `web-design-guidelines` (Web Interface Guidelines da Vercel) **duas vezes**:

1. **No wireframe**, antes da aprovação: o wireframe é HTML, então as regras se aplicam direto. O que a revisão pedir vira requisito da tela (ex.: a seção "Requisitos de implementação" da proposta v2).
2. **No código**, antes do PR: revisar os arquivos da tela e corrigir. O PR lista o que foi corrigido, o que já estava certo e o que não se aplica.

As diretrizes são baixadas na hora (a skill busca a versão atual). Como foram escritas para HTML e React, no Flutter Web valem os equivalentes:

| Regra | No Flutter |
|---|---|
| Rótulo em botão só com ícone | `tooltip` no `IconButton` |
| Leitor de tela | árvore de acessibilidade ligada ao iniciar (`ensureSemantics` em `main.dart`); `semanticsLabel` em indicadores |
| Foco visível e teclado | cores de foco do tema; testar com Tab no desktop |
| Área de toque | mínimo 48 px |
| Contraste | texto 4,5:1; contorno de campo, caixa e ícone 3:1 (WCAG 1.4.11); cores como tokens do tema |
| Movimento reduzido | `MediaQuery.disableAnimationsOf(context)` |
| Campos | `keyboardType`, `autofillHints` no login, `autocorrect: false` em e-mail, código e documentos |
| Alterações não salvas | `ProtecaoAlteracoes` (pergunta antes de descartar) |
| Textos longos | `maxLines` e `overflow: ellipsis` |
| Números em coluna | `FontFeature.tabularFigures()` |

Não se aplicam ao projeto: Title Case (a interface é pt-BR, com só a primeira letra maiúscula) e formatos de data do navegador (o projeto fixa dd/mm/aaaa e o fuso de São Paulo).

## 11. Pronto para o PR (checklist)

- [ ] Tela segue o wireframe aprovado em `docs/telas/`
- [ ] Revisão com a `web-design-guidelines` feita e registrada no PR (seção 10.1)
- [ ] Funciona no celular (testado em tela estreita)
- [ ] Testes obrigatórios escritos e passando
- [ ] Formatação e análise sem avisos
- [ ] Migração nova, se mudou o banco, com MER e dicionário de dados atualizados
- [ ] Documentação atualizada, se mudou alguma decisão ou regra
- [ ] Sem segredos, dados reais ou logs de depuração
