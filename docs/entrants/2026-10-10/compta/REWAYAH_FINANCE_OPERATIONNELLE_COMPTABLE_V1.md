# REWAYAH - FINANCE OPÉRATIONNELLE & RÔLE COMPTABLE V1

**Version :** V1  
**Date :** 4 octobre 2026  
**Statut :** SPÉCIFICATION FRONTEND DE RÉFÉRENCE  
**Phase projet :** FRONTEND ONLY  
**Rôle principal :** Comptable  
**Rôles connexes :** Direction / Admin, Enseignant, Contractuel, Tuteur, Élève adulte  
**Agent d’implémentation :** Claude Code  
**Plateformes :** Flutter Android, iOS, Web/Desktop  

---

# 0. OBJET DU DOCUMENT

Ce document remplace la définition trop étroite :

> « Le Comptable lit les mêmes pages Finance que la Direction avec des permissions adaptées. »

Cette définition reste vraie pour les données canoniques partagées, mais elle est insuffisante pour l’exploitation quotidienne.

Le rôle Comptable devient un **véritable bureau de Finance opérationnelle** permettant de :

- suivre les encaissements ;
- rapprocher les transactions ;
- suivre la trésorerie ;
- gérer les coffres d’allocation interne ;
- maintenir une **Réserve stratégique** ;
- préparer et exécuter les paiements normaux dus aux enseignants ;
- préparer et exécuter les paiements dus aux contractuels ;
- payer un bénéficiaire seul ou un lot de bénéficiaires ;
- suivre les payouts en cours, réussis ou échoués ;
- traiter les informations de paiement manquantes ;
- relancer le bénéficiaire depuis le système Communications existant ;
- traiter les échéances ;
- suivre les remboursements et avoirs ;
- consulter les métriques financières nécessaires au fonctionnement quotidien ;
- déléguer suffisamment pour soulager la Direction sans ouvrir une brèche de sécurité.

L’objectif produit est :

> **L’opérateur Finance travaille dans Rewayah. Il ne doit pas devoir ouvrir Stripe, Verto, pawaPay, Wise ou un autre dashboard prestataire pour accomplir une opération financière ordinaire lorsque l’API du prestataire permet cette opération.**

Le prestataire financier transporte réellement l’argent.  
Rewayah orchestre, contrôle, autorise, déclenche et rapproche.

---

# 1. FRONTIÈRE DE CETTE VAGUE

## 1.1 FRONTEND ONLY

Cette vague ne donne aucune autorisation pour :

- migration de base ;
- modification Supabase ;
- RLS ;
- RPC ;
- nouvelle table ;
- webhook ;
- stockage de secrets ;
- intégration serveur Stripe ;
- intégration serveur Verto ;
- intégration serveur pawaPay ;
- intégration Wise ;
- exécution réelle de payout ;
- modification d’un rail bancaire ;
- modification fiscale ;
- conservation réelle de coordonnées bancaires.

Claude prépare :

- interfaces ;
- composants ;
- navigation ;
- view models ;
- ports abstraits ;
- fixtures ;
- états ;
- permissions frontend ;
- recettes ;
- contrats attendus du futur backend.

Toute action financière réelle doit rester derrière un port neutre.

## 1.2 Fournisseurs

Aucun fournisseur n’est codé comme obligatoire.

L’interface doit fonctionner avec un modèle générique :

`FinanceProvider`

Exemples possibles selon futurs contrats :

- Stripe ;
- Verto ;
- pawaPay ;
- compte bancaire ;
- Mobile Money ;
- autre fournisseur approuvé.

Un fournisseur non réellement activé ne doit jamais apparaître comme opérationnel en production.

---

# 2. AUTORITÉ DES SOURCES

Ordre d’autorité :

1. décisions explicites du Directeur dans la présente vague ;
2. sécurité et permissions déjà prouvées dans le dépôt ;
3. ce document ;
4. high-fi Finance/Comptable ;
5. Bible Frontend Rewayah ;
6. design system gelé ;
7. composants existants ;
8. specs Finance antérieures compatibles ;
9. aucune invention silencieuse.

---

# 3. RÈGLE SPÉCIALE SUR LES HIGH-FI

## 3.1 Les high-fi Finance générées ne sont pas homogènes

Le générateur visuel a produit plusieurs variantes incompatibles :

- certaines planches sont dark intégral ;
- d’autres sont light ;
- certaines affichent une sidebar noire et un contenu blanc ;
- certaines reprennent des styles non utilisés ailleurs dans Rewayah ;
- certaines compositions sont bonnes alors que leur palette est mauvaise.

**Claude ne doit PAS recopier ces incohérences.**

## 3.2 Autorité visuelle

Les high-fi font autorité pour :

- intention fonctionnelle ;
- hiérarchie des informations ;
- densité ;
- placement relatif ;
- structure des tableaux ;
- présence des actions ;
- relation entre liste / détail / contexte ;
- composition mobile versus desktop.

Elles ne font pas autorité pour une couleur, un shell ou un style qui contredit Rewayah.

## 3.3 Harmonisation obligatoire

Claude doit harmoniser l’ensemble Finance/Comptable avec :

- les tokens gelés ;
- le thème réellement utilisé dans l’application ;
- les composants existants ;
- DM Sans pour les titres ;
- Plus Jakarta Sans pour le reste ;
- cartes groupées existantes ;
- navigation réelle du rôle ;
- light/dark existants ;
- accessibilité existante.

**Référence visuelle prioritaire : la première high-fi Finance dark intégrale produite pour le rôle Comptable.**

Interdit :

- inventer un thème Finance spécifique ;
- utiliser vert/bleu comme nouvelle identité ;
- juxtaposer sidebar noire + contenu blanc si ce pattern n’existe pas dans l’app ;
- dupliquer des composants financiers déjà existants ;
- créer un style “banque” différent du produit Rewayah.

