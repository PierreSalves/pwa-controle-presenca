import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { calcularNomeCurto } from '../src/rotas/manifesto';
import { assinarAcademia, validarAcademia } from '../src/seguranca/cookie_manifesto';
import { converterBytesEmBase64 } from '../src/util/codificacao';
import { comToken, criarTenant, criarUsuario, entrar, requisitar } from './apoio';

interface Manifesto {
  name: string;
  short_name: string;
  start_url: string;
  icons: { src: string; purpose?: string }[];
}

/** Cookie do manifesto que veio no login (ou vazio). */
function obterCookieManifesto(resposta: Response): string {
  const cookie = resposta.headers.getSetCookie().find((c) => c.startsWith('cp_manifesto='));
  return cookie?.split(';')[0] ?? '';
}

async function buscarManifesto(cookie?: string): Promise<Manifesto> {
  const resposta = await requisitar('/api/manifesto', { headers: cookie ? { Cookie: cookie } : {} });
  expect(resposta.status).toBe(200);
  expect(resposta.headers.get('content-type')).toContain('application/manifest+json');
  return resposta.json<Manifesto>();
}

function montarPng(tamanho: number): Uint8Array {
  const bytes = new Uint8Array(33);
  bytes.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52]);
  const visao = new DataView(bytes.buffer);
  visao.setUint32(16, tamanho);
  visao.setUint32(20, tamanho);
  return bytes;
}

describe('manifesto do app instalável', () => {
  it('assinatura do cookie: confere a academia e recusa valor trocado', async () => {
    const valor = await assinarAcademia('tenant-a', env.JWT_SEGREDO);
    expect(await validarAcademia(valor, env.JWT_SEGREDO)).toBe('tenant-a');
    const trocado = valor.replace('tenant-a', 'tenant-b');
    expect(await validarAcademia(trocado, env.JWT_SEGREDO)).toBeNull();
    expect(await validarAcademia('tenant-a', env.JWT_SEGREDO)).toBeNull();
    expect(await validarAcademia(valor, 'outro-segredo')).toBeNull();
  });

  it('nome curto automático: palavras inteiras até 12 letras', () => {
    const calcular = (nome: string, nome_curto: string | null = null) =>
      calcularNomeCurto({ nome, nome_curto });
    expect(calcular('Academia Teste')).toBe('Academia');
    expect(calcular('Academia do Junião Jiu-Jítsu')).toBe('Academia do');
    expect(calcular('Gracie Barra')).toBe('Gracie Barra');
    expect(calcular('Superacademiadejiujitsu')).toBe('Superacademi');
    expect(calcular('Academia Teste', 'Junião')).toBe('Junião');
  });

  it('sem login, o manifesto da TghServices', async () => {
    const manifesto = await buscarManifesto();
    expect(manifesto.name).toBe('Controle de presença');
    expect(manifesto.short_name).toBe('Presença');
    expect(manifesto.start_url).toBe('/');
    expect(manifesto.icons[0]?.src).toBe('/icons/Icon-192.png');
  });

  it('depois do login, o nome e os ícones da academia; sair apaga o cookie', async () => {
    const tenantId = await criarTenant('Academia do Junião Jiu-Jítsu');
    const professor = await criarUsuario({ tenantId, tipo: 'professor' });
    const login = await entrar(professor.email, professor.senha);
    const cookie = obterCookieManifesto(login.resposta);
    expect(cookie).not.toBe('');
    const atributos = login.resposta.headers.getSetCookie().find((c) => c.startsWith('cp_manifesto='));
    expect(atributos).toContain('Path=/api/manifesto');
    expect(atributos).toContain('HttpOnly');
    expect(atributos).toContain('SameSite=Strict');

    // Sem nome curto e sem logotipo: começo do nome e ícones padrão.
    let manifesto = await buscarManifesto(cookie);
    expect(manifesto.name).toBe('Academia do Junião Jiu-Jítsu');
    expect(manifesto.short_name).toBe('Academia do');
    expect(manifesto.icons[0]?.src).toBe('/icons/Icon-192.png');

    // Com nome curto e logotipo: os ícones da academia, com a versão no endereço.
    await requisitar(
      '/api/academia',
      comToken(login.tokenAcesso, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nome: 'Academia do Junião Jiu-Jítsu', nome_curto: 'Junião' }),
      }),
    ).then((r) => r.arrayBuffer());
    const envio = await requisitar(
      '/api/academia/logotipo',
      comToken(login.tokenAcesso, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          logotipo: converterBytesEmBase64(montarPng(800)),
          icone_192: converterBytesEmBase64(montarPng(192)),
          icone_512: converterBytesEmBase64(montarPng(512)),
        }),
      }),
    );
    const { academia } = await envio.json<{ academia: { logotipo_versao: string } }>();
    manifesto = await buscarManifesto(cookie);
    expect(manifesto.short_name).toBe('Junião');
    expect(manifesto.icons.map((i) => i.src)).toEqual([
      `/api/manifesto/icone/192?v=${academia.logotipo_versao}`,
      `/api/manifesto/icone/512?v=${academia.logotipo_versao}`,
    ]);
    expect(manifesto.icons[0]?.purpose).toBe('any maskable');
    const icone = await requisitar('/api/manifesto/icone/512', { headers: { Cookie: cookie } });
    expect(icone.status).toBe(200);
    expect(icone.headers.get('content-type')).toBe('image/png');
    expect((await icone.arrayBuffer()).byteLength).toBe(33);
    const semCookie = await requisitar('/api/manifesto/icone/512');
    expect(semCookie.status).toBe(404);
    await semCookie.arrayBuffer();

    // Sair apaga o cookie do manifesto.
    const saida = await requisitar('/api/autenticacao/sair', {
      method: 'POST',
      headers: { Cookie: login.cookieRenovacao },
    });
    expect(saida.headers.getSetCookie().find((c) => c.startsWith('cp_manifesto='))).toContain('Max-Age=0');
  });

  it('academia desativada e superadmin ficam com o manifesto padrão', async () => {
    const tenantId = await criarTenant('Academia Fechada');
    const professor = await criarUsuario({ tenantId, tipo: 'professor' });
    const cookie = obterCookieManifesto((await entrar(professor.email, professor.senha)).resposta);
    await env.DB.prepare('UPDATE tenants SET ativo = 0 WHERE id = ?1').bind(tenantId).run();
    expect((await buscarManifesto(cookie)).name).toBe('Controle de presença');

    const admin = await criarUsuario({ tenantId: null, tipo: 'superadmin' });
    const login = await entrar(admin.email, admin.senha);
    expect(obterCookieManifesto(login.resposta)).toBe('cp_manifesto=');
  });
});
