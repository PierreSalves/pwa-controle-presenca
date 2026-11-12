// Cria o administrador do sistema (superadmin) no banco D1.
//
// Uso (dentro de api/):
//   npm run criar-superadmin -- --email admin@exemplo.com --nome "Administrador"            (banco local)
//   npm run criar-superadmin -- --email admin@exemplo.com --nome "Administrador" --remoto   (banco na Cloudflare)
//
// A senha vem da variável de ambiente SENHA_SUPERADMIN; se não for informada, uma senha aleatória
// é gerada e mostrada uma única vez. Troque-a no primeiro acesso.
import { execFileSync } from 'node:child_process';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { ehSenhaValida, gerarHashSenha } from '../src/seguranca/senha.ts';

function escaparSql(valor: string): string {
  return `'${valor.replace(/'/g, "''")}'`;
}

const { values } = parseArgs({
  options: {
    email: { type: 'string' },
    nome: { type: 'string', default: 'Administrador do sistema' },
    remoto: { type: 'boolean', default: false },
  },
});

const email = values.email?.trim().toLowerCase();
if (!email || !email.includes('@')) {
  console.error('Informe --email com um e-mail válido.');
  process.exit(1);
}

const senhaInformada = process.env.SENHA_SUPERADMIN;
const senha = senhaInformada ?? randomBytes(12).toString('base64url');
if (!ehSenhaValida(senha)) {
  console.error('A senha precisa ter pelo menos 8 caracteres.');
  process.exit(1);
}

const sql = `INSERT INTO usuarios (id, tenant_id, tipo, nome, email, senha_hash)
VALUES (${escaparSql(randomUUID())}, NULL, 'superadmin', ${escaparSql(values.nome ?? 'Administrador do sistema')}, ${escaparSql(email)}, ${escaparSql(await gerarHashSenha(senha))});`;

const pasta = mkdtempSync(join(tmpdir(), 'superadmin-'));
const arquivo = join(pasta, 'superadmin.sql');
writeFileSync(arquivo, sql);
try {
  // Chama o Wrangler do projeto direto pelo Node, sem shell (os argumentos não são reinterpretados).
  const wrangler = join(
    dirname(fileURLToPath(import.meta.url)),
    '..',
    'node_modules',
    'wrangler',
    'bin',
    'wrangler.js',
  );
  execFileSync(
    process.execPath,
    [wrangler, 'd1', 'execute', 'DB', values.remoto ? '--remote' : '--local', '--file', arquivo],
    { stdio: 'inherit' },
  );
} finally {
  rmSync(pasta, { recursive: true, force: true });
}

console.log(`\nSuperadmin criado: ${email} (${values.remoto ? 'banco remoto' : 'banco local'})`);
if (!senhaInformada) console.log(`Senha gerada (guarde agora, não será mostrada de novo): ${senha}`);
