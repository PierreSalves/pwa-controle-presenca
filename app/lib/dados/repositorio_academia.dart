// Dados da academia (tela 14, só o professor): online, direto na API. O logotipo vai junto com os
// ícones 192 e 512 px gerados no app (ServicoImagens).
import 'dart:convert';
import 'dart:typed_data';

import 'cliente_api.dart';

class DadosAcademia {
  const DadosAcademia({
    required this.nome,
    required this.nomeCurto,
    required this.cabecalhoImpressao,
    required this.temLogotipo,
    required this.logotipoVersao,
  });

  factory DadosAcademia.lerJson(Map<String, dynamic> json) => DadosAcademia(
    nome: json['nome'] as String,
    nomeCurto: json['nome_curto'] as String?,
    cabecalhoImpressao: json['cabecalho_impressao'] as String?,
    temLogotipo: json['tem_logotipo'] == 1 || json['tem_logotipo'] == true,
    logotipoVersao: json['logotipo_versao'] as String?,
  );

  final String nome;
  final String? nomeCurto;
  final String? cabecalhoImpressao;
  final bool temLogotipo;
  final String? logotipoVersao;
}

class RepositorioAcademia {
  RepositorioAcademia(this._cliente);
  final ClienteApi _cliente;

  DadosAcademia _ler(Map<String, dynamic> resposta) =>
      DadosAcademia.lerJson(resposta['academia'] as Map<String, dynamic>);

  Future<DadosAcademia> buscarAcademia() async =>
      _ler(await _cliente.enviar('GET', 'academia'));

  /// Nome curto com mais de 15 caracteres: `dados_invalidos`.
  Future<DadosAcademia> salvarAcademia({
    required String nome,
    required String nomeCurto,
    required String cabecalhoImpressao,
  }) async {
    String? opcional(String texto) =>
        texto.trim().isEmpty ? null : texto.trim();
    return _ler(
      await _cliente.enviar(
        'PUT',
        'academia',
        corpo: {
          'nome': nome.trim(),
          'nome_curto': opcional(nomeCurto),
          'cabecalho_impressao': opcional(cabecalhoImpressao),
        },
      ),
    );
  }

  /// Imagem que não é PNG/JPG ou ícone de tamanho errado: `imagem_invalida`; acima de 1 MB:
  /// `logotipo_grande_demais`.
  Future<DadosAcademia> enviarLogotipo({
    required Uint8List logotipo,
    required Uint8List icone192,
    required Uint8List icone512,
  }) async => _ler(
    await _cliente.enviar(
      'PUT',
      'academia/logotipo',
      corpo: {
        'logotipo': base64Encode(logotipo),
        'icone_192': base64Encode(icone192),
        'icone_512': base64Encode(icone512),
      },
    ),
  );

  Future<DadosAcademia> removerLogotipo() async =>
      _ler(await _cliente.enviar('DELETE', 'academia/logotipo'));
}
