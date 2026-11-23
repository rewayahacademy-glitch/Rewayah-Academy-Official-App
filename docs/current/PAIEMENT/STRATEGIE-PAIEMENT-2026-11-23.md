# Stratégie du paiement : audit de l'existant et plan (23/11/2026)

Mission du directeur, 23/11/2026 : « le paiement a reçu beaucoup trop de bricolage ; interdit de recréer d'autres choses en plus de ce qui existe ; il faut d'abord voir ce qui existe et corriger ou arranger ». Ce document ne crée rien. Aucun code, aucune migration, aucune écriture en production. Lecture seule de la base de production, le 23/11/2026.

## 0. La vérité d'abord, en six phrases

1. **Aucun paiement Stripe réel n'a jamais abouti.** Sur 33 commandes de recharge, 32 sont `stale` (page de paiement expirée) et 1 est `preparing`. Les 36 événements Stripe reçus sont tous des `checkout.session.expired`. Le circuit Stripe est écrit et branché, mais **non prouvé en production**.
2. **Les taxes ne sont pas calculées.** Aucun `automatic_tax` dans `supabase/functions/_shared/stripe.ts` ni ailleurs. Le site promet « la taxe de votre pays est ajoutée au paiement » : c'est faux aujourd'hui.
3. **La devise est fixe (USD).** Le site promet « le montant en euros, livres ou dollars canadiens s'affiche au paiement » : rien ne le fait dans le code.
4. **Le premier paiement n'est demandé nulle part.** Ni la frise, ni le courriel d'acceptation, ni « classe validée » ne le disent. Un élève n'est suspendu qu'après une facture impayée passée l'échéance : sans facture échue, le premier cours a lieu gratuitement.
5. **Les gestes par élève existent à moitié** : prix spécial et accès offert sont codés (écran Finance, pas la fiche élève) ; « demander le paiement maintenant » et « reporter » n'existent pas.
6. **Aucun reçu n'existe** côté serveur (REÇUS-FAMILLE, registre du 12/11).

## 1. Inventaire de l'existant

« Branché » = atteignable depuis `lib/main.dart`. Chiffres : base de production, 23/11/2026.

### 1.1 Prix, politique, remises (une seule source : à garder)

| Brique | Où | Rôle | Branché | Prouvé / lignes |
|---|---|---|---|---|
| `politiques_commerciales` (43 colonnes, immuable par version) | `20261017170000_fac_a_01`, `20261018120000_fac_e_01`, `20261031100000` | Prix 55 / 65 $, remises, délai de remboursement, jour de suspension | Oui | 3 versions : v1.0.0 (50/60, essai), v2.0.0 (55/65, 7 j), **v2.1.0 (55/65, 14 j, depuis le 03/11)** |
| `private.fac_tarif_profil`, `fac_remise_rang`, `fac_remise_montant`, `fac_mensualite`, `fac_prix_prepaiement` | migrations FAC-E | Calcul serveur du prix d'un élève | Oui | Oui (6 factures) |
| `politique_commerciale_active`, `tarifs_publics`, `apercu_politique_famille` | FAC-A, PUB-TARIFS | Lecture par l'app et le site | Oui | Oui |
| `docs/current/tarifs-2026-10-18.json` | docs | Copie lisible du barème pour le site | Hors app | Source du site |
| Remise foyer (-8 %, -17 %), prépaiement (-5 %, -10 %), parrainage | dans la politique | Remises automatiques | Oui | `engagements_prepaiement` : **0 ligne** (jamais utilisé) |

### 1.2 Gestes par élève (bourse, prix spécial, accès offert)

