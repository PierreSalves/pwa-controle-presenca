import { env, exports } from 'cloudflare:workers';
import { gerarHashSenha } from '../src/seguranca/senha';
import type { TipoUsuario } from '../src/seguranca/permissoes';

export const BASE = 'https://exemplo.test';
export const SENHA_PADRAO = 'senha-de-teste-123';

let contador = 0;
function gerarId(prefixo: string): string {
  contador += 1;
  return `${prefixo}-${Date.now()}-${contador}`;
}

/** Faz uma requisição ao Worker, como o app faria. */
export function requisitar(caminho: string, init: RequestInit = {}): Promise<Response> {
  return exports.default.fetch(`${BASE}${caminho}`, init);
}

export async function criarTenant(nome = 'Academia Teste', ativo = 1): Promise<string> {
  const id = gerarId('tenant');
  await env.DB.prepare('INSERT INTO tenants (id, nome, ativo) VALUES (?1, ?2, ?3)')
    .bind(id, nome, ativo)
    .run();
  return id;
}

export async function criarUsuario(opcoes: {
  tenantId: string | null;
  tipo: TipoUsuario;
  email?: string;
  senha?: string;
  ativo?: number;
}): Promise<{ id: string; email: string; senha: string }> {
  const id = gerarId('usuario');
  const email = opcoes.email ?? `${id}@exemplo.test`;
  const senha = opcoes.senha ?? SENHA_PADRAO;
  await env.DB.prepare(
    'INSERT INTO usuarios (id, tenant_id, tipo, nome, email, senha_hash, ativo) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
  )
    .bind(
      id,
      opcoes.tenantId,
      opcoes.tipo,
      `Usuário ${contador}`,
      email,
      await gerarHashSenha(senha),
      opcoes.ativo ?? 1,
    )
    .run();
  return { id, email, senha };
}

export async function criarTurma(tenantId: string, nome: string): Promise<string> {
  const id = gerarId('turma');
  await env.DB.prepare('INSERT INTO turmas (id, tenant_id, nome) VALUES (?1, ?2, ?3)')
    .bind(id, tenantId, nome)
    .run();
  return id;
}

export async function liberarTurma(tenantId: string, turmaId: string, usuarioId: string): Promise<void> {
  await env.DB.prepare(
    'INSERT INTO turma_usuarios (id, tenant_id, turma_id, usuario_id) VALUES (?1, ?2, ?3, ?4)',
  )
    .bind(gerarId('acesso'), tenantId, turmaId, usuarioId)
    .run();
}

export interface Login {
  resposta: Response;
  tokenAcesso: string;
  cookieRenovacao: string;
}

/** Faz login e devolve o token de acesso e o cookie de renovação. */
export async function entrar(email: string, senha: string): Promise<Login> {
  const resposta = await requisitar('/api/autenticacao/entrar', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, senha }),
  });
  const corpo = resposta.ok ? await resposta.clone().json<{ token_acesso: string }>() : { token_acesso: '' };
  return { resposta, tokenAcesso: corpo.token_acesso, cookieRenovacao: extrairCookie(resposta) };
}

export function extrairCookie(resposta: Response): string {
  const valor = resposta.headers.get('Set-Cookie') ?? '';
  return valor.split(';')[0] ?? '';
}

export function comToken(token: string, init: RequestInit = {}): RequestInit {
  return { ...init, headers: { ...(init.headers ?? {}), Authorization: `Bearer ${token}` } };
}
