# M1 : modules en double, liste à soumettre au directeur (03/11/2026)

Lot M1, rang 17 de garde-cap. Lecture seule : **rien n'est supprimé par ce lot.** La décision de
supprimer appartient au directeur, sur la liste précise ci-dessous (CLAUDE.md, « État du code » ;
`tool/branchement_tolere.txt`, en-tête).

## Ce qui est faux, bloqué ou non prouvé, d'abord

- **Deux modules marqués « doublon » dans `tool/branchement_tolere.txt` n'en sont pas** (§B).
  - `carte_feedback_seance.dart` est le seul écran d'une fonction serveur déjà branchée.
  - `signalement_seance.dart` est le raccord qui manque à la salle pour « Signaler un besoin ».

  Les supprimer le 08/11, comme l'écrit la liste tolérée, retirerait une fonction réelle et non
  un doublon.
- **Sept tests de protection des enfants portent sur la feuille morte.** Le premier groupe de
  `test/features/protection_enfants/signalement_securite_test.dart` vise
  `tc_flux_academique/feuille_signalement.dart`, que l'application n'atteint pas. Supprimer cette
  feuille sans porter ces tests sur la feuille branchée (`SignalerBesoin`) ferait perdre leur
  couverture. Je n'ai pas vérifié que `SignalerBesoin` couvre les sept cas (responsable vide ou
  saisi, dépôt prioritaire, panne de lecture).
- **Supprimer le support actif rend un adaptateur orphelin.** Si le directeur accepte la ligne
  A8, `portSupportActifProvider` reste posé dans `lib/main.dart:568` avec `SupportActifSupabase`,
  sans aucun écran pour le lire. C'est une décision de plus à prendre : garder l'adaptateur, ou le
  retirer avec la ligne.
- **La preuve vient du graphe d'imports, pas d'une exécution.** Le relevé est fait sur `main` du
  03/11/2026 (`54a64ff2b`) depuis `lib/main.dart`, démonstration et `_dev` exclus. Les imports
  relatifs et `package:` sont résolus fichier par fichier : deux fichiers de même nom ne sont
  donc pas confondus (`alertes/feuille_signalement.dart`, branché, n'est pas
  `tc_flux_academique/feuille_signalement.dart`). Aucun analyseur n'a été lancé après une
  suppression simulée.
- **Rien de ceci n'est prouvé par le directeur en production.** Aucun de ces modules ne s'y voit,
  par définition.

## Méthode

Un module entre dans la liste A s'il remplit deux conditions :

1. **Aucun appelant en production** : aucun fichier atteint depuis `lib/main.dart` (hors
   démonstration) ne l'importe.
2. **Un module branché fait la même chose** : il est atteint depuis `lib/main.dart`, et le chemin
   d'import ou la route est cité.

Les appelants restants sont des tests. Pour chacun, le relevé indique s'il disparaît avec le
module (test qui ne vise que lui) ou s'il faut l'amender (test qui vise aussi des modules
branchés).

Candidats examinés :

- les 16 lignes « doublon d'un module branché » de `tool/branchement_tolere.txt` ;
- les lignes « Doublon » de `docs/current/INVENTAIRE-NON-BRANCHE-2026-10-31.md` §A ;
- `core/offres/port_demandes_horaires.dart`, que l'inventaire §B dit recouvrir
  `admin_regroupements`.

## A. Doublons prouvés, proposés à la suppression

13 fichiers, 2 585 lignes de `lib/`.

