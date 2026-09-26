// Tests manques releves par la revue croisee CL-R (fichier separe pour ne
// pas alourdir revue_cl_r_test.dart) :
// 1. ZoomLocal : taper - et + appelle bien les rappels.
// 2. PaginationSupport : taper precedente/suivante appelle les rappels ;
//    boutons desactives aux bornes (page 1 et derniere page).
// 3. RailSeance avec confirmerSortie:false (FinSeanceEnseignant) : la
//    navigation est directe, sans le dialogue de confirmation.
// 4. Salle eleve, guidee et enseignant (repos) a 320 px et texte 200 % :
//    aucun debordement.
// Corrige aussi deux defauts constates par la revue :
// 5. barre_support.dart _IconeBarre : inkFaint pour tout bouton sans rappel,
//    pas seulement le chevron.
// 6. BoutonPanneau (salle_seance.dart) : plus de double lecture du libelle
//    par le lecteur d'ecran.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/rail_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_catalogue/routes_tc_b.dart';

import '../../capture/outil_capture.dart';

void _rien() {}
void _outil(OutilEnseignement _) {}
void _aller(String _) {}

/// Retrouve le [Pressable] dont la semantique porte exactement [libelle].
Finder _pressablePar(String libelle) => find.byWidgetPredicate(
  (Widget w) => w is Pressable && w.libelleSemantique == libelle,
);

const ActionsSeance _actionsEleve = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onAgrandir: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
);

const ActionsSeance _actionsEnseignant = ActionsSeance(
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
);

void main() {
  group('ZoomLocal (barre_support.dart)', () {
    testWidgets('taper - et + appelle onZoomMoins / onZoomPlus', (
      WidgetTester tester,
    ) async {
      int moins = 0;
      int plus = 0;
      await tester.pumpWidget(
        hoteCapture(
          Center(
            child: ZoomLocal(
              zoom: 1,
              onMoins: () => moins++,
              onPlus: () => plus++,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(_pressablePar(t.salle.seance.zoomMoins));
      await tester.pump();
      expect(moins, 1);
      expect(plus, 0);

      await tester.tap(_pressablePar(t.salle.seance.zoomPlus));
      await tester.pump();
      expect(moins, 1);
      expect(plus, 1);
    });

    testWidgets(
      'defaut 5 : sans rappel, - et + prennent inkFaint (pas seulement le '
      'chevron)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hoteCapture(const Center(child: ZoomLocal(zoom: 1))),
        );
        await tester.pump();
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(ZoomLocal)),
        );
        final Color attendu =
            palette.inkFaint.asIconTheme(size: AppSpacing.xxl).color!;

        final IconTheme themeMoins = tester.widget<IconTheme>(
          find
              .ancestor(
                of: find.byIcon(AppIcons.zoomMoins.repos),
                matching: find.byType(IconTheme),
              )
              .first,
        );
        final IconTheme themePlus = tester.widget<IconTheme>(
          find
              .ancestor(
                of: find.byIcon(AppIcons.zoomPlus.repos),
                matching: find.byType(IconTheme),
              )
              .first,
        );
        expect(themeMoins.data.color, attendu);
        expect(themePlus.data.color, attendu);
      },
    );
  });

  group('PaginationSupport (barre_support.dart:56-74)', () {
    testWidgets('taper precedente et suivante appelle les rappels', (
      WidgetTester tester,
    ) async {
      int precedente = 0;
      int suivante = 0;
      await tester.pumpWidget(
        hoteCapture(
          Center(
            child: PaginationSupport(
              page: 2,
              pages: 3,
              onPrecedente: () => precedente++,
              onSuivante: () => suivante++,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(_pressablePar(t.salle.seance.pagePrecedente));
      await tester.pump();
      expect(precedente, 1);
      expect(suivante, 0);

      await tester.tap(_pressablePar(t.salle.seance.pageSuivante));
      await tester.pump();
      expect(precedente, 1);
      expect(suivante, 1);
    });

    testWidgets('page 1 : precedente desactivee, aucun rappel possible', (
      WidgetTester tester,
    ) async {
      int precedente = 0;
      await tester.pumpWidget(
        hoteCapture(
          Center(
            child: PaginationSupport(
              page: 1,
              pages: 3,
              onPrecedente: () => precedente++,
              onSuivante: _rien,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_pressablePar(t.salle.seance.pagePrecedente), findsNothing);
      expect(precedente, 0);

      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(PaginationSupport)),
      );
      final IconTheme themePrecedente = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byIcon(AppIcons.chevron.repos).first,
              matching: find.byType(IconTheme),
            )
            .first,
      );
      expect(
        themePrecedente.data.color,
        palette.inkFaint.asIconTheme(size: AppSpacing.xxl).color,
      );
    });

    testWidgets('derniere page : suivante desactivee, aucun rappel possible', (
      WidgetTester tester,
    ) async {
      int suivante = 0;
      await tester.pumpWidget(
        hoteCapture(
          Center(
            child: PaginationSupport(
              page: 3,
              pages: 3,
              onPrecedente: _rien,
              onSuivante: () => suivante++,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_pressablePar(t.salle.seance.pageSuivante), findsNothing);
      expect(suivante, 0);
    });
  });

  group('RailSeance : confirmerSortie:false (FinSeanceEnseignant)', () {
    testWidgets('taper navigue directement, sans le dialogue de sortie', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(800, 900), 1);
      final List<String> routes = <String>[];
      await tester.pumpWidget(
        hoteCapture(
          RailSeance(
            onNaviguer: routes.add,
            groupeId: 'demo-an-nour',
            confirmerSortie: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(_pressablePar(t.salle.seance.rail.ressources));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ConfirmDestructive), findsNothing);
      expect(find.text(t.salle.seance.quitterQuestion), findsNothing);
      expect(routes, <String>[RoutesTcB.bibliotheque]);
    });
  });

  group('320 px, texte 200 % : aucun debordement', () {
    Future<void> monter(
      WidgetTester tester,
      RoleSeance role,
      ActionsSeance actions, {
      InterfaceMode mode = InterfaceMode.standard,
    }) async {
      fixerVueCapture(tester, const Size(320, 1400), 1);
      await tester.pumpWidget(
        hoteCapture(
          SalleSeance(
            vue: DonneesSeanceDemo.vue(role, EtatDemoSalle.repos),
            actions: actions,
          ),
          echelleTexte: 2,
          interfaceMode: mode,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('eleve standard', (WidgetTester tester) async {
      await monter(tester, RoleSeance.eleve, _actionsEleve);
      expect(tester.takeException(), isNull);
    });

    testWidgets('eleve guidee', (WidgetTester tester) async {
      await monter(
        tester,
        RoleSeance.guidee,
        _actionsEleve,
        mode: InterfaceMode.enfant,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('enseignant (repos)', (WidgetTester tester) async {
      await monter(tester, RoleSeance.enseignant, _actionsEnseignant);
      expect(tester.takeException(), isNull);
    });
  });

  group('BoutonPanneau (salle_seance.dart) : une seule lecture', () {
    testWidgets('le libelle n\'est pas lu deux fois par le lecteur d\'ecran', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        hoteCapture(
          const Center(
            child: BoutonPanneau(
              icone: AppIcons.eleves,
              libelle: 'Élèves 1/3',
              onPress: _rien,
            ),
          ),
        ),
      );
      await tester.pump();

      final SemanticsNode noeud = tester.getSemantics(
        find.byType(BoutonPanneau),
      );
      expect(noeud.label, 'Élèves 1/3');
      expect(noeud.label.split('Élèves 1/3').length - 1, 1);
      semantique.dispose();
    });
  });
}
