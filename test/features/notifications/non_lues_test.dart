// Fiche « Fraicheur et notifications » (27/10/2026), lignes 12 et 14 : le
// nombre de non-lus vient d'un seul provider, derive de la liste du centre ;
// la veille de fraicheur fait relire cette liste quand la table
// `notifications` change (une notification ecrite par le serveur, une lecture
// faite sur un autre appareil).
//
// Le port de notifications est simule ; le canal de veille est pilote par le
// test. Aucun Supabase.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/fraicheur/port_veille.dart';
import 'package:rewayah_academy/core/fraicheur/veille_fraicheur.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/features/notifications/non_lues.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

class _SourcePilotee implements SourceSession {
  _SourcePilotee(this.flux);

  final StreamController<SessionState> flux;

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

class _VeillePilotee implements PortVeille {
  final List<StreamController<SignalVeille>> ecoutes =
      <StreamController<SignalVeille>>[];

  @override
  Stream<SignalVeille> ecouter() {
    // Ferme par l'application a l'annulation.
    // ignore: close_sinks
    final StreamController<SignalVeille> c = StreamController<SignalVeille>();
    ecoutes.add(c);
    return c.stream;
  }

  void signaler(SignalVeille signal) => ecoutes.last.add(signal);
}

/// Des notifications en memoire qui comptent leurs lectures.
class _FauxNotifications implements PortNotifications {
  _FauxNotifications(this.rendues);

  List<NotificationTuteur> rendues;
  int lectures = 0;
  Exception? erreur;

  @override
  Future<List<NotificationTuteur>> liste() async {
    lectures++;
    if (erreur case final Exception e) throw e;
    return rendues;
  }

  @override
  Future<NotificationTuteur?> detail(String id) async => null;
}

NotificationTuteur _n(String id, {bool lue = false}) => NotificationTuteur(
  id: id,
  titre: 'Une séance est annulée.',
  date: DateTime(2026, 10, 27),
  lue: lue,
);

void main() {
  group('nonLuesDepuis est pure', () {
    test('sans liste, pas de nombre ; avec, le compte des non-lues', () {
      expect(
        nonLuesDepuis(const AsyncValue<List<NotificationTuteur>>.loading()),
        isNull,
      );
      expect(
        nonLuesDepuis(
          const AsyncValue<List<NotificationTuteur>>.error(
            CapaciteIndisponible('DB-CPT-04'),
            StackTrace.empty,
          ),
        ),
        isNull,
      );
      expect(
        nonLuesDepuis(
          AsyncValue<List<NotificationTuteur>>.data(<NotificationTuteur>[
            _n('a'),
            _n('b', lue: true),
            _n('c'),
          ]),
        ),
        2,
      );
      expect(
        nonLuesDepuis(
          const AsyncValue<List<NotificationTuteur>>.data(
            <NotificationTuteur>[],
          ),
        ),
        0,
      );
    });
  });

  group('nonLuesProvider et la veille', () {
    late StreamController<SessionState> session;
    late _VeillePilotee veille;
    late _FauxNotifications port;
    late ProviderContainer conteneur;

    setUp(() {
      session = StreamController<SessionState>.broadcast();
      veille = _VeillePilotee();
      port = _FauxNotifications(<NotificationTuteur>[
        _n('a'),
        _n('b', lue: true),
      ]);
      conteneur = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(_SourcePilotee(session)),
          portVeilleProvider.overrideWithValue(veille),
          portNotificationsProvider.overrideWithValue(port),
        ],
      );
      conteneur
        ..listen(sessionProvider, (_, _) {})
        ..listen(veilleFraicheurProvider, (_, _) {})
        ..listen(nonLuesProvider, (_, _) {});
    });

    tearDown(() async {
      conteneur.dispose();
      await session.close();
    });

    Future<void> connecter() async {
      session.add(const SessionState(resolue: true, profileId: 'p1'));
      await pumpEventQueue();
    }

    test('le compte vient de la liste, lue une fois', () async {
      await connecter();
      expect(conteneur.read(nonLuesProvider), 1);
      expect(port.lectures, 1);
    });

    test('un changement de la table notifications fait relire la liste, et le '
        'point suit (ligne 12 : une notification ecrite ; ligne 14 : lue '
        'ailleurs)', () async {
      await connecter();
      expect(conteneur.read(nonLuesProvider), 1);

      port.rendues = <NotificationTuteur>[_n('a'), _n('b'), _n('c')];
      veille.signaler(const ChangementTable('notifications'));
      await pumpEventQueue();
      expect(port.lectures, 2);
      expect(conteneur.read(nonLuesProvider), 3);

      port.rendues = <NotificationTuteur>[
        for (final NotificationTuteur n in port.rendues) n.marqueeLue(),
      ];
      veille.signaler(const ChangementTable('notifications'));
      await pumpEventQueue();
      expect(port.lectures, 3);
      expect(conteneur.read(nonLuesProvider), 0);
    });

    test('un changement des classes ne relit pas les notifications', () async {
      await connecter();
      veille.signaler(const ChangementTable('groupes'));
      await pumpEventQueue();
      expect(port.lectures, 1);
    });

    test(
      'le canal (re)joint relit aussi les notifications (ligne 2)',
      () async {
        await connecter();
        veille.signaler(const CanalRejoint());
        await pumpEventQueue();
        expect(port.lectures, 2);
      },
    );

    test('la table notifications est veillee, dans sa propre famille', () {
      expect(tablesVeillees, contains('notifications'));
      expect(familleDeLaTable('notifications'), FamilleLecture.notifications);
      expect(
        famillesPourSignal(const ChangementTable('notifications')),
        <FamilleLecture>{FamilleLecture.notifications},
      );
      expect(lecturesVeillees[FamilleLecture.notifications], isNotEmpty);
    });

    test(
      'sans source (capacite absente), pas de nombre, pas de relance',
      () async {
        await connecter();
        expect(conteneur.read(nonLuesProvider), 1);
        // La source disparait : la relecture echoue, Riverpod n'insiste pas
        // tout seul, et le dernier compte connu reste (une relecture en echec
        // garde la valeur precedente, `lib/CLAUDE.md`).
        port.erreur = const CapaciteIndisponible('DB-CPT-04');
        conteneur.invalidate(notificationsTuteurProvider);
        await pumpEventQueue();
        final AsyncValue<List<NotificationTuteur>> liste = conteneur.read(
          notificationsTuteurProvider,
        );
        expect(liste.hasError, isTrue);
        expect(liste.isLoading, isFalse);
        expect(conteneur.read(nonLuesProvider), 1);
        expect(port.lectures, 2);
      },
    );
  });
}
