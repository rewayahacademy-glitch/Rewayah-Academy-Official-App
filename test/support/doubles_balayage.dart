// COUPE-MOTS-FOND-1 : les doubles des balayages de la garde du rendu, avec
// ce que la fiche a vu couper : des dates (« 23/09/2026 »), des heures
// (« 18:12 »), des identifiants longs (« TEACHER-AS-000001 »).

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';

import 'harnais.dart' show FauxServiceJournal, FauxServiceReseau;

CompteAdmin _compte(
  String id,
  AccountStatus etat,
  AppRole role, {
  String? prenom = 'Aicha',
}) => CompteAdmin(
  profilId: id,
  identifiant: id,
  prenom: prenom,
  nom: prenom == null ? null : 'Sow',
  role: role,
  etat: etat,
  inscritLe: DateTime(2026, 9, 23, 18, 12),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 2,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

/// Des comptes aux identifiants longs et a tous les etats.
class ComptesBalayage implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    _compte('TEACHER-AS-000001', AccountStatus.pendingKyc, AppRole.teacher),
    _compte(
      'TEACHER-AS-000002',
      AccountStatus.pendingKyc,
      AppRole.teacher,
      prenom: null,
    ),
    _compte('GUARDIAN-FD-000014', AccountStatus.active, AppRole.guardian),
    _compte('ADMIN-KN-000003', AccountStatus.provisionalActive, AppRole.admin),
    _compte('TEACHER-MB-000021', AccountStatus.disabled, AppRole.teacher),
  ];
}

EntreeJournal _entree(int id, String type, String table) => EntreeJournal(
  id: id,
  survenuLe: DateTime(2026, 9, 23, 18, 12).subtract(Duration(minutes: id)),
  acteur: 'u1',
  roleActeur: 'admin',
  nomActeur: 'Khadija Ndiaye',
  typeEvenement: type,
  tableVisee: table,
  ligneVisee: 'b5c1f0d2-7a43-4e1f-9c2b-3d8e6f0a1b2c',
  details: const <String, dynamic>{'statut': 'enregistree'},
);

/// Un journal a trois entrees.
FauxServiceJournal journalBalayage() => FauxServiceJournal()
  ..entreesEnBase = <EntreeJournal>[
    _entree(1, 'kyc_read', 'kyc_documents'),
    _entree(2, 'account_status_changed', 'profiles'),
    _entree(3, 'observation_entry_recorded', 'observation_visits'),
  ]
  ..filtres0 = const FiltresJournal(
    actions: <ValeurFiltre>[
      ValeurFiltre(valeur: 'kyc_read', libelle: 'kyc_read', nombre: 3),
    ],
    acteurs: <ValeurFiltre>[
      ValeurFiltre(valeur: 'u1', libelle: 'Khadija Ndiaye', nombre: 3),
    ],
    total: 3,
  );

/// Un reseau en ligne.
Override reseauBalayage() =>
    serviceReseauProvider.overrideWithValue(FauxServiceReseau());
