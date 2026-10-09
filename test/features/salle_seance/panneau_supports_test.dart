// Le panneau Supports, CLV-08 (T6) : enseignant seulement ; Reprendre,
// Recents, Ressources de la Classe ; une seule action pleine (« Voir toute la
// bibliotheque ») ; aucun chevauchement ni debordement aux trois tailles ;
// « Ouvrir » passe le support choisi ; rappel nul = rien de rendu.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_supports.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';

import '../../capture/outil_capture.dart';

void _rien() {}
void _outil(OutilEnseignement _) {}
void _aller(String _) {}

final List<String> _ouverts = <String>[];
void _ouvrir(SupportDisponible s) => _ouverts.add(s.id);

const ActionsSeance _complet = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
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
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onNaviguer: _aller,
  onOuvrirSupport: _ouvrir,
  onBibliotheque: _rien,
);

/// `/salle` avant BR-1 : ni ouverture ni bibliotheque.
const ActionsSeance _salle = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onEleves: _rien,
  onSupports: _rien,
);

const Map<String, Size> _tailles = <String, Size>{
  'mobile': Size(390, 844),
  'web etroit': Size(640, 1000),
  'desktop': Size(1440, 900),
};

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
      SalleSeance(
        vue: DonneesSeanceDemo.vue(
          role,
          EtatDemoSalle.supports,
        ).copyWith(panneau: PanneauOuvert.supports),
        actions: actions,
      ),
      themeMode: mode,
      interfaceMode: role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

bool _chevauche(Rect a, Rect b) =>
    a.intersect(b).width > 0.5 && a.intersect(b).height > 0.5;

