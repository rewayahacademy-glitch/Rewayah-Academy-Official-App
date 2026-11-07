// SALLE-2-ENTRETIEN (07/11/2026) : « Faisons connaissance », la page de
// l'entretien du candidat (moments ouverts, reservation, date, « Rejoindre
// l'entretien »), sur le serveur V1-b (doubles ici).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/entretien_candidat.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/candidature/entretien_candidat_page.dart';
import 'package:rewayah_academy/features/candidature/entretien_creneaux.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

final DateTime _maintenant = DateTime(2026, 11, 10, 17, 0);

class _FauxEntretien implements PortEntretienCandidat {
  _FauxEntretien({
    this.creneauxRendus = const <CreneauOuvert>[],
    this.entretien,
  });

  List<CreneauOuvert> creneauxRendus;
  MonEntretien? entretien;
  RefusReservation? refus;
  Exception? echecLecture;
  final List<(String, int, String)> reservations = <(String, int, String)>[];

  @override
  Future<List<CreneauOuvert>> creneaux() async {
    if (echecLecture != null) throw echecLecture!;
    return creneauxRendus;
  }

  @override
  Future<IssueReservation> reserver({
    required String creneau,
    required int version,
    required String cle,
  }) async {
    reservations.add((creneau, version, cle));
    if (refus != null) return (entretien: null, refus: refus);
    final CreneauOuvert c = creneauxRendus.firstWhere(
      (CreneauOuvert x) => x.id == creneau,
    );
    entretien = MonEntretien(
      seanceId: 'seance-1',
      debut: c.debut,
      fin: c.fin,
      ouvertureLe: c.debut.subtract(const Duration(minutes: 10)),
      statut: 'planned',
    );
    return (entretien: entretien, refus: null);
  }

  @override
  Future<MonEntretien?> monEntretien() async => entretien;
}

CreneauOuvert _creneau(String id, DateTime debut) => CreneauOuvert(
  id: id,
  debut: debut,
  fin: debut.add(const Duration(minutes: 45)),
  langues: const <String>['fr'],
);

CandidatureDossier _aPlanifier() => const CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.verifications,
  etat: EtatCandidature.entretienAPlanifier,
  version: 7,
);

