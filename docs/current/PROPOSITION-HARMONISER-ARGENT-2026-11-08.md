# Proposition : harmoniser l'argent, la suppression et l'arrêt (HARMONISER-ARGENT)

B, 08/11/2026, à la demande du pilote. **Proposition, pas une décision** : aucune règle n'est
décidée ici, rien n'est codé. Le directeur répond par A ou B à chaque question ; sa réponse, datée,
deviendra la décision unique qui ferme `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`.

Sources : `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md` (mots du directeur, 07/11),
`DECISION-TARIFS-2026-10-18.md` (décisions des 01/11 et 02/11), et le relevé de la phase 1
(`PROPOSITION-HARMONISER-ARGENT-2026-11-07.md`, branche `claude/harmoniser-argent`), revérifié sur
`main` 225a957d le 08/11 : aucune migration depuis le 07/11 ne change l'argent, la suppression ou
l'arrêt.

## D'abord : ce qui est faux, inconnu ou non prouvé

- **Faux en production** : le délai de 14 jours s'ouvre à **chaque** paiement, pas aux seuls
  nouveaux inscrits (contradiction 1).
- **Faux** : les conditions promettent « l'abonnement s'arrête à tout moment », et aucune porte ne
  le permet ; seule voie : écrire à la direction (contradiction 4).
- **Inexistant** : l'arrêt temporaire décidé le 07/11 (contradiction 5).
- **Inconnu** : ce que devient le crédit d'un profil supprimé (contradiction 7).
- **Correction du relevé de la phase 1** : les familles acceptent bien des conditions, versionnées
  et horodatées (`contract_acceptances`, sorte `guardian_terms`). Ce qui manque, c'est la demande
  expresse de commencer pendant le délai (contradiction 9).
- **Non relu aujourd'hui** : la politique en vigueur en production (`v2.1.0`, 14 jours depuis le
  03/11) est le relevé de la phase 1, du 07/11.

## Les contradictions (une ligne chacune)

| N° | Ce que dit la règle | Ce que fait le code aujourd'hui | Où |
| :-: | :-- | :-- | :-- |
| 1 | 14 jours de rétractation pour les **nouveaux inscrits** (07/11) | Le délai court depuis **chaque paiement** ; les textes disent « à compter du paiement » | `private.fn115c_montant_propose` (20261105100000, l. 140-150) ; `juridique.valeurs.confirmationConseil`, `juridique.conditions.s4`, `juridique.annulation.s1` (fr, ar) ; site public |
| 2 | On ne supprime pas un enfant « n'importe quand » ; un mois réservé n'est plus remboursable | Le tuteur supprime un profil d'enfant à tout moment ; aucune ligne d'argent n'est touchée ; l'écran ne parle pas d'argent | `tuteur_supprimer_profil_enfant` (20261108600000), `private.suppr_retirer` (20261108900000) ; `ficheEleve.supprimer.consequence` |
| 3 | « Mois réservé non remboursable » (07/11) | Le 02/11 : une formule payée d'avance rend le reste, les mois commencés au prix normal. Les deux tiennent seulement si « réservé » est défini | `fn115c_montant_propose` l. 151-163 ; `juridique.annulation.s2` |
| 4 | « L'abonnement s'arrête à tout moment » (conditions publiées) | Aucune fonction ne permet à une famille d'arrêter ; la facture du mois suivant part tant que l'élève est dans une classe | `private.fac_adhesion` (20261017171000) ; `juridique.annulation.s2.blocs.0`, `s6` |
| 5 | Arrêt temporaire, effectif le mois suivant si le mois est commencé (07/11) | N'existe nulle part (ni table, ni fonction, ni écran, ni texte) | (aucun) |
| 6 | (aucune règle) | La facture du mois suivant, émise à J-7, reste « à financer » après la suppression du profil ; relances et suspension sont créées sans destinataire ; aucune fonction n'annule une facture mensuelle | `private.fac_traiter_relances` (20261018170000) ; `factures_mensuelles.statut` |
| 7 | (aucune règle) | Le crédit d'un profil supprimé reste sur son solde, sans sort | `private.fac_solde_profil`, allocations de recharge |
| 8 | (aucune règle commune) | Deux suppressions, deux délais : son propre compte (14 jours de réflexion) ; profil d'enfant par le tuteur (immédiat, anonymisé à 30 jours). La page de confidentialité ne décrit que le premier | `compte.suppression_delai_jours`, `compte.anonymisation_delai_jours` ; `juridique.valeurs.dureesConservation` |
| 9 | « La part déjà suivie reste due » pendant le délai (02/11) | Les conditions sont acceptées, mais la famille ne demande nulle part, expressément, à commencer pendant le délai : sans cette demande, la loi peut obliger à tout rembourser | `contract_acceptances` (`guardian_terms`) ; aucun champ de demande expresse |
| 10 | (aucun) | `DECISION-TARIFS` dit encore « en production, la politique porte 7 jours » ; c'est 14 depuis le 03/11 (relevé du 07/11) | `DECISION-TARIFS-2026-10-18.md`, FN-115c |

## Les questions (réponse A ou B)

Chaque question porte ma recommandation et sa raison. Les questions 1, 2 et 5 engagent le droit :
la relecture par un conseil, déjà prévue (`juridique.quoi.confirmationConseil`), vaut pour elles.

**Q1. D'où partent les 14 jours ?** (contradiction 1)
- **A. Du premier paiement de l'élève, une seule fois par élève.** Un renouvellement n'ouvre pas de
  nouveau délai. *Recommandé* : c'est la règle du 07/11 (« les nouveaux inscrits »). La loi compte
  14 jours depuis la conclusion du contrat, et chez nous on paie avant de commencer : les deux tombent
  le même jour.
