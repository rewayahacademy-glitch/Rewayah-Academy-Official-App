# Contrat métier Finance / Configuration — addendum au gel d'architecture

**Statut :** décision de cartographie, addendum à `docs/architecture/ADMIN_IA_AUDIT.md`.
Comme le document qu'il complète, cet addendum ne modifie aucune route, aucun
écran, aucun droit ni service métier : il fige le périmètre et les routes
canoniques avant tout lot d'implémentation.

**Origine :** l'audit du 19/09/2026 gelait Finance et Configuration sans
activation « avant contrat métier et autorisation » (§ Correction de présence,
galerie et fonctions non activées). L'opérateur a fourni ce contrat le
19/09/2026 : deux domaines strictement séparés par nature de responsabilité,
jamais par écran d'origine.

## La règle de séparation, telle que donnée

> **Finance** contient des données et opérations financières : Vue d'ensemble,
> Tarification, Bourses, Factures, Paiements, Crédits, Rémunération
> enseignants, Coûts et résultats.
>
> **Configuration** contient uniquement des règles globales du système :
> Académie, Règles, Fonctionnalités, Classe en ligne, Notifications,
> Localisation, Conservation des données.
>
> **Interdiction absolue :** ne jamais placer le même réglage dans Profil,
> Dashboard, Finance et Configuration. Chaque configuration possède une seule
> route canonique.

Le critère de tri n'est pas l'écran où une donnée apparaît aujourd'hui, c'est
sa nature : un paiement réel est une opération Finance même s'il est aujourd'hui
saisi à la main ; un seuil qui change le comportement de toute la plateforme est
une règle Configuration même s'il vit aujourd'hui dans une migration SQL sans
interface.

## Ce que l'audit du code a trouvé : le doublon n'est pas encore commis

Recherche exhaustive de tout réglage déjà exposé qui recouperait un des quinze
items ci-dessus. **Aucune duplication existante trouvée** — l'interdiction
porte donc sur des écrans à ne pas construire deux fois, pas sur un doublon à
défaire :

- `compte/reglages` (`ReglagesComptePage`) expose déjà « Notifications » et
  « Langue et région », mais ce sont des **préférences personnelles locales**
  (bascule silencieuse par élève, thème, réduction d'animation) — déjà noté
  hors périmètre par l'audit du 19/09 (« les intitulés peuvent prêter à
  confusion avec la future Configuration de l'académie, mais les
  responsabilités sont différentes »). **Aucune modification à y faire.**
  Configuration > Notifications désignera les **modèles globaux** envoyés par
  la plateforme (contenu, déclencheurs), jamais la bascule d'un utilisateur.
  Configuration > Localisation désignera les **défauts de plateforme**
  (fuseau/langue par défaut d'un nouveau foyer), jamais la langue d'affichage
  choisie par une personne.
- `/comptable` (rôle `AppRole.accountant`) est un **portail de rôle**, pas un
  écran Admin — confirmé par l'audit du 19/09, interface reportée en V1
  (ADR-003). Finance (Admin) et l'espace Comptable restent deux surfaces
  distinctes même une fois Finance construite.

## Statut d'activation par item — ce qui est prêt, ce qui est bloqué

| Domaine | Item | Route canonique | État du schéma | Statut d'activation |
| :--- | :--- | :--- | :--- | :--- |
| Configuration | Académie | `/admin/configuration/academie` | Aucun — nom/contact codés en dur (`app.dart`, i18n) | **À modéliser** avant écran (pas de table) |
| Configuration | Règles | `/admin/configuration/regles` | `app_config` (existe, RLS admin déjà posée) + `rule_overrides` | **Construit** (`ADM-15`, 19/09) |
| Configuration | Fonctionnalités | `/admin/configuration/fonctionnalites` | `app_config` (existe, RLS admin déjà posée) | **Construit** (`ADM-16`, 19/09) |
| Configuration | Classe en ligne | `/admin/configuration/classe-en-ligne` | `video_config` (existe) ; `video_config_lire()` existe, **aucune fonction d'écriture** | **Prêt côté lecture, RPC d'écriture à créer** |
| Configuration | Notifications | `/admin/configuration/notifications` | Aucun — pas de table de modèles | **À modéliser** avant écran |
| Configuration | Localisation | `/admin/configuration/localisation` | Aucun défaut plateforme ; seuls des champs par foyer/récurrence existent (`households.timezone`, `recurrence_rules.timezone_iana`) | **À modéliser** avant écran |
| Configuration | Conservation des données | `/admin/configuration/conservation-donnees` | `app_config.recording_retention_days` (existe) ; `kyc_retention_days` / `kyc_documents.purge_at` (existent) | **Construit** (`ADM-17`, 19/09) |
| Finance | Vue d'ensemble | `/admin/finance` | Agrégation de ce qui suit | Attend que les items sous-jacents existent |
| Finance | Tarification | `/admin/finance/tarification` | Aucun — pas de catalogue de prix versionné trouvé | **Bloqué ADR-003** (module finance reporté V1) |
| Finance | Bourses | `/admin/finance/bourses` | Aucun | **Bloqué ADR-003** |
| Finance | Factures | `/admin/finance/factures` | Aucun (« Facturation et reçus automatiques » explicitement reporté) | **Bloqué ADR-003** |
| Finance | Paiements | `/admin/finance/paiements` | `wallets`, `wallet_entries` (existent, sans interface) ; `profiles.access_until` prévu par l'ADR-003 pour le contournement manuel MVP-0 | **Bloqué ADR-003**, sauf si l'opérateur avance explicitement la V1 |
| Finance | Crédits | `/admin/finance/credits` | `wallet_entries.reference_type = 'credit'` (existe) | **Bloqué ADR-003** |
| Finance | Rémunération enseignants | `/admin/finance/remuneration` | `payouts`, `payout_methods`, `fx_rates` (existent) ; payout provider explicitement non retenu (ADR-007, Flutterwave écarté) | **Bloqué ADR-003 et ADR-007** (aucun prestataire de payout retenu) |
| Finance | Coûts et résultats | `/admin/finance/couts-resultats` | Aucun | **Bloqué ADR-003** |

**Lecture du tableau :** Configuration n'a jamais été reportée par aucun ADR —
seul le gel du 19/09 attendait un contrat métier, maintenant fourni. Finance,
elle, reste sous le coup d'une décision antérieure et explicite (ADR-003 :
« Seuls la finance et le système d'objectifs élèves attendent la V1 » ;
ADR-007 : aucun prestataire de payout retenu). Ce contrat métier fixe **où**
Finance vivra le jour où elle sera construite ; il n'avance pas seul la date
de son démarrage, qui reste une décision de l'opérateur distincte de ce
document.

