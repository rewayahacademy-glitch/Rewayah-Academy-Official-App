// Captures de RESEAU-ELEVES (directeur, 11/11/2026) : CAPTURES DE TEST, pas
// de la vraie application (aucun serveur de visio ici ; les qualites sont
// donnees a la main).
// - le panneau des eleves de l'enseignant : Yasmine au bon reseau (trois
//   barres), Amine au reseau faible qui dure (une barre, teinte d'attention,
//   « On entend peut-etre mal Amine »), Sara sans mesure (aucun signe) ;
// - l'ile de l'eleve : la phrase « Votre connexion est faible... » depliee,
//   puis repliee sur son signe court ;
// a 390 et 1440, clair et sombre, plus l'arabe. Meme cadre que les captures
// de la fiche d'eleve (`fiche_eleve_salle_capture_test.dart`).
// Saute sans CAPTURE_DIR. Nommage : reseau_<objet>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/seuils_reseau.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 3, '390'),
  (Size(1440, 900), 1, '1440'),
];

final DateTime _t0 = DateTime.utc(2026, 11, 11, 18);

List<EleveSeance> _eleves(bool ar) => <EleveSeance>[
  EleveSeance(
    prenom: ar ? 'ياسمين' : 'Yasmine',
    statut: StatutEleveSeance.connecte,
    id: 'RA-26-4817',
    profilId: 'p1',
    reseau: const EtatReseau(qualite: QualiteLien.excellente),
    microOuvert: true,
  ),
  EleveSeance(
    prenom: ar ? 'أمين' : 'Amine',
    statut: StatutEleveSeance.connecte,
    id: 'RA-26-5120',
    profilId: 'p2',
    reseau: const EtatReseau(qualite: QualiteLien.mediocre, alerte: true),
    microOuvert: true,
  ),
  EleveSeance(
    prenom: ar ? 'سارة' : 'Sara',
    statut: StatutEleveSeance.connecte,
    id: 'RA-26-6033',
    profilId: 'p3',
  ),
];

void main() {
  group('Capture : reseau des eleves', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite, String largeur) in _cadres) {
      for (final (ThemeMode theme, AppLocale langue, String mode)
          in <(ThemeMode, AppLocale, String)>[
            (ThemeMode.light, AppLocale.fr, 'clair'),
            (ThemeMode.dark, AppLocale.fr, 'sombre'),
            (ThemeMode.light, AppLocale.ar, 'arabe'),
          ]) {
        testWidgets('panneau, $largeur, $mode', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              Scaffold(
                body: SafeArea(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(
                      width: taille.width < 600 ? taille.width : 300,
                      child: PanneauEleves(
                        large: taille.width >= 600,
                        eleves: _eleves(langue == AppLocale.ar),
                        actions: const ActionsSeance(),
                      ),
                    ),
                  ),
                ),
              ),
              themeMode: theme,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'reseau_panneau_${largeur}_$mode')}',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        });

        for (final bool repliee in <bool>[false, true]) {
          final String etat = repliee ? 'repliee' : 'depliee';
          testWidgets('ile $etat, $largeur, $mode', (
            WidgetTester tester,
          ) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, Size(taille.width, 200), densite);
            final VueSeance vue = VueSeance(
              chrono: BornesChrono(
                debutUtc: _t0,
                finPrevueUtc: _t0.add(const Duration(minutes: 60)),
              ),
              role: RoleSeance.eleve,
              nomClasse: 'Classe',
              nomEnseignant: 'Sayyida Amina',
              initialesEnseignant: 'SA',
              connexion: ConnexionSeance.reseauFaible,
              videoSuspendue: true,
              reseauDansIle: true,
              onVousEntendMal: true,
              tutoiement: false,
              enregistrementConfirme: false,
            );
            await tester.pumpWidget(
              hoteCapture(
                Scaffold(
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: DynamiqueChrono(
                          vue: vue,
                          avecChrono: true,
                          largeurMax: taille.width - 32,
                        ),
                      ),
                    ),
                  ),
                ),
                themeMode: theme,
                surcharges: <Override>[
                  horlogeChronoProvider.overrideWithValue(
                    () => _t0.add(const Duration(minutes: 23)),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            if (repliee) {
              await tester.pump(AppMouvement.ilePassage);
              await stabiliser(tester);
            }
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'reseau_ile_${etat}_${largeur}_$mode')}',
            );
            await tester.pumpWidget(const SizedBox());
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
          });
        }
      }
    }
  });
}
