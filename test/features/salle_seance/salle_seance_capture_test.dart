// Captures de la salle de seance (vague Classe). Sautees sans CAPTURE_DIR.
//
// T1 : l'en-tete seul (ChromeSeance dans un Scaffold), trois roles, repos et
// visite, 390x844 @3, 640x1000 @1, 1440x900 @1, clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void _rien() {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onAgrandir: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
);

void _outil(OutilEnseignement _) {}
void _aller(String _) {}

const ActionsSeance _actionsEnseignant = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onReseau: _rien,
  onEleves: _rien,
  onSupports: _rien,
  onOutil: _outil,
  onPagePrecedente: _rien,
  onPageSuivante: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNaviguer: _aller,
);

class _Taille {
  const _Taille(this.nom, this.logique, this.densite, this.zone);
  final String nom;
  final Size logique;
  final double densite;
  final EdgeInsets zone;
}

const List<_Taille> _tailles = <_Taille>[
  _Taille('390x844@3', Size(390, 844), 3, EdgeInsets.only(top: 47, bottom: 34)),
  _Taille('640x1000@1', Size(640, 1000), 1, EdgeInsets.zero),
  _Taille('1440x900@1', Size(1440, 900), 1, EdgeInsets.zero),
];

const Map<RoleSeance, String> _noms = <RoleSeance, String>{
  RoleSeance.eleve: 'cl_04_eleve',
  RoleSeance.guidee: 'cl_05_guidee',
  RoleSeance.enseignant: 'cl_06_enseignant',
};

void main() {
  group('Capture : en-tete de la salle (T1)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final RoleSeance role in RoleSeance.values) {
      for (final EtatDemoSalle etat in <EtatDemoSalle>[
        EtatDemoSalle.repos,
        EtatDemoSalle.visite,
      ]) {
        for (final _Taille taille in _tailles) {
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            final String nom =
                '${_noms[role]}_entete_${etat.name}_${taille.nom}_${mode.name}';
            testWidgets(nom, (WidgetTester tester) async {
              fixerVueCapture(
                tester,
                taille.logique,
                taille.densite,
                zoneSure: taille.zone,
              );
              await tester.pumpWidget(
                hoteCapture(
                  Scaffold(
                    body: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ChromeSeance(
                          vue: DonneesSeanceDemo.vue(role, etat),
                          actions: _actions,
                        ),
                      ),
                    ),
                  ),
                  themeMode: mode,
                  interfaceMode: role == RoleSeance.guidee
                      ? InterfaceMode.enfant
                      : InterfaceMode.standard,
                ),
              );
              await stabiliser(tester);
              // Un cycle complet du point clignotant (2 x 1200 ms) : le
              // point est capture a pleine opacite.
              await tester.pump(const Duration(milliseconds: 1400));
              expect(tester.takeException(), isNull);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    }
  });

  group('Capture : salle eleve (T2)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final EtatDemoSalle etat in <EtatDemoSalle>[
      EtatDemoSalle.repos,
      EtatDemoSalle.visite,
      EtatDemoSalle.rienPartage,
    ]) {
      for (final _Taille taille in _tailles) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String nom =
              'cl_04_eleve_${etat.name}_${taille.nom}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(
              tester,
              taille.logique,
              taille.densite,
              zoneSure: taille.zone,
            );
            await tester.pumpWidget(
              hoteCapture(
                SalleSeance(
                  vue: DonneesSeanceDemo.vue(RoleSeance.eleve, etat),
                  actions: _actions,
                ),
                themeMode: mode,
              ),
            );
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });

  group('Capture : guidee et fin eleve (T3)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Taille taille in _tailles) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = 'cl_05_guidee_visite_${taille.nom}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(
            tester,
            taille.logique,
            taille.densite,
            zoneSure: taille.zone,
          );
          await tester.pumpWidget(
            hoteCapture(
              SalleSeance(
                vue: DonneesSeanceDemo.vue(
                  RoleSeance.guidee,
                  EtatDemoSalle.visite,
                ),
                actions: _actions,
              ),
              themeMode: mode,
              interfaceMode: InterfaceMode.enfant,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }

    for (final _Taille taille in <_Taille>[_tailles.first, _tailles.last]) {
      for (final bool guidee in <bool>[false, true]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String nom =
              'cl_09_${guidee ? 'guidee' : 'eleve'}_fin_${taille.nom}_'
              '${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(
              tester,
              taille.logique,
              taille.densite,
              zoneSure: taille.zone,
            );
            await tester.pumpWidget(
              hoteCapture(
                const ResultatSeance(
                  issue: IssueSeance.terminee,
                  onRetour: _rien,
                ),
                themeMode: mode,
                interfaceMode: guidee
                    ? InterfaceMode.enfant
                    : InterfaceMode.standard,
              ),
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });

  group('Capture : salle enseignant (T4)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Taille taille in _tailles) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = 'cl_06_enseignant_visite_${taille.nom}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(
            tester,
            taille.logique,
            taille.densite,
            zoneSure: taille.zone,
          );
          await tester.pumpWidget(
            hoteCapture(
              SalleSeance(
                vue: DonneesSeanceDemo.vue(
                  RoleSeance.enseignant,
                  EtatDemoSalle.visite,
                ),
                actions: _actionsEnseignant,
              ),
              themeMode: mode,
            ),
          );
          await stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 1400));
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });

  group('Capture : panneau Eleves (T5)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Etats des images : desktop = visite + « La seance se poursuit. » ;
    // telephone = sans visite, 32 min restantes ; web etroit = visite,
    // 32 min restantes.
    VueSeance vuePour(_Taille taille) {
      final VueSeance base = DonneesSeanceDemo.vue(
        RoleSeance.enseignant,
        EtatDemoSalle.eleves,
      );
      const VisiteSeance visite = VisiteSeance(
        prenomEnfant: DonneesSeanceDemo.eleveCourant,
        concerneMoi: true,
      );
      return switch (taille.nom) {
        '1440x900@1' => base.copyWith(
          visite: visite,
          horloge: const HorlogeDepassee(),
        ),
        '640x1000@1' => base.copyWith(visite: visite),
        _ => base,
      };
    }

    for (final _Taille taille in _tailles) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = 'cl_07_eleves_${taille.nom}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(
            tester,
            taille.logique,
            taille.densite,
            zoneSure: taille.zone,
          );
          await tester.pumpWidget(
            hoteCapture(
              SalleSeance(vue: vuePour(taille), actions: _actionsEleves),
              themeMode: mode,
            ),
          );
          await stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 1400));
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });
}

void _eleve(EleveSeance _) {}

const ActionsSeance _actionsEleves = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onReseau: _rien,
  onEleves: _rien,
  onSupports: _rien,
  onOutil: _outil,
  onPagePrecedente: _rien,
  onPageSuivante: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNaviguer: _aller,
  onRappeler: _eleve,
  onChoisirPourReciter: _eleve,
  onNoter: _eleve,
  onSignaler: _eleve,
);
