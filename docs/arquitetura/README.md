# Arquitetura — Flutter + API, presença online primeiro com offline de reserva

Diagramas: [1. Hospedagem](1-hospedagem-cloudflare.jpg) · [2. Segurança](2-seguranca-comunicacao.jpg) · [3. Local-first & Sync](3-local-first-sync.jpg)

> A primeira ideia (React + MUI + Laravel + PostgreSQL), em `docs/levantamento-inicial/`, foi **substituída** por esta.
> As telas, as regras de negócio e o levantamento de tabelas de lá continuam valendo como referência.

## Visão geral

```
┌──────────── Celular / navegador (PWA) ────────────┐        ┌──────────── Cloudflare ────────────┐
│ App Flutter Web                                   │        │ API (Worker, TypeScript)           │
│   │ presença: grava aqui e envia na hora          │  sync  │   valida JWT → isola tenant        │
│   ▼                                               │ ─────► │   → filtra turmas do professor     │
│ SQLite local (drift + sqlite3.wasm)               │ ◄───── │   ▼                                │
│   + tabela outbox (alterações pendentes)          │        │ D1 (SQLite)    R2 (comprovantes)   │
│ Service worker próprio (guarda o app p/ offline)  │        └────────────────────────────────────┘
│                                                   │
│ mensalidades / cadastros / regras ── online ─────────────► API direto
└───────────────────────────────────────────────────┘
```

## Stack

| Camada | Escolha | Motivo |
|---|---|---|
| App | **Flutter Web** como PWA | preferência do projeto; o mesmo código pode virar app Android/iOS depois |
| Banco local | **drift** (SQLite via WebAssembly) | é SQLite, igual ao D1: o mesmo esquema e o mesmo SQL nos dois lados. Escolher **drift** em vez de Hive (o diagrama 3 cita os dois) |
| Cache do app offline | **service worker próprio** (ex.: Workbox) | o Flutter não gera mais um service worker offline-first (a partir da 3.41 ele só limpa o antigo) |
| API | **Cloudflare Worker** em TypeScript (sugestão: Hono) | leve, mesmo provedor do banco |
| Banco central | **D1** | |
| Arquivos | **R2** | comprovantes de mensalidade |
| Hospedagem do app | **Workers Static Assets** | recomendação da Cloudflare para projetos novos; app e API no mesmo Worker e no mesmo domínio (sem CORS, cookies e CSP mais simples) |
| Endereço | **`controlepresenca.tghservices.com.br`** | custom domain do Worker, criado pelo Wrangler (não criar o registro DNS à mão); DNS de `tghservices.com.br` na Cloudflare |

### Custos (plano gratuito, conferido em nov/2026)
| Serviço | Limite gratuito |
|---|---|
| Static Assets | pedidos ilimitados; até 20.000 arquivos de até 25 MiB |
| Workers (API) | 100.000 pedidos/dia (conta inteira); 10 ms de CPU por pedido |
| D1 | 5 milhões de linhas lidas/dia, 100 mil gravadas/dia, 5 GB |
| R2 | 10 GB, 1 milhão de operações classe A/mês, 10 milhões classe B/mês, saída grátis |

- O uso previsto (alguns milhares de pedidos/dia) cabe no gratuito. O app pausa o pull quando a tela fica em segundo plano.
- **Ponto de atenção:** hash de senha no login pode passar de 10 ms de CPU. Usar PBKDF2 nativo (Web Crypto) e medir; se não couber, o plano pago (US$ 5/mês) resolve.
- Se a API estourar o limite diário, os arquivos do app continuam servidos e a presença cai no offline de reserva até a meia-noite UTC.

Observações do drift no navegador: servir `sqlite3.wasm` com `Content-Type: application/wasm` e incluir `drift_worker.js` na pasta `web/`.

## Modo híbrido: o que funciona offline

