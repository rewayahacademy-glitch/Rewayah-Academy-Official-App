# Revue croisée COM-R : Communications V1 (spec §29 L6 et §33)

Date : 5 octobre 2026. Session 01HS7t3c, qui n'a écrit aucun code COM (les sessions 01FM3Arm et
01KyPAZg sont exclues). Revue en lecture seule : aucun fichier du lot n'a été modifié. Les
corrections relèvent de COM-RC.

- Code revu : `ui/communications-v1` @ `de2bdb64`, diff depuis `f6ac3658` (187 fichiers,
  +57 079 / -572).
- Sources lues : `CLAUDE.md`, `lib/CLAUDE.md`, `docs/current/DESIGN-GOV-2026-09-26.md` ;
  `19_communications/` : 00_REPRISE, 02_DECOUPAGE, QUESTIONS (Q1 à Q5), COM-BR, UX_REVIEW L0,
  CARTE_FONCTIONS, DECISIONS_COM_FUS (D-FUS-1 à 9), captures/COM-CAPT.md et
  com_debordements.txt ; spec `V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md` (§5, §22, §29 L6, §32,
  §33) ; fiches COM-* du tableau.
- Captures regardées : une sélection dans les 176 PNG de `captures/com-v1/` (390 clair,
  1440 clair et sombre, 320×2, RTL des écrans principaux), plus les maquettes de `V/`.
- Méthode : quatre relecteurs indépendants à contexte vierge (produit et sécurité
  communautaire, architecture et thème, accessibilité et états, contre-vérification de
  COM-CAPT). J'ai ensuite rejoué moi-même dans le code chaque constat retenu comme majeur avant
  de l'écrire ici.

## Verdict : REFUSÉE

Le lot ne remplit pas trois critères de fin de la spec §33 :
- « Communauté sans vente ni affiliation dans son UX » : une réponse échappe à la garde
  anti-promotion (R-01).
- L'accessibilité : à texte ×2 sur 320, le fil Messages et le canal du Studio ne montrent ni
  message ni composer (R-02).
- « Notifications partagées et contextuelles » : en démonstration, des notifications sont
  inertes, et l'une d'elles porte « Action requise » (R-06).

Le socle tient :
- aucun chat libre, aucun DM communautaire, aucun appel, aucune création de canal ;
- aucune permission inventée ;
- zéro backend, et la démo reste derrière `environnementAutoriseDemo` ;
- les coquilles de rôle sont correctes, sauf celle du Studio ;
- le thème Rewayah est intact ;
- les outils et la suite de tests sont aux chiffres annoncés.

Toutes les corrections sont locales. Aucune ne demande de refondre le lot. COM-RC peut les
traiter, puis demander une contre-revue ciblée.

## 1. Chiffres rejoués (worktree propre à `de2bdb64`, Flutter stable 3.13.5 de Dart)

| Contrôle | Annoncé | Rejoué |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | 0 | 0 (« No issues found! ») |
| `flutter test -j 3` (suite complète) | 6221 réussis, 0 échec | +6221, ~3071 sautés, 0 échec (« All tests passed! », 13 min 43 s) |
| `dart run tool/verifier_jetons.dart` | 39 | 39, aucun fichier COM cité |
| `dart run tool/verifier_revue.dart` | 1627 | 1627, aucun fichier COM cité |

`verifier_jetons` et `verifier_revue` n'excluent pas `lib/features/demo/`. Un grep manuel sur
tous les fichiers COM, démo comprise, n'a trouvé aucune occurrence de : `Color(0x`, `Colors.`,
`fontFamily`, `BoxShadow`, `fontSize`/`fontWeight` en dur, `.circular(` littéral, `Curves.`,
`IconButton`, `GestureDetector`, `InkWell`, `withOpacity`, `EdgeInsets.only(left/right)`,
`centerLeft`.

Statut de preuve : `présent dans le code` et `testé localement`. Rien n'est branché, rien n'a
été testé sur staging, rien n'est déployé.

## 2. Constats

Gravité : **majeur** = viole la spec, un critère §33, la sécurité communautaire ou
l'accessibilité ; **mineur** = finition ou dette. Les lignes renvoient à `de2bdb64`.

### Majeurs

| # | Angle | Fichier:ligne | Constat | Correction proposée |
| :--- | :--- | :--- | :--- | :--- |
| R-01 | Sécurité communautaire | `lib/features/com_communaute/publication_detail.dart:132-160` ; `reponses.dart:248-346` ; `core/communications/port_garde_promotion.dart:79` | Une réponse à une publication part directement par `portCommunauteProvider.repondre` (l.152-158), sans passer par `PortGardePromotion`. `ComposerReponse` ne montre ni la garde ni « Partage pédagogique uniquement ». `verifier()` n'accepte qu'un `BrouillonPublication`. Un lien affilié ou une vente postés en réponse ne reçoivent donc ni avertissement ni blocage (§5.1, §5.2). Si le serveur les refuse, l'écran dit « pas encore confirmée » et propose « Renvoyer ». | Faire vérifier aussi les réponses par la garde : étendre le port à un brouillon de réponse et le contrat COM-BR-07, puis rendre `GardePromotion` sous `ComposerReponse`. |
| R-02 | Accessibilité | `lib/core/widgets/fil_discussion.dart:305-331` ; `features/com_messages/messages_page.dart:122` ; `messages_admin.dart:59` ; `com_studio/studio_page.dart:378` ; `core/widgets/espace_travail_adaptatif.dart:274-300` ; `com_studio/canal_page.dart:404-434` | À texte ×2 sur 320 (COM-CAPT n°1, confirmé), seul le `ListView` du fil est en `Expanded`. L'en-tête du fil, la ligne (i) et `_Saisie` restent fixes, et `PageShell(defilante: false)` fige aussi la tête de page. La liste reçoit 0 px : débordements de 21 à 129 px, aucun message ni composer visible (tuteur, enseignant, admin, canal du Studio). En texte ×1, la liste n'a déjà qu'environ 300 pt à 390 et environ 100 pt à 320. | Quand le texte est agrandi ou la vue basse, faire défiler l'en-tête du fil avec les messages (premier élément du `ListView`). Poser (i) dans la rangée de l'en-tête et borner la saisie, vocal compris, à environ 40 % de la hauteur avec défilement interne. |
| R-03 | Produit, honnêteté | `lib/core/widgets/page_shell.dart:211` ; `messages_page.dart:284-287` (commentaire l.278-283) ; `studio_page.dart:727` ; `aujourdhui_page.dart:318` | Deux bandeaux hors ligne s'affichent ensemble (COM-CAPT n°3, confirmé, D-FUS-3). Celui de la coquille dit « l'envoi attendra », alors qu'aucun message n'est mis en file : la promesse est fausse. | Trancher D-FUS-3. Recommandation : option 1, un paramètre de `PageShell` qui masque le bandeau générique sur les pages Communications. |
| R-04 | UX, produit | `lib/core/widgets/fil_discussion.dart:477-490` ; `features/demo/communications/com_messages_demo.dart:620-626` ; `features/com_vocal/lecteur_vocal.dart:330-333` | Vocal (COM-CAPT n°6, confirmé, vu sur `com_vocal_pre_ecoute_tuteur_390_clair.png`) : à 390, la rangée texte reste au-dessus du panneau vocal. Il reste environ 10 pt de fil et deux « Envoyer » sont visibles. Par ailleurs, le vocal reçu n'est jamais lisible en démonstration : la pièce de démo n'a pas `peutOuvrir: true`, que `LecteurVocalRecu` exige. Le critère « vocaux avec workflow complet » n'est pas démontrable. | Pendant l'enregistrement et la pré-écoute, remplacer la rangée texte par le panneau vocal. Ajouter `peutOuvrir: true` aux vocaux de la démo, dans Messages et dans le Studio. |
| R-05 | Coquille | `lib/core/router/app_router.dart:1050-1063` ; `features/com_studio/studio_page.dart:345-357` | La coquille du Studio (COM-CAPT n°7, confirmé) n'a ni identité ni rôle, ni cloche, ni bascule clair/sombre, ni accès au compte. C'est la seule coquille dans ce cas. La route monte `StudioPage` hors de `_CoquilleAdmin` et de `ActionsEnteteCoquille`. | Envelopper la route du Studio dans `ActionsEnteteCoquille` (cloche, bascule) et donner au `NavShell` une entrée secondaire d'identité, « Administrateur ». |
| R-06 | Produit | `lib/features/notifications/notifications_page.dart:174-196` ; `features/demo/communications/com_annonces_demo.dart:170-190`, `:284-292` | Sur téléphone, une notification sans destination ni détail devient une ligne inerte, sans chevron ni explication (COM-CAPT n°11 confirmé, et plus large). En démo, « Message de la famille de Yasmine » ne mène pas au fil, et « Votre planning de la semaine prochaine a changé » est marquée « Action requise » sans aucune action. Le constructeur `n(...)` de la démo ne prend aucune `destination`. | Donner une destination aux notifications de démo (fil, planning). Interdire le niveau `actionRequise` sans destination, ou toujours ouvrir le détail. |
| R-07 | Architecture : une fonction, un endroit | `features/com_messages/fil_contextuel.dart:55`, `:71`, `:287` contre `com_studio/canal_page.dart:75`, `:91`, `:502` ; `com_messages/recherche_fils.dart:98`, `:161` contre `com_studio/recherche_studio.dart:80`, `:138` ; `com_communaute/flux_publications.dart:113` | La lecture d'un fil existe en deux copies : `texteDuMessage` et `texteMessageCanal`, `horodatageMessage` et `horodatageCanal` sont identiques ligne à ligne, aux clés i18n près. `_FilEnLecture` et `_CanalEnLecture` divergent déjà (le canal a un état vide, le fil non). La recherche existe en trois champs : Messages et Studio identiques aux clés près, plus celui de la Communauté, sans « Effacer ». | Placer dans `core/communications` un seul adaptateur `MessageCommunication` vers `MessageFil` (texte, horodatage) et un mode lecture seule de `FilDiscussion`. Placer dans `core/widgets` un seul `ChampRecherche` et une seule `SurfaceRecherche`, paramétrés par textes et clés. |

