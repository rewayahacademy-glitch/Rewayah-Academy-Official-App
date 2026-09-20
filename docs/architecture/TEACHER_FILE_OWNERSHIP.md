# TEACHER_FILE_OWNERSHIP

Matrice de propriété des fichiers pendant la phase parallèle du rôle Enseignant.

Produit par l'**Agent 0** le 19 septembre 2026. Base : `BASELINE_SHA = 550e605`.

> **La règle est immuable : chaque fichier modifiable a UN SEUL propriétaire.**
> Un agent qui a besoin d'écrire ailleurs ne le fait pas : il écrit
> `docs/parallel-reports/CONTRACT_REQUEST_<AGENT>.md` et s'arrête sur ce point.

---

## 1. Périmètres

### Agent A - Journée

Écrans : `ENS-02` Journée, `ENS-07` Fiche groupe.

| Chemin | Nature |
| :--- | :--- |
| `lib/features/journee/**` | existant (`journee_page.dart`), à étendre |
| `lib/features/fiche_groupe/**` | **nouveau** |
| `test/features/journee_test.dart` | existant, à étendre |
| `test/features/fiche_groupe_test.dart` | **nouveau** |
| `docs/parallel-reports/i18n_A.json` | **nouveau**, file de clés |
| `docs/parallel-reports/AGENT_A_REPORT.md` | **nouveau** |
| `docs/parallel-reports/CONTRACT_REQUEST_A.md` | si nécessaire |

### Agent B - Salle de cours

Écran : `ENS-03` Salle, enseignant.

| Chemin | Nature |
| :--- | :--- |
| `lib/features/salle_enseignant/**` | **nouveau** |
| `test/features/salle_enseignant_test.dart` | **nouveau** |
| `docs/parallel-reports/i18n_B.json` | **nouveau** |
| `docs/parallel-reports/AGENT_B_REPORT.md` | **nouveau** |