| # | Module (lignes) | Aucun appelant en production | Module branché qui le remplace | Tests à supprimer avec | Tests à amender |
|---|---|---|---|---|---|
| A1 | `lib/features/tc_dock/teaching_dock.dart` (504) | importé seulement par deux tests | `lib/features/salle_seance/barre_outils_salle.dart`, atteint par `salle_ordinateur.dart` et `telephone_enseignant.dart` | `test/teaching_core/d/dock_widget_test.dart` (18) | `test/teaching_core/salle_robuste_test.dart` |
| A2 | `lib/features/tc_dock/puce_intention.dart` (32) | importé seulement par un test | `barre_outils_salle.dart` nomme les quatre tons d'intention (`couleursEcriture`, ligne 70, sur `core/tc_outils/couleur_intention.dart`) | `test/teaching_core/d/intention_couleur_test.dart` (7) | aucun |
| A3 | `lib/features/tc_catalogue/class_library_picker.dart` (102) | importé seulement par un test | `lib/features/salle_seance/bibliotheque_seance.dart` (même `SurfaceBibliotheque`, ligne 184), atteint par `salle_seance.dart` ; `panneau_bibliotheque_salle.dart`, atteint par `salle/salle_page.dart` | `test/teaching_core/b/class_library_picker_test.dart` (5) | aucun |
| A4 | `lib/features/tc_flux_academique/panneau_post_cours.dart` (340) | importé seulement par deux tests | `lib/features/cahier/cahier_page.dart` (cahier de transmission), route posée par `core/router/app_router.dart` | `test/teaching_core/h/panneau_post_cours_test.dart` (4) | `salle_robuste_test.dart` |
| A5 | `lib/core/tc_parcours/port_post_cours.dart` (330) et `post_cours_vm.dart` (130) | importés seulement par A4 et par des tests ; `PostCoursDepuisCahier` relit le cahier | même remplaçant que A4 | `test/teaching_core/h/post_cours_test.dart` (18) | `salle_robuste_test.dart` |
| A6 | `lib/features/tc_flux_academique/feuille_signalement.dart` (288) | importé seulement par cinq tests | `SignalerBesoin` et `ouvrirSignalement` (`lib/features/fiche_groupe/fiche_eleve_enseignant.dart:90`, `:398`), atteints par `fiche_groupe_page.dart` et `revue_groupe_page.dart` ; ils portent la catégorie « Sécurité d'un enfant » (`:326`) | `test/teaching_core/h/feuille_signalement_test.dart` (7) | **à porter avant toute suppression** : `test/features/protection_enfants/signalement_securite_test.dart` (premier groupe, 7 cas) ; à amender : `salle_robuste_test.dart`, `test/features/coupe_mots_4/autres_appelants_coupe_mots_4_test.dart`, `test/capture/form_l1_7_13_correctifs_capture_test.dart` |
| A7 | `lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart` (196) | importé seulement par deux tests | `lib/features/accueil_famille/accueil_famille_page.dart:227` (`travailAVenirProvider`, même `PortTravailAVenir`) et `liste_preparation.dart` | `test/teaching_core/h/bloc_avant_prochain_cours_test.dart` (5) | `test/accessibilite/tuteur_k_echelle_texte_test.dart` |
| A8 | `lib/features/tc_catalogue/support_actif/support_actif_classe.dart` (174) et `presenter_port.dart` (89) | importés seulement par un test | la salle présente par LiveKit : `ContenuPresente` et `VideoSessionProvider.presenterContenu` (`lib/features/salle/salle_page.dart:137`, `:1262`), depuis `bibliotheque_seance.dart:133` | `test/features/tc_catalogue/support_actif_test.dart` (15) | aucun ; **décision en plus** : `SupportActifSupabase` (`lib/main.dart:568`) n'a plus de lecteur |
| A9 | `lib/core/tc_parcours/feedback_memoire.dart` (144) et `rotation_feedback.dart` (141) | importés seulement par des tests ; `rotation_feedback` ne sert qu'à `feedback_memoire` | `lib/core/tc_parcours/feedback_supabase.dart`, posé par `lib/main.dart:560` ; la rotation est décidée par le serveur (`question_feedback_pour`, `supabase/migrations/0065_feedback_questions_and_private_aggregate.sql:51`) | `test/teaching_core/h/feedback_test.dart` (10), `test/teaching_core/h/rotation_feedback_test.dart` (9) | `test/teaching_core/h/carte_feedback_test.dart` et `autres_appelants_coupe_mots_4_test.dart` (ils montent la carte du §B1 sur ce faux port : il faut un autre faux port) |
| A10 | `lib/core/offres/port_demandes_horaires.dart` (115) | importé seulement par un test | `lib/core/offres/port_regroupements_admin.dart` et `port_suivi_demandes.dart`, tous deux atteints (`regroupements_c11bis_supabase.dart`, `demandes_suivi_supabase.dart`) | `test/core/offres/port_demandes_horaires_test.dart` (3) | aucun |

