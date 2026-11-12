# TghServices — Controle de Presença

PWA para controlar a presença de alunos em aulas de esportes com professores particulares. O primeiro cliente é um professor de jiu-jítsu que hoje usa planilhas impressas e preenchidas à mão.

> **Status:** em planejamento. A documentação está pronta; o código ainda não começou.

## Objetivos

- **Lançar presença rápido**, pelo celular, durante a aula, mesmo com internet instável.
- **Gerar os relatórios automaticamente** (semanal, mensal, anual, frequência do semestre), sem somas à mão.
- **Regras de cálculo configuráveis**, para o sistema se adaptar ao jeito de cada professor trabalhar (ex.: frequência mínima para graduação por turma, aulas de reposição).

## Funcionalidades

### Fase 1 — Presença (MVP)
- Cadastro de alunos, turmas, quadro de aulas (dias e vigência) e matrículas
- Lançamento de presença por aula, com aulas de reposição fora do quadro
- Relatórios calculados por aluno, turma e período
- Frequência mínima para graduação (% sobre as aulas lançadas no semestre)
- Importação da lista de alunos das planilhas atuais

### Fase 2 — Mensalidades
- Registro de pagamento (data, forma) e anexo de comprovante
- Situação calculada (pago / pendente / atrasado) e visão de inadimplência

## Arquitetura

| Camada | Tecnologia |
|---|---|
| App | Flutter Web (PWA) |
| Banco local | drift (SQLite via WebAssembly) |
| API | Cloudflare Worker (TypeScript, Hono) |
| Banco central | Cloudflare D1 |
| Arquivos | Cloudflare R2 |

- **Presença: online primeiro, offline de reserva.** Cada marcação é enviada na hora; sem sinal, fica guardada no aparelho e sobe quando a conexão voltar. Quem está com a turma aberta vê as marcações dos outros em poucos segundos.
- **Demais funções são online** (cadastros, mensalidades, relatórios, usuários), validadas pelo servidor.
- **Multi-tenant:** cada academia/equipe é um tenant isolado. Usuários (`professor`, `assistente`) acessam só as turmas liberadas para eles; o administrador do sistema cadastra os tenants.

## Ambiente de desenvolvimento (Windows)

O script [`scripts/configurar-ambiente-windows.ps1`](scripts/configurar-ambiente-windows.ps1) instala Git, Node.js LTS, VS Code, Chrome, Flutter (stable) e Claude Code, e clona o projeto em `D:\workspace\Claude\projetos\controle-presenca`. Abra o PowerShell (não precisa ser como administrador) e rode:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
irm https://raw.githubusercontent.com/PierreSalves/pwa-controle-presenca/main/scripts/configurar-ambiente-windows.ps1 -OutFile $env:TEMP\configurar.ps1
& $env:TEMP\configurar.ps1
```

O SDK do Flutter e o cache do pub ficam em `D:\workspace\Claude\ferramentas` (o Flutter não aceita caminho com espaço). O script pode ser rodado de novo sem problema. O que protege o código é o GitHub: faça commit e push sempre.

## Documentação

- [Arquitetura](docs/arquitetura/README.md): stack, sincronização, tenants e permissões, segurança, modelo de dados e decisões pendentes
- [Regras de desenvolvimento](docs/desenvolvimento.md): nomes, padrão de funções, fluxo git, commits, testes, banco, segurança
- [Levantamento inicial](docs/levantamento-inicial/README.md): telas de referência, regras de negócio e tabelas da primeira versão
- [CLAUDE.md](CLAUDE.md): resumo do projeto e convenções
- [Contexto inicial](docs/contexto-inicial.md): histórico da ideia

## Convenções

- Interface em português (Brasil), mobile-first e simples
- Datas em dd/mm/aaaa, fuso America/Sao_Paulo, valores em R$
