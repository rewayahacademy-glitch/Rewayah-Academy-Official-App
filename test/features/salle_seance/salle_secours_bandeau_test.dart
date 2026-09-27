// T-S2 du lot CL-7 (ecrans de secours) : le bandeau de connexion sous
// l'en-tete, le retour bref « Connexion retablie. » et les commandes de
// publication desactivees pendant la reconnexion. Les boutons sont tapes.
// Captures : `cl7_{04,05,06}_{reseau_faible,reconnexion,retablie}_*`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/widgets/local_feedback.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

/// Compte les appels de chaque commande.
class _Journal {
  int micro = 0;
  int camera = 0;
  int quitter = 0;

  ActionsSeance get actions => ActionsSeance(
    onRetour: () {},
    onQuitter: () => quitter++,
    onMicro: () => micro++,
    onCamera: () => camera++,
    onAgrandir: () {},
    onReseau: () {},
    onEleves: () {},
    onSupports: () {},
    onOutil: (_) {},
    onPagePrecedente: () {},
    onPageSuivante: () {},
    onZoomMoins: () {},
    onZoomPlus: () {},
    onNotifications: () {},
    onReglages: () {},
    onCompte: () {},
    onReessayerConnexion: () {},
  );
}

class _Taille {
  const _Taille(this.nom, this.logique, this.densite, this.zone);

  final String nom;
  final Size logique;
  final double densite;
  final EdgeInsets zone;
}

const List<_Taille> _tailles = <_Taille>[
  _Taille('390x844@3', Size(390, 844), 3, EdgeInsets.only(top: 47, bottom: 34)),
  _Taille('768x1024@1', Size(768, 1024), 1, EdgeInsets.zero),
  _Taille('1440x900@1', Size(1440, 900), 1, EdgeInsets.zero),
];

const Map<RoleSeance, String> _noms = <RoleSeance, String>{
  RoleSeance.eleve: 'cl7_04',
  RoleSeance.guidee: 'cl7_05',
  RoleSeance.enseignant: 'cl7_06',
};

const Map<EtatDemoSalle, String> _etats = <EtatDemoSalle, String>{
  EtatDemoSalle.reseauFaible: 'reseau_faible',
  EtatDemoSalle.reconnexion: 'reconnexion',
  EtatDemoSalle.retablie: 'retablie',
};

Future<VueSeance> _monter(
  WidgetTester tester,
  RoleSeance role,
  EtatDemoSalle etat, {
  _Journal? journal,
  _Taille taille = const _Taille(
    '390x844@1',
    Size(390, 844),
    1,
    EdgeInsets.zero,
  ),
  ThemeMode mode = ThemeMode.light,
  double echelleTexte = 1,
}) async {
  fixerVueCapture(
    tester,
    taille.logique,
    taille.densite,
    zoneSure: taille.zone,
  );
  final VueSeance vue = DonneesSeanceDemo.vue(role, etat);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(vue: vue, actions: (journal ?? _Journal()).actions),
      themeMode: mode,
      echelleTexte: echelleTexte,
      interfaceMode: role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return vue;
}

Finder _dans(Finder parent, String texte) =>
    find.descendant(of: parent, matching: find.text(texte));

final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));
final Finder _bandeau = find.byKey(const ValueKey<String>('bandeau-secours'));

