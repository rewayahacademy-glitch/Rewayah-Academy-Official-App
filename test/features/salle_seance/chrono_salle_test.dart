// LIVE-CHRONO-01 : le chrono discret de la salle, avec une horloge factice.
//
// Ce que le test garde : le temps est recalcule depuis les horodatages (tic,
// retour d'arriere-plan, reconnexion), jamais un temps negatif, une annonce de
// lecteur d'ecran par minute, aucune presence suggeree, rien en Interface
// guidee, ni debordement a 320 px texte x2, en arabe, clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_classe_live.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart'
    show TeteSalleBornee;
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

void _rien() {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
);

final DateTime _t0 = DateTime.utc(2026, 10, 12, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 45)),
);

/// L'horloge factice : le test la fait avancer, ou sauter, comme il veut.
class _Horloge {
  _Horloge(this.maintenant);
  DateTime maintenant;
  DateTime lire() => maintenant;
}

Future<void> _poser(
  WidgetTester tester,
  _Horloge horloge, {
  RoleSeance role = RoleSeance.enseignant,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  ConnexionSeance connexion = ConnexionSeance.enLigne,
  BornesChrono? bornes,
  bool attendre = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final VueSeance base = DonneesSeanceDemo.vue(role, EtatDemoSalle.repos);
  final VueSeance vue = base.copyWith(
    chrono: bornes ?? _bornes,
    connexion: connexion,
  );
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
                  children: <Widget>[ChromeSeance(vue: vue, actions: _actions)],
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

String _texte(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ChronoSalle.cleTexte)).data!;

String _annonce(WidgetTester tester) =>
    tester.getSemantics(find.byKey(ChronoSalle.cleAnnonce)).label;

void main() {
  test('la source /tc/classe donne ses horodatages au chrono, rien sinon', () {
    expect(DepuisClasseLive.chronoDe(null), isNull);
    final SessionClockVM horloge = SessionClockVM.depuisFenetre(
      fenetre: FenetreSeance(
        debutUtc: _t0,
        finPrevueUtc: _t0.add(const Duration(minutes: 45)),
        fenetreAcces: const Duration(minutes: 20),
        graceApresFin: const Duration(minutes: 15),
      ),
      maintenantServeurUtc: _t0.add(const Duration(minutes: 5)),
      horlogeUtilisateur: const HorlogeAffichee(
        fuseauIana: 'Europe/Paris',
        libelleVille: 'Paris',
        heureLocaleRendue: '20:05',
        dateLocaleRendue: 'Lundi 12 octobre',
      ),
    );
    final BornesChrono? bornes = DepuisClasseLive.chronoDe(horloge);
    expect(bornes, _bornes);
    expect(bornes!.duree, const Duration(minutes: 45));
  });

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('en cours : temps ecoule et temps restant, au format HH:MM:SS', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(
      _t0.add(const Duration(minutes: 12, seconds: 34)),
    );
    await _poser(tester, h);
    final String texte = _texte(tester);
    expect(texte, contains('00:12:34'));
    expect(texte, contains('00:32:26'));
    expect(texte, contains('écoulé'));
    expect(texte, contains('restant'));
  });

  testWidgets('chaque seconde de l\'horloge se retrouve a l\'ecran', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 1)));
    await _poser(tester, h);
    for (int i = 1; i <= 120; i++) {
      h.maintenant = h.maintenant.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      final Duration ecoule = h.maintenant.difference(_t0);
      expect(
        _texte(tester),
        contains(formaterChrono(ecoule)),
        reason: 'seconde $i',
      );
    }
  });

  testWidgets('derive : un minuteur en retard ne fausse pas le temps', (
    WidgetTester tester,
  ) async {
    // L'horloge avance de trois minutes alors que le minuteur n'a tourne
    // qu'une fois : l'affichage rattrape la verite, il ne compte pas tic a tic.
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 5)));
    await _poser(tester, h);
    h.maintenant = h.maintenant.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(_texte(tester), contains('00:08:00'));
    expect(_texte(tester), contains('00:37:00'));
  });

  testWidgets('retour d\'arriere-plan : recalcul immediat', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 5)));
    await _poser(tester, h);
    expect(_texte(tester), contains('00:05:00'));
    // L'appareil dort 20 minutes : aucun tic n'a eu lieu.
    h.maintenant = h.maintenant.add(const Duration(minutes: 20));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(_texte(tester), contains('00:25:00'));
    expect(_texte(tester), contains('00:20:00'));
  });

  testWidgets('reconnexion : recalcul immediat au retour de la connexion', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 5)));
    await _poser(tester, h, connexion: ConnexionSeance.reconnexion);
    expect(_texte(tester), contains('00:05:00'));
    // La coupure dure sept minutes ; aucun tic n'est passe entre-temps.
    h.maintenant = h.maintenant.add(const Duration(minutes: 7));
    // La connexion revient : meme sans tic, le temps est relu.
    await _poser(tester, h, attendre: false);
    expect(_texte(tester), contains('00:12:00'));
  });

  testWidgets('avant T0 : aucune ligne de chrono', (WidgetTester tester) async {
    final _Horloge h = _Horloge(_t0.subtract(const Duration(minutes: 3)));
    await _poser(tester, h);
    expect(find.byKey(ChronoSalle.cleTexte), findsNothing);
  });

  testWidgets('depassement : « Temps prevu ecoule », jamais negatif', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(
      _t0.add(const Duration(minutes: 44, seconds: 58)),
    );
    await _poser(tester, h);
    expect(_texte(tester), contains('00:00:02'));
    h.maintenant = h.maintenant.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(_texte(tester), 'Temps prévu écoulé');
    h.maintenant = h.maintenant.add(const Duration(hours: 3));
    await tester.pump(const Duration(seconds: 5));
    expect(_texte(tester), 'Temps prévu écoulé');
    expect(_texte(tester), isNot(contains('-')));
    expect(_annonce(tester), 'Temps prévu écoulé.');
  });

  testWidgets('lecteur d\'ecran : une annonce par minute, pas par seconde', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 3)));
    await _poser(tester, h);
    final Set<String> annonces = <String>{_annonce(tester)};
    String? precedent = _annonce(tester);
    int changements = 0;
    for (int i = 0; i < 180; i++) {
      h.maintenant = h.maintenant.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      final String a = _annonce(tester);
      if (a != precedent) {
        changements++;
      }
      precedent = a;
      annonces.add(a);
    }
    expect(changements, 3, reason: 'trois minutes, trois annonces');
    expect(annonces, hasLength(4));
    expect(_annonce(tester), contains('min'));
    // Le texte visible n'est pas lu en plus de l'annonce.
    expect(find.bySemanticsLabel(RegExp(r'\d\d:\d\d:\d\d')), findsNothing);
    poignee.dispose();
  });

  testWidgets('jamais presente comme une presence', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 9)));
    await _poser(tester, h);
    final String tout = '${_texte(tester)} ${_annonce(tester)}'.toLowerCase();
    for (final String mot in <String>[
      'présen',
      'present',
      'assidu',
      'pointage',
    ]) {
      expect(tout, isNot(contains(mot)));
    }
    poignee.dispose();
  });

  testWidgets('l\'eleve en interface standard le voit, la guidee non', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(_t0.add(const Duration(minutes: 9)));
    await _poser(tester, h, role: RoleSeance.eleve);
    expect(find.byKey(ChronoSalle.cleTexte), findsOneWidget);
    await _poser(tester, h, role: RoleSeance.guidee);
    expect(find.byKey(ChronoSalle.cleTexte), findsNothing);
  });

  testWidgets('sans horodatages dans la source : aucune ligne', (
    WidgetTester tester,
  ) async {
    final VueSeance vue = DonneesSeanceDemo.vue(
      RoleSeance.enseignant,
      EtatDemoSalle.repos,
    );
    expect(vue.chrono, isNull);
    expect(vue.voitChrono, isFalse);
    expect(vue.copyWith(chrono: _bornes).voitChrono, isTrue);
    expect(
      vue.copyWith(chrono: _bornes).copyWith(sansChrono: true).voitChrono,
      isFalse,
    );
  });

  for (final Size taille in <Size>[
    const Size(320, 700),
    const Size(390, 844),
    const Size(640, 1000),
    const Size(1440, 900),
  ]) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness luminosite in Brightness.values) {
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          testWidgets('${taille.width.toInt()} px, texte x${echelle.toInt()}, '
              '${luminosite.name}, ${langue.languageCode} : sans debordement', (
            WidgetTester tester,
          ) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            final _Horloge h = _Horloge(
              _t0.add(const Duration(hours: 0, minutes: 12, seconds: 34)),
            );
            await _poser(
              tester,
              h,
              taille: taille,
              echelle: echelle,
              luminosite: luminosite,
            );
            expect(tester.takeException(), isNull);
            expect(find.byKey(ChronoSalle.cleTexte), findsOneWidget);
            final Rect r = tester.getRect(find.byKey(ChronoSalle.cleTexte));
            expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
            expect(r.left, greaterThanOrEqualTo(-0.5));
          });
        }
      }
    }
  }

  testWidgets('arabe : les chiffres restent de gauche a droite', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    final _Horloge h = _Horloge(
      _t0.add(const Duration(minutes: 12, seconds: 34)),
    );
    await _poser(tester, h);
    final String texte = _texte(tester);
    expect(texte, contains('\u2066'));
    expect(texte, contains('00:12:34'));
    expect(texte, contains('00:32:26'));
  });
}
