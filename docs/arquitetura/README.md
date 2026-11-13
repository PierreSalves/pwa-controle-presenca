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
| Cache do app offline | **service worker próprio** (`app/web/sw.js`, sem Workbox) | o Flutter não gera mais um service worker offline-first (a partir da 3.41 ele só limpa o antigo). Detalhes em "Abrir sem internet e CSP" |
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
| Relatórios de presença (tela 7) | **offline (leitura)** | calculados no aparelho a partir das aulas e presenças já sincronizadas; nada novo vai para o aparelho |
| Mensalidades, cadastros (alunos, turmas, quadro, matrículas), regras, usuários, acessos, tenants | **online** | ninguém lança pagamento no tatame; o servidor valida na hora (ex.: código de aluno único) e o aparelho guarda menos dados |

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

### No app (`app/lib/dados/`)
- `banco_local.dart`: esquema drift (subconjunto do D1, sem dados sensíveis) + `outbox` + `estado_sync` (cursor e turmas permitidas). O código gerado (`banco_local.g.dart`) fica no repositório; depois de mudar o esquema, rodar `dart run build_runner build` em `app/`.
- `repositorio_presenca.dart`: a tela de lançamento só fala com ele. Valida as mesmas regras da API (dia futuro, quadro, matrícula), grava a aula do quadro com o id determinístico e a presença, e põe na outbox na mesma transação. A outbox tem **uma linha por registro**: marcar e desmarcar antes do envio só atualiza a linha.
- `servico_sincronizacao.dart`: push da outbox (apaga os aceitos, marca os recusados com o erro e não os reenvia; uma nova alteração do registro limpa o erro) e pull pelo cursor. Registro com alteração pendente não é sobrescrito pelo pull. Turma retirada é apagada do aparelho (com a outbox dela) e o pull recomeça do zero.
- `abrir_banco.dart`: abre o banco no navegador com `web/sqlite3.wasm` e `web/drift_worker.js`, copiados das releases oficiais do drift (mesma versão do `pubspec.lock`; ao atualizar o drift, baixar os dois de novo da release `drift-<versão>` e conferir o SHA-256). Nos navegadores Chromium o drift usa um SharedWorker com IndexedDB. A pré-visualização do Claude Desktop não deixa SharedWorker fazer `fetch`; para testar o app ali, usar o Edge ou o Chrome.
- `cliente_api.dart`: HTTP para `/api/...` no mesmo domínio. O token de acesso fica só na memória e é renovado pelo cookie (30 s antes de expirar ou depois de um 401), **uma renovação por vez**, porque o servidor gira o cookie a cada renovação e duas simultâneas encerrariam a sessão. Falha de rede → `SemConexao`; renovação recusada → `SessaoEncerrada`.
- `consulta_inicio.dart`: leitura para o Início (turmas com dias do quadro vigente e matriculados hoje, resumo do ano, abaixo do mínimo e sumidos) e para a frequência do semestre. Recalcula quando o banco muda.
- `consulta_lancamento.dart`: leitura para a tela de lançamento (dias de aula da semana pelo quadro, matriculados na data com a frequência da lista do lançamento e quem já foi marcado). Observa o banco e recalcula a cada marcação ou pull.

### Sessão e sincronização no app (`app/lib/estado/`)
- `sessao_app.dart`: o usuário logado fica no `estado_sync` do banco local, então o app **abre sem internet** e confere a sessão em seguida. Se o servidor responder que a sessão acabou (saiu, expirou, usuário revogado), apaga o banco local e volta ao login. O primeiro login precisa de internet e só termina depois da primeira carga (pull desde 0).
- `coordenador_sincronizacao.dart`: uma rodada por vez (push e depois pull); um pedido durante uma rodada agenda outra logo depois. Roda após cada marcação e a cada 12 s com a tela de lançamento aberta. Indica online/offline para o status "Tudo enviado ✓ / N aguardando envio · sem internet".
- Sair: tenta enviar a outbox antes; se ainda houver pendências, avisa que serão perdidas.

