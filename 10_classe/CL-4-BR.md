# CL-4 : besoins serveur (branchement BR-1)

Une ligne par besoin. Démonstration seulement jusqu'à BR-1 (K-28).

## CL-4.2 (socle de démonstration, 26/09/2026)

- Horodatages qui font foi de chaque occurrence : début, fin prévue, ouverture de la fenêtre (`join_opens_at`) et fermeture, pour `FenetreSeance` / `SessionClockVM` (R5).
- Instant serveur de référence (`maintenant_serveur()`) pour recalculer l'état après reconnexion ou saut d'horloge, jamais `DateTime.now()` seul.
- État « séance annulée » de l'occurrence, pour `EmplacementEntree.pour(annulee: true)`.
- État « préparation en cours » (pré-vol ouvert pour cette séance), si l'emplacement doit le montrer depuis un autre appareil ou après rechargement.
- Présence déjà connectée avant T0 (`connecte`) pour distinguer « attente » de « fenêtre ouverte ».
- Notice DST rendue côté serveur (heures avant et après déjà converties, échéance) : le client ne convertit aucun fuseau.
- Projection pédagogique des élèves pour l'enseignant (niveau, page de reprise, dernier point utile, présence récente en texte neutre), sans donnée famille (R15).
- Support prévu de la séance (titre, chapitre, pages), « Avant le prochain cours » (3 au plus) et ressources de la classe (titre, type, taille).
- Photo publique de l'enseignante (repli initiales en attendant).
- CL-4.4 : sources à brancher pour l'Espace Classe enseignant — `preparationSeanceProvider(groupeId)` (support prévu, position de reprise, objectif), `projectionElevesProvider(groupeId)` (page de reprise, dernier point, par studentId), et `PortGroupes.groupe(id)` / horloge de séance lisibles par l'enseignant de la Classe (aujourd'hui, sans lecture, la carte dit « Aucune séance prévue »).
- CL-4.5 (préparation enseignant, `SallePage(preparation: true)`) : à brancher — nom de la classe, temps avant le début et nombre d'élèves attendus dans `ContextePreparation` (aujourd'hui seuls support et reprise sont lus, via `preparationSeanceProvider`) ; qualité réseau LiveKit avant connexion pour « Connexion instable » (R12, aujourd'hui seulement en ligne / hors ligne) ; ouverture des réglages système (« Ouvrir les réglages ») et choix du périphérique (« Modifier les périphériques », sortie audio si la plateforme le permet), absents faute d'action réelle ; test caméra réel (aujourd'hui retour local) ; états serveur « séance terminée » et « non attribuée » à relier à `IssuePreparation` ; erreur d'autorisation après le bouton (reste l'impasse existante de la salle).
- CL-4.6 (préparation élève, `PreparationEleve` via `SallePage(preparation: true)` pour le rôle élève) : à brancher — la ligne « Accès à la classe » ne lit aujourd'hui que la connectivité (l'autorisation serveur de la séance reste demandée après « Entrer dans la classe ») ; « Autoriser le micro » ouvre la feuille CL-7 sans action système réelle (pas de redemande de permission ni « Ouvrir les réglages » avant un paquet de permission) ; « Continuer sans micro » entre en sautant le blocage matériel (`_sansMicro`) : vérifier que le moteur LiveKit ne crée aucune piste audio dans ce cas ; qualité réseau LiveKit avant connexion (R12) pour « Connexion instable ».
