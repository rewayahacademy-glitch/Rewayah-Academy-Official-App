# 09 - Inventaire des textes de consentement, contrat et conservation

Date : 25/09/2026. Source : `C:\RA\depot` (branche ui/tuteur-v1), lecture seule.
Auteur : agent de pilotage. Aucun code modifié.

## 1. Textes affichés dans l'app (assets/i18n/fr.i18n.json)

| # | Clés | Écran / fichier | Rôle | Ce qu'on fait accepter | Preuve de l'accord |
|---|------|-----------------|------|------------------------|--------------------|
| T1 | `accuse.titre`, `accuse.compris` + `contrat.pointEnregistrement`, `contrat.pointControle` | `AccusePage` (`lib/features/dossier/signature_page.dart`), route d'attente | Enseignant (et tout rôle qui passe par `/attente`) | Prise de connaissance : cours enregistrés en audio 30 jours, visite de contrôle invisible possible | Ligne `contract_acceptances` sorte `recording_and_control_notice`, version `2026-09`, `accepted_at`, `profile_id` |
| T2 | `contrat.titre`, `contrat.intro`, `contrat.pointEnregistrement`, `contrat.pointControle`, `contrat.pointCoordonnees` (enseignant seul), `contrat.lireTexte`, `contrat.accepter`, `contrat.caseRequise` | `ContratPage` (même fichier) | Tuteur (conditions) ; enseignant (non-concurrence) ; `?pour=moi` élève adulte | Conditions d'utilisation (tuteur) ou contrat enseignant, avec les deux points ci-dessus en clair | `contract_acceptances` sorte `guardian_terms` version `2026-09-obs`, ou `teacher_nda` version `2026-09` |
| T3 | `consentement.texte.*` (titre, quiResponsable(Detail), quiAdulte(Detail), pourquoi(Detail), limites(Detail), caseResponsable, caseAdulte, continuer, retour) | `texte_observation.dart`, intégré à `ContratPage` et à `consentement_observation_page.dart` | Tuteur (pour son enfant) ; élève adulte | Visites d'observation des parents pendant la séance | Même ligne que T2 (`guardian_terms`, `2026-09-obs`) : **l'observation n'a pas d'accord distinct** |
| T4 | `consentement.comment.*` | `explication_observation.dart` (« Comment ça marche ? ») | Tuteur | Information : nombre et durée des visites, lus depuis la politique de la classe | Aucune (information) |
| T5 | `consentement.compte.*` | `consentement_observation_page.dart` (`/tuteur/compte/consentements`) | Tuteur déjà actif | Invite à signer la nouvelle version (observation) ; affiche « Vous avez accepté ces modalités le {date} » | Nouvelle ligne `contract_acceptances` |
| T6 | `salle.bandeauPermanent` « Cours enregistré, visite de contrôle possible. » ; `salle.observationMuette` ; `salle.bandeauControle` | Salle de classe | Tous les présents | Information permanente pendant le cours | Aucune trace d'affichage |
| T7 | `enseignant.profil.contratSection`, `contratEnseignant`, `contratConditions`, `contratAccuse`, `contratDetail`, `contratLectureSeule` | Profil enseignant | Enseignant | Relecture des accords signés (version, date) | Lecture de `contract_acceptances` |
| T8 | `kyc.intro` « Une photo lisible suffit. Elle est conservée le temps de la vérification, puis effacée. » | Dépôt de pièce d'identité | Tuteur, enseignant | Information sur la pièce d'identité | Aucune ; en base, `kyc_retention_days` = 90 jours |
| T9 | `ficheEleve.camera.*` (autorisee, interdite, application, distincte) | `lib/features/foyer/fiche/camera_page.dart` | Tuteur | Réglage caméra de l'enfant (`student_profiles.camera_policy`, défaut `forbidden`) | Colonne mise à jour ; pas de trace datée de qui a changé quoi (à vérifier dans le journal d'audit) |
| T10 | `admin.configuration.ageCameraAuto(Detail)` « En dessous de cet âge, l'activation de la caméra reste soumise à l'accord du tuteur. » | Configuration admin | Admin | Seuil `camera_auto_allow_min_age` = 11 ans (0001) | Journal d'audit (0009), à confirmer |
| T11 | `admin.conservationDonnees.*` (enregistrements, documentsIdentite) | Configuration admin | Admin | Durées : `recording_retention_days` 30, `kyc_retention_days` 90 | Journal d'audit, à confirmer |
| T12 | `foyer…photoLegende` « Une photo du visage de {prenom}. Ce n'est pas une pièce d'identité. » | Fiche élève, photo | Tuteur | Dépôt d'une photo de l'enfant | Aucun accord ; pas de durée ni de destinataires annoncés |
| T13 | `onboarding…procheDescription` « un adulte aura son propre profil et donnera lui-même son accord » | Choix du profil | Tuteur | Annonce : l'adulte consent seul | Non implémenté |
| T14 | `admin…sansPieceDetail` « a créé son compte et accepté les contrats » | Admin personnes | Admin | Lecture | `contract_acceptances` |