| Brique | Où | Rôle | Branché | Lignes |
|---|---|---|---|---|
| `bourses_eleves`, colonne `nature` : `bourse` / `acces_offert` / `prix_special` | `20261104800000`, `20261104900000` | **Une seule table** pour les trois gestes | Oui | 3 lignes, toutes `acces_offert` jusqu'au 01/01/2027 |
| RPC `accorder_bourse`, `accorder_tarif_particulier`, `retirer_bourse`, `bourses_lister` | idem | Accorder / retirer, raison et mois de fin obligatoires | Oui | |
| `private.fac_bourse`, `fac_bourse_couvre`, `acces_lever_par_bourse` | FAC-E / FAC-F / lot B | La facture applique la remise ; un accès offert lève la suspension | Oui | 3 suspensions levées par motif `bourse` |
| Écran `lib/features/admin_finance/paiements/tarifs_particuliers.dart` (551 lignes) | Finance > Paiements | Feuille « Prix spécial / Accès offert » | Oui | |
| **Fiche élève de la direction** `lib/features/admin_personnes/fiche_eleve_direction_page.dart` | Personnes | **Ne contient aucun geste de paiement** | n/a | À brancher |

### 1.3 Facturation, relances, blocage

| Brique | Où | Rôle | Branché | État |
|---|---|---|---|---|
| `factures_mensuelles` (+ `fac_emettre_facture`, `fac_emettre_factures_du_mois`, `emettre_factures_mois`) | FAC-B, B4 | Facture mensuelle par élève, prorata du premier mois | Oui | 6 factures : 1 `financee`, 5 `a_financer` |
| Cron `fac-emission-factures` (04:45 UTC) et `fac-relances-quotidiennes` (05:15 UTC) | B4 `20261102600000` | Émission et relances J-7, J-3, J-1 | Actifs | Vérifié dans `cron.job` |
| `relances_paiement` | FAC-F | Journal des relances | Oui | 8 lignes |
| `acces_suspensions_paiement`, `private.fac_eleve_suspendu`, `private.acces_paye` (+ `_groupe`, `_seance`) | FAC-F, lots A/B `20261104500000`, `20261104600000` | **Une porte serveur** : pas payé = ni séances ni ressources | Oui (jeton de salle, ressources, enregistrements) | 5 suspensions, 2 actives |
| Notification `acces_suspendu_paiement` | `fac_notifier_paiement` | Prévient la famille | Oui | |

### 1.4 Entrée d'argent : Stripe, recharge, saisie manuelle

| Brique | Où | Rôle | Branché | État |
|---|---|---|---|---|
| `recharges_recapitulatifs` (+ lignes), `commandes_recharge` (+ allocations) | `20261018100000_fi_br06_01` | Récapitulatif arrêté par le serveur, commande idempotente, une part par profil | Oui | 98 récapitulatifs, 33 commandes, 0 payée |
| Fonction Edge `recharge-payer` (244 lignes) | `supabase/functions/` | Crée la session Checkout (`mode: payment`, `price_data` en USD) | Oui | Jamais prouvée avec un vrai paiement |
| Fonction Edge `stripe-webhook` (180 lignes) | idem | Seule à créditer ; signature ; dédoublonnage | Oui | 36 événements, tous « expired » |
| `_shared/stripe.ts` : **trois formes** de formulaire (page hébergée, `embedded_page`, `elements`) | idem | Reliquat de PAY-UX et LINK-CHOIX | Oui | Bricolage (D1) |
| `wallets`, `wallet_entries` (immuable), `x217_*` | AF-L1, X217 | Crédit du foyer ; la recharge crédite, la facture débite | Oui | 3 portefeuilles, 1 écriture |
| `paiements_saisis`, `paiements_soumis`, `finance_validations`, RPC `enregistrer_paiement`, `eleves_pour_paiement` | FAC-C, FAC-D | **Recours manuel** (paiement reçu hors application), validé par la direction | Oui | 1 saisie, 0 soumission |
| Écrans famille : `foyer/recharge_foyer.dart` (1 238 lignes), `resultat_recharge.dart` (774), `reprise_foyer.dart` (731), `core/finance/page_paiement*.dart`, `formulaire_stripe*.dart`, `suivi_paiement.dart` | Foyer | Choisir les élèves, payer dans l'application, relire l'état | Oui | 33 essais, 0 abouti |
| Courriel `paiement_recu` (`20261103400000`) | | Courriel de paiement reçu | Oui | Jamais envoyé en réel |

### 1.5 Remboursement

