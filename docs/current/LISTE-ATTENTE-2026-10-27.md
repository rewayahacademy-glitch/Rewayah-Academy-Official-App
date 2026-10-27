# Liste d'attente (depuis le 27/10/2026)

Règle du pilote, acceptée par le directeur le 27/10 : une seule file de travail
(PR 62, puis fiche « Fraîcheur et notifications », puis fiche 0 par sections, puis
fiche 2, puis parcours par rôle). Toute idée nouvelle est notée ici avec sa date,
sans réponse longue, sans worker, sans fiche, et reprise à son tour. « Urgent » dit
par le directeur fait passer une ligne devant, après qu'on a dit ce qu'elle retarde.

| Date | Idée | Ce qui existe déjà | Où elle ira |
| :--- | :--- | :--- | :--- |
| 27/10 | Avis de l'élève après une séance, très simple, pas à chaque séance | Codé et testé dans le lot Teaching Core H : table `session_feedback` (migration 32 : trois réponses « difficile / bien / très bien », un vote par séance, auteur jamais nommé), carte `features/tc_flux_academique/carte_feedback_seance.dart`, rotation des questions `core/tc_parcours/rotation_feedback.dart`. Non branché depuis `main` ; 0 ligne en production | Parcours de l'élève, après la salle |
| 27/10 | Notification sur l'appareil (push) : classe, séance, absence | Rien (aucune dépendance push) | Après la fiche « Fraîcheur et notifications » |
| 27/10 | Poids du démarrage (15 Mo de code, 7 Mo de moteur de rendu, base locale) | Service worker désactivé volontairement ; aucune mesure réelle | Mesure sur téléphone et iPad d'abord, décision chiffrée ensuite |
| 27/10 | Tiroir du téléphone sous un bandeau d'échec ou alerte caméra cumulée (limite C12) | Test du bandeau « réseau faible » seulement | Fiche 1, lot suivant |
| 27/10 | Feuille des élèves : chaque élève en double (fiche 1, ligne 10) | Donnée partagée avec l'ordinateur | Fiche 1, lot suivant |
| 27/10 | « Disponibilité » toujours dans la navigation de l'enseignant | Écran présent, utilité ponctuelle | Parcours de l'enseignant |
| 27/10 | Porte d'entrée fermée aux non-invités : l'écran de connexion accepte tout compte Google ou tout e-mail, et l'écran d'inscription (RPC `inscrire_titulaire`) fait de n'importe qui un tuteur sans invitation. Constaté en production le 27/10 : quatre candidats enseignants (e-mail d'attente du 26/10) ont créé des comptes, deux sont devenus tuteurs. Parade immédiate : interrupteur « nouvelles inscriptions » de Supabase, coupé par le directeur | Tables `invitations_foyer` et `invitations_enseignant` existent ; aucune n'est exigée à l'inscription | Petit lot à part (une migration, un test de scénario), juste après le lot 2 |
