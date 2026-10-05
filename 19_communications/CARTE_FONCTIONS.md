# Communications V1, carte des fonctions finale (COM-FUS, 5 octobre 2026)

Livrable de la spec §30, point 13 (« carte des fonctions finale avec routes réelles »).
Elle décrit l'état de `ui/communications-v1` après la fusion COM-FUS des voies
`ui/com-voc`, `ui/com-msg`, `ui/com-commu`, `ui/com-stu` et `ui/com-ann`. Chaque
fonction a **un seul endroit** dans le code, une route réelle par rôle (ou aucune, quand
la fonction se pose dans une page existante), la capacité qu'elle lit, son port et l'état
du contrat serveur (`COM-BR.md`).

## Statut de preuve, pour toute la carte

| Niveau | État |
| :--- | :--- |
| spécifié | oui : `V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md`, `02_DECOUPAGE.md`, `COM-BR.md` |
| présent dans le code | oui, sur `ui/communications-v1` @ e21b9d9d (fusions ed2fac61, 217a16c6, 1ce71e43, aa115b4b, 45a8d07e ; montage 02416e91) |
| testé localement | oui : `flutter test -j 2` sur e21b9d9d, 6214 réussis, 2890 sautés, 0 échec ; `dart analyze --fatal-infos` 0 ; `verifier_jetons` 39 ; `verifier_revue` 1627 |
| testé sur staging | **non** (aucune pull request, aucun aperçu Vercel) |
| déployé | **non** (`main` non touché) |
| contrat serveur | **aucun** : les seize lignes COM-BR-01 à COM-BR-16 sont « à écrire ». En production, chaque port est neutre (`CapaciteIndisponible('COM-BR-nn')`) et chaque écran dit « pas encore disponible » ; rien ne se voit en contenu qu'en démonstration (`/demo/communications`, sous `environnementAutoriseDemo`) ou en test. |

Règles communes vérifiées par les tests : un widget lit une capacité, jamais un rôle
(test `aucun fichier des Communications ne lit un role`) ; capacité absente = action non
rendue ; chaque écran a ses états chargement, contenu, vide, erreur, hors ligne,
indisponible ; aucune URL de stockage affichée ; i18n fr et ar.

Abréviations des rôles : **T** tuteur (et élève adulte, rôle `guardian`), **E** enseignant,
**C** contrôleur, **A** administration. L'élève mineur n'a aucune entrée Communications
(pas de cloche, réponse du directeur, Q5).

## 1. Messages métier (COM-MSG-1, COM-MSG-2)

| Fonction | Seul endroit (code) | Route réelle par rôle | Entrée réelle | Capacité lue | Port | Serveur |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Liste des fils et fil contextuel (COM-M01, COM-W01) | `lib/features/com_messages/messages_page.dart` (`EspaceMessagesMetier`), `fil_contextuel.dart`, `liste_fils.dart` | T `/tuteur/messages`, `/tuteur/messages/:filId` ; E `/enseignant/messages`, `/enseignant/messages/:filId` ; A `/admin/operations/communications/messages`, `/:filId` | T : Espace Classe (`classe_tuteur_page.dart`) et cloche ; E : Mes Classes et fiche de Classe ; A : tableau de bord, ligne Communications, onglet Messages | `CapaciteCommunication.ecrireDansFil` (COM-BR-16) **et** `CapaciteFil.ecrire` portée par le fil | `PortMessagesMetier` | COM-BR-01, COM-BR-02 |
| Onglet Messages de l'administration | `lib/features/com_messages/messages_admin.dart` (`MessagesAdminPage`), monté par `app_router.dart` à COM-FUS | A `/admin/operations/communications/messages`, `/:filId` (coquille admin, domaine Opérations) | onglet Messages de `SousNavigationDomaine` | idem | `PortMessagesMetier` (vue admin) | COM-BR-14 |
| Entrée contextuelle « Écrire à … » | `lib/features/com_messages/entree_messages_contexte.dart` | aucune route propre : ouvre le fil sur la route du rôle | T : Espace Classe ; E : Mes Classes, fiche de Classe ; A : détail d'un dossier (`detail_dossier.dart`) ; élève adulte de démonstration : `ma_classe_adulte_page.dart` | idem | `PortMessagesMetier.conversationsPourObjet`, `ouvrirConversation`, `filPourObjet` | COM-BR-01 (extension proposée par COM-MSG-2) |
| Recherche des fils | `lib/features/com_messages/recherche_fils.dart` | sur la route Messages du rôle | champ de la liste | aucune | filtre local sur `fils()` | COM-BR-01 (réserve A05) |
| Fils du contrôleur sur sa mission | `lib/features/controleur/echanges_controleur_page.dart` (inchangé, C13) | C `/controleur/echanges` | navigation du contrôleur | `peutEcrire` (CT-6) | `PortEchanges` | BR-CT-13, COM-BR-14 (une seule source à BR-1) |

