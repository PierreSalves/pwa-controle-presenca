export type TipoUsuario = 'superadmin' | 'professor' | 'assistente';

export type Acao =
  | 'gerenciar_tenants'
  | 'gerenciar_usuarios'
  | 'gerenciar_acessos'
  | 'editar_tenant'
  | 'gerenciar_alunos'
  | 'gerenciar_turmas'
  | 'gerenciar_matriculas'
  | 'lancar_presenca'
  | 'lancar_mensalidade'
  | 'ver_relatorios';

/** Matriz fixa de permissões (docs/arquitetura/README.md). Usada pela API e espelhada no app. */
const MATRIZ: Record<TipoUsuario, ReadonlySet<Acao>> = {
  superadmin: new Set<Acao>(['gerenciar_tenants', 'gerenciar_usuarios']),
  professor: new Set<Acao>([
    'gerenciar_usuarios',
    'gerenciar_acessos',
    'editar_tenant',
    'gerenciar_alunos',
    'gerenciar_turmas',
    'gerenciar_matriculas',
    'lancar_presenca',
    'lancar_mensalidade',
    'ver_relatorios',
  ]),
  assistente: new Set<Acao>([
    'gerenciar_alunos',
    'gerenciar_turmas',
    'gerenciar_matriculas',
    'lancar_presenca',
    'lancar_mensalidade',
    'ver_relatorios',
  ]),
};

export function podeExecutar(tipo: TipoUsuario, acao: Acao): boolean {
  return MATRIZ[tipo].has(acao);
}

export function ehTipoUsuario(valor: unknown): valor is TipoUsuario {
  return valor === 'superadmin' || valor === 'professor' || valor === 'assistente';
}
