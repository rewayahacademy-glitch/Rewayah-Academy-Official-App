// Captures de recette ILE-SALLE (directeur, 11/11/2026) :
// - l'ile de la salle (eleve) posee sur une page de texte du Coran,
//   depliee a l'entree (mention), repliee au repos, repliee avec l'image
//   coupee (signe court) ;
// - l'ile hors de la salle (enseignant qui conduit la seance), compacte,
//   depliee, et depliee d'elle-meme pendant une reconnexion ;
// a 390 et 1440, clair et sombre, plus l'arabe. Horloge fixe.
// La page est un texte du Coran compose dans la police du Mushaf, pas
// l'image de la page de Medine (servie par le reseau en seance).
// Saute sans CAPTURE_DIR. Nommage : ile_<lieu>_<etat>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle_seance/barre_seance_en_direct.dart';
import 'package:rewayah_academy/features/salle_seance/bornes_salle.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/media_salle.dart';
import 'package:rewayah_academy/features/salle_seance/pilule_etat_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 11, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
  depassementMax: const Duration(minutes: 15),
);
final DateTime _maintenant = _t0.add(const Duration(minutes: 23, seconds: 16));

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 560), 3, '390'),
  (Size(1440, 560), 1, '1440'),
];

const String _fatiha =
    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ۝١ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ ۝٢ '
    'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ۝٣ مَٰلِكِ يَوْمِ ٱلدِّينِ ۝٤ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ '
    'نَسْتَعِينُ ۝٥ ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ ۝٦ صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ '
    'عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ ۝٧';

/// Une page de texte du Coran, sous l'ile.
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ColoredBox(
      color: palette.surfaceQuran.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.respiration + AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            '$_fatiha $_fatiha',
            textAlign: TextAlign.justify,
            style: palette.surfaceQuran.applyTo(
              const TextStyle(
                fontFamily: AppFontFamily.arabeMushaf,
                fontSize: AppSpacing.xxl,
                height: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _salle(VueSeance vue) => Stack(
  children: <Widget>[
    const Positioned.fill(child: _Page()),
    PositionedDirectional(
      top: AppSpacing.lg,
      start: AppSpacing.lg,
      end: AppSpacing.lg,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: PorteeMediaSalle(
          presenceEnSalle: true,
          child: Builder(
            builder: (BuildContext c) => PiluleEtatSalle(
              vue: vue,
              avecChrono: true,
              largeurMax: MediaQuery.sizeOf(c).width - 2 * AppSpacing.lg,
            ),
          ),
        ),
      ),
    ),
  ],
);

List<Override> get _horloge => <Override>[
  horlogeChronoProvider.overrideWithValue(() => _maintenant),
  signalChronoProvider.overrideWithValue(() {}),
];

Future<void> _salleCapture(
  WidgetTester tester,
  String nom, {
  required Size cadre,
  required double densite,
  required ThemeMode mode,
  required String etat,
}) async {
  fixerVueCapture(tester, cadre, densite);
  final VueSeance base = DonneesSeanceDemo.vue(
    RoleSeance.eleve,
    EtatDemoSalle.repos,
  ).copyWith(chrono: _bornes);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(body: _salle(base)),
      surcharges: _horloge,
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  if (etat != 'depliee') {
    await tester.pump(AppMouvement.ileMention);
    await stabiliser(tester);
  }
  if (etat == 'imagecoupee') {
    await tester.pumpWidget(
      hoteCapture(
        Scaffold(body: _salle(base.copyWith(videoSuspendue: true))),
        surcharges: _horloge,
        themeMode: mode,
      ),
    );
    await tester.pump(AppMouvement.ilePassage);
    await stabiliser(tester);
  }
  expect(tester.takeException(), isNull);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'teacher',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: true,
    peutRecevoir: true,
    invisible: false,
    peutModerer: true,
  ),
  expireLe: DateTime.utc(2030),
);

Future<void> _horsSalleCapture(
  WidgetTester tester,
  String nom, {
  required Size cadre,
  required double densite,
  required ThemeMode mode,
  required String etat,
}) async {
  fixerVueCapture(tester, cadre, densite);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  final ControleurSessionPersistante controleur = ControleurSessionPersistante(
    moteur,
    FauxServiceVideo(),
  );
  addTearDown(controleur.liberer);
  controleur.adopter(
    cours: const SessionEnCours(
      sessionId: 's1',
      groupeId: 'g1',
      libelleGroupe: 'Les sourates courtes, mardi 18 h',
    ),
    acces: _acces(),
  );
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.enseignantJournee,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.enseignantJournee,
        builder: (BuildContext _, GoRouterState _) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    hoteCapture(
      BarreSeanceEnDirect(
        routeur: routeur,
        child: const Scaffold(body: _Page()),
      ),
      surcharges: <Override>[
        ..._horloge,
        controleurSessionProvider.overrideWithValue(controleur),
        bornesSalleProvider.overrideWith((Ref _, CleBornesSalle _) => _bornes),
      ],
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  if (etat == 'depliee') {
    await tester.tap(find.byKey(BarreSeanceEnDirect.cleChevron));
    await stabiliser(tester);
  } else if (etat == 'reconnexion') {
    moteur.poser(EtatSalle.reconnexion);
    await stabiliser(tester);
  }
  expect(tester.takeException(), isNull);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : ILE-SALLE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size cadre, double densite, String largeur) in _cadres) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final String etat in <String>[
          'depliee',
          'repliee',
          'imagecoupee',
        ]) {
          final String nom = 'ile_salle_${etat}_${largeur}_${mode.name}';
          testWidgets(
            nom,
            (WidgetTester tester) => _salleCapture(
              tester,
              nom,
              cadre: cadre,
              densite: densite,
              mode: mode,
              etat: etat,
            ),
          );
        }
        for (final String etat in <String>[
          'compacte',
          'depliee',
          'reconnexion',
        ]) {
          final String nom = 'ile_horssalle_${etat}_${largeur}_${mode.name}';
          testWidgets(
            nom,
            (WidgetTester tester) => _horsSalleCapture(
              tester,
              nom,
              cadre: cadre,
              densite: densite,
              mode: mode,
              etat: etat,
            ),
          );
        }
      }
    }

    testWidgets('ile_salle_depliee_390_light_ar', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _salleCapture(
        tester,
        'ile_salle_depliee_390_light_ar',
        cadre: _cadres.first.$1,
        densite: _cadres.first.$2,
        mode: ThemeMode.light,
        etat: 'depliee',
      );
    });

    testWidgets('ile_horssalle_depliee_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _horsSalleCapture(
        tester,
        'ile_horssalle_depliee_390_light_ar',
        cadre: _cadres.first.$1,
        densite: _cadres.first.$2,
        mode: ThemeMode.light,
        etat: 'depliee',
      );
    });
  });
}
