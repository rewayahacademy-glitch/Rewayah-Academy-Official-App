# Proposition : harmoniser l'argent, la suppression et l'arrêt (lot HARMONISER-ARGENT, phase 1)

Agent G, 07/11/2026, branche `claude/harmoniser-argent`. **Proposition, pas une décision.** Rien n'est
codé, aucune migration, aucune écriture sur Supabase. Dette d'origine :
`A-HARMONISER-REGLES-ARGENT-ET-ARRET.md` (branche `claude/vigilant-pascal-utfgbs`, PR 263, pas encore sur
`main` au moment du relevé).

## 0. D'abord ce qui est faux, inconnu ou non prouvé

1. **Faux aujourd'hui, en production : les 14 jours s'appliquent à CHAQUE paiement, pas aux seuls
   nouveaux inscrits.** `private.fn115c_montant_propose` compte le délai depuis chaque paiement
   (`20261105100000_fn115c_rembourser.sql` l. 140-150), et tous les textes disent « dans les 14 jours qui
   suivent le paiement ». Une famille inscrite depuis un an qui paie son mois le 1er peut se faire
   rembourser ce mois jusqu'au 15, moins les séances suivies. Cela contredit la règle 2 du 07/11.
2. **Faux : « l'abonnement s'arrête à tout moment » n'a aucune porte.** Les conditions le promettent ;
   aucune fonction ne permet à une famille d'arrêter. La facture du mois suivant part tant que l'élève
   est membre d'une classe (`private.fac_adhesion`). Seule la direction retire un élève d'une classe.
3. **Inexistant : l'arrêt temporaire.** Ni table, ni fonction, ni écran, ni texte. La « pause » du code
   est celle de la séance (`CONTRAT_PORT_PAUSE_SEANCE.md`), autre chose.
4. **Inconnu : ce que devient l'argent d'un enfant supprimé.** `private.suppr_retirer` ne touche à aucune
   ligne d'argent. Le crédit non consommé reste au solde d'un profil supprimé, sans règle ; une facture
   du mois suivant déjà émise reste « à financer » sans fin.
5. **Non prouvé : aucune trace trouvée de l'acceptation des conditions par une famille**, ni de sa
   demande expresse de commencer les cours pendant le délai de rétractation. Recherche faite sur les
   noms usuels (`conditions_accept`, `acceptation_conditions`, `terms_accepted`…), pas exhaustive. Le
   seul contrat signé et versionné est celui de l'enseignant (`0086_signature_contrat_versionnee.sql`,
   `teacher_nda`). Sans cette trace, « la part déjà suivie reste due » est fragile en droit (point 5.1).
6. **Périmé dans un document :** `DECISION-TARIFS-2026-10-18.md` dit « en production, la politique en
   vigueur porte encore 7 ». Lecture de production du 07/11 (lecture seule) : `v2.1.0`, date d'effet
   03/11, `remboursement_delai_jours = 14`, en vigueur. `v1.0.0` et `v2.0.0` gardent 7 : un paiement des
   1er et 2 novembre garde 7 jours.
7. **Non prouvé en production :** l'appel au vrai Stripe pour un remboursement (déjà écrit dans
   `DECISION-TARIFS`, FN-115c).

## 1. Les mots du directeur (07/11/2026, mot pour mot)

« on ne peut pas supprimer un enfant n'importe quand, s'il a réservé une place pour un mois alors
l'argent n'est plus remboursable, les nouveaux inscrits ont les 14 jours selon la loi... il faut aussi
permettre aux tuteurs/élèves de demander un arrêt temporaire là aussi si le mois est commencé alors ce
sera au prochain moi que l'arrêt pourra être effectif. toutes ces règles devront être harmonisées après
car il y'a eu trop de bricolage, alors tu le mentionnes où on ne l'oubliera jamais. »

## 2. Inventaire de l'existant (relevé dans le dépôt et, pour la politique, en production)

### 2.1 Remboursements FN-115

