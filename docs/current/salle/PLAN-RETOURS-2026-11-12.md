# La salle après l'essai du directeur du 12/11/2026 : diagnostic et plan

Le directeur a tenu une vraie séance dans la salle le 12/11/2026 : « En général, la salle est bien
réussie. Aujourd'hui je l'ai utilisée, ça a bien marché. Il reste quelques corrections. » Treize
demandes, quatre captures annotées (`docs/current/captures/directeur/2026-11-12-salle/`, branche
`claude/salle-retours-directeur-1211`). Ce document dit la cause de chaque défaut et le plan.

## D'abord : ce qui est faux, bloqué ou non prouvé

- **Rien n'est corrigé à la date de ce plan.** Les causes viennent de la lecture du code ; quatre
  sont vérifiées par moi ligne par ligne (marquées « vérifié »), aucune n'est encore reproduite à
  l'écran ni mesurée.
- **L'entrée difficile du deuxième élève (point 11) n'a pas de cause racine prouvée.** Aucune règle
  du serveur ne refuse un deuxième élève. Ce qui est établi : la première connexion ne fait qu'un
  essai, ne se reprend jamais seule, et son échec n'est enregistré nulle part. La raison de l'échec
  lui-même reste inconnue tant que rien ne l'enregistre.
- **La règle de paie du directeur n'est pas entièrement respectée par le code** (point 4) : jusqu'à
  15 minutes après la fin prévue comptent dans les minutes de présence et peuvent augmenter la paie.
  La corriger est une décision d'argent : préparée ici, livrée seulement avec la confirmation du
  directeur.
