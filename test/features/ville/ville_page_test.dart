// HORLOGE-ET-LIEU, partie B (H5) : la porte du routeur vers `/ville` et la
// page elle-meme. « Plus tard » ne se montre que s'il reste un report ; le
// bouton d'enregistrement n'existe qu'une fois une ville choisie ; le
// quatrieme report est refuse par le serveur, la page le dit sans bouton grise.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/ville/ville_page.dart';

import '../../support/harnais.dart';

const SessionState _tuteur = SessionState(
  resolue: true,
  role: AppRole.guardian,
  profileId: 'u1',
  householdId: 'h1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);
const SessionState _enseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 'u2',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);
const SessionState _eleve = SessionState(
  resolue: true,
  role: AppRole.student,
  profileId: 'u3',
  householdId: 'h1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

const Ville _conakry = Ville(
  id: 2422465,
  nom: 'Conakry',
  paysCode: 'GN',
  region: 'Conakry',
  fuseau: 'Africa/Conakry',
);

class _Port extends LieuAbsent {
  _Port({this.restants = 3, this.relire = false});

  int restants;
  final bool relire;
  final List<int> enregistrees = <int>[];
  int reports = 0;
  bool requis = true;

  @override
  Future<List<Ville>> proposees(int decalageMinutes) async => <Ville>[_conakry];

  @override
  Future<ResultatVille> enregistrer(int villeId) async {
    enregistrees.add(villeId);
    requis = false;
    return ResultatVille(disponibilitesARelire: relire);
  }

  @override
  Future<EtatLieu> aFournir() async =>
      EtatLieu(requis: requis, reportsRestants: restants, reportsMax: 3);

  @override
  Future<EtatLieu> reporter() async {
    reports++;
    restants--;
    requis = restants > 0 || requis;
    return aFournir();
  }
}

String _chemin(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('porte du routeur', () {
    String? decider(
      SessionState s,
      String chemin, {
      bool villeAFournir = false,
    }) => deciderRedirection(
      session: s,
      cheminDemande: chemin,
      maintenant: DateTime(2026, 11, 13),
      villeAFournir: villeAFournir,
    );

    test('une ville a fournir mene le tuteur et l enseignant a /ville', () {
      expect(
        decider(_tuteur, Routes.tuteurAccueil, villeAFournir: true),
        Routes.ville,
      );
      expect(
        decider(_enseignant, Routes.enseignantJournee, villeAFournir: true),
        Routes.ville,
      );
      expect(decider(_tuteur, Routes.ville, villeAFournir: true), isNull);
    });

    test('la salle ne se quitte jamais pour la ville', () {
      expect(
        decider(_tuteur, Routes.salle, villeAFournir: true),
        isNot(Routes.ville),
      );
    });

    test('rien a fournir : aucune redirection vers /ville', () {
      expect(decider(_tuteur, Routes.tuteurAccueil), isNull);
      expect(decider(_tuteur, Routes.ville), isNull);
      expect(decider(_enseignant, Routes.ville), isNull);
    });

    test('un autre role ne voit pas la page', () {
      expect(decider(_eleve, Routes.ville), Routes.racinePour(AppRole.student));
    });
  });

  group('page', () {
    Future<GoRouter> monter(
      WidgetTester tester,
      _Port port, {
      AppRole role = AppRole.guardian,
      double largeur = 390,
      double echelle = 1,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(largeur, 1600);
      addTearDown(tester.view.reset);
      Widget ecran(String texte) => Scaffold(body: Text(texte));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.ville,
          echelle: echelle,
          surcharges: <Override>[
            portLieuProvider.overrideWithValue(port),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
            sourceSessionProvider.overrideWithValue(
              FausseSourceSession(
                role == AppRole.teacher ? _enseignant : _tuteur,
              ),
            ),
          ],
          routes: <RouteBase>[
            GoRoute(
              path: Routes.ville,
              builder: (BuildContext _, GoRouterState _) => const VillePage(),
            ),
            GoRoute(
              path: Routes.enseignantCreneaux,
              builder: (BuildContext _, GoRouterState _) => ecran('creneaux'),
            ),
            GoRoute(
              path: Routes.tuteurAccueil,
              builder: (BuildContext _, GoRouterState _) => ecran('accueil'),
            ),
            GoRoute(
              path: Routes.enseignantJournee,
              builder: (BuildContext _, GoRouterState _) => ecran('journee'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return GoRouter.of(tester.element(find.byType(VillePage)));
    }

    testWidgets('report possible : « Plus tard » et le choix', (tester) async {
      final _Port port = _Port();
      final GoRouter r = await monter(tester, port);
      expect(find.text(t.lieu.plusTard), findsOneWidget);
      // Pas de ville choisie : pas de bouton d'enregistrement, pas grise.
      expect(find.text(t.lieu.enregistrer), findsNothing);
      await tester.tap(find.text('Conakry'));
      await tester.pumpAndSettle();
      expect(find.text(t.lieu.enregistrer), findsOneWidget);
      await tester.tap(find.text(t.lieu.enregistrer));
      await tester.pumpAndSettle();
      expect(port.enregistrees, <int>[2422465]);
      expect(_chemin(r), Routes.tuteurAccueil);
    });

    testWidgets('« Plus tard » reporte et ramene a l accueil', (tester) async {
      final _Port port = _Port();
      final GoRouter r = await monter(tester, port);
      await tester.tap(find.text(t.lieu.plusTard));
      await tester.pumpAndSettle();
      expect(port.reports, 1);
      expect(_chemin(r), Routes.tuteurAccueil);
    });

    testWidgets('plus aucun report : la page le dit, sans « Plus tard »', (
      tester,
    ) async {
      await monter(tester, _Port(restants: 0));
      expect(find.text(t.lieu.plusTard), findsNothing);
      expect(find.text(t.lieu.obligatoire), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'enseignant dont le fuseau change : relire ses disponibilites',
      (tester) async {
        final _Port port = _Port(relire: true);
        final GoRouter r = await monter(tester, port, role: AppRole.teacher);
        expect(find.text(t.lieu.consigneEnseignant), findsOneWidget);
        await tester.tap(find.text('Conakry'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.lieu.enregistrer));
        await tester.pumpAndSettle();
        expect(find.text(t.lieu.disponibilitesTitre), findsOneWidget);
        expect(find.text(t.lieu.disponibilitesPhrase), findsOneWidget);
        await tester.tap(find.text(t.lieu.disponibilitesLien));
        await tester.pumpAndSettle();
        expect(_chemin(r), Routes.enseignantCreneaux);
      },
    );

    for (final double largeur in <double>[320, 1440]) {
      testWidgets('$largeur px, texte x2 : aucun debordement', (tester) async {
        await monter(tester, _Port(), largeur: largeur, echelle: 2);
        expect(tester.takeException(), isNull);
        expect(find.text(t.lieu.titre), findsWidgets);
      });
    }
  });
}
