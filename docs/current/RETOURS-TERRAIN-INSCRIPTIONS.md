# Retours du terrain : les problèmes rencontrés pendant les inscriptions

Demande du directeur (14/11/2026) : « consigner tous les problèmes qu'on rencontre
maintenant sur le recrutement dans un document accessible et visible pour tout le
monde, pour s'en servir pour améliorer les inscriptions des élèves […] comme ça on
ne sera pas obligé de refaire des diagnostics similaires ».

**Ce document sert à deux choses :**
1. Ne pas refaire un diagnostic déjà fait. Avant d'enquêter sur un problème
   d'inscription (candidat, élève, parent), cherche-le ici.
2. Préparer l'inscription des élèves. La colonne « Pour les élèves » dit ce qu'il
   faut prévoir dès maintenant, avant que la même chose arrive aux familles.

**Règle pour tout agent (consigne 20)** : chaque problème rencontré par une vraie
personne pendant une inscription s'ajoute ici, dans la PR qui le corrige, ou dans
une PR à lui seul s'il n'est pas encore corrigé. On écrit les faits : ce qui a été
vu, la cause prouvée et le nombre de personnes touchées, lus en production. On
n'écrit jamais de nom, d'adresse ni de donnée personnelle : seulement des nombres.

## Leçons qui valent pour toute inscription

- **L1. Ce qui reste à faire reste à portée, à toute étape.** Après un envoi, la
  personne doit encore trouver, depuis sa page d'accueil, tout ce qui lui manque
  (signature, pièce, réponse). Les problèmes R2 et R3 viennent de liens qui
  disparaissaient après l'envoi.
- **L2. Compléter n'est pas modifier.** Signer ou déposer une pièce après l'envoi
  ne gêne pas l'examen du dossier. Seules les réponses déjà envoyées restent
  figées. Aucun bouton « fermer les modifications » n'est nécessaire.
- **L3. La direction ne quitte pas un dossier pour un geste simple.** Écrire,
  répondre ou demander une pièce se fait dans le dossier, sans en sortir (R1).
- **L4. Vérifier en production avant d'affirmer.** Plusieurs fausses pistes
  venaient d'affirmations non vérifiées (R6, R8).
- **L5. Prévoir le volume avant d'envoyer en masse.** Courriels, tâches
  planifiées, disque : une vague d'inscriptions sature d'abord ce qu'on n'a pas
  mesuré (R4, R5).

## Registre

