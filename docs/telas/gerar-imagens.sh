#!/usr/bin/env bash
# Gera docs/telas/img/*.png a partir de wireframes-fase1.html usando o Edge (ou Chrome) em modo headless.
# Uso (Git Bash): bash docs/telas/gerar-imagens.sh [tela ...]
#   sem argumentos gera todas; ex.: bash docs/telas/gerar-imagens.sh 2 14 d2
set -euo pipefail

PASTA="$(cd "$(dirname "$0")" && pwd -W 2>/dev/null || pwd)"
NAVEGADOR="${CHROME_EXECUTABLE:-/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe}"
URL="file:///${PASTA//\\//}/wireframes-fase1.html"
PERFIS="$(mktemp -d)"

CELULAR=(1 2 2b 3 4 4b 5 6 7 8 8b 8c 9 10 11 12 13 14)
DESKTOP=(d1 d2 d3 d4)
TELAS=("$@")
[ ${#TELAS[@]} -eq 0 ] && TELAS=("${CELULAR[@]}" "${DESKTOP[@]}")

for tela in "${TELAS[@]}"; do
  if [[ "$tela" == d* ]]; then tamanho="1112,520"; arquivo="desktop-0${tela#d}.png"
  else tamanho="392,900"; arquivo="celular-${tela}.png"; fi
  # um perfil novo por captura: reaproveitar o perfil faz o navegador sair sem gerar a imagem.
  # --inprivate e --disable-sync: o Edge não entra sozinho na conta Microsoft do Windows no perfil novo.
  timeout 60 "$NAVEGADOR" --headless=new --inprivate --disable-sync --disable-gpu --hide-scrollbars --no-first-run \
    --disable-features=msImplicitSignin \
    --user-data-dir="$PERFIS/$tela" --virtual-time-budget=5000 --window-size="$tamanho" \
    --screenshot="$PASTA/img/$arquivo" "$URL?tela=$tela" >/dev/null 2>&1 || true
  [ -s "$PASTA/img/$arquivo" ] && echo "ok  $arquivo" || echo "ERRO $arquivo"
done
rm -rf "$PERFIS"
