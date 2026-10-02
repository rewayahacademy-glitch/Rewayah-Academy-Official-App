# REWAYAH - GUIDE FRONTEND FINANCE V4

**Version :** 2026-10-02  
**Statut :** décision produit + UX/UI de référence pour implémentation FRONTEND ONLY  
**Cible :** Flutter Web/PWA d'abord, architecture cross-platform conservée  
**Agent d'intégration :** Claude Code et agents parallèles  
**Priorité :** fidélité high-fi, cohérence métier, vitesse d'exécution, tests par lot

---

## 0. RÈGLE DE LECTURE

Ce document remplace, pour le périmètre **Finance / Soldes / Paiements / Rémunération / Politiques commerciales**, toute règle antérieure incompatible.

Il ne remplace pas les règles académiques, de classe, d'observation, de sécurité ou de navigation qui ne sont pas concernées.

### Autorité des sources

1. Les décisions explicites du présent document priment pour les règles Finance.
2. Les maquettes high-fi validées priment pour la composition, la hiérarchie, les regroupements et le placement des actions.
3. Les jetons du design system Rewayah restent la référence pour couleurs globales, espacements, rayons et typographies.
4. Les nouvelles couleurs d'identité des profils constituent une **extension explicitement approuvée le 2 octobre 2026**. Elles ne doivent pas devenir une nouvelle palette générale.
5. Les nombres visibles dans certaines maquettes sont parfois des données de démonstration. Les valeurs métier du tableau de décisions ci-dessous priment.
6. FRONTEND ONLY : aucune migration, Supabase, RLS, RPC, webhook, serveur, refonte Stripe ou autre travail backend dans ce lot.

---

# 1. DÉCISIONS FINANCE À FIGER

## 1.1 Modèle commercial élève

| Référence | Décision |
|---|---|
| FIN4-01 | Prix académique mensuel normal : **50 USD enfant**, **60 USD adulte**. |
| FIN4-02 | Facturation au mois civil. Premier mois payant proratisé selon les séances accessibles. |
| FIN4-03 | Le produit vendu est un **accès mensuel à une classe**, jamais un achat de séances à l'unité. |
| FIN4-04 | Une absence ordinaire de l'élève ne diminue pas le montant d'une période déjà financée. |
| FIN4-05 | Le solde ne diminue jamais séance après séance. Il est débité par période mensuelle. |
| FIN4-06 | Chaque élève possède un **solde individuel** et une **période financée individuelle**. |
| FIN4-07 | Le total du foyer est uniquement une agrégation de lecture. Il n'est jamais un portefeuille partagé ni une source d'autorisation. |
| FIN4-08 | L'accès au cours dépend de la **période financée**, pas de `solde > 0`. Un élève peut avoir 0 USD de solde restant tout en gardant l'accès si le mois courant est financé. |
| FIN4-09 | Aucun débit partiel automatique : si 40 USD sont dus et que l'élève possède 32 USD, les 32 USD ne sont pas consommés silencieusement. L'UI indique le manque à financer. |

## 1.2 Essai

| Référence | Décision |
|---|---|
| FIN4-10 | **2 séances d'essai maximum** par nouveau profil élève. |
| FIN4-11 | Les séances d'essai sont gratuites pour la famille et ne consomment pas le solde. |
| FIN4-12 | L'enseignant est rémunéré pour les séances d'essai réellement assurées. |
| FIN4-13 | Après la deuxième séance d'essai, aucune nouvelle séance payante n'est accessible tant que la première période payante n'est pas financée. |
| FIN4-14 | La première période payante débute après l'essai et utilise le prorata des séances payantes encore accessibles. Les deux essais ne sont pas refacturés. |
| FIN4-15 | Un essai ne compte pas comme élève payant pour les remises, quotas ou KPI de payants. |
| FIN4-16 | Pour la rémunération de la séance d'essai, le siège d'essai compte comme siège occupé sur cette séance, sans devenir un payant dans les KPI commerciaux. |
| FIN4-17 | Une séance d'essai normalement ouverte par Rewayah est consommée si l'élève est absent. Une séance annulée ou non fournie par Rewayah n'est pas consommée. |

## 1.3 Remise familiale

Nouvelle politique de lancement :

- 1er membre payant du foyer : **aucune remise**
- 2e membre payant : **aucune remise**
- 3e membre payant : **-5 USD**
- 4e membre payant et suivants : **-7 USD chacun**

Règles :

- aucune baisse rétroactive du tarif des deux premiers membres ;
- l'arrivée du 3e membre ne réécrit jamais les factures déjà payées ;
- aide sociale individuelle et remise familiale ne se cumulent pas automatiquement ;
- les membres gratuits ou en aide partielle restent hors seuil familial, sauf décision commerciale future versionnée ;
- les remises sont des paramètres configurables, versionnés et datés.

**Exemple 3 enfants :** 50 + 50 + 45 = **145 USD / mois**.  
**Exemple 4 enfants :** 50 + 50 + 45 + 43 = **188 USD / mois**.