## 2. Base de données (supabase/migrations)

- `0004_inscription_kyc_appairage.sql` section 7 : table `contract_acceptances (id, profile_id, contract_kind, version, accepted_at)`, unique `(profile_id, contract_kind, version)`. Triggers : ni modification ni suppression. Lecture : soi-même et admin. Insertion : soi-même.
  - Sortes : `guardian_terms`, `teacher_nda`, `recording_and_control_notice`.
  - **Pas de colonne** : texte ou empreinte du texte signé, langue, enfant concerné, canal/appareil, retrait.
  - `profile_id ... on delete cascade` : si le profil est supprimé, la preuve disparaît malgré le trigger (le trigger `before delete` bloque en fait la cascade, donc la suppression du profil échoue : à vérifier). Dans les deux cas, c'est un problème.
- `0001_fondations.sql` : `session_recordings (expires_at, status available/expired/revoked, deleted_at)` ; config `recording_retention_days` 30 ; `camera_auto_allow_min_age` 11 ; `student_profiles.camera_policy` défaut `forbidden`.
- `0004` section 4 : `kyc_retention_days` 90, motif de refus.
- `0009_journal_audit.sql` : journal chaîné (intégrité vérifiable). Écoutes d'enregistrement et visites y sont inscrites (selon les commentaires et `contrat.pointEnregistrement`).
- `0011`, `0012` : visite de contrôle invisible, aucune ligne lisible par enseignant, élève ou famille.
- `0036`, `0037` : défauts d'observation académie, plafond de visites par groupe ; l'entrée en observation rend l'enfant « concerné ». **0035-0037 non appliquées** (LISEZ-MOI).
- Aucune table de consentements granulaires, aucune fonction de retrait, aucune demande de droits (accès, effacement, portabilité).

## 3. Code (lib)

- `lib/core/dossier/versions_contrat.dart` : versions `2026-09` (courante) et `2026-09-obs` (tuteur avec observation). Commentaire : `etat_dossier()` ne filtre pas la version, donc un compte actif n'est pas bloqué par une nouvelle version, seulement invité.
- `lib/features/dossier/signature_page.dart` : case jamais précochée (commentaire et `CaseAccordObservation`). Un seul bouton « J'ai lu et j'accepte » : **pas de bouton de refus** ni d'explication des conséquences.
- `contrat.lireTexte` « Lire le texte complet » : **aucun texte complet trouvé dans le dépôt** (la clé n'est utilisée par aucun écran). Le tuteur signe des « conditions d'utilisation » dont le texte intégral n'existe pas.
- `lib/core/profil/service_acceptations.dart`, `lib/core/capacites/consentements_supabase.dart` : lecture et écriture des acceptations.

## 4. Ressources et décisions

- `03_DECISIONS_COORDINATEUR.md` section 1 bis-2 : l'enregistrement audio est **réel** (bucket R2) ; on garde la notice mot pour mot. Section 1 bis-3 et 4 : texte d'observation, 2 visites par défaut par parent et par séance.
- `ressources/lancement/06_SPEC_FONCTIONNELLE_MVP.md` l.33 : contradiction ADR-002 (audio systématique 30 jours) et Control System V2 (« aucun enregistrement par défaut ») ; « Ne pas activer sur de vrais élèves avant décision écrite sur finalité, consentement, rétention, chiffrement, accès et conformité ».
- `08_DECISIONS_version_locale_poste_A.md` l.37 : le bandeau « Cours enregistré » doit être fidèle à l'état réel.
- `02_ARCHITECTURE_ET_SECURITE.md` point 6 : exigences légales et de localisation à valider avant ouverture réelle aux mineurs ; gel pour litige.
- `REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` section 6 : texte d'observation du directeur ; comptes existants non considérés comme ayant accepté.
- `05_recette/A/CONTEXTE.md` : P2 livré partiel (tests de geste et captures restants).
- Hébergement : Supabase projet `gggmtelinlpseweouyav` (région non lue dans le dépôt), Cloudflare R2, LiveKit, Vercel. Région et sous-traitants à confirmer.

## 5. Bilan

14 textes ou groupes de textes recensés, 3 sortes d'accord en base. Un seul accord (`guardian_terms`) couvre à la fois les conditions, l'enregistrement audio et l'observation : consentement groupé. Aucun retrait possible, aucun texte intégral, aucun écran de droits. Voir `SCENARIOS.md`, `TEXTES_V2.md`, `CHARTE.md`.
