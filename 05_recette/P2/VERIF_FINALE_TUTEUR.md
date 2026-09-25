# Vérification finale — rôle Tuteur V1, avant passage à un autre rôle

Poste B, lecture seule (dépôt `C:\RA\depot` @ `a855b23`, non modifié). Pilotage à jour
(`git pull --rebase` sans changement). 25/09/2026.

Méthode : tableau `etapes` (ArtifactData, 120 lignes, lecture seule) ; relecture
`05_recette/P2/P2-08.md` à `P2-11.md` et `RAPPORT_DIRECTEUR.md` ; script
`06_registre/outils/graphe_imports.ps1` relancé sur `C:\RA\depot -Ref a855b23`
(lecture seule, sorties dans le scratchpad de l'agent, pas dans le dépôt) ; lecture de
`lib/core/router/app_router.dart` ; `rg` sur `lib/features` ; `TRI.md` du lot T ; `gh`
absent du poste (non installé) → CI PR #3 **non vérifiable** depuis ce poste.

## 1. Oublis réels (ni couverts par la base « fait », ni par le lot T)

1. **LC-F, reste "m4"** — icône info absente devant « Comment ça marche ? » et sablier
   au lieu d'une horloge (C-13/C-5). Mineur visuel, arbitrage non tranché.
   Preuve : `05_recette/c/REVUE.md:49,89` ; ligne tableau `LC-F` (note : « Reste : m4
   (icône sablier) non traité »). Fichier concerné probable :
   `lib/core/icons/app_icons.dart:388,639` (sablier `attente`, pas d'horloge dédiée).
2. **P2-10, mineur 4** — `CoucheAnnotation` (ardoise, `lib/features/tc_dock/couche_annotation.dart:140-155`)
   capte le dessin uniquement au doigt/stylet (`GestureDetector` brut, hors `Pressable`) :
   aucune alternative clavier/bouton relevée. Non traité dans la « suite donnée »
   (jugé non essentiel, mais pas corrigé). Preuve : `05_recette/P2/P2-10.md`, constat 4 et
   sa « Suite donnée ».
3. **P2-11, M1** — `debugPrint` qui journalise l'objet d'erreur complet (texte
   d'exception, parfois contenu de réponse serveur) non retiré en profil/release,
   plusieurs fichiers (`service_coran.dart`, `preferences_locales.dart`,
   `service_presence.dart`, `etats_routeur.dart`, `groupes_seances.dart`,
   `service_suivi.dart`, `roster_enseignant.dart`). Mineur sécurité, non traité.
   Preuve : `05_recette/P2/P2-11.md`, M1 et sa « Suite donnée ».
4. **P2-08, mineur 1** — planche `e/captures/e_planche_observations_admin_bureau_clair.png`
   compare un écran qui ne semble pas exister dans `lib/features` du rôle Tuteur
   (recherche « Historique des observations » sans résultat côté Tuteur) : capture
   probablement hors périmètre, non retirée. Impact faible (preuve à nettoyer, pas un
   écran manquant du rôle Tuteur) — à trier avec le rôle Admin plutôt qu'un oubli Tuteur.

Aucun `STUB`/`TODO`/`FIXME`/« bientôt » actif trouvé dans `lib/features` (`rg` : un seul
résultat, un commentaire historique dans `appareils_page.dart:54` référant à un ancien
STUB déjà remplacé, pas un stub actif).

Relance de `graphe_imports.ps1` sur `a855b23` : 419/473 fichiers `lib/` atteignables
depuis `main.dart`, 54 non atteignables — tous des ports/capacités (`lib/core/capacites/*`)
ou un bloc `tc_flux_academique` couverts par des tests indirects, **aucun écran de rôle
non relié** parmi eux. La route `/tuteur/compte/consentements` a un vrai bouton
(`lib/features/compte/compte_tuteur_page.dart:137`, `onPress: () => aller(Routes.tuteurCompteConsentements)`,
commit `e82ec66`, confirmé ancêtre de `a855b23` par `git merge-base --is-ancestor`) : le
constat « inatteignable » d'un agent antérieur est obsolète, comme le dit déjà
`05_recette/T/TRI.md` ligne 41 (« routes orphelines… constats des revues C et A
obsolètes »).

## 2. Couvert par le lot T (ne pas compter comme oubli du rôle Tuteur de base)

Tout le domaine Soldes/recharges/remises/accès (S01–S11), le retour cassé de la
Bibliothèque (m5 lot C), la photo Fiche (Prendre/Choisir/Annuler), le bouton scanner
« Ouvrir les réglages », le détail d'un paiement, le lien mouvements d'une séance
passée, le filtre Notifications, et le sélecteur de thème 3 cases — tous listés dans
`05_recette/T/TRI.md` et repris par les lignes `LT-1` (fait) à `LT-13`/`LT-R`/`LT-F`
(tableau : LT-1 à LT-6 « fait », LT-7 « en_cours », LT-8 à LT-F « a_faire », poste A,
branche `ui/tuteur-v1-t`). Ne pas redemander ces éléments à un futur agent Tuteur.

## 3. Attend le directeur (décisions, pas du code)

- **LA-3** (`en_cours`) — texte de consentement à l'observation à valider par le
  directeur avant de considérer la ligne terminée.
- **CO-04 / P2-14** (`a_faire`) — pull request brouillon `ui/tuteur-v1 → main` et
  adresse d'aperçu en ligne : attend l'accord du directeur (hors périmètre d'écriture
  du poste).
- **DIR-01 / DIR-02** (`a_faire`) — validation des captures/aperçu, décision de fusion
  en production.
- **HL-B-4** (`a_faire`, vague Tuteur V1) — questionnaire d'accueil, explicitement mis
  en attente par le directeur (système pédagogique pas encore finalisé) ; révisable à
  tout moment, pas un oubli de code.
- **P2-11 M2** — divergence `supabase/.github/vercel.json` entre la branche et
  `origin/main`, déjà présente avant ce lot (confirmé par `git diff`), signalée pour
  mémoire au pilotage, aucune action côté Tuteur.

CI de la PR #3 : **non vérifiable** — `gh` n'est pas installé sur ce poste. Connu par le
tableau : `HL-B-3` indique que la construction Android/APK a été réparée à la base
`a855b23` (Kotlin 2.0, compileSdk 37, libs à 36 minimum), mais que la mesure de
performance sur téléphone (`P2-16`) n'a pas pu être faite (aucun appareil détecté par
adb) — reprise décrite dans `05_recette/P2-16/RAPPORT.md`.

## 4. Déjà traité (constats levés, à ne pas rouvrir)

- P2-08 majeurs 1 et 2 (scanner non plein écran ; preuve Foyer obsolète) : corrigés
  `68a83f5`, captures régénérées.
- P2-09 majeur 1 (démo invisible en production) : écarté, comportement voulu (garde de
  sécurité confirmée par P2-11). Majeur 2 (clic non prouvé pour 30/34 routes) : corrigé
  `bed2c2d`, `navigation_test.dart` rattache maintenant chaque route à son test de bouton
  (35/35 verts). Mineurs 3 et 4 : écartés (déjà fait / voulu).
- P2-10 bloquant 1 (pas de preuve RTL + 200 % sur les écrans K) et majeur 2 (bandeau
  démo muet pour lecteur d'écran) : corrigés `f69f7f9`.
- Toutes les 33/34 destinations du rôle Tuteur ont une route, un bouton réel qui y mène
  et un test qui appuie sur ce bouton (`RAPPORT_DIRECTEUR.md`, annexe « Matrice de
  recette » ; confirmé indépendamment par la relecture de `app_router.dart` et le
  graphe d'imports).
- `/tuteur/compte/consentements` : atteignable par un vrai bouton, voir §1.

## Limites de cette vérification (35 minutes)

- Comparaison ligne à ligne complète de `01_visuel/00_MANIFESTE.md` (33 écrans, 511
  lignes) et `02_code/00_MAPPING_ROUTES.md` (42 routes, 187 lignes) contre le code
  **non refaite en détail** : je me suis appuyé sur la matrice déjà produite en
  `RAPPORT_DIRECTEUR.md` (annexe) et sur la revue `P2-09` (34 routes déclarées, toutes
  atteintes et testées), qui couvrent déjà ce croisement. Aucun écart supplémentaire
  trouvé dans le temps disponible ; un futur agent avec plus de temps peut refaire ce
  croisement ligne à ligne pour confirmation totale — **non vérifié en exhaustivité**.
- CI PR #3 : non vérifiable (outil `gh` absent).

---
Poste B, lecture seule. Rapport écrit à la suite du tableau `etapes` (ArtifactData) et
des fichiers `05_recette/P2/*.md`, sans modification du dépôt de code.
