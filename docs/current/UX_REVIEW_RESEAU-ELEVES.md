# Revue UX du lot RESEAU-ELEVES (11/11/2026)

Demande du directeur (cahier de la salle, §5 et §6) : l'élève comprend chaque mot de l'enseignant,
et l'inverse ; personne n'entend une voix déformée sans le savoir ; l'indicateur de réseau lit
l'état réel de chaque participant.

## À dire d'abord

- **Rien n'est prouvé en production.** Tout ce qui suit est présent dans le code et testé
  localement (tests unitaires et de rendu). Ni le directeur ni personne n'a vu ces signes sur un
  vrai réseau dégradé. Les captures sont **des captures de test** (qualités données à la main, pas
  de serveur de visio).
- **La qualité affichée est un indice, pas une preuve.** C'est la note de lien que LiveKit calcule
  pour chaque participant (pertes, gigue, débit vus par le serveur). Elle ne dit pas ce que
  l'auditeur entend vraiment : la mesure du « son reconstruit » par le navigateur
  (`MESURES-VOIX.md`) n'est **pas** lue en direct dans ce lot. C'est pourquoi toutes les phrases
  disent « peut-être ». Elles ne promettent pas plus que ce qu'on mesure.
- **La note locale de LiveKit mêle les deux sens.** Pour la personne devant l'écran, LiveKit donne
  une note de son lien, surtout montant (ce qu'elle publie). « On vous entend peut-être mal » en
  est la lecture la plus honnête ; ce n'est pas une mesure de ce que l'enseignant reçoit.
- **Écart à la demande** : la mission proposait « ou coupez votre caméra ». La salle coupe déjà
  la caméra locale d'elle-même quand le lien devient médiocre (repli audio, `repli_audio.dart`).
  Conseiller de couper une caméra déjà coupée serait faux : la phrase dit « fermez les autres
  applications » à la place.
- **Rien n'est conservé** (aucune écriture en base, aucun envoi au serveur). Le relevé comme preuve
  en cas de litige (cahier §6, défaut R-2) reste un autre lot, en attente de la décision du
  directeur sur la durée de conservation.

## Ce que fait le lot

| Situation | Qui | Ce qu'il voit |
| :-- | :-- | :-- |
| Un élève connecté, qualité mesurée et stable | Enseignant | Dans la carte de l'élève (panneau sur ordinateur, feuille au téléphone : le même `PanneauEleves`), les barres de `SignalVideo` à côté du statut : 3, 2, 1 ou 0 barre ; une seule barre en teinte d'attention ; lu « Bon réseau », « Réseau correct », « Réseau faible », « Réseau perdu » avec la carte |
| Pas encore de mesure stable | Enseignant | Aucun signe (jamais de barres inventées) |
| Lien de l'élève mauvais depuis 8 s | Enseignant | Une ligne dans la carte, icône du réseau et mot : « On entend peut-être mal Yasmine. » (micro ouvert) ou « Yasmine entend peut-être mal. » (micro fermé). Pas de son, pas de carte qui interrompt |
| Mon lien mauvais depuis 8 s, micro ouvert | Chacun (élève, enseignant) | L'île se déplie 6 s : « Votre connexion est faible : on vous entend peut-être mal. Rapprochez-vous du Wi-Fi ou fermez les autres applications. » ; tutoiement pour l'enfant ; en Interface guidée : « On t'entend peut-être mal. Rapproche-toi du Wi-Fi. » Puis l'île se replie sur un signe court (l'onde du réseau) tant que ça dure ; le lecteur d'écran lit toujours la phrase entière |
| Réseau faible (micro fermé ou moins de 8 s) | Chacun | L'île dit « Réseau faible. L'audio est prioritaire. » ou, si l'image est coupée, « Image coupée le temps que la connexion revienne. La voix continue. » ; plus de bandeau en plus |
| Reconnexion | Chacun | L'île, dépliée tant que ça dure : « Connexion interrompue. Reconnexion en cours… » ; ni bandeau, ni pastille de présence « Reconnexion » en plus |
| Les mêmes situations, au téléphone de l'enseignant (moins de 840 points) | Enseignant | Son île ne vit que dans le profil déplié : c'est le bandeau de secours, toujours visible, qui dit la situation, une seule fois (« on vous entend peut-être mal » d'abord, sinon le réseau faible ou la reconnexion). Choix fait pour ne pas toucher à la composition du téléphone de l'enseignant (lot d'un autre agent) |

## Règles confrontées

| Règle | Source | Date | Conclusion | Modification |
| :-- | :-- | :-- | :-- | :-- |
| Un état ne se dit pas par la couleur seule | WCAG 2.2, 1.4.1 ; `lib/CLAUDE.md` | lu le 11/11/2026 | Les barres portent trois signaux : nombre, teinte d'attention à une barre, libellé lu | `SignalVideo` réutilisé tel quel (aucun second composant) ; libellé ajouté à la lecture de la carte |
| Messages d'état annoncés sans voler le focus | WCAG 2.2, 4.1.3 | lu le 11/11/2026 | La phrase de la carte est un texte de la carte, pas une alerte ; l'île garde sa lecture existante | Aucun son, aucune carte modale |
| Ne pas faire clignoter | WCAG 2.2, 2.3.1 ; Nielsen 1 (visibilité de l'état, mais fiable) | lu le 11/11/2026 | Un signe ne change qu'après 3 s de qualité tenue ; la phrase après 8 s de mauvais lien, et elle ne s'éteint qu'au retour d'un bon lien stable | `FiltreQualite` (`lib/core/video/seuils_reseau.dart`), testé seconde par seconde |
| Un message à la fois, en haut | `MESSAGES-DE-LA-SALLE.md` §2, situations (B) | 11/11/2026 | Une situation de réseau ne se dit qu'une fois, dans l'île, la plus grave d'abord : reconnexion, « on vous entend peut-être mal », image coupée, réseau faible | `VueSeance.texteConnexion` (ordre), `texteBandeau` muet dans `/salle` (`reseauDansIle`), pastille de présence muette sur la reconnexion |
| Ce qui se passe, puis quoi faire | K-59 du dépôt | règle en vigueur | « Votre connexion est faible : on vous entend peut-être mal » (ce qui se passe) puis « Rapprochez-vous du Wi-Fi ou fermez les autres applications » (quoi faire) | Textes `salle.reseau.*` |
| Interface guidée : moins de mots | `MESSAGES-DE-LA-SALLE.md` §4 ; Children's Code | 11/11/2026 | Forme courte, tutoiement | `onTEntendMalGuidee` |
| Un enfant ne lit pas le prénom d'un camarade | `MESSAGES-DE-LA-SALLE.md` §6, n° 19 | 11/11/2026 | Le réseau des élèves n'est montré qu'à l'enseignant (panneau qu'il est seul à avoir) | Aucun signe chez les élèves |
| Rien ne pousse la page du Coran | règle du directeur, 11/11/2026 | 11/11/2026 | L'île garde sa place et sa forme (dépliée par-dessus un court instant, puis repliée) ; la carte d'élève est dans le panneau, hors de la page | Aucun changement de composition |
| Contraste du texte d'attention | WCAG 2.2, 1.4.3 | lu le 11/11/2026 | La phrase de la carte est écrite à l'encre `inkWarning` déjà employée pour « Pas encore connecté » dans la même carte | Aucune couleur nouvelle |

## Seuils et durées

- **Seuil** : `mediocre` ou `perdue` (`lienMauvais`), le même que le repli audio. Pourquoi :
  `MESURES-VOIX.md`, tableaux « Résultats » : sous un lien de type 3G ou des pertes isolées jusqu'à
  20 %, la voix arrive sans mot perdu ; les mots tombent sous des pertes en rafales de 10 % et plus,
  qui sont aussi le moment où LiveKit passe la note à « médiocre » et où la salle coupe l'image
  (« La règle : ce que l'application fait sous chaque seuil », ligne « Lien médiocre »). Une note
  « bonne » (deux barres) ne déclenche donc rien.
- **3 s** (`tenueAvantChangement`) : écarte une rafale d'une ou deux secondes, reste court devant
  une phrase de récitation.
- **8 s** (`tenueAvantAlerte`) : « depuis plusieurs secondes » (directeur), plus de deux fois la
  tenue d'un signe : la phrase ne vient qu'après un signe déjà stable.
- **Ce qui reste à mesurer** : la correspondance entre la note de LiveKit et le son reconstruit
  réel n'a pas été chiffrée sur le banc ; le passage à la règle « 1 % / 5 % de son reconstruit »
  proposée dans `MESURES-VOIX.md` demande de lire les statistiques WebRTC en direct (lot à venir).

## Vérifié et non vérifié

| Point | Statut |
| :-- | :-- |
| Barres par élève, phrase, île, un seul message | présent dans le code, testé localement |
| La qualité des participants distants arrive bien de LiveKit | lu dans `livekit_client` 2.12.0 (`room.dart`, `_onSignalConnectionQualityUpdateEvent` met à jour chaque participant distant) ; déjà traduite par `_traduire` ; **non vu sur un vrai serveur** |
| Comportement sur un vrai réseau dégradé (banc `tool/salle/reseau_degrade.mjs`) | non essayé dans ce lot |
| Preuve du directeur en production | non faite |
