## Revue adverse CTRL-ROSTER-C7-1 : liste de l'observation du Contrôleur en prénom et initiale du nom

**Verdict : la demande est remplie, avec une réserve moyenne sur le rendu bidirectionnel.** La fusion est possible, à condition de traiter ce point dans un lot de suivi.

Revue faite en lecture seule sur un worktree jetable détaché sur `origin/corrections/c2-roster-c7` (c849ab9b), base 3df81930. Le worktree est retiré et rien n'a été poussé.

### Points de la demande
| Point | Constat |
|---|---|
| La liste de l'étape 3 affiche « Prénom N. » | Oui. La page passe de `e.prenom` à `e.nomAffiche` dans la liste et dans le récapitulatif (« Élève précis · Mariam S. »). |
| Une seule fonction de formatage, partagée avec l'Historique | Oui. La fonction est `prenomEtInitiale` dans `observation_controle.dart`. L'Historique de démonstration, qui avait des libellés écrits à la main, passe maintenant par cette fonction. `historique_controleur.dart` ne contenait aucune fonction de formatage, donc l'écart signalé par le rédacteur est réel et sa solution est correcte. Rien n'est dupliqué. |
| Démonstration : Mariam, Yusuf, Aïcha | Oui. La table `initialesNom` donne S, B et N, et `rosterDemoControleur` la transmet. Le nom de famille entier n'apparaît jamais. |
| Docs qui disent « prénom seul » | Recherche faite dans `docs/current`, `lib`, `assets`, `tool` et `test`. Il ne reste aucune mention qui vise cette liste ; les occurrences restantes portent sur d'autres écrans. Les deux libellés i18n ont été corrigés et sont déclarés comme textes à valider. |
| Serveur | Le besoin est bien consigné : le serveur doit fournir `initialeNom`, sans aucun branchement. `supabase/` n'est pas modifié. |
| Interdits | Aucun fichier touché dans main, .github, pubspec, le thème, le rendu du Coran ou supabase. |

### Vérifications refaites
- `dart run slang` ne produit aucune modification ; `dart analyze --fatal-infos` ne signale aucun problème ; `dart format` sur les 8 fichiers ne change rien.
- `verifier_revue` : 1604 violations, contre 1606 sur la base, donc aucune nouvelle. `verifier_jetons` : 39. Le diff ne touche à aucun style.
- `flutter test --concurrency=2 test/features/controleur test/features/demo` : tout passe (296 réussis, 10 captures sautées).

### Mutations : chacune fait échouer au moins un test
1. Liste remise en `e.prenom` : les tests de la liste à 320 px x2 échouent (le dernier en échec est le cas RTL).
2. Récapitulatif remis en `e.prenom` : « le récapitulatif reprend le même libellé » échoue.
3. Initiale sans majuscule : le test unitaire du format échoue.
4. Démonstration sans `initialeNom` : le test du roster de démonstration échoue.
5. `substring(0,1)` au lieu d'un graphème entier : le test de l'arabe avec voyelle échoue.

### Captures ouvertes
- Captures du rédacteur, en 390 px clair : `roster_390_clair.png` et `recapitulatif_390_clair.png`. Elles sont conformes.
- Captures que j'ai produites : 320 px x2 en LTR clair, 320 px x2 en RTL sombre, 390 px sombre et 1440 px clair. Aucun mot n'est coupé. « Abd al-Rahman » passe à la ligne après le trait d'union, ce que la règle `traitDUnionPermis` autorise.
- L'Interface guidée ne concerne pas le Contrôleur.

### Réserve (moyenne) : rendu bidirectionnel
Le point final, qui est nouveau, n'est pas isolé du sens de l'interface :
- en interface RTL, un nom latin s'affiche « .Mariam S » ;
- en interface LTR, un nom arabe s'affiche « ن عائشة. », avec le point au début du nom dans le sens de lecture.

Le dépôt a déjà une solution pour ce cas : `_isole` (U+2068…U+2069) dans `mes_classes_page.dart`. Il suffit d'isoler le libellé dans `nomAffiche`, ou de régler la direction du texte selon l'écriture du nom, puis d'ajouter un test sur l'ordre d'affichage. Les tests RTL actuels ne le détectent pas : ils vérifient la présence du texte et l'absence de mot coupé, et ils inversent seulement la Directionality, sans locale arabe. Les clés `controleur.*` n'existent d'ailleurs pas dans `ar.i18n.json`.

### Autres réserves (mineures)
- Les deux libellés réécrits restent à faire valider par le directeur.

### Statut
Le changement est présent dans le code et testé localement. Il n'est ni testé sur staging ni déployé.
