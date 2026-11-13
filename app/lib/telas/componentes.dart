// Componentes comuns às telas: botões da v2, cartão, status de envio, linha de aluno e largura do
// conteúdo (celular ou ao lado do menu lateral no desktop).
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../dados/consulta_lancamento.dart';
import '../estado/coordenador_sincronizacao.dart';
import '../estado/dependencias.dart';
import 'formatacao.dart';
import 'tema.dart';

/// Cores dos wireframes aprovados (docs/telas/wireframes-fase1.html).
abstract final class CoresWireframe {
  static const okFundo = CoresV2.okClaro;
  static const okTexto = CoresV2.ok;
  static const avisoFundo = CoresV2.avisoClaro;
  static const avisoTexto = CoresV2.aviso;
  static const etiquetaFundo = CoresV2.tatameClaro;
  static const etiquetaTexto = CoresV2.tatame;
  static const perigo = CoresV2.ponta;
}

/// Botão principal da v2: pílula azul com o ícone num círculo. Mostra "Salvando…" (ou o texto de
/// [rotuloCarregando]) enquanto [carregando]; continua habilitado até a ação começar.
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.aoTocar,
    this.carregando = false,
    this.rotuloCarregando = 'Salvando…',
    this.largo = false,
  });

  final String rotulo;
  final IconData icone;
  final VoidCallback? aoTocar;
  final bool carregando;
  final String rotuloCarregando;

  /// Ocupa a largura toda (rótulo à esquerda, ícone à direita).
  final bool largo;

  @override
  Widget build(BuildContext context) {
    final circulo = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: carregando
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icone, size: 18, color: Colors.white),
    );
    return Semantics(
      label: carregando ? rotuloCarregando : null,
      child: _Pressionavel(
        ativo: aoTocar != null && !carregando,
        child: FilledButton(
          onPressed: carregando ? null : aoTocar,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
            disabledBackgroundColor: carregando ? CoresV2.tatame : null,
            disabledForegroundColor: carregando ? Colors.white : null,
          ),
          child: Row(
            mainAxisSize: largo ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: largo
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  carregando ? rotuloCarregando : rotulo,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              circulo,
            ],
          ),
        ),
      ),
    );
  }
}

/// Ao apertar, encolhe 2% com curva de mola (v2). Sem efeito quando o aparelho pede menos movimento.
class _Pressionavel extends StatefulWidget {
  const _Pressionavel({required this.ativo, required this.child});
  final bool ativo;
  final Widget child;

  @override
  State<_Pressionavel> createState() => _PressionavelState();
}

class _PressionavelState extends State<_Pressionavel> {
  bool _apertado = false;

  void _definir(bool apertado) {
    if (widget.ativo && apertado != _apertado) {
      setState(() => _apertado = apertado);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _definir(true),
      onPointerUp: (_) => _definir(false),
      onPointerCancel: (_) => _definir(false),
      child: AnimatedScale(
        scale: _apertado ? 0.98 : 1,
        duration: const Duration(milliseconds: 300),
        curve: const Cubic(0.32, 0.72, 0, 1),
        child: widget.child,
      ),
    );
  }
}

/// Cores reais das faixas (a única cor "chamativa" da v2; nunca usada como enfeite).
const _coresFaixa = {
  'branca': Color(0xFFF4F4F2),
  'cinza': Color(0xFF8C8C8C),
  'amarela': Color(0xFFE8C33A),
  'laranja': Color(0xFFE07A2E),
  'verde': Color(0xFF3C8C4A),
  'azul': Color(0xFF2456A6),
  'roxa': Color(0xFF6A3D9A),
  'marrom': Color(0xFF6B4226),
  'preta': Color(0xFF1E1E1E),
};

/// A faixa do aluno: a cor da faixa e os graus como listras brancas na ponta preta.
class FaixaDoAluno extends StatelessWidget {
  const FaixaDoAluno({
    super.key,
    required this.faixa,
    required this.grau,
    this.largura = 96,
  });

  final String faixa;
  final int grau;
  final double largura;

  @override
  Widget build(BuildContext context) {
    final cor = _coresFaixa[faixa.toLowerCase()] ?? CoresV2.contorno;
    final listras = grau.clamp(0, 6);
    return Semantics(
      label: grau == 0 ? 'Faixa $faixa' : 'Faixa $faixa, $grau grau',
      excludeSemantics: true,
      child: Container(
        width: largura,
        height: 16,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0x1F000000)),
        ),
        child: Row(
          children: [
            Expanded(child: Container(color: cor)),
            Container(
              width: largura * 0.36,
              color: const Color(0xFF1E1E1E),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < listras; i++)
                    Container(
                      width: 3,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estilo de botão para ação que apaga ou encerra (vermelho-claro).
final estiloDestrutivo = OutlinedButton.styleFrom(
  backgroundColor: CoresV2.pontaClaro,
  foregroundColor: CoresV2.ponta,
);

/// Estilo do botão de confirmar uma ação destrutiva num diálogo.
final estiloConfirmarDestrutivo = FilledButton.styleFrom(
  backgroundColor: CoresV2.ponta,
);

/// Cartão da v2: fundo branco com sombra suave (sem borda cinza).
class Cartao extends StatelessWidget {
  const Cartao({super.key, required this.child, this.aoTocar, this.padding});

  final Widget child;
  final VoidCallback? aoTocar;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: CoresV2.cartao,
      borderRadius: BorderRadius.circular(16),
      boxShadow: sombraCartao,
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: child,
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) {
    // No desktop o conteúdo fica ao lado do menu lateral, mais largo e alinhado à esquerda.
    final desktop = ehDesktop(context);
    return Align(
      alignment: desktop ? Alignment.topLeft : Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktop ? 880 : 560),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: desktop ? 12 : 0),
          child: child,
        ),
      ),
    );
  }
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
                    Icon(Symbols.check, size: 14, color: cor),
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
/// Copyright discreto da TghServices no fim da tela de entrar, do menu e do Início: a marca do
/// sistema fica em segundo plano; quem aparece é a academia.
class RodapeCopyright extends StatelessWidget {
  const RodapeCopyright({super.key});

  @override
  Widget build(BuildContext context) {
    final ano = EscopoDependencias.obter(context).relogio().year;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '© $ano TghServices',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: CoresV2.nevoa,
          fontSize: 12,
          fontFeatures: numerosFixos,
        ),
      ),
    );
  }
}

class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(semanticsLabel: 'Carregando…'),
  );
}

/// Ao voltar com alterações não salvas, pergunta antes de descartar (formulários online).
/// Pergunta se descarta o que foi mudado e não salvo; true para descartar.
Future<bool> confirmarDescarte(BuildContext context) async =>
    await showDialog<bool>(
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
            style: estiloConfirmarDestrutivo,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    ) ==
    true;

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
    if (!temAlteracoes() || await confirmarDescarte(context)) navegador.pop();
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
