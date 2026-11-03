// REMB-14 (decision du directeur du 02/11/2026, DECISION-TARIFS-2026-10-18) :
// le delai de retractation du texte « Annulation et remboursement » vient de
// la politique (`remboursement_delai_jours`, publie par `tarifs_publics()`),
// jamais du texte. « Premiere semaine » et « sauf geste de la direction »
// disparaissent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/delai_retractation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/dossier/politique_controle.dart'
    show SectionPolitique;
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

import '../../capture/outil_capture.dart';

class _PortDelai implements PortDelaiRetractation {
  _PortDelai(this.jours, {this.erreur = false});

  final int? jours;
  final bool erreur;

  @override
  Future<int?> lire() async {
    if (erreur) throw Exception('hors ligne');
    return jours;
  }
}

String _texte(TexteJuridique x, {int? delaiJours}) => sectionsJuridiques(
  x,
  renseignes: const <ChampJuridique, String>{},
  delaiJours: delaiJours,
).expand((SectionPolitique s) => <String>[s.titre, ...s.blocs]).join('\n');

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('La lecture du delai', () {
    test('le delai de la politique courante, sinon null', () {
      expect(
        delaiDepuisTarifs(<String, Object?>{
          'courante': <String, Object?>{'remboursementDelaiJours': 14},
        }),
        14,
      );
      expect(
        delaiDepuisTarifs(<String, Object?>{
          'courante': <String, Object?>{'remboursementDelaiJours': 7},
          'suivante': <String, Object?>{'remboursementDelaiJours': 14},
        }),
        7,
      );
      // Base d'avant la migration, politique absente, valeur hors bornes.
      expect(
        delaiDepuisTarifs(<String, Object?>{
          'courante': <String, Object?>{'version': 'v2.0.0'},
        }),
        isNull,
      );
      expect(delaiDepuisTarifs(<String, Object?>{'courante': null}), isNull);
      expect(
        delaiDepuisTarifs(<String, Object?>{
          'courante': <String, Object?>{'remboursementDelaiJours': 99},
        }),
        isNull,
      );
      expect(delaiDepuisTarifs('x'), isNull);
    });
  });

  group('Le texte', () {
    test('le delai lu s\'affiche, en fr et en ar', () {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(
        _texte(TexteJuridique.annulation, delaiJours: 14),
        contains('14 jours à compter du paiement'),
      );
      expect(
        _texte(TexteJuridique.annulation, delaiJours: 7),
        contains('7 jours à compter du paiement'),
      );
      LocaleSettings.setLocaleSync(AppLocale.ar);
      expect(_texte(TexteJuridique.annulation, delaiJours: 14), contains('14'));
      expect(
        _texte(TexteJuridique.annulation, delaiJours: 14),
        contains('مهلة التراجع'),
      );
    });

    test('non lu : la phrase sans duree, jamais un nombre invente', () {
      for (final AppLocale langue in AppLocale.values) {
        LocaleSettings.setLocaleSync(langue);
        final String texte = _texte(TexteJuridique.annulation);
        expect(
          texte,
          contains(t.juridique.annulation.s1.delaiSansDuree),
          reason: langue.languageCode,
        );
      }
    });

    test('la phrase du delai suit la premiere phrase de la section 1', () {
      final SectionPolitique s1 = sectionsJuridiques(
        TexteJuridique.annulation,
        renseignes: const <ChampJuridique, String>{},
        delaiJours: 14,
      ).first;
      expect(s1.titre, t.juridique.annulation.s1.titre);
      expect(s1.blocs.first, t.juridique.annulation.s1.blocs.first);
      expect(s1.blocs[1], contains('14 jours'));
      expect(s1.blocs.length, t.juridique.annulation.s1.blocs.length + 1);
    });

    test(
      '« premiere semaine » et « sauf geste de la direction » ont disparu',
      () {
        for (final AppLocale langue in AppLocale.values) {
          LocaleSettings.setLocaleSync(langue);
          for (final TexteJuridique x in <TexteJuridique>[
            TexteJuridique.annulation,
            TexteJuridique.conditions,
          ]) {
            final String texte = _texte(x, delaiJours: 14).toLowerCase();
            for (final String interdit in <String>[
              'première semaine',
              'geste de la direction',
              'الأسبوع الأول',
              'بقرار من الإدارة',
            ]) {
              expect(
                texte.contains(interdit),
                isFalse,
                reason: '${langue.languageCode} ${x.slug} : $interdit',
              );
            }
          }
        }
      },
    );

    test(
      'apres le delai, arreter une formule payee d\'avance est un droit',
      () {
        LocaleSettings.setLocaleSync(AppLocale.fr);
        expect(
          t.juridique.annulation.s2.blocs[1],
          allOf(
            contains('reste un droit'),
            contains('prix mensuel normal'),
            contains('le reste est remboursé'),
          ),
        );
      },
    );
  });

  group('La page', () {
    Future<void> ouvrir(WidgetTester tester, PortDelaiRetractation port) async {
      fixerVueCapture(tester, const Size(390, 1600), 1);
      await tester.pumpWidget(
        hoteCapture(
          const TexteJuridiquePage(texte: TexteJuridique.annulation),
          surcharges: <Override>[
            portDelaiRetractationProvider.overrideWithValue(port),
          ],
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
    }

    testWidgets('affiche le delai de la politique', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester, _PortDelai(14));
      expect(
        find.textContaining('14 jours à compter du paiement'),
        findsOneWidget,
      );
    });

    testWidgets('lecture en erreur : la phrase sans duree, aucune erreur', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester, _PortDelai(null, erreur: true));
      expect(
        find.textContaining(t.juridique.annulation.s1.delaiSansDuree),
        findsOneWidget,
      );
    });
  });
}