---

# 4. DEVOIR DE REGARD DE CLAUDE

Claude n’est pas un copieur passif.

Avant toute mutation, Claude a le devoir de vérifier :

- cohérence produit ;
- cohérence financière ;
- métriques ;
- navigation ;
- architecture ;
- permissions ;
- anti-fraude ;
- anti-doublon ;
- responsive ;
- accessibilité ;
- conformité au dépôt ;
- composants déjà existants ;
- compatibilité avec Finance foyer, Finance enseignant et Finance Direction.

Si Claude découvre :

- une métrique inutile ;
- une métrique manquante ;
- deux métriques qui disent la même chose ;
- une action placée au mauvais endroit ;
- une action risquée ;
- une permission trop large ;
- une architecture qui crée un doublon ;
- un parcours qui surcharge inutilement la Direction ;
- une incapacité à expliquer un montant ;
- un cas de fraude possible ;
- une contradiction entre high-fi et dépôt ;
- une meilleure manière de présenter ou structurer l’information ;

Claude doit :

1. arrêter uniquement le sous-lot concerné ;
2. documenter le constat ;
3. proposer l’option qu’il considère la plus bénéfique à l’application et à l’Académie ;
4. expliquer coût, bénéfice et risque ;
5. ne pas modifier silencieusement la règle métier ;
6. continuer les parties indépendantes non bloquées.

Format obligatoire :

`DEVOIR_DE_REGARD_FINANCE.md`

Rubriques :

- constat ;
- preuve ;
- risque ;
- proposition ;
- alternative ;
- impact UX ;
- impact sécurité ;
- impact futur backend ;
- décision requise ou non.

Claude est explicitement autorisé à dire :

> « La maquette est moins bonne que le composant existant sur ce point. »

ou :

> « Cette métrique n’aide pas l’opérateur et devrait être remplacée par X. »

Mais il n’est pas autorisé à modifier une règle commerciale, salariale ou de sécurité sans validation.

---

# 5. PRINCIPES PRODUIT

## 5.1 Une fonction = un endroit

Aucun écran Finance concurrent.

Les raccourcis ouvrent toujours l’écran canonique.

## 5.2 Calculer d’abord, payer ensuite

Le Comptable ne saisit pas la rémunération d’un enseignant au moment de payer.

L’application calcule l’obligation.

Le Comptable exécute l’obligation.

## 5.3 Pas de faux succès

Un paiement est :

- préparé ;
- soumis ;
- en transit ;
- confirmé ;
- échoué ;
- annulé ;
- remboursé ;

selon le retour réel du futur port.

Jamais `Payé` simplement parce qu’un bouton a été pressé.

## 5.4 Délégation contrôlée

Le Comptable doit pouvoir exécuter la majorité des opérations standards sans intervention quotidienne du Directeur.

La sécurité repose sur :

- règles ;
- limites ;
- exceptions ;
- séparation des tâches ;

pas sur une validation humaine systématique de chaque paiement.

---

# 6. ARCHITECTURE GÉNÉRALE

```text
FINANCE
|
|-- Aujourd’hui
|   |-- métriques utiles
|   |-- actions à traiter
|   |-- échéances
|   |-- alertes
|   `-- activité récente
|
|-- Paiements à effectuer
|   |-- enseignants
|   |-- contractuels
|   |-- lots
|   |-- détail obligation
|   `-- payout
|
|-- Encaissements
|   |-- paiements familles
|   |-- remboursements
|   |-- litiges
|   |-- échecs
|   `-- rapprochement
|
|-- Trésorerie & coffres
|   |-- fonds clients engagés
|   |-- paie à décaisser
|   |-- charges essentielles
|   |-- taxes & obligations
|   |-- réserve stratégique
|   |-- en transit
|   `-- trésorerie libre
|
|-- Bénéficiaires
|   |-- enseignants
|   |-- contractuels
|   |-- état du profil de paiement
|   `-- historique
|
|-- Contractuels
|   |-- récurrents
|   |-- obligations ponctuelles
|   |-- justificatifs
|   `-- échéances
|
|-- Rapprochement
|   |-- rapproché
|   |-- non rapproché
|   |-- anomalie
|   `-- preuve
|
`-- Rapports
```

---

# 7. MASQUAGE DES MONTANTS

## 7.1 Composant canonique

Nom :

`SensitiveAmount`

Tous les montants sensibles Finance doivent pouvoir être masqués.

Exemple :

`Taxes & obligations    $•• •••,••`

ou selon la longueur :

`$••••••,••`

Ne jamais remplacer par une longueur variable qui révèle involontairement l’ordre de grandeur.

## 7.2 Contrôle global

Composant :

`FinanceAmountVisibilityToggle`

Libellés :

- `Afficher les montants`
- `Masquer les montants`

Le contrôle agit sur l’ensemble de la surface Finance courante.

## 7.3 Règle de session

À l’ouverture d’une nouvelle session Finance :

**montants masqués par défaut**.

La révélation :

- reste locale à la session ;
- n’est pas conservée après déconnexion ;
- ne modifie aucune permission.

## 7.4 Contrôle local

Un œil local peut être utilisé sur certaines cartes si utile.

Il ne doit pas créer un état incohérent avec le contrôle global.

## 7.5 Confirmation de payout

Au moment de confirmer un paiement réel :

le montant exact doit être affiché explicitement.

On ne confirme jamais :

`Payer $••••••`

La confirmation affiche :

- bénéficiaire ;
- montant exact ;
- devise ;
- destination masquée ;
- provider/rail ;
- éventuels frais connus ;
- total envoyé.

---

# 8. COFFRES DE TRÉSORERIE

Les coffres représentent des allocations de trésorerie Rewayah.

