// Le client Supabase qui parle AU NOM de l'appelant, et pourquoi les points
// d'entree R2 s'en servent plutot que de la cle de service.
//
// Les fonctions Edge de ce depot appellent leurs RPC avec `clientService()`,
// puis la RPC reverifie l'autorisation metier -- la cle contourne la RLS, elle
// ne remplace pas le controle. C'est juste, et rien ici ne le conteste.
//
// Mais les acces gouvernes par R2 ont une exigence de plus, posee par
// l'ADR-002 : **chaque ecoute d'archive et chaque ouverture de piece d'identite
// est ecrite dans `audit_logs` avec l'identite de celui qui regarde.** Or
// `log_sensitive_access()` lit cette identite dans `auth.uid()` (migration
// `0001`), et `auth.uid()` rend NULL quand l'appel arrive avec la cle de
// service. Le journal porterait alors un acteur vide, ce qui est exactement
// l'inverse de ce que la decision demande. `autoriser_jeton_video()` contourne
// deja cela en recopiant l'identifiant dans la charge utile de la trace -- un
// identifiant qui, lui, arrive du corps de la requete.
//
// En passant le jeton de l'appelant a la RPC, trois choses deviennent vraies
// ensemble : `auth.uid()` designe la bonne personne, `app_role()` rend son role
// reel, et la trace d'audit est exacte sans qu'aucun identifiant ne soit recu du
// client. **Un identifiant recu du client est une demande, pas une identite.**
//
// La RLS s'applique alors normalement par-dessus la porte de la RPC, ce qui est
// une defense de plus et jamais une de moins : toutes les RPC appelees par ces
// points d'entree sont `security definer` et portent leur propre exigence
// positive.

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2'

/// Ce que le point d'entree obtient d'un appel authentifie.
export interface AppelantR2 {
  /// L'identifiant du compte, lu dans le jeton et jamais dans le corps.
  readonly id: string
  /// Le client qui portera ce jeton jusqu'a PostgreSQL.
  readonly sql: SupabaseClient
}

/// Rend l'appelant et son client, ou `null` quand aucun jeton exploitable
/// n'accompagne l'appel.
///
/// Le jeton est verifie ici, une fois, plutot que d'etre suppose valide : une
/// RPC appelee avec un jeton expire echouerait plus loin, avec un message moins
/// clair et sans code 401.
export async function appelantR2(requete: Request): Promise<AppelantR2 | null> {
  const entete = requete.headers.get('Authorization')
  if (!entete?.startsWith('Bearer ')) {
    return null
  }

  const url = Deno.env.get('SUPABASE_URL')
  const cle = Deno.env.get('SUPABASE_ANON_KEY')
  if (!url || !cle) {
    throw new Error('configuration absente : SUPABASE_URL ou SUPABASE_ANON_KEY')
  }

  const client = createClient(url, cle, {
    global: { headers: { Authorization: entete } },
    auth: { persistSession: false },
  })

  const { data, error } = await client.auth.getUser()
  if (error || !data.user) {
    return null
  }

  return { id: data.user.id, sql: client }
}
