// Ouvre le paiement d'une recharge chez le prestataire (FI-BR-06, guide
// Finance V4 §1.6 : `WEB_STRIPE` actif au lancement).
//
// Depuis le 01/11/2026 (directeur : « le paiement doit se faire sur l'app,
// pas de sortir ailleurs »), le formulaire de Stripe se monte dans la page
// de l'application : la reponse porte le secret client et la cle publiable.
// Sans cle publiable du meme mode (`STRIPE_PUBLISHABLE_KEY`), repli sur la
// page hebergee, comme avant.
//
// 1. Avec le jeton de l'appelant, `recharge_payer` cree (ou rend, pour la
//    meme cle) la commande : seul le titulaire du foyer y arrive, et le
//    montant de chaque part a ete arrete par le serveur.
// 2. Si la commande attend deja le prestataire, le meme paiement est rendu
//    (reprise apres une coupure : jamais deux paiements) : la page hebergee
//    telle quelle, ou le secret client de la meme session integree, relu
//    chez Stripe tant qu'elle est ouverte.
// 3. Sinon, la session Checkout s'ouvre chez Stripe, idempotente par
//    l'identifiant de la commande, puis `recharge_attacher_session` (cle de
//    service) la note sur la commande, qui attend alors la confirmation.
//
// PAY-UX (constats du directeur du 02/11/2026) : chaque nouveau depart
// ouvre un formulaire NEUF. Une commande qui attend deja le prestataire avec
// une session integree : l'ancienne session est relue ; payee (`complete`),
// rien ne change et la page de resultat dit l'etat ; ouverte, elle est
// expiree chez Stripe AVANT qu'une nouvelle soit creee et notee sur la
// commande (`recharge_remplacer_session`) ; si l'expiration echoue, rien
// n'est cree et la reponse le dit (jamais deux sessions ouvertes). Le webhook
// ne credite que la session notee sur la commande, une seule fois.
// Le nom des lignes dit ce qu'on paie (`nomLigne`), jamais un prenom, et le
// formulaire prend le fond de la page de l'application (`fond`).
//
// Rien n'est credite ici : seul le webhook signe (`stripe-webhook`) credite.
// Le retour du navigateur ramene a la page de resultat, qui relit l'etat.

import { clientAuthentifie, clientService, enTetesCors, json, refus } from '../_shared/clients.ts'
import {
  clientStripe,
  couleurFond,
  creerSession,
  fermerAncienneSession,
  formeDemandee,
  formulaireIntegrePossible,
  type LignePaiement,
  MARQUE_INTEGRE,
  nomLigne,
  parametresSession,
  retourAutorise,
  sessionIntegree,
} from '../_shared/stripe.ts'

