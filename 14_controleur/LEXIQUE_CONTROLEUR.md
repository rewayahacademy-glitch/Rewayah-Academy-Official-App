# Lexique du rôle Contrôleur (CT-10)

**But.** Présenter en une seule fois tous les textes que voit le Contrôleur, écran par écran, pour que le directeur les valide d'un coup (décision D4 : un lexique unique par rôle). Aucun texte n'a été modifié : ce document relève seulement.

**Date.** 02/10/2026. **Branche.** `ui/controleur-v1` @ 13bc9c4.

**Comment répondre.** Pour chaque texte, écrire « garder » ou « changer en … » (le nouveau texte entre guillemets). Un texte « Document 08 » ou « Décision du directeur » vient déjà de vous : il n'y a rien à valider, sauf si vous voulez le changer. Les textes « Proposé par un agent » sont ceux à valider (liste numérotée P1, P2… en fin de document). Les textes marqués « déjà en place avant ce lot » (E1, E2…) existaient avant le travail sur le Contrôleur et sont partagés avec d'autres rôles : à regarder, sans urgence.

**Comment lire les tableaux.** Les valeurs variables sont remplacées par un exemple : « {n} » devient « 3 », « {classe} » devient « Classe Al-Fatiha », « {date} » devient « 12/10/2026 », « {heure} » devient « 14:30 ». « Document 08 » désigne `08_CONTROLEUR_V1_UX_SECURITE.md` (avec le paragraphe). Aucun texte du fichier `00_DECISIONS_DIRECTEUR.md` (27/09/2026) n'est un libellé : il donne des règles (C1 : la visite n'a lieu que pendant la séance en direct ; C2 : le rapport part automatiquement, le bouton sert seulement à discuter avec l'administration). Les textes qui en découlent ont une formulation proposée par un agent.

**Chiffres.** 219 lignes de texte : 81 issues du Document 08, 112 proposées par un agent pour ce lot, 26 déjà en place avant ce lot. Parmi les proposés, 17 appartiennent à la page de démonstration (hors production).

---

## 1. Navigation

La barre a quatre destinations, dans cet ordre (Document 08 §4.1). Le composant `FilDiscussion` (fil de messages) n'a aucun texte à lui : ses textes viennent de l'écran Échanges (section 7).

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Contrôle » | Barre de navigation, 1re destination (aussi libellé de l'espace dans Compte > Espaces) | Document 08 §4.1 | `nav.controleur.controle` |
| « Historique » | Barre de navigation, 2e destination | Document 08 §4.1 | `nav.controleur.historique` |
| « Échanges » | Barre de navigation, 3e destination | Document 08 §4.1 | `nav.controleur.echanges` |
| « Compte » | Barre de navigation, 4e destination | Document 08 §4.1 | `nav.controleur.compte` |
| « Planning » | Non affiché dans la barre actuelle (reste dans le fichier de textes ; le document 08 §3.2 exclut le planning manuel) | Proposé par un agent (P1) | `nav.controleur.planning` |



## 2. Contrôle (CTR-01)

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Contrôle » | Titre de l'écran Contrôle | Document 08 §7, CTR-01 | `controleur.controle.titre` |
| « Votre prochaine mission » | Titre de la carte de mission | Document 08 §7, CTR-01 | `controleur.controle.mission` |
| « Commencer le contrôle » | Bouton principal de la carte de mission, quand la séance est en direct | Document 08 §6, P-CTR-02 et §7, CTR-01 | `controleur.controle.commencer` |
| « Aucun contrôle n'est à réaliser pour le moment. » | Écran sans mission | Document 08 §7, CTR-01 (textes proposés) | `controleur.controle.vide` |
| « Rewayah vous proposera une mission lorsqu'une séance compatible sera disponible. » | Sous le texte « sans mission » | Document 08 §7, CTR-01 (textes proposés) | `controleur.controle.videAide` |
| « Cette mission n'est plus disponible. » | Carte de mission quand la séance est annulée, la salle fermée ou l'accès retiré | Document 08 §6, P-CTR-08 | `controleur.controle.indisponible` |
| « Le contrôle s'ouvrira dès que la séance sera en direct. » | Carte de mission, avant que la séance soit en direct (à la place du bouton) | Proposé par un agent (P2) | `controleur.controle.attente` |
| « Visite en mode incognito : votre présence n'est pas annoncée à l'enseignant. » | Carte de mission : rappel que la visite est invisible pour l'enseignant | Proposé par un agent (P3) | `controleur.controle.incognito` |
| « 14:00 à 14:45 » | Carte de mission : horaire prévu | Proposé par un agent (P4) | `controleur.controle.horaire` |
| « 42 min prévues » | Carte de mission : durée prévue | Proposé par un agent (P5) | `controleur.controle.duree` |
| « 3 élève » | Carte de mission : nombre d'élèves (au singulier) | Proposé par un agent (P6) | `controleur.controle.eleves.one` |
| « 3 élèves » | Carte de mission : nombre d'élèves (au pluriel) | Proposé par un agent (P7) | `controleur.controle.eleves.other` |
| « Lecture de votre mission en cours. » | Annonce lue par le lecteur d'écran pendant le chargement | Proposé par un agent (P8) | `controleur.controle.chargement` |
| « Votre mission n'a pas pu être lue. Réessayez dans un instant. » | Écran Contrôle quand la mission ne se charge pas (avec bouton Réessayer) | Proposé par un agent (P9) | `controleur.controle.erreur` |
| « Compte rendu à terminer » | Bloc secondaire de l'écran Contrôle : compte rendu non terminé | Document 08 §7, CTR-01 (point 6) | `controleur.compteRendu.aTerminer` |
| « Reprendre le compte rendu » | Bouton du bloc « à terminer » | Proposé par un agent (P10) | `controleur.compteRendu.reprendre` |
| « Réessayer » | Bouton après l'erreur de chargement (texte commun à toute l'application) | Proposé par un agent, déjà en place avant ce lot (E1) | `commun.reessayer` |



## 3. Salle en rôle Contrôleur (CTR-02)

Les commandes interdites (micro, caméra, main levée, chat, annotation…) ne sont pas affichées du tout : elles n'ont donc aucun texte. Pour la salle, ne sont repris que les textes clairement vus par le Contrôleur ; les autres textes de la salle (partagés avec élève, enseignant, tuteur) ne sont pas relevés ici.

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Contrôle Rewayah » | Zone haute de la salle, visible du seul contrôleur | Document 08 §7, CTR-02 | `salle.visiteControle.titre` |
| « Quitter » | Commande en bout de la zone haute | Document 08 §7, CTR-02 | `salle.quitter` |
| « Son reçu » | Commande de bascule, son activé | Document 08 §7, CTR-02 (« Son reçu ») | `salle.visiteControle.sonRecu` |
| « Agrandir le support » | Commande, support en vue normale | Document 08 §7, CTR-02 | `salle.visiteControle.agrandir` |
| « Son coupé » | Commande de bascule, son coupé | Proposé par un agent (P11) | `salle.visiteControle.sonCoupe` |
| « Couper le son reçu » | Lu par le lecteur d'écran sur la commande son (son activé) | Proposé par un agent (P12) | `salle.visiteControle.couperSon` |
| « Rétablir le son reçu » | Lu par le lecteur d'écran sur la commande son (son coupé) | Proposé par un agent (P13) | `salle.visiteControle.retablirSon` |
| « Réduire le support » | Commande, support agrandi | Proposé par un agent (P14) | `salle.visiteControle.reduire` |
| « Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal. » | Bandeau d'invisibilité en bas de la salle (rôle contrôleur seulement) | Proposé par un agent, déjà en place avant ce lot (E2) | `salle.bandeauControle` |
| « Cours enregistré, visite de contrôle possible. » | Mention permanente de la salle, pour tous les rôles dont le contrôleur | Proposé par un agent, déjà en place avant ce lot (E3) | `salle.bandeauPermanent` |
| « Ouverture de la salle » | État affiché dans la zone haute pendant l'ouverture de la salle | Proposé par un agent, déjà en place avant ce lot (E4) | `salle.ouverture` |
| « Connexion au cours » | État pendant la connexion au cours | Proposé par un agent, déjà en place avant ce lot (E5) | `salle.connexion` |
| « Reconnexion » | Pastille de réseau pendant une reconnexion | Proposé par un agent, déjà en place avant ce lot (E6) | `salle.reconnexionCourt` |
| « Connexion faible » | Pastille de réseau, connexion faible | Proposé par un agent, déjà en place avant ce lot (E7) | `salle.lienMediocre` |
| « Connexion perdue » | Pastille de réseau, connexion perdue | Proposé par un agent, déjà en place avant ce lot (E8) | `salle.lienPerdu` |
| « Réseau rétabli » | Pastille de réseau après rétablissement | Proposé par un agent, déjà en place avant ce lot (E9) | `reseau.retabli` |
| « En direct » | Pastille de réseau quand tout va bien | Proposé par un agent, déjà en place avant ce lot (E10) | `etat.enDirect` |
| « Personne n'est encore entré dans cette salle » | Salle encore vide, vue d'un observateur (dont le contrôleur) | Proposé par un agent, déjà en place avant ce lot (E11) | `salle.seulObservation` |
| « Le cours n'a pas commencé, ou il est déjà terminé. » | Sous le texte précédent | Proposé par un agent, déjà en place avant ce lot (E12) | `salle.seulObservationDetail` |
| « Sans image » | Vignette d'un participant sans image | Proposé par un agent, déjà en place avant ce lot (E13) | `salle.sansImage` |



