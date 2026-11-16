// Le champ `complementEnCours` d'une ligne (capture de production CAND-00068 :
// « Clore le complement » proposé sans demande en cours). Ce que le test prouve :
// le champ est lu tel que le serveur le rend ; absent ou autre chose que vrai, il
// vaut faux ; et c'est lui, seul, qui ouvre le geste « clore le complément ».

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/features/admin_candidature/gestes_proposes.dart';

Map<String, Object?> _brut({Object? complement = _absent}) => <String, Object?>{
  'id': 'c1',
  'reference': 'CAND-000001',
  'etape': 'verifications',
  'etat': 'entretien_a_planifier',
  'issue': 'en_cours',
  'paiement': 'compatible',
  if (complement != _absent) 'complementEnCours': complement,
};

const Object _absent = Object();

void main() {
  test('vrai : lu vrai et le geste est propose', () {
    final LigneCandidature l = LigneCandidature.depuisJson(
      _brut(complement: true),
    )!;
    expect(l.complementEnCours, isTrue);
    expect(gestePermisPourLigne(GesteCandidature.cloreComplement, l), isTrue);
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
