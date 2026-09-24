---
name: feedback-mobile-first-proof
description: "PISI/general - verifier L'EXPERIENCE pas ses fixes : audit UI = viewport mobile 390x844 + preuve visuelle de CHAQUE ecran + tester les flux de bout en bout (taper, sauver, recharger). Un tsc vert + 0 erreur console ne suffit JAMAIS."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 208e568c-9a8d-4823-8f5a-84a7803fb38d
  modified: 2026-09-11T20:50:38.493Z
---

# Vérifier l'expérience, pas ses propres fixes (rebuke proprio PISI 11/06)

Après la vague 1 (causes racines lecteur/SVG réparées), j'ai déclaré victoire alors que
restaient : notes 100% mortes sur mobile, onglets dashboard chevauchés, streak supprimé,
badges sur les titres, pages « vides » au scroll. Le proprio a dû lister lui-même les bugs.

**Why :** j'avais audité dans un viewport 683px (ni mobile ni desktop), vérifié uniquement
les écrans touchés par MES fixes, et accepté « 0 erreur console » comme preuve de santé.
Presque tous les étudiants PISI sont sur mobile.

**How to apply :**
- Tout audit/QA étudiant PISI : `browser_resize(390, 844)` D'ABORD, puis chaque écran
  avec capture regardée (pas seulement le DOM), y compris en scrollant jusqu'en bas.
- Tester les FLUX, pas les rendus : ouvrir les notes → taper → vérifier « Enregistré » →
  recharger → vérifier la persistance. Idem quiz, lecteur (currentTime avance), etc.
- Chercher les interactions mortes : `elementFromPoint` au centre des zones interactives
  (détecte les overlays/z-index qui interceptent les taps).
- Avant de réécrire une page : inventorier les composants existants (git log + imports) ;
  la « réécriture » 670d82f avait jeté StreakHero/WeekCalendar/DashboardTabs encore présents.
- Pièges récurrents PISI : (1) style inline qui écrase les règles CSS (icônes, z-index sn2) ;
  (2) espace avalé par flex + séparateurs SSR React → toujours un template literal unique ;
  (3) un push ne déclenche pas toujours Vercel → `npx vercel ls`, commit vide au besoin.
- Rapport au proprio : chaque affirmation « réparé » = une preuve (capture ou mesure live).

- **Corollaire Flutter, mesuré le 11/09/2026 sur Rewayah** : `flutter_test` monte tout sur
  **800 × 600**, c'est-à-dire au gabarit **tablette** et plus court que n'importe quel
  téléphone. Neuf tests rouges sur dix-neuf venaient de là et accusaient le produit à tort
  (des `tap` sous la ligne de flottaison, un onglet qui n'existe qu'en mobile). Tout test
  d'écran fixe sa fenêtre : `tester.view.physicalSize = const Size(390, 844)` +
  `devicePixelRatio = 1` + `addTearDown(tester.view.reset)`. Détail dans
  [[rewayah-remise-au-vert-2026-09-11]].

[[pisi-agent-readiness-2026-06-10]] [[feedback-no-invent-best-apps]] [[feedback-agents]]
[[rewayah-remise-au-vert-2026-09-11]]
