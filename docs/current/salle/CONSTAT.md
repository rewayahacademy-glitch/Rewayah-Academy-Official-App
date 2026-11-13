# Constat de la salle

Tenu par Fable (mission `docs/current/CAHIER-SALLE.md`). Dernière mise à jour : 11/11/2026 (soir).

**Vérité d'abord.** Rien dans ce fichier n'est « fait » : « fait » veut dire prouvé par le directeur
en production. Chaque ligne porte son état exact :

- `trouvé` : vu, avec sa preuve ;
- `corrigé (code)` : la correction est écrite sur une branche, pas encore fusionnée ;
- `prouvé au banc` : rejoué sur une vraie séance locale (vraie application, vrai serveur de visio),
  avec la mesure ;
- `prouvé en production` : par le directeur seulement.

Deux niveaux de preuve pour un défaut : **mesuré** (rejoué sur le banc, chiffres à l'appui) ou
**lu** (lu dans le code, pas encore rejoué).

## 1. Pourquoi les refontes précédentes ont échoué

Chiffres : 327 commits sur la salle du 12/09 au 08/11 ; `salle_page.dart` est passé de 921 à 4 790
lignes ; les trois dossiers de la salle (`salle`, `salle_seance`, `salle_enseignant`) de 1 219 à
30 417 lignes. Huit causes, chacune avec son fait :

1. **Aucune disposition n'a été prouvée avant la suivante.** `K4-RESTE-2026-10-30.md` l'écrit :
   « tout le lot 3 et les deux compositions du 26/10 ont été fusionnés, mais aucun n'a été essayé
   par le directeur en production ». Le plan du 24/10 disait pourtant « rien d'autre tant que S0
   n'est pas prouvé ».
2. **On empile au lieu de remplacer.** Quatre dispositions vivent en production en même temps
   (l'ancienne page pour le contrôleur et l'observateur, trois panneaux pour l'enseignant sur
   ordinateur, capsule et tiroir pour l'enseignant au téléphone, plein écran flottant pour l'élève).
   Trois autres sont mortes mais restent dans le code, gardées vertes par 35 fichiers de tests.
3. **Les maquettes sont arrivées après le code, et se contredisent entre elles.** Les originales
   sont perdues. Celles du 26/10 au soir demandent l'inverse du plan validé le matin même.
4. **La maquette passait par une description écrite, et la description gagnait.** Le même agent
   écrivait la règle, le code, le test et le verdict (`CONTRAT-ECRAN-2026-10-26.md`).
5. **Un cas limite décidait du cas principal.** Un test à 320 points en texte doublé a retiré un
   bouton pour tout le monde.
6. **Les règles vivent à trois endroits qui ne disent pas la même chose** (`lib/CLAUDE.md`, le
   code, `UX-CONSTATS.md`) : seuil du téléphone à 600 ou 840 points, deux ou trois onglets.
7. **Chaque remarque est devenue une exception datée dans le code** : 189 commentaires datés, 126
   noms de lots différents, 38 tests sur le rôle au lieu de la capacité.
8. **Tout est bâti sur le Coran.** Un seul support, écrit en dur jusque dans la base.

Sur douze sujets (nom sous l'icône, couleur d'un micro coupé, place des élèves, place du tableau,
onglets du tiroir…), la décision a changé entre deux et quatre fois en un mois. Le plein écran sur
ordinateur a vécu moins de 21 heures.

**Ce que j'en tire pour la suite** (détail dans le journal des décisions) :

- on ne refait pas une disposition : on fixe **des places qui ne bougent plus**, écrites une fois,
  et le code les lit d'un seul endroit ;
- on **retire** ce qui est mort avant d'ajouter (avec l'accord du directeur, règle du dépôt) ;
- on commence par ce qui ne se voit pas et qui compte le plus : **la voix**, puis le réseau réel,
  puis le support générique ; la disposition vient après, sur des mesures ;
- chaque lot est essayé sur le banc à 12 élèves et sous mauvais réseau **avant** d'être proposé.

## 2. Les défauts, par gravité

### Bloquants (l'enseignement n'est pas possible ou pas licite dans ce cas)

