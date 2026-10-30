// R9 (30/10/2026) : apres la deconnexion, plus aucune lecture ne part vers le
// serveur. Pendant l'essai K4 du 24/10, trois lectures sont revenues en 401
// apres la sortie : `presence_seance_v` (minuterie de 20 s), `acces_du_foyer`
// (relu aussitot sans session) et `offres_remplacement` (toutes les 30 s).
// Chaque test compte les appels du port avant et apres la deconnexion.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/enseignant/remplacements_supabase.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';

class _Session extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: 'p-connecte',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );

  void sortir() => state = const SessionState.deconnecte();
}

class _Presence implements ServicePresence {
  int lectures = 0;

  @override
  Future<List<PresenceParticipant>?> presence(String seanceId) async {
    lectures++;
    return const <PresenceParticipant>[];
  }
}

class _Acces implements PortAccesFoyer {
  int lectures = 0;

  @override
  Future<List<AccesBeneficiaire>> acces() async {
    lectures++;
    return const <AccesBeneficiaire>[];
  }
}

/// Le tableau commun, relu par la meme boucle que
/// `RemplacementsSupabase.suivre` ([relectureCadencee]).
class _Remplacements implements PortRemplacements {
  int lectures = 0;

  @override
  Stream<List<OffreCommune>> suivre() =>
      relectureCadencee(intervalleOffresRemplacement, () async {
        lectures++;
        return const <OffreCommune>[];
      });

  @override
  Future<ResultatPriseRemplacement> prendre(String seanceId) =>
      throw UnimplementedError();
}

ProviderContainer _conteneur(List<Override> surcharges) {
  final ProviderContainer conteneur = ProviderContainer(
    overrides: <Override>[
      sessionProvider.overrideWith(_Session.new),
      ...surcharges,
    ],
  );
  addTearDown(conteneur.dispose);
  return conteneur;
}

void main() {
  testWidgets('presence : la minuterie s arrete a la deconnexion', (
    WidgetTester tester,
  ) async {
    final _Presence service = _Presence();
    final ProviderContainer c = _conteneur(<Override>[
      servicePresenceProvider.overrideWithValue(service),
    ]);
    final ProviderSubscription<AsyncValue<List<PresenceParticipant>?>> a = c
        .listen(presenceSeanceProvider('s1'), (_, _) {});
    addTearDown(a.close);

    await tester.pump(const Duration(seconds: 41));
    // Une lecture immediate, puis a 20 s et a 40 s.
    expect(service.lectures, 3);

    (c.read(sessionProvider.notifier) as _Session).sortir();
    await tester.pump();
    final int alaSortie = service.lectures;
    await tester.pump(const Duration(minutes: 5));
    expect(service.lectures, alaSortie);
    expect(c.read(presenceSeanceProvider('s1')).value, isNull);
  });

  testWidgets('acces du foyer : aucune relecture sans session', (
    WidgetTester tester,
  ) async {
    final _Acces port = _Acces();
    final ProviderContainer c = _conteneur(<Override>[
      portAccesFoyerProvider.overrideWithValue(port),
    ]);
    final ProviderSubscription<AsyncValue<List<AccesBeneficiaire>>> a = c
        .listen(accesFoyerProvider, (_, _) {});
    addTearDown(a.close);
    await tester.pump();
    expect(port.lectures, 1);

    (c.read(sessionProvider.notifier) as _Session).sortir();
    await tester.pump(const Duration(seconds: 1));
    expect(port.lectures, 1);
    expect(c.read(accesFoyerProvider).value, isEmpty);
  });

  testWidgets('offres de remplacement : le flux est coupe a la deconnexion', (
    WidgetTester tester,
  ) async {
    final _Remplacements port = _Remplacements();
    final ProviderContainer c = _conteneur(<Override>[
      portRemplacementsProvider.overrideWithValue(port),
    ]);
    final ProviderSubscription<AsyncValue<List<OffreCommune>>> a = c.listen(
      offresCommunesProvider,
      (_, _) {},
    );
    addTearDown(a.close);
    await tester.pump(const Duration(seconds: 61));
    // Une lecture immediate, puis a 30 s et a 60 s.
    expect(port.lectures, 3);

    (c.read(sessionProvider.notifier) as _Session).sortir();
    await tester.pump();
    final int alaSortie = port.lectures;
    await tester.pump(const Duration(minutes: 5));
    expect(port.lectures, alaSortie);
    expect(c.read(offresCommunesProvider).value, isEmpty);
  });

  testWidgets('relectureCadencee : annulee, plus aucune lecture', (
    WidgetTester tester,
  ) async {
    int lectures = 0;
    final StreamSubscription<int> abonnement = relectureCadencee<int>(
      const Duration(seconds: 30),
      () async => ++lectures,
    ).listen((int _) {});
    // Juste avant le deuxieme tic : l'ancienne boucle `async*` attendait ici
    // le tic suivant, et lisait une fois de plus apres l'annulation.
    await tester.pump(const Duration(seconds: 59));
    expect(lectures, 2);
    unawaited(abonnement.cancel());
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    expect(lectures, 2);
  });

  testWidgets('relectureCadencee : une erreur est emise et termine le flux', (
    WidgetTester tester,
  ) async {
    int lectures = 0;
    final List<Object> erreurs = <Object>[];
    bool fini = false;
    relectureCadencee<int>(const Duration(seconds: 30), () async {
      lectures++;
      throw StateError('401');
    }).listen((int _) {}, onError: erreurs.add, onDone: () => fini = true);
    await tester.pump(const Duration(minutes: 2));
    expect(lectures, 1);
    expect(erreurs, hasLength(1));
    expect(fini, isTrue);
  });

  test('surveillerPersonneConnectee rend l identifiant, puis null', () {
    final ProviderContainer c = _conteneur(const <Override>[]);
    final Provider<String?> lu = Provider<String?>(surveillerPersonneConnectee);
    expect(c.read(lu), 'p-connecte');
    (c.read(sessionProvider.notifier) as _Session).sortir();
    expect(c.read(lu), isNull);
  });
}
