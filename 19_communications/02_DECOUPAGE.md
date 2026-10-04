# Communications V1 : découpage

Étapes du tableau YAADEN, ordre 1300 à 1353, plus COM-Q (ATTEND, 2015). COM-0 précise les fichiers touchés par chaque étape, pour que les voies parallèles ne se croisent pas.

```
COM-0 ─► COM-F ─┬─► COM-MSG-1 ─► COM-MSG-2 ───────────────┐
                ├─► COM-VOC-1 ───────────────────────────┤
                ├─► COM-COMU-1 ─► COM-COMU-2 ──┐         ├─► COM-FUS ─► COM-CAPT ─► COM-R ─► COM-RC
                ├─► COM-STU-1 ─► COM-STU-2 ─► COM-STU-3 ─┤
                └─► COM-ANN-1 ─────────────────┴► COM-ANN-2┘
COM-0 ─► COM-Q (directeur, seulement si COM-0 trouve un point bloquant)
```

| Ordre | Étape | Voie | Dépend de | Modèle | Titre |
|---|---|---|---|---|---|
| 1300 | COM-0 | COM | — | Opus, 35 min, lecture seule | Préparation Communications V1 : inventaire L0 du dépôt, UX_REVIEW_COMMUNICATIONS_L0, COM-BR, questions |
| 1301 | COM-F | COM | COM-0 | Opus, 35 min | Socle Communications (L1) : branche ui/communications-v1, modèles UI, badge non lu, composer texte, pièces jointes, états, ResponsiveWorkspaceShell |
| 1310 | COM-MSG-1 | COM-MSG | COM-F | Opus, 35 min | Messages métier : liste des fils, fil contextuel, ContextThreadHeader, ThreadContextPanel (COM-M01, COM-W01) |
| 1311 | COM-MSG-2 | COM-MSG | COM-MSG-1 | Opus, 30 min | Messages métier : entrées réelles par rôle (Classes enseignant, cloche, Espace Classe tuteur, admin, mission contrôleur) |
| 1315 | COM-VOC-1 | COM-VOC | COM-F | Opus, 35 min | VoiceMessageComposer : 17 états, limite 3:00, pré-écoute, permission micro (sans serveur) |
| 1320 | COM-COMU-1 | COM-COMU | COM-F | Opus, 35 min | Communauté enseignants : flux, catégories, publication, réponses, Enregistrer, Signaler (COM-M02, COM-W02) |
| 1321 | COM-COMU-2 | COM-COMU | COM-COMU-1 | Opus, 35 min | CommunityPromotionGuard : politique anti-promotion, états bloqué et averti, 4 états de lien, motifs de signalement |
| 1330 | COM-STU-1 | COM-STU | COM-F | Opus, 35 min | Le Studio, canal : liste des canaux, visibilité, fil, panneau Fichiers/Épinglés/Membres, recherche, Enregistrer (COM-M03, COM-W03) |
| 1331 | COM-STU-2 | COM-STU | COM-STU-1 | Opus, 35 min | Le Studio, Aujourd'hui : StudioTodayBoard, ActivityInbox, brouillons (COM-W00, COM-M04) |
| 1332 | COM-STU-3 | COM-STU | COM-STU-2 | Opus, 35 min | Le Studio, Mode focus : état local de COM-W03, sortie Échap, restauration complète (COM-W03F, COM-M05) |
| 1340 | COM-ANN-1 | COM-ANN | COM-F | Opus, 35 min | NotificationCenter partagé et annonces de Classe : filtres, niveaux, ClassAnnouncementCard, détail (COM-M06) |
| 1341 | COM-ANN-2 | COM-ANN | COM-ANN-1, COM-COMU-2 | Opus, 35 min | Administration des communications (COM-W04) : AnnouncementPublisher, annonces planifiées, AudienceRulesMatrix, ModerationQueue |
| 1350 | COM-FUS | COM | COM-MSG-2, COM-VOC-1, COM-COMU-2, COM-STU-3, COM-ANN-2 | Opus, 35 min | Fusion Communications : 5 sous-branches dans ui/communications-v1, vocal branché dans Messages et Studio, suite complète |
| 1351 | COM-CAPT | COM | COM-FUS | Sonnet, 35 min | Captures Communications : chaque écran COM-* en 390, 768 et 1440, clair et sombre, avec les états clés |
| 1352 | COM-R | VERIF | COM-CAPT | Opus, 35 min, session qui n'a écrit aucun code COM | Revue croisée Communications V1 (L6) : produit, UX/UI, sécurité communautaire, accessibilité, architecture |
| 1353 | COM-RC | COM | COM-R | Opus, 35 min | Corrections de la revue Communications |
| 2015 | COM-Q | ATTEND | COM-0 | directeur | Questions du directeur sur Communications V1 (après COM-0) |

