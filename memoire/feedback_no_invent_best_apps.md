---
name: feedback-no-invent-best-apps
description: "Feedback PISI/rewayah: ne rien inventer (regles, chiffres, features), s'inspirer des meilleures apps, tester via l'UI reelle, ne pas sur-questionner."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b8d96967-1142-4771-b8df-188c584a1501
---

# Ne rien inventer - s'inspirer des meilleures apps - tester pour de vrai

Sur les projets de ce user (PISI/Rewayah notamment), il a explicitement et fermement demande :

- **Ne JAMAIS inventer de regles, chiffres ou conditions** (ex: une IA precedente avait invente une commission d'affiliation '2%' et 'a vie' jamais decidees -> l'a mis en colere). Si une valeur n'est pas connue/decidee, NE PAS la coder en dur : la laisser a la source (ex: Creem) ou demander.
- **S'inspirer des meilleures applications** du domaine (Udemy, Coursera, Google...) AVANT de proposer : aller voir ce qu'elles font et comment, puis proposer. "fais comme les meilleures app, tu n'inventes rien."
- **Tester via le vrai parcours UI**, pas seulement en accedant aux pages par URL directe. Une fonctionnalite non atteignable par l'UX = inexistante. (J'avais audite des pages joignables seulement par URL sans voir qu'aucun menu n'y menait + nav mobile dupliquee evidente -> reproche justifie.)
- **Ne pas sur-questionner** quand il a deja donne la direction ("arrete de me fatiguer"). Decider raisonnablement et avancer, montrer des resultats. Mais ne pas non plus partir sur des suppositions non validees pour les choix produit a fort impact.

**Why:** il a perdu des semaines avec des agents qui inventaient, ne testaient pas, et ratait l'evident. Confiance fragile.

**How to apply:** rechercher les references reelles -> proposer concretement -> construire -> verifier dans le navigateur (idealement prod) avec preuve -> rapporter honnetement (y compris les manques). Pas de chiffres/regles sortis du chapeau.

[[pisi-audit-remediation-2026-05-30]] [[feedback-agents]]
