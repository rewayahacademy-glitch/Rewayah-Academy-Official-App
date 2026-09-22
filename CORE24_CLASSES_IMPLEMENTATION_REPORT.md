# CORE24 — rapport d’implémentation

## BRANCHE

`integration/core24-classes-v2`

## BASE

`Fable 9a3ff0dbeeac57864ff6dd9e0a91fe3fdafff138`

## ARBITRATION_SHA

`196eb063587c237b78b70c7a728e093cacfff391`

## LEGACY_CLASSES_SNAPSHOT_SHA

`3e2b53c`

## PRESENCE_SHA

`730b7b74aef6e63aa298aec5895412be7f28935a`

## COMMITS PRODUITS

- `196eb063587c237b78b70c7a728e093cacfff391` — arbitrage canonique.
- `86e588f107708be845597859491cda9249fe0a72` — présence académique signée, cherry-pickée.
- `f4834253fa64a621497bab666907a949b118fab5` — dispatch transactionnel.
- `e005729a1276a278403d544c4979191beda87f87` — sérialisation des choix répétés.
- `3793c8ee32c54fa70e7ef5281be0fa371c561544` — projection du cycle de vie des groupes.
- `dcafddf54c62fc9fe0d8dd183c6a0b72d1911dfd` — onboarding et interface guidée.

## MIGRATIONS AJOUTÉES

- `20260922000100_core24_presence_academique.sql`
- `20260923000100_core24_classes_reconciliation.sql`
- `20260923000200_core24_dispatch_transactionnel.sql`
- `20260923000300_core24_group_lifecycle.sql`
- `20260923000400_core24_interface_guidee.sql`

## ANCIENNES MIGRATIONS MODIFIÉES

Aucune.

## TESTS

- Suite complète Flutter : **PASS — 1764 tests**.
- Parcours/offres : **PASS — 34/34**.
- Réglages tuteur/interface guidée : **PASS — 13/13**.
- Routes/redirections : **PASS — 139/139**.
- Cycle de vie combiné : **PASS — 147 tests**.
- Scénarios SQL ajoutés, mais non rejoués sur une base PostgreSQL fraîche.

## FLUTTER ANALYZE

**PASS** — `flutter analyze --no-pub` — aucun diagnostic.

## POSTGRES FRESH REPLAY

**FAIL/BLOCKED** — les migrations historiques contiennent des préfixes dupliqués (`0030`, `0032`, `0033`). La tentative de replay local contrôlé a ensuite rencontré une API Docker Desktop en `500` puis bloquée. Aucune migration distante n’a été appliquée.

## CE QUI EST EFFECTIVEMENT TERMINÉ

- Arbitrage canonique documenté, snapshot legacy conservé, branche d’intégration isolée et présence académique intégrée.
- Âge/DOB et cohortes `6–9`, `10–13`, `14–17`, `18+`; placement débutant sans faux diagnostic.
- Dispatch transactionnel avec verrous, FIFO, plafonds et formation minimale de trois élèves.
- Cycle de vie des groupes en `DRAFT`, enseignant nullable, gardes de publication.
- **Interface guidée à deux chemins** : l’enfant âgé d’au moins 10 ans peut demander l’affichage standard; le tuteur voit toujours l’action et peut l’activer directement, même sans demande préalable. La mise à jour client directe de `interface_mode` est refusée.
- UI/domaine/classes existants restaurés et routes intégrées dans le périmètre traité.

## CE QUI RESTE

- Éligibilité professionnelle de l’enseignant, qualification/dispense, corridor et prérequis : contrat `core24_private.enseignant_autorise()` absent.
- Remplacement de séance : standby, invitation et flux atomique complet.
- Écran/workflow Admin Classes complet pour proposition, pool et enseignants éligibles; l’ancien écran Admin conserve un chemin manuel par UUID.
- Replay PostgreSQL frais et exécution des scénarios SQL.
- Vérification de l’absence de données de démonstration avant release; `GroupesDemonstrationLocale` existe déjà dans `PortGroupes` et doit rester traité comme limite tant qu’il n’est pas arbitré.
- QA navigateur/authentifiée, LiveKit et déploiement non réalisés.

## BLOCKERS

- Contrat `core24_private.enseignant_autorise()` et contrats qualification/dispense manquants; ils ne sont pas inventés.
- Collisions de préfixes de migrations historiques et problème Docker Desktop pendant le replay local.
- Le prompt interdit migration distante, push sur la branche principale et déploiement pour ce lot.

## DÉPLOIEMENT DISTANT

**NON**

## PRODUCTION MODIFIÉE

**NON**
