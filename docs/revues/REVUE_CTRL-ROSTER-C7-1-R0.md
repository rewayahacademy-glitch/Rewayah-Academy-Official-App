## Revue adverse CTRL-ROSTER-C7-1 : liste de l'observation du Contrôleur en prénom et initiale du nom (décision C7 = a)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** La liste affiche bien « Prénom N. », et le changement est prouvé par mutation. Les trois réserves restantes sont mineures et aucune ne bloque la fusion.

Revue faite sur `origin/corrections/c2-roster-c7` (commits f0342a49 et c849ab9b), comparée à la base 3df81930, dans un worktree détaché et jetable. Il a été retiré à la fin. Rien n'a été poussé.

### Ce qui est livré, contrôlé dans le code

- **Une seule fonction de formatage**, `prenomEtInitiale(prenom, nom)`, dans `lib/features/controleur/observation_controle.dart`. Elle :
  - garde le prénom en retirant les espaces en trop ;
  - prend la première lettre entière du nom (une voyelle arabe attachée reste avec sa lettre), la met en majuscule et ajoute un point ;
  - rend le prénom seul quand il n'y a pas de nom.
- **`EleveRoster`** reçoit `initialeNom`, un champ facultatif, et `nomAffiche`. Le nom de famille entier n'est jamais stocké.
- **La page d'observation** affiche `nomAffiche` dans la liste de l'étape 3 et dans le récapitulatif.
- **La démonstration** connaît les initiales (Mariam S, Yusuf B, Aïcha N) et les transmet au roster.
- **L'Historique (démo)** passe maintenant par la même fonction. La consigne disait de réutiliser une fonction de l'Historique, mais elle n'existait pas : ses libellés étaient écrits à la main. J'ai vérifié que l'écart signalé par le rédacteur est exact.
- **Deux libellés i18n** (`contextePersonne`, `elevePrecisAide`) ne disent plus « prénom seulement ». Ils sont déclarés « à faire valider par le directeur » dans `tool/libelles_sources.json`.
- **Documentation** : j'ai cherché « prénom seul » et ses variantes dans `docs/` (hors archive) et dans le code. Aucune mention ne vise encore cette liste, il n'y avait rien à corriger.
- **Périmètre** : aucun fichier interdit n'est touché (`supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, thème, Coran). Les commits sont en français et finissent par le bon trailer.

### Contrôles relancés

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` | aucun écart avec le dépôt |
| `dart analyze --fatal-infos` | 0 problème |
| `verifier_revue` | 1604 sur la branche, 1606 sur la base ; aucune violation dans les fichiers modifiés |
| `verifier_jetons` | 39 sur la branche, 39 sur la base |
| `flutter test --concurrency=2 test/features/controleur test/features/demo` | 296 réussis, 0 échec |
| `test/i18n`, `test/tool`, `test/router`, `test/accessibilite` | 652 réussis, 0 échec |

Les autres utilisateurs de `EleveRoster` et `rosterControleProvider` (page de démo du Contrôleur, `frontiere_donnees`, test d'observation, test de la page de démo) sont tous couverts par ces lancements.

### Mutations (contre-épreuves)

1. **Page remise sur `e.prenom`** (liste et récapitulatif) : 3 échecs (320 px x2 en LTR, en RTL, et le récapitulatif).
2. **`prenomEtInitiale` renvoie le prénom seul** : 10 échecs, dont `frontiere_donnees`.
3. **Initiale retirée du roster de démonstration** : 3 échecs.

Le code a été restauré après chaque mutation.

### Captures ouvertes

- **Les 2 PNG livrés à 390 px en clair** : conformes. On voit Mariam S., Yusuf B., Aïcha N., puis « Élève précis · Mariam S. » dans le récapitulatif.
- **Mes captures de relecture**, avec un nom composé et un nom arabe dans le roster :
  - **320 px, texte x2, LTR** : aucun mot coupé. « Abd al-Rahman E. » passe à la ligne après son trait d'union, ce que la règle autorise.
  - **320 px, texte x2, RTL** : aucun mot coupé, mais le point d'un nom latin passe à gauche (« .Mariam S »).
  - **390 px en sombre** : conforme.
  - **1440 px en clair** : conforme.
- L'Interface guidée ne s'applique pas à l'espace Contrôleur.

### Réserves (mineures)

1. **Le point se place mal hors de son sens d'écriture**, parce que le libellé n'isole pas son sens d'écriture.
   - En RTL, un nom latin s'affiche « .Mariam S ».
   - En français, un nom arabe s'affiche « ن عائشة. », avec le point avant le prénom dans l'ordre de lecture.
   - Correctif simple : entourer le libellé des caractères U+2068…U+2069, comme le fait déjà `_isole` dans `mes_classes_page.dart`.
   - C'est mineur parce que l'arabe n'est pas encore traduit pour le Contrôleur.
2. **Le champ `RapportControle.eleve` de l'Historique reste documenté « prénom »** et s'affiche tel quel. Ce n'est pas visible en démo, mais le contrat serveur est à aligner sur C7.
3. **Aucun test n'empêche de remettre des libellés écrits à la main** dans l'Historique de démo : la règle « une seule fonction » n'est vérifiée qu'à la relecture.

### Besoins serveur (consignés, rien de branché)

- Le roster autorisé doit fournir `initialeNom`, jamais le nom entier.
- Les élèves présents de l'Historique doivent arriver au même format, et l'élève concerné aussi.

### Statut

Présent dans le code et testé localement. Ni testé sur staging, ni déployé. Les deux libellés restent à valider par le directeur.
