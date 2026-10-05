<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse : DUREE-INSECABLE-3 (`origin/corrections/c2-duree-3`, 3ab9e169)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Les quatre réserves de DUREE-INSECABLE-2 sont levées, preuves à l'appui. Il ne reste aucun défaut majeur. Trois réserves mineures restent ouvertes, plus un défaut déjà connu et signalé.

Statut : tout est testé localement seulement. Rien n'a été testé sur staging ni déployé.

## Méthode
J'ai travaillé dans un worktree jetable, détaché sur la branche, puis je l'ai retiré. Un second worktree, de base (`origin/corrections/revue-directeur-2026-10`), m'a servi de point de comparaison ; il est retiré aussi. Je n'ai rien poussé. La base est bien un ancêtre de la branche. Le diff compte 65 fichiers : 29 dans lib/, aucun dans supabase/, .github/, pubspec, le thème ou le rendu du Coran.

## Contrôles
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_jetons` | 39, identique à la base |
| `verifier_revue` | 1568, identique à la base |
| Tests des 15 fichiers de test modifiés | +365 ~11, 0 échec |
| `test/features`, `test/core`, `test/widgets`, `test/accessibilite`, `test/teaching_core` (`--concurrency=2`) | **+5503 ~2228, tous passent** |
| Contrôle de source lancé sur l'ancien lib/ | 90 appels, **57 nus** : le chiffre du rédacteur est confirmé |

## Mutations (chacune annulée après usage)
| Mutation | Résultat |
|---|---|
| M1 : silence nu (`ligne_presence`) | 3 échecs |
| M4 : attente nue | 3 échecs |
| `dureeCarte` avec `dureeSeule` (ancre au milieu) | 2 échecs |
| `dureeEnPhrase` ancrée (dernière séance) | 1 échec |
| Rappel (cooldown) nu (`fiche_seance`) | 1 échec |
| Consentement nu | 2 échecs |
| `demandeActuelle` nue (`reglages_enfant`) | 2 échecs |
| `uniteSecondes` nue (`module_reglages_observation`) | 1 échec |
| Règles des minutes avec `insecable` au lieu de `valeurSeule` (ancre perdue) | 1 échec |
| `ancreSens` neutralisée | 8 échecs |
| `dureeCarte` avec `ancreSens` au lieu de `valeurSeule` | 0 échec, mais la mutation ne change rien : `dureeLisible` rend déjà la durée insécable |

## Les quatre réserves de DUREE-INSECABLE-2
1. **Contrôle appel par appel** : fait. `test/support/garde_durees.dart` remplace la fenêtre de 400 caractères par l'appel qui entoure directement le libellé. La liste des libellés se déduit de `fr.i18n.json`, et les alias sont suivis.
2. **Ancre de la carte de groupe** : fait. `dureeCarte` rend « Durée 45 min » sans U+200E, et un test le vérifie. La dernière séance est corrigée de la même façon.
3. **Durées restantes** : faites. Le contrôle de source couvre toutes les clés fr à durée, et les valeurs rendues du silence, de l'attente, des règles et du consentement sont testées.
4. **Captures** : faites. Il y a 18 PNG, aux bonnes dimensions (390x520, 1440x420, 320x520), sans aucun doublon md5. J'en ai ouvert quatre (390x2 sombre RTL, 1440x2 clair LTR, 320x2 sombre LTR, 1440x1 sombre RTL) : « 45 min » et « Cours dans 3 h 28 » restent sur une ligne et dans le bon ordre. L'Interface guidée ne s'applique pas à cette carte.

## Réserves restantes (mineures)
- **Ancre au milieu d'un libellé.** Il en reste dans `historique_controleur_page.dart` (meta « 18:00 · ‎12 min » et la ligne lue par les technologies d'assistance) et dans `vue_seance.dart` (« Classe A · ‎12 min restantes »). Un test jetable le prouve. Le contrôle de source ne voit pas ces cas, parce que la valeur passe par une variable intermédiaire. Ces cas existaient avant cette étape et l'effet visuel est nul. La consigne « sinon la retirer » n'est donc pas appliquée partout.
- **Unités hors durée encore sécables.** Les âges (`{max} ans`), les tailles (`{taille} Mo`) et les pourcentages (`{valeur} %`) n'entrent pas dans la liste d'unités du contrôle.
- **Test du rappel.** Il ne vérifie que la fonction `insecable`. Le contrôle de source, lui, couvre bien l'écran.
- **Défauts déjà connus.** En RTL, la ponctuation française reste inversée (réserve 4 antérieure). À 1440 px, la carte s'étire sur toute la largeur.
