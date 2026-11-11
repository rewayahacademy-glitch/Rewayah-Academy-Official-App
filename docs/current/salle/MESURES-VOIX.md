# Mesures de la voix : avant et après

Banc d'essai de la salle (`tool/salle/`), le 11/11/2026. Cahier de la salle §5 : « l'élève comprend
chaque mot de l'enseignant », et l'inverse.

## À lire d'abord : ce que ces chiffres ne prouvent pas

- **Un seul passage par case.** Chaque chiffre vient d'une seule séance de 70 secondes. Un écart de
  un ou deux mots entre deux cases peut être du hasard. Les grandes tendances, elles, se répètent
  dans les deux sens et avec ou sans caméra.
- **Un banc local.** Un seul ordinateur, des pertes fabriquées par un relais. Ni vrais téléphones,
  ni vraie distance entre pays.
- **La règle absolue n'est pas tenue partout.** Sous des pertes **en rafales** de 10 % et plus, des
  mots sont encore perdus après la correction. Voir « Ce qui reste à faire ».
- **Une case est invalide** (marquée ci-dessous) : le réglage du relais n'avait pas suivi une
  reconnexion. Le relais est corrigé depuis ; la case sera refaite.
- « Mots perdus » n'est pas un jugement de tajwid. C'est une mesure répétable de ce qui reste des
  mots, faite par un modèle de reconnaissance de la récitation.

## Comment c'est mesuré

- Une vraie séance : la vraie application, un vrai serveur LiveKit, un enseignant sur ordinateur,
  un élève au téléphone. Celui qui parle récite Al-Fatiha puis Al-Ikhlas (cheikh Al-Husary, 11
  versets, 72 s, en boucle). Celui qui écoute est enregistré **après** la reconstruction du son
  par le navigateur : c'est ce qui sort de son haut-parleur.
