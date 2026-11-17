// PX-OAUTH : le serveur d'autorisation de Praxis pour claude.ai. Decouverte (2a) et points /register, /authorize, /token (2c) ; la
// decision d'autoriser est prise par la direction sur la page de consentement de l'application (2d). Voir _shared/praxis/oauth_serveur.ts
// et docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-OAUTH.md. Ouverte sans JWT Supabase (config.toml) : la porte est la base (fonctions
// `praxis_oauth_*`, service_role seul).

import { clientService } from '../_shared/clients.ts'
import { creerLimiteur } from '../_shared/praxis/limiteur.ts'
import { type PortePraxis } from '../_shared/praxis/mcp.ts'
import { adressesDe } from '../_shared/praxis/oauth.ts'
import { traiterServeur } from '../_shared/praxis/oauth_serveur.ts'

const porte: PortePraxis = {
  async appeler(fonction, params, signal) {
    const { data, error } = await clientService().rpc(fonction, params).abortSignal(signal)
    if (error) throw new Error('rpc')
    return data
  },
}

const racine = Deno.env.get('SUPABASE_URL') ?? ''
const adresses = adressesDe(racine)
const adresseApp = (Deno.env.get('PRAXIS_APP_URL') ?? 'https://app.rewayahacademy.com').replace(/\/+$/, '')
const limiteur = creerLimiteur()

// L'adresse de l'appelant, pour le debit seulement : le premier maillon de x-forwarded-for, sinon une valeur fixe.
const adresseDe = (req: Request) => (req.headers.get('x-forwarded-for') ?? '').split(',')[0].trim() || 'inconnue'

Deno.serve((req) => traiterServeur(req, { adresses, porte, limiteur, adresseApp, adresseDe }))