## 1.4 Rémunération enseignant

L'ancien modèle **20 USD enfant / 26 USD adulte par élève** et le bonus automatique **10/20 USD classe pleine ou multi-classes** sont remplacés pour la nouvelle politique de lancement.

### Formule cible

La rémunération se calcule par séance réellement assurée :

```text
taux_horaire_effectif =
min(
  plafond_horaire,
  base_horaire
  + (plafond_horaire - base_horaire)
    × sièges_éligibles
    / capacité_effective_du_groupe
)

rémunération_séance =
durée_assurée_en_minutes / 60
× taux_horaire_effectif
```

Valeurs de lancement :

- base horaire garantie : **4 USD/h**
- plafond horaire : **7 USD/h**
- capacité enfant standard : **5**
- capacité adulte : **6**
- capacité débutant : **4**
- minimum d'ouverture : **4**
- objectif courant : **3 groupes actifs par enseignant**
- maximum normal : **4 groupes actifs par enseignant**

### Définition des sièges éligibles

Pour une séance donnée :

- élève actif avec période financée : compte ;
- élève en essai valide présent dans la place prévue : compte pour la rémunération de cette séance ;
- élève financé absent : compte, car l'enseignant ne doit pas perdre sa rémunération à cause d'une absence individuelle ;
- place vide non attribuée : ne compte pas ;
- siège au-delà de la capacité : interdit dans le calcul.

Conséquence :

- le professeur possède une base garantie ;
- garder une cohorte remplie augmente son taux jusqu'au plafond ;
- un absent individuel ne le pénalise pas ;
- le professeur n'est pas payé davantage au-delà de la capacité prévue ;
- Rewayah conserve un intérêt économique clair à bien remplir les groupes.

### Internet

L'aide Internet est séparée de la rémunération pédagogique :

- une seule allocation par enseignant éligible ;
- montant configurable ;
- ne se multiplie ni par classe ni par élève ;
- affichée séparément dans le relevé enseignant.

### Bonus

Ne pas recréer le bonus automatique « classe pleine » ou « plusieurs classes ».

Les bonus futurs peuvent concerner :

- fiabilité ;
- ponctualité ;
- obligations pédagogiques ;
- rétention de cohorte ;
- qualité contrôlée.

Ils ne doivent jamais reposer uniquement sur le score académique brut des élèves.

## 1.5 Marge

Le **40 %** n'est plus un blocage métier automatique.

Créer un paramètre versionné de pilotage :

```text
margin_reference_target
```

Référence de lancement pour les simulations :

- environ **30 % net** : objectif de pilotage raisonnable ;
- **35 %** : performance forte ;
- **40 %** : scénario stretch.

Aucun widget ne doit transformer automatiquement ces valeurs en sanction, refus ou décision irréversible.

## 1.6 Paiement et lancement plateforme

### Lancement

- **Web + PWA**
- **Stripe actif**
- applications iOS / Android natives conservées dans l'architecture Flutter, mais pas de facturation App Store / Play Store au lancement.

Préparer des interfaces abstraites pour futurs rails :

- `WEB_STRIPE` : actif
- `IOS_STOREKIT` : non activé au lancement
- `ANDROID_PLAY` : non activé au lancement

Ne pas afficher de bouton App Store / Play Billing dans la version de lancement.

### Recharge multi-profils

Un paiement externe peut financer plusieurs profils.

Exemple :

```text
Commande RWY-123
Mariam +10 USD
Ibrahim +40 USD
Total externe = 50 USD
```

L'UI montre :

1. sélection des profils ;
2. montant attribué à chacun ;
3. total unique ;
4. moyen de paiement ;
5. confirmation ;
6. répartition finale par profil.

Le paiement externe est unique. L'allocation interne reste nominative par profil.

### Confirmation

L'interface doit prévoir :

- `preparing`
- `awaiting_confirmation`
- `confirmed`
- `allocation_in_progress`
- `completed`
- `failed`
- `cancelled`
- `stale`

Ne jamais afficher « paiement confirmé » simplement parce que l'utilisateur revient d'un écran externe.

Dans cette phase FRONTEND ONLY, simuler ces états avec fixtures et ports, sans webhook réel.

## 1.7 Impayé et accès

Aucun compte utilisateur n'est supprimé ou désactivé pour un impayé.

### Si la nouvelle période n'est pas financée

- le profil existe ;
- le tuteur conserve l'accès au Foyer, à l'historique, aux paiements et aux informations de l'enfant ;
- l'élève conserve ses données acquises et contenus non payants ;
- le bouton de participation à une nouvelle séance payante devient indisponible ;
- la nouvelle période affiche `À régulariser` ;
- la place peut être conservée **7 jours** ;
- au-delà, la place peut être libérée selon la règle opérationnelle ;
- aucune dette mensuelle n'est empilée indéfiniment après fin réelle de l'inscription.

### Copie enfant

Ne jamais afficher à un enfant :

> Votre famille n'a pas payé.

Utiliser une formulation neutre :

