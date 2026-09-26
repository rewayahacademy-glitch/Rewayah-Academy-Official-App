// Le panneau Eleves, CLV-07 (T5) : enseignant seulement ; fiche de Mariam
// depliee, six champs, quatre actions ; statuts sans « present » ni
// « absent » ; compteur du bouton = « Connecte » de la meme liste ; aucune
// coordonnee familiale ; aucun debordement aux trois tailles.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void _rien() {}
void _outil(OutilEnseignement _) {}
void _aller(String _) {}

final List<String> _journal = <String>[];
void _rappeler(EleveSeance e) => _journal.add('rappeler ${e.prenom}');
void _reciter(EleveSeance e) => _journal.add('reciter ${e.prenom}');
void _noter(EleveSeance e) => _journal.add('noter ${e.prenom}');
void _signaler(EleveSeance e) => _journal.add('signaler ${e.prenom}');

const ActionsSeance _complet = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onAgrandir: _rien,
  onReseau: _rien,
  onEleves: _rien,
  onSupports: _rien,
  onOutil: _outil,
  onPagePrecedente: _rien,
  onPageSuivante: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onNaviguer: _aller,
  onRappeler: _rappeler,
  onChoisirPourReciter: _reciter,
  onNoter: _noter,
  onSignaler: _signaler,
);

const Map<String, Size> _tailles = <String, Size>{
  'mobile': Size(390, 844),
  'web etroit': Size(640, 1000),
  'desktop': Size(1440, 900),
};