## 2. Message vocal (COM-VOC-1, branché à COM-FUS)

| Fonction | Seul endroit | Route réelle par rôle | Entrée réelle | Capacité lue | Port | Serveur |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Composer vocal (`VoiceMessageComposer`, 17 états, 3:00, pré-écoute, aucun envoi automatique) | `lib/features/com_vocal/composer_vocal.dart` | aucune route : posé dans `FilDiscussion.emplacementVocal` | fil contextuel des Messages (T, E, A) ; canal du Studio (A), Focus compris (`ComposerMinimal`) | `CapaciteCommunication.envoyerVocal` (ajoutée à COM-FUS, COM-BR-16) : fermée en production, **aucun composer rendu** | `PortEnregistreurVocal` (neutre : `EnregistreurVocalIndisponible`) | COM-BR-03 (paquet `record` absent de `pubspec.yaml`, décision BR-1) |
| Envoi d'un vocal | `lib/features/com_vocal/envoi_vocal.dart` (`PortEnvoiVocal`, `ClesVocales`) | idem | « Envoyer » du composer seulement | idem | `PortEnvoiVocal` (neutre : `EnvoiVocalIndisponible`), une clé d'idempotence par vocal ; à l'accusé, une bulle « Message vocal de 0:06 », « Envoyé », entre dans le fil ou le canal ouvert (`bulleVocalConfirme`, revue COM-FUS), aucune bulle sans accusé | COM-BR-03, COM-BR-02 |
| Lecture d'un vocal reçu | `lib/features/com_vocal/lecteur_vocal.dart` (`LecteurVocalRecu`, `lecteursVocauxDuMessage`) | aucune route | dans la bulle du fil (Messages, Studio), à la place de la ligne « Message vocal de 0:28 » ; la lecture seule garde la ligne texte | `PieceJointe.peutOuvrir` | `PortLectureVocale` (neutre : `LectureVocaleIndisponible`) ; `LectureVocaleJustAudio` présent, non branché | COM-BR-03 (lien signé de courte durée au toucher) |

## 3. Communauté enseignants (COM-COMU-1, COM-COMU-2)