- **Les marges des pages (point 12) contredisent une règle du directeur des 24 et 25/10** (« la page
  est l'écran », S0.2c, S0.2d, K4). Sa demande du 12/11 est plus récente : elle prime, et elle
  amende cette règle. Les marges réduisent un peu la taille du texte.
- **Qui met en production** : la règle écrite (`DECISION-AUTONOMIE-2026-10-29.md`) dit « le pilote
  seul ». Le message relayé du 12/11 dit que le pilote est retiré. Tant que le directeur ne l'a pas
  dit lui-même, tout reste sur la branche.

## Les causes, point par point

| N° | Demande | Cause | Où |
| --: | :-- | :-- | :-- |
| 1 | La tête du pointeur cache le mot | La tête est un disque plein de 32 points, opaque (cerne, anneau, cœur). Le sillage, lui, s'efface en 350 ms : sans tête, un pointeur immobile disparaît | `pointeur_salle.dart` l. 139-142, 319-338, 347-386 |
| 2 | Le chrono cache le document | **Téléphone (vérifié)** : hors Interface guidée, la page prend tout l'écran (`superposee: true`) et le haut (île du chrono, pastilles « En retard », « X récite ») flotte dessus. **Tablette et ordinateur** : la tête de la colonne a une hauteur fixe calculée pour l'île seule ; le texte de pause et le lien « Démarrer la pause » débordent et passent sous la colonne sombre | `telephone_plein_ecran.dart` l. 245-253, 777, 821-835 ; `salle_ordinateur.dart` l. 1292-1294, 1345-1352 ; `chrono_salle.dart` l. 367-403 |
| 3 | Le chrono n'a pas de contexte | Les chiffres sont le temps restant, mais le mot n'est donné qu'au lecteur d'écran | `chrono_vivant.dart` l. 122 ; `chrono_salle.dart` l. 332-335 |
| 4 | Les marges ne doivent pas compter | **Vérifié** : avant le début, rien ne compte (conforme). Après la fin, la présence est comptée jusqu'à la fin prévue plus la grâce (15 min) : cela peut faire atteindre le seuil de la séance due (45 ou 70 min) et compter présent un élève venu seulement pendant la marge. Rien ne dit à l'enseignant ce qui compte | `20261107500000_fn_serveur.sql` l. 56-59, 83 ; `20261102900000_presence_minutes.sql` l. 178-189, 285-300 ; `20261122700000_lumiere_retard_eleve.sql` l. 79-81 |
| 5 | La « Dynamique chrono » | Aucune arrivée d'élève n'est signalée ; une seule teinte hors « bientôt » et « dépassement » (la pause n'a pas de couleur) ; l'appel et la récitation passent par une annonce à part, pas par la barre | `chrono_vivant.dart` l. 43-55, 204-213 ; `salle_page.dart` l. 447-505 |
| 6 | La sonnerie est trop courte | Deux notes de 250 ms, jouées une fois | `signal_rappel_web.dart` l. 47-56 |
| 7 | Miniatures et avatars | Le fond du cadre (`surfaceSunken`) et celui de la page (`surfaceCanvas`) sont presque identiques en clair. Avatar décalé : dans une petite miniature, une rangée de nom vide reste sous le rond et le pousse vers le haut. La couleur par élève (`accent_key`) et la photo de profil existent, la salle ne les lit pas | `cadre_visage.dart` l. 102, 176, 219-223 ; `avatar_nom.dart` l. 417-458 ; `port_accents_profils.dart` ; `photo_personne.dart` |
| 8 | Le fond de la salle | La grille des visages n'a aucun fond propre : on voit le fond de page, très clair | `scene_classe.dart` l. 172-233 ; `scene_attente.dart` |
| 9 | L'orateur trop discret | Un anneau fin, allumé ou éteint. La salle ne reçoit qu'un « parle / ne parle pas » ; la force de la voix n'est pas remontée de la visio | `cadre_visage.dart` l. 243-258 ; `livekit_session_provider.dart` l. 620, 911 |
| 10 | « Coran » devient « Bibliothèque » | Le bouton ouvre le choix d'une sourate, pas la Bibliothèque, qui existe à côté (panneau, tiroir) | `salle_page.dart` l. 2178-2182, 2594-2603 ; `etagere_supports.dart` |
| 11 | Le deuxième élève entre mal | **Vérifié** : un seul essai de connexion, aucun essai automatique à la première entrée (la reprise à 5 essais n'existe qu'après une première connexion réussie), l'appel du jeton n'a pas de délai, l'échec n'est écrit nulle part. Piste non prouvée : le son reçu bloqué par le navigateur chez un élève entré micro fermé | `livekit_session_provider.dart` l. 497-503 ; `salle_page.dart` l. 917-924 ; `service_video.dart` l. 238-252 |
| 12 | Pages trop près des bords | Voulu jusqu'ici : zéro marge, zéro arrondi quand la page est en plein cadre ; la seule marge est de 0,3 corps de texte | `page_coran_salle.dart` l. 143-153 ; `page_madina_15.dart` l. 199, 317 |
| 13 | Tourner une page « plante » | **Vérifié** : l'enseignant attend deux lectures du serveur avant d'envoyer la page, puis deux autres (par un autre cache) pour l'afficher ; rien ne bouge pendant ce temps. Chez l'élève : un bloc gris de 6 lignes remplace la page, puis la nouvelle arrive d'un coup. Aucun préchargement, aucun fondu | `presentation_coran.dart` l. 105-117 ; `moteur_mushaf.dart` l. 48-76 ; `page_coran_salle.dart` l. 105-111 |

## Les décisions de conception (une seule règle par sujet)

1. **La « Dynamique chrono » est la seule barre d'état de la salle.** Elle a une place réservée,
   jamais posée sur le contenu : au téléphone, une rangée de toute la largeur au-dessus de la page ;
   sur tablette et ordinateur, la tête de la colonne, à hauteur connue. Repliée, elle tient sur une
   ligne : l'anneau, « Reste 37:51 », et des marques (points de couleur). Un toucher la déplie et
   montre tout (pause, actions, qui récite, qui arrive) ; elle se replie seule.
2. **Tout événement passe par elle** : arrivée d'un élève (+1, chiffre qui roule), appel, récitation,
   retard. Une alerte qui doit couvrir l'écran disparaît en quelques secondes et laisse une marque.
3. **Rien ne cache le contenu** : ni la barre, ni une pastille, ni la tête du pointeur.
4. **Les couleurs de la barre** : une pour le temps normal, une pour la pause, une quand il reste
   peu de temps, une pour le dépassement ; jamais la couleur seule (un mot ou une icône avec).
5. **Un seul cadre de visage** (`CadreVisage`) : fond plus marqué, photo quand elle existe, sinon
   une couleur par personne ; la lumière de l'orateur est dans le cadre, en vagues, selon la voix.
6. **La page a un cadre et des marges** partout (téléphone, tablette, ordinateur), et le fond doux
   de la salle (logo et portail, très faible opacité) ne se pose que derrière les visages, jamais
   derrière un document.
7. **Tourner une page ne fait jamais attendre** : la page change tout de suite chez celui qui
   tourne, les pages voisines sont déjà lues, l'ancienne page reste jusqu'à l'arrivée de la
   nouvelle, avec un fondu court.

## Les lots

| Lot | Contenu | Points | Dépend de |
| :-- | :-- | :-- | :-- |
| ENTREE-ROBUSTE | Deux à trois essais automatiques à la première entrée, délai sur l'appel du jeton, échec enregistré, son débloqué d'un geste si le navigateur le bloque. Aucune règle du serveur ne change | 11 | - |
| PAGES-FLUIDES | Un seul cache de page, page tournée tout de suite, pages voisines préchargées, ancienne page gardée puis fondu ; cadre et marges des pages | 12, 13 | - |
| VISAGES | Contraste des cadres, photo, couleur par personne, avatar centré, fond doux derrière la grille, lumière de l'orateur selon la voix | 7, 8, 9 | - |
| POINTEUR | Tête en anneau léger qui laisse lire le mot, sillage gardé, pointeur immobile toujours visible | 1 | - |
| DYNAMIQUE-CHRONO-1 | La place réservée de la barre (téléphone, tablette, ordinateur), le mot « Reste », les pastilles rentrées dans la barre, replié et déplié | 2, 3 | PAGES-FLUIDES |
| BIBLIOTHEQUE-SALLE | « Bibliothèque » ouvre l'étagère existante, le Coran en premier document (accord de l'architecte pédagogique : aucune seconde grille, aucune seconde source) | 10 | - |
| DYNAMIQUE-CHRONO-2 | Arrivées, couleurs, appel dans la barre et sonnerie répétée, récitation montrée à tous | 5, 6 | DYNAMIQUE-CHRONO-1 |
| REGLE-CHRONO | Serveur : seules les minutes entre le début et la fin prévus comptent ; retard borné à la fin ; écran : dire à l'enseignant ce qui compte | 4 | confirmation du directeur |
| HARMONIE-SALLE | Relecture d'ensemble de la salle (une seule logique, un seul langage de mouvement), liste des bricolages, corrections | 13 | les lots précédents |

Chaque lot : les six vérifications, des tests à travers le vrai `RewayahApp` et le vrai routeur
quand il touche une page, ses captures sous `docs/current/captures/E2E/<lot>/`, sa ligne au
registre et au journal de la salle.

## Compléments du directeur, 12/11/2026 à 21:05 et 21:15 UTC (dits par lui, directement)

Captures : `docs/current/captures/directeur/2026-11-12-salle/5-telephone-camera-ne-s-allume-pas.jpg`
et `6-telephone-compte-deja-connecte.jpg`.

| N° | Ce qu'il a dit | Ce que cela change | État |
| --: | :-- | :-- | :-- |
| 9 (corrigé) | « Il faut juste changer l'effet qui existe déjà (un rectangle violet). J'ai pas dit d'adapter au volume de sa voix. » | La lumière de l'orateur suit le seul « parle / ne parle pas ». La force de la voix n'est pas remontée de la visio : cette partie du plan est retirée | Lot VISAGES recadré à 21:09 |
| 14 | La pause est un réglage ; l'enseignant la gère lui-même. Par défaut, juste après le milieu de la séance (45 min pour une classe d'adultes), la barre du chrono propose une pause de 10 min : Oui ou Non. Oui : tous reçoivent l'alerte dans leur barre, avec l'heure exacte de reprise. Non : rappel après quelques minutes (réglable par la direction, 5 par défaut), « car la pause est un droit ». « À toi de décider et d'arbitrer. » | Lot PAUSE-PROPOSEE, dans la Dynamique chrono. Arbitrages à écrire après le relevé de l'existant (réglages, nombre de rappels, enfants) | Relevé en cours |
| 15 | La barre du chrono marche bien quand la salle est réduite ; « il faut qu'il soit exploité au max ». | La salle réduite porte la même barre, avec les mêmes événements (pause, appel, arrivées) | À concevoir avec DYNAMIQUE-CHRONO |
| 16 | L'enseignant qui sort de la salle perd le son et doit revenir vite. « L'enseignant ne doit pas être prisonnier de sa salle » : il peut sortir de l'application et continuer à entendre. Demande déjà faite, non tenue. | Lot HORS-SALLE. Cause à trouver. Limite à dire : sur une application web, c'est le téléphone et le navigateur qui décident de ce qui continue en arrière-plan ; à essayer sur de vrais téléphones | Relevé en cours |
| 17 | L'élève peut sortir de la salle sans coupure ; s'il sort de l'application, un court délai sans coupure, puis coupure. Toutes ses sorties de l'application sont consignées au rapport (nombre, fréquence, de quand à quand). | Lot HORS-SALLE. Nouvelle donnée relevée sur des mineurs : elle ne commence pas sans information des parents (règle du cahier de la salle) ; texte à valider par le directeur | Relevé en cours |
| 18 | La caméra de l'élève entré par un appareil jumelé ne s'allume pas ; message long. | Capture 5 : ce n'est pas un refus du serveur. Le téléphone dit que la caméra est déjà prise (« NotReadableError »). Piste à vérifier : le lecteur de code du jumelage garde la caméra. Le message montre une phrase technique en anglais : à retirer de l'écran | Relevé en cours ; message traité dans ENTREE-ROBUSTE |
| 19 | Rejoindre alors que le même compte est déjà connecté : « c'est bien, mais pas très clair comme signe ». | Capture 6 : l'écran dit « La salle n'a pas pu s'ouvrir, vérifiez votre connexion », un message de réseau pour une cause qui n'est pas le réseau. Le bon message existe (« ouverte ailleurs ») mais n'est pas posé dans ce cas. Piste pour le point 11 : deux appareils du même compte qui se chassent | Traité dans ENTREE-ROBUSTE |

