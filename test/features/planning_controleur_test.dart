import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/controle/service_controle.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/controleur/planning_page.dart';

import '../support/harnais.dart';

/// Une fenetre haute, et large ou etroite selon ce qu'on mesure.
///
/// **Haute** parce que la fenetre par defaut de `flutter_test` fait 800 x 600,
/// gabarit tablette plus court que tout telephone : ce qui depasse n'est
/// simplement pas construit. **La largeur est un sujet** ici comme a `ADM-04` :
/// au dela de 1024 le planning rend un tableau dense, en dessous une carte par
/// seance.
void _fenetre(WidgetTester tester, {double largeur = 1400}) {
  tester.view.physicalSize = Size(largeur, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Le 13 septembre 2026 a 10h30, fige.
final DateTime _maintenant = DateTime(2026, 9, 13, 10, 30);

Seance _seance({
  required String id,
  required int debutDansMinutes,
  int duree = 60,
  StatutSeance? statut = StatutSeance.planifiee,
  String enseignantId = 't1',
  String enseignantPrenom = 'Rachid',
  String elevePrenom = 'Sofia',
}) {
  final DateTime debut = _maintenant.add(Duration(minutes: debutDansMinutes));
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(Duration(minutes: duree)),
    statut: statut,
    eleveId: 'e-$id',
    elevePrenom: elevePrenom,
    eleveIdentifiant: 'STUD-000001',
    enseignantId: enseignantId,
    enseignantPrenom: enseignantPrenom,
    enseignantIdentifiant: 'TEACH-000001',
  );
}

/// La derniere salle ouverte, et le billet presente pour y entrer.
BilletSalle? _billet;

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceControle controle,
  required FauxServiceVideo video,
}) async {
  _billet = null;
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.controleur,
      surcharges: <Override>[
        serviceControleProvider.overrideWithValue(controle),
        serviceVideoProvider.overrideWithValue(video),
      ],
      routes: <RouteBase>[
        GoRoute(
          path: Routes.controleur,
          builder: (BuildContext _, GoRouterState _) =>
              PlanningControleurPage(horloge: () => _maintenant),
        ),
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState etat) {
            _billet = etat.extra is BilletSalle
                ? etat.extra! as BilletSalle
                : null;
            return const Scaffold(body: Text('salle'));
          },
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CTR-01 : on n\'entre que dans ce qui a lieu maintenant', () {
    testWidgets('le cours en direct porte le bouton, pas celui qui arrive', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        controle: FauxServiceControle(
          seancesRendues: <Seance>[
            _seance(id: 'direct', debutDansMinutes: -5),
            _seance(id: 'futur', debutDansMinutes: 90, elevePrenom: 'Ines'),
          ],
        ),
        video: FauxServiceVideo(),
      );

      // Deux seances, un seul bouton : le second n'est pas grise, il n'existe
      // pas (`ENS-02` applique deja cette regle a son lancement).
      expect(
        find.widgetWithText(
          ActionPrincipale,
          t.controleur.planning.observer,
        ),
        findsOneWidget,
      );
      expect(find.text('Sofia · STUD-000001'), findsOneWidget);
      expect(find.text('Ines · STUD-000001'), findsOneWidget);
    });

    testWidgets('presser Observer inscrit d\'abord, puis ouvre la salle', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceVideo video = FauxServiceVideo();
      await _monter(
        tester,
        controle: FauxServiceControle(
          seancesRendues: <Seance>[_seance(id: 'direct', debutDansMinutes: -5)],
        ),
        video: video,
      );

      await tester.tap(find.text(t.controleur.planning.observer));
      await tester.pumpAndSettle();

      // L'ordre est le sujet : sans inscription prealable, le jeton video est
      // refuse (« non inscrit a cette seance ») et la salle affiche son impasse.
      expect(video.observations, <String>['direct']);
      expect(find.text('salle'), findsOneWidget);
      expect(_billet?.sessionId, 'direct');
    });

    testWidgets('un refus de la porte n\'ouvre aucune salle et se dit', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceVideo video = FauxServiceVideo()
        ..refusInscription = StateError('seance close');
      await _monter(
        tester,
        controle: FauxServiceControle(
          seancesRendues: <Seance>[_seance(id: 'direct', debutDansMinutes: -5)],
        ),
        video: video,
      );

      await tester.tap(find.text(t.controleur.planning.observer));
      await tester.pumpAndSettle();

      expect(find.text('salle'), findsNothing);
      expect(_billet, isNull);
      expect(find.text(t.controleur.planning.entreeRefusee), findsOneWidget);
    });

    testWidgets('le rappel de journalisation est la, visite ou pas', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        controle: FauxServiceControle(),
        video: FauxServiceVideo(),
      );

      // Permanent, comme le bandeau de la salle l'est pour les participants :
      // l'ecran qui declenche la visite est le dernier endroit ou l'on devrait
      // apprendre apres coup qu'elle est tracee (ADR-011).
      expect(
        find.text(t.controleur.planning.visiteJournalisee),
        findsOneWidget,
      );
    });
  });

  group('CTR-01 : deux heures, deux rendus, trois etats vides', () {
    testWidgets('le tableau dense sort au desktop, pas au telephone', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceControle controle = FauxServiceControle(
        seancesRendues: <Seance>[_seance(id: 'direct', debutDansMinutes: -5)],
      );
      await _monter(
        tester,
        controle: controle,
        video: FauxServiceVideo(),
      );

      // L'en-tete de colonnes n'existe qu'en rendu tableau.
      expect(
        find.text(t.controleur.planning.colonneEnseignant),
        findsOneWidget,
      );

      _fenetre(tester, largeur: 390);
      await tester.pumpAndSettle();

      expect(find.text(t.controleur.planning.colonneEnseignant), findsNothing);
      // L'heure UTC, elle, reste lisible sur les deux : c'est une precision,
      // pas une colonne de confort.
      expect(find.textContaining('UTC'), findsOneWidget);
    });

    testWidgets('un planning vide n\'est pas une panne', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        controle: FauxServiceControle(),
        video: FauxServiceVideo(),
      );

      expect(find.text(t.controleur.planning.vide), findsOneWidget);
      // Aucun bouton : il n'y a rien a relacher, et rien a reessayer.
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('une liste vide sous filtre propose d\'en sortir', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        controle: FauxServiceControle(
          seancesRendues: <Seance>[_seance(id: 'futur', debutDansMinutes: 90)],
        ),
        video: FauxServiceVideo(),
      );

      await tester.tap(
        find.widgetWithText(FilterPill, t.controleur.planning.etatEnCours),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.controleur.planning.videFiltre), findsOneWidget);

      await tester.tap(find.text(t.controleur.planning.effacerFiltres));
      await tester.pumpAndSettle();

      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
    });

    testWidgets('une lecture impossible se dit et se reessaie', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceControle controle = FauxServiceControle()
        ..erreurAJeter = StateError('reseau');
      await _monter(
        tester,
        controle: controle,
        video: FauxServiceVideo(),
      );

      expect(find.text(t.controleur.planning.erreur), findsOneWidget);

      controle
        ..erreurAJeter = null
        ..seancesRendues = <Seance>[_seance(id: 'direct', debutDansMinutes: -5)];
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();

      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
    });

    testWidgets('le squelette precede la premiere lecture', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      // Le faux prend son temps : sans delai, il repond dans la micro-tache
      // suivante et l'ecran n'est jamais en chargement pendant une frame.
      final FauxServiceControle controle = FauxServiceControle()
        ..delai = const Duration(milliseconds: 50);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.controleur,
          surcharges: <Override>[
            serviceControleProvider.overrideWithValue(controle),
            serviceVideoProvider.overrideWithValue(FauxServiceVideo()),
          ],
          routes: <RouteBase>[
            GoRoute(
              path: Routes.controleur,
              builder: (BuildContext _, GoRouterState _) =>
                  PlanningControleurPage(horloge: () => _maintenant),
            ),
          ],
        ),
      );
      // Une seule frame : la lecture n'a pas encore rendu la main.
      await tester.pump();

      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);

      await tester.pumpAndSettle();
    });
  });

  group('CTR-01 : les filtres', () {
    testWidgets('la rangee des enseignants n\'apparait qu\'a partir de deux', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        controle: FauxServiceControle(
          seancesRendues: <Seance>[_seance(id: 'a', debutDansMinutes: -5)],
        ),
        video: FauxServiceVideo(),
      );

      // Un seul enseignant au planning : proposer « tous les enseignants »
      // serait un filtre sans choix.
      expect(find.text(t.controleur.planning.tousEnseignants), findsNothing);
    });

    testWidgets('retenir un enseignant ne retient que ses seances', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        controle: FauxServiceControle(
          seancesRendues: <Seance>[
            _seance(id: 'a', debutDansMinutes: -5),
            _seance(
              id: 'b',
              debutDansMinutes: 60,
              enseignantId: 't2',
              enseignantPrenom: 'Hafsa',
              elevePrenom: 'Ines',
            ),
          ],
        ),
        video: FauxServiceVideo(),
      );

      expect(find.text(t.controleur.planning.tousEnseignants), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterPill, 'Hafsa'));
      await tester.pumpAndSettle();

      expect(find.text('Ines · STUD-000001'), findsOneWidget);
      expect(find.text('Sofia · STUD-000001'), findsNothing);
    });
  });
}