### Interface e navegação no app (v2)
- Aparência e componentes: [`docs/telas/componentes.md`](../telas/componentes.md) (tokens em `app/lib/telas/tema.dart`, componentes em `componentes.dart`).
- Rotas com endereço (`/`, `/lancar`, `/relatorios`, `/alunos`, `/turmas`, `/usuarios`) em `app/lib/telas/navegacao.dart`, com `usePathUrlStrategy` (sem `#`). Cada rota passa pelo `PortaoSessao` (sem login, mostra a tela de entrar); rota sem permissão cai no Início. O Worker (`not_found_handling: single-page-application`) e o service worker devolvem o `index.html` para qualquer endereço.
- No desktop (≥ 1000 px) o menu lateral fica em volta do navegador interno (`MaterialApp.builder`), por isso continua visível ao abrir um aluno ou uma turma. O navegador é um contêiner próprio de acessibilidade: a barreira de cada rota bloqueia, no mesmo contêiner, o que é desenhado antes dela.
- Ao sair ou ter a sessão encerrada, a pilha volta para `/`.

### Telas online no app (cadastros)
- `app/lib/dados/repositorio_alunos.dart` fala direto com a API (`ClienteApi.enviar`), sem banco local: os dados sensíveis do aluno ficam **só na memória da tela**. Depois de salvar, matricular ou encerrar, o app roda uma sincronização para o lançamento ver o nome e as matrículas novas.
- Sem internet, a tela mostra "Sem internet. O cadastro precisa de conexão." e um botão para tentar de novo.
- O PUT do aluno grava todos os campos: os campos sem tela (ex.: `sexo`) voltam como vieram, para não serem apagados.
- `app/lib/dados/repositorio_usuarios.dart` (tela 11, só professor): o cadastro e a edição abrem na própria lista, como no wireframe ("Novo: nome · e-mail · tipo · turmas"). Salvar faz o `PUT` dos dados e, se as turmas mudaram, o `PUT .../turmas`. Redefinir a senha (quem esqueceu) encerra as sessões da pessoa. O professor não muda o próprio tipo nem se desativa (a API recusa e a tela já bloqueia).
- Importação (telas 8b e 8c): o usuário cola as colunas código e nome copiadas da planilha. `app/lib/regras/lista_colada.dart` separa cada linha por tab, ponto e vírgula ou espaço, ignora linhas em branco e o cabeçalho, e guarda o número da linha colada; a API (`POST /api/alunos/importacao`) faz o relatório e só grava com `confirmar: true` e sem erros. A tela traduz as linhas do relatório para as linhas do texto colado.
- `app/lib/dados/repositorio_turmas.dart` (tela 10): salvar a turma faz só as chamadas necessárias, em ordem:
  1. dados (`POST`/`PUT /api/turmas`);
  2. quadro (`POST .../quadros`, só se algum dia mudou; vale a partir de hoje por padrão, e a mesma data corrige o último quadro);
  3. regras (`PUT .../regras`, só se mudaram);
  4. acessos (`PUT .../acessos`, só o professor e só se mudaram).

  O menu "Turmas" abre a lista no padrão da tela 3, com "+" para criar.
- Textos só com caracteres da fonte embutida: `test/telas/caracteres_test.dart` falha se aparecer um símbolo fora dela (seta, ✓, emoji).

### Contrato da API de sync (implementado em `api/src/rotas/sync.ts`)
Exige login e a permissão `lancar_presenca` (professor e assistente).

**`GET /api/sync/pull?desde=<cursor>`** → `{ cursor, turmas_permitidas, turmas, turma_usuarios, quadros_aulas, matriculas, alunos, aulas, presencas }`
- `desde=0` devolve tudo (primeira carga); depois, só o que tem `server_version > desde`, inclusive excluídos.
- `alunos` traz só `id`, `codigo`, `nome`, `ativo` e colunas de sync (sem dados sensíveis).
- Cada turma traz `regras` (`lista_lancamento` e `alunos_sumidos`, já com os valores padrão), para o lançamento funcionar offline. Alterar uma regra atualiza o `server_version` da turma.
- Se `turmas_permitidas` mudar em relação ao que o app tem, o app apaga os dados das turmas que saíram e refaz o pull com `desde=0`.

