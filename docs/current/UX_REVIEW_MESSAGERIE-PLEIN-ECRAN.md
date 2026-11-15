# UX_REVIEW_MESSAGERIE-PLEIN-ECRAN : une conversation est une page

Demande du directeur (15/11/2026, capture au téléphone, en arabe) : dans la conversation de la
direction avec un candidat, la barre globale, le titre « Gestion des communications », les onglets
Annonces / Messages et la carte du candidat s'empilent avant le fil ; clavier ouvert, l'en-tête prend
près de 40 % de l'écran.

## Ce qui n'est pas prouvé (à lire d'abord)

- **Les captures sont des captures de test** (vrai `MessagesPage`, port de démonstration, vraies
  polices), pas de la vraie application. Le clavier est simulé : la zone vide est sa place.
- **Les 14 anciens tests sont réécrits** (table plus bas), aucun supprimé ni sauté.
- Mesure (test de widget, vrai `MessagesPage`, port de démonstration, 390 x 844, clavier de 300) :
  hauteur du fil **avant 240 sur 844 (28 % de l'écran, 44 % de la zone au-dessus du clavier)**,
  **après 416 (49 % de l'écran, 76 % de la zone au-dessus du clavier)**. L'« avant » est mesuré
  sans la barre globale de la coquille admin, qui s'ajoutait en production : la réalité d'avant est
  plus basse.

## Règles et sources

| Règle | Source | Conséquence |
| :--- | :--- | :--- |
| Une conversation est un écran de détail : retour, identité de l'interlocuteur, action contextuelle, rien d'autre en barre. | Material 3, « Top app bar » (small, 64 dp ; ici 56 : une ligne de nom et une ligne de rôle) ; Apple HIG, « Messages » et « Navigation bars » (retour, nom, info) | `BarreConversation` : retour, `AvatarNom` petit, nom, rôle sur une ligne coupée par une ellipse, (i). Ni titre de page, ni onglets, ni cloche. |
| Le champ de saisie suit le clavier. | Material 3, « Text fields » ; Apple HIG, « Text fields » et « Keyboards » | `Scaffold(resizeToAvoidBottomInset: true)` dans `PageConversationPleinEcran` ; la saisie est le dernier enfant de la colonne. |
| Le fil reste collé au dernier message. | Apple HIG, « Messages » ; usage de WhatsApp, Messages, Slack mobile | Liste inversée (`CustomScrollView(reverse: true)`) : le bas est le point zéro, il y reste quand la zone raccourcit. |
| Le champ grandit jusqu'à environ cinq lignes puis défile en lui-même. | Material 3, « Text fields » (multi-ligne) | `ZoneSaisie`, `maxLignes: 5` (déjà là). |
| Pas de phrase d'aide sous le champ dans une conversation. | Fitts / Hick : une ligne en moins entre le dernier message et le champ | `explication` du champ retirée en plein écran (`sansExplication`) ; l'aide reste lue par le lecteur d'écran (indication). |
| Une action simple ne fait jamais sortir d'un dossier, et pas d'onglets de téléphone sur ordinateur (règle 19). | Consigne 19 du directeur | À 600 points et plus, rien ne change : liste, fil et contexte côte à côte (`EspaceTravailAdaptatif`) ; le choix Annonces / Messages (`SousNavigationDomaine`, c'est `SelecteurSection`) reste sur la page de la liste. |

## Exception à DECISION-DEFILEMENT-2026-11-01

Le directeur nomme l'exception « messagerie » : dans une conversation ouverte, **le fil est la seule
zone qui défile**, la barre du haut et le champ restent fixes. Elle ne vaut que pour la conversation
ouverte (`FilDiscussion(pleinEcran: true)`). Elle ne touche ni la liste des conversations, ni les
annonces, ni aucune autre page, qui gardent « la liste est la page ». Le champ qui défile dans
lui-même au-delà de cinq lignes est la seconde exception, déjà admise dans toute messagerie.

## Ce qui a changé

- `lib/core/widgets/fil_discussion.dart` : mode `pleinEcran` (liste inversée, saisie fixe, sans
  en-tête ni tête de page, sans phrase d'aide). Un seul composant, pour tous les rôles.
- `lib/core/widgets/page_conversation.dart` (nouveau) : la page plein écran.
- `lib/features/com_messages/barre_conversation.dart` (nouveau) : la barre compacte, et la barre de
  retour seule pour les états sans fil (chargement, erreur, fil inaccessible : jamais une page sans
  sortie).
- `messages_page.dart`, `messages_admin.dart`, `fil_contextuel.dart` : au téléphone (moins de 600),
  un fil ouvert est servi sans `PageShell` ; le retour, (i) et l'état se règlent à un seul endroit.
- `AdminShell(conversationOuverte:)` et `NavShell` (`masquerBarreBasse`) : au téléphone, la coquille
  s'efface devant une conversation ouverte (`Routes.estConversationOuverte`).
- Aucun texte nouveau : `retourListe` et `ouvrirPanneau` existent. Aucune migration.

## Complément du directeur (15/11, relayé par le pilote)

« Au moins que la page entière soit scrollable pour tout libérer » : la page entière ne défile pas
(le champ partirait avec). À la place : la barre se replie quand on remonte vers les anciens
messages et revient quand on redescend ; **clavier ouvert, il ne reste qu'une barre de 48 (retour et
nom)**. Mesure, clavier de 300, 390 x 844 : le fil occupe **50 % de l'écran et 78 % de la zone
au-dessus du clavier** (avant : 28 % et 44 %). Le reste est le champ, d'environ 90 points : « rien
d'autre que le fil et le champ » est tenu, mais le fil ne peut pas dépasser ce plafond.
**Le repli au défilement n'est pas testé** (code seul, non vu).

## Non traité

- Tablette (600 à 839) : le fil garde l'en-tête de page actuel (une colonne de contenu, coquille
  présente). Question au directeur : le plein écran doit-il aller jusqu'à 840 ?
- La page des candidats sous `/attente/messages/:filId` n'a pas de coquille ; elle prend la même
  page plein écran au téléphone.

## Tests réécrits (décision du pilote, 15/11)

Aucun test supprimé ni sauté ; chacun garde son intention (envoi, lecture, droits, retour, contexte).
Seule la structure attendue change : plus d'en-tête ni de ligne compacte au téléphone, une barre
compacte (`BarreConversation`).

| Test | Ancien comportement attendu | Nouveau |
| :--- | :--- | :--- |
| `com_rc_lot_a` R-02 tuteur, enseignant, administration (320, texte x2) | la tête de page (titre) défile avec le fil et se retrouve en remontant | la barre est fixe, entière à l'écran, avec son retour ; ni `EntetePage` ni titre. Le canal du Studio garde l'ancien contrat |
| `com_rc_lot_a` « (i) dans la rangée de l'en-tête » | (i) sous `FilDiscussion`, dans la rangée de `EnteteFilContexte` | (i) dans la barre compacte, au niveau de la barre |
| `com_rc_tour4_lot_f` N-1 admin 390, tuteur 320 x1 et x2 | la ligne compacte (noms, objets) au-dessus de la liste, avec (i) | la barre au-dessus de la liste, nom lu entier, (i) et « Envoyer » entiers ; l'objet se lit dans le panneau ouvert par (i) ; barre sous le sixième de l'écran à x2 |
| `com_rc_tour4_lot_f` 390 x1 vue haute | l'en-tête complet fixe, sans ligne compacte | la barre compacte fixe, ni en-tête complet ni ligne compacte |
| `com_rc_tour5_lot_h` constat 3 (N-9), 320 x2 | le fil descend jusqu'au bas du panneau de pré-écoute (carte dans la liste) | la carte du panneau est entière à l'écran, sous la liste ; « Envoyer » du vocal entier et touchable |
| `com_rc_tour5_lot_h` constat 7, enseignant 320 x2 | ligne compacte fixe avec (i) | barre compacte fixe avec le nom et (i) (la vue basse 844 x 390, en tablette, garde l'ancien contrat) |
| `com_rc_tour5_lot_h` constat 8 | nom entier dans la ligne compacte, retour de la ligne compacte | nom entier dans la barre, phrase lue en entier (fonction comprise), retour de la barre (48 au moins), il mène à la liste |
| `entrees_admin` x2, `messages_page`, `routes_messages` (retour du fil) | le disque retour de la page | le retour de la barre (`cleRetourListe`) ; le retour de la liste est inchangé |
| `routes_messages` enseignant 390 | l'en-tête du fil | la barre de la conversation, pas d'en-tête |
| `entrees_enseignant` Espace Classe 390 | l'en-tête du fil | 390 : la barre ; 1440 : l'en-tête |
| `apercu_profil_candidat` 390 | toucher le nom (en-tête) ouvre le contexte | inchangé : le nom de la barre est un raccourci vers le contexte |

Captures R3 (tests `messagerie_plein_ecran_capture_test`, sautés sans `CAPTURE_DIR`, vraies polices) :
`docs/current/captures/E2E/MESSAGERIE-PLEIN-ECRAN/` : `messagerie-390-{fr,ar}-clavier.png` (clavier
simulé de 300), `messagerie-390-{fr,ar}.png`, `messagerie-1440-{fr,ar}.png`. Le clavier est simulé :
la zone vide en bas est la place du clavier, qui n'est pas dessinée.
