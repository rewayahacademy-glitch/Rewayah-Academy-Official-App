// Captures R3 de MA-PROGRESSION-ECRAN : le bloc « Ou j'en suis » (etape, sourates,
// etapes franchies / en cours / a venir, reglage de la direction) et la saisie
// de la direction dans la feuille du contenu d'une etape. 390 et 1440, clair,
// sombre, francais, arabe, texte x1 et x2.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Donnees d'essai : jamais celles d'un vrai eleve.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/suivi/ma_progression.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/section_revision_etape.dart';
import 'package:rewayah_academy/features/suivi_foyer/carte_suivi_pedagogique.dart';

import 'outil_capture.dart';

class _Port implements PortMaProgression {
  const _Port();

  @override
  Future<MaProgression?> pourEleve(String eleveId) async => MaProgression(
    suivi: SuiviPedagogique(
      etapeNom: 'Lire avec les voyelles',
      etapeOrdre: 2,
      objectifs: const <String>[
        'Lit les voyelles courtes',
        'Enchaine deux syllabes',
      ],
      dureePrevueSemaines: 14,
      dateLimite: DateTime(2027, 3),
      semainesEcoulees: 5,
      rythme: Rythme.dansLesTemps,
      pageReprise: 24,
    ),
    cycle: <EtapeDuCycle>[
      EtapeDuCycle(
        ordre: 1,
        nom: 'Les lettres',
        statut: StatutEtape.franchie,
        atteinteLe: DateTime(2026, 9, 7),
      ),
      const EtapeDuCycle(
        ordre: 2,
        nom: 'Lire avec les voyelles',
        statut: StatutEtape.enCours,
      ),
      const EtapeDuCycle(
        ordre: 3,
        nom: 'Lire sans voyelles',
        statut: StatutEtape.aVenir,
      ),
    ],
    sourates: const SouratesValidees(validees: 3, total: 17),
    reglage: const ReglageEtape(
      heuresRevisionSemaine: 2.5,
      repetitionsEstimees: 40,
    ),
  );
}

class _Famille implements PortProgressionFamille {
  const _Famille();

  @override
  Future<ProgressionEleve> progression(String eleveId) async =>
      ProgressionEleve(
        eleveId: eleveId,
        niveauHumain: 'Les bases',
        jalons: const <String>['Les lettres'],
        dernierJalonLe: DateTime(2026, 10, 14),
      );
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  group('Capture : MA-PROGRESSION-ECRAN', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final double largeur in <double>[390, 1440]) {
      for (final (String nomMode, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        for (final String langue in <String>['fr', 'ar']) {
          for (final double echelle in <double>[1, 2]) {
            final String suffixe =
                '${largeur.toInt()}_${nomMode}_${langue}_x${echelle.toInt()}';
            Future<void> regler(WidgetTester tester) async {
              if (langue == 'ar') {
                await tester.runAsync(
                  () => LocaleSettings.setLocale(AppLocale.ar),
                );
              }
              fixerVueCapture(
                tester,
                Size(largeur, echelle == 2 ? 3000 : 1500),
                1,
              );
            }

            testWidgets('bloc_$suffixe', (WidgetTester tester) async {
              await regler(tester);
              await tester.pumpWidget(
                hoteCapture(
                  const Scaffold(
                    body: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: CarteSuiviPedagogique(
                        eleveId: 'eleve-1',
                        prenom: 'Sofia',
                      ),
                    ),
                  ),
                  surcharges: <Override>[
                    portMaProgressionProvider.overrideWithValue(const _Port()),
                    portProgressionFamilleProvider.overrideWithValue(
                      const _Famille(),
                    ),
                  ],
                  themeMode: mode,
                  echelleTexte: echelle,
                ),
              );
              await stabiliser(tester);
              debugPrint('PNG ${await capturerVue(tester, 'bloc_$suffixe')}');
            });

            testWidgets('saisie_$suffixe', (WidgetTester tester) async {
              await regler(tester);
              await tester.pumpWidget(
                hoteCapture(
                  Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SectionRevisionEtape(
                        heuresInitiales: 2.5,
                        repetitionsInitiales: 40,
                        onRegler: ({double? heures, int? repetitions}) async {},
                      ),
                    ),
                  ),
                  themeMode: mode,
                  echelleTexte: echelle,
                ),
              );
              await stabiliser(tester);
              debugPrint('PNG ${await capturerVue(tester, 'saisie_$suffixe')}');
            });
          }
        }
      }
    }
  });
}