## Relevés et arbitrages du 12/11/2026, 21:18 UTC (points 14 à 19)

### La caméra de l'appareil jumelé (18) : cause vérifiée dans le code

Le lecteur de code du jumelage (`mobile_scanner` 7.4.2) ne ferme jamais la caméra dans un navigateur :
son arrêt oublie le flux sans arrêter ses pistes (`polling_barcode_reader.dart` l. 151-159,
`mobile_scanner_web.dart` l. 587-594 et 614-618, lus par moi). L'application est à page unique : la
caméra arrière reste donc ouverte jusqu'à la salle, et la caméra avant ne peut plus s'ouvrir. Que
ce soit bien la cause sur le téléphone du directeur reste à prouver sur ce téléphone ; que le flux
ne soit pas fermé est prouvé. Autres faits : l'enseignant n'a aucun geste « allumer la caméra d'un
élève » (il peut seulement la couper) ; le droit de l'élève jumelé est le même que celui d'un élève
à compte propre. Lot CAMERA-JUMELAGE : notre code ferme lui-même le flux, preuve dans un vrai
navigateur.

### La pause (14) : l'existant et les arbitrages

L'existant : la pause n'existe que si l'enseignant l'a activée dans la fiche de sa classe (inactive
par défaut), à un moment fixe compté depuis son entrée ; un lien « Démarrer la pause » ; les élèves
l'apprennent par un message de la visio ; rien ne la propose, rien ne la rappelle, rien ne la finit
à l'heure. Les réglages « pause adulte / enfant » de la base (0 et 5) ne pilotent rien.