| Fonction | Seul endroit | Route réelle par rôle | Entrée réelle | Capacité lue | Port | Serveur |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Flux, catégories, publication, réponses (COM-M02, COM-W02) | `lib/features/com_communaute/communaute_page.dart`, `flux_publications.dart`, `publication_detail.dart`, `composer_publication.dart` | E `/enseignant/communaute`, `/enseignant/communaute/:publicationId` (publication ouverte) | raccourci sur Aujourd'hui (`EntreeCommunaute` dans `journee_page.dart`, réponse du directeur) | `CapacitesCommunaute.peutPublier`, `peutRepondre` (portées par `PortCommunaute`) | `PortCommunaute` | COM-BR-05 |
| Garde anti-promotion (`CommunityPromotionGuard`) et états de lien | `lib/features/com_communaute/garde_promotion.dart`, `etat_lien.dart`, `port_garde_promotion.dart` | idem | composer de publication et composer de réponse (`reponses.dart`, COM-RC R-01) ; une panne du garde retient le contenu et propose « Réessayer » (R-17) | aucune | `PortGardePromotion.verifier`, `verifierReponse` | COM-BR-07 |
| Signalement | `lib/features/com_communaute/feuille_signalement_communaute.dart` | idem | menu d'une publication ou d'une réponse | `CapacitesModeration.peutSignaler` | `PortModeration.signaler` (clé d'idempotence, `ResultatSignalement.dejaSignale`) et `mesSignalements` (socle, COM-RC R-18) | COM-BR-06 |

## 4. Le Studio (COM-STU-1, COM-STU-2, COM-STU-3), administration seule

| Fonction | Seul endroit | Route réelle | Entrée réelle | Capacité lue | Port | Serveur |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Aujourd'hui (`StudioTodayBoard`, `ActivityInbox`) | `lib/features/com_studio/aujourdhui_page.dart` | A `/admin/studio` | accès Studio de la coquille admin (`admin_domaine.dart`) | aucune (accès admin, COM-BR-13) | `PortActiviteStudio` | COM-BR-15, COM-BR-13 |
| Canaux, canal, panneau, visibilité, recherche, Enregistrer | `lib/features/com_studio/studio_page.dart` (`EspaceStudio`), `canal_page.dart`, `liste_canaux.dart`, `panneau_partages.dart`, `recherche_studio.dart` | A `/admin/studio?vue=canaux`, `/admin/studio/canaux/:canalId` (`/admin/studio/canaux` redirige vers `?vue=canaux`) | navigation du Studio | `CapaciteCanal.ecrire`, `parametres` (portées par le canal) ; `envoyerVocal` pour le vocal | `PortStudio` | COM-BR-08, COM-BR-02 |
| Éléments enregistrés | `lib/features/com_studio/elements_enregistres_studio.dart` | A `/admin/studio?vue=enregistres` | navigation du Studio | aucune | `PortElementsEnregistres` (socle) | COM-BR-12 |
| Brouillons | `lib/features/com_studio/brouillons_studio.dart` | A `/admin/studio?vue=brouillons` | navigation du Studio | aucune | `PortBrouillons` (socle, mémoire de session) | COM-BR-12 |
| Mode focus (`StudioFocusToggle`, `FocusExitDock`, `MinimalComposer`, `FocusStateRestorer`) | `lib/features/com_studio/focus/` | aucune route (état local restaurable, spec §30 point 9) | « Mode focus » dans l'en-tête du canal | aucune | aucun | aucun |

## 5. Notifications et annonces (COM-ANN-1, COM-ANN-2)

| Fonction | Seul endroit | Route réelle par rôle | Entrée réelle | Capacité lue | Port | Serveur |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Centre de notifications partagé | `lib/features/notifications/notifications_page.dart` | T (élève adulte compris) `/tuteur/notifications` ; E `/enseignant/notifications` ; C `/controleur/notifications` ; A `/admin/notifications` | la cloche de l'en-tête du rôle (`ClocheNotifications`), jamais pour l'élève mineur | aucune | `PortNotifications` (DB-CPT-04, neutre) | COM-BR-09 |
| Annonces de la Classe | `lib/features/com_annonces/annonces_de_classe.dart` | aucune route propre | T : Espace Classe ; E : fiche de Classe ; élève adulte de démonstration : `ma_classe_adulte_page.dart` | aucune | `PortAnnonces` | COM-BR-10 |
| Publier une annonce de Classe (enseignant) | `lib/features/com_annonces/publier_annonce_classe_page.dart` + `publieur_annonce.dart` (publieur unique) | E `/enseignant/groupe/:groupeId/annonce` | lien « Publier une annonce » des annonces de la Classe | `CapaciteAnnonces.publier` portée par la Classe, lue par l'entrée et par la page même ouverte par URL (COM-RC R-20) ; `CapaciteCommunication.programmer` | `PortAnnonces.annoncesDeClasse`, `ciblesPublication`, `publier` | COM-BR-10 |
| Administration des communications, onglet Annonces (indicateurs, publiées, planifiées, matrice) | `lib/features/com_annonces/administration_communications_page.dart`, `annonces_planifiees.dart`, `matrice_audience.dart`, `publieur_annonce.dart` | A `/admin/operations/communications/annonces` (la racine `/admin/operations/communications` y redirige) | tableau de bord, ligne Communications ; domaine Opérations, aucun 9e domaine | `publierAnnonce`, `programmer` | `PortAnnonces`, `PortReglesAudience` | COM-BR-10, COM-BR-11 |
| Onglet Modération (file, masquer, restaurer, rejeter, approuver) | `lib/features/com_annonces/file_moderation.dart` | A `/admin/operations/communications/moderation` | onglet Modération | `CapacitesModeration` (source unique, `voitLaFile`, `peut(action)`) | `PortModeration` (socle) | COM-BR-06 |

## 6. Socle (COM-F, COM-F-b, compléments COM-FUS)

| Fonction | Seul endroit | Capacité | Port | Serveur |
| :--- | :--- | :--- | :--- | :--- |
| Fil et composer texte (envoi honnête, identifiant local de bulle à l'envoi, complément de bulle, saisie empilée à texte agrandi) | `lib/core/widgets/fil_discussion.dart` | portée par l'écran | appelant | COM-BR-02 |
| Capacités Communications | `lib/core/communications/capacites_communication.dart` (quatre capacités : `publierAnnonce`, `programmer`, `ecrireDansFil`, `envoyerVocal` ; `moderer` et `parametresCanal`, lues nulle part, retirées à COM-RC R-21 : la modération lit `CapacitesModeration`, le canal `CapaciteCanal.parametres`) | source unique | `PortCapacitesCommunications` (neutre) | COM-BR-16 |
| Pièces jointes (carte, politique) | `lib/core/widgets/carte_piece_jointe.dart`, `lib/core/communications/port_pieces_jointes.dart` | aucune | `PortPolitiquePiecesJointes` | COM-BR-04 (aucun envoi ni ouverture rendus) |
| Modération et signalement | `lib/core/communications/moderation.dart` | `CapacitesModeration` | `PortModeration` | COM-BR-06 |
| Brouillons, éléments enregistrés | `lib/core/communications/port_brouillons.dart`, `port_elements_enregistres.dart` | aucune | mémoire de session | COM-BR-12 |
| Badge non lu, états de communication, espace adaptatif, bandeau hors ligne | `lib/core/widgets/badge_non_lu.dart`, `vue_etat_communication.dart`, `espace_travail_adaptatif.dart` | aucune | aucun | aucun |
| Démonstration de toutes les voies | `lib/features/demo/communications/` | ouvertes par surcharge, hors production | doubles | aucun |

Correction COM-RC (revue COM-R, R-21, 5 octobre 2026) : capacités mortes retirées, route de la
publication ouverte ajoutée, garde des réponses et signalement idempotent reportés.

## 7. Ce que la carte ne couvre pas encore

- Pièce jointe : ni envoi ni ouverture (aucun contrat COM-BR-04, aucun jeton éphémère).
- Réactions secondaires du Studio (COM-BR-08 `reagir`) : non rendues.
- Compteur de non-lus des cloches enseignant, contrôleur, administration : aucune source (COM-BR-09).
- Annonce sur l'accueil quand son niveau le justifie (§13.3, « éventuellement ») : non faite.
- `/tc/groupes` et la démonstration des groupes restent à rebrancher sur les vraies données (hors COM).
