# Aparência e componentes

Referência da aparência das telas e de cada componente visual do app, como estão **implementados**. A origem é o wireframe v2 aprovado ([`wireframes-v2.html`](wireframes-v2.html)); o código fica em `app/lib/telas/` (tokens em [`tema.dart`](../../app/lib/telas/tema.dart), componentes em [`componentes.dart`](../../app/lib/telas/componentes.dart), menu e rotas em [`navegacao.dart`](../../app/lib/telas/navegacao.dart)).

**Regra:** componente novo ou mudança de aparência atualiza este arquivo no mesmo PR ([desenvolvimento, seção 10](../desenvolvimento.md#10-interface)). As telas usam os tokens e os componentes daqui, nunca cores ou estilos soltos.

## 1. Fundamentos

### 1.1 Cores (`CoresV2` em `tema.dart`)

| Token | Hex | Uso | Contraste |
|---|---|---|---|
| `tatame` | `#13557A` | Toda ação: botão principal, item ativo do menu, caixa marcada, dia selecionado, borda do campo em foco | Branco sobre ele: 8,05:1 |
| `tatameEscuro` | `#0E4462` | Hover do botão principal | — |
| `tatameClaro` | `#E3EEF4` | Botão secundário, voltar e botões só com ícone, etiquetas | `tatame` sobre ele: 6,83:1 |
| `tatameClaroHover` | `#D3E4EE` | Hover do secundário | — |
| `papel` | `#F5F6F4` | Fundo das telas (cinza frio, sem creme) | — |
| `cartao` | `#FFFFFF` | Cartões, campos, dias de aula | — |
| `menuLateral` | `#ECEFEB` | Fundo do menu lateral (desktop) | — |
| `grafite` | `#23262B` | Texto | 14:1 sobre `papel` |
| `nevoa` | `#5E646B` | Texto de apoio, rótulos, ícones do menu | 5,52:1 sobre `papel` |
| `linha` | `#E1E4E0` | Divisórias e contorno do dia futuro (decorativo) | — |
| `contorno` | `#868D94` | Contorno de campos e caixas de marcar | 3,1:1 ou mais (WCAG 1.4.11) |
| `desativado` | `#80878E` | Texto do dia futuro | 3,35:1 |
| `ok` / `okClaro` | `#2E6B45` / `#E4F1E8` | "Tudo enviado" | 5,46:1 |
| `aviso` / `avisoClaro` | `#8A5A00` / `#FBEFD5` | "N aguardando envio", avisos do Início | 5,20:1 |
| `ponta` / `pontaClaro` | `#B3261E` / `#FBE7E5` | Erro e ação que apaga ou encerra; percentual abaixo do mínimo | 5,50:1 |

Cores das faixas (só na faixa do aluno, seção 2.9): branca `#F4F4F2`, cinza `#8C8C8C`, amarela `#E8C33A`, laranja `#E07A2E`, verde `#3C8C4A`, azul `#2456A6`, roxa `#6A3D9A`, marrom `#6B4226`, preta `#1E1E1E`.

### 1.2 Tipografia

- **Lexend** (SIL OFL 1.1), embutida em `app/fonts/` (regular 400 e seminegrito 600). Nada de fonte da internet: sem rede, o app continua com texto.
- Toda `TextStyle` criada fora do tema herda a Lexend; **estilos de botão precisam da família explícita** (`fontFamily: 'Lexend'`), senão o Flutter cai na Roboto, que não está no app, e o texto some. O teste `test/telas/tema_test.dart` confere.
- Escala: 11 (etiqueta) · 13 (apoio, status) · 15 (texto e botões) · 17 (título da barra no celular) · 20 (valor dos indicadores) · 22 (título da página no desktop).
- Números em coluna (indicadores, percentuais, datas dos dias) com algarismos de largura fixa: `fontFeatures: numerosFixos`.
- Caracteres só os que a fonte tem (Latim, acentos, "·", "—", "…"); `test/telas/caracteres_test.dart` barra o resto (ex.: "✓", "→" viram ícone ou texto).

### 1.3 Ícones

Material Symbols (`material_symbols_icons`), traço fino (`weight: 300`, tamanho 22), definido no tema. Usar `Symbols.<nome>`, nunca `Icons.<nome>`.

### 1.4 Formas, sombras e espaços

| Elemento | Forma |
|---|---|
| Botões (principal e secundário) | Pílula (`StadiumBorder`) |
| Voltar e botões só com ícone | Círculo de 48 px |
| Cartão | Cantos de 16 px, sombra `sombraCartao` (duas camadas suaves), sem borda |
| Campo | Cantos de 12 px, contorno 1,5 px `contorno`; em foco, 2 px `tatame` |
| Caixa de marcar | Cantos de 7 px, contorno 2 px `contorno`; marcada em `tatame` |
| Dia de aula | Cantos de 14 px |
| Etiqueta | Cantos de 6 px |
| Item do menu lateral | Pílula |

- **Área de toque mínima: 48 px** em tudo que se toca (tema com `materialTapTargetSize.padded` e `minimumSize` 48).
- Margem das telas: 16 px no celular; 22 × 28 px no Início do desktop.

### 1.5 Layout e navegação

| | Celular (< 1000 px) | Desktop (≥ 1000 px, `ehDesktop`) |
|---|---|---|
| Menu | Escondido (☰, `MenuApp`) | **Menu lateral fixo** de 232 px à esquerda, sempre visível, inclusive com um aluno ou turma aberto |
| Título | Barra de topo, centralizado | Barra de topo (telas internas) ou cabeçalho da página (Início, D1) |
| Voltar | Círculo azul-claro | Igual; as telas principais (Alunos, Turmas, Usuários, Lançar presença) não mostram voltar, porque o menu faz esse papel |
| Largura do conteúdo | Até 560 px, centralizado (`LarguraCelular`) | Até 880 px, à esquerda; Início até 1100 px |

- Cada item do menu é uma **rota com endereço** (`/`, `/lancar`, `/relatorios`, `/alunos`, `/turmas`, `/usuarios`, `/academia`, `/meus-dados`): recarregar mantém a tela e o voltar do navegador funciona.
- O menu lateral fica fora do navegador interno (`EstruturaComMenu`); o navegador é um contêiner próprio de acessibilidade, senão a barreira das rotas esconderia o menu do leitor de tela.

### 1.6 Movimento

Só onde responde a um toque: o botão principal encolhe 2% ao apertar (300 ms, curva de mola `Cubic(0.32, 0.72, 0, 1)`). Sem animação quando o aparelho pede menos movimento (`MediaQuery.disableAnimationsOf`). Sem animação de entrada nem ao rolar.

## 2. Componentes

Cada componente: onde está, aparência, estados, acessibilidade e onde é usado.

### 2.1 Botão principal (`BotaoPrincipal`, `componentes.dart`)
- **Aparência:** pílula `tatame`, texto branco seminegrito 15, ícone num círculo branco translúcido (32 px) à direita.
- **Parâmetros:** `rotulo`, `icone`, `aoTocar` (null = desabilitado), `carregando` (troca o ícone por indicador e o texto por `rotuloCarregando`, padrão "Salvando…"), `largo` (ocupa a largura, rótulo à esquerda).
- **Estados:** hover escurece (`tatameEscuro`); apertar encolhe 2%; durante o envio continua azul e mostra o indicador; desabilitado cinza.
- **Acessibilidade:** rótulo "Salvando…" (ou o informado) para o leitor de tela durante o envio.
- **Usado em:** Salvar (aluno, turma, usuário), Entrar, Lançar presença de hoje, Cadastrar, Criar e marcar presenças, Importar N alunos. **Um por tela**, para a ação principal.

### 2.2 Botão secundário (`OutlinedButton` com o tema)
- **Aparência:** pílula `tatameClaro`, texto `tatame` seminegrito, sem contorno; com ou sem ícone à esquerda (`OutlinedButton.icon`).
- **Estados:** hover `tatameClaroHover`; desabilitado `linha`.
- **Usado em:** Marcar todos os frequentes, Reposição avulsa, Matricular, Graduação, Dar acesso, Lançar (Início no desktop), Voltar e corrigir, Importar planilha, Tentar de novo.

### 2.3 Botão destrutivo (`estiloDestrutivo` e `estiloConfirmarDestrutivo`)
- **Aparência:** secundário em `pontaClaro` com texto `ponta` (ex.: Encerrar no aviso de sumidos); no diálogo de confirmação, botão cheio `ponta` com texto branco.
- **Regra:** ação que apaga ou encerra sempre pede confirmação num diálogo.
- **Usado em:** Encerrar matrícula, Excluir graduação, Descartar alterações, Sair mesmo assim.

### 2.4 Voltar e botões só com ícone (`IconButton` com o tema)
- **Aparência:** círculo de 48 px `tatameClaro`, ícone `tatame`.
- **Acessibilidade:** sempre com `tooltip` (é o rótulo lido pelo leitor de tela): "Outro dia", "Novo aluno", "Fechar", "Tirar acesso de …".
- **Usado em:** voltar da barra de topo, calendário do lançamento, "+" de novo aluno, turma e usuário, fechar.

### 2.5 Botão de texto (`TextButton` com o tema)
- **Aparência:** só texto `tatame` seminegrito, pílula transparente.
- **Usado em:** "Cancelar" e "Continuar editando" nos diálogos (a ação que não faz nada).

### 2.6 Cartão (`Cartao`)
- **Aparência:** fundo branco, cantos de 16 px, `sombraCartao`, padding 14 × 12; tocável quando recebe `aoTocar` (efeito de toque nos cantos).
- **Usado em:** turmas e indicadores do Início, colunas do Início no desktop.

### 2.7 Campos (`TextField` e `TextFormField` com o tema)
- **Aparência:** fundo branco, cantos de 12 px, contorno 1,5 px `contorno`; foco em 2 px `tatame`; rótulo flutuante.
- **Regras:** texto de exemplo termina com "…" ("Nome ou código…"); e-mail, código, documentos e lista colada sem corretor nem sugestões (`autocorrect: false`, `enableSuggestions: false`); login com `autofillHints`; erro de validação embaixo do campo.
- **Grupo recolhido** (`_Grupo` em `tela_aluno.dart`): caixa com o mesmo contorno, título e seta, abre os campos de dados sensíveis e de responsáveis.

### 2.8 Caixa de marcar presença (`LinhaAluno`)
- **Aparência:** linha com "(código) Nome", etiqueta "novo" se for matrícula nova, opcionalmente "· 12% · última vez 02/09" em `nevoa`, e a caixa à direita (contorno `contorno`, marcada em `tatame` com ✓ branco).
- **Área de toque:** a linha inteira (48 px ou mais).
- **Usado em:** lançamento (frequentes e pouco frequentes) e busca de aluno.

### 2.9 Faixa do aluno (`FaixaDoAluno`) — o único destaque da v2
- **Aparência:** barra de 96 × 16 px com a cor real da faixa e, à direita (36% da largura), a ponta preta com uma listra branca por grau (até 6).
- **Acessibilidade:** rótulo "Faixa Azul, 2 grau".
- **Regra:** cores reais das faixas, nunca como enfeite em outro lugar.
- **Usado em:** graduações no cadastro do aluno.

### 2.10 Dias de aula (`_SeletorDias` em `tela_lancamento.dart`)
- **Aparência:** um por dia de aula da semana, lado a lado, cantos de 14 px, mínimo 48 px de altura: dia e data.
  - **selecionado:** fundo `tatame`, texto branco;
  - **dia de aula:** cartão branco com sombra;
  - **futuro:** transparente com contorno `linha` e texto `desativado`, sem toque.
- Dia de reposição com a etiqueta "repos." (fixa) ou "avulsa".

### 2.11 Etiqueta (`Etiqueta`)
- **Aparência:** texto 11 `tatame` sobre `tatameClaro`, cantos de 6 px.
- **Usado em:** "novo", "repos.", "avulsa".

### 2.12 Status de envio (`StatusEnvio`)
- **Aparência:** pílula pequena com texto 13: "✓ Tudo enviado · 14:32" em `ok`/`okClaro` (o ✓ é ícone) ou "N aguardando envio" em `aviso`/`avisoClaro`; acrescenta "· sem internet" quando offline.
- **Acessibilidade:** região viva (o leitor de tela anuncia a mudança).
- **Usado em:** Início e lançamento (sempre visível no lançamento).

### 2.13 Aviso (`_Aviso` em `tela_inicio.dart`)
- **Aparência:** faixa `avisoClaro` com texto 13 `aviso`, cantos de 8 px; tocável quando leva a outra tela.
- **Usado em:** "N alunos abaixo do mínimo para graduação" (abre a frequência do semestre) e "N alunos sem vir há mais de 4 semanas".

### 2.14 Indicador (`_Indicador` em `tela_inicio.dart`)
- **Aparência:** cartão com rótulo 13 `nevoa` e valor 20 seminegrito com algarismos de largura fixa.
- **Usado em:** Aulas, Freq. média (celular e desktop), Alunos ativos e Abaixo do mínimo (desktop).

### 2.15 Menu lateral (`_MenuLateral` em `navegacao.dart`)
- **Aparência:** coluna de 232 px em `menuLateral`; no topo o nome da academia (enquanto não houver logotipo) numa caixa contornada; itens em pílula com ícone `nevoa` e texto; o item da tela atual em `tatame` com ícone e texto brancos; "Sair" no rodapé.
- **Estados:** hover `#E1E6E1`; itens com pelo menos 48 px de altura; nome longo em até duas linhas (ex.: "Meus dados e senha") e só então cortado com reticências.
- **Acessibilidade:** cada item é botão com estado "selecionado".
- **Itens:** Início, Lançar presença, Alunos, Turmas e Usuários (só professor), conforme `obterItensMenu`.

### 2.16 Menu do celular (`MenuApp`)
- **Aparência:** gaveta com cabeçalho "Menu" e fechar (círculo), itens com ícone e divisória, "Sair" logo depois dos itens.
- **Só no celular** (`obterMenuDoCelular` devolve null no desktop).

### 2.16b Copyright discreto (`RodapeCopyright`)
- **Aparência:** "© <ano> TghServices" centralizado, 12 px, em `nevoa`, com números fixos e 12 px de respiro em cima e embaixo. O ano vem do relógio do app.
- **Uso:** só no fim da tela de entrar (presa embaixo), do menu lateral (embaixo de Sair), do menu do celular e do Início do celular. A marca do sistema nunca aparece em destaque: quem aparece é a academia.

### 2.17 Carregando (`Carregando`)
- **Aparência:** indicador circular `tatame` centralizado.
- **Acessibilidade:** rótulo "Carregando…".

### 2.18 Diálogos (`AlertDialog`)
- **Aparência:** título, texto e ações à direita: "Cancelar" (texto) e a ação (principal, ou destrutiva em `ponta`).
- **Usados para:** sair, descartar alterações (`ProtecaoAlteracoes`), encerrar matrícula, excluir graduação, matricular, nova graduação.

### 2.19 Proteção de alterações (`ProtecaoAlteracoes`)
- Não é visual por si: ao voltar com algo mudado, mostra o diálogo "Descartar alterações?" ("Continuar editando" ou "Descartar"). Usado no cadastro do aluno e da turma.

### 2.20 Grade da semana (`GradeSemana` em `grade_semana.dart`), desktop
- **Aparência:**
  - cabeçalho com voltar (se a tela foi empilhada), chevrons de semana anterior e próxima (círculos azul-claros), título "Turma · dd/mm a dd/mm/aaaa" em 20 w600 com números fixos, `StatusEnvio` e "Reposição avulsa" (secundário);
  - campo de busca "Adicionar aluno pouco frequente à grade…" (máx. 520 px);
  - `Cartao` com uma tabela: coluna do aluno flexível ("(código) Nome · N%", com a `Etiqueta` "novo") e uma coluna de 96 px por dia de aula ("qua 11/11"; reposição com `Etiqueta` "repos." ou "avulsa");
  - linhas separadas por `linha`, a linha "Pouco frequentes (N)" com chevron que abre o resto, e o rodapé "Presentes" com o total por dia ("–" no futuro).
- **Estados:** caixa marcada em `tatame`; dia futuro e dia fora da matrícula desativados e esmaecidos (opacidade 0,4); cabeçalho do dia futuro em `desativado`; próxima semana desativada quando ainda não começou.
- **Acessibilidade:** cada caixa tem o rótulo "Nome, dia dd/mm"; chevrons com dica ("Semana anterior", "Próxima semana").
- **Uso:** só no desktop (≥ 1000 px); no celular o lançamento continua um dia por vez (2.8 e 2.10). Aluno escolhido na busca fica na grade enquanto a tela estiver aberta.

### 2.21 Alunos lado a lado (`_montarDesktop` em `tela_alunos.dart`), desktop
- **Aparência:**
  - cabeçalho com o título "Alunos" (22 w600), "Importar planilha" (secundário) e "Novo aluno" (`BotaoPrincipal`);
  - à esquerda, um `Cartao` de 380 px com a busca "Nome ou código…", a contagem "Ativos · N" e as linhas (`_LinhaAlunoDesktop`): "(código) Nome" e a `FaixaDoAluno` de 70 px à direita, quando o aluno tem graduação;
  - à direita, um `Cartao` com o cadastro (`TelaAluno` com `embutido: true`): "(código) Nome" em 17 w600 e "Salvar" no topo, e o formulário abaixo; sem aluno escolhido, o convite "Escolha um aluno na lista ou cadastre um novo.".
- **Estados:** linha escolhida com fundo `tatameClaro` e nome em w600; altura mínima de 48 px.
- **Acessibilidade:** linha como botão com estado "selecionado"; a faixa mantém o rótulo "Faixa X, N grau".
- **Uso:** trocar de aluno, abrir "Novo aluno" ou "Importar planilha" com algo não salvo pergunta "Descartar alterações?" (`confirmarDescarte`). Depois de salvar, o aluno fica escolhido e a lista se atualiza. No celular, a lista e o cadastro continuam em telas separadas.

### 2.22 Escolha em pílulas (`EscolhaEmPilulas` em `relatorios/partes_relatorio.dart`)
- **Aparência:** `ChoiceChip` em pílula, fundo `cartao` com contorno `linha` de 1,5 px; a escolhida em `tatame` com texto branco, sem o visto; ícone opcional em `tatame` (branco quando escolhida).
- **Acessibilidade:** área de toque de 48 px (`MaterialTapTargetSize.padded`); estado selecionado do próprio chip.
- **Usada em:** atalhos de período (Esta semana, Este mês, Semestre, Ano) e tipos de relatório no desktop.

### 2.23 Campo de data (`CampoData`)
- **Aparência:** campo do tema com rótulo flutuante ("De", "Até"), a data em dd/mm/aaaa com números fixos e o ícone de calendário à direita; abre o `showDatePicker`.
- **Acessibilidade:** lido como botão "De: 01/11/2026".
- **Regra:** De depois do Até faz o outro campo acompanhar (o período nunca fica invertido); mudar a data à mão desmarca o atalho.

### 2.24 Tabela de relatório (`TabelaRelatorio` em `relatorios/tabela_relatorio.dart`)
- **Aparência:**
  - resumo opcional em `Cartao`s (rótulo em `nevoa` 13, valor em 20 w600, em `ponta` quando abaixo do mínimo);
  - `Cartao` com a coluna do aluno fixa (140 px no celular, 260 px no desktop, nome cortado com reticências) e as demais rolando para o lado; linhas de 44 px separadas por `linha`;
  - cabeçalho em `nevoa` 13; rótulos das colunas em w600 com a `Etiqueta` "repos." quando a aula é reposição; grupos de semanas numa linha acima;
  - marca de presença: visto `Symbols.check` em `tatame` (veio), ponto em `nevoa` (faltou), vazio (fora da matrícula); frequência abaixo do mínimo em `ponta` w600; mês futuro com "–";
  - linha de rodapé ("Presentes", "Aulas") com o rótulo em `nevoa`; legenda das marcas e nota da fórmula abaixo do cartão.
- **Acessibilidade:** o visto e o ponto são lidos como "veio" e "faltou"; números de largura fixa.
- **Uso:** mesma montagem (`RelatorioMontado`, em `montar_relatorio.dart`) para a tela e para a página impressa (`gerarHtmlRelatorio`); no mensal, tocar no aluno abre o relatório por aluno.

### 2.25 Página impressa (`gerarHtmlRelatorio` em `relatorios/html_relatorio.dart`)
- **Aparência:** A4 (paisagem na semanal e na anual, retrato nas demais), fonte do sistema, cabeçalho com a academia, o cabeçalho de impressão da academia, a turma e o da turma, e à direita o relatório e o período; tabela com bordas finas `#c9ccc8`, cabeçalho repetido em cada página, rodapé "Gerado em … por …".
- **Uso:** aberta numa aba nova pelo botão Imprimir / PDF; o navegador imprime ou salva em PDF. Com logotipo cadastrado (tela 14), o original aparece à esquerda do nome da academia, até 140 × 56 px; sem ele, só o nome.

### 2.26 Academias (`TelaAcademias` em `tela_academias.dart`), só o superadmin
- **Aparência:**
  - celular: barra "Academias" com o botão "+" (dica "Nova academia"); desktop: título "Academias" e "Nova academia" (`BotaoPrincipal`), com o menu lateral só com "Academias";
  - `Cartao` com uma linha por academia: o nome e, abaixo em `nevoa` 13 com números fixos, "N alunos · N turmas · N usuários"; à direita a `Etiqueta` "ativa" ou "inativa";
  - `Cartao` "Nova: nome · primeiro professor" que abre, no lugar, o formulário (nome da academia, nome curto opcional até 15, nome do professor, e-mail e senha inicial) com "Cancelar" e "Criar academia"; no celular estreito o botão desce para a linha de baixo;
  - "Carga inicial (planilha de alunos)" (secundário, largura toda): com mais de uma academia, pergunta qual num diálogo e abre a importação (8b/8c) com o título "Carga inicial · academia".
- **Acessibilidade:** erro vindo do servidor anunciado ao leitor de tela (região ao vivo); validação junto de cada campo.
- **Uso:** online; nada vai para o banco do aparelho do superadmin.

### 2.27 Dados da academia (`TelaDadosAcademia` em `tela_dados_academia.dart`), só o professor
- **Aparência:**
  - celular: barra "Dados da academia" (título à esquerda, para caber) com "Salvar" (`BotaoPrincipal`); desktop: título e "Salvar" no topo;
  - campos "Nome", "Nome curto no celular" (até 15, com a ajuda "Aparece embaixo do ícone do app instalado.") e "Cabeçalho de impressão (opcional)";
  - `Cartao` "Logotipo": sem logotipo, a área azul-clara "Enviar logotipo" com "PNG ou JPG · até 1 MB"; com logotipo, "Trocar logotipo" (secundário) e "Remover" (destrutivo, com confirmação); enquanto envia, o indicador "Enviando o logotipo…";
  - "Prévia do ícone do app": o ícone 512 px num quadrado de cantos arredondados e num círculo, de 64 px, com sombra de cartão.
- **Acessibilidade:** área de envio lida como botão "Enviar logotipo, PNG ou JPG até 1 MB"; prévias com rótulo; erros com a próxima ação ("Escolha outro arquivo", "Diminua a imagem").
- **Uso:** o logotipo é enviado na hora em que é escolhido; os campos de texto só com "Salvar" (sair com alteração pergunta antes). O ícone aparece no menu lateral ao lado do nome da academia, e o logotipo original no cabeçalho da página impressa (2.25).

### 2.28 Convite de instalação (`ConviteInstalacao` em `convite_instalacao.dart`), tela 2
- **Aparência:** `Cartao` no topo do Início do celular, antes do status de envio: ícone `install_mobile` em `tatame`, "Instale o app da <academia>" em w600, o apoio "Abre direto, funciona sem internet e fica com o ícone da academia." em `nevoa` 13, e dois botões da mesma largura: "Instalar" (preenchido) e "Agora não" (secundário).
- **Quando aparece:** depois do login, se o navegador ofereceu a instalação ou se é iPhone; some se o app já está instalado ou depois do "Agora não" (guardado no aparelho até sair).
- **Uso:** "Instalar" chama o convite do navegador; no iPhone, abre a tela 2b.

### 2.29 Instalar no iPhone (`TelaInstalarIphone`), tela 2b
- **Aparência:** barra "Instalar no iPhone" com o fechar (X, dica "Fechar") em círculo azul-claro; `Cartao` com os três passos, cada um com o ícone em quadrado `tatameClaro` (compartilhar, adicionar, confirmar), o título numerado em w600 e uma explicação em `nevoa` 13; nota final sobre o iPhone não ter botão de instalar.

### 2.30 Meus dados e senha (`TelaMeusDados` em `tela_meus_dados.dart`), tela 12
- **Aparência:**
  - celular: barra "Meus dados" com voltar; desktop: título "Meus dados e senha" e os dois cartões lado a lado (D7);
  - `Cartao` de consulta com linhas: rótulo em `nevoa` 13 à esquerda e o valor à direita: Nome, E-mail, Tipo ("administrador do sistema" para o superadmin) e Academia (não aparece para o superadmin); embaixo, quem muda nome e e-mail ("fale com o professor" para a assistente, "use a tela de Usuários" para o professor);
  - `Cartao` "Trocar senha" com Senha atual, Nova senha e Confirmar nova senha (os dois primeiros com o botão de mostrar a senha), a nota sobre os 8 caracteres e os outros aparelhos, e "Trocar senha" (`BotaoPrincipal`, largo no celular, à direita no desktop, "Trocando…" durante o envio).
- **Estados:** erros no próprio campo ("Informe a senha atual.", "A nova senha precisa ter pelo menos 8 caracteres.", "As senhas não conferem." e, do servidor, "Senha atual incorreta."); depois do sucesso, os campos limpos e a etiqueta verde "Senha trocada." (região ao vivo); sem internet, aviso e os campos mantidos.
- **Acessibilidade:** campos com rótulo e preenchimento automático de senha atual e nova senha; botão de mostrar com dica ("Mostrar a senha" / "Esconder a senha").
- **Uso:** item "Meus dados e senha" no menu de todos os usuários, inclusive o superadmin.

## 3. Ainda não implementado (previsto na v2)

- Nada pendente dos wireframes aprovados.
