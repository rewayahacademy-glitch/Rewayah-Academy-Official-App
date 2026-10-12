// LIVE-PAUSE-01 : le recapitulatif de fin de seance de l'enseignant dit si la
// pause a ete prise ou non ; rien quand aucune pause n'etait prevue.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void _rien() {}
void _aller(String _) {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onNaviguer: _aller,
);

const Key _ligne = ValueKey<String>('fin-recapitulatif-pause');
final DateTime _t0 = DateTime.utc(2026, 10, 12, 18);

Future<void> _monter(WidgetTester tester, PauseSeance? pause) async {
  fixerVueCapture(tester, const Size(390, 844), 1);
  VueSeance vue = DonneesSeanceDemo.vue(
    RoleSeance.enseignant,
    EtatDemoSalle.fin,
  );
  if (pause != null) vue = vue.copyWith(pause: pause);
  await tester.pumpWidget(
    hoteCapture(
      FinSeanceEnseignant(
        vue: vue,
        actions: _actions,
        onOuvrirCahier: _rien,
        onRevenirJournee: _rien,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _texte(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(_ligne), matching: find.byType(Text)),
    )
    .map(
      (Text t) => (t.data ?? '')
          .replaceAll(RegExp('[\u2066-\u2069]'), '')
          .replaceAll(' ', ' '),
    )
    .join('|');

void main() {
  testWidgets('aucune pause prevue : aucune ligne', (
    WidgetTester tester,
  ) async {
    await _monter(tester, null);
    expect(find.byKey(_ligne), findsNothing);
    await _monter(tester, const PauseSeance.nonPrevue());
    expect(find.byKey(_ligne), findsNothing);
  });

  testWidgets('pause prise : la duree reelle', (WidgetTester tester) async {
    await _monter(
      tester,
      PauseSeance(
        statut: StatutPause.prise,
        dureePrevueMinutes: 10,
        debutUtc: _t0.add(const Duration(minutes: 20)),
        finUtc: _t0.add(const Duration(minutes: 31)),
      ),
    );
    expect(_texte(tester), 'Pause|Pause prise, 11 min');
  });

  for (final StatutPause s in <StatutPause>[
    StatutPause.programmee,
    StatutPause.nonPrise,
  ]) {
    testWidgets('${s.name} a la fin : non prise', (WidgetTester tester) async {
      await _monter(tester, PauseSeance(statut: s, dureePrevueMinutes: 10));
      expect(_texte(tester), 'Pause|Pause prévue, non prise');
    });
  }
}
