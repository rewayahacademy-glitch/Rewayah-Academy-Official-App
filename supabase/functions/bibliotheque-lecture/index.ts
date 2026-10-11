import { enTetesCors, json, refus } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { verifierCle } from '../_shared/r2/cles.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import {
  DUREE_LECTURE_SENSIBLE_S,
  journaliser,
  signerLecture,
} from '../_shared/r2/signature.ts'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') return new Response('ok', { headers: enTetesCors })
  if (requete.method !== 'POST') return refus('methode non autorisee', 405)

  if (!stockageConfigure('supports')) return refus('stockage indisponible', 503)

  let compte
  try {
    compte = await appelantR2(requete)
  } catch {
    return refus('stockage indisponible', 503)
  }
  if (!compte) return refus('authentification requise', 401)

  let corps: Record<string, unknown>
  try {
    const valeur: unknown = await requete.json()
    if (!valeur || typeof valeur !== 'object' || Array.isArray(valeur)) return refus('corps invalide')
    corps = valeur as Record<string, unknown>
  } catch {
    return refus('corps illisible')
  }

  if ('object_key' in corps || 'cle_stockage' in corps) return refus('cle resolue par le serveur')
  const versionId = typeof corps.resource_version_id === 'string' ? corps.resource_version_id.trim() : ''
  if (!UUID.test(versionId)) return refus('version invalide')

  const debut = Date.now()
  const { data, error } = await compte.sql.rpc('autoriser_lecture_version', {
    p_resource_version_id: versionId,
  })

  if (error || typeof data !== 'string') {
    journaliser({
      domaine: 'supports',
      operation: 'lecture',
      statut: 'refuse',
      dureeMs: Date.now() - debut,
    })
    return refus('acces a la ressource refuse', 403)
  }

  try {
    const cle = verifierCle('supports', data)
    const signee = await signerLecture('supports', cle, {
      dureeSecondes: DUREE_LECTURE_SENSIBLE_S,
      contentDisposition: 'inline',
    })
    journaliser({
      domaine: 'supports',
      operation: 'lecture',
      statut: 'accorde',
      ressource: versionId,
      dureeMs: Date.now() - debut,
    })
    return json({ url: signee.url, expire_dans_secondes: signee.expireDansSecondes })
  } catch (e) {
    journaliser({
      domaine: 'supports',
      operation: 'lecture',
      statut: 'echec',
      ressource: versionId,
      classeErreur: (e as Error)?.name ?? 'inconnue',
      dureeMs: Date.now() - debut,
    })
    return refus('stockage indisponible', 503)
  }
})