> **Amendement du 19 septembre 2026, après audit.** `test/features/salle_test.dart`
> passe à l'**Agent Z** et non à B. L'audit a établi que ses 744 lignes mesurent
> les **quatre** rôles de la salle : une modification faite pour faire passer le
> code de l'enseignant casserait la garantie de l'élève et du contrôleur. Son
> échec antérieur (« il lit deux personnes, et ne s'y trouve pas ») est traité par
> le socle salle, qui possède déjà `salle_page.dart` et `vue_salle.dart`.

> `lib/features/salle/salle_page.dart` et `vue_salle.dart` ne sont **pas** à
> l'agent B : ce sont les fichiers de l'élève et du contrôleur autant que ceux
> de l'enseignant. Réservés à l'Agent Z, qui y insère le panneau de B en un
> seul point.

### Agent C - Pédagogie et après-cours

Écrans : `ENS-04` Cahier de transmission, `ENS-08` Revue de groupe.

| Chemin | Nature |
| :--- | :--- |
| `lib/features/cahier/**` | **nouveau** |
| `lib/features/revue_groupe/**` | **nouveau** |
| `test/features/cahier_test.dart` | **nouveau** |
| `test/features/revue_groupe_test.dart` | **nouveau** |
| `docs/parallel-reports/i18n_C.json` | **nouveau** |
| `docs/parallel-reports/AGENT_C_REPORT.md` | **nouveau** |

### Agent D - Créneaux et matching

Écran : `ENS-06` Disponibilités et matching.

| Chemin | Nature |
| :--- | :--- |
| `lib/features/creneaux/**` | existant (`creneaux_page.dart`), à étendre |
| `test/features/creneaux_test.dart` | existant, à étendre |
| `docs/parallel-reports/i18n_D.json` | **nouveau** |
| `docs/parallel-reports/AGENT_D_REPORT.md` | **nouveau** |

> `lib/features/disponibilites/**` n'est **pas** à l'agent D : c'est l'écran du
> tuteur (`TUT-04`, route `/tuteur/disponibilites`). `grille_semaine.dart` y est
> déclaré composant partagé en **lecture seule** : l'agent D l'importe, il ne le
> modifie ni ne le déplace.

### Agent E - Onboarding et profil

Écrans : `ENS-01` Onboarding et bienvenue, `ENS-05` Profil enseignant.

| Chemin | Nature |
| :--- | :--- |
| `lib/features/profil_enseignant/**` | existant (talon), à construire |
| `lib/features/bienvenue_enseignant/**` | **nouveau** |
| `lib/features/dossier/**` | existant, **partagé avec le tuteur** (voir avertissement) |
| `lib/features/inscription/**` | existant, **partagé avec le tuteur** (voir avertissement) |
| `test/features/profil_enseignant_test.dart` | existant (0,6 ko), à construire |
| `test/features/bienvenue_enseignant_test.dart` | **nouveau** |
| `test/features/dossier_test.dart` | existant, **à remettre au vert** |
| `test/features/inscription_test.dart` | existant, **à remettre au vert** |
| `docs/parallel-reports/i18n_E.json` | **nouveau** |
| `docs/parallel-reports/AGENT_E_REPORT.md` | **nouveau** |

> **Avertissement sur `dossier/` et `inscription/`.** Ces surfaces portent
> `TUT-00b`, `TUT-00c` et `TUT-00c/a,b,c`, que le **tuteur** traverse aussi.
> L'agent E en a la propriété parce qu'aucun autre agent n'y touche et parce que
> le `PROMPT E` lui confie le tunnel d'entrée de l'enseignant. Contrainte
> absolue : **aucun changement ne doit altérer le comportement du tuteur.** Seul
> le défaut de mise en page mobile est corrigé (les 5 tests rouges de
> `TEACHER_PARALLEL_BASELINE.md` §7). Rien n'est renommé, rien n'est
> restructuré, aucune étape n'est ajoutée au parcours commun.

### Agent Z - Intégrateur

Seul autorisé à écrire ici, et il y écrit **avant** le lancement des agents
(socle partagé) puis **après** leur travail (branchement).

| Chemin | Rôle |
| :--- | :--- |
| `lib/core/**` | tout le noyau, dont le nouveau `lib/core/enseignant/**` |
| `lib/core/router/routes.dart`, `app_router.dart`, `redirection.dart` | routage |
| `lib/core/widgets/nav_shell.dart` | destinations de niveau 1 |
| `lib/core/domain/enums.dart` | miroirs des énumérés SQL |
| `lib/core/cache/db/app_database.dart` | base locale drift |
| `lib/features/salle/salle_page.dart`, `vue_salle.dart` | salle partagée par 4 rôles |
| `assets/i18n/fr.i18n.json`, `ar.i18n.json` | source des chaînes |
| `lib/core/i18n/strings*.g.dart` | généré par `dart run slang` |
| `supabase/migrations/**` | schéma |
| `test/support/harnais.dart` | harnais de test partagé |
| `docs/**` hors `docs/parallel-reports/` | documentation |

---

## 2. Lecture seule pour tous les agents A-E

Ces fichiers se **consomment**, jamais ne se modifient. Un besoin non couvert
devient un `CONTRACT_REQUEST`.

```
lib/core/**                     tout le noyau, sans exception
lib/core/widgets/**             les 38 composants partagés (cf. DUPLICATES §1)
lib/core/theme/**               tokens, palette, gabarit, métriques
lib/core/i18n/strings.g.dart    généré
lib/features/salle/**           salle partagée
lib/features/disponibilites/**  écran du tuteur, grille réutilisable
lib/features/compte/**          espace commun à tous les rôles
lib/features/coran/**           lecteur partagé élève et enseignant
lib/features/_dev/**            galerie de développement
supabase/**                     schéma
test/support/harnais.dart       harnais partagé
assets/i18n/**                  chaînes
pubspec.yaml, analysis_options.yaml, build.yaml, slang.yaml
```

**Aucune dépendance nouvelle.** `pubspec.yaml` est fermé pour ce lot : tout ce
qui est nécessaire est déjà là (Riverpod 3, go_router, supabase_flutter, drift,
slang, livekit_client, uuid, adhan, qr_flutter, file_picker).

---

## 3. API publique que chaque agent doit exposer

C'est le **contrat de branchement**. L'Agent Z écrit le routeur en s'appuyant
sur ces noms exacts, avant que les agents n'aient produit une ligne. Un nom qui
diffère casse l'analyse de tout le lot.

| Agent | Fichier exact | Déclaration exacte |
| :--- | :--- | :--- |
| A | `lib/features/journee/journee_page.dart` | `class JourneePage extends ConsumerWidget` / `const JourneePage({super.key})` |
| A | `lib/features/fiche_groupe/fiche_groupe_page.dart` | `class FicheGroupePage extends ConsumerWidget` / `const FicheGroupePage({required this.groupeId, super.key})`, champ `final String groupeId;` |
| B | `lib/features/salle_enseignant/panneau_enseignant.dart` | `class PanneauEnseignantSalle extends ConsumerWidget` / `const PanneauEnseignantSalle({required this.seanceId, super.key})`, champ `final String seanceId;` |
| C | `lib/features/cahier/cahier_page.dart` | `class CahierPage extends ConsumerWidget` / `const CahierPage({required this.seanceId, super.key})`, champ `final String seanceId;` |
| C | `lib/features/revue_groupe/revue_groupe_page.dart` | `class RevueGroupePage extends ConsumerWidget` / `const RevueGroupePage({required this.groupeId, super.key})`, champ `final String groupeId;` |
| D | `lib/features/creneaux/creneaux_page.dart` | `class CreneauxPage extends StatelessWidget` / `const CreneauxPage({super.key})` (inchangé) |
| E | `lib/features/profil_enseignant/profil_enseignant_page.dart` | `class ProfilEnseignantPage extends ConsumerWidget` / `const ProfilEnseignantPage({super.key})` |
| E | `lib/features/bienvenue_enseignant/bienvenue_page.dart` | `class BienvenueEnseignantPage extends ConsumerWidget` / `const BienvenueEnseignantPage({super.key})` |

Règles qui vont avec :

- le constructeur est **`const`** et le paramètre est **positionnel nommé
  requis** ; `prefer_const_constructors` est actif et la CI lance
  `dart analyze --fatal-infos` ;
- chaque membre public porte un commentaire `///` ;
- aucun agent n'exporte autre chose de son dossier vers l'extérieur. Tout le
  reste de sa feature est privé (`_Prefixe`) ou interne à son dossier.

---

## 4. Les chaînes de texte : une file par agent

`assets/i18n/fr.i18n.json` est **fermé** aux agents (cf. `BASELINE_SHA` §2.3).

Chaque agent écrit `docs/parallel-reports/i18n_<AGENT>.json`, un objet JSON qui
sera fusionné **tel quel** à la racine de `fr.i18n.json`. Exemple pour l'agent C :

```json
{
  "enseignant": {
    "cahier": {
      "titre": "Cahier de transmission",
      "continuer": "Continuer",
      "exception": "Signaler une exception",
      "duree": "{minutes} min",
      "envoyeHorsLigne": "Enregistré. Sera envoyé dès le retour du réseau."
    }
  }
}
```

Consommation dans le code, sans exception :

```dart
Text(t.enseignant.cahier.titre)
Text(t.enseignant.cahier.duree(minutes: '$minutes'))
```

- convention de clé : `role.ecran.element`, donc **toujours** sous
  `enseignant.<ecran>` pour ce lot (`slang.yaml` l'impose depuis l'étape 2) ;
- interpolation en accolades, `{minutes}`, jamais `$minutes` ;
- **français seulement.** L'arabe est un talon volontaire et `fallback_strategy:
  base_locale` renvoie le français ;
- une clé utilisée dans le code et absente de la file casse l'analyse du lot
  entier. Déclarer d'abord, employer ensuite.

---

## 5. Contrôle de non-chevauchement

Vérification exhaustive : aucun chemin n'apparaît sous deux propriétaires.

| Chemin | Propriétaire unique |
| :--- | :--- |
| `lib/features/journee/**` | A |
| `lib/features/fiche_groupe/**` | A |
| `lib/features/salle_enseignant/**` | B |
| `lib/features/cahier/**` | C |
| `lib/features/revue_groupe/**` | C |
| `lib/features/creneaux/**` | D |
| `lib/features/profil_enseignant/**` | E |
| `lib/features/bienvenue_enseignant/**` | E |
| `lib/features/dossier/**` | E |
| `lib/features/inscription/**` | E |
| `lib/features/salle/**` | Z |
| `lib/features/disponibilites/**` | Z (lecture seule pour A-E) |
| `lib/features/compte/**` | Z (lecture seule pour A-E) |
| `lib/features/coran/**` | Z (lecture seule pour A-E) |
| `lib/core/**` | Z |
| `assets/i18n/**` | Z |
| `supabase/**` | Z |
| `test/features/journee_test.dart` | A |
| `test/features/fiche_groupe_test.dart` | A |
| `test/features/salle_test.dart` | Z (amendement §1) |
| `test/features/salle_enseignant_test.dart` | B |
| `lib/features/presence_correction/**` | Z (lecture seule ; **l'agent C l'importe et le branche**) |
| `test/features/cahier_test.dart` | C |
| `test/features/revue_groupe_test.dart` | C |
| `test/features/creneaux_test.dart` | D |
| `test/features/profil_enseignant_test.dart` | E |
| `test/features/bienvenue_enseignant_test.dart` | E |
| `test/features/dossier_test.dart` | E |
| `test/features/inscription_test.dart` | E |
| `test/support/harnais.dart` | Z |
| `docs/parallel-reports/*_A.*`, `AGENT_A_REPORT.md` | A |
| `docs/parallel-reports/*_B.*`, `AGENT_B_REPORT.md` | B |
| `docs/parallel-reports/*_C.*`, `AGENT_C_REPORT.md` | C |
| `docs/parallel-reports/*_D.*`, `AGENT_D_REPORT.md` | D |
| `docs/parallel-reports/*_E.*`, `AGENT_E_REPORT.md` | E |
| `docs/**` (reste) | Z |

**Verdict : ownership sans chevauchement.** La condition STOP du `PROMPT 0` est
remplie.

---

## 6. Ce qu'un agent n'a jamais le droit de faire

1. écrire dans un fichier dont il n'est pas propriétaire, **même d'une ligne**,
   **même pour se débloquer** ;
2. ajouter une dépendance à `pubspec.yaml` ;
3. créer un second `GoRouter`, un second provider vidéo, un second service de
   disponibilité, de matching ou de rapport ;
4. dupliquer un composant de `lib/core/widgets/` (l'index est dans
   `TEACHER_DUPLICATES_AUDIT.md` §1) ;
5. créer un état global pour contourner un contrat manquant ;
6. ajouter une table à `AppDatabase` (quatre tables, ni plus ni moins) ;
7. écrire une migration SQL ;
8. lancer `flutter analyze`, `flutter test`, `dart run slang` ou
   `dart run build_runner` : plusieurs agents travaillent en parallèle et ces
   commandes se disputent `.dart_tool`. **La vérification est centralisée chez
   l'Agent Z** ;
9. modifier `assets/i18n/*.json` ;
10. afficher un nom de famille, un courriel ou un téléphone de famille.
