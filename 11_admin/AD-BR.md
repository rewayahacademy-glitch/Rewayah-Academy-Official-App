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
