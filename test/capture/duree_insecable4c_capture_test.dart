// DUREE-INSECABLE-4 (reprise 2) : captures de preuve.
//
// - Planning de la classe (tuteur, page reelle sur le vrai routeur) :
//   « 18:10 · 45 min », la duree suit l'heure sans ancre de sens au milieu
//   (dureeEnPhrase) ; 320 texte x2 clair LTR et RTL, 1440 texte x1 sombre
//   RTL. La marque est invisible : la preuve est le test, la capture montre
//   le rendu.
// - CarteSession, eleve entre avant l'heure, avec changement d'heure annonce
//   et conseil d'appareil : 320 texte x2 clair LTR et RTL. En RTL, chaque
//   libelle francais (attente, avis de changement d'heure, conseil,
//   intitules « Votre heure », « Duree ») garde sa ponctuation a sa place.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../features/classe_tuteur/support_classe.dart' as classe;
import 'outil_capture.dart';

Widget _cadre({
  required double texte,
  required Brightness luminosite,
  required TextDirection sens,
  required Widget Function(TransitionBuilder builder) app,
  List<Override> surcharges = const <Override>[],
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: app(
        (BuildContext c, Widget? enfant) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(texte)),
          child: Directionality(textDirection: sens, child: enfant!),
        ),
      ),
    ),
  ),
);

GroupHomeVM _espaceAttente() {
  final GroupSummaryVM identite = DonneesClasseDemo.groupe(
    EtatDemoClasse.attente,
  );
  return GroupHomeVM(
    identite: identite,
    role: RoleEspaceGroupe.eleve,
    horloge: SessionClockVM.depuisFenetre(
      fenetre: DonneesClasseDemo.fenetre,
      maintenantServeurUtc: DonneesClasseDemo.instant(EtatDemoClasse.attente),
      horlogeUtilisateur: DonneesClasseDemo.horlogeUtilisateur,
      connecte: true,
      noticeDst: DonneesClasseDemo.noticeDst,
    ),
    avantProchainCours: DonneesClasseDemo.actions,
    bibliotheque: SlotBibliotheque(groupeId: identite.groupeId),
  );
}

void main() {
  group('Capture : DUREE-INSECABLE-4 (reprise 2)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    const List<
      ({
        double largeur,
        double texte,
        Brightness luminosite,
        TextDirection sens,
      })
    >
    vues =
        <
          ({
            double largeur,
            double texte,
            Brightness luminosite,
            TextDirection sens,
          })
        >[
          (
            largeur: 320,
            texte: 2,
            luminosite: Brightness.light,
            sens: TextDirection.ltr,
          ),
          (
            largeur: 320,
            texte: 2,
            luminosite: Brightness.light,
            sens: TextDirection.rtl,
          ),
          (
            largeur: 1440,
            texte: 1,
            luminosite: Brightness.dark,
            sens: TextDirection.rtl,
          ),
        ];

    for (final v in vues) {
      final String nom =
          'planning_classe_${v.largeur.toInt()}x${v.texte.toInt()}_'
          '${v.luminosite.name}_${v.sens.name}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(
          tester,
          Size(v.largeur, v.largeur < 600 ? 1400 : 900),
          1,
        );
        late GoRouter routeur;
        await tester.pumpWidget(
          _cadre(
            texte: v.texte,
            luminosite: v.luminosite,
            sens: v.sens,
            surcharges: classe.surchargesClasse(),
            app: (TransitionBuilder builder) => Consumer(
              builder: (BuildContext _, WidgetRef ref, Widget? _) {
                routeur = ref.read(routeurProvider);
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.pour(InterfaceMode.standard, v.luminosite),
                  locale: AppLocale.fr.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  builder: builder,
                  routerConfig: routeur,
                );
              },
            ),
          ),
        );
        await stabiliser(tester);
        routeur.go(
          '${Routes.classeSousPage(classe.classeA, 'planning')}'
          '?eleve=${classe.eleveA1}',
        );
        await stabiliser(tester);
        final List<String> textes = <String>[
          for (final Element e in find.byType(Text).evaluate())
            if ((e.widget as Text).data case final String d) d,
        ];
        expect(
          textes.where((String d) => d.contains(' · ')),
          isNotEmpty,
          reason: '$textes',
        );
        for (final String d in textes) {
          expect(d.lastIndexOf('\u200E'), lessThanOrEqualTo(0), reason: d);
        }
        expect(tester.takeException(), isNull);
        await capturer(tester, nom);
      });
    }

    for (final TextDirection sens in TextDirection.values) {
      final String nom = 'carte_session_attente_dst_320x2_light_${sens.name}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 1300), 1);
        await tester.pumpWidget(
          _cadre(
            texte: 2,
            luminosite: Brightness.light,
            sens: sens,
            app: (TransitionBuilder builder) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: builder,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: CarteSession(
                    espace: _espaceAttente(),
                    onRejoindre: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await stabiliser(tester);
        expect(find.byType(CarteSession), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturer(tester, nom);
      });
    }
  });
}
