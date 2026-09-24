---
name: feedback-chiffrer-avant-de-proposer
description: "Chiffrer l'ecart avant de proposer un remede - un correctif plausible qui ne comble pas l'ecart mesure n'est pas un correctif"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ed89019b-649b-403b-8214-668f32958a50
  modified: 2026-08-18T10:14:58.633Z
---

Avant de proposer un correctif pour un defaut d'interface, MESURER l'ecart, puis
verifier que le remede propose le comble reellement. Un remede plausible qui ne
ferme pas l'ecart chiffre est un faux correctif, et il coute la confiance quand
on s'en apercoit apres coup.

**Why:** le 18/08/2026 sur la console admin PISI, j'ai annonce « retirer deux
entrees de la zone Cours libere les 78 px qui cachent la zone Mesure ». Mesure
faite ensuite sur la vraie page : le contenu du `<nav>` faisait 463 px pour une
boite de 327 px, soit **136 px** sous le pli. Retirer deux entrees rendait 78 px
- il en serait reste 58. Le remede etait proportionne a mon impression, pas a
l'ecart. Le vrai defaut n'etait meme pas la hauteur : c'etait qu'un panneau qui
deborde ne le disait pas.

Deux autres affirmations du meme audit sont tombees a la mesure :
- « line-height 1.5 sur tous les titres » -> ZERO titre declarait >= 1.4 ; le
  probleme etait l'HERITAGE de `body`, pas une declaration.
- « espacements hors grille 7/11/13/15/22 » -> la grille reelle est de 2 px (pas
  4), respectee a 89 %, et 22 est DEDANS.

**How to apply:** avant d'annoncer un lot de correction UI, ecrire un script
d'inventaire qui compte les valeurs reelles dans le code (ou mesurer dans le
navigateur via `getBoundingClientRect` / `scrollHeight`), puis poser
explicitement : « ce remede comble-t-il l'ecart mesure ? ». Si non, le dire et
changer de remede. Rapporter la rectification de ses propres affirmations
plutot que de les laisser passer. Voir [[feedback_mobile_first_proof]] et
[[pisi_purge_admin_2026-08-17]] (code mort prouve par fermeture du graphe
d'imports, jamais par grep - meme piege, meme parade).
