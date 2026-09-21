// Le SEUL fichier du depot autorise a signer une requete R2.
//
// Meme regle que `_shared/livekit.ts` pose pour les jetons video, et pour la
// meme raison : les identifiants R2 ne quittent jamais les secrets du serveur,
// aucune autre fonction n'a le droit de fabriquer une URL signee, et concentrer
// cela ici rend la regle verifiable d'un seul `grep` plutot que par relecture.
//
// Pourquoi `aws4fetch` plutot qu'une signature SigV4 ecrite a la main : c'est le
// meme arbitrage que le SDK LiveKit. Une chaine canonique fabriquee de memoire
// marche le jour ou on l'ecrit, et casse en silence des qu'un detail change --
// l'ordre des en-tetes signes, l'encodage d'un segment, la charge utile vide
// d'un PUT pre-signe. `aws4fetch` fait 6 Ko, n'a aucune dependance d'execution,
// et c'est la bibliotheque que Cloudflare emploie elle-meme pour R2.
//
// Ce que ce fichier ne fait PAS :
//
//   * il ne decide aucune autorisation. **Une URL signee n'est pas une
//     autorisation** : c'est le produit d'une autorisation deja accordee. Le
//     controle metier vit en base, dans les RPC appelees par les points
//     d'entree, la ou les roles, la RLS et l'appartenance sont sous la main ;
//   * il n'accepte jamais un nom de seau. Il prend un DOMAINE, et `domaines.ts`
//     resout le seau ;
//   * il ne journalise jamais l'URL produite. Une URL pre-signee porte sa
//     signature dans sa chaine de requete : la consigner, c'est consigner un
//     droit d'acces reutilisable jusqu'a son expiration.

import { AwsClient } from 'npm:aws4fetch@1.0.20'
import {
  type ConfigurationR2,
  configurationDe,
  type DomaineStockage,
  ErreurConfigurationR2,
  type LecteurEnvironnement,
} from './domaines.ts'

// ============================================================
// Politique de duree -- centralisee, jamais recopiee
// ============================================================

/// Duree d'une URL de lecture sur une ressource sensible.
///
/// Soixante secondes, et c'est la decision de l'ADR-002 pour l'ecoute d'une
/// archive : << bucket prive, URL signee 60 secondes, generation serveur
/// uniquement >>. L'apercu KYC applique deja la meme borne. La valeur vit ici et
/// nulle part ailleurs : une duree recopiee dans dix fonctions est une duree
/// qu'on ne peut plus raccourcir.
export const DUREE_LECTURE_SENSIBLE_S = 60

/// Duree d'une URL de depot.
///
/// Plus longue que la lecture, et voici pourquoi, puisque toute duree qui
/// s'ecarte de la regle doit se justifier : la borne `X-Amz-Expires` est
/// evaluee par R2 au moment ou la requete lui parvient, pas pendant son
/// deroulement. Elle borne donc le delai avant le DEBUT de l'envoi, non sa
/// duree. Cent vingt secondes couvrent la selection du fichier et sa lecture
/// sur un appareil lent sans jamais allonger la fenetre pendant laquelle une
/// URL interceptee reste utilisable.
export const DUREE_DEPOT_S = 120

/// Plafond de taille d'une piece deposee, en octets.
///
/// Repris tel quel du plafond que `service_dossier.dart` applique deja cote
/// client (8 Mio). Il est repete ici parce qu'un controle qui n'existe que dans
/// l'application n'est pas un controle : l'appelant d'une URL pre-signee n'est
/// pas force d'etre l'application.
export const TAILLE_MAXIMALE_PIECE_OCTETS = 8 * 1024 * 1024

/// Les types de contenu acceptes au depot d'une piece d'identite.
///
/// Liste fermee : un depot signe ne doit pas devenir un tunnel par lequel
/// n'importe quel contenu entre dans le coffre. Le type annonce par le client
/// est verifie contre cette liste, puis SIGNE -- R2 refusera alors un envoi qui
/// annonce autre chose que ce qui a ete signe.
export const TYPES_PIECE_IDENTITE: readonly string[] = [
  'image/jpeg',
  'image/png',
  'image/heic',
  'application/pdf',
]

// ============================================================
// Erreurs
// ============================================================

