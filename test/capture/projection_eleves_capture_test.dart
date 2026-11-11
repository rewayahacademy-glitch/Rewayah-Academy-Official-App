// Captures de PROJECTION-ELEVES (08/11/2026) : la page de reprise et le
// travail en cours de chaque eleve, lus au serveur pour son enseignant
// (`groupe_roster_enseignant`). Trois etats : la liste des eleves, la fiche
// d'un eleve, la fiche quand la lecture est en panne (« Non disponible »).
// 390x844 et 1440x900, francais et arabe. Donnees fictives.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart'
    show TypePublicGroupe;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/preparation_seance.dart';

import '../support/harnais.dart';
import '../teaching_core/a/faux/faux_groupes.dart' show PortHorlogeMuet;
import 'outil_capture.dart';

const String _groupeId = 'g1';

class _Port implements PortProjectionsEleves {
  const _Port({this.panne = false});

  final bool panne;

  @override
  Future<Map<String, LigneProjectionEleve>> projectionsDeLaClasse(
    String groupeId,
  ) async {
    if (panne) throw StateError('reseau');
    return const <String, LigneProjectionEleve>{
      'e1': LigneProjectionEleve(
        studentId: 'e1',
        pageReprise: 24,
        intentions: <IntentionPedagogique>[
          IntentionPedagogique.aApprendre,
          IntentionPedagogique.aRevoir,
        ],
      ),
      'e2': LigneProjectionEleve(studentId: 'e2', pageReprise: 7),
    };
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PROJECTION-ELEVES : captures', skip: sautSansCapture, () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final String etat in <String>['liste', 'fiche', 'panne']) {
          final String nom =
              'pe_${taille.width.toInt()}_${langue.languageCode}_$etat';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, 1);
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              hoteCapture(
                FicheGroupePage(
                  groupeId: _groupeId,
                  onOuvrirEleve: (String _) {},
                ),
                surcharges: <Override>[
                  serviceEnseignantProvider.overrideWithValue(
                    FauxServiceEnseignant()
                      ..groupesRendus = <GroupeEnseignant>[
                        GroupeEnseignant(
                          id: _groupeId,
                          libelle: 'Classe de test',
                          type: TypePublicGroupe.enfant,
                          seuilMax: 5,
                          creneau: const Creneau(
                            jour: 3,
                            heure: 17,
                            fuseau: 'Europe/Paris',
                          ),
                          nbMembres: 2,
                          creeLe: DateTime(2026, 9, 1),
                        ),
                      ]
                      ..membresRendus = <String, List<MembreSeance>>{
                        _groupeId: <MembreSeance>[
                          membreDeTest(
                            prenom: 'Eleve A',
                            identifiant: 'RA-26-0001',
                          ),
                          membreDeTest(
                            studentId: 'e2',
                            prenom: 'Eleve B',
                            identifiant: 'RA-26-0002',
                          ),
                        ],
                      },
                  ),
                  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
                  groupeProvider(_groupeId).overrideWith((Ref _) async => null),
                  portHorlogeSeanceProvider.overrideWithValue(
                    const PortHorlogeMuet(),
                  ),
                  portProjectionsElevesProvider.overrideWithValue(
                    _Port(panne: etat == 'panne'),
                  ),
                ],
              ),
            );
            await tester.pumpAndSettle();
            if (etat != 'liste') {
              final Finder ligne = find.text('RA-26-0001');
              await tester.ensureVisible(ligne);
              await tester.pumpAndSettle();
              await tester.tap(ligne);
              await tester.pumpAndSettle();
              expect(
                find.text(t.compte.nonDisponible),
                etat == 'panne' ? findsWidgets : findsNothing,
              );
            }
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturerVue(tester, 'projection-eleves/$nom')}',
            );
          });
        }
      }
    }
  });
}
