// Partes comuns do cadastro de usuários, usadas pelo professor (rotas/usuarios.ts) e pelo
// administrador do sistema ao criar os primeiros professores de uma academia (rotas/admin.ts).
import { ehSenhaValida, gerarHashSenha } from '../seguranca/senha';
import { gerarUuidV7 } from '../util/ids';
import { lerTextoObrigatorio } from '../util/validacao';

const PADRAO_EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export type TipoUsuarioDoTenant = 'professor' | 'assistente';

export interface DadosNovoUsuario {
  nome: string;
  email: string;
  tipo: TipoUsuarioDoTenant;
  senha: string;
}

/** E-mail em minúsculas e sem espaços nas pontas; `undefined` se inválido. */
export function lerEmail(valor: unknown): string | undefined {
  if (typeof valor !== 'string') return undefined;
  const email = valor.trim().toLowerCase();
  return email.length <= 120 && PADRAO_EMAIL.test(email) ? email : undefined;
}

export function lerTipoUsuarioDoTenant(valor: unknown): TipoUsuarioDoTenant | undefined {
  return valor === 'professor' || valor === 'assistente' ? valor : undefined;
}

/** Dados de um usuário novo. `tipoFixo` força o tipo (ex.: o admin só cria professores). */
export function lerDadosNovoUsuario(
  corpo: Record<string, unknown> | null,
  tipoFixo?: TipoUsuarioDoTenant,
): DadosNovoUsuario | null {
  if (!corpo) return null;
  const nome = lerTextoObrigatorio(corpo.nome, 120);
  const email = lerEmail(corpo.email);
  const tipo = tipoFixo ?? lerTipoUsuarioDoTenant(corpo.tipo);
  const senha = corpo.senha;
  if (nome === undefined || email === undefined || tipo === undefined || !ehSenhaValida(senha)) return null;
  return { nome, email, tipo, senha };
}

/** E-mail já usado por outro usuário não excluído (o e-mail é único no sistema inteiro). */
export async function existeOutroUsuarioComEmail(
  db: D1Database,
  email: string,
  ignorarId: string | null,
): Promise<boolean> {
  const linha = await db
    .prepare(`SELECT 1 AS ok FROM usuarios WHERE email = ?1 AND excluido = 0 AND id <> coalesce(?2, '')`)
    .bind(email, ignorarId)
    .first();
  return linha !== null;
}

/** Comando de inserção do usuário (para entrar num batch junto com outras gravações). */
export async function prepararInsercaoUsuario(
  db: D1Database,
  tenantId: string,
  dados: DadosNovoUsuario,
  autorId: string,
  agora: string,
): Promise<{ id: string; comando: D1PreparedStatement }> {
  const id = gerarUuidV7();
  const comando = db
    .prepare(
      `INSERT INTO usuarios (id, tenant_id, tipo, nome, email, senha_hash, created_at, updated_at, created_by, updated_by)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?7, ?8, ?8)`,
    )
    .bind(
      id,
      tenantId,
      dados.tipo,
      dados.nome,
      dados.email,
      await gerarHashSenha(dados.senha),
      agora,
      autorId,
    );
  return { id, comando };
}

/** Revoga todas as sessões abertas do usuário (ele precisa entrar de novo). */
export function prepararRevogacaoSessoes(
  db: D1Database,
  usuarioId: string,
  agora: string,
): D1PreparedStatement {
  return db
    .prepare('UPDATE sessoes SET revogado_em = ?1 WHERE usuario_id = ?2 AND revogado_em IS NULL')
    .bind(agora, usuarioId);
}
