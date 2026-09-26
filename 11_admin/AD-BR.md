# AD-BR — Besoins serveur de la vague Admin (K-28)

Une ligne par besoin, format « quoi | où | pourquoi ». Numérotation alignée sur `01_RELEVE.md` §9.
Chaque identifiant est rendu par l'implémentation « indisponible » d'un port (`CapaciteIndisponible('AD-BR-nn')`).
Aucun adaptateur serveur n'est écrit côté client avant que la ligne soit servie.

## AD-4 (ports de revue des dossiers et de politique KYC)

- AD-BR-01 : RPC `list_reviewable_dossiers` paginée (curseur, limite, rôle), une ligne par personne, sans `object_key`, tri soumission croissante puis id, total fiable, autorisation et politique appliquées avant pagination | `PortRevueDossiers.listerDossiers` (lib/core/capacites/port_revue_dossiers.dart) | contrat §17.1, 01_RELEVE §9 n°1
- AD-BR-02 : RPC `get_dossier_for_review` avec révision, statut, référence de pièce, vérifications, accords versionnés, `can_validate` / `can_reject` / `can_view_document`, blocages et conséquence de la validation | `PortRevueDossiers.dossierPourRevue` | contrat §17.2, n°2
- AD-BR-03 : lecture de pièce par `autoriser_lecture_piece_identite` / Edge `piece-identite-acces` (couple dossier + document vérifié, audit par pièce) à la place de `createSignedUrl` côté client | `PortRevueDossiers.demanderVuePiece` ; pont démo `ServiceValidationDemo.apercu` | contrat §17.3, n°3
- AD-BR-05 : persistance et recontrôle serveur des trois vérifications transmises avec la décision (`missing_required_check`) | `PortRevueDossiers.decider(verificationsFaites)` | contrat §17.4/§17.6, n°5
- AD-BR-06 : `decide_dossier` au niveau du dossier : `expected_revision`, `stale_dossier`, `already_decided`, `cannot_activate`, retour typé (statut final, état d'accès, `new_revision`, `decided_at`) | `PortRevueDossiers.decider` | contrat §17.4, n°6, 8, 9
- AD-BR-07 : idempotence par `command_id` et lecture `get_decision_result` (pending, succeeded, failed, unknown) | `PortRevueDossiers.resultatDecision` | contrat §17.6, P-ADM-10, n°7
- AD-BR-16 : politique `genre_reviewer_enforced` versionnée (valeur initiale true), lue par `read_kyc_documents`, `dossiers_en_attente` et la décision | `PortPolitiqueRevueKyc.lire` (lib/core/capacites/port_politique_revue_kyc.dart) | contrat §17.5, §15.4, n°16
- AD-BR-17 : RPC `get_kyc_review_policy` / `set_kyc_review_policy` (Super Admin, `expected_version`, audit de l'acteur, ancienne et nouvelle valeur) | `PortPolitiqueRevueKyc.modifier` | contrat §17.5, n°17
- AD-BR-18 : fondation Super Admin (claim ou table de capacités, sans valeur `super_admin` dans `app_role`), miroir client dans `SessionState` ; en attendant, capacité simulée dans le seul double de démonstration | `PolitiqueRevueKyc.peutModifier` ; `PolitiqueRevueKycDemo` | Q40, n°18

## Ajouts AD-5 (2026-09-26)

- AD-BR-01 (complément) : `dossiers_en_attente` rend UNE LIGNE PAR PIÈCE VISIBLE (left join, 0029:124-145), pas une ligne par personne. L'adaptateur `RevueDossiersDepuisValidation` dédoublonne par profile_id en gardant la plus ancienne ; la 2e pièce n'apparaît qu'après décision sur la 1re. Besoins : une ligne par personne, total fiable (compteur), curseur (« Charger les dossiers suivants »). | lib/core/capacites/revue_dossiers_depuis_validation.dart | spec §9.9, 01_RELEVE §5 l.151
- AD-BR-01 (complément) : liste des valeurs de subject_role supportées par le serveur, pour un filtre « Type de dossier » (spec §9.7 l.673-677). Sans elle, filtre et état « Aucun dossier ne correspond à ce filtre. » absents. | PortRevueDossiers.listerDossiers(role) | UX groupe 2 l.39
- AD-BR-01 (complément) : submitted_at distinct de la date d'inscription pour un dossier sans pièce ; l'adaptateur rend deposeLe (à défaut inscrit_le). | DossierEnFile.soumisLeUtc | spec l.1929
- AD-BR-02 et 06 (rappel) : review_status et revision absents de la file ; l'adaptateur rend aVerifier et revision 0, jamais affichée. | DossierEnFile.revision | spec §9.9
- AD-BR-19 (nouveau) : fuseau IANA du profil admin lisible par le client (spec §26 ter l.1929). Aucun fuseau exposé (01_RELEVE l.181), aucun paquet de fuseaux (pubspec interdit). Défaut appliqué : heures en UTC, notées « (UTC) ». | dateRevue (lib/features/admin_dossiers/textes_dossier.dart) | spec l.1929

## Ajouts AD-6 (2026-09-26)

- AD-BR-02 (complément) : en production, le détail est reconstruit depuis la file `dossiers_en_attente` déjà chargée (même cache), aucun appel nouveau. Absents, donc non affichés : révision (0, jamais affichée : « Ce dossier a changé depuis son ouverture. » n'apparaît jamais en production), accords versionnés (carte « Accords et éléments soumis » masquée), conséquence de validation (`indeterminee`), review_status (toujours « En cours de vérification »). can_validate / can_reject non fournis : déduits de etat_piece et document_id (écart ouvert avec §10.13 « le serveur décide »). | RevueDossiersDepuisValidation.dossierPourRevue | spec §10.13
- AD-BR-03 (rappel AD-6) : « Voir la pièce » inactif en production ET en démonstration jusqu'à AD-7, légende « La consultation de la pièce est indisponible pour le moment. ». L'aperçu en ligne (createSignedUrl + Image.network) est retiré du détail (modification 13). Besoin : autoriser_lecture_piece_identite ou Edge piece-identite-acces avec le couple dossier + document vérifié. AD-6 ne doit pas être fusionné sans AD-7 (Q-AD6-1). | lib/features/admin_dossiers/revue_dossier.dart | spec l.1974
- AD-BR-05 (rappel) : les trois vérifications sont locales, jamais persistées ni recontrôlées ; decider_dossier ne les reçoit pas (AC-19 l.2043 non garanti serveur). | RevueDossier._faites | spec AC-19
- AD-BR-06 (complément AD-6) : decider_dossier(p_document_id) décide par pièce ; un dossier sans pièce n'est ni validable ni refusable en production (« Ce dossier ne peut pas être refusé dans son état actuel. »), alors que P-ADM-08 l.1886 veut un refus possible s'il est autorisé. Ni stale_dossier ni already_decided : « dossier modifié » et « conflit » inatteignables en production. | ServiceValidation.decider | spec P-ADM-08
- AD-BR-19 (rappel) : « Date de dépôt » en UTC, notée « (UTC) ». | dateRevue | spec l.1929

## Ajouts AD-6, corrections (2026-09-26)

- AD-BR-03 (décision provisoire, à confirmer par le directeur, Q-AD6-1) : jusqu'à AD-7, l'adaptateur de production FERME la validation. Les trois vérifications sont affichées non modifiables, Valider reste désactivé avec « Ce dossier n'est pas encore prêt à être validé. » (nouveau blocage `BlocageRevue.pieceNonConsultable`). Personne n'atteste « La pièce est lisible » sans l'avoir vue. Le refus reste possible. Variante non retenue sans accord : « Voir la pièce » ouvrirait l'aperçu existant (createSignedUrl) dans AppBottomSheet. La démonstration n'est pas touchée. | lib/core/capacites/revue_dossiers_depuis_validation.dart | spec l.1974
- AD-BR-07 (nouveau, dérogation provisoire) : le motif de refus EN LIGNE (TextField, clés motif/motifRequis, « la famille… » faux pour un enseignant) est maintenu jusqu'à AD-8 (modification 19, ADM-02D §26 ter l.1949) pour garder la production fonctionnelle. Quand le motif est ouvert, le premier « Refuser le dossier » est masqué : un seul bouton destructif est visible. Valider appelle encore decider_dossier sans confirmation 02E (Q-AD6-2). | lib/features/admin_dossiers/revue_dossier.dart | spec §10.11, §26 ter

## Mise à jour AD-7 (26/09, commit 466fdcc sur ui/admin-v1, non poussé)

- AD-BR-03 (mise à jour) : en production, la pièce se lit désormais par le mécanisme client EXISTANT (`ServiceValidation.apercu`, `createSignedUrl` 60 s, seau kyc), sans audit par pièce (`kyc_document_open`), sans exigence positive de rôle ni filtre de genre côté stockage (`kyc_lecture_admin` couvre tout le seau). Besoin BR-1 : brancher `autoriser_lecture_piece_identite` / Edge `piece-identite-acces` à la place. Tant que ce n'est pas fait, la validation rouverte repose sur une lecture sans journal.
- Nouveau besoin : `dossiers_en_attente` ne fournit pas le type MIME ; il est déduit de l'extension d'`object_key` (jpg, jpeg, png, webp seulement). BR : rendre `content_type` et l'échéance réelle depuis la porte serveur.
- Nouveau besoin : sur le web, l'errorBuilder d'Image ne donne pas le statut HTTP ; l'expiration est déduite de l'horloge (`expireLeUtc`). BR : code d'expiration explicite côté Edge (401/403 typé).
- Rappel : `object_key` est exposé au client par la file (0029). À retirer quand l'Edge sera branché.
- Formats : pdf et heic acceptés au dépôt, non affichables (pas de dépendance possible, pubspec interdit) : validation fermée, refus ouvert. BR ou décision produit (Q-AD7-2).

## Ajouts AD-8 (26/09, ui/admin-v1, non poussé)

- AD-BR-06 (production, AD-8) : decider_dossier n'a pas de garde d'état. L'UPDATE se fait par l'id seul (0004:550-556) et read_kyc_documents ne filtre pas le statut : une seconde décision sur un document déjà décidé RÉUSSIT et écrase la première, même opposée, par un autre administrateur, et écrit une seconde trace kyc_decision. « Conflit » et « déjà décidé » ne sont atteints que si le document a déjà disparu de la file en cache. | RevueDossiersDepuisValidation.decider | P-ADM-05, AC-14, AC-17
- AD-BR-07 (production, AD-8, remplace la dérogation du motif en ligne, levée) : ni command_id ni get_decision_result. Après un résultat inconnu (délai de 20 s AppDelais.requeteMax ou réponse perdue), le client relit la file en cache puis la recharge par dossiers_en_attente (existant). Absent : « Ce dossier a déjà été traité. », non attribué. Présent : échec, reprise de la MÊME charge permise (Q-AD8-9). Risque résiduel : une requête encore en vol peut aboutir après la reprise et produire deux traces. | RevueDossiersDepuisValidation.resultatDecision | P-ADM-10, §17.6
- AD-BR-02 et 06 (conséquence) : la RPC ne dit pas si la validation active le compte ; en réalité decider_dossier passe account_status à active si pending_kyc (0004:558-562), sans contrôler les accords. Faute de champ de conséquence, 02E est indisponible en production (Q21) : la validation est FERMÉE en production (Q-AD8-1, recul par rapport à AD-7). | DossierPourRevue.consequence | §13.2 l.1113
- AD-BR (nouveau) : les erreurs de decider_dossier sont des raise exception P0001 à texte libre ; la carte client repose sur des sous-chaînes (« un refus exige un motif », « introuvable ou hors du perimetre », « seul un administrateur »), fragile. Besoin : codes typés (forbidden, already_decided, stale_dossier, missing_reason, reason_too_long). | RevueDossiersDepuisValidation.decider | §17.4
- AD-BR (nouveau) : aucune longueur maximale du motif côté serveur (0004:536-541) ; motifTropLong (« Le motif dépasse la longueur autorisée. ») est inatteignable en production. | CodeErreurRevue.motifTropLong | Q30, l.1985
- AD-BR-05 (rappel) : les vérifications cochées ne partent pas avec decider_dossier (AC-19 non garanti par le serveur).
- Rappel sécurité : decider_dossier teste app_role() <> 'admin' (garde négative : NULL <> 'admin' ne lève pas, 01_RELEVE l.134) et n'appelle pas app_account_valid. Hors lot, aucune modification serveur.

## Corrections de revue AD-8 (26/09, ui/admin-v1, poussé sur origin)

- AD-BR-07 (corrige la ligne « Présent : échec, reprise permise » ci-dessus) : en production, un dossier ENCORE PRÉSENT après relecture rend `EtatCommandeEnAttente` et reste « résultat inconnu » : seuls « Fermer » et « Vérifier le résultat », jamais « Réessayer » (la requête peut être encore en vol, decider_dossier n'est ni idempotent ni gardé). La reprise n'est rouverte qu'avec command_id + get_decision_result côté serveur. Conséquence : un dossier réellement non traité reste bloqué pour la session tant que la relecture le montre présent ; l'administrateur peut le rouvrir après rechargement de l'application. | RevueDossiersDepuisValidation.resultatDecision | P-ADM-10.6, spec l.2010
- Q30 relié : reason_too_long n'existe pas côté decider_dossier (aucune limite, besoin l.53-54) ; « Le motif dépasse la longueur autorisée. » n'est atteignable qu'en démonstration et par port de capture. | CodeErreurRevue.motifTropLong | Q30
- Session : les commandes non résolues survivent au départ de la page (keepAlive tant qu'une commande est non résolue) ; aucune nouvelle décision sans relecture. Côté client seulement, rien ne remplace la garde serveur. | decisionsDossiersProvider | P-ADM-10.6

## Ajouts AD-9 (26/09, commit admin 15c6cd7, non vérifiés côté serveur)

| Id | Besoin | Port / écran | Source |
|----|--------|--------------|--------|
| AD-BR-16 (complément AD-9) | La politique doit aussi être lue par `comptes_admin()` (ADM-08 calcule l'état de pièce sans genre, 0015:160-174) et par la Storage policy `kyc_lecture_admin` (tout le seau, sans genre, 0004:1013-1017). Sinon, politique activée, le cloisonnement se contourne. | PortPolitiqueRevueKyc.lire | 01_RELEVE l.102, l.133, n°21 |
| AD-BR-17 (complément AD-9) | `set_kyc_review_policy` doit rendre des codes typés (`forbidden`, `stale_policy_version`) et une date serveur, et auditer (acteur, ancienne et nouvelle valeur, date). Mention d'audit masquée tant que ce n'est pas prouvé (Q37). | PortPolitiqueRevueKyc.modifier | spec l.127, l.1203 |
| AD-BR-18 (rappel AD-9) | La capacité Super Admin n'existe pas côté serveur. En production, l'onglet n'apparaît jamais et la route affiche « Pas encore disponible » : fondation requise (claim ou table de capacités, hors `app_role`). | peutReglerPolitiqueKycProvider | Q40 |
| AD-BR-20 (rappel n°20) | `profiles.gender` modifiable par son propriétaire (`profiles_self_update` ; `guard_profile_privileged_columns` ne couvre pas `gender`, 0001:541-560, 713-715) et par tout admin (0001:704-705) : §3 point 6 non tenu côté serveur. RPC administrative auditée requise pour poser le genre du personnel ; le bouton « Compléter mon profil » en dépend. | GenreManquant (revue_dossier.dart) | spec §3.6, §15.3 l.1211, 01_RELEVE l.100-101 |
| AD-BR-16 (production) | Filtre de genre codé en dur et sans condition (`read_kyc_documents` 0004:202-213, partagé par file, décision et lecture 0029:125, 0004:545, 0034:170-172) : « politique désactivée » n'existe qu'en démonstration. `kyc_admin_all` (FOR ALL admin, sans genre) laisse lire `kyc_documents` hors filtre. | RevueDossiersDepuisValidation | 01_RELEVE l.94, l.131-132 |
| AD-BR-16 (actualisation) | Notifier ou versionner la politique pour que les files ouvertes chez d'autres relecteurs se relisent (§15.2). Le client ne relit qu'au prochain rafraîchissement ; seule la session qui bascule relit. | dossiersEnAttenteProvider | spec l.1204, §15.4 |