## Règles de mise en œuvre ultérieure

1. Un item marqué « prêt à construire » se raccorde à sa table existante ; il
   ne crée jamais une seconde table ou un second `app_config` parallèle.
2. Un item marqué « à modéliser » exige une décision de schéma (nouvelle
   migration, éventuellement un ADR si le choix structure autre chose que
   cet écran) avant tout code d'interface — même règle que « le schéma
   anticipe, l'interface attend » de l'ADR-003.
3. Aucun écran Finance ne se construit avant que l'opérateur ait explicitement
   avancé la date de la V1 finance ou autorisé un sous-ensemble précis
   (par exemple : Paiements en lecture seule sur `access_until`, sans
   toucher aux payouts). Ce document ne vaut pas cette autorisation.
4. La sidebar Admin ne change pas de comportement pour Finance tant qu'aucun
   écran n'existe (`AdminDomaine.finance.chemin` reste `null`, § gel du
   19/09). Configuration, elle, peut recevoir une route dès le premier écran
   livré (probablement Règles ou Conservation des données, les deux mieux
   couverts par le schéma actuel).
5. Chaque nouvel écran suit le gabarit `SousNavigationDomaine` déjà posé par
   Pédagogie (`ongletsPedagogie()`), avec son équivalent
   `ongletsConfiguration()` / `ongletsFinance()` dans
   `lib/core/admin/admin_domaine.dart`.

## Suite proposée, non déclenchée par ce document

- **Lot CFG-01 — construit (19/09)** : Règles (`ADM-15`), Fonctionnalités
  (`ADM-16`), Conservation des données (`ADM-17`) — trois écrans branchés sur
  `app_config` existant, RLS déjà posée, aucun risque financier. Active
  `AdminDomaine.configuration` (`chemin` non nul) et
  `ongletsConfiguration()` dans `lib/core/admin/admin_domaine.dart`. Service
  partagé `lib/core/admin/service_configuration.dart`, widgets d'édition
  `lib/core/admin/config_edition.dart`. Règles édite le défaut de plateforme,
  jamais la surcharge par profil (`ADM-06`, `rule_overrides`) — deux routes
  canoniques distinctes, aucun doublon.
- **Lot CFG-02** : Classe en ligne — nécessite d'abord une fonction d'écriture
  `video_config` côté serveur (aucune n'existe), avec la même prudence que
  l'audit ADR-023 sur le risque de couper une salle en cours de séance.
- **Lot CFG-03** : Académie, Notifications, Localisation — nécessite une
  décision de schéma avant tout écran.
- **Finance** : n'entre dans aucun lot tant que l'opérateur n'a pas
  explicitement avancé la V1 ou délimité un sous-ensemble.
