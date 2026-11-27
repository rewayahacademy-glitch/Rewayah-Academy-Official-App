---
name: praxis-rewayah
description: Le personnage Praxis de Rewayah Academy (l'assistant IA de la direction, visage de la communication dans l'application, le chat et les réseaux sociaux) - son dessin de référence, ses mesures, ses couleurs, ses expressions, ses gestes, sa lumière, et la marche à suivre pour le créer ou le recréer à l'identique. À lire AVANT de dessiner, animer, redessiner, exporter ou décrire Praxis, quel que soit le support - widget Flutter, avatar, image de profil, maquette, artefact, SVG, HTML, visuel pour un réseau social, illustration, sticker, vidéo. À lire aussi avant de lui faire dire une phrase à l'écran. Évite un Praxis différent d'un écran à l'autre, des yeux modifiés, une toque qui rentre dans le visage, des couleurs hors palette.
---

# Praxis, le personnage

Version du 20/11/2026. Source de vérité : ce dossier. Le dessin de référence est du code
(`reference/source/entree_praxis.dart.txt`) : on ne redessine jamais Praxis de mémoire ni à l'œil, on
part de ce code ou des mesures ci-dessous, et on compare le résultat aux planches de `reference/planches/`.

Praxis est le même personnage partout : dans l'application, dans le chat, dans les maquettes, sur les
réseaux sociaux. Directeur, 20/11/2026 : « praxis doit rester cohérent parce qu'il sera le visage de
la communication sur les réseaux sociaux et dans le chat, et l'app ».

## 1. Ce qui est décidé (directeur, dates)

| Règle | Décision |
| :--- | :--- |
| **Les yeux sont sa signature.** Deux ovales d'encre, une pupille blanche. Ils ne changent ni de forme, ni de taille, ni de place. Ils clignent, c'est tout. | 20/11/2026 : « tu as modifié les yeux, je ne suis pas d'accord […] c'est une signature pour lui » |
| **Seuls les membres et la bouche s'ajoutent** au dessin d'origine : deux mains, deux pieds, une bouche. Aucun sourcil, aucun nez, aucune oreille, aucun cil. | 20/11/2026 : « Oui pour l'ajout des membres et la bouche mais pas pour le changement des yeux » |
| **La toque est posée sur le crâne.** Elle ne descend jamais dans le visage ; elle s'arrête au-dessus des yeux. | 20/11/2026 : « le bonnet est rentré dans le visage » (refusé) |
| **Couleurs : lavande, blanc, violet, encre.** Rien d'autre sur lui ni dans sa lumière. | 20/11/2026 : « les lumières c'est entre la lavande, blanc, violet » |
| **Sa lumière est un halo continu**, jamais des anneaux, jamais une plaque blanche. | 20/11/2026 : « un halo fluide qui ne se casse pas en anneaux » ; « le rectangle blanc […] doit être assimilé à la lumière » |
| **Le dessin en volume du 20/11/2026 est le Praxis de référence** (corps, membres, toque en volume). | 20/11/2026, sur la maquette version 2 : « Seul problème c'est le rectangle blanc » ; « son corps a changé avec l'ajout des membres, le bonnet aussi a changé » |
| **Son image de profil dans l'application porte ce nouveau visage.** | 20/11/2026 : « modifier son avatar de profil dans l'app dès maintenant avec son nouveau visage et ses mouvements » |
| **Dans la communication extérieure, Praxis est un acteur.** Il joue des scénarios avec la porte, la lumière et la route, et dialogue avec le directeur filmé (il montre, il attire, il pousse). Sa bibliothèque de gestes peut s'enrichir pour ces besoins ; ses yeux et son dessin ne changent pas. Sur les imprimables (fiches, factures, PDF), il est très discret ou absent ; sur les livrets codés dans l'application, il peut être présent. Flutter n'est pas requis hors de l'application. | 27/11/2026 : « il faut donner à Praxis un rôle qui joue des scénarios très avancés, qui utilise la porte, la lumière, la route et sa bibliothèque d'animation » ; « je dois interagir avec Praxis » ; « pour les imprimables Praxis ne doit pas y être très présent » (registre de marque, M-38) |

Ce qui n'est **pas** décidé, à présenter comme une proposition : le fond violet du portrait (l'autre
fond prêt est le lilas pâle) ; le nom des expressions et des gestes ; toute nouvelle pose, tout nouvel
accessoire, tout nouveau décor. Une nouveauté se montre au directeur avant d'entrer dans l'application.