| Sujet | Arbitrage |
| :-- | :-- |
| Par défaut | La pause est active pour toute classe. Le réglage de la fiche de classe reste à l'enseignant et prime (il peut la déplacer, l'allonger, la couper) |
| Moment | Le milieu de la durée prévue, compté depuis l'heure prévue de début : 45 min sur 90, 30 min sur 60 |
| Durée | Réglage de la direction : 10 min adultes (la décision du 18/10 n'était pas appliquée : 0 en base), 5 min enfants |
| Oui / Non | Oui : la pause commence, tous reçoivent l'alerte et l'heure exacte de reprise. Non : rappel après 5 min (réglage de la direction) |
| Combien de rappels | Tant que la pause tient encore : on ne propose plus si, après elle, il resterait moins de 15 min de cours (réglage de la direction). Ensuite, « pause non prise » au récapitulatif |
| L'enseignant décide | Il peut démarrer la pause lui-même à tout moment, proposée ou non, et la finir plus tôt |
| Fin | À l'heure annoncée, la pause finit seule ; la barre le dit à tous |
| Argent, présence | Rien ne change : la pause est comprise dans la séance (« pause comprise », décision des tarifs) |
| Élèves | Ils ne lisent toujours rien sur le serveur : le message de la visio reste la voie |

Lots : PAUSE-SERVEUR (base, réglages de la direction, port ; lancé), puis l'écran dans la Dynamique
chrono (DYNAMIQUE-CHRONO-2).

### Hors de la salle (16, 17) : l'existant

Le code actuel ne coupe rien quand on quitte l'écran de la salle (la visio vit hors de la page
depuis le 31/10 et le 11/11), ni quand l'application passe en arrière-plan. Trois pistes pour la
coupure vécue par le directeur, aucune prouvée : le téléphone lui-même suspend le réseau d'une
application web en arrière-plan ; le son reçu reste bloqué par le navigateur après une reprise
(personne n'écoute ce blocage, le son n'est relancé qu'au retour à l'écran) ; la version essayée
n'avait pas ces corrections. Rien n'est écrit au serveur quand l'application passe en arrière-plan
ou en revient : une sortie d'application ne se distingue pas d'une coupure de réseau.

