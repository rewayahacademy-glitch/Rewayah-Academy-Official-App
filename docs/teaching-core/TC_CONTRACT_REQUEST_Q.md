# TC_CONTRACT_REQUEST_Q.md — demandes d'Agent Q

> Agent Q · QA · baseline `0071557`.
> Agent Q n'écrit aucune ligne de production : ses demandes portent sur ce qui **manque pour prouver**
> un invariant, pas sur ce qui manque pour coder un écran.

---

## 1. TYPE DEMANDÉ — l'état de la photo enseignant

**Pour qui :** Agent A (producteur de `EnseignantVM`).

La décision D-01 interdit l'avatar générique silencieux : l'absence de photo doit déclencher « un état
d'erreur ou de migration **explicite** ». Mais `TEACHING_CORE_CONTRACTS.md` §1 n'expose que
`photoUrlOuCle` nullable. Un `null` n'est pas un état : chaque écran décidera seul quoi en faire, et un
seul qui affichera un avatar par défaut suffira à rendre la décision inopérante.

Agent Q a dû déclarer le type dans ses fixtures pour pouvoir le tester
(`test/teaching_core/fixtures/fixtures_groupes.dart`) :

```dart
/// Chemin canonique souhaité : lib/core/tc_groupe/group_summary_vm.dart
enum EtatPhotoEnseignant { presente, manquante }

EtatPhotoEnseignant etatPhoto(EnseignantVM enseignant);
```

**Deux valeurs, jamais trois.** L'absence de `generique` / `placeholder` dans l'énumération est ce qui
rend la décision D-01 applicable par construction. Le test `q10 › il n'existe que deux états` le vérifie.

---

## 2. TYPE DEMANDÉ — les capacités d'un observateur