VueSeance _vue(RoleSeance role) => DonneesSeanceDemo.vue(
  role,
  EtatDemoSalle.eleves,
).copyWith(panneau: PanneauOuvert.eleves);

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  RoleSeance role = RoleSeance.enseignant,
  ThemeMode mode = ThemeMode.light,
  ActionsSeance actions = _complet,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(vue: _vue(role), actions: actions),
      themeMode: mode,
      interfaceMode: role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('Panneau Eleves (CLV-07)', () {
    for (final MapEntry<String, Size> taille in _tailles.entries) {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        testWidgets('jamais rendu pour ${role.name} (${taille.key})', (
          WidgetTester tester,
        ) async {
          await _monter(tester, taille.value, role: role);
          expect(tester.takeException(), isNull);
          expect(find.byType(PanneauEleves), findsNothing);
          expect(find.byType(PanneauSeance), findsNothing);
          expect(find.text(t.salle.seance.eleves), findsNothing);
          expect(find.text(t.salle.seance.statut.connecte), findsNothing);
          expect(find.text(t.tc.classe.fiche.aReprendre), findsNothing);
        });
      }

      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('enseignant ${taille.key} ${mode.name} : sans debordement, '
            'forme du gabarit, rien de prive', (WidgetTester tester) async {
          await _monter(tester, taille.value, mode: mode);
          expect(tester.takeException(), isNull);
          expect(find.byType(PanneauEleves), findsOneWidget);
          final String forme = switch (taille.key) {
            'desktop' => 'colonne',
            'web etroit' => 'volet',
            _ => 'feuille',
          };
          expect(
            find.byKey(ValueKey<String>('panneau-seance-$forme')),
            findsOneWidget,
          );
          // Fermeture : la croix en volet et en feuille (I-8) ; en colonne
          // desktop, le menu « … » de l'image CLV-07, qui porte « Fermer le
          // panneau ».
          if (forme == 'colonne') {
            expect(
              find.byKey(const ValueKey<String>('menu-panneau-seance')),
              findsOneWidget,
            );
            await tester.tap(
              find.byKey(const ValueKey<String>('menu-panneau-seance')),
            );
            await tester.pump(const Duration(milliseconds: 500));
            expect(find.text(t.salle.seance.fermerPanneau), findsOneWidget);
            await tester.tapAt(Offset.zero);
            await tester.pump(const Duration(milliseconds: 500));
          } else {
            expect(
              find.bySemanticsLabel(t.salle.seance.fermerPanneau),
              findsOneWidget,
            );
          }
          // Jamais « present » / « absent », ni coordonnee familiale.
          expect(
            find.textContaining(
              RegExp(
                'présent|absent|@|téléphone|e-mail|tuteur',
                caseSensitive: false,
              ),
            ),
            findsNothing,
          );
          // La fiche de Mariam est depliee, ses six champs lisibles.
          for (final String intitule in <String>[
            t.tc.classe.fiche.niveau,
            t.tc.classe.fiche.objectif,
            t.tc.classe.fiche.derniereSeance,
            t.tc.classe.fiche.aReprendre,
            t.tc.classe.fiche.presenceRecente,
            t.tc.classe.fiche.travailActuel,
          ]) {
            expect(find.text(intitule), findsOneWidget, reason: intitule);
          }
          expect(find.text('Pages 24 à 26'), findsOneWidget);
          expect(find.text('Écoute de la récitation'), findsOneWidget);
          for (final String action in <String>[
            t.salle.seance.rappeler,
            t.tc.classe.action.reciter,
            t.tc.classe.action.noter,
            t.salle.seance.signalerBesoin,
          ]) {
            expect(find.text(action), findsOneWidget, reason: action);
          }
        });
      }
    }

    testWidgets('desktop : compteur du bouton = « Connecte » de la liste, '
        'trois statuts, outils en carte', (WidgetTester tester) async {
      await _monter(tester, _tailles['desktop']!);
      final VueSeance vue = _vue(RoleSeance.enseignant);
      final int connectes = vue.eleves
          .where((EleveSeance e) => e.statut == StatutEleveSeance.connecte)
          .length;
      expect(
        find.descendant(
          of: find.byType(PanneauEleves),
          matching: find.text(t.salle.seance.statut.connecte),
        ),
        findsNWidgets(connectes),
      );
      expect(
        find.text(
          t.salle.seance.compteurEleves(
            connectes: connectes,
            inscrits: vue.eleves.length,
          ),
        ),
        findsOneWidget,
      );
      // La liste defile (police de test plus large) : on descend.
      final Finder liste = find.descendant(
        of: find.byType(PanneauEleves),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text(t.salle.seance.statut.connexionInterrompue),
        100,
        scrollable: liste,
      );
      expect(
        find.text(t.salle.seance.statut.pasEncoreConnecte),
        findsOneWidget,
      );
      expect(
        find.text(t.salle.seance.statut.connexionInterrompue),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('outils-carte')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('outils-rangee')), findsNothing);
      // Le panneau est a gauche du support, jamais par-dessus.
      final Rect panneau = tester.getRect(
        find.byKey(const ValueKey<String>('panneau-seance-colonne')),
      );
      final Rect outils = tester.getRect(
        find.byKey(const ValueKey<String>('outils-carte')),
      );
      expect(panneau.right, lessThan(outils.left));
    });

    testWidgets('une fiche depliee a la fois ; les actions visent l\'eleve', (
      WidgetTester tester,
    ) async {
      _journal.clear();
      await _monter(tester, _tailles['desktop']!);
      await tester.tap(find.text(t.salle.seance.rappeler));
      await tester.pump();
      expect(_journal, <String>['rappeler Mariam']);
      expect(find.byKey(const ValueKey<String>('fiche-eleve')), findsOneWidget);
      await tester.ensureVisible(find.text('Yusuf'));
      await tester.pump();
      await tester.tap(find.text('Yusuf'));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('fiche-eleve')), findsOneWidget);
      expect(find.text('Pages 20 à 23'), findsOneWidget);
      expect(find.text('Pages 24 à 26'), findsNothing);
      await tester.ensureVisible(find.text(t.salle.seance.signalerBesoin));
      await tester.pump();
      await tester.tap(find.text(t.salle.seance.signalerBesoin));
      await tester.pump();
      expect(_journal.last, 'signaler Yusuf');
    });

    testWidgets('une action sans rappel n\'est pas rendue', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _tailles['desktop']!,
        actions: const ActionsSeance(
          onQuitter: _rien,
          onEleves: _rien,
          onRappeler: _rappeler,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(t.salle.seance.rappeler), findsOneWidget);
      expect(find.text(t.tc.classe.action.noter), findsNothing);
      expect(find.text(t.salle.seance.signalerBesoin), findsNothing);
    });
  });
}
