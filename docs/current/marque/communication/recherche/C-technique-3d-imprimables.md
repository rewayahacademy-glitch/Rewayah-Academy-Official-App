# C. Technique : 3D sur processeur seul, tournage du directeur, imprimables

Rapport du 27/11/2026. Tout ce qui est écrit « mesuré » l'a été dans ce conteneur (4 cœurs, 15 Go, pas de carte graphique). Tout ce qui est écrit « non vérifié » ne l'a pas été.

## 0. À dire d'abord

1. **Rien n'est prouvé en production.** La maquette 3D est un essai technique, pas une scène finie : pas de Praxis (une sphère marquée « placeholder »), pas de porte qui s'ouvre, brume encore grossière.
2. **La demande contredit le README du logo.** `assets/brand/logo/README.md` interdit pour le logo : rotation, miroir, ombre portée, lueur, transparence. La scène demandée fait tourner l'arche, lui donne une épaisseur, une ombre et une lumière. Il faut une décision datée du directeur qui autorise ce traitement pour la vidéo. Le même README classe `ornement-plein.svg` comme « motif décoratif, pas une signature de marque » : c'est lui que j'ai extrudé, comme demandé.
3. **La porte ne peut pas s'ouvrir sur sa charnière sans un objet dérivé.** `ornement-plein.svg` est un seul tracé : l'arche, le vantail entrouvert et le vide sont un même contour, et le vantail est soudé au pilier gauche. Extrudé tel quel, c'est une plaque rigide avec une fente. Pour une vraie charnière il faut découper ce tracé en « cadre » et « vantail », donc construire un modèle 3D dérivé du logo. C'est à valider par le directeur (détail au §2.5). Non construit.
4. **Le dessin du logo n'est pas une perspective unique** (calculé sur les points du tracé) : l'arche est un demi-cercle exact, donc vue de face ; le vantail fuit vers un point situé vers (625 ; 529) ; le haut de l'ouverture est oblique sans raison perspective. Le point de fuite est calculé ; la suite est ma lecture : avec une ouverture et un vantail rectangulaires, un modèle 3D ne redonnera pas exactement le logo sous un seul angle. On peut s'en approcher et mesurer l'écart.
5. **Sources.** Le service de recherche web (Firecrawl) était à court de crédits. Les licences ont été lues dans les fichiers `LICENSE` des dépôts GitHub. Pour Remotion j'ai lu `LICENSE.md` (branche `main`, en entier) et la page `remotion.dev/docs/license/pricing`.

## 1. Comparaison des outils pour rendre en MP4 sans carte graphique

| Outil | Licence (lue où) | Rendu sans carte graphique | Vraie 3D, une caméra | Verdict |
|---|---|---|---|---|
| **Three.js** + Chromium sans écran | MIT (fichier LICENSE) | **Mesuré : 0,37 s par image** en 1080x1920 avec ombres et brume | Oui : `SVGLoader` + `ExtrudeGeometry` | **Retenu pour la scène** |
| **Blender (bpy 5.3), Cycles** | GPL (le logiciel ; les images produites sont libres) | **Mesuré : 33,7 s par image** à 32 échantillons, 123,7 s à 128 | Oui, lumière physique exacte | Secours pour une image fixe « héros » |
| **Blender, Eevee** | idem | **Un essai, échec** : « Unable to initialize a Vulkan 1.1 instance », aucune image. Moteur OpenGL logiciel non essayé | - | Non acquis ici |
| **Remotion** | Licence propre : gratuit pour un particulier, une société à but lucratif de **3 employés au plus**, une association ; au-delà, licence société : 25 $ par mois et par poste pour créer des vidéos, minimum affiché 100 $ par mois (LICENSE.md et page des prix). **Je ne connais pas l'effectif de l'académie : au-delà de 3 employés dans une structure à but lucratif, c'est payant.** La licence change en 5.0 | Chromium sans écran, donc même moteur que ci-dessus. Non essayé | Via `@remotion/three`. Non essayé | Possible mais React obligatoire et licence à surveiller |
| **HyperFrames** (HeyGen) | Apache 2.0 (dépôt) | « HTML vers MP4 déterministe », Node 22 ou plus. Non essayé dans ce conteneur | Scènes 3D montrées dans leur vitrine. WebGL sous leur moteur de capture : non vérifié | **Candidat pour le montage** (titres, sous-titres, sons) |
| **Motion Canvas** | MIT (dépôt) | Conçu autour d'un éditeur dans le navigateur ; rendu sans écran non vérifié | 2D seulement | Écarté pour cette scène |
| **Theatre.js** | Apache 2.0 pour le dépôt (fichier LICENSE ; licence du studio à part : non vérifiée) | Outil de clés d'animation, pas de rendu | S'attache à Three.js | Inutile sans humain devant l'écran : un agent écrit les clés en code |
| **Rive** | Moteurs MIT (`rive-wasm`, `rive-runtime`) | Rendu sans écran : non vérifié | 2D | Écarté. L'éditeur demanderait un compte : non vérifié |
| **Lottie** | `lottie-web` MIT | Se lit dans Chromium | 2D | Écarté. Fabrication habituelle par After Effects : non vérifié |

