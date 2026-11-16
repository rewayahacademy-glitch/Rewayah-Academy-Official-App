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

| Fichier | Rôles | Ce qu'il fait | 390 | 1440 | fr | ar | clair | sombre | liste vide | longue | image | échec | retour | cloche | Écart |
| :--- | :--- | :--- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | :--- |
| `lib/core/widgets/fil_discussion.dart` | tous | **1.** Le fil : bulles, champ, images, échec, cœurs | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG | V-IMG | V-RET | N-CLOCHE |  |
| `lib/core/widgets/ligne_conversation.dart` | tous | **2.** Une ligne de la liste des conversations (aperçu « Photo ») | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG (aperçu « Photo » : `images_correctif_test.dart`) | =ligne 1 | =ligne 9 | N-CLOCHE |  |
| `lib/core/widgets/page_conversation_plein_ecran.dart` | tous (téléphone) | **3.** La page plein écran d'une conversation | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | =ligne 1 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE |  |
| `lib/features/com_messages/barre_conversation.dart` | tous | **4.** La barre compacte : retour ou croix, avatar à côté du nom, « Ouvrir dans Messages » | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | =ligne 6 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE |  |
| `lib/features/com_messages/entete_fil_contexte.dart` | tous (tablette, ordinateur) | **5.** L'en-tête de contexte du fil (page à titre) | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | =ligne 6 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE |  |
| `lib/features/com_messages/fil_contextuel.dart` | tous | **6.** Le fil d'une conversation métier (barre ou en-tête, fil, saisie) | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG | V-IMG | V-RET | N-CLOCHE |  |
| `lib/features/com_messages/fil_en_place.dart` | direction (dossier candidat) | **7.** Le fil ouvert dans une page sans la quitter ; barre compacte, plein écran | V-DOS | V-DOS | V-DOS | V-DOS | V-DOS | N-CAP | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE |  |
| `lib/features/com_messages/liste_fils.dart` | tous | **8.** La liste des conversations | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG (aperçu « Photo ») | sans objet (la liste n'envoie rien) | =ligne 9 | N-CLOCHE |  |
| `lib/features/com_messages/messages_page.dart` | enseignant, tuteur, élève adulte, candidat | **9.** La page Messages et ses routes `/…/messages(/:filId)` | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-MSG | V-TUT (fr) ; N-VIDE (ar) | N-LONG | V-IMG | V-IMG | V-RET | N-CLOCHE |  |
| `lib/features/com_messages/messages_admin.dart` | direction | **10.** La page Messages de l'administration | V-ADM | V-ADM | V-ADM | V-ADM (390 arabe) | V-ADM | V-ADM | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE |  |
| `lib/features/com_messages/entree_messages_contexte.dart` | selon l'objet (voir lignes 14 à 20) | **11.** La rangée « Écrire à … » d'un dossier, d'une Classe ou d'un élève ; ouvre la page Messages ou le volet | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | V-RET (volet du dossier) | N-CLOCHE |  |
| `lib/features/com_messages/entree_messages_candidature.dart` | candidat | **12.** La rangée des messages du candidat avec la direction | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-CAP | N-ROLE | N-CLOCHE |  |
| `lib/features/admin_candidature/candidature_page.dart` | direction | **13.** Le dossier d'un candidat : volet (ordinateur) ou page plein écran (téléphone) | V-DOS | V-DOS | V-DOS | V-DOS | V-DOS | N-CAP | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE |  |
| `lib/features/admin_candidature/dossier_trois_etages.dart` | direction | **14.** Le dossier à trois étages ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | V-RET | N-CLOCHE |  |
| `lib/features/admin_candidature/volet_conversation.dart` | direction | **15.** Le volet et la page plein écran de la conversation du dossier | V-DOS | V-DOS | V-DOS | V-DOS | V-DOS | N-CAP | N-CAP | N-LONG | =ligne 1 (V-IMG) | =ligne 1 (V-IMG) | V-RET | N-CLOCHE |  |
| `lib/features/admin_dossiers/detail_dossier.dart` | direction | **16.** Le dossier d'un enseignant ou d'un tuteur ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CAP | N-CLOCHE |  |
| `lib/features/classe_tuteur/classe_tuteur_page.dart` | tuteur | **17.** La Classe de l'enfant ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE |  |
| `lib/features/enseignant_classes/mes_classes_page.dart` | enseignant | **18.** Mes Classes ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE |  |
| `lib/features/fiche_groupe/fiche_groupe_page.dart` | enseignant | **19.** La fiche d'une Classe ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE |  |
| `lib/features/ma_classe_adulte/ma_classe_adulte_page.dart` | élève adulte | **20.** Ma classe ; pose l'entrée des messages | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | =ligne 11 | N-CLOCHE |  |
| `lib/features/dossier/attente_page.dart` | candidat | **21.** La page d'attente du candidat ; pose l'entrée des messages de la candidature | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | =ligne 12 | N-CLOCHE |  |
| `lib/features/comptable/beneficiaires/fil_profil_paiement_page.dart` | comptable | **22.** Le fil « Profil de paiement » d'un bénéficiaire | V-CPT (ancienne mise en page) | N-CAP | V-CPT | N-CAP | V-CPT | V-CPT | V-CPT (fil vide) | N-LONG | =ligne 1 | =ligne 1 | N-CAP | N-CLOCHE | Au téléphone : gros titre de page « Fil « Profil de paiement » », bloc d'identité, zone grise et phrase d'aide : PAS la mise en page de la messagerie refaite. Essayé et retiré : la version plein écran casse la relance (`relance_fil_test.dart` : le message modèle préchargé n'arrive plus dans le champ). Reprise à faire avec ce correctif, sur décision du directeur. |
| `lib/features/controleur/echanges_controleur_page.dart` | contrôleur | **23.** Les échanges du contrôleur avec l'administration, sur une mission | N-ECART ; N-ROLE | N-ECART ; N-ROLE | N-ECART ; N-ROLE | N-ECART ; N-ROLE | N-ROLE | N-ROLE | N-ROLE | N-LONG | sans objet (aucun envoi d'image) | tests `echanges_controleur_test.dart` (ligne d'échec et menu) | N-ROLE | N-CLOCHE | Pose `FilDiscussion` à la main dans `PageShell` avec un contexte épinglé : tolérée dans `tool/conversations_tolerees.txt`. Phrase d'aide sous le champ toujours présente (règle SUPERPOS-1). |
| `lib/features/com_studio/canal_page.dart` | direction (équipe, Studio) | **24.** Un canal d'équipe du Studio | V-STU (ancienne mise en page) | V-STU | N-VIDE | V-STU | V-STU | V-STU | N-CAP | N-LONG | sans objet (aucun envoi d'image) | N-CAP | N-CAP | N-CLOCHE | Pose `FilDiscussion` à la main dans `PageShell` ; en-tête de canal (statut, membres, mode focus) ; au téléphone les bulles touchent le bord de la zone grise et la phrase d'aide est présente. Tolérée dans `tool/conversations_tolerees.txt`. |
| `lib/core/router/app_router.dart` | tous | **25.** Les routes `/…/messages(/:filId)` (attente, tuteur, enseignant, administration) qui montent la page Messages ; au téléphone `…/messages/:filId` est une page à elle | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | =ligne 9 | N-LONG | =ligne 1 | =ligne 1 | V-RET | N-CLOCHE | |
| `lib/features/_dev/galerie/catalogue_galerie.dart` | aucun (outil) | **26.** La galerie de composants | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV |  |
| `lib/features/demo/communications/com_messages_demo.dart` | aucun (démonstration) | **27.** Les Messages de démonstration | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV |  |
| `lib/features/demo/communications/com_vocal_demo.dart` | aucun (démonstration) | **28.** Le vocal de démonstration | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV | N-DEV |  |

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
- **V-CPT** : captures `autres_entrees/com_fil_profil_{390x844@3_light,390x844@3_dark,320x640@2_x2_light}.png` (français seulement).
- **V-IMG** : captures `docs/current/captures/E2E/IMAGES-CORRECTIF/` (envoi en cours, échec, menu, après envoi, destinataire : 390 fr et ar) et `docs/current/captures/E2E/IMAGE-EXPEDITEUR/` (1440) ; tests `images_correctif_test.dart`, `images_messagerie_test.dart`, `image_expediteur_test.dart`.
- **V-RET** : tests de retour : `conversation_dans_dossier_test.dart` (replier le volet ou la page, adresse du dossier inchangée), `messages_page_test.dart`, `messagerie_plein_ecran_test.dart`.

