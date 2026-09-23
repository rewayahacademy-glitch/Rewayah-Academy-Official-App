# TC_AGENT_E_REPORT.md — Classroom Shell

> **Lot livré, vert, partiel et déclaré.**
> Worktree `D:\RA_TC\e`, baseline `0071557`.
> `flutter analyze lib test` → **No issues found**.
> `flutter test test/teaching_core/e` → **93 tests, All tests passed**.
> `dart run tool/verifier_jetons.dart` → **10 violations, toutes pré-existantes et
> toutes hors du périmètre d'Agent E** (détail en §7).

---

## 1. Ce qui a été construit

### 1.1 Domaine — `lib/core/tc_classe/`

| Fichier | Rôle |
|---|---|
| `teacher_student_projection.dart` | `TeacherStudentProjection`, `EtatPresenceProjete` (9 valeurs), `ResumeSeance`, `AssiduiteRecente` |
| `roster_classe_vm.dart` | `RosterClasseVM`, `FileRecitation` |
| `session_live_vm.dart` | `SessionLiveVM`, `EnseignantDeClasse` |
| `port_roster_enseignant.dart` | `PortRosterEnseignant`, `EchecRoster` / `MotifEchecRoster` |
| `port_rappel_discret.dart` | `PortRappelDiscret`, `EchecRappel` / `MotifEchecRappel` |
| `port_session_persistante.dart` | `PortSessionPersistante`, `SessionEnCours` |
| `roster_enseignant.dart` | `projeterEtatPresence`, `ficheDepuisRosterV`, `composerRoster`, `RosterEnseignantSupabase`, `rosterClasseProvider` |
| `rappel_discret.dart` | `RappelDiscretCadence`, `TransportRappel`, `cooldownRappelDiscret` |
| `session_persistante.dart` | `ControleurSessionPersistante`, `CoursOuvert`, `EtatSessionPersistante`, `etatSessionProvider` |
| `controleur_recitation.dart` | `ControleurRecitation`, `recitationProvider` |
| `libelles_tc_classe.dart` | La façade i18n provisoire (décision D-03), 88 clés `tc.classe.*` |
| `ports_externes/` | 6 stubs : `SessionClockVM` (A), `TitreEnseignant` (A), `ContentPosition` / `ContentRange` / `LearningAssignment` (B, D), `PortAnnonceObservation` (G) |

### 1.2 Écrans — `lib/features/tc_classe_live/`

| Fichier | Rôle |
|---|---|
| `vue_classe_live.dart` | **Fonction pure** de composition : `CompositionClasse`, `PlaceRoster`, `PoidsVideo`, `MotLien` |
| `classe_live_page.dart` | La Classe Live, `ContexteClasseLive`, la barre basse, l'attente |
| `entete_classe.dart` | L'en-tête : groupe, Sayyid/Sayyida, temps restant, lien, annonces d'observation |
| `roster_classe.dart` | `PanneauRoster`, `LigneRoster`, `BoutonRoster`, libellés et tons d'état |
| `fiche_seance.dart` | La fiche pédagogique de séance et ses actions fréquentes |
| `scene_classe.dart` | La scène vidéo (scène / bande / vignette) |
| `slots_tc_classe.dart` | `SlotClasse`, `SurfaceSupport`, `HoteDock`, `SurfaceBibliotheque` |
| `pre_vol_classe.dart` | `VuePreCours` (pure) + `PreCours` |
| `barre_cours_en_cours.dart` | La barre compacte applicative |
| `routes_tc_e.dart` | `RoutesTcE.classe` + `routesTcE()` — **retourne des routes, ne construit aucun `GoRouter`** |

### 1.3 Tests — `test/teaching_core/e/` (93 tests)

`vue_classe_live_test` 15 · `roster_test` 17 · `pii_test` 6 ·
`rappel_discret_test` 8 · `session_persistante_test` 13 · `pre_cours_test` 11 ·
`classe_live_page_test` 19 · plus `faux/faux_classe.dart` et
`support/hote_classe.dart`.

