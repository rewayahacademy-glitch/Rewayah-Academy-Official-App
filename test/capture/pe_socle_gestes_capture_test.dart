// PE-SOCLE-GESTES (parcours enseignant, 20/11/2026) : captures de preuve des
// trois composants communs, a 390 de large (zone sure d'un telephone : 47 en
// haut, 34 en bas), clair et sombre, francais et arabe.
//
// - la feuille du bas : courte, longue, et la feuille « Plus » des filtres ;
// - tirer pour actualiser, en cours, sur l'accueil du candidat (`/attente`) ;
// - la barre du bas, sur trois ecrans reels : enseignant (Journee), famille
//   (Accueil du tuteur), eleve (Suivi).
//
// N'emploie que des API deja dans `main` : le meme fichier tourne sur le code
// d'avant (prefixe `CAPTURE_PREFIXE=avant`) et d'apres (par defaut).
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/fraicheur/relecture_page.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../router/support_routeur.dart';
import '../support/harnais.dart' show FausseSourceSession;
import 'outil_capture.dart';

final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

const Size _telephone = Size(390, 844);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Une application de capture : vrai theme, locale, cadre de capture.
Widget _app({
  required List<Override> surcharges,
  required ThemeMode theme,
  GoRouter? routeur,
  GoRouter Function(WidgetRef ref)? routeurDuProvider,
  Widget? accueil,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          final Locale locale = TranslationProvider.of(context).flutterLocale;
          final GoRouter? r = routeur ?? routeurDuProvider?.call(ref);
          if (r != null) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: theme,
              locale: locale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: r,
            );
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: theme,
            locale: locale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: accueil,
          );
        },
      ),
    ),
  ),
);

Future<void> _laisser(WidgetTester tester, [int fois = 8]) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Une page qui ouvre une feuille au toucher de « Ouvrir ».
Widget _pageFeuille({required bool longue, required bool arabe}) => PageShell(
  titre: arabe ? 'الصفحة' : 'La page',
  child: Builder(
    builder: (BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              arabe
                  ? 'سطر من الصفحة رقم ${i + 1}'
                  : 'Ligne de la page numero ${i + 1}',
            ),
          ),
        ActionPrincipale(
          libelle: arabe ? 'افتح' : 'Ouvrir',
          onPress: () => unawaited(
            AppBottomSheet.ouvrir<void>(
              context,
              titre: longue
                  ? (arabe ? 'كل الدروس المسجلة' : 'Toutes les seances notees')
                  : (arabe ? 'حذف هذا الموعد؟' : 'Retirer ce creneau ?'),
              libelleFermer: longue ? (arabe ? 'إغلاق' : 'Fermer') : null,
              constructeur: (BuildContext _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (longue)
                    for (int i = 0; i < 30; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          arabe
                              ? 'الدرس ${i + 1} : حفظ ومراجعة'
                              : 'Seance ${i + 1} : memorisation et revision',
                        ),
                      )
                  else
                    Text(
                      arabe
                          ? 'سيختفي الموعد من جدول الأسبوع.'
                          : 'Le creneau quitte la semaine des entretiens.',
                    ),
                ],
              ),
              actions: longue
                  ? null
                  : (BuildContext contexte) => ActionPrincipale(
                      libelle: arabe ? 'حذف الموعد' : 'Retirer le creneau',
                      onPress: () => Navigator.of(contexte).pop(),
                    ),
            ),
          ),
        ),
      ],
    ),
  ),
);

/// Une liste et ses filtres : deux puces dans la rangee, le reste sous
/// « Plus », dont une puce et un menu retenus.
class _ListeFiltree extends StatefulWidget {
  const _ListeFiltree({required this.arabe});

  final bool arabe;

  @override
  State<_ListeFiltree> createState() => _ListeFiltreeEtat();
}

class _ListeFiltreeEtat extends State<_ListeFiltree> {
  final Set<int> _retenus = <int>{4};
  String? _pays = 'ma';

  @override
  Widget build(BuildContext context) {
    final List<String> noms = widget.arabe
        ? <String>['جديد', 'مقابلة', 'وثيقة ناقصة', 'مقبول', 'متوقف', 'منسحب']
        : <String>[
            'Nouveaux',
            'Entretien',
            'Piece manquante',
            'Admis',
            'En pause',
            'Retires',
          ];
    return PageShell(
      titre: widget.arabe ? 'الطلبات' : 'Candidatures',
      child: RangeeFiltres(
        visiblesMax: 2,
        filtres: <Widget>[
          for (int i = 0; i < noms.length; i++)
            FilterPill(
              libelle: noms[i],
              retenue: _retenus.contains(i),
              onPress: () => setState(
                () =>
                    _retenus.contains(i) ? _retenus.remove(i) : _retenus.add(i),
              ),
            ),
          MenuFiltre<String>(
            libelle: widget.arabe ? 'البلد' : 'Pays',
            valeur: _pays,
            entrees: <EntreeFiltre<String>>[
              EntreeFiltre<String>(
                valeur: null,
                libelle: widget.arabe ? 'كل البلدان' : 'Tous les pays',
              ),
              EntreeFiltre<String>(
                valeur: 'ma',
                libelle: widget.arabe ? 'المغرب' : 'Maroc',
              ),
            ],
            onChoix: (String? v) => setState(() => _pays = v),
          ),
        ],
      ),
    );
  }
}

