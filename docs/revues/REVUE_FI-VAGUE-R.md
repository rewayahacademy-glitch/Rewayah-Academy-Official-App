# Revue croisée FI-VAGUE-R : vague Finance, `ui/finance-v1` @ `5198107f` (04/10/2026)

- **Branche revue** : `origin/ui/finance-v1`, tête `5198107f` (FI-COUPE-2).
- **Plage** : `aebd21a5..143b4876`, plus les corrections qui suivent jusqu'à `5198107f`.
- **Session** : cloud 01MrLWqB, en lecture seule. Aucun commit ni push sur la branche revue.
- **Date** : 04/10/2026.
- **Méthode** : revue par agents à contexte neuf, découpée en huit lots (R1 à R8). Chaque
  constat bloquant, majeur ou mineur est passé devant deux sceptiques indépendants. Les
  cosmétiques n'ont pas été contre-vérifiés, c'est dit à chaque fois.
- **Worktree de contrôle** : `/home/user/wt/fin`, `git status` vide en fin de revue. Aucun test
  temporaire écrit.

Règles de classement appliquées :

- **Confirmé** : aucun des deux sceptiques ne réfute.
- **Partagé** : un sceptique sur deux réfute. Le constat est classé à la gravité la plus basse
  proposée, et c'est dit.
- **Écarté** : les deux sceptiques réfutent.
- Quand les deux sceptiques confirment mais ne proposent pas la même gravité, je garde aussi
  la plus basse. C'est un choix de prudence, signalé à chaque constat concerné.
- Une étape est **REFUSÉE** seulement s'il lui reste un bloquant ou un majeur confirmé.

## Verdicts par étape

| Étape | Verdict | Raison courte |
|---|---|---|
| FI-4 | **REFUSÉE** | 4 majeurs : bouton plein inversé (R1-01), « Prochain débit » échu sur la carte (R1-05), `SoldesFoyerSection` gardée pour le titulaire adulte (R1-06), carte sans accès direct aux Finances (R1-08). |
| FI-5 | **REFUSÉE** | 2 majeurs : rangée de synthèse sans le 4e bloc bouton et note (R1-03), pas de composition à 768 (R1-04). R1-06 la touche aussi (E-11). |
| FI-5b | **REFUSÉE** | La grille bureau arrive avec `e5ae9053` et ne s'active pas avant 1200 px (R1-04, majeur, partagé avec FI-5). |
| FI-6a | **REFUSÉE** | 4 majeurs : composition bureau à 2 colonnes (R2-01), segments Général / Finances absents (R2-02), note sur les absences absente (R2-03), ordre et libellés des actions, reçu absent (R2-04). |
| FI-6b | **REFUSÉE** | 1 majeur : filtre par personne sans avatar, lignes sans icône ni heure (R2-05). |
| FI-7 | **REFUSÉE** | 2 majeurs : deux étapes et « Tout sélectionner » gardés (R3-01), pas de composition à 3 colonnes ni bandeau à 1440 (R3-02). |
| FI-8 | **REFUSÉE** | 1 majeur : la carte « Répartition par profil » n'a pas de marge intérieure (R3-03). |
| FI-9a | **REFUSÉE** | 1 majeur : états « accès suspendu » et « réactivation » sans modèle, copie ni test (R4-04). |
| FI-9b | **ACCEPTÉE AVEC RÉSERVES** | Aucun majeur. 1 mineur (R4-07), 2 cosmétiques (R4-05, R4-06). |
| FI-10 | **REFUSÉE** | 2 majeurs : pas de tableau à 1440 (R5-02), relevé absent sans état honnête (R5-03). |
| FI-11a | **REFUSÉE** | 2 majeurs : aucun graphique (R6-01), alertes sans cible (R6-04). |
| FI-11b | **REFUSÉE** | 2 majeurs : vocabulaire « Groupes » (R6-05), relance, budgets et activation de l'essai absents (R6-06). |
| FI-11c | **ACCEPTÉE** | Aucun constat. Une question au directeur sur l'exception du dossier `demo/`. |

Transverse : un majeur confirmé ne dépend d'aucune étape seule. La règle « aucun mot coupé à
320 px et 200 % » n'est mesurée que sur la fiche, la page Couleur et la carte membre isolée sans
finances (R8-03). Il empêche de
fermer la vague, même si toutes les étapes étaient corrigées.

Bilan après contre-vérification : 0 bloquant, 22 majeurs, 24 mineurs, 11 cosmétiques
(dont 7 non contre-vérifiés), 3 constats écartés ou ramenés à « info ». Six doublons entre
lots ont été fusionnés (liste plus bas).

## Commandes lancées et chiffres exacts

Toutes sur `/home/user/wt/fin` @ `5198107f`.