void main() {
  group('bandeau par role et par etat', () {
    const Map<RoleSeance, Map<EtatDemoSalle, List<String>>> attendus =
        <RoleSeance, Map<EtatDemoSalle, List<String>>>{
          RoleSeance.eleve: <EtatDemoSalle, List<String>>{
            EtatDemoSalle.reseauFaible: <String>[
              'Réseau faible. L\'audio est prioritaire.',
            ],
            EtatDemoSalle.reconnexion: <String>[
              'Connexion interrompue. Reconnexion en cours…',
            ],
          },
          RoleSeance.guidee: <EtatDemoSalle, List<String>>{
            EtatDemoSalle.reseauFaible: <String>[
              'Le réseau est faible.',
              'Le son reste prioritaire.',
            ],
            EtatDemoSalle.reconnexion: <String>['Reconnexion de la séance…'],
          },
          RoleSeance.enseignant: <EtatDemoSalle, List<String>>{
            EtatDemoSalle.reseauFaible: <String>[
              'Réseau faible. L\'audio est prioritaire.',
            ],
            EtatDemoSalle.reconnexion: <String>[
              'Connexion interrompue. Reconnexion en cours…',
            ],
          },
        };

    for (final RoleSeance role in RoleSeance.values) {
      for (final MapEntry<EtatDemoSalle, List<String>> cas
          in attendus[role]!.entries) {
        testWidgets('${role.name} ${cas.key.name} : texte exact', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, cas.key);
          expect(_bandeau, findsOneWidget);
          for (final String texte in cas.value) {
            expect(_dans(_bandeau, texte), findsOneWidget);
          }
          // Jamais « hors ligne » tant que la room est connectee (P06.5).
          expect(find.textContaining('hors ligne'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }

      for (final EtatDemoSalle etat in <EtatDemoSalle>[
        EtatDemoSalle.repos,
        EtatDemoSalle.retablie,
      ]) {
        testWidgets('${role.name} ${etat.name} : aucun bandeau', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, etat);
          expect(_bandeau, findsNothing);
          expect(find.byType(OfflineBanner), findsNothing);
        });
      }
    }
  });

  group('retour bref « Connexion retablie. »', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets('${role.name} : affiche puis disparait seul', (
        WidgetTester tester,
      ) async {
        await _monter(tester, role, EtatDemoSalle.retablie);
        final Finder retour = find.descendant(
          of: find.byType(LocalFeedback),
          matching: find.text('Connexion rétablie.'),
        );
        expect(retour, findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 300));
        expect(retour, findsNothing);
      });

      testWidgets('${role.name} repos : aucun retour', (
        WidgetTester tester,
      ) async {
        await _monter(tester, role, EtatDemoSalle.repos);
        expect(find.text('Connexion rétablie.'), findsNothing);
      });
    }
  });

  group('reconnexion : Micro et Camera ne repondent pas, Quitter oui', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        final _Journal journal = _Journal();
        final VueSeance vue = await _monter(
          tester,
          role,
          EtatDemoSalle.reconnexion,
          journal: journal,
        );
        final String micro = role == RoleSeance.guidee ? 'Parler' : 'Micro';
        expect(_dans(_dock, micro), findsOneWidget);
        await tester.tap(_dans(_dock, micro), warnIfMissed: false);
        await tester.pump();
        expect(journal.micro, 0);
        expect(
          find.bySemanticsLabel(
            RegExp('^$micro. Indisponible pendant la reconnexion.'),
          ),
          findsOneWidget,
        );
        if (vue.cameraAutorisee) {
          expect(_dans(_dock, 'Caméra'), findsOneWidget);
          await tester.tap(_dans(_dock, 'Caméra'), warnIfMissed: false);
          await tester.pump();
          expect(journal.camera, 0);
        }

        await tester.tap(_dans(_dock, 'Quitter'));
        await stabiliser(tester);
        final String confirmer = role == RoleSeance.enseignant
            ? 'Quitter et ouvrir le cahier'
            : 'Quitter';
        await tester.tap(find.text(confirmer).last);
        await stabiliser(tester);
        expect(journal.quitter, 1);
      });
    }

    testWidgets('en ligne, Micro et Camera repondent (temoin)', (
      WidgetTester tester,
    ) async {
      final _Journal journal = _Journal();
      await _monter(
        tester,
        RoleSeance.eleve,
        EtatDemoSalle.reseauFaible,
        journal: journal,
      );
      await tester.tap(_dans(_dock, 'Micro'));
      await tester.tap(_dans(_dock, 'Caméra'));
      await tester.pump();
      expect(journal.micro, 1);
      expect(journal.camera, 1);
    });

    testWidgets('mode agrandi : le bandeau reste visible', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(
        hoteCapture(
          SalleSeance(
            vue: DonneesSeanceDemo.vue(
              RoleSeance.eleve,
              EtatDemoSalle.reconnexion,
            ),
            actions: _Journal().actions,
            local: const EtatLocalSeance(agrandi: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Réduire'), findsOneWidget);
      expect(_bandeau, findsOneWidget);
    });
  });

  group('aucun debordement', () {
    for (final RoleSeance role in RoleSeance.values) {
      for (final EtatDemoSalle etat in _etats.keys) {
        for (final _Taille taille in _tailles) {
          testWidgets('${role.name} ${etat.name} ${taille.nom}', (
            WidgetTester tester,
          ) async {
            await _monter(tester, role, etat, taille: taille);
            expect(tester.takeException(), isNull);
          });
        }
        testWidgets('${role.name} ${etat.name} 390 zoom 2,0', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, etat, echelleTexte: 2);
          expect(tester.takeException(), isNull);
          if (etat != EtatDemoSalle.retablie) {
            expect(_bandeau, findsOneWidget);
          }
        });
      }
    }
  });

  group('Capture : bandeau et retour bref (T-S2)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final RoleSeance role in RoleSeance.values) {
      for (final MapEntry<EtatDemoSalle, String> etat in _etats.entries) {
        for (final _Taille taille in _tailles) {
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            final String nom =
                '${_noms[role]}_${etat.value}_${taille.nom}_${mode.name}';
            testWidgets(nom, (WidgetTester tester) async {
              await _monter(tester, role, etat.key, taille: taille, mode: mode);
              await tester.pump(const Duration(milliseconds: 300));
              expect(tester.takeException(), isNull);
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    }
  });
}
