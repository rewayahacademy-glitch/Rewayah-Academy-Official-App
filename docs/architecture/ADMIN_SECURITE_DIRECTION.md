# Contrat métier Sécurité / Direction / Accueil — addendum au gel d'architecture

**Statut :** décision de cartographie, addendum à `docs/architecture/ADMIN_IA_AUDIT.md`,
même format que `docs/architecture/ADMIN_FINANCE_CONFIGURATION.md`. Comme les
deux documents qu'il complète, cet addendum ne construit aucun écran par
lui-même : il fige le périmètre et les routes canoniques avant tout lot
d'implémentation, sauf la seule correction déjà exécutée et notée en fin de
document (compteur « rapports manquants »).

**Origine :** mission reçue le 19 septembre 2026 (soir), « Sécurité +
Direction + Dashboard — MISSION : FINALISER LA HIÉRARCHIE ADMIN ».

## Le contrat, tel que donné

> **SÉCURITÉ ET AUDIT :**
> - Journal
> - Accès sensibles
> - Exports
> - Sessions et appareils
> - Incidents sécurité
>
> Aucune configuration métier générale ici.
>
> **DIRECTION, uniquement si autorisé :**
> - Objectifs
> - Indicateurs
> - Prévisions
> - Scénarios
> - Recommandations
> - Décisions
> - Advisor
>
> **ACCUEIL :**
>
> Accueil n'est PAS une seconde navigation. Il affiche seulement : priorités,
> anomalies, KPI essentiels, éléments nécessitant une action, raccourcis vers
> les routes canoniques. Un élément du dashboard ouvre toujours la fonction
> réelle. Exemple : « 7 rapports manquants » → Opérations > Séances → filtre
> rapports manquants. Il est interdit de créer une page spéciale « rapports
> manquants » derrière le dashboard. Même principe pour KYC, diagnostics,
> absences, paiements, incidents, groupes à risque. Supprimer toute
> duplication restante.

## Sécurité et audit — statut d'activation par fonction

Cinq fonctions demandées ; l'audit du 19/09 n'en avait cartographié que deux
(Journal, Accès des agents IA). Recherche exhaustive du schéma Supabase avant
d'écrire cette ligne — même réflexe que pour Finance/Configuration et que
Pédagogie ([[feedback_verifier_document_officiel_avant_audit]]) :

| Fonction | Route canonique | État actuel | Schéma trouvé | Statut d'activation |
| :--- | :--- | :--- | :--- | :--- |
| Journal | `/admin/securite-audit/journal` | Construit (`ADM-04`) | `audit_logs` (`0001`/`0009`), chaîne de hachage vérifiable | **Construit** |
| Accès sensibles | — | Non distinct aujourd'hui | `log_sensitive_access()` (`0001`) alimente déjà `audit_logs` — **une quarantaine de sites d'appel** dans les migrations `0001` à `0024` (KYC, appairage, groupes, pédagogie, agents…) | **Ambigu, voir note ci-dessous — rien construit** |
| Exports | — | Non implémenté | Aucune table de séquestre/export | **Bloqué** — contradiction de périmètre `ADM-03`/`CTR-03` jamais tranchée (`docs/HANDOFF.md` §10.4/10.5) |
| Sessions et appareils | `/admin/securite-audit/appareils` (proposée) | Non implémenté côté Admin | `public.devices` (`0001`) : `device_fingerprint`, `platform`, `paired_at`, `revoked_at`, policy `devices_admin_all` déjà posée ; `revoquer_appareil()` (`0004`) **déjà admin-capable** | **Prêt à construire**, aucune migration requise |
| Incidents sécurité | `/admin/securite-audit/incidents` (proposée) | Non implémenté côté Admin | `public.sessions.status in ('tech_failure','teacher_absent','student_absent')` déjà **compté** par `indicateurs_admin().incidents_24h` (`0015`) ; aucune fonction ne **liste** le détail | **Prêt côté données, une RPC de liste à écrire** (pas de nouvelle table) |

### Note — « Accès sensibles » n'est pas encore un concept distinct du Journal

`log_sensitive_access()` est la fonction qui **remplit** `audit_logs` depuis la
toute première migration : `kyc_read`, `kyc_decision`, `appareil_revoque`,
`affectation_attribuee`, `groupe_cloture`, etc. — c'est-à-dire que le Journal
(`ADM-04`) **est déjà**, techniquement, l'écran « Accès sensibles » : mêmes
lignes, même table, mêmes filtres acteur/action/période.

