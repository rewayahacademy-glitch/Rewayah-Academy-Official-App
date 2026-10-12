// La seule table de correspondance entre une RESPONSABILITE METIER et un seau R2.
//
// Regle posee ici, et c'est toute la raison d'etre du fichier : **aucun appelant
// ne nomme jamais un seau.** Il nomme un domaine metier, et cette couche resout
// le seau. Une faute de frappe ne peut donc pas envoyer une piece d'identite
// dans le seau de la messagerie, parce qu'il n'existe aucun chemin de code qui
// accepte un nom de seau en parametre.
//
// C'est le meme raisonnement que `_shared/livekit.ts` applique aux jetons video :
// concentrer la regle dans un fichier unique la rend verifiable d'un seul `grep`
// plutot que par relecture de chaque appelant.
//
// Les quatre seaux sont FIGES. Ils existent deja chez Cloudflare, leurs
// identifiants sont deja emis, et leur cycle complet (ecriture, relecture,
// comparaison octet a octet, suppression, verification d'absence) a ete mesure
// au vert le 21 septembre 2026 sur les quatre. Ce fichier ne les cree pas, ne
// les renomme pas et ne les devine pas : il verifie que le trousseau pose sur le
// serveur designe bien celui qu'on attend.
//
// Ce que ce fichier ne fait PAS, et c'est delibere :
//
//   * il ne fabrique aucun point d'acces. L'endpoint est lu dans les secrets,
//     jamais reconstruit depuis l'identifiant de compte. Les quatre seaux vivent
//     sous juridiction europeenne, leur hote porte donc un segment `.eu.`, et
//     reconstruire l'hote sans ce segment rend un 403 que rien n'explique ;
//   * il n'expose jamais une valeur de secret, ni dans un message d'erreur, ni
//     dans un journal. Les NOMS des secrets circulent, leurs VALEURS non.

/// Les quatre responsabilites metier, et rien d'autre.
///
/// Ajouter une valeur ici sans ajouter son trousseau ci-dessous ne compile pas :
/// les deux tables sont des `Record` complets sur ce type.
export type DomaineStockage =
  | 'pieceIdentite'
  | 'archiveSeance'
  | 'pieceJointeMessage'
  | 'priveApplicatif'
  | 'supports'

/// Le prefixe du groupe de cinq secrets de chaque domaine.
const PREFIXE: Record<DomaineStockage, string> = {
  pieceIdentite: 'R2_IDENTITY_VAULT',
  archiveSeance: 'R2_RECORDINGS',
  pieceJointeMessage: 'R2_MESSAGING',
  priveApplicatif: 'R2_APP_PRIVATE',
  supports: 'R2_APP_PRIVATE',
}

/// Le seau que chaque domaine DOIT atteindre.
///
/// Cette table n'est pas la source du nom employe a la signature -- ce nom est
/// lu dans `<PREFIXE>_BUCKET_NAME`. Elle est le controle : si le secret pose sur
/// le serveur ne porte pas ce nom, la configuration part vers un seau qui n'est
/// pas le sien et la resolution echoue franchement au lieu de reussir au mauvais
/// endroit. C'est ce qui rend vrai << aucun domaine ne partage accidentellement
/// le seau d'un autre >>, plutot que de l'esperer.
const SEAU_ATTENDU: Record<DomaineStockage, string | null> = {
  pieceIdentite: 'rewayah-identity-vault',
  archiveSeance: 'rewayah-session-recordings',
  pieceJointeMessage: 'rewayah-message-attachments',
  priveApplicatif: 'rewayah-app-private-storage',
  supports: null,
}

/// Tous les domaines, pour les balayages de configuration et les tests.
export const DOMAINES: readonly DomaineStockage[] = Object.keys(PREFIXE) as DomaineStockage[]

/// Le nom du seau attendu pour un domaine. Sert au controle et aux tests ; ce
/// n'est jamais ce qui est envoye a R2.
export function seauAttendu(domaine: DomaineStockage): string | null {
  return SEAU_ATTENDU[domaine]
}

/// Le prefixe de secrets d'un domaine. Un NOM, jamais une valeur.
export function prefixeSecrets(domaine: DomaineStockage): string {
  return PREFIXE[domaine]
}

