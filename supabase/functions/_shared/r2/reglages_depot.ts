// DEPOT-SIMPLE (13/11/2026) : les reglages de production dont depend le depot
// d'un document de la bibliotheque, et LEQUEL manque.
//
// Le directeur a du les decouvrir un par un, par des echecs (secret de
// confirmation, regle d'origine du seau, nom du seau des documents). Cette
// lecture les nomme d'un coup, pour la direction seulement.
//
// Ce que ce fichier rend : des NOMS de reglages, jamais une valeur, jamais un
// nom de seau, jamais un point d'acces. Il n'ecrit rien et ne signe rien.

import {
  configurationDe,
  type DomaineStockage,
  ErreurConfigurationR2,
  type LecteurEnvironnement,
  prefixeSecrets,
} from './domaines.ts'

/// Le secret avec lequel la fonction signe la confirmation d'un depot. La base
/// en garde la meme valeur dans private.library_upload_confirmation_secrets.
export const NOM_SECRET_CONFIRMATION = 'LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY'

/// Le nom, cote base, du reglage jumeau du secret de confirmation.
export const NOM_SECRET_BASE = 'private.library_upload_confirmation_secrets'

/// Le nom du reglage de Cloudflare qui laisse le navigateur envoyer un fichier.
export const NOM_REGLE_ORIGINE = 'CORS du seau R2 (origine de l application, methode PUT, en-tete content-type)'

const ENV_DENO: LecteurEnvironnement = (nom) => {
  try {
    return Deno.env.get(nom)
  } catch {
    return undefined
  }
}

/// Les deux domaines qu'un depot de la bibliotheque traverse : le depot
/// temporaire, puis le seau des documents.
export const DOMAINES_DEPOT: readonly DomaineStockage[] = ['priveApplicatif', 'supports']

function nomsDe(domaine: DomaineStockage): string[] {
  const prefixe = prefixeSecrets(domaine)
  return [
    `${prefixe}_ACCOUNT_ID`,
    `${prefixe}_ACCESS_KEY_ID`,
    `${prefixe}_SECRET_ACCESS_KEY`,
    domaine === 'supports' ? 'R2_BUCKET_SUPPORTS' : `${prefixe}_BUCKET_NAME`,
    `${prefixe}_ENDPOINT`,
  ]
}

/// Les secrets de stockage absents ou invalides, par leur nom. Vide quand les
/// deux domaines du depot sont regles.
export function secretsStockageManquants(env: LecteurEnvironnement = ENV_DENO): string[] {
  const manquants = new Set<string>()
  for (const domaine of DOMAINES_DEPOT) {
    for (const nom of nomsDe(domaine)) {
      const valeur = env(nom)
      if (valeur === undefined || valeur.trim() === '') manquants.add(nom)
    }
  }
  if (manquants.size === 0) {
    // Tous presents : l'un peut encore etre mal forme. La configuration le dit
    // par son nom, jamais par sa valeur.
    for (const domaine of DOMAINES_DEPOT) {
      try {
        configurationDe(domaine, env)
      } catch (e) {
        if (e instanceof ErreurConfigurationR2) manquants.add(e.secret)
        else throw e
      }
    }
  }
  return [...manquants].sort()
}

/// Le premier secret de stockage qui manque a ces domaines, ou `null`.
export function reglageManquant(
  domaines: readonly DomaineStockage[],
  env: LecteurEnvironnement = ENV_DENO,
): string | null {
  for (const domaine of domaines) {
    try {
      configurationDe(domaine, env)
    } catch (e) {
      if (e instanceof ErreurConfigurationR2) return e.secret
      throw e
    }
  }
  return null
}

/// Vrai quand le secret de confirmation est pose, assez long et sans espace
/// autour (la fonction le refuse sinon).
export function secretConfirmationValide(env: LecteurEnvironnement = ENV_DENO): boolean {
  const secret = env(NOM_SECRET_CONFIRMATION) ?? ''
  return new TextEncoder().encode(secret).byteLength >= 32 && secret.trim() === secret
}

export type EtatOrigine = 'admise' | 'refusee' | 'inconnue'

/// Demande au seau du depot temporaire s'il laisse le navigateur de cette
/// origine y envoyer un fichier : la meme question que le navigateur pose avant
/// l'envoi (OPTIONS). Aucune signature, aucun objet lu ni ecrit.
export async function origineAdmise(
  origine: string | null,
  env: LecteurEnvironnement = ENV_DENO,
  demander: typeof fetch = fetch,
): Promise<EtatOrigine> {
  if (!origine || !/^https?:\/\/[^\s/]+$/.test(origine)) return 'inconnue'
  let url: URL
  try {
    const config = configurationDe('priveApplicatif', env)
    url = new URL(config.pointAcces.toString())
    url.pathname = `/${config.seau}/private/libraryupload/00000000-0000-4000-8000-000000000000`
  } catch {
    return 'inconnue'
  }
  try {
    const reponse = await demander(url.toString(), {
      method: 'OPTIONS',
      headers: {
        'Origin': origine,
        'Access-Control-Request-Method': 'PUT',
        'Access-Control-Request-Headers': 'content-type',
      },
    })
    await reponse.body?.cancel()
    const admise = reponse.headers.get('access-control-allow-origin')
    const methodes = (reponse.headers.get('access-control-allow-methods') ?? '').toUpperCase()
    if (reponse.ok && (admise === '*' || admise === origine) && methodes.includes('PUT')) {
      return 'admise'
    }
    return 'refusee'
  } catch {
    return 'inconnue'
  }
}

export interface ReglagesDepot {
  /// Les reglages qui manquent, par leur nom. Vide : tout est pose.
  readonly manquants: string[]
  /// La regle d'origine du seau, telle que le seau l'a dite.
  readonly origine: EtatOrigine
}

/// L'etat des reglages du depot. [secretBasePose] vient de la base
/// (`bibliotheque_depot_actif`), qui seule peut le dire.
export async function reglagesDepot(
  origine: string | null,
  secretBasePose: boolean,
  env: LecteurEnvironnement = ENV_DENO,
  demander: typeof fetch = fetch,
): Promise<ReglagesDepot> {
  const manquants = secretsStockageManquants(env)
  if (!secretConfirmationValide(env)) manquants.push(NOM_SECRET_CONFIRMATION)
  if (!secretBasePose) manquants.push(NOM_SECRET_BASE)
  const etat = await origineAdmise(origine, env, demander)
  if (etat === 'refusee') manquants.push(NOM_REGLE_ORIGINE)
  return { manquants, origine: etat }
}

/// Le corps d'un refus 503. Le NOM du reglage en cause n'est rendu qu'a la
/// direction : un eleve, un tuteur ou un enseignant ne recoit jamais un nom de
/// reglage du serveur (DEPOT-SIMPLE, relecture I2).
export function corpsRefusReglage(
  message: string,
  reglage: string | null,
  estDirection: boolean,
): { error: string; reglage?: string } {
  return estDirection && reglage !== null ? { error: message, reglage } : { error: message }
}
