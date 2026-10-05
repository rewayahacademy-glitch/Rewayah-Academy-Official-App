# Revue adverse : DASH-ELV-ERR-c (captures RTL de l'état d'erreur de l'accueil élève)

**Branche** : `origin/corrections/c2-elv-err-c` @ `50f4a142`. J'ai travaillé en lecture seule, dans un worktree jetable que j'ai retiré à la fin. Je n'ai rien poussé.

**Verdict : ACCEPTÉE AVEC RÉSERVES.** La demande est remplie. Il ne reste aucun défaut majeur. Trois réserves mineures sont listées en fin de rapport.

## Ce qui était demandé

Lever la réserve de la revue DASH-ELV-ERR-b-R : produire les captures RTL de l'état d'erreur de l'accueil élève à 320 px (texte ×2), 390 px et 1440 px, en clair et en sombre, sans modifier les deux libellés soumis à DASH-LIB.

## Ce que contient le commit

- 13 fichiers, tous sous `docs/current/captures/DASH-ELV-ERR-c/` : 12 PNG et le script `.dart.txt`.
- Ni `lib/`, ni `assets/`, ni `tool/`, ni `test/` ne sont modifiés (`git diff HEAD~1 HEAD -- assets tool lib` : 0 ligne).
- Aucune zone interdite n'est touchée par ce commit : supabase, .github, pubspec, thème, Coran.
- Les deux lignes de fin du message de commit sont conformes.

## Preuves

| Contrôle | Résultat |
| :--- | :--- |
| Script rejoué (copié dans `test/capture/`, `CAPTURE_DIR`, `--concurrency=2`) | 12 cas réussis sur 12 |
| Reproductibilité | les 12 PNG régénérés sont **identiques à l'octet près** (`cmp`) aux PNG commités |
| Dimensions | 320×1400 (texte ×2), 390×900, 1440×900, conformes |
| Mutation : sens forcé à `TextDirection.ltr` dans le script | les 12 cas **échouent** sur l'assertion de sens. Le contrôle RTL n'est donc pas décoratif |
| Contrôles intégrés au script | sens RTL vérifié sur `AccueilElevePage`, présence de `erreurCours` (et de `erreurCoursHorsLigneTitre` hors ligne), `takeException() == null`, `verifierEcranSansMotCoupe` sur tout l'écran |
| `dart analyze --fatal-infos` | No issues found |
| `verifier_revue` | 1573, comme la base indiquée par le rédacteur (aucun code modifié) |
| `verifier_jetons` | exécuté, aucun changement possible puisque le code n'a pas bougé |
| `test/features/accueil_eleve_test.dart` | 54 réussis sur 54 |

Je n'ai pas fait de mutation sur le code produit : ce commit n'en contient aucun. La mutation a porté sur le script de capture. Je n'ai pas relancé les autres dossiers de tests : sans changement de code, ils ne peuvent pas régresser.

## Captures ouvertes

J'ai ouvert `elv_err_320x2_rtl_clair`, `elv_err_hors_ligne_320x2_rtl_sombre`, `elv_err_hors_ligne_390_rtl_clair`, `elv_err_1440_rtl_sombre` et `elv_err_hors_ligne_1440_rtl_clair`, et je les ai comparées à `DASH-ELV-ERR-b/elv_err_1440_sombre` (LTR).

- **Miroir correct.** L'icône d'état est à droite, le texte aligné à droite, le bouton « Réessayer » à gauche. Dans la tuile Coran, l'icône livre est à droite et le chevron pointe vers la gauche. Le bandeau hors ligne est en haut, icône à droite.
- **Aucun mot coupé ni tronqué** à 320 px texte ×2, en clair comme en sombre.
- **Aucun bouton grisé** : « Réessayer » est actif dans tous les cas.
- **Hors ligne** : le titre « Tes cours ne sont pas disponibles » s'affiche et le bandeau de PageShell est unique, conforme à EA-HL-DOUBLE-1.
- Le mode Interface guidée n'est pas pertinent ici : l'écran est l'accueil élève standard, et la réserve ne le demandait pas.

## Réserves (mineures)

1. **DASH-LIB.** `eleve.accueil.erreurCours` et `eleve.accueil.erreurCoursHorsLigneTitre` restent des rédactions de l'agent, que le directeur doit valider. L'étape ne les a pas modifiés, et c'est bien ce qui était demandé.
2. **Affirmation inexacte du rédacteur sur l'arabe.** Le compte rendu dit qu'avec la locale arabe, les textes seraient en arabe et que le point ne serait plus en tête de ligne. C'est faux : `ar.i18n.json` ne contient **aucune** de ces deux clés. En arabe, l'utilisateur verrait donc le français dans une mise en page RTL, c'est-à-dire exactement le rendu des captures (« .dans un instant »). Ces deux clés devront être traduites en arabe une fois DASH-LIB validé.
3. **Tuile « Le Coran » à 1440 px.** Son contenu n'occupe que la moitié de la carte, chevron au milieu, et la carte d'erreur est moins large que la tuile. Le défaut existait déjà en LTR et le rédacteur l'a déclaré. Il est hors périmètre et devrait faire l'objet d'une étape séparée.

## Conclusion

La réserve « aucune capture RTL » de DASH-ELV-ERR-b-R est levée, avec des preuves reproductibles et un contrôle de sens qui détecte bien une régression. La branche peut avancer. La validation des deux libellés reste attachée à DASH-LIB.
