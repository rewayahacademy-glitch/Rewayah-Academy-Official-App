// Le SEUL fichier du depot autorise a importer le SDK serveur LiveKit.
//
// Regle posee par l'ADR-001 et reprise telle quelle : la cle API et son secret
// ne quittent jamais les secrets Supabase, et aucune autre fonction Edge n'a le
// droit de fabriquer un jeton. Concentrer cela ici rend la regle verifiable
// d'un seul `grep` plutot que par relecture.
//
// Pourquoi le SDK officiel plutot qu'un JWT signe a la main : la section 4 de
// la specification l'impose (« ne te contente jamais d'une memoire approximative
// de l'API »), et surtout les claims LiveKit evoluent avec les versions --
// `canPublishSources` n'existait pas au debut, `roomJoin` a change de forme.
// Un jeton fabrique de memoire marche le jour ou on l'ecrit et casse a la
// montee de version suivante, sans prevenir.

import { AccessToken, WebhookReceiver } from 'npm:livekit-server-sdk@2.13.1'

/// Les deux fournisseurs coexistent (decision de l'operateur du 12 septembre
/// 2026 : Cloud pour eprouver, self-host pour encaisser, jamais Cloud seul).
/// Chacun a son trousseau ; la base dit lequel s'applique a une seance donnee.
export type Fournisseur = 'cloud' | 'self_hosted'

/// Ce que la base a decide, et que cette couche se contente de signer.
export interface AutorisationVideo {
  ws_url: string
  room_name: string
  provider: Fournisseur
  identity: string
  role: string
  ttl_seconds: number
  capabilities: {
    can_publish: boolean
    can_publish_video: boolean
    can_publish_data: boolean
    can_subscribe: boolean
    hidden: boolean
  }
}

interface Trousseau {
  cle: string
  secret: string
}

/// Lit le trousseau d'un fournisseur. Les noms sont explicites parce qu'il y en
/// a deux : `LIVEKIT_API_KEY` tout court serait ambigu le jour de la bascule.
function trousseau(fournisseur: Fournisseur): Trousseau {
  const prefixe = fournisseur === 'cloud' ? 'LIVEKIT_CLOUD' : 'LIVEKIT_SELFHOST'
  const cle = Deno.env.get(`${prefixe}_API_KEY`)
  const secret = Deno.env.get(`${prefixe}_API_SECRET`)
  if (!cle || !secret) {
    throw new Error(`configuration absente : ${prefixe}_API_KEY ou ${prefixe}_API_SECRET`)
  }
  return { cle, secret }
}

/// L'URL de repli d'un fournisseur, quand la base n'impose pas d'`ws_url_override`.
export function urlDe(fournisseur: Fournisseur): string {
  const nom = fournisseur === 'cloud' ? 'LIVEKIT_CLOUD_WS_URL' : 'LIVEKIT_SELFHOST_WS_URL'
  return Deno.env.get(nom) ?? ''
}

/// Vrai quand au moins un fournisseur est configure. Sert a repondre
/// proprement « la video n'est pas encore branchee » plutot qu'a exploser.
export function videoConfiguree(): boolean {
  return (
    (!!Deno.env.get('LIVEKIT_CLOUD_API_KEY') && !!Deno.env.get('LIVEKIT_CLOUD_API_SECRET')) ||
    (!!Deno.env.get('LIVEKIT_SELFHOST_API_KEY') && !!Deno.env.get('LIVEKIT_SELFHOST_API_SECRET'))
  )
}

/// Signe le jeton que le client presentera a LiveKit.
///
/// **Cette fonction ne decide rien.** Elle transcrit ce que
/// `autoriser_jeton_video()` a deja tranche en base. Si une capacite devait se
/// calculer ici, elle serait calculee dans un endroit ou la RLS, les roles et
/// l'appartenance a la seance ne sont plus sous la main -- c'est-a-dire au
/// mauvais endroit.
export async function signerJeton(a: AutorisationVideo): Promise<string> {
  const { cle, secret } = trousseau(a.provider)

  const jeton = new AccessToken(cle, secret, {
    identity: a.identity,
    ttl: a.ttl_seconds,
    // Le role voyage en metadonnee : la salle en a besoin pour placer
    // l'enseignant au centre sans redemander la base a chaque rendu.
    metadata: JSON.stringify({ role: a.role }),
  })

  // `canPublishSources` borne ce qu'un participant peut publier, source par
  // source. C'est lui qui realise `camera_policy = 'forbidden'` : l'eleve garde
  // le micro et perd la camera, sans que l'interface ait a y veiller.
  const sources: ('microphone' | 'camera' | 'screen_share')[] = []
  if (a.capabilities.can_publish) {
    sources.push('microphone')
    if (a.capabilities.can_publish_video) sources.push('camera')
  }

  jeton.addGrant({
    room: a.room_name,
    roomJoin: true,
    canPublish: a.capabilities.can_publish,
    canSubscribe: a.capabilities.can_subscribe,
    canPublishData: a.capabilities.can_publish_data,
    canPublishSources: sources,
    // L'observation invisible de `CTR-02`, decidee en base et appliquee par le
    // serveur : le controleur n'apparait dans la liste de personne.
    hidden: a.capabilities.hidden,
  })

  return await jeton.toJwt()
}

/// Verifie la signature d'un webhook LiveKit et rend l'evenement.
///
/// Un webhook non signe, ou signe par une cle inconnue, n'est pas un evenement
/// douteux : c'est quelqu'un qui fabrique des presences. Il est refuse.
///
/// Les deux trousseaux sont essayes parce que les deux fournisseurs tournent en
/// parallele : une salle sur le serveur auto-heberge est annoncee par le
/// trousseau self-host, pas par celui du Cloud.
export async function verifierWebhook(
  corps: string,
  entete: string | null,
): Promise<Record<string, unknown>> {
  if (!entete) {
    throw new Error('webhook non signe')
  }

  const candidats: Fournisseur[] = ['cloud', 'self_hosted']
  let derniereErreur: unknown = new Error('aucun fournisseur configure')

  for (const fournisseur of candidats) {
    let cles: Trousseau
    try {
      cles = trousseau(fournisseur)
    } catch (e) {
      derniereErreur = e
      continue
    }
    try {
      const receveur = new WebhookReceiver(cles.cle, cles.secret)
      return (await receveur.receive(corps, entete)) as unknown as Record<string, unknown>
    } catch (e) {
      derniereErreur = e
    }
  }

  throw derniereErreur
}
