// HEURES-PROFIL H5 (garde-cap, 12/11/2026) : le planning de la direction lit
// ses semaines au lundi du PROFIL, plus a celui de l'appareil.
//
// Ce que le test prouve :
// (i) profil a +05:30 : le dimanche 15/11 21:00 UTC est deja le lundi 16 ;
//     la semaine du 16 commence a 2026-11-15T18:30Z, et une seance du
//     dimanche 23:30 UTC y tombe (pas dans celle du 9) ;
// (ii) sans fuseau servi : les bornes d'avant (minuit de l'appareil) ;
// (iii) semaine de 169 h (heure d'hiver) : second appel, aucun doublon ;
//       semaine de 167 h (heure d'ete) : l'heure du lundi suivant est ecartee ;
// (iv) le bilan des remplacements recoit les memes bornes ;
// (v) le fuseau arrive apres le premier rendu : la semaine affichee suit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/planning_direction_supabase.dart';
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/admin/port_remplacements_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_planning/planning_libelles.dart';
import 'package:rewayah_academy/features/admin_planning/planning_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_direction.dart';

MonHorloge _horloge(Map<String, Object?> moi) => MonHorloge.lire(
  <String, Object?>{'maintenant': '2026-11-12T12:00:00Z', 'moi': moi},
);

final MonHorloge _kolkata = _horloge(const <String, Object?>{
  'fuseau': 'Asia/Kolkata',
  'decalage_secondes': 19800,
});

final MonHorloge _sansFuseau = MonHorloge.lire(const <String, Object?>{
  'maintenant': '2026-11-12T12:00:00Z',
});

/// Profil a +02:00 qui passe a +01:00 le dimanche 25/10/2026 a 01:00 UTC.
final MonHorloge _heureHiver = _horloge(const <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 7200,
  'prochain_changement': '2026-10-25T01:00:00Z',
  'decalage_apres': 3600,
});

/// Profil a +01:00 qui passe a +02:00 le dimanche 28/03/2027 a 01:00 UTC.
final MonHorloge _heureEte = _horloge(const <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 3600,
  'prochain_changement': '2027-03-28T01:00:00Z',
  'decalage_apres': 7200,
});

Map<String, Object?> _ligne(String id, String debut) => <String, Object?>{
  'id': id,
  'classe': 'A',
  'debut': debut,
  'duree_minutes': 45,
  'statut': 'planned',
  'enseignant': null,
};

/// Un faux serveur PostgREST : rend, pour chaque `p_lundi`, les lignes que le
/// SQL rendrait (`[p_lundi, p_lundi + 7 jours)`) parmi [seances].
class _Serveur {
  late HttpServer _http;
  late SupabaseClient client;
  final List<String> lundisDemandes = <String>[];
  List<Map<String, Object?>> seances = <Map<String, Object?>>[];

  Future<void> demarrer() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen((HttpRequest requete) async {
      final Map<String, dynamic> corps = jsonDecode(
        await utf8.decoder.bind(requete).join(),
      ) as Map<String, dynamic>;
      final String lundi = corps['p_lundi'] as String;
      lundisDemandes.add(lundi);
      final DateTime debut = DateTime.parse(lundi);
      final DateTime fin = debut.add(const Duration(days: 7));
      final List<Map<String, Object?>> rendues = seances.where((
        Map<String, Object?> s,
      ) {
        final DateTime d = DateTime.parse(s['debut']! as String);
        return !d.isBefore(debut) && d.isBefore(fin);
      }).toList();
      requete.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(rendues));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://${_http.address.address}:${_http.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  Future<void> arreter() async {
    await client.dispose();
    await _http.close(force: true);
  }
}

class _RemplacementsFictif implements PortRemplacementsDirection {
  final List<(DateTime, DateTime)> periodes = <(DateTime, DateTime)>[];

