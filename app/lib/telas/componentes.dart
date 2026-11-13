// Componentes comuns às telas: status de envio, linha de aluno e largura máxima no celular.
import 'package:material_ui/material_ui.dart';

import '../dados/consulta_lancamento.dart';
import '../estado/coordenador_sincronizacao.dart';
import '../estado/dependencias.dart';
import 'formatacao.dart';

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

/// "Tudo enviado ✓" ou "N aguardando envio" (arquitetura: o status aparece sempre).
class StatusEnvio extends StatelessWidget {
  const StatusEnvio({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencias = EscopoDependencias.obter(context);
    final cores = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: dependencias.coordenador,
      builder: (context, _) => StreamBuilder<int>(
        stream: dependencias.repositorio.observarPendentes(),
        builder: (context, snapshot) {
          final pendentes = snapshot.data ?? 0;
          final offline =
              dependencias.coordenador.conexao == ConexaoSync.offline;
          final texto = pendentes == 0
              ? 'Tudo enviado ✓'
              : '$pendentes aguardando envio';
          final complemento = offline ? ' · sem internet' : '';
          return Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: pendentes == 0
                    ? cores.surfaceContainerHighest
                    : const Color(0xFFFBE7CF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$texto$complemento',
                style: TextStyle(
                  color: pendentes == 0
                      ? cores.onSurfaceVariant
                      : const Color(0xFF7A4A12),
                ),
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
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('novo', style: TextStyle(fontSize: 12)),
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