Ils ne prétendent pas nécessairement correspondre à des comptes bancaires physiques séparés.

Ils doivent néanmoins être **exécutoires dans la logique Rewayah** : une somme protégée n’est pas considérée libre.

## 8.1 Coffres canoniques

### Fonds clients engagés

Argent encaissé mais lié à des prestations ou obligations clients non complètement acquises.

### Paie à décaisser

Obligations de rémunération déjà calculées et dues.

### Charges essentielles

Infrastructure, abonnements indispensables, fonctions fixes et dépenses classées essentielles.

### Taxes & obligations

Provision dédiée aux obligations fiscales, sociales ou réglementaires enregistrées.

### Réserve stratégique

Coffre de continuité et de sécurité.

### En transit

Argent déjà engagé dans une opération mais non confirmé.

### Trésorerie libre

Montant réellement disponible après allocations protégées et obligations.

---

# 9. RÉSERVE STRATÉGIQUE

## 9.1 Nom

Le produit utilise :

**Réserve stratégique**

Interdit comme titre permanent :

`Réserve 3 mois`

Trois mois n’est qu’un exemple de politique courante.

## 9.2 Objectif dynamique

L’Admin / Direction définit la politique.

Deux modes minimum :

### Mode A - Montant cible fixe

Exemples :

- 10 USD ;
- 5 000 USD ;
- 1 000 000 USD.

Aucune hypothèse de montant.

### Mode B - Couverture dynamique

Exemple :

`3 mois de charges essentielles`

Le nombre de mois est configurable.

Il peut devenir :

- 1 mois ;
- 2 mois ;
- 3 mois ;
- 6 mois ;
- 12 mois ;
- autre valeur autorisée.

L’UI affiche :

`Objectif actuel : 3 mois de charges essentielles`

mais le titre reste :

**Réserve stratégique**

## 9.3 Règle d’alimentation automatique

La Direction peut définir une règle d’alimentation.

Modes frontend à prévoir :

- désactivée ;
- montant fixe ;
- pourcentage ;
- compléter jusqu’à l’objectif ;
- proposition automatique à confirmer.

Exemple montant fixe :

`Affecter automatiquement 1 000 USD`

Le montant peut être :

- 10 USD ;
- 1 000 USD ;
- 1 000 000 USD ;

selon la configuration.

Ne pas hardcoder une plage commerciale.

La future validation serveur décidera des limites réelles.

## 9.4 Cadence

Le frontend doit pouvoir représenter :

- à chaque cycle de clôture ;
- hebdomadaire ;
- mensuel ;
- déclenchement après encaissement consolidé ;
- manuel.

La cadence exacte dépendra du futur contrat.

## 9.5 Alimenter versus retirer

### Alimenter

Une alimentation conforme à la politique peut être exécutée par le Comptable selon sa délégation.

### Retirer

Sortir de l’argent de la Réserve stratégique est une opération sensible.

Par défaut :

`Validation supplémentaire requise`

## 9.6 Changement de politique

Modifier :

- l’objectif ;
- le nombre de mois ;
- le montant cible ;
- la règle automatique ;
- la cadence ;
- la priorité ;

est une responsabilité Direction / Admin Finance.

Le Comptable lit la politique et l’exécute.

## 9.7 Indicateurs

Afficher :

- objectif ;
- montant actuel ;
- manque à compléter ;
- pourcentage atteint ;
- mode de calcul ;
- date de dernière allocation ;
- prochaine allocation prévue ;
- statut.

Ne pas afficher obligatoirement `3 mois` si la politique est fixe.

---

# 10. MOUVEMENTS ENTRE COFFRES

## 10.1 Composant

`TreasuryInternalTransfer`

## 10.2 Mouvement entrant vers une protection

Exemple :

`Trésorerie libre → Réserve stratégique`

Peut être délégué au Comptable.

## 10.3 Mouvement sortant d’un coffre protégé

Exemples :

- Réserve stratégique → Libre
- Taxes & obligations → Libre
- Fonds clients engagés → Libre hors règle normale

Doit être traité comme sensible.

## 10.4 Interdictions

Le Comptable ne doit jamais pouvoir :

- vider arbitrairement Fonds clients engagés ;
- utiliser Taxes & obligations pour payer une dépense ordinaire ;
- retirer de la Réserve stratégique sans workflow approprié ;
- modifier une allocation pour masquer un déficit.

---

# 11. TRÉSORERIE RÉELLEMENT LIBRE

Le tableau de bord doit distinguer :

- cash détenu ;
- fonds protégés ;
- fonds clients ;
- obligations ;
- transit ;
- libre.

Ne pas présenter le solde bancaire brut comme argent dépensable.

Composant :

`AvailableTreasurySummary`

Le chiffre `Trésorerie libre` est central.

---

# 12. MÉTRIQUES DU TABLEAU DE BORD

## 12.1 Métriques prioritaires

- Trésorerie détenue
- Trésorerie libre
- Fonds protégés
- Fonds clients engagés
- Paie à décaisser
- Charges essentielles réservées
- Taxes & obligations
- Réserve stratégique
- En transit
- Encaissements période
- Décaissements période
- Revenu acquis
- Remboursements / avoirs dus
- Créances / impayés si disponibles
- Transactions non rapprochées
- Paiements échoués
- Bénéficiaires avec informations manquantes

## 12.2 Métriques non décoratives

Chaque KPI doit répondre à une question opératoire.

Si une métrique n’aide ni à :

- décider ;
- payer ;
- rapprocher ;
- sécuriser ;
- prévoir ;
- détecter ;

Claude doit la challenger dans son devoir de regard.

---

# 13. PAIEMENTS ENSEIGNANTS

## 13.1 Obligation automatique

La rémunération d’un enseignant est calculée depuis les données canoniques.

