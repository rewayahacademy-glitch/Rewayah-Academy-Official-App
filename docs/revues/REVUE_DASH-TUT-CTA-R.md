# Revue croisée DASH-TUT-CTA-R : un seul bouton dominant sur l'Accueil famille (DASH_STRATEGIE §3.4)

- **Objet revu** : `corrections/c2-tut-cta` @ `3c2b808e` (base `f6ac3658`), 3 commits, 16 fichiers (+313 −12), dont 12 captures et le test de capture archivé en `.txt`.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit DASH-TUT-CTA (auteur : `b061fd81`).
- **Date** : 4 octobre 2026.
- **Références** : `docs/current/DASH_STRATEGIE.md` §3.4, D4, D5 et D9, lus sur `origin/corrections/c2-dash1` ; `lib/CLAUDE.md`.
- **Méthode** :
  - lecture du diff (`bandeau_blocage.dart`, `carte_classe_seance.dart`, `accueil_famille_test.dart`) ;
  - contrôles relancés sur le worktree `/home/user/rv-tut-cta` ;
  - une sonde de sémantique et un cas « classe en panne » ajoutés le temps de la mesure, puis retirés ;
  - trois mutations ciblées, remises en place ;
  - cinq captures ouvertes ;
  - `git status` propre à la fin.

## Verdict

**Refusée.** Un défaut majeur, visible sur la capture 1440.

Sur téléphone, tout est tenu. Le bandeau porte le seul bouton primaire. La carte classe est une carte-lien sans bouton dedans.

Mais sur tablette et bureau (`compact == false`), le bandeau ne rend pas le bouton primaire. Il rend un `LienFleche` (`bandeau_blocage.dart:104-110`). Le changement de niveau de la ligne 79 n'a donc aucun effet hors téléphone. Avec un blocage, l'écran de bureau n'a **aucun** bouton plein. La tâche immédiate « Connecter un appareil » pèse autant que « Voir la classe → » et « Voir tout → ». C'est le contraire de D5 et du §3.4 (« avec blocage : Connecter un appareil passe au niveau primaire et reste le seul bouton plein »). Le test ne le voit pas : il ne tourne qu'à 390 px.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK (code 0) |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `dart run tool/verifier_revue.dart` | **1627** violations sur la branche, **1627** avec `lib/features/accueil_famille` de la base : aucune ajoutée, aucune dans `accueil_famille` |
| `test/features/accueil_famille_test.dart` | **64 réussis, 0 échec** |
| Écrans voisins : `test/accessibilite/rtl_echelle_texte_ecrans_test.dart`, `test/features/classe_tuteur`, `compte_rendu_controleur_test`, `notifications_test`, `test/router/navigation_test`, `test/teaching_core/g/entree_observation_navigation_test` | **247 réussis, 54 sautés, 0 échec** |
| Mutation 1 : bandeau remis en `NiveauAction.secondaire` | échec de « avec blocage : Connecter un appareil est le seul bouton primaire ». Pris |
| Mutation 2 : carte sans `onPress` (`onPress: null`) | 2 échecs : « Voir la classe ouvre la classe de CET eleve » et « sans blocage : aucun bouton plein, la carte ouvre la classe ». Pris |
| Mutation 3 : `lien = laClasse != null` (on oublie les erreurs) | **64 réussis**. Non prise : rien ne teste « pas de lien quand Réessayer est dans la carte » |
| Sonde « classe en panne » (port qui lève une exception) | 1 « Réessayer », 0 indice de lien, 1 seul `Pressable` dans la carte (celui de Réessayer). Le code est juste |
| Fusion à blanc `git merge-tree --write-tree origin/corrections/revue-directeur-2026-10 HEAD` | Aucun conflit (arbre `a142aaeb`) |
| Fichiers interdits (`supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`) | Aucun |

## Points de la fiche, un par un

