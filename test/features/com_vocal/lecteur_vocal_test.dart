// COM-VOC-1 : le lecteur d'un vocal (spec section 11.2, etats 14 a 17 ;
// section 24). Chaque etat se dit en mots, la position s'ecrit en toutes
// lettres, l'action change de sens sans jamais se griser ; la lecture n'est
// ouverte qu'au toucher ; port neutre : une phrase, aucun bouton ; echec :
// « Reessayer ».

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/port_pieces_jointes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';

import '../../support/hote_theme.dart';
import 'support_vocal.dart';

const Duration _duree = Duration(seconds: 28);

/// Une lecture dont l'etat est pose par le test (lecture interrompue).
class _LectureManuelle implements LectureVocale {
  final ValueNotifier<EtatLectureAudio> notifiant =
      ValueNotifier<EtatLectureAudio>(const EtatLectureAudio());
  int lectures = 0;

  @override
  Duration get duree => _duree;

  @override
  ValueListenable<EtatLectureAudio> get etat => notifiant;

  @override
  Future<void> lire() async {
    lectures++;
    notifiant.value = const EtatLectureAudio(enLecture: true);
  }

  @override
  Future<void> mettreEnPause() async {}

  @override
  Future<void> relire() => lire();

  @override
  Future<void> liberer() async {}
}

/// Un lecteur `just_audio` sans plateforme : `play` echoue (source expiree),
/// `dispose` est compte.
class _LecteurSansPlateforme extends AudioPlayer {
  final Completer<void> lecture = Completer<void>();
  int liberations = 0;
  int lancements = 0;

  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.ready);

  @override
  Duration get position => Duration.zero;

  @override
  Stream<Duration> get positionStream => const Stream<Duration>.empty();

  @override
  Stream<PlayerState> get playerStateStream =>
      const Stream<PlayerState>.empty();

  @override
  Future<void> play() {
    lancements++;
    return lecture.future;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> dispose() async => liberations++;
}

Future<void> _monter(
  WidgetTester tester,
  Future<LectureVocale> Function() ouvrir, {
  Size taille = vueMobile,
  double echelle = 1,
  String? auteur = 'Mme Mariam',
}) async {
  fixerVue(tester, taille);
  await tester.pumpWidget(
    hoteTheme(
      LecteurVocal(ouvrir: ouvrir, duree: _duree, auteur: auteur),
      echelleTexte: echelle,
    ),
  );
  await tester.pump();
}

Future<void> _agir(WidgetTester tester) async {
  await tester.tap(find.byKey(LecteurVocal.cleAction));
  await tester.pump();
  await tester.pump();
}

