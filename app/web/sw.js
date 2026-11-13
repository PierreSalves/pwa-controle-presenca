// Service worker do app (docs/arquitetura/README.md, "Abrir sem internet").
// - Só cuida dos arquivos do app (mesmo domínio). A API (/api/) nunca passa pelo cache: os dados
//   offline ficam no banco local (drift), não aqui.
// - Rede primeiro, para pegar sempre a versão publicada; sem resposta a tempo, usa a cópia guardada.
// - Na primeira visita o service worker ainda não controla a página, então a própria página manda
//   a lista do que carregou (flutter_bootstrap.js) e ele guarda esses arquivos.
'use strict';

const CACHE = 'controle-presenca-app-v2';
const ESPERA_REDE_MS = 4000;
const ESSENCIAIS = ['./', 'index.html', 'flutter_bootstrap.js', 'instalacao.js', 'favicon.png'];

function ehDoApp(url) {
  return url.origin === self.location.origin && !url.pathname.startsWith('/api/');
}

self.addEventListener('install', (evento) => {
  evento.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => Promise.allSettled(ESSENCIAIS.map((u) => cache.add(u))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (evento) => {
  evento.waitUntil(
    (async () => {
      for (const nome of await caches.keys()) {
        if (nome !== CACHE) await caches.delete(nome);
      }
      await self.clients.claim();
    })(),
  );
});

// A página manda { tipo: 'guardar', urls: [...] } com os arquivos que já carregou.
self.addEventListener('message', (evento) => {
  const dados = evento.data;
  if (!dados || dados.tipo !== 'guardar' || !Array.isArray(dados.urls)) return;
  evento.waitUntil(
    caches.open(CACHE).then((cache) =>
      Promise.allSettled(
        dados.urls
          .map((u) => new URL(u, self.location.href))
          .filter(ehDoApp)
          .map(async (url) => {
            if (await cache.match(url)) return;
            await cache.add(url);
          }),
      ),
    ),
  );
});

async function buscarComCache(requisicao) {
  const cache = await caches.open(CACHE);
  // Navegação (abrir o app ou recarregar): qualquer rota do app é o index.html.
  const chave = requisicao.mode === 'navigate' ? './' : requisicao;
  const guardada = await cache.match(chave, { ignoreSearch: requisicao.mode === 'navigate' });

  const daRede = fetch(requisicao).then((resposta) => {
    if (resposta.ok && resposta.type === 'basic') {
      cache.put(chave, resposta.clone()).catch(() => {});
    }
    return resposta;
  });

  if (!guardada) return daRede;
  // Com cópia guardada: espera a rede só um pouco (internet ruim na academia).
  const espera = new Promise((resolver) => setTimeout(() => resolver(guardada), ESPERA_REDE_MS));
  return Promise.race([daRede.catch(() => guardada), espera]);
}

self.addEventListener('fetch', (evento) => {
  const requisicao = evento.request;
  if (requisicao.method !== 'GET') return;
  if (!ehDoApp(new URL(requisicao.url))) return;
  evento.respondWith(buscarComCache(requisicao));
});
