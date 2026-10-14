# TC_AGENT_G_REPORT.md

> **Agent G — Observation & Policies.** Worktree `D:\RA_TC\g`, baseline `0071557`.
> `flutter analyze lib test` : **propre**. `flutter test test/teaching_core/g` : **75 tests, tous verts**.
> `git status --porcelain` : quatre préfixes, tous les miens.

---

## 0. En une phrase

Le lot livre **le modèle, les trois ports, le moteur de visite et les cinq surfaces** de l'observation
tuteur / Admin / Contrôleur, écrits contre des RPC qui **n'existent pas encore en base**. Rien de ce
lot n'observe une vraie séance aujourd'hui : la migration demandée dans
`TC_CONTRACT_REQUEST_G.md` est la condition, et elle est entière.

---

## 1. Fichiers créés

### `lib/core/tc_observation/` — le domaine (10 fichiers)

| Fichier | Ce qu'il porte |
|---|---|
| `guardian_observation_policy.dart` | `GuardianObservationPolicy`, `SourcePolitique`, `plafondDeVisite()` |
| `guardian_session_visit.dart` | `GuardianSessionVisit`, `RoleObservateur`, `FinDeVisite` |
| `port_politique_observation.dart` | `PortPolitiqueObservation`, `BudgetObservation`, `MotifRefusObservation`, impl. Supabase, providers |
| `port_visite_observation.dart` | `PortVisiteObservation`, `ResultatEntreeObservation`, impl. Supabase, provider |
| `port_annonce_observation.dart` | `PortAnnonceObservation`, `AnnonceObservation`, impl. Supabase, provider |
| `mode_entree_admin.dart` | `ModeEntreeAdmin`, `CapaciteObservation`, `ProfilObservateur` |
| `vue_budget_observation.dart` | `VueBudgetObservation` — **le compte à rebours borné, fonction pure** |
| `moteur_visite_observation.dart` | `MoteurVisiteObservation`, `EtatVisiteObservation`, `PhaseVisite`, providers |
| `echec_observation.dart` | `EchecObservation`, `MotifEchecObservation` |
| `libelles_tc_g.dart` | La façade i18n, une constante par clé `tc.observation.*` |

### `lib/features/tc_observation_ui/` — les surfaces (9 fichiers)

| Fichier | Ce qu'il porte |
|---|---|
| `options_entree_observation.dart` | **Fonction pure** : qui a le choix de son mode. Contrôleur : personne. |
| `vue_observation_tuteur.dart` | **Fonction pure** : ce que la visite expose, et rien d'autre |
| `etat_reglages_observation.dart` | **Fonction pure** : les trois choix, leurs bornes, la politique produite |
| `choix_entree_observation.dart` | L'écran d'avant-entrée, par rôle |
| `panneau_observation_tuteur.dart` | Ce que le tuteur voit pendant sa visite |
| `indicateur_observation.dart` | L'annonce côté enseignant, l'indicateur discret côté enfant |
| `module_reglages_observation.dart` | Le module de réglages **isolé, non routé** |
| `entree_observation_page.dart` | L'écran qui assemble le tout |
| `routes_tc_g.dart` | `routesTcG()` — retourne des routes, ne construit aucun `GoRouter` |

### `test/teaching_core/g/` — 75 tests (9 fichiers)

`moteur_visite_observation_test.dart` (16) · `politique_observation_test.dart` (15) ·
`ecrans_observation_test.dart` (14) · `etat_reglages_observation_test.dart` (10) ·
`vue_observation_tuteur_test.dart` (7) · `vue_budget_observation_test.dart` (7) ·
`options_entree_observation_test.dart` (6) · `faux/faux_observation.dart` · `support/hote_tc_g.dart`.

### `docs/teaching-core/`

`TC_AGENT_G_REPORT.md` · `TC_CONTRACT_REQUEST_G.md` · `i18n/tc_i18n_G.json` (63 clés).

---

## 2. L'invariant du lot : le client ne peut pas prolonger sa visite

C'était la consigne centrale, et voici **exactement** ce qui est garanti et ce qui ne l'est pas.

### Ce qui est garanti, et testé

