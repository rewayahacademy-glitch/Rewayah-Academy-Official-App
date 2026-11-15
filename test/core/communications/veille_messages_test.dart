// MESSAGERIE-TEMPS-REEL (14/11/2026) : la veille des messages suit la
// personne connectee ; chaque signal monte le rang (les ecrans relisent) ; un
// message recu hors du fil ouvert pose l'avis « Nouveau message » ; un canal
// tombe se dit (enDirect faux) et relit toutes les 30 secondes jusqu'a son
// retour. L'adaptateur lit une ligne de com_signaux sans rien d'autre.

import 'dart:async';

// fake_async vient avec flutter_test (version fixee par le SDK).
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/communications/veille_messages_supabase.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';

class _SourcePilotee implements SourceSession {
  _SourcePilotee(this.flux);

  final StreamController<SessionState> flux;

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

class _VeillePilotee implements PortVeilleMessages {
  final List<StreamController<SignalMessages>> ecoutes =
      <StreamController<SignalMessages>>[];
  final List<String> profils = <String>[];

  @override
  Stream<SignalMessages> ecouter(String profilId) {
    profils.add(profilId);
    // Fermee par l'application a l'annulation.
    // ignore: close_sinks
    final StreamController<SignalMessages> c =
        StreamController<SignalMessages>();
    ecoutes.add(c);
    return c.stream;
  }
}

class _ReseauPilote implements ServiceReseau {
  // Ferme dans `tearDown`.
  // ignore: close_sinks
  final StreamController<bool> flux = StreamController<bool>.broadcast();