Le frontend reçoit un objet du type :

`TeacherPayableObligation`

Il contient :

- période ;
- enseignant ;
- détail par Classe ;
- remplacements ;
- bonus approuvés ;
- ajustements approuvés ;
- devise ;
- montant final ;
- statut ;
- preuve / source ;
- méthode de payout ;
- échéance.

## 13.2 Montant immuable dans le paiement

Le Comptable ne modifie pas le montant.

Le champ montant n’est jamais un `TextField`.

## 13.3 Détail explicable

Exemple :

```text
Sayyid Youssouf Diallo

Classe Al-Fajr          100 USD
Classe An-Nour           80 USD
Remplacement             12 USD
Bonus approuvé            20 USD
--------------------------------
Total                    212 USD
```

Chaque ligne possède une source.

## 13.4 Erreur de calcul

Action :

`Signaler un écart`

Le Comptable ne corrige pas 212 en 220.

Le problème est corrigé à la source.

Le moteur recalcule.

---

# 14. PAIEMENT PAR PERSONNE ET EN LOT

## 14.1 Paiement individuel

CTA :

`Payer`

ou :

`Payer maintenant`

## 14.2 Paiement multiple

Sélection par cases.

CTA :

`Payer la sélection`

## 14.3 Paiement de cycle

Le frontend peut offrir :

`Sélectionner tous les paiements prêts`

Pas :

`Payer absolument tout`

Les lignes non prêtes sont exclues.

## 14.4 Agrégation par bénéficiaire

Si un enseignant possède plusieurs Classes :

le paiement final doit pouvoir être consolidé par bénéficiaire.

On évite plusieurs transferts inutiles.

## 14.5 Filtre par Classe

La Classe reste un filtre et un détail analytique.

Elle n’impose pas un payout séparé.

---

# 15. ÉTATS D’UN PAIEMENT SORTANT

Minimum :

- À calculer
- Calculé
- À vérifier
- Infos paiement manquantes
- Vérification paiement requise
- Prêt à payer
- Validation supplémentaire requise
- Soumis
- En transit
- Réussi
- Échoué
- À relancer
- Annulé
- Remboursé / retourné si applicable
- Indisponible

Chaque statut doit être lisible sans couleur.

---

# 16. PROFIL DE PAIEMENT DU BÉNÉFICIAIRE

## 16.1 Principe de propriété

**Une personne modifie ses propres coordonnées financières.**

Personne d’autre ne les modifie.

Ni :

- Comptable ;
- Admin ;
- Direction ;
- contrôleur.

## 16.2 Actions du personnel

Le personnel peut :

- voir un statut ;
- voir une représentation masquée ;
- demander une mise à jour ;
- relancer ;
- suspendre un payout ;
- marquer une méthode comme nécessitant vérification selon capability ;
- constater une indisponibilité.

Il ne peut pas remplacer les coordonnées.

## 16.3 Coordonnées affichées au Comptable

Exemples :

`Orange Money •••• 4423`

`Compte bancaire •••• 8712`

`Wave •••• 6621`

Ne jamais exposer inutilement les données complètes.

## 16.4 Données possibles

Selon corridor :

- titulaire ;
- pays ;
- devise ;
- type ;
- opérateur ;
- numéro masqué ;
- banque ;
- IBAN masqué ;
- compte masqué ;
- SWIFT/BIC masqué ;
- statut vérification ;
- date de dernière modification ;
- méthode préférée.

---

# 17. AUTO-GESTION DES COORDONNÉES

Surface canonique :

`Compte > Paiements > Recevoir mes paiements`

ou route existante équivalente trouvée par Claude.

Le bénéficiaire peut :

- ajouter ;
- remplacer ;
- supprimer ;
- choisir la méthode préférée.

Le personnel ne peut pas utiliser cette surface pour autrui.

---

# 18. BÉNÉFICIAIRE EXTERNE SANS COMPTE

Cas :

contractuel ponctuel sans compte Rewayah.

Le responsable ne saisit toujours pas ses coordonnées à sa place.

Parcours futur :

1. créer obligation ;
2. inviter le bénéficiaire ;
3. le bénéficiaire reçoit un accès sécurisé ;
4. il renseigne lui-même sa méthode ;
5. vérification ;
6. obligation devient prête.

Frontend :

état `Invitation envoyée`.

---

# 19. CHANGEMENT DE COORDONNÉES

Un changement de méthode de paiement est sensible.

États :

- modification demandée ;
- nouvelle méthode en vérification ;
- ancienne méthode inactive ou conservée selon règle ;
- payout suspendu temporairement ;
- méthode vérifiée.

Prévoir futurs mécanismes :

- ré-authentification ;
- MFA ;
- KYC ;
- temporisation anti-fraude.

Ne pas implémenter backend maintenant.

---

# 20. CAS DU COMPTABLE BÉNÉFICIAIRE

Si le Comptable est aussi payé par Rewayah :

il peut modifier ses propres coordonnées dans son espace personnel.

Mais :

**il ne peut pas exécuter son propre payout.**

Statut :

`Traitement par un autre responsable requis`

CTA `Payer` absent pour lui-même.

---

# 21. DÉLÉGATION FINANCIÈRE

## 21.1 Objectif

Soulager la Direction.

## 21.2 `FinanceDelegationPolicy`

La Direction configure une fois ce que le Comptable peut exécuter.

Exemples :

- paiements standards autorisés ;
- plafond par transaction ;
- plafond par lot ;
- remboursement standard autorisé ;
- mouvement vers Réserve stratégique autorisé ;
- retrait Réserve stratégique interdit ;
- premier paiement bénéficiaire nécessite seconde validation ;
- modification récente des coordonnées nécessite seconde validation ;
- auto-payout personnel interdit ;
- montant manuel interdit ;
- politique tarifaire interdite.