| Où | Ce que ça dit | Contredit le 07/11 ? |
| :-- | :-- | :-- |
| `DECISION-TARIFS-2026-10-18.md`, section du 01/11, points 1 à 7 | Mois remboursé = accès coupé tout de suite ; partiel : séances non suivies ; formule d'avance : mois commencés au prix normal, reste rendu ; contestation ; d'où part le remboursement (écran Finance) | Non, sauf ci-dessous |
| idem, décision du 02/11 | 14 jours « à compter du paiement » : payé moins séances suivies ; ensuite, arrêter une formule d'avance reste un droit ; délai lu dans la politique | **Oui** : « à compter du paiement » pour tout paiement, et non « nouveaux inscrits » |
| `20261105100000_fn115c_rembourser.sql`, `private.fn115c_montant_propose` l. 94-186 | Délai compté depuis **chaque** paiement (l. 140) ; dans le délai : payé − séances suivies × (mensuel / 13) (l. 142-150) ; hors délai, formule d'avance : payé − mois commencés × mensuel (l. 151-163) ; hors délai, mois simple : 0 (l. 164-167) | **Oui** pour le point de départ ; le reste est conforme |
| idem, `remboursement_confirmer` l. 265-311 | Direction seule, plafonné au montant proposé, idempotent | Non |
| idem, `remboursement_eleves_remboursables` l. 237-256 | Bouton « Rembourser » si le serveur trouve un montant > 0 | Non |
| `20261106100000_remb14_delai_public.sql` | Délai publié dans `tarifs_publics()` (`remboursementDelaiJours`) ; version `v2.1.0` à 14 jours | Non |
| Production, `politiques_commerciales` (lu le 07/11) | v1.0.0 : 7 j ; v2.0.0 (01/11) : 7 j ; v2.1.0 (03/11) : 14 j, en vigueur | Non |
| `20261104400000_remboursements_litiges_stripe.sql` (`remboursement_evenement_stripe`, `fac_rendre_commande`, `fac_rouvrir_si_negatif`) | Remboursement ou contestation Stripe : solde négatif → factures repassent « à financer », accès suspendu tout de suite | Non |
| Fonction Edge `remboursement-stripe` | Rembourse chez Stripe avec la clé `remboursement-<demande>` | Non |

### 2.2 Suppression d'un profil d'enfant

