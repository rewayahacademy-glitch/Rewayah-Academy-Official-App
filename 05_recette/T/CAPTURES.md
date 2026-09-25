# Lot T — Captures et planches (LT-13)

Captures 390x844/1440x900, clair/sombre, produites via les tests de capture
(`CAPTURE_DIR`) branche `ui/tuteur-v1-t` @ 895e601. Planches maquette | rendu
composées après coup (Python + Pillow, crop de la maquette source + capture
réelle, sans modification de `lib/`).

| Écran (fichier) | État | Défauts observés |
|---|---|---|
| LT-4 `planche_soldes.png` (Foyer, soldes) | OK | Aucun débordement ni texte coupé. Données démo différentes du montant maquette (20 XTS vs 42 unités) : normal, jeux de données distincts. |
| LT-5 `planche_fiche_solde.png` (fiche Aïcha, solde + dernière remise) | **Corrigé (LT-D), recapturé en sombre.** Relu contre le complément Tuteur §5 : le solde passe sous la carte d'identité, avant les paramètres (`d42ff45`) ; « Recharger pour <prénom> » et « Voir les mouvements » du profil (`5ebb050`). Le recadrage de la maquette montre bien l'écran Mariam entier, seul le titre de la planche déborde. Ancien constat : OK (rendu) / planche imprécise | Rendu réel conforme, rien à signaler. Le recadrage de la maquette (colonne 2 de « Soldes du foyer ») déborde sur le bandeau de titre au lieu de montrer l'écran « Mariam » entier : défaut de la planche (crop approximatif), pas de l'app. |
| LT-6 `planche_mouvements.png` (mouvements de solde) | OK | Aucun défaut visible ; filtres « Tous/Aïcha/Yusuf » alignés avec la maquette. |
| LT-6 `planche_mouvement_detail.png` | Revu (LT-D, 25/09), corrigé puis recapturé en sombre | Relu par le poste A : il manquait le solde du profil en tête, le statut en pastille, « Obtenir de l'aide », et « Voir la séance » ne passait pas l'élève. Corrigé (`81d1cb6`). Toujours absents faute de donnée serveur : motif, classe, type, date de traitement, mention « incluse dans le solde » (demandes/T.md, LT-D). |
| LT-7 `planche_recharge.png` (choix des profils, répartition) | OK | Conforme à la maquette « Recharger », aucun débordement. |
| LT-8 `planche_recharge_verifier.png` | OK | Devis, totaux et bouton Payer conformes. |
| LT-8 `planche_recharge_resultat.png` | OK | États par profil (confirmé/en attente) bien rendus. |
| LT-9 `planche_acces.png` (Accès des profils élèves) | OK | Conforme. |
| LT-9 `planche_acces_consequences.png` | Mineur | La capture est cadrée après un défilement : le haut du titre de page est coupé (« avant de confirmer. » seul visible, titre « Annuler des accès / 2 sur 2 » hors cadre). Défaut de cadrage de la capture, pas un bug d'affichage en usage réel (l'utilisateur voit le titre en faisant défiler). |
| LT-9 `planche_acces_resultat.png` | OK | États « en attente »/« échouée » conformes au faux port. |
| LT-10 `planche_soldes_web_sombre.png` (Soldes, bureau 1440x900, sombre) | **Corrigé (LT-D, `7867f40`), planche refaite.** Ligne sélectionnable et panneau « Profil sélectionné » (solde, dernière remise, « Recharger pour », mouvements du profil). Le point 2 ci-dessous était faux : la page est bien sombre (K-31). Ancien constat : **Écart net avec la maquette** | 1) Layout très vide comparé à la maquette : pas de tableau des profils avec actions « Recharger » par ligne, pas de panneau « Profil sélectionné » à droite ; grand espace blanc inutilisé sur la majorité de la largeur, bouton « Recharger » isolé en haut à droite. 2) Incohérence de thème : la barre latérale est bien sombre mais la zone de contenu principale reste en fond clair alors que `ThemeMode.dark` est actif — seule la coquille applique le thème sombre, pas la page Soldes. À corriger en priorité (pas fait ici, LT-13 = captures seulement). |
| LT-11 `planche_fiche_photo.png` (feuille de choix photo) | OK | « Prendre une photo » correctement désactivé/expliqué (caméra indisponible), « Choisir une photo » actif, mention absence de document d'identité présente. |
| LT-12 `planche_paiements.png` | Mineur | Écran réel plus pauvre que la maquette : pas de filtres « Tous les profils »/« Ce mois-ci », pas de carte détail visible par défaut. Cohérent avec le port `DB-CPT-03` indisponible en production (TRI.md), mais écart visuel notable si comparé tel quel à la maquette. |
| LT-12 `planche_notifications.png` | OK | Filtre Tous/Non lus conforme à la maquette ; l'état « Ce contenu n'est plus disponible » (cible supprimée) n'est pas dans cette planche (nécessite une interaction, capturée séparément dans les PNG bruts du dossier). |

## Notes

- Toutes les captures brutes (paires 390x844/1440x900 × clair/sombre) sont dans
  chaque dossier `LT-x`, en plus des planches ci-dessus.
- LT-7/LT-8 et LT-5/LT-11 partagent le même test de capture ; les fichiers
  concernés ont été dupliqués depuis le dossier source (LT-7→LT-8,
  LT-5→LT-11) pour que chaque ligne ait ses preuves.
- LT-10 réutilise `LT-4\soldes_1440x900_dark.png` (même écran, même test) au
  lieu de relancer un test dédié.
- Aucun fichier de `lib/` modifié. Aucun défaut corrigé : ce lot ne fait que
  produire et lister les preuves.
