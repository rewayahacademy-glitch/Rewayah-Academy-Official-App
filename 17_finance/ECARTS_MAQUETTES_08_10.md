# Maquettes 08 à 10 (Finance) : écarts avec l'application et avec le guide

Reçues du directeur le 02/10/2026, 23 h. Fichiers : `V/08_bureau_clair_enseignant_revenus.png`,
`V/09_bureau_clair_finance_vue_globale.png`, `V/10_bureau_clair_politiques_commerciales.png`.
Le directeur précise : « l'image n'a pas respecté le thème de l'app à 100 % ».

**Comment s'en servir.** La maquette prime pour la structure, l'ordre des sections, les regroupements
et la place des actions (guide §2, règle de fidélité). Elle ne prime PAS pour la coque, les couleurs,
les libellés du lexique ni les valeurs métier : pour cela, ce sont l'application réelle (K-37, K-42),
le guide (§1, §5.5 à §5.7) et les décisions du directeur. Chaque écart ci-dessous dit quoi faire.
Référence de la coque réelle : `05_recette/AD/captures/AD-10/ad10_3_file_pastilles_1440x900@1_light.png`
et `lib/core/admin/admin_domaine.dart` (ui/admin-v1 @ a8dfcb3).

---

## A. Écarts communs aux trois images (thème et coque)

| # | Dans l'image | Dans l'application (à garder) | Source |
|---|---|---|---|
| A1 | Barre latérale bleu nuit (08 et 10) | Barre latérale claire de l'AdminShell, surface des jetons ; sombre seulement en thème sombre | K-37, capture AD-10 |
| A2 | 10 à 11 entrées inventées (Tableau de bord, Foyer, Élèves, Groupes, Enseignants, Planning, Présences, Messagerie, Contenus, Paramètres) | Les 7 domaines fixes : Accueil, Opérations, Personnes, Pédagogie, Finance, Configuration, Sécurité et audit. Jamais plus granulaire | `admin_domaine.dart:106-128` |
| A3 | Logo livre + « Académie en ligne » | Le mot « Rewayah » seul, jusqu'au logo officiel | LOGO-1 |
| A4 | Grand champ de recherche, cloche, puce « Tuteur / Classe Al-Fajr » ou « Tuteur / Administration » en haut | Icônes recherche, bascule clair/sombre, profil ; aucun rôle « Tuteur » dans l'espace de la direction | capture AD-10 |
| A5 | Pastilles d'icônes multicolores (orange, rouge, vert, bleu clair, cyan) et graphiques bleus | Accent violet des jetons ; succès, attention, erreur seulement pour un état ; aucun bleu ni orange décoratif. Une idée de couleur = une ligne TH-2 | K-37, guide §0.3 |
| A6 | « Groupe », « Groupes actifs », « Capacité des groupes » (08, 10) | « Classe » (décision « le mot groupe devient classe », CLASSE-FORM-1) ; « séance », pas « cours » | lexique, CLASSE-FORM-1 |
| A7 | Montants « 310,70 $ », mois « Octobre 2024 » | Montant formaté par intl avec devise identifiable (USD) ; dates de démonstration réalistes (2026) | K-41, guide §7 « devise toujours identifiable » |
| A8 | Rangées de tuiles de chiffres avec flèches vertes « + 12 % vs mois précédent » | Une rangée de synthèse sobre ; pas de tuile pour une donnée secondaire ; comparaison seulement si la donnée existe | K-42 |
| A9 | Plusieurs boutons de même force en haut (10 : « Enregistrer les modifications » plein + « Aperçu avant publication » contour) | Un seul bouton plein, sous ce qu'il confirme, au bord de fin à largeur naturelle | K-56 |

## B. 08 — Enseignant : Revenus

| # | Écart | À faire | Source |
|---|---|---|---|
| B1 | L'écran est dans la coque de la direction (Finance sélectionné, fil « Finance > Revenus de l'enseignant », pied « Admin Administrateur ») | Il vit dans l'espace **Enseignant**, ouvert depuis son Compte (`/enseignant/revenus`) | guide §4 Enseignant, FI-10 |
| B2 | Capacités 8, 6 et 10, places « 6/8 », « 5/10 » | Capacités de lancement : enfant 5, débutant 4, adulte 6 ; aucun siège au-delà de la capacité | guide §1.4 |
| B3 | Taux et montants affichés (6,00 $/h, 108,00 $…) | Recalculés par la formule (base 4, plafond 7, sièges éligibles / capacité) dans le double de démonstration ; jamais au-dessus de 7 | guide §1.4, §8 F6 |
| B4 | Carte « À propos des anciennes primes » (« Ancien bonus 20/26 », « 10/20 ») | **À retirer** : un ancien montant 20/26 ou 10/20 ne réapparaît pas | guide §13, §1.4 Bonus |
| B5 | « Historique des paiements » avec statut « Payé » | Garder la structure, mais l'écran reste une **estimation** : le libellé le dit, aucune paie présentée comme définitive sans le serveur | guide §5.5 |
| B6 | « Allocation Internet 10,00 $ / mois » | Gardée **à part** de la rémunération (bonne idée de la maquette) ; montant de démonstration, configurable | guide §1.4 Internet |
| B7 | « Groupes actifs 3 sur 3 groupes » | « Classes actives : 3 » ; rappel de l'objectif (3) et du maximum (4) si utile, sans doublon | guide §1.4 |
| B8 | Carte « Nouvelle règle de rémunération » (base + occupation, plafonné à 7) | **À garder** : c'est l'explication simple demandée (base, occupation, plafond) | guide §5.5 |