Nombre de tests : entre parenthèses, les `test` et `testWidgets` du fichier.

Supprimer toute la liste A retire 11 fichiers de test, 101 tests. Il faut aussi amender
5 autres fichiers de test, et porter sur `SignalerBesoin` les 7 cas de protection des enfants
de `signalement_securite_test.dart`. `tool/branchement_tolere.txt` perd
13 lignes, et son plafond baisse d'autant.

## B. Marqués « doublon », mais ce n'en est pas un : à garder

| # | Module | Pourquoi ce n'est pas un doublon | Preuve |
|---|---|---|---|
| B1 | `lib/features/tc_flux_academique/carte_feedback_seance.dart` (130) | C'est le **seul** écran qui lit `portFeedbackProvider`. Or ce port est branché en production sur un vrai serveur. Le supprimer laisse la fonction serveur sans aucun écran. | `lib/main.dart:560` pose `FeedbackSupabase` ; la seule lecture du port dans `lib/` est `carte_feedback_seance.dart:107` ; serveur `0065_feedback_questions_and_private_aggregate.sql` |
| B2 | `lib/features/salle_seance/signalement_seance.dart` (42) | Ce n'est pas une seconde feuille de signalement. C'est le raccord qui ouvre la feuille branchée (`ouvrirSignalement`) depuis la salle. La salle a la place « Signaler un besoin », mais sans propriétaire. | `signalement_seance.dart` importe `fiche_groupe/fiche_eleve_enseignant.dart` ; `panneau_eleves.dart:677` porte `onSignaler` ; `salle/salle_page.dart:1327` : « "Noter" et "Signaler" n'ont pas encore de propriétaire » ; seul appelant : la démonstration (`features/demo/demo_salle_page.dart:47`) |

Proposition pour le §B, à décider :

- retirer la mention « doublon » de ces deux lignes dans `tool/branchement_tolere.txt` ;
- leur donner une issue « branché à l'étape X » :
  - B1 à l'écran de l'élève après une séance ;
  - B2 au lot de la séance en arrière-plan (inventaire du 31/10, ordre 1).

## C. Écartés de la liste, et pourquoi

- `core/tc_etat_partage` : branché en partie ; ses types et son codec servent à la salle
  (inventaire §A). Ce n'est pas un module mort.
- `core/capacites/port_resume_seance_famille.dart` : aucun appelant en production, mais je n'ai
  pas trouvé de module branché qui fasse la même chose. Ce n'est donc pas un doublon prouvé ; il
  reste dans la catégorie « aucun usage » de la liste tolérée.
- `features/accueil_adulte/historique_seances_adulte_page.dart` : l'inventaire dit qu'il
  « double l'onglet Suivi », mais il est atteint par sa route. Il appartient au lot de l'élève
  adulte, pas à cette liste.
- Les autres lignes « aucun usage » ou « démonstration » de la liste tolérée : pas de module
  branché en face, donc pas de doublon. Elles ne sont pas le sujet de M1.

## Question groupée au directeur

Pour chaque ligne, oui ou non :

1. **A1 à A10** : supprimer ces 13 fichiers et leurs tests, dans un lot à part, en portant
   d'abord sur `SignalerBesoin` les 7 cas de protection des enfants (A6).
2. **A8, adaptateur** : si oui à A8, retirer aussi `SupportActifSupabase` et son port, ou les
   garder.
3. **B1 et B2** : les garder, et corriger leur ligne dans `tool/branchement_tolere.txt` (étape de
   branchement au lieu de « supprimé le 08/11 »).
