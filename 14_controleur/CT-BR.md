# Vague Contrôleur : besoins serveur (BR-1)

Créé en CT-1b (27/09/2026). Chaque ligne est un besoin que la démonstration simule, à brancher en une fois à BR-1 (K-28). CT-10 complète ce fichier (doc 08 §9 à §11).

| N° | Besoin | Simulé en démonstration par | Étape |
|---|---|---|---|
| BR-CT-01 | Capacité Contrôleur datée et bornée par périmètre ; révocation immédiate. | session `AppRole.controller` fixe (`demo_controleur_page.dart`) | CT-1b, CT-9 |
| BR-CT-02 | Projection multi-rôle pour `Compte > Espaces` (Enseignant-Contrôleur, Admin-Contrôleur) ; propre Classe exclue des missions. | `DonneesControleurDemo.profils` (`classeExclue`) | CT-1b, CT-9 |
| BR-CT-03 | Attribution des missions pendant les séances en direct (pseudo-aléatoire) ; états prévue, en direct, indisponible. | `DonneesControleurDemo.mission(etat)` | CT-1b, CT-2 |
| BR-CT-04 | Faits automatiques de séance (débuts prévu et réel, durée, participants, reconnexions). | `faitsEnDirect`, `faitsSeanceFinie` | CT-1b, CT-4 |
| BR-CT-05 | Roster autorisé de la mission (prénom seul, C8). | `DonneesControleurDemo.roster` | CT-1b, CT-5 |
| BR-CT-06 | Rapports : transmission automatique à la sortie, statuts Envoyé, Complément ajouté, À terminer ; compléments sans modifier le parent. | `DonneesControleurDemo.rapports` | CT-1b, CT-4, CT-7, CT-8 |
| BR-CT-07 | Fils avec l'administration (par mission ou sujet), états Réponse reçue, En attente ; contexte épinglé. | `DonneesControleurDemo.fils` | CT-1b, CT-6 |
| BR-CT-08 | Journal d'audit des visites et des lectures. | rien (aucune écriture) | CT-10 |
| BR-CT-09 | Remplacer la lecture `mes_seances_v` du planning global (`service_controle.dart`) par la lecture des missions. | `planningGlobalProvider` surchargé à vide | CT-2 |
