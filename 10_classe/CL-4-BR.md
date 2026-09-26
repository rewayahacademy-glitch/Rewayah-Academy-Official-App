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