| Funcionalidade | Modo | Motivo |
|---|---|---|
| Lançar presença (marcada **ao vivo** na aula) | **online primeiro, offline de reserva** | a internet da academia não é garantida; sem reserva, o app trava na chamada e todos voltam ao papel |
| Consultar turmas e alunos necessários para lançar | **offline (leitura)** | a tela de lançamento precisa abrir sem sinal |
| Mensalidades, cadastros (alunos, turmas, quadro, matrículas), regras, relatórios, usuários, acessos, tenants | **online** | ninguém lança pagamento no tatame; o servidor valida na hora (ex.: código de aluno único) e o aparelho guarda menos dados |

### Online primeiro, offline de reserva
- **Com internet:** cada marcação é gravada no SQLite local e **enviada na hora** (push imediato). Na prática se comporta como um sistema online.
- **Disponível para todos:** com a tela de lançamento aberta, o app faz pull da turma **a cada poucos segundos** (ex.: 10–15 s) e ao voltar para a tela. Duas assistentes na mesma aula veem as marcações uma da outra quase ao vivo. Se um dia precisar de tempo real, dá para acrescentar WebSocket (Durable Objects) sem mudar o modelo.
- **Sem internet:** a marcação fica na `outbox` e sobe sozinha quando o sinal voltar.
- **Status sempre visível** na tela de lançamento: "Tudo enviado ✓" ou "N marcações aguardando envio", mais a hora da última atualização.
- Duas pessoas marcando a mesma aula não geram conflito: chave única `(aula_id, aluno_id)` soma as marcações; desmarcar segue *last-write-wins*.
- Validar na academia: abrir um site pelo celular no tatame em alguns horários de aula para saber com que frequência a reserva vai entrar em ação.

### Permissões e offline
As regras de acesso não atrapalham o offline:
- O pull só traz as turmas a que o usuário tem acesso, então o aparelho nunca tem dados que ele não pode ver.
- O app usa a mesma matriz de permissões para esconder o que o usuário não pode fazer, mesmo sem internet.
- A API reconfere tudo no push. Se o acesso de alguém for retirado enquanto estava offline, os lançamentos dele são recusados, ficam com erro na outbox e o app avisa; na sincronização seguinte a turma some do aparelho.
- O que mexe com permissão (usuários, acessos, tenants) é online, então não existe "permissão offline" para conflitar.

Sem conexão, as telas online mostram um aviso e ficam desabilitadas. Se no futuro for preciso cadastrar offline, a estrutura de sync já permite liberar.

## Tenants e usuários

- **Tenant = academia/equipe**; professor autônomo é um tenant com um usuário.
- Professor e assistente são **usuários**; o que muda é a coluna **`users.tipo`**, que define as permissões.

| Permissão | `superadmin` (administrador do sistema) | `professor` | `assistente` |
|---|---|---|---|
| Cadastrar tenants | ✅ | — | — |
| Criar os primeiros professores do tenant e fazer a carga inicial (importação) | ✅ | — | — |
| Cadastrar usuários (professores, assistentes) e definir acesso às turmas | — | ✅ | — |
| Cadastrar alunos, turmas, quadro de aulas, matrículas | — | ✅ | ✅ |
| Lançar presenças e mensalidades | — | ✅ | ✅ |
| Configurar a turma (frequência mínima, cabeçalho, regras) | — | ✅ | ✅ |

- `superadmin` não pertence a tenant (`tenant_id` nulo) e não aparece dentro dos tenants; suas telas são só online.
- As permissões ficam numa **matriz fixa no código** (tipo → ações), usada pelo app para esconder botões e pela API para autorizar. Se um dia precisar de permissões sob medida, a matriz vira tabela sem mudar o resto.
- **Acesso N:N** em `turma_usuarios`: um usuário acessa N turmas; uma turma é acessada por N usuários. Professores e assistentes só veem e lançam nas turmas a que têm acesso.
  - Ao criar uma turma, quem criou ganha acesso a ela automaticamente.
  - Alunos são do tenant: qualquer usuário vê o cadastro de alunos para poder matricular.
