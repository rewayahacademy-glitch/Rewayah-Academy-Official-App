# UX_REVIEW_MESSAGERIE-PLEIN-ECRAN : une conversation est une page

Demande du directeur (15/11/2026, capture au téléphone, en arabe) : dans la conversation de la
direction avec un candidat, la barre globale, le titre « Gestion des communications », les onglets
Annonces / Messages et la carte du candidat s'empilent avant le fil ; clavier ouvert, l'en-tête prend
près de 40 % de l'écran.

## Ce qui n'est pas prouvé (à lire d'abord)

- **Aucune capture de la vraie application.** Le bac à sable n'a pas de navigateur Flutter ; le
  dossier `docs/current/captures/E2E/MESSAGERIE-PLEIN-ECRAN/` n'existe pas. **R3 n'est pas
  satisfaite** : le pilote ne doit pas fusionner avant ces captures (390 x 844 avec viewInsets de
  300, fr et ar, plus 1440).
- **14 tests existants échouent** : ils décrivent l'ancienne disposition du téléphone (disque retour
  de la page, ligne compacte N-1, raccourci du nom, tête de page R-02). Aucun n'a été affaibli ni
  supprimé ; ils sont à réécrire pour le nouveau contrat (liste en bas de ce fichier).
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

## Non traité

- Tablette (600 à 839) : le fil garde l'en-tête de page actuel (une colonne de contenu, coquille
  présente). Question au directeur : le plein écran doit-il aller jusqu'à 840 ?
- La page des candidats sous `/attente/messages/:filId` n'a pas de coquille ; elle prend la même
  page plein écran au téléphone.

## Tests à réécrire (échouent, non modifiés)

`com_rc_lot_a_test` (R-02, (i) dans l'en-tête), `com_rc_tour4_lot_f_test` (N-1), `com_rc_tour5_lot_h_test`
et `com_rc_tour7_m_test` (constats 7 et 8), `com_rc_tour3_test` (R-02 à 320, texte x2),
`apercu_profil_candidat_test` (toucher le nom), `routes_messages_test` (famille d'Adam, retour),
`com_rc_tour2_lot_d_test` (le disque retour de la tête de page).
