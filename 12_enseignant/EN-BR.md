# EN-BR : besoins serveur de la vague Enseignant (étape BR-1)

Sources : spec `04_ENSEIGNANT.md` §26 (contrats de lecture/écriture) et §27
(sécurité), `ENSEIGNANT-2026-09-26.md` (E1 à E20), K-45 (cahier de séance),
lecture de `supabase/` (migrations et fonctions, lecture seule). Aucun code
n'a été modifié pour produire ce document.

**Remarque préalable sur « K-47 ».** Le repère « K-47 (KYC enseignant
seulement) » cité dans la commande n'a été retrouvé ni dans la mémoire du
poste, ni dans `12_enseignant/`, ni dans `UX_REVIEW_04_ENSEIGNANT.md`, ni dans
l'historique du dépôt. Faute de source, ce document ne lui attribue aucun
contenu : il traite le KYC uniquement à partir de la spec (§8, §19, §24) et de
l'existant `supabase/`, et signale ce manque au directeur.

## Rappel du doc §26 et §27

- §26 attend treize contrats de lecture/écriture enseignant :
  `TeacherBootstrapVM`, `TeacherTodayVM`, `TeacherClassSummaryVM`,
  `TeacherClassHomeVM`, `TeacherStudentProjection`, `TeacherAvailabilityVM`,
  `TeacherClassOpportunityVM`, `reserve_teacher_class`,
  `TeacherAbsenceCommand`, `TeacherReplacementOfferVM`, `LessonCloseoutVM`,
  `TeacherConcernCommand`, `TeacherPublicPhoto`.
- §27 attend : des policies RLS testées (Classe A invisible à un autre
  enseignant, accès du remplaçant borné et temporaire, aucune donnée
  familiale privée dans la projection élève), un jeton LiveKit court et
  permissionné par séance, une séparation stricte photo publique / coffre KYC
  sur R2, et un audit des corrections de présence, absences, remplacements et
  modifications pédagogiques sensibles.

## Besoin par écran de démonstration

| Écran (fournisseur démo) | Donnée | RPC / table probable | État |
|---|---|---|---|
| Aujourd'hui, Classes (`enseignant_demo.dart`, `ClasseEnseignantDemo`, `SeanceEnseignant`) | Séances et groupes de l'enseignant | `mes_seances_enseignant_v`, `mes_groupes_v` | **Existe déjà**, branché dans `ServiceEnseignantSupabase` (non démo) |
| Fiche groupe, roster (`fiche_groupe_page.dart`) | Membres actifs d'une Classe | `teacher_roster_v`, RPC `mon_groupe_detail` | **Existe déjà** |
| Profil enseignant (`profil_enseignant_page.dart`) | Bootstrap : langues, plafond d'heures, statut KYC | table `teacher_profiles` via `profiles(...)` | **Existe déjà**, lu par `ServiceProfilEnseignantSupabase` |
| Photo publique (`photo_publique.dart`) | Photo distincte du KYC, visible dans les Classes | seau Storage `photos_enseignants` (policies déjà posées : écriture par l'enseignant, lecture par lui, l'académie et les membres de ses groupes) | **Existe déjà**, mais aucun service Flutter réel ne l'écrit encore (câblage BR-1, pas de nouvelle table) |
| Cahier de séance (`cahier/`, `enseignant_demo.dart` → `BrouillonCahier`, `CahierDemo`) | Brouillon préparé par le serveur, dépôt du cahier | RPC `brouillon_cahier`, table `lesson_reports` (insert) | **Existe déjà pour le dépôt simple** ; **à créer** pour K-45 (voir plus bas) |
| Cahiers à terminer (bandeau « À terminer ») | Cahiers en retard | RPC `mes_rapports_en_attente` | **Existe déjà** |
| Disponibilités (`disponibilites_page.dart`, `grille_semaine.dart`) | Grille hebdomadaire de l'enseignant | table `weekly_availability` (déjà lue/écrite côté famille par `ServicePlanning`, jamais côté enseignant) | **À créer** : le câblage Flutter enseignant, pas la table |
| Classes disponibles / opportunité (`OffreClasseDemo`, ENS-06) | Classe proposée, compatibilité, réservation | `TeacherClassOpportunityVM` et `reserve_teacher_class` du doc §26.7/26.8 | **À créer entièrement** : `offres_horaires` / `intentions_horaire` (migration 0043) servent la file élève/famille, pas la candidature d'un enseignant à une Classe |
| Absence et remplacement (`absence_remplacement.dart`, `RemplacementDemo`) | Déclarer une absence sur une occurrence, offre de remplacement, acceptation | `TeacherAbsenceCommand`, `TeacherReplacementOfferVM` du doc §26.9/26.10 | **À créer entièrement** : aucune table « absence » ni « remplacement » dans `supabase/migrations/` ; pas de notion d'occurrence versionnée non plus |
| Signalement (`feuille_signalement.dart`, `TeacherConcernCommand`) | Catégorie, détails internes, résumé partageable | table `student_concern` (RLS déjà posée : insert par l'enseignant du groupe et de la séance, lecture academie/enseignant séparée) | **Existe déjà côté base** ; **à créer** le service Flutter réel (le fichier actuel n'a qu'un modèle et un port, pas d'appel Supabase) |
| Revue de Classe (`revue_groupe_page.dart`, `anomalies_revue.dart`) | Palier à venir, hors corridor, transfert proposé, réorientation proposée | Le code documente lui-même l'écart : `0020` à `0024` calculent ces anomalies, mais leurs policies sont `app_role() = 'admin'` seulement | **À créer** : une RPC bornée à l'enseignant sur ses seuls groupes, aucune nouvelle notion à inventer (la correspondance anomalie ↔ table est déjà actée dans le code) |
| Raccourcis clavier de la salle (EN-KB) | M, V, R, B, Échap | Aucun | **Sans besoin serveur** : réglage local uniquement |

