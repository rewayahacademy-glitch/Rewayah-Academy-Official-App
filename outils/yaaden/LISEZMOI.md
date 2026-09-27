# YAADEN : logistique du tableau sans IA

Un script Node, sans dépendance, par poste. Il ne fait ni réseau ni git, n'exécute
jamais un texte lu, et n'écrit que dans `<racine>/yaaden-cache` (hors dépôt).

## Ce qu'il fait
- **Relais au fil de l'eau** : Claude écrit une ligne `@Y …` (voir `YAADEN_RULES.md` §1).
  Le hook Stop la lit dans le journal de session, la valide (vocabulaire fermé,
  600 caractères au plus, hors bloc de code, jamais un message utilisateur ni un
  résultat d'outil), déduplique et la met en boîte.
- **Envoi** : `node yaaden.mjs envoyer` prépare un lot (≤ 50 écritures, identifiants
  neufs et déterministes, donc rejouables sans doublon) ; Claude fait UN
  `ArtifactData batch` ; puis `recu <lot>` (journal) ou `echec <lot>` (remis en boîte).
  PLUS_TARD devient une étape « À faire plus tard » visible au tableau ; QUESTION
  un dépôt « nouveau » ; REGLE une règle candidate ; RELAIS la collection `relais`.
- **Réveil** : hooks SessionStart et « continuer » → paquet de reprise
  (7 lignes d'état + ces règles, ~1 500 tokens) au lieu de relire le tableau.
- **Ménage** : après une lecture fraîche (≤ 15 min) des collections avec `out_dir`
  dans `yaaden-cache/tableau`, `nettoyer` propose l'archivage des seules étapes
  `verifie` et dépôts `traite` (copie d'archive avant retrait, même lot) et signale
  les champs de « Maintenant » trop longs, que Claude condense.
- **Réveil après limite** : `reveil [uuid-session]` lit l'heure exacte de remise à
  zéro (resetsAt émis par Claude Code), +2 min, et programme la tâche Windows
  `YAADEN-reveil` qui rouvre la session avec « continuer ». `reveil-annuler` la retire.

## Limites connues (lot 0, 27/09)
- Le tableau n'est pas accessible depuis `claude -p` (outils Artifact absents en
  mode non interactif) : l'envoi passe par une session ouverte, en un appel.
- Aucun réveil entre machines sans IA : le tableau est le seul canal commun.
- La suppression d'archive n'est pas épinglée par version : seules les lignes
  closes (verifie, traite) sont concernées, lues il y a moins de 15 min.

## Installation d'un poste
1. `node <pilotage>/outils/yaaden/yaaden.mjs init B <racine> [autre dossier de travail]`
2. Dans `~/.claude/settings.json`, hooks `SessionStart` (hook-start),
   `UserPromptSubmit` (hook-prompt) et `Stop` (hook-stop) :
   `node "<pilotage>/outils/yaaden/yaaden.mjs" hook-…`, timeout 10.
3. Tests : `node --test <pilotage>/outils/yaaden/yaaden.test.mjs`.
