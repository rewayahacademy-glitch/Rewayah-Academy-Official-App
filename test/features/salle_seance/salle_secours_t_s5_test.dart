// T-S5 du lot CL-7 (ecrans de secours) : camera interdite (P10), seance
// prolongee (P11), acces retire (P12). Les boutons sont tapes.
// Captures : `cl7_04_camera_interdite_*`, `cl7_{04,06}_prolongee_*`,
// `cl7_{09,05,10}_acces_retire_*`.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

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

const _Taille _petite = _Taille(
  '390x844@1',
  Size(390, 844),
  1,
  EdgeInsets.zero,
);

const String _texteCamera = 'Caméra désactivée pour ce profil.';
const String _poursuit = 'La séance se poursuit.';
const String _accesRetire = 'Votre accès à cette séance a pris fin.';

int _sorties = 0;

Future<void> _monter(
  WidgetTester tester,
  RoleSeance role,
  EtatDemoSalle etat, {
  _Taille taille = _petite,
  ThemeMode mode = ThemeMode.light,
  double echelleTexte = 1,
}) async {
  _sorties = 0;
  fixerVueCapture(
    tester,
    taille.logique,
    taille.densite,
    zoneSure: taille.zone,
  );
  await tester.pumpWidget(
    hoteCapture(
      SalleDemo(
        key: ValueKey<String>('${role.name}-${etat.name}'),
        role: role,
        etat: etat,
        onSortir: () => _sorties++,
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

final Finder _statut = find.byKey(
  const ValueKey<String>('statut-camera-interdite'),
);
final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));

/// Le bouton Camera du dock : son mot d'etat visible (ETATS-BTN-1), « Camera
/// allumee » quand la camera est allumee.
Finder get _boutonCamera =>
    find.descendant(of: _dock, matching: find.text('Caméra allumée'));

void main() {
  group('P10 camera interdite', () {
    for (final _Taille taille in _tailles) {
      testWidgets('ES ${taille.nom} : pas de bouton, statut non tappable', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          RoleSeance.eleve,
          EtatDemoSalle.cameraInterdite,
          taille: taille,
        );
        expect(tester.takeException(), isNull);
        expect(_boutonCamera, findsNothing);
        expect(_statut, findsOneWidget);
        expect(find.text(_texteCamera), findsOneWidget);
        // Non interactif : aucun Pressable, ton neutre.
        expect(
          find.descendant(of: _statut, matching: find.byType(Pressable)),
          findsNothing,
        );
        expect(
          find.ancestor(of: _statut, matching: find.byType(Pressable)),
          findsNothing,
        );
        // Texte d'etat discret (correction T-S6) : aucune pilule, hors du
        // dock, au-dessus de lui (une ligne : captures TS6, vraies polices).
        expect(
          find.descendant(of: _statut, matching: find.byType(StatusPill)),
          findsNothing,
        );
        expect(find.descendant(of: _dock, matching: _statut), findsNothing);
        expect(
          tester.getBottomLeft(_statut).dy,
          lessThanOrEqualTo(tester.getTopLeft(_dock).dy),
        );
        // Taper le statut ne sort pas et ne leve rien.
        await tester.tap(find.text(_texteCamera), warnIfMissed: false);
        await tester.pump();
        expect(_sorties, 0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ES : lu par le lecteur d\'ecran, sans action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _monter(tester, RoleSeance.eleve, EtatDemoSalle.cameraInterdite);
      final SemanticsNode noeud = tester.getSemantics(find.text(_texteCamera));
      expect(noeud.label, _texteCamera);
      expect(noeud.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      poignee.dispose();
    });

    testWidgets('ES : le statut est au-dessus du dock a 390', (
      WidgetTester tester,
    ) async {
      await _monter(tester, RoleSeance.eleve, EtatDemoSalle.cameraInterdite);
      expect(
        tester.getBottomLeft(_statut).dy,
        lessThanOrEqualTo(tester.getTopLeft(_dock).dy),
      );
    });

    testWidgets('ES 1440 : le statut est aligne sur le debut du dock', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        RoleSeance.eleve,
        EtatDemoSalle.cameraInterdite,
        taille: _tailles.last,
      );
      expect(
        tester.getTopLeft(_statut).dx,
        moreOrLessEquals(tester.getTopLeft(_dock).dx),
      );
    });

    // Texte 200 % aux trois tailles, reflow 320 a 100 % (W2 1.4.10) et
    // 320 a 200 % sur une hauteur longue (precedent revue CL-R).
    for (final (_Taille taille, double zoom) in <(_Taille, double)>[
      (_petite, 2),
      (_tailles[1], 2),
      (_tailles[2], 2),
      (const _Taille('320x640@1', Size(320, 640), 1, EdgeInsets.zero), 1),
      (const _Taille('320x1400@1', Size(320, 1400), 1, EdgeInsets.zero), 2),
    ]) {
      testWidgets('ES ${taille.nom} zoom $zoom : aucun debordement', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          RoleSeance.eleve,
          EtatDemoSalle.cameraInterdite,
          taille: taille,
          echelleTexte: zoom,
        );
        expect(tester.takeException(), isNull);
        expect(_statut, findsOneWidget);
      });
    }

    for (final _Taille taille in _tailles) {
      testWidgets('IG ${taille.nom} : ni bouton ni explication', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          RoleSeance.guidee,
          EtatDemoSalle.cameraInterdite,
          taille: taille,
        );
        expect(tester.takeException(), isNull);
        expect(_boutonCamera, findsNothing);
        expect(_statut, findsNothing);
        expect(find.text(_texteCamera), findsNothing);
      });
    }

    testWidgets('ES camera autorisee : bouton, pas de statut', (
      WidgetTester tester,
    ) async {
      await _monter(tester, RoleSeance.eleve, EtatDemoSalle.repos);
      expect(_boutonCamera, findsOneWidget);
      expect(_statut, findsNothing);
    });

    testWidgets('EN : jamais de statut camera', (WidgetTester tester) async {
      await _monter(
        tester,
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
        taille: _tailles.last,
      );
      expect(_statut, findsNothing);
      expect(
        DonneesSeanceDemo.vue(
          RoleSeance.enseignant,
          EtatDemoSalle.cameraInterdite,
        ).texteCameraInterdite,
        isNull,
      );
    });
  });

  group('P11 seance prolongee', () {
    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.eleve,
      RoleSeance.enseignant,
    ]) {
      for (final _Taille taille in _tailles) {
        testWidgets('${role.name} ${taille.nom} : « $_poursuit »', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, EtatDemoSalle.prolongee, taille: taille);
          expect(tester.takeException(), isNull);
          expect(find.textContaining(_poursuit), findsWidgets);
          expect(find.textContaining(RegExp(r'-\s?\d')), findsNothing);
          expect(find.textContaining('restantes'), findsNothing);
        });
      }
    }

    testWidgets('IG : rien sur la duree', (WidgetTester tester) async {
      await _monter(tester, RoleSeance.guidee, EtatDemoSalle.prolongee);
      expect(find.textContaining(_poursuit), findsNothing);
    });

    testWidgets('ES : aucun bouton Prolonger, Quitter repond', (
      WidgetTester tester,
    ) async {
      await _monter(tester, RoleSeance.eleve, EtatDemoSalle.prolongee);
      expect(find.textContaining('Prolonger'), findsNothing);
      await tester.tap(
        find.descendant(of: _dock, matching: find.text('Quitter')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quitter la séance ?'), findsOneWidget);
    });
  });

  group('P12 acces retire', () {
    for (final _Taille taille in _tailles) {
      testWidgets('ES ${taille.nom} : titre en-tete, Retour a la Classe', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle poignee = tester.ensureSemantics();
        await _monter(
          tester,
          RoleSeance.eleve,
          EtatDemoSalle.accesRetire,
          taille: taille,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(_accesRetire), findsOneWidget);
        // Le titre est l'en-tete de l'ecran (point d'entree du lecteur).
        expect(
          tester
              .getSemantics(find.text(_accesRetire))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        // Aucune reconnexion, aucune presence, aucun enregistrement.
        expect(find.textContaining('Reconnexion'), findsNothing);
        expect(find.textContaining('Présent'), findsNothing);
        expect(find.textContaining('Absent'), findsNothing);
        expect(find.textContaining('enregistr'), findsNothing);
        expect(_dock, findsNothing);
        await tester.tap(find.text('Retour à la Classe'));
        expect(_sorties, 1);
        poignee.dispose();
      });
    }

    for (final _Taille taille in _tailles) {
      testWidgets(
        'ES ${taille.nom} : focus clavier sur l\'action a l\'ouverture',
        (WidgetTester tester) async {
          await _monter(
            tester,
            RoleSeance.eleve,
            EtatDemoSalle.accesRetire,
            taille: taille,
          );
          final FocusNode? focus = FocusManager.instance.primaryFocus;
          expect(focus, isNotNull);
          expect(focus!.context, isNotNull);
          expect(
            find.ancestor(
              of: find.text('Retour à la Classe'),
              matching: find.byWidget(focus.context!.widget),
            ),
            findsOneWidget,
          );
          // Entree active l'action focalisee.
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(_sorties, 1);
        },
      );
    }

    testWidgets('IG : l\'ecran de fin guide, Retour a l\'accueil', (
      WidgetTester tester,
    ) async {
      await _monter(tester, RoleSeance.guidee, EtatDemoSalle.accesRetire);
      expect(find.text('La séance est terminée.'), findsOneWidget);
      expect(find.text(_accesRetire), findsNothing);
      await tester.tap(find.text('Retour à l\'accueil'));
      expect(_sorties, 1);
    });

    testWidgets('EN : fin CLV-10, Ouvrir le cahier', (
      WidgetTester tester,
    ) async {
      await _monter(tester, RoleSeance.enseignant, EtatDemoSalle.accesRetire);
      expect(
        find.byKey(const ValueKey<String>('fin-seance-enseignant')),
        findsOneWidget,
      );
      // Le libelle vient de la cle i18n de l'ecran de fin, jamais en dur ;
      // l'action est sous le bilan, on l'amene a l'ecran avant de toucher.
      final Finder cahier = find.text(t.salle.fin.enseignant.ouvrirCahier);
      await tester.ensureVisible(cahier);
      await tester.pumpAndSettle();
      await tester.tap(cahier);
      expect(_sorties, 1);
    });
  });

  group('Capture : T-S5', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    final List<(String, RoleSeance, EtatDemoSalle)> cas =
        <(String, RoleSeance, EtatDemoSalle)>[
          (
            'cl7_04_camera_interdite',
            RoleSeance.eleve,
            EtatDemoSalle.cameraInterdite,
          ),
          ('cl7_04_prolongee', RoleSeance.eleve, EtatDemoSalle.prolongee),
          ('cl7_06_prolongee', RoleSeance.enseignant, EtatDemoSalle.prolongee),
          ('cl7_09_acces_retire', RoleSeance.eleve, EtatDemoSalle.accesRetire),
          ('cl7_05_acces_retire', RoleSeance.guidee, EtatDemoSalle.accesRetire),
          (
            'cl7_10_acces_retire',
            RoleSeance.enseignant,
            EtatDemoSalle.accesRetire,
          ),
        ];
    for (final (String base, RoleSeance role, EtatDemoSalle etat) in cas) {
      for (final _Taille taille in _tailles) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String nom = '${base}_${taille.nom}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            await _monter(tester, role, etat, taille: taille, mode: mode);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });
}
