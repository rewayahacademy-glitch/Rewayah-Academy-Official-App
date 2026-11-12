// COMPTE-A-REBOURS-JOURS (directeur, 12/11/2026) : un cours a plus d'un jour
// ne se dit jamais en heures (« Cours dans 110 h 14 »), il se dit en jours.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

import '../../support/demo/classe_demo.dart';

void main() {
  final DateTime t0 = DonneesClasseDemo.debutUtc;

  EmplacementEntree a(Duration avant, {RoleEntree role = RoleEntree.eleve}) =>
      EmplacementEntree.pour(
        role: role,
        horloge: SessionClockVM.depuisFenetre(
          fenetre: DonneesClasseDemo.fenetre,
          maintenantServeurUtc: t0.subtract(avant),
          horlogeUtilisateur: DonneesClasseDemo.horlogeUtilisateur,
          connecte: false,
        ),
        nomClasse: DonneesClasseDemo.classe,
        preparationEnCours: false,
      );

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('fr', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    test('110 h 14 : des jours, jamais des heures', () {
      final String l = a(const Duration(hours: 110, minutes: 14)).libelle;
      expect(l, matches(RegExp(r'^Cours dans [45] jours$')));
      expect(l, isNot(contains('110')));
    });

    test('quatre jours pleins : « Cours dans 4 jours »', () {
      expect(a(const Duration(days: 4)).libelle, 'Cours dans 4 jours');
    });

    test('a la veille : « Cours demain à HH:MM »', () {
      expect(
        a(const Duration(hours: 24)).libelle,
        matches(RegExp(r'^Cours demain à \d{1,2}[:h]\d{2}$')),
      );
    });

    test('moins d un jour : inchange (3 h 28, 45 min)', () {
      expect(
        a(const Duration(hours: 3, minutes: 28)).libelle,
        'Cours dans 3 h 28',
      );
      expect(a(const Duration(minutes: 45)).libelle, 'Cours dans 45 min');
    });
  });

  group('ar', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));

    test('quatre jours : « الدرس بعد 4 أيام », l entier isole', () {
      expect(a(const Duration(days: 4)).libelle, contains('أيام'));
      expect(a(const Duration(days: 4)).libelle, isNot(contains(' س ')));
    });

    test('moins d un jour : inchange, la valeur reste isolee', () {
      final String l = a(const Duration(hours: 3, minutes: 28)).libelle;
      expect(l, startsWith('الدرس بعد'));
      expect(l, contains('\u2068'));
    });

    test('a la veille : « غدًا »', () {
      expect(a(const Duration(hours: 24)).libelle, contains('غدًا'));
    });
  });
}
