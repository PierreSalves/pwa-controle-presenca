# TghServices — Controle de Presença

## Visão geral
Sistema para controlar a presença de alunos em aulas de esportes com professores particulares.
Objetivo inicial: substituir as planilhas usadas hoje por um professor de jiu-jítsu.

Objetivo geral:
- **facilitar o lançamento das presenças** pelo professor (rápido, no celular, inclusive sem internet);
- **gerar os relatórios automaticamente** (hoje o professor soma à mão);
- permitir **regras de cálculo configuráveis**, para o sistema se encaixar no jeito de cada professor trabalhar.

## Como é feito hoje (planilhas)
- As planilhas são **modelos impressos e preenchidos à mão**; não há dados digitados.
- **Presença semanal** (uma por mês): aluno × semanas 1ª a 5ª × dias de aula (ter/qua/qui). O professor marca **X em quem veio**. A coluna "PT" nunca foi usada e fica fora do sistema.
- **Presença anual**: aluno × JAN..DEZ; o professor soma à mão as presenças do mês e anota.
- **Mensalidade** (semestral): aluno × mês; ele anota a **data informada do pagamento**.
- Cada aluno tem um **código manual** (ex.: `(10A)`); por ser planilha, já houve dois alunos com o mesmo código.
- Importável: só a lista de alunos (código + nome).

## Escopo
### Fase 1 — Presença (MVP)
- Cadastro de alunos, turmas, quadro de aulas (dias e vigência), matrículas (aluno × turma com período)
- Lançamento de presença por aula (marca quem veio; falta = aula prevista sem presença)
- **Aula de reposição**: aula extra lançada fora do quadro, com `tipo = reposição`
- Relatórios calculados: semanal, mensal, anual, por aluno e por período
- **Regras configuráveis**; a primeira é a frequência mínima para graduação: % de presença sobre as aulas regulares já lançadas no semestre (jan–jun, jul–dez), consultada na graduação do início de junho e de dezembro; aulas de reposição contam (limite de 100%)
- **Reposição fixa** no quadro de aulas (cada dia: sem aula, regular ou reposição) + reposição avulsa
- **Lista do lançamento por frequência** (só frequentes; pouco frequentes na busca) e aviso de **alunos sumidos** para encerrar matrícula
- Logotipo da academia (app e relatórios) e **ícone do app instalado** da academia, com instalação oferecida só após o login
- Importação da lista de alunos das planilhas, com relatório de códigos duplicados
- **Telas aprovadas:** `docs/telas/README.md` (wireframes v1, 12/11/2026). Tela nova só com wireframe aprovado e registrado lá.

### Fase 2 — Mensalidades
- Data de pagamento informada, forma de pagamento; situação (pago / pendente / atrasado) **calculada** pelo vencimento configurado
- Anexo de comprovantes (imagem ou PDF)
- Visão de inadimplência do mês

## Usuários e tenants
- **Tenant = academia/equipe.** Um professor autônomo é um tenant com um usuário só.
- Todos são usuários; a coluna **`users.tipo`** define as permissões (matriz fixa no código, aplicada no app e na API):
  - `superadmin` (administrador do sistema, fora dos tenants): cadastra tenants, os primeiros professores de cada um e faz a carga inicial;
  - `professor`: tudo dentro do tenant, inclusive cadastrar novos professores e assistentes e definir o acesso às turmas;
  - `assistente`: lança presenças e mensalidades, cadastra alunos e turmas; **não** cadastra usuários.
- **Acesso usuário × turma é N:N** (`turma_usuarios`): um usuário acessa N turmas e uma turma é acessada por N usuários.
- Na prática quem lança as presenças são as assistentes, não o professor; a auditoria (`created_by`) mostra quem lançou.
- Alunos pertencem ao tenant e podem estar em várias turmas.
- O **percentual mínimo de frequência é configurado na turma**.
- Relatórios mostram os dados do tenant e da turma, não o professor. Tenant e turma têm um campo opcional `cabecalho_impressao` (ex.: nome do professor) usado nos cabeçalhos de impressão.
- Usuário não se autocadastra; o admin cria.

## Arquitetura (decidido)
Detalhes em `docs/arquitetura/README.md`.
- **App:** Flutter Web como PWA, com service worker próprio para abrir offline.
- **Banco local:** drift (SQLite via WebAssembly), mesmo esquema do D1.
- **API:** Cloudflare Worker em TypeScript (sugestão: Hono). **Banco:** D1. **Comprovantes:** R2.
- **Modo híbrido:**
  - **presença: online primeiro, offline de reserva.** A marcação é feita ao vivo na aula e a internet da academia não é garantida. Cada marcação grava no SQLite local + `outbox` e é enviada na hora; com a tela de lançamento aberta, o app busca as marcações dos outros a cada 10–15 s; sem sinal, a outbox guarda e envia quando voltar. A tela mostra sempre o status ("Tudo enviado ✓" / "N aguardando envio").
  - **online:** mensalidades, cadastros, edições, regras, usuários, acessos e tenants (o servidor valida na hora, ex.: código de aluno único).
  - **relatórios de presença:** calculados no aparelho a partir das presenças já sincronizadas (abrem também sem internet).
  - As permissões não atrapalham o offline: o aparelho só recebe as turmas permitidas e a API reconfere cada lançamento.