**`POST /api/sync/push`** com `{ operacoes: [{ id, tabela, registro }] }` (até 500) → `{ aceitos: [id], rejeitados: [{ id, erro }] }`
- `tabela`: `aulas` (`id`, `turma_id`, `data_aula`, `tipo`, `excluido`, `updated_at`) ou `presencas` (`id`, `aula_id`, `aluno_id`, `excluido`, `updated_at`).
- Códigos de rejeição: `dados_invalidos`, `tabela_nao_permitida`, `turma_sem_acesso`, `data_futura`, `dia_sem_aula_regular`, `id_aula_invalido`, `dia_sem_reposicao_fixa`, `aula_inexistente`, `aula_excluida`, `fora_da_matricula`. O app marca o item da outbox com o erro e avisa o usuário.
- Aula regular e reposição fixa usam id **UUID v5** de `turma_id|data_aula|tipo` com o namespace fixo `6f1c2b8e-4a3d-5e7f-9b0a-1c2d3e4f5a6b`; a API recusa id diferente. Reposição avulsa usa UUID v7.
- Presença é gravada por *upsert* na chave `(aula_id, aluno_id)`; vence o `updated_at` mais novo. `updated_at` do aparelho além de 5 min no futuro é limitado a "agora".
- Todas as linhas aceitas num push recebem o mesmo `server_version`, numa única transação (cabe no limite de consultas por requisição do D1).
- "Hoje" é calculado no fuso `America/Sao_Paulo`.

**Regras compartilhadas:** os casos de teste de data futura, dia da semana, matrícula vigente, tipo do dia no quadro e id determinístico da aula ficam em [`docs/casos-regras/presenca.json`](../casos-regras/presenca.json) e rodam na API e no app.

### API de cadastros (online)
Rotas que o app chama direto, só com internet. Respostas e erros no formato `{ erro: '<codigo>' }`. Toda gravação em tabela sincronizada incrementa o `server_version`, então o app recebe a mudança no pull seguinte.

**Turmas** (`api/src/rotas/turmas.ts`, tela 10). Exige `gerenciar_turmas` (professor e assistente). O professor vê todas as turmas da academia; a assistente, só as liberadas para ela. Turma de outra academia ou sem acesso responde `404 turma_nao_encontrada`.

| Rota | O que faz |
|---|---|
| `GET /api/turmas` | turmas visíveis, com `alunos_matriculados` (matrícula vigente hoje) |
| `POST /api/turmas` | cria (`nome`, `descricao`, `frequencia_minima`, `cabecalho_impressao`); quem cria ganha acesso; nome repetido → `409 nome_ja_existe` |
| `GET /api/turmas/:id` | `{ turma, quadros, regras, acessos }` para a tela de configuração |
| `PUT /api/turmas/:id` | altera os dados da turma |
| `DELETE /api/turmas/:id` | exclusão lógica; a turma some do aparelho no próximo pull |
| `POST /api/turmas/:id/quadros` | novo quadro a partir de `vigencia_inicio` com `dias` (`0` sem aula, `1` regular, `2` reposição); o quadro anterior termina na véspera; mesma data de início corrige o último; início anterior ao último → `409 vigencia_anterior_ao_quadro_atual` |
| `PUT /api/turmas/:id/regras` | `lista_lancamento` (`percentual_minimo` 0–100, `ultimas_aulas` 1–52) e/ou `alunos_sumidos` (`semanas` 1–52); vigência a partir de hoje |
| `PUT /api/turmas/:id/acessos` | só professor (`gerenciar_acessos`): lista completa `usuario_ids`; usuário de outra academia ou superadmin → `400 usuario_invalido` |

**Alunos** (`api/src/rotas/alunos.ts`, telas 8 e 9). Exige `gerenciar_alunos`. Alunos são da academia: todos os professores e assistentes veem o cadastro. Os dados sensíveis só saem por estas rotas, nunca pelo sync.

