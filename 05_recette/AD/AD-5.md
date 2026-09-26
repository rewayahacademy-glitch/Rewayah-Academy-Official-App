# AD-5 — corrections de revue (26/09/2026)

Branche `ui/admin-v1`, commit `e636017` « admin(AD-5): corrections de revue », poussé (`ab1101c..e636017`, c7c6555, 7694c84 et 15c306b compris).

## Changements
- Annonce « Dossier suivant : {nom} » (clé `dossiers.file.suivantAnnonce`, texte exact l.1945), via `SemanticsService.sendAnnouncement`, après une décision en maître-détail.
- Une actualisation en échec (hors ligne, erreur) garde la liste déjà affichée et pose l'état au-dessus. Refus d'accès et profil à compléter la remplacent toujours. `BlocAsynchrone` n'est pas modifié.
- Panneau unique : après une décision, retour à la liste avec le focus sur la ligne suivante. S'il n'en reste aucune, la sélection est retirée.
- « Réessayer » du détail passe par `actualiserDossiers` : la file et le détail sont relus ensemble.
- En-tête de file : « Actualiser les dossiers » au bord de fin. Sous 352 de large (file de 336), l'en-tête passe sur deux lignes : compteur au début, bouton au bord de fin.
- Sans nom, le libellé accessible est « Dossier sans nom disponible » seul.
- Tests : contrat D à 1440 (file à x=320, largeur 336 ; détail à x=680, largeur 728) ; disque « Retour » tapé, puis focus vérifié sur la ligne ; focus sur la ligne suivante après une décision à 390 ; repli séquentiel à 768 et à 1200 (ni revue ni sélection).
- Effet assumé : `retry: null` sur `dossiersEnAttenteProvider` touche aussi l'Accueil admin. Une erreur réseau n'y est plus relancée en silence : elle reste affichée jusqu'à « Réessayer ».

## Chiffres (dernier passage, après toutes les corrections)
- `flutter analyze --fatal-infos` sur lib/features/admin_dossiers, lib/core/i18n, test/features/admin_dossiers et le test de capture : aucun problème.
- `flutter test` sur file_dossiers, dossiers_admin, dossiers_admin_demo, admin_coque, admin_shell, demo/* (5 fichiers) et router/* (6 fichiers) : +345 ~4, tous verts.
- Captures : 6/6 vertes.
- Frontière (`ab1101c..HEAD` sur supabase, .github, vercel.json, pubspec.yaml et lib/core/theme) : vide. Aucun nouvel appel serveur.

## Captures (`captures/AD-5`, ouvertes et relues)
- `ad5_file_390x844@3_{light,dark}`
- `ad5_detail_390x844@3_{light,dark}`
- `ad5_file_768x1024@1_{light,dark}`
- `ad5_maitre_detail_1440x900@1_{light,dark}`
- `ad5_aucune_selection_1440x900@1_{light,dark}`

## Constats non corrigés, écarts pour le directeur
1. Squelette à 1440 non capturé : la démonstration répond dans la trame, et une trame de transition n'est pas une preuve. Il faut un port « en attente » dédié aux captures.
2. À 1440 et texte à 200 %, la barre latérale de la coque (`NavigationDrawerDestination`, admin_shell.dart:519) déborde de 5 à 29 px. Ce défaut relève de la coque (AD-S), pas d'AD-5. Le test du repli à 200 % a donc été remplacé par un test à 1200.
3. « Pièce hors de votre portée » sur la ligne : non fait. Le port (`DossierEnFile`, K-09) ne porte pas l'état de la pièce, et l'ajouter change le contrat. À décider.
4. Après une décision sur mobile, quand la file devient vide, le focus ne va pas sur le titre.
5. Questions toujours ouvertes : Q-AD5-1 (fuseau : UTC affiché), Q-AD5-2 à Q-AD5-6, Q15, OfflineBanner générique, composants partagés étendus (K-10).
6. Détail : contenu de revue actuel, avec des boutons en pleine largeur (Q-AD5-5, relève d'AD-6 et AD-8). Titre du détail avec une apostrophe droite, « Dossier d'Amina Benali ».
