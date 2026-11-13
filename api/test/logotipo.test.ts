import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { detectarTipoImagem, ehIconeValido, lerDimensoesPng } from '../src/regras/imagens';
import { converterBytesEmBase64 } from '../src/util/codificacao';
import { comToken, criarTenant, criarUsuario, entrar, requisitar } from './apoio';

/** Cabeçalho de um PNG com a largura e a altura dadas (o bastante para a conferência da API). */
function montarPng(largura: number, altura: number, extra = 0): Uint8Array {
  const bytes = new Uint8Array(33 + extra);
  bytes.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52]);
  const visao = new DataView(bytes.buffer);
  visao.setUint32(16, largura);
  visao.setUint32(20, altura);
  return bytes;
}

const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 16, 0x4a, 0x46, 0x49, 0x46]);
const base64 = (bytes: Uint8Array) => converterBytesEmBase64(bytes);

function chamar(token: string, metodo: string, caminho: string, corpo?: unknown) {
  return requisitar(
    caminho,
    comToken(token, {
      method: metodo,
      headers: { 'Content-Type': 'application/json' },
      body: corpo === undefined ? undefined : JSON.stringify(corpo),
    }),
  );
}

async function montarAcademia() {
  const tenantId = await criarTenant('Academia Logo');
  const professor = await criarUsuario({ tenantId, tipo: 'professor' });
  const assistente = await criarUsuario({ tenantId, tipo: 'assistente' });
  return {
    tenantId,
    professor: (await entrar(professor.email, professor.senha)).tokenAcesso,
    assistente: (await entrar(assistente.email, assistente.senha)).tokenAcesso,
  };
}

const corpoValido = () => ({
  logotipo: base64(JPEG),
  icone_192: base64(montarPng(192, 192)),
  icone_512: base64(montarPng(512, 512)),
});

describe('logotipo: regras das imagens', () => {
  it('reconhece PNG e JPEG pelos bytes e lê o tamanho do PNG', () => {
    expect(detectarTipoImagem(montarPng(10, 10))).toBe('png');
    expect(detectarTipoImagem(JPEG)).toBe('jpeg');
    expect(detectarTipoImagem(new TextEncoder().encode('<svg></svg>'))).toBeNull();
    expect(lerDimensoesPng(montarPng(192, 96))).toEqual({ largura: 192, altura: 96 });
    expect(ehIconeValido(montarPng(512, 512), 512)).toBe(true);
    expect(ehIconeValido(montarPng(512, 511), 512)).toBe(false);
  });
});

describe('logotipo: envio, leitura e remoção', () => {
  it('professor envia; qualquer usuário da academia lê; trocar apaga os arquivos antigos', async () => {
    const a = await montarAcademia();
    let resposta = await chamar(a.professor, 'PUT', '/api/academia/logotipo', corpoValido());
    expect(resposta.status).toBe(200);
    const { academia } = await resposta.json<{
      academia: { tem_logotipo: number; logotipo_versao: string };
    }>();
    expect(academia.tem_logotipo).toBe(1);
    expect(academia.logotipo_versao).toBeTruthy();

    // A assistente vê a versão no /eu e baixa o ícone.
    const eu = await (
      await chamar(a.assistente, 'GET', '/api/eu')
    ).json<{
      tenant: { logotipo_versao: string };
    }>();
    expect(eu.tenant.logotipo_versao).toBe(academia.logotipo_versao);
    resposta = await chamar(a.assistente, 'GET', '/api/eu/logotipo/512');
    expect(resposta.status).toBe(200);
    expect(resposta.headers.get('content-type')).toBe('image/png');
    expect(lerDimensoesPng(new Uint8Array(await resposta.arrayBuffer()))).toEqual({
      largura: 512,
      altura: 512,
    });
    resposta = await chamar(a.assistente, 'GET', '/api/eu/logotipo/original');
    expect(resposta.headers.get('content-type')).toBe('image/jpeg');
    await resposta.arrayBuffer();

    // Trocar o logotipo: versão nova, e os arquivos da anterior somem do R2.
    const antes = await env.ARQUIVOS.list({ prefix: `academias/${a.tenantId}/` });
    expect(antes.objects).toHaveLength(3);
    resposta = await chamar(a.professor, 'PUT', '/api/academia/logotipo', corpoValido());
    const trocada = await resposta.json<{ academia: { logotipo_versao: string } }>();
    expect(trocada.academia.logotipo_versao).not.toBe(academia.logotipo_versao);
    const depois = await env.ARQUIVOS.list({ prefix: `academias/${a.tenantId}/` });
    expect(depois.objects).toHaveLength(3);
    expect(depois.objects.every((o) => o.key.includes(trocada.academia.logotipo_versao))).toBe(true);

    // Remover: sem logotipo, sem arquivos.
    resposta = await chamar(a.professor, 'DELETE', '/api/academia/logotipo');
    expect((await resposta.json<{ academia: { tem_logotipo: number } }>()).academia.tem_logotipo).toBe(0);
    expect((await env.ARQUIVOS.list({ prefix: `academias/${a.tenantId}/` })).objects).toHaveLength(0);
    resposta = await chamar(a.assistente, 'GET', '/api/eu/logotipo/512');
    expect(resposta.status).toBe(404);
    await resposta.arrayBuffer();
  });

  it('recusa imagem que não é PNG ou JPG, ícone do tamanho errado e arquivo grande demais', async () => {
    const a = await montarAcademia();
    const enviar = (corpo: object) => chamar(a.professor, 'PUT', '/api/academia/logotipo', corpo);
    let resposta = await enviar({ ...corpoValido(), logotipo: base64(new TextEncoder().encode('<svg/>')) });
    expect(resposta.status).toBe(400);
    expect(await resposta.json()).toEqual({ erro: 'imagem_invalida' });
    resposta = await enviar({ ...corpoValido(), icone_192: base64(montarPng(200, 200)) });
    expect(resposta.status).toBe(400);
    await resposta.arrayBuffer();
    resposta = await enviar({ ...corpoValido(), logotipo: base64(montarPng(800, 800, 1024 * 1024)) });
    expect(resposta.status).toBe(413);
    expect(await resposta.json()).toEqual({ erro: 'logotipo_grande_demais' });
    expect((await env.ARQUIVOS.list({ prefix: `academias/${a.tenantId}/` })).objects).toHaveLength(0);
  });

  it('assistente não envia; o logotipo de outra academia não aparece', async () => {
    const a = await montarAcademia();
    const outra = await montarAcademia();
    let resposta = await chamar(a.assistente, 'PUT', '/api/academia/logotipo', corpoValido());
    expect(resposta.status).toBe(403);
    await resposta.arrayBuffer();
    resposta = await chamar(outra.professor, 'PUT', '/api/academia/logotipo', corpoValido());
    expect(resposta.status).toBe(200);
    await resposta.arrayBuffer();
    // A academia "a" não tem logotipo, mesmo com a outra tendo.
    resposta = await chamar(a.assistente, 'GET', '/api/eu/logotipo/512');
    expect(resposta.status).toBe(404);
    await resposta.arrayBuffer();
  });
});
