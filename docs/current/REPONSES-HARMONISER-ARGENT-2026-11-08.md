# Réponses retrouvées : harmoniser l'argent, la suppression et l'arrêt (HARMONISER-ARGENT)

Document rédigé par B le 08/11/2026, sur ordre du directeur relayé par le pilote à 02:12. Le
directeur ne répond plus aux questions d'argent : il y a déjà répondu, et ses réponses sont
écrites. Ce document ne pose donc **aucune question**. Il fait trois choses :

- pour chaque point, il cite la réponse déjà donnée (fichier, date, phrase exacte) ;
- quand deux réponses se contredisent, la plus récente datée l'emporte ;
- quand un point reste sensible ou n'a pas de réponse, il ne le transforme pas en question. Il le
  pose en **réglage de l'administration**, avec pour valeur par défaut la dernière réponse datée
  (consigne A5 « ne rien coder en dur » et A13 « jouer le comptable ou l'avocat dans l'intérêt de
  tous », `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`).

Il remplace la proposition à questions A/B du même jour, retirée. Il ne décide rien de neuf et
rien n'est codé. Il sert de base au lot HARMONISER-ARGENT phase 2, dernier dans la file (directeur,
07/11), qui fermera `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`.

## D'abord : ce qui est faux, inconnu ou non prouvé

- **Faux en production : le délai de 14 jours s'ouvre à chaque paiement.** La dernière réponse
  datée le réserve aux nouveaux inscrits (07/11) ; voir le point 1.
- **Faux : les conditions publiées promettent l'arrêt « à tout moment ».** Aucune porte de
  l'application ne le permet ; voir le point 9.
- **Inexistants dans le code** : la pause d'un mois (décidée le 30/09) et l'arrêt temporaire
  (07/11), qui sont la même chose (point 7).
- **Un seul point n'a aucune réponse écrite** : la pause d'une formule payée d'avance (point 8).
  Il devient un réglage, et sa valeur par défaut est **déduite** de la règle du 30/09, pas citée.
- **Les prix des sources des 30/09 et 02/10 sont caducs** : 50 et 60 USD, remplacés par 55 et 65 le
  18/10. Seules leurs règles sans prix sont citées ici.
- **Statut des sources, à garder en tête** :
  - les décisions du 30/09 (Stratégie V3) sont « arrêtées sur mandat du directeur » ;
  - le Guide Finance V4 (02/10) se présente comme « décision produit » ;
  - les textes juridiques du 18/10 ont été publiés sous l'autorisation du directeur du 18/10, mais
    aucun ne porte une phrase du directeur mot pour mot.
- **Non relue aujourd'hui** : la politique en vigueur en production (`v2.1.0`, 14 jours depuis le
  03/11). Le chiffre vient du relevé de la phase 1, du 07/11.

## Les réponses, point par point

### 1. D'où partent les 14 jours de rétractation ?