| Brique | Où | Rôle | Branché | État |
|---|---|---|---|---|
| `private.fn115c_montant_propose` | `20261105100000_fn115c_rembourser.sql` | **Le seul calcul** du remboursement : payé moins séances suivies ; hors délai, mois commencés au prix normal sans remise | Oui | Scénario SQL vert ; production : 0 remboursement |
| `remboursements_demandes` | idem | Demande de la direction, idempotente | Oui | 0 ligne |
| RPC `remboursement_paiements_eleve`, `remboursement_eleves_remboursables`, `remboursement_confirmer`, `remboursement_a_envoyer`, `remboursement_resultat_stripe`, `remboursement_solder_stripe`, `remboursement_profil_stripe` | idem | Circuit de la demande | Oui | |
| Fonction Edge `remboursement-stripe` (88 lignes) | | Rembourse chez Stripe, clé `remboursement-<demande>` | Oui | **Jamais appelée en réel** |
| `remboursements_paiement`, `litiges_paiement`, `remboursement_evenement_stripe` | `20261104400000` | Événements `charge.refunded` et contestations, y compris faits chez Stripe | Oui | 0 ligne |
| Écran `admin_finance/paiements/remboursement_direction.dart` | Finance > Paiements, menu « … » de l'élève | Bouton « Rembourser » | Oui | |
| `core/finance/delai_retractation.dart` | | Lit `remboursement_delai_jours` (aucun nombre en dur) | Oui | Lit 14 (v2.1.0) |

### 1.6 Écrans qui lisent l'argent (famille, direction, comptable)

| Écran | Rôle | Statut |
|---|---|---|
| `foyer/finances_foyer.dart`, `foyer/fiche/finances_page.dart`, `foyer/transactions_foyer.dart` | Finances du foyer | Branchés |
| `compte/paiements_page.dart` (+ `core/capacites/paiements_foyer_supabase.dart`) | Paiements du foyer ; **`justificatifDisponible` codé faux** (pas de reçu) | Branché |
| `mon_espace_adulte/mes_finances_page.dart` | Mêmes chiffres pour l'adulte | Branché (3e vue du même argent) |
| `admin_finance/` (paiements, factures du mois, à valider, rembourser, tarifs particuliers) | Bureau de la direction | Branché |
| `comptable/encaissements/`, `comptable/paiements_familles/`, `comptable/tresorerie/`, `comptable/aujourdhui/` | Espace du comptable | **`portEncaissementsProvider` n'a aucune implémentation Supabase** dans `core/capacites/` : écran de démonstration. À vérifier contre `tool/branchement_tolere.txt` |
| `foyer/nos_prix_page.dart` | Prix montrés à la famille après acceptation | Branché |
| `features/demo/finance_demo.dart` et voisins | Démonstration | Derrière `PLAYGROUND` |

### 1.7 Hors périmètre (autre sujet : la paie des enseignants)

`payout_methods`, `payouts`, `versements_paie`, `referentiel_paiement*`, Wise, `candidature_paiement_decisions`, `repartitions_paiement`. Ne pas toucher. Ne pas confondre avec le paiement des familles.

## 2. Doublons, contradictions et bricolages trouvés