## 21.3 Paiement standard

Le Comptable peut payer sans validation quotidienne de l’Admin lorsque :

- montant calculé ;
- méthode vérifiée ;
- bénéficiaire distinct du Comptable ;
- montant dans délégation ;
- corridor valide ;
- fonds suffisants ;
- pas d’alerte forte ;
- pas de duplication ;
- obligation approuvée.

## 21.4 Paiement sensible

Exemples :

- premier paiement ;
- coordonnées récemment modifiées ;
- montant hors seuil ;
- paiement hors cycle ;
- bénéficiaire lié à l’opérateur ;
- fournisseur non disponible ;
- obligation manuelle non approuvée.

UI :

`Validation supplémentaire requise`

---

# 22. CONTRACTUELS

## 22.1 Types

- récurrent ;
- ponctuel.

## 22.2 Obligation récurrente

Si contrat connu :

le système peut calculer.

## 22.3 Obligation ponctuelle

Un montant manuel est possible **à la création de l’obligation**, pas dans le payout.

Champs :

- bénéficiaire ;
- objet ;
- montant ;
- devise ;
- échéance ;
- justificatif ;
- centre de coût ;
- auteur ;
- approbateur si requis ;
- statut.

Après approbation :

montant figé.

## 22.4 Exemple

`Karim Studio - Facture #024 - 350 USD`

Le Comptable voit :

`Payer 350 USD`

Il ne modifie pas 350.

---

# 23. AJUSTEMENTS ENSEIGNANTS

Un bonus ou ajustement est une ligne indépendante.

Exemple :

`Bonus Internet +20 USD`

Il possède :

- motif ;
- source ;
- auteur ;
- validation ;
- date.

Le Comptable n’invente pas cette ligne.

---

# 24. ENCAISSEMENTS

Le Comptable doit suivre les paiements entrants.

## 24.1 États

- En attente
- Confirmé
- Échoué
- Remboursé
- Partiellement remboursé
- Contesté
- Chargeback
- À rapprocher
- Rapproché

## 24.2 Colonnes

- date ;
- famille ;
- profils concernés ;
- montant brut ;
- devise ;
- frais ;
- net ;
- moyen ;
- fournisseur ;
- référence ;
- état ;
- rapprochement.

## 24.3 Confirmation

Un paiement n’est `Confirmé` qu’après confirmation future du provider.

---

# 25. RAPPROCHEMENT

Composant :

`ReconciliationWorkspace`

Objectif :

relier :

- paiement attendu ;
- transaction prestataire ;
- solde / mensualité ;
- frais ;
- remboursement ;
- payout ;
- preuve.

États :

- automatique ;
- à vérifier ;
- rapproché ;
- conflit ;
- sans correspondance ;
- doublon potentiel.

---

# 26. REMBOURSEMENTS ET AVOIRS

Le Comptable voit :

- demande ;
- bénéficiaire ;
- motif ;
- montant ;
- source ;
- état ;
- approbation requise ou non.

Les règles commerciales appartiennent à la politique Finance.

Le Comptable ne les réécrit pas.

---

# 27. COMMUNICATIONS INTÉGRÉES

Aucune nouvelle messagerie Finance.

Réutiliser **Messages métier**.

## 27.1 Infos de paiement manquantes

Le bénéficiaire voit déjà une notice :

`Informations de paiement à compléter`

CTA :

`Configurer mes paiements`

## 27.2 File Comptable

Ligne :

`Infos de paiement manquantes`

CTA :

`Relancer`

## 27.3 `Relancer`

Ouvre ou utilise le fil métier contextuel.

Objet :

`Profil de paiement`

Message modèle :

`Vos informations de paiement doivent être complétées avant votre prochain versement. Vous pouvez les ajouter depuis votre espace personnel.`

## 27.4 Notifications

Automatiques selon futur backend :

- informations manquantes ;
- vérification requise ;
- payout proche ;
- payout échoué ;
- payout confirmé.

---

# 28. ALERTES COMPTABLE

Minimum :

- enseignants à payer ;
- contractuels à échéance ;
- infos paiement manquantes ;
- payout échoué ;
- paiement famille échoué ;
- transaction non rapprochée ;
- remboursement en attente ;
- réserve stratégique sous objectif ;
- solde prestataire insuffisant ;
- méthode modifiée récemment ;
- doublon potentiel ;
- validation supplémentaire requise.

---

# 29. ÉCRAN FIN-CPT-W01 - AUJOURD’HUI

Desktop.

Un seul écran.

Objectif :

répondre à :

`Que dois-je faire maintenant ?`

Zones :

1. résumé trésorerie ;
2. Réserve stratégique ;
3. à traiter aujourd’hui ;
4. échéances ;
5. encaissements récents ;
6. paiements à effectuer ;
7. alertes ;
8. activité récente ;
9. accès rapides.

Ne pas saturer de graphiques.

---

# 30. ÉCRAN FIN-CPT-W02 - PAIEMENTS À EFFECTUER

Table desktop.

Colonnes :

- sélection ;
- bénéficiaire ;
- type ;
- période / objet ;
- montant ;
- destination ;
- échéance ;
- statut ;
- action.

Filtres :

- tous ;
- enseignants ;
- contractuels ;
- prêts ;
- infos manquantes ;
- vérification ;
- validation ;
- en retard ;
- période ;
- Classe si utile.

Actions :

- voir ;
- payer ;
- relancer ;
- payer sélection.

---

# 31. ÉCRAN FIN-CPT-W03 - DÉTAIL BÉNÉFICIAIRE / PAIEMENT

Objectif :

expliquer et exécuter.

Zones :

- identité ;
- statut ;
- total ;
- lignes de calcul ;
- destination masquée ;
- état de vérification ;
- historique ;
- preuve ;
- alertes ;
- `Payer maintenant`.