---

## 2. Les deux invariants du lot, et comment ils sont tenus

### 2.1 Confidentialité : connaissance pédagogique forte, connaissance privée minimale

**Ce qui tient l'invariant n'est pas ce fichier-ci, et c'est le point.** La
protection tient parce que `teacher_roster_v` a retiré `last_name` en 0005
(ADR-008) et que `profiles` n'accorde aucune policy `select` à l'enseignant. Le
code Dart en est la **preuve lisible**, pas la barrière.

Ce que le lot fait, concrètement :

- le roster ne rend **que** `TeacherStudentProjection`, et aucun autre type d'élève
  n'existe dans `lib/features/tc_classe_live/` ;
- `ficheDepuisRosterV` lit **quatre colonnes nommées** et rien d'autre. `riwaya`
  est disponible dans la vue et **volontairement pas projetée** : un agent
  n'ajoute pas un champ parce que la vue le lui offre ;
- `groupe_detail()` n'est appelée nulle part — elle rend `student_nom` et reste
  admin-only ;
- `rosterDeGroupe` **refuse explicitement** (`EchecRoster.projectionAbsente`)
  plutôt que de rendre une liste vide, qui se lirait comme « ce groupe n'a aucun
  membre ».

**Test de non-régression `pii_test.dart`** : on fabrique une ligne de
`teacher_roster_v` **polluée** par dix colonnes interdites (nom, initiale,
téléphone, e-mail, adresse, identité de tuteur, IBAN, géolocalisation,
identifiant d'appareil, `household_id`), on la passe au mapping, puis on monte le
roster **et** la fiche, et on balaie **tous les `Text` et tous les libellés
sémantiques** du sous-arbre. Aucune des dix aiguilles ne doit apparaître. Le test
vérifie aussi que le prénom et l'`academy_id` sont bien là : sans cette moitié,
un rendu vide passerait le test.

Un sixième test vérifie qu'**aucune UI n'écrit « mode enfant »** (décision D-07)
et que « Interface guidée » s'affiche bien à la place.

### 2.2 Session persistante : le shell ne possède pas la room

`_SallePageEtat.dispose()` de `salle_page.dart` appelle `_moteur.quitter()` **sans
condition** : c'est pour cela que revenir au Groupe coupe le cours aujourd'hui. Ce
fichier est PROTECTED et nommé INTERDIT ; il n'a pas été touché.

À la place, `ControleurSessionPersistante` vit au **niveau applicatif**, à côté de
`moteurSalleProvider` qui est déjà un Provider racine :

- il porte les **trois temps de l'entrée** — pré-vol, jeton, connexion — et
  **il est idempotent** : un second `ouvrir()` pour la même séance ne redemande
  aucun jeton et ne rejoint pas une seconde fois. C'est ce qui rend le retour
  depuis la barre « Cours en cours » instantané, et ce qui empêche une **seconde
  `Room`** ;
- **il n'appelle `quitter()` sur le moteur qu'en un seul endroit**, dans
  `quitter()`, et `quitter()` n'est atteint que par un geste explicite. Vérifiable
  d'un `grep` sur le fichier ;
- **`_ClasseLivePageEtat.dispose()` ne quitte rien** : il annule trois
  abonnements, c'est tout ;
- la sortie volontaire **annonce au serveur AVANT de déconnecter le moteur**. Un
  journal partagé entre les deux doubles le mesure : `['annonce', 'deconnexion']`,
  dans cet ordre. LiveKit émet le même `left` dans les deux cas ; seule cette
  écriture distingue une sortie voulue d'une perte de réseau.

Tests : démonter l'écran → `departs == 0` ; ouvrir la Bibliothèque → `departs == 0`
et aucune sortie annoncée ; libérer le contrôleur → `departs == 0`.

---

## 3. Une découverte qui a changé le code, pas seulement le test

Le premier test du passage en arrière-plan échouait, et la cause n'était pas le
test : **`SchedulerBinding` coupe les frames dès l'état `paused`**. Une
application suspendue ne rend aucune image. Un avertissement affiché *pendant* la
suspension ne serait donc **jamais lu** — et il serait effacé au retour, avant la
première frame.

La conception a été corrigée plutôt que le test contourné. L'état porte désormais
deux drapeaux :

- `enArrierePlan` — vrai pendant la suspension, **pour la logique seulement** ;
- `retourDeSuspension` — posé à la suspension, **tenu au retour**, et il ne tombe
  que lorsque le moteur redit `connecte` ou `retabli` (`confirmerLien()`, appelé
  par l'écran depuis l'abonnement qu'il a déjà — pas un second abonnement au
  moteur).

C'est exactement ce que demande la spec §9.4 : « ne pas promettre une connexion
que la plateforme ne permet pas ». Le test joue maintenant la vraie séquence —
`inactive` → `hidden` → `paused` → `resumed` — vérifie que rien n'a été coupé, que
le doute est dit, puis qu'il tombe quand le moteur reconfirme.

---

## 4. Ce qui est réutilisé, et ce qui ne l'est pas

### Réutilisé tel quel, sans être recopié

| Existant | Usage |
|---|---|
| `moteurSalleProvider`, `VideoSessionProvider` | **Aucune seconde `Room`.** Adapter par-dessus, jamais un second moteur |
| `serviceVideoProvider` (`acces`, `annoncerSortie`) | Entrée et sortie |
| `preVolProvider` | Le preflight de la spec §9.5 **existait déjà** ; le lot ajoute l'écran qui l'affiche |
| `VueSalle.depuis` | **Consommée, pas recopiée** : elle décide de la phase d'entrée, du rôle et des capacités ; `VueClasseLive` décide de la composition. Deux questions, deux fonctions |
| `presenceSeanceProvider`, `PresenceParticipant`, `EtatPresence` | La source du roster. **Aucune seconde boucle** n'est ouverte : `rosterClasseProvider` compose au-dessus |
| `QualiteLien` | L'état réseau lit le flux du moteur. **Aucune mesure maison** |
| `PageImmersive` | La coque plein cadre de la salle |
| `StatusPill`, `EmptyState`, `Pressable`, `SectionHeader`, `AvatarTile`, `ActionPrincipale`, `AppBottomSheet`, `ConfirmDestructive`, `LocalFeedback`, `PermanentNotice`, `AppGabarit` | 11 composants partagés du catalogue. **Aucun composant n'a été ajouté à `lib/core/widgets/`** |

### Composants créés, et pourquoi aucun existant ne convenait

- **`SceneClasse`** — `salle_page.dart` porte déjà `_Scene`, `_Galerie`, `_Cadre`,
  mais **elles sont privées à un fichier qui m'est nommément interdit**. Elles sont
  inaccessibles, pas seulement inconvenables. La duplication est **écrite dans
  l'en-tête du fichier** et la promotion est demandée en §5.1 du CONTRACT_REQUEST.
- **`PanneauRoster` / `LigneRoster`** — `LignePresence` rend un `VuePresence`, pas
  une `TeacherStudentProjection` ; le roster pédagogique porte prénom,
  `academy_id`, état et récitation.
- **`SlotClasse`** et ses trois surfaces — l'application de l'AMENDEMENT 2 du
  contrat, pour trois ports dont la signature n'existe nulle part (§4 du
  CONTRACT_REQUEST).

