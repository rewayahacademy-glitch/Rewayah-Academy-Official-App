// T-S3 du lot CL-7 (ecrans de secours) : reconnexion impossible et hors ligne
// confirme. Le bloc `EtatSysteme` remplace le bandeau sous l'en-tete, la
// salle reste montee. Les boutons sont tapes.
// Captures : `cl7_{04,05,06}_{echec,hors_ligne}_*`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

/// Compte les appels des commandes utiles au bloc.
class _Journal {
  int reessayer = 0;
  int quitter = 0;

  ActionsSeance get actions => ActionsSeance(
    onRetour: () {},
    onQuitter: () => quitter++,
    onMicro: () {},
    onCamera: () {},
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
    onReessayerConnexion: () => reessayer++,
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
  EtatDemoSalle.echec: 'echec',
  EtatDemoSalle.horsLigne: 'hors_ligne',
};

Future<void> _monter(
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
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(
        vue: DonneesSeanceDemo.vue(role, etat),
        actions: (journal ?? _Journal()).actions,
      ),
      themeMode: mode,
      echelleTexte: echelleTexte,
      interfaceMode: role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

final Finder _bloc = find.byKey(const ValueKey<String>('bloc-echec-connexion'));
final Finder _action = find.byKey(
  const ValueKey<String>('etat-systeme-action'),
);
final Finder _sortie = find.byKey(
  const ValueKey<String>('etat-systeme-secondaire'),
);

Finder _dans(Finder parent, String texte) =>
    find.descendant(of: parent, matching: find.text(texte));

/// Le titre et la sortie attendus (`null` : pas de sortie), par role et
/// par etat (07_SECOURS §2.1).
const Map<RoleSeance, Map<EtatDemoSalle, (String, String?)>> _attendus =
    <RoleSeance, Map<EtatDemoSalle, (String, String?)>>{
      RoleSeance.eleve: <EtatDemoSalle, (String, String?)>{
        EtatDemoSalle.echec: (
          'Impossible de rétablir la connexion.',
          'Quitter la séance',
        ),
        EtatDemoSalle.horsLigne: (
          'Vous êtes hors ligne. La séance nécessite une connexion.',
          null,
        ),
      },
      RoleSeance.guidee: <EtatDemoSalle, (String, String?)>{
        EtatDemoSalle.echec: ('La connexion ne revient pas.', 'Quitter'),
        EtatDemoSalle.horsLigne: ('La connexion ne revient pas.', 'Quitter'),
      },
      RoleSeance.enseignant: <EtatDemoSalle, (String, String?)>{
        EtatDemoSalle.echec: (
          'Impossible de rétablir la connexion.',
          'Quitter la séance',
        ),
        EtatDemoSalle.horsLigne: (
          'Vous êtes hors ligne. La séance nécessite une connexion.',
          null,
        ),
      },
    };

void main() {
  group('bloc d\'erreur par role et par etat', () {
    for (final RoleSeance role in RoleSeance.values) {
      for (final EtatDemoSalle etat in _etats.keys) {
        final (String titre, String? sortie) = _attendus[role]![etat]!;

        testWidgets('${role.name} ${etat.name} : textes, salle montee', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, etat);
          expect(_bloc, findsOneWidget);
          expect(_dans(_bloc, titre), findsOneWidget);
          expect(_dans(_bloc, 'Réessayer'), findsOneWidget);
          // Aucun bandeau en meme temps que le bloc.
          expect(
            find.byKey(const ValueKey<String>('bandeau-secours')),
            findsNothing,
          );
          // Le support reste monte.
          expect(
            find.byKey(const ValueKey<String>('zone-support')),
            findsWidgets,
          );
          if (sortie == null) {
            expect(_sortie, findsNothing);
          } else {
            expect(_dans(_sortie, sortie), findsOneWidget);
            // Groupe d'actions au bord trailing : sortie puis poursuite
            // (LTR, 8 entre les deux) ; si la ligne casse, la poursuite
            // reste au bord trailing, sous la sortie.
            final Rect s = tester.getRect(_sortie);
            final Rect a = tester.getRect(_action);
            if (s.top == a.top) {
              expect(a.left - s.right, 8);
            } else {
              expect(a.top, greaterThan(s.top));
            }
            expect(a.right, greaterThanOrEqualTo(s.right));
          }
        });

        testWidgets('${role.name} ${etat.name} : taper Reessayer', (
          WidgetTester tester,
        ) async {
          final _Journal journal = _Journal();
          await _monter(tester, role, etat, journal: journal);
          await tester.tap(_action);
          await tester.pump();
          expect(journal.reessayer, 1);
          expect(journal.quitter, 0);
        });
      }
    }
  });

  group('sortie : la confirmation existante', () {
    testWidgets('eleve : Quitter la seance ? puis Annuler, puis Quitter', (
      WidgetTester tester,
    ) async {
      final _Journal journal = _Journal();
      await _monter(
        tester,
        RoleSeance.eleve,
        EtatDemoSalle.echec,
        journal: journal,
      );
      await tester.tap(_sortie);
      await stabiliser(tester);
      expect(find.text('Quitter la séance\u00a0?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await stabiliser(tester);
      expect(journal.quitter, 0);
      expect(_bloc, findsOneWidget);

      await tester.tap(_sortie);
      await stabiliser(tester);
      await tester.tap(find.text('Quitter').last);
      await stabiliser(tester);
      expect(journal.quitter, 1);
    });

    testWidgets('guidee : Quitter puis confirmer', (WidgetTester tester) async {
      final _Journal journal = _Journal();
      await _monter(
        tester,
        RoleSeance.guidee,
        EtatDemoSalle.horsLigne,
        journal: journal,
      );
      await tester.tap(_sortie);
      await stabiliser(tester);
      expect(find.text('Quitter la séance\u00a0?'), findsOneWidget);
      await tester.tap(find.text('Quitter').last);
      await stabiliser(tester);
      expect(journal.quitter, 1);
    });

    testWidgets('enseignant : Quitter et ouvrir le cahier', (
      WidgetTester tester,
    ) async {
      final _Journal journal = _Journal();
      await _monter(
        tester,
        RoleSeance.enseignant,
        EtatDemoSalle.echec,
        journal: journal,
      );
      await tester.tap(_sortie);
      await stabiliser(tester);
      expect(find.text('Quitter la séance\u00a0?'), findsOneWidget);
      await tester.tap(
        find.text('Quitter et ouvrir le cahier de transmission'),
      );
      await stabiliser(tester);
      expect(journal.quitter, 1);
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
            expect(_bloc, findsOneWidget);
          });
        }
        testWidgets('${role.name} ${etat.name} 390 zoom 2,0', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, etat, echelleTexte: 2);
          expect(tester.takeException(), isNull);
          expect(_bloc, findsOneWidget);
        });
      }
    }
  });

  group(
    'Capture : reconnexion impossible et hors ligne (T-S3)',
    skip: sautSansCapture,
    () {
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
                await _monter(
                  tester,
                  role,
                  etat.key,
                  taille: taille,
                  mode: mode,
                );
                expect(tester.takeException(), isNull);
                debugPrint('PNG ${await capturer(tester, nom)}');
              });
            }
          }
        }
      }
    },
  );
}