| N° | Défaut | Preuve | État |
| :-- | :-- | :-- | :-- |
| V-1 | **La voix part sans protection contre les pertes.** La redondance audio (RED) était demandée dans le code mais jamais obtenue : la bibliothèque LiveKit 2.12.0 inverse le réglage. Un paquet perdu = un morceau de mot perdu. | **Mesuré** le 11/11 : la voix de l'enseignant part en `audio/opus` seul, 24 kbit/s. Cause lue dans `livekit_client` (`participant/local.dart:190`). Avant et après : `MESURES-VOIX.md` (à 20 % de pertes isolées, son reconstruit de 6,2 % à 0,2 %, zéro mot perdu). | corrigé (code) ; **prouvé au banc** pour les pertes isolées, la 3G et la caméra ; **non résolu** pour les pertes en rafales |
| V-3 | **Sous des pertes en rafales (réseau mobile en mauvais état), des mots sont perdus**, avant comme après la correction V-1 : la redondance ne répare qu'un paquet perdu isolé. À 30 % de pertes, l'application en production coupe la voix 41 % du temps. | **Mesuré** le 11/11 : `MESURES-VOIX.md` (jusqu'à 10 % de mots perdus à 20 % de pertes en rafales ; 37 % à 30 % en production). | trouvé ; essai d'un tampon d'avance en cours |
| V-2 | **Personne ne sait qu'une voix arrive déformée.** Aucune mesure de pertes ou de son reconstruit n'est montrée à l'élève ni à l'enseignant. | Lu : `diagnostic_transport.dart` mesure mais n'affiche rien et ne garde rien. | en partie corrigé (code, lot RESEAU-ELEVES, D-017) : sur la note de lien de LiveKit (un indice, pas le son reconstruit), la personne au micro ouvert dont le lien est mauvais depuis 8 s lit dans l'île « on vous entend peut-être mal » ; l'enseignant lit dans la carte « On entend peut-être mal Yasmine ». Reste : lire le son reconstruit en direct (règle 1 % / 5 % de `MESURES-VOIX.md`) ; non prouvé en production |
| S-1 | **Au téléphone, l'enseignant ne peut pas tourner la page.** Ni flèches, ni glisser, ni pagination dans son tiroir : il ne peut ouvrir que le début d'une sourate. | Lu : `telephone_plein_ecran.dart:138-141`, `telephone_enseignant.dart:438-474`. | corrigé (code, commit `b6f3c6972`) : la page se tourne au doigt ; tests de widget seulement, pas encore sur le banc |
| S-2 | **Le partage ne connaît que le Coran.** Le message « page partagée » ne dit pas de quel support il s'agit ; 604 pages en dur jusque dans la base. | Lu : `video_session_provider.dart:439-445`, migration `20261110100000` ligne 49. | trouvé |

### Élevés

| N° | Défaut | Preuve | État |
| :-- | :-- | :-- | :-- |
| R-1 | **Les barres de réseau sont factices.** Toujours trois barres pleines. | Lu : `signalEnseignant = 3` (`vue_seance.dart:563`), jamais modifié ailleurs. | corrigé (code) : les barres suivent la qualité mesurée par le serveur de visio ; sans mesure, aucune barre. La qualité de chaque élève dans sa carte du panneau de l'enseignant et l'alerte « on vous entend peut-être mal » : codées (lot RESEAU-ELEVES, D-017), barres filtrées contre le clignotement (3 s), testées localement, non prouvées en production |
| R-2 | **Aucune trace de la qualité de connexion n'est conservée.** Rien à opposer à une famille qui accuse l'académie. | Lu : les mesures partent en miettes de supervision, jamais en base. | **codé le 11/11 (lot RESEAU-PREUVE, D-024), pas installé, pas déployé, pas prouvé en production** : une ligne par changement d'état (bon, faible, perdu ; micro ouvert ou non) pour l'enseignant et les élèves adultes, **rien pour un élève mineur**, heure du serveur, **180 jours** (matin : 180 jours ; début d'après-midi : deux ans, sur une question du directeur mal comprise par le pilote ; fin d'après-midi : retour à 180 jours), lecture par la direction seule. La migration `20261123700100` est un brouillon à coller par le directeur (un mot d'effacement, dans la purge) : **ne pas installer avant l'avis de modification de la politique de confidentialité**. L'information est affichée aux élèves dans « En savoir plus » de la salle et à tous dans la politique de confidentialité de l'application ; pas dans la salle des enseignants, pas sur le site public. Les points de droit sont tranchés par les textes, sans juriste (`DROIT-RELEVE-QUALITE.md` §10). Reste : l'écran de la direction. `DROIT-RELEVE-QUALITE.md` §11 |
| R-3 | **Après un passage par un mauvais réseau, l'image ne revient pas.** Le retour attend deux bonnes mesures de suite, mais LiveKit n'en envoie qu'une quand la qualité ne change plus. « Image coupée » reste affiché. | Lu : `repli_audio.dart:28` contre `livekit_client` `participant.dart:218`. À rejouer au banc. | corrigé (code) : battement toutes les 5 s ; tests de la logique seulement, à rejouer au banc |
| SEC-1 | **Des élèves mineurs peuvent être en salle sans enseignant**, micro ouvert, 20 minutes avant l'heure et après son départ. La salle n'est jamais fermée par le serveur. | Lu : migration `20261102500000` ligne 470 ; aucun appel de fermeture de salle. | **moitié « avant l'heure » : codé, pas déployé, pas prouvé en production** (décision du directeur du 11/11, journal D-008). Le serveur signe le jeton d'un élève sans droit de publier tant que l'enseignant n'est pas dans la salle, et le lui rend à son entrée (webhook, plus un filet demandé par l'application). Testé : les décisions (13 tests Deno, 17 + 16 tests Dart) ; le module partagé contre le vrai serveur LiveKit local, en salle jetable (LiveKit refuse le micro de l'élève seul, l'accepte après l'entrée de l'enseignant). **Pas encore essayé** : les deux fonctions Edge elles-mêmes sur la pile (`node tool/salle/micro_avant_enseignant.mjs`), la vraie application dans un navigateur, la production. **Moitié « après son départ » et « après la fin » : codé, pas déployé, pas prouvé en production** (lot FERMETURE-SALLE, journal D-018). Le serveur note l'instant où la salle se retrouve sans enseignant ; deux minutes plus tard, s'il n'est pas revenu, il retire aux élèves le droit de publier (micro et caméra) et le leur rend à son retour ; quand la séance est finie (fin prévue + dépassement autorisé, ou séance close en base) et que l'enseignant n'est plus là, il ferme la salle pour tous (`deleteRoom`). Un cours qui se tient encore avec son enseignant n'est jamais coupé (question posée au directeur, D-018). Appliqué par deux voies sûres : la demande de l'application d'un participant (`verifier_salle`) et les entrées et sorties de la salle (webhook). **Correction du 11/11 au soir (revue du garde-cap)** : la troisième voie annoncée, la tâche planifiée `observation-coupure` « chaque minute », **ne tourne en production que lorsqu'un tuteur observe une séance** (clause `WHERE` de la migration `20261105500000`) ; sans cela le passage planifié n'a pas lieu, et une salle sans application à jour ni entrée ou sortie après l'échéance garde ses micros ouverts. À élargir par une migration (lot FERMETURE-CRON). Testé : les décisions (29 tests Deno), l'application (16 tests Dart et 5 tests d'écran), et le tout sur la pile locale par les vraies fonctions Edge et le vrai LiveKit (`node tool/salle/fermeture.mjs`, 32 vérifications sur 32). **Pas encore essayé** : la porte HTTP de `observation-coupure` (la pile locale n'a pas son secret ; son code, lui, est essayé), la vraie application dans un navigateur, la production. |
| G-1 | **« Appeler discrètement » ne se voit pas chez l'élève qui lit.** Le bandeau dure 5 s dans une couche déjà masquée ; le premier son est très probablement muet dans un navigateur ; l'enseignant n'a aucun retour. | Lu : `telephone_plein_ecran.dart:596-603`, `signal_rappel_web.dart:52-54`. | **corrigé dans le code le 11/11 (lot GESTES-POINTEUR, D-014), pas déployé, pas prouvé en production.** Le geste s'appelle « Appeler ». Chez l'élève : « Votre enseignant vous appelle » en tête de la salle, sur tous les écrans, 6 s, dans une couche qui ne se masque jamais (`annonce_geste.dart`), avec deux notes (le réveil du son du navigateur, réparé la veille, a été relu). Chez l'enseignant : « Appel envoyé à … » ou « L'appel n'est pas parti vers … » avec la raison. Proposé seulement pour un élève présent dans la salle. Testé : tests de widget. **Pas essayé** : le son et l'annonce dans un vrai navigateur sur le banc ; le retour dit que l'appel est parti, pas que l'élève l'a vu (l'élève ne peut rien renvoyer, son jeton n'a pas le canal de données). |
| G-2 | **« Faire réciter » ne fait que poser une étiquette.** Il n'ouvre aucun micro, ne coupe personne, et l'élève choisi n'est pas prévenu. | Lu : `salle_page.dart:966-977`. | **corrigé dans le code le 11/11 (lot GESTES-POINTEUR, D-014), pas déployé, pas prouvé en production.** Pendant qu'un élève récite, le serveur ferme le micro de ses camarades (droit de publier retiré chez LiveKit) et le leur rend à la fin ; le micro du récitant n'est jamais ouvert de force ; la récitation se termine seule si le récitant ou l'enseignant quitte la salle. **Prouvé sur la pile locale** par les vraies fonctions Edge et le vrai LiveKit : `node tool/salle/gestes.mjs`, 28 contrôles sur 28 (`docs/current/captures/E2E/gestes-pointeur/journal-pile.txt`). Testé aussi : 14 tests Deno des décisions, tests de widget. **Pas essayé** : la vraie application dans deux navigateurs, le webhook coupé (`SANS_WEBHOOK=1`), la production. **Depuis le 11/11 (décision du directeur, lot RECITATION-MICRO-SEUL, D-022) : le micro seul est fermé, la caméra des camarades reste** (codé, pas déployé, pas prouvé en production). Un élève dont le profil interdit la caméra n'en gagne pas : pendant la récitation il n'a ni micro ni caméra. Rejoué sur la pile locale : `node tool/salle/gestes.mjs`, 44 contrôles sur 44 (LiveKit dépublie le micro du camarade, garde sa caméra, refuse un micro forcé par un client modifié, accepte une caméra neuve, rend le micro à la fin) ; journaux dans `docs/current/captures/E2E/recitation-micro-seul/`. Toujours **pas essayé** : la vraie application dans deux navigateurs, le webhook coupé, la production. |
| P-1 | **Le pointeur est haché et peut rester figé.** 20 positions par seconde, sans lissage ni sillage ; la dernière position et le « lever » peuvent se perdre. | Lu : `surface_page_fixe.dart:596-617`, `synchro_salle.dart:345-378`. | **corrigé dans le code le 11/11 (lot GESTES-POINTEUR, D-014), pas déployé, pas prouvé en production.** Cause du retard lue dans le code : toute position tombée dans l'intervalle de 50 ms était jetée, la dernière comprise ; le canal, lui, était déjà sans retransmission. Maintenant : 30 positions par seconde au plus, la dernière toujours envoyée, un battement tant que le point reste posé, le lever sur les deux canaux, et chez l'élève le pointeur s'efface seul après 1 s sans nouvelle. Point de 32 (anneau clair, cœur violet de marque), sillage de 350 ms, rien que le point en mouvement réduit ; à la souris il suit le curseur sans appuyer. **Pas mesuré** : le retard réel entre deux appareils (aucune mesure au banc ; les tests prouvent la cadence et l'ordre des paquets, pas des millisecondes de bout en bout). |
| C-1 | **Connexion perdue : aucune reprise automatique**, et micro et caméra reviennent fermés. | Lu : `salle_page.dart:430-431`, `549-611`. | trouvé **Corrigé le 11/11 (lot ECRAN-EVEILLE, D-009)** : reprise sans geste, micro et caméra retrouvés ; mesuré sur le banc (75 s de réseau coupé : avant, appel perdu ; après, voix et micro revenus en 3,7 s). Pas encore prouvé en production ni sur un vrai téléphone. |
| D-1 | **La vidéo de l'enseignant s'affiche deux fois sur son écran** (vignette et cadre flottant), caméra allumée et rien de partagé. Sur le même écran : « Ouvrir le Coran » et un bouton « … » posés au milieu, l'élève réduit à une pastille dans un grand vide, la rangée de filtres de la Bibliothèque coupée. | **Vu** sur la capture du banc (enseignant, 1440 × 900). Lu : `salle_page.dart:1576-1583` et `3667-3725`. | **vidéo en double : corrigé en partie dans le code le 11/11 (lot GESTES-POINTEUR, D-014).** Règle : une personne, un cadre. Chez l'enseignant (ordinateur et téléphone), la scène ne répète plus son image, qui est déjà sa vignette (test de widget). **Reste ouvert** : chez l'élève au téléphone, la capsule du haut montre l'enseignant pendant que la scène le montre en grand (`telephone_plein_ecran.dart`, zone d'un autre lot ; lu, pas vérifié à l'écran). Le reste de la ligne (boutons au milieu, pastille, filtres) n'est pas de ce lot. |
| D-3 | **L'état est dit deux fois et le chrono est bavard** (directeur, 11/11) : « En ligne » et « En salle » côte à côte ; « 00:03:15 écoulé · 00:56:44 restant » ; rien n'est animé ; après la fin prévue le chrono s'arrête sur une phrase au lieu de compter le dépassement. | **Vu** sur la capture du banc (élève au téléphone) ; `pilule_etat_salle.dart`, `chrono_salle.dart`. Le réglage du dépassement existe déjà côté serveur (`grace_after_end_minutes`, 15 par défaut). | corrigé (code, commit `f268319aa`) ; captures `docs/current/captures/E2E/chrono-etat/` ; pas encore en séance réelle |
| D-2 | **Le chronomètre est caché** au téléphone de l'enseignant (dans le profil déplié) et masqué après 3 s chez l'élève. | Lu : `telephone_enseignant.dart:371-377`. | en partie : le chrono est une capsule visible partout où la pilule d'état est rendue ; **reste** : visible au repos sur le téléphone de l'enseignant (lot du téléphone réduit) |
| N-1 | **Douze élèves : jamais essayé.** Abonnement à toutes les vidéos, galerie pensée pour six. | Lu : `salle_page.dart:3733-3840`. Essai à 12 au banc à faire. | trouvé |
| W-1 | **Premier chargement lourd.** L'application pèse environ 5 à 6 Mo compressés à la première visite : près de deux minutes sur un réseau 3G. | **Mesuré** le 11/11 : `main.dart.js` 15,6 Mo (3,6 Mo compressé) plus le moteur d'affichage. | trouvé |

### Moyens

| N° | Défaut | Preuve | État |
| :-- | :-- | :-- | :-- |
| SEC-2 | Un élève sorti de la salle peut revenir tant que son jeton est valable (15 min par défaut). | Lu : migration `20261102100000` lignes 20-21. | trouvé |
| SEC-3 | « Couper le micro » d'un élève peut être annulé par un client modifié. | Supposé (comportement standard de LiveKit), à vérifier. | trouvé |
| SEC-4 | Aucune limite au nombre de jetons demandés. | Lu : migration `20261102500000` ligne 531. | trouvé |
| SEC-5 | Un contrôleur peut entrer dans toute séance en cours et lire la présence de toutes, sans mission. | Lu : migrations `20261017150100`, `20261102900000` ligne 432. | trouvé |
| SEC-6 | Le prénom et le matricule des camarades sont lisibles côté serveur par tout participant ; la règle « un enfant ne lit pas le prénom de ses camarades » n'est tenue que par l'écran. | Lu : migration `20261017120100` lignes 111-122. | trouvé ; note du 12/11/2026 : la règle du prénom est amendée par le directeur (D-040 : tout élève lit le prénom de ses camarades) ; la fuite du matricule par `session_peers_v` reste à fermer |
| SEC-7 | Le journal de la salle (entrées, sorties, jetons) peut être modifié ou effacé : seul `audit_logs` est protégé. | Lu : `0001_fondations.sql:197`, `577-581`. | trouvé |
| SEC-8 | Les textes d'accord disent « un cours peut être enregistré en audio » alors que rien n'enregistre. | Lu : textes français, lignes 1208-1239. Arbitrage déjà ouvert. | trouvé |
| S-3 | Le trait de l'enseignant n'apparaît chez l'élève qu'une fois terminé. | Lu : `reception_outils.dart:49, 63`. | trouvé |
| S-4 | Le repère du pointeur et des traits dépend de l'appareil : décalage probable entre un enseignant sur ordinateur et un élève au téléphone. | Lu, à mesurer. | trouvé |
| S-5 | Chaque page tournée par l'enseignant attend une réponse du serveur, alors que la page est déjà dans l'application. | Lu : `presentation_coran.dart:104-109`. | trouvé |
| S-6 | « Reprendre ta lecture » ne disparaît jamais (lecteur hors salle) : la position n'est pas enregistrée quand on glisse au doigt. | Lu : `mushaf_page.dart:866-958`, `vue_page_mushaf.dart:152-155`. | trouvé |
| S-7 | Bibliothèque vide en production ; aucune vraie couverture ; « Afficher » (seul) n'existe pas. | Lu ; une lecture en production le 11/11 : 0 support. | trouvé |

### Faibles

Identité partagée de la direction en salle ; l'émetteur d'un message de données n'est pas vérifié à
la réception ; deux portes écrites en négatif (`video_config_lire`, `quitter_salle`) ; un tuteur lit
les entrées et sorties de toute la classe de son enfant ; liste des sourates sans recherche, sans
nom arabe ni numéro de page ; priorité réseau de l'audio non réglée (corrigé dans le code avec V-1).

## 2 bis. Vu en séance réelle : une classe pleine (banc, 11/11/2026)

Un enseignant et **6 élèves** dans la même salle, caméras allumées : l'enseignant et trois élèves
(téléphone, tablette, ordinateur en sombre) sur la vraie application, trois élèves simulés.
Captures et journal : `docs/current/captures/E2E/salle-banc/classe-6/`.

**À dire d'abord.**

- **Douze élèves, c'est impossible aujourd'hui : la base l'interdit.** Une Classe a 6 élèves au plus
  (contrainte `groupes_seuil_max_check` ; réglages `groupe.capacite_adulte` 6, `capacite_enfant` 5,
  `capacite_debutant` 4 ; 7 participants par séance). Le cahier demande un essai à 8 ou 12 : il
  contredit les règles de l'académie. J'ai donc essayé le vrai maximum. Si le directeur veut des
  classes plus grandes, c'est une décision à prendre, et la salle devra être essayée à cette
  taille.
- **La fluidité mesurée ici ne vaut rien pour un vrai téléphone** : cinq navigateurs tournaient sur
  une seule machine sans carte graphique (3 à 8 images par seconde avec la galerie). Elle dit
  seulement que dessiner sept vidéos coûte cher ; il faut un essai sur un téléphone d'entrée de
  gamme. C'est la mesure qui tranchera la question du langage (journal D-001).
- La machine saturée a fait passer la salle en « réseau faible » : ce qui suit sur les messages de
  réseau a donc été vu par accident, mais c'est le vrai comportement de l'application.

Ce qui marche : tout le monde entre, se voit et s'entend ; chaque écran reçoit les six vidéos en
petite couche (le serveur adapte la taille) ; la page partagée arrive chez les trois élèves ; le
nouveau chrono et l'état unique s'affichent correctement en séance réelle.

Défauts vus (tous `trouvé`) :

| N° | Écran | Défaut vu | Gravité |
| :-- | :-- | :-- | :-- |
| C6-1 | Enseignant, ordinateur, page partagée | **Il ne voit plus aucun élève** : la galerie disparaît, il ne reste que sa propre vidéo en haut à gauche. Il fait réciter des élèves qu'il ne voit pas. | Élevé **11/11 (lot SALLE-ORDINATEUR)** : la vidéo de l'enseignant est rangée en tête du panneau des élèves ; panneau ouvert, il voit ses élèves et lui-même ensemble. Panneau fermé, il ne voit toujours personne : c'est voulu par le directeur (11/11). |
| C6-2 | Enseignant, ordinateur, page partagée | La page occupe une colonne étroite au milieu d'un grand vide ; la Bibliothèque reste ouverte à droite pour un seul support. | Élevé **11/11 : en partie.** Le haut est réparti sur la largeur et la page prend toute la hauteur libre, mais elle n'a grandi que de 8 % (342 x 566 vers 371 x 614 à 1440 x 900) : une page de quinze lignes est bornée par la hauteur de l'écran. Reste ouvert (double page, ou barres qui s'effacent). |
| C6-3 | Élève, téléphone, page partagée | La pilule d'état (trois lignes quand le message de réseau est long) et la vignette de l'enseignant recouvrent le titre de la sourate et la basmala ; une pilule blanche presque vide (le zoom) flotte sur le texte. | Élevé **Corrigé le 11/11 (lot ILE-SALLE, D-011)** : l'île se replie (cercle et temps restant seuls) ; vérifié dans la vraie application sur le banc (`captures/E2E/salle-banc/avant-enseignant/`). La vignette de l'enseignant sur le texte reste à traiter. |
| C6-4 | Tous | **Le message de réseau est dit deux fois** : dans la pilule (« Image coupée le temps que la connexion revienne. La voix continue. ») et dans un bandeau (« Réseau faible. L'audio est prioritaire. »). **Corrigé (code, lot RESEAU-ELEVES, D-017)** : dans `/salle`, l'île seule dit le réseau, une situation à la fois ; le bandeau et la pastille de présence ne redisent ni le réseau faible ni la reconnexion. Testé localement, non prouvé en production | Moyen |
| C6-5 | Enseignant | Sa vignette affiche **trois barres de réseau pleines et vertes** au moment même où le bandeau dit « Réseau faible » (défaut R-1, vu). | Élevé |
| C6-6 | Enseignant, galerie | « Ouvrir le Coran » est posé sur la vignette du premier élève ; chaque vignette porte un « … » au milieu de son bord, pas dans un coin ; les prénoms sont écrits en sombre sur la vidéo (illisibles). | Moyen |
| C6-7 | Enseignant, panneau des élèves | La liste défile dans un cadre de hauteur fixe (le quatrième élève est coupé) : interdit par `DECISION-DEFILEMENT-2026-11-01.md`. | Moyen |
| C6-8 | Élève, téléphone, galerie | L'enseignant a la même petite case que les cinq camarades ; sa propre image (« Vous ») et la barre des commandes recouvrent les deux dernières cases. Référence : sur téléphone, Meet et Zoom mettent en grand celui qui parle. | Élevé |
| C6-9 | Tous | Une infobulle (« Micro ouvert », « Caméra éteinte ») reste affichée après le geste. | Faible |
| C6-10 | Réseau faible | La caméra de chacun est coupée d'office dès que le lien est jugé médiocre. C'est voulu (la voix d'abord), mais personne ne le dit clairement : l'élève voit sa caméra « éteinte » sans savoir pourquoi. | Moyen |

## 3. Ce qui n'est pas confirmé

- **« La table des sourates n'est pas dans l'ordre officiel »** : non retrouvé. Les données et le
  code sont dans l'ordre (Al-Fatiha page 1, Al-Baqara page 2, Al-Imran page 50, An-Nas page 604,
  114 sourates). Il me faut l'écran exact où le directeur l'a vu.
- Le serveur LiveKit de production (région, offre, réglages) : inconnu depuis le dépôt.
- Tout ce qui est marqué « lu » reste à rejouer sur le banc.

## 4. Le banc d'essai

Dans `tool/salle/` : une vraie séance sur une pile locale (base, serveur de visio, application),
un navigateur par participant, un relais qui abîme le réseau à la demande (pertes en rafales,
latence, débit, coupure), l'enregistrement de ce que chacun entend et sa notation objective.
Mode d'emploi : `tool/salle/README.md`. Les mesures : `docs/current/salle/MESURES-VOIX.md`.