/// GAINS (pilote et garde-cap, 06/11/2026) : l'appelant lu dans son jeton,
/// signature verifiee par `auth.getClaims` (supabase.com/docs/reference/
/// javascript/auth-getclaims : verification locale par le JWKS en cache avec
/// une cle asymetrique ; avec une cle symetrique HS256, `getClaims` appelle
/// lui-meme `getUser`, sans gain mais sans perte). Jamais un decodage sans
/// verification. Le compte reste controle par le serveur (`recharge_payer`
/// et ses gardes), comme avant.
export async function identiteVerifiee(
  auth: {
    getClaims(jeton: string): Promise<{
      data: { claims: { sub?: unknown; email?: unknown } } | null
      error: unknown
    }>
  },
  entete: string | null,
): Promise<{ id: string; email: string | null } | null> {
  if (!entete?.startsWith('Bearer ')) return null
  const jeton = entete.slice('Bearer '.length).trim()
  if (!jeton) return null
  const { data, error } = await auth.getClaims(jeton)
  if (error || !data) return null
  const { sub, email } = data.claims
  if (typeof sub !== 'string' || sub.length === 0) return null
  return { id: sub, email: typeof email === 'string' && email.length > 0 ? email : null }
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

/// La page de paiement expire au bout de 30 minutes (minimum de Stripe) : une
/// commande abandonnee se lit ensuite « perimee », jamais « en cours ».
const DUREE_PAGE_S = 30 * 60

/// La marque que l'adresse de retour porte a la place de la commande.
const MARQUE_COMMANDE = 'COMMANDE_ID'

/// Le traitement d'une requete ; exporte pour les tests (aucun serveur lance
/// a l'import, comme `stripe-webhook`).
export async function gerer(requete: Request): Promise<Response> {
  if (requete.method === 'OPTIONS') return new Response('ok', { headers: enTetesCors })
  if (requete.method !== 'POST') return refus('methode non autorisee', 405)

  const cleSecrete = Deno.env.get('STRIPE_SECRET_KEY')
  if (!cleSecrete) return refus('paiement indisponible', 503)
  const clePublique = Deno.env.get('STRIPE_PUBLISHABLE_KEY')
  const integre = formulaireIntegrePossible(cleSecrete, clePublique)

  const utilisateur = clientAuthentifie(requete)
  if (!utilisateur) return refus('authentification requise', 401)

  let corps: Record<string, unknown>
  try {
    const valeur: unknown = await requete.json()
    if (!valeur || typeof valeur !== 'object' || Array.isArray(valeur)) return refus('corps invalide')
    corps = valeur as Record<string, unknown>
  } catch {
    return refus('corps illisible')
  }
  // GAINS : un appel de chauffe a l'ouverture de la page de recharge. Il
  // reveille la fonction (le pre-vol et le demarrage a froid coutaient 2,6 s
  // le 06/11 a 13:28) et ne cree rien : ni commande, ni session Stripe.
  if (corps.chauffer === true) return json({ chaud: true })
  const recapitulatif = typeof corps.recapitulatifId === 'string' ? corps.recapitulatifId : ''
  const cle = typeof corps.cle === 'string' ? corps.cle : ''
  const retourBase = typeof corps.retour === 'string' ? corps.retour : ''
  // PAY-UX : le fond de la page autour du formulaire, et la langue des lignes.
  const fond = couleurFond(corps.fond)
  const langue = corps.langue === 'ar' ? 'ar' : 'fr'
  // LINK-CHOIX : la forme du formulaire ; sans champ, l'actuelle.
  const forme = formeDemandee(corps.forme)
  if (!UUID.test(recapitulatif) || !UUID.test(cle)) return refus('recapitulatif ou cle invalide')
  if (!retourBase.includes(MARQUE_COMMANDE) || !retourAutorise(retourBase, Deno.env.get('APP_ORIGINES'))) {
    return refus('adresse de retour refusee')
  }

  const { data, error } = await utilisateur.rpc('recharge_payer', {
    p_recapitulatif: recapitulatif,
    p_cle: cle,
  })
  if (error || !data || typeof data !== 'object') {
    const statut = error?.code === '42501' ? 403 : error?.code === 'P0002' ? 404 : 400
    return refus('recharge refusee', statut)
  }
  const commande = data as Record<string, unknown>
  const commandeId = String(commande.commandeId)
  const etat = String(commande.etat)

  // La session a remplacer, pour un nouveau depart sur une commande deja en
  // attente du prestataire (formulaire integre seulement).
  let ancienne: string | null = null
  if (etat === 'awaiting_confirmation' && typeof commande.urlPaiement === 'string') {
    const sessionId = sessionIntegree(commande.urlPaiement)
    if (sessionId === null) {
      if (commande.urlPaiement.startsWith(MARQUE_INTEGRE)) return json({ commandeId, url: null })
      return json({ commandeId, url: commande.urlPaiement })
    }
    if (!integre || !clePublique) return json({ commandeId, url: null })
    try {
      if (await fermerAncienneSession(clientStripe(cleSecrete).checkout.sessions, sessionId) === 'payee') {
        // Deja payee : jamais d'expiration ni de nouvelle session ; la page
        // de resultat relit l'etat (le webhook credite).
        return json({ commandeId, url: null, payee: true })
      }
    } catch (e) {
      // Expiration refusee (la session vient d'etre payee, ou Stripe ne
      // repond pas) : rien n'est cree, aucune seconde session ouverte.
      console.error('ancienne session non fermee', { commandeId, erreur: (e as Error).message })
      return refus('ancienne session non fermee', 409)
    }
    ancienne = sessionId
  } else if (etat !== 'preparing') {
    // Deja confirmee, echouee ou perimee : la page de resultat le dit.
    return json({ commandeId, url: null })
  }

  const qui = await identiteVerifiee(utilisateur.auth, requete.headers.get('Authorization'))
  if (!qui) return refus('authentification requise', 401)

  const total = commande.total as { devise: string }
  const lignes = (commande.lignesPaiement as LignePaiement[] | null) ?? []
  // L'application envoie l'adresse de sa page de resultat avec la marque
  // COMMANDE_ID a la place de la commande, qu'elle ne connait pas encore.
  const retour = retourBase.replace(MARQUE_COMMANDE, commandeId)

  let session
  try {
    session = await creerSession(
      clientStripe(cleSecrete),
      parametresSession({
        commandeId,
        reference: String(commande.reference),
        devise: total.devise,
        lignes,
        retour,
        libelle: (ligne) => nomLigne(ligne, langue),
        expireA: Math.floor(Date.now() / 1000) + DUREE_PAGE_S,
        integre,
        forme,
        fond,
      }),
      // Une cle par forme : une session hebergee deja ouverte avant ce lot
      // ne se rejoue jamais en integree avec d'autres parametres. Une
      // nouvelle session apres l'expiration de [ancienne] a sa propre cle,
      // stable : une reprise apres coupure rend la meme nouvelle session.
      ancienne !== null
        ? `recharge-${commandeId}-${forme === 'elements' ? 'elements' : 'integre'}-apres-${ancienne}`
        : !integre
        ? `recharge-${commandeId}`
        : forme === 'elements'
        ? `recharge-${commandeId}-elements-v1`
        : `recharge-${commandeId}-integre-v2`,
    )
  } catch (e) {
    console.error('session stripe refusee', { commandeId, erreur: (e as Error).message })
    return refus('paiement indisponible', 502)
  }

  const { error: attache } = ancienne !== null
    ? await clientService().rpc('recharge_remplacer_session', {
      p_commande: commandeId,
      p_titulaire: qui.id,
      p_ancienne: ancienne,
      p_session: session.id,
      p_url: `${MARQUE_INTEGRE}${session.id}`,
      p_environnement: session.environnement,
    })
    : await clientService().rpc('recharge_attacher_session', {
      p_commande: commandeId,
      p_titulaire: qui.id,
      p_session: session.id,
      p_url: session.url ?? `${MARQUE_INTEGRE}${session.id}`,
      p_environnement: session.environnement,
    })
  if (attache) {
    console.error('session non attachee', { commandeId, erreur: attache.message })
    return refus('paiement indisponible', 502)
  }
  if (session.secretClient) {
    // LINK-CHOIX : la forme rendue, pour que la page monte le bon formulaire.
    // En `elements`, Stripe exige une adresse a la confirmation : celle du
    // compte, que la page ne passe qu'au moment de payer (jamais a
    // l'ouverture, pour que Link ne reconnaisse personne avant un choix).
    return json({
      commandeId,
      url: null,
      secretClient: session.secretClient,
      clePublique,
      forme,
      ...(forme === 'elements' && qui.email ? { email: qui.email } : {}),
    })
  }
  return json({ commandeId, url: session.url })
}

if (import.meta.main) Deno.serve(gerer)
