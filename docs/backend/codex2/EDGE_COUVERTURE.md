# Couverture des handlers Edge - X2-05

Les tests interceptent `Deno.serve`, appellent directement les handlers et remplacent `fetch` par des reponses locales sur les deux parcours metier etudies. Aucune requete externe ni credential reel n'est utilise.

| Handler | Scenarios verifies |
| --- | --- |
| `agent-session` | Corps absent / JSON illisible -> 400. |
| `archive-seance-acces` | Methode GET -> 405. |
| `create-room-token` | Configuration absente -> 503; appelant absent -> 401; JSON illisible -> 400; RPC d'autorisation refuse -> 403; succes signe avec faux credentials, aucun secret integre au JWT. |
| `creer-profil-enfant` | Appelant absent -> 401; succes avec faux appels auth/RPC; refus RPC -> 403 et suppression compensatoire du compte simule. |
| `livekit-webhook` | Methode GET -> 405; signature absente -> 401. |
| `piece-identite-acces` | Methode GET -> 405. |
| `piece-identite-confirme` | Methode GET -> 405. |
| `piece-identite-depot` | Methode GET -> 405. |
| `session-enfant` | JSON illisible -> 400 avant creation du client de service. |

Execution de tous les fichiers: `deno test --no-check --allow-env ...` -> 13/13 tests. Aucun test ne requiert un acces reseau; les appels de succes documentes ci-dessus sont servis par `fetch` simule. Les tests ne couvrent pas encore un succes nominal pour les handlers R2, webhook, agent-session et session-enfant, ni tous les refus de role metier.

`deno test` avec verification TypeScript reste en echec sur le code existant `supabase/functions/_shared/livekit.ts:104`: `TrackSource[]` n'est pas assignable au type de chaines attendu par la dependance. Ce lot ne modifie aucun handler pour masquer cette erreur.
