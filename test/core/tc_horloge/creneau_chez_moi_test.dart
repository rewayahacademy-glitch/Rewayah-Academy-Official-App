// HORLOGE-ET-LIEU, correction B1 (13/11/2026) : l'heure d'un creneau
// hebdomadaire de classe, pour une personne. Son heure locale d'abord, calculee
// depuis l'instant reel du prochain cours, puis « Heure de La Mecque » en
// second ; jamais « Riyad », jamais l'heure enregistree brute.
//
// Les deux etats de la base : classe a La Mecque (apres la migration) et classe
// encore a Paris (avant la migration, ou classe creee par un ancien client).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/creneau_chez_moi.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';

const Map<String, Object?> _parisJson = <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 3600,
  'prochain_changement': '2027-03-28T01:00:00Z',
  'decalage_apres': 7200,
  'changement_suivant': '2027-10-31T01:00:00Z',
};
const Map<String, Object?> _parisEteJson = <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 7200,
  'prochain_changement': '2027-10-31T01:00:00Z',
  'decalage_apres': 3600,
  'changement_suivant': '2028-03-26T01:00:00Z',
};
const Map<String, Object?> _delhi = <String, Object?>{
  'fuseau': 'Asia/Kolkata',
  'decalage_secondes': 19800,
  'prochain_changement': null,
};
const Map<String, Object?> _riyad = <String, Object?>{
  'fuseau': 'Asia/Riyadh',
  'decalage_secondes': 10800,
  'prochain_changement': null,
};
const Map<String, Object?> _conakry = <String, Object?>{
  'fuseau': 'Africa/Conakry',
  'decalage_secondes': 0,
  'prochain_changement': null,
};

FuseauVu _f(Map<String, Object?> json) => FuseauVu.lire(json)!;

/// La personne vit dans [moi] ; l'academie est a La Mecque.
void _vivre(
  Map<String, Object?> moi, {
  String maintenant = '2026-11-12T22:00:00Z',
}) {
  poserMonHorlogePourTest(
    MonHorloge.lire(<String, Object?>{
      'maintenant': maintenant,
      'moi': moi,
      'academie': _riyad,
    }),
  );
}

