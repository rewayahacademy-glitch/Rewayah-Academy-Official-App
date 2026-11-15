# COM-LISTER-FILS-ECONOME (15/11/2026)

Ce que change le lot : la liste des conversations de Messages ne relit plus le serveur à chaque
signal temps réel ; les relectures sont regroupées (anti-rebond) dans
`lib/core/communications/veille_messages.dart` et `lib/features/com_messages/messages_metier_supabase.dart`.
**Aucun changement visuel.**

Captures : `messages_liste_1440x900.png` et `messages_liste_390x844.png`. Elles montrent que l'écran
Messages (liste des conversations, point de vue Famille) s'affiche toujours après le changement.

Comment : build web local (`flutter build web --release --dart-define=ENVIRONNEMENT=developpement`
avec une URL et une clé Supabase factices, aucun serveur joint), servi par `tool/e2e/serveur.mjs`,
puis Playwright (Chromium, facteur 1) sur `/demo/communications?voie=messages&role=tuteur`.

Limites, dites en premier : les données sont **fictives** (mode démonstration, aucune donnée de
production, aucune écriture). Ces captures ne prouvent ni le regroupement des relectures ni le temps
réel ; elles ne prouvent que le rendu. La preuve de l'étape reste celle du directeur en production.