- **Ce qui a été dit** :
  - 18/10, conditions publiées (`docs/orchestration/site-public/juridique-2026-10-18.json`) :
    « vous pouvez annuler dans les 14 jours qui suivent votre inscription » ;
  - 02/11, directeur (`DECISION-TARIFS-2026-10-18.md`) : « 14 jours à compter du paiement » ;
  - 07/11, directeur, mot pour mot (`A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) : « les nouveaux
    inscrits ont les 14 jours selon la loi ».
- **Ce qui l'emporte (07/11)** : le délai vaut pour les **nouveaux inscrits seulement**. Il part
  du paiement (02/11), donc du **premier paiement de l'élève**, une seule fois par élève. Un
  renouvellement n'ouvre pas de nouveau délai.
- **Ce qui change** : `private.fn115c_montant_propose` (l. 140-150) et les textes « à compter du
  paiement », en fr et en ar, et sur le site public.
- **Réglage, déjà en place** : `remboursement_delai_jours` de la politique publiée, à 14.

### 2. Pendant le délai, que rembourse-t-on ?

- **Ce qui a été dit** :
  - 02/11, directeur (`DECISION-TARIFS-2026-10-18.md`) : « la famille est remboursée de ce qu'elle
    a payé, moins les séances déjà suivies » ;
  - 18/10, conditions publiées : « Si les cours ont commencé **à votre demande** pendant ce délai,
    la part déjà suivie reste due ».
- **Ce qui l'emporte** : le payé moins les séances suivies, au prix d'une séance tiré de la
  politique, comme aujourd'hui.
- **Ce qui manque, sans nouvelle décision** : la « demande » du texte du 18/10 n'est enregistrée
  nulle part. Le lot ajoute une case à cocher avant le premier paiement, horodatée et versionnée
  comme les conditions. Ce n'est pas une règle nouvelle : c'est la mise en œuvre du texte déjà
  publié.

### 3. Quand un mois devient-il « réservé », donc non remboursable ?

- **Ce qui a été dit** :
  - 02/10, Guide Finance V4, FIN4-03 : « Le produit vendu est un accès mensuel à une classe » ;
  - FIN4-04 : « Une absence ordinaire de l'élève ne diminue pas le montant d'une période déjà
    financée » ;
  - 02/11, directeur : une formule payée d'avance « est remboursée du reste, une fois les mois
    commencés comptés au prix mensuel normal » ;
  - 07/11, directeur : « s'il a réservé une place pour un mois alors l'argent n'est plus
    remboursable ».
- **Ce qui l'emporte (07/11, accordé au 02/11)** : un mois est réservé dès que sa place est payée,
  donc dès que **la facture de ce mois est payée**, ou dès que le mois commence. Les deux règles
  tiennent ensemble : le 07/11 vise un mois réservé ; le 02/11 vise les mois **non commencés**
  d'une formule payée d'avance, dont le reste est rendu.
- **Exceptions déjà en place, inchangées** :
  - le délai légal d'un nouvel inscrit (point 1) ;
  - une séance annulée par l'académie et non remplacée ;
  - une classe qui n'ouvre pas ;
  - une contestation perdue.
- **Réglage** : aucun ; c'est une règle de droit, pas un nombre.

### 4. Supprimer le profil d'un élève pendant un mois réservé

- **Ce qui a été dit** : 07/11, directeur, mot pour mot (`A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) :
  « on ne peut pas supprimer un enfant n'importe quand, s'il a réservé une place pour un mois alors
  l'argent n'est plus remboursable » ; règle 1 : « Supprimer le profil ne rembourse pas ce mois » ;
  règle 3 : « Pas de suppression "n'importe quand" [...] l'écran doit le dire avant la
  confirmation ».
- **Réglage de l'administration** (consigne du directeur du 08/11, 02:12) : moment où la
  suppression d'un profil d'élève prend effet pendant un mois réservé.
  - **Défaut, fidèle à la phrase du 07/11** : pas de suppression effective pendant un mois réservé ;
    la demande est enregistrée et prend effet à la fin de ce mois. Le mois réservé n'est pas
    remboursé.
  - Avant la confirmation, l'écran dit, avec les chiffres lus sur le serveur, la date d'effet, ce
    qui n'est pas remboursé et ce que devient le solde (point 5).
- **Point de droit à faire relire, non tranché ici** : le droit d'effacement des données d'un
  enfant (demande d'effacement d'un tuteur) face à une suppression différée à la fin du mois. La
  relecture par un conseil, déjà prévue (`juridique.quoi.confirmationConseil`), le couvre.

### 5. Le solde restant d'un profil supprimé ou arrêté

- **Ce qui a été dit** :
  - 02/10, Guide Finance V4, FIN4-06 : « Chaque élève possède un solde individuel » ;
  - FIN4-07 : le total du foyer « n'est jamais un portefeuille partagé » ;
  - 02/11, directeur : « arrêter reste un droit, jamais un geste », et « le reste [est] rendu » ;
  - 02/11, FN-115c : le remboursement part de l'écran Finance ; le serveur propose le montant, la
    direction confirme.
- **Ce qui l'emporte** : le solde non engagé est **rendu**, par le circuit de remboursement
  existant. Il n'est **pas** versé au solde d'un autre élève du foyer, ce que FIN4-07 interdit. Ma
  proposition de transfert du 08/11 est donc retirée.

