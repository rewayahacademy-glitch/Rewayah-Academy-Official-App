// CAND-04 : les indicatifs telephoniques et la forme internationale du numero.
// Ce que le test prouve :
// - chaque pays de la liste (sauf Bouvet, sans indicatif) en a un, et chacun
//   est reconnu par le serveur : le test lit la liste dans la migration de
//   CAND-L3 ; un indicatif de plus ici qu'au serveur serait un numero refuse ;
// - le numero se compose comme le serveur le lit : « + », l'indicatif, le
//   numero sans son 0 national (sauf l'Italie, la Cote d'Ivoire, le Gabon et le
//   Benin), de 8 a 15 chiffres ;
// - ce qui ne se lit pas rend `null` : rien n'est devine.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/indicatifs_telephoniques.dart';
import 'package:rewayah_academy/core/i18n/pays_iso.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

Set<String> _indicatifsDuServeur() {
  final String migration = File(
    'supabase/migrations/20261022000600_cand_l3_inscription_import_rapprochement.sql',
  ).readAsStringSync();
  final String debut = migration.split(
    'SELECT i FROM pg_catalog.unnest(ARRAY[',
  )[1];
  final String liste = debut.split(']) AS i;')[0];
  return <String>{
    for (final RegExpMatch m in RegExp(r"'(\d+)'").allMatches(liste))
      m.group(1)!,
  };
}

void main() {
  group('la table des indicatifs', () {
    test('tous les pays en ont un, sauf Bouvet', () {
      final List<String> sans = <String>[
        for (final PaysIso p in paysIso)
          if (indicatifDuPays(p.code) == null) p.code,
      ];
      expect(sans, <String>['BV']);
      // PE-B8 : tous les pays ISO sauf Bouvet, plus le Kosovo (+383).
      expect(
        paysAvecIndicatif.length,
        paysIso.length - 1 + paysHorsIsoAvecIndicatif.length,
      );
      expect(indicatifDuPays('XK'), '383');
      expect(nomPaysTelephone('XK'), 'Kosovo');
    });

    test('chaque indicatif est reconnu par le serveur', () {
      final Set<String> serveur = _indicatifsDuServeur();
      expect(serveur, isNotEmpty);
      final Set<String> manquants = <String>{
        for (final PaysIso p in paysAvecIndicatif)
          if (!serveur.contains(indicatifDuPays(p.code)))
            indicatifDuPays(p.code)!,
      };
      expect(manquants, isEmpty);
    });

    test('quelques pays connus', () {
      expect(indicatifDuPays('FR'), '33');
      expect(indicatifDuPays('fr'), '33');
      expect(indicatifDuPays('MA'), '212');
      expect(indicatifDuPays('SA'), '966');
      expect(indicatifDuPays('CA'), '1');
      expect(indicatifDuPays('US'), '1');
      expect(indicatifDuPays('XX'), isNull);
      expect(indicatifDuPays(null), isNull);
    });

    test('l indicatif s affiche isole, le plus en tete', () {
      expect(indicatifAffiche('33'), '\u2066+33\u2069');
    });
  });

  group('telephoneInternational', () {
    String? t(String indicatif, String saisie) =>
        telephoneInternational(indicatif: indicatif, saisie: saisie);

    test('le 0 national est retire', () {
      expect(t('33', '06 12 34 56 78'), '+33612345678');
      expect(t('33', '0612345678'), '+33612345678');
      expect(t('33', '612345678'), '+33612345678');
      expect(t('212', '0661-23-45-67'), '+212661234567');
    });

    test('les separateurs et les chiffres arabes sont lus', () {
      expect(t('966', '(050) 123.4567'), '+966501234567');
      expect(t('966', '٠٥٠١٢٣٤٥٦٧'), '+966501234567');
      expect(t('98', '۰۹۱۲۳۴۵۶۷۸۹'), '+989123456789');
      expect(t('33', '6 12 34 56 78'), '+33612345678');
    });

    test('le plan nord-americain garde la zone locale', () {
      expect(t('1', '514 555 0123'), '+15145550123');
    });

    test('l Italie, la Cote d Ivoire, le Gabon et le Benin gardent leur 0', () {
      expect(t('39', '06 698 4567'), '+39066984567');
      expect(t('225', '07 12 34 56 78'), '+2250712345678');
      expect(t('241', '06 12 34 56'), '+241061234 56'.replaceAll(' ', ''));
      expect(t('229', '01 97 12 34 56'), '+2290197123456');
    });

    test('ce qui ne se lit pas rend null, rien n est devine', () {
      expect(t('33', ''), isNull);
      expect(t('33', '   '), isNull);
      expect(t('33', '0'), isNull);
      expect(t('33', '+33 6 12 34 56 78'), isNull, reason: 'avec l\'indicatif');
      expect(t('33', '06 12 34 56 7a'), isNull, reason: 'une lettre');
      expect(t('33', '0033 6 12 34 56 78'), isNull, reason: 'un 0 de plus');
      expect(t('33', '12345'), isNull, reason: 'trop court');
      expect(t('33', '1234567890123456'), isNull, reason: 'trop long');
    });

    test('de 8 a 15 chiffres, indicatif compris', () {
      expect(t('33', '12345'), isNull); // 7 chiffres
      expect(t('33', '123456'), '+33123456'); // 8 chiffres
      expect(t('33', '1234567890123'), '+331234567890123'); // 15 chiffres
      expect(t('33', '12345678901234'), isNull); // 16 chiffres
    });
  });

  group('PE-B8 : chercher un pays pour l indicatif', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.fr));
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    List<String> codes(String saisie) => <String>[
      for (final PaysIso p in chercherPaysTelephone(saisie)) p.code,
    ];

    test('sans saisie : tous les pays, Kosovo compris', () {
      expect(codes(''), hasLength(paysAvecIndicatif.length));
      expect(codes(''), contains('XK'));
    });

    test('en arabe sans article : « جزائر » trouve l Algerie', () {
      expect(codes('جزائر'), contains('DZ'));
      expect(codes('مغرب'), contains('MA'));
      expect(codes('سعودية'), contains('SA'));
    });

    test('le nom anglais, quelle que soit la langue de l ecran', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(codes('Morocco'), contains('MA'));
      expect(codes('Saudi'), contains('SA'));
      expect(codes('Ivory'), contains('CI'));
    });

    test('les autres noms courants : Angleterre, USA, بريطانيا, Kinshasa', () {
      expect(codes('Angleterre'), contains('GB'));
      expect(codes('usa'), contains('US'));
      expect(codes('بريطانيا'), contains('GB'));
      expect(codes('Kinshasa'), contains('CD'));
      expect(codes('Kosovo'), <String>['XK']);
    });

    test('un mot au milieu du nom : « congo » trouve les deux Congo', () {
      expect(codes('congo'), containsAll(<String>['CG', 'CD']));
    });

    test('par l indicatif, avec ou sans « + »', () {
      expect(codes('212'), contains('MA'));
      expect(codes('+212'), contains('MA'));
      expect(codes('383'), <String>['XK']);
    });

    test(
      'un bout de mot ne trouve rien : « ma » ne trouve pas l Allemagne',
      () {
        expect(codes('ma'), isNot(contains('DE')));
        expect(codes('arabie saoudite'), contains('SA'));
      },
    );

    test('ce qui commence par la saisie passe d abord', () {
      expect(codes('ma').indexOf('MA'), lessThan(codes('ma').indexOf('SM')));
    });
  });
}
