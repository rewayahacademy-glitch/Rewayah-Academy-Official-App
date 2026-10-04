// FORM-L4-11-12 : quatre corrections de formulaires.
//
//   * L4  : la date d'une evaluation se choisit dans un calendrier (fr, de
//           aujourd'hui a un an), elle ne se tape plus en JJ/MM/AAAA ;
//   * L11 : le depot de piece n'a plus de carte « Autre » a champ libre jamais
//           lu ; le type `autre` existe en base (`other`) et se choisit
//           explicitement ;
//   * L12 : le libelle du jeton d'acces agent est prerempli, modifiable ;
//   * L10 : le courriel saisi a la connexion arrive prerempli a la
//           recuperation.
//
// Les cas partent des VRAIS ecrans et de leurs vraies feuilles ; seuls les
// services sont des doubles. Horloge fixe : le 4 octobre 2026.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../support/harnais.dart';
import 'support_form_l2.dart';

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Un hote en francais, comme l'application (`app.dart`) : le calendrier lit
/// la langue de l'application.
Widget _hoteFr(Widget ecran, List<Override> surcharges) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: const Locale('fr'),
      supportedLocales: const <Locale>[Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ecran,
    ),
  ),
);

Future<FauxEvaluationsFormL2> _ouvrirPlanification(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxEvaluationsFormL2 evaluations = FauxEvaluationsFormL2();
  await tester.pumpWidget(
    _hoteFr(
      const EvaluationsPage(),
      surchargesFormL2(
        comptes: FauxComptesFormL2(comptesFormL2),
        evaluations: evaluations,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _presser(tester, find.text(t.admin.evaluations.planifier).first);
  return evaluations;
}

void main() {
  group('L11 : le depot de piece n\'a plus de champ libre jamais lu', () {
    Future<(FauxServiceDossier, _SelecteurQuiRetient)> monter(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxServiceDossier dossier = FauxServiceDossier();
      final _SelecteurQuiRetient selecteur = _SelecteurQuiRetient();
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attentePiece,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attentePiece,
              builder: (BuildContext _, GoRouterState _) =>
                  const DepotPiecePage(),
            ),
            GoRoute(
              path: Routes.attente,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('portail')),
            ),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
            selecteurFichierProvider.overrideWithValue(selecteur),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return (dossier, selecteur);
    }

    testWidgets('« Autre » est un type explicite : aucune carte a champ libre, '
        'aucun champ texte', (WidgetTester tester) async {
      await monter(tester);

      expect(find.text(t.kyc.autrePiece), findsOneWidget);
      // La carte generique « Autre » (champ libre) a disparu.
      expect(find.text(t.choix.autre), findsNothing);

      await _presser(tester, find.text(t.kyc.autrePiece));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('choisir « Autre pièce » envoie bien le type `other`', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _SelecteurQuiRetient selecteur) =
          await monter(tester);

      await _presser(tester, find.text(t.kyc.autrePiece));
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.envoyer));
      await tester.pumpAndSettle();

      expect(selecteur.demandes, <TypePiece>[TypePiece.autre]);
      expect(dossier.depots.single.type, TypePiece.autre);
      expect(dossier.depots.single.type.valeurSql, 'other');
    });
  });

  group('L4 : la date d\'une evaluation se choisit dans un calendrier', () {
    testWidgets('plus aucun champ texte pour la date, un champ a toucher', (
      WidgetTester tester,
    ) async {
      await _ouvrirPlanification(tester);

      expect(
        find.widgetWithText(TextField, t.admin.evaluations.champDatePrevue),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('champ-date')), findsOneWidget);
      expect(find.text(t.commun.champDate.choisir), findsOneWidget);
    });

    testWidgets('le calendrier est en francais, borne d\'aujourd\'hui a +1 an, '
        'et le jour choisi est planifie', (WidgetTester tester) async {
      final FauxEvaluationsFormL2 evaluations = await _ouvrirPlanification(
        tester,
      );
      await _presser(tester, _carte('e-mariam'));
      await _presser(tester, find.text(niveauFormL2.nomHumain));

      await _presser(tester, find.byKey(const ValueKey<String>('champ-date')));

      final CalendarDatePicker calendrier = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendrier.firstDate, DateTime(2026, 10, 4));
      expect(calendrier.lastDate, DateTime(2027, 10, 4));
      // Langue de l'application : le mois s'ecrit en francais.
      expect(find.textContaining('octobre 2026'), findsWidgets);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('15/10/2026'), findsOneWidget);
      await _presser(tester, find.text(t.admin.evaluations.planifierEnvoyer));
      expect(evaluations.planifiees.single.$3, DateTime(2026, 10, 15));
    });

    testWidgets('sans date, l\'ecran dit ce qui manque et n\'envoie rien', (
      WidgetTester tester,
    ) async {
      final FauxEvaluationsFormL2 evaluations = await _ouvrirPlanification(
        tester,
      );
      await _presser(tester, _carte('e-mariam'));
      await _presser(tester, find.text(niveauFormL2.nomHumain));
      await _presser(tester, find.text(t.admin.evaluations.planifierEnvoyer));

      expect(find.text(t.admin.evaluations.manqueDate), findsOneWidget);
      expect(evaluations.planifiees, isEmpty);
    });
  });
}

/// Un selecteur qui retient le type de piece qu'on lui demande.
class _SelecteurQuiRetient implements SelecteurFichier {
  final List<TypePiece> demandes = <TypePiece>[];

  @override
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type) async {
    demandes.add(type);
    return PieceAEnvoyer(
      octets: Uint8List(1024),
      nomFichier: 'piece.webp',
      type: type,
    );
  }
}

Finder _carte(String id) => find.byKey(ValueKey<String>('personne-$id'));
