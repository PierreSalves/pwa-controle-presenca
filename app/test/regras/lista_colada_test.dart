import 'package:controle_presenca/regras/lista_colada.dart';
import 'package:flutter_test/flutter_test.dart';

List<(int, String, String)> _ler(String texto) => [
  for (final l in lerListaColada(texto)) (l.numero, l.codigo, l.nome),
];

void main() {
  test('cópia de planilha separa por tab e ignora colunas a mais', () {
    expect(_ler('(01)\tAna P. Ribeiro\tAdulto\r\n10A\tCaio M. Duarte\r\n'), [
      (1, '(01)', 'Ana P. Ribeiro'),
      (2, '10A', 'Caio M. Duarte'),
    ]);
  });

  test('ponto e vírgula e espaço também separam', () {
    expect(_ler('03;Bruno S. Lima\n(10A)   Caio  M.  Duarte'), [
      (1, '03', 'Bruno S. Lima'),
      (2, '(10A)', 'Caio M. Duarte'),
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
