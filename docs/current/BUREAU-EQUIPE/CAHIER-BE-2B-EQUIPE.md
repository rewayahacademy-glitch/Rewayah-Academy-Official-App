# Cahier BE-2b : l'écran « Équipe » (vague 2, la mission)

Écrit par le pilote le 16/11/2026, à 21 h 20 UTC. Ce lot vient après BE-2a-1 (#565, serveur des missions) et
BE-2a-2 (rôle `associe`, invitation). Règles de lecture obligatoires : `DECISION-LISTES-2026-10-23.md`,
`DECISION-DEFILEMENT-2026-11-01.md` (la page défile, rien dans un cadre de hauteur fixe),
`DECISION-FLUIDITE-2026-11-07.md` (accorder et retirer une mission sont des actions sensibles : on les attend, avec
une animation), `RAPPORT-EXPERIENCE-2026-11-16.md` §3, et les compétences `mots-rewayah` et
`design-taste-frontend`.

## 0. La phrase de recette (directeur)

« J'invite un ami par e-mail, je coche cinq gestes sur les candidatures en anglais ; il ne voit que cela ; je retire
la mission, il ne voit plus rien et son compte n'a pas changé. »

## 1. Où se trouve l'écran

- Une entrée « Équipe » sous Personnes, à côté de « Comptes » (`AppRoutes.adminPersonnesComptes` sert de modèle). La
  route est `/admin/personnes/equipe`.
- L'écran est visible seulement si la capacité serveur le permet : la direction, en double authentification. Le
  widget lit une capacité, jamais un rôle.
- Dossier `lib/features/admin_equipe/`. Le port et l'adaptateur vont dans `lib/core/equipe/`
  (`port_equipe.dart`, `equipe_supabase.dart`), sur le modèle de `lib/core/enseignants`.

## 2. Ce que montre l'écran (une seule page qui défile)

1. **En tête, une rangée de commandes** : « Inviter une personne » et « Nouvelle mission ». Rien de plus en
   permanence.
2. **La liste des personnes de l'équipe qui portent une mission** (`lister_attributions`). Une ligne par personne,
   avec :
   - son nom et son rôle (associé, enseignant…) ;
   - le nom de ses missions ;
   - le périmètre en mots (« dossiers en anglais, salle d'examen ») ;
   - la date de fin, ou « sans fin » ;
   - un menu « … » : « Voir le détail », « Retirer la mission ».
3. **Les missions** (`lister_missions`), dans une section repliée par défaut : nom, gestes en mots, nombre de
   personnes qui la portent, et « Archiver ».
4. **Les invitations en attente** : à qui, depuis quand, avec « Renvoyer » et « Révoquer ».

Les états à prévoir : chargement, contenu, vide (« Personne n'a encore de mission. Invitez une personne ou créez
une mission. »), erreur (la phrase vraie du serveur, jamais « connexion » pour un refus), hors ligne.

## 3. Les trois feuilles (une feuille du bas sur téléphone, un panneau sur ordinateur)

- **Nouvelle mission** : un nom (80 signes au plus), puis les gestes à cocher. On ne montre que les gestes que le
  serveur déclare ouverts aux missions (`private.mission_gestes_ouverts`, exposé par une lecture : à demander au
  pilote si elle manque). Chaque geste est écrit en mots de l'écran (`mots-rewayah`), jamais avec son code.
- **Accorder une mission** :
  - la personne (recherche dans l'équipe, ou « inviter » si elle n'y est pas) ;
  - la mission ;
  - le périmètre : langues (cases), étapes (cases), « seulement ces dossiers » (vient avec BE-2c). Le côté n'est
    jamais choisi : l'écran affiche en clair « Côté : hommes » ou « Côté : femmes », tel que le serveur l'a écrit ;
  - le début (maintenant par défaut) et la fin (facultative) ;
  - un résumé en une phrase avant de valider : « Karim pourra lire et demander un complément sur les dossiers en
    anglais, jusqu'au 30 novembre. »
- **Retirer une mission** : un motif obligatoire, puis la confirmation. Après le retrait, la ligne quitte la liste,
  et un message bref dit « Mission retirée. Le compte de Karim n'a pas changé. »

## 4. Inviter une personne (avec BE-2a-2)

Un courriel et un nom, puis « Envoyer l'invitation ». Le statut se suit dans « Invitations en attente ». Le texte du
courriel se demande au pilote ; il n'est jamais inventé.

## 5. Ce que BE-2b ne fait pas

« Confier » des dossiers depuis la liste et « Mes dossiers » (BE-2c), suspendre ou rétablir un compte (BE-2d), et
l'accueil de l'associé, qui est la liste des candidatures filtrée par le serveur : rien à construire, il lit déjà
`lister_candidatures`. Vérifier seulement que sa navigation ne lui montre que « Candidatures ».

## 6. Preuves

Tests de widget pour chaque état et chaque feuille. Captures R3 fr et ar à 360 px dans
`docs/current/captures/E2E/BE-2B-EQUIPE/`. Le premier nom de la liste doit être à moins de 300 pt sur un écran de
360 × 800, mesuré et écrit dans la PR. Toutes les vérifications de `CLAUDE.md` passent. La ligne dans
`REGISTRE-LOTS.md` est écrite le jour même.
