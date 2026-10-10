// Lot I (COM-RC5), R-08 / D-FUS-1 choix a (decision du directeur du 05/10) :
// l'arabe est garde, et les dates des Communications suivent la langue
// choisie. En arabe : mois et jours arabes, ordre « jour mois annee » lu de
// droite a gauche, chiffres de l'interface ; plus aucun mot francais (« oct. »)
// ni virgule arabe colle a un texte francais.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/dates_appareil.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart';

/// Dimanche 4 octobre 2026, 9:05 (heure locale).
final DateTime _le = DateTime(2026, 10, 4, 9, 5);
final DateTime _maintenant = DateTime(2026, 10, 5, 12);

final RegExp _francais = RegExp(
  'janv|févr|avr|juil|sept|oct|nov|déc|octobre|dimanche|Dimanche|lundi',
);

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('R-08 : les dates des Communications suivent la langue', () {
    test('francais : inchange', () {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(dateCourte(_le), '4 oct. 2026');
      expect(dateCompacte(_le, _maintenant), '4 oct.');
      expect(dateLongueHistorique(_le), 'dimanche 4 octobre 2026');
      expect(dateMoyenne(_le), 'dimanche 4 oct. 2026');
      expect(dateDeLAppareil(_le), 'Dimanche 4 octobre');
      expect(momentCourt(_le, _maintenant), '4 octobre');
      // Le jour lie a son mois par une espace insecable (lot L).
      expect(horodatageMessage(_le), 'Dimanche 4\u00A0octobre, 09:05');
    });

    // Reunion de la ligne arabe (10/10) : les gabarits de date arabes isolent
    // chaque champ (U+2068 ... U+2069).
    test('arabe : mois et jours arabes, aucun mot francais', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(
        dateCourte(_le),
        '\u20684\u2069 \u2068أكتوبر\u2069 \u20682026\u2069',
      );
      expect(
        dateCompacte(_le, _maintenant),
        '\u20684\u2069 \u2068أكتوبر\u2069',
      );
      expect(
        dateLongueHistorique(_le),
        '\u2068الأحد\u2069 \u20684\u2069 \u2068أكتوبر\u2069 \u20682026\u2069',
      );
      expect(
        dateMoyenne(_le),
        'الأحد \u20684\u2069 \u2068أكتوبر\u2069 \u20682026\u2069',
      );
      expect(
        dateDeLAppareil(_le),
        '\u2068الأحد\u2069 \u20684\u2069 \u2068أكتوبر\u2069',
      );
      expect(momentCourt(_le, _maintenant), isNot(contains('oct')));
      final String horodatage = horodatageMessage(_le);
      expect(
        horodatage,
        '\u2068الأحد\u2069 \u20684\u2069\u00A0\u2068أكتوبر\u2069 · 09:05',
      );
      for (final String texte in <String>[
        dateCourte(_le),
        dateCompacte(_le, _maintenant),
        dateLongueHistorique(_le),
        dateMoyenne(_le),
        dateDeLAppareil(_le),
        momentCourt(_le, _maintenant),
        horodatage,
        t.com.annonces.auteurDate(
          auteur: 'المعلمة',
          date: dateLongueHistorique(_le),
          heure: heureMinute(_le),
        ),
      ]) {
        expect(texte, isNot(matches(_francais)), reason: texte);
      }
    });

    test('arabe : chaque mois et chaque jour a son nom arabe', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      for (int mois = 1; mois <= 12; mois++) {
        final String date = dateCourte(DateTime(2026, mois, 10));
        expect(date, isNot(matches(RegExp('[A-Za-zé]'))), reason: date);
      }
      for (int jour = 5; jour <= 11; jour++) {
        final String date = dateDeLAppareil(DateTime(2026, 10, jour));
        expect(date, isNot(matches(RegExp('[A-Za-zé]'))), reason: date);
      }
    });
  });
}