| Où | Ce que ça dit | Contredit le 07/11 ? |
| :-- | :-- | :-- |
| `20261108600000_supprimer_comptes.sql`, `public.tuteur_supprimer_profil_enfant` l. 248-286 | Un tuteur, compte valide, supprime un élève **mineur** de son foyer, **à tout moment**, sans aucune condition d'argent | **Oui** (règles 1 et 3) |
| `20261108900000_supprimer_bis_restaurer.sql`, `private.suppr_retirer` l. 54-143 | Retrait immédiat : quitte ses classes (`left_at` maintenant), profil désactivé, compte banni, anonymisation à l'échéance ; refuse seulement : introuvable, déjà retiré, soi-même, compte de direction, enseignant avec séances à venir. **Aucune ligne d'argent touchée** | **Oui** : rien ne dit ce que devient le mois payé ni le crédit restant |
| `20261110340000_mineur_fantome.sql` l. 255-290 (retouche par ancre, présente en production) | À la suppression, les demandes ouvertes (horaires, intentions, présentation, créneau personnalisé) sont closes « profil supprimé » | Non |
| `app_config` `compte.anonymisation_delai_jours` = 30 (`20261108600000` l. 50) | Anonymisation 30 jours après un retrait | Hors argent ; voir 3.7 |
| `lib/features/foyer/supprimer_profil_eleve.dart` ; `assets/i18n/fr.i18n.json` l. 1754-1770 (`ficheEleve.supprimer`) | Confirmation par saisie du prénom ; conséquence : « ne peut plus se connecter… quitte ses classes… Les factures et les paiements sont conservés. » Rien sur le remboursement ni sur le mois payé | **Oui** (règle 3 : l'écran doit le dire avant la confirmation) |
| `20261018150000_cpt_suppression_export.sql` : `demander_suppression_compte`, `traiter_demande_suppression` | Autre chemin : suppression **de son propre compte** avec délai de réflexion `compte.suppression_delai_jours` = 14 ; `ma_situation_suppression` signale un solde à régler, sans bloquer | Pas d'argent non plus ; à aligner (3.6) |

### 2.3 Factures mensuelles, allocations de recharge, crédit du foyer

| Où | Ce que ça dit | Contredit le 07/11 ? |
| :-- | :-- | :-- |
| `20261017171000_fac_b_01_factures_mensuelles.sql`, `private.fac_adhesion` l. 170-185 | Un élève est facturé pour un mois s'il est membre d'une classe ce mois (`left_at` nul ou ≥ 1er du mois) | Pas de place pour un arrêt |
| idem, `private.fac_emettre_facture` l. 323-363 | Une facture par élève et par mois, figée une fois émise ; refusée si profil supprimé | Non |
| `20261102600000_b4_factures_et_relances_planifiees.sql`, `private.fac_emission_planifiee` | Le mois **suivant** est émis dès J-7 (`jours_relance`), le mois courant du 1er à la veille de la suspension | À prendre en compte pour l'arrêt (5.4) |
| `20261018170000_fac_f_relances_suspension.sql`, `private.fac_traiter_relances` l. 252-313 | Relances et suspension sur toute facture « à financer », **sans filtrer un profil supprimé** ; les destinataires, eux, sont filtrés (`fac_destinataires_paiement` l. 100-118) : pas d'e-mail, mais des lignes de relance et de suspension pour un profil supprimé | Dette (3.5) |
| `factures_mensuelles.statut` admet `annulee` (l. 49) | **Aucune fonction n'annule une facture mensuelle** (recherche de `statut = 'annulee'` et `motif_annulation =` : aucun résultat pour cette table) | Il faudra une annulation encadrée (6) |
| `private.fac_portefeuille`, `fac_solde_profil`, `fac_financer_profil` ; `commandes_recharge_allocations` | Portefeuille par foyer et devise ; solde tenu **par profil** ; un paiement est réparti par profil (allocation) ; une facture se finance en une fois par un débit du profil | Le crédit d'un profil supprimé n'a pas de sort (0.4) |

### 2.4 Contrat, conditions, pages juridiques, site public

| Où | Ce que ça dit | Contredit le 07/11 ? |
| :-- | :-- | :-- |
| `fr.i18n.json` l. 13037-13038 `juridique.valeurs.confirmationConseil` | « vous pouvez annuler dans un délai de {jours} jours à compter du paiement… la part déjà suivie reste due » | **Oui** : tout paiement, pas l'inscription |
| l. 13040 `confirmationConseilSansDuree` | idem sans nombre | **Oui** |
| l. 13041 `remboursementModalites` | Remboursement sur le moyen de paiement, sous 14 jours après la demande | Non (délai de versement, autre chose) |
| l. 13109 `juridique.conditions.s4.blocs[3]` | « Pendant le délai de rétractation, qui court à partir du paiement… » | **Oui** |
| l. 13146-13147 `juridique.annulation.s1` | Payé moins séances suivies dans le délai ; « Après ce délai, le mois commencé est dû » | Point de départ : **oui** ; « mois commencé dû » : conforme |
| l. 13153 `annulation.s2.blocs[0]` | « L'abonnement mensuel s'arrête à tout moment… prend fin à la fin du mois en cours » | Conforme à l'esprit de la règle 4, **mais aucune porte** (0.2) ; ne parle pas d'un arrêt temporaire |
| l. 13154 `annulation.s2.blocs[1]` | Formule d'avance : mois commencés au prix normal, reste rendu | À accorder avec la règle 1 (5.3) |
| l. 13155 `annulation.s2.blocs[2]` | Inscription en cours de mois : séances restantes seulement | Non |
| l. 13161 `annulation.s3.blocs[0]` | Place manquée non remboursée | Non |
| l. 13194 `annulation.s6.blocs[0]` | « Pour arrêter ou demander un remboursement, écrivez-nous » | Seule porte réelle d'arrêt aujourd'hui |
| l. 13034 `juridique.valeurs.dureesConservation` | « délai de réflexion de 14 jours » avant effacement | Cohérent avec `compte.suppression_delai_jours`, **pas** avec le retrait par le tuteur (30 j, immédiat) (3.7) |
| `assets/i18n/ar.i18n.json` | Mêmes clés en arabe | Mêmes contradictions |
| `site-public/content/pages.json` l. 438, 2131, 2170 | « arrêter dans les 14 jours qui suivent le paiement » | **Oui** |
| idem l. 439 | « L'abonnement se renouvelle chaque mois et se résilie chaque mois » | Pas de porte (0.2) |
| idem l. 2184-2240 (`/fr/legal/annulation-remboursement`, version 2026-11-v2) | Copie des sections s1 à s5 et litige de l'application | Mêmes points |
| `docs/current/tarifs-2026-10-18.json` | Règles publiques reprises par le site | À relire en phase 2 avec le reste |
| `0086_signature_contrat_versionnee.sql` | Seul contrat signé : enseignant (`teacher_nda`) | Aucune signature famille (0.5) |

### 2.5 Arrêt, pause, suspension

| Où | Ce que ça dit |
| :-- | :-- |
| `acces_suspensions_paiement`, `fac_eleve_suspendu`, `fac_retablir_acces` (`20261018170000`) | Suspension **pour impayé** (le 4), place gardée jusqu'au 15, libérée le 16. Pas un arrêt voulu |
| Suspension pour contestation (`20261104400000`) | Idem, subie |
| `CONTRAT_PORT_PAUSE_SEANCE.md` | Pause **pendant** une séance. Hors sujet |
| Arrêt temporaire voulu par la famille | **N'existe nulle part** (recherche `arrêt temporaire`, `pause … abonnement`, `résili…`, `désinscri…` dans `lib/`, `assets/i18n`, `supabase/migrations`, `docs/current`, `site-public`) |
| Retrait d'un élève d'une classe | Seulement par la direction (`0017` l. 298, `0019` l. 195, `20261017110100` l. 208, `20261016100100` l. 293) ou par suppression du profil |

## 3. Les contradictions, chacune avec son endroit

1. **Point de départ des 14 jours.** Règle du 07/11 : nouveaux inscrits. Code : chaque paiement
   (`fn115c_montant_propose` l. 140-150). Textes : « à compter du paiement » (`fr.i18n.json` l. 13037,
   13038, 13040, 13109 ; `ar.i18n.json` mêmes clés ; `site-public/content/pages.json` l. 438, 2131, 2170,
   2191-2193 ; `DECISION-TARIFS` décision du 02/11 et résumé « Remises »).
2. **Suppression sans règle d'argent.** `tuteur_supprimer_profil_enfant` et `suppr_retirer` : à tout
   moment, rien sur le mois payé ni le crédit. Écran `ficheEleve.supprimer.consequence` (l. 1759) muet.
3. **Formule d'avance et « mois réservé non remboursable ».** Le 02/11 : mois commencés dus, le reste
   rendu. Le 07/11 : un mois réservé n'est plus remboursable. Les deux tiennent ensemble si « réservé »
   veut dire « mois commencé ou mois dont la facture est payée » ; à dire en clair (5.3).
4. **« Arrêter à tout moment » sans porte.** `annulation.s2.blocs[0]` (l. 13153), site l. 439 et 2200 ;
   aucune fonction serveur ; seule voie : écrire à la direction (l. 13194).
5. **Facture d'un profil supprimé.** Une facture du mois suivant émise (J-7) puis profil supprimé reste
   « à financer » ; `fac_traiter_relances` crée relances et suspension sans destinataire.
6. **Deux suppressions, deux délais.** Compte propre : demande, 14 jours de réflexion
   (`compte.suppression_delai_jours`). Profil d'enfant par le tuteur : immédiat, anonymisé à 30 jours
   (`compte.anonymisation_delai_jours`). Le texte de confidentialité (l. 13034) ne décrit que le premier.
7. **Aucune trace d'accord de la famille.** Pas de signature des conditions ni de demande expresse de
   commencer pendant le délai (0.5).
8. **Document périmé.** `DECISION-TARIFS` dit 7 jours en production ; c'est 14 depuis le 03/11 (0.6).

## 4. Proposition de décision unique (à faire valider par le directeur)

**Nom proposé : `DECISION-ARGENT-ARRET-SUPPRESSION-2026-11-xx.md`**, qui remplace les règles éparses
ci-dessus et que `DECISION-TARIFS` renvoie.

1. **Mois réservé = mois dû.** Un mois est réservé dès que sa facture est payée (financée) **ou** que le
   mois a commencé. L'argent d'un mois réservé ne se rembourse pas, ni par suppression, ni par arrêt,
   ni par demande. Seules exceptions : le délai légal (règle 2), une séance annulée par l'académie et
   non remplacée, une classe qui n'ouvre pas, une contestation perdue (règles déjà en place).
2. **Délai légal de 14 jours pour un nouvel inscrit.** Le délai court une fois par élève, à son
   **premier paiement** (proposition, voir 5.1). Pendant ce délai : remboursement de ce qui a été payé,
   moins les séances suivies (calcul actuel de FN-115c, inchangé). Un renouvellement ne rouvre pas de
   délai. La durée reste `remboursement_delai_jours` de la politique (rien en dur).
3. **Suppression d'un profil encadrée.** Le tuteur peut toujours supprimer (c'est son droit sur les
   données), mais l'écran dit avant la confirmation, chiffres lus sur le serveur : ce qui est remboursé
   (délai légal en cours) ou non (mois réservé), et ce que devient le crédit restant. La suppression
   d'un mois réservé n'est pas bloquée : elle ne rembourse pas. **Le crédit non engagé** (qui ne paie
   aucun mois réservé) reste à la famille : proposition 5.5.
