// FILTRES-1b (1) : Pedagogie > Qualite plantait des qu'une anomalie ouverte
// existait (« Vertical viewport was given unbounded height » a 320 px texte
// x2, « RenderFlex children have non-zero flex but incoming height
// constraints are unbounded » a 1440 texte x2) : la liste paresseuse, dans
// un `Expanded`, etait posee sous une tete qui defile (PageShell non
// defilant, defilement global) ou une colonne non bornee. Chaque cas monte
// le vrai ecran avec des anomalies ouvertes et verifie qu'il rend sa liste
// sans exception, en LTR et en RTL.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_pedagogie_qualite/qualite_page.dart';

import '../../support/harnais.dart' show FauxServiceReseau;
import '../../support/sens_et_echelle.dart';

AnomalieQualite _anomalie(
  String id,
  TypeAnomalieQualite type,
  StatutControleQualite statut,
) => AnomalieQualite(
  type: type,
  refId: id,
  studentId: 's-$id',
  studentPrenom: 'Mariam',
  studentNom: 'Diallo',
  teacherId: 't1',
  teacherPrenom: 'Amina',
  teacherNom: 'Diallo',
  depuis: DateTime(2026, 9, 20),
  controleStatut: statut,
  controleNote: null,
);

final List<AnomalieQualite> _anomalies = <AnomalieQualite>[
  for (int i = 0; i < 6; i++)
    _anomalie(
      'r$i',
      TypeAnomalieQualite.rapportManquant,
      StatutControleQualite.ouvert,
    ),
  _anomalie(
    'b1',
    TypeAnomalieQualite.blocageSansSuivi,
    StatutControleQualite.ouvert,
  ),
  _anomalie(
    'e1',
    TypeAnomalieQualite.evaluationEnRetard,
    StatutControleQualite.traite,
  ),
];

Widget _hote(TextDirection sens, double echelle) => ProviderScope(
  overrides: [
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    anomaliesQualiteProvider.overrideWith((Ref _) async => _anomalies),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: sensEtEchelle(direction: sens, echelle: echelle),
      home: const QualitePage(),
    ),
  ),
);

List<ScrollableState> _defileursVerticaux(WidgetTester tester) => tester
    .stateList<ScrollableState>(find.byType(Scrollable))
    .where(
      (ScrollableState s) =>
          axisDirectionToAxis(s.axisDirection) == Axis.vertical,
    )
    .toList();

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final Size vue in const <Size>[Size(320, 640), Size(1440, 900)]) {
    for (final double echelle in const <double>[1, 2]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('Qualite avec anomalies ouvertes : ${vue.width.toInt()} '
            'texte x${echelle.toInt()} ${sens.name}', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vue;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(_hote(sens, echelle));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          // Le filtre par defaut (« Ouvertes ») montre la liste, pas
          // l'etat vide : les groupes d'anomalies ouvertes sont la.
          expect(
            find.text(t.admin.qualite.groupeRapportManquant),
            findsOneWidget,
          );
          expect(find.text(t.admin.qualite.aucune), findsNothing);

          // La liste se parcourt jusqu'au dernier groupe ouvert : chaque
          // defileur vertical (la page, puis la liste) avance pas a pas.
          final Finder titre = find.text(
            t.admin.qualite.groupeBlocageSansSuivi,
          );
          for (int pas = 0; pas < 200 && titre.evaluate().isEmpty; pas++) {
            for (final ScrollableState s in _defileursVerticaux(tester)) {
              final ScrollPosition p = s.position;
              if (p.pixels < p.maxScrollExtent) {
                p.jumpTo(math.min(p.pixels + 100, p.maxScrollExtent));
                break;
              }
            }
            await tester.pump();
          }
          expect(titre, findsOneWidget);
          expect(tester.takeException(), isNull);

          // « Toutes » montre aussi l'anomalie traitee, sans planter.
          await tester.tap(find.textContaining(t.admin.qualite.filtreToutes));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