### Recommandation

**Three.js rendu par Chromium sans écran, piloté par Playwright, encodé par ffmpeg.** Raisons, toutes mesurées dans la maquette :

- WebGL 2 fonctionne dans le Chromium préinstallé sans aucun réglage : moteur « ANGLE, Vulkan, SwiftShader ». Les options `--use-angle=swiftshader` ne changent rien.
- 3 secondes en 1080x1920 à 30 images par seconde : 38,5 s au total. Une vidéo de 30 s prendrait environ 6 à 7 minutes. Cycles prendrait environ 8 heures à 32 échantillons.
- Rendu déterministe : la même image rendue dans trois lancements séparés donne le même fichier à l'octet près (même somme md5).
- Le tracé officiel est lu tel quel par `SVGLoader`, sans redessin (preuve au §2.3).
- Praxis est fait de sphères et d'ovales : il se construit directement en 3D dans la même scène, donc même caméra et même lumière que la porte. Il n'a pas besoin de Rive ni de Lottie. À faire selon la compétence `praxis-rewayah` ; non commencé.

Montage (titres, sous-titres, musique, plans filmés) : ffmpeg suffit pour commencer ; HyperFrames est à essayer ensuite. Images fixes « héros » pour une affiche : Cycles, 2 minutes l'image.

### Lumière volumétrique sur processeur

Trois méthodes, de la plus fausse à la plus juste :

1. **Cônes additifs avec dégradé.** Très rapide, mais c'est un dessin posé sur la scène : il ne suit pas la forme de la fente. C'est l'erreur à ne pas refaire.
2. **Rayons en espace écran** (flou radial depuis la source, type `GodRaysEffect`). Rapide, joli, mais faux dès que la source sort du cadre ou est cachée.
3. **Marche de rayon dans la carte de profondeur de la lampe** (retenu, dans la maquette). Pour chaque pixel on avance le long du rayon de vue et on demande à chaque pas : « ce point voit-il la lampe à travers la fente ? ». La brume a donc exactement la forme du vide du logo. Coût mesuré : 130 ms par image (40 pas, demi-résolution, flou).

## 2. Maquette construite

