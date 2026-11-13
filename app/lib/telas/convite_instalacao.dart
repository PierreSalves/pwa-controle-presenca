// Convite para instalar o app (tela 2) e o passo a passo do iPhone (tela 2b). Só depois do login,
// quando o app já sabe a academia: o ícone e o nome instalados são os dela.
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../estado/dependencias.dart';
import 'componentes.dart';
import 'tema.dart';

/// Cartão "Instale o app da academia" com Instalar e Agora não. Some se o app já está instalado,
/// se a pessoa dispensou, ou se o aparelho não oferece instalação.
class ConviteInstalacao extends StatelessWidget {
  const ConviteInstalacao({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencias = EscopoDependencias.obter(context);
    final sessao = dependencias.sessao;
    final instalacao = dependencias.instalacao;
    return ListenableBuilder(
      listenable: Listenable.merge([sessao, instalacao.conviteDisponivel]),
      builder: (context, _) {
        final podeInstalar =
            instalacao.conviteDisponivel.value || instalacao.ehIphone;
        if (instalacao.estaInstalado ||
            sessao.conviteDispensado ||
            !podeInstalar) {
          return const SizedBox.shrink();
        }
        final academia = sessao.nomeAcademia ?? 'academia';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Symbols.install_mobile, color: CoresV2.tatame),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Instale o app da $academia',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Abre direto, funciona sem internet e fica com o ícone da academia.',
                  style: TextStyle(color: CoresV2.nevoa, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (instalacao.ehIphone) {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TelaInstalarIphone(),
                              ),
                            );
                          } else {
                            await instalacao.convidar();
                          }
                        },
                        child: const Text('Instalar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: sessao.dispensarConvite,
                        child: const Text('Agora não'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tela 2b — Instalar no iPhone: o Safari não tem botão de instalar; o passo a passo explica.
class TelaInstalarIphone extends StatelessWidget {
  const TelaInstalarIphone({super.key});

  @override
  Widget build(BuildContext context) {
    const passos = [
      (
        Symbols.ios_share,
        'Toque em Compartilhar',
        'O quadrado com a seta para cima, na barra do Safari.',
      ),
      (
        Symbols.add_box,
        'Escolha “Adicionar à Tela de Início”',
        'Role a lista para baixo se não aparecer.',
      ),
      (
        Symbols.check_circle,
        'Confirme o nome e toque em Adicionar',
        'O ícone da academia aparece na tela de início.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instalar no iPhone'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: LarguraCelular(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Cartao(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < passos.length; i++)
                    Container(
                      decoration: BoxDecoration(
                        border: i == passos.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(color: CoresV2.linha),
                              ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: CoresV2.tatameClaro,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(passos[i].$1, color: CoresV2.tatame),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${passos[i].$2}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  passos[i].$3,
                                  style: const TextStyle(
                                    color: CoresV2.nevoa,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'O iPhone não tem botão de instalar automático; por isso o passo a passo.',
              style: TextStyle(color: CoresV2.nevoa, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