> **Accès à cette classe temporairement indisponible**  
> Votre tuteur peut gérer l'accès.

### Copie tuteur / adulte autonome

Afficher la cause utile :

> **Accès à régulariser**  
> Il manque 8 USD pour financer janvier.

## 1.8 Taxes

Correction des anciennes specs :

- 50/60 USD sont les **tarifs académiques de base** ;
- les taxes de consommation éventuellement applicables sont traitées séparément ;
- le total réellement débité doit être visible avant confirmation ;
- les taxes collectées pour une autorité ne doivent pas être présentées comme revenu académique.

Ne pas coder de taux fiscal dans Flutter.

## 1.9 PISI

PISI existe déjà comme programme autonome evergreen de Rewayah.

**Hors périmètre de ce chantier.**

Ne créer aucun « Rewayah Foundations », duplicata ou nouveau produit parallèle.

---

# 2. MAQUETTES HIGH-FI DE RÉFÉRENCE

Les maquettes validées récentes couvrent :

### Tuteur mobile dark

- Foyer - Soldes et paiements
- Mariam - Finances
- Recharge multi-profils
- Paiement confirmé

### Tuteur desktop light

- Foyer - Soldes et paiements
- Mariam - Finances
- Paiement du foyer

### Autres rôles / desktop

- Enseignant - Revenus
- Finance - Vue globale
- Admin - Politiques commerciales

### Règle de fidélité

La high-fi est autoritaire pour :

- structure ;
- densité ;
- ordre des sections ;
- placement des actions ;
- colonnes ;
- regroupements ;
- hiérarchie ;
- proportions ;
- comportement responsive attendu.

Les valeurs métier de démonstration visibles dans les images **ne sont pas autoritaires**.

Exemples à ne PAS recopier aveuglément :

- `30 USD / mois` visible dans certaines maquettes enfant ;
- `-5 USD` affiché sur Mariam si son rang familial n'y donne pas droit ;
- une éventuelle mention `J+14` dans une maquette Admin ;
- anciennes remises 5/10 sur tous les membres ;
- ancienne paie 20/26 par élève.

Le présent document prime pour ces valeurs.

---

# 3. SYSTÈME D'IDENTITÉ VISUELLE DES PROFILS

Cette section est obligatoire. Elle répond à un problème réel de foyer multi-profils : plusieurs enfants peuvent partager le même nom de famille et le tuteur ne doit pas devoir relire chaque nom pour éviter une erreur.

## 3.1 Principe

Chaque profil élève d'un même foyer possède un `profileAccentKey` stable.

Exemple visuel approuvé :

- Mariam : rose / lilas
- Ibrahim : bleu clair
- Aïcha : violet doux

La couleur n'est jamais recalculée à partir de la position de l'enfant dans une liste.

Même personne = même accent partout.

## 3.2 Composant canonique

Créer un composant partagé de type :

```text
ProfileIdentityAvatar
```

Il combine :

1. photo réelle ou initiale ;
2. cercle avatar ;
3. petit bandeau coloré visible derrière l'avatar ;
4. nom accessible dans le contexte ;
5. variante de taille.

Le bandeau n'est PAS :

- un statut ;
- un niveau ;
- une alerte ;
- une couleur de classe.

C'est uniquement un identifiant visuel de personne.

## 3.3 Géométrie

### Mobile standard

- avatar cible : environ 56-64 dp ;
- bandeau : environ 50-60 % de la largeur de l'avatar ;
- bandeau visible de 8-14 dp au-dessus du cercle ;
- aligné au centre ou légèrement décalé selon la high-fi ;
- aucune ombre colorée excessive.

### Desktop carte

- avatar cible : environ 44-56 dp ;
- bandeau plus court et compact ;
- visibilité immédiate sans prendre le dessus sur le contenu.

### Grand header profil

- avatar cible : environ 72-88 dp ;
- bandeau plus ample mais toujours partiellement masqué par l'avatar.

Ces tailles sont des guides. Claude doit utiliser les métriques et composants existants plutôt que créer des valeurs dispersées.

## 3.4 Où l'utiliser

Obligatoire lorsque l'utilisateur doit distinguer plusieurs membres :

- Foyer ;
- sélecteur de profils ;
- recharge multi-profils ;
- récapitulatif paiement ;
- confirmation de paiement ;
- historique filtrable par personne ;
- alertes « accès à régulariser » ;
- cartes d'enfants ;
- changement de profil ;
- résumé d'un enfant dans une surface familiale.

Sur la fiche individuelle, conserver le bandeau pour continuité visuelle même si une seule personne est affichée.

## 3.5 Où ne pas le multiplier

Ne pas colorer :

- toute la carte ;
- tout le fond de page ;
- les montants ;
- les statuts ;
- les CTA.

La couleur identitaire reste locale à l'avatar et à de petits marqueurs associés.

## 3.6 Photo réelle

Si le profil possède une photo :

- garder le bandeau ;
- afficher la photo dans le cercle ;
- ne pas appliquer de filtre coloré sur la photo.

## 3.7 Accessibilité