### Mineurs

| # | Angle | Fichier:ligne | Constat | Correction proposée |
| :--- | :--- | :--- | :--- | :--- |
| R-08 | Accessibilité, RTL | `assets/i18n/ar.i18n.json` (clés `commun.dates` et `historique` absentes) ; `features/accueil_famille/bloc_seance.dart:216` ; `suivi_foyer/filtres_historique.dart:320-332` ; `notifications_page.dart:551` | Les dates restent en français en arabe (COM-CAPT n°12, confirmé) : repli slang `base_locale`. Elles sont aussi mal ordonnées en RTL (« oct. 2026 4 »). Le manque existait avant le lot, mais le lot l'étend à toutes ses surfaces. | Ajouter `commun.dates` et `historique` en arabe (à rattacher à D-FUS-1), ou formater avec `intl` et la locale. Isoler la date en bidi. |
| R-09 | Accessibilité | `features/com_studio/aujourdhui_page.dart:504-518` ; `notifications_page.dart:541-546` ; `com_annonces/administration_communications_page.dart:134-136` | Mots coupés au milieu à 320×2 (COM-CAPT n°2, confirmé) : indicateurs toujours deux par rangée, colonne date figée à 38 %, titre de page sans repli. | À texte ≥ 1,5 : un indicateur par rangée et la date au-dessus du titre. Sur téléphone, la date passe à environ 25 %. |
| R-10 | UX | `core/widgets/espace_travail_adaptatif.dart:108`, `:111`, `:225`, `:249-257` | Liste et contexte sont figés à 256 px à 1440 : liste des fils étroite, « Rechercher une conve… » tronqué, flux Communauté étroit, file de modération étroite (n°9 et n°10). Aucune gouttière entre le filet et le fil (n°4, confirmé). L'écart entre colonnes est de 16, alors que DESIGN-GOV §4 bis.4 demande 24. | Largeur de liste ≥ 320 à 1440, un retrait `AppSpacing.lg` quand le filet est posé, et l'écart porté par l'espace adaptatif. |
| R-11 | UX | `fil_contextuel.dart:59-61`, `:259` ; `canal_page.dart:81`, `:477` | La pièce jointe s'affiche en texte dans la bulle (COM-CAPT n°5, confirmé), alors que `CartePieceJointe` existe dans `core/widgets/carte_piece_jointe.dart:43`. | Passer une `CartePieceJointe` dans `complement` pour chaque pièce non vocale. |
| R-12 | UX | `core/widgets/action_principale.dart:164` (antérieur au lot) ; `com_studio/sortie_focus.dart:57-63` ; `studio_page.dart:332-343` | `Center` sans `widthFactor` centre les actions compactes dans un `Wrap` : « Mode focus », « Quitter le focus », « Enregistrer ». Le bandeau de sortie du Focus est hors du `centre()` (COM-CAPT n°8 confirmé en partie). | `Center(widthFactor: 1)` (à faire valider, composant partagé), et poser le bandeau dans le même `centre()`. |
| R-13 | UX | `publication_detail.dart:290-301` ; `reponses.dart:156` | Le menu « … » est collé au nom au lieu d'être en bord de carte (n°9). À 1440, le flux vide et le centre vide affichent deux états vides côte à côte. | `crossAxisAlignment.stretch` autour de `AvatarNom`, et un seul état vide quand aucune publication n'existe. |
| R-14 | Copie | `assets/i18n/fr.i18n.json:5062`, `:5055-5058` ; `flux_publications.dart:40-60` ; `bloc_seance.dart:216` via `com_studio/activite.dart:71`, `brouillons_studio.dart:171` | Majuscules en milieu de phrase : « Classe An-Nour, Il y a 2 h » ; « Échéance le Mardi 6 octobre ». | Variantes en minuscule pour l'usage dans une phrase, ou séparateur « · ». |
| R-15 | Copie | `administration_communications_page.dart:134-136` (clé `com.socle.navigation.provisoire.administrationTitre`) | Le titre de page est « Communications » au lieu de « Administration des communications » (n°14, confirmé). La pastille « Démonstration » est répétée quatre fois. | Reprendre le titre de la spec, avec retour à la ligne permis (sinon R-09 s'aggrave), et une seule pastille par page. |
| R-16 | Produit | `classe_tuteur_page.dart:164-168`, `:175` | L'annonce de Classe passe avant la séance ouverte ou proche (n°13). Ce choix est écrit par COM-F, mais il pousse la séance sous le pli. | Mettre la carte de séance en tête quand une séance est ouverte ou commence bientôt. |
| R-17 | Sécurité communautaire | `com_communaute/composer_publication.dart:274-282` | Si la garde tombe en panne (n'importe quelle erreur), la publication part quand même, comme si aucun contrat n'existait. | Seule `CapaciteIndisponible` laisse passer. Toute autre erreur retient la publication et propose « Réessayer ». |
| R-18 | Sécurité communautaire | `core/communications/moderation.dart:141-145` ; `publication_detail.dart:121-127` | Le signalement n'a pas de clé d'idempotence. Le double signalement n'est empêché qu'en mémoire de page. | Ajouter une clé d'idempotence à `signaler` (et au contrat COM-BR) et un état « déjà signalé » rendu par le serveur. |
| R-19 | Produit | `com_communaute/regles_communaute.dart:78` | Une cinquième règle, « Aucune donnée personnelle… », s'ajoute aux quatre règles exactes du §22. | La faire valider par le directeur, ou la retirer. |
| R-20 | Permissions | `com_annonces/publier_annonce_classe_page.dart` via `administration_communications_page.dart:525-543` | Ouverte par URL directe, `/enseignant/groupe/:id/annonce` rend le publieur sans lire `CapaciteAnnonces.publier`. L'entrée est bien gardée (`annonces_de_classe.dart:180`), et le serveur reste juge. | Exiger la capacité de publier avant de rendre le publieur. |
| R-21 | Architecture | `core/communications/capacites_communication.dart:39`, `:42` ; `19_communications/CARTE_FONCTIONS.md` §5 | `CapaciteCommunication.moderer` et `parametresCanal` ne sont lues nulle part hors démo. La modération lit `CapacitesModeration`, le canal `CapaciteCanal.parametres`. CARTE annonce à tort ces deux capacités pour la Modération et la publication enseignant, et omet la route `/enseignant/communaute/:publicationId`. | Retirer les deux valeurs mortes ou en faire la source unique, puis corriger CARTE_FONCTIONS. |
| R-22 | Architecture | `com_studio/brouillons_studio.dart:405-490` ; `canal_page.dart:312` ; `com_communaute/reponses.dart:276-374` | Pour retrouver le contrôleur du champ de `FilDiscussion`, les brouillons parcourent l'arbre d'éléments, et le parcours est relancé à chaque `build`. `ComposerReponse` est un second composer, avec sa propre persistance. Le fil Messages n'a pas de brouillon. | `FilDiscussion` reçoit un contrôleur ou une `CleBrouillon` et porte seul `DraftPersistence`. |
| R-23 | Architecture | `messages_page.dart:347`, `:383`, `:449` contre `studio_page.dart:857`, `:893`, `:964` ; `communaute_page.dart:221-240` ; `file_moderation.dart:67` contre `publication_detail.dart:46` | L'orchestration liste et détail (choisir, état de liste, vue d'erreur) est recopiée. Le Messages « Choisir » ne défile pas, contrairement au Studio. Deux providers lisent les mêmes capacités de modération. | `VueEtatCommunication.depuisErreur(...)`, une vue « choisir » partagée et un seul provider de capacités de modération. |
| R-24 | États | `com_annonces/annonces_de_classe.dart:152-175` ; `annonces_planifiees.dart:43` ; `notifications_page.dart:265-282` ; `fil_discussion.dart:310` | Il manque des états. Annonces de Classe : rien pendant le chargement, et l'erreur générique au lieu de l'état hors ligne. Admin : état réseau lu par `ref.read`, donc non suivi. Notifications : un échec hors ligne s'affiche comme une erreur. Fil en écriture : un `ListView` vide au lieu d'un état vide. | Squelette et `horsLigne` choisi selon `horsLigneProvider`, `ref.watch`, et un état « Aucun message ». |
| R-25 | Clavier | `fil_discussion.dart:497-500` ; `composer_publication.dart:410` ; `publieur_annonce.dart:466` | Aucun raccourci d'envoi au clavier sur ordinateur (aucun `Shortcuts`). | Ctrl/Cmd+Entrée pour envoyer, Entrée garde le saut de ligne. |
| R-26 | Tests | `test/core/communications/complements_com0b_test.dart:147-152` | Le test « aucun fichier COM ne lit un rôle » ne couvre ni `features/com_vocal`, ni `features/notifications`, ni `core/widgets/fil_discussion.dart`. Le grep est vide aujourd'hui, mais ces chemins ne sont pas protégés. | Ajouter ces trois chemins au test. |
| R-27 | Produit | `features/journee/journee_page.dart:827` ; `com_communaute/entree_communaute.dart:47-70` | En production, le raccourci « Communauté enseignants » mène toujours à « Pas encore disponible ». C'est conforme à Q2, mais l'enseignant tombe sur une impasse visible. | Masquer la ligne tant que les capacités Communauté sont indisponibles, ou l'assumer par écrit. |
| R-28 | Pilotage | `19_communications/captures/COM-CAPT.md`, section « Défauts transmis » ; fiche COM-CAPT, champ reste | La fiche annonce « 15 défauts », mais la liste en compte 14. Des écarts relevés dans le corps du rapport n'y sont pas reportés : liste à 300 pt et 100 pt en texte ×1, colonne des fils étroite, « Mode focus » en lien, vocal ouvert par un lien et non par le micro, pastille répétée, navigation des coquilles en français en RTL. | Corriger le chiffre et la liste. Ils sont repris ici sous R-02, R-10, R-12 et R-15. |

## 3. Les 14 défauts de COM-CAPT, un par un

| COM-CAPT | Verdict | Repris en |
| :--- | :--- | :--- |
| 1. En-tête du fil non défilant à 320×2 | confirmé | R-02 (majeur) |
| 2. Mots coupés à 320×2 | confirmé | R-09 |
| 3. Double bandeau hors ligne | confirmé (D-FUS-3) | R-03 (majeur) |
| 4. Pas de gouttière entre liste et fil | confirmé | R-10 |
| 5. Pièce jointe en texte dans la bulle | confirmé | R-11 |
| 6. Vocal à 390, deux « Envoyer », vocal reçu illisible | confirmé (cause : donnée de démo) | R-04 (majeur) |
| 7. Studio sans identité ni rôle | confirmé, et plus large (ni cloche, ni bascule, ni compte) | R-05 (majeur) |
| 8. Focus à 1440 mal aligné | confirmé en partie : le composer n'est pas plus large que le fil (fil de 800 px, bulles à 86 %) | R-12 |
| 9. Communauté à 1440 | confirmé | R-10, R-13 |
| 10. « Politique anti-/promotion » coupé | confirmé en partie : c'est une coupure au trait d'union, légitime ; le vrai défaut est la colonne de 256 px | R-10 |
| 11. Notifications, date large, message sans destination | confirmé, et plus large (une « Action requise » est inerte) | R-06 (majeur), R-09 |
| 12. Dates non localisées en RTL | confirmé (clés arabes absentes) | R-08 |
| 13. Annonce avant la séance | confirmé, mais c'est un choix écrit par COM-F, à arbitrer | R-16 |
| 14. Titre « Communications » | confirmé | R-15 |

Aucun des 14 n'est infirmé en bloc. Il n'y a pas de 15e numéro (R-28).

## 4. Ce qui est vérifié conforme

**Produit.**
- Aucun chat libre. Aucun « Nouveau message » (`liste_fils.dart:7`). `PortMessagesMetier`
  ouvre seulement le fil d'un objet ou d'une paire autorisée par le serveur.
- Aucun DM communautaire : l'auteur est un `AvatarNom` non cliquable et le seul menu est
  « Signaler » (`publication_detail.dart:293-312`). `Participant` ne porte aucune coordonnée
  (`modeles_communication.dart:200-217`).
- Aucun appel. Aucune création de canal : `PortStudio` n'a ni méthode ni bouton pour cela
  (`port_studio.dart:318-337`, `liste_canaux.dart:14-17`).
- Aucun prix, boutique, « Promouvoir », « Sponsoriser », compteur ni cœur.
- Un seul centre de notifications : les quatre routes construisent `NotificationsPage`. Une
  seule cloche, une seule garde, un seul badge, un seul composer et un seul lecteur vocaux.

**Permissions.**
- Aucun `AppRole` ni `role ==` dans `features/com_*`, `core/communications` et `notifications`.
- Chaque action lit une capacité : publier, répondre, signaler, modérer, annoncer, écrire dans
  un fil ou un canal, envoyer un vocal.
- Tout est fermé par défaut (`capacites_communication.dart:113-131`).

**Zéro backend.**
- Aucun import Supabase, HTTP ni LiveKit dans le code COM.
- Les 16 ports ont un défaut neutre `CapaciteIndisponible('COM-BR-nn')`. `lib/main.dart` n'est
  pas modifié.
- `LectureVocaleJustAudio` n'est branché nulle part.
- `routesDemoCommunications` est vide hors `environnementAutoriseDemo`
  (`demo_communications_page.dart:71-72`). L'exception de redirection est conditionnée
  (`redirection.dart:50-66`). Aucun code de production n'importe `features/demo`.
- Réserve antérieure au lot : `environnementAutoriseDemo` est une liste noire (« prod »), à
  passer en liste blanche (`mode_demonstration.dart:63-66`).

**Coquilles.**
- Le Studio est sous `/admin`, réservé à l'admin par la garde de préfixe (Q1).
- L'administration est sous `/admin/operations/communications`, sans 9e domaine (Q4).
- La Communauté est réservée à l'enseignant et le tuteur reçoit `accesRefuse` (Q2).
- Les cloches sont conformes à Q5.

**Thème.** Uniquement des jetons, `StatusPill` avec un mot, `AppRadius`, `AppSpacing`. Aucune
couleur, police, ombre, rayon ni pastille colorée reprise des maquettes.

**Anti-promotion et signalement.**
- Textes §5.2 et §22 présents, accents compris.
- États avertissement et bloqué (lien affilié, vente), jamais « Vérifié ».
- Aucune détection maison présentée comme une garantie.
- Huit motifs dans l'ordre §5.5, motif obligatoire, confirmation seulement après l'accusé de
  réception.
- Données de famille non exposées : nom et fonction seulement.

**Accessibilité.**
- Les cinq états sont atteignables sur les écrans principaux.
- `BoutonIcone` avec libellé et cible de 48.
- `liveRegion` pour les arrivées, l'envoi, la garde, le signalement et le vocal.
- Focus Studio : focus posé à l'entrée et restauré à la sortie, Échap, `PopScope`, aucun piège.
- Mouvement réduit respecté.
- RTL : aucun alignement gauche ou droite en dur, icônes directionnelles en miroir.

**Fuites.** Aucune trouvée : timers vocaux, lecteur, `FocusNode`, observateurs et contrôleurs
sont libérés. La seule réserve vient du contournement R-22.

## 5. Suite pour le tableau

- COM-R : fait, verdict REFUSÉE, 7 majeurs et 21 mineurs.
- Aucune étape COM ne passe à `verifie` : chaque voie porte au moins un constat.

| Voie | Constats |
| :--- | :--- |
| socle, COM-F | R-02, R-10, R-12, R-22, R-26 |
| COM-MSG | R-02, R-07, R-11, R-23 |
| COM-VOC | R-04 |
| COM-COMU | R-01, R-13, R-17, R-18, R-19, R-27 |
| COM-STU | R-05, R-07, R-22 |
| COM-ANN | R-06, R-15, R-16, R-20, R-24 |
| COM-FUS | R-03, R-21 |
| COM-CAPT | R-28 |

- COM-RC traite d'abord les majeurs R-01 à R-07.
- R-03 attend la décision D-FUS-3 et R-08 la décision D-FUS-1. R-16 et R-19 sont des
  arbitrages du directeur.

## 6. Contre-vérification de COM-RC (COM-R-2)

Date : 5 octobre 2026. Même session (01HS7t3c), à la demande de la session 01FM3Arm (ordre du
directeur : tout livrer). Lecture seule, rien n'a été corrigé.

Périmètre :
- code : `ui/communications-v1` @ `022cc31e`, diff depuis `de2bdb64` (11 commits, 95
  fichiers) ;
- captures : `pilotage/tuteur-v1` @ `1fab6898`, 186 PNG, comparées à celles de `de2bdb64`.

Méthode : deux relecteurs indépendants à contexte vierge, l'un pour le code et les tests,
l'autre pour les captures avant et après. Les affirmations de COM-CAPT.md et des commits ont
été tenues pour non prouvées. J'ai moi-même rejoué R-01, N-1 et N-3 dans le code et sur
l'image.

### 6.1 Chiffres rejoués (worktree propre à `022cc31e`)

| Contrôle | Annoncé par COM-RC | Rejoué |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | 0 | 0 |
| `flutter test -j 3` (suite complète) | 6320 réussis, 3081 sautés, 0 échec | +6320, ~3081 sautés, 0 échec (« All tests passed! », 9 min 23 s) |
| `verifier_jetons` | 39 | 39 |
| `verifier_revue` | 1627 | 1627 |

### 6.2 État de chaque constat

| # | Gravité | État | Preuve à `022cc31e` |
| :--- | :--- | :--- | :--- |
| R-01 | majeur | **corrigé** (deux réserves, ci-dessous) | `reponses.dart:418-470` : `verifierReponse` avant `onEnvoyer` ; un verdict qui retient garde le texte, et une panne retient aussi. Test `com_communaute/revue_com_rc_test.dart:107-188` ; capture `com_communaute_reponse_bloquee_390_clair.png` |
| R-02 | majeur | **corrigé**, mais régression N-1 | `fil_discussion.dart:641-720` : en-tête et saisie dans la liste à texte ≥ 1,5 ou sous 480 de hauteur ; sinon, saisie bornée. Les quatre fils à 320×2 montrent champ et « Envoyer » |
| R-03 | majeur | **décision du directeur** (D-FUS-3) | les deux bandeaux restent (`com_messages_hors_ligne_tuteur_390_clair.png`) |
| R-04 | majeur | **corrigé** | un seul « Envoyer » en pré-écoute (`com_vocal_pre_ecoute_tuteur_390_clair.png`) ; `peutOuvrir: true` (`com_messages_demo.dart:628`, `com_studio_demo.dart:417`) ; « Écouter » visible |
| R-05 | majeur | **corrigé** (identité seulement en icône à 768, et seulement le compte à 390) | `app_router.dart:1059,1069` (`_ActionsStudio`), `studio_page.dart:243` |
| R-06 | majeur | **corrigé** | aucune ligne inerte ; toute `actionRequise` a une destination (`demo_annonces_test.dart`) ; chevrons visibles (`com_notifications_enseignant_390_clair.png`) |
| R-07 | majeur | **corrigé** | aucune copie restante ; un seul `messageFilDe` ; `ChampRecherche` et `SurfaceRecherche` partagés par Messages, le Studio et la Communauté |
| R-08 | mineur | **décision du directeur** (D-FUS-1) | dates toujours en français en arabe |
| R-09 | mineur | **corrigé** | plus aucun mot coupé à 320×2 |
| R-10 | mineur | **corrigé** | liste d'environ 336 px, gouttière, recherches entières |
| R-11 | mineur | **corrigé** | carte PDF dans la bulle, nom réduit par le milieu |
| R-12 | mineur | **partiel** ; le `Center` d'`ActionPrincipale` relève d'une décision du directeur | bandeau du Focus aligné sur le fil (`studio_page.dart:846-866`). « Quitter le focus » et « Mode focus » restent centrés. Le décalage d'« Envoyer » vient de bulles à 86 % face à une saisie pleine largeur : ce n'est pas un débordement |
| R-13 | mineur | **corrigé** (voir N-5) | menu au bord, un seul état vide |
| R-14 | mineur | **corrigé** | « · Il y a 2 h », « le mardi 6 octobre » |
| R-15 | mineur | **corrigé** | « Administration des communications », une seule pastille |
| R-16 | mineur | **décision du directeur** | annonce toujours avant la séance |
| R-17 | mineur | **corrigé** | seule `CapaciteIndisponible` laisse passer (`relireParLeGarde`) ; le test attend désormais 0 publication en cas de panne |
| R-18 | mineur | **corrigé côté client** ; le contrat COM-BR-06 reste à tenir côté serveur | `moderation.dart:158-168`, une clé rejouée (`revue_com_rc_test.dart:312-389`) |
| R-19 | mineur | **décision du directeur** | `regles_communaute.dart`, inchangé |
| R-20 | mineur | **corrigé** | `publier_annonce_classe_page.dart:79-116` : refus avant tout publieur |
| R-21 | mineur | **corrigé dans le code**, **partiel** dans CARTE_FONCTIONS | la carte n'a été mise à jour qu'au lot B. Elle cite encore `recherche_fils.dart` (l.37) et `lecteursVocauxDuMessage` (l.46), et omet `ChampRecherche`, `SurfaceRecherche` et `PersistanceBrouillon` |
| R-22 | mineur | **corrigé** | plus aucun parcours de l'arbre ; `FilDiscussion` porte `PersistanceBrouillon`, partagé avec `ComposerReponse` ; le fil Messages a un brouillon |
| R-23 | mineur | **partiel** | `depuisErreur`, `VueChoisirCommunication` et un seul provider de modération. La logique reste recopiée à la main dans `publication_detail.dart:289-299`, `annonces_de_classe.dart:176-181` et `publier_annonce_classe_page.dart:89-95` |
| R-24 | mineur | **corrigé** | squelette, `ref.watch`, hors ligne, « Aucun message » |
| R-25 | mineur | **corrigé** pour les trois composers cités | `raccourciEnvoi` ; voir N-2 |
| R-26 | mineur | **corrigé** | trois chemins ajoutés ; voir N-7 |
| R-27 | mineur | **décision du directeur** | inchangé |
| R-28 | mineur | **corrigé** | COM-CAPT.md compte 14 défauts et reporte les écarts |

Bilan :
- **21 corrigés** ;
- **3 partiels** : R-12 (en partie une décision), R-21 (carte) et R-23 ;
- **5 décisions du directeur** : R-03, R-08, R-16, R-19 et R-27, plus le `Center` de R-12.

Les six majeurs que COM-RC pouvait traiter (R-01, R-02, R-04, R-05, R-06 et R-07) sont
corrigés. R-03 attend D-FUS-3.

Réserves sur R-01 :
- L'avertissement d'une réponse (« Cette réponse semble… avant d'envoyer », `fr.i18n.json:5035`)
  et les titres « Réponse bloquée » et « Réponse à revoir » ne sont pas les textes exacts du
  §5.2. Il faut l'aval du directeur, ou revenir au texte du §5.2.
- Un refus du serveur pour cause de politique s'affiche comme un échec générique
  « Renvoyer » (`publication_detail.dart:184-186`).

### 6.3 Constats nouveaux introduits par COM-RC

| # | Gravité | Fichier:ligne ou capture | Constat | Correction proposée |
| :--- | :--- | :--- | :--- | :--- |
| N-1 | **majeur** | `lib/core/widgets/fil_discussion.dart:641-645` (seuil `hauteurBasse = 480`, l.296) ; `com_admin_messages_390_clair.png`, `com_admin_messages_320_clair.png`, `com_messages_fil_tuteur_320_clair.png` | **Régression de R-02 à texte ×1.** Quand le fil reçoit moins de 480 pt, l'en-tête de contexte passe dans la liste. Le défilement initial vers le bas le cache alors : chez l'admin à 390 (titre sur trois lignes plus onglets), et chez le tuteur à 320. Le fil s'ouvre sans interlocuteur, sans objet et sans bouton (i), alors qu'à `de2bdb64` « M. Rachid, Contrôleur pédagogique · Visite de contrôle, Classe An-Nour » était visible. Le critère « Messages métier contextuel » (§33) n'est plus tenu à une largeur courante. COM-CAPT.md ne le relève qu'à 320×2. | À texte ×1, garder fixe au moins une ligne compacte de contexte (nom et objet, avec (i)), ou ouvrir le fil sur l'en-tête plutôt que tout en bas. Ne pas lier la bascule à la seule hauteur, puis ajouter un test « en-tête visible à 390, texte ×1, coquille admin ». |
| N-2 | mineur | `features/com_communaute/reponses.dart:483` | Le composer de réponse, quatrième composer, n'a pas Ctrl/Cmd+Entrée. | Envelopper son champ dans `raccourciEnvoi`. |
| N-3 | mineur | `core/widgets/fil_discussion.dart:499` avec `persistance_brouillon.dart:56-65` | `_champ.clear()` déclenche `noter(cle, '')`, qui efface le brouillon avant l'accusé. Un message non confirmé est perdu si l'on quitte le fil. `ComposerReponse` attend l'accusé, lui. | Faire comme la réponse : `caler('')` avant `clear()`, puis effacer à l'accusé. |
| N-4 | mineur | `test/features/com_studio/focus_studio_test.dart` (assertions en `skipOffstage: false`) | Test affaibli : en Focus à texte ×2, il accepte une saisie hors écran (§23 : « contenu centré + composer + sortie »). | Ramener la saisie dans la vue à l'entrée du Focus, et rétablir l'assertion « visible ». |
| N-5 | mineur | `test/features/com_annonces/admin_publieur_test.dart` ; `com_communaute_vide_1440_clair.png` | Le cas « capacité présente, aucune audience » (`aucuneCibleTitre`) n'est plus testé. À 1440, sans publication, la colonne centrale est vide, sans titre ni état. | Rajouter le cas de test, et poser une invite légère au centre. |
| N-6 | mineur | `flux_publications.dart:185`, `notifications_page.dart:482`, `aujourdhui_page.dart:512`, `administration_communications_page.dart:375`, `fil_discussion.dart:296-298` | Les seuils « texte agrandi = 1,5 » et « 480 » sont recopiés, parfois en littéral. | Une seule constante (`AppGabarit` ou `core/accessibilite`). |
| N-7 | mineur | `test/core/communications/complements_com0b_test.dart:164-171` | Le test « aucun rôle » ne couvre pas `champ_recherche.dart`, `surface_recherche.dart` ni `page_shell.dart` (`TetePageConfiee`). | Les ajouter. |
| N-8 | mineur | `features/com_vocal/lecteur_vocal.dart:341` | `lecteursVocauxDuMessage` n'est plus appelée nulle part : code mort qui double `piecesDuMessage`. | La supprimer, et corriger CARTE_FONCTIONS (l.46). |
| N-9 | mineur | `com_vocal_pre_ecoute_tuteur_390_clair.png`, `..._1440_sombre.png` | Le bas du panneau de pré-écoute touche la barre de navigation (390) ou le bord de page (1440). | Une marge basse sous le panneau borné. |
| N-10 | mineur | `com_notifications_enseignant_390_clair.png`, `com_admin_moderation_1440_clair.png`, `com_messages_fil_tuteur_390_rtl_clair.png` | Trois défauts de finition : date sur deux lignes à texte ×1 (« 4 oct. / 2026 ») ; pastille de motif longue étirée sur toute la largeur ; virgule arabe « ، » insérée dans du français (famille R-08). | Date compacte, sans l'année quand c'est l'année en cours ; largeur intrinsèque de la pastille ; séparateur neutre. |

Les quatre défauts nouveaux que COM-CAPT.md relève au tour 3 (ligne auteur mixte en RTL,
alignements RTL, premier écran sans titre à 320×2) sont confirmés et restent mineurs ou à
arbitrer.

Vérifié sans défaut dans le diff :
- aucun rôle lu ;
- aucune couleur, police ni rayon en dur ;
- aucune démo hors garde, aucun appel réseau ;
- ressources libérées, y compris le contrôleur injecté dans `FilDiscussion` et
  `RelaisTetePage` ;
- parité slang fr et ar ;
- aucun `skip` ajouté, aucun test supprimé ;
- aucun tiret cadratin.

### 6.4 Verdict de COM-R-2 : COM-RC ACCEPTÉE AVEC RÉSERVES, non vérifiée

COM-RC corrige les sept majeurs de la revue, hors la décision D-FUS-3. Elle introduit
toutefois une régression majeure, N-1 : sur téléphone, le fil Messages s'ouvre sans son
contexte. COM-RC reste donc en `dev_ok`.

Pour passer à `verifie`, il faut :
1. corriger N-1, avec un test ;
2. de préférence, N-3 et N-4, qui touchent à la perte de données et à un test affaibli ;
3. les autres mineurs peuvent suivre.

Aucune étape COM ne passe à `verifie` tant que N-1 reste ouvert. N-1 touche le socle
(`FilDiscussion`) et donc Messages, le Studio et la coquille admin.

## 7. Contre-vérification du tour 4 de COM-RC (COM-R-3)

Date : 5 octobre 2026. Même session (01HS7t3c), à la demande de la session 01FM3Arm. Lecture
seule.

Périmètre :
- code : `ui/communications-v1` @ `27689f94`, diff depuis `022cc31e` (4 commits, 36
  fichiers) ;
- captures : `pilotage/tuteur-v1` @ `fbc9153d`, 187 PNG ;
- carte des fonctions : `729cb967`.

Méthode : un relecteur indépendant à contexte vierge pour le code et les tests. J'ai lu moi-même
les captures clés (`com_admin_messages_390_clair`, `com_messages_fil_tuteur_320_clair`,
`..._320x2_clair`, `com_studio_focus_320x2_clair`, `com_vocal_pre_ecoute_tuteur_390_clair`,
`com_communaute_reponse_bloquee_390_clair`) et rejoué dans le code les constats nouveaux 1 et 2.

### 7.1 Chiffres rejoués (worktree propre à `27689f94`)

| Contrôle | Annoncé | Rejoué |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | 0 | 0 |
| `flutter test -j 3` (suite complète) | 6344 réussis, 3082 sautés, 0 échec | +6344, ~3082 sautés, 0 échec (« All tests passed! », 10 min 57 s) |
| `verifier_jetons` | 39 | 39 |
| `verifier_revue` | 1627 | 1627 |

### 7.2 Constats de COM-R-2

| # | État | Preuve à `27689f94` |
| :--- | :--- | :--- |
| N-1 (majeur) | **corrigé** | `fil_discussion.dart:735-772` : quand l'en-tête défile, sa ligne compacte (nom, objet, (i)) reste fixe au-dessus de la liste. Elle sert à Messages (tuteur, enseignant, admin) et au canal, Focus compris. Test `com_rc_tour4_lot_f_test.dart:360-375` : admin, 390, texte ×1, vraie coquille ; il échouerait à `022cc31e`. À l'image, « M. Rachid, Contrôleur pédagogique · Visite de contrôle, Classe An-Nour » et (i) sont visibles à 390, et « Mme Mariam, Enseignante d… · Classe An-Nour · Adam » à 320 et à 320×2. R-02 ne régresse pas : à 320×2, champ et « Envoyer » sont entiers. |
| N-2 | **corrigé** | `reponses.dart:560-578`, `raccourciEnvoi` ; test `com_communaute/com_rc_tour4_test.dart:273-305` |
| N-3 | **corrigé**, avec un défaut résiduel (constat 1 ci-dessous) | `fil_discussion.dart:556`, `:582-592` ; tests `lot_f_test.dart:457-531` (le brouillon reste jusqu'à l'accusé, et aussi en cas d'échec) |
| N-4 | **corrigé** | `focus_studio_test.dart:244-264` : plus de `skipOffstage`. Le test vérifie le rectangle à l'écran et `hitTestable` |
| N-5 | **corrigé** | `aucuneCibleTitre` testé ; un état vide au centre à 1440 |
| N-6 | **corrigé** | `core/accessibilite/texte_agrandi.dart` (`SeuilsTexteAgrandi`). Les littéraux restants sont hors COM (`admin_shell.dart:837`, `nav_shell.dart:406`) ou désignent une largeur (`_largeurEmpilee`) |
| N-7 | **corrigé** | `complements_com0b_test.dart:167-173` |
| N-8 | **corrigé** | plus aucune occurrence dans `lib` ; CARTE_FONCTIONS l.46 à jour |
| N-9 | **partiel** | marge ajoutée (`fil_discussion.dart:827-833`). Le panneau de pré-écoute reste rogné en bas à 390 et à 1440 : la saisie, bornée à 40 % de la hauteur, défile depuis le haut |
| N-10 | **corrigé** | date compacte sans l'année en cours, pastille à sa largeur, séparateur neutre « · » |
| R-01, réserve sur les textes | **partiel**, aval du directeur | le blocage reprend le texte exact du §5.2 et les titres inventés sont retirés. Trois textes restent hors du §5.2 : l'avertissement de réponse (`fr.i18n.json:5034`, qui dit « avant de publier » sous un bouton « Envoyer »), `reponse.consigneBlocage` et `reponses.refusee`. Ils sont marqués « à valider par le directeur » |
| R-01, réserve sur le refus du serveur | **corrigé côté client** | `ContenuRefuse` est affiché sans « Renvoyer » (`publication_detail.dart:199-203`, `reponses.dart:315-323`). Aucun adaptateur réel ne le lève encore |
| R-21 | **corrigé** | CARTE_FONCTIONS (`729cb967`), l.37, l.46 et l.81-83 |
| R-23 | **corrigé** | les trois écrans passent par `depuisErreur` |

### 7.3 Constats nouveaux, tous mineurs

| # | Fichier:ligne | Constat | Correction proposée |
| :--- | :--- | :--- | :--- |
| 1 | `core/widgets/fil_discussion.dart:584-592` | Un message en échec reste dans `_locaux`, et `any(etat != envoye)` bloque ensuite tout effacement. Si A échoue puis B est confirmé, le brouillon garde le texte de B : à la réouverture, ce texte déjà envoyé revient dans le champ. | N'attendre que les messages `enCours`, ou effacer à l'accusé du message dont le texte correspond. |
| 2 | `core/widgets/fil_discussion.dart:735-747` | En lecture seule, `limite != null` rend `compacteFixe` toujours vrai, même à 1440. Le canal en lecture seule perd l'en-tête complet (avatar, nom entier). | Réserver la ligne compacte au texte agrandi et à la vue basse. |
| 3 | `fil_discussion.dart:800-833` | N-9 : le panneau vocal dépasse la saisie bornée ; son bas est découpé. | Faire défiler la saisie jusqu'au bas du panneau à son ouverture, ou relever la borne quand le vocal est ouvert. Le test doit vérifier que le bas du panneau est visible. |
| 4 | `features/notifications/notifications_page.dart:577` | `DateTime.now()` n'est pas injecté : rendu et captures dépendent de l'année courante, et le test associé est tautologique. | Passer l'horloge de la page à `LigneNotification`. |
| 5 | `com_studio_focus_320x2_clair.png` | En Focus à 320×2, aucune bulle n'est visible (§23 : « contenu centré + composer + sortie »). | Arbitrage du directeur, ou champ réduit à une ligne en Focus. |
| 6 | `features/com_studio/canal_page.dart:434` | `_entreesFocus++` est fait dans `build`. | Le déplacer dans le rappel de changement d'`EtatFocusStudio`. |
| 7 | `test/.../com_rc_tour4_lot_f_test.dart:355` | N-1 n'est testé ni pour l'enseignant ni pour le Focus en vue basse (même widget). | Ajouter ces deux cas. |
| 8 | captures 320 et 320×2 | La ligne compacte tronque le nom (« Mme Mariam, Ense… »). À 320×2, aucun bouton retour n'est visible au premier écran (la barre basse reste). Déjà déclaré par COM-RC. | Le nom entier passe derrière (i) ; un retour compact dans la ligne de contexte. |

Vérifié sans défaut dans ce diff :
- aucun rôle lu ;
- aucune couleur, police ni rayon en dur ;
- aucune démo hors garde, aucun appel réseau ;
- aucun contrôleur, `FocusNode` ni écouteur ajouté sans libération ;
- aucun `skip` ajouté ; le seul `expect` retiré est remplacé par une assertion cohérente ;
- parité slang inchangée ;
- aucun tiret cadratin.

### 7.4 Verdict de COM-R-3 : COM-RC ACCEPTÉE, passée à `verifie`

Le seul majeur ouvert, N-1, est corrigé, testé et visible à l'image. Les sept majeurs de la
revue initiale sont corrigés, hors R-03, qui attend D-FUS-3. Il ne reste que des mineurs (N-9
partiel, constats 1 à 8 ci-dessus) et des décisions du directeur.

- **COM-RC passe à `verifie`**, ainsi que les étapes COM couvertes par cette revue :
  COM-MSG-1, COM-MSG-2, COM-VOC-1, COM-COMU-1, COM-COMU-2, COM-STU-1, COM-STU-2, COM-STU-3,
  COM-ANN-1, COM-ANN-2, COM-FUS, COM-CAPT.
- Statut de preuve : `présent dans le code` et `testé localement`. Rien n'est branché, rien
  n'est testé sur staging, rien n'est déployé. `verifie` ne vaut ni fusion dans `main` ni mise
  en production.

Les décisions du directeur restent ouvertes :
- R-03 (D-FUS-3), R-08 (D-FUS-1), R-16, R-19, R-27 ;
- le `Center` d'`ActionPrincipale` (R-12) ;
- les trois textes de réponse de R-01 ;
- le Focus à 320×2 (constat 5) ;
- les neuf décisions de `DECISIONS_COM_FUS.md`, dont l'historique de com-commu dans com-ann
  (COM-ANN-2).

## 8. Contre-vérification du tour 5 de COM-RC (COM-R-4)

Date : 5 octobre 2026. Session 01HS7t3c, qui n'a écrit aucun code COM. Lecture seule.

Périmètre :
- code : `ui/communications-v1` @ `a1a33222`, diff depuis `27689f94` (17 commits, 56 fichiers) ;
- pilotage : `pilotage/tuteur-v1` @ `2eccde92` (`DECISIONS_COM_FUS.md`, `QUESTIONS.md`,
  `LIBELLES_COM_RELECTURE.md`, `UX_REVIEW_COM-STU-1..3`) ; décisions du 05/10 lues dans ces
  fichiers, pas dans l'artefact.

Méthode : relecture du diff et des tests ; comparaison scriptée de `fr` et `ar.i18n.json` et de
`libelles_sources.json` entre `27689f94` et `a1a33222` ; aucune capture relue (aucune refaite).

### 8.1 Chiffres rejoués (worktree propre à `a1a33222`)

| Contrôle | Annoncé | Rejoué |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | 0 | 0 |
| `flutter test -j 3` (suite complète) | +6400, ~3082, 0 échec | +6400, ~3082, 0 échec (« All tests passed! », 11 min 28 s) |
| `verifier_jetons` | 39 | 39 |
| `verifier_revue` | 1627 | 1627 |

Aucun fichier `supabase/`, `.github/` ni `pubspec.yaml` touché ; worktree propre après `slang` et
`build_runner`.

### 8.2 Constats attendus

| # | État | Preuve à `a1a33222` |
| :--- | :--- | :--- |
| 7.3-1 (brouillon) | **corrigé**, défaut résiduel (8.3-1) | `persistance_brouillon.dart:62-101` (textes en attente par port et clé) ; `fil_discussion.dart:726-767` ; tests `com_rc_tour5_lot_h_test.dart:356-531` (A échoue puis B confirmé ; accusé fil fermé ; fil rouvert avant l'accusé) |
| 7.3-2 (lecture seule) | **corrigé** | `fil_discussion.dart:979-989` : ligne compacte seulement à texte agrandi ou vue basse ; tests l.555-600 (1440 en-tête complet, 320×2 compacte) |
| 7.3-3 (N-9) | **corrigé** | borne 60 % / 75 % quand le vocal est ouvert (`fil_discussion.dart:422-432`), saisie menée à son bas (l.779-803) ; tests l.602-690 : carte entière, « Envoyer » et « Supprimer » à l'écran à 390 et 1440 |
| 7.3-4 (horloge) | **corrigé** | `horlogeNotificationsProvider` (`notifications_page.dart:335`, `:462`) passé à la ligne (`:588`) ; test d'horloge injectée dans `notifications_test.dart` |
| 7.3-5 (Focus 320×2) | **corrigé** selon la décision (zone réduite à une ligne) | `FilDiscussion.saisieReduite` (`fil_discussion.dart:1010-1020`, seuil `largeurReduite = 360`) ; test l.871 : une bulle entière visible, champ et sortie atteignables |
| 7.3-6 (`build`) | **corrigé** | `canal_page.dart:334`, dans l'écoute d'`EtatFocusStudio` ; test source l.692 |
| 7.3-7 (tests N-1) | **corrigé** | enseignant 320×2 et vue basse (l.734), Focus du Studio en vue basse (l.762) |
| 7.3-8 (nom, retour) | **corrigé** | nom sans fonction sur deux lignes, sémantique entière ; `retourCompacte` (`fil_discussion.dart:807-828`) ; test l.798 |
| R-03 (D-FUS-3 = a) | **corrigé** | `PageShell.bandeauHorsLigne` (`page_shell.dart`) ; les 13 `PageShell` des Communications le renseignent ; test `com_rc5_lot_i_bandeau_test.dart`. Voir 8.3-2 |
| R-08 (D-FUS-1 = a) | **corrigé** | mois, jours et gabarits de date ajoutés en arabe (`historique.*`, `commun.dates.*`) ; test `com_rc5_lot_i_dates_test.dart`. Clés globales : l'effet dépasse COM, dans le bon sens |
| R-12 (= a) | **corrigé** | `action_principale.dart` : `Center(widthFactor: 1)` ; « Mode focus » et « Quitter le focus » au début (`9cd8c394`) ; tests `action_principale_compacte_test.dart`, `com_rc5_r12_alignement_test.dart` (320×2, 390, 1440, arabe) |
| R-16 (= a) | **corrigé** | `seanceAvantAnnonces` (`classe_tuteur_page.dart:89-110`) à l'heure serveur : salle ouverte, en direct, prolongée, ou à moins de 5 min (`seuilImminence`). « Proche » = 5 min est une lecture de l'auteur ; tests `classe_tuteur_test.dart` |
| R-27 (= a) | **corrigé** | `entree_communaute.dart` lit `capacitesCommunauteProvider` (capacité, pas rôle) : `CapaciteIndisponible` ou lecture en cours, rien n'est rendu ; tests `journee_test.dart` (production et démo) |
| R-28 (= a) | **corrigé** | micro (`BoutonIcone`, cible 48) à côté d'« Envoyer », seulement si `envoyerVocal` est ouverte (`fil_discussion.dart:944`, `composer_vocal.dart:504`) ; tests l.980-1080 (libellé arabe compris) |
| D-FUS-9 (icônes) | **corrigé** | `AppIcons.signet` ajouté (`app_icons.dart`), `epingle` et `lien` employés ; un fichier sans pièce prend `supports` (`61a4c96a`) ; test `com_rc5_lot_i_icones_test.dart` |
| Libellés (D-FUS-8) | **corrigé** | les 26 lignes de `LIBELLES_COM_RELECTURE.md` (25 + `reponse.avertissement`) sont au mot près dans `fr.i18n.json` ; 24 changent en arabe, les 2 autres y étaient déjà justes (`messagesDetail`, `demo.roles.admin`). Les 658 libellés validés portent « validé par délégation le 05/10 » et **aucun** n'a changé de texte. Seul autre changement du français : la clé nouvelle `composer.enregistrerVocal` (R-28), sourcée. Les 15 orphelines sont retirées ; parité `com.*` et `notifications.*` fr/ar complète (759 clés) |

Restes déclarés :
- **Captures COM-CAPT non refaites** : acceptable pour `verifie` de COM-RC, car chaque changement
  visuel est mesuré par un test de géométrie aux vraies largeurs. Non acceptable pour la recette
  humaine : COM-CAPT doit être rejouée à `a1a33222` (R-12, micro, Focus réduit, retour compact,
  icônes, bandeau, dates arabes) avant HU-1.
- **Arabe de 23 libellés corrigés non relu par un arabophone** : acceptable tant que rien n'est
  branché ni déployé. À relire avant toute ouverture en arabe, avec la typographie (« : » précédé
  d'une espace, à la française, dans `garde.panne`, `indicateurs.echec`, `publieur.horsLigne`).

### 8.3 Constats nouveaux, tous mineurs

| # | Fichier:ligne | Constat | Correction proposée |
| :--- | :--- | :--- | :--- |
| 1 | `core/widgets/fil_discussion.dart:759-767`, `persistance_brouillon.dart:160` | Lu dans le code, non rejoué : un accusé reçu par un fil **fermé** efface le brouillon de la clé sans condition. Si le fil a été rouvert et qu'on y a tapé Y entre-temps, Y est effacé du port ; le champ le montre encore, mais il est perdu si l'on ressort sans retoucher le texte. | N'effacer que si le brouillon gardé vaut encore `m.brut` (un `effacerSi(cle, texte)` dans la persistance) ; un test « rouvert, Y saisi, puis accusé ». |
| 2 | `test/features/com_annonces/admin_communications_test.dart:309-313`, `admin_moderation_test.dart:444-448` | Hors ligne, la même phrase « Vous êtes hors ligne. Les nouveaux messages ne peuvent pas être actualisés. » paraît trois fois (bandeau et deux blocs) sur l'Administration des communications, deux fois sur la Modération. Le texte parle de « messages » sur des pages d'annonces. D-FUS-3 retire le doublon de bandeau, pas la répétition. | Sous un bandeau, les blocs disent seulement ce qui n'est pas chargé, avec « Réessayer » ; un texte de bandeau propre aux annonces. |
| 3 | `features/com_studio/liste_canaux.dart:122` ; `aujourdhui_page.dart:328` | Les ajustements demandés par `UX_REVIEW_COM-STU-1` (point 6 : 20 au lieu de 24 entre sections) et `UX_REVIEW_COM-STU-2` (points 4 et 14 : 32 au-delà de 600, squelette d'Aujourd'hui) ne sont pas dans ce tour. Les revues les rattachaient « au tour 5 ou à la passe d'harmonisation ». | Les ranger explicitement dans la passe d'harmonisation (DESIGN-GOV §4 bis.8), ou les corriger. |

Vérifié sans défaut dans ce diff :
- aucun rôle lu, aucune permission inventée (micro et raccourci derrière une capacité) ;
- aucune couleur, police ni rayon en dur (jetons 39, inchangé) ;
- aucune démo hors `environnementAutoriseDemo`, aucun appel réseau, aucun backend ;
- aucun `skip` ajouté ; quatre tests renommés, aucun supprimé ; trois `expect` retirés, chacun
  remplacé par une assertion plus stricte (189 ajoutés) ;
- contrôleurs, écouteurs et `ValueNotifier` du micro libérés (`fil_discussion.dart:628-640`) ;
- aucun tiret cadratin.

### 8.4 Verdict de COM-R-4 : COM-RC (tour 5) ACCEPTÉE, COM-RC-5 passe à `verifie`

Les huit mineurs de COM-R-3 §7.3 sont corrigés et testés. Les décisions R-03, R-08, R-12, R-16,
R-27, R-28, le Focus à 320×2, D-FUS-9 et les 25 libellés sont appliqués, et les chiffres
annoncés se rejouent à l'identique. Il ne reste que trois mineurs (8.3) et deux restes déclarés.

- Statut de preuve : `présent dans le code` et `testé localement`. Rien n'est branché, testé
  sur staging ni déployé ; `verifie` ne vaut ni fusion dans `main` ni mise en production.
- Avant HU-1 : COM-CAPT rejouée à `a1a33222` et relue ; arabe des libellés corrigés relu par un
  arabophone.
- Restent au directeur : la colonne « Validation requise » (COM-BR-11) et la lecture « proche =
  5 min » de R-16.

## 9. Contre-vérification du tour 6 de COM-RC (COM-R-5)

Date : 5 octobre 2026. Session 01HS7t3c, qui n'a écrit aucun code COM. Lecture seule.

Périmètre :
- code : `ui/communications-v1` @ `145af740`, diff depuis `a1a33222` (4 commits, 22 fichiers) ;
- captures : `pilotage/tuteur-v1` @ `0b43fd9f`, 187 PNG, section « Après COM-RC tour 6 » de
  `COM-CAPT.md`.

Méthode : relecture du diff et des tests ; contre-preuve du test 8.3-1 sur le code de
`a1a33222` ; captures régénérées à `145af740` et comparées octet par octet ; huit PNG lus.

### 9.1 Chiffres rejoués (worktree propre à `145af740`)

| Contrôle | Annoncé | Rejoué |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | 0 | 0 |
| `flutter test -j 3` | +6410, ~3082, 0 échec | +6410, ~3082, 0 échec (« All tests passed! », 11 min 02 s) |
| `verifier_jetons` | 39 | 39 |
| `verifier_revue` | 1627 | 1627 |
| Captures (`CAPTURE_DIR`, `communications_capture_test.dart`) | 187 à `145af740` | 187 régénérées, **187 identiques octet par octet** à celles de `0b43fd9f` |

### 9.2 Constats attendus

| # | État | Preuve à `145af740` |
| :--- | :--- | :--- |
| 8.3-1 (brouillon, accusé tardif) | **corrigé** | `PersistanceBrouillon.effacerSi` (`persistance_brouillon.dart:159-173`) relit le brouillon et n'efface que s'il vaut encore le texte envoyé ; appel `fil_discussion.dart:769`. Test `com_rc_tour5_lot_h_test.dart` « 8.3-1 » (A envoyé, fil fermé puis rouvert, B saisi, accusé de A : B reste). **Contre-preuve rejouée** : avec `fil_discussion.dart` et `persistance_brouillon.dart` de `a1a33222`, le test échoue (`Expected: 'B'`, `Actual: <null>`) |
| 8.3-2 (hors ligne répété) | **corrigé** | `BandeauHorsLigneCommunication(message:)` et `VueEtatCommunication(sousBandeau:)` (`vue_etat_communication.dart`) ; phrases propres aux annonces et à la modération ; sous le bandeau, un bloc dit « Impossible de charger ce contenu. Réessayez quand la connexion revient. » avec « Réessayer ». Tests : `textContaining('hors ligne')` une seule fois sur l'Administration et la Modération ; aucune capture hors ligne des annonces (test seulement). Les autres pages COM gardent la phrase des messages, qui leur convient |
| 8.3-3 (UX_REVIEW) | **corrigé** | `liste_canaux.dart:128-131` : 24 sur téléphone, 32 au-delà ; `aujourdhui_page.dart` : écart de section 24/32 et squelette à la forme d'Aujourd'hui (tuiles, puis 1, 2 ou 3 colonnes de groupes) ; test `com_rc_tour6_studio_test.dart` ; à l'image, 32 entre sections à 1440 (`com_studio_canal_1440_clair`) |

Captures lues : `com_studio_focus_320x2_clair` (une ligne, micro, dernière bulle visible),
`com_studio_canal_320x2_clair`, `com_studio_canal_1440_clair`, `com_communaute_hors_ligne_390_clair`
(un seul bandeau), `com_vocal_pre_ecoute_tuteur_390_clair` (panneau entier, « Supprimer » et
« Envoyer » visibles), `com_admin_annonces_390_rtl_clair`, `com_admin_moderation_390_sombre`,
`com_annonce_classe_tuteur_390_clair`.

Restes déclarés, aucun bloquant pour `verifie` :
- « Envoyer » plus large que le fil à 1440 : mineur, le bouton reste dans sa colonne ;
- micro de taille fixe à 320×2 : mineur, la cible reste de 48 ; à aligner sur « Envoyer » ;
- retrait de « Mode focus » (marge interne du bouton texte) : cosmétique ;
- démonstration incohérente de la Classe du tuteur (« Classe fictive A », « Eleve A1 » sans
  accent, annonce « Classe An-Nour ») : à corriger **avant HU-1**, sinon la recette humaine lira
  une incohérence ;
- arabe des 23 libellés corrigés, plus les 3 nouveaux : relecture par un arabophone avant toute
  ouverture en arabe.

### 9.3 Constats nouveaux, tous mineurs

| # | Fichier:ligne | Constat | Correction proposée |
| :--- | :--- | :--- | :--- |
| 1 | `19_communications/captures/COM-CAPT.md:594-595`, `:604` | COM-CAPT cite N-9 (panneau de pré-écoute coupé) parmi les restes « non revus ». À `145af740`, `com_vocal_pre_ecoute_tuteur_390_clair.png` montre le panneau entier : la mention est périmée. | Retirer N-9 des restes, ou le noter « levé à l'image à 390 ». |
| 2 | `tool/libelles_sources.json` (3 dernières entrées) | `etats.horsLigneBloc`, `administration.horsLigne` et `moderation.horsLigne` sont marqués « à valider par le directeur ». Relus avec la grille de `LIBELLES_COM_RELECTURE.md`, ils sont conformes (ce qui manque, puis quoi faire ; pas de « non envoyé »). | Les marquer « validé par délégation » par une relecture croisée, comme les 658 autres. |

Vérifié sans défaut dans ce diff :
- aucun rôle lu ;
- aucune couleur, police ni rayon en dur (jetons 39) ;
- aucune démo hors garde, aucun appel réseau, aucun fichier `supabase/` ni `.github/` ;
- aucun `skip` ajouté, aucun test supprimé ; les cinq `expect` retirés sont remplacés par des
  assertions plus strictes ;
- parité fr/ar des trois clés nouvelles ;
- worktree propre après les contrôles ;
- aucun tiret cadratin.

### 9.4 Verdict de COM-R-5 : COM-RC (tour 6) ACCEPTÉE, COM-RC-6 passe à `verifie`

Les trois mineurs de COM-R-4 §8.3 sont corrigés et testés. Le correctif 8.3-1 a sa contre-preuve.
Les captures sont bien celles de `145af740`, et les chiffres se rejouent à l'identique. Il ne
reste que des mineurs et des restes déclarés, dont aucun ne bloque `verifie`.

- Statut de preuve : `présent dans le code` et `testé localement`. Rien n'est branché, testé sur
  staging ni déployé ; `verifie` ne vaut ni fusion dans `main` ni mise en production.
- Avant HU-1 : données de démonstration de la Classe du tuteur cohérentes ; relecture arabe.

## 10. Contre-vérification du tour 7 de COM-RC (COM-R-6)

Date : 8 octobre 2026. Session 01HS7t3c, qui n'a écrit aucun code COM. Lecture seule. Ordre du
directeur du 08/10 : tout défaut est corrigé par la session sans lui être soumis ; la relecture
arabe par un agent remplace celle d'un arabophone.

Périmètre :
- code : `ui/communications-v1` @ `5c0bffa3`, diff depuis `7356160b` (7 commits, 78 fichiers) ;
- captures : `pilotage/tuteur-v1` @ `0d33c946`, 200 PNG, section « Après COM-RC tour 7 » de
  `COM-CAPT.md`.

Méthode : relecture du diff et des tests ; comparaison scriptée des fichiers `fr` et `ar` et des
sources de libellés ; échantillon de 30 libellés arabes ; captures régénérées et comparées octet
par octet ; huit PNG lus.

### 10.1 Chiffres rejoués (worktree propre à `5c0bffa3`)

| Contrôle | Annoncé | Rejoué |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | 0 | 0 |
| `flutter test -j 3` | +6516, ~3095, 0 échec | +6516, ~3095, 0 échec (« All tests passed! », 14 min 51 s) |
| `verifier_jetons` | 39 | 39 |
| `verifier_revue` | 1627 | 1627 |
| Captures (`communications_capture_test`, `com_rc7_k_capture_test`) | 200 à `5c0bffa3` | 200 régénérées, **200 identiques octet par octet** à `0d33c946` |

### 10.2 Constats attendus

| # | État | Preuve |
| :--- | :--- | :--- |
| §9.3-1 (N-9 périmé dans COM-CAPT) | **corrigé** | `708ef8f5` : `COM-CAPT.md:595`, `:606` disent N-9 corrigé |
| §9.3-2 (3 libellés hors ligne) | **corrigé** | `7356160b` : « relu conforme par COM-R-5, validé par délégation le 05/10 » |
| « Envoyer » dans la colonne à 768 et 1440 | **corrigé** | `fil_discussion.dart` : bulles reçues pleine colonne, bulles de soi à 92 % au bord d'« Envoyer », téléphone à 86 % ; `com_rc_lot_k_test.dart` ; à l'image, les bulles et « Envoyer » finissent au même bord (`com_studio_canal_1440_clair`, `com_controleur_echanges_1440_clair`) |
| Micro à l'échelle du texte | **corrigé** | `BoutonIcone(suitTexte:)` : icône bornée à ×2, cible `max(48, icône + 16)` ; défaut inchangé pour les autres appelants ; à l'image, le micro est à la hauteur d'« Envoyer » à 320×2 |
| Retrait de « Mode focus » | **corrigé** | `ActionPrincipale(affleurant:)` (défaut `false`) : décalage de la marge interne, sens RTL respecté |
| Champ du Studio d'une ligne à 390 | **corrigé** | aide peinte seulement si elle tient sur une ligne, toujours lue par le lecteur d'écran ; captures `com_studio_canal_saisie_390_*` |
| Contexte, moment, « An-Nour », date | **corrigé** | `texte_sans_coupure.dart` (`nombresLiesSiTient`, `traitsDUnionInsecables`, gluon U+2060) ; à l'image : « Organisation générale » sur deux lignes à 320×2, « 4 octobre » non coupé |
| Démo An-Nour, R-16 | **corrigé** | `demo_an_nour.dart` ; à l'image, Classe An-Nour, Sayyida Mariam partout, « Salle ouverte, Cours dans 10 min », la séance passe avant les annonces |
| Arabe, 26 libellés et démos | **corrigé**, jugé acceptable | 66 valeurs `ar` modifiées et 388 ajoutées (démos Messages, Studio et Communauté ; `tc.groupe`, `classe.*`, `nav.*`) ; parité `com.*` et `notifications.*` complète. Sur l'échantillon : grammaire juste, pluriels accordés (منذ ساعة، منذ ساعتين، منذ 3 ساعات، منذ 11 ساعة), terminologie unifiée (مجدولة، جدولة، رد), deux-points sans espace, marque RTL (U+200F) après un paramètre suivi de « ، », initiales isolées (س‌م). Aucune faute vue. Relecture par agent seulement : acceptable en vertu de l'ordre du 08/10 |

Comportements laissés à l'image, acceptés :
- Focus à 320×2 sans « Envoyer » tant que le champ est vide (décision Focus 320) ;
- fonction de l'auteur abrégée à 320×2 dans la Communauté ;
- nom de fichier arabe à extension latine lu `pdf.3_واجب_الأسبوع` (ordre bidi standard).

### 10.3 Constats nouveaux, tous mineurs

| # | Fichier:ligne | Constat | Correction proposée |
| :--- | :--- | :--- | :--- |
| 1 | `assets/i18n/fr.i18n.json`, `com.vocal.demo.auteurEnseignante` ; `tool/libelles_sources.json` | Seul libellé français validé dont le texte change (« Mme Mariam » devient « Sayyida Mariam »). Sa source dit encore « validé par délégation le 05/10 », sans trace du tour 7. Libellé de démonstration. | Ajouter « modifié au tour 7 (Sayyida, docs/current/00) » à la source. |
| 2 | `ar.i18n.json`, 6 valeurs `»…«` ; test `com_rc_tour7_m_test.dart:378` | Les guillemets arabes sont stockés dans l'ordre visuel parce que le moteur ne les retourne pas. Le rendu est juste à l'image. En revanche, le lecteur d'écran, le copier-coller et tout moteur qui appliquerait le miroir Unicode (U+00AB et U+00BB sont `Bidi_Mirrored`) recevraient des guillemets inversés. | Garder, avec le test, mais le vérifier sur l'aperçu web réel avant ouverture en arabe ; sinon, guillemets droits « " » ou isolation. |
| 3 | `lib/core/tc_groupe/libelles_tc_groupe.dart` (`minutesAvant`) ; `accueil_famille/bloc_seance.dart`, `accueil_eleve/accueil_eleve_page.dart` | Hors du périmètre COM, le tour change le compte à rebours de l'Accueil famille et de l'Accueil élève : arrondi au supérieur, 0 sous une minute. Le changement est cohérent (« dans 10 min » à côté de 14:10) et testé, mais il touche des écrans hors lot. | Le reporter dans le suivi des écrans Accueil (aucune régression vue : suite complète verte). |

Vérifié sans défaut dans ce diff :
- aucun rôle lu ;
- aucune couleur, police ni rayon en dur (jetons 39) ;
- aucune démo hors garde, aucun appel réseau, aucun fichier `supabase/`, `.github/` ni `pubspec.yaml` ;
- un seul `skip` ajouté, celui du groupe de capture sans `CAPTURE_DIR`, comme les autres ;
- un test renommé, aucun supprimé ; les 14 `expect` retirés suivent les renommages (« Élève », « Sayyida »), contre 214 ajoutés ;
- worktree propre après les contrôles ;
- aucun tiret cadratin.

### 10.4 Verdict de COM-R-6 : COM-RC (tour 7) ACCEPTÉE, COM-RC-7 passe à `verifie`

Les deux mineurs de §9 sont corrigés. Les corrections annoncées sont présentes, testées et
visibles à l'image. Les captures sont celles de `5c0bffa3`, et les chiffres se rejouent à
l'identique. L'arabe échantillonné est de bonne qualité. Il reste trois mineurs, dont aucun ne
bloque `verifie`.

- Statut de preuve : `présent dans le code` et `testé localement`. Rien n'est branché, testé sur
  staging ni déployé ; `verifie` ne vaut ni fusion dans `main` ni mise en production.