### Choix de barre basse à connaître

Les commandes passent par `ActionPrincipale` (libellés) et non par des boutons
circulaires à icône : `_Commande` de `salle_page.dart` est **privée** elle aussi,
et la recopier aurait fait un cinquième dessin de bouton dans le produit.
`tool/verifier_jetons.dart` refuse tout bouton Material ; `ActionPrincipale` est le
seul point d'entrée des actions.

---

## 5. Ce qui est mocké, et ce qui ne l'est pas

| Surface | État réel |
|---|---|
| Rappel discret | **Cadencé, testé, et il n'aboutit pas.** `transportRappelAbsent` échoue explicitement tant qu'Agent Z n'a pas branché `PortRealtimePedagogique.emettreCible`. Un transport muet ferait croire à l'enseignant que l'élève a été appelé |
| Support pédagogique | **Slot vide** : Agents B et C le remplissent. L'écran dit « Aucun support présenté » |
| Teaching Dock | **Slot vide**, et il ne rend rien du tout : un dock en attente occuperait la place du Coran |
| Bibliothèque en classe | **Slot vide**, avec un état explicite « Bibliothèque non branchée » : ici l'enseignant a appuyé sur un bouton, il doit savoir pourquoi rien ne s'ouvre |
| Horloge de séance | **Non branchée.** `SessionClockVM` est un stub d'Agent A ; la Classe Live la reçoit en paramètre et affiche le groupe **sans temps restant** quand elle manque. Aucun compte à rebours n'est calculé localement |
| Annonces d'observation | Reçues en paramètre (`List<AnnonceObservation>`). Le port d'Agent G est stubé, **pas implémenté** |
| Projection pédagogique | `curriculum_path`, `current_unit`, `active_goals`, `resume_points`, `authorized_pedagogical_notes`, `interface_mode` : **rien ne les sert côté serveur.** La fiche affiche un état explicite « Suivi pédagogique indisponible » |
| Roster de groupe hors séance | **Refusé explicitement** : la RPC n'existe pas |
| « Noter » et « Signaler un besoin » | **Callbacks non branchés** ; quand ils sont `null`, l'action **n'est pas rendue** |