| # | Date | Ce qui a été vu | Cause prouvée | Personnes touchées | Correctif | Pour les élèves |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| R1 | 14/11 | La direction devait sortir du dossier d'un candidat pour lui écrire, puis faire jusqu'à 10 gestes pour y revenir. | La conversation s'ouvrait sur une autre page. | La direction, sur chaque dossier | PR #485 : la conversation se déplie dans le dossier ; la sortie de la salle d'entretien ramène au dossier (#489). | Le dossier d'un foyer ou d'un élève garde la conversation dépliable sur place. |
| R2 | 14/11 | Des candidats ne trouvaient plus où déposer leur pièce d'identité après l'envoi. | Le serveur suspendait le dépôt en examen, et le portail retirait le lien. | 27 candidats | PR #485 et migration `20261126300000_piece_salle1_apres_envoi` (installée). | Le parent garde le lien de dépôt de pièce après l'envoi de l'inscription. |
| R3 | 14/11 | Un candidat avait envoyé sans signer le contrat ni l'accusé, et ne trouvait plus où signer. | Le serveur accepte la signature à toute étape, mais le portail ne proposait plus que la pièce après l'envoi. En attendant le correctif : se connecter, puis ouvrir `/attente/accords`. | 37 candidatures envoyées sans contrat signé | PR #491 : « Lire et accepter » avant la pièce, après l'envoi. | Les accords du parent (contrat, publication, sorties) restent signables après l'envoi ; on vérifie que `/attente` les propose. |
| R4 | 14/11 | Les invitations aux candidats partaient trop lentement. | Le plafond de 300 courriels non essentiels par 24 h était une précaution, pas une limite de Google (environ 2000 par jour). | Les lots d'invitation en attente | PR #490 : 900 par jour, 40 par heure au plus, étalés sur la journée (réglages `courriels.non_essentiels_par_*`). | Avant une campagne d'inscription, calculer le nombre de courriels et régler le plafond à l'avance. |
| R5 | 14/11 | Alerte Supabase « Disk IO Budget » sur la production. | Sept tâches pg_cron par minute écrivaient chacune 5 lignes de journal à chaque passage. | Toute la plateforme | PR #488 : une seule tâche `tache-minute` (installée, vérifiée). | Toute nouvelle tâche planifiée passe par `tache-minute`, jamais une tâche de plus par minute. |
| R6 | 14/11 | Le directeur, seul super-admin, se croyait bloqué pour voir les pièces des candidates. | L'exception super-admin était déjà active ; l'affirmation contraire n'avait pas été vérifiée. | Le directeur | Aucun code ; vérification en production. | Le super-admin voit les deux côtés ; vérifier `kyc_super_admin_exception_active()` avant de conclure à un blocage. |
| R7 | 14/11 | La carte à partager montrerait le lien de l'app au lieu de celui du site. | Non confirmé : l'affiche et son QR pointent déjà vers le site. Capture d'écran demandée au directeur. | À confirmer | En attente. | Toute carte publique pointe vers le site, jamais vers l'app. |
| R8 | 14/11 | La refonte du panneau latéral passait pour jamais déployée. | Elle l'était (#413, #415) ; seule la partie en attente de décision manquait. | La direction | PR #487 (sous-liens). | Avant de dire « jamais déployé », lire l'historique des fusions. |
| R9 | 14/11 | Des comptes existent sans profil. | Inscription interrompue avant la création du profil. | 8 comptes | À faire : liste « comptes incomplets » pour la direction. | Prévoir dès le départ une liste des inscriptions interrompues, avec une relance. |
| R10 | 14/11 | Le lien de connexion par courriel n'arrive pas dans la langue de la personne. | Un seul modèle de courriel dans Supabase Auth. | Les candidats arabophones et anglophones | À faire : un modèle par langue (fr, ar, en). | Les parents reçoivent ce lien dans leur langue. |
| R11 | 14/11 | Audit complet du portail candidat (122 cases obligation × état) : une pièce refusée en salle 1 s'affichait « Fait » et aucun dépôt n'était proposé. | `pieceADeposer` ne comptait que l'absence de pièce, pas le refus ; le serveur accepte pourtant un nouveau dépôt. | 0 aujourd'hui (aucune pièce refusée) | PR AUDIT-PORTAIL-CANDIDAT : « Déposer ma pièce » et « Élément à reprendre » en salle 1. | Le parent dont la pièce est refusée voit la raison et le bouton de dépôt, à toute étape. |
| R12 | 14/11 | Même audit : en salle 2, une nouvelle version du cadre religieux à accepter n'avait aucun chemin. | Le portail de la salle 2 ne connaissait que les accords et la pièce ; le serveur demande pourtant le cadre neuf (`aCompleter`). | 0 aujourd'hui | PR AUDIT-PORTAIL-CANDIDAT : « Lire et accepter » mène au cadre en salle 2. | Toute nouvelle version d'un texte à accepter se propose depuis la page d'accueil du parent, à toute étape. |
| R13 | 14/11 | Même audit : une nouvelle version du contrat ou de l'avis aurait été affichée « Fait » au candidat, puis refusée en salle 3 sans chemin pour signer. | `etat_dossier` acceptait toute version ; la salle 3 exige la version courante (et l'empreinte du contrat). Deux règles pour la même chose. | 0 aujourd'hui (trou latent) | Migration `20261126700000_audit_portail_candidat` (à coller) : `etat_dossier` lit la règle de la salle 3 pour l'enseignant. | Une seule règle par obligation, lue au même endroit par le portail et par le contrôle de passage. |
| R14 | 14/11 | Même audit : le dossier d'un candidat ne disait pas à la direction ce qui manque (contrat, avis, code de conduite, pièce) ; il affichait « Disponible au branchement serveur ». | `lire_candidature` rendait `controles` à nul. | La direction, sur 74 dossiers en cours (dont 36 envoyés sans contrat) | Même migration : contrôles du dossier et causes nommées. | Le dossier d'un foyer dit dès le départ ce qui manque, en mots, sans ouvrir une autre page. |
| R15 | 14/11 | La feuille « Demander un complément » d'un candidat en salle 1 ne proposait que les cartes du questionnaire et le cadre : impossible de redemander la pièce, le contrat, l'avis, le code de conduite, la photo ou l'accord de publication. | La liste du serveur (`private.candidature_complement_codes('prequalification', …)`) s'arrêtait au cadre ; la salle 1 reçoit pourtant tout depuis SALLE-1-TOUT-ICI. | La direction, sur chaque dossier de salle 1 (71 candidatures en salle 1 le 14/11) | Lot COMPLEMENT-ET-FORMATS : migration `20261126800000` (six codes de plus, salle 1 seulement) ; feuille en deux groupes « Réponses » puis « Documents et accords », une colonne ; le portail mène à chaque élément demandé (la pièce redemandée redevient « À déposer » tant qu'aucune pièce n'a été déposée depuis la demande). | La direction peut redemander au parent tout ce qu'il a fourni (pièce, accords, photo de l'élève), et le portail du parent mène à chaque élément demandé. |
| R16 | 14/11 | Des pièces s'affichaient « Ce format de pièce ne peut pas être affiché. » dans le dossier de la direction, des jours après l'envoi. | Le dépôt acceptait HEIC (iPhone) et PDF, que la visionneuse n'affiche pas sur ordinateur (elle n'affiche que JPEG, PNG, WebP). Lu en production : seau `kyc` 49 JPEG, 5 PNG, 3 PDF, 1 HEIC ; seau `photos_enseignants` 66 JPEG, 4 PNG, 1 HEIC. | 4 pièces (3 PDF, 1 HEIC) et 1 photo HEIC, toutes déposées le 14/11 par des candidats encore en salle 1 (3 en examen, 2 en versement pas encore possible ; lu en production par le pilote le 15/11). Réglage lu le même jour : `kyc` acceptait JPEG, PNG, HEIC, WebP, PDF (8 Mo) ; `photos_enseignants` et `avatars` acceptaient tout, sans limite. Aucun fichier au-dessus des nouvelles tailles. | Lot COMPLEMENT-ET-FORMATS : au dépôt, pièce en JPEG ou PNG (8 Mo), photo en JPEG, PNG ou WebP (4 Mo) ; une photo HEIC est convertie en JPEG sur l'appareil ; tout autre format est refusé tout de suite avec la phrase qui dit quoi faire ; la même liste et la même taille sur les seaux (migration `20261126800000`) ; les fichiers déjà déposés disent « Format non lisible » avec « Demander une nouvelle pièce » (ou photo) en un geste. | Pièces et photos des parents et des élèves : mêmes formats, même conversion (même code, `lib/core/fichiers/`), même limite serveur ; à faire : poser la même liste sur le seau `avatars` (photos des parents et des élèves ; aujourd'hui 3 JPEG, 3 WebP, 11 PNG, rien d'illisible, mais aucun type ni taille imposés) avant l'ouverture des inscriptions des élèves. |
| R17 | 14/11 | Sur ordinateur, la feuille « Demander un complément » était un écran de téléphone étiré : une colonne au milieu, de grandes cartes pour de simples cases, deux boutons pleine largeur. | Au-delà de 840 points, `AppBottomSheet` ouvrait une boîte centrée de 560 points, qui devenait la fenêtre entière quand le contenu débordait. Les choix restaient des cartes de téléphone. | La direction, sur chaque geste d'un dossier | Lot COMPLEMENT-ET-FORMATS : à partir de 840 points, un panneau latéral ancré à côté du dossier, avec les choix en lignes compactes et les boutons en ligne au bord de fin, à la largeur de leur contenu. Fait dans le composant partagé (`FormeModale.panneau`), pour tous les gestes. | Tout écran de la direction ou des parents qui s'ouvre sur ordinateur (fiche d'un foyer, inscription d'un élève) prend la forme d'ordinateur, jamais une colonne de téléphone étirée ; à vérifier à 1440 avant chaque livraison. |
