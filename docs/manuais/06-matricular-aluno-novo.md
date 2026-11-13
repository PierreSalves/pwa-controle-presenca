# 06 — Matricular um aluno novo que chegou agora na academia

**Objetivo:** cadastrar o aluno e colocá-lo na lista de presença da turma dele.
**Quem pode:** professor e assistente. **Precisa de internet.**

## Antes de começar
- A turma já existe ([manual 03](03-abrir-turma-nova.md)).
- Tenha o nome completo. Os dados pessoais (nascimento, telefone, CPF, responsáveis) são opcionais.

## Passo a passo

### 1. Cadastrar
1. Menu → **Alunos** → **Novo aluno** (o botão **+**).
2. **Cód.:** já vem com o próximo número livre. Se a academia usa outro código (ex.: `10A`), troque.
3. **Nome completo.**
4. Se quiser, abra **Nascimento · telefone · CPF** e **Responsáveis** e preencha.
5. Toque em **Salvar**. Aparece "Aluno cadastrado.".

### 2. Matricular
6. Ainda no cadastro, em **Matrículas**, toque em **Matricular**.
7. Escolha a **Turma** e o **Início da matrícula** (deixe hoje se ele começa hoje).
8. Confirme. A matrícula aparece como "desde dd/mm/aaaa · matriculado".

## Pronto quando
No **Lançar presença** da turma, o aluno aparece na lista com a etiqueta **novo**. Aluno novo sempre aparece na lista principal nas primeiras aulas.

## Dúvidas comuns
- **"Já existe um aluno com este código."** Cada código só pode ser usado uma vez na academia (`10a` e `10A` contam como o mesmo). Escolha outro.
- **Ele treina em duas turmas.** Toque em **Matricular** de novo e escolha a outra turma: uma matrícula para cada turma.
- **Ele começou na semana passada e eu esqueci.** Matricule com o **Início da matrícula** na data certa; depois você pode lançar as presenças dos dias passados ([manual 08](08-lancar-presenca.md), "Corrigir um dia que já passou").
- **Por que os dados pessoais não aparecem no celular sem internet?** Por segurança (muitos alunos são menores, LGPD), CPF, telefone, endereço e responsáveis ficam só no servidor. No aparelho fica apenas código e nome.
- **Chegaram vários alunos de uma vez.** Importe pela planilha ([manual 07](07-importar-alunos-da-planilha.md)).
