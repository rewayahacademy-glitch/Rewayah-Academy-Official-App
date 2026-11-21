// PERSONNES-PERF (20/11/2026) : combien de lectures un onglet du bureau
// laisse ouvert fait-il par heure ? En production, le 20/11, un compte de la
// direction relisait toute la messagerie (`com_lister_fils`) 90 fois par heure,
// la nuit, sans aucun geste. Minuteur simule (une heure), la coquille
// (`nonLusMessagesProvider`) et la liste des candidatures
// (`nonLusParCandidatureProvider`) a l'ecran, comme dans le bureau.
//
// AVANT (code de main du 20/11, meme sonde, lectures demandees au port) :
// canal tombe 242 lectures completes par heure (onglet vu ou cache) ; canal qui se rejoint toutes
// les 40 s : 360 ; canal en direct sans message : 0.

import 'dart:async';

// fake_async vient avec flutter_test (version fixee par le SDK).
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/communications/visibilite_onglet.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/features/admin_candidatures/messages_non_lus.dart';
import 'package:rewayah_academy/features/com_messages/non_lus_messages.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

class _Source implements SourceSession {
  _Source(this.flux);

  final StreamController<SessionState> flux;

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

class _Veille implements PortVeilleMessages {
  final List<StreamController<SignalMessages>> ecoutes =
      <StreamController<SignalMessages>>[];
  int annulations = 0;

  @override
  Stream<SignalMessages> ecouter(String profilId) {
    // Fermee par l'application a l'annulation.
    // ignore: close_sinks
    late final StreamController<SignalMessages> c;
    c = StreamController<SignalMessages>(onCancel: () => annulations += 1);
    ecoutes.add(c);
    return c.stream;
  }
}

class _Reseau implements ServiceReseau {
  // Ferme avec le test.
  // ignore: close_sinks
  final StreamController<bool> flux = StreamController<bool>.broadcast();

  @override
  Stream<bool> horsLigne() => flux.stream;
}

class _Visibilite implements PortVisibilite {
  // Ferme avec le test.
  // ignore: close_sinks
  final StreamController<bool> flux = StreamController<bool>.broadcast();
  bool vue = true;

  @override
  bool get visible => vue;

  @override
  Stream<bool> changements() => flux.stream;

