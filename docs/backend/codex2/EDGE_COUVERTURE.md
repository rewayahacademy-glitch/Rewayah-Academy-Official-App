# Couverture des handlers Edge - X2-05

Les tests interceptent `Deno.serve`, appellent les handlers directement et remplacent `fetch` par des reponses locales. Les signatures JWT/R2 sont calculees localement avec des valeurs de test. Aucun appel externe ni credential reel n'est utilise.

| Handler | Scenarios verifies |
| --- | --- |
| `agent-session` | Corps absent / JSON illisible -> 400; refus RPC -> 401; succes signe, claim `role=agent_ro`, secret absent du JWT. |
| `archive-seance-acces` | GET -> 405; appelant absent -> 401; JSON illisible -> 400; RPC refuse -> 403; URL GET signee nominale; URL et cle R2 absentes des journaux. |
| `create-room-token` | Configuration absente -> 503; appelant absent -> 401; JSON illisible -> 400; RPC refuse -> 403; succes signe avec faux credentials. |
| `creer-profil-enfant` | Appelant absent -> 401; succes avec faux auth/RPC; refus RPC -> 403 et suppression compensatoire simulee. |
| `livekit-webhook` | GET -> 405; signature invalide/absente -> 401; evenement signe accepte et transmis a la RPC simulee. |
| `piece-identite-acces` | GET -> 405; appelant absent -> 401; JSON illisible -> 400; RPC refuse -> 403; URL GET signee nominale; URL et cle R2 absentes des journaux. |
| `piece-identite-confirme` | GET -> 405; JSON illisible / UUID invalide -> 400; deposant non autorise -> 403; objet HEAD present et confirmation nominale. |
| `piece-identite-depot` | GET -> 405; JSON illisible / MIME refuse -> 400; reservation refusee -> 403; URL PUT signee nominale; URL et cle R2 absentes des journaux. |
| `session-enfant` | JSON illisible -> 400; code refuse -> 403; appairage nominal avec faux RPC/Auth. |

Execution de tous les fichiers: `deno test --no-check --allow-env ...` -> 20/20 tests. Les neuf handlers ont maintenant au moins un parcours nominal simule; les points d'entree avec session utilisateur couvrent des refus d'appelant et de role selon leur modele d'autorisation. Les webhooks n'ont pas de role utilisateur: leur garde est la signature LiveKit.

`deno test` avec verification TypeScript reste en echec sur le code existant `supabase/functions/_shared/livekit.ts:104`: `TrackSource[]` n'est pas assignable au type de chaines attendu par la dependance. Le test `create-room-token` a egalement revele que le cas autorise avec publication audio echoue a l'execution dans cette conversion. Aucun handler n'est modifie par ce lot.

Relance lors de la finalisation X2-05 (Deno 2.9.6 sous Windows, `--cached-only`): le processus panique avant le lancement des tests (`Unexpected client pipe failure`, `cli/tools/test/channel.rs:252`). Le résultat 20/20 ci-dessus correspond à l'exécution antérieure du lot; cette relance n'a pas pu le reproduire. Aucun accès réseau n'est permis par cette relance.