| Rota | O que faz |
|---|---|
| `GET /api/alunos?busca=&inativos=1` | lista (busca por nome ou código), com as turmas das matrículas em aberto |
| `GET /api/alunos/proximo-codigo` | próximo código numérico livre (mantém os zeros à esquerda: `09` → `10`) |
| `POST /api/alunos` | cria; código único na academia sem diferenciar maiúsculas → `409 codigo_ja_existe` |
| `GET /api/alunos/:id` | `{ aluno, matriculas, graduacoes }`, com os dados sensíveis |
| `PUT /api/alunos/:id` | altera |
| `DELETE /api/alunos/:id` | exclusão lógica do aluno e das matrículas dele; o código fica livre |
| `POST /api/alunos/:id/graduacoes` · `DELETE /api/alunos/:id/graduacoes/:gid` | faixa, grau e data |
| `POST /api/alunos/importacao` | `{ alunos: [{ codigo, nome }], confirmar }` (até 2.000 linhas; `(10A)` vira `10A`). Sem `confirmar`, só o relatório: linhas incompletas, códigos repetidos na planilha, códigos já cadastrados e nomes repetidos (este só avisa). Com `confirmar: true`, grava tudo se não houver bloqueio |

**Matrículas** (`api/src/rotas/matriculas.ts`). Exige `gerenciar_matriculas` e acesso à turma.

| Rota | O que faz |
|---|---|
| `POST /api/matriculas` | `aluno_id`, `turma_id`, `data_inicio`, `data_fim` e `situacao` opcionais (sem situação: com fim é `encerrado`, sem fim é `matriculado`); dias em comum com outra matrícula do aluno na mesma turma → `409 matricula_sobreposta` |
| `PUT /api/matriculas/:id` | altera período e situação; usado também para encerrar (alunos sumidos) |
| `DELETE /api/matriculas/:id` | exclusão lógica (lançada por engano) |

**Usuários** (`api/src/rotas/usuarios.ts`, tela 11). Só professor (`gerenciar_usuarios` e `gerenciar_acessos`). O professor cria o usuário com uma senha inicial e passa para a pessoa (sem autocadastro nem e-mail na Fase 1).

| Rota | O que faz |
|---|---|
| `GET /api/usuarios` | usuários da academia com as turmas de cada um |
| `POST /api/usuarios` | `nome`, `email`, `tipo` (`professor`/`assistente`), `senha` (8+), `turma_ids` opcional; e-mail é único no sistema → `409 email_ja_existe` |
| `PUT /api/usuarios/:id` | `nome`, `email`, `tipo`, `ativo`; desativar encerra as sessões na hora; o professor não muda o próprio tipo nem se desativa → `409 nao_pode_alterar_o_proprio_acesso` |
| `POST /api/usuarios/:id/senha` | redefine a senha de outro usuário (esqueceu a senha) e encerra as sessões dele |
| `PUT /api/usuarios/:id/turmas` | lista completa de `turma_ids` que o usuário acessa |

**Dados da academia** (`api/src/rotas/academia.ts`, tela 14). Só professor (`editar_tenant`): `GET /api/academia` e `PUT /api/academia` (`nome`, `nome_curto` até 15 caracteres, `cabecalho_impressao`). O envio do logotipo e a geração dos ícones no R2 ficam numa etapa própria.

**Administrador do sistema** (`api/src/rotas/admin.ts`, tela 13). Só superadmin (`gerenciar_tenants`).

| Rota | O que faz |
|---|---|
| `GET /api/admin/academias` | academias com número de usuários ativos, alunos e turmas |
| `POST /api/admin/academias` | cria a academia e o primeiro professor (`professor: { nome, email, senha }`) numa gravação só |
| `PUT /api/admin/academias/:id` | `nome`, `nome_curto`, `cabecalho_impressao`, `ativo`; desativar encerra as sessões de todos os usuários dela |
| `GET`/`POST /api/admin/academias/:id/professores` | lista e cria professores |
| `DELETE /api/admin/academias/:id/professores/:usuarioId` | desativa o professor e encerra as sessões |
| `POST /api/admin/academias/:id/alunos/importacao` | carga inicial; mesmas regras de `POST /api/alunos/importacao` |

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

