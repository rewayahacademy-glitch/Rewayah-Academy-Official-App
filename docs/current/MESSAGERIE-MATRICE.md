# Messagerie : matrice des entrées (CONVERSATIONS-PARTOUT)

Lot du 16/11/2026, consigne du directeur : « avoir toujours une vision globale ». Un changement sur un écran peut
casser les autres : cette matrice nomme **chaque fichier de `lib/` qui affiche ou ouvre une conversation**, les rôles
qui l'atteignent, et pour chaque vérification si elle a été faite (avec la preuve) ou non (avec la raison).

**Cette matrice est gardée.** `dart run tool/verifier_conversations.dart` (et son test
`test/tool/verifier_conversations_test.dart`, joué par la CI) relève par recherche tous les fichiers de `lib/` qui
utilisent un composant de conversation, et **échoue** si l'un d'eux n'a pas sa ligne ici (première cellule : son chemin
entre apostrophes inverses), si une ligne nomme un fichier disparu, ou si un écran recompose un en-tête de conversation
au lieu du composant partagé (hors `tool/conversations_tolerees.txt`, qui ne fait que rétrécir). Une future entrée ne
peut donc plus être oubliée.

Statut au dépôt de la PR : *présent dans le code*, *testé localement* (tests Flutter, captures de test) ; **rien n'est
prouvé en production** : « fait » veut dire « prouvé par le directeur en production ». La recette du directeur se fait
entrée par entrée, à partir de ce tableau.

## Les entrées

