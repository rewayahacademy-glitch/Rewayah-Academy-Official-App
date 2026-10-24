// Le panneau Eleves, CLV-07 (T5) : enseignant seulement ; fiche de Mariam
// depliee, six champs, quatre actions ; statuts sans « present » ni
// « absent » ; compteur du bouton = « Connecte » de la meme liste ; aucune
// coordonnee familiale ; aucun debordement aux trois tailles.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../../support/garde_interface.dart';

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
          // EN-9 : sur bureau, le panneau Eleves reste ouvert a droite du
          // support ; il n'a ni menu ni croix.
          if (forme == 'colonne') {
            expect(
              find.byKey(const ValueKey<String>('menu-panneau-seance')),
              findsNothing,
            );
            expect(
              find.bySemanticsLabel(t.salle.seance.fermerPanneau),
              findsNothing,
            );
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
            t.salle.seance.faireReciter,
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
      // Deux volets, jamais par-dessus. TB-5 (n. 12, remplace EN-9 « a
      // droite ») : les Participants a gauche du support. TB-4 : plus
      // d'outils permanents (dans les Commandes).
      expect(find.byKey(const ValueKey<String>('outils-carte')), findsNothing);
      expect(find.byKey(const ValueKey<String>('outils-rangee')), findsNothing);
      final Rect panneau = tester.getRect(
        find.byKey(const ValueKey<String>('panneau-seance-colonne')),
      );
      final Rect support = tester.getRect(
        find.byKey(const ValueKey<String>('zone-support')),
      );
      expect(panneau.right, lessThan(support.left));
    });

    testWidgets('une fiche depliee a la fois ; les actions visent l\'eleve', (
      WidgetTester tester,
    ) async {
      _journal.clear();
      await _monter(tester, _tailles['desktop']!);
      // TB-RC (TB-10 reste a) : les tuiles passent en colonnes mesurees ;
      // avec la police de test (glyphes d'un em), elles s'empilent et la
      // tuile peut etre sous le pli : on l'amene, comme une personne.
      await tester.ensureVisible(find.text(t.salle.seance.rappeler));
      await tester.pump();
      await tester.tap(find.text(t.salle.seance.rappeler));
      await tester.pump();
      expect(_journal, <String>['rappeler Mariam']);
      expect(find.byKey(const ValueKey<String>('fiche-eleve')), findsOneWidget);
      // EN-9 : « Yusuf » figure aussi dans la file de recitation (A suivre) ;
      // on vise sa carte.
      final Finder yusuf = find.descendant(
        of: find.byKey(const ValueKey<String>('eleve-Yusuf')),
        matching: find.text('Yusuf'),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('eleve-Yusuf')),
        80,
        scrollable: find
            .descendant(
              of: find.byType(PanneauEleves),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
      await tester.tap(yusuf);
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

  group('Panneau Eleves : fidelite aux images (recette T10)', () {
    // Les mesures de texte n'ont de sens qu'avec les vraies polices.
    setUpAll(chargerPolicesDuDepot);

    testWidgets('web etroit : aucun mot du support ne depasse du volet', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _tailles['web etroit']!);
      final double bordVolet = tester
          .getRect(find.byKey(const ValueKey<String>('panneau-seance-volet')))
          .right;
      final Finder textes = find.descendant(
        of: find.byKey(const ValueKey<String>('zone-support')),
        matching: find.byType(RichText),
      );
      final Finder vignette = find.byKey(
        const ValueKey<String>('vignette-video'),
      );
      for (final Element e in textes.evaluate()) {
        final RenderParagraph p = e.renderObject! as RenderParagraph;
        final bool dansVignette = find
            .descendant(of: vignette, matching: find.byWidget(e.widget))
            .evaluate()
            .isNotEmpty;
        if (dansVignette) continue;
        final int n = p.text.toPlainText().length;
        for (final TextBox b in p.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: n),
        )) {
          final Offset debut = p.localToGlobal(Offset(b.left, b.top));
          final Offset fin = p.localToGlobal(Offset(b.right, b.top));
          // Un texte commence sous le volet : il y reste entier.
          if (debut.dx < bordVolet) {
            expect(
              fin.dx,
              lessThanOrEqualTo(bordVolet),
              reason: '« ${p.text.toPlainText()} » depasse du volet',
            );
          }
        }
      }
    });

    for (final PanneauOuvert panneau in <PanneauOuvert>[
      PanneauOuvert.eleves,
      PanneauOuvert.supports,
    ]) {
      testWidgets('desktop, panneau ${panneau.name} : le titre du support '
          'tient sur deux lignes', (WidgetTester tester) async {
        fixerVueCapture(tester, _tailles['desktop']!, 1);
        final VueSeance vue = _vue(RoleSeance.enseignant)
            .copyWith(panneau: panneau);
        await tester.pumpWidget(
          hoteCapture(SalleSeance(vue: vue, actions: _complet)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        final String titre = vue.support!.titre;
        final RenderParagraph p = tester.renderObject<RenderParagraph>(
          find.text(titre),
        );
        final Set<double> lignes = <double>{
          for (final TextBox b in p.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: titre.length),
          ))
            b.top.roundToDouble(),
        };
        expect(lignes.length, 2);
      });
    }

    testWidgets('telephone : les inscrits commencent tous a l ecran', (
      WidgetTester tester,
    ) async {
      // K-55 : 16 entre deux fiches (au lieu de 4) ; la liste defile, le
      // dernier inscrit peut donc finir sous le bord, mais les precedents
      // tiennent entiers. Standard des commandes d'appel (24/10/2026) : la
      // pilule de 56 prend 16 de plus, le dernier inscrit s'atteint en
      // faisant defiler la liste.
      await _monter(tester, _tailles['mobile']!);
      final List<EleveSeance> eleves = _vue(RoleSeance.enseignant).eleves;
      for (int i = 0; i < eleves.length; i++) {
        if (i == eleves.length - 1) {
          await tester.scrollUntilVisible(
            find.byKey(ValueKey<String>('eleve-${eleves[i].prenom}')),
            64,
            scrollable: find.byType(Scrollable).last,
          );
        }
        final Rect r = tester.getRect(
          find.byKey(ValueKey<String>('eleve-${eleves[i].prenom}')),
        );
        expect(r.top, lessThan(844), reason: eleves[i].prenom);
        if (i < eleves.length - 1) {
          expect(r.bottom, lessThanOrEqualTo(844), reason: eleves[i].prenom);
        }
      }
    });
  });

  group('Panneau Eleves : cartes separees de 16 (K-55)', () {
    for (final MapEntry<String, Size> taille in _tailles.entries) {
      testWidgets('les fiches des inscrits ne se collent pas '
          '(${taille.key})', (WidgetTester tester) async {
        await _monter(tester, taille.value);
        // Une liste paresseuse ne construit que ce qui est a l'ecran : on
        // mesure les fiches presentes.
        final int n = verifierEcartEntre(tester, <Finder>[
          for (final EleveSeance e in _vue(RoleSeance.enseignant).eleves)
            find.byKey(ValueKey<String>('eleve-${e.prenom}')),
        ]);
        expect(n, greaterThanOrEqualTo(2));
      });
    }
  });
}
