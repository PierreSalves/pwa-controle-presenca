// Inicialização do app (modelo do Flutter: o build troca os marcadores {{...}}).
// - CanvasKit servido pelo próprio app (canvaskit/), não pelo gstatic.com: funciona offline e
//   respeita a CSP sem terceiros.
// - Service worker próprio (sw.js) no lugar do service worker do Flutter, que foi descontinuado.
{{flutter_js}}
{{flutter_build_config}}

/** Manda ao service worker a lista do que a página já carregou, para abrir offline depois. */
function guardarArquivosCarregados(registro) {
  const ativo = registro.active;
  if (!ativo) return;
  const urls = performance
    .getEntriesByType('resource')
    .map((entrada) => entrada.name)
    .filter((url) => url.startsWith(location.origin) && !url.includes('/api/'));
  ativo.postMessage({ tipo: 'guardar', urls: [location.href, ...urls] });
}

if ('serviceWorker' in navigator) {
  navigator.serviceWorker
    .register('sw.js')
    .then(() => navigator.serviceWorker.ready)
    .then((registro) => {
      // O Flutter termina de carregar o motor e as fontes depois do load; manda duas vezes.
      setTimeout(() => guardarArquivosCarregados(registro), 3000);
      setTimeout(() => guardarArquivosCarregados(registro), 15000);
    })
    .catch((erro) => console.warn('Service worker não registrado:', erro));
}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});
