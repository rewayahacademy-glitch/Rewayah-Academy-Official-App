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
