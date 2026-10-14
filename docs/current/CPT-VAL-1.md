# CPT-VAL-1 : « À valider » dans la Finance de la direction (CPT-BR-09)

Décision Q-8 = (a) du directeur (CPT-Q1, 05/10/2026) : un onglet « À valider » dans la Finance de la direction reçoit les demandes du Comptable. Boutons Valider et Refuser, motif obligatoire pour refuser, celui qui demande ne valide jamais lui-même.

Statut : **présent dans le code, testé localement** (démonstration). **Rien n'est branché** : aucun fichier `supabase/`, aucune RPC, aucune migration. En production le port rend `CapaciteIndisponible('CPT-BR-09')` et l'onglet dit « Pas encore disponible », sans demande ni bouton.

## Amendement de la ligne CPT-BR-09 (à reporter dans `20_comptable/CPT-BR.md`, branche de pilotage)

| Réf. | Étape | Besoin serveur | Port et méthodes | Démonstration |
|---|---|---|---|---|
| CPT-BR-09 | CPT-PAY-2, CPT-TRES-2, CPT-CTR-1, **CPT-VAL-1** | **Validations** : file des demandes (paiement sensible : coordonnées modifiées récemment, premier paiement, bénéficiaire lié à l'opérateur ; retrait de la Réserve stratégique ou sortie d'un coffre protégé ; obligation ponctuelle à approuver ; paie du Comptable lui-même), raison de la sensibilité et sa précision rendue, demandeur, date, montant exact, état ; pour chaque demande, **ce que l'appelant peut en faire** (`approuver` permise, ou bloquée `autoPaiement` quand l'appelant est le demandeur) ; décision (valider / refuser avec motif) par une autre personne que le demandeur, **refusée par le serveur** sinon ; idempotence par clé ; journal. | `lib/core/capacites/port_validations_finance.dart` : `demandes(filtre: etat?, nature?, objetId?)`, `decider(demandeId, decision, cleIdempotence, motif?)` (jette `RefusDecision` : `demandeurNePeutPasValider`, `motifObligatoire`, `dejaDecidee`), `journal(demandeId)` | `validations_demo.dart` : registre unique partagé par `/demo/comptable` et `/demo/finance?ecran=aValider` (4 demandes du Comptable en attente, 1 demande de la direction elle-même, 1 validée, 1 refusée avec motif). Côté Comptable : « Validation demandée », puis « Validée » ou « Refusée (motif) ». |

## RPC attendues au branchement (BR-1)

- `finance_validations_lister(etat text default null, nature text default null, objet_id text default null)` : les demandes visibles par l'appelant (la direction habilitée : toutes ; le Comptable : les siennes). Chaque ligne porte `actions_permises` et `raison_blocage` **calculées pour `auth.uid()`** : `approuver` seulement si l'appelant a la capacité de décider et n'est pas le demandeur, sinon `raison_blocage.approuver = 'autoPaiement'`. Montants en unités mineures + devise ISO 4217.
- `finance_validation_decider(demande_id uuid, decision text, motif text, cle_idempotence text)` : `security definer`, vérifie la capacité de l'appelant ; refuse `demandeur_ne_peut_pas_valider` si `auth.uid()` est le demandeur, `motif_obligatoire` pour un refus sans motif (après `trim`), `deja_decidee` si la demande n'est plus en attente ; la même clé rejouée rend la même réponse sans seconde décision ; écrit le journal (initiateur, date, ancien et nouvel état, montant, motif) ; la décision « validée » rend l'objet exécutable selon sa nature (paiement payable par le Comptable, obligation approuvée et figée, mouvement exécuté), jamais « payé ».
- `finance_validation_journal(demande_id uuid)` (CPT-BR-17).
- RLS : lecture des demandes par le demandeur et par les personnes habilitées seulement ; aucune écriture directe sur la table, uniquement par la RPC. Tests d'accès horizontal et revue de sécurité séparée avant tout branchement.

## Décisions prises par délégation le 05/10 (DIR-REP-1)

- Place de l'onglet : **quatrième** onglet de Finance (après Réserve et délégation), pour ne déplacer aucun onglet existant.
- Motifs de refus (5 + « Autre ») rédigés à partir des textes de l'app : « Coordonnées du bénéficiaire à vérifier », « Montant à vérifier à la source », « Justificatif manquant ou illisible », « Hors de la politique de la Réserve », « À reporter au prochain cycle ».
- La demande faite par la personne connectée elle-même reste visible dans la liste (« Votre propre demande ») sans aucun bouton de décision.
- Hors ligne avec la liste chargée : une phrase remplace les boutons dans la feuille (aucun bouton grisé) ; le bandeau général reste le seul message hors ligne de la page.
- Le libellé arabe de ces textes suit la traduction du Comptable (CPT-DIR-2) : repli sur le français d'ici là.

## Captures

`docs/current/captures/CPT-VAL-1/` : onglet, détail (montant exact), refus avec motif, côté Comptable (paiement refusé avec motif), à 390, 1440 et 320 texte ×2, clair et sombre.
