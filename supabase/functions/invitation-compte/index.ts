// INVITATION-SECOND-ADULTE (07/11/2026) : la creation du compte d'une adresse
// invitee alors que les inscriptions sont fermees au niveau de l'instance
// Auth. Une seule fonction pour les quatre chemins : foyer (second
// adulte), enseignant, comptable (ou `equipe`, code recopie sans savoir
// lequel), candidat d'un formulaire importe (code du courriel lien_inscription).
//
// Publique (verify_jwt = false) : la personne invitee n'a pas encore de
// compte. Elle envoie le type, le code de son e-mail et son adresse.
// 1. Debit : cinq demandes par heure au plus, par adresse ET par IP
//    (`invitation_compte_debit`, journal par empreintes).
// 2. Autorisation : `invitation_compte_autoriser` (service_role seul) n'est
//    vraie que pour un code valide, non utilise, non revoque, non echu, emis
//    pour cette adresse, et une adresse sans compte ; le code d'un foyer y
//    est consomme dans la meme transaction. Regle de `_shared/clients.ts` :
//    la cle de service reverifie l'autorisation metier.
// 3. Creation du compte, adresse confirmee : le code n'a ete remis qu'a cette
//    boite (e-mail du foyer ou du candidat) ou par la direction a cette
//    personne (enseignant, comptable), et il est lie a l'adresse. Un compte
//    NON confirme ne pourrait pas recevoir le lien de connexion : GoTrue
//    traite son premier lien comme une inscription, que l'instance refuse
//    (« Signups not allowed for this instance », vu sur la pile fermee le
//    07/11). Le lien de connexion habituel, envoye ensuite par l'application,
//    ouvre la session.
//
// La reponse est toujours la meme (`{ ok: true }`), quel que soit l'echec
// (debit atteint, code faux, adresse deja inscrite) : elle ne dit jamais si
// un code ou une adresse existe. Seule une requete mal formee recoit 400.

import { clientService, enTetesCors, json, refus } from '../_shared/clients.ts'

const TYPES = ['foyer', 'enseignant', 'comptable', 'equipe', 'candidat'] as const
type TypeInvitation = typeof TYPES[number]
const CODE = /^[A-Za-z0-9 -]{12,24}$/
const ADRESSE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

export interface Demande {
  type: TypeInvitation
  code: string
  adresse: string
}

/// Ce que la fonction attend de la base et de l'Auth, pour les tests.
export interface PorteInvitation {
  debit(adresse: string, ip: string): Promise<boolean>
  autoriser(demande: Demande): Promise<boolean>
  creerCompte(adresse: string): Promise<'cree' | 'existe' | 'echec'>
}

/// Lit le corps : `{ type, code, email }`, ou `null` s'il est mal forme.
/// Sans type, une invitation de foyer (le lien de l'e-mail du foyer).
export function lireDemande(corps: unknown): Demande | null {
  if (typeof corps !== 'object' || corps === null) return null
  const { type, code, email } = corps as Record<string, unknown>
  const t = type ?? 'foyer'
  if (typeof t !== 'string' || !(TYPES as readonly string[]).includes(t)) return null
  if (typeof code !== 'string' || typeof email !== 'string') return null
  const adresse = email.trim().toLowerCase()
  if (!CODE.test(code.trim()) || adresse.length > 254 || !ADRESSE.test(adresse)) return null
  return { type: t as TypeInvitation, code: code.trim(), adresse }
}

/// L'IP de l'appelant, pour le debit. Regle du garde-cap (07/11/2026),
/// d'apres sa mesure en production (function_edge_logs sur 24 h :
/// cf_connecting_ip = x_real_ip sur toutes les lignes) : cf-connecting-ip,
/// pose par Cloudflare qui l'ecrase toujours (le client ne peut pas le
/// forger), sinon x-real-ip, sinon 'inconnue'. x-forwarded-for n'est JAMAIS
/// lu : sa premiere valeur est ecrite par le client, et sa derniere peut etre
/// un saut interne (Cloudflare, Kong) partage par tous, qui rendrait le debit
/// global (une seule personne bloquerait les invitations de toutes les
/// familles).
export function ipDe(requete: Request): string {
  for (const entete of ['cf-connecting-ip', 'x-real-ip']) {
    const valeur = (requete.headers.get(entete) ?? '').trim()
    if (valeur.length > 0) return valeur
  }
  return 'inconnue'
}

/// Debit, autorisation (qui consomme le code d'un foyer), creation.
export async function traiter(demande: Demande, ip: string, porte: PorteInvitation): Promise<'cree' | 'rien'> {
  if (!(await porte.debit(demande.adresse, ip))) return 'rien'
  if (!(await porte.autoriser(demande))) return 'rien'
  return (await porte.creerCompte(demande.adresse)) === 'cree' ? 'cree' : 'rien'
}

function porteReelle(): PorteInvitation {
  const db = clientService()
  return {
    async debit(adresse, ip) {
      const { data, error } = await db.rpc('invitation_compte_debit', { p_adresse: adresse, p_ip: ip })
      return !error && data === true
    },
    async autoriser(d) {
      const { data, error } = await db.rpc('invitation_compte_autoriser', {
        p_type: d.type, p_code: d.code, p_email: d.adresse,
      })
      return !error && data?.autorise === true
    },
    async creerCompte(adresse) {
      const { error } = await db.auth.admin.createUser({ email: adresse, email_confirm: true })
      if (!error) return 'cree'
      const code = (error as { code?: string }).code ?? ''
      if (code === 'email_exists' || code === 'user_already_exists') return 'existe'
      console.error('invitation-compte : creation refusee', code)
      return 'echec'
    },
  }
}

if (import.meta.main) {
  Deno.serve(async (requete) => {
    if (requete.method === 'OPTIONS') return new Response('ok', { headers: enTetesCors })
    if (requete.method !== 'POST') return refus('methode', 405)
    let corps: unknown
    try {
      corps = await requete.json()
    } catch {
      return refus('demande invalide')
    }
    const demande = lireDemande(corps)
    if (!demande) return refus('demande invalide')
    try {
      const issue = await traiter(demande, ipDe(requete), porteReelle())
      console.log('invitation-compte', demande.type, issue)
    } catch (e) {
      console.error('invitation-compte', e instanceof Error ? e.message : 'erreur')
    }
    return json({ ok: true })
  })
}
