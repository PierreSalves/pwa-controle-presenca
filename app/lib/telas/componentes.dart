// Componentes comuns às telas: status de envio, linha de aluno e largura máxima no celular.
import 'package:material_ui/material_ui.dart';

import '../dados/consulta_lancamento.dart';
import '../estado/coordenador_sincronizacao.dart';
import '../estado/dependencias.dart';
import 'formatacao.dart';

/// Cores dos wireframes aprovados (docs/telas/wireframes-fase1.html).
abstract final class CoresWireframe {
  static const okFundo = Color(0xFFEAF3DE);
  static const okTexto = Color(0xFF3B6D11);
  static const avisoFundo = Color(0xFFFAEEDA);
  static const avisoTexto = Color(0xFF854F0B);
  static const etiquetaFundo = Color(0xFFE6F1FB);
  static const etiquetaTexto = Color(0xFF0C447C);
  static const perigo = Color(0xFFA32D2D);
}

/// Etiqueta pequena azul ("novo", "repos.", "avulsa").
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: CoresWireframe.etiquetaFundo,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 11, color: CoresWireframe.etiquetaTexto),
    ),
  );
}

/// Conteúdo centralizado com largura de celular (o desktop terá layout próprio, tela D2).
class LarguraCelular extends StatelessWidget {
  const LarguraCelular({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: child,
    ),
  );
}

/// "✓ Tudo enviado · 14:32" ou "N aguardando envio" (arquitetura: o status aparece sempre).
/// O ✓ é um ícone: o caractere não existe na Roboto e faria o Flutter baixar outra fonte.
class StatusEnvio extends StatelessWidget {
  const StatusEnvio({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencias = EscopoDependencias.obter(context);
    return ListenableBuilder(
      listenable: dependencias.coordenador,
      builder: (context, _) => StreamBuilder<int>(
        stream: dependencias.repositorio.observarPendentes(),
        builder: (context, snapshot) {
          final pendentes = snapshot.data ?? 0;
          final offline =
              dependencias.coordenador.conexao == ConexaoSync.offline;
          final ultima = dependencias.coordenador.ultimaSincronizacao;
          final texto = pendentes > 0
              ? '$pendentes aguardando envio'
              : ultima == null
              ? 'Tudo enviado'
              : 'Tudo enviado · ${formatarHora(ultima)}';
          final cor = pendentes == 0
              ? CoresWireframe.okTexto
              : CoresWireframe.avisoTexto;
          final complemento = offline ? ' · sem internet' : '';
          return Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: pendentes == 0
                    ? CoresWireframe.okFundo
                    : CoresWireframe.avisoFundo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pendentes == 0) ...[
                    Icon(Icons.check, size: 14, color: cor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '$texto$complemento',
                    style: TextStyle(fontSize: 13, color: cor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Linha do aluno com a caixa de presença.
class LinhaAluno extends StatelessWidget {
  const LinhaAluno({
    super.key,
    required this.aluno,
    required this.aoMarcar,
    this.mostrarFrequencia = false,
  });

  final AlunoNoLancamento aluno;
  final ValueChanged<bool> aoMarcar;
  final bool mostrarFrequencia;

  String _descreverFrequencia() {
    final ultima = aluno.frequencia.ultimaPresenca;
    final quando = ultima == null
        ? 'nunca veio'
        : 'última vez ${formatarDiaMes(ultima)}';
    return '${aluno.frequencia.percentual}% · $quando';
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return CheckboxListTile(
      value: aluno.presente,
      onChanged: (valor) => aoMarcar(valor ?? false),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: formatarAluno(aluno.codigo, aluno.nome)),
            if (aluno.frequencia.novo)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Etiqueta('novo'),
                ),
              ),
            if (mostrarFrequencia)
              TextSpan(
                text: ' · ${_descreverFrequencia()}',
                style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de carregamento com rótulo para o leitor de tela.
class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(semanticsLabel: 'Carregando…'),
  );
}

/// Ao voltar com alterações não salvas, pergunta antes de descartar (formulários online).
class ProtecaoAlteracoes extends StatelessWidget {
  const ProtecaoAlteracoes({
    super.key,
    required this.temAlteracoes,
    required this.child,
  });

  /// Consultada na hora de voltar (os campos mudam sem redesenhar a tela).
  final bool Function() temAlteracoes;
  final Widget child;

  Future<void> _confirmarSaida(BuildContext context) async {
    final navegador = Navigator.of(context);
    if (!temAlteracoes()) {
      navegador.pop();
      return;
    }
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('O que você mudou nesta tela ainda não foi salvo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true) navegador.pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (saiu, _) {
      if (!saiu) _confirmarSaida(context);
    },
    child: child,
  );
}
