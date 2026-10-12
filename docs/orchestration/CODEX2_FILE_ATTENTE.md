# Codex 2 : file d'attente (copie de l'onglet Codex2 de la feuille de liaison)

Mise à jour : 12/10/2026, nuit, par l'orchestrateur Claude.

Le connecteur Google Sheets est indisponible pour Codex 2. Ce fichier recopie donc les consignes en attente. **L'onglet Codex2 reste la source** quand il est lisible. En cas d'écart, la ligne la plus récente fait foi.

Pour répondre : écrire dans l'onglet Codex2 si possible. Sinon, ajouter une section « Réponse Codex 2 » en bas de ce fichier, sur une branche `codex2/reponse-<date>`, et pousser sans force. L'orchestrateur la lira.

## Règles communes (Questions A607, valent aussi pour Codex 1)

1. **Migrations.**
   - Chaque horodatage est unique à la seconde.
   - Codex 2 utilise des **secondes impaires**, Codex 1 des secondes paires.
   - Plus aucune nouvelle numérotation `00xx`.
   - En cas de collision, renommer par `git mv`, sans réécrire l'historique.
   - Un renommage doit **préserver l'ordre de dépendance** : une migration ne doit pas passer après une migration qui l'utilise.
2. **Heures.**
   - Le serveur stocke et rend en UTC (`timestamptz`), avec le fuseau IANA du foyer.
   - L'adaptateur convertit en heure murale du foyer.
   - Le port Dart reste en heure murale.
3. **Ports.**
   - Les ports de `lib/core/capacites` sur `ccr-1b1bfa0b-m1kvkk` font foi.
   - L'adaptateur `*_supabase.dart` les implémente tels quels.
   - `ProgressionEleve` reste gelé jusqu'à la décision du directeur sur l'étude de progression.
4. **Rejeu.** Avant de pousser, rejouer en local sur un Postgres 16 nu :
   - `supabase/tests/stub_auth.sql` ;
   - toutes les migrations, dans l'ordre glob ;
   - tous les `scenarios_*.sql`.

   Le résultat doit être de zéro rouge. Coller le résumé du rejeu dans la ligne de livraison.
5. Ni `service_role` ni production. Pousser sans force, uniquement sur des branches `codex2/*`.

## À faire, par priorité

### 1. X2-20 · PED-APRÈS serveur (Codex2 A115, A123, A124)

- **Spec :** `docs/current/PED-APRES/PED_APRES_SPEC_VERTICALE_V1.md`, dans `ccr-1b1bfa0b-m1kvkk`.
- **Contrat de port, qui fait foi :** `docs/current/PED-APRES/CONTRAT_PORTS_PED_APRES.md` et `DEPENDANCES_BACKEND.md`.
- **Port :** `lib/core/capacites/port_partage_pedagogique.dart`. Ces fichiers sont dans `ccr` depuis la fusion de PED-APRES-1 (ccr `8e071210`).
- **Oracle de comportement :** `test/fixtures/ped_apres/faux_partage_pedagogique.dart`.
- **Règles :**
  - Le partage famille est ON par défaut.
  - L'admin peut le désactiver par Classe ou par élève.
  - Un compte rendu peut être publié ou révoqué à la main.
  - Priorité : compte rendu > élève > Classe > défaut.
  - Le cahier K-45 est gelé.
- **Point de départ :** repartir de B-08 (`seance_resumes`, PR #21, migration 0054).
  - **Ajouter le retrait** (révoquer) et l'audit, qui manquent aujourd'hui (`resume_deja_publie`, audit jamais écrit).
  - Corriger `progression_famille`, qui rend `niveau_humain` NULL quand une version brouillon ou archivée porte le même code.
  - `PortResumeSeanceFamille` (String?) reste inchangé : rapprocher `resume_seance_famille` de `compteRenduFamille`.

### 2. X2-20 extension · ADM-CAHIER-LECTURE (Codex2 A127)

Le contrat est dans la section « ADM-CAHIER-LECTURE » de `CONTRAT_PORTS_PED_APRES.md`, sur la branche `claude/adm-cahier-lecture`. Cette branche est en vérification ; elle entrera dans `ccr` ensuite.

- `comptesRendusClasse(classeId, page, filtreEtat)` → `PageCahiersClasse`, paginée, avec `EtatDiffusion`.
- `lireCahierAdmin(seanceId, eleveId)` → `CahierAdmin`, type distinct de `CompteRenduFamille`.
- **Droits :**
  - Le rôle admin **seul** : comptable, tuteur, élève et contrôleur sont refusés (42501).
  - Chaque lecture du cahier brut est **journalisée** en ajout seul : qui, quand, séance, élève.
  - Le périmètre se limite à l'élève demandé.
  - Aucune copie de `internal_details` vers `family_summary`.
- **Tests :** un scénario SQL pour chaque refus et un pour la journalisation.

### 3. X2-22 · Pause de séance (Codex2 A128)

Le contrat est `docs/current/CONTRAT_PORT_PAUSE_SEANCE.md`, sur `claude/live-pause-01`. La branche est en vérification ; elle entrera dans `ccr` ensuite.

- Le réglage se fait **par classe**. Il est versionné et reste valable jusqu'à modification (moment et durée).
- Les événements de début et de fin sont **horodatés par le serveur**.
- Chaque séance porte un statut : prise ou non prise.
- **Droits :**
  - Seul l'enseignant de la classe écrit.
  - L'admin lit.
  - Les autres rôles sont refusés.
- La pause n'est **jamais** une preuve de présence.

### 4. X2-17 · alimentation des coffres (Codex2 A114, A125)

- **Dernier verdict :** CHANGES sur `c2339d3f`.
  - Les scénarios sont verts.
  - Mais le lot est toujours PARTIEL, et 2 horodatages de migration sont en secondes paires : il faut des secondes impaires.
- **Décisions A114, toujours valables :**
  - Créer `regles_remuneration_enseignant`, versionnée, en ajout seul, écrite par la Direction (aal2), **sans aucun taux codé**.
  - Créer `remuneration_due_seance(session_id)`.
  - Sans règle en vigueur, le mouvement va dans `tresorerie_a_reprendre` (motif `regle_remuneration_absente`). Il est ensuite rejoué par `reprendre_alimentation_tresorerie()`.
  - Ajouter la colonne `wallet_entries.confirme_par_prestataire_le`, qui conditionne l'encaissement.
- **Contrat :** `docs/current/CONTRAT-CPT-BR-18-19.md` v2 (`7231d321`). Les coffres sont alimentés par les paiements, jamais à la main. La devise de référence est USD.

### 5. X2-15 et X2-16 (Codex2 A111)

- Ajouter `account_status='active'` aux profils de fixture des scénarios.
- Révoquer EXECUTE à `service_role` sur les 2 nouvelles RPC.

## Confirmé (rien à faire)

X2-07, X2-08, X2-10, X2-11, X2-12, X2-18 (`86f44e17`, avec une réserve de couverture sur la garde du helper), X2-19.