| # | Constat | Preuve | Sort proposé |
|---|---|---|---|
| D1 | **Trois formes de formulaire Stripe** : page hébergée (repli), `embedded_page`, `elements` | `parametresSession`, `formeDemandee`, clés d'idempotence à trois variantes dans `recharge-payer` | Garder **une** forme. Retirer les deux autres après la première vraie preuve (lot P3) |
| D2 | **Deux entrées d'argent** : Stripe et saisie manuelle | FAC-C, FAC-D | Garder les deux **avec des rôles nets** : Stripe = chemin normal ; saisie = recours (décision du 18/10). Aucune suppression |
| D3 | **Le mot « recharge »** pour dire « payer » : tables, fonctions, écrans, routes (`/recharge`) | `commandes_recharge`, `recharge_payer`, `recharge_foyer.dart` | Ne **pas** renommer les objets de base. Changer seulement les **textes visibles** : « Payer » |
| D4 | **Crédit du foyer (wallet) + facture** : la famille crédite un portefeuille que la facture débite | `wallet_entries`, `fac_crediter_paiement` | Garder (moteur de prorata et de remboursement). Côté famille : « à payer » et « payé », jamais « crédit » |
| D5 | **Trois vues du même argent côté famille** | §1.6 | Une seule source de lecture (`paiements_foyer`), une seule page (lot P7) |
| D6 | **Espace du comptable branché sur rien** pour les encaissements | Aucun adaptateur Supabase pour `PortEncaissements` | Ne pas le brancher tel quel : la direction a déjà l'écran Finance. Décision du directeur |
| D7 | **`DECISION-TARIFS` dit « la politique porte encore 7 »** | Production : v2.1.0 porte 14 depuis le 03/11 | Corriger la phrase (lot P0) |
| D8 | **Règle du remboursement en deux versions** : 02/11 (« ensuite, le reste est remboursé ») et 07/11 (« mois réservé non remboursable ») | `DECISION-TARIFS` et `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md` | Le code applique celle du 02/11. La règle du 23/11 (« remboursé du reste du mois, moins les séances suivies ») concorde avec le code, **pas** avec la ligne 1 du 07/11. Le directeur tranche |
| D9 | **Taxes promises, non calculées** | Site ; code sans `automatic_tax` ; migration FI-BR-06 : « aucune taxe configurée » ; colonne `taxe_mineur` | Un seul réglage : Stripe Tax (lot P2) |
| D10 | **Devise** : site « euros, livres, dollars canadiens », code USD seul | `price_data.currency` = devise de la politique | Dire USD dans les textes **ou** activer les prix locaux de Stripe ; décision du directeur |
| D11 | **Délai de 14 jours** : départ « à fixer » dans l'harmonisation | `A-HARMONISER` règle 2 | Départ = premier paiement confirmé (webhook) |
| D12 | **Suspension seulement après facture échue** ; rien n'empêche le premier cours sans paiement | `fac_eleve_suspendu` ne lit que les suspensions posées ; audit angles morts, étape 8 | La porte unique `acces_paye` existe : lui faire dire « jamais payé » (lot P4) |
| D13 | **Reçus : aucun** | `justificatifDisponible` faux, `PortRecus` sans implémentation | Reçu Stripe + page « Paiements » ; décision du directeur |
| D14 | **Remboursement jamais joué en vrai** | 0 ligne dans `remboursements_demandes` | Preuve avec un vrai paiement de 1 $ (lot P1) |
| D15 | **Code mort signalé** : règle `confirmer_moyen_paiement`, branche `a_verifier` de `private.paiement_etat` | Registre, 17/11 | Paie des enseignants : ne pas toucher ici |
| D16 | **« Demander maintenant » et « reporter » n'existent pas** | Aucune occurrence dans `lib/` ni `supabase/migrations/` | §4.3 : on les construit **sur** l'existant |

## 3. Le parcours réel d'aujourd'hui, et où il casse