## C. 09 — Finance : vue globale (direction)

| # | Écart | À faire | Source |
|---|---|---|---|
| C1 | KPI « Essais en cours : 1 250 $ » | Les essais sont gratuits : c'est un **nombre** d'élèves en essai, jamais un montant | FIN4-11, FIN4-15 |
| C2 | KPI « Marge observée » | « Marge projetée », référence de pilotage (~30 %), jamais une sanction | guide §1.5, §5.6 |
| C3 | « Répartition des revenus » : frais de scolarité, inscriptions, cours additionnels, dons, autres | Catégories inventées : Rewayah vend un **accès mensuel à une classe**, sans frais d'inscription ni séance à l'unité. Répartition possible : par type d'élève (enfant, adulte) ou par classe | FIN4-03 |
| C4 | « Dernières opérations » : « Frais d'inscription », « Matériel pédagogique / Fournisseurs », « Don » | Seulement les mouvements du modèle : encaissements (recharges), allocations par profil, paie enseignant, remboursements | FIN4-03, §5.6 |
| C5 | Encaissement, revenu, charge et marge dans un même histogramme | Toujours distinguer encaissement, revenu, solde client, charge, marge ; chaque graphique affiche son nombre exact | guide §5.6, FI-11a |
| C6 | 7 tuiles en une rangée à 1440 | Garder les 7 indicateurs (ils suivent le guide), mais en grille lisible à 1440, propre à 1200 et 768 | guide §6, K-55 |
| C7 | « État des paiements » (Financés, À régulariser, En essai, En confirmation) et « Alertes et actions » | **À garder** : conformes au guide et utiles ; alertes en couleurs d'état des jetons seulement | guide §1.6, §1.7 |
| C8 | « Top classes (par encaissements) » | Garder ; s'assurer qu'aucune classe n'est classée « mauvaise » par la marge (aucune sanction) | guide §1.5 |

## D. 10 — Politiques commerciales

| # | Écart | À faire | Source |
|---|---|---|---|
| D1 | Tarifs « 50 $ **par cours** », « 60 $ **par cours** » | **Par mois** : le produit est un accès mensuel, jamais à la séance | FIN4-01, FIN4-03 |
| D2 | Remises « - 5 $ par cours », « - 7 $ par cours » ; « Total par cours 145 $ » | Par mois ; total « 145 USD / mois » | guide §1.3 |
| D3 | « 1er et 2e **enfant** », « 3e enfant », « 4e enfant » | « membre payant » : la remise compte aussi les adultes payants du foyer | guide §1.3 |
| D4 | « Enfant (≤ 15 ans) » / « Adulte (≥ 16 ans) » | Seuil d'âge absent du guide : ne pas l'afficher tant qu'il n'est pas décidé (question au directeur si besoin) | guide §1.1 |
| D5 | « Pilotage » : marge cible 22 %, budget marketing 8 %, opérationnel 15 % | Référence de lancement ~30 % (35 % fort, 40 % ambitieux) ; budgets « non contraignants » marqués comme tels | guide §1.5, §5.7 |
| D6 | Bloc « Rémunération enseignants » sans aide Internet | Ajouter le champ « aide Internet » (une par enseignant éligible) | guide §5.7 Enseignants |
| D7 | Bloc « Paiement » sans « règles de relance visibles » | L'ajouter ; « place conservée 7 jours » est juste | guide §1.7, §5.7 |
| D8 | Bloc « Essais » : « 2 cours maximum » sans activation | « 2 séances d'essai maximum » + interrupteur d'activation | guide §5.7 Essai |
| D9 | « Enregistrer les modifications » en haut, plein | Flux versionné : brouillon enregistré → aperçu avant publication → **Publier la version** (action principale, une seule) ; date d'effet obligatoire avant publication | guide §5.7, K-56 |
| D10 | Paramètres et invariants mélangés dans le menu « … » | Aucun invariant (idempotence, soldes séparés, historique en ajout seul, confirmation avant crédit…) n'est un champ | guide §5.7 |
| D11 | Version brouillon v2.1.0 → version active v2.0.0, date d'effet | **À garder** : c'est exactement le versionnage demandé | guide §5.7 |
| D12 | Aperçus « exemple de foyer » et « exemple d'enseignant » | **À garder** ; l'aperçu enseignant applique la formule complète (base + occupation), pas seulement 4 $ × heures | guide §1.4, FI-11c |

---

## E. Ce que cela change au tableau

- FI-10, FI-11a et FI-11b n'attendent plus les maquettes : elles suivent la file de la voie FIN.
- FI-1a (revue UX, en cours dans une autre session) intègre ce relevé : une décision par écart (garder / adapter / refuser).
- Aucune nouvelle couleur : toute idée de couleur venue de ces images va en une ligne dans TH-2.