/// L'echec d'une operation de stockage, structure et sans fuite.
///
/// `ErreurStockageR2` est ce qui remonte aux points d'entree. Sa `classe` sert
/// aux journaux et au choix du code HTTP ; son `message` ne reprend jamais une
/// valeur de secret, une URL signee ni un fragment de chaine de requete.
export class ErreurStockageR2 extends Error {
  readonly classe: 'configuration' | 'signature' | 'validation'
  readonly domaine: DomaineStockage

  constructor(classe: 'configuration' | 'signature' | 'validation', domaine: DomaineStockage, message: string) {
    super(message)
    this.name = 'ErreurStockageR2'
    this.classe = classe
    this.domaine = domaine
  }
}

// ============================================================
// Signature
// ============================================================

/// Le client de signature d'un domaine.
///
/// Mis en cache par domaine : `AwsClient` derive une cle de signature a chaque
/// construction, et le refaire a chaque requete coute pour rien. Le cache ne
/// porte que des objets deja construits a partir des secrets ; il n'allonge la
/// duree de vie d'aucune valeur qui ne soit deja en memoire du processus.
const clients = new Map<DomaineStockage, { config: ConfigurationR2; aws: AwsClient }>()

function clientDe(domaine: DomaineStockage, env?: LecteurEnvironnement) {
  const enCache = clients.get(domaine)
  // L'injection d'environnement sert aux tests : elle court-circuite le cache
  // pour qu'un test n'herite pas de la configuration d'un autre.
  if (enCache && env === undefined) {
    return enCache
  }

  let config: ConfigurationR2
  try {
    config = configurationDe(domaine, env)
  } catch (e) {
    if (e instanceof ErreurConfigurationR2) {
      throw new ErreurStockageR2('configuration', domaine, e.message)
    }
    throw e
  }

  const aws = new AwsClient({
    accessKeyId: config.cleAcces,
    secretAccessKey: config.secretAcces,
    service: 's3',
    // R2 n'a pas de regions au sens S3 ; `auto` est la valeur que Cloudflare
    // impose dans sa chaine canonique.
    region: 'auto',
  })

  const entree = { config, aws }
  if (env === undefined) {
    clients.set(domaine, entree)
  }
  return entree
}

/// Efface le cache de clients. Reserve aux tests.
export function reinitialiserClients(): void {
  clients.clear()
}

function urlObjet(config: ConfigurationR2, cle: string): URL {
  const url = new URL(config.pointAcces.toString())
  // Chemin en style << path >> : `<endpoint>/<seau>/<cle>`. Le seau vient de la
  // configuration du domaine, jamais d'un parametre d'appel.
  url.pathname = `/${config.seau}/${cle}`
  return url
}

export interface OptionsLecture {
  readonly dureeSecondes?: number
  readonly env?: LecteurEnvironnement
}

// Pourquoi il n'y a PAS d'option << nom de fichier propose >> ici, alors
// qu'elle serait commode.
//
// Elle passerait par `response-content-disposition`, donc par un parametre de
// requete contenant des espaces. Or `URLSearchParams` encode l'espace en `+`,
// tandis que SigV4 impose l'encodage RFC 3986, ou l'espace s'ecrit `%20`. La
// chaine signee porterait `attachment%3B+filename...` quand R2 recalculerait
// sur `attachment%3B%20filename...` : signatures differentes, et **403 sur
// toute lecture**. Mesure faite le 21 septembre 2026 avec aws4fetch 1.0.20.
//
// Deux raisons de plus de s'en passer, une fois le piege connu : le nom qu'on
// aurait voulu proposer etait le type de la piece, que la convention de cles
// bannit precisement des chemins parce qu'il voyage en clair ; et une chaine
// de requete est exactement l'endroit ou une donnee finit dans un journal
// d'acces. Le client nomme le fichier qu'il telecharge, c'est son affaire.