Encart permanent :

`Le Comptable ne peut modifier ni le montant ni les coordonnées de paiement du bénéficiaire.`

---

# 32. ÉCRAN FIN-CPT-W04 - TRÉSORERIE & COFFRES

Objectif :

comprendre où est affecté l’argent.

Zones :

- total détenu ;
- libre ;
- protégé ;
- transit ;
- liste coffres ;
- Réserve stratégique ;
- transfert interne ;
- historique allocations ;
- prévision.

Action clé :

`Alimenter la Réserve stratégique`

Pas :

`Alimenter la réserve 3 mois`

---

# 33. ÉCRAN FIN-CPT-W05 - ENCAISSEMENTS & RAPPROCHEMENT

Table de transactions.

Filtres :

- tous ;
- confirmés ;
- en attente ;
- échoués ;
- remboursés ;
- contestés ;
- à rapprocher.

Panneau détail :

- brut ;
- frais ;
- net ;
- référence ;
- provider ;
- foyer ;
- affectation ;
- rapprochement.

---

# 34. ÉCRAN FIN-CPT-W06 - CONTRACTUELS & OBLIGATIONS

Zones :

- obligations ;
- à approuver ;
- à payer ;
- historique.

Action :

`Nouvelle obligation`

Cette action n’est disponible qu’aux rôles autorisés.

Le Comptable peut ne pas être autorisé à créer l’obligation selon délégation.

---

# 35. ÉCRAN FIN-CPT-W07 - ÉTAT DU PROFIL DE PAIEMENT

Le Comptable consulte :

- identité ;
- méthode masquée ;
- statut ;
- pays ;
- devise ;
- dernière modification ;
- vérification ;
- capacité de payout ;
- historique paiement.

Aucun bouton :

`Modifier coordonnées`

Actions possibles :

- `Relancer`
- `Demander une mise à jour`
- `Voir le fil`
- `Suspendre le paiement` selon capability.

---

# 36. SURFACES MOBILE

Les mobiles utilisent 2 ou 3 écrans par planche selon complexité.

Pas de dashboard desktop compressé.

## Planche FIN-CPT-M01

3 écrans :

1. Aujourd’hui
2. Paiements
3. Détail paiement

## Planche FIN-CPT-M02

2 ou 3 écrans :

1. Trésorerie & coffres
2. Encaissements / rapprochement
3. Alertes / relances si lisible

Chaque téléphone doit être visible en entier.

---

# 37. ADMIN / DIRECTION - DELTA NÉCESSAIRE

Ne pas créer un second système Finance Direction.

Ajouter aux surfaces Finance Direction existantes :

## `StrategicReservePolicyPanel`

Permet :

- titre Réserve stratégique ;
- type objectif ;
- montant cible ;
- couverture en mois ;
- règle alimentation ;
- montant auto ;
- pourcentage auto ;
- cadence ;
- seuil d’alerte ;
- retrait nécessitant validation.

## `FinanceDelegationPolicyPanel`

Permet :

- pouvoirs Comptable ;
- seuils ;
- exceptions ;
- lots ;
- remboursements ;
- auto-payout interdit ;
- reserve ;
- premier payout ;
- méthode modifiée ;
- opérations sensibles.

---

# 38. BÉNÉFICIAIRE - DELTA NÉCESSAIRE

Enseignant / contractuel avec compte :

surface personnelle :

`Recevoir mes paiements`

États :

- aucun moyen ;
- incomplet ;
- en vérification ;
- vérifié ;
- suspendu ;
- action requise.

Le bénéficiaire agit lui-même.

---

# 39. COMPOSANTS PARTAGÉS

Claude cherche d’abord les composants existants.

Noms fonctionnels :

- `SensitiveAmount`
- `FinanceAmountVisibilityToggle`
- `MoneyAmount`
- `FinancialStatusChip`
- `PaymentMethodRow`
- `BalanceSummary`
- `TreasuryVaultCard`
- `StrategicReserveCard`
- `StrategicReservePolicyPanel`
- `FinanceDelegationPolicyPanel`
- `TreasuryInternalTransfer`
- `PayableObligationRow`
- `PayoutBatchBar`
- `PayoutConfirmationSheet`
- `BeneficiaryPaymentProfileCard`
- `BeneficiaryPaymentSetup`
- `ReconciliationWorkspace`
- `FinanceAttentionQueue`
- `FinanceAlertRow`
- `FinanceProviderStatus`
- `FinanceActivityRow`

Ne pas créer un composant si un équivalent existe.

---

# 40. CONFIRMATION D’UN PAIEMENT

Avant envoi :

Afficher :

- bénéficiaire ;
- montant exact ;
- devise ;
- destination masquée ;
- type ;
- période ;
- provider prévu ;
- frais si connus ;
- statut des contrôles.

CTA :

`Confirmer le paiement`

Si sensible :

`Demander validation`

---

# 41. PAIEMENT EN LOT

Préflight obligatoire.

Résumé :

- nombre bénéficiaires ;
- montant total ;
- devises ;
- providers ;
- prêts ;
- exclus ;
- erreurs.

Les lignes non prêtes ne bloquent pas nécessairement tout le lot.

Exemple :

`18 prêts / 3 exclus`

La confirmation porte uniquement sur les prêts.

---

# 42. FOURNISSEURS ET CORRIDORS

Le frontend ne doit jamais supposer :

- un pays supporté ;
- une devise supportée ;
- un opérateur supporté ;
- un solde suffisant ;
- une API disponible.

Port futur :

`PayoutCapabilityPort`

Retour :

- supported ;
- unsupported ;
- temporarilyUnavailable ;
- needsVerification ;
- insufficientProviderBalance.

---

# 43. FX ET FRAIS

