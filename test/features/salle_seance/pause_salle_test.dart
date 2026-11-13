// LIVE-PAUSE-01 : la pause dans la ligne du chrono de la salle.
//
// Ce que le test garde : « Pause dans N min », « Pause, reprise a HH:MM »,
// « Pause prise » ; la commande n'existe que si la capacite est lue
// (`peutPiloter`) et fournie ; le temps ecoule du chrono decompte la pause et
// le temps restant ne la retire pas ; rien en Interface guidee, ni sans
// chrono, ni sans pause ; 320 a 1440 px, texte x2, fr et ar, clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart'
    show TeteSalleBornee;
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../support/demo/seance_demo.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 12, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 45)),
);

class _Horloge {
  _Horloge(this.maintenant);
  DateTime maintenant;
  DateTime lire() => maintenant;
}

PauseSeance _programmee({bool pilote = true, int dans = 5, int duree = 10}) =>
    PauseSeance(
      statut: StatutPause.programmee,
      dureePrevueMinutes: duree,
      debutPrevuUtc: _t0.add(Duration(minutes: 20 + dans)),
      peutPiloter: pilote,
    );

PauseSeance _enCours({bool pilote = true}) => PauseSeance(
  statut: StatutPause.enCours,
  dureePrevueMinutes: 10,
  debutUtc: _t0.add(const Duration(minutes: 20)),
  peutPiloter: pilote,
);

PauseSeance _prise() => PauseSeance(
  statut: StatutPause.prise,
  dureePrevueMinutes: 10,
  debutUtc: _t0.add(const Duration(minutes: 20)),
  finUtc: _t0.add(const Duration(minutes: 30)),
  peutPiloter: true,
);

String _hhmm(DateTime utc) {
  final DateTime l = utc.toLocal();
  String deux(int n) => n.toString().padLeft(2, '0');
  return '${deux(l.hour)}:${deux(l.minute)}';
}