  @override
  Stream<bool> horsLigne() => flux.stream;
}

void main() {
  late StreamController<SessionState> session;
  late _VeillePilotee veille;
  late _ReseauPilote reseau;
  late ProviderContainer c;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    session = StreamController<SessionState>.broadcast();
    veille = _VeillePilotee();
    reseau = _ReseauPilote();
    c = ProviderContainer(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(_SourcePilotee(session)),
        portVeilleMessagesProvider.overrideWithValue(veille),
        serviceReseauProvider.overrideWithValue(reseau),
      ],
    );
    c
      ..listen(sessionProvider, (_, _) {})
      ..listen(veilleMessagesProvider, (_, _) {})
      ..listen(avisEphemereProvider, (_, _) {});
  });

  tearDown(() async {
    c.dispose();
    await session.close();
    await reseau.flux.close();
  });

  Future<void> connecter(String profil) async {
    session.add(SessionState(resolue: true, profileId: profil));
    await pumpEventQueue();
  }

  test('aucune veille sans personne connectee', () async {
    await pumpEventQueue();
    expect(veille.ecoutes, isEmpty);
    expect(c.read(etatVeilleMessagesProvider).rang, 0);
  });

  test('la veille s\'ouvre pour la personne connectee, les signaux montent '
      'le rang, regroupes (15/11/2026)', () {
    fakeAsync((FakeAsync temps) {
      final StreamController<SessionState> session =
          StreamController<SessionState>.broadcast();
      addTearDown(session.close);
      final _VeillePilotee veille = _VeillePilotee();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(_SourcePilotee(session)),
          portVeilleMessagesProvider.overrideWithValue(veille),
          serviceReseauProvider.overrideWithValue(_ReseauPilote()),
        ],
      );
      addTearDown(c.dispose);
      c
        ..listen(sessionProvider, (_, _) {})
        ..listen(veilleMessagesProvider, (_, _) {})
        ..listen(avisEphemereProvider, (_, _) {});
      temps.flushMicrotasks();
      session.add(const SessionState(resolue: true, profileId: 'p1'));
      temps.elapse(const Duration(milliseconds: 10));
      expect(veille.profils, <String>['p1']);
      int rang() => c.read(etatVeilleMessagesProvider).rang;

      // Le premier signal monte le rang tout de suite.
      veille.ecoutes.last.add(const CanalMessagesRejoint());
      temps.flushMicrotasks();
      final int apresJointure = rang();
      expect(apresJointure, 1);

      // Une rafale dans la fenetre : le rang ne bouge pas, l'etat est a jour.
      veille.ecoutes.last
        ..add(
          const FilABouge(filId: 'f1', nature: NatureSignalMessages.lecture),
        )
        ..add(
          const FilABouge(filId: 'f2', nature: NatureSignalMessages.lecture),
        );
      temps.flushMicrotasks();
      expect(rang(), apresJointure);
      expect(c.read(etatVeilleMessagesProvider).dernier?.filId, 'f2');
      // Une lecture ne pose aucun avis.
      expect(c.read(avisEphemereProvider), isNull);

      // A la fin de la fenetre : UNE seule montee pour toute la rafale.
      temps.elapse(AppDelais.regroupementMessages);
      expect(rang(), apresJointure + 1);

      // Plus rien en attente : le rang reste.
      temps.elapse(AppDelais.regroupementMessages * 3);
      expect(rang(), apresJointure + 1);

      // Un signal isole apres la fenetre monte aussitot le rang.
      veille.ecoutes.last.add(
        const FilABouge(filId: 'f3', nature: NatureSignalMessages.lecture),
      );
      temps.flushMicrotasks();
      expect(rang(), apresJointure + 2);
    });
  });

  test('aucun signal : aucune relecture (le rang ne bouge pas)', () {
    fakeAsync((FakeAsync temps) {
      final StreamController<SessionState> session =
          StreamController<SessionState>.broadcast();
      addTearDown(session.close);
      final _VeillePilotee veille = _VeillePilotee();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(_SourcePilotee(session)),
          portVeilleMessagesProvider.overrideWithValue(veille),
          serviceReseauProvider.overrideWithValue(_ReseauPilote()),
        ],
      );
      addTearDown(c.dispose);
      c
        ..listen(sessionProvider, (_, _) {})
        ..listen(veilleMessagesProvider, (_, _) {});
      temps.flushMicrotasks();
      session.add(const SessionState(resolue: true, profileId: 'p1'));
      temps.elapse(const Duration(minutes: 5));
      expect(c.read(etatVeilleMessagesProvider).rang, 0);
    });
  });

  test('un message recu hors du fil ouvert pose l\'avis, pas dans le fil '
      'ouvert', () async {
    await connecter('p1');
    c.read(filAfficheProvider.notifier).ouvrir('f1');
    veille.ecoutes.last.add(
      const FilABouge(filId: 'f1', nature: NatureSignalMessages.message),
    );
    await pumpEventQueue();
    expect(c.read(avisEphemereProvider), isNull);
    veille.ecoutes.last.add(
      const FilABouge(filId: 'f2', nature: NatureSignalMessages.message),
    );
    await pumpEventQueue();
    expect(c.read(avisEphemereProvider), t.com.messages.direct.nouveau);
  });

  test('canal tombe : enDirect faux, relecture toutes les 30 s, puis retour '
      'au direct', () {
    fakeAsync((FakeAsync temps) {
      // Tout est monte dans la zone du faux temps.
      final StreamController<SessionState> session =
          StreamController<SessionState>.broadcast();
      addTearDown(session.close);
      final _VeillePilotee veille = _VeillePilotee();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(_SourcePilotee(session)),
          portVeilleMessagesProvider.overrideWithValue(veille),
          serviceReseauProvider.overrideWithValue(_ReseauPilote()),
        ],
      );
      addTearDown(c.dispose);
      c
        ..listen(sessionProvider, (_, _) {})
        ..listen(veilleMessagesProvider, (_, _) {});
      temps.flushMicrotasks();
      session.add(const SessionState(resolue: true, profileId: 'p1'));
      temps.elapse(const Duration(milliseconds: 10));
      veille.ecoutes.last.addError(const ErreurCanalMessages('timedOut'));
      temps.flushMicrotasks();
      expect(c.read(etatVeilleMessagesProvider).enDirect, isFalse);
      final int rang = c.read(etatVeilleMessagesProvider).rang;
      temps.elapse(AppDelais.repliMessages * 2);
      expect(c.read(etatVeilleMessagesProvider).rang, rang + 2);
      veille.ecoutes.last.add(const CanalMessagesRejoint());
      temps.flushMicrotasks();
      expect(c.read(etatVeilleMessagesProvider).enDirect, isTrue);
      // Le retour tombe dans la fenetre de la derniere relecture : son rang
      // monte a la fin de la fenetre.
      temps.elapse(AppDelais.regroupementMessages);
      final int rejoint = c.read(etatVeilleMessagesProvider).rang;
      temps.elapse(AppDelais.repliMessages * 3);
      // Le repli s'est arrete avec le retour du canal.
      expect(c.read(etatVeilleMessagesProvider).rang, rejoint);
    });
  });

  test('la deconnexion ferme la veille', () async {
    await connecter('p1');
    session.add(const SessionState.deconnecte());
    await pumpEventQueue();
    expect(veille.ecoutes.single.hasListener, isFalse);
  });

  group('adaptateur : une ligne de com_signaux', () {
    test('message et lecture sont lus, rien d\'autre', () {
      final FilABouge? m = VeilleMessagesSupabase.signalDe(<String, dynamic>{
        'destinataire': 'p1',
        'fil_id': 'f1',
        'nature': 'message',
        'rang': 3,
      });
      expect(m?.filId, 'f1');
      expect(m?.nature, NatureSignalMessages.message);
      expect(
        VeilleMessagesSupabase.signalDe(<String, dynamic>{
          'fil_id': 'f1',
          'nature': 'lecture',
        })?.nature,
        NatureSignalMessages.lecture,
      );
      expect(
        VeilleMessagesSupabase.signalDe(<String, dynamic>{
          'fil_id': 'f1',
          'nature': 'autre',
        }),
        isNull,
      );
      expect(
        VeilleMessagesSupabase.signalDe(<String, dynamic>{'nature': 'message'}),
        isNull,
      );
    });
  });
}