Dossier : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/250ae9e7-8a6b-5e50-b765-052d5cb2c173/scratchpad/recherche/poc3d/`

| Fichier | Contenu |
|---|---|
| `porte_route_1080x1920_30fps.mp4` | 3 s, 90 images, H.264, 1,4 Mo |
| `frames/scene_t0.png`, `frames/scene_t1.5.png`, `frames/scene_t3.png` | Trois images de la scène |
| `frames/sansbrume_t1.5.png` | La même sans brume |
| `frames/video_extrait_t1.5.png` | Image extraite du MP4 : identique à l'image fixe (PSNR 43 dB), donc ni image noire ni décalage de couleur |
| `frames/fidelite_face_t0.png` | L'arche 3D vue de face, pour la comparer au SVG |
| `src/scene.js`, `src/render.mjs`, `src/index.html` | Le code. Relancer : `node src/render.mjs --stills=0,1.5,3 --name=scene` ou `--video=nom.mp4` |

### 2.1 Ce que la maquette fait

- **Une seule scène, une seule caméra en perspective.** L'arche tourne de 30° sur l'axe vertical ; on voit son épaisseur sur le côté. La route sort selon la normale de la porte puis tourne à gauche. Aucun calque 2D : c'était la cause de l'échec passé (route inclinée, logo de face).
- **Une seule source**, placée derrière la porte, dans le groupe qui tourne avec elle.
- **La nappe au sol est la projection réelle des vides du tracé** : elle vient de la carte d'ombre de la lampe, et l'arche extrudée est l'objet qui fait l'ombre. Aucun rectangle lumineux n'est dessiné.
- **Brume** par la méthode 3 ci-dessus.
- **L'épaisseur intérieure de la fente est éclairée** directement par la lampe.
- **La sphère placeholder** est à contre-jour, avec un liseré clair et une ombre longue vers la caméra, issue de la même carte d'ombre.
- **L'ombre du vantail n'existe pas à part** : avec la plaque rigide, c'est l'ombre de toute la plaque. Une ombre propre au vantail demande la voie B (§2.5).
- **Pour un virage à droite** : on tourne l'arche dans l'autre sens ou on déplace la caméra. Jamais de miroir du logo.

### 2.2 Ce qu'elle ne fait pas, ou triche

- Pas de Praxis, pas de marche. La sphère flotte et porte l'étiquette « PLACEHOLDER (pas Praxis) ».
- La porte ne s'ouvre pas (voir §2.5). L'animation est : la lumière monte, la caméra avance, la sphère avance.
- **Le rebond du sol vers l'arche est approché** par une petite lampe sans ombre posée au centre de la nappe. Ce n'est pas un calcul de lumière indirecte.
- Deux lumières d'ambiance violettes très faibles rendent la face avant lisible. Elles ne projettent rien, mais ce sont bien des lumières en plus de la source.
- Un cache invisible derrière l'arche empêche la lampe d'éclairer autour de la silhouette. Le rectangle lumineux vu à travers les vides est un plan émissif.
- Le bas de l'ornement n'est pas plat (il est coupé sur un cercle). Le sol est posé à la cote 700 du tracé : le coin du vantail flotte à environ 0,55 m, d'où un filet de lumière sous la porte. À arbitrer : socle, sol plus haut, ou autre fichier du logo.
- Défauts visibles : trame dans la brume à gauche, brume trop large au-dessus du vantail, petite ligne pointillée au pied droit de l'arche, étiquette coupée par l'arche.

### 2.3 Preuve que le tracé n'est pas redessiné

L'arche 3D rendue de face, en vue orthographique à 2 pixels par unité du SVG, est comparée pixel à pixel au SVG officiel dessiné par le navigateur : **recouvrement de 99,94 %**, 606 pixels différents sur 1 003 331 (je suppose qu'ils sont sur le bord, à cause du lissage : non contrôlé). Ni miroir, ni déformation.

### 2.4 Temps mesurés (1080x1920)

| Mesure | Valeur |
|---|---|
| Chargement de la scène | 0,11 s |
| Première image (compilation des shaders) | 0,8 à 0,9 s |
| Rendu d'une image, moyenne sur 90 | **374 ms** (médiane 365 ms) |
| dont brume | environ 130 ms (243 ms sans brume) |
| Capture JPEG de l'image | 38 ms |
| Vidéo de 3 s, encodage x264 compris | **38,5 s**, soit 0,43 s par image |
| Même scène en 720x1280 | 209 ms par image |
| Brume à 16 pas au lieu de 40 | 340 ms par image |

### 2.5 La charnière : deux voies, au choix du directeur

- **Voie A, plaque rigide (dans la maquette).** Tracé officiel extrudé, zéro redessin. La porte reste entrouverte comme sur le logo. La lumière peut monter, mais rien ne pivote.
- **Voie B, modèle dérivé.** Un cadre (contour extérieur du tracé officiel, ouverture déduite) et un vantail rectangulaire sur une charnière à gauche. On règle l'angle d'ouverture au repos pour que la vue de face ressemble au logo, et on mesure l'écart avec le même outil qu'au §2.3. Comme le logo n'est pas une perspective unique (§0, point 4), l'écart ne sera pas nul. C'est un nouvel objet de marque : il faut l'accord du directeur avant de le construire.

## 3. Incruster le directeur filmé dans l'animation

### Détourage, gratuit, sur processeur

| Outil | Licence | Vitesse sur processeur | Avis |
|---|---|---|---|
| **RobustVideoMatting** (MobileNetV3, ONNX) | **GPL-3.0** (fichier LICENSE) | **Mesuré : 86 ms par image en 1080x1920** (11,6 images par seconde), 63 ms en 720x1280 | **Retenu.** Conçu pour la vidéo, garde la mémoire d'une image à l'autre, donc peu de scintillement. Qualité sur un vrai plan : non vérifiée (essai fait sur une image de bruit, pour la vitesse seulement) |
| MediaPipe Selfie Segmentation | Apache 2.0 (dépôt) | Non mesuré | Réputé donner un masque aux bords grossiers : non vérifié |
| rembg | MIT pour le code ; **chaque modèle a sa licence** | Non mesuré | Image par image, donc scintillement en vidéo. **Piège : le modèle par défaut est maintenant `bria-rmbg`, dont la licence exige un accord payant pour un usage commercial** (README de rembg). Choisir `-m u2net_human_seg` ou `birefnet-portrait` (licences de ces modèles : non vérifiées) |
| BackgroundMattingV2 | MIT (fichier LICENSE) | Non mesuré | Demande une photo du fond vide. Très propre si le plan est fixe, mais plus ancien que RVM |

La GPL de RVM porte sur le logiciel, pas sur les vidéos qu'il produit ; ce n'est pas un avis juridique. Une minute filmée à 30 images par seconde = 1 800 images, environ 2 min 35 de détourage.

### Raccord de lumière

- Dans la scène 3D, le directeur est un plan placé à sa distance réelle : il reçoit l'ombre et la brume comme le reste.
- Étalonnage par ffmpeg : baisser un peu la saturation de la peau, teinter les ombres en violet, ajouter un liseré violet (#8652E6) calculé à partir du bord du masque, du côté de la porte.
- Ombre de contact au sol sous le directeur : forme floue sombre, même direction que l'ombre de Praxis.
- Pas de suivi de caméra : plan fixe.

### Exigences techniques du tournage

1. Téléphone **sur trépied, verrouillé**. Aucun mouvement, aucun zoom.
2. **Vertical, 1080x1920 au minimum** (4K si possible, pour recadrer). **30 images par seconde**, fixe. Pas de ralenti, pas de mode « cinéma », pas de HDR.
3. **Exposition, mise au point et balance des blancs verrouillées** avant de filmer.
4. **Fond uni, mat, sans plis**, d'une couleur éloignée de la peau et des vêtements. Se tenir à 1,5 m du fond au moins. Un fond vert n'est pas obligatoire avec RVM, mais il aide.
5. **Filmer 5 secondes du fond vide** avant d'entrer dans le cadre (sert à BackgroundMattingV2 en secours).
6. **Lumière** : une lumière douce de face, à 45°. **Une lumière d'appoint derrière, du côté où sera la porte**, pour créer un vrai liseré sur l'épaule et les cheveux. Pas de fenêtre dans le dos, pas de néon qui scintille.
7. **Vêtements** : unis, pas de rayures fines, pas de la couleur du fond, pas de blanc brûlé.
8. **Mains** : les garder dans le cadre, gestes lents. Des doigts rapides deviennent flous et se détourent mal.
9. **Regard** : coller un repère (pastille de couleur) à l'endroit exact où sera Praxis, à hauteur de ses yeux. Regarder le repère quand on lui parle, l'objectif quand on parle au public. Noter la position du repère par rapport au cadre.
10. **Son** : micro-cravate ou second téléphone près de la bouche ; un clap de mains au début pour caler.
11. Marquer au sol la place des pieds. Refaire la prise entière plutôt que de bouger.

## 4. Imprimables et PDF dans le style de la marque

Essai fait : une page A5 avec les polices du dépôt (`assets/fonts/`, lues sans rien écrire) : UthmanicHafs pour le Coran, UthmanTahaNaskh pour l'arabe, DM Sans pour les titres, Plus Jakarta Sans pour le texte. Basmala et dou'a avec toutes les voyelles, texte mêlé arabe et français. Fichiers : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/250ae9e7-8a6b-5e50-b765-052d5cb2c173/scratchpad/recherche/pdf-test/` (`compare.png` montre les trois côte à côte).