| Sujet | Arbitrage |
| :-- | :-- |
| Enseignant | Rien n'est jamais coupé par l'application. Le son reçu est relancé après toute reprise, pas seulement au retour à l'écran. Ce que le téléphone coupe lui-même est mesuré et écrit au relevé de connexion, pour le prouver à l'essai suivant |
| Élève hors de la salle, dans l'application | Rien n'est coupé (déjà le cas) |
| Élève hors de l'application | 30 secondes sans coupure (réglage de la direction), puis sa place est rendue ; il rentre d'un geste à son retour |
| Journal des sorties | Chaque sortie de l'application : de quand à quand ; au rapport de séance : nombre et durée totale. Lisible par la direction, l'enseignant de la séance et le parent de l'élève |
| Information des parents | Le journal reste éteint (réglage de la direction) tant que le directeur n'a pas validé la phrase d'information aux familles : rien n'est relevé sur un mineur sans information |

Lot HORS-SALLE : après ENTREE-ROBUSTE (mêmes fichiers).

## Compléments du directeur, 12/11/2026 vers 22:50 UTC (dits par lui, directement)

| N° | Ce qu'il a dit | Ce que cela change | État |
| --: | :-- | :-- | :-- |
| 20 | « Il faut que les autres élèves voient celui qui récite, au moins une partie du nom, la photo, car ils partagent une salle ; [...] mais la vraie vidéo, c'est seulement celui qui récite ; sinon on ne voit que sa photo ; la vidéo reste coupée. » | Tranche la question ouverte de la fiche 0 (ligne 11, Q7 contre D-028 et D-031). Relevé : les élèves se voient déjà en grille et la photo est déjà permise aux camarades (K-44, 09/10) ; manquent le prénom chez les enfants et la règle sur la vidéo (aujourd'hui rien n'empêche la vidéo d'un camarade de s'afficher) | Lot CAMARADES, en cours |
| 21 | « Sur ta première capture j'ai vu le dynamique timing posé sur les panneaux et la barre sur desktop ; si c'est comme ça que ça va s'afficher en réel, alors tu rectifies. » | Le chevauchement était réel (île dépliée d'office, boîte à débordement en tête de colonne). Corrigé par DYNAMIQUE-CHRONO-1 : la barre vit en tête de la colonne, 16 tests de géométrie | Sur la branche |

Trois défauts trouvés par le relevé du point 20 : le texte du dépôt de la photo d'un enfant ne dit
pas qui la verra (corrigé dans CAMARADES, texte à valider par le directeur) ; un texte jamais
affiché dit l'inverse du serveur (retiré dans CAMARADES) ; la vue `session_peers_v` rend le prénom
et le matricule des autres participants d'une séance à tout participant (constat SEC-6) : la fermer
demande de remplacer une vue, donc une installation par le directeur ; pas fait.

