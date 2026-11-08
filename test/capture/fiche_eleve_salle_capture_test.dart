// Captures de RELEVE-SUIVI point 4 (08/11/2026) : dans la salle, la carte
// d'un eleve dit son etape, les points a reprendre et la page de la Classe ;
// puis la meme carte quand une source est en panne (« Non disponible » pour
// ce seul fait). 390x844 @3 et 1440x900 @1, clair, francais et arabe.
// Donnees de test uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/fiche_groupe/etape_eleve.dart';
import 'package:rewayah_academy/features/fiche_groupe/observations_eleve.dart';
import 'package:rewayah_academy/features/salle/suivi_fiche_seance.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import 'outil_capture.dart';

void main() {
  group('Capture : fiche eleve dans la salle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      final String format =
          '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final bool panne in <bool>[false, true]) {
          final String cas =
              '${langue.languageCode}_${panne ? 'panne' : 'complete'}';
          testWidgets('$format, $cas', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            final bool ar = langue == AppLocale.ar;
            final FicheEleveSeance fiche = ficheAvecSuivi(
              FicheEleveSeance(
                niveau: ar ? 'الأساسيات' : 'Les bases',
                objectifActuel: '',
                derniereSeance: '',
                aReprendre: '',
                presenceRecente: '',
                travailActuel: '',
              ),
              profilId: 'p1',
              suivi: (
                etapes: AsyncData<Map<String, EtapeEleve>>(<String, EtapeEleve>{
                  'p1': EtapeEleve(
                    studentId: 'p1',
                    nom: ar ? 'القراءة بالحركات' : 'Lire avec les voyelles',
                    objectifs: const <String>[],
                  ),
                }),
                observations: panne
                    ? AsyncError<Map<String, ObservationsEleve>>(
                        StateError('panne'),
                        StackTrace.empty,
                      )
                    : AsyncData<Map<String, ObservationsEleve>>(
                        <String, ObservationsEleve>{
                          'p1': ObservationsEleve(
                            studentId: 'p1',
                            notees: DateTime(2026, 11, 6),
                            aRenforcer: ar
                                ? const <String>['يقرأ التنوين', 'يقرأ الشدة']
                                : const <String>[
                                    'Lit le tanwin',
                                    'Lit la chadda',
                                  ],
                            pretBilan: false,
                          ),
                        },
                      ),
                pageClasse: const AsyncData<int?>(24),
              ),
            );
            await tester.pumpWidget(
              hoteCapture(
                Scaffold(
                  body: SafeArea(
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: SizedBox(
                        width: taille.width < 600 ? taille.width : 400,
                        child: PanneauEleves(
                          large: taille.width >= 600,
                          eleves: <EleveSeance>[
                            EleveSeance(
                              prenom: ar ? 'ياسمين' : 'Yasmine',
                              statut: StatutEleveSeance.connecte,
                              id: 'RA-26-4817',
                              profilId: 'p1',
                              fiche: fiche,
                            ),
                          ],
                          actions: ActionsSeance(
                            onRappeler: (_) {},
                            onChoisirPourReciter: (_) {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await stabiliser(tester);
            expect(
              find.textContaining(ar ? 'القراءة بالحركات' : 'Lire avec'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, 'fs_${format}_$cas')}');
            await tester.pumpWidget(const SizedBox());
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
          });
        }
      }
    }
  });
}
