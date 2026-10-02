# EA-12 : rapport de recette — vague Élèves adultes

**Suite complète EA-12 (clôture, un seul passage sous verrou `flutter-verrou.ps1`)** :
`flutter analyze` sans remarque ; `flutter test --reporter failures-only`
(1 297 s) : **3820 réussis, 1960 ignorés (captures sans `CAPTURE_DIR`), 0
échec**. Commit `510acbb` sur `origin/ui/eleves-adultes-v1` (inchangé, aucun
test à corriger). Journal complet : `build/suite_ea12.txt`.

**Portée.** Démonstration seulement (K-28, F24). Recette frontend : chaque
critère est vérifié par un test qui part de la vraie coquille adulte et de la
vraie route `/demo/adulte` (`routesDemoAdulte`), jamais par une simulation à
côté (K-07). Aucun écran ni aucune fonction n'a été ajouté ici ; seuls des
tests ont été écrits ou complétés.

**Commit de la recette** : `298ba34` sur `ui/eleves-adultes-v1` (base
`43e0682`), poussé. Fichier ajouté :
`test/features/adulte_recette/recette_ea12_test.dart` (220 tests, tous
verts ; `dart analyze` à 0 sur les fichiers touchés).

**Méthode.** Pour les critères déjà couverts écran par écran (EA-5 à EA-11),
ce rapport cite le test existant plutôt que de le dupliquer. Pour les quatre
balayages transverses demandés par la tâche EA-12a (mot « admin », valeurs
économiques en dur, confidentialité du second adulte sur les 25 états, porte
de production), un seul fichier neuf les couvre : `recette_ea12_test.dart`.
Quand aucun test n'a été trouvé ni écrit dans le temps imparti, la ligne dit
« non vérifié » et la raison, plutôt que d'affirmer une preuve qui n'existe
pas.

---

## 1. Critères du doc §21 (recette fonctionnelle minimale)

