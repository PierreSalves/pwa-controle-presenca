# Casos de uso detalhados

Cada caso de uso segue o mesmo formato: **objetivo** (o que a pessoa quer), **ator**, **pré-condições**, **fluxo principal** (o passo a passo nas telas), **variações e erros**, **regras** e **entidades** envolvidas (dicionário em [`entidades-por-tela.md`](entidades-por-tela.md)). Visão geral e diagramas em [`README.md`](README.md).

Convenções:
- Os nomes entre aspas são os textos que aparecem no app ("Salvar", "Nova turma").
- "Tela 4" etc. são os números dos wireframes em [`../telas/README.md`](../telas/README.md).
- **Online** = precisa de internet (o servidor confere e grava na hora). **Offline** = funciona sem internet com os dados do aparelho.

---

## UC01 — Entrar no sistema

- **Objetivo:** acessar o app com o e-mail e a senha recebidos.
- **Ator:** professor, assistente ou administrador do sistema.
- **Pré-condições:** o usuário foi cadastrado por outra pessoa (UC16, UC21 ou UC22) e está ativo; a academia está ativa. O **primeiro** acesso no aparelho precisa de internet.

**Fluxo principal**
1. Na tela 1 (Entrar), a pessoa digita **E-mail** e **Senha** e toca em "Entrar".
2. O servidor confere a senha e abre uma sessão de 30 dias, renovada a cada uso.
3. Professor e assistente: o app baixa para o aparelho as turmas a que a pessoa tem acesso, com quadros de aulas, alunos (só código e nome), matrículas, aulas e presenças, e abre o **Início** (tela 2).
4. Administrador do sistema: abre **Academias** (tela 13); nada é baixado para o aparelho.

**Variações e erros**
- Senha errada → "E-mail ou senha incorretos.".
- Sem internet no primeiro acesso → o app avisa e continua na tela de entrar.
- Já entrou antes neste aparelho → o app abre direto no Início, mesmo sem internet, e renova a sessão quando a conexão volta.
- Usuário desativado ou academia desativada → a sessão é encerrada e o app apaga os dados do aparelho na próxima conexão.
- Esqueceu a senha → não há recuperação automática: o professor redefine a senha da assistente (UC16) e o administrador, a do professor (UC23).

**Regras:** usuário não se autocadastra. Sair (menu → "Sair") apaga os dados do aparelho; se houver presença aguardando envio, o app avisa antes.

**Entidades:** Usuário, Sessão, Academia; no download, Turma, Acesso à turma, Quadro de aulas, Aluno, Matrícula, Aula, Presença.

---

## UC02 — Abrir uma turma

- **Objetivo:** criar uma turma nova (ex.: "Kids", "Adulto noite") com os dias de aula.
- **Ator:** professor ou assistente.
- **Pré-condições:** online.

**Fluxo principal**
1. Menu → "Turmas" → "Nova turma" (botão "+").
2. Na tela 10 (Turma), preenche **Nome** e, se quiser, **Frequência mínima (%)** e **Cabeçalho de impressão (opcional)**.
3. Em **Quadro de aulas**, toca em cada dia da semana até mostrar o tipo desejado: *sem aula* → *regular* → *reposição*.
4. Ajusta, se quiser, a **Lista do lançamento** e o aviso de **sumidos** (UC04).
5. Professor: em **Quem acessa**, toca em "Dar acesso" para escolher as assistentes (UC17).
6. Toca em "Salvar" → "Turma criada.".

**Variações e erros**
- Já existe turma com o mesmo nome → o servidor recusa (o nome é único na academia, sem diferenciar maiúsculas).
- Sair com alterações não salvas → o app pergunta "Descartar alterações?".

**Regras**
- O primeiro quadro de aulas vale a partir de hoje; mudanças depois criam um quadro novo (UC03).
- Dia **regular** entra na conta da frequência; dia de **reposição** aparece no lançamento como reposição fixa e conta como presença extra.
- Quem cria a turma passa a acessá-la automaticamente; quem dá acesso a outras pessoas é o professor.

**Entidades:** Turma, Quadro de aulas, Regras da turma, Acesso à turma.

---

## UC03 — Mudar os dias de aula da turma

- **Objetivo:** a turma passa a ter aula em outros dias (ex.: troca terça por segunda) sem bagunçar o histórico.
- **Ator:** professor ou assistente.
- **Pré-condições:** online; a turma existe.

