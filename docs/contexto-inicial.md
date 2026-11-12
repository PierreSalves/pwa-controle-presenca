# Contexto inicial (vindo do claude.ai)

> **Histórico.** As decisões pendentes abaixo já foram resolvidas: a stack é Flutter Web + Cloudflare (Worker, D1, R2), não Next.js + Supabase. Veja `CLAUDE.md` e `docs/arquitetura/README.md`.

Resumo da conversa no Project "TghServices - Controle de Presença" do claude.ai (12/11/2026).

## Origem da ideia
- O professor de jiu-jítsu do Pierre controla presença e mensalidades manualmente em planilhas.
- Objetivo: um sistema pequeno que substitua essas planilhas, pensado para professores particulares de esportes em geral.

## O que já foi feito
- Criado o `CLAUDE.md` com visão geral, escopo (Fase 1: presença; Fase 2: mensalidades com comprovantes), usuários e convenções.
- Criada esta pasta do projeto, ainda sem código.

## Decisões pendentes
- Escolher a stack (frontend, backend, banco, hospedagem, armazenamento de comprovantes).
  - Sugestão levantada: Next.js + Supabase (banco Postgres, autenticação e storage para os comprovantes num só serviço).
- Definir o modelo de dados do MVP (alunos, turmas, aulas, presenças).
- Decidir como importar os dados das planilhas atuais (pedir uma cópia da planilha do professor).

## Próximo passo sugerido
Pedir ao Claude Code: "Leia o CLAUDE.md e docs/contexto-inicial.md e proponha a stack e a estrutura do MVP de presença."