| # | Critère (doc §21) | Preuve (fichier:test) | Résultat |
|---|---|---|---|
| 1 | Un adulte « Moi uniquement » ouvre « Ajouter ma famille » sans perdre son profil élève | `mon_espace_adulte_page_test.dart` (entrée `ajouterMaFamille`, cas `adulteSeul`) ; écran provisoire confirmé par `demo_adulte_page.dart` (`ajouterMaFamille`, EA-4) | OK |
| 2 | Le titulaire voit un libellé conjoint/conjointe cohérent avec son genre | `foyer/inviter_conjoint_test.dart` (« Ajouter un conjoint », titulaire femme, F3) ; `foyer/ma_famille_adulte_test.dart` (ligne 277, F3) | OK |
| 3 | Un seul second adulte peut être actif | `foyer/ma_famille_adulte_test.dart` (place adulte à une seule ligne, aucune liste) ; modèle `DonneesAdulteDemo.place` à une seule place (EA-BR-14) | OK (démonstration ; le serveur devra le garantir, EA-BR-14/15) |
| 4 | Une seule invitation peut être en attente | `foyer/inviter_conjoint_test.dart` (ligne 539, F5/F21) | OK |
| 5 | Une invitation annulée ne déclenche aucun cooldown | `adulte_demo.dart` (états `invitationAnnulee` → place libre sans date de délai, doc F5) ; vérifié par `recette_ea12_test.dart` (balayage (a) sur l'état `invitationAnnulee`, aucune date affichée en plus du texte attendu) | OK en démonstration ; non branché (EA-BR-15) |
| 6 | Un départ effectif déclenche 60 jours au premier remplacement | `foyer/ma_famille_adulte_test.dart` (état `delai60`, date rendue) ; `foyer/sortie_forfait_test.dart` (F17) | OK (date de démonstration fixe, jamais calculée) |
| 7 | Un nouveau départ ultérieur déclenche 120 jours | `foyer/ma_famille_adulte_test.dart` (état `delai120`, `secondDepart`, `departsSuivants`) | OK |
| 8 | Le délai ne dépasse jamais 120 jours | `adulte_demo.dart` : états `secondDepart`/`delai120`/`departsSuivants` partagent la même règle (120, jamais plus) ; pas de test qui additionne au-delà | OK par construction des données ; **non prouvé par un test dédié qui échouerait si un futur état inventait 180 jours** (point ouvert #1) |
| 9 | Un refus Admin ne redémarre pas le délai | `foyer/ma_famille_adulte_test.dart` (état `validationRefusee` : ligne « Validation refusée par la direction » + « Faire une nouvelle demande », sans remise à zéro visible) ; EA-BR-18 | OK |
| 10 | Le conjoint sortant conserve son compte et son solde | `foyer/sortie_forfait_test.dart` (texte F15 : « ne seront pas supprimés ») | OK |
| 11 | Le titulaire est notifié si le conjoint quitte | `foyer/sortie_forfait_test.dart` (notification F16, doc §9.3) | OK |
| 12 | Le conjoint est notifié s'il est retiré | `foyer/sortie_forfait_test.dart` (idem, texte accordé au genre, F16) | OK |
| 13 | Le titulaire prépare une recharge nominative pour tous les bénéficiaires, conjoint inclus | `foyer/recharge_foyer_adulte_test.dart` (un/plusieurs/tous les bénéficiaires, F11) | OK |
| 14 | Chaque bénéficiaire conserve son propre solde | `foyer/paiements_foyer_adulte_test.dart` (une ligne par bénéficiaire, F9) | OK |
| 15 | Aucun prix/remise n'est calculé localement | `foyer/recharge_foyer_adulte_test.dart` (F12) ; `foyer/ma_famille_adulte_test.dart` (ligne 524, F12) ; balayage statique `recette_ea12_test.dart` (b) sur les fichiers Dart réels (foyer/*, compte/*, mon_espace_adulte, accueil_adulte, ma_classe_adulte) et sur le dictionnaire `adulte.*` (hors sélecteur de démonstration) | OK, avec une **exception connue et signalée** : le sélecteur `adulte.demo.etats.*` (délai60/120/repriseSansReponse) porte des « 60/120/30 jours » en dur — voir Défauts #1 |
| 16 | Un enseignant ne voit aucun détail familial | `ma_classe_adulte_page_test.dart:142` (F8) | OK |
| 17 | Le second adulte ne peut pas ajouter un enfant | `foyer/inviter_conjoint_test.dart` (ligne 588, F6) ; `mon_espace_adulte_page_test.dart` (aucune entrée Foyer pour le second adulte, F6/F7) | OK |
| 18 | Une demande de reprise du foyer notifie le titulaire et l'Admin | `foyer/reprise_foyer_test.dart` (notification titulaire) ; notification Admin non observable côté client (dossier futur vague Admin, hors périmètre) | OK côté client ; volet Admin hors périmètre (attendu) |
| 19 | Le titulaire peut refuser la demande | `foyer/reprise_foyer_test.dart` (« Refuser la demande », bouton principal sans confirmation, décision E5) | OK |
| 20 | Après 30 jours sans réponse, aucune reprise automatique n'a lieu | `foyer/reprise_foyer_test.dart` (ligne 280, F17 : état « en attente de l'administration », jamais « validée ») | OK |
| 21 | Une validation Admin reste obligatoire | `foyer/reprise_foyer_test.dart` (états `repriseValidee`/`repriseRefusee` rendus par le serveur de démonstration, jamais déduits côté client) | OK |
| 22 | La reprise transfère la titularité du foyer, pas le compte privé de l'ancien titulaire | `foyer/reprise_foyer_test.dart` (ligne 157, F6/F7 : rien du foyer ni des enfants tant que non validé ; aucune donnée privée de l'ancien titulaire affichée) | OK |
| 23 | L'émancipation conserve l'identité pédagogique et les données de l'élève | **Aucun test : le parcours d'émancipation n'existe pas dans le code de cette branche** (F19). Déjà signalé au directeur en EA-0/EA-1b (`00_REPRISE.md`, « Émancipation introuvable ») | **Non vérifiable — absence déjà signalée, pas une régression de EA-12** |

## 2. Règles F1 à F24