## 2. La fiche de construction

Toutes les mesures sont dans une boîte de 200 unités de large (celle du dessin d'origine). Praxis se
pose par ses pieds : le point du sol entre ses deux pieds est en (100, 206).

**Le corps.** Une seule boule, qui est à la fois sa tête et son corps : centre (100, 108), rayon 86.
Peinte en volume par un seul dégradé (clair du côté de la lumière, lilas, lilas un peu sombre, ombre),
puis un liseré de contre-jour du côté de la source. Jamais un aplat quand il est en scène ; l'aplat
lilas reste permis pour une icône de moins de 24 points.

**Les yeux (inchangeables).** Deux ovales d'encre de 26 de large sur 36 de haut, centrés en (84, 128)
et (122, 128) quand il est de face. Dans chacun, une pupille blanche de rayon 6, au centre ; elle se
déplace d'au plus 5,5 unités pour suivre un regard. Le clignement ferme l'ovale le long de sa propre
hauteur (il reste un trait de 8,5 % de la hauteur) ; la pupille s'efface quand l'œil se ferme. Jamais
plus grands que cela, jamais plus ronds, jamais inclinés.

**La bouche.** Centre (103, 166). Fermée : un trait d'encre de 4 d'épaisseur, bouts ronds, large de 28,
courbé par le sourire (flèche de 7 unités au plus). Ouverte : une forme pleine d'encre, haute de 20 au
plus, avec une langue corail au fond. Ronde quand il s'étonne (12 à 22 de large).

**Les joues.** Deux touches corail très légères, seulement dans la joie et la gêne.

**La toque, en volume.** Construite dans le repère de la tête puis projetée (caméra en légère plongée,
0,27 radian) :
- la **calotte** d'encre épouse le haut du crâne ; son bord est le cercle de la boule situé à 0,54
  rayon au-dessus du centre, le long de l'axe de la toque ;
- l'axe de la toque penche un peu sur le côté (0,10) et en arrière (0,05) ;
- le **plateau** carré, lilas, cerné d'encre (trait de 4), est posé au sommet (1 unité au-dessus du
  crâne), ses coins à 68 unités de l'axe, tourné de 0,20 radian ; il a une tranche d'encre de 6 ;
- un **bouton** d'encre au centre du plateau, d'où part le **cordon** vers le coin de droite ;
- le **pompon** pend de ce coin : un fil de 29, puis un gland d'encre de 12 sur 19, coins arrondis.
  Il balance comme un pendule amorti quand Praxis bouge.
La toque peut se soulever (surprise, salut), jamais s'enfoncer.

**Les mains.** Deux boules lilas de rayon 19, peintes comme le corps, sans bras. Au repos, de part et
d'autre du corps, à hauteur de la bouche. Elles tournent avec lui et passent derrière quand il se
retourne. Une main devant le corps y porte une ombre de contact.

**Les pieds.** Deux ovales d'encre de 19,5 sur 8,8, sous le corps, écartés. Pas de jambes quand il
est debout.

**De dos.** Les yeux et la bouche glissent et disparaissent en vraie rotation ; la calotte et le
plateau tournent avec lui ; le corps est un peu plus sombre.

## 3. Les couleurs

