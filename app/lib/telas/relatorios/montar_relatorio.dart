// Monta cada relatório da tela 7 como uma tabela neutra, desenhada tanto na tela (TabelaRelatorio)
// quanto na página impressa (gerarHtmlRelatorio): os números são os mesmos nos dois lugares.
import '../../dados/consulta_relatorios.dart';
import '../../regras/frequencia.dart';
import '../../regras/lista_lancamento.dart';
import '../../regras/presenca.dart';
import '../../regras/relatorios.dart';
import '../formatacao.dart';

enum TipoRelatorio {
  semanal('Presença semanal', 'Como a planilha do mês', 'Semanal'),
  mensal('Presença mensal', 'Presenças por mês e frequência', 'Mensal'),
  anual('Presença anual', 'JAN a DEZ, como a planilha anual', 'Anual'),
  porAluno('Por aluno', 'Cada aula do período', 'Por aluno'),
  graduacao(
    'Frequência para graduação',
    'Semestre, mínimo da turma',
    'Graduação',
  );

  const TipoRelatorio(this.titulo, this.descricao, this.rotuloCurto);
  final String titulo;
  final String descricao;
  final String rotuloCurto;
}

enum EstiloCelula { normal, veio, faltou, vazio, abaixoDoMinimo, futuro }

class CelulaRelatorio {
  const CelulaRelatorio(this.texto, [this.estilo = EstiloCelula.normal])
    : marca = false;

  /// Marca da presença semanal: um visto (ícone na tela, entidade no HTML), lido como "veio".
  const CelulaRelatorio.veio()
    : texto = 'veio',
      estilo = EstiloCelula.veio,
      marca = true;

  /// Marca de falta: um ponto, lido como "faltou".
  const CelulaRelatorio.faltou()
    : texto = 'faltou',
      estilo = EstiloCelula.faltou,
      marca = true;
  const CelulaRelatorio.vazia()
    : texto = '',
      estilo = EstiloCelula.vazio,
      marca = false;
  const CelulaRelatorio.futura()
    : texto = '–',
      estilo = EstiloCelula.futuro,
      marca = false;
  final String texto;
  final EstiloCelula estilo;

  /// Desenhada como símbolo (visto ou ponto) e lida pelo [texto].
  final bool marca;
}

class ColunaRelatorio {
  const ColunaRelatorio(this.rotulo, {this.etiqueta, this.esmaecida = false});
  final String rotulo;

  /// "repos." ou "avulsa" embaixo do rótulo.
  final String? etiqueta;
  final bool esmaecida;
}

class LinhaRelatorio {
  const LinhaRelatorio(this.rotulo, this.celulas, {this.rodape = false});
  final String rotulo;
  final List<CelulaRelatorio> celulas;

  /// Linha de totais ("Presentes", "Aulas").
  final bool rodape;
}

typedef GrupoColunas = ({String rotulo, int colunas});
typedef ItemResumo = ({String rotulo, String valor, String? apoio, bool baixo});

class RelatorioMontado {
  const RelatorioMontado({
    required this.tipo,
    required this.periodo,
    required this.rotuloPrimeiraColuna,
    required this.colunas,
    required this.linhas,
    this.grupos,
    this.resumo = const [],
    this.nota,
    this.legendaDeMarcas = false,
    this.vazio = 'Nenhuma aula lançada no período.',
  });

  final TipoRelatorio tipo;

  /// "01/11 a 30/11/2026 · mínimo 75%".
  final String periodo;
  final String rotuloPrimeiraColuna;
  final List<ColunaRelatorio> colunas;
  final List<LinhaRelatorio> linhas;

  /// Agrupamento das colunas (semanas na presença semanal).
  final List<GrupoColunas>? grupos;
  final List<ItemResumo> resumo;
  final String? nota;

  /// Mostra a legenda visto = veio, ponto = faltou, em branco = fora da matrícula.
  final bool legendaDeMarcas;
  final String vazio;

  bool get estaVazio => linhas.where((l) => !l.rodape).isEmpty;

  /// Semanal e anual são largos: paisagem na impressão.
  bool get paisagem =>
      tipo == TipoRelatorio.semanal || tipo == TipoRelatorio.anual;
}

const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _nomearMes(String mes) => _meses[int.parse(mes.substring(5, 7)) - 1];