**Deux sources de temps, une seule autorité.** Le flux de budget vient du serveur et peut terminer la
visite à tout instant. Le battement local ne fait que repeindre un nombre, et ce nombre est calculé
par `VueBudgetObservation.depuis`, qui **plancherise l'écoulé à zéro** : un écoulé négatif — horloge
reculée, veille, bricolage volontaire — ne rend aucune seconde. Il en découle l'asymétrie voulue :

| Manipulation du client | Effet |
|---|---|
| horloge **avancée** | la visite se termine **plus tôt**. Permis : plus strict que la borne. |
| horloge **reculée** de 10 min | `restantAffiche` reste à la valeur serveur. Le serveur ferme quand même. |
| battement **supprimé** | aucun décompte local, et le serveur ferme quand même. |
| budget généreux arrivé **après** la fin | la visite ne se rouvre pas. |

Sept tests couvrent ce tableau, dont
`« un battement supprime ne prolonge rien : le serveur ferme »` et
`« reculer l'horloge locale ne rend pas une seconde »`.

**Une panne n'est jamais une permission.** Si la RPC d'entrée échoue, la phase est `indisponible`,
jamais `enVisite`. Test explicite :
`« une capacite serveur absente ne devient jamais une entree »`.

**La sortie n'est pas avalée.** Le contrat nomme le précédent à ne pas reproduire :
`ServiceVideo.annoncerSortie()` avale volontairement son échec, ce qui est acceptable pour une trace
et inacceptable pour un quota. `EtatVisiteObservation.sortieConfirmee` passe à faux et l'écran le dit.

### Ce qui n'est PAS garanti par ce lot

**Ce code ne borne rien.** Un compte à rebours Dart ne peut pas expulser quelqu'un d'une salle
LiveKit. La borne réelle tient à deux choses, toutes deux **demandées et non livrées** :

1. `autoriser_jeton_video()` doit **refuser** un `guardian_observer` dont le quota est épuisé,
   **avant** d'émettre le jeton ;
2. le TTL du jeton doit valoir `least(token_ttl_seconds, restant_secondes)`, pour que le jeton expire
   exactement à la fin du budget.

Tant que ces deux points ne sont pas en base, **un client modifié peut rester dans la salle**. Ce
n'est pas une faiblesse de mon code : c'est la partie que mon périmètre m'interdit d'écrire
(`lib/core/video/service_video.dart` READ-ONLY, migrations interdites). Elle est détaillée en
§1.5 du `TC_CONTRACT_REQUEST_G.md`.

---

## 3. Ce qui marche aujourd'hui, sans base

Tout ce qui ne demande pas le serveur :

- les **trois choix** du module de réglages, leurs bornes, et la politique qu'ils produisent ;
- le **compte à rebours** et son bornage ;
- le **filtre de la visite tuteur** : enseignant + son propre enfant, jamais un camarade ;
- **l'absence d'option de mode pour le Contrôleur**, prouvée deux fois : par la fonction pure et par
  l'arbre de widgets ;
- les **deux modes Admin** et leurs capacités attendues ;
- la **machine d'états** de la visite, de la demande à la fermeture, avec ses six phases ;
- la **route** `/tc/observation/:seanceId`, montée dans un test.

Chaque état de refus a son message explicite. Aucun écran ne reste muet.

---

## 4. Ce qui est mocké, vide ou absent — les limites honnêtes

1. **Aucune RPC n'existe.** `politique_observation_effective`, `budget_observation`,
   `entrer_observation`, `sortir_observation`, `visites_observation`, `annonces_observation` : les six
   sont écrites côté Dart, aucune côté base. Chaque appel rend aujourd'hui
   `EchecObservation(capaciteAbsente)` et l'écran affiche « L'observation n'est pas encore activée sur
   cette installation. » **C'est un état explicite, pas un faux succès.**
2. **La table `guardian_session_visit` n'existe pas**, ni les cinq colonnes sur `groupes`, ni les deux
   valeurs de `participant_role`. L'entrée Admin est donc **impossible en production** :
   `rejoindre_observation()` lève `insufficient_privilege` pour tout rôle autre que `controller`.
