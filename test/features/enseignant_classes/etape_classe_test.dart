// MES-CLASSES-ETAPE : l'etape de la Classe (publiee seulement) sur la ligne,
// et la lecture de `mes_classes_details` par l'adaptateur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/enseignant_classes/details_classes_supabase.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart'
    show maintenantJourneeProvider;

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/demo/enseignant_demo.dart';
import '../../support/harnais.dart';

List<Override> _surcharges(Map<String, DetailClasse> details) => <Override>[
  maintenantJourneeProvider.overrideWithValue(
    () => DonneesEnseignantDemo.maintenant,
  ),
  groupesEnseignantProvider.overrideWith(
    (Ref _) async => DonneesEnseignantDemo.groupes(),
  ),
  seancesEnseignantProvider.overrideWith(
    (Ref _) async => DonneesEnseignantDemo.seances(EtatDemoEnseignant.nominal),
  ),
  cahiersEnRetardProvider.overrideWith(
    (Ref _) async =>
        DonneesEnseignantDemo.cahiersEnRetard(EtatDemoEnseignant.nominal),
  ),
  detailsClassesProvider.overrideWithValue(details),
];

void main() {
  group('detailsDepuisLignes : la reponse du serveur', () {
    test('une etape publiee et une langue lisible', () {
      final Map<String, DetailClasse> d = detailsDepuisLignes(<Object?>[
        <String, Object?>{
          'groupe_id': 'g1',
          'etape_ordre': 2,
          'etape_nom': 'Lire avec les voyelles',
          'langue': 'Français',
        },
      ]);
      expect(d['g1']!.etapeOrdre, 2);
      expect(d['g1']!.etapeNom, 'Lire avec les voyelles');
      expect(d['g1']!.langue, 'Français');
      expect(d['g1']!.remplacement, isFalse);
    });

    test('etape inconnue (NULL) : rien, la ligne existe quand meme', () {
      final Map<String, DetailClasse> d = detailsDepuisLignes(<Object?>[
        <String, Object?>{
          'groupe_id': 'g1',
          'etape_ordre': null,
          'etape_nom': null,
          'langue': null,
        },
        <String, Object?>{
          'groupe_id': 'g2',
          'etape_ordre': 3,
          'etape_nom': '  ',
          'langue': 'Arabe',
        },
      ]);
      expect(d['g1']!.etapeOrdre, isNull);
      expect(d['g1']!.etapeNom, isNull);
      // Un nom vide n'est pas une etape : ni ordre ni nom.
      expect(d['g2']!.etapeOrdre, isNull);
      expect(d['g2']!.etapeNom, isNull);
    });

    test('une ligne mal formee est ignoree, une reponse non liste echoue', () {
      expect(
        detailsDepuisLignes(<Object?>[
          'x',
          <String, Object?>{'groupe_id': 3},
        ]),
        isEmpty,
      );
      expect(() => detailsDepuisLignes('x'), throwsFormatException);
    });
  });

  group('MES-CLASSES-ETAPE : la ligne de la Classe', () {
    Future<void> monter(
      WidgetTester tester,
      Map<String, DetailClasse> details, {
      TextDirection sens = TextDirection.ltr,
    }) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        hote(
          Directionality(textDirection: sens, child: const MesClassesPage()),
          surcharges: _surcharges(details),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    String tout(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((Text x) => x.data ?? x.textSpan?.toPlainText() ?? '')
        .join('|');

    testWidgets('etape connue : « Étape 2 · … » est affichee', (
      WidgetTester tester,
    ) async {
      final GroupeEnseignant badr = DonneesEnseignantDemo.groupes().firstWhere(
        (GroupeEnseignant g) => g.libelle == 'Al-Badr',
      );
      await monter(tester, <String, DetailClasse>{
        badr.id: const DetailClasse(
          etapeOrdre: 2,
          etapeNom: 'Lire avec les voyelles',
        ),
      });
      expect(
        tout(tester),
        contains(
          t.enseignant.classes.etape(n: 2, nom: 'Lire avec les voyelles'),
        ),
      );
    });

    testWidgets('etape inconnue : aucun « Étape » ni point d interrogation', (
      WidgetTester tester,
    ) async {
      await monter(tester, const <String, DetailClasse>{});
      final String lu = tout(tester);
      expect(lu, isNot(contains('Étape')));
      expect(lu, isNot(contains('?')));
    });

    testWidgets('arabe, de droite a gauche : l etape tient dans l ecran', (
      WidgetTester tester,
    ) async {
      final GroupeEnseignant badr = DonneesEnseignantDemo.groupes().firstWhere(
        (GroupeEnseignant g) => g.libelle == 'Al-Badr',
      );
      await monter(tester, <String, DetailClasse>{
        badr.id: const DetailClasse(etapeOrdre: 2, etapeNom: 'القراءة'),
      }, sens: TextDirection.rtl);
      final Finder f = find.textContaining('القراءة');
      expect(f, findsWidgets);
      for (final Element e in f.evaluate()) {
        final Rect r = tester.getRect(find.byWidget(e.widget).first);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(1280));
      }
    });
  });

  group('Capture R3 MES-CLASSES-ETAPE', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    testWidgets('Mes classes : l etape sous la legende de chaque Classe', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final List<GroupeEnseignant> g = DonneesEnseignantDemo.groupes();
      await tester.pumpWidget(
        hote(
          const MesClassesPage(),
          surcharges: _surcharges(<String, DetailClasse>{
            g[0].id: const DetailClasse(
              etapeOrdre: 2,
              etapeNom: 'Lire avec les voyelles',
            ),
            g[1].id: const DetailClasse(
              etapeOrdre: 1,
              etapeNom: 'Reconnaître les lettres',
            ),
          }),
        ),
      );
      await tester.pumpAndSettle();
      await capturerVue(tester, '1-mes-classes-etape');
    });
  }, skip: sautSansCapture);
}
