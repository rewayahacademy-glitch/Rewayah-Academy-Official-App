<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Revue adverse PAGESHELL-200-1d (branche `corrections/c2-pageshell-d`, tête ea70037d, base 6e2c91c4)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Les cinq points demandés sont remplis et chacun est prouvé par une mutation. Il me manque une seule preuve : la relance de régression large sur les dossiers features, core et router.

Statut du lot : testé localement seulement. Rien n'est testé sur staging ni déployé.

## Ce que j'ai fait
- J'ai créé un worktree jetable détaché sur origin/corrections/c2-pageshell-d, plus un second worktree pour les mutations (retiré depuis).
- Je n'ai rien poussé, et aucune zone interdite n'est touchée : supabase, .github, pubspec, thème, rendu du Coran.
- La décision est datée et marquée « décidé par délégation le 05/10 » dans deux endroits : `03_DESIGN_SYSTEM_ET_UX.md` (paragraphe « Coquille de page (PageShell) et texte agrandi ») et la fiche de `REVUE-DIRECTEUR-2026-10.md`.
- L'ancienne règle « barre entière au premier affichage à 200 % » est explicitement remplacée. Aucune autre mention ne la contredit dans docs/current.

## Contrôles
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1550, égal à la base.
- `verifier_jetons` : 39 violations, toutes antérieures et aucune dans les fichiers touchés.
- `flutter test --concurrency=2 test/widgets test/teaching_core/g` : +960 ~192, tout passe.
- Les deux commits se terminent exactement par les deux lignes d'attribution demandées.

## Mutations (correction annulée, les tests doivent échouer)

| Point | Mutation | Résultat |
|---|---|---|
| 1. Vignettes | `page_shell.dart` et `panneau_observation_tuteur.dart` remis à la base (le repère revient) | 16 échecs : les 14 cas du groupe « les vignettes défilent avec la page » (7 vues, LTR et RTL), plus 2 tests de page_shell_hauteur_corps |
| 2. `_hauteurMinSupport` | `minimumEtire` du téléphone remis à `AppTouchTarget.standard` | 3 échecs (salle_support_agrandi_test) |
| 2. `_hauteurMinSupport` | `minimumEtire` de la carte large remis à `AppTouchTarget.standard` | 4 échecs (2 dans salle_support_agrandi, 2 dans le groupe « support agrandi ») |
| 5. `_vueForcee` | `_revenirTeteFixe` rendu sans effet | 2 échecs (« un corps qui rapetisse », « sous une boîte de dialogue ») |
| 5. Attente des animations | attente des animations supprimée | page_shell_hauteur_corps passe encore (le rédacteur l'avait annoncé) ; fin_visite_test 844x390 light/dark échoue (2) |
| 5. Revérification des sources | revérification supprimée | 2 échecs : « barre large sans mot coupé 1024x900, texte x3 » LTR et RTL |
| 4. Compteur | `compteur_visite.dart` de 397ef11d | 10 échecs dans le groupe « bandeau du décompte sans débordement » |

Sur le point 4 : la correction venait déjà de PAGESHELL-200-1c. Elle est prouvée et protégée, en LTR et RTL, à 320x568 à 200 %, avec contrôle des mots coupés.

Sur le point 2 : `_hauteurMinSupport` n'est pas redondant. Avec « Agrandir », le support est seul dans la zone, sans défileur. Il est donc gardé et protégé.

## Captures ouvertes
J'ai ouvert les captures 1440x900 claire et sombre, 390x844 à 100 % (claire LTR, sombre RTL), 320x568 à 100 % (standard en haut et au bout, Interface guidée RTL au bout), 320x568 à 200 % sombre RTL au bout et 390x844 à 200 % Interface guidée au bout.

- **1440x900** : la barre est entière au premier affichage, sans régression visible.
- **390x844 à 100 %** : la salle tient sans défiler. Les captures haut et bout sont identiques, comme attendu.
- **Au bout de la page** : on voit le support, les deux vignettes entières, puis la barre entière au-dessus de la zone sûre.
- Aucun mot coupé, aucun bouton grisé.

## Réserves
1. Je n'ai pas fini de relancer moi-même la régression large (test/features, test/core, test/router). Le rédacteur la déclare verte. Elle est à relancer avant la fusion, puisque `_Bascule` concerne toutes les pages.
2. Mineur, sans effet aujourd'hui : le retour à la tête fixe attend que les animations s'arrêtent. Sur une page où une animation tourne sans fin, il ne se ferait jamais. Seule la salle d'observation est concernée et elle n'a pas d'animation en boucle.

Le worktree de revue rv-PAGESHELL-200-1d-80 portait encore la relance en arrière-plan au moment du verdict : il reste à le retirer.
