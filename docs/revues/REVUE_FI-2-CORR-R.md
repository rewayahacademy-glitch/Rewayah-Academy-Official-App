# Revue FI-2-CORR-R (relecteur spécialiste, 04/10/2026)

## Verdict : ACCEPTÉE AVEC RÉSERVES

M1, m1 et m2 de la revue FI-2-R sont levés. Je l'ai vérifié par les tests, par une contre-épreuve refaite moi-même et par les captures. Il ne reste aucun défaut bloquant ni majeur dans le périmètre de la correction. Quatre réserves mineures sont à reporter : une coupure de mot antérieure à cette correction, et trois manques de preuve.

## Périmètre et commandes

- **Périmètre** : `bdac0bb7^..bdac0bb7` sur `ui/finance-v1`, soit 10 fichiers, +246 / −41. J'ai lu tout le diff.
- **`lib/core/widgets/avatar_nom.dart`** : nouveau paramètre `texteEtire`, faux par défaut, qui passe le texte en `FlexFit.tight`.
  - `CarteMembre` est le seul appelant à l'activer (`ligne_membre.dart:221`). Les autres appelants de `fin:` ne changent pas.
  - Le changement est minimal, sans valeur en dur, et RTL correct puisque Row et Flexible suivent le sens de lecture.
- **`legendeCouleur`** (`fiche_eleve_page.dart`) : renvoie « Pas encore disponible » quand l'erreur est `CapaciteIndisponible`. Sinon, le nom de la couleur ou « Sans couleur ».
- **`prenomsJoints`** (`couleur_page.dart`) : la jonction passe par le libellé `prenomsEt`, pas par une concaténation en dur.
- **Fichiers générés et libellés** : les décalages de `strings_fr.g.dart` viennent du découpage en blocs de slang, régénéré à l'identique. Les deux libellés nouveaux sont sourcés dans `tool/libelles_sources.json`.
- **Branchement serveur** : aucun. Le rendu du Coran n'est pas touché.

| Contrôle | Tête | Base |
|---|---|---|
| `dart analyze --fatal-infos` | 0 | n/a |
| `verifier_jetons` | 39 | 39 (sortie identique) |
| `verifier_revue` | 1627 | 1627 (sortie identique) |
| carte_membre + fiche_eleve | 52/52 | n/a |
| ligne_membre, foyer_page, accessibilite_foyer, avatar_nom, avatar_ligne_rubrique | 102/102 | n/a |

**Contre-épreuve refaite.** J'ai remis l'ancien code : `ligne_membre.dart` de la base, `legendeCouleur` sans la branche de l'indisponible, et `prenomsJoints` qui ne garde que le premier prénom. Résultat : 9 échecs.
- carte de 896 et 1312 px, en LTR et en RTL (4) ;
- Foyer à 1024 et 1440 px (2) ;
- m1, en test unitaire et dans le parcours de la fiche (2) ;
- m2 (1).

Les cas à 358 et 390 px restent verts, comme annoncé par l'auteur. Le code est restauré.

## Défauts

1. **Mineur, antérieur à FI-2-CORR.** À 320 px et 200 % de texte, un prénom de 12 lettres est coupé au milieu du mot dans la carte du Foyer : « Abdour/ahmane ».
   - Où : `ligne_membre.dart:216-240` et `avatar_nom.dart:255`.
   - Le nom est un `Text` simple, sans `TexteSansCoupure`.
   - L'ancien code donne le même rendu (capture `rv12_base_320_ltr_200`) : la correction n'y est pour rien. Le défaut est à traiter dans une étape distincte, avec un test aucun-mot-coupé sur `CarteMembre`.
2. **Mineur.** Rien ne teste m2 dans l'écran.
   - Où : `couleur_page.dart:132-136`.
   - Preuve : si je remets l'ancienne boucle de `priseePar`, les 52 tests passent toujours.
3. **Mineur.** Les captures livrées n'ont ni 320 px ni RTL : seulement 390 et 1440.
4. **Mineur.** Le test du Foyer réel à 390, 1024 et 1440 px ne mesure la flèche qu'en LTR. Le RTL n'est couvert que par le test de la carte isolée.

## Captures vues