**Fluxo principal**
1. Menu → "Turmas" → toca na turma.
2. Em **Quadro de aulas**, muda os dias.
3. Escolhe a data em **O quadro novo vale a partir de** (padrão: hoje).
4. "Salvar".

**Regras**
- O quadro anterior continua valendo para as datas antes da nova data; o lançamento e a frequência usam, em cada dia, o quadro vigente naquela data.
- A data do quadro novo não pode ser anterior à do quadro atual.

**Entidades:** Quadro de aulas (um novo registro com nova vigência).

---

## UC04 — Definir a frequência mínima e a lista do lançamento

- **Objetivo:** dizer quantos por cento das aulas o aluno precisa frequentar para poder graduar, quem aparece direto na lista do lançamento e quando avisar que um aluno sumiu.
- **Ator:** professor ou assistente.
- **Pré-condições:** online.

**Fluxo principal**
1. Menu → "Turmas" → toca na turma.
2. **Frequência mínima (%)**: ex.: `75`.
3. **Lista do lançamento**: "Frequentes: ao menos **30** % das últimas **8** aulas".
4. **Avisar sumidos após** **4** semanas.
5. "Salvar".

**Regras**
- **Frequência para graduação** = (presenças em aulas regulares + presenças em reposições) ÷ aulas regulares lançadas no semestre (jan–jun ou jul–dez), contando só as aulas dentro da matrícula; limite de 100%. Quem fica abaixo do mínimo aparece em vermelho e no aviso do Início.
- O sistema não guarda um "limite de faltas": ele decorre do mínimo. Com mínimo de 75% e 48 aulas regulares no semestre, o aluno precisa de 36 presenças, ou seja, pode faltar até 12 vezes; cada reposição compensa uma falta. O manual [11](../manuais/11-frequencia-minima-e-limite-de-faltas.md) tem a conta passo a passo.
- **Lista do lançamento:** aparecem direto os alunos com frequência de pelo menos o percentual nas últimas N aulas. Matrícula nova (menos de N aulas) sempre aparece. Os outros ficam recolhidos em "Pouco frequentes" e na busca.
- **Sumidos:** o Início avisa quem não vem há mais semanas que o configurado, com atalho para encerrar a matrícula (UC11).
- Valores: frequência mínima de 0 a 100; percentual da lista de 0 a 100; últimas aulas e semanas a partir de 1.

**Entidades:** Turma (`frequencia_minima`), Regras da turma (lista do lançamento e sumidos).

---

## UC05 — Cadastrar aluno

- **Objetivo:** registrar um aluno novo na academia.
- **Ator:** professor ou assistente.
- **Pré-condições:** online.

**Fluxo principal**
1. Menu → "Alunos" → "Novo aluno" (botão "+").
2. Na tela 9 (Aluno), o **Cód.** já vem sugerido (o próximo número livre; pode editar). Preenche **Nome completo**.
3. Se quiser, abre **Nascimento · telefone · CPF** e **Responsáveis** para os dados pessoais.
4. "Salvar" → "Aluno cadastrado.".
5. Continua no cadastro para matricular (UC06) ou registrar graduação (UC15).

**Variações e erros**
- Código já usado → "Já existe um aluno com este código." (único na academia, sem diferenciar maiúsculas: `10a` = `10A`).
- Desmarcar **Aluno ativo** tira o aluno da lista de ativos sem apagar o histórico.

**Regras**
- **LGPD:** nascimento, CPF, RG, endereço, telefones e dados dos responsáveis ficam **só no servidor**; o aparelho guarda apenas código e nome. Por isso o cadastro completo precisa de internet.
- Cadastrar não matricula: o aluno só aparece no lançamento depois de matriculado numa turma.

**Entidades:** Aluno.

---

## UC06 — Matricular aluno numa turma

- **Objetivo:** colocar o aluno na lista de uma turma a partir de uma data.
- **Ator:** professor ou assistente.
- **Pré-condições:** online; aluno salvo; a turma existe.

**Fluxo principal**
1. Abre o aluno (menu → "Alunos" → toca no aluno, ou logo depois do UC05).
2. Em **Matrículas**, toca em "Matricular".
3. Escolhe a **Turma** e o **Início da matrícula** (padrão: hoje) e confirma.
4. A matrícula aparece como "desde dd/mm/aaaa · matriculado". Na próxima sincronização, ele aparece no lançamento da turma.

