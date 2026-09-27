# Prompt 01 — Décisions produit bloquantes

**Statut global : `BLOCKED`**

Ce rapport prépare les arbitrages demandés par `docs/HANDOFF.md §10.5`. Il ne
constitue pas une décision opérateur. Tant qu'une décision écrite n'est pas
ajoutée par l'opérateur au handoff, à ce rapport ou au registre des décisions,
aucun lot dépendant ne doit coder, migrer, changer une route ou publier un
comportement sur le sujet concerné.

## Règles de lecture

- Les options ci-dessous sont des alternatives, pas des décisions implicites.
- Une option peut être retenue pour `ADM-03` et une autre pour `CTR-03` : leur
  sort ne doit pas être couplé sans décision explicite.
- Les invariants déjà documentés restent applicables tant qu'ils ne sont pas
  contredits par une décision opérateur : RLS et journalisation, aucune
  correction par le tuteur ou l'élève, aucune présence déduite d'un minuteur
  client, et aucune donnée Coran inventée.
- Le statut `BLOCKED` signifie « décision requise avant le lot dépendant »,
  pas « option techniquement impossible ».

## Tableau de synthèse

| ID | Sujet | Décision requise | Statut |
| :-- | :-- | :-- | :-- |
| D01 | `ENS-05` | Profil enseignant en MVP-0 ou payout/finance en V1 | **BLOCKED** |
| D02 | `ADM-03` | Séquestre/exports en MVP-0 ou V1 | **BLOCKED** |
| D03 | `CTR-03` | Grille d'audit en MVP-0 ou V1 | **BLOCKED** |
| D04 | N6 | Canal du Coran partagé | **BLOCKED** |
| D05 | Présence | Acteurs autorisés à corriger/excuser | **BLOCKED** |
| D06 | Présence | Motif obligatoire et délai d'action | **BLOCKED** |
| D07 | Mode enfant | Valeur et sémantique de `child_ui_mode_max_age` | **BLOCKED** |
| D08 | Paiement | Règle en cas de litige | **BLOCKED** |
| D09 | Corpus Coran | Source technique et licence | **BLOCKED** |

---

## D01 — `ENS-05` : profil enseignant MVP-0 ou payout V1

**Statut : `BLOCKED`**

La section 10 décrit une contradiction : l'ancien nom `ENS-05` désignait le
payout V1, tandis que la refonte le catalogue comme `/enseignant/profil` et le
handoff le place parmi les lots MVP-0. Le profil ne doit pas afficher de
finance ou de capacité inventée.

### Option A — `ENS-05 = profil enseignant MVP-0`, finance/payout en V1

Impacts :

- construit `/enseignant/profil` en lecture seule avec les données réellement
  autorisées et disponibles ;
- ferme le lot d'écran MVP-0 sans créer de ledger, de prestataire de payout ou
  de nouvelle règle financière ;
- laisse `CPT-01`, portefeuille, collecte, payout et la partie financière
  historique d'`ENS-05` en V1 ;
- nécessite de confirmer le contrat des champs visibles et les états de
  lecture, mais ne dépend pas d'un moteur de paiement.

### Option B — `ENS-05 = payout/finance V1`, profil différé

Impacts :

- maintient le profil enseignant hors du MVP-0 ;
- ouvre un lot finance plus large : ledger, calcul payable, choix du
  prestataire, webhooks, idempotence, verrou de modification et contrôles
  comptables ;
- conserve le risque qu'une route ou une fiche nommée `ENS-05` soit interprétée
  comme un écran manquant tant que la décision de nomenclature n'est pas
  répercutée ;
- ne doit pas être commencé avant les décisions D08 et le périmètre finance
  V1.

### Décision opérateur requise

Écrire une seule formulation explicite :

```text
D01 = [ ] Option A : profil enseignant MVP-0, payout/finance V1
      [ ] Option B : payout/finance V1 sous ENS-05, profil différé
```

Références : `docs/HANDOFF.md §10.2, §10.4, §10.5` ;
`docs/design/08-catalogue-ecrans.md` ; `docs/architecture/decisions.md
ADR-003`.

## D02 — `ADM-03` : séquestre et exports MVP-0 ou V1

**Statut : `BLOCKED`**

Les sources se contredisent : certaines réintroduisent `ADM-03` au MVP-0,
alors que le parcours produit le reporte avec les exports. Ce lot ne peut pas
être classé par simple lecture de l'ancien catalogue.

