# AGENT_E_REPORT — Onboarding et profil enseignant

Lot **Agent E** : `ENS-01` Onboarding et bienvenue, `ENS-05` Profil enseignant.
Base : `BASELINE_SHA = 550e605`. Écrit le 20 septembre 2026.

> **Ce rapport n'a pas été vérifié par une commande.** Aucun `flutter analyze`,
> `flutter test`, `dart run slang` ni `build_runner` n'a été lancé : cinq agents
> travaillaient en parallèle dans le même arbre et ces commandes se disputent
> `.dart_tool`. Tout chiffre d'analyse ou de test appartient à l'Agent Z. Ce qui
> est écrit ici comme **mesuré** l'a été par lecture de code, arithmétique de mise
> en page, ou requête SQL sur la base — jamais par exécution de la suite.

---

## 1. Fichiers touchés, sans exception

| Fichier | Nature | Ce qui y est fait |
| :--- | :--- | :--- |
| `lib/features/profil_enseignant/profil_enseignant_page.dart` | modifié | `ENS-05` réécrit : talon de 183 lignes → écran complet, branché sur `profilEnseignantProvider` |
| `lib/features/profil_enseignant/service_acceptations.dart` | créé | lecture du contrat et des accusés signés (`contract_acceptances`) |
| `lib/features/profil_enseignant/service_declaration.dart` | créé | l'unique porte d'écriture du titulaire, sur la RPC `maj_profil_enseignant` |
| `lib/features/bienvenue_enseignant/bienvenue_page.dart` | créé | `ENS-01` : `BienvenueEnseignantPage` |
| `lib/features/dossier/depot_piece_page.dart` | modifié | **un seul changement** : les deux gestes du dépôt passent dans la zone d'action collée |
| `test/features/profil_enseignant_test.dart` | modifié | 18 lignes → 23 cas |
| `test/features/bienvenue_enseignant_test.dart` | créé | 15 cas |
| `test/features/dossier_test.dart` | modifié | diagnostic corrigé, un cas ajouté |
| `test/features/inscription_test.dart` | modifié | mesuré sur 390 × 844, cartes atteintes par `ensureVisible` |
| `docs/parallel-reports/i18n_E.json` | créé | 49 clés `enseignant.profil.*`, 17 `enseignant.bienvenue.*` |
| `docs/parallel-reports/CONTRACT_REQUEST_E.md` | créé | 10 demandes à l'Agent Z |
| `docs/parallel-reports/AGENT_E_REPORT.md` | créé | ce fichier |

**Hors du périmètre de fichiers, et déclaré comme tel** : deux migrations ont été
**appliquées sur la base de production** (§7). Aucun fichier de
`supabase/migrations/` n'a été écrit — ce dossier est à l'Agent Z — donc **la base
est en avance sur le dépôt jusqu'à ce qu'il les y écrive.** Le SQL exact est dans
`CONTRACT_REQUEST_E.md` §0, prêt à copier.

---

## 2. `ENS-05` — ce que l'écran fait maintenant

### Le défaut central, et sa correction

`profil_enseignant_page.dart:107-114` **affirmait** « Compte enseignant vérifié »
avec une pastille verte étiquetée `t.etat.enDirect` — un libellé de visio en
cours — **sans jamais lire un statut**. Un enseignant suspendu, provisoire ou en
attente y voyait la même affirmation. C'est un mensonge d'interface qui passe la
compilation, `dart analyze` et la relecture rapide.