4. **Arrêt temporaire.** Un tuteur, ou un élève adulte pour lui-même, demande un arrêt depuis
   l'application, pour un ou plusieurs mois entiers. Il prend effet au **1er du mois suivant** ; le mois
   en cours reste dû et la place est tenue jusqu'à sa fin. Pendant l'arrêt : aucune facture, aucun
   accès aux séances ni aux ressources, l'espace reste ouvert. La place n'est pas gardée pendant
   l'arrêt (proposition 5.6) ; au retour, l'élève reprend une classe de son niveau.
5. **Arrêt définitif (résiliation).** Même porte, même date d'effet (1er du mois suivant), sans date de
   retour. C'est la porte que les conditions promettent déjà (l. 13153).
6. **Formule payée d'avance.** Inchangée du 02/11 : arrêter reste un droit, mois commencés au prix
   mensuel normal sans la remise, reste rendu. Avec la règle 1, le mois courant est compté commencé.
   Un arrêt temporaire d'une formule d'avance reporte les mois non commencés (5.3).

## 5. Les questions qui relèvent du droit ou de l'argent (au directeur, une seule fois, groupées)

Chaque question porte la recommandation de l'agent. Arbitrage C3 des consignes : engagement juridique
→ question obligatoire au directeur.

1. **Point de départ des 14 jours.** La loi européenne (directive 2011/83/UE, art. 9) et la loi
   britannique (Consumer Contracts Regulations 2013) comptent 14 jours **à partir de la conclusion du
   contrat** de service, pas du paiement. **Recommandation :** le premier paiement d'un élève, puisque
   « on paie avant de commencer » : contrat et paiement tombent le même jour. Un seul délai par élève ;
   les renouvellements n'en ouvrent pas. À faire relire par un conseil (déjà prévu,
   `juridique.quoi.confirmationConseil`).