## Détail

### COM-0 — Préparation Communications V1 : inventaire L0 du dépôt, UX_REVIEW_COMMUNICATIONS_L0, COM-BR, questions

Spec §29 L0, aucune ligne de code. Lire 19_communications/00_REPRISE.md puis la spec V/ et les 6 maquettes. Inventaire sur origin/corrections/revue-directeur-2026-10 : routes, shells par rôle (tuteur, élève adulte, enseignant, admin, contrôleur), NotificationsPage existante, fil Contrôleur (CTRL-MSG-1), composants chat/composer, ports et démo, tokens, composants partagés (fichier:ligne). Matrice Garder / Améliorer / Ajouter / Supprimer sur validation. Pour chaque écran COM-*, dire l'entrée réelle (bouton, route) et le shell réel du rôle. Établir qui est « équipe interne » dans les rôles existants (Le Studio). Fait : 19_communications/UX_REVIEW_COMMUNICATIONS_L0.md, COM-BR.md (contrats serveur §34), QUESTIONS.md (seulement ce qui bloque, avec recommandation), 02_DECOUPAGE.md précisé (fichiers par étape, pour qu'aucune voie parallèle ne touche les mêmes fichiers).

### COM-F — Socle Communications (L1) : branche ui/communications-v1, modèles UI, badge non lu, composer texte, pièces jointes, états, ResponsiveWorkspaceShell