Deux lectures possibles du contrat, et ni l'une ni l'autre n'est tranchée
ici :

1. **« Accès sensibles » = le Journal existant**, sous un intitulé différent
   ou avec un filtre pré-appliqué sur un sous-ensemble d'actions (par exemple
   les seules lectures/décisions KYC et révocations, par opposition aux
   mutations métier générales). Dans ce cas, il n'y a **rien à construire** :
   au plus un filtre par défaut sur l'écran `ADM-04`.
2. **« Accès sensibles » = un concept nouveau**, distinct du Journal (par
   exemple : qui a consulté quel dossier, quelle salle, quel enregistrement —
   une trace de **lecture**, pas seulement d'écriture). C'est explicitement
   ce que `0009_journal_audit.sql` signale comme **non fait et pourquoi** :
   « la consultation du journal ne s'inscrit pas au journal », et renvoie la
   décision à l'opérateur (question 27, `docs/architecture/decisions.md`).

Construire un second écran qui recopierait le Journal violerait la règle
« une seule route canonique par concept » du contrat Finance/Configuration.
**Aucun écran n'est construit pour « Accès sensibles » tant que l'opérateur
n'a pas choisi entre ces deux lectures.**

## Direction — sept fonctions, toutes réservées

| Fonction | Route canonique | Schéma | Statut |
| :--- | :--- | :--- | :--- |
| Objectifs | `/admin/direction/objectifs` | Aucun | Réservé |
| Indicateurs | `/admin/direction/indicateurs` | Aucun | Réservé |
| Prévisions | `/admin/direction/previsions` | Aucun | Réservé |
| Scénarios | `/admin/direction/scenarios` | Aucun | Réservé |
| Recommandations | `/admin/direction/recommandations` | Aucun | Réservé |
| Décisions | `/admin/direction/decisions` | Aucun | Réservé |
| Advisor | `/admin/direction/advisor` | Aucun | Réservé |

Le contrat dit « uniquement si autorisé » : c'est **déjà exactement** la règle
6 du gel d'architecture d'origine — « Direction ne doit pas être ajoutée par
`if (role == admin)`. Son affichage attend la capacité fournie par
l'autorisation existante ; en son absence, ni la route ni le libellé ne sont
exposés. » Vérifié dans le code actuel :
`AdminDomaine.direction.chemin` vaut `null` et `domainesAdmin()` n'inclut
`AdminDomaine.direction` que `if (voitDirection)`
(`lib/core/admin/admin_domaine.dart`), et `voitDirection` n'a aujourd'hui
aucune source — `SessionState.peutVoirDirection` n'existe pas.

**Rien à construire.** Le domaine est déjà correctement invisible. Cette liste
de sept fonctions fixe seulement leur nom et leur route future, pour le jour
où une capacité serveur existera — elle ne fait pas partir de chantier.

## Accueil — audit de duplication restante (19 septembre 2026, soir)

Relecture complète de `lib/features/admin_tableau/tableau_de_bord_page.dart`
à la lumière du contrat : la quasi-totalité de la règle « pas de seconde
navigation » était déjà tenue par le gel d'architecture du 19/09 matin
(lot IA-01, `b3be532`) — six compteurs zéro-compris, une liste « à traiter »
triée par ancienneté, deux raccourcis contextuels vers Personnes et Sécurité,
aucun regroupement « Outils » autonome.

**Un seul écart trouvé, et corrigé dans ce lot** (pas une migration, un
raccord de navigation) : le compteur « rapports manquants » restait sans
`onPress` alors que `Pédagogie > Qualité` (`ADM-14`) existe et l'alimente
depuis la nuit précédente (`e3faea8`) — le compteur mort le plus ancien du
produit (présent depuis la toute première migration, jamais consommé par
aucun écran, `docs/architecture/ADMIN_IA_AUDIT.md` l'avait déjà signalé comme
non cliquable « tant qu'une fonction réellement livrée » n'existe pas).
Exactement l'exemple donné par le contrat (« 7 rapports manquants → la
fonction réelle, avec son filtre ») : le tap ouvre maintenant
`/admin/pedagogie/qualite`, qui affiche par défaut le filtre « ouvertes »
groupé par type — le groupe « Rapport manquant » y est déjà visible sans
filtre supplémentaire à construire. **Aucune page dédiée créée** : le contrat
l'interdit explicitement, et `QualitePage` existait déjà.

