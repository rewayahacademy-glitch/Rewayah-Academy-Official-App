// HORLOGE-ET-LIEU, partie B (Q5) : la ville du candidat remplace l'etape du
// fuseau. Le serveur enregistre la ville ; le questionnaire recoit le fuseau
// de la ville. Sans les fonctions du lieu, l'ancienne etape reste.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/choix_ville.dart';
import 'package:rewayah_academy/core/lieu/lieu.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/candidature/fuseau_etape.dart';
import 'package:rewayah_academy/features/candidature/ville_etape.dart';

import '../../support/harnais.dart';

const Ville _conakry = Ville(
  id: 2422465,
  nom: 'Conakry',
  paysCode: 'GN',
  region: 'Conakry',
  fuseau: 'Africa/Conakry',
);
const Ville _kolkata = Ville(
  id: 1275004,
  nom: 'Kolkata',
  paysCode: 'IN',
  region: 'Bengale-Occidental',
  fuseau: 'Asia/Kolkata',
);

class _Port implements PortLieu {
  _Port({this.indisponible = false});

  final bool indisponible;
  final List<int> enregistrees = <int>[];

  @override
  Future<List<Ville>> proposees(int decalageMinutes) async {
    if (indisponible) throw const LieuIndisponible();
    return <Ville>[_conakry, _kolkata];
  }

  @override
  Future<ResultatVille> enregistrer(int villeId) async {
    enregistrees.add(villeId);
    return const ResultatVille(disponibilitesARelire: false);
  }

  @override
  Future<List<Ville>> rechercher(String texte) async => const <Ville>[];

  @override
  Future<EtatLieu> aFournir() async =>
      const EtatLieu(requis: false, reportsRestants: 0, reportsMax: 0);

  @override
  Future<EtatLieu> reporter() => aFournir();

  @override
  Future<LieuChoisi?> monLieu() async => null;
}

Future<void> _monter(
  WidgetTester tester,
  PortLieu port,
  List<String> options,
  ValueChanged<String> onChange,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/',
      surcharges: <Override>[
        portLieuProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState _) => Scaffold(
            body: SingleChildScrollView(
              child: VilleEtape(
                options: options,
                choisi: null,
                onChange: onChange,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('la ville choisie est enregistree et son fuseau repond a la '
      'question', (tester) async {
    final _Port port = _Port();
    String? repondu;
    await _monter(tester, port, <String>[
      'Africa/Conakry',
      'Europe/Paris',
    ], (String f) => repondu = f);
    expect(find.byType(ChoixVille), findsOneWidget);
    expect(find.byType(FuseauEtape), findsNothing);
    await tester.tap(find.text('Conakry'));
    await tester.pumpAndSettle();
    expect(port.enregistrees, <int>[2422465]);
    expect(repondu, 'Africa/Conakry');
  });

  testWidgets('une ville dont le fuseau n est pas accepte ne part pas : on '
      'le dit, rien n est enregistre', (tester) async {
    final _Port port = _Port();
    String? repondu;
    await _monter(tester, port, <String>[
      'Africa/Conakry',
    ], (String f) => repondu = f);
    await tester.tap(find.text('Kolkata'));
    await tester.pumpAndSettle();
    expect(port.enregistrees, isEmpty);
    expect(repondu, isNull);
    expect(find.text(t.lieu.echec), findsOneWidget);
  });

  testWidgets('fonctions du lieu absentes du serveur : l ancienne etape du '
      'fuseau', (tester) async {
    await _monter(tester, _Port(indisponible: true), <String>[
      'Africa/Conakry',
      'Europe/Paris',
    ], (String _) {});
    expect(find.byType(FuseauEtape), findsOneWidget);
  });

  testWidgets('sans serveur : l ancienne etape du fuseau', (tester) async {
    await _monter(tester, const LieuAbsent(), <String>[
      'Africa/Conakry',
      'Europe/Paris',
    ], (String _) {});
    expect(find.byType(FuseauEtape), findsOneWidget);
  });
}
