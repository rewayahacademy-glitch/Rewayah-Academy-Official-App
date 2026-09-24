---
name: feedback-sonnet-for-easy-tasks
description: "Choisir le modèle des agents selon la difficulté — sonnet pour les tâches faciles afin d'économiser les tokens."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 50dc0207-3d8a-4e49-acad-497b8ab48d25
---

Quand une tâche (notamment déléguée à un sous-agent) est **peu difficile / mécanique**, assigner le modèle **sonnet** plutôt qu'opus.

**Why:** économiser le budget tokens (cf. [[feedback-token-economy-opencode]] — le propriétaire surveille la consommation Claude de près).

**How to apply:** au spawn d'un agent (`model: "sonnet"`), réserver opus aux tâches vraiment complexes (design distinctif, raisonnement architectural lourd, sécurité critique). Tâches mécaniques (CRUD, câblage UI répétitif, refactors guidés, drag-reorder, formulaires) → sonnet. En cas de doute sur la difficulté, défaut = sonnet. Vu en pratique : refonte hub PISI tranche 3b livrée par 2 agents Frontend sonnet en parallèle. Lié à [[feedback-agents]].
