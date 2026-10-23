// B-09 : lecture des reponses de `declarer_absence_seance` et de la cle
// d'idempotence des actions de remplacement (aucun reseau).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/remplacements_supabase.dart';

void main() {
  test("l'etat d'absence est celui que rend le serveur, sinon nul", () {
    expect(
      etatAbsenceServeur(<String, Object?>{'etat': 'absence_declaree'}),
      EtatAbsence.enregistree,
    );
    expect(
      etatAbsenceServeur(<String, Object?>{'etat': 'remplacement_pris'}),
      EtatAbsence.remplacantConfirme,
    );
    expect(
      etatAbsenceServeur(<String, Object?>{
        'etat': 'remplacement_designe_admin',
      }),
      EtatAbsence.remplacantConfirme,
    );
    expect(etatAbsenceServeur(<String, Object?>{'etat': 'autre'}), isNull);
    expect(etatAbsenceServeur(null), isNull);
  });

  test('la cle est stable par seance et distincte par action', () {
    const String seance = '11111111-1111-4111-8111-111111111111';
    expect(
      cleRemplacement('absence', seance),
      cleRemplacement('absence', seance),
    );
    expect(
      cleRemplacement('absence', seance),
      isNot(cleRemplacement('prise', seance)),
    );
    expect(
      RegExp(r'^[0-9a-f-]{36}$').hasMatch(cleRemplacement('prise', seance)),
      isTrue,
    );
  });
}