Quand disponibles :

afficher :

- devise obligation ;
- devise payout ;
- taux utilisé ;
- date/heure ;
- frais provider ;
- coût FX ;
- montant envoyé ;
- montant reçu attendu.

Ne pas calculer une conversion fictive.

---

# 44. DONNÉES DE DÉMONSTRATION

Minimum :

- 15 enseignants ;
- 5 contractuels ;
- 12 paiements prêts ;
- 2 infos manquantes ;
- 1 modification récente méthode ;
- 1 auto-payout interdit ;
- 1 validation supplémentaire ;
- 1 payout échoué ;
- 1 lot partiellement prêt ;
- 1 remboursement ;
- 3 encaissements ;
- 2 rapprochements ;
- 1 Réserve stratégique en dessous de l’objectif ;
- politique cible fixe ;
- politique couverture en mois ;
- allocation auto fixe ;
- montant masqué / affiché ;
- fournisseur indisponible.

---

# 45. RESPONSIVE

## Mobile

- une tâche dominante ;
- bottom navigation réelle ;
- tables transformées en listes ;
- montant masqué ;
- CTA bas accessible ;
- confirmation en sheet ;
- pas de tableau horizontal illisible.

## Tablette

- master/detail si espace ;
- panneaux temporaires.

## Desktop

- vraie composition multi-colonnes ;
- tables ;
- filtres ;
- détail ;
- panneaux ;
- pas de mobile étiré.

---

# 46. ACCESSIBILITÉ

- focus clavier visible ;
- 200 % text scaling ;
- labels pour eye icons ;
- statut non dépendant de la couleur ;
- montant masqué annoncé `Montant masqué` ;
- montant affiché lu avec devise ;
- tableaux navigables ;
- confirmation payout lisible ;
- erreurs vocalisées ;
- ordre logique ;
- cibles tactiles ;
- RTL testé ;
- chiffres tabulaires pour montants.

---

# 47. SÉCURITÉ UX

## Interdit

- modifier coordonnées d’un tiers ;
- modifier montant au payout ;
- se payer soi-même ;
- payer depuis une réserve protégée sans autorisation ;
- afficher coordonnées complètes inutilement ;
- considérer un paiement envoyé comme confirmé ;
- doublon silencieux ;
- payer un bénéficiaire non vérifié si policy l’interdit ;
- contourner une validation en fractionnant un lot.

---

# 48. JOURNAL ET TRAÇABILITÉ

Chaque opération visible doit pouvoir afficher :

- initiateur ;
- date ;
- source ;
- ancien état ;
- nouvel état ;
- montant ;
- objet ;
- preuve ;
- provider ;
- référence.

Le frontend ne doit pas inventer un audit serveur.

---

# 49. ÉTATS UI

Tous les écrans :

- chargement ;
- vide ;
- erreur ;
- erreur partielle ;
- indisponible ;
- hors ligne ;
- permission insuffisante ;
- données masquées ;
- données révélées ;
- pending ;
- retry.

Paiements :

- prêt ;
- bloqué ;
- sensible ;
- transit ;
- réussi ;
- échoué.

Réserve :

- objectif atteint ;
- sous objectif ;
- dépassement ;
- règle inactive ;
- alimentation prévue ;
- mouvement sensible.

---

# 50. RECETTE - MONTANTS MASQUÉS

## R-FIN-01

À l’entrée Finance :

tous les montants sensibles sont masqués.

## R-FIN-02

Après `Afficher les montants` :

les montants apparaissent.

## R-FIN-03

Après déconnexion / nouvelle session :

ils sont de nouveau masqués.

## R-FIN-04

La confirmation payout affiche toujours le montant exact avant confirmation.

---

# 51. RECETTE - RÉSERVE STRATÉGIQUE

## R-FIN-05

Le titre reste `Réserve stratégique` quelle que soit la politique.

## R-FIN-06

Objectif `3 mois` :

l’UI affiche `Objectif : 3 mois de charges essentielles`.

## R-FIN-07

Objectif fixe :

l’UI affiche le montant cible.

## R-FIN-08

Allocation automatique fixe configurée à 10 USD :

le frontend affiche 10 USD.

## R-FIN-09

Allocation automatique fixe configurée à 1 000 000 USD :

aucun hardcode ne bloque le rendu.

## R-FIN-10

Retrait Réserve stratégique sans capability :

action bloquée.

---

# 52. RECETTE - COORDONNÉES

## R-FIN-11

Comptable consulte enseignant :

aucun `Modifier les coordonnées`.

## R-FIN-12

Admin consulte enseignant :

aucun `Modifier les coordonnées`.

## R-FIN-13

Enseignant consulte son propre espace :

il peut ajouter/modifier.

## R-FIN-14

Coordonnées récemment changées :

payout sensible selon policy.

---

# 53. RECETTE - AUTO-PAYOUT

## R-FIN-15

Le Comptable voit sa propre rémunération :

pas de CTA `Payer`.

Libellé :

`Traitement par un autre responsable requis`

---

# 54. RECETTE - CALCUL

## R-FIN-16

Montant enseignant :

lecture seule.

## R-FIN-17

Comptable signale un écart :

aucun champ de correction directe.

## R-FIN-18

Après recalcul source :

le détail et total reflètent la nouvelle version.

---

# 55. RECETTE - COMMUNICATION

## R-FIN-19

Infos paiement manquantes :

notice visible bénéficiaire.

## R-FIN-20

Comptable clique `Relancer` :

ouvre Messages métier contextuel.

## R-FIN-21

Aucune nouvelle messagerie Finance n’est créée.

---

# 56. RECETTE - LOT

## R-FIN-22

Un lot contient 12 prêts et 2 bloqués :

la confirmation affiche clairement l’exclusion.

## R-FIN-23

