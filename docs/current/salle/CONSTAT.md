# Constat de la salle

Tenu par Fable (mission `docs/current/CAHIER-SALLE.md`). Dernière mise à jour : 11/11/2026.

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
| V-1 | **La voix part sans protection contre les pertes.** La redondance audio (RED) était demandée dans le code mais jamais obtenue : la bibliothèque LiveKit 2.12.0 inverse le réglage. Un paquet perdu = un morceau de mot perdu. | **Mesuré** le 11/11 : la voix de l'enseignant part en `audio/opus` seul, 24 kbit/s. Cause lue dans `livekit_client` (`participant/local.dart:190`). | corrigé (code), mesure avant et après en cours |
| V-2 | **Personne ne sait qu'une voix arrive déformée.** Aucune mesure de pertes ou de son reconstruit n'est montrée à l'élève ni à l'enseignant. | Lu : `diagnostic_transport.dart` mesure mais n'affiche rien et ne garde rien. | trouvé |
| S-1 | **Au téléphone, l'enseignant ne peut pas tourner la page.** Ni flèches, ni glisser, ni pagination dans son tiroir : il ne peut ouvrir que le début d'une sourate. | Lu : `telephone_plein_ecran.dart:138-141`, `telephone_enseignant.dart:438-474`. | trouvé |
| S-2 | **Le partage ne connaît que le Coran.** Le message « page partagée » ne dit pas de quel support il s'agit ; 604 pages en dur jusque dans la base. | Lu : `video_session_provider.dart:439-445`, migration `20261110100000` ligne 49. | trouvé |

### Élevés

| N° | Défaut | Preuve | État |
| :-- | :-- | :-- | :-- |
| R-1 | **Les barres de réseau sont factices.** Toujours trois barres pleines. | Lu : `signalEnseignant = 3` (`vue_seance.dart:563`), jamais modifié ailleurs. | trouvé |
| R-2 | **Aucune trace de la qualité de connexion n'est conservée.** Rien à opposer à une famille qui accuse l'académie. | Lu : les mesures partent en miettes de supervision, jamais en base. | trouvé |
| R-3 | **Après un passage par un mauvais réseau, l'image ne revient pas.** Le retour attend deux bonnes mesures de suite, mais LiveKit n'en envoie qu'une quand la qualité ne change plus. « Image coupée » reste affiché. | Lu : `repli_audio.dart:28` contre `livekit_client` `participant.dart:218`. À rejouer au banc. | trouvé |
| SEC-1 | **Des élèves mineurs peuvent être en salle sans enseignant**, micro ouvert, 20 minutes avant l'heure et après son départ. La salle n'est jamais fermée par le serveur. | Lu : migration `20261102500000` ligne 470 ; aucun appel de fermeture de salle. | trouvé |
| G-1 | **« Appeler discrètement » ne se voit pas chez l'élève qui lit.** Le bandeau dure 5 s dans une couche déjà masquée ; le premier son est très probablement muet dans un navigateur ; l'enseignant n'a aucun retour. | Lu : `telephone_plein_ecran.dart:596-603`, `signal_rappel_web.dart:52-54`. | trouvé |
| G-2 | **« Faire réciter » ne fait que poser une étiquette.** Il n'ouvre aucun micro, ne coupe personne, et l'élève choisi n'est pas prévenu. | Lu : `salle_page.dart:966-977`. | trouvé |
| P-1 | **Le pointeur est haché et peut rester figé.** 20 positions par seconde, sans lissage ni sillage ; la dernière position et le « lever » peuvent se perdre. | Lu : `surface_page_fixe.dart:596-617`, `synchro_salle.dart:345-378`. | trouvé |
| C-1 | **Connexion perdue : aucune reprise automatique**, et micro et caméra reviennent fermés. | Lu : `salle_page.dart:430-431`, `549-611`. | trouvé |
| D-1 | **La vidéo de l'enseignant s'affiche deux fois sur son écran** (vignette et cadre flottant), caméra allumée et rien de partagé. Sur le même écran : « Ouvrir le Coran » et un bouton « … » posés au milieu, l'élève réduit à une pastille dans un grand vide, la rangée de filtres de la Bibliothèque coupée. | **Vu** sur la capture du banc (enseignant, 1440 × 900). Lu : `salle_page.dart:1576-1583` et `3667-3725`. | trouvé |
| D-3 | **L'état est dit deux fois et le chrono est bavard** (directeur, 11/11) : « En ligne » et « En salle » côte à côte ; « 00:03:15 écoulé · 00:56:44 restant » ; rien n'est animé ; après la fin prévue le chrono s'arrête sur une phrase au lieu de compter le dépassement. | **Vu** sur la capture du banc (élève au téléphone) ; `pilule_etat_salle.dart`, `chrono_salle.dart`. Le réglage du dépassement existe déjà côté serveur (`grace_after_end_minutes`, 15 par défaut). | trouvé |
| D-2 | **Le chronomètre est caché** au téléphone de l'enseignant (dans le profil déplié) et masqué après 3 s chez l'élève. | Lu : `telephone_enseignant.dart:371-377`. | trouvé |
| N-1 | **Douze élèves : jamais essayé.** Abonnement à toutes les vidéos, galerie pensée pour six. | Lu : `salle_page.dart:3733-3840`. Essai à 12 au banc à faire. | trouvé |
| W-1 | **Premier chargement lourd.** L'application pèse environ 5 à 6 Mo compressés à la première visite : près de deux minutes sur un réseau 3G. | **Mesuré** le 11/11 : `main.dart.js` 15,6 Mo (3,6 Mo compressé) plus le moteur d'affichage. | trouvé |

### Moyens

| N° | Défaut | Preuve | État |
| :-- | :-- | :-- | :-- |
| SEC-2 | Un élève sorti de la salle peut revenir tant que son jeton est valable (15 min par défaut). | Lu : migration `20261102100000` lignes 20-21. | trouvé |
| SEC-3 | « Couper le micro » d'un élève peut être annulé par un client modifié. | Supposé (comportement standard de LiveKit), à vérifier. | trouvé |
| SEC-4 | Aucune limite au nombre de jetons demandés. | Lu : migration `20261102500000` ligne 531. | trouvé |
| SEC-5 | Un contrôleur peut entrer dans toute séance en cours et lire la présence de toutes, sans mission. | Lu : migrations `20261017150100`, `20261102900000` ligne 432. | trouvé |
| SEC-6 | Le prénom et le matricule des camarades sont lisibles côté serveur par tout participant ; la règle « un enfant ne lit pas le prénom de ses camarades » n'est tenue que par l'écran. | Lu : migration `20261017120100` lignes 111-122. | trouvé |
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