**Variações e erros**
- O aluno já está matriculado nessa turma no período → "O aluno já está matriculado nessa turma nesse período.".
- Trocar de turma = encerrar a matrícula atual (UC11) e matricular na nova.
- Um aluno pode estar em várias turmas ao mesmo tempo, com uma matrícula em cada.

**Regras**
- A presença só pode ser marcada em aulas dentro do período da matrícula; antes do início, a célula fica bloqueada.
- Matrícula nova aparece sempre na lista do lançamento enquanto tiver menos aulas que a janela da lista (padrão 8).

**Entidades:** Matrícula, Aluno, Turma.

---

## UC07 — Importar alunos da planilha

- **Objetivo:** trazer de uma vez a lista de alunos que hoje está na planilha, já matriculados numa turma.
- **Ator:** professor ou assistente (e o administrador na carga inicial, UC24).
- **Pré-condições:** online; a lista está numa planilha (Excel, Google Planilhas) com código e nome.

**Fluxo principal**
1. Menu → "Alunos" → "Importar planilha".
2. Tela 8b: na planilha, seleciona as colunas **código e nome**, copia e cola no campo (uma linha por aluno).
3. Escolhe a **Turma** em que os alunos serão matriculados e **Matriculados desde** (data de início), ou "Não matricular (só cadastrar)".
4. Toca em "Conferir lista".
5. Tela 8c: o relatório mostra quantas linhas foram lidas, linhas incompletas, **códigos repetidos** na lista, códigos que **já existem** na academia e nomes repetidos (este só avisa).
6. Sem problemas que impeçam → "Importar e matricular N alunos" (ou "Importar N alunos", sem turma). Com problemas → "Voltar e corrigir", ajusta o texto colado e confere de novo.

**Regras**
- O código `(10A)` vira `10A`; separadores aceitos: tab, ponto e vírgula ou espaço. Linhas em branco e o cabeçalho são ignorados.
- Nada é gravado enquanto houver código repetido ou já cadastrado.
- Até 2.000 linhas por vez.

**Entidades:** Aluno, Matrícula.

---

## UC08 — Lançar a presença da aula

- **Objetivo:** marcar, durante a aula, quem veio.
- **Ator:** professor ou assistente.
- **Pré-condições:** já entrou no aparelho uma vez (UC01); tem acesso à turma. **Funciona sem internet.**

**Fluxo principal**
1. No Início, toca em "Lançar presença de hoje" (ou menu → "Lançar presença").
2. Se tem mais de uma turma, escolhe a turma (tela 3); com uma só, essa tela é pulada.
3. Na tela 4, o dia de hoje vem selecionado; a fileira de dias mostra os dias de aula da semana (o futuro fica bloqueado).
4. A lista mostra os **frequentes**, ordenados pela frequência. A pessoa toca na caixa de cada aluno presente; para tirar, toca de novo.
5. Atalho: "Marcar todos os frequentes" e depois desmarca quem faltou.
6. O rodapé mostra "N presentes" e o status de envio: "Tudo enviado" ou "N aguardando envio".

**Variações e erros**
- **Sem internet:** cada marcação fica guardada no aparelho ("N aguardando envio") e vai sozinha quando a conexão voltar.
- **Duas pessoas lançando a mesma aula:** com a tela aberta, o app busca as marcações dos outros aparelhos a cada poucos segundos; vale a última alteração.
- **Outro dia:** toca em outro dia da semana ou em "Outro dia" (calendário) para corrigir uma aula passada.
- **Aluno que não está na lista:** UC10. **Aula fora do quadro:** UC09.
- **Desktop:** a tela vira a grade da semana (D2), com uma coluna por dia, como a planilha.

**Regras**
- Dia futuro não aceita presença; dia antes do início ou depois do fim da matrícula fica bloqueado para aquele aluno.
- A aula é criada no momento da primeira marcação. Dia sem nenhuma marcação (ex.: feriado) não vira aula e não conta como falta.
- **Falta** não é registrada: é calculada (aula lançada, dentro da matrícula, sem presença).
- O servidor reconfere tudo: permissão, turma, matrícula e data.

**Entidades:** Aula, Presença, Matrícula, Quadro de aulas, Regras da turma; quem lançou fica em `created_by`.

---

## UC09 — Lançar reposição avulsa

- **Objetivo:** registrar uma aula extra fora dos dias do quadro (ex.: reposição num sábado que normalmente não tem aula).
- **Ator:** professor ou assistente.
- **Pré-condições:** acesso à turma. Funciona sem internet.

