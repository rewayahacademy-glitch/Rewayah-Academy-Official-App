# À faire : langues de l'application (directeur, 07/11/2026)

Lot **LANGUES**, en attente sur ordre du directeur : « Ne lance pas pour l'instant ces lots-là,
le lot des langues. On attend après. » Il ne démarre que sur un nouvel ordre daté du directeur.
Ce fichier garde ce qui doit y entrer, pour que rien ne se perde.

## Les mots du directeur (07/11/2026)

« L'arabe, c'est bien parti, mais il y a beaucoup de portions des interfaces qui ne se traduisent
pas, qui restent en français. Donc, lorsqu'on va commencer à traduire après pour les autres
langues, on va corriger cela. Il faut juste le marquer. Et avant que je n'oublie, lors de la
traduction, on fait attention pour ne pas que l'app devienne trop lourde, pour ne pas qu'elle
charge toutes les langues. Je pense que je l'avais dit, mais vu que c'est important, je dois le
redire et tu le marques. »

## Ce que le lot devra faire

1. **Textes restés en français dans l'interface arabe.** Relever tous les écrans et toutes les
   portions qui restent en français quand l'application est en arabe (textes en dur, clés sans
   traduction, textes venus du serveur), puis les traduire. Même relevé pour chaque nouvelle
   langue.
2. **Ne jamais charger toutes les langues.** L'application ne télécharge que la langue affichée.
   Chaque langue (et sa police, comme l'arabe depuis le lot 4 « police arabe à la demande ») se
   charge à la demande. Mesure obligatoire du poids du premier chargement avant et après, dans le
   bilan du lot ; aucune hausse pour un utilisateur qui reste dans sa langue.
3. **La langue appartient au compte, pas à l'appareil** (constat du directeur, 07/11) : aujourd'hui
   le choix est enregistré sur l'appareil (`lib/core/preferences/preferences_locales.dart`, clé
   locale `apparence.langue`), donc tout compte qui se connecte sur un téléphone hérite de la langue
   choisie par le précédent, et un même compte n'a pas la même langue sur deux appareils. Règle
   attendue : la langue enregistrée du compte s'applique à la connexion sur tous ses appareils ;
   avant connexion et après déconnexion, l'appareil suit son propre choix ou sa langue système ; le
   compte suivant n'hérite jamais de la langue du précédent. Réutiliser un stockage serveur de
   préférences s'il existe (la langue des courriels est déjà dans les métadonnées du compte,
   `lib/core/capacites/langues_communication_supabase.dart`). Réservation de migration si besoin :
   `20261111300000`.
4. **Vocabulaire** : compétence `mots-rewayah` pour tout texte ; on ne change un mot que sur
   décision datée du directeur.

## Preuves attendues

- Robot : deux comptes sur un même appareil retrouvent chacun leur langue ; un compte sur deux
  appareils garde la sienne.
- Captures 390 et 1440 de chaque écran principal dans chaque langue, sans aucun texte resté en
  français.
- Mesure du poids de chargement par langue.

Inscrit au journal des décisions (`08`, §5 bis, 2026-11-07) et dans la table « Lire » de
`CLAUDE.md`.