- **Captures de l'auteur** : `fi2_foyer_1440_light`, `fi2_foyer_1440_dark`, `fi2_foyer_390_light_200pc`, `fi2_fiche_390_light`. La flèche est au bout de la carte à 1440 px (x≈915 pour un bord à ≈945). Rien de coupé ni de chevauché.
- **Captures du relecteur** :
  - `rv12_320_ltr_100` : correct ; la phrase avec trois prénoms se lit bien.
  - `rv12_320_ltr_200` et `rv12_320_rtl_200_dark` : la coupure du défaut 1. La flèche est au bord de fin et sa direction est juste en RTL.
  - `rv12_1024_rtl_dark` : la flèche est au bord de fin, à gauche.

## Pour accepter sans réserve (étape suivante, ne bloque pas FI-2-CORR)

- **Défaut 1** : garantir aucun mot coupé pour le nom de `CarteMembre` à 320 px et 200 %, avec `TexteSansCoupure` ou une disposition empilée. Ajouter le test correspondant et sa contre-épreuve.
- **Défaut 2** : un test de la page Couleur avec deux autres profils sur la même couleur, qui vérifie « X et Y ».
- **Défauts 3 et 4** : des captures à 320 px et en RTL du Foyer, et la mesure de la flèche en RTL dans le test du Foyer réel.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **ACCEPTEE_AVEC_RESERVES**.

Le verdict ACCEPTEE_AVEC_RESERVES tient : je n'ai trouvé ni bloquant ni majeur.

Diff relu en entier :
- M1 : AvatarNom.texteEtire vaut false par défaut, ce qui fait passer le Flexible en FlexFit.tight. Seule CarteMembre l'active. Son seul usage est foyer_page.dart:443, dans une largeur bornée, donc le Flexible tight n'expose aucun risque de largeur infinie. Les quatre autres appelants de fin: ne changent pas.
- m1 : legendeCouleur. m2 : prenomsJoints, avec la phrase dejaPrise réécrite.
- Les deux libellés nouveaux sont déclarés.
- Dans strings_fr.g.dart, les hunks sur dossiers, admin, compte, enseignant, controleur et tc ont un contenu identique octet pour octet (vérifié avec cat -A). Ce sont des frontières de fonctions générées par slang qui se déplacent, pas une régression.

Les réserves du premier relecteur sont vérifiées et justes :
- test/support/aucun_mot_coupe.dart est bien absent de la branche.
- Les captures livrées sont bien les 10 PNG à 390 et 1440 px, sans 320 px ni RTL.
- Le test du Foyer réel ne mesure bien la flèche qu'en LTR.
- La mesure RTL de carte_membre_test est correcte : rFleche.left - rCarte.left. Le test passe à 9/9 chez moi.

Le premier relecteur a manqué un défaut mineur : la correction de m1 ne couvre que l'indisponible. Pendant le chargement et sur un échec de lecture, la ligne affiche encore « Sans couleur » (prouvé par une sonde). Il est mineur parce qu'il n'a pas d'effet en production tant que la source n'est pas branchée. Il ne renverse donc pas l'acceptation, mais il doit s'ajouter aux réserves.

Lecture seule : sonde supprimée, worktree cr-12 retiré (git worktree list ne le montre plus).

- Défaut manqué (mineur) — lib/features/foyer/fiche_eleve_page.dart:446-461 (legendeCouleur, ecrite par FI-2-CORR) : La correction de m1 est partielle (D10). legendeCouleur ne distingue que CapaciteIndisponible. Pendant le chargement, et sur un echec de lecture ordinaire (reseau, serveur), la ligne « Couleur du profil » affiche « Sans couleur ». C'est le meme travers que m1 : on fait croire a un choix vide alors qu'on ne sait rien. Pourtant LigneRubrique.legende accepte null (groupe_reglages.dart:57), et le meme ecran suit deja la bonne regle pour la classe : texteClasse rend null quand la lecture est inconnue, « jamais pas de classe faute de savoir », et a un libelle d'echec. Aucun test ne couvre ces deux etats.
  Preuve : J'ai ecrit une sonde jetable sur bdac0bb7 (flutter test --concurrency=2), puis je l'ai supprimee. Elle appelle legendeCouleur avec AsyncValue.loading() et avec AsyncValue.error(Exception('reseau')). Sortie : « CHARGEMENT=Sans couleur ECHEC=Sans couleur AUCUNE=Sans couleur ». En production le port est indisponible, donc l'impact reste nul tant que la source n'est pas branchee (FI-BR-19). D'ou mineur, non bloquant.
