---
name: feedback-agent-ro-jamais-sur-rpc-ecriture
description: "Sur Rewayah Academy, ne jamais grant execute à agent_ro sur une RPC d'écriture (volatile) — seulement sur des fonctions de lecture (stable/immutable) ; sinon un jeton d'agent en lecture seule peut écrire dès que la personne observée est admin"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0ac23a86-c718-4781-a9b3-95031609987f
  modified: 2026-09-19T12:51:46.353Z
---

**Règle** : sur le projet Rewayah Academy, `grant execute ... to agent_ro`
ne doit **jamais** viser une fonction `volatile` (donc toute fonction
`plpgsql` sans `stable`/`immutable`, en particulier toute RPC qui fait un
`insert`/`update`/`delete`). Seules les fonctions de lecture
(`language sql stable` ou `immutable`) peuvent recevoir ce grant.

**Pourquoi** : l'architecture posée par `0014_acces_agent.sql` (lot AGT-01)
construit le rôle `agent_ro` comme l'intersection stricte « appelable par
`authenticated` » ET « stable/immutable » — jamais volatile — précisément
pour qu'un jeton d'agent (accès en lecture seule borné dans le temps sur le
parcours d'une personne observée) **ne puisse structurellement rien
écrire**, quel que soit le rôle de la personne observée. Le 19/09, le lot
G-01 (voir [[rewayah_pivot_groupes_2026-09-19]]) a grantée `agent_ro` sur
cinq nouvelles RPC d'écriture (`creer_groupe`, `modifier_groupe`,
`ajouter_eleve_groupe`, `retirer_eleve_groupe`, `cloturer_groupe`) en confondant
deux leçons : celle de 0014/0015/0016 (« accorder `agent_ro` explicitement, il
ne l'a pas par défaut ») ne concernait que des fonctions de **lecture**
(`comptes_admin`, `dossiers_en_attente`...). Le trou trouvé par la revue de
code : si la personne observée par un agent est administratrice, l'agent
censé être en lecture seule pouvait créer/modifier/clôturer des groupes et
ajouter/retirer des élèves. `mcp__supabase__get_advisors(security)` **ne
détecte pas ce trou** : c'est un invariant maison (I2 de 0014), pas un lint
générique Supabase — il faut le vérifier par une requête directe
(`has_function_privilege('agent_ro', oid, 'EXECUTE')`) ou en lisant le grant
de la fonction sœur la plus proche déjà en production.

**Comment appliquer** : avant tout `grant ... to agent_ro` sur une RPC
nouvelle, vérifier sa signature (`language ... volatile|stable|immutable`
dans le `create function`). Si elle écrit (insert/update/delete), ne
grantée que `authenticated` — jamais `agent_ro`, même si une fonction sœur
de lecture du même lot en a besoin. En cas de doute, chercher la fonction la
plus proche déjà en production (ex. `attribuer_eleve` pour toute RPC
d'attribution/affectation) et copier exactement son couple
`revoke .../grant ...`, pas seulement sa logique métier.
