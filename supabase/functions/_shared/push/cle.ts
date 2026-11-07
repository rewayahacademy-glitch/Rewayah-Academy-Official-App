// PUSH-1 : la cle publique VAPID, lue par l'application pour s'abonner.
// Le JWT est verifie par la plateforme. GET (et OPTIONS pour CORS).

import { enTetesCors } from '../clients.ts'

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
  const cle = env('VAPID_PUBLIC_KEY')?.trim()
  if (!cle) return reponse({ error: 'push indisponible' }, 503)
  return reponse({ cle }, 200)
}