/// Signe une lecture (GET) d'un objet deja autorisee.
///
/// L'appelant a DEJA obtenu l'accord metier avant d'arriver ici -- c'est la RPC
/// de son domaine qui l'a donne, et qui a journalise l'acces. Cette fonction ne
/// fait que transformer cet accord en URL bornee dans le temps.
///
/// La methode est GET et rien d'autre : elle entre dans la chaine canonique de
/// SigV4, donc l'URL produite ne peut pas servir a ecrire ni a supprimer.
export async function signerLecture(
  domaine: DomaineStockage,
  cle: string,
  options: OptionsLecture = {},
): Promise<{ url: string; expireDansSecondes: number }> {
  const { config, aws } = clientDe(domaine, options.env)
  const duree = options.dureeSecondes ?? DUREE_LECTURE_SENSIBLE_S
  exigerDureeSensee(domaine, duree)

  const url = urlObjet(config, cle)
  url.searchParams.set('X-Amz-Expires', String(duree))

  const signee = await signer(domaine, aws, url, 'GET')
  return { url: signee, expireDansSecondes: duree }
}

export interface OptionsDepot {
  readonly typeMime: string
  readonly tailleOctets: number
  readonly typesAutorises: readonly string[]
  readonly tailleMaximaleOctets: number
  readonly dureeSecondes?: number
  readonly env?: LecteurEnvironnement
}

/// Signe un depot (PUT) vers une cle fabriquee par le serveur.
///
/// Un depot pre-signe ne doit pas devenir un tunnel ouvert. Deux verrous, et
/// tous deux tiennent parce qu'ils entrent dans la signature :
///
///   * `content-type` est verifie contre une liste fermee, puis signe. R2
///     refuse alors un envoi qui annonce un autre type ;
///   * `content-length` est verifie contre le plafond, puis signe. Comme la
///     valeur signee doit correspondre a la taille reelle du corps, le porteur
///     de l'URL ne peut pas deposer davantage que ce qui a ete accorde.
///
/// Le type annonce par le client n'est jamais cru sur parole : il est CONTRAINT.
/// Ce qui est signe ici est ce que R2 exigera, pas ce que le client a dit.
export async function signerDepot(
  domaine: DomaineStockage,
  cle: string,
  options: OptionsDepot,
): Promise<{ url: string; enTetesExiges: Record<string, string>; expireDansSecondes: number }> {
  const typeMime = options.typeMime.trim().toLowerCase()
  if (!options.typesAutorises.includes(typeMime)) {
    throw new ErreurStockageR2('validation', domaine, 'type de contenu refuse')
  }
  if (!Number.isInteger(options.tailleOctets) || options.tailleOctets <= 0) {
    throw new ErreurStockageR2('validation', domaine, 'taille annoncee invalide')
  }
  if (options.tailleOctets > options.tailleMaximaleOctets) {
    throw new ErreurStockageR2('validation', domaine, 'taille annoncee au-dela du plafond')
  }

  const { config, aws } = clientDe(domaine, options.env)
  const duree = options.dureeSecondes ?? DUREE_DEPOT_S
  exigerDureeSensee(domaine, duree)

  const url = urlObjet(config, cle)
  url.searchParams.set('X-Amz-Expires', String(duree))

  const enTetesExiges = {
    'content-type': typeMime,
    'content-length': String(options.tailleOctets),
  }

  const signee = await signer(domaine, aws, url, 'PUT', enTetesExiges)
  return { url: signee, enTetesExiges, expireDansSecondes: duree }
}

function exigerDureeSensee(domaine: DomaineStockage, duree: number): void {
  // SigV4 plafonne `X-Amz-Expires` a sept jours ; on reste tres en deca, mais
  // une duree negative ou absurde doit echouer ici plutot que de produire une
  // URL que R2 refusera sans explication.
  if (!Number.isInteger(duree) || duree < 1 || duree > 3600) {
    throw new ErreurStockageR2('validation', domaine, 'duree de validite hors bornes')
  }
}

