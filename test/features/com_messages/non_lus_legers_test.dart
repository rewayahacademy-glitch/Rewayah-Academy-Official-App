// PERSONNES-PERF (20/11/2026) : l'adaptateur lit les non-lus seuls
// (`com_non_lus_par_objet`) ; tant que le serveur ne la connait pas, il
// retombe sur `com_lister_fils`, sans erreur et sans la redemander ; et jamais
// deux lectures de la meme liste ne partent en meme temps.

import 'dart:async';

// fake_async vient avec flutter_test (version fixee par le SDK).
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

const String _fil = '7c400000-0000-4000-8000-0000000000f1';
const String _candidature = '9e9ca000-0000-4000-8000-000000000001';

Map<String, Object?> _filComplet(int nonLus) => <String, Object?>{
  'id': _fil,
  'objet': <String, Object?>{'type': 'candidature', 'id': _candidature},
  'accessible': true,
  'peut_ecrire': true,
  'cree_le': '2026-11-20T10:00:00Z',
  'dernier_message_le': '2026-11-20T11:00:00Z',
  'parties': <Object?>[
    <String, Object?>{
      'id': 'administration',
      'nature': 'equipe',
      'fonction': 'administration',
      'est_soi': true,
    },
  ],
  'non_lus': nonLus,
  'nouveau': false,
  'messages': <Object?>[],
};

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  MessagesMetierSupabase adaptateur(
    Future<Object?> Function(String f, Map<String, dynamic> p) appel,
  ) => MessagesMetierSupabase(
    appel,
    libelles: const LibellesCommunicationSlang(),
  );

  test('la lecture legere : fils metier a non-lus, rien d\'autre', () async {
    final List<String> appels = <String>[];
    final MessagesMetierSupabase p = adaptateur((String f, _) async {
      appels.add(f);
      return <Object?>[
        <String, Object?>{
          'fil': _fil,
          'type': 'candidature',
          'objet': _candidature,
          'non_lus': 2,
        },
        // Une nature qui n'est pas un fil metier : ecartee, comme fils().
        <String, Object?>{
          'fil': 'f2',
          'type': 'publication',
          'objet': 'o2',
          'non_lus': 1,
        },
        // Illisible : ecartee.
        <String, Object?>{'fil': 'f3', 'type': 'classe', 'non_lus': 1},
      ];
    });
    final List<NonLusFil> n = await p.nonLus();
    expect(appels, <String>['com_non_lus_par_objet']);
    expect(n, hasLength(1));
    expect(n.single.filId, _fil);
    expect(n.single.objetId, _candidature);
    expect(n.single.nonLus, 2);
  });

  test('serveur sans la fonction : repli sur com_lister_fils, meme resultat, '
      'une seule tentative', () async {
    final List<String> appels = <String>[];
    final MessagesMetierSupabase p = adaptateur((String f, _) async {
      appels.add(f);
      if (f == 'com_non_lus_par_objet') {
        throw const PostgrestException(message: 'absente', code: 'PGRST202');
      }
      return <Object?>[_filComplet(3)];
    });
    final List<NonLusFil> premiere = await p.nonLus();
    final List<NonLusFil> attendu = nonLusDepuisFils(await p.fils());
    expect(
      premiere.map((NonLusFil f) => (f.filId, f.objetId, f.nonLus)),
      <(String, String, int)>[(_fil, _candidature, 3)],
    );
    expect(
      attendu.map((NonLusFil f) => (f.filId, f.objetId, f.nonLus)),
      premiere.map((NonLusFil f) => (f.filId, f.objetId, f.nonLus)),
    );
    await p.nonLus();
    expect(
      appels.where((String f) => f == 'com_non_lus_par_objet'),
      hasLength(1),
    );
  });

  test('jamais deux lectures en meme temps : la suivante attend la fin de '
      'la premiere, et sert tous ceux arrives entre-temps', () async {
    int enCours = 0;
    int auPlus = 0;
    int lectures = 0;
    final List<Completer<Object?>> reponses = <Completer<Object?>>[];
    final MessagesMetierSupabase p = adaptateur((String f, _) {
      lectures += 1;
      enCours += 1;
      if (enCours > auPlus) auPlus = enCours;
      final Completer<Object?> c = Completer<Object?>();
      reponses.add(c);
      return c.future.whenComplete(() => enCours -= 1);
    });
    // Deux demandes du meme signal : une lecture.
    final Future<List<ResumeFil>> a = p.fils();
    final Future<List<ResumeFil>> b = p.fils();
    expect(lectures, 1);
    // Plus tard, pendant la lecture : aucune lecture en parallele.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final Future<List<ResumeFil>> c = p.fils();
    final Future<List<ResumeFil>> d = p.fils();
    expect(lectures, 1);
    reponses.first.complete(<Object?>[_filComplet(1)]);
    await Future.wait(<Future<List<ResumeFil>>>[a, b]);
    await pumpEventQueue();
    // Une seule lecture suivante, pour c et d.
    expect(lectures, 2);
    reponses.last.complete(<Object?>[_filComplet(2)]);
    final List<List<ResumeFil>> fin = await Future.wait(
      <Future<List<ResumeFil>>>[c, d],
    );
    expect(fin.first.single.attention.nonLus, 2);
    expect(fin.last.single.attention.nonLus, 2);
    expect(auPlus, 1);
  });

  test('B1 : une lecture qui ne revient jamais est abandonnee apres le delai ; '
      'la demande suivante relance et revient', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      final MessagesMetierSupabase p = adaptateur((String f, _) {
        appels += 1;
        if (appels == 1) return Completer<Object?>().future; // ne revient pas
        return Future<Object?>.value(<Object?>[
          <String, Object?>{
            'fil': _fil,
            'type': 'candidature',
            'objet': _candidature,
            'non_lus': 4,
          },
        ]);
      });
      Object? erreur;
      p.nonLus().then(
        (_) {},
        onError: (Object e) {
          erreur = e;
        },
      );
      temps.elapse(AppDelais.lectureMessagesMax);
      expect(erreur, isA<TimeoutException>());
      List<NonLusFil>? seconde;
      p.nonLus().then((List<NonLusFil> n) => seconde = n);
      temps.flushMicrotasks();
      expect(appels, 2);
      expect(seconde!.single.nonLus, 4);
    });
  });

  test('B1 : meme regle pour la liste des fils', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      final MessagesMetierSupabase p = adaptateur((String f, _) {
        appels += 1;
        if (appels == 1) return Completer<Object?>().future;
        return Future<Object?>.value(<Object?>[_filComplet(1)]);
      });
      Object? erreur;
      p.fils().then(
        (_) {},
        onError: (Object e) {
          erreur = e;
        },
      );
      temps.elapse(AppDelais.lectureMessagesMax);
      expect(erreur, isNotNull);
      List<ResumeFil>? seconde;
      p.fils().then((List<ResumeFil> f) => seconde = f);
      temps.flushMicrotasks();
      expect(seconde, hasLength(1));
    });
  });

  test('M1 : une demande juste apres « lu » ne rejoint pas la lecture partie '
      'avant lui', () async {
    final List<String> appels = <String>[];
    final List<Completer<Object?>> reponses = <Completer<Object?>>[];
    final MessagesMetierSupabase p = adaptateur((String f, _) {
      appels.add(f);
      if (f == 'com_marquer_lu') return Future<Object?>.value(null);
      final Completer<Object?> c = Completer<Object?>();
      reponses.add(c);
      return c.future;
    });
    final Future<List<NonLusFil>> avant = p.nonLus();
    await p.marquerLu(_fil);
    final Future<List<NonLusFil>> apres = p.nonLus();
    // La seconde attend la fin de la premiere, puis relit (jamais en meme temps).
    expect(
      appels.where((String f) => f == 'com_non_lus_par_objet'),
      hasLength(1),
    );
    reponses.first.complete(<Object?>[
      <String, Object?>{
        'fil': _fil,
        'type': 'candidature',
        'objet': _candidature,
        'non_lus': 3,
      },
    ]);
    await avant;
    await pumpEventQueue();
    expect(
      appels.where((String f) => f == 'com_non_lus_par_objet'),
      hasLength(2),
    );
    reponses.last.complete(<Object?>[]);
    expect(await apres, isEmpty);
  });

  test(
    'M2 : le repli sur la liste complete est retente apres 10 minutes',
    () async {
      DateTime maintenant = DateTime(2026, 11, 21, 10);
      final List<String> appels = <String>[];
      bool installee = false;
      final MessagesMetierSupabase p = MessagesMetierSupabase(
        (String f, _) async {
          appels.add(f);
          if (f == 'com_non_lus_par_objet' && !installee) {
            throw const PostgrestException(
              message: 'absente',
              code: 'PGRST202',
            );
          }
          if (f == 'com_non_lus_par_objet') return <Object?>[];
          return <Object?>[_filComplet(2)];
        },
        libelles: const LibellesCommunicationSlang(),
        horloge: () => maintenant,
      );
      await p.nonLus();
      installee = true;
      maintenant = maintenant.add(const Duration(minutes: 9));
      await p.nonLus();
      expect(
        appels.where((String f) => f == 'com_non_lus_par_objet'),
        hasLength(1),
      );
      maintenant = maintenant.add(const Duration(minutes: 2));
      expect(await p.nonLus(), isEmpty);
      expect(
        appels.where((String f) => f == 'com_non_lus_par_objet'),
        hasLength(2),
      );
    },
  );
}
