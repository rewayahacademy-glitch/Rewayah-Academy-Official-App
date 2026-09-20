# TEACHER_PREMERGE_REPORT

Contrôle pré-fusion du lot **rôle Enseignant**, écrit par l'**Agent Z** le
20 septembre 2026.

Base : `BASELINE_SHA = 550e605`. Cinq agents métier (A à E) ont travaillé en
parallèle sur des périmètres de fichiers exclusifs, après deux phases de socle
(catalogue, puis salle) écrites par Z avant leur lancement.

> **Verdict global : READY WITH CONTRACT CHANGE.** Aucun lot n'est BLOQUÉ. Les
> changements de contrat sont ceux que l'intégration a appliqués, tous demandés
> par écrit par les agents et tous listés au §4. Une seule condition de fusion du
> `PROMPT Z` n'est pas remplie et elle ne l'était pas non plus avant ce lot :
> `test/widgets/catalogue_galerie_test.dart` reste rouge pour une cause
> antérieure à `BASELINE_SHA`, prouvée au §6.

---

## 1. Ce qui a été mesuré, et avec quoi

| Mesure | Résultat | Avant le lot |
| :--- | :--- | :--- |
| `flutter analyze --no-pub` | **No issues found!** (149 s) | No issues found! |
| `flutter test --no-pub` | **857 passés, 1 échec** | 708 passés, 7 échecs |
| Écritures hors périmètre par A–E | **zéro** | — |
| Migrations appliquées sur `gggmtelinlpseweouyav` | `0021`–`0029` **au complet** (cf. §7) | `0025`, `0026` |
| Migrations écrites non appliquées | **aucune** | `0020`–`0024` sauf `0020` |

Les six tests rouges qui étaient **dans** le périmètre Enseignant sont revenus au
vert : `dossier_test.dart` ×3 et `inscription_test.dart` ×2 par l'agent E,
`navigation_test.dart` ×1 par Z.

---

## 2. Audit de propriété : aucun agent n'a écrit hors de son périmètre

Vérification faite sur `git diff --name-status 550e6059` plus les fichiers non
suivis, chemin par chemin, contre `TEACHER_FILE_OWNERSHIP.md` §5.

### Agent A — Journée (`ENS-02`, `ENS-07`)

| Fichier | Propriétaire déclaré | Verdict |
| :--- | :--- | :--- |
| `lib/features/journee/journee_page.dart` | A | conforme |
| `lib/features/fiche_groupe/fiche_groupe_page.dart` | A | conforme, neuf |
| `test/features/journee_test.dart` | A | conforme |
| `test/features/fiche_groupe_test.dart` | A | conforme, neuf |
| `docs/parallel-reports/i18n_A.json`, `CONTRACT_REQUEST_A.md`, `AGENT_A_REPORT.md` | A | conformes |

### Agent B — Salle de cours (`ENS-03`)

| Fichier | Propriétaire déclaré | Verdict |
| :--- | :--- | :--- |
| `lib/features/salle_enseignant/**` (3 fichiers) | B | conforme, neuf |
| `test/features/salle_enseignant_test.dart` | B | conforme, neuf |
| `docs/parallel-reports/i18n_B.json`, `CONTRACT_REQUEST_B.md`, `AGENT_B_REPORT.md` | B | conformes |

**B n'a touché ni `lib/features/salle/salle_page.dart` ni `vue_salle.dart`**, et
c'est le point le plus délicat du lot : ces deux fichiers portent l'élève, le
tuteur observateur et le contrôleur autant que l'enseignant. B a spécifié son
point d'insertion dans son rapport §4 et s'est arrêté là. Z l'a posé.

### Agent C — Pédagogie après-cours (`ENS-04`, `ENS-08`)

| Fichier | Propriétaire déclaré | Verdict |
| :--- | :--- | :--- |
| `lib/features/cahier/**` | C | conforme, neuf |
| `lib/features/revue_groupe/**` | C | conforme, neuf |
| `test/features/cahier_test.dart`, `revue_groupe_test.dart` | C | conformes, neufs |
| `docs/parallel-reports/*_C.*` | C | conformes |

C a appliqué `0020_programme_pedagogique` en base sur autorisation de
l'opérateur, sans écrire dans `supabase/migrations/` — le fichier y existait déjà
depuis le lot Pédagogie. Conséquence inscrite au §7.

### Agent D — Créneaux et matching (`ENS-06`)