Aucun paiement bloqué n’est envoyé avec le lot.

---

# 57. RECETTE - DESIGN

## R-FIN-24

Toutes les surfaces Finance utilisent le design system Rewayah.

## R-FIN-25

Aucun thème hybride sidebar noire / contenu blanc inventé.

## R-FIN-26

Les high-fi divergentes sont harmonisées.

## R-FIN-27

DM Sans titres.

## R-FIN-28

Plus Jakarta Sans reste.

## R-FIN-29

Desktop réel 1440.

---

# 58. PLAN D’EXÉCUTION CLAUDE

## FIN-L0 - Audit avant code

Lecture seule.

Produire :

`UX_REVIEW_FINANCE_COMPTABLE_L0.md`

Contenu :

- routes ;
- composants ;
- screens existants ;
- Finance foyer ;
- Finance enseignant ;
- Finance direction ;
- Comptable actuel ;
- navigation ;
- composants argent ;
- data demo ;
- ports ;
- tests ;
- design tokens ;
- doublons ;
- high-fi ;
- contradictions.

Puis produire :

`DEVOIR_DE_REGARD_FINANCE.md`

Aucun code avant ces deux fichiers.

## FIN-L1 - Fondations

- SensitiveAmount ;
- visibility ;
- statuses ;
- lignes ;
- view models ;
- fixtures ;
- shells.

## FIN-L2 - Aujourd’hui

- FIN-CPT-W01 ;
- mobile Aujourd’hui ;
- alertes ;
- queues ;
- réserve.

## FIN-L3 - Paiements

- liste ;
- détail ;
- lot ;
- confirmation ;
- auto-payout block ;
- missing info.

## FIN-L4 - Bénéficiaires

- profil payout ;
- self-service ;
- relance ;
- états.

## FIN-L5 - Trésorerie

- coffres ;
- Réserve stratégique ;
- transferts internes ;
- policy display.

## FIN-L6 - Encaissements

- transaction list ;
- detail ;
- reconciliation ;
- refunds.

## FIN-L7 - Contractuels

- obligations ;
- recurring ;
- one-shot ;
- approvals view.

## FIN-L8 - Delta Direction

- StrategicReservePolicyPanel ;
- FinanceDelegationPolicyPanel.

## FIN-L9 - Recette

- screenshots ;
- widget tests ;
- keyboard ;
- mobile ;
- desktop ;
- dark/light ;
- demo ;
- no backend.

---

# 59. ORDRE DE REGARD APRÈS CHAQUE LOT

Claude doit vérifier :

1. est-ce la bonne fonction ?
2. est-elle au bon endroit ?
3. existe-t-elle déjà ailleurs ?
4. le Comptable peut-il accomplir son travail sans appeler le Directeur ?
5. la sécurité reste-t-elle suffisante ?
6. le montant est-il explicable ?
7. l’action peut-elle créer une fraude ?
8. le statut est-il honnête ?
9. la métrique aide-t-elle vraiment ?
10. le design ressemble-t-il à Rewayah ?
11. le mobile est-il réellement utilisable ?
12. le desktop est-il réellement un bureau ?
13. le bénéficiaire garde-t-il la propriété de ses coordonnées ?
14. le Comptable peut-il se payer lui-même ?
15. une réserve protégée peut-elle être détournée ?
16. l’UI suppose-t-elle un backend inexistant ?

Si une réponse est mauvaise :

corriger ou remonter le problème avant intégration.

---

# 60. HORS PÉRIMÈTRE

Ne pas créer maintenant :

- comptabilité légale complète ;
- dépôt fiscal ;
- grand livre général exhaustif ;
- paie salariale réglementaire multi-pays complète ;
- banque interne ;
- stockage serveur de credentials ;
- crypto ;
- investissement de trésorerie ;
- prêt ;
- carte corporate ;
- fournisseur de paiement maison ;
- API réelle ;
- moteur KYC backend ;
- FX réel ;
- fiscalité automatique.

---

# 61. CRITÈRES DE FIN

Le rôle Comptable frontend est fermé lorsque :

- Aujourd’hui existe ;
- Paiements à effectuer existe ;
- paiement individuel existe ;
- paiement en lot existe ;
- détail explicable existe ;
- contractuels existent ;
- encaissements existent ;
- rapprochement existe ;
- trésorerie existe ;
- coffres existent ;
- Réserve stratégique existe ;
- objectif dynamique existe ;
- alimentation auto configurable est représentée ;
- montants masqués existent ;
- self-payout est bloqué ;
- staff ne modifie pas les coordonnées ;
- bénéficiaire self-service existe ;
- Communications est réutilisé ;
- états d’erreur existent ;
- responsive existe ;
- accessibilité existe ;
- design est harmonisé ;
- devoir de regard est livré ;
- zéro backend modifié.

---

# 62. SYNTHÈSE DE DÉCISION

## Réserve

Nom :

**Réserve stratégique**

L’objectif peut être :

- montant fixe ;
- couverture dynamique.

L’alimentation automatique peut être :

- fixe ;
- proportionnelle ;
- jusqu’à l’objectif ;
- manuelle / proposée.

## Comptable

Il peut :

- gérer l’opérationnel ;
- payer les obligations standards ;
- payer en lot ;
- rapprocher ;
- relancer ;
- alimenter la réserve selon délégation.

Il ne peut pas :

- changer les prix ;
- changer les salaires ;
- changer un montant calculé ;
- modifier les coordonnées d’un tiers ;
- payer sa propre rémunération ;
- casser une réserve protégée sans règle.

## Direction

Elle fixe :

- politiques ;
- délégation ;
- Réserve stratégique ;
- exceptions ;
- seuils ;
- règles commerciales ;
- règles salariales.

Elle ne valide pas chaque opération standard.

---

# FIN
