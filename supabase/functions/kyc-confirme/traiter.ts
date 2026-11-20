// FN-101, option B (garde-cap, 06/11/2026) : la seule porte qui confirme le
// CONTENU d'une piece d'identite deposee dans le seau Supabase `kyc`.
//
//   { object_key }  ->  { confirme: true }   |   422 contenu_non_conforme
//
// Pourquoi. L'application depose la piece dans le seau `kyc`, puis insere sa
// ligne `kyc_documents`. Le seau ne verifie que le type ANNONCE (liste fermee,
// 20261108400000) : un texte renomme en `.pdf` y entrait, et la direction
// recevait un dossier vide (parcours 1, piege 1.12, 31/10/2026). Le controle du
// contenu existait deja pour le coffre R2 (`piece-identite-confirme`), pas pour
// ce chemin.
//
// Ce que fait cette fonction, et rien d'autre :
//   1. l'appelant est lu dans son jeton, jamais dans le corps ;
//   2. la cle doit commencer par son identifiant (`<uid>/...`), comme l'exige
//      deja la policy de depot du seau : on ne confirme que ce qu'on a depose ;
//   3. le type vient de l'extension de la cle, dans la liste fermee de
//      `contenuConforme` (PDF, JPEG, PNG, HEIC ; le WebP est retire du
//      selecteur, il n'est pas ajoute ici) ;
//   4. AU PLUS les 16 premiers octets sont lus (`Range: bytes=0-15`, cle de
//      service), compares, puis oublies : ni conserves, ni journalises, ni
//      renvoyes ;
//   5. conforme : `kyc_confirmer_contenu()` pose la confirmation, que les
//      policies d'insertion de `kyc_documents` exigent desormais
//      (migration 20261110800000). Non conforme : rien n'est pose, la ligne ne
//      pourra pas etre inseree.
//
// La cle de service contourne la RLS, elle ne remplace pas le controle (regle
// de `_shared/clients.ts`) : le point 2 est ce controle.
//
// PE-B10 (20/11/2026) : le travail vit ici, le monde (jeton, secrets, lecture
// du seau, RPC) arrive par [Dependances], pour etre teste sans reseau. Deux
// statuts changent, rien d'autre : un service d'authentification injoignable
// rend 503 (et non 401), un echec de la RPC rend 503 (et non 403). Pendant la
// panne R19 du 15/11, ces 401 et 403 faisaient lire au candidat
// « reconnectez-vous » ou « ecrivez a la direction ».

import { enTetesCors, json, refus, type AppelantDetaille } from '../_shared/clients.ts'
import { contenuConforme, OCTETS_ENTETE } from '../_shared/r2/contenu_piece.ts'

/// Ce dont la fonction a besoin du monde, remplace dans les tests.
export interface Dependances {
  /// L'appelant lu dans son jeton, avec la raison d'un echec.
  appelant(requete: Request): Promise<AppelantDetaille>
  /// L'adresse du projet.
  url(): string | undefined
  /// La cle qui lit les 16 premiers octets de l'objet.
  cleLecture(): string | undefined
  /// La lecture de la tete de l'objet.
  fetch(url: string, init: RequestInit): Promise<Response>
  /// L'appel de `kyc_confirmer_contenu`.
  confirmer(deposePar: string, cle: string, type: string): Promise<{ error: { message: string } | null }>
}

/// Le type de contenu d'une extension, dans la liste fermee du controle.
const TYPES_PAR_EXTENSION: Readonly<Record<string, string>> = {
  pdf: 'application/pdf',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  heic: 'image/heic',
}

/// `<uuid>/<nom>.<extension>` : la forme des cles du depot de l'application.
const CLE = /^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\/[A-Za-z0-9._-]{1,120}$/

/// Traite une requete.
export async function traiter(requete: Request, dep: Dependances): Promise<Response> {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }
  if (requete.method !== 'POST') {
    return refus('methode non autorisee', 405)
  }

  // PE-B10 : 401 pour un jeton absent ou refuse ; 503 quand le service
  // d'authentification ne repond pas.
  const lu = await dep.appelant(requete)
  if (lu.etat === 'indisponible') {
    return refus('authentification indisponible', 503)
  }
  if (lu.etat !== 'ok') {
    return refus('authentification requise', 401)
  }
  const compte = { id: lu.id }

  let corps: Record<string, unknown>
  try {
    corps = await requete.json()
  } catch {
    return refus('corps illisible')
  }

  const cle = String(corps.object_key ?? '').trim()
  const forme = CLE.exec(cle)
  if (!forme || forme[1].toLowerCase() !== compte.id.toLowerCase()) {
    // Une cle d'un autre, ou d'une autre forme : on ne confirme que ses depots.
    return refus('cle refusee', 403)
  }
  const extension = cle.slice(cle.lastIndexOf('.') + 1).toLowerCase()
  const type = TYPES_PAR_EXTENSION[extension]
  if (!type) {
    return json({ error: 'contenu_non_conforme' }, 422)
  }

  const url = dep.url()
  const lecture = dep.cleLecture()
  if (!url || !lecture) {
    return refus('configuration absente', 503)
  }

  // Au plus 16 octets. Un objet absent n'est pas confirme.
  let octets: Uint8Array
  try {
    const reponse = await dep.fetch(
      `${url}/storage/v1/object/kyc/${cle.split('/').map(encodeURIComponent).join('/')}`,
      {
        headers: {
          Authorization: `Bearer ${lecture}`,
          apikey: lecture,
          Range: `bytes=0-${OCTETS_ENTETE - 1}`,
        },
      },
    )
    if (reponse.status === 404 || reponse.status === 400) {
      await reponse.body?.cancel()
      return refus('aucun objet depose sous cette cle', 409)
    }
    if (!reponse.ok) {
      await reponse.body?.cancel()
      return refus('lecture impossible', 502)
    }
    const tout = new Uint8Array(await reponse.arrayBuffer())
    // Un serveur qui ignorerait le Range rendrait tout : on ne garde que la tete.
    octets = tout.subarray(0, OCTETS_ENTETE)
  } catch (e) {
    console.error('lecture de la piece impossible', { classe: (e as Error)?.name ?? 'inconnue' })
    return refus('lecture impossible', 502)
  }

  if (!contenuConforme(type, octets)) {
    return json({ error: 'contenu_non_conforme' }, 422)
  }

  // PE-B10 : `kyc_confirmer_contenu` n'a aucun refus metier atteignable ici
  // (la cle et le type viennent d'etre controles) : un echec de l'appel est
  // une panne de la base, dite 503, jamais un refus (403) qui ferait ecrire
  // la personne a la direction pour rien.
  let echec: { message: string } | null
  try {
    echec = (await dep.confirmer(compte.id, cle, type)).error
  } catch (e) {
    echec = { message: (e as Error)?.name ?? 'inconnue' }
  }
  if (echec) {
    console.error('confirmation impossible', { erreur: echec.message })
    return refus('confirmation indisponible', 503)
  }
  return json({ confirme: true })
}