3. **Le panneau tuteur n'affiche aucune vidéo et aucun support.** Les participants et le support
   partagé viennent de la Classe Live (Agent E) : je livre un panneau qui les reçoit
   (`supportPartage` en emplacement, `VueObservationTuteur` en entrée) et, sans eux, ses états vides
   explicites. `entree_observation_page.dart` passe donc une liste de participants **vide**.
   Agent Z branche la vraie liste.
4. **La page ne demande aucun jeton vidéo et n'entre dans aucune `Room`.** Elle ouvre le *droit*
   d'entrer, pas la salle. Un second `create-room-token` serait une seconde porte vidéo.
5. **Aucune route n'est branchée.** `redirection.dart` n'est pas ajusté : en l'état, `/tc/observation/...`
   serait redirigée vers la racine du rôle, donc **inatteignable**. Aucune entrée de navigation n'est
   posée non plus (`accueil_famille_page.dart` et `planning_page.dart` sont lecture seule pour moi).
6. **Le module de réglages n'est volontairement branché nulle part** — consigne explicite. Il n'est
   ni dans `admin_domaine.dart` (gelé à huit domaines) ni dans `ongletsConfiguration()`.
7. **« Administration Rewayah » n'est qu'un libellé côté client.** L'identité institutionnelle réelle
   doit être posée dans le jeton LiveKit, côté serveur : demandée, non livrée.
8. **`annonces_observation` est relue par sondage** (10 s) et le budget toutes les 5 s. Supabase
   Realtime n'est branché nulle part dans `lib/` ; l'ouvrir pour deux minutes de compte à rebours
   aurait été une infrastructure neuve pour un besoin minuscule. Documenté dans le code.
9. **`GuardianObservationPolicy.defautsNormatifs` code en dur 1 visite / 120 secondes.** C'est un
   écart assumé avec la règle « jamais de capacité codée en dur » : ce sont les valeurs normatives de
   la spec §11.1, le constructeur sert de référence écrite et de double de test, et **aucun écran ne
   l'appelle**. Rien dans le code ne l'interdit pourtant : si vous voulez la barrière plutôt que la
   discipline, supprimez ce constructeur à l'intégration une fois `app_config` peuplé.
10. **Aucun test de bout en bout depuis la page.** Un `entrer()` déclenché depuis l'écran abonne le
    battement par défaut (`Stream.periodic` à la seconde) et laisserait une minuterie pendante en fin
    de test. Le moteur est donc testé en unité avec un battement injecté, et les surfaces en widget
    avec des états déjà construits. La couture entre les deux — le `StreamProvider` de famille — n'est
    pas couverte.
11. **`fin_de_visite` ne prend jamais les valeurs `seanceTerminee`, `revocationServeur` ni
    `deconnexion` côté client.** Elles sont modélisées et lues depuis le serveur, mais seul le serveur
    peut les constater. Le moteur n'émet que `sortieVolontaire` et `quotaAtteint`.
12. **La fermeture d'un intervalle resté ouvert n'est pas résolue.** Un onglet fermé n'annonce rien ;
    `dispose()` ne ferme volontairement pas l'intervalle, parce qu'une page démontée n'est pas une
    sortie. Deux voies sont proposées à Agent Z (§1.7 du CONTRACT_REQUEST) ; **l'arbitrage n'est pas
    pris**, et sans lui le quota est faux dans un sens ou dans l'autre.

---

## 5. Ports

### Produits

| Port | Chemin | État |
|---|---|---|
| `PortPolitiqueObservation` | `lib/core/tc_observation/port_politique_observation.dart` | signature conforme au contrat §13 |
| `PortVisiteObservation` | `lib/core/tc_observation/port_visite_observation.dart` | signature conforme au contrat §14 |
| `PortAnnonceObservation` | `lib/core/tc_observation/port_annonce_observation.dart` | signature conforme au contrat §14 |

Les trois ont une implémentation Supabase et un provider, au chemin canonique, selon le patron des
31 services du dépôt (`abstract interface class` + `XSupabase` + `Provider` dans le même fichier).

### Consommés — **aucun stub, et c'est un choix documenté**

L'ownership me donne `SessionLiveVM` (E) et `SessionClockVM` (A) comme ports consommés. **Je n'ai
stubé ni l'un ni l'autre**, pour deux raisons distinctes :