| Commande | Résultat |
|---|---|
| `dart analyze --fatal-infos` | No issues found. |
| `dart run tool/verifier_jetons.dart` | 39 violation(s). Exemples : `mouvement.dart:32` et `:35` (courbe-litterale), `admin_shell.dart:450` et `:600` (graisse-hors-typographie), `groupe_reglages.dart:353` (graisse-hors-typographie). Aucune dans un fichier Finance. Celles de `groupe_reglages.dart` et `admin_shell.dart` datent d'avant la vague (blame `760802cc`, `d3cb8575`). |
| `dart run tool/verifier_revue.dart` | 1618 violation(s), dont bouton-recompose 1, plein-multiple 16, avatar-recompose 2, avatar-taille 2. Aucune dans les fichiers du Foyer finance ni de `admin_finance` (sortie filtrée vide). Les 14 lignes plein-multiple du socle sont écrites avec `\` et ne filtrent pas sous Linux (R8-04). |
| `git status` | propre, aucune sortie. |

`flutter test`, un dossier à la fois :

| Dossier | Passés | Échoués | Sautés |
|---|---|---|---|
| foyer | 483 | 0 | 37 |
| admin_finance | 79 | 0 | 0 |
| mon_espace_adulte | 111 | 0 | 0 |
| revenus_enseignant | 23 | 0 | 0 |
| acces_finance | 41 | 0 | 0 |
| finance | 37 | 0 | 0 |
| finance_recette | 38 | 0 | 567 |
| fiche_eleve | 5 | 0 | 13 |
| **Total** | **817** | **0** | **617** |

Aucun échec, donc aucun nom de test ni message à signaler. Les sautés du foyer, de
`finance_recette` et de `fiche_eleve` sont des tests de capture (`sautSansCapture`, maquettes
absentes). Aucun test fonctionnel n'est sauté dans `test/features/foyer`.

Relances ciblées par les relecteurs : `fiche_eleve_finances_test` et
`fiche_eleve_mouvements_test` 66/66 ; `recharge_multi_profils_test` et
`resultat_recharge_test` 77 verts ; `revenus_enseignant` 23/0 ; `admin_finance` 79/0.

Captures : 8 fichiers de test lancés avec `CAPTURE_DIR` (`captures_fi_test`,
`captures_fi4_test`, `captures_fi12_test`, `captures_fi2_test`, `fiche_eleve_capture_test`,
`foyer_capture_test`, `formulaire_profil_eleve_capture_test`,
`test/capture/fi3c_argent_capture_test.dart`). Résultat : 594 verts, 18 sautés, 0 échec. Les
18 sautés sont les planches maquette | capture (`MAQUETTES_DIR` absent). 683 PNG produits,
65 gardés dans `docs/revues/captures/FI-VAGUE-R/`, 618 déplacés (aucune suppression) vers le
scratchpad de la session (`…/scratchpad/fi_all/`).

## Défauts

### Bloquants

Aucun.

### Majeurs

- **R1-01 (FI-4). « Ajouter un profil élève » reste le seul bouton plein du Foyer.**
  `lib/features/foyer/foyer_page.dart:202-208` (ActionPrincipale sans niveau, donc pleine) et
  `lib/features/foyer/finances_foyer.dart:119-128` (« Recharger plusieurs profils » en
  `NiveauAction.secondaire`). Le test `foyer_finances_test.dart:260-274` fige cet ordre.
  02_DECOUPAGE.md:62 et 00_REPRISE.md:84 demandent l'inverse (Q-FI-2 « Oui », E-17). Vu sur
  `fi4_cinqProfils_1440_light` et `fi4_unProfil_390_dark`. Correction : « Ajouter » en
  secondaire, « Recharger plusieurs profils » plein, test inversé. Le cas sans source de
  finances est une question au directeur.
- **R1-03 (FI-5). La rangée de synthèse bureau n'a pas ses 4 blocs.**
  `lib/core/widgets/resume_soldes.dart:77-105` aligne total, à payer, profils financés et
  paiements du mois. Le bouton est posé seul dessous (`finances_foyer.dart:130-142`). La note
  « Chaque enfant a un solde et une période financée individuels… » n'existe pas. Exigé par
  la revue ligne 2 a et 02_DECOUPAGE.md:36. Vu sur `fi4_cinqProfils_1440_light`. Correction :
  4e bloc = bouton puis note (nouvelle clé i18n), « Paiements du mois » gardé ailleurs
  (Q-FI-7).
- **R1-04 (FI-5, FI-5b). Aucune composition intermédiaire à 768.**
  `foyer_page.dart:160` et `:214` : la grille n'existe que pour `Gabarit.desktop` (1200 et
  plus). À 768, pile du téléphone étirée, libellés coupés (« À financer ce / mois »).
  `_largeurMinCarte` vaut 320, donc même activée la grille donnerait 1 colonne. Aucun test à
  768 de large (le test « 1024x768 » mesure 1024). Exigé par 02_DECOUPAGE.md:36 et :63, revue
  2 g. Capture dans le scratchpad (`fi4_cinqProfils_768_light`). Correction : grille dès la
  tablette, 2 colonnes vers 640 px utiles, synthèse sur 2 rangées sous 900 px, test à 768.
- **R1-05 (FI-4). La carte d'un enfant à régulariser affiche un « Prochain débit » déjà échu.**
  `finances_foyer.dart:208-226` affiche toujours `prochainDebit` et la phrase « Il manque 8 $
  pour la prochaine période ». En démo, le débit est le 1er octobre 2026 pour un jour de
  référence au 4 octobre (`finance_demo.dart:102`, `:270-279`). La fiche Finances du même
  enfant a été corrigée (`d7cbc70f`) : les deux écrans se contredisent. Les captures citées
  (`fi4_unARegulariser_*`) ne sont pas dans le dossier gardé, le code suffit à la preuve.
  Correction : partager `_moisAFinancer` et `_periodeNonFinancee` (core/finance), les
  réutiliser dans `BlocFinanceMembre`, test sur le jeu `unARegulariser`.
- **R1-06 (FI-4, FI-5). `SoldesFoyerSection` reste posée pour le titulaire adulte.**
  `foyer_page.dart:214` (`compositionBureau = bureau && adulte == null`) et `:275-281`,
  `paiements_page.dart:128`. Le titulaire garde l'ancienne composition à deux colonnes
  (« planche 6 », décision EA que E-11 remplace). Avec une source de finances, deux blocs de
  soldes et plusieurs « Recharger ». Exigé par 02_DECOUPAGE FI-4 (E-19), FI-5 (E-11), revue
  14 c et d. Le test `paiements_foyer_adulte_test.dart:286-330` fige l'ancien rendu.
  Correction : composition FI-5b pour le titulaire, retrait de `SoldesFoyerSection` des deux
  poses, tests EA mis à jour.
- **R1-08 (FI-4). Aucun geste direct vers les Finances d'un enfant financé.**
  `foyer_page.dart:567` envoie la carte vers `Routes.ficheElevePour` (Général). Aucune chaîne
  « Voir le détail » dans `fr.i18n.json`. Critère d'acceptation FI-4 (02_DECOUPAGE.md:35) :
  « Voir le détail » ouvre la fiche Finances. Les Finances restent à deux gestes.
  Correction : geste de carte ou action secondaire « Voir le détail » (nom lu avec le prénom)
  vers `Routes.ficheEleveSousPage(id, 'finances')` quand une finance est rendue, et test.
- **R2-01 (FI-6a). La fiche Finances bureau a 2 colonnes au lieu de 3.**
  `lib/features/foyer/fiche/finances_page.dart:527-537` : identité (flex 2) puis vue
  financière (flex 3). Il manque la colonne « Historique des transactions » avec « Voir
  tout », le groupe « Paramètres de l'élève » sous l'identité, le bandeau du bas à trois
  faits, le titre « {prénom} · Finances » et le fil d'Ariane. Exigé par revue 4 a, b, e,
  02_DECOUPAGE.md:64, 00_REPRISE.md:87. Correction : voir le suivi.
- **R2-02 (FI-6a). Pas de segments Général / Finances sous 1200 px.**
  `fiche_eleve_page.dart:354-362` ouvre les finances par une `LigneRubrique`. Q-FI-1 tranchée
  (00_REPRISE.md:86 et :121), 02_DECOUPAGE.md:64, revue 3 a. Aucun document ne remplace cette
  décision. Correction : `ControleSegmente` à deux segments sur la fiche et sur Finances, sans
  segmenté à 1200 et plus, ou décision écrite du directeur.
- **R2-03 (FI-6a). La note sur les absences (FIN4-04) manque.**
  « absences ordinaires » absent de `fr.i18n.json` et de `lib/`. Exigé par 02_DECOUPAGE.md:37,
  revue 3 f et lexique :220. Correction : clé `ficheEleve.finances.noteAbsences`, note sous la
  vue financière, dans le bandeau du bas sur bureau.
- **R2-04 (FI-6a). Ordre et libellés des actions, reçu absent.**
  `fr.i18n.json:1147` : `voirMouvements` vaut « Mouvements ». `finances_page.dart:538-557`
  met le lien avant le bouton plein. Aucune chaîne « Télécharger ». Exigé par revue 3 g et
  4 d, 02_DECOUPAGE.md:37 et :64. Correction : « Voir les mouvements », « Recharger
  {prénom} » d'abord puis le lien 8 px dessous, « Télécharger le reçu » secondaire sur bureau
  seulement si un reçu est rendu.
- **R2-05 (FI-6b). Filtre par personne sans avatar, lignes sans icône ni heure.**
  `mouvements_page.dart:262-264` : `EntreeFiltre(valeur, libelle)` sans avatar
  (`menu_filtre.dart:11-28`). `LigneTransaction` n'a pas d'icône. Les dates passent par
  `dateEcheance` (jour, mois, année). Critère FI-6b (02_DECOUPAGE.md:38) et guide §3.4
  « obligatoire ». Correction : entrée de filtre avec `ProfileIdentityAvatar`, icône par
  `NatureMouvement`, date avec l'heure locale.
- **R3-01 (FI-7, fusionné avec R7-01). La recharge garde les deux étapes d'EA-10 et « Tout
  sélectionner ».**
  `lib/features/foyer/recharge_foyer.dart:372-375` (`PageEtape(numero: etape2 ? 2 : 1,
  total: 2)`), `:247` et `:484-493` (`toutSelectionnerKey`), `:549-561` (seule action de
  l'étape 1 : « Vérifier la recharge », sans total). Exigé par 02_DECOUPAGE.md:66, 00_REPRISE
  :89, revue 6 a et e, E-4, E-14, guide §5.3. Seul X-6 touche FI-7, et il ne porte que sur
  Compte > Paiements. `ea3306d3` a même figé « Tout sélectionner » au lieu de le retirer. Vu
  sur `fi12_recharge_production_390_dark` (« 1 sur 2 »). Correction : voir le suivi.
- **R3-02 (FI-7). Pas de composition à 3 colonnes ni de bandeau « Accès à régulariser » à
  1440.**
  `recharge_foyer.dart:376` enveloppe tout dans `_Colonne`, bornée à
  `AppPage.largeurDialogue` et centrée (`invitation_conjoint.dart:897-912`). Aucun
  « régulariser » ni « Ajouter … à la recharge » dans le fichier. Exigé par 02_DECOUPAGE.md:39
  et :66, 00_REPRISE.md:90, revue 7 a et d, contrat D (« jamais une colonne de téléphone
  centrée »). Correction : composition de la maquette 07, bandeau `BandeauAttention` sans
  croix, test à 1440.
- **R3-03 (FI-8). La carte « Répartition par profil » du résultat n'a pas de marge
  intérieure.**
  `lib/features/foyer/resultat_recharge.dart:451-478` pose des `LigneAllocation` dans
  `CarteLignes`, qui n'ajoute aucun padding. `LigneCleValeur` n'a qu'un padding vertical
  (`ligne_cle_valeur.dart:154`). Avatar collé au bord gauche, montant contre le bord droit,
  dans tous les états. Même défaut que FI12-E07, déjà ouvert dans `FI_RAPPORT.md:107` : à
  fusionner. Correction : marge horizontale par jeton `AppSpacing` quand `LigneDansCarte` est
  vrai (pas sans condition, `mouvements_page.dart:503` pose aussi la ligne hors carte), avatar
  à côté du nom.
- **R4-04 (FI-9a). États « accès suspendu » et « réactivation » absents.**
  `lib/core/capacites/port_acces_foyer.dart:65-70` : `statutServeur` et `motif` « Réservé,
  toujours null ». Aucune occurrence de suspendu, libéré ou réactivation dans le code ni les
  tests d'accès. Exigé par 02_DECOUPAGE.md:41 et la mission F5 du guide, aucun report écrit.
  Côté enfant, la copie neutre couvre déjà le cas. Correction : états au contrat de démo
  (FI-BR-08), copies tuteur et adulte, tests, ou report écrit avec sa ligne de branchement.
- **R5-02 (FI-10). Pas de tableau compact à 1440.**
  `lib/features/revenus_enseignant/revenus_enseignant_page.dart:248-324` : une section de
  lignes clé-valeur par classe à toutes les largeurs. Ni colonne Type, ni ligne de total.
  `RevenusClasse` n'a pas de champ type. Exigé par revue 11 e et le lot F6. Correction :
  tableau à partir du gabarit desktop (classe, type, capacité, sièges éligibles, heures, taux,
  montant), ligne de total rendue par le port, type ajouté au port.
- **R5-03 (FI-10). Le relevé est absent, sans état honnête.**
  `revenus_enseignant_page.dart:14-16` dit que l'historique n'existe « dans aucun contrat
  (FI-BR-11) », alors que FI-BR.md:19 cite « relevé ». Le port n'a que `moisEnCours()`. La
  mention renvoie à un relevé qu'aucune surface ne montre. Exigé par guide §4, 02_DECOUPAGE
  :43, revue 11 g, ECARTS B5. Correction : lecture du relevé au port (indisponible en
  production, FI-BR-11), section « Relevé » en « pas encore disponible », jamais « Payé » sans
  le serveur.
- **R6-01 (FI-11a). La Vue globale n'a aucun graphique.**
  `lib/features/admin_finance/vue_globale_finance.dart:7-9` : « Aucun graphique : la source ne
  rend pas d'historique ». Le port n'a pas de série. Exigé par revue 12 d, e, f,
  02_DECOUPAGE.md:44 et :71, guide F7 (« graphiques UI avec fixtures »). L'écart n'est écrit
  ni dans 00_REPRISE §5 ni dans QUESTIONS.md. Vu sur `fi1_vue_globale_1440_light`.
  Correction : séries mensuelles et répartition au port (FI-BR-12), un graphique par notion
  avec son nombre exact, ou ÉCART écrit et question au directeur.
- **R6-04 (FI-11a). Les alertes ne mènent nulle part.**
  `vue_globale_finance.dart:241-277` : `BandeauAttention` sans `action`. `AlerteFinance`
  (`port_finance_direction.dart:30-55`) n'a pas de cible. Exigé par revue 12 i (« chaque ligne
  ouvre sa cible, une seule fois »). Vu sur `fi1_vue_globale_1440_light` : ni chevron ni
  bouton. Correction : cible dans `AlerteFinance`, une action secondaire unique. Le routeur
  admin n'a peut-être pas encore de route de profil ou de classe : la cible devra viser une
  page existante.
- **R6-05 (FI-11b). La famille s'appelle « Groupes ».**
  `fr.i18n.json:1836` (« Groupes »), `:1829` (« Objectif de groupes par enseignant »), `:1831`
  (« Maximum normal de groupes »), `:1799` (unité « groupes »). Affiché par
  `politiques_commerciales.dart:690`, `:499`, `:507`, `:921`, `:1008`. Revue 13 f et X-10
  imposent « Classes ». L'aide de la ligne 1830 dit déjà « classes actives ». Correction :
  renommer, mettre à jour `tool/libelles_sources.json` et les tests.
- **R6-06 (FI-11b). Relance, budgets et activation de l'essai absents.**
  `lib/core/finance/politique_commerciale.dart:80-138` n'a pas ces champs.
  `politiques_commerciales.dart:666-668`, `:693-708`, `:709`. Exigé par guide §5.7, FI-BR-01,
  ECARTS D5, D7, D8, revue 13 f. Correction : champs au contrat et au modèle, affichage dans
  leurs familles, mention « non contraignant » pour les budgets.
- **R8-03 (transverse). La règle « aucun mot coupé à 320 px et 200 % » n'est mesurée que sur
  deux écrans.**
  `grep -rln motsCoupes test` : `carte_membre_test.dart`, `fiche_eleve_test.dart` et
  `test/support/mots_coupes.dart`. Précision de l'audit : en plus de la fiche et de la page
  Couleur, `carte_membre_test.dart:135` mesure `CarteMembre` isolée, sans son bloc d'argent
  (aucun paramètre `finance`), donc pas la carte du Foyer telle que FI-4 la rend. Les tests FI à 320 px ne vérifient que l'absence
  d'exception. Une coupure en plein mot n'en lève pas, d'où des tests verts alors que R8-01 et
  R8-02 se voient. Correction : `motsCoupes` avec les vraies polices sur chaque écran FI,
  coquille comprise.

### Mineurs

- **R1-02 (FI-5). « Vue financière du foyer » absente.** Proposé majeur, ramené à mineur par
  les deux sceptiques. `foyer_page.dart:350-358`, aucune clé i18n. Revue 2 d et Q-FI-8 (choix
  de nuit) la gardent. Elle répète la rangée de synthèse, le sélecteur de mois n'a pas de
  contrat. Correction : panneau sur le mois courant, « Total des soldes (lecture) », ou
  réponse du directeur à Q-FI-8.
- **R1-07 (FI-5). « Voir tout » ouvre les mouvements d'un seul enfant.** Un sceptique majeur,
  un mineur : gardé mineur (règle de prudence). `transactions_foyer.dart:130-141` (et non 360,
  le fichier fait 151 lignes). X-12 (00_REPRISE.md:150) veut l'historique du foyer. Le filtre
  par personne de la page cible atténue. Correction : cible = historique du foyer
  (`PaiementsComptePage` sans soldes), test corrigé.
- **R1-09 (FI-4). Libellés de la fiche non appliqués.** `fr.i18n.json:913` (sous-titre),
  `:914` (« Profils élèves »), `:5099` (« Total des soldes »), `:5101` (« À financer ce
  mois »). Attendus : « Soldes et paiements », « Enfants du foyer », « Total des soldes
  (lecture) », « À payer ce mois ». Vu sur `fi4_cinqProfils_1440_light`. « Enfants » serait
  faux pour un titulaire adulte bénéficiaire : question au directeur.
- **R1-11 (FI-4). Deux dates pour la même échéance sur chaque carte.** « Accès jusqu'au »
  dans la légende et « Financé jusqu'au » dans le badge (`finances_foyer.dart:194-200`,
  `foyer_page.dart:559-564`). Vu sur `fi4_cinqProfils_1440_light` et `fi4_unProfil_390_dark`.
  Correction : une seule date quand elles sont égales, ou badge en libellé de mois.
- **R1-12 (FI-5). Le nom lu de « Voir tout » ne contient pas « Voir tout ».**
  `fr.i18n.json:905-906` (« Voir tous les mouvements de {prenom} »), usage
  `transactions_foyer.dart:133-141`. WCAG 2.5.3. Correction : « Voir tout : mouvements de
  {prenom} », à revoir avec R1-07.
- **R1-13 (FI-4, fusionné avec R7-02). Les montants de démonstration ne portent pas
  « (démonstration) ».** R1-13 confirmé mineur. R7-02 : un sceptique majeur, un mineur, gardé
  mineur. `montant_argent.dart:64`, `format_montant.dart` : rien n'écrit la marque. Le
  commentaire de `finance_demo.dart:19-21` affirme le contraire. Exigé par 02_DECOUPAGE.md:10,
  :31, :58 (E-9), FI-BR-03. Vu sur `fi4_cinqProfils_1440_light` : « 80 $ », « 45 $ » nus.
  Correction : marque posée par le composant en démonstration (modèle F12), ou commentaire
  corrigé et décision écrite que le ruban suffit.
- **R2-06 (FI-6a). La période financée est dans la carte d'identité.**
  `finances_page.dart:385-393` (badge à la ligne 392). Revue 3 c, 3 d, 4 c : dans la Vue
  financière, avec « Accès jusqu'au », et « Accès actif » dans l'en-tête. Correction :
  déplacer le badge, une seule fois.
- **R2-07 (FI-6a). « Remise familiale » sans le rang.** `fr.i18n.json:1125`,
  `LigneMensualite` (`finances_profil.dart:65-74`) n'a pas de rang. Lexique revue :217, guide
  §5.2. Correction : champ `rang` rendu par le port, libellé « Remise familiale {rang}e
  membre ».
- **R3-04 (FI-8). Pas de coche « Crédité » ni de signe « + » sur le succès.**
  `ligne_allocation.dart`, `resultat_recharge.dart:452-476`. Revue 8 e et lexique :264. Le
  « + » vient de la maquette plus que d'une règle. Correction : coche avec nom lu « Crédité »
  et « + » à l'état `termine` seulement, test sur les huit états.
- **R3-05 (FI-7). « Paiement web sécurisé » fait la promesse retirée par Q-FI-4.**
  `fr.i18n.json:5096`, affiché par `ligne_moyen_paiement.dart:77` sur la recharge et le
  résultat. Revue 6 g et :329, 00_REPRISE.md:124. La phrase sur la confirmation est
  défendable. Correction : description neutre du rail, sans « sécurisé ».
- **R4-01 (FI-9a). Rejoindre reste actif sur Espace groupe, ouvert depuis Mes groupes.** Un
  sceptique majeur, un mineur : gardé mineur. `routes_tc_a.dart:48-51` câble `onRejoindre`
  sans lire l'accès. Mes groupes retire le bouton (`mes_groupes_page.dart:106`, `:215`).
  L'Accueil Accessibilité et l'Accueil adulte ne sont routés qu'en démonstration, et le port
  de production est neutre. Correction : `ouvertureSeances(accesEleveProvider)` dans la page
  ou la route Espace groupe (sans toucher `EmplacementEntree`), même chose dans les deux
  accueils de démonstration, test « Espace groupe ouvert avec l'accès fermé ».
- **R4-02 (FI-9a, partagé, fusionné avec R7-03). L'enfant charge l'accès de tout le foyer.**
  Un sceptique réfute dans chaque paire : classé mineur. `acces_finance.dart:55-59` lit
  `accesFoyerProvider` puis filtre par `eleveId`. `AccesBeneficiaire` ne porte ni montant ni
  cause, et la règle par rôle (revue :94-104) autorise l'état d'accès à l'enfant. Le reste est
  de la minimisation : prénoms et ouverture des frères et sœurs sur l'appareil de l'enfant.
  Correction : lecture bornée à la session de l'enfant (comme `PortMesFinances`), à inscrire au
  contrat FI-BR-08, test espion.
- **R4-03 (FI-9a). L'enfant ne voit jamais « Essai : n/2 » ni « Accès actif ».** Ramené de
  majeur à mineur par les deux sceptiques. `accueil_eleve_page.dart:203-250`. Guide §4 « Élève
  enfant » liste ces états. Les critères d'acceptation FI-9a sont tenus. Question au
  directeur.
- **R4-07 (FI-9b). La légende de « Paiements » dit « Historique et reçus ».**
  `mon_espace_adulte_page.dart:298-306`, `fr.i18n.json:4688`. Pour l'adulte autonome, la
  ligne ouvre désormais `MesFinancesPage` (solde, période, recharge). Correction : légende
  propre à l'adulte autonome (lexique D4).
- **R5-01 (FI-10). Trois jeux F6 manquent : essai dans la séance, élève financé absent,
  remplacement.** Un sceptique majeur, un mineur : gardé mineur. `finance_demo.dart:899-934`
  n'a que An-Nour, Al-Huda, As-Salam. Le commentaire présente ces trois jeux comme tout F6.
  Le remplacement demande un choix de contrat. Correction : jeux et tests pour les trois cas,
  commentaire corrigé.
- **R5-04 (FI-10). Titre « Mes revenus » au lieu de « Revenus estimés ».**
  `fr.i18n.json:3586` et `:3639`. 02_DECOUPAGE.md:70, revue 11 b. « Mes revenus » est le texte
  de la maquette 08 : à faire trancher par Q-FI-10. Vu sur
  `fi12_revenus_production_390_light_200pc`.
- **R5-05 (FI-10). Ni sélecteur de mois ni taux horaire moyen.**
  `revenus_enseignant_page.dart:190-237`, `port_revenus_enseignant.dart:96`. Revue 11 c et d.
  Le sélecteur demande d'étendre FI-BR-11. Correction : taux moyen rendu par le port,
  sélecteur si le directeur le garde.
- **R5-06 (FI-10). Définition des sièges éligibles répétée dans chaque classe.**
  `revenus_enseignant_page.dart:299`. À 390, colonne de 8 lignes sur environ 120 px.
  Correction : une seule définition, sous « Détail par classe », test mis à jour.
- **R5-07 (FI-10, partagé, fusionné avec R8-01). Libellés de la barre du bas coupés en plein
  mot.** Dans chaque paire, un sceptique réfute : défaut antérieur à la vague
  (`nav_shell.dart` non touché depuis `aebd21a5`, code de `b3b67594`, `436c290d`, `2442829a`).
  Classé mineur, la plus basse gravité proposée. `nav_shell.dart:814-822` : `Text` en
  `maxLines: 2` sans `TexteSansCoupure`, alors que le rail Accessibilité l'utilise (l.908).
  Vu sur `fi2_fiche_320_light_200pc` (« Historiq / ue ») et
  `fi12_revenus_production_390_light_200pc` (« Aujourd'h / ui », « Disponibili / tés »). À
  traiter hors vague, dans un lot navigation.
- **R6-02 (FI-11a). État des paiements, Top classes et Dernières opérations absents.** Un
  sceptique majeur, un mineur : gardé mineur. Déjà relevé en FI12-E20 (mineur, Q8 sans
  réponse). `vue_globale_finance.dart:184-245`. Revue 12 g, h, j.
- **R6-03 (FI-11a). Pas de sélecteur de mois sur la Vue globale.** Ramené à mineur par les
  deux sceptiques. `vueGlobale()` sans paramètre, conforme à FI-BR-12 tel qu'écrit. Revue
  12 b le garde.
- **R6-08 (FI-11b). Composition de Politiques.** `politiques_commerciales.dart:743-759`
  (`i += 2`) casse l'ordre de lecture. À 1440, l'en-tête et l'historique remplissent le
  premier écran. Pas de « Modifier » par carte, aperçu toujours affiché. Revue 13 c et f.
  L'édition directe se défend (K-57) : question au directeur.
- **R7-04 (transverse). Lectures d'argent non liées à la session.** `financesFoyerProvider`
  (`finances_foyer.dart:37-40`), `mesFinancesProvider` (`port_mes_finances.dart:53-56`),
  `beneficiairesRechargeProvider` (`port_recharge_foyer.dart:258-261`). Rien ne les invalide à
  la déconnexion. `accesFoyerProvider` est antérieur à la vague. Latent (ports neutres en
  production). Correction : surveiller `sessionProvider.select((s) => s.profileId)` comme
  `identiteTitulaireProvider`, test à deux sessions.
- **R8-02 (FI-11, fusionné avec R6-09). Titre « Politiques / commerci / ales » à 390 et
  200 %.** R8-02 confirmé mineur par les deux sceptiques. R6-09 était partagé (cosmétique).
  `lib/core/widgets/page_shell.dart:143-146` : la branche sans en-tête riche rend un `Text`
  sans `TexteSansCoupure`. Ne touche que `/demo/finance` : en production, les actions de la
  coquille admin font passer par `EntetePage` (titre entier sur
  `fi12_admin_politiques_production_390_light_200pc`). Vu sur
  `fi1_politiques_390_light_200pc`. Correction : `TexteSansCoupure` dans la branche `else`,
  test `motsCoupes` 390 et 320.

### Cosmétiques

Contre-vérifiés (reclassés vers le bas) :

- **R1-10 (FI-4). « Recharger {prénom} » montre le prénom dans le libellé visible.** Un
  sceptique mineur, un cosmétique : gardé cosmétique. `foyer_page.dart:572-593`. La forme
  `LienFleche` hors de la carte est conforme à K-56 et évite un bouton dans un bouton. Les
  hauteurs inégales ne sont pas prouvées (cartes égales sur `fi4_cinqProfils_1440_light`).
  Correction : libellé « Recharger », nom lu « Recharger {prénom} ».
- **R4-05 (FI-9b). `mesFinancesProvider` et `mesMouvementsProvider` sans `autoDispose`.** Un
  sceptique mineur, un cosmétique : gardé cosmétique. `port_mes_finances.dart:52-62`. Aucune
  route adulte réelle aujourd'hui, le commentaire « relus à chaque ouverture » est faux.
- **R4-06 (FI-9b). Recharge de l'adulte autonome avec les textes multi-profils.** Un
  sceptique mineur, un cosmétique : gardé cosmétique. `recharge_foyer.dart:468-515`, appelée
  par `demo_adulte_page.dart:1142-1150`. Titre au pluriel, « Tout désélectionner » sur un seul
  profil, note de répartition superflue mais pas fausse.
- **R8-04 (outillage, partagé). Socle de `verifier_revue` avec des `\`.** Un sceptique
  réfute (antérieur à la vague, portée réduite) : cosmétique. Seules les lignes 1117 à 1130
  de `tool/revue_socle.txt` (plein-multiple) sont touchées. Les 1559 libelle-sans-source sont
  de vraies nouveautés. À traiter hors vague.

Non contre-vérifiés :

- **R2-08 (FI-6b).** Dans la répartition du reçu, l'avatar à bandeau dépasse la ligne, le
  prénom s'aligne sur le bandeau (`mouvements_page.dart:505`).
- **R3-06 (FI-8).** « Retour aux soldes » seulement à `termine`, « Revenir aux paiements du
  foyer » ailleurs pour la même cible (`resultat_recharge.dart:312`, `:337`, `:353`, `:486`).
- **R4-08 (FI-9a, fusionné avec R8-06).** « Accès de Aïcha », « Accès de Ibrahim » au lieu de
  « d'Aïcha » (`fr.i18n.json:1107`, aussi `:1143`, `:1144`, `:1148`, `:1152`).
- **R5-08 (FI-10).** « Heures assurées » et « Classes » non alignées en fin de ligne
  (`revenus_enseignant_page.dart:228-237`).
- **R6-10 (FI-11b).** « Publier cette version » au lieu de « Publier la version »
  (`fr.i18n.json:1867`), et « Version brouillon brouillon-2027-01 » (`finance_demo.dart:142`).
- **R7-07 (FI-BR).** Références des ports neutres non alignées sur FI-BR.md : `LOT-E`
  (`port_acces_foyer.dart:106`), `EA-BR-23`, `EA-BR-24`, `EA-BR-25`.
- **R8-05 (FI-4, FI-5, FI-6b).** « 1 novembre 2026 » au lieu de « 1er novembre 2026 »
  (`ligne_membre.dart:72-75`). FI-3c écrit « 1er octobre ». Vu sur `fi4_cinqProfils_1440_light`
  et `fi4_unProfil_390_dark`.

### Écartés ou reclassés par la contre-vérification

- **R7-06 (FI-10, proposé mineur, écarté par les deux sceptiques).** La somme des minutes dans
  le widget n'est pas un calcul d'argent (FI6 vise prix, remise, taxe, paie). Le montant vient
  du port. `moisEnCours()` fixe un mois civil, lire `debut.month` suffit.
- **R6-07 (FI-11b, partagé, ramené à info).** Date d'effet sans sélecteur. Un sceptique : le
  guide demande seulement d'afficher la date, `dateEffet` est non nullable, la publication
  n'écrit rien avant FI-BR-02, et le test « date d'effet » existe. Gardé comme question au
  directeur pour le branchement.
- **R7-05 (FI-3a, partagé, ramené à info).** Devises à 3 décimales (KWD, BHD…) affichées à
  2 décimales (`format_montant.dart:36-39`). Antérieur à la vague (`4acc1293`), aucune devise
  de ce type prévue. Gardé comme question.
- **R6-09 (fusionné dans R8-02).** Le sceptique qui le réfutait le jugeait antérieur et limité
  à la démo. R8-02, confirmé par ses deux sceptiques, porte la correction.

Doublons fusionnés : R3-01 et R7-01 ; R1-13 et R7-02 ; R4-02 et R7-03 ; R5-07 et R8-01 ;
R6-09 et R8-02 ; R4-08 et R8-06.

Réserves sur les preuves : plusieurs constats citent des captures du scratchpad
(`fi4_unARegulariser_*`, `fi4_cinqProfils_768_light`, `fi12_resultat_termine_*`,
`fi12_revenus_contenu_*`, `fi12_recharge_etape*`) qui ne sont pas dans le dossier gardé. Les
sceptiques ont établi chaque constat sur le code. Certaines lignes citées étaient décalées
(R1-07, R1-12, R2-06) ; les lignes ci-dessus sont celles vérifiées.

### Vérifié sans défaut (info)

- **Argent** : `Montant(int mineur, String devise)`. Aucun double, num, toDouble ni
  toStringAsFixed sur un montant dans les 58 fichiers `lib/` de la vague (`git diff --name-only
  aebd21a5..5198107f -- lib`, recompté à l'audit ; le rapport disait 60). `formaterMontant`
  n'utilise que des entiers, vrai signe moins U+2212, espace insécable avant la devise.
- **Aucun calcul de prix, remise, taxe ou total dans un écran.** Totaux du Foyer, de la
  direction et de la recharge rendus par le port ou le serveur. Somme `fi4_cinqProfils` :
  45 + 0 + 3 + 12 + 20 = 80 $, affiché 80 $. Revenus : 56 + 51,20 + 36 = 143,20 $, 22 h,
  affichés tels quels. Marge 79,2 % cohérente avec (690 − 143,20) / 690.
- **Production honnête** : tous les ports Finance rendent `CapaciteIndisponible`. Captures
  `fi12_*_production` : « pas encore disponible » partout, aucun montant, aucune référence
  `EA-BR-xx` affichée.
- **Routes de démo** absentes en production (`routesDemoFinance` et `routesDemoAdulte` vides
  hors `environnementAutoriseDemo`). Routeur unique, routes du guide §4 présentes, sans
  branche par plateforme. Aucun widget de la vague ne lit un rôle.
- **Recharge** : un seul moteur pour les quatre entrées. Clé d'idempotence par récapitulatif,
  gardée après une coupure, double envoi bloqué, commande rendue jamais repayée. Seul le rail
  web est montré. Succès seulement à `termine`, jamais déduit localement. Huit états testés.
  Échec : sélection gardée.
- **Foyer** : retraits Q-FI-9 et Q-FI-3 faits, grille 3 colonnes à 1440 et 2 à 1200, montants
  signés dans les transactions, statuts en texte, relecture après recharge.
- **FI-6a et FI-6b** : identifiant résolu dans le foyer (aucune fuite), 8 cas F3 testés,
  historique en ajout seul, reçu seulement pour un mouvement enregistré, provider des
  mouvements en `autoDispose`.
- **FI-9a et FI-9b** : Rejoindre ne dépend jamais du solde. Copies §1.7 mot pour mot. L'enfant
  ne lit ni montant ni cause (espion : 0 lecture). `EmplacementEntree` non modifié.
  `MesFinancesPage` ne lit que `PortMesFinances` (espion du foyer : 0 appel).
- **FI-10** : route dans le Profil, pas de 5e destination, taux toujours sous le plafond
  (tests 0 à 12 sièges), aucune donnée de famille, estimation signalée, aide Internet à part,
  états testés, vocabulaire « Classe ».
- **FI-11a, b, c** : vraie coquille admin, 7 indicateurs séparés avec leur nombre exact,
  « Marge projetée », marge jamais présentée comme une sanction, invariants en texte,
  « Publier » seul bouton plein avec état honnête, erreurs de champ et de cohérence, aperçu
  relu par le port avec jeton anti-course, garde de source verte.
- **Jetons, slang, ton** : aucune violation de jetons dans un fichier Finance, aucune chaîne
  littérale, aucun tutoiement hors écrans enfant.

## Captures vues

Ouvertes par le rédacteur de ce rapport (dossier `docs/revues/captures/FI-VAGUE-R/`) :

1. `fi4_cinqProfils_1440_light.png` : Foyer, coquille tuteur. « Ajouter un profil élève → » en
   bouton tonal en haut à droite. Rangée « Soldes et paiements » à 4 chiffres : 80 $, 0 $,
   5 sur 5, 2. « Recharger plusieurs profils » en contour, seul sous la rangée à droite
   (R1-01, R1-03). Pas de « Vue financière du foyer » (R1-02). Grille de 3 colonnes, 5 cartes
   de même hauteur. Chaque carte porte « Accès jusqu'au 31 octobre 2026 », la pastille
   « Financé » et « Financé jusqu'au 31 octobre 2026 » (R1-11), puis « Prochain débit
   1 novembre 2026 » (R8-05). Montants sans « (démonstration) » (R1-13). En bas, « Dernières
   transactions » avec « Voir tout » et −50 $, « Appareils partagés ».
2. `fi4_unProfil_390_dark.png` : Foyer à 390, sombre. Bouton plein pleine largeur « Ajouter un
   profil élève », synthèse en lignes clé-valeur (12 $, 0 $, 1 sur 1, 1), « Recharger
   plusieurs profils » en contour. Carte Mariam avec les deux dates. Aucun débordement.
3. `fi1_vue_globale_1440_light.png` : Vue globale de démonstration, ruban « Démonstration »
   en angle. Onglets Vue globale / Politiques commerciales. 7 cartes (4 puis 3) : 690 $, 690 $,
   143,20 $, 79,2 %, 8 $, 1, 57 $. Une alerte « Période à régulariser » sans chevron ni bouton
   (R6-04). Aucun graphique ni sélecteur de mois (R6-01, R6-03). La page s'arrête vers 770 px.
4. `fi1_politiques_390_light_200pc.png` : titre « Politiques / commerci / ales » sur trois
   lignes (R8-02), puis le sélecteur d'onglet qui répète « Politiques commerciales », puis le
   texte d'introduction lisible.
5. `fi2_fiche_320_light_200pc.png` : fiche d'Aïcha à 320 et 200 %. Contenu sans mot coupé
   (« Paramètres de / l'élève », « Prénom et / photo »). Barre du bas : « Historiq / ue »
   (R5-07). La liste continue sous la barre, ce qui est le défilement normal.
6. `fi12_recharge_production_390_dark.png` : flèche retour, barre « 1 sur 2 » (R3-01), titre
   « Recharge », carte « Recharge pas encore disponible ». Aucun bouton de paiement.
7. `fi12_revenus_production_390_light_200pc.png` : titre « Mes revenus » (R5-04), carte « Pas
   encore disponible », barre du bas « Aujourd'h / ui » et « Disponibili / tés » (R5-07), onglet
   Profil actif.

Lues par l'agent de capture (non rouvertes ici) : `fi12_foyer_production_390_dark`,
`fi12_recharge_production_1440_light`, `fi12_resultat_production_390_dark`,
`fi12_mouvements_production_390_light_200pc`, `fi12_finances_production_1440_light`,
`fi12_acces_compte_production_390_dark`, `fi12_adulte_production_390_dark`,
`fi12_revenus_production_390_dark`, `fi12_admin_vue_globale_production_1440_light`,
`fi12_admin_politiques_production_390_dark`, `fi3c-argent_320x2_light`,
`fi3c-argent_1440_light`. Rien d'autre à signaler que les constats déjà listés.

Non ouvertes : `fi1_*` en 390, `fi2_foyer`, `fi2_couleur`, `foyer_contenu_*`,
`fi12_acces_enfant_ouvert`, `fi12_acces_fiche_essai`, `fi12_adulte_mon_espace`. Toutes
existent.

Couverture : les captures FI-12 gardées montrent la production (« pas encore disponible »).
Les écrans avec contenu réel gardés sont `fi2_*`, `fi3c-argent_*`, `fi4_*` et
`foyer_contenu_*`. Les captures de contenu FI-12 (`fi12_foyer_cinq_profils`,
`fi12_revenus_contenu`, `fi12_adulte_paiements`…) sont dans le scratchpad seulement. Aucun
test dédié à FI-7 ni FI-8 n'existe dans `test/capture` : ils ne sont couverts que par les
captures FI-12.

## Questions au directeur

1. **Q-FI-2** : sans source de finances (production), « Recharger plusieurs profils »
   n'existe pas. « Ajouter un profil élève » redevient-il plein, ou la page n'a-t-elle aucun
   bouton plein ?
2. **Q-FI-8** : garder « Vue financière du foyer » (maquette 05), ou la retirer ?
3. Section du Foyer : « Enfants du foyer » ou « Profils élèves » quand le titulaire adulte est
   lui-même bénéficiaire ?
4. **X-12** : « Voir tout » vise l'historique du foyer, ou une vue des mouvements filtrable
   par personne ?
5. Démonstration : le ruban suffit-il, ou chaque montant porte-t-il « (démonstration) » ?
6. **Q-FI-1** : les segments Général / Finances sont-ils remplacés par la ligne
   « Finances » ? Si oui, l'écrire dans 02_DECOUPAGE.
7. « Télécharger le reçu » : bouton sur un état honnête (FI-BR-05) ou retiré jusqu'au
   branchement ?
8. **X-6** : Compte > Paiements ouvre la recharge, ou redirige vers `/tuteur/foyer` ?
9. Montant de la recharge : saisissable (revue 6 b) ou choisi dans une liste (K-57) ?
10. Paiement en suspens : le serveur (EA-BR-26) doit-il reconnaître une commande en attente
    pour le même foyer, et le Foyer afficher « paiement en cours de confirmation » ?
11. **X-9** : confettis interdits partout, ou permis dans `lib/core/mouvement` ?
12. Enfant : afficher « Essai : n/2 » et « Accès actif », ou seulement l'état fermé ?
13. Tuteur et adulte : un rappel « Accès à régulariser » sur leur Accueil ?
14. Route `/eleve/finances` : dette de FI-9b à fixer à l'arrivée de la coquille adulte ?
15. « Il manque 8 $ » ou « Il manque 8 USD » (guide §1.7) ?
16. **Q-FI-10** : « Revenus estimés » ou « Mes revenus » ?
17. Relevé de l'enseignant : section « pas encore disponible » dès maintenant, ou report à
    FI-BR-11 ?
18. Sélecteur de mois des Revenus et de la Vue globale : à garder (lecture par mois au
    contrat) ?
19. Sièges éligibles : nombre mensuel, moyen, ou détail par séance ? Remplacement : comment
    le montrer au titulaire et au remplaçant ?
20. Vue globale : demander séries et répartitions à FI-BR-12, ou accepter une vue réduite et
    l'écrire en ÉCART dans 00_REPRISE §5 ?
21. Politiques : marge de référence et moyens de paiement modifiables dans un brouillon ?
    Rails iOS et Android en « Préparé (inactif) » ? Édition directe ou « Modifier » par
    carte ? Date d'effet réglable avant le branchement (R6-07) ?
22. FI-11c : le dossier `lib/features/demo/` fait-il exception à « aucune formule dans
    `lib/features/` », ou faut-il déplacer le double sous `lib/core/` ?
23. Second adulte rattaché : une capacité de session doit-elle fermer
    `/tuteur/foyer/recharge` côté client ?
24. Montants en arabe : chiffres et séparateurs arabes, ou forme française ? Devises à
    3 décimales à prévoir (R7-05) ?
25. Contraste : exiger une mesure chiffrée (4,5:1) des pastilles « À régulariser » et
    « Essai » en clair et en sombre avant de fermer la vague ?
26. Admin sur mobile : garder le titre et le sélecteur d'onglet qui le répète ? Disque retour
    présent en production, absent en démo : lequel est voulu ?
27. `docs/design/00-bible-frontend-v2.md` et `08-catalogue-ecrans.md` sont absents du worktree
    `/home/user/wt/fin` (seuls `docs/archive` et `docs/current`). Où vérifier l'inscription des
    écrans FI au catalogue ?

## Suivi proposé

Étape proposée à la session principale (rien n'est créé par cette revue) :

### FI-VAGUE-CORR

Foyer (FI-4, FI-5, FI-5b) :

1. R1-01 : « Ajouter un profil élève » en `NiveauAction.secondaire` à sa place,
   « Recharger plusieurs profils » plein, assertion de `foyer_finances_test.dart:260` inversée.
   Cas sans source selon la réponse à la question 1.
2. R1-03 : rangée bureau en 4 blocs, le 4e = bouton puis note « Chaque enfant a un solde et
   une période financée individuels… » (clé i18n nouvelle). « Paiements du mois » gardé
   ailleurs.
3. R1-04 : `_GrilleCartes` dès la tablette, 2 colonnes vers 640 px utiles, synthèse sur 2
   rangées sous 900 px, test à 768 de large (2 colonnes, aucun débordement).
4. R1-05 : `_moisAFinancer` et `_periodeNonFinancee` déplacées dans `lib/core/finance`,
   réutilisées par `BlocFinanceMembre` (« Période à financer {mois} », « Il manque … pour
   financer {mois} »), test sur `unARegulariser`.
5. R1-06 : composition FI-5b pour le titulaire adulte, `SoldesFoyerSection` retirée de
   `foyer_page.dart` et `paiements_page.dart`, tests EA mis à jour.
6. R1-08 : « Voir le détail » (nom lu avec le prénom) ou geste de carte vers
   `Routes.ficheEleveSousPage(id, 'finances')` quand une finance est rendue, test.
7. R1-02 : panneau « Vue financière du foyer » sur le mois courant, sauf réponse contraire à
   Q-FI-8.
8. R1-07 et R1-12 : « Voir tout » vers l'historique du foyer, nom lu qui contient « Voir
   tout », test corrigé.
9. R1-09 : libellés « Soldes et paiements », « Enfants du foyer » (selon la question 3),
   « Total des soldes (lecture) », « À payer ce mois ».
10. R1-11 : une seule date d'échéance par carte.
11. R1-13 : marque « (démonstration) » posée par le composant d'argent en démo, ou
    commentaire de `finance_demo.dart:19-21` corrigé et décision écrite.
12. R1-10 (cosmétique) : libellé visible « Recharger », nom lu « Recharger {prénom} ».

Fiche élève (FI-6a, FI-6b) :

13. R2-01 : 3 colonnes à 1200 et plus (identité et groupe « Paramètres de l'élève » réutilisé
    depuis `fiche_eleve_page.dart`, vue financière et actions, derniers mouvements avec « Voir
    tout »), bandeau du bas à trois faits, titre « {prénom} · Finances », fil d'Ariane.
14. R2-02 : `ControleSegmente` Général / Finances sous 1200 px, sur la fiche et sur Finances,
    sauf décision écrite contraire.
15. R2-03 : clé `ficheEleve.finances.noteAbsences`, note sous la vue financière.
16. R2-04 : « Voir les mouvements », « Recharger {prénom} » d'abord, lien 8 px dessous,
    « Télécharger le reçu » sur bureau si un reçu est rendu.
17. R2-05 : avatar dans le filtre par personne, icône par `NatureMouvement`, date avec l'heure.
18. R2-06 : badge de période dans la Vue financière, une seule fois.
19. R2-07 : champ `rang` dans `LigneMensualite`, « Remise familiale {rang}e membre ».

Recharge et résultat (FI-7, FI-8) :

20. R3-01 : une seule page (profils et montants, total arrêté par `verifierMontants`,
    explication, moyen, « Payer {total} », « Payer {nouveau total} » si le serveur change le
    total). `PageEtape` 1/2 et `toutSelectionnerKey` retirés, titre « Recharge » seul, tests de
    `recharge_multi_profils_test.dart` adaptés.
21. R3-02 : composition 3 colonnes à partir de la classe large (maquette 07), bandeau « Accès
    à régulariser » sans croix avec « Ajouter {prénom} à la recharge », test à 1440.
22. R3-03 : marge horizontale (jeton `AppSpacing`) des `LigneAllocation` dans une
    `CarteLignes`, avatar à côté du nom, captures du résultat refaites. Fermer FI12-E07 avec.
23. R3-04 : coche « Crédité » et « + » à l'état `termine`, test sur les huit états.
24. R3-05 : `webStripeDetail` neutre, sans « sécurisé ».
25. R3-06 (cosmétique) : « Retour aux soldes » dans tous les états.

Accès et adulte (FI-9a, FI-9b) :

26. R4-04 : états « place libérée / accès suspendu » et « réactivé » au contrat de démo
    (FI-BR-08), copies tuteur et adulte, tests, ou report écrit.
27. R4-01 : `ouvertureSeances(accesEleveProvider)` sur Espace groupe (route ou page) et dans
    les deux accueils de démonstration, test « Espace groupe ouvert avec l'accès fermé ».
28. R4-02 : lecture d'accès bornée à la session de l'enfant, écrite au contrat FI-BR-08,
    test espion.
29. R4-03 : selon la question 12.
30. R4-07 : légende de « Paiements » propre à l'adulte autonome.
31. R4-05, R4-06 (cosmétiques) : `autoDispose` ou invalidation au retour de recharge ;
    textes au singulier et sans « Tout désélectionner » ni note quand un seul bénéficiaire.
32. R4-08 (cosmétique) : élision « d' » devant voyelle ou h muet pour toutes les chaînes
    « de {prenom} ».

Revenus (FI-10) :

33. R5-02 : tableau compact à 1440 avec type et ligne de total rendue par le port, type ajouté
    à `RevenusClasse`.
34. R5-03 : lecture du relevé au port (indisponible, FI-BR-11), section « Relevé » honnête,
    en-tête du fichier corrigé.
35. R5-01 : jeux « essai dans la séance », « élève financé absent », « remplacement » et leurs
    tests, commentaire corrigé.
36. R5-04, R5-05, R5-06 : titre selon Q-FI-10, taux moyen rendu par le port (et sélecteur si
    gardé), définition des sièges dite une seule fois.
37. R5-08 (cosmétique) : `valeurEnFin: true` dans la synthèse.

Admin Finance (FI-11a, FI-11b) :

38. R6-01 : séries et répartition au port (FI-BR-12), un graphique par notion avec son nombre
    exact, ou ÉCART écrit et question posée.
39. R6-04 : cible dans `AlerteFinance`, action secondaire unique sur chaque alerte.
40. R6-05 : « Classes » partout (libellés, unité, pluriel), `tool/libelles_sources.json` et
    tests.
41. R6-06 : relance, budgets non contraignants et activation de l'essai au contrat, au modèle
    et à l'écran.
42. R6-02, R6-03, R6-08 : selon les réponses (Q8 et questions 18, 21).
43. R8-02 : `TexteSansCoupure` dans la branche `else` de `PageShell`, test 390 et 320 à 200 %.
44. R6-10 (cosmétique) : « Publier la version », versions de démo réalistes.

Transverse :

45. R8-03 : `motsCoupes` (vraies polices, coquille comprise) dans les tests 320 px et 200 % de
    Foyer, Finances, Mouvements, Recharge, Résultat, Accès, Mes finances, Revenus, Vue
    globale, Politiques.
46. R7-04 : providers d'argent liés à `session.profileId`, test à deux sessions.
47. R7-07, R8-05, R2-08 (cosmétiques) : références FI-BR des ports neutres, « 1er » pour le
    jour 1, alignement de l'avatar dans la répartition du reçu.
48. Refaire et garder les captures de contenu après correction (Foyer `unARegulariser`, 768,
    Finances, Mouvements, Recharge à 1440, Résultat `termine`, Revenus contenu), puis rejouer
    la revue des étapes refusées.

Hors vague, à ouvrir à part : R5-07 / R8-01 (barre du bas de `nav_shell.dart`, lot
navigation et accessibilité) ; R8-04 (socle `verifier_revue` normalisé en `/` et régénéré sur
main) ; R7-05 (devises à 3 décimales, si la réponse à la question 24 le demande).

## Audit du rapport

Critique de complétude faite par un agent à contexte neuf, le 04/10/2026, en lecture seule sur
`/home/user/wt/fin` @ `5198107f` (`git status` vide avant et après). Seul ce fichier a été modifié.

Ce qui a été vérifié :

- **Verdicts** : les 13 étapes FI-4, FI-5, FI-5b, FI-6a, FI-6b, FI-7, FI-8, FI-9a, FI-9b,
  FI-10, FI-11a, FI-11b et FI-11c ont chacune un verdict. Les comptes du bilan ont été
  recomptés sur les listes : 22 majeurs, 24 mineurs, 11 cosmétiques (4 + 7). Ils sont justes.
- **Citations fichier:ligne**, ouvertes une à une (plus de 30, dont) : `foyer_page.dart:160`,
  `:202-208`, `:214`, `:567` ; `finances_foyer.dart:119-128` ; `foyer_finances_test.dart:260-274` ;
  `resume_soldes.dart:77-105` ; `finances_page.dart:527-537` ; `recharge_foyer.dart:247`,
  `:372-375`, `:484-493` ; `port_acces_foyer.dart:65-70` ; `vue_globale_finance.dart:7-9` ;
  `page_shell.dart:143-146` ; `ligne_cle_valeur.dart:154` ; `revenus_enseignant_page.dart:14-16` ;
  `resultat_recharge.dart:451-478` ; `routes_tc_a.dart:48-51` ; `nav_shell.dart:814-822` et `:908` ;
  `politiques_commerciales.dart:743-759` ; `transactions_foyer.dart` (151 lignes) ; et dans
  `assets/i18n/fr.i18n.json` les lignes 905, 906, 913, 914, 1107, 1125, 1147, 1799, 1829, 1831,
  1836, 1867, 3586, 3639, 4688, 5096, 5099, 5101. Toutes disent ce que le rapport leur fait dire.
  Une seule est décalée : `mouvements_page.dart:262-263`, l'`EntreeFiltre` est à la ligne 264.
- **Chiffres** : `dart run tool/verifier_jetons.dart` relancé : 39 violations, comme écrit.
  `nav_shell.dart` est bien inchangé depuis `aebd21a5` (`git diff --stat` vide). 65 PNG dans
  `docs/revues/captures/FI-VAGUE-R/` et 618 dans `…/scratchpad/fi_all/`, soit 683. Le seul
  chiffre faux est « 60 fichiers `lib/` de la vague » : la mesure donne 58.
  `flutter test` et `verifier_revue` n'ont **pas** été relancés par l'audit. Les 817 / 0 / 617 et
  les 1618 violations restent ceux du rapport.
- **Captures** : les 20 noms cités comme ouverts ou lus existent dans le dossier gardé. Les
  7 familles « non ouvertes » existent aussi. `fi4_cinqProfils_768_light.png` est bien dans le
  scratchpad (`fi_all/`).
- **Exigences du guide V4 et de 02_DECOUPAGE que la revue ne cite pas**, contrôlées dans le
  code. Aucune ne donne de nouveau défaut :
  - Mouvements (FI-6b) en tableau à 1440 : présent (`mouvements_page.dart:215-216`, `_Tableau`
    l. 349).
  - FI-8 sans « ! » ni confettis : aucune chaîne Finance avec « ! » dans `fr.i18n.json`, aucun
    confetti hors `lib/core/mouvement`. « Ne payez pas une seconde fois » présent (l. 1141,
    4740, 4747).
  - Échec (guide §5.4) : motif, « Réessayer » et « Changer de moyen de paiement » présents
    (`resultat_recharge.dart:88`, `:91`, `:287-288`).
  - FI-11b : aucun menu « … » ni sélecteur de mois dans `lib/features/admin_finance/`.
  - FI-10 : explication en trois points (base, occupation, plafond) et aide Internet à part
    (`revenus_enseignant_page.dart:130`, `:325-348`).
  - FI-9a : place conservée (`acces_finance.dart:183-190`, clé `placeConservee`). Compte
    navigable testé (`acces_finance_test.dart:374`, bloc du Coran visible).
  - Second adulte (FI-4, K-53.8) : historique seul, sans soldes, testé
    (`paiements_foyer_adulte_test.dart:260`).
  - Fait commun point 4 : variantes 768 et RTL présentes dans `captures_fi12_test.dart:914-938`
    (34 PNG en 768 et 26 en RTL dans le scratchpad).
  - Guide §5.1 états visuels (financé, essai, manque, en confirmation, expiré, pause) :
    `EtatFinancier` les porte tous (`finances_profil.dart:21-41`).

Corrections apportées au rapport :

1. « 60 fichiers `lib/` de la vague » devient 58, avec la commande de mesure.
2. R2-05 : `mouvements_page.dart:262-263` devient `:262-264`.
3. R8-03 et le paragraphe « Transverse » : `carte_membre_test.dart:135` mesure aussi
   `CarteMembre` isolée, sans finances. La règle n'est donc pas mesurée que sur deux écrans.
   La conclusion ne change pas : aucun écran FI n'est mesuré dans sa composition Finance.
   R8-03 reste majeur.

Aucun verdict d'étape n'est modifié.
