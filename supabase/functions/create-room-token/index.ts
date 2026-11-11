// Le point de bascule de l'ADR-001.
//
//   { session_id, eleve_id? }  ->  { ws_url, token, room_name, provider, capabilities, expire_le,
//                                    publication_differee }
//   { session_id, eleve_id?, action: 'retablir_publication' }
//                               ->  { retabli, publication_differee, enseignant_present }
//   { session_id, eleve_id?, action: 'verifier_salle' }
//                               ->  { salle: 'ouverte' | 'fermee', micros_fermes, reste_s }
//
// C'est ici, et nulle part ailleurs, que le client apprend a quel serveur se
// connecter. Le contrat de portabilite en decoule : **aucune URL LiveKit
// n'existe dans le code Flutter.** Changer de fournisseur, c'est changer une
// ligne de `video_config`, sans redeploiement d'application et sans passage par
// les stores.
//
// Ce que cette fonction ne fait pas, et c'est deliberе :
//
//   * elle ne decide aucune capacite -- `autoriser_jeton_video()` le fait en
//     base, la ou les roles, la RLS et l'appartenance a la seance sont sous la
//     main. Ici, le role de l'appelant serait un parametre recu, donc une
//     affirmation du client ;
//   * elle ne lit pas le `profile_id` dans le corps de la requete. Elle le lit
//     dans le jeton Supabase de l'appelant. Un identifiant recu du client est
//     une demande, pas une identite.

import { appelant, clientService, enTetesCors, json, refus } from '../_shared/clients.ts'
import {
  type AutorisationVideo,
  presenceEnseignant,
  retablirPublication,
  type RouteSalle,
  signerJeton,
  tenirFermeture,
  urlDe,
  videoConfiguree,
} from '../_shared/livekit.ts'
import {
  type DetailRefusSalle,
  estPanne,
  lireMotifSalle,
  motifHorsSeance,
  motifPersonnel,
} from '../_shared/motif_salle.ts'
import { doitDifferer, ROLE_QUI_ATTEND } from '../_shared/publication_differee.ts'
import { seanceDeLaSalle } from '../_shared/seance_salle.ts'

/// Le mode « filet » de MICRO-AVANT-ENSEIGNANT : voir plus bas.
const ACTION_RETABLIR = 'retablir_publication'