- **`SessionClockVM` (A) « pour le compte à rebours de budget »** : ce n'est pas le même temps. Le
  compte à rebours de budget compte des secondes d'observation, pas le temps de la séance, et sa
  vérité est `BudgetObservation`, que le serveur calcule. Quant à la validité temporelle de la séance
  — « est-elle en cours ? », « suis-je dans la fenêtre ? » — elle m'arrive déjà comme deux motifs de
  refus serveur (`seanceNonActive`, `horsFenetre`). Recopier `SessionClockVM`, `HorlogeAffichee`,
  `PhaseSeance`, `NoticeDst` et `EcheanceDst` pour ne rien en faire aurait créé cinq occasions de
  diverger d'un contrat que je n'utilise pas.
- **`SessionLiveVM` (E)** : c'est Agent E qui consomme *mon* `PortAnnonceObservation`, pas l'inverse.
  Le sens de la dépendance va de G vers E, et l'amendement 2 des contrats le recommande explicitement
  pour ce cas : exposer une surface, laisser l'hôte la remplir.

Ce que je consomme réellement, **en lecture seule et sans copie** : `ParticipantSalle` et
`QualiteLien` (`lib/core/video/video_session_provider.dart`), `AppRole` (`lib/core/domain/enums.dart`),
`sessionProvider` (`lib/core/session/session_controleur.dart`).

Si Agent 0 juge le stub obligatoire malgré tout, il coûte dix minutes et ne change aucune ligne de mon
code : je n'ai pas de point d'appel.

---

## 6. Ce que j'ai réutilisé plutôt que recréé

La règle demande de citer les composants partagés réutilisés. `lib/core/widgets/` a été listé avant
d'écrire une ligne d'interface.

| Réutilisé | Où | Pourquoi lui |
|---|---|---|
| `ChoiceCardGroup` (`autoriserSaisieLibre: false`) | choix de mode Admin **et** les trois choix de politique | seul point d'entrée d'un choix proposé à l'utilisateur (ADR-013) ; la saisie libre est fermée, ce sont des listes administratives closes |
| `ActionPrincipale` | entrer, quitter, enregistrer, les deux pas de quota | seul point d'entrée des actions ; la CI refuse tout bouton Material |
| `StatusPill` | compte à rebours, temps restant de l'annonce | un mot **et** une pastille, jamais la couleur seule (invariant J7) |
| `EmptyState` (`RegistreVide.subi`) | tous les refus, toutes les fins, le support absent | « l'utilisateur ne peut rien faire » est exactement le registre d'un refus de quota |
| `AppCard` | les deux vignettes du panneau tuteur | surface d'écran ; la CI refuse un `Container` décoré sous `features/` |
| `AvatarTile` | vignettes enseignant et enfant | repli par initiales déjà traité |
| `SettingRow` | les deux quotas du module | ligne de réglage avec emplacement de contrôle natif |
| `SectionHeader`, `PageShell`, `Skeleton`, `Ecart`/`AppSpacing`, `AppPalette`, `AppIcons` | partout | coquille, rythme, jetons |

**Aucun composant neuf n'a été ajouté à `lib/core/widgets/`** : le répertoire m'est interdit, et
`catalogue_galerie_test` est rouge à la baseline de toute façon. Mes deux widgets privés (`_Vignette`,
`_Pas`) vivent dans mes propres fichiers.

