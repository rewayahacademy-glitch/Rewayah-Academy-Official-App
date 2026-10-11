# Couverture des handlers Edge — X2-05

Les tests interceptent `Deno.serve` et invoquent le handler avec des `Request`
en mémoire. Ils ne démarrent pas de serveur, n'autorisent pas le réseau et
n'utilisent aucun credential réel. Les scénarios couvrent les premières
barrières (méthode, absence d'appelant, corps rejeté, configuration absente),
pas les chemins nominaux qui exigeraient des réponses simulées de Supabase,
LiveKit ou R2.

| Handler | Fichier de test | Scénario exécuté |
| --- | --- | --- |
| `agent-session` | `supabase/functions/agent-session/index_test.ts` | Jeton absent et JSON illisible → 400 |
| `archive-seance-acces` | `supabase/functions/archive-seance-acces/index_test.ts` | Méthode GET → 405 |
| `create-room-token` | `supabase/functions/create-room-token/index_test.ts` | Aucun trousseau LiveKit → 503 sans exposer les noms de secrets |
| `creer-profil-enfant` | `supabase/functions/creer-profil-enfant/index_test.ts` | Appelant absent → 401 avant lecture du corps |
| `livekit-webhook` | `supabase/functions/livekit-webhook/index_test.ts` | Méthode GET → 405; POST sans signature → 401 |
| `piece-identite-acces` | `supabase/functions/piece-identite-acces/index_test.ts` | Méthode GET → 405 |
| `piece-identite-confirme` | `supabase/functions/piece-identite-confirme/index_test.ts` | Méthode GET → 405 |
| `piece-identite-depot` | `supabase/functions/piece-identite-depot/index_test.ts` | Méthode GET → 405 |
| `session-enfant` | `supabase/functions/session-enfant/index_test.ts` | JSON illisible → 400 avant création du client de service |

Exécution réussie : `deno test --no-check --allow-env ...` sur les neuf fichiers
(9 tests). `--no-check` est requis sur cette branche car le contrôle TypeScript
échoue dans le fichier existant `supabase/functions/_shared/livekit.ts:104`
(`TrackSource[]` incompatible avec les chaînes `microphone`/`camera`/
`screen_share`). Aucun handler existant n'a été modifié pour contourner cette
erreur. Les tests ne vérifient donc pas les appels métier autorisés ni la
réponse nominale avec des dépendances distantes simulées.
