# Contrat backend CPT-BR-18 (séries de trésorerie) et CPT-BR-19 (exports comptables)

Décision de l'orchestrateur, par délégation du directeur, le 11/10/2026. Ce document est la source de
vérité pour les lots Codex 2 X2-17 et X2-18 (Codex2!A103). Il complète les ports Claude, qui ne
changent pas :

- `lib/core/capacites/port_series_tresorerie.dart` (`PortSeriesTresorerie.series()`) ;
- `lib/core/capacites/port_export_rapports.dart` (`exporterRapport`, `exporterSelection`).

Règles communes :

- Aucun calcul financier de référence côté Flutter (DR-08). Tout total, solde, conversion ou
  variation vient du serveur.
- Montants en entiers, en unités mineures (`bigint`), jamais en flottant.
- Rôles autorisés : `admin` et `accountant`, avec `app_account_valid()`. Tous les autres rôles
  voient zéro ligne ou reçoivent `42501`.
- Les RPC de lecture sont en `SECURITY INVOKER` sous RLS. Aucun `service_role`.
- Migrations additives. Toute fonction `SECURITY DEFINER` suit la procédure F86 (md5 `A_CALCULER`).

## 1. Le registre des coffres (prérequis de X2-17)

Le schéma actuel (`wallets`, `wallet_entries`, `payouts`, `fx_rates`) ne connaît pas les coffres.
On ajoute un registre, en ajout seul :

```
public.tresorerie_mouvements
  id               uuid primary key default gen_random_uuid()
  coffre           text not null check (coffre in ('fonds_clients_engages','paie_a_decaisser',
                     'charges_essentielles','taxes_obligations','reserve_strategique',
                     'en_transit','tresorerie_libre'))
  sens             text not null check (sens in ('entree','sortie'))
  montant_minor    bigint not null check (montant_minor > 0)
  devise           text not null check (devise ~ '^[A-Z]{3}$')
  montant_ref_minor bigint not null check (montant_ref_minor > 0)  -- converti, figé à l'insertion
  devise_ref       text not null                                   -- copie de la config au moment T
  survenu_le       timestamptz not null
  transfert_id     uuid null      -- même valeur sur la sortie et l'entrée d'un transfert entre coffres
  source_type      text not null check (source_type in ('encaissement','prestation','remboursement',
                     'payout','transfert_interne','correction'))
  regle            text not null    -- la règle d'alimentation appliquée (ex. 'encaissement->fonds_clients')
  source_id        text null
  note             text null check (char_length(note) <= 500)
  motif            text null       -- obligatoire pour transfert_interne et correction
  cree_par         uuid null       -- null = système (événement de paiement) ; sinon l'admin
  cree_le          timestamptz not null default now()
  unique (source_type, source_id, regle, coffre, sens)
```

- **Devise de référence : le dollar US** (décision du directeur, 11/10/2026). La clé de
  configuration `devise_reference` vaut `USD` ; les unités mineures sont des cents. À l'insertion,
  `montant_ref_minor` est calculé avec le dernier `fx_rates` dont `effective_at <= survenu_le` (de
  `devise` vers `USD`), arrondi au plus proche avec les demi-unités arrondies loin de zéro. Il n'est
  jamais recalculé ensuite. Sans taux disponible : erreur `22023 taux_change_absent`, et le
  paiement source n'est pas perdu (voir la reprise plus bas). Pour une devise déjà en USD, le taux
  vaut 1.

### 1 bis. Alimentation automatique par les paiements (décision du directeur, 11/10/2026)

