// CALENDRIER-ET-PAUSES (lot 2) x SOCLE-PROGRAMME (lot 1), arbitrage du 13/11/2026 :
// l'enfant de 6 a 9 ans ne voit AUCUNE date ni duree sur la carte du suivi, y
// compris quand une fermeture de l'ecole ou une pause du lot 2 est en cours, donc
// quand la lecture de l'etape porte un recul en jours (`recul_jours`) sur la date
// limite. Le serveur masque ces champs pour lui (scenario 28 de
// scenarios_calendrier_pauses.sql) ; l'ecran, lui, ne doit rien afficher meme si
// la reponse les portait (lue avec le jeton du tuteur) : la decision vient du seul
// drapeau `eleve_voit_dates`, jamais de la presence d'une date.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/suivi/ma_progression.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// La reponse de `ma_progression` d'un eleve a l'etape 2 pendant une fermeture de
/// 20 jours et une pause acceptee : la date limite est reculee de 20 jours.
/// [masquee] : telle que le serveur la rend a l'enfant de 6 a 9 ans.
Map<String, Object?> _reponseEnFermeture({required bool masquee}) {
  int? n(int v) => masquee ? null : v;
  String? d(String v) => masquee ? null : v;
  return <String, Object?>{
    'eleve_voit_dates': false,
    'etape': <String, Object?>{
      'code': 'BASES-2',
      'ordre': 2,
      'nom': 'Lire avec les voyelles',
      'cycle': 'Les bases',
      'objectifs': <Object?>['Lit le tanwin'],
      'duree_prevue_semaines': n(11),
      'date_limite_semaines': n(14),
      'entree_le': d('2026-10-01'),
      'date_limite': d('2027-01-27'),
      'recul_jours': n(20),
      'semaines_ecoulees': n(6),
      'rythme': masquee ? null : 'dans_les_temps',
      'page_reprise': 12,
    },
    'niveau': <String, Object?>{
      'code': 'bases',
      'nom': 'Les bases',
      'cohorte': 'enfant_6_9',
      'duree_prevue_semaines': n(28),
      'date_limite_semaines': n(36),
      'entree_le': d('2026-09-01'),
      'horizon': d('2027-05-26'),
      'date_limite_visible': !masquee,
    },
    'etapes_du_cycle': <Object?>[],
    'sourates': <String, Object?>{'sourates_validees': 3, 'sourates_total': 17},
    'reglage': null,
  };
}

class _Port implements PortMaProgression {
  _Port(this.brut);
  final Object? brut;

  @override
  Future<MaProgression?> pourEleve(String eleveId) async =>
      MaProgression.depuisJson(brut);
}

Future<void> _monter(
  WidgetTester tester,
  Map<String, Object?> brut,
  InterfaceMode mode,
) async {
  await monterRouteur(
    tester,
    Routes.eleveSuivi,
    source: FausseSourceSession(sessionActive(AppRole.student, mode: mode)),
    interface: mode,
    taille: const Size(390, 3200),
    surcharges: <Override>[
      portMaProgressionProvider.overrideWithValue(_Port(brut)),
      horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(false)),
    ],
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void _aucuneDateNiDuree(WidgetTester tester) {
  final s = t.suiviPedagogique;
  expect(find.text(s.aFinirAvant), findsNothing);
  expect(find.text(s.horizonNiveau(niveau: 'Les bases')), findsNothing);
  expect(find.text(s.rythme), findsNothing);
  expect(find.text(s.dureePrevue), findsNothing);
  expect(find.text(s.depuis), findsNothing);
  expect(find.textContaining('semaines'), findsNothing);
  // Le recul de la fermeture ou de la pause ne se dit pas non plus.
  expect(find.textContaining('20 jours'), findsNothing);
  expect(find.textContaining(RegExp(r'\b(19|20)\d\d\b')), findsNothing);
  for (final String mois in t.commun.dates.mois) {
    expect(find.textContaining(RegExp('\\d{1,2}[\\s ]+$mois')), findsNothing);
  }
}

void main() {
  group('Enfant de 6 a 9 ans, fermeture ou pause du lot 2 en cours', () {
    for (final InterfaceMode mode in <InterfaceMode>[
      InterfaceMode.standard,
      InterfaceMode.enfant,
    ]) {
      testWidgets('reponse masquee par le serveur, $mode : l etape, aucune '
          'date ni duree', (WidgetTester tester) async {
        await _monter(tester, _reponseEnFermeture(masquee: true), mode);
        expect(find.byType(SuiviElevePage), findsOneWidget);
        expect(find.text('Lire avec les voyelles'), findsWidgets);
        _aucuneDateNiDuree(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('reponse NON masquee (recul de 20 jours, dates, durees dans '
          'la reponse), $mode : toujours aucune date ni duree, sur le seul '
          'drapeau eleve_voit_dates', (WidgetTester tester) async {
        await _monter(tester, _reponseEnFermeture(masquee: false), mode);
        expect(find.text('Lire avec les voyelles'), findsWidgets);
        _aucuneDateNiDuree(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
