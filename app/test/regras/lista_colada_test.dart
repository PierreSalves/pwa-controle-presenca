import 'package:controle_presenca/regras/lista_colada.dart';
import 'package:flutter_test/flutter_test.dart';

List<(int, String, String)> _ler(String texto) => [
  for (final l in lerListaColada(texto)) (l.numero, l.codigo, l.nome),
];

void main() {
  test('cópia de planilha separa por tab e ignora colunas a mais', () {
    expect(
      _ler(
        '(01)\tAugusto E. B. Torres\tAdulto\r\n10A\tLucas A. Costelinha\r\n',
      ),
      [(1, '(01)', 'Augusto E. B. Torres'), (2, '10A', 'Lucas A. Costelinha')],
    );
  });

  test('ponto e vírgula e espaço também separam', () {
    expect(_ler('03;Lucas V. S. da Mata\n(10A)   Lucas  A.  Costelinha'), [
      (1, '03', 'Lucas V. S. da Mata'),
      (2, '(10A)', 'Lucas A. Costelinha'),
    ]);
  });

  test(
    'linhas em branco ficam de fora, mas a numeração segue o texto colado',
    () {
      expect(_ler('\n01 Ana\n\n02 Bia\n'), [
        (2, '01', 'Ana'),
        (4, '02', 'Bia'),
      ]);
    },
  );

  test('cabeçalho na primeira linha é ignorado', () {
    expect(_ler('Código\tNome\n01\tAna'), [(2, '01', 'Ana')]);
    expect(_ler('Cód. Nome\n01 Ana'), [(2, '01', 'Ana')]);
  });

  test('linha só com código fica sem nome (a API acusa como incompleta)', () {
    expect(_ler('15'), [(1, '15', '')]);
  });

  test('texto vazio não tem linhas', () {
    expect(lerListaColada('  \n \n'), isEmpty);
  });
}