La couleur ne doit jamais être l'unique moyen d'identification.

Toujours conserver :

- prénom ;
- initiale ou photo ;
- libellé explicite ;
- information de classe si utile.

Pour le lecteur d'écran :

```text
"Mariam, profil enfant, Classe An-Nour"
```

et non :

```text
"profil rose"
```

## 3.8 Palette

Ne pas inventer des hex dans les widgets.

Claude doit :

1. auditer les tokens actuels ;
2. réutiliser les accents de profils déjà présents si disponibles ;
3. s'ils n'existent pas, ajouter uniquement les tokens sémantiques nécessaires au niveau du design system ;
4. exclure les couleurs réservées aux états succès / alerte / erreur ;
5. figer ces tokens par test.

Cette extension est la seule exception couleur nouvellement approuvée dans ce chantier.

---

# 4. ARBORESCENCE CANONIQUE FRONTEND

Les routes exactes doivent être adaptées à l'existant après audit. Ne pas créer une seconde route si une route compatible existe déjà.

## Tuteur

```text
/tuteur/foyer
  Foyer + synthèse Soldes et paiements

/tuteur/foyer/:studentId/finances
  Fiche financière individuelle

/tuteur/foyer/recharge
  Recharge 1 ou plusieurs profils
  selectedStudentIds préremplissables

/tuteur/foyer/recharge/result
  Résultat de paiement

/tuteur/foyer/:studentId/mouvements
  Historique financier individuel
```

La recharge simple « Recharger Mariam » ouvre **le même flux** que la recharge multi-profils avec Mariam présélectionnée.

Ne pas créer deux moteurs de recharge.

Si `Compte > Paiements` existe déjà, il devient :

- un raccourci vers la surface canonique ;
- ou une redirection vers le même flux ;

jamais un deuxième centre de paiement concurrent.

## Élève adulte

Préparer le contrat pour une surface financière personnelle :

```text
/eleve/finances
```

mais ne pas dupliquer le Foyer.

L'adulte autonome voit ses propres :

- solde ;
- période financée ;
- prochain débit ;
- historique ;
- recharge.

## Élève enfant

Pas de surface « finance » détaillée.

L'enfant voit uniquement l'état d'accès utile :

- essai ;
- accès actif ;
- accès temporairement indisponible.

## Enseignant

```text
/enseignant/revenus
```

Une seule surface de référence pour :

- revenu estimé ;
- groupes ;
- séances ;
- taux effectif ;
- allocation Internet ;
- relevé.

## Admin / Finance

```text
/admin/finance
/admin/parametres/politiques-commerciales
```

Si le dépôt utilise une autre structure, conserver l'existant et mapper ces responsabilités.

Le rôle Comptable utilise la même source fonctionnelle Finance avec permissions adaptées. Ne pas construire un deuxième système financier « comptable ».

---

# 5. ÉCRANS ET CONTENU ATTENDU

## 5.1 Tuteur - Foyer / Soldes et paiements

### Mobile

Priorités :

1. titre ;
2. synthèse foyer ;
3. profils ;
4. actions contextuelles.

Afficher :

- nombre d'enfants ;
- nombre de profils financés ;
- paiements du mois ;
- total des soldes en lecture ;
- montant à financer ce mois ;
- CTA `Recharger plusieurs profils`.

Pour chaque enfant :

- `ProfileIdentityAvatar` ;
- prénom ;
- âge si présent dans le design ;
- classe ;
- état de période ;
- solde ;
- prochain débit ;
- une action adaptée.

États visuels :

- financé ;
- essai ;
- manque à financer ;
- paiement en confirmation ;
- accès expiré ;
- pause.

### Desktop

Même information, vraie composition ordinateur :

- sidebar ;
- résumé horizontal ;
- cartes enfants en colonnes ;
- vue financière foyer ;
- dernières transactions ;
- raccourcis utiles.

Ne jamais étirer le mobile.

## 5.2 Tuteur - Fiche élève / Finances

Afficher :

- identité ;
- période financée ;
- solde ;
- prochain débit ;
- mensualité ;
- décomposition tarifaire ;
- CTA recharge ;
- mouvements ;
- historique / reçu selon format.

Le détail tarifaire doit être data-driven.

Exemples possibles :

```text
Tarif enfant                50 USD
Remise familiale 3e membre -5 USD
Réduction calendrier        -X USD
Avoir                       -Y USD
Taxe applicable             +Z USD
Total à financer            XX USD
```

Ne jamais afficher une remise inexistante juste pour correspondre à une image.

## 5.3 Recharge multi-profils

Éléments obligatoires :

- checkbox par profil ;
- avatar + accent stable ;
- montant par profil ;
- total ;
- moyen de paiement ;
- explication de la répartition ;
- CTA unique.

Règles UX :

- profil non sélectionné = montant désactivé ;
- minimum requis peut être suggéré ;
- l'utilisateur voit toujours à qui va chaque montant ;
- le total se recalcule sans ambiguïté ;
- pas de « solde commun ».

