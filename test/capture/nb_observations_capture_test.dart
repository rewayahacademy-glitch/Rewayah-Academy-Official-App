// Captures de NON-BRANCHE-LIVRAISON 1 (08/11/2026) : la fiche de l'eleve,
// cote enseignant, montre ce que le dernier cahier a note (points a
// renforcer, pret pour le petit bilan, date), et une lecture en echec dite
// comme une panne. 390x844 @3 et 1440x900 @1, clair, francais et arabe.
// Donnees de test uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/fiche_groupe/observations_eleve.dart';

import 'outil_capture.dart';

class _Port implements PortObservationsClasse {
  _Port({required this.panne});

  final bool panne;

  @override
  Future<Map<String, ObservationsEleve>> observationsDeLaClasse(
    String groupeId,
  ) async {
    if (panne) throw StateError('panne');
    return <String, ObservationsEleve>{
      'e1': ObservationsEleve(
        studentId: 'e1',
        notees: DateTime(2026, 11, 6, 18),
        aRenforcer: langueArabe
            ? const <String>['يقرأ التنوين', 'يقرأ الشدة']
            : const <String>['Lit le tanwin', 'Lit la chadda'],
        pretBilan: true,
      ),
    };
  }
}

bool langueArabe = false;

void main() {
  group('Capture : NON-BRANCHE 1, observations du cahier', skip: sautSansCapture, () {
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
              '${langue.languageCode}_${panne ? 'panne' : 'contenu'}';
          testWidgets('$format, $cas', (WidgetTester tester) async {
            langueArabe = langue == AppLocale.ar;
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(
                Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppPage.largeurReglages,
                          ),
                          child: FicheEleveEnseignant(
                            eleve: EleveFiche(
                              membre: MembreSeance(
                                studentId: 'e1',
                                identifiantImmuable: 'RA-26-0001',
                                prenom: langueArabe ? 'مريم' : 'Mariam',
                              ),
                              classe: 'An-Nour',
                              groupeId: 'c1',
                            ),
                            onSignaler: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                surcharges: <Override>[
                  portObservationsClasseProvider.overrideWithValue(
                    _Port(panne: panne),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            await tester.scrollUntilVisible(
              find.byType(BlocObservationsEleve),
              200,
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, 'obs_${format}_$cas')}');
            await tester.pumpWidget(const SizedBox());
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
          });
        }
      }
    }
  });
}