| Point demandé | Constat |
| :--- | :--- |
| Niveau principal du bandeau | ❌ **Téléphone seulement.** `bandeau_blocage.dart:79` passe `ActionPrincipale` en `principale`, mais ce widget n'est rendu que si `compact` (l.103) ou action à droite. Hors téléphone, l.104-110 rend `LienFleche`. Captures `famille_blocage_1440_clair` et `_sombre` : « Connecter un appareil → » est un lien texte, aucun bouton plein à l'écran |
| Un seul bouton plein (K-56) | ✅ Sur téléphone : test « avec blocage » (1 seul `principale`, libellé « Connecter un appareil ») et test « sans blocage » (0). Captures 390 et 320 x2 : un seul bouton plein. ❌ Sur bureau avec blocage : 0 bouton plein, donc pas d'action dominante (voir M1) |
| Carte-lien, sans bouton dans un bouton | ✅ `AppCard(onPress: ouvrir)` (`carte_classe_seance.dart:91-93`). Le lien n'existe que si la classe est connue **et** qu'aucun « Réessayer » n'est dans la carte (l.83). L'indice « Voir la classe → » est un `Row` texte et icône sous `ExcludeSemantics`, pas un bouton. Aucun élément pressable dans `BlocSeance` ni `ConseilAppareil`. Sans classe, la carte n'est pas un lien et n'est pas un bouton grisé (D9) |
| Sémantique | ✅ avec réserve. La sonde lit un seul nœud bouton : « Voir la classe, Classe fictive A, Salle ouverte, Cours dans 10 min, Tablette ou ordinateur conseillé… ». Le prénom (en-tête), l'enseignant, la date, l'heure et la durée restent des nœuds enfants lisibles. L'indice n'est pas lu deux fois. Réserve : la carte est annoncée **bouton**, pas **lien**, alors que `Pressable` a un drapeau `lien` (`pressable.dart:171`). `AppCard` ne le transmet pas. Aucun écran ne s'en sert encore, donc c'est cohérent avec le reste (r2) |
| Captures K-61 | ✅ 12 captures présentes (avec et sans blocage, 320 x2, 390, 1440, clair et sombre). Ouvertes : `famille_blocage_320x2_clair`, `famille_blocage_390_sombre`, `famille_blocage_1440_sombre`, `famille_blocage_1440_clair`, `famille_sans_blocage_390_clair`. À 320 x2, aucun mot coupé dans la carte ni le bandeau ; le bouton passe sur deux lignes. Le sombre est sombre. Ce sont elles qui montrent M1 |
| Port neutre, capacité, i18n | ✅ Aucun texte en dur (`t.tuteur.accueil.voirLaClasse` réutilisé), aucune lecture de rôle, couleurs et tailles par jetons (`palette.inkAccent`, `AppSpacing.lg`, `Ecart.hXs`). `verifier_jetons` inchangé à 39 |
| 5 états | ✅ Inchangés : chargement (squelettes), erreur par source (Réessayer, et la carte cesse d'être un lien), vide (« aucune séance »), hors ligne par `PageShell`, contenu |
| Composants partagés | Aucun composant de `lib/core` modifié. `CarteClasseSeance` et `BandeauBlocage` ne servent qu'à `accueil_famille_page.dart`. Écrans voisins verts (247) |

## Défauts retenus

- **M1 (MAJEUR) : sur tablette et bureau, la tâche immédiate n'a pas de bouton primaire.**
  - Fichier : `lib/features/accueil_famille/bandeau_blocage.dart:103-110`.
  - Scénario : tuteur sur ordinateur (1440), élève sans appareil prêt. Le bandeau montre « Connecter un appareil → » en lien texte. Aucun bouton plein. La carte classe reste l'élément dominant.
  - Règle cassée : D5 et §3.4 (« Connecter un appareil passe au niveau primaire et reste le seul bouton plein »).
  - Le test « avec blocage » ne tourne qu'à 390 px (`_monter`, taille par défaut).
- **r1 (mineur) : la règle « pas de lien quand un Réessayer est dans la carte » n'est pas testée.** La mutation 3 passe 64 tests sur 64. Le code est juste (vérifié par sonde), mais rien ne le garde.
- **r2 (cosmétique) : la carte est annoncée « bouton », pas « lien ».** Elle mène à un endroit. `AppCard` pourrait transmettre `lien` à `Pressable`. À trancher pour toutes les tuiles-liens (lot BENTO ou DASH-LIB), pas ici.
- **Hors lot, pour mémoire** : à 320 x2, le sélecteur de profils coupe « Aucune séan… » sous Eleve A2 (capture `famille_blocage_320x2_clair`). Présent avant ce lot.

## Pour accepter

1. Étape de correction **DASH-TUT-CTA-C1** : dans `BandeauBlocage`, rendre `action` (l'`ActionPrincipale` primaire, `pleineLargeur: false`) aussi quand `compact` est faux, à la place du `LienFleche`. Mettre à jour le commentaire de classe (« lien fléché (V2) »).
2. Ajouter au groupe « DASH-TUT-CTA » un cas « avec blocage » à 1440 (`taille: Size(1440, 1800)`) : un seul `ActionPrincipale` de niveau `principale`, libellé « Connecter un appareil ».
3. Ajouter un cas « classe illisible » : « Réessayer » présent et aucun `Pressable` de carte autour (garde r1).
4. Refaire les 4 captures `famille_blocage_1440_*` et vérifier le bouton plein à droite du texte.

## Contre-vérification

- **Sceptique** : session `01KyPAZg`, qui n'est pas l'auteur. Date : 4 octobre 2026. But : essayer de réfuter M1 et chercher un majeur oublié.
- **Méthode** : relecture de `bandeau_blocage.dart`, de `carte_classe_seance.dart` et de §3.4 et D5 sur `origin/corrections/c2-dash1`. Deux captures ouvertes. Une sonde de test à 1440, retirée ensuite (`git checkout --`). `git status` propre à la fin.

### M1 : confirmé, reproduit, vraiment majeur

- **Code.** `actionADroite` exige `compact` (l.69-72). Hors téléphone, la branche `!actionADroite` rend `LienFleche` (l.105-111). L'`ActionPrincipale` de la ligne 79 n'est jamais montée.
- **Mesure.** J'ai ajouté un test temporaire : `_monter(depart: Routes.tuteurAccueil, appareils: [], taille: Size(1440, 1800))`. `BandeauBlocage` est trouvé une fois. Le nombre d'`ActionPrincipale` de niveau `principale` est **0** (attendu 1, « Expected: <1> Actual: <0> »). Le test a ensuite été retiré.
- **Capture.** Sur `famille_blocage_1440_clair`, « Connecter un appareil → » est un lien texte, de même poids que « Voir la classe → » et « Voir tout → ». Aucun bouton plein à l'écran.
- **Réfutation tentée.** Le commentaire de classe parle d'un « lien fléché (V2) » sur bureau. On peut donc se demander si c'est voulu. Ce n'est pas une défense. §3.4 ne distingue pas les appareils : « Connecter un appareil passe au niveau primaire et reste le seul bouton plein ». D5 dit : « c'est son bouton, au niveau primaire ». S11 interdit aussi de décider selon le type d'appareil. Le lot avait pour objet ce bouton dominant, et il ne le livre pas sur bureau. M1 reste **majeur**.

### Mineurs

- r1 et r2 sont confirmés comme mineurs. Le code évite bien le bouton dans un bouton, mais aucun test ne le garde.
- Le mot coupé « Aucune séan… » à 320 x2 est confirmé sur `famille_blocage_320x2_sombre`. Il existait déjà avant ce lot, donc il reste hors lot.

### Recherche d'un majeur oublié : rien de nouveau

- **Bouton dans un bouton.** Dans la carte-lien, les seuls éléments pressables sont les « Réessayer » de niveau tertiaire (`carte_classe_seance.dart:223` et `:311`). Ils n'existent que si `classe.hasError` ou `seance.hasError`, et dans ce cas `lien` est faux (l.83). `BlocSeance`, `ConseilAppareil` et `_Identite` ne contiennent aucun `Pressable`. Aucun défaut.
- **Mot coupé à 320 x2.** Sur `famille_blocage_320x2_sombre`, le bandeau, le bouton plein sur deux lignes et l'indice « Voir la classe → » (`TexteSansCoupure`) passent sans coupure. Aucun défaut nouveau.
- **Autres boutons primaires.** Les autres `ActionPrincipale` de `accueil_famille` sont des « Réessayer » de niveau tertiaire (`ligne_derniere_seance.dart:72` compris). Il n'y a donc pas de second bouton primaire sur téléphone.
- **États, texte en dur, rôle.** Il n'y a pas de texte en dur : `voirLaClasse` est réutilisé. Le code ne lit aucun rôle. Les cinq états sont inchangés.
- **Composant partagé.** Aucun fichier de `lib/core` n'est modifié. `CarteClasseSeance` et `BandeauBlocage` ne sont utilisés que par `accueil_famille_page.dart:254` et `:270`.
- **Test non discriminant.** C'est déjà relevé (r1). En plus, le test « avec blocage » ne tourne qu'à 390 px. C'est pour cela que M1 passe inaperçu. Le correctif proposé (cas à 1440) couvre ce point.

### Verdict final

**Refusée, verdict confirmé.** M1 est réel, reproduit par une mesure (0 bouton primaire à 1440 avec blocage) et majeur (D5 et §3.4). Aucun nouveau majeur. La correction proposée, DASH-TUT-CTA-C1, reste celle de « Pour accepter », points 1 à 4.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