Future<void> _poser(
  WidgetTester tester,
  _Horloge horloge,
  PauseSeance? pause, {
  RoleSeance role = RoleSeance.enseignant,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  VoidCallback? onPause,
  BornesChrono? bornes,
  bool attendre = true,
  String? echecPause,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final VueSeance vue = DonneesSeanceDemo.vue(
    role,
    EtatDemoSalle.repos,
  ).copyWith(chrono: bornes ?? _bornes, pause: pause, echecPause: echecPause);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horlogeChronoProvider.overrideWithValue(horloge.lire),
      ],
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp(
            theme: AppTheme.pour(
              role == RoleSeance.guidee
                  ? InterfaceMode.enfant
                  : InterfaceMode.standard,
              luminosite,
            ),
            home: Material(
              child: Align(
                alignment: Alignment.topCenter,
                child: TeteSalleBornee(
                  children: <Widget>[
                    ChromeSeance(
                      vue: vue,
                      actions: ActionsSeance(
                        onRetour: () {},
                        onQuitter: () {},
                        onNotifications: () {},
                        onReglages: () {},
                        onCompte: () {},
                        onPause: onPause,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (attendre) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Ce que la capsule donne a lire (CHRONO-ETAT, 11/11/2026).
String _chrono(WidgetTester tester) {
  final ChronoVivant c = tester.widget<ChronoVivant>(find.byType(ChronoVivant));
  return c.chrono.prevuEcoule
      ? c.libelleFini
      : ChronoVivant.chiffresDe(c.chrono);
}

String _pause(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ChronoSalle.clePause)).data!;

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('programmee : « Pause dans 5 min », puis 4, puis « prevue »', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 20)));
    await _poser(tester, h, _programmee());
    expect(_pause(tester), contains('Pause dans'));
    expect(_pause(tester), contains('5'));
    h.maintenant = _t0.add(const Duration(minutes: 21));
    await tester.pump(const Duration(seconds: 1));
    expect(_pause(tester), contains('4'));
    h.maintenant = _t0.add(const Duration(minutes: 25));
    await tester.pump(const Duration(seconds: 1));
    expect(_pause(tester), 'Pause prévue');
  });

  testWidgets(
    'en cours : « Pause, reprise dans 8 min » (DYNAMIQUE-CHRONO-2), l heure '
    'exacte lue ; la fin prevue ne bouge pas',
    (WidgetTester tester) async {
      final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 22)));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _poser(tester, h, _enCours());
      expect(_pause(tester), 'Pause, reprise dans 8\u00a0min');
      // L'heure exacte de reprise reste lue par le lecteur d'ecran.
      expect(
        tester.getSemantics(find.byKey(ChronoSalle.cleAnnoncePause)).label,
        contains(_hhmm(_t0.add(const Duration(minutes: 30)))),
      );
      semantique.dispose();
      // CHRONO-ETAT : le chrono ne montre que ce qui reste, et la pause ne
      // repousse pas la fin prevue.
      expect(_chrono(tester), '23:00');
      h.maintenant = _t0.add(const Duration(minutes: 27));
      await tester.pump(const Duration(seconds: 1));
      expect(_chrono(tester), '18:00');
    },
  );

  testWidgets('prise : « Pause prise », la fin prevue reste fixe', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 35)));
    await _poser(tester, h, _prise());
    expect(_pause(tester), 'Pause prise');
    expect(_chrono(tester), '10:00', reason: 'fin prevue fixe');
  });

  testWidgets('la commande suit la capacite lue, jamais le role', (
    WidgetTester tester,
  ) async {
    int appels = 0;
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 20)));
    // Capacite lue + commande fournie : « Demarrer la pause ».
    await _poser(tester, h, _programmee(), onPause: () => appels++);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
    expect(find.text('Démarrer la pause'), findsOneWidget);
    await tester.tap(find.byKey(ChronoSalle.cleCommandePause));
    expect(appels, 1);
    // En cours : « Terminer la pause ».
    await _poser(tester, h, _enCours(), onPause: () => appels++);
    expect(find.text('Terminer la pause'), findsOneWidget);
    // Sans capacite lue : aucune commande (jamais grisee), meme fournie.
    await _poser(
      tester,
      h,
      _programmee(pilote: false),
      onPause: () => appels++,
    );
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
    // Capacite lue mais commande non fournie (l'eleve) : rien non plus.
    await _poser(tester, h, _programmee(), role: RoleSeance.eleve);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
    expect(find.byKey(ChronoSalle.clePause), findsOneWidget);
    // Pause prise : plus de commande.
    await _poser(tester, h, _prise(), onPause: () => appels++);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
  });

  testWidgets('rien sans pause, sans chrono, ni en Interface guidee', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 20)));
    await _poser(tester, h, null);
    expect(find.byKey(ChronoSalle.clePause), findsNothing);
    await _poser(tester, h, const PauseSeance.nonPrevue());
    expect(find.byKey(ChronoSalle.clePause), findsNothing);
    await _poser(
      tester,
      h,
      const PauseSeance(
        statut: StatutPause.nonPrise,
        dureePrevueMinutes: 10,
        peutPiloter: true,
      ),
    );
    expect(find.byKey(ChronoSalle.clePause), findsNothing);
    await _poser(tester, h, _programmee(), role: RoleSeance.guidee);
    expect(find.byKey(ChronoSalle.cleTexte), findsNothing);
    expect(find.byKey(ChronoSalle.clePause), findsNothing);
  });

  testWidgets('temps prevu ecoule : plus de pause ni de commande', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 50)));
    await _poser(tester, h, _programmee(), onPause: () {});
    expect(find.byKey(ChronoSalle.clePause), findsNothing);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
    expect(_chrono(tester), 'Temps prévu écoulé');
  });

  testWidgets('lecteur d\'ecran : la pause est annoncee, la commande se lit', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 22)));
    await _poser(tester, h, _enCours(), onPause: () {});
    expect(
      tester.getSemantics(find.byKey(ChronoSalle.cleAnnoncePause)).label,
      contains('Pause en cours'),
    );
    expect(find.bySemanticsLabel('Terminer la pause'), findsWidgets);
    poignee.dispose();
  });

  testWidgets('jamais une preuve de presence', (WidgetTester tester) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 22)));
    await _poser(tester, h, _enCours(), onPause: () {});
    final String tout =
        '${_chrono(tester)} ${_pause(tester)} '
                '${tester.getSemantics(find.byKey(ChronoSalle.cleAnnoncePause)).label}'
            .toLowerCase();
    for (final String mot in <String>['présen', 'present', 'assidu', 'absen']) {
      expect(tout, isNot(contains(mot)));
    }
    poignee.dispose();
  });

  for (final Size taille in <Size>[
    const Size(320, 700),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness lum in Brightness.values) {
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          testWidgets(
            '${taille.width.toInt()} px, x${echelle.toInt()}, ${lum.name}, '
            '${langue.languageCode} : pause et commande sans debordement',
            (WidgetTester tester) async {
              await tester.runAsync(() => LocaleSettings.setLocale(langue));
              final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 22)));
              await _poser(
                tester,
                h,
                _enCours(),
                taille: taille,
                echelle: echelle,
                luminosite: lum,
                onPause: () {},
              );
              expect(tester.takeException(), isNull);
              for (final Key cle in <Key>[
                ChronoSalle.cleTexte,
                ChronoSalle.clePause,
                ChronoSalle.cleCommandePause,
              ]) {
                final Rect r = tester.getRect(find.byKey(cle));
                expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
                expect(r.left, greaterThanOrEqualTo(-0.5));
              }
            },
          );
        }
      }
    }
  }

  testWidgets('N3 : un geste sur la pause non confirme se dit sous la ligne '
      '(K-59), a 320 et 1440, texte x2', (WidgetTester tester) async {
    for (final Size taille in <Size>[
      const Size(320, 800),
      const Size(1440, 900),
    ]) {
      final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 22)));
      await _poser(
        tester,
        h,
        _enCours(),
        taille: taille,
        echelle: 2,
        onPause: () {},
        echecPause: t.salle.seance.pause.echec,
      );
      expect(find.byKey(ChronoSalle.cleEchecPause), findsOneWidget);
      expect(find.text(t.salle.seance.pause.echec), findsOneWidget);
      expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('N3 : sans echec, aucune phrase', (WidgetTester tester) async {
    await _poser(
      tester,
      _Horloge(_t0.add(const Duration(minutes: 22))),
      _enCours(),
      onPause: () {},
    );
    expect(find.byKey(ChronoSalle.cleEchecPause), findsNothing);
  });
}
