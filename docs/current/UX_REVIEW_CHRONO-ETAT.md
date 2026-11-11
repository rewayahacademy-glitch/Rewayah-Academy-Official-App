# UX_REVIEW CHRONO-ETAT : le chrono vivant et l'état unique de la salle

Lot demandé par le directeur (cahier de la salle §8, 10/11/2026 ; remarque du 11/11/2026 sur une
capture du banc d'essai : « en ligne / en salle = doublon », « le chrono trop verbatif montre
seulement ce qui reste », « quand le chrono est à 0 ça bip et il continue par ordre croissant »,
« les minutes ajoutées après la durée officielle doivent être un réglage côté admin », « bien
animé avec des effets visuels visibles et modernes »).

Disposition `PROPOSITION` confrontée aux référentiels (DESIGN-GOV §4). Aucune règle métier
modifiée : le chrono ne donne ni droit, ni preuve de présence, ni décision. Il remplace la ligne
de LIVE-CHRONO-01 (`UX_REVIEW_LIVE-CHRONO-01.md`), dont il garde les règles d'accessibilité.

## Ce qui est proposé

- **Une capsule** (`ChronoVivant`, `lib/core/widgets`) devant la pilule d'état : un anneau qui se
  remplit, et le temps restant seul (`56:44` ; `1:02:10` au-delà d'une heure).
- **Cinq minutes avant la fin**, la capsule de qui conduit la séance passe à la teinte
  d'attention. **À la fin prévue**, elle passe à la teinte d'alerte et compte le dépassement en
  croissant (`+03:12`), jusqu'au dépassement autorisé, puis dit « Temps prévu écoulé ».
- **Le dépassement autorisé** est le réglage serveur `grace_after_end_minutes` (15 par défaut),
  déjà servi à l'application par `horloge_classe`. Rien n'est décidé par l'écran.
- **Un seul mot d'état** : « En salle » dès que le serveur a confirmé la présence, sinon l'état de
  la connexion (« En ligne », « Reconnexion… »). La pastille de présence ne reste que pour ce qui
  s'en écarte (« Pas encore là », « En retard »).
- **Mouvement** : chaque chiffre qui change roule ; la capsule s'étire quand les chiffres changent
  de nombre ; elle « respire » sur un ressort à l'entrée et à chaque changement d'état.

## Règles et conclusions

| Règle | Source (consultée le 11/11/2026) | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Montrer l'essentiel, rien d'autre | Apple HIG, Live Activities (« présentation compacte : l'information la plus importante ») ; Nielsen 8 (design minimaliste) ; Google Meet et Zoom n'affichent qu'un temps, pas deux | Le temps restant seul ; le temps écoulé se déduit de l'anneau | `formaterChronoCourt`, anneau d'avancement |
| L'état du système est visible | Nielsen 1 (visibilité de l'état du système) | Le chrono n'est plus dans une carte à déplier ; il est posé en tête, partout où la pilule d'état est rendue | capsule sœur de la pilule (`PiluleEtatSalle`) |
| Prévenir avant la fin, pas à la fin | Google Meet prévient 5 minutes avant la coupure d'un appel à durée limitée ; Zoom affiche le temps restant en fin de réunion limitée | Un état « bientôt » à 5 minutes : c'est le moment de conclure | `ChronoVivant.seuilBientot` |
| Un état ne se dit pas par la couleur seule | WCAG 2.2, 1.4.1 ; règle du dépôt (`lib/CLAUDE.md`) | Le dépassement se lit au signe « + » et à l'annonce vocale, pas seulement à la teinte | `chiffresDe`, `annonceDepassement` |
| Un minuteur ne s'annonce pas chaque seconde | WCAG 2.2, 4.1.3 (messages d'état) | Chiffres exclus de la sémantique ; un nœud annonce les minutes, une fois par minute | inchangé depuis LIVE-CHRONO-01 |
| Une information qui bouge plus de 5 s doit pouvoir être arrêtée, sauf si elle est essentielle | WCAG 2.2, 2.2.2 (exception « essentiel ») | Un chrono est essentiel par nature ; rien d'autre ne boucle | aucune boucle décorative |
| Le mouvement déclenché se désactive | WCAG 2.2, 2.3.3 ; réglage « réduire les animations » | Sous réduction du mouvement : ni roulement, ni ressort ; chiffres et teinte changent d'un coup | `AppMouvement.duree`, `mouvementReduit` |
| Chiffres stables, pas de saut de mise en page | Apple HIG et Material 3 (chiffres tabulaires) | Chiffres tabulaires ; la capsule s'étire en douceur quand un chiffre apparaît | `FontFeature.tabularFigures`, `AnimatedSize` |
| Les chiffres qui changent se transforment, ils ne clignotent pas | SwiftUI `contentTransition(.numericText())` (chrono et minuteurs d'iOS, Dynamic Island) | Le chiffre nouveau monte, l'ancien s'efface, case par case | `_ChiffresRoulants` |
| Un petit élément peut dépasser sa cible puis s'y poser | Material 3 Expressive (mouvement à ressort pour les petits composants) ; Dynamic Island | Ressort à léger dépassement pour la capsule seule | `AppMouvement.ressortVif` |
| Pas de pression sur l'enfant | Children's Code du Royaume-Uni (conception adaptée à l'âge) ; Apple HIG (calme) ; LIVE-CHRONO-01 | Jamais de chrono en Interface guidée ; chez l'élève la capsule reste sobre (aucune teinte d'urgence) et muette | `VueSeance.voitChrono`, `ChronoVivant.sobre` |
| Un son ne doit pas gêner l'écoute | WCAG 2.2, 1.4.2 (son de moins de 3 s) ; contexte : une récitation ne s'interrompt pas | Le signal sonore est court et ne sonne que chez qui conduit la séance | `VueSeance.conduitLaSeance` |
| Chiffres dans une phrase arabe | Unicode UAX 9, WCAG 1.3.2 | Les chiffres restent de gauche à droite | `Directionality.ltr` autour des chiffres |

## Écarts datés aux règles du dépôt

1. **« Aucun rebond visible »** (`AppMouvement.ressort`, DESIGN-GOV) : levé **pour la capsule du
   chrono seulement**, sur demande expresse du directeur (« un ressort, une forme qui se déforme,
   comme la Dynamic Island », 10/11 ; « effets visuels visibles et modernes », 11/11).
2. **« On n'anime jamais la taille »** (`DECISION-FLUIDITE-2026-11-07.md` §2) : la capsule s'étire
   quand les chiffres changent de nombre. C'est la « forme qui se déforme » demandée ; l'élément
   est petit et seul, le coût est négligeable. À mesurer sur téléphone d'entrée de gamme.
3. **« Jamais un temps après la fin »** (LIVE-CHRONO-01) : remplacé par le dépassement compté en
   croissant, sur demande du directeur du 11/11. Le mot interdit reste interdit : aucun « temps
   négatif » ; le dépassement est un compte positif précédé de « + ».

## Désaccord dit au directeur avant d'agir (11/11/2026)

Demande : « quand le chrono est à 0 ça bip ». Proposé : le signal sonne **chez l'enseignant
seulement**, et un premier signal est ajouté **5 minutes avant la fin**. Raison : chez l'élève, un
bip peut tomber au milieu d'un verset ; et c'est avant la fin que l'enseignant doit conclure.

## Ce qui reste à prouver

Captures clair et sombre, 320, 390 et 1440 points, texte ×1 et ×2, arabe, Mode Accessibilité ;
essai sur le banc à 12 élèves ; puis le directeur, en production.