String _formatarPeriodo(String inicio, String fim, int? minimo) {
  final mesmoAno = inicio.substring(0, 4) == fim.substring(0, 4);
  final de = mesmoAno ? formatarDiaMes(inicio) : formatarDataBr(inicio);
  return [
    '$de a ${formatarDataBr(fim)}',
    if (minimo != null) 'mínimo $minimo%',
  ].join(' · ');
}

String _formatarFrequencia(FrequenciaNoPeriodo f) =>
    f.percentual == null ? '–' : '${f.percentual}%';

CelulaRelatorio _celulaFrequencia(FrequenciaNoPeriodo f) => CelulaRelatorio(
  _formatarFrequencia(f),
  f.abaixoDoMinimo ? EstiloCelula.abaixoDoMinimo : EstiloCelula.normal,
);

ColunaRelatorio _colunaDaAula(AulaDaLista aula, {required bool comData}) =>
    ColunaRelatorio(
      comData
          ? '${obterDiaAbreviado(aula.data)} ${formatarDiaMes(aula.data)}'
          : obterDiaAbreviado(aula.data),
      etiqueta: aula.tipo == 'reposicao' ? 'repos.' : null,
    );

CelulaRelatorio _celulaDaMarca(MarcaPresenca marca) => switch (marca) {
  MarcaPresenca.veio => const CelulaRelatorio.veio(),
  MarcaPresenca.faltou => const CelulaRelatorio.faltou(),
  MarcaPresenca.foraDaMatricula => const CelulaRelatorio.vazia(),
};

/// Semanas da presença semanal (o celular mostra uma por vez).
List<SemanaDoRelatorio> obterSemanas(
  TurmaDoRelatorio turma,
  String inicio,
  String fim,
) => calcularSemanas(turma.base, inicio, fim);

/// Presença semanal: aluno × dias de aula das [semanas] (todas no desktop e na impressão).
RelatorioMontado montarSemanal(
  TurmaDoRelatorio turma,
  String inicio,
  String fim,
  List<SemanaDoRelatorio> semanas, {
  required bool comData,
}) {
  final base = turma.base;
  final aulas = [for (final s in semanas) ...s.aulas];
  final alunos = base.obterAlunosEntre(inicio, fim);
  return RelatorioMontado(
    tipo: TipoRelatorio.semanal,
    periodo:
        '${_formatarPeriodo(inicio, fim, null)} · '
        '${semanas.length} ${semanas.length == 1 ? 'semana' : 'semanas'}',
    rotuloPrimeiraColuna: 'Aluno',
    grupos: semanas.length < 2
        ? null
        : [
            for (final s in semanas)
              (
                rotulo:
                    '${s.ordem}ª sem. · ${formatarDiaMes(s.domingo)} a '
                    '${formatarDiaMes(s.sabado)}',
                colunas: s.aulas.length,
              ),
          ],
    colunas: [
      for (final a in aulas) _colunaDaAula(a, comData: comData),
      const ColunaRelatorio('Total'),
    ],
    linhas: aulas.isEmpty
        ? const []
        : [
            for (final aluno in alunos)
              LinhaRelatorio(formatarAluno(aluno.codigo, aluno.nome), [
                for (final a in aulas)
                  _celulaDaMarca(base.calcularMarca(aluno, a)),
                CelulaRelatorio('${base.contarPresencas(aluno, aulas)}'),
              ]),
            LinhaRelatorio('Presentes', rodape: true, [
              for (final a in aulas)
                CelulaRelatorio(
                  '${alunos.where((al) => base.calcularMarca(al, a) == MarcaPresenca.veio).length}',
                ),
              const CelulaRelatorio(''),
            ]),
          ],
    legendaDeMarcas: true,
  );
}

