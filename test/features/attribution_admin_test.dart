import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_attribution.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_attribution/attribution_page.dart';

import '../support/garde_interface.dart';

import '../support/harnais.dart';

/// Une fenetre large et haute.
///
/// **Large** parce que `ADM-05` est un ecran a deux colonnes : sous 600 px il
/// replie la file des que l'on choisit un eleve, et la moitie des assertions
/// porteraient alors sur le repli plutot que sur la regle. **Haute** parce que
/// la fenetre par defaut de `flutter_test` fait 800 x 600, gabarit tablette plus
/// court que tout telephone : ce qui depasse n'est simplement pas construit.
void _fenetre(WidgetTester tester, {double largeur = 1400}) {
  tester.view.physicalSize = Size(largeur, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Creneau _creneau(int jour, int heure) =>
    Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris');

FoyerEnAttente _eleve({
  String id = 'e1',
  String prenom = 'Yacine',
  List<Creneau>? creneaux,
  DateTime? depuis,
}) => FoyerEnAttente(
  eleveId: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-A5-000001',
  foyerId: 'f1',
  mode: InterfaceMode.enfant,
  niveau: 'debutant',
  depuis: depuis ?? DateTime.now().subtract(const Duration(days: 12)),
  creneaux: creneaux ?? <Creneau>[_creneau(2, 17)],
);

EnseignantCandidat _enseignant({
  String id = 't1',
  String prenom = 'Omar',
  List<Creneau> communs = const <Creneau>[],
  int actifs = 1,
  int plafond = 5,
}) => EnseignantCandidat(
  id: id,
  prenom: prenom,
  nom: 'Sow',
  identifiantImmuable: 'TEACH-A5-000001',
  elevesActifs: actifs,
  plafond: plafond,
  creneauxCommuns: communs,
);

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAttribution service,
  required FauxServiceAdmin admin,
}) async {
  await tester.pumpWidget(
    hote(
      const AttributionPage(),
      surcharges: <Override>[
        serviceAttributionProvider.overrideWithValue(service),
        serviceAdminProvider.overrideWithValue(admin),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ADM-05 : cartes separees de 16 (K-55)', () {
    for (final double largeur in <double>[700, 1400]) {
      testWidgets('les enseignants proposes ne se collent pas a $largeur px', (
        WidgetTester tester,
      ) async {
        _fenetre(tester, largeur: largeur);
        final FauxServiceAttribution service = FauxServiceAttribution()
          ..foyers = <FoyerEnAttente>[_eleve()]
          ..enseignants['e1'] = <EnseignantCandidat>[
            _enseignant(communs: <Creneau>[_creneau(2, 17)]),
            _enseignant(
              id: 't2',
              prenom: 'Ibrahim',
              communs: <Creneau>[_creneau(2, 17)],
            ),
            _enseignant(
              id: 't3',
              prenom: 'Awa',
              communs: <Creneau>[_creneau(2, 17)],
            ),
          ];

        await _monter(tester, service: service, admin: FauxServiceAdmin());
        await tester.tap(find.text('Yacine'));
        await tester.pumpAndSettle();
        // Le choix d'un enseignant insere la confirmation entre deux cartes :
        // le cas le plus serre, avec la liste sans choix.
        verifierAucuneCarteCollee(tester, estCarte: (Widget w) => w is AppCard);
        await tester.tap(find.text('Omar Sow'));
        await tester.pumpAndSettle();

        final int n = verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is AppCard,
        );
        expect(n, greaterThanOrEqualTo(4));
      });
    }
  });

  group('ADM-05 : deux listes, et un geste qui ne ment pas', () {
    testWidgets(
      'l\'eleve sans creneau reste dans la file, et ne se choisit pas',
      (WidgetTester tester) async {
        _fenetre(tester);
        final FauxServiceAttribution service = FauxServiceAttribution()
          ..foyers = <FoyerEnAttente>[
            _eleve(),
            _eleve(
              id: 'e2',
              prenom: 'Moussa',
              creneaux: const <Creneau>[],
              depuis: null,
            ),
          ];

        await _monter(tester, service: service, admin: FauxServiceAdmin());

        // Il est visible : le masquer laisserait le compteur « Foyers sans
        // enseignant » de `ADM-01` sans ligne en face, ce qui ressemble a une
        // panne.
        expect(find.text('Moussa'), findsOneWidget);
        expect(find.text(t.admin.attribution.sansHeure), findsOneWidget);
        expect(find.text(t.admin.attribution.sansHeureDetail), findsOneWidget);

        // Et il ne se choisit pas : un tap qui ne peut mener a rien ne se rend
        // pas actif pour autant.
        final AppCard carte = tester.widget<AppCard>(
          find.ancestor(
            of: find.text('Moussa'),
            matching: find.byType(AppCard),
          ),
        );
        expect(carte.onPress, isNull);
      },
    );

    testWidgets('une seule heure commune : deux taps suffisent, sans motif', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceAttribution service = FauxServiceAttribution()
        ..foyers = <FoyerEnAttente>[_eleve()]
        ..enseignants['e1'] = <EnseignantCandidat>[
          _enseignant(communs: <Creneau>[_creneau(2, 17)]),
        ];

      await _monter(tester, service: service, admin: FauxServiceAdmin());

      await tester.tap(find.text('Yacine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Omar Sow'));
      await tester.pumpAndSettle();

      // L'heure evidente est preselectionnee : c'est ce qui fait tenir la
      // promesse des « deux taps » de la specification.
      expect(find.text(t.admin.attribution.quelleHeure), findsNothing);
      expect(find.text(t.admin.attribution.motif), findsNothing);

      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.admin.attribution.attribuer(eleve: 'Yacine', enseignant: 'Omar'),
      );
      expect(tester.widget<ActionPrincipale>(bouton).onPress, isNotNull);

      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(service.attributions, hasLength(1));
      expect(service.attributions.single.eleveId, 'e1');
      expect(service.attributions.single.enseignantId, 't1');
      expect(service.attributions.single.creneau, _creneau(2, 17));
      // Aucun motif : l'enseignant avait pose cette heure.
      expect(service.attributions.single.motif, isNull);
    });

    testWidgets('hors disponibilite : le motif est exige avant le geste', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceAttribution service = FauxServiceAttribution()
        ..foyers = <FoyerEnAttente>[_eleve()]
        ..enseignants['e1'] = <EnseignantCandidat>[
          _enseignant(id: 't3', prenom: 'Ibrahim'),
        ];

      await _monter(tester, service: service, admin: FauxServiceAdmin());

      await tester.tap(find.text('Yacine'));
      await tester.pumpAndSettle();
      expect(find.text(t.admin.attribution.sansHeureCommune), findsOneWidget);

      await tester.tap(find.text('Ibrahim Sow'));
      await tester.pumpAndSettle();

      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.admin.attribution.attribuer(eleve: 'Yacine', enseignant: 'Ibrahim'),
      );

      // Le champ est la, l'avertissement aussi, et le bouton reste inerte : la
      // base refuserait de toute facon (ADR-021), l'ecran le dit avant.
      expect(find.text(t.admin.attribution.motif), findsOneWidget);
      expect(tester.widget<ActionPrincipale>(bouton).onPress, isNull);

      await tester.enterText(
        find.byType(TextField),
        'Aucun enseignant libre sur ce creneau, accord verbal.',
      );
      await tester.pumpAndSettle();

      expect(tester.widget<ActionPrincipale>(bouton).onPress, isNotNull);
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(
        service.attributions.single.motif,
        'Aucun enseignant libre sur ce creneau, accord verbal.',
      );
    });

    testWidgets('un enseignant au plafond ne se choisit pas', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceAttribution service = FauxServiceAttribution()
        ..foyers = <FoyerEnAttente>[_eleve()]
        ..enseignants['e1'] = <EnseignantCandidat>[
          _enseignant(
            communs: <Creneau>[_creneau(2, 17)],
            actifs: 5,
            plafond: 5,
          ),
        ];

      await _monter(tester, service: service, admin: FauxServiceAdmin());
      await tester.tap(find.text('Yacine'));
      await tester.pumpAndSettle();

      expect(find.text(t.admin.attribution.complet), findsOneWidget);
      final AppCard carte = tester.widget<AppCard>(
        find.ancestor(
          of: find.text('Omar Sow'),
          matching: find.byType(AppCard),
        ),
      );
      // Pas un bouton qui echoue apres le geste : un choix qui n'existe pas.
      expect(carte.onPress, isNull);
    });

    testWidgets('plusieurs heures communes : aucune n\'est choisie d\'office', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceAttribution service = FauxServiceAttribution()
        ..foyers = <FoyerEnAttente>[
          _eleve(creneaux: <Creneau>[_creneau(2, 17), _creneau(4, 18)]),
        ]
        ..enseignants['e1'] = <EnseignantCandidat>[
          _enseignant(communs: <Creneau>[_creneau(2, 17), _creneau(4, 18)]),
        ];

      await _monter(tester, service: service, admin: FauxServiceAdmin());
      await tester.tap(find.text('Yacine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Omar Sow'));
      await tester.pumpAndSettle();

      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.admin.attribution.attribuer(eleve: 'Yacine', enseignant: 'Omar'),
      );

      // Deux heures possibles : choisir a la place de l'administration serait
      // poser une heure de cours par defaut.
      expect(find.text(t.admin.attribution.quelleHeure), findsOneWidget);
      expect(tester.widget<ActionPrincipale>(bouton).onPress, isNull);

      await tester.tap(
        find.text(t.admin.attribution.creneau(jour: 'jeudi', heure: '18')),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<ActionPrincipale>(bouton).onPress, isNotNull);
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(service.attributions.single.creneau, _creneau(4, 18));
    });

    testWidgets('le chargement montre la forme de la liste, pas un mot', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await tester.pumpWidget(
        hote(
          const AttributionPage(),
          surcharges: <Override>[
            serviceAttributionProvider.overrideWithValue(
              FauxServiceAttribution()
                ..delai = const Duration(milliseconds: 200),
            ),
            serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
          ],
        ),
      );
      // Un seul `pump` : on regarde l'ecran pendant la lecture, pas apres.
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.commun.chargement), findsNothing);

      // `pumpAndSettle` ne vide pas un `Future.delayed` : il ne pompe que tant
      // qu'une frame est planifiee, et un minuteur sans animation n'en planifie
      // aucune. Sans cette avance de temps, le test se termine sur un minuteur
      // en attente, ce que `flutter_test` compte comme un echec.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    });

    testWidgets('une file illisible propose de reessayer', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceAttribution service = FauxServiceAttribution()
        ..erreurFoyers = Exception('hors ligne');

      await _monter(tester, service: service, admin: FauxServiceAdmin());

      expect(find.text(t.admin.attribution.erreurEleves), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });
  });
}