// Jeudi 12/11/2026, 22:00 UTC : le prochain mercredi est le 18/11.
final DateTime _novembre = DateTime.utc(2026, 11, 12, 22);
// Mercredi 31/03/2027 : Paris est a l'heure d'ete.
final DateTime _printemps = DateTime.utc(2027, 3, 31, 12);

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() {
    poserMonHorlogePourTest(null);
    poserHorlogeCreneauxPourTest(null);
    viderFuseauxLusPourTest();
  });

  group('classe a La Mecque (apres la migration)', () {
    test(
      'mercredi 21:00 a La Mecque : 19:00 a Paris l hiver, puis La Mecque',
      () {
        _vivre(_parisJson);
        final CreneauChezMoi? c = creneauChezMoi(
          jour: 3,
          heure: 21,
          fuseauCreneau: _f(_riyad),
          maintenant: _novembre,
        );
        expect(c?.jour, 3);
        expect(c?.heure, '19:00');
        expect(c?.mecque, '21:00');
        expect(
          libelleCreneauChezMoi(c!, capitale: true),
          'Mercredi 19:00 · Heure de La Mecque : 21:00',
        );
      },
    );

    test('l ete a Paris : 20:00 chez soi, toujours 21:00 a La Mecque', () {
      _vivre(_parisEteJson, maintenant: '2027-03-31T12:00:00Z');
      final CreneauChezMoi? c = creneauChezMoi(
        jour: 3,
        heure: 21,
        fuseauCreneau: _f(_riyad),
        maintenant: _printemps,
      );
      expect(c?.heure, '20:00');
      expect(c?.mecque, '21:00');
    });

    test('a Delhi : 23:30 chez soi, 21:00 a La Mecque', () {
      _vivre(_delhi);
      final CreneauChezMoi? c = creneauChezMoi(
        jour: 3,
        heure: 21,
        fuseauCreneau: _f(_riyad),
        maintenant: _novembre,
      );
      expect(c?.heure, '23:30');
      expect(c?.mecque, '21:00');
    });

    test('a La Mecque meme : aucune seconde heure', () {
      _vivre(_riyad);
      final CreneauChezMoi? c = creneauChezMoi(
        jour: 3,
        heure: 21,
        fuseauCreneau: _f(_riyad),
        maintenant: _novembre,
      );
      expect(c?.heure, '21:00');
      expect(c?.mecque, isNull);
      expect(libelleCreneauChezMoi(c!, capitale: true), 'Mercredi 21:00');
    });

    test(
      'le jour change : lundi 01:00 a La Mecque est dimanche 23:00 a Paris',
      () {
        _vivre(_parisJson);
        final CreneauChezMoi? c = creneauChezMoi(
          jour: 1,
          heure: 1,
          fuseauCreneau: _f(_riyad),
          maintenant: _novembre,
        );
        expect(c?.jour, 7);
        expect(c?.heure, '23:00');
        expect(c?.mecque, '01:00');
      },
    );
  });

  group('classe encore a Paris (avant la migration)', () {
    test('mercredi 19:00 a Paris, vu de Paris : 19:00, La Mecque 21:00', () {
      _vivre(_parisJson);
      final CreneauChezMoi? c = creneauChezMoi(
        jour: 3,
        heure: 19,
        fuseauCreneau: _f(_parisJson),
        maintenant: _novembre,
      );
      expect(c?.jour, 3);
      expect(c?.heure, '19:00');
      expect(c?.mecque, '21:00');
    });

    test('vu de Conakry : 18:00, La Mecque 21:00', () {
      _vivre(_conakry);
      final CreneauChezMoi? c = creneauChezMoi(
        jour: 3,
        heure: 19,
        fuseauCreneau: _f(_parisJson),
        maintenant: _novembre,
      );
      expect(c?.heure, '18:00');
      expect(c?.mecque, '21:00');
    });
  });

  test('sans lecture du fuseau : l heure du creneau et la ville de son fuseau, '
      'jamais « Riyad » ni une heure devinee', () {
    _vivre(_parisJson);
    const CleCreneau cle = (jour: 3, heure: 21, fuseau: 'Asia/Riyadh');
    final String libelle = libelleDuCreneau(null, cle);
    expect(libelle, contains('21:00'));
    expect(libelle, isNot(contains('Riyad')));
    // Le fuseau de l'academie, quand il n'est pas lu, est dit avec une ville
    // connue du produit ; l'heure n'est pas convertie.
    expect(
      libelleDuCreneau(null, (jour: 3, heure: 19, fuseau: 'Europe/Paris')),
      contains('Paris'),
    );
  });

  test('un decalage incertain (apres le changement suivant) : rien, pas une '
      'heure fausse', () {
    _vivre(_parisJson);
    final CreneauChezMoi? c = creneauChezMoi(
      jour: 3,
      heure: 21,
      fuseauCreneau: _f(_parisJson),
      maintenant: DateTime.utc(2028, 6, 1),
    );
    expect(c, isNull);
  });

  test(
    'creneauDansFuseau : le creneau de La Mecque lu dans le fuseau saisi',
    () {
      final ({int jour, int heure})? lu = creneauDansFuseau(
        jour: 3,
        heure: 21,
        origine: _f(_riyad),
        vers: _f(_parisJson),
        maintenant: _novembre,
      );
      expect(lu, (jour: 3, heure: 19));
      // Heure sans equivalent entier (Delhi) : rien.
      expect(
        creneauDansFuseau(
          jour: 3,
          heure: 21,
          origine: _f(_riyad),
          vers: _f(_delhi),
          maintenant: _novembre,
        ),
        isNull,
      );
    },
  );

  test('partiesDuCreneau : le jour et l heure a mettre dans une phrase', () {
    _vivre(_parisJson);
    const CleCreneau cle = (jour: 3, heure: 21, fuseau: 'Asia/Riyadh');
    final CreneauChezMoi? c = creneauChezMoi(
      jour: 3,
      heure: 21,
      fuseauCreneau: _f(_riyad),
      maintenant: _novembre,
    );
    final ({String jour, String heure}) p = partiesDuCreneau(c, cle);
    expect(p.jour, 'mercredi');
    expect(p.heure, '19:00 · Heure de La Mecque : 21:00');
  });

  test(
    'les trois cas : sans ville choisie, la phrase suit l heure de l appareil',
    () {
      poserMonHorlogePourTest(
        MonHorloge.lire(<String, Object?>{
          'maintenant': '2026-11-12T22:00:00Z',
          'moi': _parisJson,
          'academie': _riyad,
          'lieu_choisi': false,
        }),
      );
      final CreneauChezMoi? c = creneauChezMoi(
        jour: 3,
        heure: 21,
        fuseauCreneau: _f(_riyad),
        maintenant: _novembre,
      );
      final DateTime instant = DateTime.utc(2026, 11, 18, 18);
      final Duration appareil = instant.toLocal().timeZoneOffset;
      // 21:00 a La Mecque = 18:00 UTC ; l'appareil le lit a son decalage.
      final DateTime attendu = instant.toLocal();
      expect(
        c?.heure,
        '${attendu.hour.toString().padLeft(2, '0')}:'
        '${attendu.minute.toString().padLeft(2, '0')}',
      );
      expect(
        c?.mecque,
        appareil == const Duration(hours: 3) ? isNull : '21:00',
      );
    },
  );
}