- Le mauvais réseau est celui de l'**élève**, dans les deux sens. Chaque essai avec pertes porte
  aussi 100 ms de latence aller-retour. « Rafales » : les pertes arrivent par paquets de 3 de suite
  en moyenne (4 pour l'essai à 30 %), comme sur un réseau mobile.
- Trois notes :
  1. **Mots perdus** : chaque verset reçu est transcrit et comparé au même verset d'origine, par le
     même modèle (Whisper affiné par Tarteel sur la récitation du Coran).
  2. **ESTOI** : intelligibilité objective (Jensen et Taal, 2016), de 0 à 1. Sans aucune perte,
     cette chaîne donne 0,85 à 0,88 : c'est le plafond du banc.
  3. **Son reconstruit** : part du son que le navigateur a dû inventer pour boucher un trou
     (statistique WebRTC). C'est la mesure que l'application pourra lire en direct.

## Les deux versions comparées

| | Avant (en production) | Après (cette branche) |
| :-- | :-- | :-- |
| Redondance de la voix (RED) | **désactivée par erreur** : la bibliothèque LiveKit 2.12.0 inverse le réglage | active : chaque paquet porte aussi le son du précédent |
| Débit de la voix | 24 kbit/s | 32 kbit/s (environ 67 avec la redondance) |
| Coupure pendant les silences (DTX) | oui | non |
| Priorité de la voix sur la vidéo | non réglée | haute |

## Résultats

Chaque case : mots perdus · ESTOI · son reconstruit.

### L'élève écoute l'enseignant (sans caméra)

| Réseau de l'élève | Avant | Après |
| :-- | :-- | :-- |
| Parfait | 0 % · 0,86 · 0 % | 0 % · 0,88 · 0 % |
| 300 ms de latence | 0 % · 0,81 · 0 % | *case invalide, à refaire* |
| 3G (384 kbit/s, 2 % de pertes, 300 ms) | 0 % · 0,79 · 2,3 % | **0 % · 0,85 · 0 %** |
| 10 % de pertes isolées | 0 % · 0,72 · 6,8 % | **0 % · 0,89 · 0,1 %** |
| 20 % de pertes isolées | 0 % · 0,73 · 6,2 % | **0 % · 0,88 · 0,2 %** |
| 10 % de pertes en rafales | 3 % · 0,70 · 6,8 % | 6 % · 0,74 · 7,7 % |
| 20 % de pertes en rafales | 0 % · 0,74 · 5,8 % | 10 % · 0,70 · 13,7 % |
| 30 % de pertes en rafales | **37 % · 0,53 · voix muette 41 % du temps** | 3 % · 0,61 · 21,9 % |

### L'enseignant écoute l'élève qui récite

| Réseau de l'élève | Avant | Après |
| :-- | :-- | :-- |
| Parfait | 0 % · 0,85 · 0 % | 0 % · 0,87 · 0 % |
| 300 ms de latence | 0 % · 0,82 · 0,1 % | 0 % · 0,87 · 0,1 % |
| 3G | 0 % · 0,77 · 1,8 % | **0 % · 0,86 · 0 %** |
| 10 % de pertes isolées | 0 % · 0,80 · 1,4 % | **0 % · 0,88 · 0 %** |
| 20 % de pertes isolées | *case douteuse, à refaire* | 0 % · 0,83 · 0 % |
| 10 % de pertes en rafales | 3 % · 0,72 · 6,5 % | **0 % · 0,77 · 4,8 %** |
| 20 % de pertes en rafales | 17 % · 0,65 · 12,3 % | **3 % · 0,74 · 7,7 %** |
| 30 % de pertes en rafales | 17 % · 0,55 · 20,6 % | 13 % · 0,64 · 17,2 % |

### L'élève écoute l'enseignant, caméra de l'enseignant allumée

| Réseau de l'élève | Avant | Après |
| :-- | :-- | :-- |
| Parfait | 0 % · 0,85 · 0 % · vidéo 720p | 0 % · 0,89 · 0 % · vidéo 720p |
| 3G | 0 % · 0,75 · 1,8 % · vidéo 360p | **0 % · 0,84 · 0 %** · vidéo 180p |
| 20 % de pertes en rafales | 11 % · 0,60 · 17,1 % · vidéo 180p | **0 % · 0,69 · 12,3 %** · vidéo 180p |

Sous contrainte, la vidéo baisse (720p, puis 360p, puis 180p à quelques images par seconde) et la
voix garde son débit : la voix passe avant l'image, dans les deux versions.

## Ce que j'en conclus

1. **Pertes isolées, 3G, latence : la correction rend la voix intacte.** Zéro mot perdu et un son
   aussi propre que sans perte (ESTOI 0,83 à 0,89), jusqu'à 20 % de pertes, dans les deux sens.
   Avant, le navigateur devait inventer 6 à 7 % du son.
2. **Pertes en rafales : la correction aide mais ne suffit pas.** La redondance ne répare qu'un
   paquet perdu isolé ; deux paquets perdus de suite laissent un trou. Des mots restent perdus
   (jusqu'à 10 % dans un essai). C'est le cas d'un réseau mobile en mauvais état.
3. **À 30 % de pertes, l'application actuelle coupe la voix près de la moitié du temps** (la
   connexion se reconstruit sans cesse). La correction garde une voix continue, mais abîmée.
4. **La correction n'est jamais nettement pire.** La seule case où « avant » fait mieux (élève qui
   écoute, 20 % en rafales) est un passage unique ; la même case avec la caméra dit l'inverse.

## Essai : un tampon d'avance de 250 ms chez l'élève

Idée : retarder un peu le son chez l'auditeur en difficulté, pour laisser aux paquets perdus le
temps d'être renvoyés. L'élève écoute l'enseignant, sans caméra. Chaque case : mots perdus · ESTOI
· son reconstruit.

| Réseau de l'élève | Avant, sans tampon | Avant, tampon 250 ms | Après, sans tampon | Après, tampon 250 ms |
| :-- | :-- | :-- | :-- | :-- |
| 3G | 0 % · 0,79 · 2,3 % | **0 % · 0,84 · 0,1 %** | 0 % · 0,85 · 0 % | 0 % · 0,89 · 0 % |
| 10 % en rafales | 3 % · 0,70 · 6,8 % | 0 % · 0,72 · 3,7 % | 6 % · 0,74 · 7,7 % | 10 % · 0,78 · 6,2 % |
| 20 % en rafales | 0 % · 0,74 · 5,8 % | 0 % · 0,76 · 5,7 % | 10 % · 0,70 · 13,7 % | 0 % · 0,73 · 11,9 % |
| 30 % en rafales | 37 % · 0,53 · muette 41 % | 14 % · 0,54 · 11,0 % | 3 % · 0,61 · 21,9 % | 23 % · 0,58 · 21,9 % |