## 5.4 États de paiement

### Préparation

> Vérifiez la répartition avant de payer.

### Confirmation externe en attente

> Paiement en cours de confirmation  
> Ne payez pas une seconde fois.

### Allocation

> Paiement confirmé  
> Mise à jour des soldes...

### Succès

Montrer :

- montant total ;
- référence ;
- moyen ;
- date ;
- répartition exacte ;
- nouveau solde par profil.

### Échec

Ne pas perdre la sélection.

Afficher :

- motif utilisateur lorsque disponible ;
- CTA réessayer ;
- CTA changer de moyen ;
- retour.

## 5.5 Enseignant - Revenus

Le dashboard affiche une **estimation**, pas une paie définitive.

Par groupe :

- heures assurées ;
- capacité ;
- sièges éligibles moyens ou détail par séance ;
- taux horaire effectif ;
- montant estimé.

Explication simple :

1. base garantie ;
2. composante occupation ;
3. plafond horaire.

Ne pas afficher les soldes familiaux ni les montants payés individuellement par les élèves.

## 5.6 Finance - Vue globale

KPI possibles :

- chiffre encaissé ;
- revenu académique ;
- paie enseignants ;
- marge projetée ;
- impayés ;
- essais en cours ;
- soldes créditeurs.

Toujours distinguer :

- encaissement ;
- revenu ;
- solde client ;
- charge ;
- marge.

## 5.7 Admin - Politiques commerciales

Le design doit montrer qu'une politique est versionnée.

Chaque version affiche :

- statut brouillon / publié ;
- date d'effet ;
- comparaison avec version active ;
- aperçu avant publication.

Paramètres modifiables sans recoder :

### Tarifs
- enfant ;
- adulte.

### Essai
- nombre de séances ;
- activation ;
- autres paramètres futurs.

### Remises
- rang familial ;
- montant.

### Enseignants
- base horaire ;
- plafond horaire ;
- cible groupes ;
- maximum groupes ;
- aide Internet ;
- paramètres d'occupation.

### Groupes
- capacité enfant ;
- capacité adulte ;
- capacité débutant ;
- minimum ouverture.

### Paiement
- durée de conservation de place ;
- rails activés ;
- règles de relance visibles.

### Pilotage
- référence de marge ;
- budgets non contraignants.

Important : les invariants financiers ne sont PAS des champs Admin.

Exemples d'invariants non éditables :

- idempotence ;
- séparation des soldes ;
- historique append-only ;
- confirmation avant crédit ;
- absence de double débit ;
- contrôle d'accès par période financée.

---

# 6. RESPONSIVE ET THÈMES

## Breakpoints

Conserver la logique Rewayah :

- mobile : environ 390 x 844 de référence ;
- tablette / rail : à partir d'environ 600 ;
- desktop : sidebar réelle à partir d'environ 1200 ;
- capture obligatoire desktop : **1440 x 900** minimum.

## Références visuelles obligatoires

Pour chaque écran implémenté :

- mobile dark si la maquette dark existe ;
- desktop light si la maquette desktop light existe ;
- vérifier également le thème inverse via tokens, sans inventer un layout différent.

## Desktop

Le desktop doit exploiter :

- largeur ;
- colonnes ;
- panneaux latéraux ;
- tableaux lorsque pertinents ;
- raccourcis secondaires.

Interdit :

- colonne mobile centrée dans 1440 px ;
- cartes géantes étirées ;
- duplication verticale inutile.

---

# 7. COMPOSANTS PARTAGÉS À CONSTRUIRE AVANT LES PAGES

Créer ou perfectionner les composants existants plutôt que coder écran par écran.

Minimum :

```text
ProfileIdentityAvatar
ProfileIdentityRow
FinancialStatusChip
MoneyAmount
MoneySummaryCard
GroupedCard
FinanceLineItem
FinancedPeriodBadge
BalanceSummary
PaymentAllocationRow
PaymentMethodRow
TransactionRow
AttentionBanner
PolicyField
PolicyVersionHeader
ResponsiveFinanceScaffold
```

## GroupedCard

Rappel strict :

- un seul rectangle ;
- lignes internes par fins séparateurs ;
- pas une pile de mini-cartes pour chaque ligne.

## Montants

Prévoir :

- tabular figures ;
- alignement des décimales si nécessaire ;
- signe positif/négatif explicite ;
- devise toujours identifiable ;
- couleur secondaire, jamais couleur seule.

---

# 8. DÉCOUPAGE D'IMPLÉMENTATION POUR CLAUDE

Objectif : petits lots rapides, ownership clair, aucun conflit inutile.

## LOT F0 - Audit et contrats - lecture seule

**Agent F0**

Mission :

- lire ce guide et les docs actuels ;
- inventorier routes, widgets, modèles et tokens existants ;
- repérer tous les anciens montants et règles finance ;
- produire la carte `fonction -> écran -> route -> fichier` ;
- produire la liste des conflits.

Recherche obligatoire :

