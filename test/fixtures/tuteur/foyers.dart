// Deux foyers fictifs, pour les tests de non-croisement du role Tuteur.
//
// PROPRIETE : coordinateur (contrats K1 a K7, `test/fixtures/tuteur/`).
// **Aucune ligne de production n'importe ce fichier** : il vit sous `test/`,
// et le test `fixtures_isolees_test.dart` verifie qu'aucun double n'est servi
// par un provider de `lib/`.
//
// Aucun nom ni aucune photo reels : des prenoms-etiquettes (`Élève A1`), des
// identifiants lisibles qui disent leur foyer, aucune cle d'avatar.

import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';

/// Les eleves du foyer A (deux profils) et du foyer B (un profil).
abstract final class FoyersFictifs {
  /// Premier eleve du foyer A, en interface guidee.
  static const EleveDuFoyer a1 = EleveDuFoyer(
    id: 'foyer-a-eleve-1',
    prenom: 'Élève A1',
    identifiantImmuable: 'STUD-FA-000001',
    mode: InterfaceMode.enfant,
    camera: CameraPolicy.forbidden,
  );

  /// Second eleve du foyer A, en interface standard.
  static const EleveDuFoyer a2 = EleveDuFoyer(
    id: 'foyer-a-eleve-2',
    prenom: 'Élève A2',
    identifiantImmuable: 'STUD-FA-000002',
    mode: InterfaceMode.standard,
    camera: CameraPolicy.allowed,
  );

  /// Le seul eleve du foyer B. Jamais visible depuis le foyer A.
  static const EleveDuFoyer b1 = EleveDuFoyer(
    id: 'foyer-b-eleve-1',
    prenom: 'Élève B1',
    identifiantImmuable: 'STUD-FB-000001',
    mode: InterfaceMode.standard,
    camera: CameraPolicy.forbidden,
  );

  /// Le foyer A, dans un ordre volontairement inverse de l'ordre attendu.
  static const List<EleveDuFoyer> foyerA = <EleveDuFoyer>[a2, a1];

  /// Le foyer B.
  static const List<EleveDuFoyer> foyerB = <EleveDuFoyer>[b1];

  /// Un foyer sans eleve.
  static const List<EleveDuFoyer> foyerVide = <EleveDuFoyer>[];

  /// Le profil selectionnable d'un eleve fictif.
  static ProfilEleveFoyer profil(EleveDuFoyer eleve) =>
      ProfilEleveFoyer.depuis(eleve);
}
