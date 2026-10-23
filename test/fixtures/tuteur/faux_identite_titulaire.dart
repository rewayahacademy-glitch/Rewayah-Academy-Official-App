// Double du port d'identite du titulaire (contrat K6).
//
// PROPRIETE : coordinateur (`test/fixtures/tuteur/`). Aucun nom ni courriel
// reels : le domaine `.test` est reserve et ne recoit aucun courrier.

import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';

/// Le titulaire fictif du foyer A.
const IdentiteTitulaire titulaireFoyerA = IdentiteTitulaire(
  prenom: 'Titulaire A',
  nom: 'Foyer A',
  courriel: 'titulaire.a@exemple.test',
  methodeConnexion: MethodeConnexion.lienCourriel,
  statut: AccountStatus.active,
);

/// Le port d'identite, en memoire. La modification reste indisponible, comme
/// en production (DB-CPT-01).
class FauxIdentiteTitulaire implements PortIdentiteTitulaire {
  /// Cree le faux.
  FauxIdentiteTitulaire({this.identite = titulaireFoyerA});

  /// L'identite rendue.
  IdentiteTitulaire identite;

  @override
  Future<IdentiteTitulaire> lire() async => identite;

  @override
  Future<void> modifier({String? prenom, String? nom}) async =>
      throw const CapaciteIndisponible('DB-CPT-01');
}