- Quem lança no dia a dia são as assistentes que hoje cuidam das planilhas; cada uma tem seu usuário, e `created_by`/`updated_by` registram quem lançou.
- Alunos pertencem ao tenant e podem estar em várias turmas, sem cadastro duplicado.
- A API tira `tenant_id` e `tipo` do token, nunca do app.
- O pull de cada usuário traz só as turmas a que ele tem acesso e os alunos matriculados nelas.
- **O tenant é identificado pelo login**: todos acessam `controlepresenca.tghservices.com.br`.
- Subdomínio por tenant (ex.: `equipejuniao.tghservices.com.br`) fica para depois e é opcional. Precisa ser de **um nível** abaixo de `tghservices.com.br`, que é o que o certificado gratuito da Cloudflare cobre.

## Como a sincronização funciona (presença)

### Regra de ouro
A tela de lançamento **nunca** fala direto com a API. Ela lê e grava só no SQLite local. Um serviço de sincronização separado conversa com a API.

### Colunas obrigatórias em toda tabela sincronizada
| Coluna | Para quê |
|---|---|
| `id TEXT` (UUID v7, gerado no app) | criar registros offline sem colidir com outros aparelhos |
| `tenant_id TEXT` | isolamento por tenant (diagrama 2) |
| `created_at`, `updated_at` (ISO, UTC) | `updated_at` decide o conflito (última edição vence) |
| `excluido INTEGER 0/1` | soft delete (diagrama 3); exclusão também precisa sincronizar |
| `server_version INTEGER` | só no servidor: número crescente gravado a cada alteração; é o cursor do pull |
| `created_by`, `updated_by` | auditoria |

Local, além disso: tabela **`outbox`** (`id`, `tabela`, `registro_id`, `operacao`, `payload`, `tentativas`, `erro`, `criado_em`).

### Fluxo
1. **Gravar**: numa única transação local, salva o registro e insere uma linha na `outbox`.
2. **Push**: `POST /sync/push` com o lote da outbox. A API valida permissão e regras, aplica *last-write-wins* por `updated_at`, dá um novo `server_version` e devolve os ids aceitos. O app apaga essas linhas da outbox.
3. **Pull**: `GET /sync/pull?desde=<ultimo_server_version>` devolve tudo que mudou (inclusive excluídos) nas turmas do usuário. O app grava no SQLite local e guarda o novo cursor.
4. **Quando sincronizar**: push logo após cada marcação; pull a cada 10–15 s com a tela de lançamento aberta; também ao abrir o app, no evento `online` e a cada poucos minutos nas outras telas. Não depender de Background Sync, que não existe no Safari/iOS.

Por que `server_version` e não a hora do celular para o pull: relógio de celular pode estar errado. O cursor do servidor nunca perde alterações.

### Conflitos
- Presença é quase só inserção; chave única `presencas (aula_id, aluno_id)`: dois aparelhos marcando o mesmo aluno resultam num registro só.
- Aula regular: id determinístico (UUID v5 de `turma_id` + `data_aula`) e no máximo uma por turma e data, evitando duas aulas iguais criadas offline.
- Mensalidade (online): chave única `(matricula_id, competencia)` validada pelo servidor.
- No resto, a última edição vence (`updated_at`).

### Regras de negócio nos dois lados
As validações rodam **no app** (resposta imediata offline) e **de novo na API**, que tem a palavra final:
- não lançar presença em dia futuro;
- aluno só pode ser marcado dentro do período da matrícula;
- aula **regular** só nos dias marcados como *regular* no quadro de aulas vigente;
- aula de **reposição fixa** aparece nos dias marcados como *reposição* no quadro; **reposição avulsa** pode ser em qualquer dia não futuro.

Se a API rejeitar um item, ele fica marcado com erro na outbox e o usuário vê um aviso.

### Login e token offline
- O primeiro login exige internet.
- Guardar o access token (curto) e um refresh token (longo, ex.: 30 dias).
- Offline, o app continua lançando presença com a sessão salva. Se o token expirar, a sync pede novo login **sem perder a outbox**.

## Segurança

