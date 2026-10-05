<!-- verdict : REFUSEE -->
## Revue adverse PAGESHELL-200-1c : refusée

- **Branche relue :** `corrections/c2-pageshell-c`, au commit 397ef11d, qui suit aea2efb4.
- **Base :** `corrections/revue-directeur-2026-10` (4207c357).
- **Conditions :** worktree jetable en lecture seule, retiré à la fin. Rien n'a été poussé.

### Verdict

La branche apporte un vrai progrès et n'introduit aucune régression. Mais le premier point de la demande n'est pas rempli. Il fallait « un minimum utile du corps qui garde le support réellement visible ». Or ce minimum ne s'applique que lorsque la page défile déjà. Dans les vues jugées « qui tiennent », le support reste invisible ou presque :
- en Interface guidée, à 390x844 et 200 % de texte, on n'en voit que 13 px ;
- en Interface guidée, à 667x375 et 100 %, la fenêtre fait 39 px et le support n'y apparaît pas.

C'est le symptôme même de la réserve 1, qui citait déjà l'Interface guidée. D'où le refus.

### Ce qui est vérifié et tient

**Contrôles statiques**
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1568 violations, comme sur la base.
- `verifier_jetons` : 39 violations, comme sur la base.
- Aucune ligne ajoutée ne dépasse 80 colonnes. Le commentaire de `_corpsLarge` est corrigé.

**Tests**
- Lancés avec `--concurrency=2` sur `test/widgets`, `test/teaching_core/g` et tous les fichiers de test qui citent `PageShell` ou `PanneauObservationTuteur` : +1140 ~139, tous verts.
- `test/features`, `test/router` et `test/core` : +3797 ~2129, tous verts. Réserve : ce lancement a recouvert des bascules temporaires de `lib` vers la base pour les comparaisons. Le lancement ciblé ci-dessus, lui, est propre.

**Mutations** (sur `salle_observation_test` et `page_shell_hauteur_corps_test`), toutes rattrapées :
- signal de `DefileurCorps` mis à 0 : 16 échecs ou plus ;
- `setState` de bascule neutralisé : 4 échecs ou plus ;
- `minimumEtire` remis à `AppTouchTarget.standard` : échecs ;
- condition « texte agrandi » neutralisée : échecs.

**Captures ouvertes**
- 320x568 à 200 % en haut, au support et au bout : la pastille « En direct » est entière et le support entier en bout.
- 800x360 à 200 % : en-tête et support entiers.
- 667x375 à 200 %, en Interface guidée : barre atteinte en bout, sans débordement.
- RTL :
  - 667x375, Interface guidée, sombre ;
  - 320x568, Interface guidée, au support ;
  - 390x844 à 200 %, relancé par moi.

  Dans ces vues, l'en-tête en Wrap s'aligne bien au début.
- 1440x900 à 100 % (sombre) et à 200 % (clair) : aucune régression.
- 390x844 à 200 % : la barre reste au premier affichage.

**Débordement à 667x375 sans zone sûre, à 200 %**
- Il a bien disparu, en standard comme en Interface guidée, en LTR comme en RTL.
- À 100 %, en paysage standard, la tête reste fixe et la barre reste visible.
- À 320x568 et 100 %, la branche supprime aussi un débordement bas de 168 px présent sur la base.

### Défauts

1. **Majeur. Le minimum utile ne garde pas le support visible quand la salle « tient ».**

   Le minimum de 200 porte sur la zone étirée, qui contient aussi l'en-tête. Le signal de `DefileurCorps`, lui, n'est compté que si la page défile déjà.

   Mesures du test adverse (page sans défilement) :

   | Vue | Texte | Interface | Zone | Haut du support | Support visible |
   | --- | --- | --- | --- | --- | --- |
   | 390x844 | 200 % | guidée | 348..605 | 592 | 13 px |
   | 414x896 | 200 % | guidée | 348..656 | 598 | 58 px |
   | 360x800 | 200 % | standard | — | — | 82 px sur 312 |

   Les valeurs sont identiques sur la base. Le commentaire du panneau, qui affirme que le défileur garde l'en-tête et le support visibles, est faux dans ces vues.

2. **Majeur. En Interface guidée à 100 %, le défaut reste entier.**
   - À 667x375, la zone du support n'a que 39 px (vp=39, max=259). Le support n'y est pas construit : `find.byKey('support-observation')` ne trouve aucun widget.
   - La cause : la bascule exige plus de 130 % de texte (`texteAgrandi`), un critère qui ignore l'Interface guidée.
   - À 390x844, à 100 % et en guidée, le support est écrasé à 102 px.

3. **Mineur, hors périmètre et préexistant.** Le Row de `compteur_visite.dart:149` déborde de 6 px à droite à 320x568 et 100 % de texte, en standard comme en guidée. À 390x844, 130 %, guidée, le même débordement vaut 1,3 px.

4. **Mineur.** `_vueForcee` n'est jamais réévaluée tant que la vue (contraintes et échelle) ne change pas. Une page passée en défilement global y reste même si son contenu rapetisse ensuite.

### Ce qu'il faut pour accepter

- Le minimum utile doit garantir que le support lui-même est visible, à sa hauteur lisible et pastille comprise. Il ne suffit pas d'une zone de 200 px qui contient l'en-tête.
- Cela vaut aussi quand la salle « tient » : à 390x844 et 414x896 à 200 % en Interface guidée, à 360x800 à 200 %, et en Interface guidée à 100 % (667x375, 390x844).
- Il faut soit faire défiler la page, soit réduire l'en-tête. Si le directeur préfère la barre au premier affichage plutôt que la visibilité du support, il doit trancher cet arbitrage par écrit.
- Des tests doivent couvrir ces vues et échouer sur 397ef11d.