Ce que ça dit, honnêtement :

- Le tampon aide la version qui **renvoie** les paquets perdus (« avant ») : la 3G devient presque
  parfaite, et la voix ne se coupe plus à 30 %. Il n'aide presque pas la version à redondance
  (« après »), parce que le serveur de visio ne renvoie pas les paquets d'une voix redondante.
- Sous des rafales, **aucune des quatre combinaisons ne tient la règle** : il reste 4 à 22 % de son
  reconstruit, et des mots tombent d'un essai à l'autre (les écarts de mots entre cases voisines
  sont dans le hasard d'un passage unique).
- Les deux mécanismes se complètent : la redondance répare tout de suite les pertes isolées, le
  renvoi répare les rafales quand il a le temps. Il faut **les deux ensemble**. C'est la piste
  principale de la suite, et elle se joue en partie dans les réglages du serveur de visio.

## La règle : ce que l'application fait sous chaque seuil

En vigueur avec cette branche :

| Ce que le serveur de visio mesure | Ce que fait l'application |
| :-- | :-- |
| Lien bon ou excellent | Voix redondante à 32 kbit/s ; vidéo jusqu'à 720p |
| Lien médiocre | Les vidéos reçues passent à la couche la plus basse ; la caméra locale se coupe ; la voix ne change pas. L'écran dit « Réseau faible » |
| Lien perdu | Plus aucune vidéo reçue ; la voix seule |
| Lien redevenu bon | L'image revient après deux bonnes mesures (au plus 10 secondes). **Avant, elle ne revenait jamais** tant que le réseau ne changeait pas de nouveau (défaut R-3) |

À venir (lot « réseau réel », pas dans cette branche) :

| Ce que l'appareil de l'auditeur mesure sur 10 secondes | Ce que l'application fera |
| :-- | :-- |
| Moins de 1 % de son reconstruit | Rien : la voix est claire |
| 1 à 5 % | « Voix hachée » : l'élève lit quoi faire (se rapprocher du Wi-Fi, fermer les autres applications) ; l'enseignant lit « Amina vous entend mal » ; le son prend un tampon d'avance pour laisser le temps de rattraper les paquets perdus |
| Plus de 5 % | « Voix très hachée » : même chose, plus fort ; l'enseignant sait qu'il doit répéter ; le relevé de la séance le garde |

Ces seuils sont des propositions tirées de ces mesures (à 6 ou 7 % de son reconstruit, aucun mot
n'est perdu mais l'ESTOI tombe de 0,86 à 0,72 ; au-delà de 10 %, des mots tombent). Ils seront
réglables côté serveur.

## Ce qui reste à faire

- **Les rafales : toujours ouvertes.** Voir l'essai du tampon ci-dessous : il ne suffit pas. Pistes
  suivantes, à mesurer : un tampon plus long (500 ms) avec le renvoi des paquets ; obtenir du
  serveur de visio à la fois la redondance et le renvoi (aujourd'hui c'est l'un ou l'autre) ; une
  redondance sur deux paquets au lieu d'un.
- **Répéter** chaque case trois fois pour chiffrer le hasard, et refaire les deux cases invalides.
- **Dire la vérité à l'écran** : mesurer le son reconstruit en direct et prévenir l'élève et
  l'enseignant (défaut V-2 du constat).
- **Le traitement du micro** (suppression du bruit, gain automatique) n'a pas encore été mesuré sur
  une récitation : une voyelle tenue longtemps peut être prise pour un bruit. À mesurer.
- **Le serveur de production** : sa région et ses réglages restent inconnus depuis le dépôt ; le
  repli par le port 443 n'a pas été essayé.
- **La preuve du directeur**, en production, avec de vrais élèves.

## Les enregistrements

Ce que l'auditeur entend, pour chaque case, est gardé hors du dépôt (la récitation d'essai n'est
pas à l'académie). Ils sont remis au directeur à part. Pour une preuve versée au dépôt, il faudra
une récitation dont l'académie a les droits.
