# Décisions du 30/10/2026 : Bibliothèque, politique commerciale, restes de K4

Le directeur a tranché la Bibliothèque lui-même et a confié les autres choix au pilote
(« le reste des choix, tu choisis le meilleur »).

**Ordre du directeur du 30/10, plus tard dans la journée** : on n'attend plus le 04/11. Les
lots se construisent tout de suite ; un essai avec Hakim dans une nouvelle salle a lieu sous
un jour ; le pilote remet une liste de tests détaillée, à valider un par un. Les mentions
« après le 04/11 » ci-dessous sont levées. Seul le contenu de la Bibliothèque (§1, points 2 à 4)
reste un chantier long : il commence après les lots ci-dessous.

## 1. La Bibliothèque (décision du directeur)

1. **« Bibliothèque » est le seul nom du conteneur** de tous les supports, dans la salle comme
   ailleurs. Le mot « Support » disparaît des textes visibles, y compris l'onglet « Support »
   du tiroir de la salle au téléphone. Cela tranche la contradiction n° 7 de
   `K4-RESTE-2026-10-30.md` en faveur de LOT-3 §3.9.
2. Ce qu'elle contient, à terme :
   - des livres en PDF ;
   - des livres audio ;
   - une **lecture à la demande** : l'élève touche une lettre de l'alphabet ou un verset et
     entend la voix du directeur, qui enregistre lui-même tout l'alphabet. But : qu'un élève
     en retard rattrape seul, puisque la classe n'attend personne ;
   - des vidéos ;
   - des liens externes ;
   - d'autres types, ajoutés sans changer le conteneur.
3. **Des supports gratuits et des supports payants.** Les supports fournis avec la classe sont
   gratuits ; d'autres seront vendus aux familles et aux élèves, comme les manuels et
   fournitures d'une école ou d'un lycée ordinaire. Le prix d'un support payant est fixé par
   la direction et vérifié par le serveur, jamais calculé dans l'application.
4. Choix du pilote sur la forme : on garde le métier existant de CAP-29
   (`CATALOGUE_ECRANS_BIBLIOTHEQUE.md` : brouillon, revue des droits, publication,
   attribution à une classe). La lecture à la demande et la vente s'y ajoutent comme deux
   nouveaux types de support, pas comme de nouveaux écrans principaux.

## 2. Politique commerciale lue par une famille (choix du pilote, complété par le directeur)

Constat : l'écran de la famille appelle `politique_commerciale_active`, réservée à la
direction et à la comptabilité, et reçoit un refus (403). Il n'en lit que le nombre de
séances d'essai et les moyens de paiement actifs.

Décision : on **n'ouvre pas** cette fonction aux familles. Elle contient la base horaire et
le plafond de paie des enseignants, les marges et les budgets, qui ne regardent pas une
famille. On crée une lecture dédiée (`politique_commerciale_famille`) qui ne rend que ce
qu'une famille a le droit de voir : les tarifs publics, l'essai (actif, nombre), les remises
par rang et les moyens de paiement actifs. L'écran de la famille lit celle-là.

Le directeur (30/10) : « en tant que musulman je préfère être transparent ». Une page
« Nos prix, en toute transparence » montre aux familles, en pourcentages seulement (règle du
22/10 de `DECISION-TARIFS-2026-10-18.md`) :
- la répartition de chaque paiement, somme = 100 % : enseignant 47 %, frais de paiement,
  chaque service, administration, bénéfice ;
- pourquoi l'application n'est pas sur l'App Store ni sur Google Play : 15 à 30 % de chaque
  paiement, insupportable sans hausse des prix ;
- que les prix peuvent augmenter avec le coût des services et l'inflation, et que l'académie
  devra alors s'aligner.

Base de calcul choisie par le pilote : 100 élèves, moitié enfants et moitié adultes, charges du
19/10 ; la page dit qu'il s'agit d'une estimation revue à chaque version des prix.

## 3. Restes techniques (choix du pilote)

| Sujet | Décision | Quand |
| :--- | :--- | :--- |
| Suppression de l'ancienne `ajouter_creneau_classe_admin(uuid,integer,integer)` | **Annulée** : l'application l'appelle encore (`lib/core/admin/creneaux_classe_supabase.dart`, trois paramètres). La retirer casserait l'ajout d'un créneau. Le directeur n'a rien à coller | n/a |
| R9 (401 après la déconnexion) | Correction par un agent, petite PR | maintenant (lot RELIQUATS-B2) |
| Staging (une semaine de migrations en retard) | On le remet à jour une fois, par une page à coller, quand le directeur est devant un ordinateur ; ensuite chaque migration y passe avant la production | au prochain passage du directeur devant un ordinateur |
| Mot « Support » dans la salle | Remplacé par « Bibliothèque » (§1) | maintenant (lot TRANSPARENCE) |
