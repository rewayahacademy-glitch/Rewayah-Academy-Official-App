// Le champ `complementEnCours` d'une ligne (capture de production CAND-00068 :
// « Clore le complement » proposé sans demande en cours). Ce que le test prouve :
// le champ est lu tel que le serveur le rend ; absent ou autre chose que vrai, il
// vaut faux. Depuis GESTES-DU-SERVEUR, le geste « clore le complément » est ouvert
// par le seul nom `clore_complement` de la cle `gestes` de la ligne (le serveur le
// sert quand la regle et un complement en cours le permettent) : le champ ne
// l'ouvre plus tout seul.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/features/admin_candidature/gestes_proposes.dart';

Map<String, Object?> _brut({
  Object? complement = _absent,
  List<String> gestes = const <String>[],
}) => <String, Object?>{
  'id': 'c1',
  'gestes': gestes,
  'reference': 'CAND-000001',
  'etape': 'verifications',
  'etat': 'entretien_a_planifier',
  'issue': 'en_cours',
  'paiement': 'compatible',
  if (complement != _absent) 'complementEnCours': complement,
};

const Object _absent = Object();

void main() {
  test('vrai : lu vrai ; le geste est propose quand le serveur le sert', () {
    final LigneCandidature l = LigneCandidature.depuisJson(
      _brut(complement: true, gestes: const <String>['clore_complement']),
    )!;
    expect(l.complementEnCours, isTrue);
    expect(gestePermisPourLigne(GesteCandidature.cloreComplement, l), isTrue);
  });

  test('vrai mais non servi : le champ seul n\'ouvre pas le geste', () {
    final LigneCandidature l = LigneCandidature.depuisJson(
      _brut(complement: true),
    )!;
    expect(l.complementEnCours, isTrue);
    expect(gestePermisPourLigne(GesteCandidature.cloreComplement, l), isFalse);
  });

  for (final (String nom, Object? valeur) in <(String, Object?)>[
    ('faux', false),
    ('nul', null),
    ('une chaine', 'true'),
    ('un nombre', 1),
  ]) {
    test('$nom : faux, le geste n\'est pas propose', () {
      final LigneCandidature l = LigneCandidature.depuisJson(
        _brut(complement: valeur),
      )!;
      expect(l.complementEnCours, isFalse);
      expect(
        gestePermisPourLigne(GesteCandidature.cloreComplement, l),
        isFalse,
      );
    });
  }

  test('absent (serveur d\'avant) : faux, le geste n\'est pas propose', () {
    final LigneCandidature l = LigneCandidature.depuisJson(_brut())!;
    expect(l.complementEnCours, isFalse);
    expect(gestePermisPourLigne(GesteCandidature.cloreComplement, l), isFalse);
  });
}