## 4. Compte rendu (CTR-03)

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Compte rendu » | Titre de l'écran | Document 08 §7, CTR-03 | `controleur.compteRendu.titre` |
| « Classe Al-Fatiha · 14:30 » | Sous le titre : classe et heure de la visite | Document 08 §7, CTR-03 (« classe + heure ») | `controleur.compteRendu.sousTitre` |
| « Cet écran est en préparation. » | Texte d'attente d'une version précédente de l'écran (le code actuel ne l'affiche plus) | Proposé par un agent (P15) | `controleur.compteRendu.provisoire` |
| « Faits automatiques » | Titre du bloc des faits calculés par le système | Document 08 §7, CTR-06 (« Faits automatiques ») | `controleur.compteRendu.faits` |
| « Faits automatiques, repliés » | Lu par le lecteur d'écran, bloc replié | Proposé par un agent (P16) | `controleur.compteRendu.faitsReplies` |
| « Faits automatiques, dépliés » | Lu par le lecteur d'écran, bloc déplié | Proposé par un agent (P17) | `controleur.compteRendu.faitsDeplies` |
| « Lecture des faits de la visite en cours. » | Lecteur d'écran pendant la lecture des faits | Proposé par un agent (P18) | `controleur.compteRendu.faitsChargement` |
| « Les faits de la visite ne sont pas encore disponibles. » | Bloc des faits quand ils ne sont pas encore reçus | Proposé par un agent (P19) | `controleur.compteRendu.faitsAbsents` |
| « Heure prévue » | Étiquette dans les faits | Document 08 §1.1 (« heure prévue ») | `controleur.compteRendu.cleHoraire` |
| « 14:00 à 14:45 » | Valeur de « Heure prévue » | Proposé par un agent (P20) | `controleur.compteRendu.horaire` |
| « Début réel » | Étiquette dans les faits | Document 08 §1.1 (« heure réelle d'entrée ») | `controleur.compteRendu.cleDebutReel` |
| « 14:30, 42 min de retard » | Valeur de « Début réel » quand la séance a commencé en retard | Document 08 §1.1 (« retard ») | `controleur.compteRendu.debutRetard` |
| « 14:30, à l'heure » | Valeur de « Début réel » quand la séance a commencé à l'heure | Proposé par un agent (P21) | `controleur.compteRendu.debutALHeure` |
| « Fin » | Étiquette dans les faits | Proposé par un agent (P22) | `controleur.compteRendu.cleFin` |
| « En cours » | Valeur de « Fin » quand la séance continue | Proposé par un agent (P23) | `controleur.compteRendu.enCours` |
| « Élèves présents » | Étiquette dans les faits | Document 08 §1.1 (« participants présents ») | `controleur.compteRendu.clePresents` |
| « 8 sur 10 » | Valeur de « Élèves présents » | Proposé par un agent (P24) | `controleur.compteRendu.presents` |
| « Reconnexions » | Étiquette dans les faits | Document 08 §1.1 (« reconnexions ») | `controleur.compteRendu.cleReconnexions` |
| « Avez-vous quelque chose à signaler ? » | Question principale | Document 08 §6, P-CTR-04 et §7, CTR-03 | `controleur.compteRendu.question` |
| « Rien à signaler » | Première carte de choix | Document 08 §6, P-CTR-04 | `controleur.compteRendu.rienASignaler` |
| « Ajouter une observation » | Deuxième carte de choix | Document 08 §6, P-CTR-04 | `controleur.compteRendu.ajouterObservation` |
| « Signaler un point important » | Troisième carte de choix | Document 08 §6, P-CTR-04 | `controleur.compteRendu.pointImportant` |
| « Envoyer le compte rendu » | Bouton principal, sous les cartes ou au récapitulatif | Document 08 §6, P-CTR-05 (« CTA ») | `controleur.compteRendu.envoyer` |
| « Plus tard » | Lien secondaire : quitter sans envoyer, le compte rendu reste « à terminer » | Proposé par un agent (P25) | `controleur.compteRendu.plusTard` |
| « Ce compte rendu est transmis automatiquement à l'administration. » | Au-dessus du bouton d'envoi : le rapport part tout seul | Proposé par un agent (P26) | `controleur.compteRendu.notice` |
| « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » | Message quand l'envoi n'est pas confirmé | Proposé par un agent (P27) | `controleur.compteRendu.echec` |
| « Compte rendu envoyé » | Titre de l'écran de résultat | Proposé par un agent (P28) | `controleur.compteRendu.envoyeTitre` |
| « Il est transmis à l'administration. Pour y revenir, ouvrez-le dans l'Historique et choisissez « Ajouter un complément ». » | Phrase de l'écran de résultat | Proposé par un agent (P29) | `controleur.compteRendu.envoyePhrase` |
| « Revenir au contrôle » | Bouton principal du résultat, et sortie quand la mission n'est plus disponible | Document 08 §6, P-CTR-08 | `controleur.compteRendu.revenir` |
| « Écrire à l'administration » | Lien secondaire du résultat (ouvre Échanges) | Document 08 §6, P-CTR-06 | `controleur.compteRendu.ecrireAdmin` |
| « Transmission de la visite à l'administration en cours. » | Ligne d'état : la visite est en cours de transmission | Proposé par un agent (P30) | `controleur.compteRendu.visiteEnCours` |
| « La visite et ses faits sont transmis à l'administration. » | Ligne d'état : la visite est transmise | Proposé par un agent (P31) | `controleur.compteRendu.visiteTransmise` |
| « La visite n'a pas encore pu être transmise à l'administration. » | Ligne d'état : la transmission de la visite a échoué | Proposé par un agent (P32) | `controleur.compteRendu.visiteEchec` |



## 5. Observation (CTR-03A)

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Vous signalez un point important : votre texte sera demandé. » | Bandeau quand le chemin « Signaler un point important » est pris | Proposé par un agent (P33) | `controleur.observation.important` |
| « Quelle est la nature de votre observation ? » | Question de l'étape 1 | Proposé par un agent (P34) | `controleur.observation.questionNature` |
| « Point positif » | Choix de nature | Document 08 §6, P-CTR-05 étape 1 | `controleur.observation.pointPositif` |
| « À suivre » | Choix de nature | Document 08 §6, P-CTR-05 étape 1 | `controleur.observation.aSuivre` |
| « Intervention Admin souhaitée » | Choix de nature | Document 08 §6, P-CTR-05 étape 1 (mot « Admin » écrit tel quel dans le document) | `controleur.observation.interventionAdmin` |
| « Quel domaine concerne-t-elle ? » | Question de l'étape 2 | Proposé par un agent (P35) | `controleur.observation.questionDomaine` |
| « Pédagogie » | Choix de domaine | Document 08 §6, P-CTR-05 étape 2 | `controleur.observation.pedagogie` |
| « Interaction avec les élèves » | Choix de domaine | Document 08 §6, P-CTR-05 étape 2 | `controleur.observation.interaction` |
| « Gestion de la classe » | Choix de domaine | Document 08 §6, P-CTR-05 étape 2 | `controleur.observation.gestionClasse` |
| « Respect du cadre » | Choix de domaine | Document 08 §6, P-CTR-05 étape 2 | `controleur.observation.respectCadre` |
| « Comportement / climat » | Choix de domaine | Document 08 §6, P-CTR-05 étape 2 | `controleur.observation.climat` |
| « Autre » | Choix de domaine | Document 08 §6, P-CTR-05 étape 2 | `controleur.observation.autre` |
| « Qui est concerné ? » | Question de l'étape 3 | Proposé par un agent (P36) | `controleur.observation.questionPersonne` |
| « Enseignant » | Choix de personne concernée | Document 08 §6, P-CTR-05 étape 3 | `controleur.observation.enseignant` |
| « Classe entière » | Choix de personne concernée | Document 08 §6, P-CTR-05 étape 3 | `controleur.observation.classeEntiere` |
| « Élève précis » | Choix de personne concernée | Document 08 §6, P-CTR-05 étape 3 | `controleur.observation.elevePrecis` |
| « Aucun participant précis » | Choix de personne concernée | Document 08 §6, P-CTR-05 étape 3 | `controleur.observation.aucun` |
| « Choisissez l'élève dans la liste de la Classe. » | Consigne quand « Élève précis » est choisi | Proposé par un agent (P37) | `controleur.observation.questionEleve` |
| « La liste des élèves n'est pas disponible pour le moment. » | Quand la liste des élèves ne se charge pas | Proposé par un agent (P38) | `controleur.observation.rosterIndisponible` |
| « Qu'avez-vous observé ? » | Question de l'étape 4 | Proposé par un agent (P39) | `controleur.observation.questionTexte` |
| « Votre texte est nécessaire pour cette observation. » | Aide sous la question, texte exigé (point important, intervention de l'administration) | Proposé par un agent (P40) | `controleur.observation.texteObligatoire` |
| « Ce texte est facultatif. » | Aide sous la question, texte facultatif | Proposé par un agent (P41) | `controleur.observation.texteFacultatif` |
| « Votre remarque » | Étiquette du champ de texte | Proposé par un agent (P42) | `controleur.observation.libelleTexte` |
| « Décrivez seulement ce que vous avez observé. » | Texte d'aide dans le champ vide | Document 08 §6, P-CTR-05 étape 4 (« Placeholder ») | `controleur.observation.aideTexte` |
| « Écrivez ce que vous avez observé pour continuer. » | Erreur quand le texte exigé est vide | Proposé par un agent (P43) | `controleur.observation.texteRequis` |
| « Vérifiez votre observation avant l'envoi. » | Titre du récapitulatif (étape 5) | Proposé par un agent (P44) | `controleur.observation.questionRecap` |
| « Nature » | Étiquette du récapitulatif | Proposé par un agent (P45) | `controleur.observation.cleNature` |
| « Domaine » | Étiquette du récapitulatif | Proposé par un agent (P46) | `controleur.observation.cleDomaine` |
| « Personne concernée » | Étiquette du récapitulatif | Proposé par un agent (P47) | `controleur.observation.clePersonne` |
| « Remarque » | Étiquette du récapitulatif | Proposé par un agent (P48) | `controleur.observation.cleTexte` |
| « Aucun texte » | Valeur du récapitulatif quand le texte est facultatif et vide | Proposé par un agent (P49) | `controleur.observation.sansTexte` |
| « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » | Message quand l'envoi n'est pas confirmé | Proposé par un agent (P50) | `controleur.observation.echec` |
| « Continuer » | Bouton de passage à l'étape suivante (texte commun à l'application) | Proposé par un agent, déjà en place avant ce lot (E14) | `commun.continuer` |



## 6. Complément (CTR-03B)

Les trois motifs (Précision, Correction, Fait nouveau) ne sont pas dans le Document 08 : ils sont marqués provisoires dans le code.

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Ajouter un complément » | Bouton principal du détail (ouvre le complément) | Document 08 §6, P-CTR-07 et §7, CTR-06 | `controleur.historique.ajouterComplement` |
| « Ce complément sera ajouté au rapport existant. » | Bandeau en haut du parcours | Document 08 §7, CTR-03B | `controleur.complement.bandeau` |
| « Pourquoi ajoutez-vous ce complément ? » | Question de l'étape « motif » | Proposé par un agent (P51) | `controleur.complement.questionMotif` |
| « Facultatif : le motif aide l'administration à lire le complément. Le rapport d'origine ne change pas. » | Aide sous la question | Proposé par un agent (P52) | `controleur.complement.contexteMotif` |
| « Précision » | Choix de motif (libellé provisoire) | Proposé par un agent (P53) | `controleur.complement.precision` |
| « Quand un détail manque · il complète le rapport, sans rien y changer » | Explication du choix | Proposé par un agent (P54) | `controleur.complement.precisionAide` |
| « Correction » | Choix de motif (libellé provisoire) | Proposé par un agent (P55) | `controleur.complement.correction` |
| « Quand un fait est inexact · l'original reste lisible, la correction s'affiche dessous » | Explication du choix | Proposé par un agent (P56) | `controleur.complement.correctionAide` |
| « Fait nouveau » | Choix de motif (libellé provisoire) | Proposé par un agent (P57) | `controleur.complement.faitNouveau` |
| « Quand vous l'apprenez après la visite · il est daté du jour de l'ajout » | Explication du choix | Proposé par un agent (P58) | `controleur.complement.faitNouveauAide` |
| « Qu'ajoutez-vous au rapport ? » | Question de l'étape texte | Proposé par un agent (P59) | `controleur.complement.questionTexte` |
| « Obligatoire : des faits, en quelques phrases. » | Aide sous la question | Proposé par un agent (P60) | `controleur.complement.texteObligatoire` |
| « Complément » | Étiquette du champ | Proposé par un agent (P61) | `controleur.complement.libelleTexte` |
| « Ce que vous avez constaté ou appris depuis la visite. » | Aide dans le champ | Proposé par un agent (P62) | `controleur.complement.aideTexte` |
| « Écrivez le complément pour continuer. » | Erreur quand le champ est vide | Proposé par un agent (P63) | `controleur.complement.texteRequis` |
| « Vérifiez avant d'envoyer » | Titre du récapitulatif | Proposé par un agent (P64) | `controleur.complement.questionRecap` |
| « Rapport d'origine » | Étiquette du récapitulatif | Proposé par un agent (P65) | `controleur.complement.cleRapport` |
| « Classe Al-Fatiha · 12/10/2026, inchangé » | Valeur du récapitulatif | Document 08 §7, CTR-03B (« aucune édition destructive de l'original ») | `controleur.complement.rapportInchange` |
| « Motif » | Étiquette du récapitulatif | Proposé par un agent (P66) | `controleur.complement.cleMotif` |
| « Aucun motif » | Valeur du récapitulatif sans motif | Document 08 §6, P-CTR-07 (« motif facultatif ») | `controleur.complement.sansMotif` |
| « Complément » | Étiquette du récapitulatif | Proposé par un agent (P67) | `controleur.complement.cleTexte` |
| « Envoyer le complément » | Bouton principal du récapitulatif | Proposé par un agent (P68) | `controleur.complement.envoyer` |
| « L'envoi n'est pas confirmé : la connexion ou le serveur n'a pas répondu. Votre texte est gardé ici, réessayez dans un instant. Le rapport d'origine reste intact. » | Message quand l'envoi n'est pas confirmé | Proposé par un agent (P69) | `controleur.complement.echec` |
| « Complément ajouté » | Titre du résultat | Proposé par un agent (P70) | `controleur.complement.envoyeTitre` |
| « Il s'affiche sous le rapport d'origine, qui reste inchangé. » | Phrase du résultat | Proposé par un agent (P71) | `controleur.complement.envoyePhrase` |
| « Revenir au rapport » | Bouton principal du résultat | Proposé par un agent (P72) | `controleur.complement.revenir` |



## 7. Échanges (CTR-04)

Ces textes sont aussi ceux du fil de discussion (`FilDiscussion`), qui les reçoit de l'écran.

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Échanges » | Titre de l'écran et de la 3e destination | Document 08 §7, CTR-04 | `controleur.echanges.titre` |
| « Classe Al-Fatiha · 12/10/2026 » | Titre d'un fil : classe et date de la mission, jamais un nom de personne | Document 08 §7, CTR-04 (« titre humain ») | `controleur.echanges.titreFil` |
| « Dernière activité : 12/10/2026 » | Ligne d'un fil de la liste | Document 08 §7, CTR-04 (« dernière activité ») | `controleur.echanges.derniereActivite` |
| « Réponse reçue » | Pastille d'état d'un fil | Document 08 §7, CTR-04 | `controleur.echanges.reponseRecue` |
| « En attente » | Pastille d'état d'un fil | Document 08 §7, CTR-04 | `controleur.echanges.enAttente` |
| « Aucun échange avec l'administration pour le moment. » | Liste sans aucun fil | Proposé par un agent (P73) | `controleur.echanges.vide` |
| « Contexte de la visite, joint automatiquement » | Titre du bloc épinglé en haut d'un fil | Document 08 §6, P-CTR-06 (« contexte joint automatiquement ») | `controleur.echanges.contexte` |
| « Classe » | Étiquette du bloc épinglé | Document 08 §6, P-CTR-06 | `controleur.echanges.cleClasse` |
| « Date » | Étiquette du bloc épinglé | Document 08 §6, P-CTR-06 | `controleur.echanges.cleDate` |
| « Heure » | Étiquette du bloc épinglé | Document 08 §6, P-CTR-06 | `controleur.echanges.cleHeure` |
| « Vous » | Nom de l'auteur de vos messages (composant fil de discussion) | Proposé par un agent (P74) | `controleur.echanges.auteurVous` |
| « Administration » | Nom de l'auteur des réponses | Document 08 §4.1 (« Administration ») | `controleur.echanges.auteurAdmin` |
| « Répondre à l'administration… » | Texte d'aide dans le champ de message | Document 08 §7, CTR-04 (planche, « Répondre à l'administration… ») | `controleur.echanges.champ` |
| « Répondre à l'administration » | Étiquette du champ, lue par le lecteur d'écran | Proposé par un agent (P75) | `controleur.echanges.champLibelle` |
| « Envoyer » | Bouton d'envoi | Proposé par un agent (P76) | `controleur.echanges.envoyer` |
| « Écrivez un message pour pouvoir l'envoyer. » | Raison lisible quand le bouton est inactif | Proposé par un agent (P77) | `controleur.echanges.champVide` |
| « Envoi en cours. » | État d'un message en cours d'envoi | Proposé par un agent (P78) | `controleur.echanges.enCours` |
| « Envoyé. » | État d'un message envoyé (affiché seulement sur réponse du serveur) | Proposé par un agent (P79) | `controleur.echanges.envoye` |
| « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » | État d'un message dont l'envoi n'est pas confirmé (la saisie est gardée) | Proposé par un agent (P80) | `controleur.echanges.echec` |
| « Réessayer » | Bouton de nouvel essai | Proposé par un agent (P81) | `controleur.echanges.reessayer` |
| « Nouveau message de l'administration : Bonjour » | Annonce du lecteur d'écran à l'arrivée d'un message | Proposé par un agent (P82) | `controleur.echanges.nouveauMessage` |



## 8. Historique (CTR-05) et Détail (CTR-06)

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Historique » | Titre de l'écran et de la 2e destination | Document 08 §4.1 | `controleur.historique.titre` |
| « Cet écran est en préparation. » | Texte d'attente d'une version précédente de l'écran (le code actuel ne l'affiche plus) | Proposé par un agent (P83) | `controleur.historique.provisoire` |
| « Période » | Filtre | Document 08 §7, CTR-05 (« Période ») | `historique.filtres.periode` |
| « Toute la période » | Choix du filtre Période | Proposé par un agent, déjà en place avant ce lot (E15) | `historique.filtres.toutePeriode` |
| « 7 derniers jours » | Choix du filtre Période | Proposé par un agent, déjà en place avant ce lot (E16) | `historique.filtres.septJours` |
| « 30 derniers jours » | Choix du filtre Période | Proposé par un agent, déjà en place avant ce lot (E17) | `historique.filtres.trenteJours` |
| « 3 derniers mois » | Choix du filtre Période | Proposé par un agent, déjà en place avant ce lot (E18) | `historique.filtres.troisMois` |
| « Classe » | Filtre | Document 08 §7, CTR-05 (« Classe ») | `historique.filtres.classe` |
| « Toutes les classes » | Choix du filtre Classe | Proposé par un agent, déjà en place avant ce lot (E19) | `historique.filtres.toutesClasses` |
| « État » | Filtre | Document 08 §7, CTR-05 (« État du rapport ») | `controleur.historique.filtreEtat` |
| « Tous les états » | Choix du filtre État | Proposé par un agent (P84) | `controleur.historique.tousEtats` |
| « Envoyé » | Statut d'une ligne et choix du filtre État | Document 08 §7, CTR-05 (statuts) | `controleur.historique.envoye` |
| « Complément ajouté » | Statut d'une ligne et choix du filtre État | Document 08 §7, CTR-05 (statuts) | `controleur.historique.complementAjoute` |
| « À terminer » | Statut d'une ligne et choix du filtre État | Document 08 §7, CTR-05 (statuts) | `controleur.historique.aTerminer` |
| « 42 min observées » | Ligne de l'historique : durée observée | Document 08 §7, CTR-05 (« durée observée ») | `controleur.historique.duree` |
| « 14:30 · 42 min » | Ligne de l'historique : heure et durée | Proposé par un agent (P85) | `controleur.historique.meta` |
| « 12/10/2026, Classe Al-Fatiha, M. Karim, 42 min, Envoyé » | Phrase complète lue par le lecteur d'écran pour une ligne | Proposé par un agent (P86) | `controleur.historique.ligne` |
| « Aucun contrôle pour le moment. » | Historique sans aucun contrôle | Proposé par un agent (P87) | `controleur.historique.vide` |
| « Aucun contrôle ne correspond à ces filtres. » | Historique vide à cause des filtres | Proposé par un agent (P88) | `controleur.historique.videFiltres` |
| « Contrôles affichés : 3 » | Annonce du nombre de lignes après un filtre | Proposé par un agent (P89) | `controleur.historique.resultats` |
| « Classe Al-Fatiha · 12/10/2026 » | Titre du détail d'un contrôle (classe et date) | Proposé par un agent (P90) | `controleur.historique.titreDetail` |
| « Mission » | Section 1 du détail | Document 08 §7, CTR-06 (section 1) | `controleur.historique.sectionMission` |
| « Faits automatiques » | Section 2 du détail (même texte que dans le compte rendu) | Document 08 §7, CTR-06 (section 2) | `controleur.compteRendu.faits` |
| « Observation du Contrôleur » | Section 3 du détail | Document 08 §7, CTR-06 (section 3) | `controleur.historique.sectionObservation` |
| « Compléments » | Section 4 du détail | Document 08 §7, CTR-06 (section 4) | `controleur.historique.sectionComplements` |
| « Échanges avec l'administration » | Section 5 du détail | Document 08 §7, CTR-06 (section 5) | `controleur.historique.sectionEchanges` |
| « Classe » | Étiquette de la section Mission | Document 08 §6, P-CTR-06 (classe, enseignant, date) | `controleur.historique.cleClasse` |
| « Enseignant » | Étiquette de la section Mission | Document 08 §6, P-CTR-06 (classe, enseignant, date) | `controleur.historique.cleEnseignant` |
| « Date » | Étiquette de la section Mission | Document 08 §6, P-CTR-06 (classe, enseignant, date) | `controleur.historique.cleDate` |
| « Durée observée » | Étiquette de la section Mission | Document 08 §7, CTR-05 (« durée observée ») | `controleur.historique.cleDuree` |
| « Présents » | Étiquette de la section Mission | Proposé par un agent (P91) | `controleur.historique.cleElevesPresents` |
| « Réponse » | Étiquette d'une réponse de l'administration dans le détail | Proposé par un agent (P92) | `controleur.historique.cleReponse` |
| « Aucun complément. » | Section Compléments quand il n'y en a pas | Proposé par un agent (P93) | `controleur.historique.sansComplement` |
| « Les faits de cette visite ne sont pas encore reçus : la séance vient de se terminer ou la connexion a été coupée. Ils s'afficheront ici dès leur réception. Le reste du rapport reste fiable. » | Section des faits quand ils ne sont pas encore reçus | Proposé par un agent (P94) | `controleur.historique.faitsIndisponibles` |
| « Motif : Un détail manque » | Ligne d'un complément affichant son motif | Proposé par un agent (P95) | `controleur.historique.motif` |
| « Écrire à l'administration » | Lien secondaire du détail (ouvre Échanges) | Document 08 §7, CTR-06 (actions) | `controleur.compteRendu.ecrireAdmin` |



## 9. Espaces et accès (CT-9)

Zone « Espaces » de l'écran Compte : un même compte peut passer d'Enseignant ou d'administration à Contrôle, puis revenir.

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Espaces » | Titre de la zone dans Compte | Document 08 §4.2 (zone « Espaces ») | `compte.espaces` |
| « Les espaces auxquels votre compte donne accès » | Sous le titre de la zone | Proposé par un agent, déjà en place avant ce lot (E20) | `compte.espacesDetail` |
| « Enseignant » | Libellé de l'espace Enseignant | Proposé par un agent, déjà en place avant ce lot (E21) | `compte.roles.teacher` |
| « Administrateur » | Libellé de l'espace d'administration (voir Mots à surveiller) | Proposé par un agent, déjà en place avant ce lot (E22) | `compte.roles.admin` |
| « Actif » | Pastille sur l'espace actuellement ouvert | Proposé par un agent, déjà en place avant ce lot (E23) | `compte.actif` |
| « Observe les séances pour la qualité pédagogique » | Sous le libellé de l'espace Contrôle | Proposé par un agent, déjà en place avant ce lot (E24) | `compte.roleDetail.controller` |
| « Donne les cours et suit ses créneaux » | Sous le libellé de l'espace Enseignant | Proposé par un agent, déjà en place avant ce lot (E25) | `compte.roleDetail.teacher` |
| « Gère les dossiers, l'attribution et le journal de l'académie » | Sous le libellé de l'espace d'administration | Proposé par un agent, déjà en place avant ce lot (E26) | `compte.roleDetail.admin` |
| « Pour revenir à votre espace principal, quittez d'abord la mission en cours. » | Quand on veut quitter Contrôle pendant une mission | Document 08 §4.2 (« quitter la mission en cours ») | `compte.espacesMissionEnCours` |
| « Votre accès au contrôle n'est plus actif. » | Écran quand l'accès Contrôle est retiré | Document 08 §6, P-CTR-01 (point 7) | `controleur.acces.revoque` |
| « Revenir à mon espace » | Bouton de cet écran | Document 08 §6, P-CTR-01 (point 8) | `controleur.acces.revenir` |



Page de démonstration (accessible hors production seulement ; données fictives) :

| Texte affiché | Où il apparaît | Source | Clé technique |
|---|---|---|---|
| « Démonstration contrôleur » | Page de démonstration (hors production) | Proposé par un agent (P96) | `controleur.demo.titre` |
| « Données fictives, aucun envoi. » | Page de démonstration (hors production) | Proposé par un agent (P97) | `controleur.demo.mention` |
| « Choisissez un écran du contrôle et une situation de mission. » | Page de démonstration (hors production) | Proposé par un agent (P98) | `controleur.demo.intro` |
| « Aucune mission » | Page de démonstration (hors production) | Proposé par un agent (P99) | `controleur.demo.etatAucune` |
| « Séance pas encore en direct » | Page de démonstration (hors production) | Proposé par un agent (P100) | `controleur.demo.etatPasEncoreEnDirect` |
| « Séance en direct » | Page de démonstration (hors production) | Proposé par un agent (P101) | `controleur.demo.etatEnDirect` |
| « Mission indisponible » | Page de démonstration (hors production) | Proposé par un agent (P102) | `controleur.demo.etatIndisponible` |
| « Espaces et accès » | Page de démonstration (hors production) | Proposé par un agent (P103) | `controleur.demo.espaces` |
| « Le même compte, plusieurs espaces : Enseignant ou Admin passent en Contrôle par Compte, puis Espaces. » | Page de démonstration (hors production) | Proposé par un agent (P104) | `controleur.demo.espacesIntro` |
| « Enseignant-Contrôleur, espace Contrôle » | Page de démonstration (hors production) | Proposé par un agent (P105) | `controleur.demo.enseignantControle` |
| « Enseignant-Contrôleur, espace Enseignant » | Page de démonstration (hors production) | Proposé par un agent (P106) | `controleur.demo.enseignantPrincipal` |
| « Admin-Contrôleur, espace Contrôle » | Page de démonstration (hors production) | Proposé par un agent (P107) | `controleur.demo.adminControle` |
| « Admin-Contrôleur, espace Admin » | Page de démonstration (hors production) | Proposé par un agent (P108) | `controleur.demo.adminPrincipal` |
| « Mission en cours, retour à l'espace principal » | Page de démonstration (hors production) | Proposé par un agent (P109) | `controleur.demo.missionEnCours` |
| « Accès révoqué pendant la navigation » | Page de démonstration (hors production) | Proposé par un agent (P110) | `controleur.demo.accesRevoque` |
| « Enseignant sans capacité Contrôle » | Page de démonstration (hors production) | Proposé par un agent (P111) | `controleur.demo.sansCapacite` |
| « Compte rendu, mission devenue indisponible » | Page de démonstration (hors production) | Proposé par un agent (P112) | `controleur.demo.compteRenduIndisponible` |



## 10. Messages d'erreur

Grille appliquée : K-59 (un message d'erreur dit la cause et l'action) et D5 (dire « non confirmé », jamais « non envoyé »).

| Texte affiché | Où il apparaît | Verdict (K-59 : cause + action) | Clé technique |
|---|---|---|---|
| « Votre mission n'a pas pu être lue. Réessayez dans un instant. » | Contrôle : la mission ne se charge pas | Action oui (Réessayez), cause non. À compléter si possible (K-59). | `controleur.controle.erreur` |
| « Cette mission n'est plus disponible. » | Contrôle : séance annulée, salle fermée ou accès retiré | Volontairement sans cause (document 08 : ne pas révéler de détail de sécurité). Action portée par le bouton « Revenir au contrôle ». Conforme. | `controleur.controle.indisponible` |
| « Votre accès au contrôle n'est plus actif. » | Accès retiré | Pas de cause (volontaire), action portée par le bouton « Revenir à mon espace ». Conforme. | `controleur.acces.revoque` |
| « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » | Compte rendu : envoi non confirmé | Dit « non confirmé » (D5 respecté). Cause absente, action floue (« Vérifiez » quoi ?). À compléter (K-59). | `controleur.compteRendu.echec` |
| « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » | Observation : envoi non confirmé | Même défaut que le compte rendu (K-59). | `controleur.observation.echec` |
| « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » | Échanges : envoi non confirmé | Même défaut que le compte rendu (K-59). | `controleur.echanges.echec` |
| « L'envoi n'est pas confirmé : la connexion ou le serveur n'a pas répondu. Votre texte est gardé ici, réessayez dans un instant. Le rapport d'origine reste intact. » | Complément : envoi non confirmé | Modèle : « non confirmé » (D5), cause, action, rassurance. Conforme. | `controleur.complement.echec` |
| « La visite n'a pas encore pu être transmise à l'administration. » | Compte rendu : transmission de la visite | Affirme un non-envoi (« n'a pas encore pu être transmise ») sans cause ni action (D5 et K-59). | `controleur.compteRendu.visiteEchec` |
| « Les faits de la visite ne sont pas encore disponibles. » | Compte rendu : faits pas encore reçus | Information sans action ; acceptable car transitoire, mais pourrait dire que l'écran se met à jour tout seul. | `controleur.compteRendu.faitsAbsents` |
| « Les faits de cette visite ne sont pas encore reçus : la séance vient de se terminer ou la connexion a été coupée. Ils s'afficheront ici dès leur réception. Le reste du rapport reste fiable. » | Détail : faits pas encore reçus | Cause et suite données, rassure sur le rapport. Conforme. | `controleur.historique.faitsIndisponibles` |
| « La liste des élèves n'est pas disponible pour le moment. » | Observation : liste d'élèves absente | Ni cause ni action (K-59). | `controleur.observation.rosterIndisponible` |
| « Écrivez ce que vous avez observé pour continuer. » | Observation : champ vide | Action claire. Conforme. | `controleur.observation.texteRequis` |
| « Écrivez le complément pour continuer. » | Complément : champ vide | Action claire. Conforme. | `controleur.complement.texteRequis` |
| « Écrivez un message pour pouvoir l'envoyer. » | Échanges : bouton inactif | Action claire. Conforme. | `controleur.echanges.champVide` |
| « Ce cours ne vous est pas ouvert en ce moment » | Salle : refus d'entrée (tous rôles) | Cause (horaires) donnée dans le détail, action portée par le bouton de sortie. Conforme. | `salle.refusAcces` |
| « La salle s'ouvre dix minutes avant l'heure du cours, et se ferme un quart d'heure après sa fin. » | Salle : refus d'entrée (tous rôles) | Voir ci-dessus. | `salle.refusAccesDetail` |
| « La salle n'est pas encore disponible » | Salle : service non disponible (tous rôles) | Cause donnée mais en jargon (« pas branché ») ; « L'équipe le sait » est une promesse. Pas d'action (K-59). | `salle.refusConfiguration` |
| « Ce n'est pas votre appareil : le service de visioconférence n'est pas branché. L'équipe le sait. » | Salle : service non disponible (tous rôles) | Voir ci-dessus. | `salle.refusConfigurationDetail` |
| « La salle n'a pas répondu » | Salle : pas de réponse (tous rôles) | Action donnée (« Vérifiez votre connexion, puis réessayez »). Conforme. | `salle.refusReseau` |
| « Vérifiez votre connexion, puis réessayez. » | Salle : pas de réponse (tous rôles) | Voir ci-dessus. | `salle.refusReseauDetail` |
| « Aucun micro utilisable sur cet appareil » | Salle : micro (écrit pour l'élève et l'enseignant) | Parle de micro et de voix : ne concerne pas le contrôleur, qui n'a pas de micro. À vérifier qu'il ne l'a jamais. | `salle.refusMateriel` |
| « Un cours de Coran se fait à la voix. Autorisez l'accès au micro, ou branchez un casque, puis réessayez. » | Salle : micro | Voir ci-dessus. | `salle.refusMaterielDetail` |
| « Revenir à mon accueil » | Salle : bouton de sortie après un refus | Bouton d'action. | `salle.retourAccueil` |



---

## Textes « Proposé par un agent » à valider

Ces 137 textes sont ceux que le directeur doit valider ou changer (garder / changer en …).

1. P1 : « Planning » (`nav.controleur.planning`)
2. P2 : « Le contrôle s'ouvrira dès que la séance sera en direct. » (`controleur.controle.attente`)
3. P3 : « Visite en mode incognito : votre présence n'est pas annoncée à l'enseignant. » (`controleur.controle.incognito`)
4. P4 : « 14:00 à 14:45 » (`controleur.controle.horaire`)
5. P5 : « 42 min prévues » (`controleur.controle.duree`)
6. P6 : « 3 élève » (`controleur.controle.eleves.one`)
7. P7 : « 3 élèves » (`controleur.controle.eleves.other`)
8. P8 : « Lecture de votre mission en cours. » (`controleur.controle.chargement`)
9. P9 : « Votre mission n'a pas pu être lue. Réessayez dans un instant. » (`controleur.controle.erreur`)
10. P10 : « Reprendre le compte rendu » (`controleur.compteRendu.reprendre`)
11. P11 : « Son coupé » (`salle.visiteControle.sonCoupe`)
12. P12 : « Couper le son reçu » (`salle.visiteControle.couperSon`) — retiré jusqu'à BR-1 (CTRL-SON-1, C5 = a, d208e53e)
13. P13 : « Rétablir le son reçu » (`salle.visiteControle.retablirSon`) — retiré jusqu'à BR-1 (CTRL-SON-1, C5 = a, d208e53e)
14. P14 : « Réduire le support » (`salle.visiteControle.reduire`)
15. P15 : « Cet écran est en préparation. » (`controleur.compteRendu.provisoire`)
16. P16 : « Faits automatiques, repliés » (`controleur.compteRendu.faitsReplies`)
17. P17 : « Faits automatiques, dépliés » (`controleur.compteRendu.faitsDeplies`)
18. P18 : « Lecture des faits de la visite en cours. » (`controleur.compteRendu.faitsChargement`)
19. P19 : « Les faits de la visite ne sont pas encore disponibles. » (`controleur.compteRendu.faitsAbsents`)
20. P20 : « 14:00 à 14:45 » (`controleur.compteRendu.horaire`)
21. P21 : « 14:30, à l'heure » (`controleur.compteRendu.debutALHeure`)
22. P22 : « Fin » (`controleur.compteRendu.cleFin`)
23. P23 : « En cours » (`controleur.compteRendu.enCours`)
24. P24 : « 8 sur 10 » (`controleur.compteRendu.presents`)
25. P25 : « Plus tard » (`controleur.compteRendu.plusTard`)
26. P26 : « Ce compte rendu est transmis automatiquement à l'administration. » (`controleur.compteRendu.notice`)
27. P27 : « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » (`controleur.compteRendu.echec`)
28. P28 : « Compte rendu envoyé » (`controleur.compteRendu.envoyeTitre`)
29. P29 : « Il est transmis à l'administration. Pour y revenir, ouvrez-le dans l'Historique et choisissez « Ajouter un complément ». » (`controleur.compteRendu.envoyePhrase`)
30. P30 : « Transmission de la visite à l'administration en cours. » (`controleur.compteRendu.visiteEnCours`)
31. P31 : « La visite et ses faits sont transmis à l'administration. » (`controleur.compteRendu.visiteTransmise`)
32. P32 : « La visite n'a pas encore pu être transmise à l'administration. » (`controleur.compteRendu.visiteEchec`)
33. P33 : « Vous signalez un point important : votre texte sera demandé. » (`controleur.observation.important`)
34. P34 : « Quelle est la nature de votre observation ? » (`controleur.observation.questionNature`)
35. P35 : « Quel domaine concerne-t-elle ? » (`controleur.observation.questionDomaine`)
36. P36 : « Qui est concerné ? » (`controleur.observation.questionPersonne`)
37. P37 : « Choisissez l'élève dans la liste de la Classe. » (`controleur.observation.questionEleve`)
38. P38 : « La liste des élèves n'est pas disponible pour le moment. » (`controleur.observation.rosterIndisponible`)
39. P39 : « Qu'avez-vous observé ? » (`controleur.observation.questionTexte`)
40. P40 : « Votre texte est nécessaire pour cette observation. » (`controleur.observation.texteObligatoire`)
41. P41 : « Ce texte est facultatif. » (`controleur.observation.texteFacultatif`)
42. P42 : « Votre remarque » (`controleur.observation.libelleTexte`)
43. P43 : « Écrivez ce que vous avez observé pour continuer. » (`controleur.observation.texteRequis`)
44. P44 : « Vérifiez votre observation avant l'envoi. » (`controleur.observation.questionRecap`)
45. P45 : « Nature » (`controleur.observation.cleNature`)
46. P46 : « Domaine » (`controleur.observation.cleDomaine`)
47. P47 : « Personne concernée » (`controleur.observation.clePersonne`)
48. P48 : « Remarque » (`controleur.observation.cleTexte`)
49. P49 : « Aucun texte » (`controleur.observation.sansTexte`)
50. P50 : « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » (`controleur.observation.echec`)
51. P51 : « Pourquoi ajoutez-vous ce complément ? » (`controleur.complement.questionMotif`)
52. P52 : « Facultatif : le motif aide l'administration à lire le complément. Le rapport d'origine ne change pas. » (`controleur.complement.contexteMotif`)
53. P53 : « Précision » (`controleur.complement.precision`)
54. P54 : « Quand un détail manque · il complète le rapport, sans rien y changer » (`controleur.complement.precisionAide`)
55. P55 : « Correction » (`controleur.complement.correction`)
56. P56 : « Quand un fait est inexact · l'original reste lisible, la correction s'affiche dessous » (`controleur.complement.correctionAide`)
57. P57 : « Fait nouveau » (`controleur.complement.faitNouveau`)
58. P58 : « Quand vous l'apprenez après la visite · il est daté du jour de l'ajout » (`controleur.complement.faitNouveauAide`)
59. P59 : « Qu'ajoutez-vous au rapport ? » (`controleur.complement.questionTexte`)
60. P60 : « Obligatoire : des faits, en quelques phrases. » (`controleur.complement.texteObligatoire`)
61. P61 : « Complément » (`controleur.complement.libelleTexte`)
62. P62 : « Ce que vous avez constaté ou appris depuis la visite. » (`controleur.complement.aideTexte`)
63. P63 : « Écrivez le complément pour continuer. » (`controleur.complement.texteRequis`)
64. P64 : « Vérifiez avant d'envoyer » (`controleur.complement.questionRecap`)
65. P65 : « Rapport d'origine » (`controleur.complement.cleRapport`)
66. P66 : « Motif » (`controleur.complement.cleMotif`)
67. P67 : « Complément » (`controleur.complement.cleTexte`)
68. P68 : « Envoyer le complément » (`controleur.complement.envoyer`)
69. P69 : « L'envoi n'est pas confirmé : la connexion ou le serveur n'a pas répondu. Votre texte est gardé ici, réessayez dans un instant. Le rapport d'origine reste intact. » (`controleur.complement.echec`)
70. P70 : « Complément ajouté » (`controleur.complement.envoyeTitre`)
71. P71 : « Il s'affiche sous le rapport d'origine, qui reste inchangé. » (`controleur.complement.envoyePhrase`)
72. P72 : « Revenir au rapport » (`controleur.complement.revenir`)
73. P73 : « Aucun échange avec l'administration pour le moment. » (`controleur.echanges.vide`)
74. P74 : « Vous » (`controleur.echanges.auteurVous`)
75. P75 : « Répondre à l'administration » (`controleur.echanges.champLibelle`)
76. P76 : « Envoyer » (`controleur.echanges.envoyer`)
77. P77 : « Écrivez un message pour pouvoir l'envoyer. » (`controleur.echanges.champVide`)
78. P78 : « Envoi en cours. » (`controleur.echanges.enCours`)
79. P79 : « Envoyé. » (`controleur.echanges.envoye`)
80. P80 : « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » (`controleur.echanges.echec`)
81. P81 : « Réessayer » (`controleur.echanges.reessayer`)
82. P82 : « Nouveau message de l'administration : Bonjour » (`controleur.echanges.nouveauMessage`)
83. P83 : « Cet écran est en préparation. » (`controleur.historique.provisoire`)
84. P84 : « Tous les états » (`controleur.historique.tousEtats`)
85. P85 : « 14:30 · 42 min » (`controleur.historique.meta`)
86. P86 : « 12/10/2026, Classe Al-Fatiha, M. Karim, 42 min, Envoyé » (`controleur.historique.ligne`)
87. P87 : « Aucun contrôle pour le moment. » (`controleur.historique.vide`)
88. P88 : « Aucun contrôle ne correspond à ces filtres. » (`controleur.historique.videFiltres`)
89. P89 : « Contrôles affichés : 3 » (`controleur.historique.resultats`)
90. P90 : « Classe Al-Fatiha · 12/10/2026 » (`controleur.historique.titreDetail`)
91. P91 : « Présents » (`controleur.historique.cleElevesPresents`)
92. P92 : « Réponse » (`controleur.historique.cleReponse`)
93. P93 : « Aucun complément. » (`controleur.historique.sansComplement`)
94. P94 : « Les faits de cette visite ne sont pas encore reçus : la séance vient de se terminer ou la connexion a été coupée. Ils s'afficheront ici dès leur réception. Le reste du rapport reste fiable. » (`controleur.historique.faitsIndisponibles`)
95. P95 : « Motif : Un détail manque » (`controleur.historique.motif`)
96. P96 : « Démonstration contrôleur » (`controleur.demo.titre`)
97. P97 : « Données fictives, aucun envoi. » (`controleur.demo.mention`)
98. P98 : « Choisissez un écran du contrôle et une situation de mission. » (`controleur.demo.intro`)
99. P99 : « Aucune mission » (`controleur.demo.etatAucune`)
100. P100 : « Séance pas encore en direct » (`controleur.demo.etatPasEncoreEnDirect`)
101. P101 : « Séance en direct » (`controleur.demo.etatEnDirect`)
102. P102 : « Mission indisponible » (`controleur.demo.etatIndisponible`)
103. P103 : « Espaces et accès » (`controleur.demo.espaces`)
104. P104 : « Le même compte, plusieurs espaces : Enseignant ou Admin passent en Contrôle par Compte, puis Espaces. » (`controleur.demo.espacesIntro`)
105. P105 : « Enseignant-Contrôleur, espace Contrôle » (`controleur.demo.enseignantControle`)
106. P106 : « Enseignant-Contrôleur, espace Enseignant » (`controleur.demo.enseignantPrincipal`)
107. P107 : « Admin-Contrôleur, espace Contrôle » (`controleur.demo.adminControle`)
108. P108 : « Admin-Contrôleur, espace Admin » (`controleur.demo.adminPrincipal`)
109. P109 : « Mission en cours, retour à l'espace principal » (`controleur.demo.missionEnCours`)
110. P110 : « Accès révoqué pendant la navigation » (`controleur.demo.accesRevoque`)
111. P111 : « Enseignant sans capacité Contrôle » (`controleur.demo.sansCapacite`)
112. P112 : « Compte rendu, mission devenue indisponible » (`controleur.demo.compteRenduIndisponible`)

Ajouts de CT-RC (revue CT-R M1, m1, m2, m9 ; 02/10/2026). Lignes d'aide au format « Quand … · conséquence », provisoires (D4) :

113. P113 : « Votre réponse s'ajoute aux faits automatiques de cette visite. » (`controleur.compteRendu.contexte`)
114. P114 : « Quand la séance s'est déroulée normalement · le compte rendu part en une action ; vous pourrez ajouter un complément ensuite » (`controleur.compteRendu.rienASignalerAide`)
115. P115 : « Quand vous voulez noter un fait · quelques questions courtes, une à la fois » (`controleur.compteRendu.ajouterObservationAide`)
116. P116 : « Quand un fait demande l'attention de l'administration · votre texte sera demandé » (`controleur.compteRendu.pointImportantAide`)
117. P117 : « Votre observation rejoint le compte rendu de cette visite, transmis à l'administration. » (`controleur.observation.contexteNature`)
118. P118 : « Quand une pratique mérite d'être relevée · elle figure au rapport comme point positif » (`controleur.observation.pointPositifAide`)
119. P119 : « Quand un point devra être revu lors d'une prochaine visite · il figure au rapport comme point à suivre » (`controleur.observation.aSuivreAide`)
120. P120 : « Quand l'administration doit agir · votre texte sera demandé, elle le reçoit avec le rapport » (`controleur.observation.interventionAdminAide`)
121. P121 : « Le domaine aide l'administration à lire votre observation. » (`controleur.observation.contexteDomaine`)
122. P122 : « Quand il s'agit de l'enseignement : explications, progression, supports » (`controleur.observation.pedagogieAide`)
123. P123 : « Quand il s'agit des échanges entre l'enseignant et les élèves » (`controleur.observation.interactionAide`)
124. P124 : « Quand il s'agit de l'organisation de la séance : temps, consignes, déroulement » (`controleur.observation.gestionClasseAide`)
125. P125 : « Quand il s'agit des règles de l'académie et de la séance » (`controleur.observation.respectCadreAide`)
126. P126 : « Quand il s'agit du comportement ou de l'ambiance de la classe » (`controleur.observation.climatAide`)
127. P127 : « Quand aucun autre domaine ne convient · précisez-le dans votre texte » (`controleur.observation.autreAide`)
128. P128 : « Indiquez qui l'observation concerne. Un élève se choisit dans la liste de la Classe, prénom seulement. » (`controleur.observation.contextePersonne`)
129. P129 : « Quand l'observation porte sur l'enseignant de la séance » (`controleur.observation.enseignantAide`)
130. P130 : « Quand elle porte sur l'ensemble des élèves présents » (`controleur.observation.classeEntiereAide`)
131. P131 : « Quand un seul élève est concerné · vous le choisissez dans la liste, prénom seulement » (`controleur.observation.elevePrecisAide`)
132. P132 : « Quand elle ne vise personne en particulier, par exemple le déroulement » (`controleur.observation.aucunAide`)
133. P133 : « L'envoi n'est pas confirmé : la connexion ou le serveur n'a pas répondu. Votre choix reste sélectionné ; réessayez dans un instant. Si le problème continue, écrivez à l'administration. » (`controleur.compteRendu.echecRien`, échec de « Rien à signaler »)
134. P134 : « Lecture de la liste des élèves présents. » (`controleur.observation.rosterChargement`)
135. P135 : « La liste des élèves présents n'est pas reçue, sans doute à cause de la connexion. Réessayez, ou choisissez « Classe entière » ou « Aucun participant précis ». Vos autres réponses sont gardées. » (`controleur.observation.rosterIndisponible`, texte modifié, avec le bouton « Réessayer »)
136. P136 : « Aucun élève présent n'apparaît dans la liste de cette visite. Choisissez « Classe entière » ou « Aucun participant précis ». » (`controleur.observation.rosterVide`)
137. P137 : « {date}, {heure} » (`controleur.historique.dateHeure`, ordre et virgule traduisibles)

### Textes déjà en place avant ce lot (partagés avec d'autres rôles, à regarder sans urgence)

1. E1 : « Réessayer » (`commun.reessayer`)
2. E2 : « Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal. » (`salle.bandeauControle`)
3. E3 : « Cours enregistré, visite de contrôle possible. » (`salle.bandeauPermanent`)
4. E4 : « Ouverture de la salle » (`salle.ouverture`)
5. E5 : « Connexion au cours » (`salle.connexion`)
6. E6 : « Reconnexion » (`salle.reconnexionCourt`)
7. E7 : « Connexion faible » (`salle.lienMediocre`)
8. E8 : « Connexion perdue » (`salle.lienPerdu`)
9. E9 : « Réseau rétabli » (`reseau.retabli`)
10. E10 : « En direct » (`etat.enDirect`)
11. E11 : « Personne n'est encore entré dans cette salle » (`salle.seulObservation`)
12. E12 : « Le cours n'a pas commencé, ou il est déjà terminé. » (`salle.seulObservationDetail`)
13. E13 : « Sans image » (`salle.sansImage`)
14. E14 : « Continuer » (`commun.continuer`)
15. E15 : « Toute la période » (`historique.filtres.toutePeriode`)
16. E16 : « 7 derniers jours » (`historique.filtres.septJours`)
17. E17 : « 30 derniers jours » (`historique.filtres.trenteJours`)
18. E18 : « 3 derniers mois » (`historique.filtres.troisMois`)
19. E19 : « Toutes les classes » (`historique.filtres.toutesClasses`)
20. E20 : « Les espaces auxquels votre compte donne accès » (`compte.espacesDetail`)
21. E21 : « Enseignant » (`compte.roles.teacher`)
22. E22 : « Administrateur » (`compte.roles.admin`)
23. E23 : « Actif » (`compte.actif`)
24. E24 : « Observe les séances pour la qualité pédagogique » (`compte.roleDetail.controller`)
25. E25 : « Donne les cours et suit ses créneaux » (`compte.roleDetail.teacher`)
26. E26 : « Gère les dossiers, l'attribution et le journal de l'académie » (`compte.roleDetail.admin`)

---

## Mots à surveiller

### A. « Admin » ou « administrateur » visible (interdit côté client, K-53 : dire « l'administration »)

1. « Intervention Admin souhaitée » (`controleur.observation.interventionAdmin`). Le mot vient du Document 08 §6 P-CTR-05, mais K-53 l'interdit. Proposition de remplacement à valider : « Intervention de l'administration souhaitée ».
2. « Administrateur » (`compte.roles.admin`), libellé de l'espace d'administration dans Compte > Espaces, visible par un Admin-Contrôleur. À trancher : « Administration » ?
3. « Le même compte, plusieurs espaces : Enseignant ou Admin passent en Contrôle par Compte, puis Espaces. » (`controleur.demo.espacesIntro`), page de démonstration seulement.
4. « Admin-Contrôleur, espace Contrôle » (`controleur.demo.adminControle`), démonstration seulement.
5. « Admin-Contrôleur, espace Admin » (`controleur.demo.adminPrincipal`), démonstration seulement.

Les textes qui disent déjà « l'administration » sont corrects : `controleur.compteRendu.ecrireAdmin`, `controleur.echanges.champ`, `controleur.echanges.auteurAdmin` (« Administration »), `controleur.historique.sectionEchanges`, etc. Les clés techniques contiennent « admin » (ex. `ecrireAdmin`), ce qui n'est pas un texte visible.

### B. Texte qui affirme un non-envoi (D5 : dire « non confirmé »)

1. « La visite n'a pas encore pu être transmise à l'administration. » (`controleur.compteRendu.visiteEchec`). Affirme que ce n'est pas transmis alors que l'on ne sait pas. Proposition : « La transmission de la visite n'est pas confirmée. »
2. « Données fictives, aucun envoi. » (`controleur.demo.mention`). Exact en démonstration, sans risque ; signalé par prudence.

Les quatre messages d'échec d'envoi (`compteRendu.echec`, `observation.echec`, `echanges.echec`, `complement.echec`) disent bien « non confirmé » : conformes à D5.

### C. Message d'erreur sans cause ou sans action (K-59)

1. « L'envoi n'a pas été confirmé. Vérifiez avant de réessayer. » (`controleur.compteRendu.echec`, `controleur.observation.echec`, `controleur.echanges.echec`) : pas de cause, et « Vérifiez » ne dit pas quoi. Modèle à reprendre : `controleur.complement.echec` (cause, action, rassurance).
2. « Votre mission n'a pas pu être lue. Réessayez dans un instant. » (`controleur.controle.erreur`) : action oui, cause non.
3. « La liste des élèves n'est pas disponible pour le moment. » (`controleur.observation.rosterIndisponible`) : ni cause ni action.
4. « La visite n'a pas encore pu être transmise à l'administration. » (`controleur.compteRendu.visiteEchec`) : ni cause ni action.
5. « Les faits de la visite ne sont pas encore disponibles. » (`controleur.compteRendu.faitsAbsents`) : pas d'action (acceptable car transitoire).
6. « Ce n'est pas votre appareil : le service de visioconférence n'est pas branché. L'équipe le sait. » (`salle.refusConfigurationDetail`) : jargon et promesse ; texte partagé par tous les rôles.
7. « Un cours de Coran se fait à la voix. Autorisez l'accès au micro, ou branchez un casque, puis réessayez. » (`salle.refusMaterielDetail`) : écrit pour élève et enseignant ; le Contrôleur n'a pas de micro, il ne doit jamais le voir (à vérifier).
8. « Cette mission n'est plus disponible. » (`controleur.controle.indisponible`) et « Votre accès au contrôle n'est plus actif. » (`controleur.acces.revoque`) : sans cause, volontairement (Document 08 : ne pas révéler de détail de sécurité). Action portée par le bouton. À garder.
9. « Cet écran est en préparation. » (`controleur.historique.provisoire`, `controleur.compteRendu.provisoire`) : textes d'attente que le code actuel n'affiche plus ; à supprimer ou à garder en réserve.

### D. Tutoiement et vouvoiement

Aucun tutoiement trouvé : tout est au vouvoiement (« Votre », « Vérifiez », « Écrivez », « Choisissez »). Petites incohérences de ton :

1. « Revenir à mon espace » (`controleur.acces.revenir`, Document 08) et « Revenir à mon accueil » (`salle.retourAccueil`) parlent à la première personne, alors que le reste dit « votre » (« Pour revenir à votre espace principal », `compte.espacesMissionEnCours`).
2. « Observation du Contrôleur » (`controleur.historique.sectionObservation`, Document 08 §7 CTR-06) parle du Contrôleur à la troisième personne, alors que le reste dit « vous » (« Vous signalez un point important », `controleur.observation.important`).
3. « L'envoi n'est pas confirmé » (`controleur.complement.echec`, présent) contre « L'envoi n'a pas été confirmé » (trois autres messages, passé composé).
4. Deux rappels d'invisibilité dans le parcours : « Visite en mode incognito : votre présence n'est pas annoncée à l'enseignant. » (`controleur.controle.incognito`, avant la visite) et « Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal. » (`salle.bandeauControle`, dans la salle). Deux formulations pour une même idée.
5. Majuscules : « Contrôleur » (rôle), « Contrôle » (espace) et « l'administration » (minuscule) varient d'un écran à l'autre, c'est volontaire mais à confirmer.

### Texte déclaré mais sans emploi relevé

« Planning » (`nav.controleur.planning`) : présent dans le fichier de textes, absent de la barre du Contrôleur.
