# Revue DASH-TUT-CTA : REFUSÉE

L'étape est refusée pour un défaut majeur : sur bureau, le blocage n'a toujours pas de bouton primaire. Le téléphone est conforme.

## Verdict

**REFUSÉE.**

- **Téléphone : conforme.** Avec un blocage, « Connecter un appareil » est le seul bouton primaire. Sans blocage, il n'y a aucun bouton plein. La carte classe entière ouvre la classe, sauf quand un « Réessayer » est dedans ou que la classe est inconnue.
- **Tablette et bureau : non conforme.** Avec un blocage, « Connecter un appareil » reste un lien fléché, comme sur la maquette V2. DASH_STRATEGIE D5, §3.4 et l'annexe A TUT-01 demandent sans exception un bouton de niveau primaire pour cette tâche immédiate. Sur la capture 1440, l'écran n'a aucun bouton plein. Le blocage a le même poids que « Voir la classe → », « Voir tout → » et « Voir l'historique → ». Le point « à juger » de la fiche est donc tranché : majeur.

## Périmètre et commandes

- **Périmètre :** `f6ac3658..3c2b808e`, soit 3 commits : `bandeau_blocage.dart` (+2/-1), `carte_classe_seance.dart` (+43/-11), `accueil_famille_test.dart` (+41), le fichier de test de capture (.txt) et 12 PNG.
- **`dart analyze --fatal-infos` :** propre.
- **`verifier_revue` :** 1627 violations sur la tête comme sur la base.
- **`verifier_jetons` :** 39 violations sur la tête comme sur la base, toutes préexistantes.
- **Tests ciblés** (accueil_famille, classe_tuteur, entree_observation_navigation ; `--concurrency=2`) : 111 tests, tous passent.
- **Contre-épreuve 1 :** avec l'ancien code de `lib/features/accueil_famille/`, les 2 nouveaux tests échouent.
- **Contre-épreuve 2 :** avec le seul ancien bandeau, le test « avec blocage » échoue (longueur 0 au lieu de 1).
- Le code a été restauré après les contre-épreuves.
- **Libellés :** aucun libellé nouveau.

## Défauts

1. **Majeur** — `lib/features/accueil_famille/bandeau_blocage.dart:104-110`
   - La branche hors téléphone (`!compact`) rend un `LienFleche` au lieu de l'`ActionPrincipale` primaire.
   - Les tests ne vérifient que le gabarit téléphone, ce qui laisse passer le défaut.
   - Correction : rendre aussi `action` sur bureau, et ajouter un test au gabarit 1440 (un seul bouton primaire, « Connecter un appareil »).
2. **Mineur** — `carte_classe_seance.dart:91-93` et `app_card.dart:103-109`
   - La carte-lien est annoncée « bouton » et non « lien » aux lecteurs d'écran.
   - AppCard ne transmet pas le paramètre `lien` de Pressable.
3. **Mineur** — `accueil_famille_test.dart`
   - Trois règles ne sont pas testées : carte sans lien quand un « Réessayer » est présent, carte sans lien quand la classe est inconnue, gabarit bureau.
4. **Mineur** — `carte_classe_seance.dart:119-144`
   - Sur bureau, l'indice « Voir la classe → » est au milieu de la carte, au-dessus de la note appareil, au lieu de la fermer.
5. **Mineur, préexistant, hors lot** — en 320 px au texte ×2 :
   - « Aucune séan » est rogné dans le sélecteur de profils.
   - « Cours dans 2 h / 59 » est coupé dans le bloc séance.
   - À consigner, pas à imputer à ce lot.

## Captures vues

- **`famille_blocage_390_clair` :** conforme.
- **`famille_blocage_320x2_clair` :** conforme pour le lot ; défaut 5 préexistant.
- **`famille_blocage_1440_sombre` :** défauts 1 et 4.
- **`famille_sans_blocage_320x2_sombre` :** conforme pour le lot ; défaut 5 préexistant.

Partout : aucun chevauchement, aucun texte trop petit, aucun élément collé.

## Pour accepter

1. **Corriger le défaut 1 :** sur tablette et bureau, avec un blocage, « Connecter un appareil » devient un bouton primaire, seul bouton plein de l'écran.
2. **Ajouter le test au gabarit bureau** et faire sa contre-épreuve.
3. **Refaire les deux captures `famille_blocage_1440`** (clair et sombre).
4. **Corriger si possible** les défauts 2 à 4 dans le même lot (sinon ils restent comme réserves).

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **REFUSEE**.

Le refus tient. J'ai vérifié le défaut majeur sur un worktree détaché à origin/corrections/c2-tut-cta (3c2b808e), que j'ai retiré ensuite.

1) Code. Dans lib/features/accueil_famille/bandeau_blocage.dart, `action` passe bien à NiveauAction.principale, mais il n'est rendu que si `compact` est vrai (rangée de droite si actionADroite, sinon `if (compact) action`). Hors compact, c'est toujours `LienFleche(libelle: connecterAppareil)`. Sur tablette et bureau, l'écran n'a donc aucun bouton plein quand il y a un blocage. Le diff du lot (f6ac3658..HEAD) ne touche pas à cette branche.

2) Spécification. Dans DASH_STRATEGIE.md (origin/corrections/c2-dash1), D5 dit : « Quand une tâche est immédiate (… connecter l'appareil qui bloque), c'est son bouton, au niveau primaire, et lui seul ». Le §3.4, l.198-199, dit : « avec blocage : "Connecter un appareil" passe au niveau primaire et reste le seul bouton plein ». La ligne 1 du tableau TUT-01 donne « large 2×1 / 4×1 », donc les deux gabarits sont concernés. L'annexe TUT-01, l.377, dit la même chose. Aucun de ces passages ne prévoit d'exception pour le bureau ou la tablette. La maquette V2, citée dans la docstring, est antérieure et ne prévaut pas sur une décision datée du 02/10.

3) Capture. J'ai ouvert famille_blocage_1440_clair.png, que le premier relecteur n'avait pas regardée. « Connecter un appareil → » y est un lien texte violet, du même style que « Voir la classe → », « Voir tout → » et « Voir l'historique → ». Il n'y a aucun bouton plein. La capture confirme aussi que l'indice « Voir la classe » se trouve au-dessus de la note appareil, et non en bas de la tuile.

4) Tests. Le test « avec blocage : seul bouton primaire » monte le gabarit par défaut (téléphone) et ne couvre donc pas le bureau. Les défauts mineurs sont réels eux aussi : app_card.dart n'expose pas `lien` (grep vide), alors que pressable.dart:326-327 en dispose (`button: _pressable && !widget.lien, link: widget.lien`). Et le groupe DASH-TUT-CTA ne contient que deux tests, sans cas d'erreur, sans cas sans classe et sans gabarit bureau.

Je n'ai pas relancé la suite de tests ciblée : le premier relecteur l'a déjà passée (+111) avec ses contre-épreuves, et le refus repose sur une branche de code non modifiée, prouvée par le code, le texte de la spécification et la capture. Je n'ai trouvé aucun défaut supplémentaire de gravité bloquante ou majeure. Les défauts du sélecteur (« Aucune séan ») et de « 2 h / 59 » restent consignés comme préexistants, hors lot.

Correction attendue : rendre `action` (ActionPrincipale principale, pleineLargeur:false) aussi hors compact, ajouter un test au gabarit 1440, et refaire les captures 1440.

