// Peças comuns da tela 7: campos de período, atalhos, escolha do aluno e a impressão.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../dados/consulta_relatorios.dart';
import '../../estado/dependencias.dart';
import '../../regras/presenca.dart';
import '../../regras/relatorios.dart';
import '../formatacao.dart';
import '../tema.dart';
import 'html_relatorio.dart';
import 'montar_relatorio.dart';

/// Monta o relatório escolhido. [paraImprimir] usa a versão completa (todas as semanas, todas as
/// colunas); [compacto] é o celular.
RelatorioMontado? montarRelatorio(
  TurmaDoRelatorio turma,
  TipoRelatorio tipo, {
  required String inicio,
  required String fim,
  required String hoje,
  AlunoDoRelatorio? aluno,
  bool compacto = false,
  int? semana,
}) {
  switch (tipo) {
    case TipoRelatorio.semanal:
      final semanas = obterSemanas(turma, inicio, fim);
      final escolhidas = semana == null || semanas.isEmpty
          ? semanas
          : [semanas[semana.clamp(0, semanas.length - 1)]];
      return montarSemanal(
        turma,
        inicio,
        fim,
        escolhidas,
        comData: escolhidas.length < 2 && semana == null,
      );
    case TipoRelatorio.mensal:
      return montarMensal(turma, inicio, fim, completo: !compacto);
    case TipoRelatorio.anual:
      return montarAnual(turma, fim, hoje);
    case TipoRelatorio.porAluno:
      return aluno == null ? null : montarPorAluno(turma, aluno, inicio, fim);
    case TipoRelatorio.graduacao:
      return montarGraduacao(turma, fim);
  }
}

/// Abre a página impressa; avisa se o navegador bloqueou a aba.
void imprimirRelatorio(
  BuildContext context,
  TurmaDoRelatorio turma,
  RelatorioMontado relatorio,
) {
  final dependencias = EscopoDependencias.obter(context);
  final sessao = dependencias.sessao;
  final usuario = sessao.usuario;
  final html = gerarHtmlRelatorio(
    relatorio,
    CabecalhoImpressao(
      academia: sessao.nomeAcademia ?? 'Academia',
      cabecalhoAcademia: sessao.cabecalhoAcademia,
      turma: turma.nome,
      cabecalhoTurma: turma.cabecalhoImpressao,
      geradoEm: dependencias.relogio(),
      geradoPor: usuario == null ? '' : '${usuario.nome} (${usuario.tipo})',
    ),
  );
  if (!dependencias.abrirImpressao(html)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível abrir a impressão. Permita janelas pop-up para este site.',
        ),
      ),
    );
  }
}

/// Campo de data que abre o calendário.
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.rotulo,
    required this.data,
    required this.aoEscolher,
  });

  final String rotulo;
  final String data;
  final ValueChanged<String> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$rotulo: ${formatarDataBr(data)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final escolhida = await showDatePicker(
            context: context,
            initialDate: DateTime.parse(data),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            helpText: rotulo,
          );
          if (escolhida != null) aoEscolher(formatarData(escolhida));
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: rotulo,
            isDense: true,
            suffixIcon: const Icon(Symbols.calendar_month, size: 20),
          ),
          child: Text(
            formatarDataBr(data),
            style: const TextStyle(fontFeatures: numerosFixos),
          ),
        ),
      ),
    );
  }
}

/// Escolha entre opções curtas (atalhos de período e tipos de relatório no desktop).
class EscolhaEmPilulas<T> extends StatelessWidget {
  const EscolhaEmPilulas({
    super.key,
    required this.opcoes,
    required this.escolhida,
    required this.rotular,
    required this.aoEscolher,
    this.icone,
  });

  final List<T> opcoes;
  final T? escolhida;
  final String Function(T) rotular;
  final IconData Function(T)? icone;
  final ValueChanged<T> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opcao in opcoes)
          ChoiceChip(
            label: Text(rotular(opcao)),
            avatar: icone == null
                ? null
                : Icon(
                    icone!(opcao),
                    size: 18,
                    color: opcao == escolhida ? Colors.white : CoresV2.tatame,
                  ),
            showCheckmark: false,
            selected: opcao == escolhida,
            selectedColor: CoresV2.tatame,
            backgroundColor: CoresV2.cartao,
            side: BorderSide(
              color: opcao == escolhida ? CoresV2.tatame : CoresV2.linha,
              width: 1.5,
            ),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              fontFamily: 'Lexend',
              color: opcao == escolhida ? Colors.white : CoresV2.grafite,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: (_) => aoEscolher(opcao),
          ),
      ],
    );
  }
}

/// Escolha da turma (lista suspensa).
class EscolhaTurma extends StatelessWidget {
  const EscolhaTurma({
    super.key,
    required this.turmas,
    required this.turmaId,
    required this.aoEscolher,
  });

  final List<({String id, String nome})> turmas;
  final String? turmaId;
  final ValueChanged<String> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: turmaId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Turma', isDense: true),
      items: [
        for (final t in turmas)
          DropdownMenuItem(value: t.id, child: Text(t.nome)),
      ],
      onChanged: (id) {
        if (id != null) aoEscolher(id);
      },
    );
  }
}

/// Escolha do aluno do relatório "Por aluno" (matriculados no período).
class EscolhaAluno extends StatelessWidget {
  const EscolhaAluno({
    super.key,
    required this.alunos,
    required this.alunoId,
    required this.aoEscolher,
  });

  final List<AlunoDoRelatorio> alunos;
  final String? alunoId;
  final ValueChanged<String> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(alunos.length),
      initialValue: alunos.any((a) => a.id == alunoId) ? alunoId : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Aluno', isDense: true),
      hint: const Text('Escolha o aluno'),
      items: [
        for (final a in alunos)
          DropdownMenuItem(
            value: a.id,
            child: Text(
              formatarAluno(a.codigo, a.nome),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) {
        if (id != null) aoEscolher(id);
      },
    );
  }
}

/// Garante De ≤ Até: ao escolher um De depois do Até, o Até acompanha (e vice-versa).
({String inicio, String fim}) ajustarPeriodo(String inicio, String fim) =>
    inicio.compareTo(fim) > 0
    ? (inicio: inicio, fim: inicio)
    : (inicio: inicio, fim: fim);

/// Hoje em São Paulo pelo relógio das dependências.
String obterHoje(BuildContext context) =>
    obterHojeEmSaoPaulo(EscopoDependencias.obter(context).relogio());
