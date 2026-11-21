// CHIFFRES-ACADEMIE : la page « Les chiffres de l'academie ».
// Etats, regles des pastilles, lecture du serveur, legerete (aucune trame
// une fois la page posee), une seule zone de defilement.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_chiffres_academie.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/vivant/nombre_rouleaux.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_chiffres/chiffres_academie_page.dart';
import 'package:rewayah_academy/features/admin_chiffres/dessins_chiffres.dart';

import '../../support/harnais.dart';

ChiffresAcademie _chiffres({
  int recus = 608,
  int aujourdhui = 8,
  int septJours = 125,
  int septJoursAvant = 483,
  int pays = 35,
  int familles = 24,
}) => ChiffresAcademie(
  genereLe: DateTime(2026, 11, 21, 9, 42),
  candidatsRecus: recus,
  candidatsAujourdhui: aujourdhui,
  candidatsSeptJours: septJours,
  candidatsSeptJoursAvant: septJoursAvant,
  candidatsParJour: const <int>[239, 191, 57, 19, 21, 8, 8],
  pays: pays,
  hommes: 493,
  femmes: 115,
  repondants: 512,
  coranEntier: 376,
  juzMin: 11959,
  ijaza: 253,
  riwayat: 20,
  langues: 18,
  enseignants: 4,
  eleves: 28,
  elevesEnClasse: 5,
  familles: familles,
  classes: 4,
  languesCours: 6,
  seancesTenues: 21,
  seancesMinutes: 1590,
  seancesSeptJours: 3,
  seancesSeptJoursAvant: 2,
);

class _Port implements PortChiffresAcademie {
  _Port(this.reponses);

  /// Une reponse par lecture ; la derniere se repete.
  final List<Object> reponses;
  int lectures = 0;

  @override
  Future<ChiffresAcademie> lire() async {
    final Object r = reponses[lectures.clamp(0, reponses.length - 1)];
    lectures++;
    if (r is ChiffresAcademie) return r;
    // ignore: only_throw_errors, le test rejoue l'echec tel quel.
    throw r;
  }
}

