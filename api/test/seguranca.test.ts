import { describe, expect, it } from 'vitest';
import { podeExecutar } from '../src/seguranca/permissoes';
import { ehSenhaValida, gerarHashSenha, validarSenha } from '../src/seguranca/senha';
import { gerarTokenAcesso, validarTokenAcesso } from '../src/seguranca/tokens';
import { gerarUuidV7 } from '../src/util/ids';

describe('hash de senha', () => {
  it('gera hashes diferentes para a mesma senha (salt) e valida corretamente', async () => {
    const a = await gerarHashSenha('minha-senha');
    const b = await gerarHashSenha('minha-senha');
    expect(a).not.toBe(b);
    expect(a.startsWith('pbkdf2-sha256$100000$')).toBe(true);
    expect(await validarSenha('minha-senha', a)).toBe(true);
    expect(await validarSenha('Minha-senha', a)).toBe(false);
  });

  it('recusa hash em formato desconhecido', async () => {
    expect(await validarSenha('x', 'md5$abc')).toBe(false);
    expect(await validarSenha('x', 'pbkdf2-sha256$999999999$c2FsdA==$aGFzaA==')).toBe(false);
  });

  it('exige senha de pelo menos 8 caracteres', () => {
    expect(ehSenhaValida('1234567')).toBe(false);
    expect(ehSenhaValida('12345678')).toBe(true);
    expect(ehSenhaValida(12345678)).toBe(false);
  });
});

describe('token de acesso', () => {
  const dados = { sub: 'u1', tenant: 't1', tipo: 'assistente' as const, sessao: 's1' };

  it('valida token assinado com o mesmo segredo', async () => {
    const token = await gerarTokenAcesso(dados, 'segredo');
    expect(await validarTokenAcesso(token, 'segredo')).toEqual(dados);
  });

  it('recusa token com outro segredo ou expirado', async () => {
    const token = await gerarTokenAcesso(dados, 'segredo');
    expect(await validarTokenAcesso(token, 'outro')).toBeNull();
    const antigo = await gerarTokenAcesso(dados, 'segredo', Date.now() - 60 * 60 * 1000);
    expect(await validarTokenAcesso(antigo, 'segredo')).toBeNull();
  });
});

describe('matriz de permissões', () => {
  it('só o superadmin gerencia academias', () => {
    expect(podeExecutar('superadmin', 'gerenciar_tenants')).toBe(true);
    expect(podeExecutar('professor', 'gerenciar_tenants')).toBe(false);
    expect(podeExecutar('assistente', 'gerenciar_tenants')).toBe(false);
  });

  it('assistente não cadastra usuários nem acessos, mas lança e cadastra alunos e turmas', () => {
    expect(podeExecutar('assistente', 'gerenciar_usuarios')).toBe(false);
    expect(podeExecutar('assistente', 'gerenciar_acessos')).toBe(false);
    expect(podeExecutar('assistente', 'lancar_presenca')).toBe(true);
    expect(podeExecutar('assistente', 'gerenciar_alunos')).toBe(true);
    expect(podeExecutar('assistente', 'gerenciar_turmas')).toBe(true);
  });

  it('professor faz tudo dentro da academia', () => {
    expect(podeExecutar('professor', 'gerenciar_usuarios')).toBe(true);
    expect(podeExecutar('professor', 'gerenciar_acessos')).toBe(true);
    expect(podeExecutar('professor', 'lancar_presenca')).toBe(true);
  });

  it('superadmin não lança presença', () => {
    expect(podeExecutar('superadmin', 'lancar_presenca')).toBe(false);
  });
});

describe('UUID v7', () => {
  it('tem versão 7, variante correta e é ordenável pelo tempo', () => {
    const a = gerarUuidV7(1_700_000_000_000);
    const b = gerarUuidV7(1_700_000_000_001);
    expect(a).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
    expect(a < b).toBe(true);
  });
});