- Sincronização por push/pull com cursor `server_version`.
- IDs UUID v7 gerados no cliente.

## Segurança (requisitos)
- Isolamento por tenant **na API**, com o `tenant_id` vindo do token, nunca do app.
- Toda gravação vinda do app é revalidada na API (permissão, tenant, regras de negócio).
- **Dados mínimos offline:** código, nome, turma, período da matrícula e presenças. Mensalidades ficam só no servidor. CPF, RG, endereço, telefones e dados dos responsáveis ficam **só no servidor** (LGPD; muitos alunos são menores).
- Cada professor só sincroniza as próprias turmas.
- Logout apaga o banco local; revogar o usuário no servidor faz o app apagar os dados na próxima conexão.
- CSP restrita, sem scripts de terceiros.

## Stack
- App: Flutter Web (PWA) + drift
- API: Cloudflare Worker (TypeScript, Hono)
- Banco: Cloudflare D1; arquivos: Cloudflare R2
- Hospedagem do app: **Workers Static Assets** (app e API no mesmo Worker, mesmo domínio)
- Endereço: **`controlepresenca.tghservices.com.br`** (custom domain criado pelo Wrangler; não criar o registro DNS à mão). DNS do domínio na Cloudflare. O tenant é identificado pelo login, não pelo endereço.

## Convenções
**Regras de desenvolvimento completas em `docs/desenvolvimento.md` — seguir sempre.** Resumo:
- Nomes do domínio em português, sem acentos em identificadores (`frequencia_minima`, `calcularFrequencia`); termos técnicos do framework em inglês.
- Funções: um verbo no infinitivo, uma responsabilidade; sem "e"/"ou" nem verbos genéricos (`processar`, `gerenciar`). Prefixos: `obter` (local), `buscar` (remoto), `definir`, `eh`/`esta`/`tem`/`pode` (booleanos), `calcular`, `validar`.
- Git: branch por tarefa (`feat/`, `fix/`, `docs/`…) + Pull Request para a `main`; squash merge.
- Commits: Conventional Commits em português (`feat(app): adiciona …`).
- Testes obrigatórios para regras de negócio (casos compartilhados entre Dart e TS), sync e permissões/isolamento de tenant na API.
- Datas de calendário `AAAA-MM-DD` sem fuso; timestamps em UTC; dinheiro em centavos.
- Idioma da interface: português (Brasil)
- Datas no formato dd/mm/aaaa; fuso America/Sao_Paulo; moeda em R$
- Interface mobile-first e simples (o usuário não é técnico)
- Relatórios nunca guardam totais: sempre calculados a partir das presenças

## Comandos
Rodar a partir da raiz do repositório (Git Bash ou PowerShell). Pré-requisitos: Node.js LTS e Flutter stable no PATH.

| O quê | Comando |
|---|---|
| Testar migrações | `node --test db/` |
| API: instalar | `cd api && npm ci` |
| API: testes / lint / tipos / formato | `npm test` · `npm run lint` · `npm run tipos` · `npm run formatar` |
| API: regenerar tipos após mudar `wrangler.jsonc` | `npm run cf-typegen` |
| API: segredo local (uma vez) | copiar `api/.dev.vars.example` para `api/.dev.vars` e trocar o valor |
| Banco local: aplicar migrações | `cd api && npm run db:migrar:local` |
| Criar o superadmin | `cd api && npm run criar-superadmin -- --email voce@exemplo.com` (`--remoto` para o banco da Cloudflare) |
| App: testes / análise / formato | `cd app && flutter test` · `flutter analyze` · `dart format lib test` |
| App: rodar em desenvolvimento | `cd app && flutter run -d edge` |
| Tudo junto (app + API no Worker local) | `cd app && flutter build web` e depois `cd api && npm run dev` → http://localhost:8811 (a 8799 é usada por outro projeto) |
| Imagens dos wireframes | `bash docs/telas/gerar-imagens.sh` |
| Publicar em produção (precisa do `npx wrangler login`) | `cd api && npx wrangler d1 migrations apply DB --remote`, depois `cd app && flutter build web` e `cd api && npm run deploy` |

O CI (`.github/workflows/ci.yml`) roda tudo isso em cada PR.
