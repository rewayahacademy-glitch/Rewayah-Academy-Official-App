// Etat des connexions R2, pour la direction seulement.
//
//   POST (ou GET) sans corps  ->  { connexions: { <domaine>: { configuree, joignable } } }
//
// Reactivee le 03/11/2026 sur decision de la direction. La version deployee
// jusqu'ici (v62) repondait 410 depuis le 21/09/2026 et sa source n'avait
// jamais ete versionnee ; celle-ci la remplace a la fusion, par `deploy.yml`.
//
// Elle n'ecrit rien, ni dans R2 ni en base : un HEAD signe par domaine, sur une
// cle qui n'existe pas (`_shared/r2/autotest.ts`). Elle ne renvoie ni secret,
// ni nom de seau, ni point d'acces, ni message de R2 : seulement le nom du
// domaine metier et deux booleens.
//
// Porte : un compte `admin` dont la session est valide (compte actif, jeton a
// jour). Le role est lu par `app_role()` sous le jeton de l'appelant, jamais
// dans le corps.

import { enTetesCors, json, refus } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { etatConnexions } from '../_shared/r2/autotest.ts'

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }
  if (requete.method !== 'POST' && requete.method !== 'GET') {
    return refus('methode non autorisee', 405)
  }

  const compte = await appelantR2(requete)
  if (!compte) {
    return refus('authentification requise', 401)
  }

  const [{ data: role, error: erreurRole }, { data: valide, error: erreurSession }] = await Promise.all([
    compte.sql.rpc('app_role'),
    compte.sql.rpc('rech_session_autorisee'),
  ])
  if (erreurRole || erreurSession) {
    console.error('autotest R2 : porte illisible', {
      role: erreurRole?.code ?? null,
      session: erreurSession?.code ?? null,
    })
    return refus('verification impossible', 503)
  }
  if (role !== 'admin' || valide !== true) {
    return refus('reserve a la direction', 403)
  }

  const connexions = await etatConnexions()
  console.log('autotest R2', {
    domaines: Object.fromEntries(
      Object.entries(connexions).map(([d, e]) => [d, e.configuree && e.joignable]),
    ),
  })
  return json({ connexions })
})
