# CORE24 - rapport global d'implementation

## Perimetre et arbitrage

- Branche : `integration/core24-classes-v2`
- Base Fable : `9a3ff0dbeeac57864ff6dd9e0a91fe3fdafff138`
- Arbitrage canonique : `196eb063587c237b78b70c7a728e093cacfff391`
- Snapshot legacy Classes conserve : `3e2b53c`
- Presence academique preservee : `730b7b74aef6e63aa298aec5895412be7f28935a`
- Depot principal, production et migrations distantes : inchanges.

Le lot respecte la separation Fable / Presence / Core24. Aucune reecriture de Presence,
aucun push sur `main` et aucun deploiement n'ont ete effectues.

## Commits du lot

- `196eb06` - arbitrage canonique Classes.
- `86e588f` - presence academique signee.
- `f483425` - dispatch transactionnel.
- `e005729` - serialisation des choix repetes.
- `3793c8e` - cycle de vie DRAFT des groupes.
- `dcafddf` - onboarding et interface guidee.
- `8923564` - etat intermediaire documente.
- `8f819d0` - titulaires, admissibilite, Admin et remplacement de session.
- Le present rapport sera committe separement apres verification de ce lot.

## Specifications effectivement implementees

1. Offre, intention, onboarding, prediagnostic, diagnostic qualifie, pool compatible,
   dispatch, groupe DRAFT, validation Admin, publication puis session.
2. Date de naissance comme source des cohortes definitives : `6-9`, `10-13`,
   `14-17`, `18+`; les enfants de moins de 6 ans restent hors standard. Le choix
   debutant conserve sa base de placement sans fabriquer un diagnostic termine.
3. Dispatch transactionnel, verrouille et idempotent : compatibilite langue/cohorte/
   niveau, minimum 3, plafond enfant 5, adulte 6, sans double affectation.
4. Cycle de vie groupe : enseignant nullable en DRAFT, titulaire obligatoire et
   controles de capacite/compatibilite avant READY, PUBLISHED ou ACTIVE.
5. Titulaire : autorisation enseignant, statut/KYC ou dispense motivee, NDA, langue,
   qualification, disponibilites de chaque creneau, conflits DST et plafond de groupes
   principaux configurable (2 par defaut).
6. Remplacement : demande de standby, invitations, acceptation atomique du premier
   enseignant, revocation des autres invitations, remplacement dans
   `session_participants`; `groupes.teacher_id` reste le titulaire nominal.
7. Admin Classes : creation/publication/retrait des offres, pool des intentions,
   enseignants admissibles, affectation du titulaire et transitions de groupe. Le
   nouvel ecran ne propose plus la saisie manuelle de UUID pour le parcours normal.
8. Interface guidee : l'enfant age d'au moins 10 ans peut demander le passage au
   standard; le tuteur voit toujours l'action et peut l'activer directement, meme
   sans demande de l'enfant. Une mise a jour cliente directe de `interface_mode` est
   refusee.
9. RLS et surface RPC : tables internes sans ecriture directe, fonctions d'ecriture
   reservees et scenarios de privileges ajoutes.

## Fichiers SQL ajoutes

- `supabase/migrations/20260921000000_core24_private_schema.sql`
- `supabase/migrations/20260922000100_core24_presence_academique.sql`
- `supabase/migrations/20260923000100_core24_classes_reconciliation.sql`
- `supabase/migrations/20260923000200_core24_dispatch_transactionnel.sql`
- `supabase/migrations/20260923000300_core24_group_lifecycle.sql`
- `supabase/migrations/20260923000400_core24_interface_guidee.sql`
- `supabase/migrations/20260923000500_core24_enseignant_remplacement_admin.sql`

Anciennes migrations modifiees : aucune. Les trois fichiers Windows generes deja sales
ont ete preserves hors du commit.

## Verification locale

- `flutter analyze --no-pub` : **PASS**, aucun diagnostic.
- `flutter test --no-pub` : **PASS, 1767 tests**.
- Tests cibles du dernier lot : **PASS, 12 tests**.
- `git diff --check` : **PASS** sur le lot committe.
- Scenarios SQL de securite ajoutes dans
  `supabase/tests/scenarios_core24_teacher_replacement_admin.sql`.

## Limites et blocages connus

- Replay PostgreSQL frais : **BLOQUE**. Docker Desktop renvoie une erreur API
  `500 Internal Server Error` lors de l'inspection du conteneur Supabase local,
  avant l'execution des migrations. Le depot contient aussi des prefixes historiques
  dupliques (`0030`, `0032`, `0033`), qui restent a arbitrer sans renommer l'historique
  dans ce lot.
- Les scenarios SQL n'ont donc pas ete executes sur une base PostgreSQL fraiche.
- QA navigateur authentifiee, LiveKit reel, OAuth/OTP, donnees de production et
  deploiement n'ont pas ete declares ni testes ici.
- L'audit des donnees de demonstration reste une verification de release distincte.
- Paiement et facturation restent hors perimetre Core24.

## Etat de livraison

- Code local du lot : **TERMINE**.
- Branche isolee : **oui**.
- Commit local : **oui**, `8f819d0`.
- Push distant : **NON**.
- Migration distante : **NON**.
- Production modifiee : **NON**.
- Deploiement : **NON**.

La conclusion correcte est donc : toutes les specifications fonctionnelles du prompt
initial sont implementees et couvertes par la verification Flutter locale; la validation
PostgreSQL/runtime et la release restent volontairement bloquees par l'environnement ou
hors perimetre.
