// Captures de recette FORM-L5 (Programmes : feuille ajouter un niveau, cycle en
// puces, ordre deduit, code genere). Vraie page `ProgrammesPage`, ouverte par
// de vrais tap (K-07), service en memoire (aucun serveur).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// forml5_<etat>_<largeur>_x<echelle>_<mode>.png.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/champ_etiquete.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';

import 'outil_capture.dart';

class _Service implements ServiceProgramme {
  _Service({this.doublon = false});

  final bool doublon;

  @override
  Future<List<VersionProgramme>> versions() async => <VersionProgramme>[
    VersionProgramme(
      id: 'v1',
      statut: StatutVersionProgramme.brouillon,
      numeroVersion: 1,
      creeParIdentifiant: 'x',
      creeParPrenom: null,
      creeParNom: null,
      publieeAt: null,
      nombreNiveaux: 3,
      createdAt: DateTime.utc(2026, 10, 1),
    ),
  ];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      const <NiveauProgramme>[
        NiveauProgramme(
          id: 'a',
          codeTechnique: 'fondations-lettres',
          nomHumain: 'Lettres',
          cycle: 'Fondations',
          ordre: 1,
          description: null,
        ),
        NiveauProgramme(
          id: 'b',
          codeTechnique: 'fondations-voyelles',
          nomHumain: 'Voyelles',
          cycle: 'Fondations',
          ordre: 2,
          description: null,
        ),
        NiveauProgramme(
          id: 'c',
          codeTechnique: 'intermediaire-madd',
          nomHumain: 'Madd',
          cycle: 'Intermédiaire',
          ordre: 5,
          description: null,
        ),
      ];

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {
    if (doublon) throw Exception('PostgrestException: code déjà utilisé');
    return 'n9';
  }

  @override
  Future<String> creerVersion({String? versionSourceId}) async => 'v2';

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {}

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) async {}

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) async {}
}

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 2, '390'),
  (Size(1440, 900), 1, '1440'),
  (Size(320, 700), 2, '320'),
];

void main() {
  group('Capture : FORM-L5 feuille niveau', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, double densite, String nom) in _cadres) {
        for (final double echelle in <double>[1, if (nom == '320') 2]) {
          final String suffixe = '${nom}_x${echelle.toInt()}_${mode.name}';

          testWidgets('ajout $suffixe', (WidgetTester tester) async {
            fixerVueCapture(
              tester,
              // 320 x2 : la page de fond deborde deja a 700 de haut (Column de
              // _Corps, hors perimetre FORM-L5) ; vue plus haute pour ouvrir la feuille.
              echelle == 2 ? const Size(320, 1100) : taille,
              densite,
            );
            await tester.pumpWidget(
              hoteCapture(
                const ProgrammesPage(),
                themeMode: mode,
                echelleTexte: echelle,
                surcharges: <Override>[
                  serviceProgrammeProvider.overrideWithValue(_Service()),
                ],
              ),
            );
            await stabiliser(tester);
            await tester.tap(find.text(t.admin.programmes.ajouterNiveau));
            await stabiliser(tester);
            await tester.enterText(
              find.descendant(
                of: find.widgetWithText(
                  ChampEtiquete,
                  t.admin.programmes.champNomHumain,
                ),
                matching: find.byType(TextField),
              ),
              'Éléments de Tajwîd',
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            // ignore: avoid_print
            print('PNG ${await capturer(tester, 'forml5_ajout_$suffixe')}');
          });

          testWidgets('nouveau cycle et erreur $suffixe', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(
              tester,
              // 320 x2 : la page de fond deborde deja a 700 de haut (Column de
              // _Corps, hors perimetre FORM-L5) ; vue plus haute pour ouvrir la feuille.
              echelle == 2 ? const Size(320, 1100) : taille,
              densite,
            );
            await tester.pumpWidget(
              hoteCapture(
                const ProgrammesPage(),
                themeMode: mode,
                echelleTexte: echelle,
                surcharges: <Override>[
                  serviceProgrammeProvider.overrideWithValue(
                    _Service(doublon: true),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            await tester.tap(find.text(t.admin.programmes.ajouterNiveau));
            await stabiliser(tester);
            await tester.tap(find.text(t.admin.programmes.nouveauCycle));
            await stabiliser(tester);
            await tester.enterText(
              find.descendant(
                of: find.widgetWithText(
                  ChampEtiquete,
                  t.admin.programmes.champNouveauCycle,
                ),
                matching: find.byType(TextField),
              ),
              'Avancé',
            );
            await tester.enterText(
              find.descendant(
                of: find.widgetWithText(
                  ChampEtiquete,
                  t.admin.programmes.champNomHumain,
                ),
                matching: find.byType(TextField),
              ),
              'Lettres',
            );
            await stabiliser(tester);
            await tester.ensureVisible(
              find.text(t.admin.programmes.ajouterNiveauEnvoyer),
            );
            await tester.tap(
              find.text(t.admin.programmes.ajouterNiveauEnvoyer),
            );
            await stabiliser(tester);
            expect(find.textContaining('pas été confirmé'), findsOneWidget);
            expect(tester.takeException(), isNull);
            // ignore: avoid_print
            print('PNG ${await capturer(tester, 'forml5_erreur_$suffixe')}');
          });
        }
      }
    }

    // Page Programmes seule, 320 x 700 a texte x2, defilee au bas de la liste
    // des niveaux : preuve visuelle de l'absence de debordement.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('liste bas 320x700 x2 ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(320, 700), 2);
        await tester.pumpWidget(
          hoteCapture(
            const ProgrammesPage(),
            themeMode: mode,
            echelleTexte: 2,
            surcharges: <Override>[
              serviceProgrammeProvider.overrideWithValue(_Service()),
            ],
          ),
        );
        await stabiliser(tester);
        final Finder defilants = find.byType(Scrollable);
        for (int i = 0; i < defilants.evaluate().length; i++) {
          final ScrollableState etat = tester.state<ScrollableState>(
            defilants.at(i),
          );
          if (etat.position.axis == Axis.vertical) {
            etat.position.jumpTo(etat.position.maxScrollExtent);
          }
        }
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        // ignore: avoid_print
        print('PNG ${await capturer(tester, 'forml5_liste_bas_320x700_x2_${mode.name}')}');
      });
    }
  });
}