### Option A — `ADM-03 = MVP-0`

Impacts :

- ajoute une demande d'export bornée par périmètre et colonnes, avec justification
  et approbation ;
- impose génération côté serveur, bucket privé, URL signée courte/à usage
  unique, pagination/limites côté serveur, audit et rétention ;
- augmente le périmètre migration/RLS/Edge Function et la surface de données
  sensibles avant la clôture MVP-0 ;
- exige une recette de non-fuite et d'approbation, pas seulement un bouton
  d'export.

### Option B — `ADM-03 = V1`

Impacts :

- garde l'écran, le séquestre et les exports hors du MVP-0 ;
- permet de clôturer le MVP-0 sans ouvrir une nouvelle surface d'extraction
  sensible ;
- laisse les opérateurs sans export produit pendant le MVP-0 et demande de
  maintenir le statut différé dans le catalogue et le handoff ;
- interdit toute implémentation opportuniste d'un export local ou d'une URL
  publique en attendant V1.

### Décision opérateur requise

```text
D02 = [ ] MVP-0
      [ ] V1
```

Références : `docs/HANDOFF.md §10.4, §10.5` ;
`docs/produit/parcours-utilisateurs.md §5` ;
`docs/design/08-catalogue-ecrans.md` ; `docs/architecture/decisions.md
ADR-003`.

## D03 — `CTR-03` : grille d'audit MVP-0 ou V1

**Statut : `BLOCKED`**

Le parcours produit indique qu'en MVP-0 le contrôleur observe et signale mais
ne note pas. D'autres sources ont réintroduit la grille d'audit dans le
périmètre MVP-0. `CTR-02` observation invisible et journalisation ne valent
pas décision pour `CTR-03`.

### Option A — `CTR-03 = MVP-0`

Impacts :

- ajoute une grille de notation/évaluation après observation ;
- nécessite de définir critères, anonymat, destinataire des signalements,
  droits de lecture, audit et conservation avant le code ;
- augmente le risque de réidentifier un élève ou un enseignant si la grille
  expose plus que la projection autorisée ;
- demande des tests RLS et une recette métier distincts de la simple entrée
  invisible en salle.

### Option B — `CTR-03 = V1`

Impacts :

- conserve `CTR-02` et son journal d'accès sans livrer de notation en MVP-0 ;
- permet de fermer le MVP-0 avec un contrôleur observateur, non évaluateur ;
- reporte les critères, le workflow de signalement et les exports/rapports
  associés à une spécification V1 ;
- interdit de remplacer la grille absente par un formulaire ad hoc ou une
  écriture dans le journal d'audit.

### Décision opérateur requise

```text
D03 = [ ] MVP-0
      [ ] V1
```

Références : `docs/HANDOFF.md §10.4, §10.5` ;
`docs/produit/parcours-utilisateurs.md §4` ;
`docs/design/08-catalogue-ecrans.md` ; `docs/architecture/decisions.md
ADR-011`.

> **Point de coordination D02/D03 :** l'opérateur peut choisir MVP-0 pour un
> sujet et V1 pour l'autre. Toute combinaison est valide seulement si elle est
> écrite séparément (`D02 = ...`, `D03 = ...`).

## D04 — Canal du Coran partagé (N6)

**Statut : `BLOCKED`**

Le contenu partagé est une position/session, pas la progression personnelle de
l'élève. Le transport choisi doit être autorisé par la séance et ne doit pas
permettre à l'enseignant d'écraser silencieusement la position personnelle.

### Option A — LiveKit Data

Impacts :

- très proche de la séance active et cohérent avec l'accès déjà porté par le
  jeton de room ;
- convient à une commande enseignant → participants présents, avec faible
  latence ;
- ne constitue pas une source durable : reconnexion, historique et reprise
  exigent un état courant renvoyé par un participant ou stocké séparément ;
- le mode partagé cesse d'être disponible hors de la room, et le protocole de
  version/conflit doit être défini.

### Option B — Supabase Realtime

Impacts :

- réutilise Supabase, sa RLS, son journal et les canaux déjà admis par la
  documentation contenu ;
- permet de persister un état partagé et de le relire après reconnexion, sous
  réserve d'un schéma et de policies explicites ;
- ajoute une subscription backend pour l'état de classe, avec gestion de
  fraîcheur, doublons, ordre et concurrence ;
- le contrôle d'accès ne doit pas reposer sur le nom du canal : la RLS et la
  validation serveur restent nécessaires.

