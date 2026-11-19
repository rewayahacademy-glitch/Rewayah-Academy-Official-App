// PX-OAUTH, etape 2a : la decouverte OAuth du connecteur Praxis. Voir _shared/praxis/oauth.ts et
// docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-OAUTH.md. Ouverte sans JWT Supabase (config.toml) : elle ne publie que des metadonnees et
// ne touche ni la base ni aucun secret a cette etape.

import { adressesDe, traiterOauth } from '../_shared/praxis/oauth.ts'

const racine = Deno.env.get('SUPABASE_URL') ?? ''

Deno.serve((req) => traiterOauth(req, adressesDe(racine)))