2. **Ce qui est remboursé pendant le délai.** **Recommandation :** garder la règle du 02/11 (payé moins
   séances suivies), **à condition** de recueillir, avant le premier paiement, la demande expresse de
   commencer pendant le délai et la reconnaissance de la perte du droit pour la part suivie (case à
   cocher horodatée et versionnée). Sans elle, la loi peut obliger à tout rembourser.
3. **« Mois réservé » : commencé, ou payé ?** **Recommandation :** payé **ou** commencé (règle 4.1). Un
   mois suivant payé d'avance le 26 n'est plus remboursable, sauf délai légal d'un nouvel inscrit.
   Alternative plus douce : réservé seulement le jour où le mois commence.
4. **Demande d'arrêt après l'émission de la facture du mois suivant (J-7, vers le 24).**
   **Recommandation :** jusqu'à la veille du 1er, l'arrêt vaut pour le mois suivant ; si sa facture est
   émise et **non payée**, elle est annulée par le serveur ; si elle est **payée**, le mois est réservé
   (5.3) et l'arrêt prend effet le mois d'après.
5. **Crédit restant d'un profil supprimé ou arrêté.** **Recommandation :** il reste au foyer : versé au
   solde d'un autre élève du foyer s'il en a, sinon remboursé sur demande, sans frais pour l'académie.
