import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/planning/service_remplacement_session.dart';

void main() {
  test('un remplacant est affiche par identite masquee si necessaire', () {
    final RemplacantEligible remplacant = RemplacantEligible.depuisJson(
      const <String, dynamic>{
        'teacher_id': 't1',
        'teacher_immutable_id': 'ENS-1',
        'teacher_prenom': null,
        'teacher_nom': null,
      },
    );

    expect(remplacant.libelle, 'ENS-1');
  });
}