```text
20
26
10/20 bonus
family discount 5/10
40%
30 days
session units
wallet
shared balance
balance > 0
J+14
tax included
StoreKit
Play Billing
```

Livrable :

```text
FINANCE_FRONTEND_AUDIT.md
```

Classification :

- CONFORME
- ÉCART
- RISQUE
- BLOCAGE
- INCONNU

**Aucun code métier dans F0.**

---

## LOT F1 - Fondation UI partagée

**Agent F1**

Ownership :

- design-system / components partagés finance ;
- tokens d'identité profil ;
- fixtures et view-models frontend.

Mission :

- `ProfileIdentityAvatar` ;
- composants argent / statuts ;
- `ResponsiveFinanceScaffold` ;
- fixtures ;
- états de démonstration.

Critères :

- aucune valeur commerciale hardcodée dans les widgets ;
- accent d'un profil stable ;
- photo et initiales fonctionnent ;
- thème clair/sombre ;
- taille texte 200 % sans coupure critique.

Tests :

- widget tests ;
- golden composants ;
- test de stabilité `profileAccentKey` ;
- semantics tests.

**F1 est le seul lot bloquant pour les autres pages.**

---

## LOT F2 - Tuteur / Foyer finance

**Agent F2**

Dépend de F1.

Ownership exclusif :

- page Foyer ;
- sections finance du Foyer ;
- cartes profils finance.

Mission :

- reproduire mobile dark ;
- reproduire desktop light ;
- intégrer résumé foyer ;
- intégrer états profil.

Fixtures minimales :

1. tous financés ;
2. un profil à régulariser ;
3. un profil en essai ;
4. aucun paiement ;
5. famille 1 profil ;
6. famille 5 profils.

Tests :

- mobile 390 ;
- desktop 1440 ;
- text scale 200 % ;
- navigation ;
- aucune carte enfant confondue visuellement.

---

## LOT F3 - Fiche élève / Finances

**Agent F3**

Dépend de F1.

Ownership :

- onglet ou route Finances de l'élève ;
- mouvements individuels ;
- reçu UI.

Mission :

- mobile Mariam ;
- desktop Mariam ;
- détail mensualité data-driven ;
- historique.

Tests :

- aucune remise ;
- 3e membre -5 ;
- 4e membre -7 ;
- prorata ;
- avoir ;
- taxe ;
- période financée avec solde 0 ;
- solde positif mais période non financée.

---

## LOT F4 - Recharge et résultat paiement

**Agent F4**

Dépend de F1.

Ownership :

- sélection multi-profils ;
- récapitulatif ;
- moyen de paiement ;
- états de résultat.

Mission :

- une recharge simple utilise ce même flux ;
- mobile + desktop ;
- états `pending`, `confirmed`, `failed`, `cancelled`, `stale`.

Tests critiques :

- 1 profil ;
- 3 profils ;
- désélection ;
- montant 0 ;
- total ;
- retour après échec ;
- même confirmation reçue deux fois en fixture : UI n'affiche jamais deux crédits ;
- écran fermé puis rouvert en `awaiting_confirmation`.

Aucun appel Stripe réel dans ce lot.

---

## LOT F5 - Accès / essai / impayé

**Agent F5**

Peut travailler en parallèle après F1.

Ownership :

- affichage frontend des états d'accès ;
- CTA `Rejoindre` activé/désactivé selon fixture ;
- copies enfant/tuteur/adulte.

Mission :

- trial 0/2, 1/2, 2/2 ;
- période financée ;
- à régulariser ;
- place conservée ;
- accès suspendu ;
- réactivation.

Important :

- ne toucher ni LiveKit ni serveur ;
- seulement le contrat UI et les états.

Tests :

- enfant ne voit jamais le motif financier détaillé ;
- tuteur voit le manque exact ;
- compte reste navigable ;
- bibliothèque non payante reste accessible selon contrat existant.

---

## LOT F6 - Enseignant / Revenus

**Agent F6**

Peut commencer après F1.

Ownership :

- `/enseignant/revenus` ou route existante équivalente.

Mission :

- high-fi desktop ;
- version mobile responsive cohérente ;
- explication de la formule ;
- tableaux groupes ;
- allocation Internet.

Fixtures :

- groupe plein ;
- groupe 80 % ;
- groupe minimum ;
- essai dans la séance ;
- élève financé absent ;
- remplacement ;
- allocation Internet oui/non.

Tests :

- ne jamais afficher solde famille ;
- ne jamais afficher montant payé par enfant ;
- revenu marqué estimé ;
- taux ne dépasse jamais 7 dans les fixtures de lancement.

---

## LOT F7 - Admin Finance

**Agent F7**

Dépend de F1.

Ownership :

- vue globale Finance ;
- alertes ;
- tableau / graphiques UI avec fixtures.

Mission :

- high-fi desktop ;
- mobile/tablette simplifiés sans transformer en grille illisible.

Tests :

- chiffres vides ;
- mois sans activité ;
- impayés ;
- soldes créditeurs ;
- longue liste d'alertes ;
- aucun graphique ne remplace les nombres exacts.

