# 07 — Importar alunos da planilha

**Objetivo:** trazer de uma vez a lista de alunos (código e nome) que hoje está numa planilha, já matriculados numa turma.
**Quem pode:** professor e assistente. **Precisa de internet.** Faça pelo computador, que fica mais fácil copiar e colar.

## Antes de começar
- A planilha precisa ter o **código** e o **nome** de cada aluno, lado a lado (Excel, Google Planilhas ou parecido). Ex.:

| Código | Nome |
|---|---|
| (01) | Augusto Eduardo Barbosa Torres |
| (03) | Lucas Vieira Santos da Mata |

- A turma já existe ([manual 03](03-abrir-turma-nova.md)). Se os alunos são de turmas diferentes, importe uma turma de cada vez.

## Passo a passo
1. Na planilha, selecione as duas colunas (código e nome) das linhas dos alunos e copie (Ctrl+C).
2. No sistema: menu → **Alunos** → **Importar planilha**.
3. Clique no campo e cole (Ctrl+V). Uma linha por aluno.
4. Escolha a **Turma** e a data em **Matriculados desde** (o dia em que eles passam a contar nessa turma; ex.: o primeiro dia do mês).
   - Só quer cadastrar, sem matricular? Escolha **Não matricular (só cadastrar)**.
5. Clique em **Conferir lista**.
6. O sistema mostra quantas linhas leu e avisa problemas:
   - **linhas incompletas** (sem código ou sem nome);
   - **códigos repetidos** na própria lista (o caso de dois alunos com o mesmo código na planilha);
   - **códigos que já existem** na academia;
   - **nomes repetidos** (só avisa; pode ser homônimo).
7. Se aparecer problema que impede, clique em **Voltar e corrigir**, ajuste o texto colado (ex.: troque um código repetido por `10B`) e confira de novo.
8. Sem problemas, clique em **Importar e matricular N alunos**.

## Pronto quando
Os alunos aparecem em **Alunos** e no **Lançar presença** da turma.

## Dúvidas comuns
- **O código está como "(10A)" na planilha.** Pode colar assim: o sistema tira os parênteses e grava `10A`.
- **Colou o cabeçalho junto.** Tudo bem: a linha do cabeçalho é ignorada, assim como linhas em branco.
- **A planilha tem mais colunas.** Copie só código e nome. O sistema aceita colunas separadas por tab (o normal ao copiar de uma planilha), ponto e vírgula ou espaço.
- **Nada foi gravado.** Enquanto houver código repetido ou já cadastrado, o sistema não grava nada; corrija e confira de novo.
- **Limite:** até 2.000 linhas por vez.