- B. De chaque paiement, comme aujourd'hui.

**Q2. Pendant le délai, que rembourse-t-on ?** (contradiction 9)
- **A. Le payé moins les séances suivies, avec une case à cocher avant le premier paiement** :
  « Je demande que les cours commencent pendant le délai de rétractation ; la part suivie restera
  due ». Elle est horodatée et versionnée, comme les conditions. *Recommandé* : sans cette demande
  expresse, garder la part suivie est fragile en droit.
- B. Le payé moins les séances suivies, sans case (comme aujourd'hui).

**Q3. Quand un mois devient-il « réservé », donc non remboursable ?** (contradictions 2 et 3)
- **A. Dès que sa facture est payée, ou dès que le mois commence.** *Recommandé* : un mois suivant
  payé d'avance le 26 tient déjà la place. Seules exceptions : le délai légal d'un nouvel inscrit, une
  séance annulée par l'académie et non remplacée, une classe qui n'ouvre pas, une contestation perdue
  (règles déjà en place).
- B. Seulement le jour où le mois commence.

**Q4. Supprimer le profil d'un élève pendant un mois réservé** (contradiction 2)
- **A. Toujours possible, mais sans remboursement du mois réservé.** Avant la confirmation, l'écran
  le dit avec les chiffres lus sur le serveur : ce qui est remboursé, ce qui ne l'est pas, ce que
  devient le crédit. *Recommandé* : c'est « encadré » sans retenir les données d'un enfant contre de
  l'argent. Le droit d'effacer des données personnelles ne se monnaie pas, et la règle d'argent
  s'applique de toute façon.
- B. Bloquée jusqu'à la fin du mois réservé.

**Q5. Le crédit restant d'un profil supprimé ou arrêté** (contradiction 7)
- **A. Il reste au foyer.** Il est versé au solde d'un autre élève du foyer s'il y en a un, sinon
  remboursé sur demande, sans frais pour l'académie. *Recommandé* : l'argent non engagé appartient à
  la famille, et le geste reste simple pour la direction.
- B. Remboursé automatiquement sur le moyen de paiement, à la suppression.

**Q6. La facture du mois suivant, émise mais pas encore payée, quand le profil est supprimé ou que
l'arrêt est demandé** (contradiction 6)
- **A. Le serveur l'annule, avec le motif écrit.** Une facture payée n'est jamais annulée (Q3).
  *Recommandé* : sinon elle reste « à financer » sans fin et crée des relances sans destinataire.
- B. Elle reste due.

**Q7. L'arrêt temporaire : la place est-elle gardée ?** (contradiction 5)
- **A. Non. Une durée maximale, réglée par la direction (3 mois proposés) ; au-delà, l'arrêt devient
  définitif.** Au retour, l'élève reprend une classe de son niveau. *Recommandé* : une classe de 3 à
  6 élèves ne peut pas porter une place vide.
- B. Oui, la place est gardée pendant l'arrêt.

Dans tous les cas, par la décision du 07/11 : un tuteur, ou un élève adulte pour lui-même, le
demande ; si le mois est commencé, l'arrêt prend effet le mois suivant ; le mois en cours reste dû et
la place tenue jusqu'à sa fin.

**Q8. L'arrêt temporaire d'une formule payée d'avance** (trimestre, année)
- **A. Les mois non commencés sont reportés après le retour, sans perte de la remise.** Si l'arrêt
  devient définitif, la règle du 02/11 s'applique : mois commencés au prix normal, le reste rendu.
  *Recommandé* : la famille ne perd ni son argent ni sa remise.
- B. Pas d'arrêt temporaire pour une formule payée d'avance : seulement l'arrêt définitif et la
  règle du 02/11.

**Q9. L'arrêt définitif** (contradiction 4)
- **A. Dans l'application, la même porte que l'arrêt temporaire**, effet au 1er du mois suivant, sans
  date de retour. *Recommandé* : c'est ce que les conditions promettent déjà.
- B. Garder la seule voie actuelle : écrire à la direction.

**Q10. Les deux suppressions** (contradiction 8)
- **A. La même règle d'argent pour les deux.** Chacune garde son délai (14 jours de réflexion pour son
  propre compte ; retrait immédiat, anonymisé à 30 jours, pour un profil d'enfant), et la page de
  confidentialité les décrit toutes deux. *Recommandé* : les deux délais protègent des choses
  différentes ; seuls l'argent et le texte doivent s'accorder.
- B. Un seul délai pour les deux.

**Q11. Le mot visible pour l'arrêt temporaire**
- **A. « Demander une pause »**, en mois entiers. *Recommandé* : c'est le mot déjà décidé dans le
  vocabulaire de l'application (`mots-rewayah` : « demander une pause d'un mois », jamais « geler »
  ni « suspendre l'abonnement »).
- B. « Arrêt temporaire », le mot du directeur du 07/11.

## Ce que la réponse déclenchera (pour mémoire, pas dans ce document)

La décision datée, puis le lot HARMONISER-ARGENT phase 2, dernier dans la file (directeur,
07/11) :
- le serveur : délai, mois réservé, suppression, crédit, annulation de facture, table et
  fonctions de l'arrêt, relances ;
- les écrans : suppression, arrêt, case de Q2 ;
- les textes, en fr et ar, et le site public par qui le tient ;
- la correction de `DECISION-TARIFS` (contradiction 10).

Le détail technique est déjà écrit dans la section 6 de la phase 1.