| Fichier | Rôles | Ce qu'il fait | 390 | 1440 | fr | ar | clair | sombre | liste vide | longue | image | échec | retour | cloche | non lus | Écart |
| :--- | :--- | :--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | :--- |
| `lib/core/widgets/fil_discussion.dart` | tous | **1.** Le fil : bulles, champ, images, échec, cœurs | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG | V-IMG | V-RET | N-CLOCHE | sans objet (le fil ne porte pas de badge) |  |
| `lib/core/widgets/ligne_conversation.dart` | tous | **2.** Une ligne de la liste des conversations (aperçu « Photo ») | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG (aperçu « Photo » : `images_correctif_test.dart`) | =ligne 1 | =ligne 9 | N-CLOCHE | affichage V-NL-LISTE ; justesse N-NL-PROD |  |
| `lib/core/widgets/page_conversation_plein_ecran.dart` | tous (téléphone) | **3.** La page plein écran d'une conversation | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | =ligne 1 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE | sans objet |  |
| `lib/features/com_messages/barre_conversation.dart` | tous | **4.** La barre compacte : retour ou croix, avatar à côté du nom, « Ouvrir dans Messages » | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | =ligne 6 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE | sans objet |  |
| `lib/features/com_messages/entete_fil_contexte.dart` | tous (tablette, ordinateur) | **5.** L'en-tête de contexte du fil (page à titre) | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | =ligne 6 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE | badge d'attention du fil (`badgeDuFil`) ; N-CAP ; N-NL-PROD |  |
| `lib/features/com_messages/fil_contextuel.dart` | tous | **6.** Le fil d'une conversation métier (barre ou en-tête, fil, saisie) | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG | V-IMG | V-RET | N-CLOCHE | marque le fil lu à l'ouverture : V-NL-LISTE (`messages_lu_anticipe_test.dart`) ; N-NL-PROD |  |
| `lib/features/com_messages/fil_en_place.dart` | direction (dossier candidat) | **7.** Le fil ouvert dans une page sans la quitter ; barre compacte, plein écran | V-DOS | V-DOS | V-DOS | V-DOS | V-DOS | N-CAP | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE | marque le fil lu à l'ouverture (`_marquerLu`) puis `onLu` relit les badges du dossier ; N-CAP ; N-NL-PROD |  |
| `lib/features/com_messages/liste_fils.dart` | tous | **8.** La liste des conversations | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG (aperçu « Photo ») | sans objet (la liste n'envoie rien) | =ligne 9 | N-CLOCHE | affichage V-NL-LISTE ; justesse N-NL-PROD |  |
| `lib/features/com_messages/ligne_fil.dart` | tous | **30.** La ligne d'un fil dans une liste (extraite de la ligne 8 : avatar, titre, aperçu, heure, non lus, « Nouveau ») ; seul endroit qui la compose | =ligne 8 | =ligne 8 | =ligne 8 | =ligne 8 | =ligne 8 | =ligne 8 | =ligne 8 | N-LONG | =ligne 8 | sans objet (la ligne n'envoie rien) | =ligne 8 | =ligne 8 | =ligne 8 |  |
| `lib/features/admin_acces_agents/choix_conversations_essai.dart` | direction | **31.** Le choix des conversations d'essai de Praxis : la liste de la messagerie de la direction (`PortMessagesMetier.fils`), chaque conversation posée par la ligne 30 avec une case à cocher, dix au plus | N-CAP | V-PX4 (360) | V-PX4 | V-PX4 | V-PX4 | N-CAP | V-PX4 (phrase « créez d'abord une conversation de test ») | N-LONG (20 résultats au plus, la recherche affine) | =ligne 30 | V-PX4 (phrase et Réessayer, test) | sans objet | =ligne 8 | =ligne 8 | |
| `lib/features/com_messages/messages_page.dart` | enseignant, tuteur, élève adulte, candidat | **9.** La page Messages et ses routes `/…/messages(/:filId)` | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG | V-IMG | V-RET | N-CLOCHE | liste : V-NL-LISTE ; en-tête (`nonLusMessagesProvider`) : V-NL-TETE (direction seulement) ; autres rôles N-ROLE ; N-NL-PROD |  |
| `lib/features/com_messages/messages_admin.dart` | direction | **10.** La page Messages de l'administration | V-ADM | V-ADM | V-ADM | V-ADM (390 arabe) | V-ADM | V-ADM | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE | V-NL-TETE (en-tête de l'administration, 320, 599, 1440) et V-NL-LISTE ; N-NL-PROD |  |
| `lib/features/com_messages/entree_messages_contexte.dart` | selon l'objet (voir lignes 14 à 20) | **11.** La rangée « Écrire à … » d'un dossier, d'une Classe ou d'un élève ; ouvre la page Messages ou le volet | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | V-RET (volet du dossier) | N-CLOCHE | affichage V-NL-ENT (administration, enseignant, tuteur, états) ; N-NL-PROD |  |
| `lib/features/com_messages/entree_messages_candidature.dart` | candidat | **12.** La rangée des messages du candidat avec la direction | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-ROLE | N-CLOCHE | affichage V-NL-CAND ; N-NL-PROD |  |
| `lib/features/admin_candidature/candidature_page.dart` | direction | **13.** Le dossier d'un candidat : volet (ordinateur) ou page plein écran (téléphone) | V-DOS | V-DOS | V-DOS | V-DOS | V-DOS | N-CAP | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE | le volet marque lu puis relit l'entrée (`_messagesLus`) ; N-CAP ; N-NL-PROD |  |
| `lib/features/admin_candidature/dossier_trois_etages.dart` | direction | **14.** Le dossier à trois étages ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | V-RET | N-CLOCHE | =ligne 11 |  |
| `lib/features/admin_candidature/volet_conversation.dart` | direction | **15.** Le volet et la page plein écran de la conversation du dossier | V-DOS | V-DOS | V-DOS | V-DOS | V-DOS | N-CAP | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE | =ligne 7 |  |
| `lib/features/admin_dossiers/detail_dossier.dart` | direction | **16.** Le dossier d'un enseignant ou d'un tuteur ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CAP | N-CLOCHE | =ligne 11 |  |
| `lib/features/classe_tuteur/classe_tuteur_page.dart` | tuteur | **17.** La Classe de l'enfant ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE | =ligne 11 (tuteur : V-NL-ENT) |  |
| `lib/features/enseignant_classes/mes_classes_page.dart` | enseignant | **18.** Mes Classes ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE | =ligne 11 (enseignant : V-NL-ENT) |  |
| `lib/features/fiche_groupe/fiche_groupe_page.dart` | enseignant | **19.** La fiche d'une Classe ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE | =ligne 11 (enseignant : V-NL-ENT) |  |
| `lib/features/ma_classe_adulte/ma_classe_adulte_page.dart` | élève adulte | **20.** Ma classe ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE | =ligne 11 ; élève adulte N-ROLE ; N-NL-PROD |  |
| `lib/features/dossier/attente_page.dart` | candidat | **21.** La page d'attente du candidat ; pose l'entrée des messages de la candidature | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | N-CLOCHE | candidat en salle d'attente, « Écrire à l'Administration » : V-NL-CAND ; N-NL-PROD |  |
| `lib/features/com_messages/fil_libre.dart` | contrôleur | **29.** Le fil d'une conversation qui n'est pas un fil de Messages (échanges d'une mission) : barre libre et fil plein écran | V-CTR | N-CAP | N-ROLE | N-ROLE | N-ROLE | N-ROLE | N-ROLE | N-LONG | sans objet | =ligne 1 | V-RET | N-CLOCHE | sans objet |  |
| `lib/features/comptable/beneficiaires/fil_profil_paiement_page.dart` | comptable | **22.** Le fil « Profil de paiement » d'un bénéficiaire | V-CPT (barre compacte et fil plein écran, `relance_fil_test.dart`) | N-CAP (page à titre, inchangée sur ordinateur) | V-CPT | N-CAP | V-CPT | V-CPT | V-CPT (fil vide) | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE | N-ROLE (aucun badge de non lus sur ce fil ; la lecture le marque lu) | Au téléphone : la page est une page à elle (`PageConversationPleinEcran`, `BarreConversation`, fil plein écran), comme Messages ; le message modèle reste en brouillon dans le champ. Cause du premier échec trouvée et corrigée dans le composant : quand la capacité d'écrire arrivait après le premier rendu, `FilDiscussion` ne rebranchait pas la mémoire des brouillons (`_preparerBrouillon`, aussi dans `didUpdateWidget`). Sur ordinateur : page à titre, inchangée. |
| `lib/features/controleur/echanges_controleur_page.dart` | contrôleur | **23.** Les échanges du contrôleur avec l'administration, sur une mission | V-CTR (barre compacte et fil plein écran : `echanges_controleur_test.dart`, `echanges_compact_superpos_test.dart`) | V-CTR (page à titre, contexte épinglé en lignes) | N-ROLE | N-ROLE | N-ROLE | N-ROLE | N-ROLE | N-LONG | sans objet (aucun envoi d'image) | tests `echanges_controleur_test.dart` (ligne d'échec et menu) | V-RET | N-CLOCHE | N-ROLE | Au téléphone le fil passe par `FilLibre` (barre `BarreConversation.libre` : Classe et date au titre, heure en ligne fine) ; la phrase de contexte épinglée n'existe plus à ce gabarit. Rôle non montable avec un vrai compte. |
| `lib/features/com_studio/canal_page.dart` | direction (équipe, Studio) | **24.** Un canal d'équipe du Studio | V-STU (ancienne mise en page) | V-STU | N-VIDE | V-STU | V-STU | V-STU | N-CAP | N-LONG | sans objet (aucun envoi d'image) | N-CAP | N-CAP | N-CLOCHE | badge du canal dans Aujourd'hui : `aujourdhui_page_test.dart` ; N-NL-PROD | Pose `FilDiscussion` à la main dans `PageShell` ; en-tête de canal (statut, membres, mode focus) ; au téléphone les bulles touchent le bord de la zone grise. **Non repris** : le fil plein écran n'a pas d'emplacement d'en-tête, donc le Mode focus (« Quitter le focus ») disparaît ; essayé (`pleinEcran: true`), `test/features/com_studio/focus_studio_test.dart` échoue (R-COM-09, 390, 768, 1440, arabe). Tolérée dans `tool/conversations_tolerees.txt`, sur décision du directeur. |
| `lib/core/router/app_router.dart` | tous | **25.** Les routes `/…/messages(/:filId)` (attente, tuteur, enseignant, administration) qui montent la page Messages ; au téléphone `…/messages/:filId` est une page à elle | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE | en-tête de navigation : V-NL-TETE (direction) ; autres rôles N-ROLE ; N-NL-PROD | |
| `lib/features/_dev/galerie/catalogue_galerie.dart` | aucun (outil) | **26.** La galerie de composants | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV |  |
| `lib/features/demo/communications/com_messages_demo.dart` | aucun (démonstration) | **27.** Les Messages de démonstration | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV |  |
| `lib/features/demo/communications/com_vocal_demo.dart` | aucun (démonstration) | **28.** Le vocal de démonstration | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV |  |

