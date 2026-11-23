// SALLE-SECOND-APPAREIL (directeur, 23/11/2026) : un profil, un appareil a la
// fois, sans coupure brusque. Les deux dialogues (premier appareil : « Laisser
// passer ? » ; second appareil : « Nous lui demandons de confirmer… »), le
// battement qui les nourrit, et l'attente du service de jeton : acceptation,
// refus, premier appareil silencieux, sans reponse, annulation, hors ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/libelle_appareil.dart';
import 'package:rewayah_academy/core/video/second_appareil.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart'
    show AccesSalle;
import 'package:rewayah_academy/features/salle/passage_second_appareil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Port implements PortSecondAppareil {
  BattementSalle prochain = const BattementSalle();
  final List<String> appels = <String>[];
  bool echecReponse = false;
  final List<EtatPassage> etats = <EtatPassage>[];
  Exception? echecEtat;
  int battements = 0;

  @override
  Future<BattementSalle> battement({
    required String seanceId,
    required String profilId,
    required String appareilId,
    required String libelle,
  }) async {
    battements++;
    return prochain;
  }

  @override
  Future<void> repondre(String demandeId, {required bool accepter}) async {
    if (echecReponse) throw StateError('reseau');
    appels.add('repondre:$demandeId:$accepter');
  }

  @override
  Future<EtatPassage> etat(String demandeId) async {
    final Exception? e = echecEtat;
    if (e != null) throw e;
    return etats.isEmpty ? EtatPassage.enAttente : etats.removeAt(0);
  }

  @override
  Future<void> annuler(String demandeId) async => appels.add('annuler');
}

Widget _app(Widget enfant, {List<Override> overrides = const <Override>[]}) =>
    ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: enfant),
        ),
      ),
    );

FunctionException _conflit(Map<String, Object?> details) =>
    FunctionException(status: 409, details: details);

const Map<String, Object?> _jeton = <String, Object?>{
  'ws_url': 'wss://x',
  'token': 'jwt',
  'room_name': 'salle',
  'provider': 'livekit_cloud',
  'role': 'student',
  'expire_le': '2030-01-01T00:00:00Z',
  'capabilities': <String, Object?>{},
};

