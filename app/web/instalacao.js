// Convite de instalação do app (tela 2): o navegador (Android, Chrome/Edge no computador) avisa que
// o app pode ser instalado com o evento beforeinstallprompt. O evento é guardado aqui para o app
// mostrar o convite no Início, depois do login, e chamar prompt() quando a pessoa tocar em Instalar.
'use strict';

window.conviteInstalacao = null;
window.appInstalado = false;

window.addEventListener('beforeinstallprompt', (evento) => {
  evento.preventDefault();
  window.conviteInstalacao = evento;
});

window.addEventListener('appinstalled', () => {
  window.conviteInstalacao = null;
  window.appInstalado = true;
});