### 6. La facture du mois suivant, émise mais pas encore payée, à la suppression ou à l'arrêt

- **Ce qui a été dit** : 02/10, Guide Finance V4 §1.7 : « aucune dette mensuelle n'est empilée
  indéfiniment après fin réelle de l'inscription ».
- **Ce qui l'emporte** : le serveur **annule** cette facture, avec le motif écrit. Les relances et
  la suspension qui en découlent s'arrêtent. Une facture payée n'est jamais annulée (point 3).

### 7. L'arrêt temporaire : préavis, durée, place

- **Ce qui a été dit** :
  - 30/09, Stratégie V3, ABS-01 : « Pause personnelle gratuite : mois civil complet annoncé au
    moins 7 jours avant son début » ;
  - 30/09, paramètres de lancement : « Pause personnelle | mois complet, préavis 7 jours |
    Directeur pour règle ; famille pour sa demande » ;
  - 30/09, Plan V3 (`05_PLAN_IMPLEMENTATION_APP_V3_2026-09-30.md`) : « pause mensuelle gratuite,
    préavis, impact sur le foyer, **retour non garanti** » ;
  - 14/10 (`programme-rewayah`, `REGISTRE-RECONCILIATION-2026-10-14.md`) : « le tuteur, ou
    l'élève adulte, demande dans l'application une pause d'un mois civil complet, au moins 7 jours
    avant. Ce mois n'est pas facturé, et la date limite recule d'autant. Il n'y a pas de pause de
    quelques jours » ;
  - 07/11, directeur : « permettre aux tuteurs/élèves de demander un arrêt temporaire [...] si le
    mois est commencé alors ce sera au prochain mois que l'arrêt pourra être effectif ».
- **Ce qui l'emporte** : l'arrêt temporaire du 07/11 est la pause d'un mois du 30/09. Le 07/11 ne
  la contredit pas, il en précise l'effet :
  - le tuteur, ou l'élève adulte pour lui-même, la demande dans l'application ;
  - elle porte sur des mois civils entiers, non facturés ; la date limite du programme recule
    d'autant ;
  - si le mois est commencé, elle prend effet au mois suivant ; le mois en cours reste dû et la
    place tenue jusqu'à sa fin ;
  - la demande arrive au moins 7 jours avant le mois visé ;
  - la place n'est pas gardée (« retour non garanti ») : au retour, l'élève reprend une classe de
    son niveau, sans frais.
- **Réglages** :
  - préavis : défaut 7 jours (30/09) ;
  - durée maximale d'une pause : défaut 1 mois civil (30/09 et 14/10 : « une pause d'un mois »).

### 8. La pause d'une formule payée d'avance (trimestre, année)

- **Ce qui a été dit** : rien sur ce cas précis.
- **Réglage** : défaut, les mois de pause **sont reportés** après le retour, sans perte de la remise.
  Cette valeur est **déduite**, pas citée : le 30/09 dit que le mois de pause « n'est pas facturé »,
  et pour une formule déjà payée, ne pas facturer ce mois revient à le reporter. Si la pause devient
  un arrêt définitif, la règle du 02/11 s'applique : mois commencés au prix normal, le reste rendu.

### 9. L'arrêt définitif

- **Ce qui a été dit** :
  - 18/10, document du directeur (`sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md`) :
    « **Résiliation libre.** Le mensuel s'arrête à tout moment pour la fin du mois en cours, sans
    justification » ;
  - 18/10, conditions publiées, section « Arrêter l'abonnement » : « L'abonnement mensuel
    s'arrête à tout moment, sans justification. Il prend fin à la fin du mois en cours » ;
  - 02/11, directeur : « arrêter reste un droit, jamais un geste ».
- **Ce qui l'emporte** : la famille arrête **elle-même dans l'application**, avec la même porte que
  la pause, sans date de retour. L'arrêt prend effet à la fin du mois en cours. La voie « écrire à
  la direction » ne suffit pas : un droit ne passe pas par un geste de la direction.

### 10. Les deux suppressions