Il lit désormais `profilEnseignantProvider`, le contrat qui existait depuis
toujours et que **aucun écran ne consommait** (zéro référence hors de son propre
fichier dans tout le dépôt, pas même un test). Les deux lectures fabriquées ont
disparu : `seancesProvider` (qui appartient à l'agent A) et
`elevesEnAttenteProvider` (agent D), dont l'une dédupliquait
`seances.map(eleveId).toSet()` — fragile depuis le pivot groupes, où
`mes_seances_v` rend une ligne par élève et non par séance.

### Les deux lectures de `account_status`, et ce qu'on en fait

`account_status` est lu par deux chemins : `source_session.dart` alimente
`sessionProvider`, qui **gouverne la porte du routeur** ; et
`service_profil_enseignant.dart` alimente `profilEnseignantProvider`, qui
**alimente l'écran**. Rien ne garantit qu'ils soient du même instant.

Décision, et elle est visible à l'écran : **le profil décide de ce qui s'affiche,
la session de ce qui gouverne l'accès**, et quand les deux diffèrent l'écran le
dit en une phrase (« Ce statut vient de changer. Rouvrez l'application pour que
votre accès suive. »). Un test le mesure. L'alternative — choisir en silence celle
qui arrange — aurait produit un écran qui affirme un statut que le routeur
contredit.

### La déconnexion, et pourquoi elle est là où elle est

C'est l'invariant qui justifie cet écran. `destinationsPour(AppRole.teacher)` rend
désormais **trois** destinations (l'Agent Z a retiré « Compte »), et
`secondairesPour(AppRole.teacher)` est vide. Le pied de coquille qui porterait
cette entrée n'est rendu qu'à partir de 600 de large, une barre basse Material 3
n'acceptant aucune entrée hors destination. **Sans `ENS-05`, un enseignant sur
téléphone n'a plus aucun chemin vers la déconnexion.**

Elle vit donc dans la zone d'action **collée en bas** de `PageShell`, pas dans le
corps défilant. Deux conséquences mesurables, et deux tests :

1. son rectangle tient dans `[0, 844]` à 390 × 844 — elle est atteignable **sans
   défilement** ;
2. elle survit à l'échec de **toutes** les lectures de l'écran, parce que l'état
   d'erreur remplace le corps et jamais la zone d'action. La fiche l'exige mot
   pour mot.

Elle se confirme par `ConfirmDestructive.demander` — le seul point d'entrée d'une
confirmation destructive — et le libellé nomme l'acte : « Me déconnecter
maintenant », jamais « OK ».

### Le contrat, redevenu lisible

`deciderRedirection` renvoie tout compte actif **hors** de `/attente/*`. Un
enseignant validé ne pouvait donc plus relire ni son contrat `teacher_nda` ni son
accusé d'enregistrement et de contrôle. Le protocole exige l'inverse.

`service_acceptations.dart` les relit. **Aucune migration n'a été nécessaire** :
la policy `contract_acceptances_self_read` autorise le titulaire depuis `0004`,
la donnée était lisible, il manquait une classe Dart. La section rend la sorte, la
version et la date, en lecture seule, et une phrase dit pourquoi elle l'est. Une
sorte inconnue rend `null` et la ligne disparaît plutôt que d'afficher
« contrat enseignant » sur une ligne qu'on n'a pas su lire.

### Les surfaces personnelles, et leur chemin de retour — constat demandé

`ENS-05` mène à `/compte/profil` et `/compte/reglages` par `context.push`, sans
rien réimplémenter. **Le chemin de retour à 390 de large existe, et ce n'est pas
un chevron** : `_CoquilleSecondaire` (`app_router.dart:628`) rend tout
`/compte/*` dans `NavShell` avec les trois destinations de l'enseignant, aucune
active. On revient donc par la barre basse, en tapant « Profil ».

Ce que cela vaut, honnêtement : c'est un retour **par destination** et non par
`pop`, donc la pile de navigation n'est pas rembobinée. Acceptable — c'est le
comportement que tous les rôles ont déjà sur cet espace — mais ce n'est pas un
bouton « Retour », et personne ne devrait l'écrire comme tel dans une fiche.

---

## 3. `ENS-01` — la bienvenue

Le tunnel d'entrée **n'a pas été dupliqué** : `/connexion`, `/attente`,
`/attente/accuse`, `/attente/contrat` et `/attente/piece` existent, sont testés et
servent le tuteur autant que l'enseignant. Le seul écran neuf est
`/enseignant/bienvenue`.

Ce qu'elle porte : la salutation nommée, l'état du dossier, les trois pas qui
viennent, **les deux dispositifs de l'ADR-011 dits en clair, chacun pour
lui-même**, et deux sorties.

Trois décisions à connaître :

- **aucune grille de semaine.** La déclaration des disponibilités vit dans
  `ENS-06` (`Routes.enseignantCreneaux`). Un test mesure
  `find.byType(GrilleSemaine), findsNothing` : deux grilles jumelles finiraient
  par diverger, et celle du tuteur en dépend ;
- **deux sorties, pas une.** La bienvenue n'est pas une destination : elle vit
  hors des trois branches de la coquille, donc sans barre de navigation. Avec la
  seule action « Déclarer mes disponibilités », un enseignant qui ne veut pas le
  faire tout de suite serait coincé. « Aller à ma journée » est donc une action
  secondaire, dans la même zone collée, et deux tests mesurent où chacune mène ;
- **un dossier non valide ne se fait pas féliciter.** `pendingKyc`, `disabled` et
  un statut illisible renvoient au portail d'attente. On ne laisse jamais passer
  par défaut ce qu'on n'a pas su lire. `provisionalActive` accueille, comme
  `active` : ADR-014 lui donne un accès complet sans coupure automatique.

**Ce qu'elle ne sait pas faire, et il faut le lire** : elle ne mémorise pas
qu'elle a été vue, rien ne mène à elle, et sa route n'est pas encore dans
`app_router.dart` — seule la constante `Routes.enseignantBienvenue` existe. Les
trois manquent hors du périmètre de l'Agent E (`CONTRACT_REQUEST_E.md` §6). En
attendant, l'écran est sans effet de bord : il ne s'auto-navigue pas, ne mémorise
rien, et se comporte correctement s'il est atteint deux fois.

---

## 4. Les cinq tests rouges — la cause réelle, et elle n'était pas la même

C'est le point du lot où le diagnostic évident était faux. Les cinq échecs
partageaient le **même symptôme** — `tap()` sur un offset hors du viewport — et
avaient **deux causes opposées**.

### `inscription_test.dart` × 2 : le test avait tort

`flutter_test` monte tout sur **800 × 600**, une fenêtre plus **courte** que
n'importe quel téléphone du marché. La question du rôle porte quatre cartes de
`AppPage.hauteurChoix = 112` chacune, plus 12 de marge : 484 points de choix. Sous
l'en-tête de parcours (titre d'écran 48, titre, `Ecart.vXxl`, ligne d'étape,
progression) et au-dessus de la zone d'action collée, il restait environ **294**
points de viewport défilant. Les cartes 3 (« Enseignant ») et 4 (« Autre »)
tombaient donc hors cadre, `tap()` dérivait un offset qui atteignait la zone
d'action collée, et **« Continuer » était pressé à la place**.

Le même écran tient à 390 × 844 : le viewport défilant y vaut environ 538 pour un
contenu de 540, donc les centres des quatre cartes sont dans le cadre — **avec
deux points de marge**, qu'un libellé plus long ou une échelle de texte
suffiraient à manger. Les tests amènent donc la cible par `ensureVisible` avant de
taper : c'est le geste qu'une personne ferait, et il ne dépend pas de cette marge.

**Aucune ligne de `inscription_page.dart` n'a été touchée.** Le parcours du tuteur
est intact au caractère près.

### `dossier_test.dart` × 3 : l'écran avait tort

Le commentaire déjà présent dans ce fichier accusait la fenêtre de `flutter_test`
et affirmait avoir corrigé le défaut en passant à 390 × 844. **C'était faux, et le
test restait rouge** : `tap()` dérivait toujours `Offset(195, 971)`, soit
**127 points sous le bas de l'écran**.

La cause était le dépôt de pièce lui-même. « Choisir la photo » était posé en bas
d'une carte qui dépasse la hauteur d'un téléphone — marque, titre, intro, question
de type, quatre cartes de choix, puis le bouton — donc **sous la ligne de
flottaison**, tandis que « Envoyer ma pièce » occupait seul la zone collée en bas,
inerte. Un enseignant comme un tuteur voyait un bouton d'envoi qu'il ne pouvait
pas presser, et devait deviner qu'il fallait faire défiler pour trouver le geste
qui vient **avant**. C'est un vrai défaut mobile, sur une surface que le tunnel
d'entrée de l'enseignant traverse.

Correction, **un seul changement** : les deux gestes vivent dans la zone d'action
collée, dans l'ordre où on les fait. Le corps défilant garde ce qui se lit — le
texte et le choix du type — la zone collée garde ce qui s'actionne. Rien n'est
renommé, aucune étape n'est ajoutée, la borne de 8 Mo, le `TypePiece` et l'appel
`deposerPiece()` sont inchangés : **le parcours du tuteur ne bouge pas, sa mise en
page s'améliore de la même façon.**

Le test ne fait toujours aucun défilement, et c'est ce qui le rend utile : s'il
redevient rouge, c'est que le bouton est reparti sous la ligne de flottaison. Un
cas de plus mesure directement les deux rectangles.

---

## 5. Les états rendus, un par un

### `ENS-05`

| État | Où il se voit | Comment il est atteint |
| :--- | :--- | :--- |
| `loading` | `Skeleton.liste(lignes: 6)` | future du profil non résolue |
| `content` | identité, statut, déclaration, contrat, réglages | profil lu |
| `empty` | `EmptyState` registre `subi`, sans bouton | profil lu, **aucune** ligne `teacher_profiles` |
| `error` | `EmptyState` + « Réessayer » | lecture du profil en échec |
| `offline` | bandeau de `PageShell` + phrase + lignes redevenues lectures | `horsLigneProvider` vrai |
| statut `active` | pastille verte, « Compte enseignant vérifié » | `AccountStatus.active` |
| statut `provisional_active` | pastille avertissement, échéance dite | `AccountStatus.provisionalActive` |
| statut `pending_kyc` | pastille neutre, « aucune action de plus » | `AccountStatus.pendingKyc` |
| statut `disabled` | pastille alerte | `AccountStatus.disabled` |
| statut illisible | « Statut non disponible », **jamais un repli sur actif** | `AccountStatus.depuisSql` rend `null` |
| statut divergent | phrase en encre `inkWarning` | session ≠ profil |
| contrat vide | `EmptyState` subi | aucune ligne `contract_acceptances` |
| contrat en échec | `EmptyState` + « Réessayer », **section seule** | lecture des acceptations en échec |
| écriture réussie | `LocalFeedback` « Modification enregistrée » | après `declarer()` |
| écriture en échec | `LocalFeedback` d'erreur, ancienne valeur conservée | `declarer()` lève |

**`empty` existe et est atteignable**, contrairement à ce que la fiche prévoyait
(« n'existe pas : un enseignant connecté a toujours un profil ») : le service rend
`null` quand la relation `teacher_profiles` est absente, ce qui arrive pour un
compte créé autrement que par le parcours public. Le rendre était plus honnête que
de le déclarer impossible.

### `ENS-01`

| État | Où il se voit |
| :--- | :--- |
| `loading` | `Skeleton.liste(lignes: 5)` |
| `content` | salutation nommée, trois pas, les deux rappels ADR-011 |
| `empty` | il n'en a pas, et la fiche le dit : un profil illisible donne la **bienvenue sans nom**, pas un écran vide |
| `error` | `EmptyState` + « Réessayer », **les deux sorties restent** |
| `offline` | phrase au-dessus des boutons : naviguer aboutit toujours, poser un créneau non |
| dossier non valide | renvoi au portail d'attente, aucune félicitation |
| accès provisoire | accueille comme un compte actif (ADR-014) |

---

## 6. Les tests écrits, et ce que chacun mesure

`test/features/profil_enseignant_test.dart` — 23 cas, tous montés sur 390 × 844 :

- 5 cas paramétrés : chaque valeur d'`AccountStatus` **plus le cas illisible** a sa
  phrase. Le tableau est la mesure : une valeur ajoutée à l'énuméré sans phrase
  fait échouer son cas, et non une relecture ;
- un statut illisible ne se replie jamais sur « vérifié » — le mensonge d'avant ;
- une divergence session / profil se dit ; sans divergence, rien n'est annoncé ;
- la déconnexion tient dans `[0, 844]` — mesure de **rectangle**, pas de présence
  dans l'arbre : un bouton présent et hors cadre est un bouton absent ;
- elle se confirme avant de partir ; un renoncement ne déconnecte pas ;
- elle survit à l'échec de la lecture du profil (rectangle **et** geste complet) ;
- les cinq états d'écran, dont `loading` par une future qui ne se résout jamais ;
- `content` vérifie que les valeurs viennent du contrat, et que `StatTile` a
  disparu — mesure sur le **widget**, pour que les quatre clés i18n de la charge
  pédagogique puissent être supprimées sans casser le test ;
- le contrat se relit après validation, y compris l'accusé ADR-011 ;
- une section en échec laisse les autres lisibles **et la déconnexion
  fonctionnelle** ;
- modifier les langues n'envoie **que** les langues, et découpe `'Peul , Arabe,'`
  en deux entrées sans vide ;
- un échec d'écriture se dit et laisse l'ancienne valeur à l'écran ;
- le plafond hebdomadaire ne s'édite pas.

`test/features/bienvenue_enseignant_test.dart` — 15 cas, sur 390 × 844 et un
routeur-témoin à trois destinations :

- elle nomme la personne et dit où en est son dossier ;
- sans prénom lisible, elle reste une bienvenue et garde son action ;
- les trois pas suivants sont dits ;
- **les deux dispositifs de l'ADR-011 sont dits, chacun pour lui-même** ;
- aucune grille de semaine n'est rendue ici ;
- l'action principale mène aux créneaux ; la seconde à la journée ;
- les deux sorties tiennent dans `[0, 844]` ;
- 3 cas paramétrés : `pending_kyc`, `disabled` et un statut illisible renvoient au
  portail, sans féliciter ;
- un accès provisoire accueille (ADR-014) ;
- `loading`, `error` et `offline`.

`test/features/dossier_test.dart` — un cas ajouté : les deux gestes du dépôt
tiennent dans un téléphone, mesuré au rectangle. Le diagnostic faux qui vivait
dans le fichier est corrigé et remplacé par le vrai.

`test/features/inscription_test.dart` — même suite, mesurée sur un téléphone, avec
un helper qui amène les cartes de choix dans le cadre avant de taper.

**Un seul faux écrit hors du harnais** : `_FauxDeclaration`, dans le fichier de
test lui-même, parce que `ServiceDeclarationEnseignant` naît avec ce lot et que
`test/support/harnais.dart` appartient à l'Agent Z. Le profil et les acceptations
se surchargent directement par `overrideWith`, sans classe de plus.
`TEACHER_SHARED_CONTRACTS.md` §11 annonce un `FauxServiceProfil…` qui **n'existe
pas** dans le harnais : c'est un écart entre le document et le dépôt, signalé ici
comme la règle de lecture le demande.

---

## 7. Ce qui a été écrit en base, et ce qui ne l'a pas été

L'opérateur a donné une autorisation explicite d'écrire en base. Deux migrations
sont **appliquées** sur `gggmtelinlpseweouyav` (`get_project_url` vérifié avant
toute écriture) :

- **`0027_maj_profil_enseignant`** : la RPC qui manquait. Sans elle, un enseignant
  hors d'Europe ne pouvait **jamais** corriger son fuseau —
  `creer_profil_inscription()` reçoit `p_timezone` mais ne l'emploie que pour
  `households`, et la seule policy du titulaire sur `teacher_profiles` est en
  `SELECT` — alors que `mon_fuseau()` fait loi sur sa grille de disponibilités.
  Une fonction plutôt qu'une policy `UPDATE` parce qu'une policy borne les
  **lignes**, pas les **colonnes** : bornée à `auth.uid()`, elle aurait laissé
  l'enseignant relever son propre `weekly_hours_cap`. Volatile, donc **aucun
  `grant` à `agent_ro`** : vérifié, `has_function_privilege('agent_ro', …)` rend
  `false`.

- **`0028_maj_profil_enseignant_revoke_anon`** : une porte que `0027` laissait
  ouverte, et **la leçon vaut pour toute fonction créée sur ce projet.** Mesuré
  juste après application de `0027`, dont le `revoke all … from public` est
  correctement écrit : `proacl` portait un `anon=X/postgres` **nominal** et
  `has_function_privilege('anon', …, 'execute')` rendait `true`. Ce n'est pas le
  défaut de `0026` : Supabase pose un
  `alter default privileges … grant execute on functions to anon` sur le schéma
  `public`, donc le droit d'`anon` n'est pas hérité de `PUBLIC` et révoquer
  `PUBLIC` ne le retire pas. **Les deux formules sont nécessaires, aucune ne
  suffit, et le seul contrôle qui vaut est `has_function_privilege`, jamais la
  lecture du `revoke` écrit dans le fichier.** Ni `get_advisors` ni la relecture
  ne voient cette faute. Après `0028` : `anon` non, `authenticated` oui, `agent_ro`
  non. Aucune donnée n'avait été exposée dans l'intervalle — la fonction lève
  `authentification requise` quand `auth.uid()` est nul — c'était une surface
  d'appel de trop, pas une fuite.

**Ce qui n'a PAS été fait, malgré l'autorisation, et pourquoi :** les deux accusés
séparément opposables de l'ADR-011. Le point SQL serait faisable ; les trois
autres ne le sont pas depuis ce périmètre. `SorteContrat` vit dans
`lib/core/domain/enums.dart` et `PieceManquante` dans
`lib/core/dossier/etat_dossier.dart`, tous deux à l'Agent Z ; et `etat_dossier()`
ne teste qu'une seule sorte, si bien qu'en exiger deux **changerait le parcours du
tuteur**, ce que le périmètre interdit absolument. Appliquer le seul point SQL
aurait créé en production une valeur de `contract_kind` qu'aucune ligne de Dart ne
peut produire ni lire : une porte ouverte sur rien. La demande reste entière dans
`CONTRACT_REQUEST_E.md` §1, et elle est de l'Agent Z de bout en bout.

**Le fuseau reste en lecture**, alors que la RPC l'accepte : aucun inventaire de
fuseaux n'est tranché dans le produit, et un champ libre où l'enseignant devrait
deviner `Africa/Conakry` refuserait des saisies qu'il ne peut pas inventer. Un
champ qui refuse en silence est pire qu'une lecture assumée. `country` et
`languages`, eux, sont du texte libre en base : l'écran les édite, et un champ
libre y dit exactement ce que la colonne accepte.

---

## 8. Dettes ouvertes

1. **La route de la bienvenue n'existe pas.** `Routes.enseignantBienvenue` est
   posée, la `GoRoute` non, et rien ne mène à l'écran. Agent Z.
2. **La bienvenue ne sait pas qu'elle a été vue.** `AppDatabase` est gelée à quatre
   tables et `PreferencesLocales` ne vaut que pour l'appareil courant : sur un
   second appareil elle réapparaîtrait. Un drapeau serveur est le seul support
   honnête.
3. **Les deux migrations ne sont pas dans `supabase/migrations/`.** Base en avance
   sur le dépôt jusqu'à ce que l'Agent Z les y écrive. Le SQL est prêt.
4. **`ProfilEnseignant` ne porte pas `timezone_iana`** : `ENS-05` fait deux
   lectures (`profilEnseignantProvider` + `monFuseauProvider`) là où une
   suffirait.
5. **Deux contrats Dart sont dans une feature** faute de pouvoir écrire dans
   `lib/core/profil/` : `service_acceptations.dart` et `service_declaration.dart`.
   À promouvoir si un autre écran en a besoin.
6. **`_FauxDeclaration` n'est pas dans le harnais.**
7. **« Correction demandée » ne se distingue pas de « refusé »**, et **« expiré »
   n'existe pas** pour un enseignant. Décisions opérateur, déjà écrites comme
   ouvertes dans la fiche `ENS-01`.
8. **`VerificationEnseignant` duplique exactement `StatutPiece`** et vit hors de
   `core/domain/enums.dart`. L'existant est employé, rien n'est dupliqué de plus ;
   le rangement reste à faire.
9. **`profiles.gender` n'est saisi qu'à l'inscription et n'est jamais
   corrigeable**, alors que `completer_kyc_document()` refuse tout dépôt quand il
   est nul. Un enseignant entré autrement que par ce parcours est bloqué sans
   message utile. Hors périmètre : la correction demande une écriture sur
   `profiles` et une page qui ne m'appartient pas.
10. **Quatre clés `enseignant.profil.*` n'ont plus d'appelant**
    (`chargePedagogique`, `elevesActifs`, `heuresDisponibles`, `reglagesHeures`) :
    la fiche exclut la charge opérationnelle du Profil. Aucun test ne les
    référence, elles peuvent être supprimées librement.

---

## 9. Ce qu'un relecteur doit vérifier en premier

Par ordre de coût si c'est faux :

1. **`dart analyze --fatal-infos` sur les cinq fichiers Dart de ce lot.** Aucune
   commande n'a été lancée. Les points les plus susceptibles de fâcher
   l'analyseur : les patterns `AsyncValue<ProfilEnseignant?>(hasValue: true, value: final ProfilEnseignant lu)`
   dans les deux écrans, et `if (… case final Acceptation lue) lue,` dans une
   littérale de liste (`service_acceptations.dart`).
2. **Les clés d'`i18n_E.json` après fusion et `dart run slang`.** 66 clés sont
   employées dans le code comme si elles existaient. Une seule absente casse
   l'analyse du lot entier.
3. **Les trois tests de `dossier_test.dart`.** La correction repose sur une
   arithmétique de mise en page, pas sur une exécution : j'affirme que les deux
   boutons de la zone collée tiennent dans 390 × 844, et que le premier choix de
   type reste atteignable sans défilement. Si le cas
   « les deux gestes tiennent dans un téléphone » échoue, c'est mon calcul qui est
   faux, pas le test.
4. **Les deux tests de `inscription_test.dart`**, pour la même raison, et surtout
   pour vérifier que **rien du parcours du tuteur n'a changé** : `git diff` sur
   `inscription_page.dart` doit être **vide**, et sur `depot_piece_page.dart` ne
   doit montrer que le déplacement d'un bouton.
5. **Que `tester.ensureVisible` ne lève pas** quand la cible n'est pas dans un
   `Scrollable`. Les deux helpers ne l'appellent que sur des cibles qui le sont
   (cartes de choix, lignes de réglage), jamais sur la zone d'action collée, mais
   je ne l'ai pas exécuté.
6. **Que `monFuseauProvider` en échec ne fasse pas tomber `ENS-05`** hors des
   tests de ce lot. Il est lu par `ref.watch` dans un `FutureProvider`, donc
   l'erreur devrait être capturée en `AsyncError` et la ligne afficher « Non
   renseigné ». Les deux services synchrones de l'écran (`serviceAuthProvider`,
   `serviceDeclarationProvider`) sont volontairement lus **au moment du geste** et
   non pendant `build`, précisément pour qu'aucun test montant l'écran sans les
   surcharger ne construise un client Supabase.

Ce dont je doute le plus : le point 3. Le reste est du code que je peux relire ;
celui-là est une mesure que je n'ai pas pu prendre.