String _libelleAction(WidgetTester tester) {
  final Finder textes = find.descendant(
    of: find.byKey(LecteurVocal.cleAction),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(textes.first).data!;
}

void main() {
  final l = t.com.vocal.lecteur;

  testWidgets('14 a 17 : recu, lecture, pause, fin, reecoute', (
    WidgetTester tester,
  ) async {
    final HorlogeManuelle horloge = HorlogeManuelle();
    int ouvertures = 0;
    await _monter(tester, () async {
      ouvertures++;
      return LectureVocaleSimulee(duree: _duree, horloge: horloge.horloge);
    });
    // 14. Recu : rien n'est ouvert avant le toucher.
    expect(ouvertures, 0);
    expect(find.text(l.nonEcoute), findsOneWidget);
    expect(
      find.text(l.position(position: '0:00', duree: '0:28')),
      findsOneWidget,
    );
    expect(_libelleAction(tester), l.ecouter);

    // 15. Lecture.
    await _agir(tester);
    expect(ouvertures, 1);
    expect(find.text(l.lecture), findsOneWidget);
    expect(_libelleAction(tester), l.pause);
    await avancer(tester, horloge, const Duration(seconds: 10));
    expect(
      find.text(l.position(position: '0:10', duree: '0:28')),
      findsOneWidget,
    );

    // 16. Pause : la position est gardee.
    await _agir(tester);
    expect(find.text(l.enPause), findsOneWidget);
    expect(_libelleAction(tester), l.reprendre);
    await avancer(tester, horloge, const Duration(seconds: 30));
    expect(
      find.text(l.position(position: '0:10', duree: '0:28')),
      findsOneWidget,
    );

    // 17. Fin.
    await _agir(tester);
    await avancer(tester, horloge, const Duration(seconds: 18));
    expect(find.text(l.fin), findsOneWidget);
    expect(
      find.text(l.position(position: '0:28', duree: '0:28')),
      findsOneWidget,
    );
    expect(_libelleAction(tester), l.reecouter);

    // Reecouter repart du debut, sans rouvrir.
    await _agir(tester);
    expect(find.text(l.lecture), findsOneWidget);
    expect(
      find.text(l.position(position: '0:00', duree: '0:28')),
      findsOneWidget,
    );
    expect(ouvertures, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lecteur d ecran : auteur et duree dits, barre decorative', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    final HorlogeManuelle horloge = HorlogeManuelle();
    await _monter(
      tester,
      () async => LectureVocaleSimulee(duree: _duree, horloge: horloge.horloge),
    );
    expect(
      find.bySemanticsLabel(
        RegExp(
          RegExp.escape(l.libelleAuteur(auteur: 'Mme Mariam', duree: '0:28')),
        ),
      ),
      findsWidgets,
    );
    expect(find.bySemanticsLabel(l.ecouter), findsOneWidget);
    final Finder barre = find.byType(LinearProgressIndicator);
    expect(
      find.ancestor(of: barre, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    semantique.dispose();
  });

  testWidgets('port neutre : phrase, aucun bouton', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      () => const LectureVocaleIndisponible().ouvrir(vocalRecuDemo),
    );
    await _agir(tester);
    expect(find.text(l.indisponible), findsOneWidget);
    expect(find.byKey(LecteurVocal.cleAction), findsNothing);
  });

  testWidgets('echec d ouverture : Reessayer, puis lecture', (
    WidgetTester tester,
  ) async {
    final HorlogeManuelle horloge = HorlogeManuelle();
    int essais = 0;
    await _monter(tester, () async {
      essais++;
      if (essais == 1) throw StateError('reseau');
      return LectureVocaleSimulee(duree: _duree, horloge: horloge.horloge);
    });
    await _agir(tester);
    expect(find.text(l.erreurLectureTitre), findsOneWidget);
    expect(_libelleAction(tester), l.erreurLectureAction);
    await _agir(tester);
    expect(find.text(l.erreurLectureTitre), findsNothing);
    expect(find.text(l.lecture), findsOneWidget);
  });

  testWidgets('la capacite manquante n est pas un echec', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      () =>
          Future<LectureVocale>.error(const CapaciteIndisponible('COM-BR-03')),
    );
    await _agir(tester);
    expect(find.text(l.erreurLectureTitre), findsNothing);
    expect(find.text(l.indisponible), findsOneWidget);
  });

  testWidgets('320 en texte x2 : rien ne deborde', (WidgetTester tester) async {
    final HorlogeManuelle horloge = HorlogeManuelle();
    await _monter(
      tester,
      () async => LectureVocaleSimulee(duree: _duree, horloge: horloge.horloge),
      taille: const Size(320, 800),
      echelle: 2,
    );
    await _agir(tester);
    expect(tester.takeException(), isNull);
    final Rect r = tester.getRect(find.byKey(LecteurVocal.cleAction));
    expect(r.right, lessThanOrEqualTo(320));
  });

  testWidgets('liberee a la fermeture', (WidgetTester tester) async {
    final HorlogeManuelle horloge = HorlogeManuelle();
    final LectureVocaleSimulee lecture = LectureVocaleSimulee(
      duree: _duree,
      horloge: horloge.horloge,
    );
    await _monter(tester, () async => lecture);
    await _agir(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    // Liberee : plus aucune minuterie en attente, lire() ne fait plus rien.
    await lecture.lire();
    await tester.pump(const Duration(seconds: 30));
  });

  group('LecteurVocalRecu, branche sur PortLectureVocale', () {
    Future<void> monterRecu(
      WidgetTester tester,
      PieceJointe vocal, {
      PortLectureVocale? port,
    }) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          LecteurVocalRecu(vocal: vocal, auteur: 'Mme Mariam'),
          surcharges: <Override>[
            if (port != null) portLectureVocaleProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pump();
    }

    testWidgets('port neutre de production : indisponible au toucher', (
      WidgetTester tester,
    ) async {
      await monterRecu(tester, vocalRecuDemo);
      expect(
        find.text(l.position(position: '0:00', duree: '0:28')),
        findsOneWidget,
      );
      await _agir(tester);
      expect(find.text(l.indisponible), findsOneWidget);
      expect(find.byKey(LecteurVocal.cleAction), findsNothing);
    });

    testWidgets('port de demonstration : la lecture part', (
      WidgetTester tester,
    ) async {
      final HorlogeManuelle horloge = HorlogeManuelle();
      await monterRecu(
        tester,
        vocalRecuDemo,
        port: LecturesVocalesDemonstration(horloge: horloge.horloge),
      );
      await _agir(tester);
      expect(find.text(l.lecture), findsOneWidget);
    });

    testWidgets('piece non ouvrable : la phrase, aucun bouton', (
      WidgetTester tester,
    ) async {
      final PieceJointe ferme = PieceJointe(
        reference: ReferencePieceJointe('vocal_ferme'),
        nom: 'vocal.m4a',
        nature: NaturePieceJointe.vocal,
        typeLisible: 'Audio',
        duree: _duree,
      );
      await monterRecu(tester, ferme);
      expect(find.text(l.indisponible), findsOneWidget);
      expect(find.byKey(LecteurVocal.cleAction), findsNothing);
    });
  });

  testWidgets(
    'lecture interrompue apres son lancement : la phrase, Reessayer',
    (WidgetTester tester) async {
      final _LectureManuelle lecture = _LectureManuelle();
      await _monter(tester, () async => lecture);
      await _agir(tester);
      expect(find.text(l.lecture), findsOneWidget);
      lecture.notifiant.value = const EtatLectureAudio(echec: true);
      await tester.pump();
      expect(find.text(l.erreurLectureTitre), findsOneWidget);
      expect(_libelleAction(tester), l.erreurLectureAction);
      await _agir(tester);
      expect(lecture.lectures, 2);
      expect(find.text(l.erreurLectureTitre), findsNothing);
      expect(find.text(l.lecture), findsOneWidget);
    },
  );

  group('LectureVocaleJustAudio', () {
    test(
      'play qui echoue : l echec passe dans l etat, rien de non gere',
      () async {
        final _LecteurSansPlateforme lecteur = _LecteurSansPlateforme();
        final LectureVocaleJustAudio lecture =
            LectureVocaleJustAudio.surLecteur(lecteur, duree: _duree);
        await lecture.lire();
        expect(lecteur.lancements, 1);
        expect(lecture.etat.value.echec, isFalse);
        lecteur.lecture.completeError(StateError('source expiree'));
        await Future<void>.delayed(Duration.zero);
        expect(lecture.etat.value.echec, isTrue);
        expect(lecture.etat.value.enLecture, isFalse);
        await lecture.liberer();
      },
    );

    test('liberer deux fois ne leve rien et ne libere qu une fois', () async {
      final _LecteurSansPlateforme lecteur = _LecteurSansPlateforme();
      final LectureVocaleJustAudio lecture = LectureVocaleJustAudio.surLecteur(
        lecteur,
        duree: _duree,
      );
      await lecture.liberer();
      await lecture.liberer();
      expect(lecteur.liberations, 1);
    });

    test('un echec arrive apres la liberation ne touche plus l etat', () async {
      final _LecteurSansPlateforme lecteur = _LecteurSansPlateforme();
      final LectureVocaleJustAudio lecture = LectureVocaleJustAudio.surLecteur(
        lecteur,
        duree: _duree,
      );
      await lecture.lire();
      await lecture.liberer();
      lecteur.lecture.completeError(StateError('reseau perdu'));
      await Future<void>.delayed(Duration.zero);
      expect(lecteur.liberations, 1);
    });
  });
}
