import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_classes_admin.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';

void main() {
  test('un brouillon peut être rendu sans titulaire', () {
    final GroupeAdmin exemple = GroupeAdmin.depuisJson(
      const <String, dynamic>{
        'groupe_id': 'g1',
        'type_public': 'enfant',
        'teacher_id': null,
        'teacher_immutable_id': null,
        'weekday': 1,
        'hour_local': 18,
        'nombre_membres': 3,
        'seuil_max': 5,
        'actif': true,
        'etat': 'brouillon',
      },
    );

    expect(exemple.teacherId, isNull);
    expect(exemple.etat, 'brouillon');
  });

  test('le pool conserve langue, cohorte et statut diagnostic', () {
    final IntentionPoolAdmin intention = IntentionPoolAdmin.depuisJson(
      const <String, dynamic>{
        'intention_id': 'i1',
        'eleve_id': 's1',
        'eleve_immutable_id': 'ELV-1',
        'eleve_prenom': 'Awa',
        'langue_code': 'poular',
        'cohorte': 'enfant_10_13',
        'diagnostic_statut': 'fait',
        'niveau_id': 'n1',
        'etat': 'enregistree',
      },
    );

    expect(intention.eleveLibelle, 'Awa');
    expect(intention.langueCode, 'poular');
    expect(intention.cohorte, 'enfant_10_13');
    expect(intention.diagnosticStatut, 'fait');
  });
}
