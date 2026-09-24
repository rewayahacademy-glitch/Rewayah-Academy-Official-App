---
name: feedback_preciser_branche_push
description: Toujours nommer la branche exacte quand on rapporte un push — surtout main
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ce33078c-c43c-4f57-8811-0aed40eb2118
  modified: 2026-09-20T23:11:04.428Z
---

Ne jamais dire « tout est poussé » sans préciser la branche exacte, surtout quand le travail vit sur
une branche d'intégration et que `main` n'a rien reçu.

**Why** : le 21/09, après avoir poussé Teaching Core sur `integration/teaching-core`, j'ai annoncé
à l'opérateur que « tout est poussé » sans qualifier la branche. L'opérateur a dû corriger : « main n'a
rien reçu depuis une journée, ce que tu as fait se trouve sur des branches différentes. » L'information
exacte était déjà dans ma mémoire ([[rewayah_teaching_core_2026-09-20]] le disait noir sur blanc), mais
le résumé oral donné en fin de session l'a effacée.

**How to apply** : dans tout message de fin de tâche ou de statut, si le travail est poussé sur une
branche autre que `main` (ou autre que celle que l'opérateur regarde), le dire explicitement — nom de
branche + état de `main` par rapport à elle (« en avance de N commits, pas encore fusionné »). Ne
jamais laisser « poussé » sous-entendre « visible sur main » implicitement.
