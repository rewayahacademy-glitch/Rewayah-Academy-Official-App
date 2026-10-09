<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## Verdict : SUPERPOS-1b est acceptée avec réserves

J'ai relu la branche `corrections/c2-superpos-b` au commit `dcc3cb0b`, par rapport à `origin/corrections/revue-directeur-2026-10` (tête `5a52ff30`). J'ai travaillé dans un worktree détaché et jetable, sans rien pousser. Les worktrees de relecture (branche et base) sont retirés.

Les quatre points demandés sont remplis, et chacun est prouvé par une mutation qui fait échouer les tests. Il ne reste **aucun défaut majeur prouvé**, seulement 5 réserves mineures.

Statut : présent dans le code et testé localement. Ni testé sur staging, ni déployé.

### 1. Contrôles du dépôt
- **`dart run slang`** : l'arbre reste propre.
- **`dart analyze --fatal-infos`** : aucun problème.
- **`verifier_revue`** : 1532 violations, contre 1533 sur la base. La fiche annonce « 1533 → 1533 », ce qui est faux mais va dans le bon sens.
- **`verifier_jetons`** : 37 violations, égal à la base.
- **Suite de tests** (`--concurrency=2`, sur `test/features`, `test/core`, `test/router`, `test/widgets`) : **+4389 réussis, ~2173 ignorés, 0 échec**.
- **Interdits** : aucun fichier touché dans `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, le thème, `page_shell.dart`, `nav_shell.dart`, `rangee_filtres.dart`, le rendu du Coran ou `dart_define`.
- **`fr.i18n.json`** : un seul ajout, la clé `demandeValeurRequise`. Aucune ponctuation existante n'est modifiée. Le libellé est déclaré dans `tool/libelles_sources.json` avec la mention « décidé par délégation le 09/10 ».
- **Commits** : les 5 commits sont en français et se terminent par les deux lignes exigées.

### 2. Mutations (j'annule la correction, puis je relance les tests)

| # | Mutation | Résultat |
|---|---|---|
| M1 | `minimumListe` renvoie 96 | 3 échecs sur 3 |
| M1b | Le minimum ne suit plus l'échelle du texte | 2 échecs sur 3 |
| M1c | `minimumEtire: 0` passé à la page | 1 échec (la liste à 320 x2 avec clavier) |
| M2a | Repère « Démonstration » peint en `surfacePrimary` | 12 échecs sur 12 |
| M2b | Bandeau d'observation peint en `surfaceWarning` | 4 échecs |
| M2c | Bulle de l'autre interlocuteur peinte en `surfacePrimary` | 4 échecs (les tests du fil) |
| M3a | Bouton des réglages remis à l'état grisé (`_pret ? … : null`) | 2 échecs |
| M3b | Retour du focus au champ retiré | 1 échec |
| M3c | Erreur du motif jamais affichée | 1 échec |
| M3d | Phrase « durée manquante » jamais affichée | 1 échec |
| M3e | Envoi possible sans durée choisie | 1 échec |
| M4 | `_erreurEntiere` renvoie le texte brut (saisie du code) | 2 échecs sur 2 (fr et ar) |

### 3. Captures ouvertes
- **Réglages, appui sans motif, 320 x2 clair** : le bouton est plein et actif. Le champ a un filet d'alerte et l'erreur « Un motif est nécessaire… » s'affiche en entier.
- **Réglages, avant l'appui** : la phrase s'affiche en registre calme.
- **Réglages, appui sans durée** : la phrase « Choisissez une durée, ou écrivez-en une autre en minutes. » s'affiche en encre d'alerte, sans mot coupé.
- **Réglages en Interface guidée, sombre, RTL** : la page défile et le bouton s'atteint. Le « ? » reste orphelin (réserve 3, voie COUPE-MOTS-4, hors lot).
- **Saisie du code, refus « appareil retiré »** :
  - avant : « Demandez- / lui », coupé au trait d'union ;
  - après : « Demandez-lui » entier, sans aucune troncature.
- **Captures absentes** : rien à 1440 pour les réglages, rien en Interface guidée pour la saisie du code.

### 4. Lecture du code et effets sur les autres usages
- **Hauteur minimale de la liste du fil** : le test mesure une vraie bulle de deux lignes rendue, à l'échelle de texte x1 et x2. Il vérifie aussi qu'à 320 x2, clavier ouvert, la liste montre cette bulle en entier. Il est solide.
- **Bouton des réglages** :
  - le bouton n'est plus jamais inerte. `_valider` n'envoie que si tout est rempli ; sinon il passe `_tente` à vrai et ramène le focus au champ si le motif manque ;
  - le double envoi reste impossible, car `ActionPrincipale` ignore les appuis pendant `enCours` ;
  - c'est le même motif que les autres formulaires (`ZoneSaisie.explication` puis `erreur`).
- **Saisie du code** :
  - le caractère invisible U+2060 n'est ajouté que si la ligne se couperait vraiment à la largeur réelle de l'erreur, grâce à `sansCoupureAuTrait`, qui existait déjà ;
  - `LayoutBuilder` n'enveloppe que le champ ;
  - les autres tests de la page (dont `scanner_saisie_test`) passent tous dans la suite.
- **Aides des champs** : l'invitation du conjoint et le profil élève sont bornés à `ZoneSaisie.lignesAideMax` (8 lignes) depuis SUPERPOS-1. Le test existant les protège, et la relecture R2 l'avait prouvé par mutation (M8). La saisie du code a maintenant sa propre mesure, avec l'aide et les 9 refus testés sur le vrai routeur.

### 5. Réserves, toutes mineures
1. **Lecteur d'écran** : un appui sans durée affiche une phrase qui n'est ni annoncée ni accompagnée d'un déplacement du focus. Avec un lecteur d'écran, l'appui ne produit aucun retour. La fiche affirme une annonce qui n'existe que pour le motif.
2. **Bouton grisé hors lot** : sur la saisie du code, « Connecter l'appareil » reste inerte, et un test existant exige ce comportement. Le rédacteur l'a relevé ; c'est à relayer et à corriger avant la production.
3. **Test du point d'attention** : il porte sur des compositions de vrais composants, pas sur les pages réelles auditées.
4. **Captures** : il manque 1440 pour les réglages et l'Interface guidée pour la saisie du code.
5. **Chiffre de `verifier_revue`** : la fiche dit 1533 → 1533, la mesure donne 1533 → 1532.

**Décision : ACCEPTEE_AVEC_RESERVES**, décidé par délégation le 09/10. Le lot peut être fusionné quand la CI et les contrôles du dépôt le permettront. Toute fusion dans `main` est une mise en production.
