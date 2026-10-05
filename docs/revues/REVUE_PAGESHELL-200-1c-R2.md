<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## Revue adverse de PAGESHELL-200-1c sur `corrections/c2-pageshell-c` (4a879cbd)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Je n'ai trouvé aucun défaut majeur prouvé. Les quatre points de la demande sont traités. Il reste quatre réserves mineures, détaillées plus bas.

### Les quatre points de la demande

**1. Un minimum utile qui garde le support visible : fait.**
- `ColonneCorps` passe à `minimumEtire: _hauteurMinSupport` (200).
- Un nouveau composant, `DefileurCorps`, signale à `PageShell` la part de l'en-tête et du support que le défileur imbriqué cache. La page donne alors cette hauteur au corps et défile.
- Captures ouvertes : 800x360 x2 (haut, support, bout, clair et sombre), 320x568 x2 (standard, Interface guidée, RTL), 390x844 x2 en Interface guidée (LTR clair, RTL sombre) et 667x375 x2 en Interface guidée (LTR, RTL sombre). Le support fait au moins 200 px et s'affiche en entier. La pastille « En direct » n'est plus coupée.

**2. Le débordement à 667x375 sans zone sûre, à 200 % : corrigé.**
- Sur la base 4207c357, ma sonde reproduit « _RenduColonneCorps overflowed by 213 pixels » en Interface guidée.
- Sur la branche : aucune exception, la page défile sur 849 px, et la barre se rejoint en entier (« Quitter » à 267..323 dans une vue de 375).

**3. Capture RTL : faite.** Il y en a 18, en clair et en sombre, en standard et en Interface guidée.

**4. Commentaire trop long dans `_corpsLarge` : corrigé.** Il est désormais coupé sur plusieurs lignes.

**En plus, ce qui est vérifié :** le bandeau du décompte passe dans un `Wrap`. La mutation qui l'annule fait échouer 5 tests sur 5.

### Mutations

| Correctif annulé | Résultat |
| :--- | :--- |
| `DefileurCorps` signale 0 au lieu de `_cache` | 32 échecs dans les tests touchés |
| `_basculer` neutralisé (plus de défilement global forcé) | 15 échecs |
| `Wrap` du compteur retiré | 5 échecs sur 5 |
| `minimumEtire` remis à 48 | **aucun échec** : réserve 3 |

### Commandes

- `dart analyze --fatal-infos` : 0 problème.
- `verifier_revue` : 1568, comme sur la base.
- `verifier_jetons` : 39, comme sur la base.
- Tests, tous avec `--concurrency=2` :
  - `test/widgets` et `test/teaching_core` : +1673 ~168, tous passent.
  - `test/features` et `test/router` : +3127 ~2129, tous passent.
- Aucun fichier interdit n'est touché (ni `supabase/`, ni `.github/`, ni `pubspec`, ni le thème, ni le Coran).
- Les trois commits se terminent par les deux lignes de signature exactes.

### Réserves (toutes mineures)

1. **Les vignettes de la salle téléphone restent derrière le défileur imbriqué.** Le repère est posé avant elles. Une fois la page défilée jusqu'au bout, on voit le support puis la barre, sans caméra. Cas mesurés (part encore cachée dans le défileur imbriqué) :
   - 390x844 à 200 %, Interface guidée : 142 px ;
   - 414x896 : 151 px ;
   - 360x800 : 131 px ;
   - 320x568 à 200 % : 116 px ;
   - 320x568 à 100 % : 116 px.

   La capture `390x844@2_texte200_light_guidee_bout.png` le montre. Ce n'est pas une régression, car c'était déjà le cas sur la base, où le support était en plus caché. Mais « la page défile pour le reste » n'est pas rempli à la lettre. Correctif suggéré : poser le repère après les vignettes.

2. **La règle PAGESHELL-200-1 est abandonnée sur téléphone à 200 %.** Elle demandait la barre entière au premier affichage ; désormais la barre ne se rejoint qu'en défilant. Le rédacteur l'a déclaré. Le directeur doit trancher.

3. **`minimumEtire: _hauteurMinSupport` n'est couvert par aucun test** (mutation survivante).

4. **Il manque les captures à 1440 et à 390x844 à 100 % en standard.** La sonde montre une géométrie à 1440 identique à la base.

### Non vérifié

- L'assertion sémantique de Flutter qui casse en debug quand on tourne l'écran pendant qu'une boîte de dialogue se ferme. Le rédacteur la dit préexistante ; je n'ai pas cherché à la reproduire.
- Le statut reste « testé localement » seulement. Rien n'est testé sur staging ni déployé.

Les worktrees jetables (branche, base, mutations) ont été retirés. Je n'ai rien poussé.