### Autenticação (implementada em `api/src/rotas/autenticacao.ts`)
| Rota | O que faz |
|---|---|
| `POST /api/autenticacao/entrar` | e-mail + senha → token de acesso (JWT HS256, 15 min) no corpo e token de renovação em cookie `cp_renovacao` (HttpOnly, Secure, SameSite=Strict, caminho `/api/autenticacao`, 30 dias) |
| `POST /api/autenticacao/renovar` | troca o cookie por um novo token de acesso e **rotaciona** o token de renovação (o antigo deixa de valer) |
| `POST /api/autenticacao/sair` | revoga a sessão e apaga o cookie |
| `GET /api/eu` | usuário, academia e turmas liberadas |
| `POST /api/eu/senha` | troca a própria senha e encerra as outras sessões |

- Senhas: PBKDF2-SHA256 com 100.000 iterações (limite do runtime do Workers) e salt aleatório; comparação em tempo constante. E-mail inexistente também calcula um hash, para o tempo de resposta não revelar quais e-mails existem.
- Toda rota autenticada confere no banco que a sessão não foi revogada e que usuário e academia seguem ativos: **desativar um usuário bloqueia o acesso na hora**.
- Segredo do JWT: `JWT_SEGREDO` (local em `api/.dev.vars`, modelo em `.dev.vars.example`; produção via `wrangler secret put JWT_SEGREDO`).
- Primeiro usuário: `npm run criar-superadmin -- --email ... [--remoto]` (em `api/`).
- Pendente: limitar tentativas de login por IP/e-mail (proteção contra força bruta) antes de abrir para outras academias.

## Segurança

| Risco | Mitigação |
|---|---|
| Aparelho perdido/roubado ou usado por outra pessoa | **dados mínimos offline** (código, nome, turma, período da matrícula, presenças); mensalidades e dados sensíveis só no servidor; PIN opcional para abrir o app |
| Computador compartilhado | logout apaga o banco local e a outbox (avisar se houver itens não enviados) |
| Sessão ativa em aparelho perdido | admin revoga o usuário; refresh token é invalidado; na próxima conexão o app recebe a revogação e apaga os dados locais |
| Banco local adulterado | toda gravação é revalidada na API (permissão, tenant, regras); o app nunca envia `tenant_id` confiável |
| XSS | CSP restrita, sem scripts de terceiros |
| LGPD (muitos alunos são menores) | CPF, RG, endereço, telefones e dados dos responsáveis **nunca** vão para o aparelho; só consulta online |

### Abrir sem internet e CSP (implementado em `app/web/`)
- **Nada de terceiros:** por padrão o Flutter web baixa o CanvasKit (motor de desenho) de `www.gstatic.com` e a fonte Roboto de `fonts.gstatic.com`. O app usa a cópia do CanvasKit que vem no build (`canvasKitBaseUrl: 'canvaskit/'` em `web/flutter_bootstrap.js`) e a Roboto embutida em `app/fonts/` (cópia do SDK do Flutter, Apache 2.0). Evitar caracteres que a Roboto não tem (ex.: ✓): o Flutter baixaria uma fonte de reserva do Google. Usar ícone.
- **Service worker (`web/sw.js`):**
  - só cuida dos arquivos do app; `/api/` nunca passa pelo cache, porque os dados offline ficam no drift;
  - rede primeiro: sem resposta em 4 s, usa a cópia guardada; navegação (abrir o app ou recarregar) devolve o `index.html`;
  - na primeira visita o service worker ainda não controla a página, então `flutter_bootstrap.js` manda a lista do que a página carregou (`performance.getEntriesByType('resource')`) e ele guarda esses arquivos. Assim fica só a variante do CanvasKit que aquele navegador usa;
  - o `flutter_service_worker.js` que o build ainda gera não é registrado.
- **Cabeçalhos dos arquivos** (`web/_headers`, lido pelo Workers Static Assets): CSP `default-src 'self'` com `'wasm-unsafe-eval'` (CanvasKit e SQLite em WebAssembly), `style-src 'unsafe-inline'` (estilos que o Flutter cria) e `worker-src blob:`, mais `frame-ancestors 'none'`, `nosniff`, `no-referrer` e `Cache-Control: no-cache` para `index.html`, `sw.js` e `flutter_bootstrap.js`. As rotas `/api/*` têm os cabeçalhos do Worker (`secureHeaders`).
- Verificado no Edge: nenhuma requisição para fora do domínio, nenhum bloqueio da CSP e o app recarregando offline com os dados do aparelho.

