// ADRESSE-LIBEREE (14/11/2026) : une adresse invitee dont l'ancien compte a ete
// supprime (profil retire, compte banni) doit etre libre AVANT que la personne
// ne se connecte, quel que soit son chemin (lien, code, Google, « Retrouver mon
// acces »). Constat de production (14/11, 10:03-10:05 UTC) : « 403: User is
// banned » sur /callback et /verify, `invitation-compte` jamais appelee.
//
// Le moment sur : l'envoi du courriel d'invitation (`courriels-envoi`), seul
// endroit serveur ou passent TOUTES les invitations d'equipe et de candidat
// (les creations se font en SQL, qui ne touche jamais au schema `auth`).
// Meme mecanique que `invitation-compte` : `invitation_compte_ancien_a_liberer`
// (service_role seul : verifie le code, journalise, rend l'id de l'ancien
// compte), puis l'API admin native (`updateUserById`, GoTrue gere les
// identites), puis un compte neuf confirme (`createUser`) : Google, lien et code
// tombent alors sur un compte existant, sans profil. Meme sans ancien compte :
// toute invitation valide recoit son compte a l'envoi. Jamais pour un foyer.

import type { SupabaseClient } from 'jsr:@supabase/supabase-js@2'

/// Les modeles de courriel qui portent un code d'invitation d'equipe ou de
/// candidat, et le ou les types que le serveur sait verifier pour eux.
const MODELES: Record<string, readonly ('equipe' | 'candidat')[]> = {
  invitation_enseignant: ['equipe'],
  // Le candidat importe : son code est celui d'une invitation d'equipe ou de
  // candidat ; le serveur dit lequel.
  invitation_candidat_importe: ['equipe', 'candidat'],
}

export interface PorteLiberation {
  ancienCompte(type: 'equipe' | 'candidat', code: string, adresse: string): Promise<string | null>
  liberer(idAncien: string): Promise<boolean>
  /// Le code est valide pour cette adresse ET aucun compte ne la tient
  /// (`invitation_compte_autoriser`).
  autoriser(type: 'equipe' | 'candidat', code: string, adresse: string): Promise<boolean>
  creerCompte(adresse: string): Promise<'cree' | 'existe' | 'echec'>
  consommer(type: 'equipe' | 'candidat', code: string, adresse: string): Promise<boolean>
}

/// `rien` : pas d'invitation valide pour cette adresse (ou modele sans code) ;
/// `preparee` : l'adresse est libre de tout ancien compte et un compte neuf
/// confirme, sans profil, existe ; `echec` : l'adresse tient encore ou le
/// compte n'a pas pu etre cree, le courriel ne doit PAS partir (il serait
/// suivi d'un « User is banned » ou d'un refus d'inscription).
///
/// Vaut pour TOUTE invitation d'equipe ou de candidat valide : les inscriptions
/// sont fermees au niveau de l'instance Auth, donc un invite tout neuf qui
/// prendrait Google ou un lien hors du chemin `invitation-compte` echouerait
/// aussi. Le compte existant, la connexion (Google, lien, code) l'ouvre, et
/// l'accueil des invites mene la personne a son inscription.
export async function preparerAdresseInvitee(
  modele: string,
  donnees: Record<string, unknown>,
  adresse: string,
  porte: PorteLiberation,
): Promise<'rien' | 'preparee' | 'echec'> {
  const types = MODELES[modele]
  const code = typeof donnees.code === 'string' ? donnees.code.trim() : ''
  if (!types || code === '') return 'rien'
  let ancien: string | null = null
  for (const type of types) {
    ancien = await porte.ancienCompte(type, code, adresse)
    if (ancien !== null) break
  }
  if (ancien !== null && !(await porte.liberer(ancien))) return 'echec'
  let valide: 'equipe' | 'candidat' | null = null
  for (const type of types) {
    if (await porte.autoriser(type, code, adresse)) {
      valide = type
      break
    }
  }
  if (valide === null) return ancien !== null ? 'echec' : 'rien'
  const creation = await porte.creerCompte(adresse)
  if (creation === 'echec') return 'echec'
  if (creation === 'cree' && !(await porte.consommer(valide, code, adresse))) {
    console.error('invitation : code non consomme apres creation', valide)
  }
  return 'preparee'
}

export function porteLiberationReelle(db: SupabaseClient): PorteLiberation {
  return {
    async ancienCompte(type, code, adresse) {
      const { data, error } = await db.rpc('invitation_compte_ancien_a_liberer', {
        p_type: type, p_code: code, p_email: adresse.trim().toLowerCase(),
      })
      return !error && typeof data === 'string' ? data : null
    },
    async liberer(idAncien) {
      const { error } = await db.auth.admin.updateUserById(idAncien, {
        email: `efface-${idAncien}@invalide.rewayahacademy.com`,
        email_confirm: true,
      })
      if (error) console.error('adresse non liberee', (error as { code?: string }).code ?? '')
      return !error
    },
    async autoriser(type, code, adresse) {
      const { data, error } = await db.rpc('invitation_compte_autoriser', {
        p_type: type, p_code: code, p_email: adresse.trim().toLowerCase(),
      })
      return !error && data?.autorise === true
    },
    async consommer(type, code, adresse) {
      const { data, error } = await db.rpc('invitation_compte_consommer', {
        p_type: type, p_code: code, p_email: adresse.trim().toLowerCase(),
      })
      return !error && data === true
    },
    async creerCompte(adresse) {
      const { error } = await db.auth.admin.createUser({ email: adresse.trim().toLowerCase(), email_confirm: true })
      if (!error) return 'cree'
      const code = (error as { code?: string }).code ?? ''
      if (code === 'email_exists' || code === 'user_already_exists') return 'existe'
      console.error('compte neuf non cree', code)
      return 'echec'
    },
  }
}
