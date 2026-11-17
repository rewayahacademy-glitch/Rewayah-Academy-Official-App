// PX-KYC-1 : lecture automatique des pieces d'identite en attente, par un modele de vision.
//
//   POST {}  ->  { traitees, lues, non_lues, ferme? }
//
// Plan : docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-KYC.md. ISOLEE de Praxis : aucune importation de `_shared/praxis`,
// aucun outil donne au modele, aucun texte libre.
//
// L'ordre des operations est le sujet de ce fichier :
//   1. l'appelant est la DIRECTION, en aal2, par SON jeton (`direction_kyc_lecture_lancer`) : la base refuse tout
//      autre appelant ET refuse tant que la lecture est fermee (reglage ferme par defaut, aucun genre envoye) ;
//   2. seulement alors la cle du fournisseur est lue (secret du serveur ; absente = 503, rien n'est envoye) ;
//   3. la file vient de la base : seules les pieces des GENRES DECIDES par le directeur, jamais deux fois la meme
//      version de consigne ;
//   4. chaque piece est lue, ecartee (HEIC, trop grande, introuvable) ou ecrite ; le nom du dossier ne sort jamais ;
//   5. la base calcule la proposition. Une panne du fournisseur ecrit « a verifier », JAMAIS « non conforme ».
//
// Aucune image, aucun nom, aucune cle ne passe dans un journal : une trace ne porte que des COMPTEURS et des classes.

import { clientAuthentifie, clientService, enTetesCors, json, refus } from '../_shared/clients.ts'
import { verifierCle } from '../_shared/r2/cles.ts'
import { signerLecture, DUREE_LECTURE_SENSIBLE_S } from '../_shared/r2/signature.ts'
import { creerFournisseurAnthropic } from '../_shared/kyc/fournisseur_anthropic.ts'
import {
  ErreurFournisseur,
  lireUnePiece,
  type PieceALire,
  VERSION_CONSIGNE,
  versBase,
} from '../_shared/kyc/lecture.ts'

/// Pieces par appel : la fonction Edge a un temps borne ; la direction relance pour la suite.
const PIECES_PAR_APPEL = 10
const SEAU_HISTORIQUE = 'kyc'

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') return new Response('ok', { headers: enTetesCors })
  if (requete.method !== 'POST') return refus('methode non autorisee', 405)

  const client = clientAuthentifie(requete)
  if (!client) return refus('authentification requise', 401)

  // 1. La porte : direction active, aal2, lecture ouverte.
  const { data: porte, error: erreurPorte } = await client.rpc('direction_kyc_lecture_lancer')
  if (erreurPorte) {
    console.error('lecture refusee', { classe: 'porte' })
    return refus('acces refuse', 403)
  }
  if (!porte || (porte as { ok?: boolean }).ok !== true) {
    return json({ traitees: 0, lues: 0, non_lues: 0, ferme: true })
  }

  // 2. La cle du fournisseur : un secret du serveur.
  const cle = Deno.env.get('ANTHROPIC_API_KEY')
  if (!cle) {
    console.error('lecture impossible', { classe: 'cle_absente' })
    return refus('lecture indisponible', 503)
  }
  const fournisseur = creerFournisseurAnthropic(cle)
  const service = clientService()

  // 3. La file.
  const { data: file, error: erreurFile } = await service.rpc('kyc_lecture_file', {
    p_version: VERSION_CONSIGNE,
    p_limite: PIECES_PAR_APPEL,
  })
  if (erreurFile || !file) {
    console.error('file illisible', { classe: 'file' })
    return refus('lecture indisponible', 503)
  }
  const modele = (file as { modele?: string }).modele
  const items = ((file as { items?: Array<Record<string, string>> }).items ?? []).map((i): PieceALire => ({
    documentId: i.documentId,
    objectKey: i.objectKey,
    stockage: i.stockage,
    nomDossier: i.nomDossier,
  }))
  if (!modele || items.length === 0) return json({ traitees: 0, lues: 0, non_lues: 0 })

  // 4 et 5. Chaque piece.
  let lues = 0
  let nonLues = 0
  for (const piece of items) {
    let resultat
    try {
      resultat = await lireUnePiece(piece, modele, {
        fournisseur,
        async lireOctets(p) {
          if (p.stockage === 'r2') {
            const signee = await signerLecture('pieceIdentite', verifierCle('pieceIdentite', p.objectKey), {
              dureeSecondes: DUREE_LECTURE_SENSIBLE_S,
            })
            const r = await fetch(signee.url)
            return r.ok ? new Uint8Array(await r.arrayBuffer()) : null
          }
          const { data, error } = await service.storage.from(SEAU_HISTORIQUE).download(p.objectKey)
          return error || !data ? null : new Uint8Array(await data.arrayBuffer())
        },
      })
    } catch (e) {
      if (e instanceof ErreurFournisseur && e.classe === 'configuration') {
        // La cle est refusee : inutile d'insister piece apres piece. On arrete, on le dit.
        console.error('lecture arretee', { classe: 'cle_refusee' })
        return json({ traitees: lues + nonLues, lues, non_lues: nonLues, arret: 'cle_refusee' }, 502)
      }
      console.error('lecture arretee', { classe: (e as Error)?.name ?? 'inconnue' })
      return json({ traitees: lues + nonLues, lues, non_lues: nonLues, arret: 'panne' }, 502)
    }
    const { error } = await service.rpc('kyc_lecture_ecrire', {
      p_document: piece.documentId,
      p_version: VERSION_CONSIGNE,
      p_modele: modele,
      p_resultat: versBase(resultat),
    })
    if (error) {
      console.error('ecriture refusee', { classe: 'ecriture' })
      continue
    }
    if (resultat.etat === 'lue') lues++
    else nonLues++
  }
  console.log('lecture automatique', { traitees: lues + nonLues, lues, non_lues: nonLues })
  return json({ traitees: lues + nonLues, lues, non_lues: nonLues })
})
