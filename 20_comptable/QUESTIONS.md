# Comptable V1 : questions au directeur (CPT-Q)

Seulement ce qui attend vraiment votre décision. Écrit par CPT-0 le 04/10/2026. Tous les autres choix sont pris par défaut et écrits dans `DEVOIR_DE_REGARD_FINANCE.md` (DR-01 à DR-25) : vous pouvez les reprendre à tout moment.

**Aucune voie n'est arrêtée par cette question** (spec §4) : CPT-F, CPT-JOUR, CPT-PAY, CPT-TRES, CPT-ENC, CPT-BEN, CPT-CTR et les deux panneaux de CPT-DIR-1 avancent. Seul le complément de CPT-DIR-1 décrit ci-dessous attend votre réponse.

## CPT-Q1. Où la Direction valide-t-elle ce que le Comptable lui demande ?

La spec fait demander une validation au Comptable dans quatre cas : un paiement sensible (premier paiement d'une personne, coordonnées changées récemment, montant au-dessus du plafond), un retrait de la Réserve stratégique, une obligation ponctuelle à approuver, et **sa propre paie** (« Traitement par un autre responsable requis »). Mais elle ne prévoit aucun écran côté Direction pour voir ces demandes et y répondre : les deux panneaux du §37 règlent des politiques, ils ne valident rien. Et l'admin ne peut pas ouvrir les écrans du Comptable (chaque rôle a ses adresses).

**Exemple** : le Comptable veut payer 450 USD à Mariam Bah, dont les coordonnées ont changé hier. L'écran lui dit « Validation supplémentaire requise » et il appuie sur « Demander validation ». Aujourd'hui, cette demande n'arrive nulle part.

- **Recommandé** : ajouter un onglet **« À valider »** dans Finance de la Direction (à côté de Vue globale, Politiques et du nouvel onglet Réserve et délégation). Chaque demande montre le montant exact, la personne (son profil de paiement masqué, sans bouton pour modifier ses coordonnées), la raison, et deux boutons : Valider, Refuser avec un motif. Celui qui demande ne peut jamais valider. C'est fait dans CPT-DIR-1, en démonstration, sans serveur. Cela sert aussi la recette R-FIN-12 (« l'admin consulte un enseignant : aucun Modifier les coordonnées »).
- **Sinon** : rien côté Direction dans cette vague. Le Comptable voit « Validation demandée » et la boucle se fermera avec le branchement serveur (BR-1). R-FIN-12 se vérifie alors seulement sur la fiche Personnes existante de l'admin.

Pourquoi c'est à vous : c'est un écran que la spec ne demande pas, et il touche la séparation des tâches (qui valide l'argent du Comptable).