- **Ce qui a été dit** :
  - 18/10, migration `20261018150000_cpt_suppression_export.sql` : `compte.suppression_delai_jours`
    vaut 14 par défaut, un réglage de la direction ;
  - migration `20261108600000_supprimer_comptes.sql` : `compte.anonymisation_delai_jours` vaut 30
    par défaut ;
  - 07/11, règle 1 : la règle d'argent vise la suppression d'un profil d'élève.
- **Ce qui l'emporte** : **la même règle d'argent pour les deux suppressions** (points 3 à 6).
  Chacune garde son délai :
  - son propre compte : 14 jours de réflexion ;
  - le profil d'un enfant : retrait immédiat, anonymisé à 30 jours.

  Les deux délais protègent des choses différentes. La page de confidentialité décrit les deux.
- **Réglages, déjà en place** : `compte.suppression_delai_jours` (14),
  `compte.anonymisation_delai_jours` (30).

### 11. Le mot visible

- **Ce qui a été dit** : `mots-rewayah` §3, vocabulaire décidé (du 30/09, ABS-01, et du 14/10) :
  « demander une pause d'un mois » ; jamais « geler », jamais « suspendre l'abonnement ».
  L'« arrêt temporaire » du 07/11 vient de la phrase du directeur et ne décide pas d'un mot.
- **Ce qui l'emporte** : « Demander une pause », en mois entiers. L'arrêt définitif se dit
  « Arrêter l'abonnement », le titre des conditions du 18/10.

## Les réglages de l'administration (récapitulatif)

| Réglage | Défaut | Source du défaut | Existe déjà ? |
| :-- | :-- | :-- | :-- |
| Délai de rétractation, en jours (nouveaux inscrits) | 14 | 02/11 et 07/11 | Oui : `remboursement_delai_jours` (politique) |
| Séances par mois, pour le prix d'une séance suivie | 13 | 18/10, barème | Oui : `seances_par_mois` (politique) |
| Préavis d'une pause, en jours | 7 | 30/09, ABS-01 | Non : à créer |
| Durée maximale d'une pause, en mois civils | 1 | 30/09 et 14/10 | Non : à créer |
| Pause d'une formule payée d'avance | mois reportés, remise gardée | Déduit du 30/09 (« non facturé ») | Non : à créer |
| Effet de la suppression d'un profil d'élève pendant un mois réservé | à la fin de ce mois, sans remboursement | 07/11 (« on ne peut pas supprimer un enfant n'importe quand ») | Non : à créer |
| Délai de suppression de son propre compte, en jours | 14 | 18/10 | Oui : `compte.suppression_delai_jours` |
| Délai d'anonymisation d'un profil retiré, en jours | 30 | migration `20261108600000_supprimer_comptes.sql` | Oui : `compte.anonymisation_delai_jours` |

Les règles de droit (points 1 à 3, 5, 6, 9 et 10) ne sont pas des réglages : ce sont des réponses
datées. Elles ne bougent que sur une nouvelle décision datée du directeur.

## Ce que le lot HARMONISER-ARGENT phase 2 en tirera (pour mémoire)

- **Serveur** :
  - le délai réservé au premier paiement d'un élève ;
  - le mois réservé ;
  - la suppression d'un profil prenant effet à la fin du mois réservé (réglage), sans remboursement ;
  - le solde rendu ;
  - l'annulation de la facture non payée ;
  - la table et les fonctions de la pause et de l'arrêt ;
  - l'arrêt des relances ;
  - les quatre réglages nouveaux.
- **Écrans** : la suppression (date d'effet et chiffres avant la confirmation), « Demander une pause »,
  « Arrêter l'abonnement », la case de demande expresse avant le premier paiement.
- **Textes** : en fr et en ar, et le site public par qui le tient.
- **Correction de `DECISION-TARIFS-2026-10-18.md`** : il dit encore « en production, la politique
  porte 7 jours » ; c'est 14 depuis le 03/11.

Le relevé technique (fonctions, migrations, écrans touchés) est dans la section 6 de la phase 1,
branche `claude/harmoniser-argent`.
