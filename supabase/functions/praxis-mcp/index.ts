// PX-1 (SEC-1) : le connecteur MCP de Praxis. Voir _shared/praxis/mcp.ts. Ouverte sans JWT Supabase (config.toml) : la porte
// est la cle Praxis, relue en base a chaque appel. Elle n'a aucune logique metier : elle valide, puis appelle une fonction
// SQL `praxis_*` avec le role service_role (executable par lui seul).
//
// UNE SEULE exception (PX-BD-SUPPORT) : `praxis_support_deposer` n'est pas une fonction SQL. Deposer un support exige d'ecrire un fichier
// dans le coffre R2, ce qu'aucune fonction SQL ne sait faire : la fonction Edge analyse le texte, ecrit l'objet et signe la confirmation
// (_shared/support/deposer.ts), et ne parle a la base QUE par `praxis_agir` (le pont borne, la cle de chat, l'identite de la direction).

import { clientService } from '../_shared/clients.ts'
import { type PortePraxis, traiter } from '../_shared/praxis/mcp.ts'
import { verifierCle } from '../_shared/r2/cles.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import { signatureConfirmationUpload } from '../_shared/r2/confirmation_hmac.ts'
import { signerDepot } from '../_shared/r2/signature.ts'
import { deposerSupport, type Json, MIME_TEXTE, type PortDepot } from '../_shared/support/deposer.ts'
import { OCTETS_MAX } from '../_shared/support/markdown_ferme.ts'

function secretConfirmation(): string | null {
  try {
    const s = Deno.env.get('LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY') ?? ''
    return new TextEncoder().encode(s).byteLength >= 32 && s.trim() === s ? s : null
  } catch {
    return null
  }
}

function portDepot(cle: string, signal: AbortSignal): PortDepot {
  return {
    pret: () => stockageConfigure('supports') && secretConfirmation() !== null,
    async agir(acte, params, cleIdempotence) {
      const { data, error } = await clientService().rpc('praxis_agir', {
        p_cle: cle, p_acte: acte, p_params: params, p_cle_idempotence: cleIdempotence,
      }).abortSignal(signal)
      if (error) throw new Error('rpc')
      return data
    },
    async ecrire(cleObjet, octets) {
      const signee = await signerDepot('supports', verifierCle('supports', cleObjet), {
        typeMime: MIME_TEXTE, tailleOctets: octets.byteLength, typesAutorises: [MIME_TEXTE], tailleMaximaleOctets: OCTETS_MAX,
      })
      const r = await fetch(signee.url, { method: 'PUT', headers: signee.enTetesExiges, body: octets.slice(), signal })
      if (!r.ok) throw new Error('r2')
    },
    signer(intention, empreinte, taille) {
      const secret = secretConfirmation()
      if (secret === null) return Promise.reject(new Error('secret'))
      return signatureConfirmationUpload(secret, intention, empreinte, taille)
    },
  }
}

const porte: PortePraxis = {
  async appeler(fonction, params, signal) {
    if (fonction === 'praxis_support_deposer') {
      return await deposerSupport({
        titre: String(params.p_titre ?? ''),
        langue: String(params.p_langue ?? ''),
        corps: String(params.p_corps ?? ''),
        rayon: typeof params.p_rayon === 'string' ? params.p_rayon : null,
        description: typeof params.p_description === 'string' ? params.p_description : null,
        cle_idempotence: String(params.p_cle_idempotence ?? ''),
      }, portDepot(String(params.p_cle ?? ''), signal)) as Json
    }
    const { data, error } = await clientService().rpc(fonction, params).abortSignal(signal)
    if (error) throw new Error('rpc')
    return data
  },
}

Deno.serve((req) => traiter(req, porte))
