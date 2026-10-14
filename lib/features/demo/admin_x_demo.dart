// Donnees fictives de l'etape AD-X (Accueil, Espace de traitement), pour la
// demonstration admin seulement (`surchargesDemoAdmin`, garde compilee
// `environnementAutoriseDemo`, K-09). Noms synthetiques, aucune vraie
// identite, aucun appel serveur.

import '../../core/admin/service_groupes.dart';
import '../../core/domain/enums.dart';
import '../../core/journal/service_journal.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/service_planning.dart' show Creneau;

/// Les trois dernieres entrees du journal, telles que l'Accueil les montre
/// (colonne « Activite recente », ADMIN-SHELL-01). [maintenant] est l'heure
/// locale de la demonstration : les delais restent vrais quel que soit le
/// moment de l'ouverture.
List<EntreeJournal> activiteRecenteDemo(DateTime maintenant) => <EntreeJournal>[
  EntreeJournal(
    id: 3,
    survenuLe: maintenant.subtract(const Duration(hours: 2)),
    typeEvenement: 'profil_cree',
    tableVisee: 'profiles',
    acteur: 'demo-ines',
    roleActeur: 'teacher',
    nomActeur: 'Inès Exemple',
    details: const <String, dynamic>{},
  ),
  EntreeJournal(
    id: 2,
    survenuLe: maintenant.subtract(const Duration(hours: 5)),
    typeEvenement: 'demande_creee',
    tableVisee: 'matching_requests',
    acteur: 'demo-karim',
    roleActeur: 'guardian',
    nomActeur: 'Karim Fictif',
    details: const <String, dynamic>{},
  ),
  EntreeJournal(
    id: 1,
    survenuLe: maintenant.subtract(const Duration(days: 1, hours: 1)),
    typeEvenement: 'kyc_decision',
    tableVisee: 'kyc_documents',
    acteur: 'demo-admin',
    roleActeur: 'admin',
    nomActeur: 'Direction Démo',
    details: const <String, dynamic>{},
  ),
];

/// Deux demandes en attente, pour l'Espace de traitement et la tuile
/// « Demandes a trancher » de la demonstration (meme nombre des deux cotes).
List<Demande> demandesDemo(DateTime maintenant) => <Demande>[
  Demande(
    id: 'demo-demande-1',
    sorte: SorteDemande.reaffectation,
    sujetId: 'demo-eleve-1',
    sujetPrenom: 'Sami',
    sujetIdentifiant: 'STUDENT-SD-000001',
    motif: 'Les horaires de la classe ne conviennent plus à la famille.',
    roleDemandeur: AppRole.guardian,
    creeeLe: maintenant.subtract(const Duration(hours: 5)),
  ),
  Demande(
    id: 'demo-demande-2',
    sorte: SorteDemande.plafond,
    sujetId: 'demo-enseignant-1',
    sujetPrenom: 'Inès',
    sujetIdentifiant: 'TEACHER-IE-000002',
    motif: 'Je peux accueillir deux élèves de plus le mercredi.',
    roleDemandeur: AppRole.teacher,
    valeurDemandee: 8,
    creeeLe: maintenant.subtract(const Duration(days: 3)),
  ),
];

/// Quatre classes fictives (ADMIN-SHELL-03) : trois actives, une cloturee.
/// Ajouter, retirer et cloturer passent par le service de la demonstration,
/// qui repond « indisponible » ; la creation passe par `CreationClasseDemo`
/// (CLASSE-FORM-1), en memoire.
List<GroupeAdmin> groupesDemo() => const <GroupeAdmin>[
  GroupeAdmin(
    id: 'demo-classe-1',
    libelle: 'Classe An-Nour',
    type: TypePublicGroupe.enfant,
    seuilMax: 6,
    teacherId: 'demo-ens-1',
    teacherIdentifiant: 'TEACHER-AE-000001',
    teacherPrenom: 'Amina',
    teacherNom: 'Exemple',
    creneau: Creneau(jour: 3, heure: 17, fuseau: 'Europe/Paris'),
    nombreMembres: 3,
    actif: true,
  ),
  GroupeAdmin(
    id: 'demo-classe-2',
    libelle: 'Classe Al-Furqan',
    type: TypePublicGroupe.adulte,
    seuilMax: 8,
    teacherId: 'demo-ens-2',
    teacherIdentifiant: 'TEACHER-OF-000002',
    teacherPrenom: 'Omar',
    teacherNom: 'Fictif',
    creneau: Creneau(jour: 6, heure: 10, fuseau: 'Europe/Paris'),
    nombreMembres: 5,
    actif: true,
  ),
  GroupeAdmin(
    id: 'demo-classe-3',
    libelle: 'Classe As-Sabr',
    type: TypePublicGroupe.enfant,
    seuilMax: 6,
    teacherId: 'demo-ens-3',
    teacherIdentifiant: 'TEACHER-IE-000003',
    teacherPrenom: 'Inès',
    teacherNom: 'Modèle',
    creneau: Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
    nombreMembres: 4,
    actif: true,
  ),
  GroupeAdmin(
    id: 'demo-classe-4',
    libelle: 'Classe Al-Hikma',
    type: TypePublicGroupe.adulte,
    seuilMax: 8,
    teacherId: 'demo-ens-2',
    teacherIdentifiant: 'TEACHER-OF-000002',
    teacherPrenom: 'Omar',
    teacherNom: 'Fictif',
    creneau: Creneau(jour: 4, heure: 20, fuseau: 'Europe/Paris'),
    nombreMembres: 0,
    actif: false,
  ),
];

/// Les eleves fictifs d'une classe de la demonstration.
List<MembreGroupe> membresDemo(String groupeId) => <MembreGroupe>[
  for (final (String prenom, String nom) p in const <(String, String)>[
    ('Mariam', 'Exemple'),
    ('Yusuf', 'Démo'),
    ('Aïcha', 'Fictif'),
  ])
    MembreGroupe(
      studentId: '$groupeId-${p.$1}',
      identifiant: 'STUDENT-${p.$1.toUpperCase()}',
      prenom: p.$1,
      nom: p.$2,
      rejointLe: DateTime(2026, 9, 1),
    ),
];
