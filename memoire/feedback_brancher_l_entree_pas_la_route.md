---
name: feedback-brancher-l-entree-pas-la-route
description: "Un écran n'est livré que si quelque chose y mène. Vérifier l'entrée dans la navigation, pas l'enregistrement dans le routeur — sinon l'utilisateur dit à juste titre « rien n'a changé »."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 409ba240-ea8f-4468-ac47-e83809244335
  modified: 2026-09-18T11:18:29.974Z
---

# Un écran livré est un écran **atteignable**

Le 18/09/2026 sur Rewayah, l'opérateur a signalé : « sur l'app je ne vois rien
de nouveau, absolument rien n'a changé sur l'interface depuis près d'une
semaine ». **Il avait raison**, alors que l'écran était bel et bien compilé,
déployé et présent dans le bundle en ligne.

Mesure : `adminAccesAgents` n'apparaissait que **deux fois** dans tout `lib/` —
sa déclaration dans `routes.dart` et son enregistrement dans `app_router.dart`.
**Zéro** entrée de navigation. L'écran n'était atteignable qu'en tapant son URL
à la main. C'était la seule route admin dans ce cas.

**Pourquoi :** avoir enregistré la route donne la sensation d'avoir fini. Les
tests passent, `dart analyze` est vert, le bundle contient l'écran, l'URL rend
200. **Tous les signaux disent livré, et l'utilisateur ne voit rien.**

**Comment l'appliquer :** à la fin de tout lot qui ajoute un écran, compter les
références à la route **hors** du fichier de routes et du routeur. Zéro
référence = l'écran n'existe pas pour l'utilisateur. Le balayage coûte une
commande :

```powershell
# routes déclarées, puis celles que rien n'atteint depuis un écran
$routes = Select-String lib\core\router\routes.dart -Pattern "static const String (\w+)\s*=" |
          ForEach-Object { $_.Matches[0].Groups[1].Value }
# ... compter "Routes\.<nom>\b" dans lib\ SAUF routes.dart et app_router.dart
```

⚠ **Deux faux positifs à connaître** avant d'annoncer un chiffre : une route
peut être atteinte par une **fonction intermédiaire** (`appairerPour(id)`,
`compteProfilEnfantPour(id)` — le `\b` de la regex ne matche alors pas) ou par
une **redirection de rôle** (`Routes.racinePour(role)`, qui vit dans
`routes.dart`, justement le fichier exclu). Sur 38 routes, le balayage brut en
signalait 5 ; après vérification il n'en restait **qu'une**, la mienne. Ne
jamais annoncer le chiffre brut : vérifier chaque candidat d'abord.

⚠ **Corollaire de plafond** : quand la barre de navigation est plafonnée (ici
quatre destinations pour l'admin, `03-architecture-information` section 5, avec
un `assert`), l'entrée se pose sur l'écran d'accueil du rôle, pas dans la barre.

Voir aussi [[rewayah-agt01-acces-agent-2026-09-18]],
[[feedback-mobile-first-proof]] (vérifier l'expérience, pas ses fixes),
[[feedback-chiffrer-avant-de-proposer]].