### Option C — Autre ou hybride, à spécifier

Exemple de découpage possible : état durable autoritatif dans Supabase,
notification instantanée par LiveKit Data. Impacts : meilleure reprise
potentielle, mais deux transports à réconcilier, deux chemins d'erreur, et
besoin d'une règle claire pour les versions concurrentes. Cette option ne doit
pas devenir un choix par défaut sans contrat de source de vérité, TTL, replay,
offline et autorisations.

### Décision opérateur requise

```text
D04 = [ ] LiveKit Data
      [ ] Supabase Realtime
      [ ] Autre/hybride : _________________________________
```

Références : `docs/HANDOFF.md §10.2, §10.5` ;
`docs/architecture/decisions.md ADR-020` ;
`docs/produit/bibliotheque-contenu.md §Confrontation avec les décisions` ;
`docs/design/08-catalogue-ecrans.md` (N6).

## D05 — Acteurs autorisés à corriger ou excuser une présence

**Statut : `BLOCKED`**

La documentation de l'écran borne le geste à l'enseignant et à
l'administration, et exclut le tuteur. Le rôle exact de chaque acteur reste à
écrire : corriger et excuser peuvent avoir des autorisations différentes.

### Option A — Enseignant et administration peuvent décider

Impacts :

- correction rapide par l'enseignant de sa propre séance ;
- administration conserve un pouvoir de reprise/escalade ;
- exige une borne de périmètre (ses séances seulement pour l'enseignant), une
  journalisation de l'auteur et un affichage du nouvel état ;
- augmente le risque de conflit d'intérêts sur la paie, à compenser par audit,
  fenêtre temporelle et éventuellement validation administrative.

### Option B — Enseignant propose, administration valide

Impacts :

- séparation plus nette entre constat de cours et décision qui peut affecter
  la paie ;
- ajoute un état de demande, une file de validation et un délai opérationnel ;
- évite qu'une UI enseignant écrive directement un état final, mais demande un
  contrat de rejeu/idempotence et une UX de suivi.

### Option C — Administration seulement

Impacts :

- contrôle central et séparation forte pour les corrections sensibles ;
- charge opérationnelle et délai plus élevés ;
- l'enseignant peut seulement consulter ou signaler une anomalie ;
- nécessite une projection lisible du contexte sans exposer au tuteur le motif
  administratif.

### Invariants à confirmer ou maintenir explicitement

Le tuteur et l'élève ne corrigent ni n'excusent une présence. Le contrôleur
reste observateur/auditeur dans les options courantes ; l'autoriser à écrire
créerait une séparation de fonctions supplémentaire à arbitrer explicitement.

### Décision opérateur requise

```text
D05 = Corriger : [ ] enseignant dans ses séances + administration
                  [ ] enseignant propose, administration valide
                  [ ] administration seulement
      Excuser   : [ ] mêmes acteurs que ci-dessus
                  [ ] règle distincte : ________________________
      Contrôleur peut écrire : [ ] oui, périmètre ______________
                               [ ] non
```

Références : `docs/HANDOFF.md §10.2, §10.5` ;
`docs/design/08-catalogue-ecrans.md` (présence et suivi foyer) ;
`docs/architecture/decisions.md ADR-020`.

## D06 — Motif et délai de correction/excuse

**Statut : `BLOCKED`**

Le motif obligatoire, la confirmation et l'entrée de journal sont déjà des
contraintes documentées. Le vocabulaire accepté, la longueur minimale et la
fenêtre après la séance ne le sont pas assez pour coder sans choix.

### Motif — options

| Option | Impacts |
| :-- | :-- |
| Liste fermée de motifs | Données cohérentes et auditables ; moins de souplesse pour les cas non prévus. |
| Liste fermée + commentaire obligatoire | Bon compromis pour statistiques et contexte ; validation et rétention d'un texte sensible à définir. |
| Texte libre obligatoire, longueur minimale | Mise en œuvre simple et souple ; qualité et comparabilité moindres, risque de motifs vagues. |

Quel que soit le choix, le serveur doit refuser vide/blanc, rattacher le motif
à l'état précédent et au nouvel état, et journaliser auteur, séance,
participant, horodatage et source. Le tuteur ne voit pas le motif par défaut.

### Délai — options

| Option | Impacts |
| :-- | :-- |
| Fenêtre courte, par exemple 24 h | Réduit les corrections rétrospectives ; risque de rater un incident découvert plus tard. |
| Fenêtre opérationnelle, par exemple 7 jours | Laisse le temps de vérifier la séance ; conservation et rapprochement de paie plus complexes. |
| Pas de fermeture stricte, mais dépassement réservé à l'administration | Répare les cas tardifs ; exige justification renforcée, alerte et audit du dépassement. |

Le choix doit préciser séparément la fenêtre de `corrigee_manuel` et celle de
`excusee`, le fuseau/horodatage de référence, le comportement après expiration
et si une correction déjà payée déclenche un ajustement ou seulement un audit.

### Décision opérateur requise

```text
D06 = Motif : [ ] liste fermée
              [ ] liste + commentaire obligatoire
              [ ] texte libre obligatoire, min. ______ caractères
      Correction possible jusqu'à : ______________________________
      Excuse possible jusqu'à : __________________________________
      Après délai : [ ] refus
                    [ ] administration seulement avec motif renforcé
                    [ ] autre : _________________________________
```

Références : `docs/HANDOFF.md §10.2, §10.5` ;
`docs/design/08-catalogue-ecrans.md` ; `docs/architecture/decisions.md
ADR-020`.

## D07 — `child_ui_mode_max_age`

**Statut : `BLOCKED`**

La valeur `8` existe déjà dans `app_config` et est consommée pour dériver le
mode d'interface enfant. Cela ne vaut pas confirmation opérateur. Le mode UI
ne doit pas devenir une nouvelle permission : droits, rôle et âge restent
distincts.

### Option A — confirmer `8`

Impacts :

- aucun changement de valeur de configuration ;
- continuité avec la dérivation actuelle du mode enfant ;
- exige de préciser si « 8 » signifie âge strictement inférieur à 8, âge
  inférieur ou égal à 8, ou âge au moment de la création du profil ;
- le passage au mode standard doit avoir une règle explicite, notamment pour
  les contrôles audio/caméra déjà autorisés par le profil.

### Option B — choisir `7` ou une autre valeur

Impacts :

- change les parcours et la densité d'interface d'une population d'enfants ;
- peut modifier le moment de transition d'affichage, sans modifier à lui seul
  les permissions serveur ;
- doit préciser calcul de l'âge, fuseau/date d'anniversaire, effet sur les
  profils existants et comportement pendant une séance ;
- la valeur reste idéalement dans `app_config`, sans constante Dart ni
  redéploiement obligatoire.

### Décision opérateur requise

```text
D07 = Valeur : ______ ans
      Sémantique : [ ] âge <= valeur
                   [ ] âge < valeur
                   [ ] autre : _________________________________
      Calcul : [ ] à la création du profil
               [ ] recalculé au changement d'âge
               [ ] autre : ____________________________________
```

Références : `docs/HANDOFF.md §10.5` ; `docs/architecture/decisions.md
ADR-016` ; `supabase/migrations/0001_fondations.sql`.

## D08 — Politique de paiement en cas de litige

**Statut : `BLOCKED`**

Le cadre existant décrit une séance de 60 minutes avec un minimum payable à
partir de 45 minutes, mais le registre laisse ouverte la priorité entre ce
minimum et la présence mesurée. Aucun lot de payout ne doit figer cette règle
avant décision.

### Option A — plancher du minimum payable

Une séance éligible au paiement conserve le minimum payable, même si la
présence mesurée est inférieure dans les conditions prévues.

Impacts : protection de l'enseignant contre les pauses, prières, reconnexions
ou limites de mesure ; risque de payer une présence insuffisamment établie ;
exige critères d'éligibilité, preuve serveur, détection d'abus et audit.

### Option B — présence mesurée prioritaire

Le temps validé par les événements serveur de séance détermine le payable,
sans plancher automatique en cas de désaccord.

Impacts : règle directement liée à une preuve mesurée ; risque de pénaliser un
enseignant lors d'une coupure ou d'une mesure incomplète ; exige une définition
de la fenêtre de reconnexion, des événements manquants et de l'appel.

### Option C — hybride : minimum protégé et delta litigieux gelé

Le montant non contesté ou le minimum qualifié est payé, tandis que le delta
entre minimum et présence mesurée est gelé jusqu'à décision.

Impacts : réduit le risque de non-paiement total et le risque de surpaiement ;
ajoute états de litige, rapprochement, journal d'audit, délai de résolution et
autorité de décision ; doit préciser si le gel porte sur le payout entier ou
seulement sur le delta.

### Décisions liées à écrire en même temps

- qui ouvre, instruit et clôt un litige ;
- quels événements serveur font foi et quelle fenêtre de reconnexion s'applique ;
- paiement de la partie non contestée ou gel total ;
- délai d'ouverture et de résolution ;
- effet d'une correction de présence après calcul ou après payout ;
- événements d'audit obligatoires et rétention des preuves audio/présence.

### Décision opérateur requise

```text
D08 = [ ] minimum payable prioritaire
      [ ] présence mesurée prioritaire
      [ ] hybride : ___________________________________________
      Gel : [ ] payout entier
            [ ] seul delta litigieux
            [ ] autre : _______________________________________
```

Références : `docs/HANDOFF.md §10.3, §10.5` ;
`docs/architecture/decisions.md ADR-017 et registre des questions ouvertes` ;
`docs/architecture/etape-5-salle-coran-presence.md`.

## D09 — Source et licence du corpus Coran

**Statut : `BLOCKED`**

La riwaya et l'édition cible sont documentées comme Hafs, Mushaf Al-Madinah du
Complexe du Roi Fahd, 604 pages. La source technique et la licence doivent
toutefois être confirmées dans le handoff avant tout nouveau lot de contenu ou
de diffusion. Le texte, les données de pagination, la police et les notices de
licence doivent être traités séparément dans la vérification.

### Option A — confirmer le corpus importé décrit par ADR-024

Tanzil Project, `quran-uthmani` 1.1 et `quran-data.xml`, sous CC BY 3.0,
importés dans la base ; attribution et lien vers `tanzil.net` conservés ; texte
non modifié.

Impacts :

- fonctionnement hors ligne et version contrôlée après import ;
- attribution obligatoire dans les fichiers dérivés et provenance visible dans
  l'interface ;
- nécessite une vérification écrite de la version, du périmètre exact de la
  licence, de la police `UthmanTahaNaskh` et de la conformité avec l'édition
  visuelle/pagination annoncée ;
- évite de dépendre d'une API révocable ou d'une politique de cache externe.

Cette option est une proposition déjà décrite par `ADR-024`, pas une
confirmation nouvelle pour le présent rapport.

### Option B — API ou fournisseur externe sous contrat

Impacts :

- moins d'opérations d'import et possibilité de contenu fourni par un tiers ;
- dépendance réseau, cache/offline, disponibilité et révocation de contrat ;
- exige licence commerciale écrite pour stockage/redistribution, limites de
  cache, versionnement, SLA et plan de secours ;
- ne doit pas être choisi si ses conditions empêchent le hors-ligne ou le
  stockage durable requis par le produit.

### Option C — autre corpus licencié/importé

Impacts :

- permet de choisir une source dont texte, pagination, police et redistribution
  couvrent exactement le produit ;
- demande preuve de licence, attribution, intégrité des 604 pages, riwaya,
  encodage, police et procédure de mise à jour ;
- peut rendre la migration `0013`, les contrôles d'intégrité et les notices
  existantes incompatibles, donc aucun remplacement silencieux.

### Décision opérateur requise

```text
D09 = Source : [ ] Tanzil quran-uthmani 1.1 + quran-data.xml
                  [ ] fournisseur/API : _________________________
                  [ ] autre corpus importé : ____________________
      Licence/autorisation : ____________________________________
      Police couverte : _________________________________________
      Attribution et URL à afficher : ____________________________
```

Références : `docs/HANDOFF.md §10.2, §10.5` ;
`docs/architecture/decisions.md ADR-020 et ADR-024` ;
`docs/produit/bibliotheque-contenu.md` ; `docs/design/08-catalogue-ecrans.md`
(ELV-04/N6).

---

## Forme minimale d'une décision opérateur

Pour débloquer un lot, l'opérateur doit écrire l'ID, l'option retenue, les
exceptions éventuelles et la date. Exemple de forme, sans valeur préremplie :

```text
Décisions opérateur — 2026-__-__
D01 = ______________________________
D02 = ______________________________
D03 = ______________________________
D04 = ______________________________
D05 = ______________________________
D06 = ______________________________
D07 = ______________________________
D08 = ______________________________
D09 = ______________________________
Exceptions / conditions : ______________________________________
Opérateur : ______________________
```

Après inscription et revue par l'opérateur, le statut de chaque ID pourra
passer individuellement de `BLOCKED` à `DECIDED`. Ce rapport ne déclenche aucun
code, aucune migration, aucun changement de route et aucune mise en production.
