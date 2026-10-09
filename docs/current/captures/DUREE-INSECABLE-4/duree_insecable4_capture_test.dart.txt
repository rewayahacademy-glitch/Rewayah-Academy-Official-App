// DUREE-INSECABLE-4 : captures de preuve.
//
// - CarteSession aux quatre moments (avant, fenetre, pendant, apres), 320 px texte x2,
//   LTR et RTL : la ponctuation d'un libelle francais reste a sa place en
//   RTL (isolat partage FSI ... PDI, isolerDansInterface) ;
// - CarteSession a 1440 px (texte x1 clair, texte x2 sombre) : la carte
//   garde la largeur de lecture (AppPage.largeurLecture), au bord de debut ;
// - fiche de seance, rappel discret en attente, 320 px texte x2, LTR et
//   RTL : « A nouveau dans 30 s » sur une ligne, point a sa place
//   (LocalFeedback isole son message). Defaut anterieur visible, hors de
//   cette etape : l'etat vide partage (EmptyState) n'isole pas encore son
//   texte (« .l'enseignant » en RTL).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/tc_classe_live/fiche_seance.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../teaching_core/e/faux/faux_classe.dart';
import '../teaching_core/e/support/hote_classe.dart' show surchargesClasse;
import 'outil_capture.dart';

typedef _Cas = ({
  double largeur,
  double hauteur,
  double texte,
  Brightness luminosite,
  MomentDemoAccessibilite moment,
});

const List<_Cas> _cartes = <_Cas>[
  (
    largeur: 320,
    hauteur: 760,
    texte: 2,
    luminosite: Brightness.light,
    moment: MomentDemoAccessibilite.avant,
  ),
  (
    largeur: 320,
    hauteur: 760,
    texte: 2,
    luminosite: Brightness.light,
    moment: MomentDemoAccessibilite.fenetre,
  ),
  (
    largeur: 320,
    hauteur: 760,
    texte: 2,
    luminosite: Brightness.light,
    moment: MomentDemoAccessibilite.pendant,
  ),
  (
    largeur: 320,
    hauteur: 760,
    texte: 2,
    luminosite: Brightness.light,
    moment: MomentDemoAccessibilite.apres,
  ),
  (
    largeur: 1440,
    hauteur: 420,
    texte: 1,
    luminosite: Brightness.light,
    moment: MomentDemoAccessibilite.avant,
  ),
  (
    largeur: 1440,
    hauteur: 520,
    texte: 2,
    luminosite: Brightness.dark,
    moment: MomentDemoAccessibilite.apres,
  ),
];

Widget _hote({
  required Widget enfant,
  required double texte,
  required Brightness luminosite,
  required TextDirection sens,
  List<Override> surcharges = const <Override>[],
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.pour(InterfaceMode.standard, luminosite),
        locale: AppLocale.fr.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (BuildContext c, Widget? app) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(texte)),
          child: Directionality(textDirection: sens, child: app!),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: enfant,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('Capture : DUREE-INSECABLE-4', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Cas cas in _cartes) {
      for (final TextDirection sens in TextDirection.values) {
        final String nom =
            'carte_session_${cas.moment.name}_${cas.largeur.toInt()}'
            'x${cas.texte.toInt()}_${cas.luminosite.name}_${sens.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, Size(cas.largeur, cas.hauteur), 1);
          await tester.pumpWidget(
            _hote(
              enfant: CarteSession(
                espace: DonneesAccessibiliteDemo.espaceAccueil(cas.moment),
                onRejoindre: () {},
              ),
              texte: cas.texte,
              luminosite: cas.luminosite,
              sens: sens,
            ),
          );
          await stabiliser(tester);
          expect(find.byType(CarteSession), findsOneWidget);
          expect(tester.takeException(), isNull);
          await capturer(tester, nom);
        });
      }
    }

    for (final TextDirection sens in TextDirection.values) {
      final String nom = 'fiche_rappel_attente_320x2_light_${sens.name}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 1500), 1);
        await tester.pumpWidget(
          _hote(
            enfant: const FicheSeance(
              eleve: TeacherStudentProjection(
                firstName: 'Amina',
                academyId: 'RA-AB0012',
                liveStatus: EtatPresenceProjete.present,
                interfaceGuidee: false,
              ),
              sessionId: 's1',
            ),
            texte: 2,
            luminosite: Brightness.light,
            sens: sens,
            surcharges: surchargesClasse(
              moteur: FauxMoteurClasse(),
              video: FauxServiceVideoClasse(),
              preVol: FauxPreVolClasse(),
              rappel: FauxRappelDiscret(
                echec: const EchecRappel(MotifEchecRappel.cooldown),
                restant: const Duration(seconds: 30),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text(t.tc.classe.action.rappel));
        await tester.pump();
        // Le retour local apparait en fondu : on le laisse entrer.
        await tester.pump(const Duration(milliseconds: 600));
        await capturer(tester, nom);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 6));
      });
    }
  });
}
