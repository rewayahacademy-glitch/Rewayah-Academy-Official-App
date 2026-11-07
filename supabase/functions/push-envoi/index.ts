// PUSH-1 : vide la file des notifications push (Web Push, RFC 8291 et 8292).
// Ouverte sans JWT : la porte est le secret partage `COURRIELS_ENVOI_SECRET`
// (le meme que courriels-envoi), en en-tete `x-courriels-secret`, compare en
// temps constant. La cle de service ne sert qu'aux deux RPC du travailleur,
// `push_reserver` et `push_consigner`. Toute la logique est dans
// `_shared/push/`, testee sans reseau.

import { clientService } from '../_shared/clients.ts'
import { creerTravailleur } from '../_shared/push/travailleur.ts'

Deno.serve(creerTravailleur({
  env: (nom) => Deno.env.get(nom),
  base: () => clientService(),
}))