List<(String, AppLocale, ThemeMode)> get _variantes =>
    <(String, AppLocale, ThemeMode)>[
      for (final AppLocale l in <AppLocale>[AppLocale.fr, AppLocale.ar])
        for (final ThemeMode m in <ThemeMode>[ThemeMode.light, ThemeMode.dark])
          (
            '${l.languageCode}_${m == ThemeMode.light ? 'clair' : 'sombre'}',
            l,
            m,
          ),
    ];

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PE-SOCLE-GESTES : captures', skip: sautSansCapture, () {
    setUp(masquerRubanDebug);

    for (final (String v, AppLocale langue, ThemeMode theme) in _variantes) {
      final bool arabe = langue == AppLocale.ar;

      for (final bool longue in <bool>[false, true]) {
        final String nom = longue ? 'feuille-longue' : 'feuille-courte';
        testWidgets('$nom $v', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, _telephone, 2, zoneSure: _zoneSure);
          await tester.pumpWidget(
            _app(
              surcharges: const <Override>[],
              theme: theme,
              accueil: _pageFeuille(longue: longue, arabe: arabe),
            ),
          );
          await _laisser(tester);
          await tester.tap(find.byType(ActionPrincipale).first);
          await _laisser(tester);
          await capturer(tester, '${_prefixe}_${nom}_$v');
        });
      }

      testWidgets('feuille-filtres $v', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        fixerVueCapture(tester, _telephone, 2, zoneSure: _zoneSure);
        await tester.pumpWidget(
          _app(
            surcharges: const <Override>[],
            theme: theme,
            accueil: _ListeFiltree(arabe: arabe),
          ),
        );
        await _laisser(tester);
        await capturer(tester, '${_prefixe}_filtres-rangee_$v');
        final Finder plus = find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'rangee-filtres-plus-',
              ) &&
              w is FilterPill,
        );
        await tester.tap(plus.hitTestable().first);
        await _laisser(tester);
        await capturer(tester, '${_prefixe}_feuille-filtres_$v');
      });

      testWidgets('actualiser candidat $v', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        fixerVueCapture(tester, _telephone, 2, zoneSure: _zoneSure);
        final Completer<void> fin = Completer<void>();
        final GoRouter routeur = GoRouter(
          initialLocation: Routes.attente,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attente,
              builder: (BuildContext _, GoRouterState _) => RelecturePage(
                relire: () => fin.future,
                relireAuRetour: () {},
                child: const AttentePage(),
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          _app(
            theme: theme,
            routeur: routeur,
            surcharges: surchargesCandidature(
              port: FauxMaCandidature(),
              etat: etatCandidat(
                candidature: const CandidatureDossier(
                  existe: true,
                  etape: EtapeCandidature.verifications,
                  etat: EtatCandidature.entretienAPlanifier,
                  version: 5,
                ),
              ),
            ),
          ),
        );
        await _laisser(tester, 12);
        await capturer(tester, '${_prefixe}_attente-repos_$v');
        // Le doigt tire la page vers le bas, sans la lacher.
        final TestGesture geste = await tester.startGesture(
          const Offset(195, 300),
        );
        for (int i = 0; i < 12; i++) {
          await geste.moveBy(const Offset(0, 20));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await capturer(tester, '${_prefixe}_actualiser-tire_$v');
        // Lache : la relecture est en cours (elle ne finit pas ici).
        await geste.up();
        await _laisser(tester, 4);
        await capturer(tester, '${_prefixe}_actualiser-en-cours_$v');
        fin.complete();
        await _laisser(tester, 15);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
      });

      for (final (AppRole role, String nom, String chemin)
          in <(AppRole, String, String)>[
            (AppRole.teacher, 'enseignant-journee', Routes.enseignantJournee),
            (AppRole.guardian, 'famille-accueil', Routes.tuteurAccueil),
            (AppRole.student, 'eleve-suivi', Routes.eleveSuivi),
          ]) {
        testWidgets('barre $nom $v', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, _telephone, 2, zoneSure: _zoneSure);
          late GoRouter routeur;
          await tester.pumpWidget(
            _app(
              theme: theme,
              surcharges: <Override>[
                ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
                portClassesFoyerProvider.overrideWithValue(
                  const ClassesFoyerIndisponible(),
                ),
              ],
              routeurDuProvider: (WidgetRef ref) =>
                  routeur = ref.read(routeurProvider),
            ),
          );
          await _laisser(tester);
          routeur.go(chemin);
          await _laisser(tester, 12);
          await capturer(tester, '${_prefixe}_barre_${nom}_$v');
          // Tout en bas : la fin du contenu s'arrete au-dessus de la barre.
          final Finder defilant = find.byType(Scrollable);
          if (defilant.evaluate().isNotEmpty) {
            final ScrollableState s = tester.state<ScrollableState>(
              defilant.first,
            );
            if (s.position.maxScrollExtent > 0) {
              s.position.jumpTo(s.position.maxScrollExtent);
              await _laisser(tester, 4);
              await capturer(tester, '${_prefixe}_barre_${nom}_${v}_fin');
            }
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 1));
        });
      }
    }
  });
}
