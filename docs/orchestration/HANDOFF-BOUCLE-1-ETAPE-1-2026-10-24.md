> Remplacé par `PILOTAGE-BOUCLES-2026-10-24.md` (but unique de la session de travail). Ce fichier reste comme trace de l'étape 1.

# Passation à la session suivante : Boucle 1, étape 1 (K1), 24/10/2026

Lire ceci, puis `docs/current/BOUCLE-1_PLAN_2026-10-24.md`, puis seulement les fichiers nommés
ci-dessous. Ne rien relire d'autre dans `docs/current/` : tout ce qui compte est ici.

## Décisions du directeur à respecter (24/10/2026)

- Une seule boucle (K1 à K4), étape par étape. Aucun autre travail, aucune session parallèle,
  aucune remise à plat d'architecture, aucun nouvel écran, aucune nouvelle règle.
- La preuve se fait **en production, par le directeur, après fusion**. Risque accepté par lui.
- **Vérité d'abord** : dire en premier ce qui est faux, bloqué, inconnu ou non prouvé. Interdit de
  le tromper pour ne pas le froisser. « Fait » = prouvé par le directeur en production.
- Économie : une étape, une pull request, un seul agent, pas de boucle de relance, pas de
  relecture du dépôt. Les tâches mécaniques (lancer des tests, grep, clé i18n) aux petits modèles.

## Où en est la branche `claude/admiring-brown-r6ai72`

- `a0184d88` : le plan, le bloc « Mission en cours » et « Vérité d'abord » dans `CLAUDE.md`,
  deux lignes dans `08_DECISIONS` §5 bis.
- Commit suivant (ce même jour) : **le code de l'étape 1, presque fini**. Détail ci-dessous.
- Aucune pull request ouverte : le garde-fou refuse à tout agent d'ouvrir une PR vers `main`.
  **Le directeur l'ouvre lui-même** : https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/compare/main...claude/admiring-brown-r6ai72?expand=1

## Étape 1 : ce qui est codé

Fichier `lib/core/capacites/revue_dossiers_depuis_validation.dart` :

1. `surchargeRevueDossiersProduction` (fin du fichier) branche désormais `apercu`
   (`ServiceValidation.apercu`, fonction serveur `piece-identite-acces`), `deciderExistant`
   (`ServiceValidation.decider`, RPC `decider_dossier`) et `relire` (invalidation puis relecture
   de `dossiersEnAttenteProvider`). Avant : seule la file était branchée, depuis le 27/09.
2. `dossierPourRevue` : `consequence` n'est plus figée à `indeterminee`. Quand la décision est
   branchée, elle vaut `consequencePour(d.etatCompte)` : `pending_kyc` donne
   `activationPossible`, `active` ou `provisional_active` donne `documentaireSeule`, le reste
   reste `indeterminee`. Nouvelle méthode statique `consequencePour`.
3. `decider` : la garde `throw CapaciteIndisponible('AD-BR-02')` qui refusait toute validation
   a été retirée. L'appel RPC passe `approuve: true` sans motif.
4. Commentaires mis à jour. Même chose dans `lib/features/admin_dossiers/revue_dossier.dart`
   (doc de classe seulement, aucun code).

Tests : `test/core/capacites/revue_dossiers_depuis_validation_test.dart` : le test
« valider : AD-BR-02 » remplacé par trois tests Boucle 1 (valider appelle la RPC ; table de
`consequencePour` ; aperçu et décision branchés ouvrent la validation).

Vérifié : `dart format` appliqué ; `dart analyze --fatal-infos` sans défaut sur les 4 fichiers
touchés ; `flutter test` sur `test/core/capacites`, `test/features/admin_dossiers`,
`test/capacites/ports_capacites_test.dart` : **161 verts, 1 rouge**.

## Ce qui reste, dans l'ordre (une heure de travail au plus)

1. **Le test rouge** : `test/features/admin_dossiers/visionneuse_production_test.dart`, premier
   `testWidgets` (« production depuis la coque : ni Voir la piece ni refus... decision du
   27/09 »). Il affirme l'ancienne fermeture. Le réécrire pour la production du 24/10 :
   « Voir la pièce » présent, « Refuser » présent et actif, aucune URL dans l'écran, puis après
   lecture de la pièce et les trois cases cochées, « Approuver » présent. Pour cela, dans
   `_monterCoque`, donner au `DossierAValider` de Moussa `etatCompte: AccountStatus.pendingKyc`
   (sans cet état, la conséquence reste indéterminée et « Approuver » reste fermé : c'est
   voulu). Le second test (`surchargeRevueDossiersBrancheeBR1`) passe déjà ; le laisser.
   Mettre à jour l'en-tête du fichier (il parle encore de BR-1).
2. Relancer : `flutter test test/features/admin_dossiers test/core/capacites`.
3. Lancer, non faits (interrompus) : `dart run tool/verifier_jetons.dart`,
   `dart run tool/verifier_revue.dart`, puis `dart analyze --fatal-infos` sur tout le projet.
   Pas de `slang` ni de `build_runner` : aucune clé i18n ni code généré touché.
4. Commit (message en français, sans nom de modèle dans le texte), `git push -u origin
   claude/admiring-brown-r6ai72`. Ne pas tenter d'ouvrir la PR : donner le lien ci-dessus au
   directeur. Un push sur la branche ne déclenche aucune CI ; la PR en déclenche ~25 min, la
   fusion ~10 min.
5. Après la fusion : attendre dix minutes, puis le directeur fait le test du plan, étape 1
   (six clics). Vérifier en même temps, en lecture seule sur la base de production :
   `kyc_documents.status` passe `approved`, `profiles.account_status` passe `active` pour
   l'enseignant.

## Faits vérifiés en production le 24/10 (ne pas revérifier)

- Un seul enseignant, `pending_kyc`, une pièce `pending`, clé en `.jpg`, stockage `supabase`.
  Signatures à jour : `teacher_nda` 2026-10-jur, `recording_and_control_notice` 2026-10-jur,
  `teacher_conduct_code` 2026-10-19. Direction et enseignant de même genre (règle de genre OK).
- Fonctions présentes : `decider_dossier`, `dossiers_en_attente` (renvoie `account_status`),
  `teacher_signature_statuses`, `read_kyc_documents`, fonction Edge `piece-identite-acces`.
- Le serveur refuse l'activation si une signature manque : message
  `contract_not_signed_current:<kind>` (code 23514). Non traduit à l'écran : défaut K-59 mineur,
  à faire après K1, pas avant.

## Pièges

- Le garde-fou `.claude/hooks/garde.py` refuse : écrire dans `.github/`, `vercel.json`,
  `pubspec.yaml` ; toute PR vers `main` ; tout push vers `main` ; toute écriture ou commande
  distante sur Supabase ; relancer ou annuler la CI ; toute commande qui cite l'identifiant du
  projet de production. Ne pas le contourner.
- Un `git checkout -B` ou un push forcé est refusé : avancer par `git merge --ff-only`.
- Lecture seule sur la base de production autorisée (SELECT par l'outil Supabase). Jamais d'écriture.
- Le `flutter test` complet dure longtemps : cibler les dossiers nommés.
- La session « Recrutement » (PR 50) a un contrôle « Flutter (web) » bloqué depuis 01:21 UTC :
  https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/actions/runs/40049437978
  Seul le directeur peut l'annuler (« Cancel workflow »). Ne pas y toucher.

## Après K1 vraie

Étape 2 du plan : aucun code prévu, le directeur crée la classe. Lire le plan §3, étape 2.
