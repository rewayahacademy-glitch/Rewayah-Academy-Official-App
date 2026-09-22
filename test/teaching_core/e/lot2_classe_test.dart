import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/commandes_classe.dart';
import 'package:rewayah_academy/features/tc_classe_live/entree_salle.dart';
import 'package:rewayah_academy/features/tc_classe_live/roster_classe.dart';
import 'package:rewayah_academy/features/tc_classe_live/scene_classe.dart';
import 'package:rewayah_academy/features/tc_classe_live/vue_classe_live.dart';
import 'package:rewayah_academy/features/tc_dock/teaching_dock.dart';

import 'faux/faux_classe.dart';
import 'support/hote_classe.dart';

/// Le lot 2 : une seule coque, des commandes qui disent l'etat du materiel,
/// une composition qui distingue le portrait du paysage, une porte `/salle`
/// qui decide de la sortie.
void main() {
  const String seance = 's1';

  ({
    FauxMoteurClasse moteur,
    FauxServiceVideoClasse video,
    FauxPreVolClasse preVol,
    List<Override> surcharges,
  })
  banc({String role = 'teacher', FauxPreVolClasse? preVol}) {
    final FauxMoteurClasse moteur = FauxMoteurClasse();
    final FauxServiceVideoClasse video = FauxServiceVideoClasse(
      acces0: accesDe(role, camera: true),
    );
    final FauxPreVolClasse mesure = preVol ?? FauxPreVolClasse();
    return (
      moteur: moteur,
      video: video,
      preVol: mesure,
      surcharges: surchargesClasse(
        moteur: moteur,
        video: video,
        preVol: mesure,
      ),
    );
  }

  ContexteClasseLive contexte({
    String? support,
    void Function(SortieClasse)? onSortie,
  }) => ContexteClasseLive(
    sessionId: seance,
    groupeId: 'g1',
    libelleGroupe: 'Groupe Al-Fatiha',
    supportActifId: support,
    support: support == null
        ? null
        : (BuildContext _) => const Text('support presente'),
    onSortie: onSortie,
  );

  group('etat d un peripherique : fonction pure', () {
    test('l ordre est celui de la verite', () {
      expect(
        etatPeripherique(
          ouvert: true,
          disponible: true,
          permissionRefusee: false,
          enCours: true,
          erreur: true,
        ),
        EtatPeripherique.enCours,
      );
      expect(
        etatPeripherique(
          ouvert: true,
          disponible: false,
          permissionRefusee: true,
          enCours: false,
          erreur: true,
        ),
        EtatPeripherique.erreur,
      );
      expect(
        etatPeripherique(
          ouvert: false,
          disponible: false,
          permissionRefusee: true,
          enCours: false,
          erreur: false,
        ),
        EtatPeripherique.permissionRefusee,
      );
      expect(
        etatPeripherique(
          ouvert: false,
          disponible: false,
          permissionRefusee: false,
          enCours: false,
          erreur: false,
        ),
        EtatPeripherique.absent,
      );
      expect(
        etatPeripherique(
          ouvert: true,
          disponible: true,
          permissionRefusee: false,
          enCours: false,
          erreur: false,
        ),
        EtatPeripherique.ouvert,
      );
    });

    test('seuls ferme et ouvert se reglent', () {
      for (final EtatPeripherique etat in EtatPeripherique.values) {
        expect(
          peripheriqueReglable(etat),
          etat == EtatPeripherique.ferme || etat == EtatPeripherique.ouvert,
          reason: '$etat',
        );
      }
    });
  });

  group('commandes', () {
    testWidgets('une camera absente se dit, elle n est pas cachee', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(preVol: FauxPreVolClasse(cameraDisponible: false));
      await monterClasse(
        tester,
        contexte: contexte(),
        surcharges: banc0.surcharges,
      );

      // Le jeton permet la camera : le bouton existe. Le materiel ne la
      // fournit pas : le bouton le dit, et un appui ne demande rien au moteur.
      expect(find.text(t.tc.classe.commandes.cameraAbsente), findsOneWidget);
      await tester.tap(find.text(t.tc.classe.commandes.cameraAbsente));
      await tester.pump();
      expect(banc0.moteur.cameraDemandee, isEmpty);
    });

    testWidgets('un lien sain ne dit rien en bas non plus', (
      WidgetTester tester,
    ) async {
      final banc0 = banc();
      await monterClasse(
        tester,
        contexte: contexte(),
        surcharges: banc0.surcharges,
      );
      banc0.moteur.publierQualite(QualiteLien.bonne);
      await tester.pump();

      expect(find.text(t.tc.classe.reseau.bon), findsNothing);

      banc0.moteur.publierQualite(QualiteLien.mediocre);
      await tester.pump();
      expect(find.text(t.tc.classe.reseau.mediocre), findsOneWidget);
    });

    testWidgets('les commandes sont rondes, le micro s ouvre par son acte', (
      WidgetTester tester,
    ) async {
      final banc0 = banc();
      await monterClasse(
        tester,
        contexte: contexte(),
        surcharges: banc0.surcharges,
      );

      expect(find.byType(CommandeRonde), findsNWidgets(4));
      await tester.tap(find.text(t.tc.classe.commandes.microCourt));
      await tester.pump();
      expect(banc0.moteur.microDemande, <bool>[true]);
    });
  });

  group('composition', () {
    testWidgets('telephone portrait : la vignette est SOUS le support', (
      WidgetTester tester,
    ) async {
      final banc0 = banc();
      await monterClasse(
        tester,
        contexte: contexte(support: 'coran'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.mobile,
      );
      banc0.moteur.publier(<ParticipantSalle>[
        participantDe(identite: 'p1', role: 'student', nom: 'Amina'),
      ]);
      await tester.pump();

      final Rect support = tester.getRect(find.text('support presente'));
      final Rect scene = tester.getRect(find.byType(SceneClasse));
      expect(scene.top, greaterThanOrEqualTo(support.bottom));
      expect(find.byType(PanneauRoster), findsNothing);
      expect(find.byType(BoutonRoster), findsOneWidget);
    });

    testWidgets('telephone paysage : composition courte, pas tablette', (
      WidgetTester tester,
    ) async {
      final banc0 = banc();
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteClasse(
          ClasseLivePage(contexte: contexte(support: 'coran')),
          surcharges: banc0.surcharges,
        ),
      );
      await tester.pumpAndSettle();
      banc0.moteur.publier(<ParticipantSalle>[
        participantDe(identite: 'p1', role: 'student', nom: 'Amina'),
      ]);
      await tester.pump();

      // Large comme une tablette, court comme un telephone : le roster est
      // replie et la video est une vignette a cote, jamais une colonne de
      // 256 points qui etranglerait le Coran.
      expect(find.byType(PanneauRoster), findsNothing);
      expect(find.byType(BoutonRoster), findsOneWidget);
      final Rect support = tester.getRect(find.text('support presente'));
      final Rect scene = tester.getRect(find.byType(SceneClasse));
      expect(scene.left, greaterThanOrEqualTo(support.right));
      expect(support.width, greaterThan(scene.width * 2));
    });

    testWidgets('le dock est heberge sans couvrir le support', (
      WidgetTester tester,
    ) async {
      final banc0 = banc();
      await monterClasse(
        tester,
        contexte: contexte(support: 'coran'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      expect(find.byType(HoteDuDock), findsOneWidget);
      expect(find.byType(TeachingDock), findsOneWidget);
      // L'hote reserve la place du dock : le support ne descend pas sous lui.
      final Rect dock = tester.getRect(find.byType(TeachingDock));
      final Rect support = tester.getRect(find.text('support presente'));
      expect(support.bottom, lessThanOrEqualTo(dock.top));
    });

    testWidgets('un eleve n a pas de dock, et lit sa presence', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(role: 'student');
      await monterClasse(
        tester,
        contexte: contexte(support: 'coran'),
        surcharges: banc0.surcharges,
      );

      expect(find.byType(TeachingDock), findsNothing);
      expect(find.text(t.presence.mienne), findsOneWidget);
    });
  });

  group('rappels par role', () {
    for (final (String role, String Function() texte)
        in <(String, String Function())>[
          ('masked_controller', () => t.salle.bandeauControle),
          ('admin_masked', () => t.tc.classe.rappel.adminIncognito),
          ('guardian_observer', () => t.salle.observationMuette),
        ]) {
      testWidgets('$role lit son rappel', (WidgetTester tester) async {
        final banc0 = banc(role: role);
        await monterClasse(
          tester,
          contexte: contexte(),
          surcharges: banc0.surcharges,
        );

        expect(find.text(texte()), findsOneWidget);
        // Aucun micro, aucune camera : le jeton n'en donne pas.
        expect(find.byType(CommandeRonde), findsOneWidget);
      });
    }
  });

  group('la porte /salle', () {
    Future<void> monterPorte(
      WidgetTester tester, {
      required BilletSalle billet,
      required List<Override> surcharges,
    }) async {
      poserEcran(tester, LargeurEcran.tablette);
      await tester.pumpWidget(
        ProviderScope(
          overrides: surcharges,
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: GoRouter(
                initialLocation: Routes.salle,
                routes: <RouteBase>[
                  GoRoute(
                    path: Routes.salle,
                    builder: (BuildContext _, GoRouterState _) =>
                        EntreeSalle(billet: billet),
                  ),
                  GoRoute(
                    path: Routes.cahierPour(seance),
                    builder: (BuildContext _, GoRouterState _) =>
                        const Text('cahier'),
                  ),
                  GoRoute(
                    path: Routes.racine,
                    builder: (BuildContext _, GoRouterState _) =>
                        const Text('racine'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sans groupe connu, le cours a quand meme un nom', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(role: 'student');
      await monterPorte(
        tester,
        billet: BilletSalle(
          sessionId: seance,
          emisA: DateTime.now(),
          enseignantPrenom: 'Youssouf',
        ),
        surcharges: banc0.surcharges,
      );

      expect(find.text(t.tc.classe.entete.sansGroupe), findsOneWidget);
      expect(find.text('Youssouf'), findsOneWidget);
      expect(find.text(t.tc.classe.entete.photoManquante), findsNothing);
    });

    testWidgets('l enseignant qui a tenu le cours sort vers le cahier', (
      WidgetTester tester,
    ) async {
      final banc0 = banc();
      await monterPorte(
        tester,
        billet: BilletSalle(
          sessionId: seance,
          emisA: DateTime.now(),
          groupeId: 'g1',
          libelleGroupe: 'Groupe Al-Fatiha',
        ),
        surcharges: banc0.surcharges,
      );
      expect(find.text('Groupe Al-Fatiha'), findsWidgets);

      await tester.tap(find.text(t.tc.classe.commandes.quitter).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.tc.classe.commandes.quitter).last);
      await tester.pumpAndSettle();

      expect(find.text('cahier'), findsOneWidget);
      expect(banc0.moteur.departs, 1);
    });

    testWidgets('un eleve sort vers sa racine', (WidgetTester tester) async {
      final banc0 = banc(role: 'student');
      await monterPorte(
        tester,
        billet: BilletSalle(sessionId: seance, emisA: DateTime.now()),
        surcharges: banc0.surcharges,
      );

      await tester.tap(find.text(t.tc.classe.commandes.quitter).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.tc.classe.commandes.quitter).last);
      await tester.pumpAndSettle();

      expect(find.text('racine'), findsOneWidget);
    });
  });

  group('VueClasseLive et la hauteur courte', () {
    test('un ecran court se compose comme un telephone', () {
      // Verifie par le widget ci-dessus a 844 x 390 ; ici la regle nue.
      expect(VueClasseLive.seuilHauteurCourte, 500);
    });
  });
}