Future<void> _monter(
  WidgetTester tester,
  PortChiffresAcademie? port, {
  Size taille = const Size(1440, 2000),
  bool horsLigne = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const ChiffresAcademiePage(),
      surcharges: [
        portChiffresAcademieProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith((ref) => Stream<bool>.value(horsLigne)),
      ],
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('regles pures', () {
    test('tendance : nulle sans base de comparaison ou sans ecart', () {
      expect(tendancePourcent(608, 0), isNull);
      expect(tendancePourcent(10, 10), isNull);
      expect(tendancePourcent(125, 483), -74);
      expect(tendancePourcent(3, 2), 50);
    });

    test('« +n » : jamais le total lui-meme, jamais zero', () {
      expect(plusUtile(608, 608), isFalse);
      expect(plusUtile(0, 608), isFalse);
      expect(plusUtile(8, 608), isTrue);
    });

    test('la reponse du serveur se lit, et tolere un champ absent', () {
      final ChiffresAcademie c = ChiffresAcademie.json(const <String, dynamic>{
        'genere_le': '2026-11-21T06:42:00+00:00',
        'memorise_le': '2026-11-21T06:40:00+00:00',
        'candidats': <String, dynamic>{
          'recus': 608,
          'aujourd_hui': 8,
          'sept_jours': 125,
          'sept_jours_avant': 483,
          'par_jour': <int>[1, 2, 3, 4, 5, 6, 7],
          'pays': 35,
          'hommes': 493,
          'femmes': 115,
        },
        'declarations': <String, dynamic>{'juz_min': 11959, 'riwayat': 20},
        'academie': <String, dynamic>{'classes': 4},
      });
      expect(c.candidatsRecus, 608);
      expect(c.candidatsParJour, <int>[1, 2, 3, 4, 5, 6, 7]);
      expect(c.juzMin, 11959);
      expect(c.coranEntier, 0);
      expect(c.seancesTenues, 0);
      expect(c.classes, 4);
      expect(c.estVide, isFalse);
      expect(ChiffresAcademie.json(const <String, dynamic>{}).estVide, isTrue);
    });
  });

  testWidgets('contenu : chaque chiffre, sa phrase, ses dessins', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(<Object>[_chiffres()]));
    final l = t.admin.chiffres;
    for (final String cle in <String>[
      'candidats',
      'pays',
      'coran',
      'juz',
      'riwayat',
      'ijaza',
      'langues',
      'genre',
      'enseignants',
      'eleves',
      'familles',
      'classes',
      'seances',
    ]) {
      expect(
        find.byKey(ValueKey<String>('chiffres-carte-$cle')),
        findsOneWidget,
        reason: cle,
      );
    }
    expect(find.text('608'), findsOneWidget);
    expect(find.text('11959'), findsOneWidget);
    expect(find.text(l.auMoins), findsOneWidget);
    expect(find.text(l.declarations), findsNWidgets(2));
    expect(find.text(l.aJour(heure: '09:42')), findsOneWidget);
    // Aucune phrase ne repete le chiffre ecrit au-dessus d'elle.
    expect(l.candidats.contains('608'), isFalse);
    expect(l.pays.contains('35'), isFalse);
    // Un point par pays, un point par famille.
    final Iterable<PeintrePoints> points = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((CustomPaint c) => c.painter)
        .whereType<PeintrePoints>();
    expect(
      points.map((PeintrePoints p) => p.n),
      containsAll(<int>[35, 18, 24]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pastilles : ni le total, ni une tendance sans base', (
    WidgetTester tester,
  ) async {
    // Tout est arrive cette semaine, rien la semaine d'avant.
    await _monter(
      tester,
      _Port(<Object>[
        _chiffres(septJours: 608, septJoursAvant: 0, aujourdhui: 0),
      ]),
    );
    final Finder carte = find.byKey(
      const ValueKey<String>('chiffres-carte-candidats'),
    );
    expect(
      find.descendant(of: carte, matching: find.byType(StatusPill)),
      findsNothing,
    );
  });

  testWidgets('pastilles : baisse dite en mots et en signe', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(<Object>[_chiffres()]));
    final l = t.admin.chiffres;
    expect(find.text(l.plusAujourdhui(n: 8)), findsOneWidget);
    expect(find.text(l.plusSeptJours(n: 125)), findsOneWidget);
    expect(
      find.text(l.baisseSeptJours(part: l.pourcent(n: 74))),
      findsOneWidget,
    );
    expect(
      find.text(l.hausseSeptJours(part: l.pourcent(n: 50))),
      findsOneWidget,
    );
  });

  testWidgets('au-dela de 60, pas de points (jamais une proportion)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(<Object>[_chiffres(familles: 400)]));
    final Finder carte = find.byKey(
      const ValueKey<String>('chiffres-carte-familles'),
    );
    expect(
      find.descendant(of: carte, matching: find.byType(CustomPaint)),
      findsNothing,
    );
    expect(find.text('400'), findsOneWidget);
  });

  testWidgets('legerete : page posee, plus aucune trame ; une lecture par '
      'minute ; un chiffre qui change tourne une fois puis se tait', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(<Object>[
      _chiffres(),
      _chiffres(),
      _chiffres(recus: 609, aujourdhui: 9, septJours: 126),
    ]);
    await _monter(tester, port);
    await tester.pump(const Duration(seconds: 2));
    expect(port.lectures, 1);
    expect(
      SchedulerBinding.instance.hasScheduledFrame,
      isFalse,
      reason: 'page immobile : aucune trame demandee',
    );
    expect(SchedulerBinding.instance.transientCallbackCount, 0);

    // 59 secondes : rien. La minute : une lecture, memes chiffres, et
    // toujours aucune animation.
    await tester.pump(const Duration(seconds: 55));
    expect(port.lectures, 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(port.lectures, 2);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);

    // La minute suivante : un chiffre change, il tourne, puis tout se tait.
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(port.lectures, 3);
    expect(find.text('609'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    expect(find.byType(NombreRouleaux), findsWidgets);
  });

  testWidgets('onglet cache : aucune lecture ; au retour : tout de suite', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(<Object>[_chiffres()]);
    await _monter(tester, port);
    expect(port.lectures, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(minutes: 30));
    expect(port.lectures, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(port.lectures, 2);
    await tester.pump(const Duration(seconds: 30));
    expect(port.lectures, 2);
  });

  testWidgets('une seule zone de defilement : la page', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      _Port(<Object>[_chiffres()]),
      taille: const Size(390, 844),
    );
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vide', (WidgetTester tester) async {
    await _monter(
      tester,
      _Port(<Object>[ChiffresAcademie.json(const <String, dynamic>{})]),
    );
    expect(find.byKey(const ValueKey<String>('chiffres-vide')), findsOneWidget);
  });

  testWidgets('erreur, puis « Reessayer » relit', (WidgetTester tester) async {
    final _Port port = _Port(<Object>[StateError('panne'), _chiffres()]);
    await _monter(tester, port);
    expect(
      find.byKey(const ValueKey<String>('chiffres-erreur')),
      findsOneWidget,
    );
    expect(find.text(t.admin.chiffres.erreur), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(port.lectures, 2);
    expect(find.text('608'), findsOneWidget);
  });

  testWidgets('hors ligne, rien de lu', (WidgetTester tester) async {
    await _monter(
      tester,
      _Port(<Object>[StateError('reseau')]),
      horsLigne: true,
    );
    expect(
      find.byKey(const ValueKey<String>('chiffres-sans-donnees')),
      findsOneWidget,
    );
  });

  testWidgets('port absent : dit en clair, sans « Reessayer »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, null);
    expect(
      find.byKey(const ValueKey<String>('chiffres-indisponible')),
      findsOneWidget,
    );
    expect(find.text(t.admin.chiffres.indisponibleTitre), findsOneWidget);
  });

  testWidgets('un echec apres une lecture garde les chiffres', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(<Object>[
      _chiffres(),
      const CapaciteIndisponible('x'),
    ]);
    await _monter(tester, port);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(port.lectures, 2);
    expect(find.text('608'), findsOneWidget);
  });

  testWidgets('la section de l\'academie tient a une constante', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(<Object>[_chiffres()]));
    expect(
      find.text(t.admin.chiffres.sectionAcademie),
      sectionAcademieAffichee ? findsOneWidget : findsNothing,
    );
  });
}