| Règle | Preuve | Résultat |
|---|---|---|
| F1 (le foyer n'est pas une fusion de comptes) | Conséquence vérifiée par l'ensemble F6/F7/F8 ci-dessous (ports séparés, aucune donnée croisée) ; aucun test ne porte le code « F1 » isolément | OK par construction, voir F6-F8 |
| F2 (titulaire unique, proche adulte retiré du formulaire) | `foyer/formulaire_profil_eleve_test.dart:200` | OK |
| F3 (libellés selon le genre) | `foyer/inviter_conjoint_test.dart`, `foyer/ma_famille_adulte_test.dart:277`, `foyer/captures_ea5_test.dart:130` | OK |
| F4 (invitation neutre) | `foyer/acceptation_invitation_test.dart:358`, `foyer/inviter_conjoint_test.dart:265,686`, `adulte_recette/captures_ea6_test.dart:300`, `captures_ea7_test.dart:275` | OK |
| F5 (dix états de l'invitation) | `foyer/inviter_conjoint_test.dart:539` ; états couverts dans `adulte_demo.dart` et balayés par `recette_ea12_test.dart` (a) | OK |
| F6 / F7 (permission ≠ bouton masqué, aucune donnée pédagogique croisée) | `mon_espace_adulte_page_test.dart` (25 états × 2 genres, lignes 268-330 et 833-876) ; `foyer/sortie_forfait_test.dart:247` ; `foyer/paiements_foyer_adulte_test.dart:257` ; `foyer/recharge_foyer_adulte_test.dart:448` ; `foyer/ma_famille_adulte_test.dart:304` ; **renforcé ici** par `recette_ea12_test.dart` (a)+(c) : accès direct par adresse à `maFamille` en vue second adulte, sur les 25 états, jamais de `FoyerPage` ni de prénom d'enfant | OK |
| F8 (l'enseignant ne voit rien du foyer) | `ma_classe_adulte_page_test.dart:142` | OK |
| F9 / F10 (un profil = un solde, vue minimale du titulaire) | `foyer/paiements_foyer_adulte_test.dart` | OK |
| F11 (recharge groupée, récapitulatif séparé) | `foyer/recharge_foyer_adulte_test.dart:170,225` | OK |
| F12 (aucun chiffre économique en dur) | `foyer/recharge_foyer_adulte_test.dart`, `foyer/ma_famille_adulte_test.dart:524`, `mon_espace_adulte_page_test.dart:159` ; balayage statique `recette_ea12_test.dart` (b) | OK, exception signalée (Défauts #1) |
| F13 (pas de faux succès au paiement) | `foyer/recharge_foyer_adulte_test.dart:290` | OK |
| F14 / F15 (sortie sans accord de l'autre, rien supprimé) | `foyer/sortie_forfait_test.dart` | OK |
| F16 (notification obligatoire des deux côtés) | `foyer/sortie_forfait_test.dart` | OK |
| F17 (délai rendu par le serveur, jamais calculé) | `foyer/ma_famille_adulte_test.dart:915`, `foyer/sortie_forfait_test.dart`, `foyer/reprise_foyer_test.dart:280`, `foyer/reprise_foyer.dart:483` (commentaire de garde) | OK |
| F18 (reprise = succession de titularité) | `foyer/reprise_foyer_test.dart` (en entier) | OK |
| F19 (émancipation préservée) | Non trouvé dans le code ; absence déjà signalée (voir §21 critère 23) | **Point ouvert**, pas une régression EA-12 |
| F20 (espaces séparés, 4 destinations, une seule entrée pour une fonction) | `adulte_recette/captures_ea_test.dart` (coquille à 4 destinations sur tous les écrans) ; `mon_espace_adulte_page_test.dart` (entrée unique « Ajouter ma famille ») | OK |
| F21 (l'état d'une place se lit sur sa ligne) | `foyer/ma_famille_adulte_test.dart:209` | OK |
| F22 (textes du doc §19 repris mot pour mot) | Revue documentaire `UX_REVIEW_07_ELEVES_ADULTES.md` (EA-1a, préalable obligatoire) ; contrôles ponctuels de texte exact dans `foyer/reprise_foyer_test.dart` et `foyer/sortie_forfait_test.dart` | OK sur les textes contrôlés ; **pas de balayage automatique mot-à-mot contre le doc §19 dans le temps imparti** (point ouvert #2) |
| F23 (droit anglais, minimisation) | Essentiellement serveur (durée de conservation, minimisation) ; côté client, `EA-BR-20` note que la phrase de durée de conservation est omise en démonstration faute de valeur | **Hors portée client**, cohérent avec le périmètre FRONTEND ONLY |
| F24 (démonstration seulement) | `recette_ea12_test.dart` (d) : `routesDemoAdulte`/`environnementAutoriseDemo` fermés en production et en environnement vide/mal déclaré | OK |

## 3. Matrice §16 (qui voit quoi)

| Ligne de la matrice | Preuve | Résultat |
|---|---|---|
| Voir son propre espace élève | `accueil_adulte_page_test.dart`, `ma_classe_adulte_page_test.dart` | OK |
| Ajouter un profil mineur (titulaire seul) | `foyer/formulaire_profil_eleve_test.dart` | OK |
| Inviter le second adulte (titulaire seul) | `foyer/inviter_conjoint_test.dart` (ligne 588 : le second adulte n'invite personne) | OK |
| Annuler une invitation en attente (titulaire seul) | `foyer/inviter_conjoint_test.dart` | OK |
| Quitter le forfait (second adulte seul) | `foyer/sortie_forfait_test.dart` | OK |
| Retirer le second adulte (titulaire seul) | `foyer/sortie_forfait_test.dart` | OK |
| Initier une recharge foyer (titulaire seul) | `foyer/recharge_foyer_adulte_test.dart:448` (le second adulte n'atteint jamais la recharge) | OK |
| Voir données pédagogiques du conjoint (personne, hors soi-même) | `mon_espace_adulte_page_test.dart` (25 états), `ma_classe_adulte_page_test.dart` | OK |
| Voir données pédagogiques des mineurs (titulaire/Tuteur seulement) | `mon_espace_adulte_page_test.dart`, `recette_ea12_test.dart` (c) | OK |
| Demander reprise du foyer (second adulte seul) | `foyer/reprise_foyer_test.dart` | OK |
| Valider remplacement adulte / reprise (Admin seul) | Aucune action cliquable côté client ; les écrans adulte ne proposent que « déposer » et « refuser » (vérifié par absence de tout bouton de validation dans `foyer/reprise_foyer_test.dart` et `recette_ea12_test.dart` (a), qui garantit aussi l'absence du mot « admin ») | OK |

## 4. Exigences §17 vérifiables côté client

| Exigence | Preuve | Résultat |
|---|---|---|
| Confidentialité entre les deux adultes | `mon_espace_adulte_page_test.dart` (25 états × 2 genres) + F6/F7 ci-dessus | OK |
| Les enfants ne sont jamais visibles du second adulte | `mon_espace_adulte_page_test.dart` + `recette_ea12_test.dart` groupe (a)/(c) : aucun `FoyerPage`, aucun prénom d'enfant, sur `maFamille`, `forfaitFamille`, `repriseFoyer`, pour les 25 états × (ici) 1 genre croisé avec l'autre dans le balayage par écran | OK |
| Aucune démonstration atteignable en production | `recette_ea12_test.dart` groupe (d) : `routesDemoAdulte('production')` et variantes de casse/espaces renvoient une liste vide ; `environnementAutoriseDemo` refuse aussi un environnement vide | OK |

---

## Défauts trouvés

| # | Fichier:ligne | Constat | Gravité | Correction proposée |
|---|---|---|---|---|
| 1 | `assets/i18n/fr.i18n.json` (clés `adulte.demo.etats.delai60`, `.nouvelleDemande`, `.delai120`, `.departsSuivants`, `.repriseSansReponse`) | Le sélecteur de démonstration de `/demo/adulte` (le menu qui liste les 25 situations) écrit en dur « 60 jours », « 120 jours » et « 30 jours » dans ses libellés. Ce n'est pas un écran vu par un client réel (c'est l'outil de pilotage de la démonstration elle-même), mais la lettre de F12/F17 (« aucun délai en dur ») est techniquement enfreinte à cet endroit précis. La tâche EA-12a demande explicitement de signaler ce point sans le corriger ici. | Mineur | En EA-RC : soit accepter l'exception et la documenter formellement dans F12/F17 (le sélecteur de démonstration n'est pas un écran produit), soit rendre ces libellés depuis `adulte_demo.dart` (déjà la source des dates F17) plutôt que depuis le dictionnaire de traduction. |

Aucun autre défaut de code n'a été constaté dans le temps imparti : les écrans réels (`foyer/*.dart`, `compte/*.dart`, `mon_espace_adulte/*.dart`, `accueil_adulte/*.dart`, `ma_classe_adulte/*.dart`) ne contiennent aucune occurrence de `%`, `€` ou délai en jours hors commentaire (vérifié par balayage statique, `recette_ea12_test.dart` (b)), et aucun des écrans parcourus par (a) ne contient le mot « admin ».

## Points ouverts

1. **§21 critère 8 (délai jamais > 120 jours)** : prouvé par la construction des données de démonstration, pas par un test qui échouerait si un état futur introduisait une valeur supérieure. À renforcer en EA-RC par un test qui lit `adulte_demo.dart` et vérifie qu'aucune valeur de délai ne dépasse 120 jours, plutôt que de se fier à l'absence d'un tel état aujourd'hui.
2. **F22 (textes du doc §19 mot pour mot)** : la vérification de fond a eu lieu en EA-1a (`UX_REVIEW_07_ELEVES_ADULTES.md`) et quelques textes sont recontrôlés par des tests ponctuels (reprise, sortie). Il n'existe pas de balayage automatique qui compare chaque texte affiché au doc §19 phrase par phrase ; non refait ici par manque de temps (tâche bornée à 35 minutes).
3. **F19 (émancipation)** et le critère §21-23 qui en dépend restent non vérifiables : le parcours n'existe pas dans cette branche. Ce n'est pas une régression de EA-12, le constat avait déjà été fait et transmis au directeur en EA-0/EA-1b (`16_eleves_adultes/00_REPRISE.md`). Je le rappelle ici pour que le rapport EA-12 ne donne pas l'impression que ce point est clos.
4. **§16, ligne « Valider remplacement adulte / Valider reprise du foyer » (Admin)** : vérifiée uniquement par l'absence côté client (aucun bouton de validation, aucun mot « admin ») ; la vraie preuve (que l'administration seule peut valider) est un besoin serveur déjà tracé (EA-BR-27, EA-BR-28, dossiers de la vague Admin), hors périmètre de cette branche.
5. Le balayage (a)/(c) de `recette_ea12_test.dart` couvre 220 cas mais pas la totalité du produit cartésien écran × état × genre × vue (qui serait de plusieurs milliers de rendus) : il cible les écrans où le texte dépend le plus de l'état (`maFamille`, `placeAdulte`, `repriseTitulaire`, `forfaitFamille`, `repriseFoyer`) et ceux qui restent (comme la coquille des 4 destinations ou Mon espace) sont balayés une fois par genre/vue plutôt que sur les 25 états. La couverture complète à 25 états existe déjà par ailleurs pour la confidentialité (`mon_espace_adulte_page_test.dart`).

## Tests et chiffres

- `dart analyze` sur les fichiers touchés : **0 problème**.
- `flutter test test/features/adulte_recette/recette_ea12_test.dart` : **220 tests, 220 réussis, 0 échec**, en 26 s (verrou flutter-verrou.ps1, durée totale mesurée 43 s avec démarrage de l'outil).
- La suite complète (3600 tests) **n'a pas été relancée** dans cette tâche : la tâche demandait de lancer « ces tests » (ceux de la recette), et le budget de 35 minutes ne permettait pas en plus une suite complète. À relancer avant le passage à `verifie` (K-29), conformément à la définition de « fait » du découpage.

## Captures (EA-12b)

**Commit** : `510acbb` sur `ui/eleves-adultes-v1` (base `298ba34`, elle-même sur `43e0682`), poussé. Fichier ajouté : `test/features/adulte_recette/captures_ea12_test.dart` (50 tests, 50 réussis, 0 échec, `dart analyze` à 0 sur le fichier). Les écrans adulte en 390/768/1440, clair et sombre, plus 200 % en 390, avaient déjà été capturés écran par écran en EA-2 à EA-11 (voir les commits de captures de chaque étape) ; cette tâche ne les refait pas, elle comble cinq trous relevés en inventoriant `test/features/adulte_recette/captures_ea*_test.dart` et les dossiers `build/captures/ea-*` existants :

| # | Trou | Pourquoi c'était un trou | Capture ajoutée |
|---|---|---|---|
| 1 | EA-10, l'état hors ligne de la recharge | La VRAIE route `/demo/adulte` force `horsLigneProvider` à `false` pour tout écran hors Accueil/Ma classe (`demo_adulte_page.dart`) ; `captures_ea10_test.dart` ne le capture donc jamais, même si le code de l'écran gère déjà ce cas (vérifié par `recharge_foyer_adulte_test.dart`, test « hors ligne : dit comme tel »). Montée directement sur `RechargeFoyerPage` avec `hoteCapture`, `horsLigneProvider` à vrai et un port dont la lecture échoue, comme `captures_ea11_test.dart` le fait déjà pour le D5 de `RepriseTitulairePage`. | 390/768/1440 clair/sombre + 200 % (7 PNG) |
| 2 | EA-8, le lien « Demande de reprise du foyer » de Forfait famille | Le lien (`ForfaitFamillePage.repriseKey`) a été ajouté en EA-11, après les captures d'EA-8 ; `captures_ea8_test.dart` capture la page entière mais sans défiler jusqu'au lien ni le nommer dans le fichier. | 390/768/1440 clair/sombre + 200 %, défilée jusqu'au lien (7 PNG) |
| 3 | EA-4, Mon espace de l'adulte seul | `captures_ea4_test.dart` ne le capture qu'à 390 (clair/sombre/200 %) ; titulaire et second adulte ont 768/1440, pas l'adulte seul. | 768/1440 clair/sombre (4 PNG) |
| 4 | EA-7, invitation reçue (acceptée, refusée, erreur réseau) | `captures_ea7_test.dart` capture ces trois états seulement à 390 ; l'étape 1 et les notifications ont déjà 768/1440, pas les réponses. | 768/1440 clair/sombre pour chacun des trois états (12 PNG) |
| 5 | EA-11, les cinq états rendus de la reprise | `captures_ea11_test.dart` capture les cinq états (déposée, refusée par le titulaire, attente de l'administration, validée, refusée) seulement à 390 ; l'explication et la décision du titulaire ont déjà 768/1440, pas les cinq états. | 768/1440 clair/sombre pour chacun des cinq états (20 PNG) |

**Total : 50 PNG**, listés avec leur chemin dans `planche.json` (modèle `05_recette/AD/planche.json`). Produits par `flutter test test/features/adulte_recette/captures_ea12_test.dart --reporter expanded` sous `flutter-verrou.ps1`, `CAPTURE_DIR=build/captures/ea-12` ; copiés tels quels dans `16_eleves_adultes/captures/ea12`.

**Relecture.** 8 PNG ouverts et regardés un par un par l'agent avant publication : `ea12_recharge_hors_ligne_390_light`, `_390_dark`, `_390_light_200pc` (bandeau hors ligne lisible, « Réessayer » entier, aucun débordement même à 200 % où le titre passe sur deux lignes proprement) ; `ea12_forfait_lien_reprise_390_light` (le lien « Demande de reprise du foyer » visible sous « Quitter le forfait famille », aucun chevauchement) ; `ea12_invitation_acceptee_1440_dark` (mise en page bureau correcte, rail et contenu alignés, aucun mot « admin » visible) ; `ea12_invitation_echec_reseau_768_light` (le message D5 « L'acceptation n'a pas été confirmée. Vérifiez avant de réessayer. » complet, lisible) ; `ea12_reprise_etat_validee_1440_light` (tableau Motif/Déposée le/État lisible, « L'administration a validé la demande » sans le mot « admin ») ; `ea12_mon_espace_adulte_seul_768_dark` (sombre lisible, contrastes corrects, « Non disponible » entier à côté de chaque légende). **Aucun défaut constaté** dans les 8 PNG relus (pas de coupure, pas de débordement, pas de texte tronqué à 200 %, pas de sombre illisible).

**Limite assumée.** Ces 50 captures ciblent les cinq trous relevés par l'inventaire, pas une reprise intégrale de tous les écrans × 25 états × 3 largeurs × 2 thèmes (plusieurs milliers de rendus, déjà hors de portée d'EA-12 §19, point ouvert #5 du rapport EA-12a). Les autres écrans restent couverts par les commits de captures d'EA-2 à EA-11, non repris ici.
