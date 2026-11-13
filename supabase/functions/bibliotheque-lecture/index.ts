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

/// Une vignette se montre dans une liste : l'URL vit plus longtemps que celle
/// d'un document (60 s), mais reste courte.
const DUREE_VIGNETTE_S = 300
const VIGNETTES_MAX = 100

/// BIBLIOTHEQUE-UNE : les vignettes d'une liste de documents. La base dit
/// lesquels l'appelant a le droit de lire (`bibliotheque_vignettes_autorisees`,
/// avec son jeton) ; seule cette liste est signee. L'application ne recoit que
/// des URL, jamais une cle de stockage.
async function signerVignettes(
  compte: NonNullable<Awaited<ReturnType<typeof appelantR2>>>,
  corps: Record<string, unknown>,
): Promise<Response> {
  const ids = Array.isArray(corps.ids) ? corps.ids : []
  if (
    ids.length < 1 || ids.length > VIGNETTES_MAX ||
    !ids.every((i) => typeof i === 'string' && UUID.test(i))
  ) {
    return refus('liste de documents invalide')
  }
  const { data, error } = await compte.sql.rpc('bibliotheque_vignettes_autorisees', {
    p_ids: (ids as string[]).map((i) => i.toLowerCase()),
  })
  if (error || !Array.isArray(data)) return refus('acces aux vignettes refuse', 403)
  const urls: Record<string, string> = {}
  for (const ligne of data as Array<Record<string, unknown>>) {
    try {
      const id = String(ligne.id ?? '')
      if (!UUID.test(id)) continue
      const cle = verifierCle('supports', String(ligne.cle ?? ''))
      const signee = await signerLecture('supports', cle, {
        dureeSecondes: DUREE_VIGNETTE_S,
        contentDisposition: 'inline',
      })
      urls[id] = signee.url
    } catch {
      // Une vignette qui ne se signe pas est une vignette absente : la carte
      // retombe sur sa vignette par defaut, la liste ne tombe pas.
    }
  }
  return json({ urls, expire_dans_secondes: DUREE_VIGNETTE_S })
}

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
  if (corps.action === 'vignettes') return await signerVignettes(compte, corps)
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