| Fichier | Propriétaire déclaré | Verdict |
| :--- | :--- | :--- |
| `lib/features/creneaux/creneaux_page.dart` | D | conforme |
| `test/features/creneaux_test.dart` | D | conforme |
| `docs/parallel-reports/*_D.*` | D | conformes |

D n'a pas touché `lib/features/disponibilites/**` ni `grille_semaine.dart`, qu'il
importe en lecture seule — l'écran du tuteur `TUT-04` est intact.

### Agent E — Onboarding et profil (`ENS-01`, `ENS-05`)

| Fichier | Propriétaire déclaré | Verdict |
| :--- | :--- | :--- |
| `lib/features/profil_enseignant/profil_enseignant_page.dart` | E | conforme |
| `lib/features/profil_enseignant/service_acceptations.dart` | E | conforme, neuf — **remonté en `core` par Z**, cf. §4 |
| `lib/features/profil_enseignant/service_declaration.dart` | E | conforme, neuf — **remonté en `core` par Z**, cf. §4 |
| `lib/features/bienvenue_enseignant/bienvenue_page.dart` | E | conforme, neuf |
| `lib/features/dossier/depot_piece_page.dart` | E | conforme (surface partagée avec le tuteur) |
| `test/features/profil_enseignant_test.dart`, `bienvenue_enseignant_test.dart`, `dossier_test.dart`, `inscription_test.dart` | E | conformes |

**`lib/features/inscription/**` n'apparaît pas au diff** : E n'a pas eu besoin
d'y toucher, donc le parcours commun du tuteur n'a pas été effleuré. C'était la
contrainte absolue de son périmètre, et elle est tenue par l'absence même de
modification, pas par une relecture.

E a appliqué `0027` et `0028` en base sans pouvoir déposer les fichiers :
`supabase/migrations/**` est à Z. Z les a écrits à l'intégration depuis
`pg_get_functiondef()` lu sur la base, pas depuis une transcription.

### Agent Z — socle et intégration

`lib/core/**`, `lib/core/router/*`, `lib/core/widgets/nav_shell.dart`,
`lib/features/salle/*`, `assets/i18n/*`, `lib/core/i18n/strings*.g.dart`,
`supabase/migrations/**`, `test/support/harnais.dart`,
`test/features/salle_test.dart`, `test/router/*`, `test/accessibilite/*`,
`test/video/*`, `test/coran/service_coran_test.dart`, `docs/**` hors
`parallel-reports/`. Tous dans son périmètre.

`docs/design/08-catalogue-ecrans.md` a été étendu en **phase socle**, avant le
lancement des agents : la règle « aucun écran ne s'implémente s'il n'est pas
inscrit » exigeait d'y enregistrer `ENS-01`, `ENS-04`, `ENS-05`, `ENS-07` et
`ENS-08` d'abord. Il l'a été à nouveau à l'intégration, pour la fiche `ENS-02`
(demande `CONTRACT_REQUEST_A.md` §7).

**Conclusion du §2 : zéro violation de périmètre, sur les 47 fichiers touchés.**
Le pari de l'Agent 0 — geler l'API publique de chaque écran avant qu'une ligne
soit écrite — a tenu : les cinq déclarations livrées sont **exactement** celles
de `TEACHER_FILE_OWNERSHIP.md` §3, au caractère près, et le routeur les a
branchées sans une adaptation.

---

## 3. Audit de duplication : les neuf preuves de responsabilité unique

Mesurées par balayage du dépôt, pas affirmées.