| Étape | Ce qui se passe aujourd'hui | Où ça casse |
|---|---|---|
| 1. Admission acceptée | Courriel « Votre espace est ouvert » ; profils actifs | Il ne dit pas qu'il faudra payer |
| 2. Choix des créneaux, classes visibles | Fonctionne | La frise n'a pas d'étape de paiement (7 étapes, aucune d'argent) |
| 3. Prix montré | `/tuteur/foyer/prix` (`nos_prix_page`), **après** l'acceptation | Aucune phrase « pourquoi payer avant » |
| 4. Facture | Cron 04:45 UTC : facture du mois, prorata du premier mois | Un seul cas financé en réel |
| 5. Payer | Foyer > « Recharger » : récapitulatif serveur, commande, session Stripe, formulaire dans l'application, page de résultat | 33 essais, 0 abouti ; USD seul ; **aucune taxe** ; le mot « recharge » |
| 6. Confirmation | Webhook signé crédite le portefeuille ; la facture est financée | Jamais vu en réel |
| 7. Reçu | Courriel `paiement_recu` ; page « Paiements » | Pas de reçu téléchargeable |
| 8a. Exonérer | Finance > Paiements > « Accès offert » ; lève la suspension | Pas sur la fiche élève |
| 8b. Prix spécial | Même écran, « Prix spécial » | Pas sur la fiche élève |
| 8c. Demander maintenant | **N'existe pas** | Seul moyen : attendre le cron ou saisir à la main |
| 8d. Reporter | **N'existe pas** | Contournement : « Accès offert » jusqu'à un mois donné |
| 9. Annulation, remboursement | Finance > menu « … » > « Rembourser » ; Stripe ; webhook | Jamais joué ; deux règles écrites (D8) |
| 10. Blocage | Rappels J-7, J-3, J-1 ; suspension le 4 ; place libérée le 16 | Ne joue **qu'après** une facture échue : pas de blocage avant le premier cours (D12) |

## 4. La stratégie unique

### 4.1 Les cinq principes

1. **Une source de vérité du prix par élève** : `politiques_commerciales` (version en vigueur) pour le prix par défaut, `bourses_eleves` pour tout écart accordé à la main (`bourse`, `prix_special`, `acces_offert`). `private.fac_tarif_profil` + `fac_bourse` + `fac_mensualite` calculent. Rien en dur dans Flutter.
2. **Un seul état de paiement par élève**, lu par **une seule porte** : `private.acces_paye(profil)`. Quatre valeurs que l'écran dit en mots : `a_payer`, `paye`, `en_retard`, `exonere`. Elles se **déduisent** des tables existantes (factures, suspensions, bourses) ; aucune colonne d'état nouvelle.
3. **Un seul circuit Stripe** : `recharge_payer` → `recharge-payer` → `stripe-webhook` → `recharge_evenement_stripe`, avec **Stripe Tax** (`automatic_tax`, prix hors taxes) et **une seule forme** de formulaire.
4. **Un seul circuit de remboursement** : `fn115c_montant_propose` → `remboursement_confirmer` → `remboursement-stripe` → webhook. Un remboursement fait chez Stripe est capté par le même webhook.
5. **Rien de nouveau tant que l'existant suffit.** Deux manques réels : le **moment** (demander le paiement après la validation des classes) et la **fiche élève** (aucun geste de paiement).

### 4.2 Brique par brique : garder, corriger, brancher, retirer

| Brique | Décision | Raison |
|---|---|---|
| `politiques_commerciales`, `tarifs_publics`, `tarifs-2026-10-18.json` | **Garder** | Source unique des prix |
| Prix 55 / 65 $ hors taxes | **Garder** | Déjà v2.1.0 |
| `bourses_eleves` (3 natures) + RPC `accorder_*`, `retirer_bourse` | **Garder** | Prix spécial et exonération y sont déjà |
| `factures_mensuelles`, cron d'émission et de relances | **Garder** | Actifs |
| `acces_suspensions_paiement`, `private.acces_paye` | **Corriger** | Ajouter « jamais payé » à la porte unique (P4) |
| `commandes_recharge`, `recharges_recapitulatifs`, `wallets`, `wallet_entries` | **Garder** | Moteur de crédit, de prorata, de remboursement ; ne pas renommer |
| `recharge-payer`, `stripe-webhook`, `_shared/stripe.ts` | **Corriger** | Ajouter Stripe Tax ; une seule forme de formulaire |
| Page hébergée et deux des trois formes | **Retirer**, **après** preuve | Doublon (D1) |
| `paiements_saisis`, `paiements_soumis`, validations | **Garder** (recours) | Décision du 18/10 |
| `fn115c_*`, `remboursements_demandes`, `remboursement-stripe`, `remboursements_paiement`, `litiges_paiement` | **Garder, prouver** | Jamais joué en réel |
| `engagements_prepaiement` (0 ligne) | **Garder** | Prépaiement dans la politique ; pas de retrait sans décision |
| Feuilles `tarifs_particuliers.dart`, `remboursement_direction.dart` | **Brancher** aussi sur la fiche élève (réutiliser) | Les gestes doivent être sur la fiche |
| `comptable/encaissements`, `paiements_familles` | **Retirer** ou laisser, décision du directeur | Sans adaptateur ; double de l'écran Finance |
| `compte/paiements_page`, `mon_espace_adulte/mes_finances`, `foyer/finances_foyer` | **Fusionner** en une page de lecture | Trois vues du même argent |
| Textes « recharge », « crédit » côté famille | **Corriger** (textes seulement) | Un mot : « Payer » |
| Paie des enseignants | **Ne pas toucher** | Autre sujet |

### 4.3 Les gestes de la fiche élève, mappés sur l'existant

Fiche : `lib/features/admin_personnes/fiche_eleve_direction_page.dart`. Une section « Paiement » avec l'état et quatre gestes. Chaque geste ouvre la feuille qui existe ou fait un seul appel serveur.

| Geste | Par défaut | Ce qui existe | Ce qu'il manque |
|---|---|---|---|
| **Prix spécial** | Prix de la politique | `accorder_tarif_particulier` (nature `prix_special`, montant mensuel hors taxes ou pour mille, raison et mois de fin obligatoires) ; feuille dans `tarifs_particuliers.dart` ; la facture lit déjà le montant | Un bouton sur la fiche, même feuille |
| **Exonérer** | Paiement activé | `accorder_tarif_particulier` / `accorder_bourse`, nature `acces_offert` ; lève la suspension tout de suite (`acces_lever_par_bourse`) ; `retirer_bourse` pour réactiver | Même bouton |
| **Demander le paiement maintenant** | Automatique après la validation de la classe | `fac_emettre_facture` (idempotente) + `fac_notifier_paiement` + `recharge_beneficiaires` | **Un appel serveur fin** qui émet la facture du mois de cet élève et notifie le titulaire : il enveloppe des fonctions existantes (lot P5 ; la seule fonction nouvelle, sans table) |
| **Reporter / attendre** | Pas de report | Contournement existant : `acces_offert` avec `mois_fin` = mois de reprise ; facture à 0, suspension levée ; le paiement reprend de lui-même | Un libellé « Reporter jusqu'au… » qui appelle le même geste, raison « reporté ». Aucune table |

Règle : un seul geste actif par élève et par période (la table l'impose déjà). Chaque geste exige une raison, est journalisé (`accordee_par`, `accordee_le`) et se lit sur la fiche et dans l'écran Finance.

### 4.4 Le moment du paiement (règle du directeur, 23/11)

1. La famille fait tout : admission acceptée, créneaux choisis, elle voit ses classes.
2. Quand la classe de l'élève est complète et qu'**il ne reste que l'affectation de l'enseignant**, l'application affiche « Dernière étape : payer » et envoie l'avis (`classe_validee` / `tout_est_pret`, à compléter).
3. Le paiement est dû **avant le début des cours**. La porte `acces_paye` ferme l'entrée en séance tant que rien n'est payé, sauf prix spécial, exonération ou report.
4. Les gestes de la direction ouvrent la porte ; « demander maintenant » avance l'avis.

Aucune nouvelle table : « jamais payé » se déduit de l'absence d'un crédit confirmé et d'une exonération.

### 4.5 Les taxes et la devise

| Point | Règle |
|---|---|
| Prix | 55 $ / 65 $ hors taxes ; aucune taxe écrite dans la base ni dans Flutter |
| Taxe | Calculée par **Stripe Tax** à l'achat : `automatic_tax: { enabled: true }`, `tax_behavior: 'exclusive'` sur chaque ligne, adresse du payeur recueillie par Stripe. **Réglages du tableau de bord Stripe par le directeur** : activer Stripe Tax, pays d'enregistrement |
| Devise | USD (politique). Pour afficher euro, livre, dollar canadien : prix locaux de Stripe, ou changer la phrase du site. Décision du directeur |
| Contrôle serveur | `recharge_evenement_stripe` exige que le montant payé soit celui de la commande : avec une taxe, ce contrôle échouerait. À corriger : comparer le **hors taxes** au montant de la commande (lot P2). À confirmer en lisant la fonction avant d'écrire |

### 4.6 Textes à montrer à la famille (à valider ; voir `.claude/skills/mots-rewayah`)

Tous lus de la politique (nombre de jours, prix) ; jamais écrits en dur.

**Pourquoi payer avant les cours** (écran « Dernière étape », courriel d'avis)
> Votre famille a tout préparé : vos classes sont prêtes. Il ne reste que l'affectation de l'enseignant. Pour réserver sa place, nous vous demandons de payer avant le début des cours. Nous recevons beaucoup de faux comptes et de demandes sans suite, et nous ne pouvons pas engager un enseignant pour un compte qui n'était là que par curiosité. Payer maintenant nous montre que vous êtes sérieux, et la place est gardée pour votre enfant.

**Les 14 jours** (sous le bouton « Payer », page de paiement, courriel)
> Vous pouvez arrêter dans les {14} jours qui suivent votre paiement. Si le cours ne vous convient pas, nous vous remboursons le reste du mois, moins les séances déjà suivies. Texte complet : « Annulation et remboursement ».

**Prix**
> {55 $} par mois, hors taxes. La taxe de votre pays est calculée par notre prestataire de paiement au moment où vous payez, et vous la voyez avant de confirmer.

**Prix spécial et exonération (famille concernée)**
> La direction a fixé votre prix à {prix} par mois. / La direction a offert l'accès jusqu'au {date}.

**Blocage (existant, à vérifier au mot près)**
> Les séances reprennent dès que le paiement est reçu. Votre espace reste ouvert pour voir votre profil, votre historique et payer.

## 5. Écarts sur la règle des 14 jours

| Source | Dit | Écart |
|---|---|---|
| Directeur, 23/11 | Annulation dans les 14 jours ; si l'élève n'est pas satisfait, remboursé du reste du mois | |
| `DECISION-TARIFS`, 02/11 | Payé moins séances suivies ; ensuite arrêter est un droit, mois commencés au prix normal, le reste rendu | Concorde |
| Code `fn115c_montant_propose` | Même règle, délai lu de la politique (14 en v2.1.0) | Concorde ; jamais joué |
| `A-HARMONISER`, 07/11 | Mois réservé non remboursable ; arrêt temporaire effectif le mois suivant | **Contredit** le 02/11 |
| Pause : préavis de 7 jours (`20261123910000_calendrier_pauses.sql`) | | À rapprocher de l'arrêt temporaire du 07/11 |
| Site `pages.json` | Arrêter dans les 14 jours qui suivent le paiement : remboursé, moins les séances suivies | Concorde ; promet aussi taxes et devises que le code ne tient pas |
| Site, même page | « Le remboursement se fait dans les 14 jours qui suivent votre demande » | Deux délais de 14 jours différents : à dire clairement |

## 6. Décisions qui restent au directeur

| # | Question | Proposition |
|---|---|---|
| D1 | **Règle de remboursement unique** : après les 14 jours, le mois commencé est-il rendu (02/11, code) ou non remboursable (07/11) ? | 14 jours = payé moins séances suivies ; après, mois commencé dû, mois futurs d'une formule d'avance rendus |
| D2 | Départ des 14 jours | Premier paiement confirmé par Stripe |
| D3 | **Stripe Tax** : l'activer, et dans quels pays | Activer ; réglages Stripe par le directeur |
| D4 | **Devise** : USD seul (corriger le site) ou prix locaux | USD seul au début, corriger la phrase du site |
| D5 | **Premier cours sans paiement** : refusé ? | Oui, sauf exonération ou report |
| D6 | Délai pour payer après « classe prête » | À fixer (par exemple 5 jours, avec rappels) |
| D7 | « Demander maintenant » : un appel serveur fin qui enveloppe l'existant | Oui, sans table |
| D8 | « Reporter » : par « accès offert jusqu'au… », ou un état dédié | Contournement |
| D9 | Espace du comptable (encaissements, paiements des familles) | Retirer |
| D10 | Forme du formulaire Stripe à garder | Celle que le directeur aura éprouvée (à tester en P1) |
| D11 | Reçu | Reçu Stripe + page « Paiements » |
| D12 | Textes du §4.6 | À relire |

## 7. Plan de lots (petits, ordonnés)

Une étape, une pull request. La preuve finale est celle du directeur en production.

| Lot | Contenu | Touche | Preuve attendue |
|---|---|---|---|
| **P0** | Ce document validé ; D1 à D12 écrites dans `DECISION-TARIFS` et `A-HARMONISER` ; correction de la phrase « 7 jours » | Docs seules | Décisions datées |
| **P1** | **Preuve du circuit réel sans rien changer** : un vrai paiement de 1 $, puis son remboursement, par le directeur | Rien | `commandes_recharge` `completed`, écriture `wallet_entries`, `remboursements_demandes` soldée ; courriels reçus |
| **P2** | **Stripe Tax** : `automatic_tax` et `tax_behavior` ; le webhook accepte le total taxes comprises ; phrase devise du site ou prix locaux | `_shared/stripe.ts`, `recharge-payer`, `stripe-webhook`, une migration (contrôle de montant), tests Deno | Paiement de test avec taxe visible ; test Deno vert |
| **P3** | **Une seule forme de formulaire** ; une seule clé d'idempotence | `_shared/stripe.ts`, `recharge-payer`, `core/finance/formulaire_stripe*.dart` | Paiement de bout en bout ; `verifier_branchement` vert |
| **P4** | **Porte « payé » avec le premier paiement** : `private.acces_paye` dit « jamais payé » ; textes du blocage | Migration (corps d'une fonction) | Scénario SQL : sans paiement refusé, exonéré admis ; compte d'essai du directeur |
| **P5** | **Gestes sur la fiche élève** : section « Paiement », quatre gestes ; « demander maintenant » ; « reporter » = accès offert jusqu'à une date | `fiche_eleve_direction_page.dart`, réutilise `tarifs_particuliers.dart` et `remboursement_direction.dart`, au plus une migration sans table | Captures à 1280 et 1440 ; scénarios SQL ; le directeur exonère, fixe un prix, demande un paiement sur un compte d'essai |
| **P6** | **Le moment et les textes** : étape « Dernière étape : payer » dans la frise, avis `classe_validee` / `tout_est_pret`, courriel d'acceptation (fr, en, ar), page de paiement avec le « pourquoi » et les 14 jours | frise d'inscription, `modeles_*.ts`, `assets/i18n/*.json` | Écrans et courriels rendus ; relecture du directeur |
| **P7** | **Une seule page « Paiements » de la famille** ; « Payer » à la place de « Recharger » ; reçu Stripe | `compte/paiements_page`, `mon_espace_adulte/mes_finances_page`, `foyer/finances_foyer`, textes | Les trois entrées ouvrent la même page ; test d'écran |
| **P8** | **Ménage** : retirer l'espace du comptable (si D9), les formulaires retirés, les textes caducs ; mettre à jour le registre | `comptable/encaissements`, `paiements_familles`, `tool/branchement_tolere.txt` | `dart analyze`, `verifier_branchement` verts |
| **P9** | Une famille test traverse tout : acceptation, classes, paiement, premier cours, remboursement | Rien | Parcours prouvé par le directeur |

Ordre : P0, P1 (en parallèle des décisions), puis P2 à P9. Aucun lot n'écrit en production sans le feu vert de `supabase/CLAUDE.md`.

## 8. Ce qui n'a pas été vérifié

- Aucun vrai paiement n'a été tenté : « jamais abouti » est lu dans la base, la cause n'est pas établie (clé Stripe, mode, ou abandon des familles).
- Les clés Stripe et le mode ne sont pas lus (pas d'accès aux secrets). Les 32 commandes sont en environnement `live`.
- `portEncaissementsProvider` : absence d'adaptateur déduite de la liste de `core/capacites/`, pas d'une exécution.
- Le calcul exact du prorata du premier mois et le contrôle de montant de `recharge_evenement_stripe` n'ont pas été rejoués ni relus en base.
