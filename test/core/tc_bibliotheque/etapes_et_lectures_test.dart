// BIBLIOTHEQUE-UNE, D2 et D3 : les etapes du programme publie lues au serveur
// (jamais un code tape) et les lectures du Coran, avec les memes intitules que
// les candidatures. Aucun reseau.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/etapes_programme.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/etapes_programme_supabase.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/lecture_coran.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('les etapes du programme publie', () {
    test('une liste de {code, nom} se lit, dans l\'ordre rendu', () {
      final List<EtapeProgramme> e = EtapesProgrammeSupabase.lireEtapes(
        <Object?>[
          <String, Object?>{
            'code': 'E-01',
            'nom': 'Lettres et sons',
            'cycle': 'Debut',
            'ordre': 1,
          },
          <String, Object?>{'code': 'E-02', 'nom': 'Premiers mots'},
        ],
      );
      expect(e.map((EtapeProgramme x) => x.code), <String>['E-01', 'E-02']);
      expect(e.first.cycle, 'Debut');
      expect(e.last.ordre, 0);
    });

    test('une etape sans code ou sans nom est ecartee, jamais devinee', () {
      final List<EtapeProgramme> e = EtapesProgrammeSupabase.lireEtapes(
        <Object?>[
          <String, Object?>{'code': '', 'nom': 'Sans code'},
          <String, Object?>{'code': 'E-03', 'nom': ''},
          'pas une etape',
          null,
          <String, Object?>{'code': 'E-04', 'nom': 'Bonne'},
        ],
      );
      expect(e.map((EtapeProgramme x) => x.code), <String>['E-04']);
    });

    test('programme non publie : le serveur rend une liste vide, ou rien', () {
      expect(EtapesProgrammeSupabase.lireEtapes(<Object?>[]), isEmpty);
      expect(EtapesProgrammeSupabase.lireEtapes(null), isEmpty);
      expect(EtapesProgrammeSupabase.lireEtapes('x'), isEmpty);
    });

    test('sans adaptateur, le port est vide (tests, demonstration)', () async {
      expect(await const EtapesAucune().publiees(), isEmpty);
    });
  });

  group('les lectures du Coran', () {
    test('quatre lectures, celles des candidatures', () {
      expect(lecturesCoran, <String>['hafs', 'warsh', 'qalun', 'shuba']);
    });

    testWidgets(
      'les noms sont ceux des candidatures, en francais et en arabe',
      (tester) async {
        final o = t.recrutement.parcours.q.riwayat.options;
        expect(libelleLectureCoran('hafs'), o.hafs.libelle);
        expect(libelleLectureCoran('warsh'), 'Warsh');
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        final oa = t.recrutement.parcours.q.riwayat.options;
        expect(libelleLectureCoran('qalun'), oa.qalun.libelle);
        expect(libelleLectureCoran('qalun'), isNot('Qalun'));
      },
    );

    test('un code inconnu est rendu tel quel, jamais devine', () {
      expect(libelleLectureCoran('inconnue'), 'inconnue');
    });
  });
}
