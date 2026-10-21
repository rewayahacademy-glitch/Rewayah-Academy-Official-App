# Sessions dédiées et choix du modèle

**Directeur, 10/10/2026.** Le travail est trop lent et encore trop manuel. L'orchestrateur ouvre une session dédiée par lot, lui envoie sa mission et suit son avancement. Le tableau (`etapes`) reste le seul registre de qui fait quoi. Le directeur demande aussi d'économiser les jetons : on ne prend pas toujours le modèle le plus cher.

## Qui fait quoi

| Rôle | Où | Modèle |
| :--- | :--- | :--- |
| Orchestrateur : tableau, fusions dans `ccr`, arbitrages, revue du backend de ChatGPT | session principale | Opus |
| Lot d'écran, de texte, de traduction, de tests | session dédiée ou sous-agent | Sonnet |
| Vérificateur non auteur d'un lot d'écran (K-60.4) | sous-agent | Sonnet |
| Vérificateur ou auteur d'un lot de sécurité : garde-fou, RLS, script PROD, PR de ChatGPT | sous-agent | Opus |
| Tâches mécaniques : relevé de tableau, comptage, mise en forme | sous-agent | Haiku |

On monte d'un cran seulement quand le lot l'exige : un conflit de fusion difficile, une faille, ou un échec du modèle moins cher sur le même lot.

## Déroulé d'un lot en session dédiée

1. L'orchestrateur réserve l'étape au tableau (`if_version`).
2. Il crée la session : dépôt, branche `claude/<lot>` partie de `ccr`, modèle choisi selon le tableau ci-dessus.
3. La mission envoyée tient en une page : la fiche, les fichiers permis, les preuves attendues, l'interdiction de pousser ailleurs que sur `claude/<lot>`.
4. La session code, vérifie (`dart run slang`, `build_runner`, `dart analyze --fatal-infos`, `flutter test`, `verifier_jetons`, `verifier_revue`), pousse sa branche et répond par message : tête, chiffres, écarts.
5. Un vérificateur non auteur rejoue. Si c'est oui, l'orchestrateur fusionne `--no-ff` dans `ccr`, pousse, met à jour le tableau et archive la session.

Le garde-fou (`.claude/hooks/garde.py`) s'applique à chaque session et à chacun de ses agents.

## Économie

- Les missions sont courtes et renvoient aux documents au lieu de les recopier.
- Les vérificateurs lancent les tests des dossiers touchés ; la suite complète tourne une fois, avant la fusion.
- Pas de suivi par sondage : les sessions répondent par message quand elles ont fini.
