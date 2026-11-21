// La fonction `kyc-confirme` (FN-101). Son travail et ses regles sont dans
// `traiter.ts` (PE-B10, 20/11/2026 : separes pour etre testes sans reseau) ;
// ce point d'entree ne fait que brancher le monde reel.

import { appelantDetaille, clientService } from '../_shared/clients.ts'
import { traiter } from './traiter.ts'

Deno.serve((requete: Request) =>
  traiter(requete, {
    appelant: appelantDetaille,
    url: () => Deno.env.get('SUPABASE_URL'),
    cleLecture: () => Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
    fetch: (url, init) => fetch(url, init),
    confirmer: async (deposePar, cle, type) => {
      const { error } = await clientService().rpc('kyc_confirmer_contenu', {
        p_depose_par: deposePar,
        p_object_key: cle,
        p_type_contenu: type,
      })
      return { error: error ? { message: error.message } : null }
    },
  })
)