---

## LOT F8 - Admin Politiques commerciales

**Agent F8**

Dépend de F1.

Ownership :

- page politiques ;
- aperçu de simulation frontend ;
- historique de versions UI.

Mission :

- reproduire high-fi ;
- champs dynamiques ;
- brouillon vs publié ;
- aperçu famille ;
- aperçu enseignant.

Interdit :

- publication backend ;
- migration ;
- vraie écriture de politique.

Tests :

- comparaison de versions ;
- date d'effet ;
- erreur de champ ;
- champ non autorisé absent ;
- 3e membre / 4e membre ;
- base 4 / plafond 7 ;
- capacité modifiée ;
- aperçu recalculé en fixture.

---

## LOT FQ - QA visuelle et fonctionnelle transverse

**Agent Q**

Lecture/recette sur tous les lots.

Ne doit pas réinventer le design.

Mission :

1. comparer captures au high-fi ;
2. vérifier routing ;
3. chercher fonctions dupliquées ;
4. vérifier accents de profils ;
5. vérifier responsive ;
6. vérifier accessibilité ;
7. vérifier copies ;
8. vérifier règles métier visibles ;
9. détecter anciens montants.

Livrable :

```text
FINANCE_FRONTEND_QA_REPORT.md
```

Chaque problème :

```text
ID
Sévérité
Écran
Capture
Attendu
Observé
Correction
Statut
```

---

# 9. PARALLÉLISATION CONSEILLÉE

Ordre optimal :

```text
F0 audit
   ↓
F1 composants partagés
   ↓
┌─────────┬─────────┬─────────┬─────────┐
F2        F3        F5        F6
Foyer     Élève     Accès     Enseignant
└────┬────┴────┬────┴────┬────┴─────────┘
     ↓         ↓         ↓
     F4        F7        F8
 Recharge    Finance    Politiques
     └─────────┬─────────┘
               ↓
              FQ
               ↓
          Intégrateur final
```

Règle :

- un fichier = un owner pendant un lot ;
- fichiers partagés F1 gelés pendant les lots parallèles sauf demande de contrat ;
- aucune modification croisée silencieuse ;
- si un composant manque, ouvrir une demande de contrat, ne pas dupliquer.

---

# 10. RECETTE OBLIGATOIRE PAR LOT

Chaque agent doit fournir :

### Technique frontend

- `dart format`
- analyse Flutter
- tests unitaires ciblés
- tests widgets
- golden / screenshot tests lorsque le repo les supporte
- aucune régression de navigation

### Tailles

Au minimum :

- mobile ~390 px ;
- tablette / rail ;
- desktop 1440 x 900.

### Thèmes

- clair ;
- sombre.

### Accessibilité

- navigation clavier desktop ;
- focus visible ;
- lecteurs d'écran ;
- cible tactile minimale ;
- text scale 200 % ;
- état jamais indiqué uniquement par couleur.

### États

- loading ;
- empty ;
- success ;
- error ;
- forbidden ;
- incomplete ;
- stale ;
- concurrent / pending.

---

# 11. COMMENT ATTEINDRE LE NIVEAU DE PERFECTION DES HIGH-FI

## 11.1 Ne pas « interpréter » une maquette

Claude doit reproduire :

- ordre ;
- densité ;
- alignements ;
- respirations ;
- proportions ;
- largeur relative des cartes ;
- place des CTA ;
- hiérarchie des textes.

Une carte déplacée « parce que c'est plus simple » est un défaut.

## 11.2 Comparaison par capture

Pour chaque écran :

1. exécuter la vraie page ;
2. capturer à la taille cible ;
3. placer capture et high-fi côte à côte ;
4. si possible, faire un overlay à 50 % ;
5. corriger les écarts ;
6. répéter.

Ne pas valider « ça ressemble ».

Valider :

- grille ;
- hauteur ;
- paddings ;
- typo ;
- rayons ;
- épaisseur des séparateurs ;
- position des icônes ;
- alignement des chiffres ;
- densité.

## 11.3 Chiffres

Utiliser des chiffres tabulaires.

Les colonnes de montants doivent sembler calmes et stables.

Éviter :

```text
50$
```

Préférer le formateur de devise du produit :

```text
50 $
```

selon la locale affichée.

## 11.4 Statuts

Succès / warning / erreur :

- chip compact ;
- icône ou point ;
- texte explicite ;
- jamais seulement une teinte.

L'accent profil ne doit jamais être confondu avec un statut.

## 11.5 Avatars et profils

C'est un point de contrôle prioritaire.

Vérifier sur chaque écran :

- la bonne personne possède la bonne couleur ;
- le bandeau reste visible même avec photo ;
- la taille est identique dans des contextes équivalents ;
- le cercle n'écrase pas le bandeau ;
- l'accent n'est jamais remplacé par la couleur du statut ;
- l'ordre prénom / âge / classe est constant ;
- le nom reste lisible à 200 % ;
- deux enfants du même foyer restent distinguables en moins d'une seconde.