## Relatórios e regras configuráveis

- **Nenhum total é gravado.** Semanal, mensal, anual, por aluno e inadimplência são calculados a partir de `aulas` + `presencas` (+ `mensalidades`).
- Falta = aula lançada (dentro da matrícula) sem presença do aluno; frequência = presenças + reposições ÷ aulas regulares lançadas (limite de 100%), a mesma regra da graduação.
- **Onde:** os relatórios de presença são calculados no app (`app/lib/regras/relatorios.dart`, montados em `app/lib/telas/relatorios/`) a partir do banco local, então funcionam offline. A mesma tabela montada vai para a tela e para a página impressa.
- **Impressão / PDF:** o app gera um HTML simples, sem script, e o abre numa aba nova a partir de um blob do próprio app (mesma origem, compatível com a CSP); a aba chama a impressão do navegador, onde dá para salvar em PDF. Semanal e anual em A4 paisagem; os demais em retrato.
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
- Implementação (`api/src/regras/frequencia.ts` e `app/lib/regras/frequencia.dart`, casos em `docs/casos-regras/frequencia.json`): `calcularFrequenciaNoPeriodo(inicio, fim)` lista os alunos matriculados no dia `fim`; percentual arredondado para baixo e limitado a 100, e nulo quando não há aula regular no período. Os períodos ainda são fixos (jan–jun e jul–dez; `calcularInicioDoSemestre`) e a reposição sempre conta. Os parâmetros da tabela `regras` entram quando a tela de regras existir.
- No app: tela 6 (frequência do semestre, até hoje) e aviso no Início com o número de alunos abaixo do mínimo; a "Freq. média" do resumo do ano é a média das frequências do ano dos alunos matriculados hoje.

### Regra: lista do lançamento (alunos frequentes)
- O lançamento mostra só os alunos **frequentes**: presentes em ao menos `percentual_minimo`% das últimas `ultimas_aulas` aulas regulares da turma (padrão 30% de 8), ordenados pela frequência.
- Matrícula com menos de `ultimas_aulas` aulas lançadas é tratada como **nova** e sempre aparece.
- Os demais ficam recolhidos e na busca; marcar um deles o traz de volta para os frequentes.
- Calculada no aparelho com as presenças sincronizadas (funciona offline).
- Tipo `lista_lancamento` na tabela `regras`, escopo turma: `{ "percentual_minimo": 30, "ultimas_aulas": 8 }`.
- Detalhes do cálculo (`api/src/regras/lista-lancamento.ts` e `app/lib/regras/lista_lancamento.dart`, casos em `docs/casos-regras/lista-lancamento.json`):
  - entram na conta as últimas `ultimas_aulas` aulas **regulares** da turma **antes** do dia do lançamento e dentro da matrícula do aluno. A aula do próprio dia fica fora, para a lista não mudar de ordem durante a aula;
  - percentual = presenças nessas aulas ÷ aulas, arredondado para baixo; reposições não entram;
  - "última presença" (mostrada na busca) considera qualquer aula, regular ou reposição, até o dia.

### Regra: alunos sumidos
- Aviso no início para alunos com matrícula aberta e sem presença há mais de `semanas` semanas (padrão 4), com atalho para encerrar a matrícula (data de fim sugerida = última presença).
- Tipo `alunos_sumidos` na tabela `regras`, escopo turma: `{ "semanas": 4 }`.
- Implementação (`calcularAlunosSumidos`, mesmos arquivos da frequência): matrícula **aberta** (sem data de fim) no dia de hoje cuja última presença é anterior a `semanas` × 7 dias. Quem nunca veio conta a partir do início da matrícula.
- Encerrar é online (`PUT /api/matriculas/:id` com `situacao = encerrado`); a data sugerida é a última presença ou, se o aluno nunca veio, o início da matrícula. O pull seguinte traz a matrícula encerrada para o aparelho.

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