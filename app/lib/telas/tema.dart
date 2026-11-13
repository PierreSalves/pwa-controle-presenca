// Tema da v2 (docs/telas/wireframes-v2.html): cores, fonte Lexend, botões com cor de destaque e
// contornos com contraste de 3:1. As telas usam estes tokens, nunca cores soltas.
import 'package:material_ui/material_ui.dart';

abstract final class CoresV2 {
  /// Azul do tatame: tudo que é ação (botão principal, item ativo do menu, caixa marcada).
  static const tatame = Color(0xFF13557A);
  static const tatameEscuro = Color(0xFF0E4462);

  /// Botões secundários e voltar.
  static const tatameClaro = Color(0xFFE3EEF4);
  static const tatameClaroHover = Color(0xFFD3E4EE);

  static const papel = Color(0xFFF5F6F4);
  static const cartao = Color(0xFFFFFFFF);
  static const menuLateral = Color(0xFFECEFEB);
  static const grafite = Color(0xFF23262B);
  static const nevoa = Color(0xFF5E646B);
  static const linha = Color(0xFFE1E4E0);

  /// Contorno de campos e caixas: 3:1 ou mais (WCAG 1.4.11).
  static const contorno = Color(0xFF868D94);
  static const desativado = Color(0xFF80878E);

  static const ok = Color(0xFF2E6B45);
  static const okClaro = Color(0xFFE4F1E8);
  static const aviso = Color(0xFF8A5A00);
  static const avisoClaro = Color(0xFFFBEFD5);

  /// Ponta vermelha: erro e ação que apaga ou encerra.
  static const ponta = Color(0xFFB3261E);
  static const pontaClaro = Color(0xFFFBE7E5);
}

/// Largura a partir da qual o app usa o menu lateral fixo (wireframes D1 a D3).
const larguraDesktop = 1000.0;

bool ehDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= larguraDesktop;

const _pilula = StadiumBorder();

ThemeData criarTemaV2() {
  const esquema = ColorScheme(
    brightness: Brightness.light,
    primary: CoresV2.tatame,
    onPrimary: Colors.white,
    primaryContainer: CoresV2.tatameClaro,
    onPrimaryContainer: CoresV2.tatame,
    secondary: CoresV2.tatame,
    onSecondary: Colors.white,
    secondaryContainer: CoresV2.tatameClaro,
    onSecondaryContainer: CoresV2.tatame,
    error: CoresV2.ponta,
    onError: Colors.white,
    errorContainer: CoresV2.pontaClaro,
    onErrorContainer: CoresV2.ponta,
    surface: CoresV2.papel,
    onSurface: CoresV2.grafite,
    onSurfaceVariant: CoresV2.nevoa,
    surfaceContainerLowest: CoresV2.cartao,
    surfaceContainerLow: CoresV2.cartao,
    surfaceContainer: CoresV2.menuLateral,
    surfaceContainerHigh: CoresV2.menuLateral,
    surfaceContainerHighest: CoresV2.linha,
    outline: CoresV2.contorno,
    outlineVariant: CoresV2.linha,
  );
  // A fonte vai explícita: o estilo dos botões não herda a do tema, e sem ela o Flutter usaria a
  // Roboto, que não está no app (o texto sumiria, sem internet nem acesso ao Google).
  const textoBotao = TextStyle(
    fontFamily: 'Lexend',
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );
  const tamanhoMinimo = Size(48, 48);
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    fontFamily: 'Lexend',
    scaffoldBackgroundColor: CoresV2.papel,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    focusColor: CoresV2.tatame.withValues(alpha: 0.24),
    // Ícones de traço fino (Material Symbols, espessura 300).
    iconTheme: const IconThemeData(weight: 300, size: 22),
    appBarTheme: const AppBarTheme(
      backgroundColor: CoresV2.papel,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      // Botões da barra longe da borda.
      actionsPadding: EdgeInsets.symmetric(horizontal: 8),
      titleTextStyle: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: CoresV2.grafite,
      ),
    ),
    // Principal: pílula azul.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: _pilula,
        minimumSize: tamanhoMinimo,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: textoBotao,
      ),
    ),
    // Secundário: azul-claro, sem contorno (todo botão de ação tem cor de destaque).
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: _pilula,
        minimumSize: tamanhoMinimo,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: CoresV2.tatameClaro,
        foregroundColor: CoresV2.tatame,
        disabledBackgroundColor: CoresV2.linha,
        side: BorderSide.none,
        textStyle: textoBotao,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: _pilula,
        minimumSize: tamanhoMinimo,
        foregroundColor: CoresV2.tatame,
        textStyle: textoBotao,
      ),
    ),
    // Botões só com ícone (voltar, calendário, fechar): círculo azul-claro de 48 px.
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: CoresV2.tatameClaro,
        foregroundColor: CoresV2.tatame,
        minimumSize: tamanhoMinimo,
        shape: const CircleBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoresV2.cartao,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CoresV2.contorno, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CoresV2.contorno, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CoresV2.tatame, width: 2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      side: const BorderSide(color: CoresV2.contorno, width: 2),
    ),
    dividerTheme: const DividerThemeData(color: CoresV2.linha),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Sombra suave dos cartões (no lugar da borda cinza de 1 px).
const sombraCartao = [
  BoxShadow(color: Color(0x0F23262B), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(
    color: Color(0x2E23262B),
    blurRadius: 24,
    spreadRadius: -12,
    offset: Offset(0, 8),
  ),
];

/// Algarismos de largura fixa (indicadores, percentuais, códigos).
const numerosFixos = [FontFeature.tabularFigures()];