  void changer(bool v) {
    vue = v;
    flux.add(v);
  }
}

/// Un port qui sait lire les non-lus seuls : compte les lectures legeres et
/// les lectures completes.
class _MessagesLegers extends MessagesMetierIndisponibles
    implements LectureNonLus {
  int completes = 0;
  int legeres = 0;

  @override
  Future<List<ResumeFil>> fils() async {
    completes += 1;
    return const <ResumeFil>[];
  }

  @override
  Future<List<NonLusFil>> nonLus() async {
    legeres += 1;
    return const <NonLusFil>[
      NonLusFil(
        filId: 'f1',
        type: TypeObjetLie.candidature,
        objetId: 'c1',
        nonLus: 2,
      ),
    ];
  }
}

class _Mesure {
  int completes = 0;
  int legeres = 0;
  int annulations = 0;
  int ouvertures = 0;
}

_Mesure _mesurer(
  void Function(FakeAsync temps, _Veille veille, _Visibilite vue) scenario,
) {
  final _Mesure m = _Mesure();
  fakeAsync((FakeAsync temps) {
    final StreamController<SessionState> session =
        StreamController<SessionState>.broadcast();
    final _Veille veille = _Veille();
    final _Visibilite vue = _Visibilite();
    final _MessagesLegers messages = _MessagesLegers();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(_Source(session)),
        portVeilleMessagesProvider.overrideWithValue(veille),
        serviceReseauProvider.overrideWithValue(_Reseau()),
        portVisibiliteProvider.overrideWithValue(vue),
        portMessagesMetierProvider.overrideWithValue(messages),
      ],
    );
    c
      ..listen(sessionProvider, (_, _) {})
      ..listen(veilleMessagesProvider, (_, _) {})
      ..listen(nonLusMessagesProvider, (_, _) {})
      ..listen(nonLusParCandidatureProvider, (_, _) {});
    temps.flushMicrotasks();
    session.add(const SessionState(resolue: true, profileId: 'p1'));
    temps.elapse(const Duration(seconds: 1));
    veille.ecoutes.last.add(const CanalMessagesRejoint());
    // Au-dela de la fenetre de rejointe : le scenario part d'un etat calme.
    temps.elapse(const Duration(minutes: 2));
    final int completes = messages.completes;
    final int legeres = messages.legeres;
    final int ouvertures = veille.ecoutes.length;
    scenario(temps, veille, vue);
    m
      ..completes = messages.completes - completes
      ..legeres = messages.legeres - legeres
      ..annulations = veille.annulations
      ..ouvertures = veille.ecoutes.length - ouvertures;
    c.dispose();
    unawaited(session.close());
  });
  return m;
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('canal tombe, onglet vu : un tic de 30 s, lectures legeres seules', () {
    final _Mesure m = _mesurer((FakeAsync t, _Veille v, _Visibilite _) {
      v.ecoutes.last.addError(const ErreurCanalMessages('channelError'));
      t.elapse(const Duration(hours: 1));
    });
    // 120 tics ; deux ecrans servis par lecture : 240 lectures LEGERES
    // demandees au port (une seule par tic arrive au serveur, la jonction de
    // l'adaptateur), et aucune complete. Meme rythme qu'avant quand l'onglet
    // est vu (la chute du canal ne fait plus relire) ; la lecture change.
    expect(m.completes, 0);
    expect(m.legeres, 240);
  });

  test('canal tombe, onglet cache : un tic toutes les 5 min, relecture au '
      'retour', () {
    final _Mesure m = _mesurer((FakeAsync t, _Veille v, _Visibilite vue) {
      v.ecoutes.last.addError(const ErreurCanalMessages('channelError'));
      vue.changer(false);
      t.elapse(const Duration(hours: 1));
    });
    // 12 tics en une heure cachee (deux ecrans par tic).
    expect(m.completes, 0);
    expect(m.legeres, 24);

    // Au retour de l'onglet : une relecture immediate.
    final _Mesure retour = _mesurer((FakeAsync t, _Veille v, _Visibilite vue) {
      v.ecoutes.last.addError(const ErreurCanalMessages('channelError'));
      vue.changer(false);
      t.elapse(const Duration(minutes: 3));
      vue.changer(true);
      t.elapse(const Duration(seconds: 1));
    });
    expect(retour.legeres, 2);
  });

  test(
    'canal qui se rejoint en boucle (toutes les 40 s) : une relecture par '
    'minute au plus, et le canal est ferme puis rouvert de plus en plus tard',
    () {
      final _Mesure m = _mesurer((FakeAsync t, _Veille v, _Visibilite _) {
        for (int i = 0; i < 90; i++) {
          if (v.ecoutes.last.isClosed || !v.ecoutes.last.hasListener) {
            t.elapse(const Duration(seconds: 40));
            continue;
          }
          v.ecoutes.last.add(const CanalMessagesRejoint());
          t.elapse(const Duration(seconds: 20));
          v.ecoutes.last.addError(const ErreurCanalMessages('channelError'));
          t.elapse(const Duration(seconds: 20));
        }
      });
      expect(m.completes, 0);
      // Une relecture (deux ecrans) par fenetre d'une minute au plus, plus les
      // tics du repli quand le canal est tombe.
      expect(m.legeres, lessThanOrEqualTo(2 * 60 + 2 * 120));
    },
  );

  test('trois echecs sans retour : le canal est ferme, puis rouvert apres '
      '30 s, 60 s, 120 s...', () {
    final _Mesure m = _mesurer((FakeAsync t, _Veille v, _Visibilite _) {
      // Le client temps reel retente seul : trois echecs de suite.
      for (int i = 0; i < 3; i++) {
        v.ecoutes.last.addError(const ErreurCanalMessages('timedOut'));
        t.flushMicrotasks();
      }
      expect(v.ecoutes.last.hasListener, isFalse);
      final int avant = v.ecoutes.length;
      t.elapse(const Duration(seconds: 29));
      expect(v.ecoutes.length, avant);
      t.elapse(const Duration(seconds: 1));
      expect(v.ecoutes.length, avant + 1);
      // Trois nouveaux echecs : l'attente double.
      for (int i = 0; i < 3; i++) {
        v.ecoutes.last.addError(const ErreurCanalMessages('timedOut'));
        t.flushMicrotasks();
      }
      t.elapse(const Duration(seconds: 59));
      expect(v.ecoutes.length, avant + 1);
      t.elapse(const Duration(seconds: 1));
      expect(v.ecoutes.length, avant + 2);
    });
    expect(m.ouvertures, 2);
  });

  test('canal en direct, aucun message : aucune lecture', () {
    final _Mesure m = _mesurer((FakeAsync t, _Veille v, _Visibilite _) {
      t.elapse(const Duration(hours: 1));
    });
    expect(m.completes, 0);
    expect(m.legeres, 0);
  });

  test('un message recu : relu tout de suite, onglet vu ou cache', () {
    final _Mesure m = _mesurer((FakeAsync t, _Veille v, _Visibilite vue) {
      vue.changer(false);
      v.ecoutes.last.add(
        const FilABouge(filId: 'f1', nature: NatureSignalMessages.message),
      );
      t.elapse(const Duration(seconds: 1));
    });
    expect(m.legeres, 2);
  });
}