async function signer(
  domaine: DomaineStockage,
  aws: AwsClient,
  url: URL,
  methode: 'GET' | 'PUT',
  enTetes?: Record<string, string>,
): Promise<string> {
  try {
    const requete = await aws.sign(url.toString(), {
      method: methode,
      headers: enTetes,
      aws: {
        // La signature voyage dans la chaine de requete : c'est ce qui fait une
        // URL pre-signee plutot qu'un appel authentifie.
        signQuery: true,
        // Sans ceci, `aws4fetch` ecarte `content-type` et `content-length` de la
        // liste des en-tetes signes -- et les deux verrous du depot tomberaient
        // en silence, ce qui est la pire facon de les perdre.
        allHeaders: enTetes !== undefined,
      },
    })

    // Garde contre le retour du piege decrit plus haut : un `+` dans la chaine
    // de requete signifie qu un parametre a ete encode a la maniere des
    // formulaires et non selon RFC 3986. R2 recalculerait alors une signature
    // differente, et rendrait un 403 que rien n expliquerait. Mieux vaut
    // echouer ici, ou la cause est lisible.
    const requeteSignee = requete.url.slice(requete.url.indexOf('?'))
    if (requeteSignee.includes('+')) {
      throw new Error('parametre encode en + au lieu de %20')
    }

    return requete.url
  } catch (e) {
    // L'erreur d'origine reste dans le journal du serveur, jamais dans la
    // reponse : une trace de bibliotheque de signature peut porter des
    // fragments de la chaine canonique.
    console.error('signature R2 impossible', {
      domaine,
      methode,
      classe: (e as Error)?.name ?? 'inconnue',
    })
    throw new ErreurStockageR2('signature', domaine, 'signature impossible')
  }
}

/// Demande a R2 si un objet existe, sans le telecharger.
///
/// Sert a une seule chose, et elle compte : rendre la confirmation d'un depot
/// VRAIE. Sans elle, << j'ai fini d'envoyer >> ne serait qu'une declaration du
/// client, et une piece annoncee mais jamais deposee entrerait dans la file de
/// validation de l'administration, qui ouvrirait un document inexistant.
///
/// C'est un HEAD : R2 rend les en-tetes, jamais le corps. Aucun octet de piece
/// d'identite ne transite par le serveur.
export async function objetExiste(
  domaine: DomaineStockage,
  cle: string,
  env?: LecteurEnvironnement,
): Promise<boolean> {
  const { config, aws } = clientDe(domaine, env)
  const url = urlObjet(config, cle)

  let reponse: Response
  try {
    reponse = await aws.fetch(url.toString(), { method: 'HEAD' })
  } catch (e) {
    console.error('verification d objet impossible', {
      domaine,
      classe: (e as Error)?.name ?? 'inconnue',
    })
    throw new ErreurStockageR2('signature', domaine, 'verification impossible')
  }

  if (reponse.status === 200) {
    return true
  }
  // R2 repond `AccessDenied` la ou S3 dirait `NoSuchBucket`, et un 403 peut
  // donc signifier aussi bien << absent >> que << pas le droit >>. Un 404 est
  // franc ; tout le reste est une panne, pas une absence, et le confondre avec
  // une absence ferait echouer des depots legitimes en silence.
  if (reponse.status === 404) {
    return false
  }
  console.error('verification d objet : reponse inattendue', {
    domaine,
    statut: reponse.status,
  })
  throw new ErreurStockageR2('signature', domaine, 'verification impossible')
}

// ============================================================
// Observabilite
// ============================================================

/// Ce qu'un journal a le droit de porter au sujet d'une operation de stockage.
///
/// La liste est exhaustive et fermee. Ne peuvent pas y entrer : une URL
/// pre-signee, une chaine de requete de signature, un secret, le contenu d'un
/// objet, une piece d'identite, un texte prive, une donnee personnelle dont
/// l'exploitation n'a pas besoin.
export interface TraceStockage {
  readonly domaine: DomaineStockage
  readonly operation: 'lecture' | 'depot'
  readonly statut: 'accorde' | 'refuse' | 'echec'
  readonly ressource?: string
  readonly correlation?: string
  readonly classeErreur?: string
  readonly dureeMs?: number
}

export function journaliser(trace: TraceStockage): void {
  console.log('stockage', trace)
}

/// Ce qu'un client a le droit d'apprendre d'un echec.
///
/// Un echec de configuration et un echec de signature disent tous deux
/// << indisponible >> : la difference interesse l'exploitant, pas l'appelant, et
/// la lui donner renseignerait sur l'etat interne du trousseau.
export function messagePourClient(e: unknown): { message: string; statut: number } {
  if (e instanceof ErreurStockageR2) {
    if (e.classe === 'validation') {
      return { message: 'depot refuse', statut: 400 }
    }
    return { message: 'stockage indisponible', statut: 503 }
  }
  return { message: 'stockage indisponible', statut: 503 }
}