### Légende des cases

- **V-xxx** : vérifié ; le code renvoie à la capture ou au test nommé dans la légende des preuves.
- **N-xxx** : non vérifié, pour la raison donnée dans la légende des raisons.
- **=ligne N** : la case est celle du fichier de la ligne N (le fichier ne dessine rien de lui-même).

### Légende des preuves

- **V-DOS** : captures `apres/dossier_candidat_{390,1440}-{fr,ar}.png` (et `avant/` pour l'ancien rendu), clair ; test `test/features/admin_candidature/conversation_mise_en_page_test.dart` (390, 390 court, texte ×2, clavier, 320 texte ×2 clavier, 768, 1440, fr et ar : une barre, rien de l'ancien en-tête, marge, aucune exception).
- **V-MSG** : captures `messagerie/bulles-fil-{390,1440}-{fr,ar}-{clair,sombre}.png`, `messagerie/bulles-liste-390-{fr,ar}-{clair,sombre}.png`, `messagerie/messagerie-{1440,390}-{fr,ar}.png` et `-clavier.png`.
- **V-ADM** : captures `messagerie/bulles-admin-1440-fr-clair-{fil,liste}.png` et `autres_entrees/com_admin_messages_{390_clair,390_rtl_clair,1440_clair,1440_sombre,390_sombre}.png`.
- **V-TUT** : captures `autres_entrees/com_messages_fil_tuteur_*`, `com_messages_fil_contexte_enseignant_*`, `com_messages_liste_tuteur_*`, `com_messages_vide_tuteur_*`, `com_messages_hors_ligne_tuteur_*` (390 clair, 390 arabe, 1440, sombre).
- **V-STU** : captures `autres_entrees/com_studio_canal_{390_clair,390_rtl_clair,1440_clair,1440_sombre,390_sombre}.png`.
- **V-CPT** : captures `autres_entrees/com_fil_profil_{390x844@3_light,390x844@3_dark,320x640@2_x2_light}.png` (français seulement) : **captures de l'ancienne mise en page au téléphone** ; la nouvelle (barre et fil plein écran) n'est prouvée que par le test `relance_fil_test.dart`, sans capture régénérée.
- **V-CTR** : tests `echanges_controleur_test.dart` et `echanges_compact_superpos_test.dart` (320 ×2, 390, 1440, fr et ar : la barre au téléphone, le contexte en lignes sur ordinateur) ; **aucune capture** de la nouvelle page.
- **V-PX4** : captures `docs/current/captures/E2E/PX-4/praxis_*_{fr,ar}_360.png` (le choix des conversations d'essai est dans la carte des réglages de la section Praxis) ; test `test/features/admin_acces_agents/section_praxis_test.dart` (cocher, dix au plus, recherche, liste vide, liste illisible, refus de la double vérification).
- **V-IMG** : captures `docs/current/captures/E2E/IMAGES-CORRECTIF/` (envoi en cours, échec, menu, après envoi, destinataire : 390 fr et ar) et `docs/current/captures/E2E/IMAGE-EXPEDITEUR/` (1440) ; tests `images_correctif_test.dart`, `images_messagerie_test.dart`, `image_expediteur_test.dart`.
- **V-RET** : tests de retour : `conversation_dans_dossier_test.dart` (replier le volet ou la page, adresse du dossier inchangée), `messages_page_test.dart`, `messagerie_plein_ecran_test.dart`.

### Légende des preuves « non lus »

- **V-NL-LISTE** : la pastille du nombre de non lus dans la liste et son retrait après lecture : `ligne_conversation`, `messages_page_test.dart`, `messages_lu_anticipe_test.dart`, `badge_non_lu_test.dart`.
- **V-NOUVEAU** (NOUVEAU-FILS, 16/11/2026) : le badge « Nouveau » dans la ligne (`ligne_conversation`, composant `badge_nouveau`), « Nouveau · aucun message » pour une conversation vide, le filtre « Nouveaux » de `liste_fils` : `test/features/com_messages/nouveau_fils_test.dart` ; la règle (moins de 7 jours, aucune lecture de l'équipe) est au serveur, `supabase/tests/scenarios_nouveau_fils.sql`. À 390 avec les vraies polices, les trois puces (Tous, Non lus, Nouveaux) tiennent sur la rangée (captures `NOUVEAU-FILS`) ; quand elles ne tiennent pas (texte agrandi, polices de test), la règle de `RangeeFiltres` range le reste sous « Plus » et le test le vérifie.
- **V-NL-ENT** : le badge de la rangée « Écrire à … » (entrée contextuelle) : `entrees_admin_test.dart`, `entrees_enseignant_test.dart`, `entrees_tuteur_test.dart`, `entrees_etats_test.dart`.
- **V-NL-CAND** : le candidat en salle d'attente, « Écrire à l'Administration », nombre et badge : `messages_candidat_test.dart` (et capture `messages_candidat_capture_test.dart`).
- **V-NL-TETE** : le nombre dans l'en-tête de navigation (`nonLusMessagesProvider`) : `test/widgets/admin_shell_messages_test.dart` (320, 599, 1440), direction seulement.
- **N-NL-PROD** : **la justesse du nombre n'est pas vérifiée en production** : les tests vérifient que le nombre donné par le port s'affiche (et baisse à la lecture), pas que le serveur le calcule juste (`com_fil_json`, non lus d'un fil) ; noté « non vérifié en production » tant que le directeur ne l'a pas vu.

### Légende des raisons

- **N-PROD** : aucun accès à l'application déployée ni à la base de production dans ce lot : seuls des ports de démonstration et des doubles de test ont servi ; à vérifier par le directeur en production.
- **N-ROLE** : ce rôle n'a pas de compte de démonstration qui atteigne cet écran ; l'écran n'a été monté que sous un autre rôle ou par un test.
- **N-CAP** : aucune capture de cette case dans ce lot ; le comportement vient du composant partagé (lignes 1, 6, 7) qui, lui, est capturé.
- **N-LONG** : aucune capture ni test d'une conversation de plus de vingt messages ; défilement et groupes de messages non rejoués ici.
- **N-CLOCHE** : la cloche ouvre `destination`, une route fournie par le serveur ; aucune notification de message en démonstration ni en test, donc l'ouverture depuis la cloche n'a pas été rejouée (elle atterrit sur la page Messages, ligne 9).
- **N-VIDE** : capture absente (arabe) ; seul le rendu français est capturé.
- **N-ECART** : écart connu : cette entrée n'a PAS la mise en page de la messagerie refaite ; elle est dans `tool/conversations_tolerees.txt` ou décrite dans la colonne Écart, à traiter sur décision du directeur.
- **N-DEV** : outil de développement (démonstration ou galerie), forcé à faux en production ; non vérifié.

### Vérifications transversales (une fois, dans le composant partagé)

| Vérification | Où | Preuve | Reste à vérifier |
| :--- | :--- | :--- | :--- |
| **Pas de rectangle derrière le champ** (consigne du directeur, 16/11 : « supprime le rectangle ») : le champ et le bouton image flottent sur le fond de la conversation, sans bande, bord ni ombre à part | `lib/core/widgets/fil_discussion.dart` (ligne 1), donc toutes les entrées qui posent un fil : lignes 6, 7, 15, 22, 23, 24 | garde de rendu captures `rectangle/{avant,apres}/` ; `test/core/widgets/fil_saisie_sans_rectangle_test.dart` (téléphone plein écran, ordinateur, tablette, page à titre, texte ×2 ; contre-épreuve) ; captures `rectangle/avant_*` et `rectangle/apres_*` (1440 et 390, fr et ar, clair) | production ; rôles non montables (voir la légende) |
| **Colonne « non lus »** | voir la dernière colonne du tableau | tests nommés dans la légende des preuves « non lus » | **justesse du nombre en production** : N-NL-PROD |

### Fermeture d'un volet de conversation (MESSAGERIE-COULEURS, pilote, 16/11/2026)

Régression de #540 : « sur ordinateur, la croix a disparu, le volet ne peut plus être fermé ». **Cause mesurée** : la barre
compacte de la conversation se repliait (hauteur 0) quand on remontait un long fil, et emportait avec elle le seul bouton
qui fermait le volet (sur le code d'avant, après avoir remonté un fil de quarante messages, le bouton n'était plus atteignable ;
la croix était de plus au bord de début, pas de fin). **Corrigé** : dans un volet (`FilEnPlace(volet: true)`), la croix
« Fermer la conversation » est le dernier contrôle de la barre, au bord de **fin** (LTR et RTL), la barre ne se replie jamais, et
Échap ferme le volet (le volet prend le focus à l'ouverture). Test : `conversation_mise_en_page_test.dart`, groupe « volet »
(1024 et 1440, fr et ar : croix au bord de fin, atteignable après avoir remonté, fermée par la croix puis par Échap).

Entrées en volet : **une seule** dans le code, `volet_conversation.dart` (dossier candidat, direction ; ligne 15). Aucune autre
entrée n'ouvre un volet : le comptable (ligne 22) et le contrôleur (ligne 23) sont des pages avec leur flèche de retour ; la page
Messages (lignes 6 et 7) met la liste à côté du fil. **Non touché, à savoir** : la barre de la page plein écran (téléphone, et
fil de la page Messages sur ordinateur) se replie toujours quand on remonte un long fil (choix de MESSAGERIE-PLEIN-ECRAN) ; sur
ordinateur dans Messages, elle emporte alors le bouton « i » du panneau de contexte jusqu'à ce qu'on redescende.

### Hors garde, à connaître

- `lib/features/com_communaute/reponses.dart` ne cite `FilDiscussion` qu'en commentaire : la réponse à une publication de
  la Communauté est un composer à part, voulu (`UX_REVIEW` L0). Il n'est pas une conversation de personne ; il n'a pas
  de ligne ici et la garde ne le voit pas.
- Rôles de la colonne « Rôles » : direction, comptable, contrôleur, enseignant, candidat, tuteur, élève adulte. L'élève
  de moins de 18 ans n'est partie d'aucun fil (COM-BACK-1).
- **Phrase d'aide sous le champ** (`champVide`) : **retirée partout** (directeur, 16/11/2026 : « supprimer la phrase d'aide sous le champ »). SUPERPOS-1 est modifiée par un commentaire daté dans `FilDiscussion` ; les limites et erreurs ne s'affichent que quand elles s'appliquent. Les tests qui attendaient la phrase ont été réécrits un par un (liste dans la PR).
- **Lecteur vocal dans MA bulle : à revoir à l'ouverture des vocaux** (IMAGE-CANDIDAT, 16/11/2026, décision du pilote : les
  vocaux ne sont pas ouverts, « gros chantier », ne pas le prendre). `LecteurVocalRecu` (`com_vocal/lecteur_vocal.dart`)
  écrit en encre de surface claire (`surfaceRaised`) sans carte : dans la bulle « de soi » (violet de marque), ce serait de
  l'encre sombre sur violet. Non mesuré, non corrigé. Le correctif des liens (`EncreLienSurFond`) ne le couvre pas : il ne
  concerne que `LienFleche`.
- **Le « plante »** décrit par le directeur depuis un profil candidat **n'a pas été reproduit** : 18 situations montées
  en test (390, 390 court, texte ×2, clavier, 320, 768, 1024, 1440, français et arabe) ne lèvent aucune exception, et la
  démonstration comme le playground n'atteignent pas le dossier d'un candidat (aucun compte de direction). Voir la PR.