void main() {
  group('Panneau Supports (CLV-08)', () {
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
          expect(find.byType(PanneauSupports), findsNothing);
          expect(find.byType(PanneauSeance), findsNothing);
          expect(find.text(t.salle.seance.supports), findsNothing);
          expect(
            find.text(t.salle.seance.panneauSupports.voirBibliotheque),
            findsNothing,
          );
        });
      }

      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('enseignant ${taille.key} ${mode.name} : rubriques, une '
            'seule action pleine, sans chevauchement', (
          WidgetTester tester,
        ) async {
          await _monter(tester, taille.value, mode: mode);
          expect(tester.takeException(), isNull);
          expect(find.byType(PanneauSupports), findsOneWidget);
          final String forme = switch (taille.key) {
            'desktop' => 'colonne',
            'web etroit' => 'volet',
            _ => 'feuille',
          };
          // TB-5 : sur bureau, la colonne des Participants est aussi la (a
          // gauche) ; le panneau Supports est celui qui contient la liste.
          expect(
            find.ancestor(
              of: find.byType(PanneauSupports),
              matching: find.byKey(ValueKey<String>('panneau-seance-$forme')),
            ),
            findsOneWidget,
          );
          Finder dansPanneau(Finder f) =>
              find.descendant(of: find.byType(PanneauSupports), matching: f);
          for (final String texte in <String>[
            t.salle.seance.panneauSupports.reprendre,
            'Chapitre 1',
            'Les bonnes manières',
            'Support de cours · v2.0',
            t.salle.seance.panneauSupports.recents,
            'Fiche de mémorisation',
            'PDF · 12 pages · v1.1',
            'Exercices – Chapitre 1',
            'PDF · 8 pages · v1.0',
            t.salle.seance.panneauSupports.ressourcesClasse,
            'Bibliothèque An-Nour',
            '24 ressources',
          ]) {
            await tester.scrollUntilVisible(
              dansPanneau(find.text(texte)),
              50,
              scrollable: dansPanneau(find.byType(Scrollable)).first,
            );
            expect(dansPanneau(find.text(texte)), findsOneWidget);
            // « Voir tout » : Recents partout, Ressources hors desktop. Mesure
            // dans la ligne de son titre : la liste est paresseuse, et la
            // feuille s'arrete au-dessus de la barre de l'appel (TB-2).
            final bool recents =
                texte == t.salle.seance.panneauSupports.recents;
            final bool classe =
                texte == t.salle.seance.panneauSupports.ressourcesClasse;
            if (recents || classe) {
              expect(
                find.descendant(
                  of: find
                      .ancestor(
                        of: find.text(texte),
                        matching: find.byType(Row),
                      )
                      .first,
                  matching: find.text(t.salle.seance.panneauSupports.voirTout),
                ),
                recents || taille.key != 'desktop'
                    ? findsOneWidget
                    : findsNothing,
                reason: texte,
              );
            }
          }
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey<String>('voir-bibliotheque')),
            50,
            scrollable: dansPanneau(find.byType(Scrollable)).first,
          );
          // Une seule action pleine dans le panneau.
          final Iterable<ActionPrincipale> actions = tester
              .widgetList<ActionPrincipale>(
                dansPanneau(find.byType(ActionPrincipale)),
              );
          expect(
            actions.where(
              (ActionPrincipale a) => a.niveau == NiveauAction.principale,
            ),
            hasLength(1),
          );
          expect(
            actions
                .firstWhere(
                  (ActionPrincipale a) => a.niveau == NiveauAction.principale,
                )
                .libelle,
            t.salle.seance.panneauSupports.voirBibliotheque,
          );
          // Aucun chevauchement : le panneau ne couvre ni le dock ; en
          // desktop, ni le support ; le panneau tient dans l'ecran.
          final Rect panneau = tester.getRect(
            find.ancestor(
              of: find.byType(PanneauSupports),
              matching: find.byKey(ValueKey<String>('panneau-seance-$forme')),
            ),
          );
          final Rect ecran = Offset.zero & taille.value;
          expect(ecran.contains(panneau.topLeft), isTrue);
          expect(panneau.right <= ecran.right + 0.5, isTrue);
          expect(panneau.bottom <= ecran.bottom + 0.5, isTrue);
          if (taille.key != 'mobile') {
            expect(
              _chevauche(panneau, tester.getRect(find.byType(DockSeance))),
              isFalse,
            );
          }
          if (taille.key == 'desktop') {
            expect(
              _chevauche(panneau, tester.getRect(find.byType(ZoneSupport))),
              isFalse,
            );
            // TB-4 : plus de carte d'outils permanente (dans les
            // Commandes). TB-5 (n. 12, n. 13) : Supports a droite du
            // support, les Participants en colonne a gauche.
            expect(find.text(t.salle.seance.outils.titre), findsNothing);
            final Rect zone = tester.getRect(find.byType(ZoneSupport));
            expect(panneau.left, greaterThan(zone.right));
            expect(
              tester.getRect(find.byType(PanneauEleves)).right,
              lessThan(zone.left),
            );
          }
        });
      }
    }

    testWidgets('« Ouvrir » passe le support de Reprendre', (
      WidgetTester tester,
    ) async {
      _ouverts.clear();
      await _monter(tester, const Size(1440, 900));
      await tester.tap(
        find.byKey(const ValueKey<String>('ouvrir-demo-chapitre-1')),
      );
      await tester.tap(find.text('Fiche de mémorisation'));
      expect(_ouverts, <String>['demo-chapitre-1', 'demo-fiche-memorisation']);
    });

    testWidgets('rappels nuls (/salle avant BR-1) : aucun bouton rendu', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(1440, 900), actions: _salle);
      expect(tester.takeException(), isNull);
      expect(find.byType(PanneauSupports), findsOneWidget);
      expect(find.text(t.salle.seance.panneauSupports.ouvrir), findsNothing);
      expect(find.text(t.salle.seance.panneauSupports.voirTout), findsNothing);
      expect(
        find.text(t.salle.seance.panneauSupports.voirBibliotheque),
        findsNothing,
      );
    });

    testWidgets('demonstration : « Ouvrir » change le support et ferme', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const SalleDemo(
            role: RoleSeance.enseignant,
            etat: EtatDemoSalle.supports,
            onSortir: _rien,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PanneauSupports), findsOneWidget);
      await tester.tap(find.text('Exercices – Chapitre 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PanneauSupports), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ZoneSupport),
          matching: find.text('Associer chaque situation à la bonne manière.'),
        ),
        findsOneWidget,
      );
    });
  });

  // Mesures sur les polices du depot (relecture T6) : en dernier, car le
  // chargement vaut pour tout le fichier.
  group('Panneau Supports : mesures (relecture T6)', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('telephone 390x844 : tout le panneau tient, action pleine '
        'comprise, sans defiler (relecture T6)', (WidgetTester tester) async {
      fixerVueCapture(
        tester,
        const Size(390, 844),
        3,
        zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
      );
      await tester.pumpWidget(
        hoteCapture(
          SalleSeance(
            vue: DonneesSeanceDemo.vue(
              RoleSeance.enseignant,
              EtatDemoSalle.supports,
            ).copyWith(panneau: PanneauOuvert.supports),
            actions: _complet,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final Rect cta = tester.getRect(
        find.byKey(const ValueKey<String>('voir-bibliotheque')),
      );
      expect(cta.bottom, lessThanOrEqualTo(844));
    });

    for (final MapEntry<String, Size> taille in _tailles.entries) {
      testWidgets('« Ouvrir » est une petite pastille (${taille.key})', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille.value);
        // La pastille est la surface peinte de l'ActionPrincipale compacte (la
        // cible tactile de 48 qui l'entoure n'est pas dessinee).
        final Rect pastille = tester.getRect(
          find
              .descendant(
                of: find.byKey(
                  const ValueKey<String>('ouvrir-demo-chapitre-1'),
                ),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(pastille.height, lessThanOrEqualTo(40));
        expect(pastille.width, lessThanOrEqualTo(90));
        // Le titre de Reprendre tient sur une ligne a cote de la pastille.
        final Finder titre = find.descendant(
          of: find.byType(PanneauSupports),
          matching: find.text('Les bonnes manières'),
        );
        expect(tester.getSize(titre).height, lessThanOrEqualTo(28));
      });
    }
  });
}