**Fluxo principal**
1. Na tela 4 (Lançar presença) → "Reposição avulsa (outro dia)".
2. Tela 5: escolhe o **Dia da reposição** (não pode ser futuro).
3. "Criar e marcar presenças" → abre o lançamento dessa aula, marcada como "avulsa" na fileira de dias.
4. Marca os presentes como no UC08.

**Regras**
- Presença em reposição **soma** na frequência, mas a reposição não entra no total de aulas (não gera falta para quem não veio).
- A reposição **fixa** é diferente: é um dia do quadro marcado como reposição (UC02) e aparece sozinho no lançamento.

**Entidades:** Aula (`tipo = reposicao`), Presença.

---

## UC10 — Marcar aluno pouco frequente

- **Objetivo:** marcar presença de um aluno matriculado que não aparece na lista principal (porque vem pouco).
- **Ator:** professor ou assistente. Funciona sem internet.

**Fluxo principal**
1. Na tela 4, toca em "Buscar outro aluno matriculado…" (ou abre "Pouco frequentes").
2. Tela 4b: digita parte do nome ou do código e toca na caixa do aluno.
3. Ao voltar, o aluno marcado passa a aparecer na lista do dia.

**Regras:** só aparecem alunos matriculados na turma na data da aula.

**Entidades:** Presença, Matrícula, Aluno.

---

## UC11 — Encerrar a matrícula de aluno sumido

- **Objetivo:** tirar da turma o aluno que parou de vir, sem apagar o histórico.
- **Ator:** professor ou assistente.
- **Pré-condições:** online.

**Fluxo principal (pelo aviso do Início)**
1. O Início mostra "N alunos sem vir há mais de 4 semanas" e, abaixo, cada aluno com o botão "Encerrar".
2. Toca em "Encerrar"; o app pede a **Data de fim da matrícula**, com a sugestão da última presença.
3. Confirma → a matrícula fica "encerrada" e o aluno sai da lista do lançamento a partir do dia seguinte à data de fim.

**Fluxo alternativo (pelo cadastro)**
1. Abre o aluno → em **Matrículas**, toca na matrícula aberta ("Toque na matrícula aberta para encerrar.").
2. Escolhe a data de fim e confirma "Encerrar matrícula".

**Regras:** a data de fim não pode ser anterior ao início. O histórico de presenças continua nos relatórios. Para voltar, basta matricular de novo (UC06).

**Entidades:** Matrícula (`data_fim`, `situacao = encerrado`).

---

## UC12 — Consultar a frequência para graduação

- **Objetivo:** antes da graduação (início de junho e de dezembro), saber quem atingiu a frequência mínima.
- **Ator:** professor ou assistente. Funciona sem internet.

**Fluxo principal**
1. No Início, toca no aviso "N alunos abaixo do mínimo para graduação" (ou, no desktop, num aluno da lista "Abaixo do mínimo").
2. Tela 6 (Frequência do semestre): lista os alunos da turma com a frequência do semestre até hoje; abaixo do mínimo em vermelho.
3. Alternativa com mais detalhes e impressão: Relatórios → "Frequência para graduação" (UC13).

**Regras:** a regra do UC04 (semestre jan–jun ou jul–dez; reposições contam; limite de 100%).

**Entidades:** Aula, Presença, Matrícula, Turma (`frequencia_minima`).

---

## UC13 — Emitir relatório

- **Objetivo:** ver os números que hoje se somam à mão na planilha.
- **Ator:** professor ou assistente. Funciona sem internet (calculado no aparelho a partir das presenças já sincronizadas).

**Fluxo principal (celular)**
1. Menu → "Relatórios".
2. Escolhe a **Turma**, o período (**De** e **Até**) ou um atalho: "Esta semana", "Este mês", "Semestre", "Ano".
3. Toca no relatório:

| Relatório | O que mostra | Para que serve |
|---|---|---|
| **Presença semanal** | aluno × dias de aula de cada semana, com visto em quem veio, ponto na falta e em branco fora da matrícula | substitui a planilha semanal do mês; conferir uma semana específica |
| **Presença mensal** | presenças por mês e a frequência do período | acompanhar a assiduidade mês a mês e quem está caindo |
| **Presença anual** | presenças de JAN a DEZ, com total e aulas do mês | substitui a planilha anual |
| **Por aluno** | cada aula do período do aluno escolhido: veio, faltou, reposição; com aulas, presenças e frequência | conversar com o aluno ou com os pais; tirar dúvida sobre uma falta |
| **Frequência para graduação** | aulas, presenças, reposições e frequência do semestre até a data "Até"; abaixo do mínimo em vermelho | decidir quem pode graduar |