/// Presença mensal: presenças por mês e a frequência do período ([completo] na impressão e no desktop).
RelatorioMontado montarMensal(
  TurmaDoRelatorio turma,
  String inicio,
  String fim, {
  required bool completo,
}) {
  final base = turma.base;
  final aulas = base.obterAulasEntre(inicio, fim);
  final meses = calcularMeses(inicio, fim);
  final alunos = base.obterAlunosEntre(inicio, fim);
  return RelatorioMontado(
    tipo: TipoRelatorio.mensal,
    periodo: _formatarPeriodo(inicio, fim, base.minimo),
    rotuloPrimeiraColuna: 'Aluno',
    colunas: [
      for (final m in meses) ColunaRelatorio(_nomearMes(m)),
      if (completo) ...const [
        ColunaRelatorio('Aulas'),
        ColunaRelatorio('Presenças'),
        ColunaRelatorio('Repos.'),
      ],
      const ColunaRelatorio('Freq.'),
    ],
    linhas: aulas.isEmpty
        ? const []
        : [
            for (final aluno in alunos)
              () {
                final f = base.calcularFrequencia(aluno, inicio, fim);
                return LinhaRelatorio(formatarAluno(aluno.codigo, aluno.nome), [
                  for (final m in meses)
                    CelulaRelatorio(
                      '${base.contarPresencas(aluno, obterAulasDoMes(aulas, m))}',
                    ),
                  if (completo) ...[
                    CelulaRelatorio('${f.aulas}'),
                    CelulaRelatorio('${f.presencas}'),
                    CelulaRelatorio('${f.reposicoes}'),
                  ],
                  _celulaFrequencia(f),
                ]);
              }(),
            LinhaRelatorio('Aulas', rodape: true, [
              for (final m in meses)
                CelulaRelatorio(
                  '${contarAulasRegulares(obterAulasDoMes(aulas, m))}',
                ),
              if (completo) ...[
                CelulaRelatorio('${contarAulasRegulares(aulas)}'),
                const CelulaRelatorio(''),
                const CelulaRelatorio(''),
              ],
              const CelulaRelatorio(''),
            ]),
          ],
    nota:
        'Frequência = presenças + reposições ÷ aulas regulares lançadas dentro '
        'da matrícula (limite de 100%).',
  );
}

/// Presença anual: presenças de JAN a DEZ do ano de [fim].
RelatorioMontado montarAnual(TurmaDoRelatorio turma, String fim, String hoje) {
  final base = turma.base;
  final ano = fim.substring(0, 4);
  final inicioAno = '$ano-01-01';
  final fimAno = '$ano-12-31';
  final aulas = base.obterAulasEntre(inicioAno, fimAno);
  final meses = calcularMeses(inicioAno, fimAno);
  final alunos = base.obterAlunosEntre(inicioAno, fimAno);
  CelulaRelatorio celula(String mes, int valor) => ehMesFuturo(mes, hoje)
      ? const CelulaRelatorio.futura()
      : CelulaRelatorio('$valor');
  return RelatorioMontado(
    tipo: TipoRelatorio.anual,
    periodo: ano,
    rotuloPrimeiraColuna: 'Aluno',
    colunas: [
      for (final m in meses) ColunaRelatorio(_nomearMes(m).toUpperCase()),
      const ColunaRelatorio('Total'),
    ],
    linhas: aulas.isEmpty
        ? const []
        : [
            for (final aluno in alunos)
              LinhaRelatorio(formatarAluno(aluno.codigo, aluno.nome), [
                for (final m in meses)
                  celula(
                    m,
                    base.contarPresencas(aluno, obterAulasDoMes(aulas, m)),
                  ),
                CelulaRelatorio('${base.contarPresencas(aluno, aulas)}'),
              ]),
            LinhaRelatorio('Aulas', rodape: true, [
              for (final m in meses)
                celula(m, contarAulasRegulares(obterAulasDoMes(aulas, m))),
              CelulaRelatorio('${contarAulasRegulares(aulas)}'),
            ]),
          ],
    vazio: 'Nenhuma aula lançada em $ano.',
  );
}

/// Por aluno: cada aula do período dentro da matrícula, com os totais no resumo.
RelatorioMontado montarPorAluno(
  TurmaDoRelatorio turma,
  AlunoDoRelatorio aluno,
  String inicio,
  String fim,
) {
  final base = turma.base;
  final f = base.calcularFrequencia(aluno, inicio, fim);
  final aulas = calcularAulasDoAluno(base, aluno, inicio, fim);
  return RelatorioMontado(
    tipo: TipoRelatorio.porAluno,
    periodo:
        '${formatarAluno(aluno.codigo, aluno.nome)} · '
        '${_formatarPeriodo(inicio, fim, base.minimo)}',
    rotuloPrimeiraColuna: 'Aula',
    colunas: const [ColunaRelatorio('Tipo'), ColunaRelatorio('Situação')],
    resumo: [
      (rotulo: 'Aulas', valor: '${f.aulas}', apoio: null, baixo: false),
      (
        rotulo: 'Veio',
        valor: '${f.presencas + f.reposicoes}',
        apoio: f.reposicoes == 0
            ? null
            : '${f.reposicoes} ${f.reposicoes == 1 ? 'reposição' : 'reposições'}',
        baixo: false,
      ),
      (
        rotulo: 'Freq.',
        valor: _formatarFrequencia(f),
        apoio: null,
        baixo: f.abaixoDoMinimo,
      ),
    ],
    linhas: [
      for (final a in aulas)
        LinhaRelatorio(
          '${obterDiaAbreviado(a.aula.data)} ${formatarDataBr(a.aula.data)}',
          [
            CelulaRelatorio(a.aula.tipo == 'reposicao' ? 'repos.' : 'regular'),
            a.veio
                ? const CelulaRelatorio('veio', EstiloCelula.veio)
                : const CelulaRelatorio('faltou', EstiloCelula.faltou),
          ],
        ),
    ],
    vazio: 'Nenhuma aula do aluno no período.',
  );
}