### Légende des raisons

- **N-PROD** : aucun accès à l'application déployée ni à la base de production dans ce lot : seuls des ports de démonstration et des doubles de test ont servi ; à vérifier par le directeur en production.
- **N-ROLE** : ce rôle n'a pas de compte de démonstration qui atteigne cet écran ; l'écran n'a été monté que sous un autre rôle ou par un test.
- **N-CAP** : aucune capture de cette case dans ce lot ; le comportement vient du composant partagé (lignes 1, 6, 7) qui, lui, est capturé.
- **N-LONG** : aucune capture ni test d'une conversation de plus de vingt messages ; défilement et groupes de messages non rejoués ici.
- **N-CLOCHE** : la cloche ouvre `destination`, une route fournie par le serveur ; aucune notification de message en démonstration ni en test, donc l'ouverture depuis la cloche n'a pas été rejouée (elle atterrit sur la page Messages, ligne 9).
- **N-VIDE** : capture absente (arabe) ; seul le rendu français est capturé.
- **N-ECART** : écart connu : cette entrée n'a PAS la mise en page de la messagerie refaite ; elle est dans `tool/conversations_tolerees.txt` ou décrite dans la colonne Écart, à traiter sur décision du directeur.
- **N-DEV** : outil de développement (démonstration ou galerie), forcé à faux en production ; non vérifié.

### Hors garde, à connaître

- `lib/features/com_communaute/reponses.dart` ne cite `FilDiscussion` qu'en commentaire : la réponse à une publication de
  la Communauté est un composer à part, voulu (`UX_REVIEW` L0). Il n'est pas une conversation de personne ; il n'a pas
  de ligne ici et la garde ne le voit pas.
- Rôles de la colonne « Rôles » : direction, comptable, contrôleur, enseignant, candidat, tuteur, élève adulte. L'élève
  de moins de 18 ans n'est partie d'aucun fil (COM-BACK-1).
- **Phrase d'aide sous le champ** (`champVide`) : retirée de la conversation du dossier (page plein écran). Elle reste
  dans les fils posés en page à titre (Studio, contrôleur, comptable) : la retirer partout inverse la règle SUPERPOS-1
  (un bouton inactif est expliqué) et une dizaine de tests ; décision du directeur.
- **Le « plante »** décrit par le directeur depuis un profil candidat **n'a pas été reproduit** : 18 situations montées
  en test (390, 390 court, texte ×2, clavier, 320, 768, 1024, 1440, français et arabe) ne lèvent aucune exception, et la
  démonstration comme le playground n'atteignent pas le dossier d'un candidat (aucun compte de direction). Voir la PR.

