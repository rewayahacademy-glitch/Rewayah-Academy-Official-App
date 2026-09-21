// Le point de bascule de l'ADR-001.
//
//   { session_id }  ->  { ws_url, token, room_name, provider, capabilities, expire_le }
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
  signerJeton,
  urlDe,
  videoConfiguree,
} from '../_shared/livekit.ts'

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

  const service = clientService()

  // La cle de service contourne la RLS, elle ne remplace pas le controle :
  // c'est la fonction appelee qui reverifie l'appartenance, la fenetre horaire
  // et le statut de la seance, et qui refuse par exception.
  const { data, error } = await service.rpc('autoriser_jeton_video', {
    p_session_id: seance,
    p_profile_id: compte.id,
    p_ws_url_cloud: urlDe('cloud'),
    p_ws_url_self_hosted: urlDe('self_hosted'),
  })

  if (error || !data) {
    // Codes metier limites a un participant verifie par la RPC. Aucun detail SQL.
    if (error?.message === 'photo_identification_requise') {
      return json({
        error: 'Ajoutez la photo d’identification pour rejoindre le cours.',
        code: 'photo_identification_requise',
      }, 403)
    }
    if (error?.message === 'conformite_enseignant_requise') {
      return json({
        error: 'Completez la verification et acceptez le contrat enseignant.',
        code: 'conformite_enseignant_requise',
      }, 403)
    }
    // Le motif exact reste dans les logs. Un appelant qui tente une salle qui
    // n'est pas la sienne n'a pas a apprendre si elle existe, si elle est
    // commencee, ou s'il est simplement en avance.
    console.error('autoriser_jeton_video refuse', { seance, erreur: error?.message })
    return refus('acces a la salle refuse', 403)
  }

  const autorisation = data as unknown as AutorisationVideo

  let jeton: string
  try {
    jeton = await signerJeton(autorisation)
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
    capabilities: autorisation.capabilities,
  })
})