## K-45, le cahier de séance = séance payée

Le dépôt de cahier existe (`ServiceEnseignantSupabase.deposerCahier`, table
`lesson_reports`), mais seulement comme un insert protégé par une clé
d'idempotence : une ligne, jamais modifiée. Or K-45 exige, pour BR-1 :

- qu'une séance ne soit payée que lorsque son cahier est validé (aujourd'hui,
  rien dans `sessions`, `wallet_entries` ni `payouts` ne relie un paiement à
  la présence ou à l'absence d'un `lesson_reports` validé) ;
- que « où la Classe s'est arrêtée » (position de reprise) soit obligatoire à
  la validation, pour qu'un remplaçant la retrouve ;
- que le cahier reste corrigeable après validation, avec un historique des
  corrections visible seulement de l'académie (la table actuelle n'a ni
  statut « validé », ni mécanisme de correction, ni table d'historique) ;
- que l'enseignant ne soit jamais bloqué par un cahier manquant, seulement
  non payé, avec une notice sur l'espace Paye (l'espace Paye lui-même n'a pas
  encore d'écran ni de source de vérité liée au cahier).

**À créer** : un statut de validation sur `lesson_reports` (ou une table
dérivée), une table de correction/historique réservée à l'académie, et le
lien entre validation du cahier et déclenchement du paiement. Rien de tout
cela n'existe dans les migrations lues.

## Sécurité et confidentialité (§27)

- RLS : les tests attendus (Classe A invisible à l'enseignant B, accès
  temporaire du remplaçant, aucune donnée familiale dans la projection
  élève) sont **à écrire** ; les policies déjà posées sur `student_concern`
  et sur `photos_enseignants` vont dans ce sens, mais aucune table
  d'occurrence ni de remplacement n'existe encore à tester.
- LiveKit : jeton par séance, court, permissionné — déjà couvert par
  `create-room-token` (fonction Edge existante), à revérifier pour le rôle
  enseignant précisément à l'étape BR-1.
- R2 : la séparation photo publique / KYC est déjà réelle (deux emplacements
  Storage distincts, `kyc_documents` côté coffre, `photos_enseignants` côté
  public).
- Audit : `audit_logs` existe déjà (migration `0009`) ; il reste à y verser
  les événements propres à l'enseignant (correction de cahier, déclaration
  d'absence, acceptation de remplacement) une fois ces mécanismes créés.

## Résumé en 5 lignes

Le document `EN-BR.md` est écrit à `C:\RA\pilotage\12_enseignant\EN-BR.md`,
sans code ni commit. Beaucoup existe déjà côté serveur pour l'enseignant
(séances, groupes, roster, profil, dépôt simple de cahier, signalement,
disponibilités familiales, photo publique). Trois besoins sont entièrement à
créer : la candidature à une Classe disponible, la déclaration d'absence
et le remplacement, et la revue de Classe côté enseignant. Le cahier de
séance a le plus gros écart avec K-45 : validation liée à la paye, position
de reprise obligatoire, correction avec historique réservé à l'académie
restent à concevoir. Le repère « K-47 » cité dans la commande est introuvable
dans les sources connues et n'a donc reçu aucun contenu inventé.