/// Ce dont la couche de signature a besoin, et rien de plus.
///
/// Volontairement sans `accountId` : il n'est utile qu'a construire un endpoint,
/// or l'endpoint est lu. Le garder ici serait une valeur sensible transportee
/// sans emploi.
export interface ConfigurationR2 {
  readonly domaine: DomaineStockage
  readonly seau: string
  readonly pointAcces: URL
  readonly cleAcces: string
  readonly secretAcces: string
}

/// L'echec de configuration, structure et sans fuite.
///
/// `message` ne porte que le NOM du secret fautif et un motif. La valeur lue
/// n'y entre jamais : un message d'erreur finit dans un journal, et un journal
/// finit par etre lu par quelqu'un qui n'avait pas a connaitre la cle.
export class ErreurConfigurationR2 extends Error {
  readonly domaine: DomaineStockage
  readonly secret: string
  readonly motif: string

  constructor(domaine: DomaineStockage, secret: string, motif: string) {
    super(`configuration R2 invalide : ${secret} (${motif})`)
    this.name = 'ErreurConfigurationR2'
    this.domaine = domaine
    this.secret = secret
    this.motif = motif
  }
}

/// Comment on lit l'environnement.
///
/// Injecte plutot que capture, pour deux raisons : la configuration devient
/// testable sans poser de variables d'environnement reelles, et un test ne peut
/// pas lire par accident un vrai trousseau present sur la machine.
export type LecteurEnvironnement = (nom: string) => string | undefined

const ENVIRONNEMENT_DENO: LecteurEnvironnement = (nom) => {
  // `Deno` est absent d'un harnais Node ; la configuration reste alors lisible
  // par injection, ce dont les tests unitaires se servent.
  const portee = globalThis as { Deno?: { env: { get(n: string): string | undefined } } }
  return portee.Deno?.env.get(nom)
}

const HEXADECIMAL_32 = /^[0-9a-f]{32}$/i
const HEXADECIMAL_64 = /^[0-9a-f]{64}$/i

/// Lit un secret et refuse le vide.
///
/// Le blanc de bordure est retire parce qu'un secret colle depuis un tableau de
/// bord traine souvent un retour a la ligne, et qu'une cle avec un `\n` final
/// produit une signature invalide dont le message ne dit rien d'utile.
function lireSecret(
  domaine: DomaineStockage,
  suffixe: string,
  env: LecteurEnvironnement,
): string {
  const nom = domaine === 'supports' && suffixe === 'BUCKET_NAME'
    ? 'R2_BUCKET_SUPPORTS'
    : `${PREFIXE[domaine]}_${suffixe}`
  const brut = env(nom)
  if (brut === undefined || brut.trim() === '') {
    throw new ErreurConfigurationR2(domaine, nom, 'secret absent')
  }
  const valeur = brut.trim()
  // Panne reellement rencontree le 21 septembre pendant la mise au point des
  // quatre trousseaux : une variable contenait `NOM = valeur`, une autre
  // contenait le nom de la variable au lieu de son contenu. Les deux se voient
  // ici, et nulle part ailleurs.
  if (/\s/.test(valeur)) {
    throw new ErreurConfigurationR2(domaine, nom, 'la valeur contient une espace')
  }
  return valeur
}

