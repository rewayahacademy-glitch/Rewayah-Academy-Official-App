// PX-1 (SEC-1) : le connecteur MCP de Praxis. Voir _shared/praxis/mcp.ts. Ouverte sans JWT Supabase (config.toml) : la porte
// est la cle Praxis, relue en base a chaque appel. Elle n'a aucune logique metier : elle valide, puis appelle une fonction
// SQL `praxis_*` avec le role service_role (executable par lui seul).

import { clientService } from '../_shared/clients.ts'
import { type PortePraxis, traiter } from '../_shared/praxis/mcp.ts'

const porte: PortePraxis = {
  async appeler(fonction, params, signal) {
    const { data, error } = await clientService().rpc(fonction, params).abortSignal(signal)
    if (error) throw new Error('rpc')
    return data
  },
}

Deno.serve((req) => traiter(req, porte))
