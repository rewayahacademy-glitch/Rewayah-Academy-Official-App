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
