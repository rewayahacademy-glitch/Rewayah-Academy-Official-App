# Revue du directeur des 01 et 02/10/2026 : table des règles et des preuves

Remplace la table §4 BIS de `docs/design/README.md`, absent de la branche `integration/essai-fusion` (déplacé dans `docs/archive/2026-09-pre-remise-a-plat/design/README.md` à la remise à plat). Les règles écrites sont dans `lib/CLAUDE.md`, section « Interdits d'interface (revue directeur 01-02/10) ». Source : consignes K-54 à K-59 du tableau « Suivi Rewayah ».

Principe : corriger la cause (composant partagé de `lib/core`), recenser tous les écrans au même défaut ou à un défaut équivalent, écrire la règle et son contrôle, noter le chiffre avant et après.

| Règle | Consigne | Composant partagé | Contrôle automatique | Test de garde |
|---|---|---|---|---|
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale` | `bouton-recompose` | `verifierBoutonCentre` |
| Jamais de cartes collées (cartes séparées, ou une carte à lignes fines) | K-55 | `AppCard`, `Ecart`, `GroupeReglages` | `cartes-collees` | `verifierEcartCartes` |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche` | `bouton-grise` (alias `bouton-desactive`) | revue d'écran |
| Formulaires déduit > choisi > saisi | K-57 | `ChoiceCardGroup` | revue de fiche (FORM-AUTO-1) | |
| Tout choix : contexte, quand, conséquence, carte entière cliquable | K-58 | `ChoiceCardGroup` | revue de fiche | |
| Message d'erreur : cause et action | K-59 | `EtatSysteme`, `BlocAsynchrone` | `erreur-sans-action`, `affirmation-reseau` | |
| Aucun élément ne recouvre un contenu | déduite | | | `verifierSansChevauchement` |
| Hiérarchie de titres stricte | déduite | `EnteteDePage`, `SectionHeader` | revue d'écran | |
| État jamais par la couleur seule | déduite | `StatusPill` | revue d'écran | |
| « En direct » et « Annulée » reconnaissables d'un coup d'œil, partout | ON-AIR-1, ANNUL-VIS-1 | `PastilleEtatSeance`, `TexteHeureSeance`, `LigneRaisonSeance`, `surfaceCarteSeance` | `etat-seance-pastille` | `test/core/widgets/pastille_etat_seance_test.dart` |
| Alerte urgente en tête | déduite | | revue d'écran | |
| Libellé sans ambiguïté (qui, quoi) | déduite | | `libelle-ambigu` | |
| Aucun mot interne chez le client | déduite | | `mot-interne` | |

## Chiffres au 02/10/2026 (branche `corrections/revue-directeur-2026-10`, base `integration/essai-fusion` 55a5235)

Avant correction, par contrôle (`dart run tool/verifier_revue.dart --regle=<nom> --detail`) :