  @override
  Future<BilanRemplacements> periode(DateTime debut, DateTime fin) async {
    periodes.add((debut, fin));
    throw StateError('seules les bornes comptent ici');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PlanningFictif implements PortPlanningDirection {
  final List<DateTime> demandes = <DateTime>[];

  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async {
    demandes.add(lundi);
    return const <SeancePlanning>[];
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tearDown(() => poserMonHorlogePourTest(null));

  group('(i) profil a +05:30', () {
    setUp(() => poserMonHorlogePourTest(_kolkata));

    test('le dimanche 21:00 UTC est deja le lundi 16 au profil', () {
      expect(lundiDe(DateTime.utc(2026, 11, 15, 21)), DateTime(2026, 11, 16));
      final ({DateTime debut, DateTime fin}) b = bornesSemaineChezMoi(
        DateTime(2026, 11, 16),
      );
      expect(b.debut, DateTime.utc(2026, 11, 15, 18, 30));
      expect(b.fin, DateTime.utc(2026, 11, 22, 18, 30));
    });

    test('la seance du dimanche 23:30 UTC est lue dans la semaine du 16, '
        'pas dans celle du 9', () async {
      final _Serveur serveur = _Serveur()
        ..seances = <Map<String, Object?>>[
          _ligne('s-dim', '2026-11-15T23:30:00Z'),
        ];
      await serveur.demarrer();
      addTearDown(serveur.arreter);
      final PlanningDirectionSupabase port = PlanningDirectionSupabase(
        serveur.client,
      );

      final List<SeancePlanning> du16 = await port.semaine(
        DateTime(2026, 11, 16),
      );
      expect(serveur.lundisDemandes.single, '2026-11-15T18:30:00.000Z');
      expect(du16.map((SeancePlanning s) => s.id), <String>['s-dim']);

      final List<SeancePlanning> du9 = await port.semaine(
        DateTime(2026, 11, 9),
      );
      expect(du9, isEmpty);
      // Et le regroupement le range au lundi 16.
      expect(parJour(du16).keys.single, DateTime(2026, 11, 16));
    });
  });

  group('(ii) sans fuseau servi', () {
    setUp(() => poserMonHorlogePourTest(_sansFuseau));

    test('le lundi et les bornes de l appareil, comme avant', () {
      expect(lundiDe(DateTime(2026, 10, 18, 23, 59)), DateTime(2026, 10, 12));
      final ({DateTime debut, DateTime fin}) b = bornesSemaineChezMoi(
        DateTime(2026, 10, 12),
      );
      expect(b.debut, DateTime(2026, 10, 12).toUtc());
      expect(b.fin, DateTime(2026, 10, 19).toUtc());
    });
  });

  group('(iii) changement d heure du profil', () {
    test('semaine de 169 h : second appel, la seance du dimanche 23:30 '
        'locale est lue, aucun doublon', () async {
      poserMonHorlogePourTest(_heureHiver);
      final ({DateTime debut, DateTime fin}) b = bornesSemaineChezMoi(
        DateTime(2026, 10, 19),
      );
      expect(b.debut, DateTime.utc(2026, 10, 18, 22));
      expect(b.fin, DateTime.utc(2026, 10, 25, 23));
      expect(b.fin.difference(b.debut), const Duration(hours: 169));

      final _Serveur serveur = _Serveur()
        ..seances = <Map<String, Object?>>[
          _ligne('s-lun', '2026-10-19T08:00:00Z'),
          _ligne('s-mer', '2026-10-21T16:00:00Z'),
          // Dimanche 25/10 23:30 a +01:00 : dans la 169e heure.
          _ligne('s-dim', '2026-10-25T22:30:00Z'),
          // Lundi 26/10 00:30 a +01:00 : semaine suivante.
          _ligne('s-suiv', '2026-10-25T23:30:00Z'),
        ];
      await serveur.demarrer();
      addTearDown(serveur.arreter);

      final List<SeancePlanning> seances = await PlanningDirectionSupabase(
        serveur.client,
      ).semaine(DateTime(2026, 10, 19));
      expect(serveur.lundisDemandes, <String>[
        '2026-10-18T22:00:00.000Z',
        '2026-10-18T23:00:00.000Z',
      ]);
      expect(seances.map((SeancePlanning s) => s.id), <String>[
        's-lun',
        's-mer',
        's-dim',
      ]);
    });

    test('semaine de 167 h : un seul appel, l heure du lundi suivant est '
        'ecartee', () async {
      poserMonHorlogePourTest(_heureEte);
      final ({DateTime debut, DateTime fin}) b = bornesSemaineChezMoi(
        DateTime(2027, 3, 22),
      );
      expect(b.debut, DateTime.utc(2027, 3, 21, 23));
      expect(b.fin, DateTime.utc(2027, 3, 28, 22));
      expect(b.fin.difference(b.debut), const Duration(hours: 167));

      final _Serveur serveur = _Serveur()
        ..seances = <Map<String, Object?>>[
          _ligne('s-lun', '2027-03-22T08:00:00Z'),
          // Dimanche 28/03 23:30 a +02:00 : dans la semaine.
          _ligne('s-dim', '2027-03-28T21:30:00Z'),
          // Lundi 29/03 00:30 a +02:00 : rendu par le serveur (168 h), pas
          // de cette semaine.
          _ligne('s-suiv', '2027-03-28T22:30:00Z'),
        ];
      await serveur.demarrer();
      addTearDown(serveur.arreter);

      final List<SeancePlanning> seances = await PlanningDirectionSupabase(
        serveur.client,
      ).semaine(DateTime(2027, 3, 22));
      expect(serveur.lundisDemandes, hasLength(1));
      expect(seances.map((SeancePlanning s) => s.id), <String>[
        's-lun',
        's-dim',
      ]);
    });
  });

  test('(iv) le bilan des remplacements recoit les bornes du profil', () async {
    poserMonHorlogePourTest(_kolkata);
    final _RemplacementsFictif port = _RemplacementsFictif();
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[
        portRemplacementsDirectionProvider.overrideWithValue(port),
      ],
    );
    addTearDown(conteneur.dispose);
    await expectLater(
      conteneur.read(
        remplacementsSemaineProvider(DateTime(2026, 11, 16)).future,
      ),
      throwsStateError,
    );
    expect(port.periodes.single, (
      DateTime.utc(2026, 11, 15, 18, 30),
      DateTime.utc(2026, 11, 22, 18, 30),
    ));
  });

  testWidgets('(v) le fuseau arrive apres le premier rendu : la semaine '
      'affichee suit le profil', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final Completer<MonHorloge?> arrivee = Completer<MonHorloge?>();
    final _PlanningFictif port = _PlanningFictif();
    // Dimanche 15/11 21:00 UTC : lundi 16 a +05:30.
    final DateTime instant = DateTime.utc(2026, 11, 15, 21);
    final DateTime lundiAppareil = lundiDe(instant);
    // L'appareil de test n'est pas au fuseau du profil.
    expect(lundiAppareil, isNot(DateTime(2026, 11, 16)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          portPlanningDirectionProvider.overrideWithValue(port),
          monHorlogeProvider.overrideWith((Ref _) => arrivee.future),
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
          sessionProvider.overrideWith(SessionPlanning.new),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: PlanningPage(semaineInitiale: instant),
          ),
        ),
      ),
    );
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(port.demandes.last, lundiAppareil);
    expect(find.text(libelleSemaine(lundiAppareil)), findsOneWidget);

    poserMonHorlogePourTest(_kolkata);
    arrivee.complete(_kolkata);
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(port.demandes.last, DateTime(2026, 11, 16));
    expect(find.text(libelleSemaine(DateTime(2026, 11, 16))), findsOneWidget);
  });
}
