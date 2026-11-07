// PUSH-1 : la cle publique VAPID, lue par l'application pour s'abonner.
// Le JWT est verifie par la plateforme. GET (et OPTIONS pour CORS).

import { enTetesCors } from '../clients.ts'
import { lireVapid, versBase64Url } from './web_push.ts'

export const enTetesCle = { ...enTetesCors, 'Access-Control-Allow-Methods': 'GET, OPTIONS' }

function reponse(corps: unknown, statut: number): Response {
  return new Response(JSON.stringify(corps), {
    status: statut,
    headers: { ...enTetesCle, 'Content-Type': 'application/json' },
  })
}

export function repondreCle(req: Request, env: (nom: string) => string | undefined): Response {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: enTetesCle })
  if (req.method !== 'GET') return reponse({ error: 'methode' }, 405)
  // Les trois secrets sont controles comme a l'envoi (lireVapid) : une cle
  // manquante donne 503, un format faux 500 « vapid invalide » (cle publique
  // de 65 octets commencant par 0x04, cle privee de 32 octets, sujet en
  // mailto: ou https:). Aucune valeur n'est jamais rendue sauf la publique.
  let vapid
  try {
    vapid = lireVapid(env)
  } catch (e) {
    // Le detail (longueurs seulement, jamais une valeur) va au journal.
    console.error((e as Error).message)
    return reponse({ error: 'vapid invalide' }, 500)
  }
  if (!vapid) return reponse({ error: 'push indisponible' }, 503)
  return reponse({ cle: versBase64Url(vapid.publique) }, 200)
}
