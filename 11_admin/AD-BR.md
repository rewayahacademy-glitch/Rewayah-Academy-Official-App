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