**Le registre ne se remplit jamais à la main.** Chaque ligne naît d'un événement financier réel,
dans la même transaction que cet événement (trigger serveur ou RPC qui l'enregistre). Ces
fonctions sont `SECURITY DEFINER` si nécessaire, sous la procédure F86. Il n'existe aucune RPC
d'entrée d'argent libre.

| Événement réel | Mouvement(s) dans le registre |
| :--- | :--- |
| Paiement d'une famille **confirmé par le prestataire** (crédit `wallet_entries`, preuve webhook vérifiée, FI-BR-06) ; un retour navigateur ne suffit jamais | entrée dans `fonds_clients_engages` (argent reçu pour des cours pas encore donnés), `source_type = 'encaissement'` |
| Prestation **acquise** : séance terminée et débitée sur le portefeuille (débit `wallet_entries`) | transfert depuis `fonds_clients_engages` : la rémunération due à l'enseignant vers `paie_a_decaisser`, puis le reste réparti selon la **politique d'allocation** en vigueur (`taxes_obligations`, `charges_essentielles`, `reserve_strategique` selon CPT-BR-12), et le solde vers `tresorerie_libre`. Ce sont des lignes liées par `transfert_id`, avec `source_type = 'prestation'` |
| Paiement d'un enseignant demandé (`payouts` → `requested`) | transfert de `paie_a_decaisser` vers `en_transit` |
| Paiement d'un enseignant confirmé (`payouts` → `paid`) | sortie de `en_transit` (argent réellement parti) |
| Paiement d'un enseignant échoué ou annulé (`failed`, `cancelled`) | transfert inverse de `en_transit` vers `paie_a_decaisser` |
| Remboursement d'une famille confirmé | sortie de `fonds_clients_engages`, `source_type = 'remboursement'` |

Règles :

- **Politique d'allocation** : table versionnée `politique_allocation_coffres` (pour mille par coffre,
  date d'effet). Elle est écrite par la Direction seule (admin aal2), auditée, et ne change jamais
  une allocation passée. Aucune valeur codée en dur. Sans politique en vigueur, le reste après la
  paie va en entier vers `tresorerie_libre`, et une alerte « politique d'allocation absente » est
  levée pour la Direction.
- **Rémunération de l'enseignant** : le montant vient du calcul serveur de rémunération déjà en
  place pour la séance. Si aucune source serveur de ce montant n'existe dans le schéma, Codex le
  signale dans l'onglet avant d'écrire quoi que ce soit : on n'invente pas de taux.
- **Idempotence** : `unique (source_type, source_id, regle, coffre, sens)`. Un webhook rejoué ou un
  trigger relancé n'écrit jamais deux fois.
- **Reprise** : si une conversion ou une allocation échoue (taux absent), l'événement source est
  quand même enregistré, et il est noté dans `tresorerie_a_reprendre`. La RPC
  `reprendre_alimentation_tresorerie()` (admin) rejoue ces événements quand le taux existe. Aucune
  somme n'est saisie à la main.
- **Seules interventions humaines permises** :
  - les **transferts internes entre coffres** (CPT-BR-05), via `transferer_entre_coffres(de,
    vers, montant_minor, devise, motif, cle_idempotence)`, en admin aal2, avec les quatre
    interdits de §10.4 refusés par le serveur ;
  - les **corrections** par contre-mouvement d'une ligne existante, avec un motif obligatoire.
  Dans les deux cas, la somme totale détenue ne change pas, ou elle est ramenée à la vérité d'une
  ligne réelle ; jamais d'argent créé.
- Le registre est en ajout seul : pas d'UPDATE ni de DELETE (un trigger les refuse).
- Les 7 valeurs de `coffre` correspondent une à une à l'enum Dart `Coffre`, dans le même ordre.

## 2. X2-17 : `series_tresorerie()` (CPT-BR-18)

RPC sans argument, `SECURITY INVOKER`, en lecture seule, réservée à `admin` et `accountant`. Elle
renvoie un JSON qui suit exactement `SeriesTresorerie`. Tous les montants sont donnés en dollars US (devise
de référence) : `{"mineur": <bigint>, "devise": "<devise_ref>"}`.

- **Fuseau.** Clé de configuration `fuseau_comptable`, `Europe/Paris` par défaut. « Jour » et
  « mois » s'entendent dans ce fuseau.
- **Exclusion des transferts.** Les lignes dont `transfert_id` est non nul sont exclues de toutes
  les entrées et sorties : `mensuel`, `flux30Jours`, `entrees30Jours`, `sorties30Jours` et les
  variations. Elles comptent dans les soldes : `repartition` et `evolution`.
- `repartition` : le solde de chacun des 7 coffres à l'instant présent, soit la somme des entrées
  moins la somme des sorties de `montant_ref_minor`. Les 7 coffres sont toujours présents, dans
  l'ordre de l'enum, même à zéro. Un solde négatif est rendu tel quel : c'est une anomalie à voir,
  pas à masquer.
- `mensuel` : 6 points, du mois le plus ancien au mois en cours inclus. `mois` = premier jour du
  mois (date locale). `entrees` et `sorties` sont toujours positives ou nulles. Un mois vide vaut
  zéro, il n'est pas omis.
- `flux30Jours` : 30 points, de J-29 à aujourd'hui inclus, complétés par des zéros.
- `evolution` : 6 points alignés sur `mensuel`. `detenue` = somme des soldes de tous les coffres
  à la fin du mois (fin du mois local exclue) ; pour le mois en cours, à l'instant présent.
- `entrees30Jours` et `sorties30Jours` : les totaux sur la même fenêtre de 30 jours.
- `variationEntreesPourMille` et `variationSortiesPourMille` : comparaison entre les 30 jours
  courants et les 30 jours précédents (J-59 à J-30), calculée comme
  `round((courant - precedent) * 1000 / precedent)`. Le résultat est `null` si `precedent = 0`.
- Dates en ISO 8601 : `mois` et `jour` en `YYYY-MM-DD`.
- Le masquage des montants (Q-9) reste côté client. Le serveur rend toujours les montants à un rôle
  autorisé.
- Scénario : rôles positifs et négatifs, transfert exclu des flux mais compté dans les soldes,
  conversion figée (un nouveau taux ne change pas l'historique), mois et jours vides présents,
  variation `null` quand la période précédente est vide, bascule de fuseau à minuit local.
- L'adaptateur `SeriesTresorerieSupabase` lit le JSON et produit `FormatException` sur toute clé
  manquante ou tout type faux. Il ne fait aucun calcul.

## 3. X2-18 : exports (CPT-BR-19)

Le port rend une référence et un nombre de lignes. Le serveur produit le fichier : du CSV en
texte, stocké dans le journal, sans objet de stockage.

```
public.exports_comptables
  reference        text primary key       -- 'EXP-' || to_char(now() at time zone fuseau,'YYYYMMDD') || '-' || 6 caractères aléatoires [A-Z0-9]
  perimetre        text not null check (perimetre in ('rapport','selection'))
  periode_debut    date null, periode_fin date null   -- rapport
  identifiants     uuid[] null                         -- sélection
  nb_lignes        int not null
  csv              text not null
  cree_par         uuid not null default auth.uid()
  cree_le          timestamptz not null default now()
  cle_idempotence  text not null, unique (cree_par, cle_idempotence)
```

- Le journal est en ajout seul. RLS : `accountant` lit ses propres exports, `admin` lit tout.
  Personne d'autre n'y accède.
- `exporter_rapport_comptable(p_cle text)` renvoie `{reference, lignes}`. Le périmètre est le mois
  en cours dans `fuseau_comptable`, du premier jour à aujourd'hui. Les lignes sont les
  `tresorerie_mouvements` de la période, triées par `survenu_le` puis `id`.
- `exporter_selection_comptable(p_ids uuid[], p_cle text)` renvoie `{reference, lignes}`. Les
  lignes sont les `payouts` désignés, quel que soit leur statut ; c'est l'écran qui choisit les
  paiements à effectuer. Il faut entre 1 et 500 identifiants, sans doublon ; sinon erreur
  `22023`. Un identifiant inconnu ou invisible pour l'appelant donne aussi l'erreur `22023`.
- **Idempotence.** Une même clé du même utilisateur renvoie la référence existante, sans nouvel
  export.
- **Plafond.** Au-delà de 5 000 lignes, erreur `54000 export_trop_volumineux` ; rien n'est
  journalisé. Un export vide est permis (`lignes = 0`, en-tête seul).
- **Format CSV.** UTF-8 avec BOM (pour Excel), séparateur `;`, fin de ligne `\r\n`, guillemets
  RFC 4180. Toute cellule qui commence par `=`, `+`, `-`, `@`, une tabulation ou un retour chariot
  est préfixée d'une apostrophe (protection contre l'injection de formules). Les montants sont
  donnés deux fois : en unités mineures et sous forme décimale, avec un point et le nombre de
  décimales de la devise selon `private.devise_decimales` (ISO 4217, migration
  `20261021210300_fi_devises_decimales_iso4217.sql`). L'export appelle cette fonction, depuis une
  fonction `SECURITY DEFINER` (voir « Qui appelle » ci-dessous) ; il ne recopie aucune liste de
  devises (FI-DEV-1, 21/10/2026 : une liste recopiée ici donnait 2 décimales au GNF).
  - En-tête du rapport : `date;coffre;sens;montant;montant_mineur;devise;montant_ref;montant_ref_mineur;devise_ref;transfert;source_type;source_id;note`
  - En-tête de la sélection : `paiement_id;cree_le;statut;montant;montant_mineur;devise;methode_type;beneficiaire_profil_id`
  - Dates en ISO 8601 dans `fuseau_comptable`. Aucune donnée de `payout_methods.details` n'est
    exportée : uniquement `kind`.
- **Qui appelle `private.devise_decimales`.** Aucun rôle client ne l'atteint : ni `USAGE` sur le
  schéma `private`, ni `EXECUTE` pour `anon`, `authenticated`, `service_role` ou `agent_ro`.
  L'appel part donc d'une fonction `SECURITY DEFINER`, propriétaire `postgres`, avec
  `search_path = ''`, sous la procédure F86 (garde `admin` ou `accountant` avec
  `app_account_valid()`, empreinte md5) : soit les RPC d'export elles-mêmes, soit la fonction de
  formatage décimal passée en `DEFINER`. Une fonction `SECURITY INVOKER` appelée par un compte
  connecté échoue en `42501` (« permission denied for schema private »). On n'accorde jamais
  `USAGE` sur `private` ni `EXECUTE` sur `private.devise_decimales` à un rôle client pour
  contourner ce refus.
- **Reprise de la branche `codex2/x2-18` (`bf78725d`).** Elle n'est pas dans la pile. Telle
  quelle, elle aurait deux défauts. D'abord, `public.montant_comptable_decimal` recopie l'ancienne
  table (GNF et KRW à 2 décimales). Ensuite, cette fonction et `public.exporter_rapport_comptable`
  sont `SECURITY INVOKER` avec `EXECUTE` pour `authenticated` : un simple appel à
  `private.devise_decimales` y échouerait en `42501`. Avant toute reprise, il faut retirer la table
  recopiée et faire passer l'appel par une fonction `DEFINER` comme ci-dessus.
- `telecharger_export_comptable(p_reference text)` renvoie le texte CSV, sous les mêmes droits que
  le journal. Il servira au téléchargement quand l'écran l'ajoutera ; le port actuel ne l'appelle
  pas encore.
- Scénario : rôles positifs et négatifs, idempotence, plafond, sélection vide ou trop grande,
  identifiant étranger, injection de formule neutralisée, BOM et séparateur, aucune donnée de
  `details`.
- L'adaptateur `ExportRapportsSupabase` mappe `{reference, lignes}` vers `ResultatExport`.

## 4. Hors périmètre, à décider plus tard

- Le choix de la période du rapport dans l'écran : le port actuel n'a pas de paramètre de période.
  Ce sera un ajout au port, côté Claude, s'il est demandé.
