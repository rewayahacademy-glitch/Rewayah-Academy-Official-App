// FN-113 (01/11/2026) : le directeur bloque a la creation d'une classe,
// l'enseignant tenant deja 3 classes. Le serveur leve
// `plafond_classes_atteint` (20261022000200) avec en DETAIL « classes
// actives : 3 ; maximum : 3 » ; l'ecran le dit, avec les deux sorties.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creation_classe_refusee.dart';
import 'package:rewayah_academy/core/admin/plafond_classes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/affectation_refusee.dart';
import 'package:rewayah_academy/features/admin_groupes/refus_creation_classe_libelles.dart';
import 'package:rewayah_academy/features/admin_groupes/refus_deplacement_libelles.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_libelles.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('nombresPlafondClasses', () {
    test('lit le DETAIL du serveur', () {
      expect(nombresPlafondClasses('classes actives : 3 ; maximum : 3'), (
        actives: 3,
        maximum: 3,
      ));
      expect(nombresPlafondClasses('Classes actives: 12 ; maximum: 4'), (
        actives: 12,
        maximum: 4,
      ));
    });
    test('rien d invente sans DETAIL lisible', () {
      expect(nombresPlafondClasses(null), (actives: null, maximum: null));
      expect(nombresPlafondClasses('plafond'), (actives: null, maximum: null));
    });
  });

  group('creation de classe', () {
    test('les codes jusqu ici generiques ont leur motif', () {
      expect(
        motifRefusCreationClasse(
          code: 'P0001',
          message: 'plafond_classes_atteint',
        ),
        MotifRefusCreationClasse.plafondClasses,
      );
      expect(
        motifRefusCreationClasse(code: '22023', message: 'CreneauxEnDouble'),
        MotifRefusCreationClasse.creneaux,
      );
      expect(
        motifRefusCreationClasse(code: '22023', message: 'CreneauxInvalides'),
        MotifRefusCreationClasse.creneaux,
      );
    });

    test('le refus porte les nombres du DETAIL', () async {
      Future<void> appel() async => throw const PostgrestException(
        message: 'plafond_classes_atteint',
        code: 'P0001',
        details: 'classes actives : 3 ; maximum : 3',
      );
      await expectLater(
        traduireRefusCreationClasse(appel),
        throwsA(
          isA<CreationClasseRefusee>()
              .having(
                (CreationClasseRefusee r) => r.motif,
                'motif',
                MotifRefusCreationClasse.plafondClasses,
              )
              .having((CreationClasseRefusee r) => r.actives, 'actives', 3)
              .having((CreationClasseRefusee r) => r.maximum, 'maximum', 3),
        ),
      );
    });

    test('la phrase dit le nombre et les deux sorties, FR et AR', () async {
      final String trois = phraseRefusCreationClasse(
        MotifRefusCreationClasse.plafondClasses,
        actives: 3,
        maximum: 3,
      ).replaceAll(' ', ' ');
      expect(trois, contains('3 classes actives, pour un maximum de 3'));
      expect(trois, contains('Clôturez une de ses classes'));
      expect(trois, contains('relevez le maximum dans les Règles'));
      final String une = phraseRefusCreationClasse(
        MotifRefusCreationClasse.plafondClasses,
        actives: 1,
        maximum: 1,
      ).replaceAll(' ', ' ');
      expect(une, contains('1 classe active, pour un maximum de 1'));
      expect(
        phraseRefusCreationClasse(MotifRefusCreationClasse.plafondClasses),
        t.admin.groupes.refusCreation.plafondClassesSansNombre,
      );
      await LocaleSettings.setLocale(AppLocale.ar);
      final String ar = phraseRefusCreationClasse(
        MotifRefusCreationClasse.plafondClasses,
        actives: 3,
        maximum: 3,
      );
      expect(ar, contains('\u20683\u2069'));
      expect(ar, contains('القواعد'));
      expect(ar, isNot(contains('plafond')));
    });
  });

  group('affectation et deplacement', () {
    test('les codes jusqu ici generiques ont leur motif', () {
      expect(
        motifRefusAffectation(
          code: 'P0001',
          message: 'plafond_classes_atteint',
        ),
        MotifRefusAffectation.plafondClasses,
      );
      expect(
        motifRefusAffectation(
          code: 'P0001',
          message: 'deja_affecte ou classe indisponible',
        ),
        MotifRefusAffectation.classeIndisponible,
      );
      expect(
        motifRefusAffectation(
          code: 'P0001',
          message: "affectation reservee a l'administration active",
        ),
        MotifRefusAffectation.reservee,
      );
      expect(
        motifRefusDeplacementClasse(
          code: 'P0001',
          message: 'plafond_classes_atteint',
        ),
        MotifRefusAffectation.plafondClasses,
      );
    });

    test('AffectationRefusee.depuis lit le DETAIL du plafond seulement', () {
      final AffectationRefusee r = AffectationRefusee.depuis(
        MotifRefusAffectation.plafondClasses,
        'classes actives : 4 ; maximum : 3',
      );
      expect((r.actives, r.maximum), (4, 3));
      final AffectationRefusee autre = AffectationRefusee.depuis(
        MotifRefusAffectation.plafond,
        'classes actives : 4 ; maximum : 3',
      );
      expect((autre.actives, autre.maximum), (null, null));
    });

    test('les phrases nomment le maximum, jamais le code', () {
      final String confirmation = libelleRefusAffectation(
        MotifRefusAffectation.plafondClasses,
        actives: 3,
        maximum: 3,
      ).replaceAll(' ', ' ');
      expect(confirmation, contains('3 classes actives, pour un maximum de 3'));
      expect(confirmation, isNot(contains('plafond_classes_atteint')));
      final String horaire = phraseRefusDeplacement(
        MotifRefusAffectation.plafondClasses,
      );
      expect(
        horaire,
        t.admin.groupes.refusDeplacement.plafondClassesSansNombre,
      );
    });
  });
}