/// Resout la configuration complete d'un domaine, ou echoue franchement.
///
/// Aucun repli. Un domaine mal configure ne bascule jamais sur le trousseau d'un
/// autre : c'est precisement le repli silencieux qui ferait atterrir une piece
/// d'identite dans le seau des pieces jointes.
export function configurationDe(
  domaine: DomaineStockage,
  env: LecteurEnvironnement = ENVIRONNEMENT_DENO,
): ConfigurationR2 {
  const prefixe = PREFIXE[domaine]

  // Lu pour etre VERIFIE, pas pour etre transporte : l'identifiant de compte
  // n'entre pas dans `ConfigurationR2`.
  const compte = lireSecret(domaine, 'ACCOUNT_ID', env)
  if (!HEXADECIMAL_32.test(compte)) {
    throw new ErreurConfigurationR2(
      domaine,
      `${prefixe}_ACCOUNT_ID`,
      'forme inattendue, 32 caracteres hexadecimaux attendus',
    )
  }

  const cleAcces = lireSecret(domaine, 'ACCESS_KEY_ID', env)
  if (!HEXADECIMAL_32.test(cleAcces)) {
    throw new ErreurConfigurationR2(
      domaine,
      `${prefixe}_ACCESS_KEY_ID`,
      'forme inattendue, 32 caracteres hexadecimaux attendus',
    )
  }

  const secretAcces = lireSecret(domaine, 'SECRET_ACCESS_KEY', env)
  if (!HEXADECIMAL_64.test(secretAcces)) {
    throw new ErreurConfigurationR2(
      domaine,
      `${prefixe}_SECRET_ACCESS_KEY`,
      'forme inattendue, 64 caracteres hexadecimaux attendus',
    )
  }

  const seau = lireSecret(domaine, 'BUCKET_NAME', env)
  if (domaine === 'supports') {
    if (!/^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$/.test(seau)) {
      throw new ErreurConfigurationR2(domaine, 'R2_BUCKET_SUPPORTS', 'nom de seau invalide')
    }
  } else if (seau !== SEAU_ATTENDU[domaine]) {
    // Le nom lu n'entre pas dans le message : c'est peut-etre le seau d'un
    // AUTRE domaine, et l'annoncer reviendrait a publier la carte des seaux
    // dans un journal.
    throw new ErreurConfigurationR2(
      domaine,
      `${prefixe}_BUCKET_NAME`,
      `ne designe pas ${SEAU_ATTENDU[domaine]}`,
    )
  }

  const pointAcces = lirePointAcces(domaine, env, compte)

  return { domaine, seau, pointAcces, cleAcces, secretAcces }
}

/// Lit et valide le point d'acces, sans jamais le fabriquer.
///
/// La juridiction europeenne des quatre seaux impose un hote en
/// `<compte>.eu.r2.cloudflarestorage.com`. Reconstruire cet hote a partir de
/// l'identifiant de compte produirait la forme sans `.eu.`, mesuree en 403 le
/// 21 septembre sur les quatre trousseaux. On lit donc la valeur posee, et on se
/// contente d'en verifier la forme -- y compris qu'elle designe bien le compte
/// dont on vient de lire l'identifiant. Les quatre domaines vivent sur quatre
/// comptes Cloudflare DISTINCTS : un point d'acces recopie d'un domaine a
/// l'autre signerait vers le compte du voisin, et R2 repondrait 403 sans jamais
/// dire pourquoi.
function lirePointAcces(
  domaine: DomaineStockage,
  env: LecteurEnvironnement,
  compte: string,
): URL {
  const nom = `${PREFIXE[domaine]}_ENDPOINT`
  const brut = lireSecret(domaine, 'ENDPOINT', env)

  let url: URL
  try {
    url = new URL(brut)
  } catch {
    throw new ErreurConfigurationR2(domaine, nom, 'ce n est pas une URL absolue')
  }

  if (url.protocol !== 'https:') {
    throw new ErreurConfigurationR2(domaine, nom, 'protocole autre que https')
  }
  if (!url.hostname.endsWith('.r2.cloudflarestorage.com')) {
    throw new ErreurConfigurationR2(domaine, nom, 'hote hors de r2.cloudflarestorage.com')
  }
  // L'hote doit commencer par l'identifiant de compte de CE domaine. C'est ce
  // qui distingue un point d'acces simplement mal forme d'un point d'acces qui
  // vise un autre compte.
  if (!url.hostname.startsWith(`${compte.toLowerCase()}.`)) {
    throw new ErreurConfigurationR2(domaine, nom, 'ne designe pas le compte de ce domaine')
  }
  // Un endpoint qui porte deja un chemin ferait signer une cle sous un prefixe
  // invisible depuis l'appelant.
  if (url.pathname !== '/' || url.search !== '' || url.hash !== '') {
    throw new ErreurConfigurationR2(domaine, nom, 'le point d acces porte un chemin ou des parametres')
  }

  return url
}

/// Vrai quand les cinq secrets d'un domaine sont poses et valides.
///
/// Sert a repondre proprement << ce stockage n'est pas encore branche >> plutot
/// qu'a exploser, exactement comme `videoConfiguree()` le fait pour la video.
export function stockageConfigure(
  domaine: DomaineStockage,
  env: LecteurEnvironnement = ENVIRONNEMENT_DENO,
): boolean {
  try {
    configurationDe(domaine, env)
    return true
  } catch {
    return false
  }
}