| Outil | Arabe avec voyelles (mesuré) | Polices dans le PDF (mesuré, `pdffonts`) | Fond perdu et traits de coupe (mesuré) | CMJN |
|---|---|---|---|---|
| **Chromium, impression PDF** | Correct | Incorporées ; **les polices variables sortent en « Type 3 »** | **Ignorés** : `bleed` et `marks` sans effet, toutes les zones égales | Non, RVB seulement |
| **WeasyPrint 70** | Correct, identique à Chromium | Incorporées en TrueType, sous-ensembles | **Oui** : zone de rogne distincte, traits de coupe et croix tracés | Non vérifié |
| **Typst 0.15** | Correct | Incorporées ; **DM Sans variable : introuvable sous son nom (remplacée en silence), trouvée sous « DM Sans 9pt » mais en graisse normale au lieu du gras demandé** | Non essayé | Couleurs CMJN natives : non vérifié ici |
| **Paged.js** | Même moteur que Chromium, donc même arabe | Comme Chromium | Ajoute fond perdu et traits par script : installé, non essayé | Non |

Les trois moteurs donnent le même arabe : ligatures, lam-alif, mot Allah, voyelles bien posées. Vitesse : moins d'une demi-seconde par document pour les trois.

### Recommandation

- **WeasyPrint pour tout ce qui part chez un imprimeur** (cartes, livrets d'alphabet et de dou'a) : même HTML et CSS que le reste, fond perdu et traits de coupe réels, polices proprement incorporées.
- **Chromium pour ce qui reste à l'écran ou sort sur une imprimante de bureau** (factures, attestations) : rien à installer, rendu identique à ce que l'agent voit.
- **Typst écarté pour l'instant** : il ne règle pas la graisse des polices variables de la marque dans mon essai ; il faudrait des fichiers statiques.
- **CMJN** : aucun des outils essayés ne l'a produit. La conversion se ferait après coup avec Ghostscript, qui n'est pas installé ici : non vérifié. Demander à l'imprimeur s'il accepte un PDF RVB : le violet #8652E6 est hors de la gamme CMJN et sortira plus terne, il faut une épreuve.
- Une police de secours s'est glissée dans les PDF de Chromium et de WeasyPrint (Liberation Serif, DejaVu Sans). Cause la plus probable : le tiret long (U+2014) de ma ligne d'arabe, absent d'UthmanTahaNaskh (vérifié dans la police) ; aucune lettre arabe ni voyelle de l'essai ne manque à cette police. Avant toute impression : contrôler `pdffonts` et refuser tout nom de police inattendu.
- **Deux trous vérifiés dans les polices** : UthmanTahaNaskh n'a pas l'alif wasla (U+0671), UthmanicHafs n'a pas l'alif madda (U+0622). Donc un verset s'écrit en UthmanicHafs avec son propre texte, une dou'a en UthmanTahaNaskh sans alif wasla. Ne pas mélanger.
- **Règle de marque** (compétence `marque-rewayah`) : DM Sans pour les titres, Plus Jakarta Sans pour le reste et les chiffres, Noto Sans Arabic, Uthman Taha Naskh, UthmanicHafs pour le Coran seulement. Reem Kufi n'est admise que pour l'arabe décoratif du site public (M-31, 22/10/2026).

## 5. Liste de ce qui n'est pas vérifié

- Effectif et statut juridique de l'académie, dont dépend la gratuité de Remotion.
- HyperFrames, Remotion, Motion Canvas, Rive : aucun n'a été lancé dans ce conteneur.
- Licence du studio Theatre.js ; conditions du compte Rive.
- Vitesse de MediaPipe, rembg, BackgroundMattingV2 ; qualité de RVM sur un vrai plan du directeur.
- Licences des modèles `u2net_human_seg` et `birefnet-portrait`.
- CMJN dans WeasyPrint et Typst ; conversion par Ghostscript ; Paged.js en fonctionnement.
- Cycles : scène d'essai non réglée, le temps peut varier du simple au triple selon la scène.
- La voie B (charnière) et Praxis en 3D : non construits.
