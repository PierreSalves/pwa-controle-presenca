import 'dart:convert';

import 'package:controle_presenca/dados/banco_local.dart';
import 'package:controle_presenca/dados/cliente_api.dart';
import 'package:controle_presenca/estado/dependencias.dart';
import 'package:controle_presenca/main.dart';
import 'package:controle_presenca/plataforma/imagens.dart';
import 'package:controle_presenca/plataforma/instalacao.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:controle_presenca/telas/componentes.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import 'dados/apoio.dart';

http.Response _json(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// PNG de 1×1 px de verdade (o Image.memory consegue abrir).
final pngDeTeste = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Serviço de imagens falso: "escolhe" o PNG de teste e devolve ele mesmo como ícone.
class _ImagensFalsas implements ServicoImagens {
  final List<int> iconesGerados = [];

  @override
  Future<ImagemEscolhida?> escolherImagem() async =>
      ImagemEscolhida(bytes: pngDeTeste, nome: 'logo.png');

  @override
  Future<Uint8List> gerarIcone(Uint8List imagem, int tamanho) async {
    iconesGerados.add(tamanho);
    return pngDeTeste;
  }
}

/// Instalação falsa: o teste decide se é iPhone e se o navegador ofereceu o convite.
class _InstalacaoFalsa implements ServicoInstalacao {
  bool iphone = false;
  int convites = 0;
  final List<({String? titulo, int? icone, String? chave})> identidades = [];
  final _disponivel = ValueNotifier(false);

  set disponivel(bool valor) => _disponivel.value = valor;

  @override
  bool get estaInstalado => false;

  @override
  bool get ehIphone => iphone;

  @override
  ValueListenable<bool> get conviteDisponivel => _disponivel;

  @override
  Future<bool> convidar() async {
    convites++;
    return true;
  }

  @override
  void definirIdentidade({
    required String? titulo,
    required Uint8List? icone,
    required String? chave,
  }) => identidades.add((titulo: titulo, icone: icone?.length, chave: chave));
}

/// API falsa: login da Carla, pull com a turma de apoio.dart e push aceitando tudo.
class _ApiFalsa {
  final List<List<dynamic>> envios = [];
  final List<Map<String, dynamic>> matriculasEncerradas = [];
  final List<Map<String, dynamic>> alunosCriados = [];
  final List<Map<String, dynamic>> quadrosCriados = [];
  int alunosImportados = 0;
  final List<Map<String, dynamic>> importacoes = [];
  String tipoUsuario = 'assistente';
  final List<Map<String, dynamic>> usuariosCriados = [];
  final List<Map<String, dynamic>> academias = [
    {
      'id': '0190f5a0-0000-7000-8000-0000000000c1',
      'nome': 'Academia Teste',
      'nome_curto': null,
      'ativo': 1,
      'usuarios': 3,
      'alunos': 1,
      'turmas': 1,
    },
  ];
  final List<Map<String, dynamic>> academiasCriadas = [];
  final List<String> cargasIniciais = [];
  Map<String, dynamic> academia = {
    'nome': 'Academia Teste',
    'nome_curto': null,
    'cabecalho_impressao': null,
    'tem_logotipo': 0,
    'logotipo_versao': null,
  };
  Map<String, dynamic>? logotipoEnviado;
  final List<Map<String, dynamic>> academiaSalva = [];
  final List<Map<String, dynamic>> senhasRedefinidas = [];
  final List<Map<String, dynamic>> professoresCriados = [];
  bool online = true;

  Future<http.Response> responder(http.Request req) async {
    if (!online) throw http.ClientException('offline');
    final caminho = req.url.path;
    if (caminho.contains('/admin/academias/') &&
        caminho.endsWith('/senha') &&
        req.method == 'POST') {
      senhasRedefinidas.add({
        'caminho': caminho,
        ...jsonDecode(req.body) as Map<String, dynamic>,
      });
      return http.Response('', 204);
    }
    if (caminho.contains('/admin/academias/') &&
        caminho.endsWith('/professores')) {
      if (req.method == 'POST') {
        professoresCriados.add(jsonDecode(req.body) as Map<String, dynamic>);
        return _json({'professor': {}}, 201);
      }
      return _json({
        'professores': [
          {
            'id': '0190f5a0-0000-7000-8000-0000000000p1',
            'nome': 'Marcos Silva',
            'email': 'marcos@juniao.com.br',
            'ativo': 1,
            'ultimo_login_em': '2026-11-02T13:00:00.000Z',
          },
          {
            'id': '0190f5a0-0000-7000-8000-0000000000p2',
            'nome': 'Carla Souza',
            'email': 'carla@juniao.com.br',
            'ativo': 1,
            'ultimo_login_em': null,
          },
          {
            'id': '0190f5a0-0000-7000-8000-0000000000p3',
            'nome': 'Rui Antigo',
            'email': 'rui@juniao.com.br',
            'ativo': 0,
            'ultimo_login_em': null,
          },
        ],
      });
    }
    final token = {
      'token_acesso': 'T',
      'expira_em': agora.add(const Duration(minutes: 15)).toIso8601String(),
    };
    if (caminho.endsWith('/entrar')) {
      final corpo = jsonDecode(req.body) as Map;
      if (corpo['senha'] != 'segredo123') {
        return _json({'erro': 'credenciais_invalidas'}, 401);
      }
      return _json({
        ...token,
        'usuario': {
          'id': 'u1',
          'nome': 'Carla',
          'email': 'carla@exemplo.com',
          'tipo': tipoUsuario,
          'tenant_id': tipoUsuario == 'superadmin' ? null : 't1',
        },
      });
    }
    if (caminho.endsWith('/renovar')) return _json(token);
    if (caminho.endsWith('/eu')) {
      return _json({
        'usuario': {'id': 'u1'},
        'tenant': {
          'id': 't1',
          'nome': academia['nome'],
          'logotipo_versao': academia['logotipo_versao'],
        },
        'turmas': [],
      });
    }
    if (caminho.endsWith('/sair')) return http.Response('', 204);
    if (caminho.endsWith('/eu/logotipo/512') ||
        caminho.endsWith('/eu/logotipo/original')) {
      return http.Response.bytes(pngDeTeste, 200);
    }
    if (caminho.endsWith('/api/academia') && req.method == 'GET') {
      return _json({'academia': academia});
    }
    if (caminho.endsWith('/api/academia') && req.method == 'PUT') {
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      academiaSalva.add(corpo);
      academia = {...academia, ...corpo};
      return _json({'academia': academia});
    }
    if (caminho.endsWith('/academia/logotipo') && req.method == 'PUT') {
      logotipoEnviado = jsonDecode(req.body) as Map<String, dynamic>;
      academia = {...academia, 'tem_logotipo': 1, 'logotipo_versao': 'v1'};
      return _json({'academia': academia});
    }
    if (caminho.endsWith('/academia/logotipo') && req.method == 'DELETE') {
      academia = {...academia, 'tem_logotipo': 0, 'logotipo_versao': null};
      return _json({'academia': academia});
    }
    if (caminho.endsWith('/admin/academias') && req.method == 'GET') {
      return _json({'academias': academias});
    }
    if (caminho.endsWith('/admin/academias') && req.method == 'POST') {
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      academiasCriadas.add(corpo);
      final nova = {
        'id': '0190f5a0-0000-7000-8000-0000000000c2',
        'nome': corpo['nome'],
        'nome_curto': corpo['nome_curto'],
        'ativo': 1,
        'usuarios': 1,
        'alunos': 0,
        'turmas': 0,
      };
      academias.add(nova);
      return _json({'academia': nova}, 201);
    }
    if (caminho.contains('/admin/academias/') && caminho.endsWith('/turmas')) {
      return _json({'turmas': []});
    }
    if (caminho.contains('/admin/academias/') &&
        caminho.endsWith('/alunos/importacao')) {
      cargasIniciais.add(caminho);
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      final quantos = (corpo['alunos'] as List).length;
      return _json({
        'relatorio': {
          'incompletas': [],
          'codigos_repetidos': [],
          'codigos_existentes': [],
          'nomes_repetidos': [],
          'pode_importar': true,
        },
        'importados': corpo['confirmar'] == true ? quantos : 0,
      }, corpo['confirmar'] == true ? 201 : 200);
    }
    if (caminho.contains('/matriculas/') && req.method == 'PUT') {
      matriculasEncerradas.add(jsonDecode(req.body) as Map<String, dynamic>);
      return _json({'matricula': {}});
    }
    if (caminho.endsWith('/api/usuarios') && req.method == 'GET') {
      return _json({
        'usuarios': [
          {
            'id': 'u1',
            'nome': 'Carla',
            'email': 'carla@exemplo.com',
            'tipo': tipoUsuario,
            'ativo': 1,
            'turmas': [],
          },
        ],
      });
    }
    if (caminho.endsWith('/api/usuarios') && req.method == 'POST') {
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      usuariosCriados.add(corpo);
      return _json({
        'usuario': {...corpo, 'id': 'u9', 'ativo': 1, 'turmas': []},
      }, 201);
    }
    if (caminho.endsWith('/alunos/importacao')) {
      // Relatório simplificado: só códigos repetidos na lista.
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      final alunos = (corpo['alunos'] as List).cast<Map<String, dynamic>>();
      final porCodigo = <String, List<int>>{};
      for (var i = 0; i < alunos.length; i++) {
        porCodigo
            .putIfAbsent(alunos[i]['codigo'] as String, () => [])
            .add(i + 1);
      }
      final repetidos = [
        for (final e in porCodigo.entries)
          if (e.value.length > 1) {'codigo': e.key, 'linhas': e.value},
      ];
      final relatorio = {
        'incompletas': [],
        'codigos_repetidos': repetidos,
        'codigos_existentes': [],
        'nomes_repetidos': [],
        'pode_importar': repetidos.isEmpty,
      };
      final grava = corpo['confirmar'] == true && repetidos.isEmpty;
      if (grava) alunosImportados += alunos.length;
      importacoes.add(corpo);
      return _json({
        'relatorio': relatorio,
        'matricula': corpo['turma_id'] == null
            ? null
            : {
                'turma_id': corpo['turma_id'],
                'turma_nome': 'Adulto',
                'data_inicio': corpo['data_inicio'],
              },
        'importados': grava ? alunos.length : 0,
      }, grava ? 201 : 200);
    }
    if (caminho.endsWith('/alunos/proximo-codigo')) {
      return _json({'codigo': '12'});
    }
    if (caminho.endsWith('/alunos') && req.method == 'GET') {
      return _json({
        'alunos': [
          {
            'id': alunoId,
            'codigo': '10A',
            'nome': 'Ana',
            'ativo': 1,
            'turmas': ['Turma A'],
            'graduacao': {'faixa': 'Azul', 'grau': 2},
          },
        ],
      });
    }
    if (caminho.endsWith('/alunos/$alunoId') && req.method == 'GET') {
      return _json({
        'aluno': {
          'id': alunoId,
          'codigo': '10A',
          'nome': 'Ana',
          'ativo': 1,
          'data_nascimento': null,
        },
        'matriculas': [],
        'graduacoes': [
          {
            'id': '0190f5a0-0000-7000-8000-0000000000g1',
            'faixa': 'Azul',
            'grau': 2,
            'data_graduacao': '2026-06-05',
            'observacoes': null,
          },
        ],
      });
    }
    if (caminho.endsWith('/alunos') && req.method == 'POST') {
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      alunosCriados.add(corpo);
      return _json({
        'aluno': {...corpo, 'id': '0190f5a0-0000-7000-8000-0000000000b9'},
        'matriculas': [],
        'graduacoes': [],
      }, 201);
    }
    if (caminho.endsWith('/api/turmas') && req.method == 'GET') {
      return _json({
        'turmas': [
          {'id': turmaId, 'nome': 'Turma $turmaId', 'alunos_matriculados': 1},
        ],
      });
    }
    if (caminho.endsWith('/quadros') && req.method == 'POST') {
      quadrosCriados.add(jsonDecode(req.body) as Map<String, dynamic>);
      return _json({'quadros': []}, 201);
    }
    if (caminho.endsWith('/api/turmas/$turmaId') && req.method == 'PUT') {
      return _json({
        'turma': {'id': turmaId},
      });
    }
    if (caminho.endsWith('/api/turmas/$turmaId')) {
      return _json({
        'turma': {
          'id': turmaId,
          'nome': 'Turma $turmaId',
          'frequencia_minima': 75,
          'cabecalho_impressao': null,
        },
        'quadros': [
          {
            'id': 'q1',
            'vigencia_inicio': '2026-01-01',
            'vigencia_fim': null,
            'domingo': 0,
            'segunda': 0,
            'terca': 0,
            'quarta': 1,
            'quinta': 1,
            'sexta': 0,
            'sabado': 2,
          },
        ],
        'regras': {
          'lista_lancamento': {'percentual_minimo': 30, 'ultimas_aulas': 8},
          'alunos_sumidos': {'semanas': 4},
        },
        'acessos': [
          {'id': 'u1', 'nome': 'Carla', 'tipo': 'assistente'},
        ],
      });
    }
    if (caminho.endsWith('/sync/pull')) return _json(montarPull());
    if (caminho.endsWith('/sync/push')) {
      final ops = (jsonDecode(req.body) as Map)['operacoes'] as List;
      envios.add(ops);
      return _json({
        'aceitos': [for (final op in ops) (op as Map)['id']],
        'rejeitados': [],
      });
    }
    return _json({'erro': 'rota_nao_encontrada'}, 404);
  }
}

void main() {
  late BancoLocal banco;
  late _ApiFalsa api;
  late Dependencias dependencias;
  late List<String> impressos;
  late _ImagensFalsas imagens;
  late _InstalacaoFalsa instalacao;

  setUp(() {
    impressos = [];
    imagens = _ImagensFalsas();
    instalacao = _InstalacaoFalsa();
    banco = BancoLocal(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    api = _ApiFalsa();
    dependencias = Dependencias(
      banco: banco,
      cliente: ClienteApi(
        base: Uri.parse('https://app.test/api/'),
        relogio: () => agora,
        cliente: MockClient(api.responder),
      ),
      relogio: () => agora,
      imagens: imagens,
      instalacao: instalacao,
      abrirImpressao: (html) {
        impressos.add(html);
        return true;
      },
    );
  });

  tearDown(() async {
    dependencias.coordenador.dispose();
    await banco.close();
  });

  /// Deixa o banco e a API falsa responderem (fora do relógio falso) e redesenha.
  Future<void> esperar(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  /// O botão fica abaixo da lista e da turma: rola até ele antes de tocar.
  Future<void> tocarConferir(WidgetTester tester) async {
    final botao = find.text('Conferir lista');
    await tester.scrollUntilVisible(
      botao,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(botao);
  }

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(ControlePresencaApp(dependencias: dependencias));
    await tester.runAsync(dependencias.sessao.iniciar);
    await tester.pumpAndSettle();
  }

  Future<void> entrar(
    WidgetTester tester, {
    String senha = 'segredo123',
  }) async {
    await abrirApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'carla@exemplo.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), senha);
    await tester.tap(find.text('Entrar'));
    await esperar(tester);
  }

  /// Do Início, abre o lançamento de hoje (uma turma só: a escolha é pulada).
  Future<void> abrirLancamentoDeHoje(WidgetTester tester) async {
    await entrar(tester);
    await tester.tap(find.text('Lançar presença de hoje'));
    await esperar(tester);
  }

  Future<void> fecharApp(WidgetTester tester) async {
    // Desmonta as telas (para o timer da atualização periódica) antes de fechar o banco.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('sem usuário gravado abre a tela de entrar', (tester) async {
    await abrirApp(tester);
    expect(find.text('Controle de presença'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    // A TghServices só como copyright discreto no fim, nunca em destaque.
    expect(find.text('© 2026 TghServices'), findsOneWidget);
    expect(find.text('TghServices'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('senha errada mostra o aviso', (tester) async {
    await entrar(tester, senha: 'errada');
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('depois do login abre o Início com o nome da academia', (
    tester,
  ) async {
    await entrar(tester);
    expect(find.text('Academia Teste'), findsOneWidget);
    expect(find.text('Lançar presença de hoje'), findsOneWidget);
    expect(find.text('Suas turmas'), findsOneWidget);
    expect(find.text('Turma $turmaId · qua qui · 1 aluno'), findsOneWidget);
    expect(find.text('Resumo de 2026'), findsOneWidget);
    expect(find.textContaining('Tudo enviado'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('lança a presença de hoje da única turma e marca a aluna', (
    tester,
  ) async {
    await abrirLancamentoDeHoje(tester);
    expect(find.text('Turma $turmaId'), findsOneWidget);
    expect(find.text('qui'), findsOneWidget);
    expect(find.textContaining('(10A) Ana'), findsOneWidget);
    expect(find.textContaining('(11) Bruno'), findsNothing);
    expect(find.text('0 presentes'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await esperar(tester);
    expect(find.text('1 presentes'), findsOneWidget);
    expect(api.envios.expand((e) => e).length, 2); // aula + presença
    expect(find.textContaining('Tudo enviado'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('sem internet a marcação fica aguardando envio', (tester) async {
    await abrirLancamentoDeHoje(tester);
    api.online = false;
    await tester.tap(find.byType(Checkbox));
    await esperar(tester);
    expect(find.text('1 presentes'), findsOneWidget);
    expect(find.textContaining('2 aguardando envio'), findsOneWidget);
    expect(find.textContaining('sem internet'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('cria reposição avulsa e marca a aluna nela', (tester) async {
    await abrirLancamentoDeHoje(tester);
    final botao = find.text('Reposição avulsa (outro dia)');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text('Turma $turmaId'), findsOneWidget);
    expect(find.text('12/11/2026 (quinta)'), findsOneWidget);

    await tester.tap(find.text('Criar e marcar presenças'));
    await esperar(tester);
    expect(find.text('avulsa'), findsOneWidget);
    expect(find.textContaining('reposição avulsa de 12/11'), findsOneWidget);
    expect(find.text('0 presentes'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await esperar(tester);
    expect(find.text('1 presentes'), findsOneWidget);
    final enviados = api.envios.expand((e) => e).toList();
    final aula = enviados.firstWhere((op) => op['tabela'] == 'aulas');
    expect((aula['registro'] as Map)['tipo'], 'reposicao');
    expect(enviados.where((op) => op['tabela'] == 'presencas'), hasLength(1));
    await fecharApp(tester);
  });

  testWidgets('encerra a matrícula de aluno sumido sugerindo a data', (
    tester,
  ) async {
    await entrar(tester);
    // A Ana está matriculada desde 01/10 e nunca veio: sumida há mais de 4 semanas.
    expect(find.text('1 aluno sem vir há mais de 4 semanas'), findsOneWidget);
    expect(find.text('(10A) Ana · nunca veio'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Encerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Encerrar matrícula'), findsOneWidget);
    expect(
      find.text('01/10/2026'),
      findsOneWidget,
    ); // nunca veio: início da matrícula

    await tester.tap(find.widgetWithText(FilledButton, 'Encerrar'));
    await esperar(tester);
    expect(api.matriculasEncerradas.single, {
      'data_inicio': '2026-10-01',
      'data_fim': '2026-10-01',
      'situacao': 'encerrado',
    });
    expect(
      find.text('Matrícula de Ana encerrada em 01/10/2026.'),
      findsOneWidget,
    );
    await fecharApp(tester);
  });

  testWidgets('cadastra aluno pelo menu com o código sugerido', (tester) async {
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alunos'));
    await esperar(tester);
    expect(find.text('Ativos · 1'), findsOneWidget);
    expect(find.text('(10A) Ana'), findsOneWidget);
    expect(find.text('Turma A'), findsOneWidget);

    await tester.tap(find.byTooltip('Novo aluno'));
    await esperar(tester);
    expect(find.text('12'), findsOneWidget); // código sugerido
    expect(
      find.text('Salve o aluno para matricular e registrar graduações.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome completo'),
      'Bruno Lima',
    );
    await tester.tap(find.text('Salvar'));
    await esperar(tester);
    expect(api.alunosCriados.single['codigo'], '12');
    expect(api.alunosCriados.single['nome'], 'Bruno Lima');
    expect(find.text('Aluno cadastrado.'), findsOneWidget);
    expect(find.text('Matricular'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('muda o quadro de aulas da turma a partir de hoje', (
    tester,
  ) async {
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turmas'));
    await esperar(tester);
    expect(find.text('1 aluno'), findsOneWidget);

    await tester.tap(find.text('Turma $turmaId'));
    await esperar(tester);
    expect(find.text('Quadro de aulas · desde 01/01/2026'), findsOneWidget);
    await tester.tap(find.text('seg'));
    await tester.pump();
    expect(find.text('Quadro de aulas · desde 12/11/2026'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Só professor altera os acessos'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Carla (assistente)'), findsOneWidget);
    expect(find.byTooltip('Tirar acesso de Carla'), findsNothing); // assistente
    await tester.tap(find.text('Salvar'));
    await esperar(tester);
    expect(api.quadrosCriados.single['vigencia_inicio'], '2026-11-12');
    expect((api.quadrosCriados.single['dias'] as Map)['segunda'], 1);
    expect((api.quadrosCriados.single['dias'] as Map)['sabado'], 2);
    expect(find.text('Alterações salvas.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('importa alunos colados: acusa repetido e importa corrigido', (
    tester,
  ) async {
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alunos'));
    await esperar(tester);
    await tester.tap(find.text('Importar planilha'));
    await tester.pumpAndSettle();

    // Linha 2 em branco: o relatório aponta as linhas do texto colado (1 e 3).
    await tester.enterText(
      find.byType(TextField),
      '20\tAna\n\n20\tBia\n21\tCaio',
    );
    await tocarConferir(tester);
    await esperar(tester);
    expect(find.text('3 linhas lidas'), findsOneWidget);
    expect(find.text('Código 20 repetido nas linhas 1 e 3'), findsOneWidget);
    final botao = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Importar 3 alunos'),
    );
    expect(botao.onPressed, isNull);

    await tester.tap(find.text('Voltar e corrigir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '20\tAna\n22\tBia\n21\tCaio',
    );
    await tocarConferir(tester);
    await esperar(tester);
    expect(find.text('Tudo certo para importar.'), findsOneWidget);
    await tester.tap(find.text('Importar 3 alunos'));
    await esperar(tester);
    expect(api.alunosImportados, 3);
    expect(find.text('3 alunos importados.'), findsOneWidget);
    expect(
      find.text('Importar planilha'),
      findsOneWidget,
    ); // voltou para a lista
    await fecharApp(tester);
  });

  testWidgets(
    'importa e matricula todos na turma escolhida, com a data de hoje',
    (tester) async {
      await entrar(tester);
      await tester.tap(find.byTooltip('Abrir menu de navegação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alunos'));
      await esperar(tester);
      await tester.tap(find.text('Importar planilha'));
      await esperar(tester);

      // Sem turma, a data fica desabilitada.
      expect(find.text('Não matricular (só cadastrar)'), findsOneWidget);
      expect(find.text('12/11/2026'), findsOneWidget);
      expect(
        find.text(
          'Sem turma, a data fica desabilitada e os alunos só são cadastrados.',
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '20\tAna\n21\tCaio');
      await tester.tap(find.text('Não matricular (só cadastrar)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turma $turmaId').last);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Todos os alunos da lista serão matriculados nessa turma a partir dessa data.',
        ),
        findsOneWidget,
      );

      await tocarConferir(tester);
      await esperar(tester);
      expect(api.importacoes.last['turma_id'], turmaId);
      expect(api.importacoes.last['data_inicio'], '2026-11-12');
      expect(
        find.textContaining(
          'Os 2 alunos serão matriculados na turma Adulto a partir de 12/11/2026',
          findRichText: true,
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Importar e matricular 2 alunos'));
      await esperar(tester);
      expect(api.importacoes.last['confirmar'], true);
      expect(api.importacoes.last['turma_id'], turmaId);
      expect(
        find.text('2 alunos importados e matriculados na turma Adulto.'),
        findsOneWidget,
      );
      await fecharApp(tester);
    },
  );

  testWidgets('sem turma o relatório avisa que é só cadastro', (tester) async {
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alunos'));
    await esperar(tester);
    await tester.tap(find.text('Importar planilha'));
    await esperar(tester);
    await tester.enterText(find.byType(TextField), '20\tAna');
    await tocarConferir(tester);
    await esperar(tester);
    expect(api.importacoes.last.containsKey('turma_id'), isFalse);
    expect(
      find.text('Só cadastro: nenhuma matrícula será criada.'),
      findsOneWidget,
    );
    expect(find.text('Importar 1 aluno'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('Usuários só aparece no menu do professor', (tester) async {
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    expect(find.text('Turmas'), findsOneWidget);
    expect(find.text('Usuários'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('professor cadastra assistente com turma pela lista', (
    tester,
  ) async {
    api.tipoUsuario = 'professor';
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuários'));
    await esperar(tester);
    expect(find.text('Carla'), findsOneWidget);

    await tester.tap(find.text('Novo: nome · e-mail · tipo · turmas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Dani');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'dani@exemplo.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha inicial'),
      'senha-da-dani',
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Turma $turmaId'));
    await tester.pump();
    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.tap(find.text('Cadastrar'));
    await esperar(tester);
    expect(api.usuariosCriados.single, {
      'nome': 'Dani',
      'email': 'dani@exemplo.com',
      'tipo': 'assistente',
      'senha': 'senha-da-dani',
      'turma_ids': [turmaId],
    });
    expect(
      find.text('Usuário cadastrado. Passe a senha inicial para a pessoa.'),
      findsOneWidget,
    );
    await fecharApp(tester);
  });

  testWidgets('voltar com alterações não salvas pergunta antes de descartar', (
    tester,
  ) async {
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alunos'));
    await esperar(tester);
    await tester.tap(find.byTooltip('Novo aluno'));
    await esperar(tester);

    // Sem nada digitado, volta direto.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Ativos · 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Novo aluno'));
    await esperar(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome completo'),
      'Bruno Lima',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.text('Bruno Lima'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Ativos · 1'), findsOneWidget);
    expect(api.alunosCriados, isEmpty);
    await fecharApp(tester);
  });

  testWidgets('carregando tem rótulo para o leitor de tela', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Carregando(),
      ),
    );
    expect(find.bySemanticsLabel('Carregando…'), findsOneWidget);
  });

  testWidgets(
    'no desktop a importação põe lista e turma lado a lado (D8, D9)',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await entrar(tester);
      await tester.tap(find.text('Alunos'));
      await esperar(tester);
      await tester.tap(find.text('Importar planilha'));
      await esperar(tester);

      // D8: a turma fica à direita da lista colada, na mesma altura.
      final lista = tester.getRect(find.byType(TextField));
      final turma = tester.getRect(find.text('Não matricular (só cadastrar)'));
      expect(turma.left, greaterThan(lista.right));
      expect(turma.top, lessThan(lista.bottom));

      await tester.enterText(find.byType(TextField), '20\tAna');
      await tester.tap(find.text('Não matricular (só cadastrar)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turma $turmaId').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conferir lista'));
      await esperar(tester);

      // D9: botões lado a lado, alinhados à direita.
      final voltar = tester.getRect(find.text('Voltar e corrigir'));
      final importar = tester.getRect(
        find.text('Importar e matricular 1 aluno'),
      );
      expect(importar.left, greaterThan(voltar.right));
      expect((importar.center.dy - voltar.center.dy).abs(), lessThan(4));
      await fecharApp(tester);
    },
  );

  testWidgets('no desktop o menu lateral fica fixo e acompanha as telas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final semantica = tester.ensureSemantics();
    await entrar(tester);
    // D1: título na página, indicadores e menu lateral no lugar do ☰.
    expect(find.text('Início · Academia Teste'), findsOneWidget);
    expect(find.text('Alunos ativos'), findsOneWidget);
    expect(find.byTooltip('Abrir menu de navegação'), findsNothing);
    expect(find.text('Turmas'), findsOneWidget);
    // O menu lateral também existe para o leitor de tela.
    expect(find.bySemanticsLabel('Turmas'), findsOneWidget);

    await tester.tap(find.text('Alunos'));
    await esperar(tester);
    expect(find.text('Ativos · 1'), findsOneWidget);

    // D3: o cadastro abre ao lado da lista, com o menu lateral visível.
    await tester.tap(find.text('Novo aluno'));
    await esperar(tester);
    expect(find.text('Código sugerido, pode editar'), findsOneWidget);
    expect(find.text('(10A) Ana'), findsOneWidget);
    expect(find.text('Turmas'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);

    // Trocar de aluno com algo digitado pergunta antes de descartar.
    await tester.enterText(find.byType(TextFormField).at(1), 'Bruno');
    await tester.tap(find.text('(10A) Ana'));
    await esperar(tester);
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await esperar(tester);
    // Na lista e no cadastro: a faixa azul com 2 graus.
    expect(find.text('Azul · 2º grau'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Faixa Azul, 2 grau')),
      findsNWidgets(2),
    );
    await fecharApp(tester);
    semantica.dispose();
  });

  testWidgets('no desktop o lançamento mostra a grade da semana', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final semantica = tester.ensureSemantics();
    await entrar(tester);
    await tester.tap(find.text('Lançar presença de hoje'));
    await esperar(tester);

    // D2: a semana inteira, uma coluna por dia de aula (qua, qui e a reposição de sábado).
    expect(find.text('Turma $turmaId · 08/11 a 14/11/2026'), findsOneWidget);
    expect(find.text('qua 11/11'), findsOneWidget);
    expect(find.text('qui 12/11'), findsOneWidget);
    expect(find.text('sáb 14/11'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));
    // Sábado ainda não chegou: bloqueado.
    expect(
      tester.widgetList<Checkbox>(find.byType(Checkbox)).last.onChanged,
      isNull,
    );
    expect(find.bySemanticsLabel(RegExp('Ana, qui 12/11')), findsOneWidget);

    // Marca a quinta: grava, envia e conta no rodapé.
    await tester.tap(find.byType(Checkbox).at(1));
    await esperar(tester);
    final marcadas = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .map((c) => c.value);
    expect(marcadas, [false, true, false]);
    expect(api.envios.expand((e) => e).length, 2); // aula + presença
    expect(find.textContaining('Tudo enviado'), findsOneWidget);

    // Semana que vem ainda não chegou; a anterior abre normalmente.
    final proxima = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Symbols.chevron_right),
    );
    expect(proxima.onPressed, isNull);
    await tester.tap(find.byTooltip('Semana anterior'));
    await esperar(tester);
    expect(find.text('Turma $turmaId · 01/11 a 07/11/2026'), findsOneWidget);
    expect(find.text('qua 04/11'), findsOneWidget);
    await fecharApp(tester);
    semantica.dispose();
  });

  /// Ana presente na aula de hoje (quinta, regular), gravada direto no aparelho.
  Future<void> marcarAnaHoje(WidgetTester tester) async {
    await tester.runAsync(
      () => dependencias.repositorio.definirPresenca(
        turmaId: turmaId,
        data: hoje,
        alunoId: alunoId,
        presente: true,
      ),
    );
  }

  testWidgets('relatório mensal no celular e impressão', (tester) async {
    await entrar(tester);
    await marcarAnaHoje(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await esperar(tester);
    await tester.tap(find.text('Relatórios'));
    await esperar(tester);
    expect(find.text('Este mês'), findsOneWidget);
    expect(find.text('01/11/2026'), findsOneWidget);
    expect(find.text('30/11/2026'), findsOneWidget);

    await tester.tap(find.text('Presença mensal'));
    await esperar(tester);
    expect(find.text('Mensal · Turma $turmaId'), findsOneWidget);
    expect(find.text('(10A) Ana'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('Imprimir / PDF'));
    await tester.pump();
    expect(impressos, hasLength(1));
    expect(impressos.single, contains('Presença mensal'));
    expect(impressos.single, contains('Academia Teste'));
    expect(impressos.single, contains('size: A4 portrait'));
    await fecharApp(tester);
  });

  testWidgets('relatórios no desktop: troca de tipo e impressão', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final semantica = tester.ensureSemantics();
    await entrar(tester);
    await marcarAnaHoje(tester);
    await tester.tap(find.text('Relatórios'));
    await esperar(tester);
    // D5: semanal do mês; só a aula de hoje foi lançada (coluna com a data) e a Ana veio.
    expect(find.text('Imprimir / PDF'), findsOneWidget);
    expect(find.text('qui 12/11'), findsOneWidget);
    expect(find.bySemanticsLabel('veio'), findsOneWidget);

    await tester.tap(find.text('Anual'));
    await esperar(tester);
    expect(find.text('JAN'), findsOneWidget);
    expect(find.text('DEZ'), findsOneWidget);

    await tester.tap(find.text('Imprimir / PDF'));
    await tester.pump();
    expect(impressos.single, contains('Presença anual'));
    expect(impressos.single, contains('size: A4 landscape'));
    await fecharApp(tester);
    semantica.dispose();
  });

  testWidgets('superadmin cadastra academia e faz a carga inicial', (
    tester,
  ) async {
    // Celular alto: a lista, o formulário e a carga inicial cabem sem rolar.
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    api.tipoUsuario = 'superadmin';
    await entrar(tester);
    // Tela 13: academias no lugar do Início.
    expect(find.text('Academias'), findsOneWidget);
    expect(find.text('Academia Teste'), findsOneWidget);
    expect(find.text('1 aluno · 1 turma · 3 usuários'), findsOneWidget);
    expect(find.text('ativa'), findsOneWidget);

    await tester.tap(find.text('Nova: nome · primeiro professor'));
    await esperar(tester);
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Equipe Nova');
    await tester.enterText(campos.at(2), 'Joana Lima');
    await tester.enterText(campos.at(3), 'Joana@Equipe.com');
    await tester.enterText(campos.at(4), 'curta');
    await tester.tap(find.text('Criar academia'));
    await esperar(tester);
    expect(find.text('Pelo menos 8 caracteres'), findsOneWidget);
    expect(api.academiasCriadas, isEmpty);

    await tester.enterText(campos.at(4), 'senhainicial');
    await tester.tap(find.text('Criar academia'));
    await esperar(tester);
    expect(api.academiasCriadas.single, {
      'nome': 'Equipe Nova',
      'professor': {
        'nome': 'Joana Lima',
        'email': 'joana@equipe.com',
        'senha': 'senhainicial',
      },
    });
    expect(find.text('Equipe Nova'), findsOneWidget);

    // Carga inicial: com duas academias, pergunta qual.
    await tester.ensureVisible(find.text('Carga inicial (planilha de alunos)'));
    await tester.tap(find.text('Carga inicial (planilha de alunos)'));
    await esperar(tester);
    await tester.tap(find.text('Equipe Nova').last);
    await esperar(tester);
    expect(find.text('Carga inicial · Equipe Nova'), findsOneWidget);
    expect(find.text('A academia ainda não tem turmas.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('professor edita os dados da academia e envia o logotipo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    api.tipoUsuario = 'professor';
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await esperar(tester);
    await tester.tap(find.text('Dados da academia'));
    await esperar(tester);
    expect(find.text('Enviar logotipo'), findsOneWidget);

    // Logotipo: gera os dois ícones e envia tudo junto; a sessão guarda o ícone.
    await tester.tap(find.text('Enviar logotipo'));
    await esperar(tester);
    expect(imagens.iconesGerados, [192, 512]);
    expect(api.logotipoEnviado!.keys, {'logotipo', 'icone_192', 'icone_512'});
    expect(
      base64Decode(api.logotipoEnviado!['logotipo'] as String),
      pngDeTeste,
    );
    expect(find.text('Trocar logotipo'), findsOneWidget);
    expect(dependencias.sessao.iconeAcademia, pngDeTeste);
    expect(dependencias.sessao.logotipoAcademia, pngDeTeste);

    // Nome curto e cabeçalho de impressão.
    await tester.enterText(find.byType(TextFormField).at(1), 'Equipe T');
    await tester.enterText(find.byType(TextFormField).at(2), 'Prof. Fulano');
    await tester.tap(find.text('Salvar'));
    await esperar(tester);
    expect(api.academiaSalva.single, {
      'nome': 'Academia Teste',
      'nome_curto': 'Equipe T',
      'cabecalho_impressao': 'Prof. Fulano',
    });

    // Remover pede confirmação.
    await tester.tap(find.text('Remover'));
    await esperar(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await esperar(tester);
    expect(find.text('Enviar logotipo'), findsOneWidget);
    expect(dependencias.sessao.iconeAcademia, isNull);
    expect(dependencias.sessao.logotipoAcademia, isNull);
    await fecharApp(tester);
  });

  testWidgets('assistente não vê Dados da academia no menu', (tester) async {
    await entrar(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await esperar(tester);
    expect(find.text('Dados da academia'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('convite de instalação no início: instalar e agora não', (
    tester,
  ) async {
    instalacao.disponivel = true;
    await entrar(tester);
    // A identidade da academia vai para o manifesto e o iPhone logo depois do login.
    expect(instalacao.identidades.last.titulo, 'Academia Teste');
    expect(instalacao.identidades.last.chave, isNotNull);

    expect(find.text('Instale o app da Academia Teste'), findsOneWidget);
    await tester.tap(find.text('Instalar'));
    await esperar(tester);
    expect(instalacao.convites, 1);

    await tester.tap(find.text('Agora não'));
    await esperar(tester);
    expect(find.text('Instale o app da Academia Teste'), findsNothing);
    expect(dependencias.sessao.conviteDispensado, isTrue);

    // Ao sair, a identidade volta ao padrão da TghServices.
    await tester.runAsync(dependencias.sessao.encerrarLocalmente);
    await esperar(tester);
    expect(instalacao.identidades.last, (
      titulo: null,
      icone: null,
      chave: null,
    ));
    await fecharApp(tester);
  });

  testWidgets('no iPhone, Instalar abre o passo a passo (tela 2b)', (
    tester,
  ) async {
    instalacao.iphone = true;
    await entrar(tester);
    await tester.tap(find.text('Instalar'));
    await esperar(tester);
    expect(find.text('Instalar no iPhone'), findsOneWidget);
    expect(find.text('1. Toque em Compartilhar'), findsOneWidget);
    expect(
      find.text('2. Escolha “Adicionar à Tela de Início”'),
      findsOneWidget,
    );
    expect(instalacao.convites, 0);
    await tester.tap(find.byTooltip('Fechar'));
    await esperar(tester);
    expect(find.text('Instale o app da Academia Teste'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('sem convite do navegador e fora do iPhone, nada de convite', (
    tester,
  ) async {
    await entrar(tester);
    expect(find.text('Instale o app da Academia Teste'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('superadmin abre a academia e redefine a senha do professor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    api.tipoUsuario = 'superadmin';
    await entrar(tester);

    // 13a: tocar na academia abre os professores dela.
    await tester.tap(find.text('Academia Teste'));
    await esperar(tester);
    expect(
      find.text('marcos@juniao.com.br · último acesso 02/11/2026'),
      findsOneWidget,
    );
    expect(find.text('carla@juniao.com.br · nunca entrou'), findsOneWidget);
    expect(find.text('rui@juniao.com.br · desativado'), findsOneWidget);
    // Professor desativado não tem o botão.
    expect(find.text('Redefinir senha'), findsNWidgets(2));

    // 13b: painel de baixo; senha curta não vai para a API.
    await tester.tap(find.text('Redefinir senha').first);
    await esperar(tester);
    expect(find.text('Redefinir a senha de Marcos Silva'), findsOneWidget);
    expect(
      find.text(
        'Marcos sai de todos os aparelhos e passa a entrar com a nova senha.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).last, 'curta');
    await tester.tap(find.widgetWithText(BotaoPrincipal, 'Redefinir senha'));
    await esperar(tester);
    expect(
      find.text('A senha precisa ter pelo menos 8 caracteres.'),
      findsOneWidget,
    );
    expect(api.senhasRedefinidas, isEmpty);

    // Gerar senha preenche e mostra uma senha fácil de ditar.
    await tester.tap(find.text('Gerar senha'));
    await tester.pump();
    final gerada = tester
        .widget<TextField>(find.byType(TextField).last)
        .controller!
        .text;
    expect(gerada, matches(RegExp(r'^[a-z]+-\d{4}$')));
    await tester.tap(find.widgetWithText(BotaoPrincipal, 'Redefinir senha'));
    await esperar(tester);
    expect(api.senhasRedefinidas.single, {
      'caminho':
          '/api/admin/academias/0190f5a0-0000-7000-8000-0000000000c1/'
          'professores/0190f5a0-0000-7000-8000-0000000000p1/senha',
      'senha': gerada,
    });

    // 13c: a senha aparece uma vez, com Copiar.
    expect(find.text('Senha redefinida'), findsOneWidget);
    expect(find.text(gerada), findsOneWidget);
    expect(
      find.text('E-mail para entrar: marcos@juniao.com.br'),
      findsOneWidget,
    );
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (chamada) async {
        if (chamada.method == 'Clipboard.setData') {
          copiado = (chamada.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.text('Copiar'));
    await esperar(tester);
    expect(copiado, gerada);
    expect(find.text('Copiada'), findsOneWidget);
    await tester.tap(find.text('Concluir'));
    await esperar(tester);
    expect(find.text('Senha redefinida'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('no desktop a academia abre ao lado e a senha num diálogo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    api.tipoUsuario = 'superadmin';
    await entrar(tester);

    expect(
      find.text('Escolha uma academia para ver os professores.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Academia Teste'));
    await esperar(tester);
    // D7a: a lista continua visível e a academia abre ao lado.
    expect(find.text('Academia Teste'), findsNWidgets(2));
    expect(find.text('Marcos Silva'), findsOneWidget);

    await tester.tap(find.text('Redefinir senha').first);
    await esperar(tester);
    // D7b: diálogo central, com Gerar senha ao lado de Cancelar.
    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'nova-senha-1');
    await tester.tap(find.widgetWithText(BotaoPrincipal, 'Redefinir senha'));
    await esperar(tester);
    expect(api.senhasRedefinidas.single['senha'], 'nova-senha-1');
    expect(find.text('nova-senha-1'), findsOneWidget);

    // Novo professor na academia aberta.
    await tester.tap(find.text('Concluir'));
    await esperar(tester);
    await tester.tap(find.text('Novo professor'));
    await esperar(tester);
    final campos = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(campos.at(0), 'Ana Nova');
    await tester.enterText(campos.at(1), 'Ana@Juniao.com.br');
    await tester.enterText(campos.at(2), 'senhainicial');
    await tester.tap(find.text('Cadastrar'));
    await esperar(tester);
    expect(api.professoresCriados.single, {
      'nome': 'Ana Nova',
      'email': 'ana@juniao.com.br',
      'senha': 'senhainicial',
    });
    await fecharApp(tester);
  });
}