**Pour qui :** Agent G (producteur des contrats d'observation), Agent Z (confrontation au SQL).

Les décisions D-14, D-15 et D-16 fixent, pour chaque rôle d'observateur, micro / caméra / publication
data / visibilité / annonce / audit. Aucun type de contrat ne les porte : `CapacitesSalle` existe côté
vidéo mais ne connaît ni l'annonce ni l'audit, et `CapacitesPedagogiques` (CONTRACTS §9) ne couvre pas
la visibilité.

Agent Q a dû déclarer la table dans ses fixtures
(`test/teaching_core/fixtures/fixtures_observation.dart`) :

```dart
/// Chemin canonique souhaité : lib/core/tc_observation/capacites_observateur.dart
class CapacitesObservateur {
  const CapacitesObservateur({
    required bool micro,
    required bool camera,
    required bool publicationData,
    required bool visibleDesParticipants,
    required bool annonceFaite,
    required bool auditee,
  });
}

CapacitesObservateur capacitesDe(RoleObservateur role);
```

**Ce n'est pas une barrière et ne doit jamais le devenir.** La vérité reste le jeton signé par
`autoriser_jeton_video`. Le type sert à écrire la table **une fois** et à la confronter au SQL, au lieu
de la voir réécrite dans chaque écran.

---

## 3. MÉTHODE DEMANDÉE — la durée académique bornée

**Pour qui :** Agent A, en complément de `TC_CONTRACT_REQUEST_A.md`.

La décision D-13 nomme le défaut : `VuePresence.depuis` calcule la durée depuis `entre_le` brut, sans
la borner à `max(entreLe, debutSeance)`. Tant que la fenêtre vaut T-10, l'écart passe inaperçu ; à
T-20, un élève entré à l'ouverture verra « en salle depuis 38 min » pour un cours commencé il y a 18.

Agent Q a écrit la fonction corrigée dans ses fixtures
(`test/teaching_core/fixtures/fixtures_horloge.dart`) et l'a testée :

```dart
/// Chemin canonique souhaité : lib/core/tc_horloge/duree_academique.dart
Duration dureeAcademique({
  required DateTime? entreLe,
  required DateTime debutSeance,
  required DateTime maintenant,
  DateTime? finSeance,
});
// entreLe == null            -> Duration.zero
// depart = max(entreLe, debutSeance)
// arrivee = min(maintenant, finSeance ?? maintenant)
// arrivee <= depart          -> Duration.zero, jamais une duree negative
```

`test/teaching_core/q/q02_entree_precoce_presence_test.dart` en contient la suite complète : elle est
prête à être déplacée telle quelle le jour où la fonction entre en production.

⚠ **Ne pas éditer `lib/core/presence/vue_presence.dart` en phase parallèle.** Le fichier est consommé
par quatre écrans existants et la décision D-13 l'interdit explicitement.

---

## 4. DEMANDE SQL

Agent Q ne demande **aucune table pour lui-même**. Les quatre points ci-dessous sont des demandes de
**vérifiabilité** : sans elles, un invariant du chantier reste invérifiable autrement que par lecture
de code.

### 4.1 Une fonction de test SQL pour la projection enseignant

| | |
|---|---|
| **Objet** | `supabase/tests/scenarios_tc_pii.sql` (fichier de test, **pas** une migration) |
| **Étend** | `supabase/tests/scenarios_n4.sql`, déjà en place pour la présence |
| **Rôle appelant** | un `teacher` authentifié, puis un `student`, puis un `anon` |
| **Ce qu'il doit prouver** | Qu'un `select *` sur toute vue lisible par l'enseignant ne rend **aucune** colonne de `profiles.last_name`, `households`, `wallets`, `payouts` — et qu'aucune jointure ne les reconstitue. |
| **Pourquoi** | Q-01 garde la seconde ligne de défense. La première est en base, et rien ne la teste aujourd'hui. |

### 4.2 Le quota d'observation, vérifié AVANT le token

| | |
|---|---|
| **Objet** | extension de `public.assister_seance(uuid)` et de `public.autoriser_jeton_video(...)` |
| **Étend** | `0012_observation_controleur.sql` — **jamais une troisième porte**, l'en-tête de 0012 l'interdit |
| **Attendu** | Le contrôle de `policy`, de `visit_number` et de `duration_seconds` cumulée se fait **avant** l'émission du jeton, et le refus porte un `MotifRefusObservation` lisible. |
| **Sécurité** | (1) Jamais `grant execute` à `agent_ro` sur ces fonctions volatiles — `get_advisors` ne le détecte pas. (2) Toute nouvelle vue d'exposition répète le filtre d'appelant et le masquage `agent_identite_masquee()` **colonne par colonne**. |
| **Piège nommé** | ⚠ Si un rôle d'observation Admin est ajouté à `participant_role`, il faut l'ajouter aux **deux** listes d'exemption de 0012 (`guard_session_participant_cap`, `guard_session_overlap`), sinon l'Admin sera refusé par un déclencheur écrit pour tout autre chose. |

### 4.3 La fermeture d'intervalle écrite par le serveur

| | |
|---|---|
| **Objet** | `guardian_session_visit` (demandée par Agent G) |
| **Attendu** | `left_at`, `duration_seconds` et `fin_de_visite` sont écrits **côté serveur**, pas par le client. |
| **Pourquoi c'est une demande d'Agent Q** | `ServiceVideo.annoncerSortie()` **avale volontairement l'échec**. Acceptable pour une trace, **inacceptable** si c'est ce geste qui ferme un quota. Le test `q12 › une annonce qui échoue n'empêche pas de sortir` documente ce comportement ; `q03` ferme donc l'intervalle côté serveur. Les deux doivent rester cohérents après l'intégration. |

### 4.4 `verset.ligne`, ou un jeu d'assets de layout

| | |
|---|---|
| **Objet** | peupler `public.verset.ligne` (NULL sur les 6236 lignes), **ou** embarquer un fichier de coordonnées |
| **Pourquoi Q le signale** | `q08 › la fidélité Mushaf n'est pas disponible` vérifie aujourd'hui qu'on répond `indisponible`. Le jour où l'une des deux sources arrive, ce test devra basculer sur `degrade` puis `fidele`. La demande appartient à Agent C (D-23) ; Agent Q la relaie pour que le golden suive. |
| **Point juridique à ne pas perdre** | `assets/fonts/` porte une licence pour Bricolage, InstrumentSans et Phosphor, **mais aucune pour UthmanTahaNaskh ni NotoSansArabic**. Un jeu QCF redistribué sans notice serait un risque de plus, pas de moins. |

---

## 5. DÉPENDANCE DEMANDÉE

**Aucune.**

Ce qui a été essayé avec l'existant, et a suffi :

- `dart:io` pour lire les sources — même mécanisme que `tool/verifier_jetons.dart`, qui lit `lib/`
  depuis la CI. Pas de `dart:mirrors` (absent côté Flutter), pas de génération de code.
- `flutter_test` + `go_router` pour l'hôte de navigation. Le `GoRouter` de test vit sous `test/`, donc
  hors de la règle CI qui refuse un second routeur dans `lib/` (D-04).
- Les compteurs des doubles remplacent un framework de mock. `mockito` / `mocktail` auraient ajouté une
  dépendance et une génération pour une valeur nulle : le dépôt écrit ses faux à la main (25 faux dans
  `test/support/harnais.dart`), et Agent Q suit la convention.

---

## 6. ICÔNES DEMANDÉES

**Aucune.** Agent Q ne produit aucune interface.

---

## 7. ÉCART D'OWNERSHIP À ARBITRER

`TEACHING_CORE_FILE_OWNERSHIP.md` §2 attribue à Agent Q le sous-arbre i18n « **aucun** », et la §5.1 ne
liste pas `docs/teaching-core/i18n/tc_i18n_Q.json` parmi ses fichiers possédés. La mission reçue par
Agent Q, elle, le nomme explicitement parmi ses livrables documentaires.

**Résolution retenue :** le fichier est écrit, vide de libellés et porteur d'une note qui explique
pourquoi. Il n'entre en collision avec aucun autre agent — la preuve de disjonction §5.1 ne l'attribue à
personne. L'écart est déclaré ici et dans `TC_AGENT_Q_REPORT.md` plutôt que résolu en silence.

Agent Z tranche : soit le fichier reste (inoffensif), soit il est supprimé à l'intégration.
