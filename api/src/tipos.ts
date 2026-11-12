import type { TipoUsuario } from './seguranca/permissoes';

export interface UsuarioAutenticado {
  id: string;
  tenantId: string | null;
  tipo: TipoUsuario;
  sessaoId: string;
}

export interface Contexto {
  Bindings: Env;
  Variables: { usuario: UsuarioAutenticado };
}