| Risco | Mitigação |
|---|---|
| Aparelho perdido/roubado ou usado por outra pessoa | **dados mínimos offline** (código, nome, turma, período da matrícula, presenças); mensalidades e dados sensíveis só no servidor; PIN opcional para abrir o app |
| Computador compartilhado | logout apaga o banco local e a outbox (avisar se houver itens não enviados) |
| Sessão ativa em aparelho perdido | admin revoga o usuário; refresh token é invalidado; na próxima conexão o app recebe a revogação e apaga os dados locais |
| Banco local adulterado | toda gravação é revalidada na API (permissão, tenant, regras); o app nunca envia `tenant_id` confiável |
| XSS | CSP restrita, sem scripts de terceiros |
| LGPD (muitos alunos são menores) | CPF, RG, endereço, telefones e dados dos responsáveis **nunca** vão para o aparelho; só consulta online |

## Relatórios e regras configuráveis

- **Nenhum total é gravado.** Semanal, mensal, anual, por aluno e inadimplência são calculados a partir de `aulas` + `presencas` (+ `mensalidades`).
- Falta = aula prevista (regular, dentro da matrícula) sem presença.
- **Cabeçalho dos relatórios/impressão:** dados do tenant e da turma. Se preenchido, o campo `cabecalho_impressao` do tenant e o da turma também aparecem (ex.: para incluir o nome do professor).
- **Regras** ficam numa tabela `regras` com tipos pré-definidos e parâmetros (JSON), não fórmulas livres:
  - escopo: padrão do tenant, sobrescrito por professor ou turma;
  - exemplos de tipo: `frequencia_minima_graduacao`, `contagem_reposicao` (conta como presença / separado / não conta), `vencimento_mensalidade`.
- A primeira regra a implementar é a **frequência mínima para graduação**.

### Regra: frequência mínima para graduação
- **Fórmula:** `frequência = presenças do aluno ÷ aulas regulares lançadas no período`, em %.
  - Denominador: só aulas **já lançadas** (dia sem aula lançada, como feriado, não conta) e só as que caem **dentro da matrícula** do aluno na turma.
  - Numerador: presenças do aluno nessas aulas **+ presenças em aulas de reposição** (a reposição conta; padrão `conta_reposicao = true`). A frequência é limitada a 100%.
- **Período de apuração:** semestre, jan–jun e jul–dez (configurável).
- **Graduação:** no início de junho e de dezembro, ou seja, antes do fim do semestre. Na data da graduação, a frequência é calculada com o que foi lançado **do início do semestre até aquele dia**.
- **Percentual mínimo: campo `turmas.frequencia_minima`**, configurado em cada turma.
- Demais parâmetros na tabela `regras` (JSON): `{ "periodos": [["01-01","06-30"],["07-01","12-31"]], "meses_graduacao": [6, 12], "conta_reposicao": <bool> }`.
- Relatório: lista dos alunos da turma com a frequência atual do semestre, destacando quem está abaixo do mínimo, para o professor consultar antes da graduação.

### Regra: lista do lançamento (alunos frequentes)
- O lançamento mostra só os alunos **frequentes**: presentes em ao menos `percentual_minimo`% das últimas `ultimas_aulas` aulas regulares da turma (padrão 30% de 8), ordenados pela frequência.
- Matrícula com menos de `ultimas_aulas` aulas lançadas é tratada como **nova** e sempre aparece.
- Os demais ficam recolhidos e na busca; marcar um deles o traz de volta para os frequentes.
- Calculada no aparelho com as presenças sincronizadas (funciona offline).
- Tipo `lista_lancamento` na tabela `regras`, escopo turma: `{ "percentual_minimo": 30, "ultimas_aulas": 8 }`.

### Regra: alunos sumidos
- Aviso no início para alunos com matrícula aberta e sem presença há mais de `semanas` semanas (padrão 4), com atalho para encerrar a matrícula (data de fim sugerida = última presença).
- Tipo `alunos_sumidos` na tabela `regras`, escopo turma: `{ "semanas": 4 }`.

### Logotipo e ícone do app por academia
- Endereço único para todos; a academia é conhecida **depois do login**.
- O login mostra o logotipo da TghServices. Após o login, app e relatórios mostram o logotipo da academia.
- O convite para instalar o PWA só aparece **após o login**. O manifesto (`/api/manifesto`, pedido com credenciais) é montado pelo Worker com o `nome_curto` e os ícones da academia do usuário; o `apple-touch-icon` é trocado pelo app após o login. Sem logotipo, usa o ícone da TghServices.
- Limitação conhecida: instalar pelo menu do navegador antes do login fica com o ícone da TghServices.
- No envio do logotipo, o app gera ícones 192 e 512 px (com margem de segurança para ícone redondo) e envia ao R2.