Les deux compteurs restants (« incidents », « comptes échus ») **restent
inertes**, et c'est correct selon la règle 5 du gel d'architecture :
« Aucun domaine absent ne reçoit un compteur actionnable ». Ils gagneront leur
`onPress` quand, respectivement, `Incidents sécurité` (ci-dessus) et un filtre
canonique « accès échu » sur `Personnes > Comptes` existeront réellement — pas
avant.

## Règles de mise en œuvre ultérieure

1. `Sessions et appareils` et `Incidents sécurité` suivent le gabarit déjà
   posé par Configuration : nouvelle entrée dans `ongletsSecuriteAudit()` (à
   créer sur le modèle d'`ongletsConfiguration()`,
   `lib/core/admin/admin_domaine.dart`), route ajoutée à
   `AdminDomaine.securite` sans changer `chemin` (qui reste la racine du
   domaine, redirigeant vers Journal, sa fonction primaire).
2. `Sessions et appareils` ne crée ni nouvelle table ni nouvelle RPC
   d'écriture : lecture directe de `public.devices` (RLS `devices_admin_all`
   déjà posée) et appel de `revoquer_appareil()` (déjà `admin`-capable,
   déjà journalisé). Seule une RPC de **liste** paginée/filtrée est
   éventuellement à écrire si une lecture directe par le client s'avère
   insuffisante (tri, comptage) — à confirmer au moment du lot.
3. `Incidents sécurité` ajoute **une seule fonction** de liste (`security
   definer`, réservée `admin`, sur le modèle d'`anomalies_qualite()`,
   `0024`) au-dessus de `public.sessions` déjà filtrée par
   `indicateurs_admin()` — jamais une nouvelle table, jamais un doublon du
   compteur existant.
4. `Exports` (`ADM-03`) ne se construit pas avant que l'opérateur tranche son
   périmètre contre `CTR-03` (`docs/HANDOFF.md` §10.4/10.5). Ce document ne
   vaut pas cette décision.
5. `Accès sensibles` ne se construit pas avant que l'opérateur choisisse entre
   les deux lectures de la note ci-dessus. Un filtre par défaut sur `ADM-04`
   est réversible en une ligne ; un second écran ne l'est pas.
6. `Direction` ne se construit pas avant qu'une capacité serveur existe pour
   `SessionState.peutVoirDirection`. Aucun des sept écrans ne démarre en
   parallèle « au cas où » : la règle 6 du gel d'architecture l'interdit
   explicitement.
7. Chaque nouveau raccourci d'Accueil transporte une route canonique et, si
   nécessaire, un filtre sérialisable — jamais une liste calculée localement
   (règle 2 du gel d'architecture, déjà appliquée au raccourci « rapports
   manquants » ci-dessus : aucun paramètre de filtre, la vue par défaut de
   `ADM-14` suffit).

## Suite proposée, non déclenchée par ce document

- **Correction immédiate — faite dans ce lot** : raccord du compteur
  « rapports manquants » d'`ADM-01` vers `ADM-14`
  (`lib/features/admin_tableau/tableau_de_bord_page.dart`).
- **Lot SEC-01 — Sessions et appareils** (`ADM-18` proposé) : liste des
  appareils appairés, filtre actif/révoqué, révocation admin. Même taille que
  `CFG-01` : schéma et RLS déjà là, aucun risque de migration.
- **Lot SEC-02 — Incidents sécurité** (`ADM-19` proposé) : liste détaillée des
  séances en échec technique/absence sur une fenêtre glissante, une RPC de
  liste au-dessus de `public.sessions`. Une fois construit, le compteur
  « incidents » d'`ADM-01` gagne son `onPress`.
- **Accès sensibles** : n'entre dans aucun lot avant décision opérateur entre
  « filtre du Journal existant » et « nouveau concept de trace de lecture ».
- **Exports (`ADM-03`)** : n'entre dans aucun lot avant décision opérateur sur
  son périmètre contre `CTR-03`.
- **Direction** : n'entre dans aucun lot avant qu'une capacité serveur
  `peutVoirDirection` existe. Les sept routes de ce document servent de cible
  le jour où elle existera.