| # | Responsabilité | Mesure | Verdict |
| :-: | :--- | :--- | :--- |
| 1 | **un seul système de routes** | `GoRouter(` apparaît une fois : `lib/core/router/app_router.dart:80` | ✅ |
| 2 | **un seul fournisseur vidéo** | `implements VideoSessionProvider` une fois (`LiveKitSessionProvider`) ; le SDK `package:livekit_client` importé dans **2 fichiers**, tous deux sous `lib/core/video/` | ✅ |
| 3 | **une seule vérité Supabase** | `Supabase.instance` lu une fois par service, jamais deux fois dans un fichier, jamais dans un écran. Après la remontée du §4, **plus aucun service Supabase hors de `lib/core/`** | ✅ |
| 4 | **une seule implémentation de disponibilité** | `weekly_availability` : `lib/core/planning/service_planning.dart` seul (l'occurrence dans `creneaux_page.dart:179` est un commentaire, vérifiée ligne à ligne) | ✅ |
| 5 | **une seule implémentation de matching** | `prendre_eleve` : `lib/core/matching/service_matching.dart:212` seul (`creneaux_page.dart:584` est un commentaire) | ✅ |
| 6 | **une seule implémentation de rapport** | écriture dans `lesson_reports` : `lib/core/enseignant/service_enseignant.dart:151` seul. Toutes les autres occurrences sont des commentaires ou des lectures Admin | ✅ |
| 7 | **aucune duplication du profil** | `profil_enseignant_page.dart` ne lit plus `seancesProvider` ni `elevesEnAttenteProvider` et ne porte plus aucun `StatTile` : la duplication de `TEACHER_DUPLICATES_AUDIT.md` §9 est résorbée | ✅ |
| 8 | **aucun réglage global dans le Profil** | une seule mention de `/compte/reglages`, dans un commentaire qui dit précisément que les préférences réelles vivent là-bas | ✅ |
| 9 | **aucune donnée privée de famille chez l'enseignant** | balayage de `last_name`, `lastName`, `email`, `courriel`, `phone`, `telephone` sur les huit dossiers d'écrans enseignant : **aucune lecture**. Tous les résultats sont des commentaires énonçant la garantie, ou des faux positifs sur « téléphone » (l'appareil) et « phonétique ». Mesuré en plus à l'exécution par `creneaux_test.dart` | ✅ |

Duplications **évitées** que les agents ont signalées au lieu de les créer :
aucun troisième `_hhmm` (A), aucun septième `'Europe/Paris'` (D, qui en a même
supprimé un), aucun composant « page de mushaf » dupliqué (B, plafond inscrit
dans le code), aucun troisième miroir de `StatutPiece` (E), aucun second écran de
salle (B), aucun quatrième bandeau (B).

---

## 4. Changements de contrat appliqués à l'intégration

C'est ce qui fait la classification **READY WITH CONTRACT CHANGE**. Chacun était
demandé par écrit ; aucun n'a été deviné.

### 4.1 Dans `lib/core/` et `lib/features/salle/` — le périmètre de Z

| Changement | Demandé par | Ce qui a été fait |
| :--- | :--- | :--- |
| `VueSalle.peutPresenter` | `CONTRACT_REQUEST_B` §1, priorité haute | champ ajouté, dérivé de `capacites?.peutPublierDonnees ?? false`. **Première consommation de cette capacité dans tout le dépôt** : elle existait côté jeton depuis le lot N2 sans lecteur. Dérivée en booléen plutôt qu'en ouvrant l'`AccesSalle` — donc le jeton signé — à toutes les features |
| `seuilOuvertureSalle` remonté en `core` | `CONTRACT_REQUEST_A` §1 | déplacé de `journee_page.dart` vers `lib/core/video/pre_vol.dart`, à côté du pré-vol : les deux répondent à « ce geste peut-il aboutir maintenant ? », l'un interroge le matériel, l'autre l'horloge |
| `service_acceptations.dart` et `service_declaration.dart` remontés | `CONTRACT_REQUEST_E` §4 | déplacés vers `lib/core/profil/`. Ils étaient nés dans la feature parce que c'était le seul endroit où E pouvait écrire, et ils y étaient **la seule entorse architecturale du lot** : deux services parlant à Supabase depuis un dossier d'écran, ce qu'aucun autre service du dépôt ne fait |
| les quatre routes de pose | `CONTRACT_REQUEST_E` §6.1 | `enseignantBienvenue`, `cahierPour`, `groupePour`, `revuePour` posées **hors** de la coquille : une `GoRoute` dans une `StatefulShellBranch` deviendrait une quatrième destination |
| la sortie de salle mène au cahier | invariant du catalogue, écart inscrit depuis le lot N3 | `_quitter` route l'enseignant vers `Routes.cahierPour(seanceId)` **quand le cours a eu lieu** (`vue.dansLaSalle`), et chez lui sinon. L'écart « `ENS-04` n'a pas de route, on renvoie donc chez soi » est levé |
| fusion des six files i18n | `TEACHER_FILE_OWNERSHIP` §4 | 237 clés sous `enseignant.*`, huit écrans, plus `dart run slang` |

### 4.2 Dans les fichiers des agents — l'exception d'intégration

`PROMPT Z` autorise l'intégrateur, et lui seul, à modifier les fichiers joints.
Voici **tout** ce qui a été touché, et pourquoi.

| Fichier (propriétaire) | Modification | Raison |
| :--- | :--- | :--- |
| `journee_page.dart` (A) | suppression de la déclaration de `seuilOuvertureSalle` ; bloc `///` de tête transformé en documentation de bibliothèque (`library;`) en haut du fichier | la remontée demandée par A §1. Le bloc décrivait l'écran mais était attaché à la constante : en la sortant, il se serait attaché au `_maximumAlertes` suivant |
| `journee_test.dart` (A) | `import 'dart:ui' show Size;` retiré | `unnecessary_import`, bloquant sous `--fatal-infos` |
| `fiche_groupe_test.dart` (A) | idem | idem |
| `salle_enseignant_test.dart` (B) | `const` ajouté sur un `SessionState` | `prefer_const_constructors`, bloquant sous `--fatal-infos` |
| `creneaux_test.dart` (D) | l'identifiant immuable écarté du balayage de vie privée | **le test ne pouvait pas passer** : il exigeait `STUD-KB-000003` à l'écran ligne 578 et refusait toute suite de six chiffres ligne 590. Le garde-fou se déclenchait sur la donnée qu'il protège. D ne pouvait pas le voir : lancer `flutter test` lui était interdit (règle 8) |
| `service_declaration.dart` (E) | `if (x != null) 'k': x` → `'k': ?x` | `use_null_aware_elements`, bloquant. Même sémantique : l'entrée disparaît quand la valeur est nulle, ce que le `coalesce` de la RPC attend |
| `profil_enseignant_page.dart` et `profil_enseignant_test.dart` (E) | imports mis à jour | conséquence de la remontée en `core` |

**Aucun conflit Git n'a été résolu en choisissant « ours » ou « theirs ».** La
question ne s'est pas posée : les périmètres exclusifs ont produit zéro conflit,
ce qui est précisément ce que la matrice de propriété achetait.

---

## 5. Demandes de contrat non satisfaites, et pourquoi

Trente-neuf demandes écrites, six appliquées (§4.1). Voici les autres, classées
par ce qui les bloque. Aucune n'empêche la fusion : chacune est absorbée par une
dette locale documentée dans le code, ou par un écran qui **se tait** au lieu de
mentir.

### 5.1 Demandes qui attendent une décision de l'opérateur

| Demande | Origine | Ce que l'écran fait en attendant |
| :--- | :--- | :--- |
| retirer une disponibilité engagée : refusé, averti ou silencieux ? | D §4 | le geste passe, et la confirmation dit exactement ce qu'il fait **et ce qu'il ne fait pas** |
| inventaire des fuseaux horaires (liste fermée, déduction depuis le pays, ou recherche libre) | E §2 | `ENS-05` affiche le fuseau en lecture et dit à quoi il sert. La RPC accepte déjà l'écriture |
| « correction demandée » distinguée de « refusé » | E §7 | un seul état, le motif pour seule différence. La fiche `ENS-01` l'écrit comme ouvert |
| l'élève a-t-il droit à la liste des participants ? | socle salle | `voitLesParticipants` la lui refuse, état courant verrouillé |
| `student_profiles.level` : texte libre ou libellé à traduire ? | D §6 | la valeur brute est affichée. Inventer un libellé serait pire |

### 5.2 Demandes qui exigent une migration et un lot à elles

| Demande | Origine | État |
| :--- | :--- | :--- |
| `mes_anomalies_groupe(p_groupe_id)` bornée à l'enseignant | C §1 | **`ENS-08` est livré complet et vide, et il le dit à l'écran.** `anomaliesGroupeProvider` rend une liste vide ; le jour où la RPC existe, **seul ce provider change** — ni l'écran, ni sa projection, ni ses tests |
| `PresenceCorrectionAdaptateurSupabase` | C §2 | le cahier consigne le motif dans son contenu, qui part avec sa clé d'idempotence. Une seule écriture atteint la base |
| deux accusés séparément opposables (ADR-011) | E §1 | les deux points sont dits explicitement et séparément sur `ENS-01`, et un test le mesure. La demande est de Z de bout en bout : `contract_kind`, `SorteContrat`, `etat_dossier()` **pour l'enseignant seulement**, et `PieceManquante` |
| un drapeau serveur « bienvenue vue » | E §6 | l'écran est complet et sans effet de bord : il ne s'auto-navigue pas, ne mémorise rien, et se comporte correctement s'il est atteint deux fois |
| `errcode` stable sur les refus de `prendre_eleve()` | D §1 | reconnaissance par sous-chaîne, plafond nommé en `ponytail:` dans le code, quatre tests. Une reformulation SQL casserait silencieusement la reconnaissance et ferait retomber sur le message brut |
| clés de règle pour la « marge autorisée » | C §5 | **rien n'a été borné.** Aucune constante inventée, aucun plafond de caractères. « Dans la marge autorisée » n'est pas implémentable aujourd'hui, et le dire vaut mieux que le simuler |
| `sessions.objectif` (objectif commun de séance) | A §4 | l'écran se tait plutôt que d'afficher un tiret à chaque cours |
| `timezone_iana` sur `ProfilEnseignant` | E §3 | `ENS-05` fait deux lectures là où une suffirait |
| `consolide` sur `ParticipantBrouillon` | C §6 | le cahier passe `afficherConsolide: false` : il se tait plutôt que d'affirmer ce qu'il ne sait pas |

### 5.3 Dettes de socle reportées

`EntreeJournee`/`TimelineRow` ignorent le groupe (A §2) — conséquence visible et
unique du lot : une séance **individuelle** antérieure au pivot (`groupe_id` nul)
affiche « Cours avec Cours individuel ». C'est le seul libellé bancal, et il
disparaît avec ce contrat. Lecture bornée en date de `mes_seances_enseignant_v`
(A §5). Prise `onRafraichir` de `PageShell` (A §6). Paramètre `engagees` sur
`GrilleSemaine` (D §3). État de vue asynchrone réutilisable (D §5). `Duration` et
compteur de lectures sur `FauxServiceMatching` (D §7). `peutDeciderHorsLigne` sur
`PresenceCorrectionCapacites` (C §3). Les treize libellés injectés de
`PresenceCorrectionLibelles` (C §4). `VerificationEnseignant` à ranger dans
`enums.dart` (E §8).

### 5.4 Arbitrages i18n tranchés par Z

- **sept clés orphelines supprimées**, après avoir vérifié qu'aucun appelant
  écrit à la main ne subsiste (seul le fichier généré les citait) :
  `enseignant.journee.elevesEnAttente`, `unEleveEnAttente`,
  `aucunEleveEnAttente` (A §8), et `enseignant.profil.chargePedagogique`,
  `elevesActifs`, `heuresDisponibles`, `reglagesHeures` (E §9) ;
- **`nav.enseignant.compte` supprimée** : le passage à trois destinations
  (ADR-027) l'a laissée sans lecteur ;
- **`ENS-07` continue de lire `t.admin.groupes.typeEnfant` / `typeAdulte`**
  (A §9) : déclarer des jumeaux sous `enseignant.*` donnerait deux clés pour
  « Enfants ». Exception notée, promotion sous `commun.*` non faite parce
  qu'elle toucherait les écrans Admin, hors de ce lot ;
- **`ENS-06` garde deux namespaces** (D §8) : 19 clés anciennes sous
  `t.creneaux.*` et 20 neuves sous `t.enseignant.creneaux.*`. Migrer les
  anciennes toucherait sept écrans qui lisent `t.disponibilites.joursLongs`.
  Exception notée, pas une intention.

---

## 6. Le seul test rouge, et la preuve qu'il précède le lot

`test/widgets/catalogue_galerie_test.dart` → « chaque fichier de
`lib/core/widgets` a son entrée ».

Cinq composants n'ont pas d'entrée de galerie : `admin_shell`, `menu_actions`,
`menu_filtre`, `selecteur_niveau`, `sous_navigation_domaine`.

Preuve qu'aucun n'appartient à ce lot :

```
git cat-file -e 550e6059:lib/core/widgets/admin_shell.dart             → True
git cat-file -e 550e6059:lib/core/widgets/menu_actions.dart            → True
git cat-file -e 550e6059:lib/core/widgets/menu_filtre.dart             → True
git cat-file -e 550e6059:lib/core/widgets/selecteur_niveau.dart        → True
git cat-file -e 550e6059:lib/core/widgets/sous_navigation_domaine.dart → True

git diff --name-status 550e6059 -- lib/core/widgets/  → M nav_shell.dart, et rien d'autre
git diff --stat       550e6059 -- lib/features/_dev/  → (vide)
```

Les cinq existaient à `BASELINE_SHA`, la galerie n'a pas bougé, et **aucun
fichier n'a été ajouté à `lib/core/widgets/` par ce lot** — c'était d'ailleurs
une interdiction explicite du périmètre, précisément parce que ce test était déjà
rouge. Les cinq viennent des lots `IA-01` (`b3be532`), `1acb9e4` et Pédagogie
(`e3faea8`), tous des 18 et 19 septembre 2026, et la mémoire du projet les
enregistre déjà comme « bug préexistant, non corrigé, hors mission ».

Ce lot ne le corrige pas non plus, et c'est un choix : ajouter cinq entrées de
galerie les soumettrait chacune à une dizaine de tests de rendu (trois largeurs,
RTL, réduction du mouvement, mode enfant), dont `admin_shell` qui exige un
routeur et `sous_navigation_domaine` un domaine. C'est un lot, pas une ligne.

---

## 7. État de la base : plus rien n'attend

| Migration | Fichier au dépôt | Appliquée | Par qui |
| :--- | :--- | :--- | :--- |
| `0025_role_enseignant` | ✅ | ✅ `20260919224503` | Z |
| `0026_durcissement_execute_enseignant` | ✅ | ✅ `20260919224844` | Z |
| `0027_maj_profil_enseignant` | ✅ **écrit à l'intégration** | ✅ `20260919235846` | agent E |
| `0028_maj_profil_enseignant_revoke_anon` | ✅ **écrit à l'intégration** | ✅ `20260919235944` | agent E |
| `0029_fermeture_dossiers_en_attente_anon` | ✅ | ✅ `20260920025402` | Z |
| `0020_programme_pedagogique` | ✅ (lot Pédagogie) | ✅ `20260919232916` | agent C |
| `0021_diagnostics_placement` | ✅ (lot Pédagogie) | ✅ `20260920033433` | Z |
| `0022_progression_suivi` | ✅ (lot Pédagogie) | ✅ `20260920033522` | Z |
| `0023_evaluations` | ✅ (lot Pédagogie) | ✅ `20260920033612` | Z |
| `0024_qualite_pedagogique` | ✅ (lot Pédagogie) | ✅ `20260920033657` | Z |

Le dépôt et la base racontent la même histoire, sans exception. `0021`–`0024`
sont appliquées sur autorisation explicite de l'opérateur, après un contrôle
préalable prouvant les 4 tables et les 12 fonctions **absentes** — donc aucune
collision, et aucun risque de régresser le lot Enseignant appliqué avant elles
(aucune des quatre n'emploie `or replace` : une collision aurait échoué fort).

Leurs huit portes avaient été réécrites en exigence positive **avant**
l'application — ces fichiers n'étant pas appliqués, les corriger était permis, et
il aurait été absurde de poser en base huit exemplaires du défaut que `0029`
venait de fermer. La mesure prouve que la correction porte : appelées en rôle
`authenticated` **sans jeton** (`app_role()` vaut donc NULL), les huit écritures
refusent en `P0001` avec leur propre message. Sous la forme en refus, ce `if` ne
se serait pas déclenché et l'appel aurait continué jusqu'à l'insertion.

| Mesure sur les 12 nouvelles RPC | Résultat |
| :--- | :--- |
| En rôle `anon` | `42501 permission denied for function` — les 12 |
| En `authenticated` sans jeton, les 8 écritures (plpgsql, `if`) | `P0001`, message de la porte — les 8 |
| En `authenticated` sans jeton, les 4 lectures (`sql`, `where`) | passent, **0 ligne** — les 4 |
| `has_function_privilege('agent_ro', …)` sur les 8 volatiles | `false` — les 8 |
| `has_function_privilege('agent_ro', …)` sur les 4 stables | `true` — les 4 |
| RLS active + policy de lecture sur les 4 tables | oui, 1 chacune |
| `insert`/`update`/`delete` pour `authenticated` sur les 4 tables | `false` partout |
| `get_advisors` : nouvel objet sous l'avis `anon_…` | **aucun** |

La dernière ligne des lectures est la loi `where` contre `if` en action : une
porte dans un `where` échoue **fermée** (0 ligne), une porte en `if … then raise`
échoue **ouverte** si elle est écrite en refus. Les 12 fonctions n'apparaissent
chez `get_advisors` que sous `authenticated_security_definer_function_executable`,
avis attendu par conception — c'est ainsi que toute l'application fonctionne, et
c'est la porte interne, mesurée ci-dessus, qui protège.

**Conséquence tenue :** `unite_curriculum()` s'allume, comme annoncé. Son garde
`to_regclass` est franchi, la requête dynamique se compile (vérifié à nu : une
colonne absente aurait été avalée en `null` par son `exception when
undefined_column`), et sur un élève réel elle rend désormais `null` **parce
qu'aucun placement n'est décidé**, non plus parce que la table manque. Le bloc
curriculum du cahier se remplira au premier diagnostic, sans une ligne de Dart.

### 7.1 La leçon de privilèges, corrigée deux fois

`0026` concluait que « `revoke ... from anon` ne retire rien ». C'était vrai de
ce qu'elle mesurait et **faux comme règle**. Mesure complète sur
`pg_default_acl` :

```
type_objet = 'f', schema = 'public', posé par 'postgres'
droits_par_defaut = {postgres=X, anon=X, authenticated=X, service_role=X}
```

Une fonction créée dans `public` sur ce projet reçoit EXECUTE par **deux chemins
indépendants** : le défaut `PUBLIC` de PostgreSQL, et un `alter default
privileges` de Supabase qui donne à `anon` un droit **nominal**. `revoke from
public` ferme le premier, `revoke from anon` le second, **aucun des deux ne
suffit seul.** Le lot Enseignant est fermé parce que `0025` portait l'un et
`0026` l'autre, pas parce que l'un était le bon.

**Le seul contrôle qui vaut est `has_function_privilege('anon', …, 'execute')`**,
jamais la relecture du `revoke` écrit dans le fichier. Ni `get_advisors` ni une
relecture attentive ne voient ces deux fautes.

État mesuré des sept fonctions du périmètre, après `0028` :

| Fonction | volatilité | `anon` | `authenticated` | `agent_ro` |
| :--- | :--- | :--- | :--- | :--- |
| `brouillon_cahier` | stable | ❌ | ✅ | ✅ |
| `mes_rapports_en_attente` | stable | ❌ | ✅ | ✅ |
| `mon_groupe_detail` | stable | ❌ | ✅ | ✅ |
| `mon_fuseau` | stable | ❌ | ✅ | ✅ |
| `unite_curriculum` | stable | ❌ | ❌ | ❌ |
| `maj_profil_enseignant` | **volatile** | ❌ | ✅ | ❌ |
| `prendre_eleve` | **volatile** | ❌ | ✅ | ❌ |

`agent_ro` n'a **aucune** fonction volatile. La règle de la mémoire projet tient.

### 7.2 Une fuite trouvée hors périmètre, et fermée

En cherchant si la leçon de `0028` avait des cousines, le contrôle a trouvé
`public.dossiers_en_attente()` — posée par `0015`, donc **antérieure à
`BASELINE_SHA`** :

```sql
set local role anon;
select count(*) from public.dossiers_en_attente();   -->  4 lignes
```

et ces lignes portaient `first_name`, `last_name`, `immutable_id`, `role` et
`account_status` de chaque personne en attente de vérification. La clé publiable
`anon` est embarquée dans le bundle web servi : la fonction était joignable par
`POST /rest/v1/rpc/dossiers_en_attente` sans aucun compte. `last_name` est
précisément ce qu'ADR-008 interdit de montrer même à un enseignant authentifié.

Cause : **le même défaut que `brouillon_cahier` avant `0026`.** La porte
s'écrivait en refus, `if public.app_role() <> 'admin' then raise`. Pour un
appelant anonyme `app_role()` rend NULL, `NULL <> 'admin'` vaut NULL, et
`if NULL then` ne se déclenche pas : la fonction continuait, `security definer`,
et lisait `profiles` avec les droits du propriétaire.

Balayage complet : **31 fonctions `security definer` du schéma portent cette
forme de porte**, et `dossiers_en_attente()` est la **seule** que `anon` pouvait
exécuter. Des seize autres candidates, quinze sont des fonctions de déclencheur et
une un déclencheur d'événement — non appelables directement. Les trente autres ne
sont donc protégées que par leur `revoke`, ce qui est **une défense de moins que
ce que le dépôt croit avoir**. Dette inscrite au lot G-02.

`0029_fermeture_dossiers_en_attente_anon.sql` corrige les deux choses : la porte
devient une exigence positive enveloppée de `coalesce(…, false)`, et EXECUTE est
retiré à `anon` **et** à `PUBLIC`. Aucun écran ne change de comportement :
`admin_dossiers` appelle la RPC en `authenticated` avec `app_role() = 'admin'`.

**Elle est appliquée** (`20260920025402`), sur autorisation explicite de
l'opérateur. Les deux défenses sont mesurées **séparément**, parce qu'une seule
mesure ne dirait pas laquelle des deux travaille :

| Mesure | Avant | Après |
| :--- | :--- | :--- |
| `anon` appelle la RPC | **PASSE, 4 lignes** | `42501 permission denied for function` |
| La porte seule (`authenticated` sans jeton, donc `app_role()` NULL) | passait | `42501 validation des dossiers reservee a l'administration` |
| `has_function_privilege('anon', …, 'execute')` | `true` | **`false`** |
| `proacl` | `… \| anon=X/postgres \| …` | `anon` **absent** |
| `authenticated` / `agent_ro` / `service_role` | `true` | `true` |
| `agent_identite_masquee` + `read_kyc_documents` dans le corps | oui | **oui** |

La deuxième ligne est celle qui compte : ce n'est pas seulement le `revoke` qui
arrête l'anonyme, c'est la porte qui refuse désormais un rôle NULL.

### 7.3 Le balayage qui explique pourquoi une seule des 31 fuyait

La fuite avait été trouvée par hasard. Le balayage a donc été refait en entier,
sur ce qu'un appelant anonyme peut **atteindre**, et non sur ce que le code a
l'air de dire — chaque cible appelée en rôle `anon`, avec de vraies clés prises
sur la base :

| Cible joignable par `anon` | Mesure |
| :--- | :--- |
| `mes_appareils_v`, `mes_codes_appairage_v`, `presence_seance_v`, `profils_du_foyer_v` | **0 ligne** chacune |
| `comptes_admin()` — identités, foyer, contrats | **0 ligne** |
| `personnes_observables()` — identités | **0 ligne** |
| `etat_presence(vraie séance, vrai profil)` | `NULL` — n'apprend rien (invariant J3) |
| `profil_de_mon_foyer(vrai profil)` | `false` |
| `app_config_int('session_duration_minutes', -1)` | **rend `60`** |

Et cela donne la loi qui manquait : **une porte posée dans un `where` échoue
fermée, une porte posée en `if … then raise` échoue ouverte.** `NULL = 'admin'`
dans un `where` ne rend aucune ligne ; `if NULL then raise` ne se déclenche pas.
Les 31 fonctions portent la forme fragile, mais 30 la portent **dans un `where`** :
elles sont sûres par construction, pas par chance. `dossiers_en_attente()` était
la seule dont la porte était un `if` en plpgsql — c'est ce qui en faisait la seule
qui fuyait, pas le hasard de son `revoke`.

Deux dettes mesurées restent, aucune n'étant une fuite d'identité :

1. Les quatre vues portent `security_barrier=true` mais **pas
   `security_invoker=true`** : elles lisent avec les droits de leur propriétaire,
   RLS contournée. Elles ne rendent rien à `anon` parce que leur `where` filtre
   sur `app_user_id()`/`app_household_id()`, NULL pour un anonyme — donc sûres,
   mais par leur `where` seul, et `anon` ne devrait pas avoir le `select` dessus.
2. `app_config_int(clé, défaut)` rend `60` à un appelant anonyme. C'est un
   paramètre produit, pas une donnée personnelle ; à borner par hygiène.

Dette inscrite au lot G-02.

---

## 8. Classification par lot

| Lot | Écrans | Classification | Motif |
| :--- | :--- | :--- | :--- |
| **A** | `ENS-02`, `ENS-07` | **READY WITH CONTRACT CHANGE** | `seuilOuvertureSalle` remonté, fiche `ENS-02` mise à jour, trois clés supprimées. 43 tests |
| **B** | `ENS-03` | **READY WITH CONTRACT CHANGE** | `VueSalle.peutPresenter` posé, point d'insertion appliqué dans `salle_page.dart`. 20 tests |
| **C** | `ENS-04`, `ENS-08` | **READY** | aucun changement de contrat requis pour fonctionner. `ENS-08` est livré vide et le dit |
| **D** | `ENS-06` | **READY WITH CONTRACT CHANGE** | un test qui ne pouvait pas passer, corrigé. Aucun changement de code de production |
| **E** | `ENS-01`, `ENS-05` | **READY WITH CONTRACT CHANGE** | deux services remontés en `core`, deux migrations écrites au dépôt, quatre clés supprimées. 5 tests rouges préexistants remis au vert |
| **Z** | socle + branchement | **READY** | analyse verte, 857 tests verts, neuf preuves de responsabilité unique |

**Aucun lot BLOQUÉ. La fusion peut avoir lieu.**

Les conditions du `PROMPT Z` phase 9, une par une :

| Condition | État |
| :--- | :--- |
| analyse verte | ✅ `No issues found!` |
| tests verts | ⚠️ **857 / 858**, l'unique échec prouvé antérieur à `BASELINE_SHA` (§6) |
| build réussi | à vérifier au rapport d'intégration |
| E2E réussi | preuve du chemin de bout en bout au rapport d'intégration |
| zéro BLOCKER | ✅ |
| zéro duplication fonctionnelle connue | ✅ neuf preuves au §3 |