## Modelo de dados

O esquema do servidor (D1) está em [`db/migrations/0001_inicial.sql`](../../db/migrations/0001_inicial.sql), testado com `node --test db/`. O banco local do app (drift) usa um subconjunto dele, sem as colunas sensíveis.

**MER e dicionário de dados completo: [`docs/banco-de-dados.md`](../banco-de-dados.md).** Resumo:

| Tabela | Sincronizada? | Observações |
|---|---|---|
| `tenants` | não | `nome`, `subdominio` (opcional), `cabecalho_impressao` |
| `usuarios` | não | `tipo`: `superadmin` (sem tenant), `professor` e `assistente` (com tenant); e-mail único no sistema todo; senha em PBKDF2 |
| `sessoes` | não | refresh tokens (guarda só o hash); revogar = preencher `revogado_em` |
| `turmas` | sim | `frequencia_minima` (0–100), `cabecalho_impressao`; nome único por tenant |
| `turma_usuarios` | sim | acesso N:N; único por `(turma_id, usuario_id)` |
| `alunos` | sim, **só** `codigo`, `nome`, `ativo` | `codigo` único por tenant (sem diferenciar maiúsculas); CPF, RG, endereço, telefones e responsáveis ficam só no servidor |
| `graduacoes` | não | faixa, grau, data |
| `matriculas` | sim | `data_inicio`, `data_fim` (nulo = em aberto), `situacao` (matriculado, remanejado, encerrado) |
| `quadros_aulas` | sim | dias da semana habilitados, com vigência |
| `aulas` | sim | `tipo` regular ou reposicao; no máximo **uma regular por turma e data** |
| `presencas` | sim | só quem veio; única por `(aula_id, aluno_id)`, mesmo excluída (desmarcar e remarcar alternam `excluido`) |
| `regras` | não | escopo `tenant`, `turma` ou `usuario`; `parametros` em JSON validado |
| `controle_versao` | — | contador global que gera o `server_version` |

Decisões de modelagem:
- **Id da aula regular é determinístico** (UUID v5 de `turma_id` + `data_aula`): dois aparelhos offline que abrem a mesma aula geram o mesmo id, sem conflito.
- Unicidades de negócio valem só para registros não excluídos (índices parciais), exceto `presencas`, que reaproveita a mesma linha.
- Não existe cadastro de professor separado: professor é um usuário e não aparece nos relatórios por padrão.
- Coerência entre tenants (ex.: aluno e turma do mesmo tenant) é garantida pela API.
- **Migração `0002_quadro_reposicao_e_identidade.sql`**, aprovada junto com os wireframes:
  - `quadros_aulas`: cada dia da semana passa de 0/1 para `0` sem aula, `1` regular, `2` reposição (dia fixo de reposição);
  - aula de reposição fixa também ganha id determinístico (UUID v5 de `turma_id` + `data_aula` + `reposicao`);
  - `tenants`: `logotipo_key`, `nome_curto` e as chaves dos ícones gerados (R2).
- `mensalidades` entra numa migração da Fase 2: `matricula_id`, `competencia` (mês/ano), `valor` (centavos), `data_pagamento` (data informada), `forma_pagamento`, `comprovante_key`. Situação (pago/pendente/atrasado) é calculada.

## Importação das planilhas
- As planilhas atuais são modelos impressos sem dados digitados; importar só a **lista de alunos** (código + nome) a partir das abas da presença semanal/anual.
- Antes de gravar, gerar um relatório de **códigos duplicados** e nomes repetidos para o professor resolver.

## Decisões pendentes
1. Se tenant e turma tiverem `cabecalho_impressao`, aparecem os dois ou o da turma substitui o do tenant? (Sugestão: os dois, tenant em cima.)
2. Valor da mensalidade fica na turma, na matrícula ou nos dois (turma como padrão, matrícula como exceção)?