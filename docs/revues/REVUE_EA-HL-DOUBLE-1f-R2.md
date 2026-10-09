<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Revue adverse EA-HL-DOUBLE-1f (reprise) : branche corrections/c2-hl-double-f, commit dc03aee3

**Verdict : ACCEPTEE_AVEC_RESERVES.** La demande est remplie. Aucun défaut majeur n'est prouvé. Il reste deux réserves mineures et une cosmétique.

## Périmètre vérifié
- La base 5a52ff30 est bien ancêtre de la branche. Quatre commits : 3c60b313, cc3f3729, 3da0de5a, dc03aee3. Chacun se termine exactement par les deux lignes d'attribution demandées. Aucun identifiant de modèle n'apparaît ailleurs dans le diff.
- Aucune zone interdite n'est touchée : supabase/, .github/, vercel.json, pubspec.yaml, thème, Coran, dart_define.

## Textes (fr.i18n.json)
- `agent.indisponible` et `agent.indisponibleDetail` : « Service indisponible » et « L'ouverture de session n'a pas répondu » deviennent « L'ouverture n'a pas abouti » et « Il est possible que la demande ne soit pas parvenue jusqu'à Rewayah. Réessayez dans un instant. »
- `adulte.accueil.echec` et `adulte.historique.echec` (séances prochaines et passées) : ces textes utilisaient déjà la formulation unique depuis 1e. Leur statut de source est passé à « validé par délégation le 09/10 ».
- Textes réécrits par l'étape :
  - `salle.refusReseau` et `salle.refusReseauDetail` ;
  - `tc.bibliotheque.indisponible.message`, plus une nouvelle clé `invitation` ;
  - `tc.observation.refus.indisponible`, plus une nouvelle clé `indisponibleInvitation` ;
  - `tc.observation.disponibilite.capacite` et `classe.observation.motif.capaciteAbsente`, qui disent maintenant l'effet seul ;
  - `classe.entree.indisponible`, avec une espace insécable devant le deux-points ;
  - `copieImpossible` et `fuseauIndisponible`.
- 14 entrées de `tool/libelles_sources.json` portent « validé par délégation le 09/10 (DIR-REP-1) ; décidé par délégation le 09/10 ».
- Le doc 03 est aligné. Il reprend la règle, la liste des titres et les exceptions nommées clé par clé.
- J'ai fait ma propre recherche dans tout le catalogue sur « répondu », « indisponib », « (pas|non) disponible », « momentan », « pour le moment », « pour l'instant » et « serveur ».
  - Les 5 exceptions des dossiers sont légitimes : je l'ai vérifié dans le code. File, détail et décision ne sont affichés que sur `CapaciteIndisponible`, le hors ligne étant traité avant. La pièce et la validation n'apparaissent que quand la capacité est fermée.
  - `attenteAdministration` désigne une personne, pas une panne.
  - **Réserve 1 :** `tc.classe.attente.refus` (« Le cours n'est pas accessible pour le moment ») a été manqué, et le motif de la garde ne l'attrape pas. Il est servi par la Classe Live, sans entrée sur main.

## Code
- **Agent :** le bouton Réessayer apparaît (ActionPrincipale secondaire, jamais grisée) sauf quand le jeton est refusé. Il passe par `relancerOuvertureAgentProvider` (location.reload sur le web, sans effet ailleurs).
- **Observation :** la phrase de cause probable n'apparaît que si `seReessaye`. Le cas `hasError` du flux d'états propose maintenant Réessayer (`ref.invalidate`).
- **Fiche de groupe :** la carte passe en `RegistreVide.actionnable` sur erreur. Avant, le bouton Réessayer était masqué.
- **Salle :** encre du fond (`_EncreDuFond`) pour « Votre présence » et pour l'impasse.
- **Bibliothèque :** invitation dans la liste et dans le détail ; `hintMaxLines: 3`.
- **Autre appelant de `classe.entree.indisponible` :** `EmplacementEntree` dans `CarteSession`. J'en ai fait des captures jetables à 390, 1440 et 320 x2, en LTR et RTL, en clair et en sombre. Aucun mot n'est coupé et le bouton Réessayer est présent. Ce rendu n'est pas dans les captures du rédacteur (**réserve 2**).

## Garde du catalogue
`motifCauseAffirmee` couvre :
- « n'a pas répondu », « ne répond pas » ;
- « service|serveur|… indisponible », « momentanément|temporairement indisponible » ;
- « (indisponible|pas disponible|non disponible) pour le moment|l'instant ».

Seules des exceptions nommées clé par clé passent. La formulation unique est exigée sur 7 clés, et l'absence de « connexion|réseau » sur 9 clés situées sous le bandeau.

## Mutations (faites réellement, puis annulées)
| Mutation | Résultat |
|---|---|
| JSON : ancien `agent.indisponibleDetail`, ancien `capaciteAbsente`, plus une clé « Le service est momentanément indisponible » | la garde échoue et liste les clés fautives |
| fiche_groupe_page.dart ramené à la base | 1 échec |
| entree_observation_page.dart ramené à la base | 4 échecs |
| salle_page.dart ramené à la base | 4 échecs |
| surface_bibliotheque.dart et detail_ressource_page.dart ramenés à la base | 3 échecs |
| agent_entree_page.dart ramené à la base | 4 échecs |

## Contrôles
- `dart run slang` : aucune différence.
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : 37 violations, au seuil (≤ 37).
- `verifier_revue` : 1529 violations (base annoncée par le rédacteur : 1533).
- `flutter test --concurrency=2 test/features test/core test/teaching_core test/router` : +5503 ~2399, **tous passés**.

## Captures ouvertes
- Fiche de séance : 320 x2 clair, 390 en ligne, 1440.
- Observation : 320 x2 RTL sombre.
- Agent : 320 x2 LTR et RTL.
- Salle : 1440 clair, 320 x2 clair, 320 x2 RTL sombre, 390 sombre.
- Bibliothèque : 390 sombre.

Constats :
- Aucun mot coupé ni tronqué, aucun bouton grisé. Le bandeau n'est pas redit, et le sablier ou l'avertissement remplace le « wifi barré ».
- La ponctuation inversée en RTL vient d'un défaut connu et antérieur (texte français dans un sens RTL).
- À 320 x2, la salle montre la pastille de présence seule. C'est le mode compact prévu, avec le libellé porté par la sémantique.
- L'Interface guidée n'est pas concernée : agent, observation du tuteur et fiche de groupe sont des écrans d'adulte.

## Réserves
1. *(Mineure)* `tc.classe.attente.refus` : « … pas accessible pour le moment » n'a pas été traité, et la garde ne connaît pas « accessible ».
2. *(Mineure)* La carte de séance de l'espace de groupe n'a pas de capture de preuve. Mon contrôle n'y trouve aucune coupure, mais le texte est long : 9 lignes en titleMedium à 320 x2.
3. *(Cosmétique)* Dans la fiche de groupe, la cause probable est dans le message en style titre au lieu de l'invitation : 14 lignes en gras à 320 x2.

Le worktree jetable a été retiré. Rien n'a été poussé.
