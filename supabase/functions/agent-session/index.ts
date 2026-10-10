// Echange un jeton d'observation (`rag_...`) contre une session d'agent
// (ADR-025). C'est le SEUL endroit du systeme qui fabrique une session d'agent.
//
// **Volontairement autonome**, alors que les autres fonctions Edge partagent
// `_shared/clients.ts` : c'est la seule fonction du projet qui signe une
// identite. Un changement dans un fichier partage pourrait en modifier la
// signature sans que personne ne relise ce fichier-ci. Meme raison que la regle
// de l'ADR-001 pour LiveKit -- on concentre, pour que la regle se verifie d'un
// seul `grep` plutot que par relecture.
//
// Ce que cette fonction signe, et pourquoi chaque claim y est :
//
//   * `sub` = **la personne observee**, pas un compte de service. C'est tout
//     l'edifice : les policies et les vues de ce depot se bornent deja par
//     `auth.uid()`, `app_household_id()` et `app_role()`. En signant avec
//     l'identifiant de la personne observee, l'agent herite de son ecran --
//     exactement, ni plus ni moins -- sans qu'une seule regle de securite soit
//     reecrite pour lui. Une deuxieme regle serait une regle a maintenir, et
//     donc une regle qui divergerait.
//
//   * `role` = **`agent_ro`**. PostgREST bascule sur le role Postgres nomme par
//     ce claim. `agent_ro` ne detient AUCUN droit d'ecriture : la lecture seule
//     est un defaut de privilege du moteur, pas une politesse de l'interface.
//     Un agent qui rejoue la requete a la main avec curl obtient le meme refus
//     que celui qui clique.
//
//   * `app_metadata.agent_token_id` = **un identifiant opaque**, jamais des
//     droits. La portee (qui est observe, sous quel parcours, avec ou sans
//     identite) se relit EN BASE a chaque requete, par le garde
//     `agent_pre_request()`. C'est ce qui rend la revocation immediate au lieu
//     d'attendre l'expiration de la signature.
//
// Le jeton signe vit QUINZE MINUTES, et il n'y a pas de jeton de
// rafraichissement. Un porteur qui veut continuer repasse par ici, donc par la
// base, donc par la verification de vivacite. La lecon vient de l'autre produit
// de l'operateur : un `refresh_token` remis a un tiers regenere des sessions
// indefiniment, et revoquer la ligne ne coupe alors plus rien.

import { SignJWT } from 'npm:jose@5.9.6'
import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2'

/// Duree d'une session signee. Volontairement courte : c'est le delai maximal
/// entre une revocation et sa prise d'effet dans le pire cas ou le garde
/// central ne serait pas atteint.
const DUREE_SESSION_SECONDES = 15 * 60

const enTetesCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

function json(corps: unknown, statut = 200): Response {
  return new Response(JSON.stringify(corps), {
    status: statut,
    headers: { ...enTetesCors, 'Content-Type': 'application/json' },
  })
}

/// Un refus. Le message reste court et ne dit jamais pourquoi une valeur est
/// invalide : « jeton inconnu » et « jeton expire » se distinguent pour le
/// porteur legitime, pas pour celui qui essaie.
function refus(message: string, statut = 400): Response {
  return json({ error: message }, statut)
}

/// Le client qui detient la cle de service. Jamais expose au navigateur.
///
/// Regle non negociable de l'etape 1 : **une fonction qui emploie la cle de
/// service reverifie l'autorisation metier explicitement.** Ici, c'est
/// `remettre_session_agent()` qui la tient, en base.
function clientService(): SupabaseClient {
  const url = Deno.env.get('SUPABASE_URL')
  const cle = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!url || !cle) {
    throw new Error('configuration absente : SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY')
  }
  return createClient(url, cle, { auth: { persistSession: false } })
}

interface Remise {
  jeton_id: string
  profil_observe: string
  parcours: string
  foyer: string | null
  identite_masquee: boolean
  expire_le: string
}