Spec §19, §20, §12, §25. Créer ui/communications-v1 + worktree D:\RA_TUTEUR\com depuis origin/corrections/revue-directeur-2026-10 (le plus récent), puis les 5 sous-branches ui/com-msg, ui/com-voc, ui/com-commu, ui/com-stu, ui/com-ann depuis le commit du socle (poussées, sans worktree). Livrer : modèles UI neutres, UnreadUrgencyBadge (texte + icône, jamais la couleur seule), composer texte avec un emplacement pour le vocal, AttachmentPolicyPort + carte pièce jointe (jamais d'URL R2 brute), états chargement/vide/erreur/hors ligne/indisponible en réutilisant l'existant, ResponsiveWorkspaceShell (1, 2 ou 3 panneaux, panneau droit fermable, aucune colonne vide). Ports neutres, démo hors production. Clés i18n du lexique §22. Tests widgets. Fait : sous-branches poussées, analyze 0, tests verts.

### COM-MSG-1 — Messages métier : liste des fils, fil contextuel, ContextThreadHeader, ThreadContextPanel (COM-M01, COM-W01)

Branche ui/com-msg, worktree D:\RA_TUTEUR\com-msg. Spec §3, §16 COM-M01, §17 COM-W01, §23. Paires autorisées §3.2 seulement ; pas de bouton global Nouveau message, ni annuaire, ni coordonnée. Ordinateur : Navigation | Conversations | Fil | Contexte. Mobile : une surface à la fois, composer fixe, clavier logiciel. Fixtures §26 (parent/enseignant, admin/famille, contrôleur/admin, échec d'envoi, hors ligne). Réutiliser le fil Contrôleur s'il existe (UX_REVIEW L0). Tests R-COM-01, 02, 13, 15.

### COM-MSG-2 — Messages métier : entrées réelles par rôle (Classes enseignant, cloche, Espace Classe tuteur, admin, mission contrôleur)

Spec §21. Aucune 5e destination ajoutée au shell tuteur sans décision. Chaque entrée est prouvée par un test qui tape le vrai bouton depuis la vraie coquille (K-07). États propres §25 (fil inaccessible, objet lié inaccessible, pièce indisponible).

### COM-VOC-1 — VoiceMessageComposer : 17 états, limite 3:00, pré-écoute, permission micro (sans serveur)

Branche ui/com-voc, worktree D:\RA_TUTEUR\com-voc. Spec §11, §24. Jamais d'envoi automatique à l'arrêt. Le port d'enregistrement est neutre, avec un faux enregistreur en démo et une horloge fixe dans les tests. Semantics Pause, Reprendre, Supprimer, Envoyer ; la waveform n'est pas nécessaire pour comprendre. Le composant se branche dans l'emplacement du composer de COM-F. Tests R-COM-03, 04.

### COM-COMU-1 — Communauté enseignants : flux, catégories, publication, réponses, Enregistrer, Signaler (COM-M02, COM-W02)

Branche ui/com-commu, worktree D:\RA_TUTEUR\com-commu. Spec §4, §16 COM-M02, §17 COM-W02, §18. Shell Enseignant réel, jamais Foyer. Ordinateur : Navigation | Flux | Publication/Réponses | Aide/Règles. Un seul composer (PostComposerEntry) sans prix, boutique ou Promouvoir. Aucun bouton Message privé (R-COM-07). Pas de compteur d'abonnés ni de classement (§32). 6 publications en fixtures.

### COM-COMU-2 — CommunityPromotionGuard : politique anti-promotion, états bloqué et averti, 4 états de lien, motifs de signalement

Spec §5, textes exacts §5.2 et §22. Le garde se nourrit de fixtures et d'un port ; aucun moteur artisanal de détection, et jamais « Vérifié » côté client. 8 motifs §5.5. Fixtures : 2 publications bloquées, 1 lien affilié, 1 vente. Tests R-COM-05, 06. Les contrats serveur vont dans COM-BR.md.

### COM-STU-1 — Le Studio, canal : liste des canaux, visibilité, fil, panneau Fichiers/Épinglés/Membres, recherche, Enregistrer (COM-M03, COM-W03)

Branche ui/com-stu, worktree D:\RA_TUTEUR\com-stu. Spec §6, §9, §8.3, §18. Shell de l'équipe interne (L0), jamais Tuteur. Un canal non autorisé n'est pas rendu (R-COM-08), sans cadenas. Taxonomie §9.1 en démo, 5 canaux, 1 privé absent, 1 restreint autorisé. Maquette sombre : structure seulement, sans Tâches, sans visio, sans Nouvel espace. Ordinateur : Navigation | Canaux | Fil | Contexte.

### COM-STU-2 — Le Studio, Aujourd'hui : StudioTodayBoard, ActivityInbox, brouillons (COM-W00, COM-M04)

Spec §7, §8.1, §8.2. 7 blocs. Règle anti-doublon : chaque ligne ouvre son module canonique (Finance, Planning, dossier, Classe, Admissions), R-COM-11. DraftPersistence en mémoire de session seulement, sauf couche locale déjà approuvée. Pas de maquette COM-W00/M04 dans le dossier : composition d'après le texte de la spec et la navigation de la maquette sombre. États avec activité et vide.

### COM-STU-3 — Le Studio, Mode focus : état local de COM-W03, sortie Échap, restauration complète (COM-W03F, COM-M05)

Spec §10, §20 FocusStateRestorer. Liste exacte de ce qui disparaît et de ce qui reste (§10.3, §10.4). Ce n'est pas une nouvelle route ni le plein écran du navigateur. Échap seulement sans dialogue prioritaire. Le focus clavier n'est jamais piégé, et avec la réduction de mouvement la transition est directe. Tests R-COM-09, 10 : scroll, canal, brouillon et panneaux restaurés, aucune perte de texte.

### COM-ANN-1 — NotificationCenter partagé et annonces de Classe : filtres, niveaux, ClassAnnouncementCard, détail (COM-M06)

Branche ui/com-ann, worktree D:\RA_TUTEUR\com-ann. Spec §13, §18. Faire évoluer la NotificationsPage existante, sans créer un second centre. Filtres : Toutes, Non lues, Mentions, Action requise. 4 niveaux, chacun dit par du texte. Catalogue par rôle §13.2 en démo. La cloche des shells ouvre le centre ; l'annonce ouvre sa Classe (R-COM-12). Ordinateur : liste + détail dans le shell du rôle.

### COM-ANN-2 — Administration des communications (COM-W04) : AnnouncementPublisher, annonces planifiées, AudienceRulesMatrix, ModerationQueue

Shell Admin réel. Spec §13.4, §17 COM-W04, §20 AnnouncementPublisher (5 étapes, une seule action pleine) et §5.5. Rien n'est « Publiée » sans confirmation du contrat réel. Matrice sur capabilities prouvées ou fixtures marquées démo, sans ligne inventée depuis l'image. Les 4 indicateurs du haut viennent seulement de données réelles ou de démo marquée. L'enseignant publie seulement vers sa Classe. Réutiliser les motifs de COM-COMU-2.

### COM-FUS — Fusion Communications : 5 sous-branches dans ui/communications-v1, vocal branché dans Messages et Studio, suite complète

K-14 : une seule session, merge --no-ff, union i18n + slang, jamais main. Brancher VoiceMessageComposer dans les composers Messages et Studio. analyze 0. Suite complète par dossiers sous flutter-verrou, avec tous les dossiers cités. Carte des fonctions finale avec routes réelles (spec §30.13) dans 19_communications/CARTE_FONCTIONS.md.

### COM-CAPT — Captures Communications : chaque écran COM-* en 390, 768 et 1440, clair et sombre, avec les états clés

Spec §27. Captures dans 19_communications/captures/, comparées à la maquette sur la composition seulement : on ne relève pas les écarts de couleur, de police ou de rayon, puisque le thème Rewayah prime. On contrôle le rôle affiché, la navigation, les textes, les cartes groupées, le texte ×2 et les 320 px (K-61). Focus, hors ligne, anti-promotion, vide.

### COM-R — Revue croisée Communications V1 (L6) : produit, UX/UI, sécurité communautaire, accessibilité, architecture

Spec §29 L6 et §33. Une fonction a un seul endroit, aucun chat libre, aucun DM communautaire, aucune permission inventée, zéro backend. Shells corrects. Thème Rewayah respecté : aucune couleur, police ou rayon venus des maquettes. Clavier, lecteur d'écran, texte ×2. Fait : 05_recette/COM/REVUE_COM-R.md.

### COM-RC — Corrections de la revue Communications

Corriger chaque point de REVUE_COM-R.md, puis relancer toute la suite et citer le dernier passage (K-29). Captures refaites pour les écrans touchés.

### COM-Q — Questions du directeur sur Communications V1 (après COM-0)

Seulement ce que COM-0 trouve bloquant, avec une recommandation pour chaque point (K-53). Pressentis : 1) où entre Le Studio et qui y a droit parmi les rôles existants ; 2) la Communauté devient-elle une destination du shell Enseignant ou reste-t-elle un raccourci ; 3) les maquettes absentes (planche B mobile, COM-W00, COM-W03F), qui ne bloquent pas. Une réponse donnée est définitive.

## Règle de style (toutes étapes)

STYLE (directeur 04/10) : maquette = composition seulement (zones, proportions, densité, place des actions) ; thème Rewayah en vigueur, aucune couleur, police, rayon, ombre ou pastille colorée venue de la maquette (K-37) ; shell réel du rôle, jamais « Tuteur/Foyer » des images. Sources : 19_communications/00_REPRISE.md.
