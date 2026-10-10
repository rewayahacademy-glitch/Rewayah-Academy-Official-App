// Captures de recette de COUPE-MOTS-1 (part 1/2 : composants partages et
// Mes Classes), avec PASTILLE-COUPE-1 et CORR-SUITE-2 : vraies polices, vrai
// theme, vraies coquilles de demonstration.
//
// - Mes Classes (ENS-09) a 320, 390 et 1280 px, texte x2, LTR et RTL ;
// - un ecran par role touche, 320 px, texte x1 et x2, clair et sombre :
//   enseignant (Mes Classes dans sa coquille, barre basse « Disponibilites »),
//   controleur (Echanges), tuteur (Historique et son controle segmente),
//   administration (Dossiers) ;
// - les rails (enseignant, controleur) a 768 et les barres laterales (tuteur,
//   administration) a 1440, x1 et x2, clair et sombre ;
// - le titre de la salle « Seance en direct » a 320, x1 et x2, clair et
//   sombre (titre toujours plus grand que son sous-titre).
//
// Chaque capture mesure aussi, en vraies polices, qu'aucun mot de l'ECRAN
// ENTIER (chaque Scaffold, plus la navigation) n'est coupe ni tronque ; le
// rail ne descend jamais sous 0,85 a 100 %, ni sous la taille du theme
// quand le texte est agrandi.
//
// Eleve et famille : aucune capture ici, leurs ecrans d'accueil et la
// journee appartiennent a la voie Bento (fichiers interdits a ce lot).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Sortie versionnee
// dans `docs/current/captures/COUPE-MOTS-1/`. Donnees : fixtures synthetiques
// de la demonstration uniquement.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart'
    show echelleMinimaleLisible;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart'
    show maintenantJourneeProvider;

import '../support/ecrans_roles.dart';
import 'outil_capture.dart';

String _x(double echelle) => 'x${echelle.round()}';

void _mesurer(WidgetTester tester) => mesurerEcranEntier(tester);

/// Le rail a libelles ne descend jamais sous `echelleMinimaleLisible`
/// (0,85) a 100 %, ni sous la taille du theme (1) quand le texte est agrandi :
/// il s'elargit plutot (revue COUPE-MOTS-1-R M1). En vraies polices,
/// francais, a 100 %, il garde sa largeur de base (80) ; agrandi, il ne la
/// garde plus forcement.
void _railBorne(WidgetTester tester, double echelle) {
  final Finder rail = find.byKey(NavShell.railKey);
  if (rail.evaluate().isEmpty) return;
  final double plancher = echelle > 1 ? 1 : echelleMinimaleLisible;
  for (final RenderParagraph p in tester.renderObjectList<RenderParagraph>(
    find.descendant(of: rail, matching: find.byType(RichText)),
  )) {
    debugPrint(
      'RAIL « ${p.text.toPlainText()} » echelle '
      '${p.textScaler.scale(1).toStringAsFixed(3)}',
    );
    expect(
      p.textScaler.scale(1),
      greaterThanOrEqualTo(plancher),
      reason: '« ${p.text.toPlainText()} » sous le plancher',
    );
  }
  final double largeur = tester.getSize(rail).width;
  debugPrint('RAIL largeur ${largeur.toStringAsFixed(1)}');
  if (echelle > 1) {
    expect(largeur, greaterThanOrEqualTo(AppGabarit.largeurRail));
  } else {
    expect(largeur, AppGabarit.largeurRail);
  }
}

/// La taille rendue d'un paragraphe (taille du style, a son echelle).
double _tailleRendue(RenderParagraph p) =>
    p.textScaler.scale(p.text.style?.fontSize ?? 14);

/// Le titre de la salle reste plus grand que son sous-titre : la reduction
/// pour tenir dans ses lignes ne renverse jamais la hierarchie.
void _titreSalleAuDessusDuSousTitre(WidgetTester tester) {
  final Finder titre = find.text('Séance en direct');
  final Finder sousTitre = find.textContaining('min restantes');
  if (titre.evaluate().isEmpty || sousTitre.evaluate().isEmpty) return;
  final RenderParagraph t = tester.renderObject<RenderParagraph>(
    find.descendant(of: titre.first, matching: find.byType(RichText)).first,
  );
  final RenderParagraph s = tester.renderObject<RenderParagraph>(
    find.descendant(of: sousTitre.first, matching: find.byType(RichText)).first,
  );
  debugPrint(
    'SALLE titre ${_tailleRendue(t).toStringAsFixed(1)} / sous-titre '
    '${_tailleRendue(s).toStringAsFixed(1)}',
  );
  expect(_tailleRendue(t), greaterThan(_tailleRendue(s)));
}