---

## 6. Limites honnêtes

1. **`recentAttendance` n'est pas branché.** `ServiceSuivi`, `presence_seance_v` et
   `SortDuCours` existent et suffiraient, mais le brancher demandait de croiser
   plusieurs séances par élève ; ce lot lit une séance. Le champ est au contrat, la
   fiche l'affiche quand il est rempli, et **rien ne le remplit aujourd'hui**.
2. **`suivreRoster` du port n'est empruntée par aucun écran.** La Classe Live
   compose `rosterClasseProvider` au-dessus de `presenceSeanceProvider`, la boucle
   de 20 s qui existe déjà. La méthode est là parce que le contrat l'exige.
3. **La file de récitation est un état client, non partagé.** Rien ne la transporte
   aux élèves : cela demanderait `PortRealtimePedagogique`, dont la charge utile
   n'a pas de signature (§4.1 du CONTRACT_REQUEST). Elle survit à la navigation,
   pas au rechargement.
4. **Le post-cours (spec §9.5, colonne « après ») n'est pas construit.** Il
   appartient à `PortPostCours` d'Agent H. Ce lot livre le pré-cours.
5. **La vignette vidéo mobile est posée à côté du support, pas par-dessus.** La
   spec §9.2 dit « vignette selon le contexte » et « aucune barre d'outils ne
   couvre le Coran » : le choix a été fait de ne rien superposer au support. Sur
   390 points, le support garde environ 292 points et la vignette 96.
6. **L'état réseau est affiché en permanence**, y compris quand il est bon
   (« Réseau bon »). La spec §9.1 le demande dans la barre basse ; le dépôt, lui,
   avait tranché l'inverse (`VueSalle.lienADire` ne parle que des deux valeurs
   basses). **La spec l'emporte ici, et la tension est déclarée.**
7. **Aucune caméra d'élève n'est forcée ni bloquée côté client.** Micro et caméra
   fermés à l'entrée sont **déjà** tenus par `livekit_session_provider.dart` pour
   les quatre rôles, et par `canPublishSources` côté serveur. Re-coder un mute UI
   aurait été un second endroit qui pourrait diverger.
8. **Aucune commande vocale n'existe** (décision D-10), et aucune infrastructure
   qui pourrait en devenir une.