/// Frequência para graduação: semestre de [fim] até [fim], alunos matriculados nesse dia.
RelatorioMontado montarGraduacao(TurmaDoRelatorio turma, String fim) {
  final base = turma.base;
  final inicio = calcularInicioDoSemestre(fim);
  final semestre =
      '${int.parse(fim.substring(5, 7)) <= 6 ? 1 : 2}º sem. ${fim.substring(0, 4)}';
  return RelatorioMontado(
    tipo: TipoRelatorio.graduacao,
    periodo:
        '$semestre · até ${formatarDataBr(fim)}'
        '${base.minimo == null ? '' : ' · mínimo ${base.minimo}%'}',
    rotuloPrimeiraColuna: 'Aluno',
    colunas: const [
      ColunaRelatorio('Aulas'),
      ColunaRelatorio('Presenças'),
      ColunaRelatorio('Repos.'),
      ColunaRelatorio('Freq.'),
    ],
    linhas: [
      for (final aluno in base.alunos)
        if (aluno.estaMatriculado(fim))
          () {
            final f = base.calcularFrequencia(aluno, inicio, fim);
            return LinhaRelatorio(formatarAluno(aluno.codigo, aluno.nome), [
              CelulaRelatorio('${f.aulas}'),
              CelulaRelatorio('${f.presencas}'),
              CelulaRelatorio('${f.reposicoes}'),
              _celulaFrequencia(f),
            ]);
          }(),
    ],
    nota:
        'Presenças + reposições ÷ aulas regulares lançadas na matrícula, no '
        'semestre (limite de 100%).',
    vazio: 'Nenhum aluno matriculado em ${formatarDataBr(fim)}.',
  );
}

/// Atalhos de período da tela 7.
enum AtalhoPeriodo { semana, mes, semestre, ano }

extension RotuloAtalho on AtalhoPeriodo {
  String get rotulo => switch (this) {
    AtalhoPeriodo.semana => 'Esta semana',
    AtalhoPeriodo.mes => 'Este mês',
    AtalhoPeriodo.semestre => 'Semestre',
    AtalhoPeriodo.ano => 'Ano',
  };
}

/// Início e fim do atalho para o dia [hoje] (fim é o último dia do intervalo, mesmo futuro).
({String inicio, String fim}) calcularPeriodoDoAtalho(
  AtalhoPeriodo atalho,
  String hoje,
) {
  final ano = int.parse(hoje.substring(0, 4));
  final mes = int.parse(hoje.substring(5, 7));
  String data(int a, int m, int d) =>
      '$a-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  int ultimoDia(int a, int m) => DateTime.utc(a, m + 1, 0).day;
  switch (atalho) {
    case AtalhoPeriodo.semana:
      final domingo = somarDiasNaData(
        hoje,
        -diasDaSemana.indexOf(obterDiaDaSemana(hoje)),
      );
      return (inicio: domingo, fim: somarDiasNaData(domingo, 6));
    case AtalhoPeriodo.mes:
      return (
        inicio: data(ano, mes, 1),
        fim: data(ano, mes, ultimoDia(ano, mes)),
      );
    case AtalhoPeriodo.semestre:
      return mes <= 6
          ? (inicio: data(ano, 1, 1), fim: data(ano, 6, 30))
          : (inicio: data(ano, 7, 1), fim: data(ano, 12, 31));
    case AtalhoPeriodo.ano:
      return (inicio: data(ano, 1, 1), fim: data(ano, 12, 31));
  }
}