void main() {
  group('Capture : COUPE-MOTS-1', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    // Mes Classes, avec la pastille « Remplacement » et le cahier a valider
    // sur la meme ligne (Al-Badr), comme le test ENS-09.
    final GroupeEnseignant badr = DonneesEnseignantDemo.groupes().firstWhere(
      (GroupeEnseignant g) => g.libelle == 'Al-Badr',
    );
    final List<Override> surchargesClasses = <Override>[
      maintenantJourneeProvider.overrideWithValue(
        () => DonneesEnseignantDemo.maintenant,
      ),
      groupesEnseignantProvider.overrideWith(
        (Ref _) async => DonneesEnseignantDemo.groupes(),
      ),
      seancesEnseignantProvider.overrideWith(
        (Ref _) async =>
            DonneesEnseignantDemo.seances(EtatDemoEnseignant.nominal),
      ),
      cahiersEnRetardProvider.overrideWith(
        (Ref _) async =>
            DonneesEnseignantDemo.cahiersEnRetard(EtatDemoEnseignant.nominal),
      ),
      detailsClassesProvider.overrideWithValue(<String, DetailClasse>{
        badr.id: const DetailClasse(
          niveau: 2,
          langue: 'Français',
          remplacement: true,
        ),
      }),
    ];

    for (final double largeur in <double>[320, 390, 1280]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('Mes Classes $largeur x2 ${sens.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, Size(largeur, 900), 2);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: sens,
                child: const MesClassesPage(),
              ),
              surcharges: surchargesClasses,
              echelleTexte: 2,
            ),
          );
          await stabiliser(tester);
          _mesurer(tester);
          if (largeur >= 1280) {
            // CORR-SUITE-2, en vraies polices : a 1280 x2, la marque (passee
            // sous la legende) tient sur une seule ligne.
            final RenderParagraph p = tester.renderObject<RenderParagraph>(
              find.text(t.enseignant.classes.cahierAValider),
            );
            expect(<int>{
              for (final TextBox b in p.getBoxesForSelection(
                TextSelection(
                  baseOffset: 0,
                  extentOffset: p.text.toPlainText().length,
                ),
              ))
                b.top.round(),
            }, hasLength(1));
          }
          debugPrint(
            'PNG ${await capturer(tester, 'mes_classes_${largeur.round()}_x2_${sens.name}')}',
          );
        });
      }
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final double echelle in <double>[1, 2]) {
        for (final (String role, String ecran) in <(String, String)>[
          ('enseignant', 'enseignant_classes'),
          ('controleur', 'controleur_echanges'),
          ('tuteur', 'tuteur_historique'),
          ('admin', 'admin_dossiers'),
        ]) {
          testWidgets('$role 320 ${_x(echelle)} ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, const Size(320, 700), 2);
            await monterEcranRole(
              tester,
              ecranRole(role),
              mode: mode,
              echelle: echelle,
            );
            _mesurer(tester);
            debugPrint(
              'PNG ${await capturer(tester, '${ecran}_320_${_x(echelle)}_${mode.name}')}',
            );
          });
        }
      }
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final double echelle in <double>[1, 2]) {
        final String suffixe = '${_x(echelle)}_${mode.name}';

        // Rails a 768 (enseignant, controleur), barres laterales a 1440
        // (tuteur, administration), titre de la salle a 320.
        for (final (String role, String nom, Size taille, double densite)
            in const <(String, String, Size, double)>[
              ('enseignant', 'enseignant_rail_768', Size(768, 1024), 1),
              ('controleur', 'controleur_rail_768', Size(768, 1024), 1),
              ('tuteur', 'tuteur_barre_laterale_1440', Size(1440, 900), 1),
              ('admin', 'admin_barre_laterale_1440', Size(1440, 900), 1),
              ('salle', 'salle_titre_320', Size(320, 700), 2),
            ]) {
          testWidgets('$nom $suffixe', (WidgetTester tester) async {
            fixerVueCapture(tester, taille, densite);
            await monterEcranRole(
              tester,
              ecranRole(role),
              mode: mode,
              echelle: echelle,
            );
            _mesurer(tester);
            _railBorne(tester, echelle);
            _titreSalleAuDessusDuSousTitre(tester);
            debugPrint('PNG ${await capturer(tester, '${nom}_$suffixe')}');
          });
        }
      }
    }
  });
}