## Où en sont les lots, au 13/11/2026 à 00:17 UTC

Tout est sur `claude/zealous-tesla-ewstzw`. Rien sur staging, rien en production, rien prouvé par
le directeur. Les preuves sont des tests et des captures de test, sauf mention.

| Lot | Points | État |
| :-- | :-- | :-- |
| POINTEUR | 1 | Sur la branche |
| VISAGES | 7, 8, 9 | Sur la branche. La couleur d'une personne sans photo est une teinte stable, pas l'accent choisi par le tuteur (le serveur ne le rend qu'au foyer) |
| BIBLIOTHEQUE-SALLE | 10 | Sur la branche |
| ENTREE-ROBUSTE | 11, 18 (message), 19 | Sur la branche. La cause des entrées difficiles du 12/11 reste inconnue ; chaque échec est désormais supervisé |
| PAGES-FLUIDES | 12, 13 | Sur la branche. Le texte rétrécit de 3 à 8 % |
| CAMERA-JUMELAGE | 18 | Sur la branche. Prouvé dans Chromium (pistes fermées après le lecteur) ; pas sur un vrai téléphone |
| PAUSE-SERVEUR | 14 | Sur la branche. Migration `20261124100000_pause_proposee.sql` rejouée en local, NON installée |
| HORS-SALLE-1 | 16, 17 | Sur la branche. Rien d'essayé sur un vrai téléphone ; aucune ligne enregistrée sur un élève |
| DYNAMIQUE-CHRONO-1 | 2, 3, 5 (place), 15, 21 | Sur la branche |
| DYNAMIQUE-CHRONO-2 | 5, 6, 14 (écran), 15 | Sur la branche (13/11, 02:02 UTC). La sonnerie n'est pas essayée dans un vrai navigateur ; la salle réduite ne reçoit ni la récitation ni les arrivées ; une pause démarrée hors de la salle n'est pas relayée aux élèves sur le moment ; le délai de rappel sans réponse est une constante de l'application |
| CAMARADES | 20 | Sur la branche (13/11, 01:23 UTC). Migration `20261124300000_camarades_prenoms.sql` rejouée en local, NON installée. La règle de la vidéo est tenue par l'application, pas encore par le serveur de visio. Texte du dépôt de la photo à valider par le directeur |
| HORS-SALLE-2 | 17 (journal des sorties) | Pas commencé : pour un mineur, l'accord du parent est exigé (règle du 11/11, `DROIT-RELEVE-QUALITE.md` §10 point 3) et le mécanisme d'accord n'existe qu'en démonstration |
| RETRAIT | prière | Pas commencé : « Je m'absente un instant », sans trace ; règle convenue avec l'architecte pédagogique |
| REGLE-CHRONO | 4 | Attend la confirmation du directeur (argent) |
| HARMONIE-SALLE | 13 | Sur sa branche (13/11). Relevé `HARMONIE-2026-11-13.md`, journal D-044. Sur ordinateur, l'état de repos prime (la colonne se tasse le temps d'un dépli) ; synchronisation hors de la page non faite (plan écrit) |

### Depuis ce tableau (13/11/2026, 02:07 UTC)

- Onze lots sont sur la branche et dans la demande de fusion en brouillon
  `rewayahacademy-glitch/Rewayah-Academy-Official-App#449`.
- Suite complète sur neuf lots (tête `eee1b2a5`) : 20 824 tests passés, 1 échec (une durée sécable
  dans le message de retour de l'élève), corrigé. Contrôles de la demande de fusion sur dix lots
  (tête `835d0899`) : tous verts, migrations rejouées sur Postgres 17 comprises. Sur onze lots
  (tête `f7b0935f`) : 4 518 tests de la salle et des gardes passés ici ; contrôles en cours.
- Restes connus, à reprendre dans HARMONIE-SALLE : sur ordinateur, les noms des tuiles de la
  colonne disparaissent le temps où la barre est dépliée sur un écran bas ; au téléphone, la ligne
  d'état passe sur le haut de la page le temps où la barre est dépliée ; la fermeture de la vidéo
  des camarades côté serveur ; la fuite du matricule par `session_peers_v`.

