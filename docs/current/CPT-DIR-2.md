# CPT-DIR-2 : fiche board5 (Q-9, Q-10, Q-11, libellés)

Branche `ui/cpt-dir-2`, base `origin/ui/cpt-val` @ b26add64 (ui/comptable-v1 avec
l'onglet « À valider » de CPT-VAL-1, dont le comportement n'est pas modifié).
Statuts : **présent dans le code et testé localement**, rien n'est déployé.

## 1. Q-9 cpt-pourcent = (a) : pourcentages masqués avec les montants

- Nouveau composant `lib/core/widgets/comptable/pourcentage_sensible.dart` :
  `PourcentageSensible` (texte) et `JaugeSensible` (jauge). Ils suivent la même
  bascule que `MontantSensible` (`visibiliteMontantsProvider`), le même point de
  masque (`MontantSensible.point`), une longueur fixe (« •• % atteint » pour 8 %
  comme pour 100 %), et le lecteur d'écran lit « Montant masqué », jamais le
  chiffre. Le style est le même dans les deux états : la ligne ne bouge pas.
- Branché sur `CarteReserveStrategique` (« 82 % atteint » et sa jauge, donc
  Aujourd'hui, Trésorerie et l'onglet Réserve et délégation) et `CarteCoffre`
  (« 29,2 % de la trésorerie détenue »).
- Décidé par délégation le 05/10 : la **jauge** est vide quand les montants sont
  masqués (sa longueur dirait le pourcentage aussi sûrement que le chiffre) ; les
  pourcentages **de règle** (part automatique, seuil d'alerte de la politique) ne
  dérivent d'aucun montant et restent affichés.
- `montant_sensible.dart` (gelé) n'est pas modifié : le nouveau composant
  réutilise sa constante et son libellé.

## 2. Q-10 cpt-arabe = (a) : l'espace Comptable en arabe

- `assets/i18n/ar.i18n.json` : les 843 clés `comptable.*` (dont
  `comptable.validation.*`, `comptable.direction.*`, `comptable.demo.*`),
  `admin.finance.aValider`, et les textes des composants partagés affichés dans
  l'espace Comptable (`commun.etats.*`, `commun.dates.jours/mois/jourDate`,
  `commun.reessayer`, `commun.annuler`, `commun.choix.indisponible`, `choix.*`,
  `destructif.irreversible`, `reseau.horsLigne`, `nav.principale/replier/deplier`).
- Pluriels arabes : formes `one`, `two`, `few`, `other` (résolveur arabe de slang).
- Vocabulaire fixé (aucune traduction arabe de la Finance n'existait avant, il
  devient la référence) : المدفوعات (paiements), الخزينة (trésorerie),
  المقبوضات (encaissements), المطابقة (rapprochement), الصناديق (coffres),
  الاحتياطي الاستراتيجي (Réserve stratégique), الالتزام (obligation), المصادقة
  (validation), الاعتماد (approbation), التفويض (délégation), مزوّد الدفع
  (prestataire), استرداد (remboursement), صرف دفعة (payout), المحاسب (Comptable).
- Chiffres et montants : la règle déjà appliquée dans l'app
  (`lib/core/finance/format_montant.dart`) est gardée telle quelle, mêmes
  chiffres et même forme qu'en français. En sens RTL, le nombre reste d'un seul
  tenant (séparateurs de classe CS de l'algorithme bidi) et la devise se place à
  sa gauche (« $ 9500 », lu « 9500 $ » de droite à gauche), masque compris
  (« $ ••,••• •• ») : montant affiché et masque sont cohérents. Les flèches de
  transition (`activiteTransition`, `transfert.couple`) passent à « ← » en arabe.
- Le nom « Rewayah » reste en caractères latins (marque).
- Reste : les **données de démonstration** (« Famille Bah », « Carte
  bancaire », « Prestataire A ») viennent des fichiers `lib/features/demo/comptable/*`
  et restent en français : ce ne sont pas des clés de traduction.

## 3. Q-11 cpt-registre = (b) : catalogue des écrans

Le catalogue général (`docs/design/08-catalogue-ecrans.md` sur `main`) a été
déplacé par la remise à plat du 23/09 dans
`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md` sur
cette lignée ; aucun autre catalogue d'écrans n'existe sous `docs/current/`.
Décidé par délégation le 05/10 : les entrées sont inscrites **dans ce fichier, à
son emplacement actuel**, plutôt que de recréer `docs/design/` (ce qui
défairait la remise à plat). Nouvelle section « Zone Comptable » au format du
registre : `CPT-01` (code gardé) à `CPT-13`, `ADM-18` (Réserve et délégation),
`ADM-19` (À valider), chacune avec un renvoi vers sa section de
`20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md` (branche `pilotage/tuteur-v1`).
À confirmer par l'orchestrateur si le catalogue doit revenir sous `docs/design/`.

## 4. Libellés

- `comptable.aujourdhui.aTraiterHorsPaiements` : « Autres tâches » ;
  `comptable.encaissements.rap.vueRemboursements` : « Remboursements ».
  Déclarations mises à jour dans `tool/libelles_sources.json`, « validé par
  délégation le 05/10 ».
- Les réponses `decisions/reponses/l-comptable*.json` ne contiennent que ces
  deux libellés (avis « change ») : aucun libellé `comptable.*` n'y a l'avis
  « bon », il n'y avait donc rien d'autre à marquer.

## 5. Preuves

Mesuré le 08/10 sous `flock /tmp/flutter.lock` :

- `dart run slang` : traductions générées sans erreur ;
- suite `test/features/comptable`, `test/features/admin_finance`,
  `test/features/demo`, `test/router` : **861 passés, 92 sautés, 0 échec** ;
- `dart analyze --fatal-infos` complet : **0 problème** ;
- `dart run tool/verifier_jetons.dart` : **39 → 39** ;
- `verifier_revue --detail` : 0 violation sur les clés `comptable.*` ;
- contre-épreuves : une clé `comptable.paiements.titre` retirée de l'arabe fait
  échouer le test arabe (« manquante : comptable.paiements.titre ») ;
  l'ancienne `CarteReserveStrategique` (b26add64) fait échouer 2 des 4 tests du
  pourcentage masqué ; retour à l'état de la branche : 7/7 passés.

Tests ajoutés :

- `test/features/comptable/socle/pourcentage_masque_test.dart` (4 tests :
  masqué, longueur fixe, affiché, bascule) ;
- `test/features/comptable/socle/arabe_comptable_test.dart` (3 tests : chaque
  clé présente, non vide, mêmes paramètres ; périmètre ; contre-épreuve
  intégrée) ;
- `tresorerie_page_test.dart` : la part détenue est masquée à l'entrée,
  affichée par la bascule.

Captures (ouvertes) : `docs/current/captures/CPT-DIR-2/`, 35 PNG : Aujourd'hui,
Paiements, Trésorerie, Encaissements en arabe RTL, montants affichés, à 390,
1440 et 320 ×2, clair et sombre (24) ; Trésorerie arabe montants masqués (1) ;
français montants masqués avec le pourcentage et la jauge masqués : Aujourd'hui
1440, Trésorerie Réserve et coffres 390 et 1440, clair et sombre (10).
Sur téléphone, Aujourd'hui ne montre pas la carte de la Réserve (une tâche
dominante, M01), d'où la Trésorerie à 390.