6. **Place pendant un arrêt temporaire.** **Recommandation :** non gardée (une classe de 3 à 6 ne peut
   pas payer une place vide) ; durée maximale d'un arrêt réglable par la direction (proposé : 3 mois),
   au-delà l'arrêt devient définitif.
7. **Arrêt temporaire d'une formule d'avance.** **Recommandation :** les mois non commencés sont
   reportés après le retour, sans perte de la remise ; si l'arrêt devient définitif, règle 4.6.
8. **Suppression d'un profil d'élève adulte ou du compte propre.** Même règle d'argent que pour un
   enfant (proposé), par les deux chemins de suppression.

## 6. Ce que la phase 2 devra coder

**Serveur (migrations, aucun calcul d'argent dans Flutter) :**
- `fn115c_montant_propose` : délai compté depuis le **premier paiement de l'élève** (5.1), pas depuis
  chaque paiement ; scénario SQL qui prouve qu'un renouvellement hors délai rend 0.
- Une table d'arrêts (`arrets_eleve` : élève, demandé par, type temporaire ou définitif, effet le,
  retour prévu le, état), RLS ; RPC `demander_arret(eleve, type, mois)` (tuteur pour un mineur de son
  foyer, élève adulte pour lui-même), `annuler_arret`, et la lecture pour la direction.
- `fac_adhesion` ou `fac_emettre_facture` : aucune facture pour un mois couvert par un arrêt.
- Une annulation de facture mensuelle encadrée (aujourd'hui inexistante) : facture non payée d'un mois
  arrêté ou d'un profil supprimé → `annulee`, motif écrit ; jamais une facture payée.
- `fac_traiter_relances` : ignorer un profil supprimé ou arrêté (3.5).
- Une RPC de lecture « ce que coûte la suppression » (mois réservé, montant remboursable, crédit
  restant) appelée par l'écran avant la confirmation ; `tuteur_supprimer_profil_enfant` applique le
  sort du crédit (5.5) dans la même transaction.
- L'accès coupé pendant l'arrêt (même porte que la suspension, cause « arrêt »).
- Les réglages de la direction : durée maximale d'un arrêt (5.6) ; le délai reste celui de la politique.
- Si 5.2 est retenu : la trace horodatée et versionnée de l'accord de la famille avant le premier paiement.

**Écrans :**
- Fiche d'un élève (foyer) : « Demander un arrêt » (temporaire ou définitif), date d'effet lue du
  serveur ; état de l'arrêt et bouton d'annulation tant qu'il n'a pas pris effet. Pareil pour l'élève
  adulte dans son espace.
- Confirmation de suppression (`supprimer_profil_eleve.dart`) : la phrase d'argent lue du serveur avant
  la saisie du prénom.
- Paiement (`recharge_foyer.dart`) : la case d'accord (5.2) avant le premier paiement.
- Finance (direction) : la liste des arrêts ; « Rembourser » suit la nouvelle règle sans autre changement.

**Textes (fr, ar, site public, avec la compétence `mots-rewayah`) :**
- `juridique.valeurs.confirmationConseil*`, `juridique.conditions.s4`, `juridique.annulation.s1`, `s2`
  (arrêt temporaire, arrêt définitif, mois réservé), `s6` (la porte n'est plus « écrivez-nous »),
  `juridique.valeurs.dureesConservation` (les deux suppressions), `ficheEleve.supprimer.consequence`.
- `site-public/content/pages.json` (l. 438-441, 2131-2132, 2170, 2184-2240) et
  `docs/current/tarifs-2026-10-18.json` : zone protégée, à confier à qui tient `site-public/`.
- `DECISION-TARIFS-2026-10-18.md` : renvoi vers la décision unique ; corriger « en production porte
  encore 7 » (c'est 14 depuis le 03/11).
- Fermer `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md` seulement quand la décision unique est datée par le
  directeur et que la phase 2 est en production.
