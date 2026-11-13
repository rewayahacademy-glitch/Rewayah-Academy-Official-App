// HORLOGE-ET-LIEU, partie B (H5) : le choix de la ville, ses cinq etats, le
// credit GeoNames dans les deux langues, 320 et 1440 points, texte x1 et x2.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/choix_ville.dart';
import 'package:rewayah_academy/core/lieu/lieu.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';

import '../../support/harnais.dart';

const Ville _conakry = Ville(
  id: 2422465,
  nom: 'Conakry',
  paysCode: 'GN',
  region: 'Conakry',
  fuseau: 'Africa/Conakry',
  milliers: 1660,
);
const Ville _paris = Ville(
  id: 2988507,
  nom: 'Paris',
  paysCode: 'FR',
  region: 'Île-de-France',
  fuseau: 'Europe/Paris',
  milliers: 2138,
);
const Ville _riyad = Ville(
  id: 108410,
  nom: 'Riyadh',
  nomAr: 'الرياض',
  paysCode: 'SA',
  region: 'Riyad',
  fuseau: 'Asia/Riyadh',
  milliers: 5188,
);

class _Port extends LieuAbsent {
  _Port({this.propositions = const <Ville>[], this.trouvees = const <Ville>[]});

  final List<Ville> propositions;
  final List<Ville> trouvees;
  final List<String> recherches = <String>[];
  Completer<List<Ville>>? attente;
  bool echec = false;

  @override
  Future<List<Ville>> proposees(int decalageMinutes) {
    if (echec) return Future<List<Ville>>.error(StateError('hors service'));
    return attente?.future ?? Future<List<Ville>>.value(propositions);
  }

  @override
  Future<List<Ville>> rechercher(String texte) {
    recherches.add(texte);
    if (echec) return Future<List<Ville>>.error(StateError('hors service'));
    return Future<List<Ville>>.value(trouvees);
  }
}

Widget _monter(
  _Port port, {
  required double echelle,
  bool horsLigne = false,
  ValueChanged<Ville>? onChoisie,
}) => hoteRoutant(
  depart: '/',
  echelle: echelle,
  surcharges: <Override>[
    portLieuProvider.overrideWithValue(port),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  ],
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext _, GoRouterState _) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ChoixVille(onChoisie: onChoisie ?? (Ville _) {}),
        ),
      ),
    ),
  ],
);

Future<void> _regler(WidgetTester tester, double largeur) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largeur, 1600);
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final double largeur in <double>[320, 1440]) {
    for (final double echelle in <double>[1, 2]) {
      final String cas = '$largeur px, texte x$echelle';

      testWidgets('$cas : contenu, credit GeoNames, choix d une ville', (
        tester,
      ) async {
        await _regler(tester, largeur);
        Ville? choisie;
        await tester.pumpWidget(
          _monter(
            _Port(propositions: <Ville>[_conakry, _paris]),
            echelle: echelle,
            onChoisie: (Ville v) => choisie = v,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.lieu.propositions), findsOneWidget);
        expect(find.text('Conakry'), findsOneWidget);
        expect(find.text('Paris'), findsOneWidget);
        expect(find.byKey(ChoixVille.cleCredit), findsOneWidget);
        expect(find.text(t.lieu.credit), findsOneWidget);
        await tester.tap(find.text('Paris'));
        await tester.pumpAndSettle();
        expect(choisie?.id, _paris.id);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$cas : lecture en cours, un squelette', (tester) async {
        await _regler(tester, largeur);
        final _Port port = _Port()..attente = Completer<List<Ville>>();
        await tester.pumpWidget(_monter(port, echelle: echelle));
        await tester.pump();
        expect(find.text(t.lieu.propositions), findsNothing);
        expect(find.text(t.lieu.chargeEchec), findsNothing);
        expect(tester.takeException(), isNull);
        port.attente!.complete(<Ville>[_conakry]);
        await tester.pumpAndSettle();
        expect(find.text('Conakry'), findsOneWidget);
      });

      testWidgets('$cas : aucune ville trouvee, ce qu il faut essayer', (
        tester,
      ) async {
        await _regler(tester, largeur);
        final _Port port = _Port(propositions: <Ville>[_conakry]);
        await tester.pumpWidget(_monter(port, echelle: echelle));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(ChoixVille.cleChamp), 'zzzz');
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(port.recherches, <String>['zzzz']);
        expect(find.text(t.lieu.aucune(texte: 'zzzz')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$cas : echec du serveur, ce qui manque et quoi faire', (
        tester,
      ) async {
        await _regler(tester, largeur);
        final _Port port = _Port(propositions: <Ville>[_conakry])..echec = true;
        await tester.pumpWidget(_monter(port, echelle: echelle));
        await tester.pumpAndSettle();
        expect(find.text(t.lieu.chargeEchec), findsOneWidget);
        expect(find.text(t.lieu.chargeEchecPhrase), findsOneWidget);
        expect(find.text(t.commun.reessayer), findsOneWidget);
        port.echec = false;
        await tester.tap(find.text(t.commun.reessayer));
        await tester.pumpAndSettle();
        expect(find.text('Conakry'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$cas : hors ligne, le bloc dit ce qui manque', (
        tester,
      ) async {
        await _regler(tester, largeur);
        final _Port port = _Port()..echec = true;
        await tester.pumpWidget(
          _monter(port, echelle: echelle, horsLigne: true),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.lieu.chargeEchec), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    testWidgets('en arabe : le nom arabe de la ville et le credit en arabe', (
      tester,
    ) async {
      await _regler(tester, 390);
      await tester.pumpWidget(
        _monter(_Port(propositions: <Ville>[_riyad]), echelle: 1),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('الرياض'), findsOneWidget);
      expect(find.text(t.lieu.credit), findsOneWidget);
      expect(t.lieu.credit, contains('GeoNames'));
      expect(tester.takeException(), isNull);
    });
  });

  test('Ville.lire : une ligne incomplete n est pas une ville', () {
    expect(Ville.lire(null), isNull);
    expect(Ville.lire(<String, Object?>{'id': 1, 'nom': 'X'}), isNull);
    final Ville? v = Ville.lire(<String, Object?>{
      'id': 1,
      'nom': 'Conakry',
      'pays_code': 'GN',
      'fuseau_iana': 'Africa/Conakry',
      'milliers': 1660,
      'nom_ar': '',
      'region': 'Conakry',
    });
    expect(v?.nomAr, isNull);
    expect(v?.region, 'Conakry');
    expect(EtatLieu.lire(<String, Object?>{'requis': true}), isNull);
    expect(
      EtatLieu.lire(<String, Object?>{
        'requis': true,
        'reports_restants': 2,
        'reports_max': 3,
      })?.peutReporter,
      isTrue,
    );
  });
}