void main() {
  testWidgets('premier appareil : la demande dit QUI veut entrer et propose '
      'Accepter / Refuser', (WidgetTester tester) async {
    int accepte = 0;
    int refuse = 0;
    await tester.pumpWidget(
      _app(
        DialogueAutreAppareil(
          libelle: 'Chrome · Android',
          onAccepter: () => accepte++,
          onRefuser: () => refuse++,
        ),
      ),
    );
    expect(find.textContaining('Chrome · Android'), findsOneWidget);
    expect(find.textContaining('Laisser passer\u00a0?'), findsOneWidget);
    await tester.tap(find.byKey(DialogueAutreAppareil.accepterKey));
    await tester.tap(find.byKey(DialogueAutreAppareil.refuserKey));
    expect((accepte, refuse), (1, 1));
    expect(find.text(t.salle.passage.echecReponse), findsNothing);
  });

  testWidgets('premier appareil : en cours, les boutons attendent ; en echec, '
      'la phrase dit quoi faire', (WidgetTester tester) async {
    int appuis = 0;
    await tester.pumpWidget(
      _app(
        DialogueAutreAppareil(
          libelle: '',
          enCours: true,
          echec: true,
          onAccepter: () => appuis++,
          onRefuser: () => appuis++,
        ),
      ),
    );
    await tester.tap(find.byKey(DialogueAutreAppareil.accepterKey));
    await tester.tap(find.byKey(DialogueAutreAppareil.refuserKey));
    expect(appuis, 0);
    expect(find.text(t.salle.passage.echecReponse), findsOneWidget);
    // Sans nom d'appareil, la phrase reste vraie.
    expect(find.text(t.salle.passage.demandeSansNom), findsOneWidget);
  });

  testWidgets('second appareil : « Nous lui demandons de confirmer », avec '
      'Annuler ; hors ligne, il le dit', (WidgetTester tester) async {
    int annule = 0;
    await tester.pumpWidget(
      _app(
        AttentePassageAppareil(
          phase: PhasePassage.attente,
          libelleAutre: 'Safari · iOS',
          onAnnuler: () => annule++,
        ),
      ),
    );
    expect(find.textContaining('Nous lui demandons de confirmer'), findsOne);
    expect(find.textContaining('Safari · iOS'), findsOneWidget);
    expect(find.text(t.salle.passage.horsLigne), findsNothing);
    await tester.tap(find.byKey(AttentePassageAppareil.annulerKey));
    expect(annule, 1);

    await tester.pumpWidget(
      _app(
        AttentePassageAppareil(
          phase: PhasePassage.horsLigne,
          onAnnuler: () => annule++,
        ),
      ),
    );
    expect(find.text(t.salle.passage.horsLigne), findsOneWidget);
  });

  group('premier appareil, dans la salle : le battement et le dialogue', () {
    Future<_Port> monter(
      WidgetTester tester,
      _Port port,
      List<String> cedes,
    ) async {
      await tester.pumpWidget(
        _app(
          SurveillanceSecondAppareil(
            seanceId: 's1',
            profilId: 'p1',
            actif: true,
            rythme: const Duration(seconds: 5),
            appareil: () => 'a1',
            libelle: () => 'Firefox · Windows',
            onCeder: () async => cedes.add('cede'),
            child: const Text('salle'),
          ),
          overrides: <Override>[
            portSecondAppareilProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pump();
      return port;
    }

    testWidgets('Accepter : reponse envoyee, puis sortie propre', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port()
        ..prochain = const BattementSalle(
          demande: DemandePassage(id: 'd1', libelle: 'Chrome · Android'),
        );
      final List<String> cedes = <String>[];
      await monter(tester, port, cedes);
      await tester.pump();
      expect(find.byKey(DialogueAutreAppareil.cle), findsOneWidget);
      expect(find.textContaining('Chrome · Android'), findsOneWidget);
      await tester.tap(find.byKey(DialogueAutreAppareil.accepterKey));
      await tester.pump();
      await tester.pump();
      expect(port.appels, <String>['repondre:d1:true']);
      expect(cedes, <String>['cede']);
      expect(find.byKey(DialogueAutreAppareil.cle), findsNothing);
    });

    testWidgets('Refuser : l\'appareil reste, rien ne le coupe', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port()
        ..prochain = const BattementSalle(
          demande: DemandePassage(id: 'd2', libelle: 'Safari · iOS'),
        );
      final List<String> cedes = <String>[];
      await monter(tester, port, cedes);
      await tester.pump();
      await tester.tap(find.byKey(DialogueAutreAppareil.refuserKey));
      await tester.pump();
      await tester.pump();
      expect(port.appels, <String>['repondre:d2:false']);
      expect(cedes, isEmpty);
      expect(find.byKey(DialogueAutreAppareil.cle), findsNothing);
      expect(find.text('salle'), findsOneWidget);
    });

    testWidgets('reponse impossible (hors ligne) : le dialogue reste et le '
        'dit', (WidgetTester tester) async {
      final _Port port = _Port()
        ..echecReponse = true
        ..prochain = const BattementSalle(
          demande: DemandePassage(id: 'd3', libelle: 'Chrome · Android'),
        );
      final List<String> cedes = <String>[];
      await monter(tester, port, cedes);
      await tester.pump();
      await tester.tap(find.byKey(DialogueAutreAppareil.accepterKey));
      await tester.pump();
      await tester.pump();
      expect(find.text(t.salle.passage.echecReponse), findsOneWidget);
      expect(find.byKey(DialogueAutreAppareil.cle), findsOneWidget);
      expect(cedes, isEmpty);
    });

    testWidgets('le serveur dit de ceder (l\'autre appareil a ete accepte) : '
        'sortie propre sans dialogue', (WidgetTester tester) async {
      final _Port port = _Port()..prochain = const BattementSalle(cede: true);
      final List<String> cedes = <String>[];
      await monter(tester, port, cedes);
      await tester.pump();
      expect(cedes, <String>['cede']);
      expect(find.byKey(DialogueAutreAppareil.cle), findsNothing);
    });

    testWidgets('le battement revient toutes les 5 secondes, et la demande '
        'qui expire disparait', (WidgetTester tester) async {
      final _Port port = _Port()
        ..prochain = const BattementSalle(
          demande: DemandePassage(id: 'd4', libelle: 'Chrome · Android'),
        );
      await monter(tester, port, <String>[]);
      await tester.pump();
      expect(find.byKey(DialogueAutreAppareil.cle), findsOneWidget);
      port.prochain = const BattementSalle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(port.battements, greaterThanOrEqualTo(2));
      expect(find.byKey(DialogueAutreAppareil.cle), findsNothing);
    });

    testWidgets('hors de la salle, aucun battement n\'est envoye', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port();
      await tester.pumpWidget(
        _app(
          SurveillanceSecondAppareil(
            seanceId: 's1',
            profilId: 'p1',
            actif: false,
            onCeder: () async {},
            child: const Text('salle'),
          ),
          overrides: <Override>[
            portSecondAppareilProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pump(const Duration(seconds: 12));
      expect(port.battements, 0);
    });
  });

  group('second appareil : le service de jeton attend la decision', () {
    late _Port port;
    late ProviderContainer conteneur;
    late List<Map<String, dynamic>> corps;
    late List<Object> reponses;

    ServiceVideoSupabase service() => ServiceVideoSupabase(
      SupabaseClient('https://x.supabase.co', 'anon'),
      port: port,
      pilote: conteneur.read(passageSalleProvider.notifier),
      appel: (Map<String, dynamic> c) async {
        corps.add(c);
        final Object r = reponses.removeAt(0);
        if (r is Exception) throw r;
        return FunctionResponse(status: 200, data: r);
      },
      appareil: () => 'appareil-2',
      libelle: () => 'Chrome · Android',
      pas: const Duration(milliseconds: 1),
    );

    setUp(() {
      port = _Port();
      conteneur = ProviderContainer();
      corps = <Map<String, dynamic>>[];
      reponses = <Object>[];
    });
    tearDown(() => conteneur.dispose());

    test('l\'appareil et son etiquette partent avec la demande de jeton, '
        'jamais une adresse', () async {
      reponses.add(_jeton);
      await service().acces('s1');
      expect(corps.single['appareil_id'], 'appareil-2');
      expect(corps.single['appareil_libelle'], 'Chrome · Android');
      expect(corps.single.containsKey('demande_id'), isFalse);
    });

    test(
      'accepte : le jeton se redemande avec la meme demande, puis arrive',
      () async {
        reponses
          ..add(
            _conflit(<String, Object?>{
              'passage': 'attendre',
              'demande_id': 'd1',
              'appareil_libelle': 'Firefox · Windows',
            }),
          )
          ..add(_jeton);
        port.etats.addAll(<EtatPassage>[
          EtatPassage.enAttente,
          EtatPassage.accepte,
        ]);
        final AccesSalle acces = await service().acces('s1');
        expect(acces.jeton, 'jwt');
        expect(corps[1]['demande_id'], 'd1');
        expect(conteneur.read(passageSalleProvider).phase, PhasePassage.aucune);
      },
    );

    test('refuse : l\'echec dit « refuse », aucun jeton', () async {
      reponses.add(
        _conflit(<String, Object?>{'passage': 'attendre', 'demande_id': 'd2'}),
      );
      port.etats.add(EtatPassage.refuse);
      await expectLater(
        service().acces('s1'),
        throwsA(
          isA<EchecSalle>().having(
            (EchecSalle e) => e.motif,
            'motif',
            MotifRefusSalle.passageRefuse,
          ),
        ),
      );
      expect(corps, hasLength(1));
    });

    test('sans reponse : l\'echec se reessaye', () async {
      reponses.add(
        _conflit(<String, Object?>{'passage': 'attendre', 'demande_id': 'd3'}),
      );
      port.etats.add(EtatPassage.sansReponse);
      await expectLater(
        service().acces('s1'),
        throwsA(
          isA<EchecSalle>().having(
            (EchecSalle e) => e.motif,
            'motif',
            MotifRefusSalle.passageSansReponse,
          ),
        ),
      );
    });

    test(
      'premier appareil silencieux : l\'entree est directe, avec la note',
      () async {
        reponses.add(<String, Object?>{
          ..._jeton,
          'note_passage': 'ancien_silencieux',
        });
        await service().acces('s1');
        expect(
          conteneur.read(passageSalleProvider).phase,
          PhasePassage.ancienSilencieux,
        );
      },
    );

    test(
      'annuler : la demande est annulee cote serveur, l\'echec le dit',
      () async {
        reponses.add(
          _conflit(<String, Object?>{
            'passage': 'attendre',
            'demande_id': 'd4',
          }),
        );
        port.etats.addAll(List<EtatPassage>.filled(50, EtatPassage.enAttente));
        final Future<AccesSalle> attente = service().acces('s1');
        attente.ignore();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          conteneur.read(passageSalleProvider).phase,
          PhasePassage.attente,
        );
        conteneur.read(passageSalleProvider.notifier).annuler();
        await expectLater(
          attente,
          throwsA(
            isA<EchecSalle>().having(
              (EchecSalle e) => e.motif,
              'motif',
              MotifRefusSalle.passageAnnule,
            ),
          ),
        );
        expect(port.appels, contains('annuler'));
      },
    );

    test(
      'hors ligne pendant l\'attente : la phase le dit, la demande reste',
      () async {
        reponses
          ..add(
            _conflit(<String, Object?>{
              'passage': 'attendre',
              'demande_id': 'd5',
            }),
          )
          ..add(_jeton);
        port.echecEtat = Exception('reseau');
        final Future<AccesSalle> attente = service().acces('s1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          conteneur.read(passageSalleProvider).phase,
          PhasePassage.horsLigne,
        );
        port
          ..echecEtat = null
          ..etats.add(EtatPassage.accepte);
        expect((await attente).jeton, 'jwt');
      },
    );

    test(
      'un refus du serveur (409 deja decide) est entendu sans attendre',
      () async {
        reponses.add(
          _conflit(<String, Object?>{'passage': 'refuse', 'demande_id': 'd6'}),
        );
        await expectLater(
          service().acces('s1'),
          throwsA(
            isA<EchecSalle>().having(
              (EchecSalle e) => e.motif,
              'motif',
              MotifRefusSalle.passageRefuse,
            ),
          ),
        );
      },
    );
  });

  test(
    'l\'etiquette de l\'appareil : navigateur et systeme, jamais une adresse',
    () {
      expect(
        libelleDepuisAgent(
          'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36',
        ),
        'Chrome · Android',
      );
      expect(
        libelleDepuisAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:130.0) Gecko/20100101 '
          'Firefox/130.0',
        ),
        'Firefox · Windows',
      );
      expect(
        libelleDepuisAgent(
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 '
          'Safari/604.1',
        ),
        'Safari · iOS',
      );
      expect(libelleDepuisAgent('', repli: 'Android'), 'Application · Android');
    },
  );

  test(
    'les phrases de sortie sont dites en francais, anglais et arabe',
    () async {
      for (final AppLocale langue in <AppLocale>[
        AppLocale.fr,
        AppLocale.en,
        AppLocale.ar,
      ]) {
        final tr = await langue.build();
        expect(tr.salle.passage.cede, isNotEmpty);
        expect(tr.salle.passage.refuse, isNotEmpty);
        expect(tr.salle.passage.sansReponse, isNotEmpty);
        expect(tr.salle.passage.ancienSilencieux, isNotEmpty);
        expect(tr.salle.passage.attente, isNotEmpty);
      }
      expect(
        (await AppLocale.ar.build()).salle.passage.demande(appareil: 'X'),
        contains('\u2068X\u2069'),
      );
    },
  );
}