4. No relatório mensal, tocar num aluno abre o relatório **Por aluno** dele.

**Desktop:** filtros no topo, os tipos em pílulas e o relatório logo abaixo, na mesma tela.

**Regras:** nenhum total é gravado; tudo é recalculado a partir das presenças. Falta = aula lançada sem presença, dentro da matrícula.

**Entidades:** Aula, Presença, Matrícula, Aluno, Turma, Academia (cabeçalho).

---

## UC14 — Imprimir ou salvar em PDF

- **Objetivo:** ter o relatório em papel ou em PDF para arquivar ou mandar.
- **Ator:** professor ou assistente.

**Fluxo principal**
1. Com um relatório aberto (UC13), toca em "Imprimir / PDF".
2. Abre uma aba nova com a página pronta (A4; semanal e anual na horizontal) e a janela de impressão do navegador.
3. Escolhe a impressora ou "Salvar como PDF".

**Variações:** se o navegador bloquear a aba nova, o app avisa para permitir janelas pop-up deste site.

**Regras:** o cabeçalho traz o logotipo e o nome da academia, a turma e os **cabeçalhos de impressão** da academia (UC18) e da turma (UC02); o rodapé diz quando e por quem foi gerado.

**Entidades:** as do UC13, mais Academia (logotipo, cabeçalho de impressão) e Turma (cabeçalho de impressão).

---

## UC15 — Registrar graduação

- **Objetivo:** guardar a faixa e o grau que o aluno recebeu.
- **Ator:** professor ou assistente. Online.

**Fluxo principal**
1. Abre o aluno → em **Graduações**, toca em "Graduação".
2. Escolhe a **Faixa**, o **Grau** e a **Data**, e confirma.
3. A graduação aparece na lista com a faixa desenhada (cor e graus) e passa a ser a faixa atual na lista de alunos do desktop.

**Variações:** graduação lançada por engano → toque longo (segurar o dedo) nela → "Excluir graduação".

**Entidades:** Graduação, Aluno.

---

## UC16 — Cadastrar assistente ou professor

- **Objetivo:** dar acesso ao sistema para quem vai lançar presença (assistente) ou para outro professor.
- **Ator:** professor. Online.

**Fluxo principal**
1. Menu → "Usuários".
2. Toca em "Novo: nome · e-mail · tipo · turmas".
3. Preenche **Nome**, **E-mail**, **Tipo** (assistente ou professor) e **Senha inicial** (pelo menos 8 caracteres); marca as turmas que a pessoa vai acessar.
4. "Salvar" → "Usuário cadastrado. Passe a senha inicial para a pessoa.".

**Variações**
- E-mail já usado → "Já existe um usuário com este e-mail." (o e-mail é único no sistema inteiro).
- **Esqueceu a senha:** toca no usuário → "Esqueceu a senha?" → **Nova senha** → salva; as sessões dela são encerradas e você passa a senha nova.
- **Desligar alguém:** toca no usuário → desmarca **Ativo** → salva; o acesso acaba na hora e o app dela apaga os dados.
- O professor não muda o próprio tipo nem se desativa.

**Entidades:** Usuário, Acesso à turma, Sessão.

---

## UC17 — Dar acesso às turmas

- **Objetivo:** definir quais turmas cada pessoa vê e lança.
- **Ator:** professor. Online.

**Fluxo principal (pela turma)**
1. Menu → "Turmas" → toca na turma.
2. Em **Quem acessa**, toca em "Dar acesso" e escolhe a pessoa; para tirar, toca no ícone ao lado do nome ("Tirar acesso de …").
3. "Salvar".

**Fluxo alternativo (pela pessoa):** menu → "Usuários" → toca na pessoa → marca ou desmarca as turmas → "Salvar".

**Regras:** o aparelho de cada pessoa só recebe as turmas a que ela tem acesso; tirar o acesso faz a turma sumir do aparelho dela na próxima sincronização.

**Entidades:** Acesso à turma.

---

## UC18 — Configurar os dados e o logotipo da academia

- **Objetivo:** deixar o app e os relatórios com a identidade da academia.
- **Ator:** professor. Online.