/// Le nom du secret n'est PAS une coquille. La plateforme **refuse** tout secret
/// de fonction Edge dont le nom commence par `SUPABASE_` : ce prefixe lui est
/// reserve pour les variables qu'elle injecte elle-meme (`SUPABASE_URL`,
/// `SUPABASE_SERVICE_ROLE_KEY`, ...). Le sceau est donc depose sous
/// `ISSUPABASE_JWT_SECRET`. Ne pas « corriger » ce nom : le renommer en
/// `SUPABASE_...` rend la variable impossible a enregistrer, et la fonction
/// retomberait silencieusement sur « non configure ».
const NOM_SECRET = 'ISSUPABASE_JWT_SECRET'

function secretJwt(): Uint8Array {
  const secret = Deno.env.get(NOM_SECRET)
  // Un repli sur une valeur publique ne degrade pas un sceau, il le publie :
  // pas de valeur par defaut, pas de repli sur la cle anon.
  if (!secret || secret.length < 32) {
    throw new Error(`configuration absente : ${NOM_SECRET}`)
  }
  return new TextEncoder().encode(secret)
}

Deno.serve(async (requete) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }

  // Etat de configuration, sur le modele de `videoConfiguree()` (ADR-001) : il
  // dit si le sceau est en place, **jamais sa valeur**. Sans lui, une erreur de
  // configuration ne se decouvrirait qu'au premier jeton emis, c'est-a-dire au
  // pire moment -- exactement le defaut qui a laisse une cle factice en
  // production du 11 au 13 septembre sans un bruit.
  if (requete.method === 'GET') {
    let configure = false
    try {
      secretJwt()
      configure = true
    } catch {
      configure = false
    }
    return json({
      service: 'agent-session',
      configure,
      detail: configure
        ? 'Le sceau est en place : un jeton peut etre echange.'
        : `${NOM_SECRET} absent : aucun jeton ne peut ouvrir de session.`,
    })
  }

  if (requete.method !== 'POST') {
    return refus('methode non permise', 405)
  }

  let jeton: string
  try {
    const corps = await requete.json()
    jeton = typeof corps?.jeton === 'string' ? corps.jeton.trim() : ''
  } catch {
    return refus('corps illisible', 400)
  }
  if (!jeton) {
    return refus('jeton absent', 400)
  }

  const service = clientService()

  // La base tranche : elle seule voit les empreintes. Un refus ne dit jamais
  // POURQUOI -- inconnu, revoque et expire rendent le meme message, pour le
  // meme motif qu'en base.
  const { data, error } = await service.rpc('remettre_session_agent', { p_jeton: jeton })
  if (error || !data || (Array.isArray(data) && data.length === 0)) {
    return refus('jeton refuse', 401)
  }

  const remise = (Array.isArray(data) ? data[0] : data) as Remise

  // La session ne survit jamais au jeton qui l'a ouverte : si le jeton expire
  // dans trois minutes, la session expire dans trois minutes.
  const maintenant = Math.floor(Date.now() / 1000)
  const finJeton = Math.floor(new Date(remise.expire_le).getTime() / 1000)
  const expiration = Math.min(maintenant + DUREE_SESSION_SECONDES, finJeton)
  if (expiration <= maintenant) {
    return refus('jeton refuse', 401)
  }

  const url = Deno.env.get('SUPABASE_URL') ?? ''

  let signe: string
  try {
    signe = await new SignJWT({
      // Le role Postgres sur lequel PostgREST bascule. Tout tient a cette ligne.
      role: 'agent_ro',
      app_metadata: {
        role: remise.parcours,
        household_id: remise.foyer,
        agent_token_id: remise.jeton_id,
      },
      user_metadata: {},
      // Rend une session d'agent reconnaissable dans les journaux PostgREST
      // sans avoir a la relire en base.
      is_agent: true,
    })
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setSubject(remise.jeton_id)
      .setIssuer(`${url}/auth/v1`)
      .setAudience('authenticated')
      .setIssuedAt(maintenant)
      .setExpirationTime(expiration)
      .sign(secretJwt())
  } catch (e) {
    console.error('agent-session : signature impossible', e)
    return refus('service indisponible', 503)
  }

  return json({
    access_token: signe,
    token_type: 'bearer',
    expires_in: expiration - maintenant,
    expires_at: expiration,
    // De quoi afficher le bandeau d'observation sans relire la base.
    parcours: remise.parcours,
    identite_masquee: remise.identite_masquee,
    jeton_expire_le: remise.expire_le,
  })
})