## 11.6 Desktop

Le desktop doit ressembler à un logiciel pensé pour 1440 px.

Utiliser :

- alignement sur grille ;
- colonnes asymétriques quand la hiérarchie l'exige ;
- panneaux de contexte ;
- tableaux compacts ;
- espace blanc utile.

Ne pas grossir artificiellement les composants mobiles.

## 11.7 Mobile

Sur mobile :

- une décision principale par écran ;
- CTA principal atteignable ;
- ne pas faire défiler une répétition de résumés identiques ;
- ne pas cacher la navigation ;
- retour clair dans les tâches focalisées.

---

# 12. DEVOIR DE REGARD CLAUDE

Avant toute implémentation, Claude doit contester ce guide s'il trouve dans le dépôt une preuve que :

- une fonction existe déjà à un autre endroit utile ;
- une route est déjà canonique ;
- un composant partagé existe ;
- un token existe ;
- une décision récente plus explicite existe ;
- une high-fi validée contredit ce document.

Mais il ne doit jamais modifier silencieusement la décision.

Format obligatoire :

```text
DEVOIR DE REGARD - FINANCE FRONTEND

CONFORME
- ...

ÉCART
- ...

RISQUE
- ...

BLOCAGE
- ...

INCONNU
- ...

PROPOSITION MINIMALE
- ...
```

### Recherches obligatoires dans le dépôt

Claude doit vérifier particulièrement :

- ancienne paie 20/26 ;
- bonus 10/20 ;
- remise 2 membres / 3+ ;
- seuil 40 % codé en dur ;
- ancien wallet familial ;
- consommation par séance ;
- accès calculé par simple solde ;
- `J+14` ;
- prix 30 USD de démonstration ;
- taxes « incluses » ;
- StoreKit / Play Billing activés par erreur ;
- ancien écran Paiements dupliquant le nouveau Foyer.

---

# 13. CE QUE L'INTÉGRATEUR DOIT REFUSER

Refuser un lot si :

- une action existe à deux endroits ;
- un enfant peut consommer le solde d'un autre ;
- le total foyer est utilisable comme wallet ;
- un avatar change de couleur d'un écran à l'autre ;
- la couleur de profil dépend de l'index de liste ;
- un statut financier est exprimé uniquement par couleur ;
- les tarifs sont codés dans le widget ;
- le mobile est étiré sur desktop ;
- une maquette desktop est compressée en mobile sans adaptation ;
- un compte entier devient inaccessible pour impayé ;
- le bouton Rejoindre dépend de `balance > 0` ;
- une confirmation de paiement est simulée comme vérité serveur ;
- un ancien montant 20/26 ou 5/10 réapparaît sans justification ;
- le lot touche au backend alors que la phase reste FRONTEND ONLY.

---

# 14. DEFINITION OF DONE - FINANCE FRONTEND

Le périmètre Finance frontend est terminé seulement si :

- high-fi Tuteur mobile reproduites ;
- high-fi Tuteur desktop reproduites ;
- identité couleur des profils partout nécessaire ;
- recharge 1 ou plusieurs profils dans le même flux ;
- résultat paiement et états intermédiaires ;
- essai visible correctement ;
- accès impayé visible sans désactiver le compte ;
- enseignant Revenus ;
- Admin Finance ;
- Admin Politiques commerciales ;
- paramètres commerciaux injectables via fixtures/config frontend ;
- aucune valeur métier critique hardcodée dans les widgets ;
- responsive ;
- light/dark ;
- accessibilité ;
- tests ;
- rapport QA ;
- aucune fonction dupliquée.

---

# 15. NOTE DE SCOPE

Ce guide prépare le frontend à un futur câblage financier sérieux, mais **ne donne aucune autorisation** pour :

- migrations ;
- Supabase ;
- RLS ;
- RPC ;
- webhooks Stripe ;
- stockage de carte ;
- backend de ledger ;
- StoreKit ;
- Play Billing ;
- fiscalité backend ;
- paie réelle.

Tous ces éléments appartiendront à une phase distincte après validation visuelle et fonctionnelle.

Le frontend doit seulement fournir :

```text
interfaces
ports
fixtures
états
composants
navigation
copies
responsive
tests
```

sans prétendre qu'un paiement ou un droit d'accès est réellement garanti par un serveur.

---

# 16. RÉSUMÉ EXÉCUTIF POUR CLAUDE

Ne reconstruis pas la finance.

Perfectionne et raccorde le frontend autour de six vérités :

1. **un élève = un solde + une période financée + une identité couleur stable** ;
2. **un foyer peut payer une seule fois pour plusieurs élèves, sans wallet commun** ;
3. **l'accès dépend de la période financée, pas du solde instantané** ;
4. **deux séances d'essai gratuites précèdent le premier accès payant** ;
5. **la rémunération enseignant combine base garantie + occupation, plafonnée** ;
6. **toutes les valeurs commerciales sont configurables et versionnées, les invariants ne le sont pas**.

La fidélité aux high-fi est un critère de recette, pas une suggestion.