**Fluxo principal**
1. Menu → "Dados da academia".
2. **Nome**, **Nome curto no celular** (até 15 letras, aparece embaixo do ícone do app instalado) e **Cabeçalho de impressão (opcional)**; "Salvar".
3. Logotipo: "Enviar logotipo" → escolhe um PNG ou JPG de até 1 MB → o app gera os ícones e envia na hora; a **Prévia do ícone do app** mostra o quadrado e o redondo.
4. Para mudar: "Trocar logotipo"; para tirar: "Remover" (com confirmação).

**Regras:** o logotipo aparece no menu lateral (desktop), na página impressa e no ícone do app instalado; sem logotipo, aparece o nome da academia e o ícone da TghServices.

**Entidades:** Academia (nome, nome curto, cabeçalho, logotipo e ícones no R2).

---

## UC19 — Trocar a própria senha

- **Objetivo:** trocar a senha inicial ou uma senha que vazou.
- **Ator:** todos. Online.

**Fluxo principal**
1. Menu → "Meus dados e senha".
2. Confere os dados (nome, e-mail, tipo, academia).
3. Em **Trocar senha**: **Senha atual**, **Nova senha** (pelo menos 8) e **Confirmar nova senha** → "Trocar senha".
4. "Senha trocada.": os outros aparelhos em que a pessoa entrou saem da conta; este continua.

**Variações:** "Senha atual incorreta.", "As senhas não conferem.", sem internet → aviso, e o que foi digitado fica.

**Entidades:** Usuário, Sessão.

---

## UC20 — Instalar o app

- **Objetivo:** abrir o sistema direto pelo ícone, em tela cheia, também sem internet.
- **Ator:** professor ou assistente.
- **Pré-condições:** já entrou (o convite só aparece depois do login, quando o app conhece a academia).

**Fluxo principal**
1. No Início do celular aparece "Instale o app da *academia*".
2. Android, ou Chrome/Edge no computador: "Instalar" → confirma na janela do navegador.
3. iPhone: "Instalar" → tela 2b com o passo a passo (Compartilhar → "Adicionar à Tela de Início" → Adicionar).
4. "Agora não" esconde o convite neste aparelho.

**Regras:** o ícone e o nome instalados são os da academia (UC18). Quem instala pelo menu do navegador antes de entrar fica com o ícone da TghServices.

**Entidades:** Academia (nome curto, ícones).

---

## UC21 — Cadastrar academia e primeiro professor

- **Objetivo:** liberar o sistema para uma academia nova.
- **Ator:** administrador do sistema. Online.

**Fluxo principal**
1. Entra (UC01) e cai em **Academias** (tela 13).
2. Toca em "Nova: nome · primeiro professor" (ou "Nova academia" no desktop).
3. Preenche **Nome da academia**, **Nome curto no celular (opcional)**, **Nome do professor**, **E-mail** e **Senha inicial**.
4. "Criar academia" → "Academia cadastrada. Passe o e-mail e a senha inicial para o professor.".

**Regras:** a academia e o professor são gravados juntos (ou nenhum dos dois). O e-mail é único no sistema inteiro.

**Entidades:** Academia, Usuário.

---

## UC22 — Cadastrar mais um professor

- **Objetivo:** dar acesso a outro professor de uma academia existente.
- **Ator:** administrador do sistema. Online.

**Fluxo principal:** Academias → toca na academia (tela 13a) → "Novo professor" → **Nome**, **E-mail**, **Senha inicial** → "Cadastrar".

**Entidades:** Usuário.

---

## UC23 — Redefinir a senha de um professor

- **Objetivo:** o professor esqueceu a senha.
- **Ator:** administrador do sistema. Online.

**Fluxo principal:** Academias → toca na academia → no professor, "Redefinir senha" → digita ou gera a **Nova senha** → "Concluir". As sessões do professor são encerradas; passe a senha nova para ele, que deve trocá-la depois (UC19).

**Entidades:** Usuário, Sessão.

---

## UC24 — Fazer a carga inicial de alunos

- **Objetivo:** importar os alunos de uma academia recém-cadastrada, para o professor já começar com a lista pronta.
- **Ator:** administrador do sistema. Online.

**Fluxo principal:** Academias → "Carga inicial (planilha de alunos)" → escolhe a academia (se houver mais de uma) → segue o UC07 nas telas 8b e 8c ("Carga inicial · *academia*").

**Entidades:** Aluno (e Matrícula, quando a turma já existe).
