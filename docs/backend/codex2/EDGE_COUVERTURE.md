# Couverture des handlers Edge - X2-05

Les tests interceptent `Deno.serve`, appellent les handlers directement et remplacent `fetch` par des reponses locales sur les parcours metier retenus. Aucune requete externe ni credential reel n'est utilise.

| Handler | Scenarios verifies |
| --- | --- |
| `agent-session` | Corps absent / JSON illisible -> 400; refus RPC -> 401; succes avec faux RPC, JWT emet un claim `role=agent_ro` sans exposer la cle de signature. |
| `archive-seance-acces` | Methode GET -> 405. |
| `create-room-token` | Configuration absente -> 503; appelant absent -> 401; JSON illisible -> 400; RPC refuse -> 403; succes signe avec faux credentials. |
| `creer-profil-enfant` | Appelant absent -> 401; succes avec faux appels auth/RPC; refus RPC -> 403 et suppression compensatoire simulee. |
| `livekit-webhook` | Methode GET -> 405; signature absente -> 401. |
| `piece-identite-acces` | Methode GET -> 405. |
| `piece-identite-confirme` | Methode GET -> 405. |
| `piece-identite-depot` | Methode GET -> 405. |
| `session-enfant` | JSON illisible -> 400 avant service; refus de code -> 403; succes d'appairage avec faux RPC/Auth, reponse a usage unique. |

Execution de tous les fichiers: `deno test --no-check --allow-env ...` -> 15/15 tests. Les tests ne couvrent pas encore un succes nominal pour les handlers R2, webhook, ni tous les refus de role metier. `create-room-token` emet un jeton nominal si la reponse autorisee interdit la publication; le cas autorise avec publication audio revele une erreur d'execution dans la conversion `TrackSource` du module partage.

`deno test` avec verification TypeScript reste en echec sur le code existant `supabase/functions/_shared/livekit.ts:104`: `TrackSource[]` n'est pas assignable au type de chaines attendu par la dependance. Ce lot ne modifie aucun handler pour masquer cette erreur.
