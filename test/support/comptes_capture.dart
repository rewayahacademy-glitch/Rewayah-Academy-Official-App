// Les comptes fictifs des captures de la refonte des listes (LISTES-1,
// 23/10/2026) : eleves, tuteurs (enseignants), responsables de foyer.
// Aucune personne reelle ; aucun courriel.

import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';

/// Un double de [ServiceComptes] qui rend [liste].
class FauxComptesCapture implements ServiceComptes {
  /// Cree le double.
  const FauxComptesCapture(this.liste);

  /// Les comptes rendus.
  final List<CompteAdmin> liste;

  @override
  Future<List<CompteAdmin>> comptes() async => liste;
}

CompteAdmin _c(
  String id,
  String prenom,
  String nom,
  AppRole role, {
  AccountStatus etat = AccountStatus.active,
  EtatPiece piece = EtatPiece.aucune,
  String? pays,
  int jours = 40,
  int contrats = 2,
  bool aEnseignant = false,
  int enfants = 0,
}) => CompteAdmin(
  profilId: id,
  identifiant: id,
  prenom: prenom,
  nom: nom,
  role: role,
  etat: etat,
  inscritLe: DateTime.utc(2026, 10, 23).subtract(Duration(days: jours)),
  accesJusquAu: null,
  foyerId: null,
  piece: piece,
  contrats: contrats,
  aEnseignant: aEnseignant,
  enfantsDuFoyer: enfants,
  paysEnseignant: pays,
);

/// Seize comptes : des eleves, des tuteurs, des responsables de foyer.
List<CompteAdmin> comptesCapture() => <CompteAdmin>[
  _c(
    'TEACH-ID-000001',
    'Ibrahim',
    'Diallo',
    AppRole.teacher,
    etat: AccountStatus.pendingKyc,
    pays: 'Guinée',
    jours: 9,
  ),
  _c(
    'TEACH-KS-000002',
    'Khadija',
    'Sow',
    AppRole.teacher,
    piece: EtatPiece.validee,
    pays: 'Sénégal',
  ),
  _c(
    'TEACH-MB-000003',
    'Mariam',
    'Barry',
    AppRole.teacher,
    piece: EtatPiece.aVerifier,
    pays: 'France',
    jours: 12,
  ),
  _c(
    'TEACH-OT-000004',
    'Oumar',
    'Traore',
    AppRole.teacher,
    piece: EtatPiece.validee,
    pays: 'Mali',
  ),
  _c(
    'TEACH-NH-000005',
    'Nour',
    'Haddad',
    AppRole.teacher,
    piece: EtatPiece.validee,
    pays: 'Maroc',
  ),
  _c('GUAR-AD-000006', 'Aicha', 'Diop', AppRole.guardian, enfants: 2),
  _c('GUAR-YB-000007', 'Youssef', 'Benali', AppRole.guardian, enfants: 1),
  _c(
    'GUAR-FC-000008',
    'Fatou',
    'Camara',
    AppRole.guardian,
    etat: AccountStatus.provisionalActive,
    enfants: 3,
    jours: 5,
  ),
  _c('STUD-AD-000009', 'Amine', 'Diop', AppRole.student, aEnseignant: true),
  _c('STUD-SD-000010', 'Salma', 'Diop', AppRole.student, aEnseignant: true),
  _c('STUD-YB-000011', 'Yasmine', 'Benali', AppRole.student, aEnseignant: true),
  _c('STUD-IC-000012', 'Ismael', 'Camara', AppRole.student),
  _c('STUD-MC-000013', 'Maryam', 'Camara', AppRole.student, aEnseignant: true),
  _c(
    'STUD-HC-000014',
    'Hamza',
    'Camara',
    AppRole.student,
    etat: AccountStatus.disabled,
  ),
  _c('STUD-LK-000015', 'Lina', 'Kone', AppRole.student, aEnseignant: true),
  _c('STUD-ZR-000016', 'Zaynab', 'Rahmani', AppRole.student),
];
