// T-S4 du lot CL-7 (ecrans de secours) : micro bloque par le systeme (P09).
// Le geste Micro ouvre la feuille (`AppBottomSheet.ouvrir`), texte exact par
// role ; « Ouvrir les reglages » seulement si la plateforme le permet ;
// « Continuer sans micro » ferme, appelle le rappel et rend le focus au
// bouton Micro, qui reste coupe. Les boutons sont tapes.
// Captures : `cl7_{04,05,06}_micro_bloque_*`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

/// Compte les appels des commandes utiles a la feuille.
class _Journal {
  _Journal({this.reglagesPossibles = false});

  final bool reglagesPossibles;
  int micro = 0;
  int continuer = 0;
  int reglages = 0;

  ActionsSeance get actions => ActionsSeance(
    onRetour: () {},
    onQuitter: () {},
    onMicro: () => micro++,
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
    onReessayerConnexion: () {},
    onContinuerSansMicro: () => continuer++,
    onOuvrirReglages: reglagesPossibles ? () => reglages++ : null,
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

/// Le corps exact par role (07_SECOURS §2.3).
const Map<RoleSeance, String> _textes = <RoleSeance, String>{
  RoleSeance.eleve: 'Le micro est bloqué dans les réglages de cet appareil.',
  RoleSeance.guidee: 'Le micro est bloqué sur cet appareil.',
  RoleSeance.enseignant:
      'Le micro est bloqué dans les réglages de cet appareil.',
};

Future<void> _monter(
  WidgetTester tester,
  RoleSeance role, {
  EtatDemoSalle etat = EtatDemoSalle.microBloque,
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

final Finder _micro = find.byKey(const ValueKey<String>('bouton-micro'));
final Finder _texte = find.byKey(const ValueKey<String>('texte-micro-bloque'));
final Finder _continuer = find.byKey(
  const ValueKey<String>('micro-bloque-continuer'),
);
final Finder _reglages = find.byKey(
  const ValueKey<String>('micro-bloque-reglages'),
);

/// Le micro est montre coupe : l'icone coupee est dans le bouton.
Finder _iconeCoupee(RoleSeance role) => find.descendant(
  of: _micro,
  matching: find.byIcon(
    role == RoleSeance.guidee
        ? AppIcons.microCoupe.actif
        : AppIcons.microCoupe.repos,
  ),
);

Future<void> _ouvrir(WidgetTester tester) async {
  await tester.tap(_micro);
  await stabiliser(tester);
}

void main() {
  group('feuille micro bloque par role', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets('${role.name} : taper Micro ouvre la feuille, texte exact', (
        WidgetTester tester,
      ) async {
        final _Journal journal = _Journal();
        await _monter(tester, role, journal: journal);
        // Bloque : le micro est montre coupe avant tout geste (P09.6).
        expect(_iconeCoupee(role), findsOneWidget);
        await _ouvrir(tester);
        expect(_texte, findsOneWidget);
        expect(find.text(_textes[role]!), findsOneWidget);
        // Titre de la feuille : le libelle existant « Micro ».
        expect(find.text('Micro'), findsWidgets);
        expect(
          find.descendant(
            of: _continuer,
            matching: find.text('Continuer sans micro'),
          ),
          findsOneWidget,
        );
        // Aucun paquet de permission (BR-1) : pas de reglages.
        expect(_reglages, findsNothing);
        // Le geste n'a pas bascule le micro.
        expect(journal.micro, 0);
      });

      testWidgets('${role.name} : Continuer sans micro ferme, rappelle et '
          'rend le focus au bouton Micro', (WidgetTester tester) async {
        final _Journal journal = _Journal();
        await _monter(tester, role, journal: journal);
        await _ouvrir(tester);
        await tester.tap(_continuer);
        await stabiliser(tester);
        expect(_texte, findsNothing);
        expect(journal.continuer, 1);
        expect(journal.micro, 0);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'bouton-micro');
        // Toujours coupe apres la feuille.
        expect(_iconeCoupee(role), findsOneWidget);
      });

      testWidgets('${role.name} : Ouvrir les reglages present si possible, '
          'et appele', (WidgetTester tester) async {
        final _Journal journal = _Journal(reglagesPossibles: true);
        await _monter(tester, role, journal: journal);
        await _ouvrir(tester);
        expect(
          find.descendant(
            of: _reglages,
            matching: find.text('Ouvrir les réglages'),
          ),
          findsOneWidget,
        );
        // Contrat B : Continuer au bord leading, Reglages au bord trailing.
        final Rect c = tester.getRect(_continuer);
        final Rect r = tester.getRect(_reglages);
        if (c.top == r.top) {
          expect(r.left - c.right, 8);
        } else {
          expect(r.top, greaterThan(c.top));
        }
        await tester.tap(_reglages);
        await stabiliser(tester);
        expect(_texte, findsNothing);
        expect(journal.reglages, 1);
        expect(journal.continuer, 0);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'bouton-micro');
      });

      testWidgets('${role.name} : Echap ferme sans rappel, focus rendu', (
        WidgetTester tester,
      ) async {
        final _Journal journal = _Journal();
        await _monter(tester, role, journal: journal);
        await _ouvrir(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await stabiliser(tester);
        expect(_texte, findsNothing);
        expect(journal.continuer, 0);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'bouton-micro');
      });

      testWidgets('${role.name} : micro autorise, taper Micro bascule sans '
          'feuille', (WidgetTester tester) async {
        final _Journal journal = _Journal();
        await _monter(
          tester,
          role,
          etat: EtatDemoSalle.repos,
          journal: journal,
        );
        await _ouvrir(tester);
        expect(_texte, findsNothing);
        expect(journal.micro, 1);
      });
    }
  });

  group('aucun debordement', () {
    for (final RoleSeance role in RoleSeance.values) {
      for (final _Taille taille in _tailles) {
        testWidgets('${role.name} ${taille.nom}', (WidgetTester tester) async {
          await _monter(
            tester,
            role,
            taille: taille,
            journal: _Journal(reglagesPossibles: true),
          );
          await _ouvrir(tester);
          expect(tester.takeException(), isNull);
          expect(_texte, findsOneWidget);
        });
      }
      testWidgets('${role.name} 390 zoom 2,0', (WidgetTester tester) async {
        await _monter(
          tester,
          role,
          echelleTexte: 2,
          journal: _Journal(reglagesPossibles: true),
        );
        await _ouvrir(tester);
        expect(tester.takeException(), isNull);
        expect(_texte, findsOneWidget);
      });
    }
  });

  group('Capture : micro bloque (T-S4)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final RoleSeance role in RoleSeance.values) {
      for (final _Taille taille in _tailles) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String nom =
              '${_noms[role]}_micro_bloque_${taille.nom}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            await _monter(tester, role, taille: taille, mode: mode);
            await _ouvrir(tester);
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
      // Variante 390 avec « Ouvrir les reglages » (plateforme qui le permet).
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom =
            '${_noms[role]}_micro_bloque_reglages_390x844@3_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          await _monter(
            tester,
            role,
            taille: _tailles.first,
            mode: mode,
            journal: _Journal(reglagesPossibles: true),
          );
          await _ouvrir(tester);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });
}