**Non refaits, consommés ou laissés intacts** : `lib/features/controleur/` (CTR-01, que j'ai lu et
dont j'ai repris `graceApresFin` comme référence de fenêtre), `lib/core/journal/` et
`lib/features/admin_journal/` (le journal d'audit reste **le** journal), `lib/core/agent/`
(`jetons_agent` sert aux agents IA : j'en ai copié les **règles**, pas la table),
`lib/core/admin/admin_domaine.dart` (gelé à huit domaines), `lib/core/presence/`,
`lib/core/video/` (lecture seule).

---

## 7. Défauts préexistants rencontrés — signalés, non corrigés

1. **`dart run tool/verifier_jetons.dart` est ROUGE à la baseline `0071557`** : 10 violations, aucune
   dans un fichier que je possède. Pour mémoire, afin que personne ne me les attribue :
   `lib/core/widgets/menu_filtre.dart` (2 m-dash) · `lib/core/widgets/nav_shell.dart` (3 m-dash,
   1 `IconButton`, 1 `onTap` nu) · `lib/core/widgets/sous_navigation_domaine.dart` (1 `onTap` nu) ·
   `lib/features/admin_dossiers/dossiers_page.dart` (1 m-dash) ·
   `lib/features/admin_journal/journal_page.dart` (1 m-dash).
   **Mes 19 fichiers de `lib/` n'en produisent aucune.**
2. **`assister_seance()` (migration `0012`) ne journalise rien et ne consulte aucun quota.** Ce n'est
   pas un bug que j'introduis : c'est exactement le trou que ce lot est fait pour fermer. Tant que la
   migration n'est pas appliquée, **le tuteur entre aujourd'hui sans budget et sans trace** via
   `accueil_famille_page.dart`.
3. **`supabase/migrations/0029` est écrite mais non appliquée** (signalé par le `BASELINE_ADDENDUM`) :
   `dossiers_en_attente()` livre nom et prénom de toute personne en attente de KYC à un appelant
   anonyme. Hors mission, non touché.
4. **`windows/flutter/generated_plugin_registrant.*`** ont été réécrits par `flutter pub get` /
   `flutter test` — **uniquement des fins de ligne LF vers CRLF**, aucun changement de contenu. Je les
   ai restaurés (`git checkout --`) et le commit ne les porte pas. Ils réapparaîtront chez quiconque
   lance `flutter` sous Windows dans ce worktree.

---

## 8. Ce qu'Agent Z devra brancher

Par ordre de blocage décroissant.

1. **La migration.** Sans elle rien n'observe : §1 du `TC_CONTRACT_REQUEST_G.md`, six fonctions, une
   table, cinq colonnes, deux valeurs d'enum, cinq clés `app_config`, et **six endroits** à ne pas
   oublier quand l'enum grandit.
2. **`autoriser_jeton_video()`** : contrôle de quota avant le jeton, et TTL borné par le budget
   restant. C'est la borne réelle.
3. **`redirection.dart`** : autoriser `/tc/observation/...` pour `guardian`, `admin`, `controller`.
   Sans cela la route existe et personne ne l'atteint.
4. **`app_router.dart`** : appeler `routesTcG()`, promouvoir les constantes dans `routes.dart`.
5. **Les deux entrées existantes** : `accueil_famille_page.dart` `_assister()` et le bouton
   « Observer » de `planning_page.dart` doivent naviguer vers la route plutôt qu'appeler
   `ServiceVideo` en direct. **L'entrée Admin est un arbitrage produit**, pas un patch.
6. **Le module de réglages** dans « Groupe > Réglages », avec la lecture de
   `politiqueObservationProvider(groupeId)` et l'écriture par
   `definir_politique_observation_groupe()`. Ne pas le lister dans `ongletsConfiguration()` avant
   qu'il ait une route réelle.
7. **Le panneau tuteur dans la Classe Live d'Agent E** : lui passer la liste de participants et le
   widget de support partagé. `PanneauObservationTuteur` est déjà écrit pour les recevoir.
8. **`IndicateurObservation`** dans le shell enseignant d'Agent E, alimenté par
   `annoncesObservationProvider(sessionId)` ; **`IndicateurObservationEnfant`** dans la surface élève,
   piloté par `enfantConcerneParObservation()`.
9. **L'i18n** : fusionner `tc_i18n_G.json`, régénérer slang, remplacer les constantes de
   `libelles_tc_g.dart` par leurs `t.tc.observation...`, supprimer la façade. Chaque constante porte
   sa clé en commentaire `// TC-I18N:`.
10. **Les cinq icônes** et, s'il le souhaite, l'amendement `ModeEntreeAdmin` au contrat (§2.1 du
    CONTRACT_REQUEST).

---

## 9. Commandes rejouables

```powershell
cd D:\RA_TC\g
flutter analyze lib test                 # No issues found!
flutter test test/teaching_core/g        # All tests passed! (75)
git status --porcelain                   # 4 chemins, tous sous docs/teaching-core, lib/core/tc_observation,
                                         # lib/features/tc_observation_ui, test/teaching_core
dart run tool/verifier_jetons.dart       # 10 violations PRÉEXISTANTES, aucune dans mes fichiers (voir §7.1)
```