/// FERMETURE-SALLE (directeur, 11/11/2026, D-018) : l'application d'un
/// participant demande au serveur de relire la regle dans sa salle
/// (enseignant parti depuis trop longtemps, seance finie). **Le client ne
/// decide rien et n'affirme rien** : le serveur relit lui-meme qui est dans
/// la salle chez LiveKit, la marque qu'il y a posee et la seance en base
/// (`_shared/fermeture_salle.ts`), et applique a TOUTE la salle. Un seul
/// client honnete suffit donc a fermer les micros de tous ; aucun client ne
/// peut ni avancer ni retarder l'echeance. Si tous les clients se taisent, la
/// tache planifiee (`observation-coupure`) fait le meme passage chaque minute.
const ACTION_VERIFIER = 'verifier_salle'

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }

  // Tant qu'aucun trousseau n'est pose, la video n'est pas branchee. Le dire
  // franchement vaut mieux qu'une erreur de signature illisible : c'est l'etat
  // normal du produit entre la livraison de N2 et l'ouverture du compte
  // LiveKit.
  if (!videoConfiguree()) {
    return refus('video non configuree', 503)
  }

  const compte = await appelant(requete)
  if (!compte) {
    return refus('authentification requise', 401)
  }

  let corps: Record<string, unknown>
  try {
    corps = await requete.json()
  } catch {
    return refus('corps illisible')
  }

  const seance = String(corps.session_id ?? '').trim()
  if (!seance) {
    return refus('seance non precisee')
  }

  // D6 : un tuteur peut demander le jeton de son enfant, qui entre en salle
  // depuis l'appareil du tuteur. `eleve_id` est une demande : la base verifie
  // le foyer, l'inscription a la seance, et ne rend que le role eleve.
  const eleve = String(corps.eleve_id ?? '').trim()

  // Le mode de l'appel : absent, un jeton ; `retablir_publication`, le filet
  // de MICRO-AVANT-ENSEIGNANT (plus bas). Toute autre valeur est refusee
  // plutot qu'ignoree : un mode mal ecrit ne doit pas rendre un jeton.
  const action = String(corps.action ?? '').trim()
  if (action && action !== ACTION_RETABLIR && action !== ACTION_VERIFIER) {
    return refus('action inconnue')
  }

  const service = clientService()

  // La cle de service contourne la RLS, elle ne remplace pas le controle :
  // c'est la fonction appelee qui reverifie l'appartenance, la fenetre horaire
  // et le statut de la seance, et qui refuse par exception.
  const { data, error } = eleve
    ? await service.rpc('autoriser_jeton_video_eleve', {
      p_session_id: seance,
      p_tuteur_id: compte.id,
      p_eleve_id: eleve,
      p_ws_url_cloud: urlDe('cloud'),
      p_ws_url_self_hosted: urlDe('self_hosted'),
    })
    : await service.rpc('autoriser_jeton_video', {
      p_session_id: seance,
      p_profile_id: compte.id,
      p_ws_url_cloud: urlDe('cloud'),
      p_ws_url_self_hosted: urlDe('self_hosted'),
    })

  if (error || !data) {
    // Le motif exact reste dans les logs. Un appelant qui tente une salle qui
    // n'est pas la sienne n'a pas a apprendre si elle existe, si elle est
    // commencee, ou s'il est simplement en avance.
    console.error('autoriser_jeton_video refuse', { seance, eleve: eleve || null, erreur: error?.message })
    // SITUATIONS-GRAVES (11/11/2026) : une panne n'est pas un refus ; elle
    // se dit « la salle n'a pas pu s'ouvrir, reessayez » (statut 500).
    if (estPanne(error)) {
      return refus('salle momentanement indisponible', 500)
    }
    // SITUATIONS-GRAVES : le refus qui ne concerne que l'appelant dit sa
    // vraie raison (compte, acces suspendu, sorti, temps d'observation).
    const personnel = motifPersonnel(error?.message)
    if (personnel) {
      return json({ error: 'acces a la salle refuse', ...personnel }, 403)
    }
    // FN-025 : la raison, a qui y a droit seulement. La base en decide
    // (`motif_refus_salle`, participant, enseignant effectif ou tuteur d'un
    // eleve inscrit) ; pour tout autre appelant elle rend NULL et le refus
    // reste generique. Si la migration n'est pas encore posee (fonction
    // absente) ou si la lecture echoue, rien ne change : 403 generique.
    let detail: DetailRefusSalle | null = null
    try {
      const { data: motif, error: erreurMotif } = await service.rpc('motif_refus_salle', {
        p_session_id: seance,
        p_profile_id: compte.id,
        p_eleve_id: eleve || null,
      })
      if (erreurMotif) {
        console.error('motif_refus_salle indisponible', { seance, erreur: erreurMotif.message })
      } else {
        detail = lireMotifSalle(motif)
      }
    } catch (e) {
      console.error('motif_refus_salle en echec', { seance, erreur: (e as Error).message })
    }
    // SITUATIONS-GRAVES : sans motif de la base, une seance qui n'est pas
    // la sienne se dit « pas inscrit », la meme reponse qu'elle existe ou non.
    detail = detail ?? motifHorsSeance(error?.message)
    if (detail) {
      // FERMETURE-SALLE : la base vient de dire a quelqu'un qui y a droit
      // (`motif_refus_salle` ne repond qu'a un participant, a l'enseignant
      // effectif ou au tuteur d'un eleve inscrit) que la porte de cette
      // seance est fermee. S'il demandait la verification, c'est le moment de
      // relire la salle : seance finie et enseignant parti, elle est fermee
      // pour tous. Un echec ne change pas la reponse.
      let salleFermee = false
      if (action === ACTION_VERIFIER) {
        try {
          const { route, seance: vue } = await seanceDeLaSalle(service, { seanceId: seance })
          if (route) {
            const bilan = await tenirFermeture(route, vue)
            salleFermee = bilan.action === 'fermer_salle' && bilan.echecs.length === 0
          }
        } catch (e) {
          console.error('verification de la salle en echec', {
            seance,
            erreur: (e as Error).message,
          })
        }
      }
      return json({
        error: 'acces a la salle refuse',
        ...detail,
        ...(action === ACTION_VERIFIER ? { salle: salleFermee ? 'fermee' : 'ouverte' } : {}),
      }, 403)
    }
    return refus('acces a la salle refuse', 403)
  }

  const autorisation = data as unknown as AutorisationVideo
  const route: RouteSalle = {
    provider: autorisation.provider,
    ws_url: autorisation.ws_url,
    room_name: autorisation.room_name,
  }
  // MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026, defaut SEC-1) : seul un
  // eleve qui aurait le droit de publier est concerne. Pour tous les autres
  // roles, LiveKit n'est meme pas interroge.
  const concerne = autorisation.role === ROLE_QUI_ATTEND &&
    autorisation.capabilities.can_publish === true

  // FERMETURE-SALLE : la verification demandee par un participant qui a
  // encore droit a la salle (porte ouverte). Typiquement : un eleve dont
  // l'enseignant n'est plus la depuis le delai de grace. Aucun jeton n'est
  // signe ; la reponse dit seulement ou en est la salle.
  if (action === ACTION_VERIFIER) {
    try {
      const { seance: vue } = await seanceDeLaSalle(service, { seanceId: seance })
      const bilan = await tenirFermeture(route, vue)
      return json({
        salle: bilan.action === 'fermer_salle' && bilan.echecs.length === 0 ? 'fermee' : 'ouverte',
        micros_fermes: bilan.fermes.length,
        // Le temps avant l'echeance, quand un delai court : l'application
        // redemande la verification a ce moment-la.
        reste_s: bilan.resteMs === undefined ? null : Math.ceil(bilan.resteMs / 1000),
      })
    } catch (e) {
      console.error('verification de la salle en echec', {
        seance,
        erreur: (e as Error).message,
      })
      return refus('serveur video indisponible', 502)
    }
  }

  // Le filet : un client qui VOIT son enseignant dans la salle alors que son
  // propre droit de publier est encore ferme (webhook perdu ou en retard)
  // demande au serveur de le lui rendre. Le client ne decide rien : la base
  // vient de reverifier son droit a cette seance (meme fonction que pour un
  // jeton, donc compte, inscription, exclusion, suspension, fenetre), et
  // `retablirPublication` relit elle-meme chez LiveKit que l'enseignant est
  // la. Aucun jeton n'est signe.
  if (action === ACTION_RETABLIR) {
    if (!concerne) {
      return json({ retabli: false, publication_differee: false })
    }
    try {
      const bilan = await retablirPublication(route, {
        identite: autorisation.identity,
        droits: {
          micro: true,
          camera: autorisation.capabilities.can_publish_video === true,
        },
      })
      if (bilan.echecs.length > 0) {
        return refus('serveur video indisponible', 502)
      }
      return json({
        retabli: bilan.retablis.length > 0,
        // Vrai tant que le droit reste ferme : l'enseignant n'est pas la, ou
        // l'eleve n'est pas (encore) dans la salle.
        publication_differee: bilan.cibleOuverte !== true,
        enseignant_present: bilan.enseignant,
      })
    } catch (e) {
      console.error('retablissement de la publication en echec', {
        seance,
        erreur: (e as Error).message,
      })
      return refus('serveur video indisponible', 502)
    }
  }

  // Au jeton : l'enseignant est-il dans la salle ? S'il n'y est pas, le jeton
  // de l'eleve est signe sans droit de publier ; le webhook de l'entree de
  // l'enseignant (ou le filet ci-dessus) le lui rendra. Si LiveKit ne repond
  // pas, rien n'est differe : la classe parle (voir `publication_differee.ts`).
  const differe = concerne &&
    doitDifferer(autorisation.role, autorisation.capabilities, await presenceEnseignant(route))

  let jeton: string
  try {
    jeton = await signerJeton(autorisation, differe)
  } catch (e) {
    console.error('signature du jeton impossible', {
      fournisseur: autorisation.provider,
      erreur: (e as Error).message,
    })
    // Le trousseau du fournisseur retenu manque, alors que l'autre est peut-etre
    // pose. C'est une panne de configuration, pas un refus d'acces : le client
    // doit pouvoir la distinguer pour afficher le bon message.
    return refus('fournisseur video indisponible', 503)
  }

  return json({
    ws_url: autorisation.ws_url,
    token: jeton,
    room_name: autorisation.room_name,
    provider: autorisation.provider,
    role: autorisation.role,
    expire_le: (data as Record<string, unknown>).expire_le,
    // Les droits decides par la base : ceux que l'eleve a, ou qu'il aura.
    // Ils ne changent pas de sens, pour qu'une application pas encore mise a
    // jour garde son bouton (le serveur LiveKit, lui, refuse la publication
    // tant que `publication_differee` est vrai).
    capabilities: autorisation.capabilities,
    // Vrai : le jeton est signe sans droit de publier, en attendant
    // l'enseignant. L'application ne rend alors pas le bouton du micro et
    // dit pourquoi.
    publication_differee: differe,
  })
})