Future<void> _monter(
  WidgetTester tester,
  _FauxEntretien port, {
  CandidatureDossier? candidature,
  DateTime? maintenant,
  List<Object?>? billets,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attenteEntretien,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attenteEntretien,
          builder: (BuildContext _, GoRouterState _) =>
              const EntretienCandidatPage(),
        ),
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState etat) {
            billets?.add(etat.extra);
            return const Scaffold(body: Text('SALLE'));
          },
        ),
        ...routesCandidature(),
      ],
      surcharges: <Override>[
        ...surchargesCandidature(
          port: FauxMaCandidature(),
          etat: etatCandidat(candidature: candidature ?? _aPlanifier()),
        ),
        portEntretienCandidatProvider.overrideWithValue(port),
        horlogeEntretienProvider.overrideWithValue(
          () => maintenant ?? _maintenant,
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('a planifier : les moments, un choix, la reservation part avec '
      'la version du dossier ; puis la date de l\'entretien', (
    WidgetTester tester,
  ) async {
    final _FauxEntretien port = _FauxEntretien(
      creneauxRendus: <CreneauOuvert>[
        _creneau('c1', DateTime(2026, 11, 12, 18)),
        _creneau('c2', DateTime(2026, 11, 13, 10)),
      ],
    );
    await _monter(tester, port);
    expect(find.text(t.recrutement.entretien.titre), findsWidgets);
    expect(find.byKey(ChoixCreneauEntretien.listeKey), findsOneWidget);
    expect(find.text(t.recrutement.entretien.heureAppareil), findsOneWidget);
    // Sans choix, rien ne part.
    await tester.tap(find.byKey(ChoixCreneauEntretien.reserverKey));
    await tester.pumpAndSettle();
    expect(port.reservations, isEmpty);
    expect(find.text(t.recrutement.entretien.choisir), findsOneWidget);

    await tester.tap(
      find.text(
        horaireEntretien(
          DateTime(2026, 11, 13, 10),
          DateTime(2026, 11, 13, 10, 45),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChoixCreneauEntretien.reserverKey));
    await tester.pumpAndSettle();
    expect(port.reservations.single.$1, 'c2');
    expect(port.reservations.single.$2, 7);
    expect(find.byKey(ContenuEntretien.carteKey), findsOneWidget);
    expect(find.text(t.recrutement.entretien.votreEntretien), findsOneWidget);
    // Pas encore ouvert : l'heure d'ouverture, pas de bouton.
    expect(find.byKey(ContenuEntretien.rejoindreKey), findsNothing);
    expect(
      find.text(t.recrutement.entretien.ouvreA(heure: '09:50')),
      findsOneWidget,
    );
  });

  testWidgets('moment pris entre-temps : dit, la liste est relue', (
    WidgetTester tester,
  ) async {
    final _FauxEntretien port = _FauxEntretien(
      creneauxRendus: <CreneauOuvert>[
        _creneau('c1', DateTime(2026, 11, 12, 18)),
      ],
    )..refus = RefusReservation.creneauIndisponible;
    await _monter(tester, port);
    await tester.tap(
      find.text(
        horaireEntretien(
          DateTime(2026, 11, 12, 18),
          DateTime(2026, 11, 12, 18, 45),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChoixCreneauEntretien.reserverKey));
    await tester.pumpAndSettle();
    expect(find.text(t.recrutement.entretien.pris), findsOneWidget);
    expect(find.byKey(ContenuEntretien.carteKey), findsNothing);
  });

  testWidgets('aucun moment ouvert : une phrase, Reessayer', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _FauxEntretien());
    expect(find.byKey(ChoixCreneauEntretien.aucunKey), findsOneWidget);
    expect(find.byKey(ChoixCreneauEntretien.reserverKey), findsNothing);
  });

  testWidgets('erreur de lecture : le dit, Reessayer relit', (
    WidgetTester tester,
  ) async {
    final _FauxEntretien port = _FauxEntretien(
      creneauxRendus: <CreneauOuvert>[
        _creneau('c1', DateTime(2026, 11, 12, 18)),
      ],
    )..echecLecture = Exception('panne');
    await _monter(tester, port);
    expect(find.byKey(ChoixCreneauEntretien.erreurKey), findsOneWidget);
    port.echecLecture = null;
    await tester.tap(find.text(t.commun.reessayer));
    await tester.pumpAndSettle();
    expect(find.byKey(ChoixCreneauEntretien.listeKey), findsOneWidget);
  });

  testWidgets('entretien ouvert : « Rejoindre l\'entretien » ouvre la salle '
      'sur la seance, billet par extra', (WidgetTester tester) async {
    final List<Object?> billets = <Object?>[];
    final DateTime debut = DateTime(2026, 11, 10, 17, 5);
    await _monter(
      tester,
      _FauxEntretien(
        entretien: MonEntretien(
          seanceId: 'seance-9',
          debut: debut,
          fin: debut.add(const Duration(minutes: 45)),
          ouvertureLe: debut.subtract(const Duration(minutes: 10)),
          statut: 'planned',
        ),
      ),
      candidature: const CandidatureDossier(
        existe: true,
        etape: EtapeCandidature.verifications,
        etat: EtatCandidature.entretienPlanifie,
        version: 8,
      ),
      billets: billets,
    );
    await tester.tap(find.byKey(ContenuEntretien.rejoindreKey));
    await tester.pumpAndSettle();
    expect(find.text('SALLE'), findsOneWidget);
    expect((billets.single! as BilletSalle).sessionId, 'seance-9');
  });

  testWidgets('pas encore ouvert pour la candidature : une phrase, aucun '
      'bouton', (WidgetTester tester) async {
    await _monter(tester, _FauxEntretien(), candidature: candidatureAFaire());
    expect(find.byKey(ContenuEntretien.pasEncoreKey), findsOneWidget);
    expect(find.byKey(ChoixCreneauEntretien.reserverKey), findsNothing);
  });

  testWidgets('arabe : le titre et le bouton dans la langue', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    await _monter(
      tester,
      _FauxEntretien(
        creneauxRendus: <CreneauOuvert>[
          _creneau('c1', DateTime(2026, 11, 12, 18)),
        ],
      ),
    );
    expect(find.text('لنتعارف'), findsWidgets);
    expect(find.text('حجز هذا الموعد'), findsOneWidget);
  });
}