| Rôle | Valeur |
| :--- | :--- |
| Lilas (le corps, les mains, le plateau) | `#DCCAFD` |
| Encre (yeux, toque, pieds, traits) | `#110E20` |
| Blanc (pupilles, cœur de la lumière en thème clair) | `#FFFFFF` |
| Violet du logo (fond du portrait, logo en thème clair) | `#8652E6` |
| Lavande (accent et logo en thème sombre) | `#BA98FB` |
| Lilas pâle (fond clair du portrait) | `#EEE6FA` |
| Corail (langue, joues, rien d'autre) | `#E0375A` en clair, `#FF8FA3` en sombre |

Dans l'application, ces couleurs viennent des jetons du thème (`AppPalette`), jamais d'une valeur
écrite en dur. Aucun ambre, aucun vert, aucun bleu sur Praxis ni dans sa lumière.

## 4. Les expressions et les gestes

Une expression ne touche que la bouche, les joues, l'ouverture des paupières et la posture. Les onze
expressions de référence : `neutre`, `sourire`, `joie` (bouche ouverte, joues), `etonne` (bouche
ronde), `reflexion` (bouche droite), `desole` (bouche tombante), `attente`, `paisible` (yeux fermés,
sourire), `gene` (sourire, joues), `concentre`, `baille`. Planche : `reference/planches/yeux-origine-et-canon.png`.

Quand il **signale un blocage** à la direction, il est sérieux, pas triste : il accueille la direction
chaque jour, un blocage qui dure ne lui donne pas un visage abattu. La bouche tombante est réservée à
une vraie erreur.

Les gestes de référence (mains, accessoires, posture) sont dans `reference/source/entree_textes.dart.txt`
(énumération `Geste`) et sur la planche `reference/planches/toque-angles-et-gestes.png` : salut, montrer,
réfléchir, chercher, regarder sa montre, lever un doigt, main sur le cœur, s'asseoir, balayer, bâiller,
applaudir, etc. Un accessoire (montre, balai, clé, étincelle) est tenu par une main, en encre et lilas.

Chaque phrase qu'il dit à l'écran va avec un geste et une expression : voir les répliques de
`entree_textes.dart.txt`.

## 5. Le mouvement

- **Du poids.** Un pied posé ne glisse pas. Il se lève quand le corps l'a dépassé d'un demi-pas, et se
  repose en avant. Jamais deux pieds en l'air. Le corps monte au passage, s'écrase au contact, roule
  vers le pied d'appui.
- **Des ressorts, pas des courbes.** Tout ce qui suit (tête, mains, toque, pompon) suit avec retard et
  dépasse un peu. Anticipation au départ, dépassement à l'arrêt.
- **Il vit au repos** : il respire (1,2 %), cligne, suit le pointeur ou le texte des yeux. Il
  s'endort quand rien ne bouge, et ne coûte alors plus aucune image.
- **Un demi-tour est une vraie rotation** : les traits glissent et se raccourcissent.
- **La vitesse ne dépend pas de l'appareil** : l'horloge avance du temps réellement écoulé.
- **« Réduire les effets »** : plus aucun mouvement continu, toute l'information reste.
- **Quand il parle**, les mots sortent de sa bouche, un à un.

## 6. Sa lumière et sa scène

Une seule source : la porte du logo. Elle éclaire Praxis (contre-jour), la route, et porte son ombre
vers nous, plus longue quand il s'éloigne d'elle. Chaque halo est un seul dégradé continu. Le vide de
l'arche du logo est de la lumière en dégradé. Les deux pieds de l'arche blanche descendent au sol et
deviennent les bordures de la route, d'un seul trait qui ne s'arrête pas. Hors connexion, la porte
s'éteint et la scène s'assombrit. Planches : `scene-porte-route-sombre.png`, `scene-telephone.png`.
Code : `entree_scene.dart.txt`, `entree_lumiere.dart.txt`.

## 7. Ce qu'il dit

Praxis écrit et parle selon `voix-directeur`, `mots-rewayah` et `agir-rewayah`. À l'écran : des
phrases courtes, une idée à la fois, jamais de reproche. En arabe : écrit comme un arabophone, jamais
traduit mot à mot (« شكرًا على انتظارك », pas « شكرا على صبرك »). Il ne se fait jamais passer pour le
directeur ; si on lui demande s'il est une IA, il dit oui.

## 8. Par support

**Application Flutter.**
- L'image de profil : `lib/core/communications/image_praxis.dart` (`ImagePraxis`, seul point
  d'affichage), image rangée en octets ; plein format dans `assets/brand/praxis/praxis-profil.png`.
- Le personnage animé : `lib/core/vivant/praxis_vivant.dart`. **Au 20/11/2026, ce fichier porte encore
  un dessin antérieur** (toque plus petite, pieds lilas) : le lot PRAXIS-CANON doit l'aligner sur le
  dessin de référence. Ne pas créer un second widget : on corrige celui-là.
- Règles du dépôt : couleurs, durées et courbes par les jetons ; `dart run tool/verifier_jetons.dart` ;
  captures dans `docs/current/captures/E2E/<lot>/`.

**Image fixe (profil, réseau social, document).** On l'exporte depuis le dessin de référence, jamais
depuis une retouche. Portrait : mode `?planche=avatar` (fond violet) ou `?planche=avatar&fond=clair`
de la maquette, capturé à 2000 × 2000 (`reference/outils/exporter-portrait.js.txt`). Fonds permis :
violet du logo, lilas pâle, blanc, encre. Jamais sur une photo, jamais déformé, jamais recoloré.

**Maquette ou artefact en vrai Flutter.** Reprendre les fichiers de `reference/source/` (retirer
l'extension `.txt`) dans un projet Flutter web, construire avec `reference/outils/build.sh.txt`
(sans `--wasm`), l'héberger dans `reference/outils/page-hote.html.txt`.

**SVG, HTML, outil de design, chat.** Suivre la fiche du §2 à la lettre, à partir de la vue de face ;
poser le portrait `praxis-profil.png` à côté et comparer. Si le support ne permet pas le volume, on
garde les formes, les mesures et les couleurs, en aplats. On ne demande jamais à un générateur
d'images de « dessiner Praxis » : il en ferait un autre personnage.

## 9. La marche à suivre pour créer ou recréer Praxis

1. Lire ce fichier en entier, puis regarder les cinq planches.
2. Partir de `entree_praxis.dart.txt` (fonction `peindrePraxis`, classe `Corps`). Ne rien réécrire de
   mémoire.
3. Régler la pose : expression, geste, orientation, éclairage (`Eclairage` : couleur, direction de la
   source, force du contre-jour).
4. Rendre l'image ou la scène.
5. **Vérifier les yeux** : poser le Praxis d'origine à gauche et le nouveau à droite (planche
   `?planche=1`), mesurer les ovales (26 × 36) et les pupilles (rayon 6). S'ils diffèrent, c'est faux.
6. **Vérifier la toque** : sous tous les angles, elle reste au-dessus des yeux (`?planche=toque`).
7. Vérifier les couleurs (§3), en thème clair et en thème sombre, et la lumière (aucun anneau, aucune
   plaque).
8. Regarder le rendu soi-même, en grand et à la taille réelle d'usage (40, 96 points), avant de le
   montrer. Dire au directeur ce qui est nouveau par rapport à cette fiche.
9. Toute nouveauté validée par le directeur s'écrit ici le jour même, avec sa date et ses mots, et le
   code de référence est mis à jour dans ce dossier.

## 10. Ce qu'on ne fait jamais

- Changer les yeux, ajouter des sourcils, des cils, un nez, des oreilles, des cheveux, des bras.
- Faire descendre la toque sur le visage, la retirer, la remplacer par un autre couvre-chef.
- Employer une couleur hors du §3, une lumière en anneaux, une plaque blanche pour de la lumière.
- Dessiner un second Praxis à côté de celui du dépôt, ou garder deux dessins différents dans l'application.
- Publier une image de Praxis faite par un générateur d'images ou retouchée à la main.
- Lui donner un visage triste par défaut, un air moqueur, une posture d'autorité sur une personne.
- Le présenter comme le directeur ou comme un humain.

## 11. Les fichiers de ce dossier

| Fichier | Contenu |
| :--- | :--- |
| `reference/source/entree_praxis.dart.txt` | Le dessin de référence : corps, toque en volume, mains, pieds, yeux, bouche, marche, gestes |
| `reference/source/vivant.dart.txt` | Le Praxis d'origine (aplat, toque dessinée) : la référence des yeux |
| `reference/source/entree_lumiere.dart.txt` | Les teintes et les halos (un seul dégradé par halo) |
| `reference/source/entree_scene.dart.txt` | La porte, la route, les bordures, l'ombre, la caméra |
| `reference/source/entree_textes.dart.txt` | Les expressions, les gestes, les phrases (français, arabe) |
| `reference/source/main_entree.dart.txt` | Les écrans de la maquette, les planches de vérification, le portrait |
| `reference/outils/` | Construire la maquette, l'héberger, exporter le portrait |
| `reference/planches/yeux-origine-et-canon.png` | Les onze expressions : origine à gauche, référence à droite |
| `reference/planches/toque-angles-et-gestes.png` | Le demi-tour, la lumière de côté, assis, les gestes |
| `reference/planches/portrait-tailles.png` | Le portrait sur ses deux fonds, à 500, 96 et 40 points |
| `reference/planches/scene-*.png` | La porte, la lumière et la route, au téléphone et à l'ordinateur |

Les mêmes règles sont à installer dans les compétences du compte claude.ai (chat, design) : y déposer
ce dossier tel quel. Quand ce fichier change, la copie du compte est à remplacer le même jour.