9. **`_RosterVide` défile.** `EmptyState` posé dans une colonne de 256 points
   dépassait de 64 points sur une tablette en paysage — **mesuré**, pas supposé.
   Le défilement rend la place au texte au lieu de le rogner.

---

## 7. Défauts pré-existants croisés, non corrigés

1. **`dart run tool/verifier_jetons.dart` est rouge dans la baseline `0071557`** :
   10 violations, **aucune dans `tc_classe` ni `tc_classe_live`**. Détail :
   `nav_shell.dart:461` (`IconButton`), `nav_shell.dart:513` et
   `sous_navigation_domaine.dart:63` (`onTap:` nu), 5 M-dash répartis dans
   `nav_shell.dart`, `menu_filtre.dart`, `dossiers_page.dart`, `journal_page.dart`.
   `flutter analyze lib test` est **propre**.
2. `supabase/migrations/0029` écrite mais non appliquée — `dossiers_en_attente()`
   livre nom et prénom à un appelant anonyme.
3. `test/.../catalogue_galerie_test` rouge : aucun composant nouveau ne peut entrer
   dans `lib/core/widgets/`.
4. `session_participants.entered_at` / `exited_at` ne sont jamais écrites.
5. `lesson_reports_teacher_write` (0001:1064-1069) ne vérifie pas que `session_id`
   appartient à l'enseignant (rappel de la cartographie §6 ; appartient à Agent H).

---

## 8. Ce qu'Agent Z devra brancher

1. **`redirection.dart`** — sans quoi `/tc/classe` est inatteignable (§5.2 du
   CONTRACT_REQUEST). Appeler `routesTcE()` depuis `app_router.dart` et promouvoir
   `RoutesTcE.classe` dans `routes.dart`.
2. **La barre `BarreCoursEnCours`** dans la coque de navigation. Elle rend un
   `SizedBox.shrink()` quand aucun cours n'est ouvert : elle peut être posée
   inconditionnellement sans déplacer un pixel des écrans ordinaires. Lui fournir
   `onRevenir`.
3. **Les trois slots** : `support`, `dock`, `bibliotheque` de `ContexteClasseLive`.
4. **`PortHorlogeSeance`** (A) → `ContexteClasseLive.horloge`, et
   `ControleurSessionPersistante.rafraichirHorloge` pour le suivi.
5. **`PortAnnonceObservation`** (G) → `ContexteClasseLive.annonces`.
6. **`PortRealtimePedagogique.emettreCible`** (F) → `RappelDiscretCadence.transport`.
   **Un seul endroit change.**
7. **`onNoter`** (cahier du chantier enseignant) et **`onSignaler`**
   (`PortSignalement`, H).
8. **`groupes.seuil_max`** → `ContexteClasseLive.seuilMax`. Aucun fichier de ce lot
   n'écrit un plafond : aucun nombre de places n'y est écrit en dur.
9. **La fusion i18n** : `docs/teaching-core/i18n/tc_i18n_E.json` (88 clés
   `tc.classe.*`), puis supprimer `lib/core/tc_classe/libelles_tc_classe.dart` et
   les six stubs de `lib/core/tc_classe/ports_externes/`.
10. **L'amendement `SessionEnCours.horloge` nullable** (§3 du CONTRACT_REQUEST),
    après quoi `CoursOuvert` disparaît.

---

## 9. Vérifications lancées, et leurs résultats

```
flutter analyze lib test                 -> No issues found!
flutter test test/teaching_core/e        -> 93 tests, All tests passed!
dart run tool/verifier_jetons.dart       -> 10 violations, toutes pre-existantes,
                                            aucune dans le perimetre d'Agent E
git status --porcelain                   -> docs/teaching-core/
                                            lib/core/tc_classe/
                                            lib/features/tc_classe_live/
                                            test/teaching_core/
```

`windows/flutter/generated_plugin_registrant.*` et `generated_plugins.cmake` ont
été modifiés par `flutter pub get` et **restaurés** (`git checkout --`) : ils sont
hors périmètre.