| Contrôle | Occurrences avant | Après |
|---|---|---|
| `cartes-collees` | 5 | |
| `bouton-recompose` | 2 | |
| `libelle-ambigu` | 5 | |
| `mot-interne` | 4 | |
| `erreur-sans-action` | 27 | |
| `bouton-grise` | 73 (53 dans le socle hérité de `main`) | |
| `affirmation-reseau` | 10 (6 dans le socle hérité de `main`) | |
| `libelle-sans-source` | 1377 (1023 dans le socle hérité de `main`) | |
| `verifier_jetons` | 36 | |

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` ne voit que des appels voisins dans une liste `children` sans `spacing:` (pas les `ListView.builder` sans séparateur) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

## Pastille d'état de séance (ON-AIR-1, ANNUL-VIS-1)

Demande du directeur (01 et 02/10/2026) : une séance en cours et une séance annulée se reconnaissent au premier coup d'œil, partout où une séance apparaît avec un statut, tous rôles. Partie interface seulement : l'état « en direct » reste calculé côté serveur, les notifications temps réel (« Votre classe est ouverte : rejoignez-la ») et leur délai mesuré sont hors de cette étape.

Cause : chaque écran posait à la main une `StatusPill` (disque et mot) ou un point de couleur, sans battement pour « En direct », et la carte annulée du tuteur prenait tout le fond `washAlert`. Correction : un composant partagé unique, `lib/core/widgets/pastille_etat_seance.dart`.

| Élément | Règle | Source des valeurs |
|---|---|---|
| `PastilleEtatSeance(enDirect)` | pilule douce `washSuccess`, point de statut qui bat doucement, puis reste fixe | `AppMouvement.pulsationDirect` (1500 ms), `pulsationCourbe` (`easeInOut`), `battementsDirect` (3) |
| Réduire les animations | point fixe d'emblée, aucun halo, le mot « En direct » reste | `AppMouvement.mouvementReduit` |
| `PastilleEtatSeance(annulee)` | pilule `washAlert` (le ton d'alerte des jetons, aucun rouge inventé), icône d'annulation (`AppIcons.interdit`), mot « Annulée » | `palette.washAlert`, `pointsStatut` |
| `TexteHeureSeance` | heure barrée et atténuée (`inkMuted`), annoncée « Prévue à … » au lecteur d'écran | `palette.inkMuted` |
| `surfaceCarteSeance` | carte annulée sur `surfaceSunken`, jamais une opacité (le texte garde son contraste) | `palette.surfaceSunken` |
| `LigneRaisonSeance` | une ligne : pourquoi et, quand la donnée existe, la suite (« Aucun remplaçant trouvé · séance non facturée ») ; rien n'est inventé | clé `etat.raisonEtSuite` |

Nouveaux jetons de mouvement (aucun jeton existant ne convenait : `pulsation` vaut 1,2 s et est réservée à l'imminence ELV-02) : `AppMouvement.pulsationDirect`, `AppMouvement.battementsDirect`, `AppMouvement.pulsationCourbe`.

Choix à connaître : le battement s'arrête après trois cycles (4,5 s), sous les 5 s au-delà desquelles WCAG 2.2.2 exige une commande d'arrêt, comme le `PointRappel` de K-45. Pour un battement sans fin, il suffit de remplacer `battementsDirect` ; le test `dit le mot et bat doucement, puis reste fixe` est alors à adapter.

Emplacements recensés (une séance apparaît avec un statut) et convertis au composant :

| # | Emplacement | Rôle | « En direct » | « Annulée » |
|---|---|---|---|---|
| 1 | `ChildCard` (accueil du tuteur) | tuteur | converti | converti, carte atténuée |
| 2 | Accueil élève (`accueil_eleve_page`) | élève | converti | converti |
| 3 | Ma journée, carte « Séance en direct » (`journee_page`) | enseignant | converti | |
| 4 | Ma journée, alerte « Le cours de … est annulé » | enseignant | | converti, première ligne des alertes |
| 5 | Ma journée, état d'absence « Séance annulée » (`PastilleAbsence`) | enseignant | | converti |
| 6 | Carte de séance de la Classe (`carte_seance_classe`) | tuteur | converti | converti, heures barrées, carte atténuée |
| 7 | Planning de la classe (`planning_classe_page`) | tuteur | converti | converti, heures barrées |
| 8 | Dernière séance (`ligne_derniere_seance`) | tuteur | converti | converti, date barrée |
| 9 | Carte de séance de l'Espace Classe (`carte_session`, `EmplacementEntreeVue`) | élève, tuteur, enseignant, adulte | converti | converti, heures barrées, carte atténuée |
| 10 | Mes groupes (`carte_groupe`) | élève, enseignant, adulte | converti | |
| 11 | Barre « Cours en cours » (`barre_cours_en_cours`) | enseignant, élève | converti | |
| 12 | Salle d'observation (`panneau_observation_tuteur`) | tuteur | converti | |
| 13 | Entête de la salle du contrôleur (`salle_page`, 2 appels) | contrôleur | converti | |
| 14 | Mission du contrôleur (`controle_page`) | contrôleur | converti | |
| 15 | Sélecteur de profils (`selecteur_profils`, point) | tuteur | converti (point qui bat) | point d'alerte et mot, inchangé |
| 16 | Suivi de l'élève (`suivi_eleve_page`) | élève | | converti |
| 17 | Historique, liste (`composants_historique`) | tuteur | | converti, horaire barré |
| 18 | Historique, détail d'une séance (`detail_seance_page`) | tuteur | | converti |

Non convertis, et pourquoi : la pastille de connexion de la salle (`chrome_seance`, « En ligne » est l'état du lien, pas celui de la séance) ; les statuts d'évaluation de la direction (`evaluations_page`, l'évaluation annulée n'est pas une séance) ; l'horaire du détail de séance (`LigneCleValeur` n'a pas de rendu barré, la pastille et la phrase portent l'état) ; les écrans de démonstration (`features/demo`) rendent les vrais composants.

Contrôle automatique : `etat-seance-pastille` (`tool/verifier_revue.dart`) échoue sur toute `StatusPill` qui porte le mot « En direct » ou « Annulée » hors de `pastille_etat_seance.dart`.

Chiffres :

| Mesure | Avant | Après |
|---|---|---|
| `StatusPill` posées à la main avec le mot « En direct » ou « Annulée » (contrôle `etat-seance-pastille`) | 6 | 0 |
| Emplacements recensés, tous états | 18 | 18 convertis |
| Pastilles « En direct » qui battent | 0 | 14 appels (13 emplacements) |
| Emplacements « Annulée » au composant (icône d'annulation, heure barrée là où une heure s'affiche, carte atténuée là où il y a une carte) | 0 | 11 emplacements |
| `verifier_jetons` | 36 | 36 |
| `cartes-collees`, `bouton-recompose`, `libelle-ambigu`, `mot-interne`, `erreur-sans-action` | 0 nouvelle | 0 nouvelle |
