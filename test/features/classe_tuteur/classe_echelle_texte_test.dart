// Texte agrandi et contraste de la Classe, de ses quatre sous-pages et du
// Catalogue (lot C, revue C M5) : a 200 pour cent de taille de texte, a 390 et
// a 1440, aucun debordement ni exception ; en clair et en sombre, le contraste
// du texte rendu passe la regle d'accessibilite de Flutter
// (`textContrastGuideline`).
//
// Donnees : fixtures isolees et doubles de `support_classe.dart`. Le montage
// passe par le VRAI routeur ; ici `routeur.go` ne sert qu'a poser l'ecran
// mesure (les parcours touches sont prouves par `classe_tuteur_test.dart` et
// `catalogue_classes_test.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/classe_tuteur/catalogue_classes_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/planning_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/progression_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/ressources_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/travail_classe_page.dart';

import '../../router/support_routeur.dart';
import 'support_classe.dart';

/// Les donnees fictives completes : seances, classe avec parcours,
/// observation ouverte en simulation, travail, bibliotheque, progression et
/// catalogue branche.
Future<List<Override>> _surcharges() async => surchargesClasse(
  seances: <SeanceFamille>[
    seanceEnDirect(duree: const Duration(minutes: 70)),
    seanceSalleOuverte(seanceId: 's2', avant: const Duration(days: 2)),
    seanceSalleOuverte(
      seanceId: 's3',
      avant: const Duration(days: 5),
      statut: StatutSeance.annulee,
    ),
  ],
  portClasses: classesAvecParcours(),
  observation: true,
  presence: const <PresenceParticipant>[presenceA1],
  travail: await travauxFictifs(),
  catalogue: FauxCatalogueClasse(<LibraryResource>[
    ressourceFictive('r1', 'Support fictif 1'),
    ressourceFictive('r2', 'Lecon fictive 2', type: TypeRessource.lecon),
  ]),
  progression: const FausseProgressionClasse(
    ProgressionEleve(
      eleveId: eleveA1,
      niveauHumain: 'Niveau fictif',
      jalons: <String>['Etape fictive 1', 'Etape fictive 2'],
    ),
  ),
  catalogueClasses: FauxCatalogueClasses(),
);

/// Un ecran mesure : son nom, son adresse, son type, et le geste qui l'ouvre
/// depuis l'adresse (la confirmation du catalogue est une tache focalisee
/// dans la page).
class _Ecran {
  const _Ecran(this.nom, this.chemin, this.type, {this.ouvrir});

  final String nom;
  final String chemin;
  final Type type;
  final Future<void> Function(WidgetTester tester)? ouvrir;
}

String _sousPage(String segment) =>
    '${Routes.classeSousPage(classeA, segment)}?eleve=$eleveA1';

final List<_Ecran> _ecrans = <_Ecran>[
  _Ecran(
    'Classe',
    Routes.classePour(classeA, eleveId: eleveA1),
    ClasseTuteurPage,
  ),
  _Ecran('Planning', _sousPage('planning'), PlanningClassePage),
  _Ecran('Travail', _sousPage('travail'), TravailClassePage),
  _Ecran('Bibliotheque', _sousPage('ressources'), RessourcesClassePage),
  _Ecran('Progression', _sousPage('progression'), ProgressionClassePage),
  _Ecran(
    'Catalogue',
    '${Routes.tuteurClassesCatalogue}?eleve=$eleveA2',
    CatalogueClassesPage,
  ),
  _Ecran(
    'Confirmation',
    '${Routes.tuteurClassesCatalogue}?eleve=$eleveA2',
    CatalogueClassesPage,
    ouvrir: (WidgetTester tester) async {
      final Finder choisir = find.text(t.classe.pageCatalogue.choisir);
      await tester.ensureVisible(choisir);
      await stabiliser(tester);
      await tester.tap(choisir);
      await stabiliser(tester);
      expect(find.text(t.classe.pageCatalogue.confirmer), findsWidgets);
    },
  ),
];

Future<void> _monter(
  WidgetTester tester,
  _Ecran ecran, {
  required Size taille,
  double echelle = 1,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final List<Override> surcharges = await _surcharges();
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, luminosite),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(ecran.chemin);
  await stabiliser(tester);
  await ecran.ouvrir?.call(tester);
  expect(find.byType(ecran.type), findsOneWidget, reason: ecran.nom);
}

void main() {
  group('200 pour cent de taille de texte : aucun debordement', () {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      for (final _Ecran ecran in _ecrans) {
        testWidgets('${ecran.nom} a ${taille.width.toInt()}', (
          WidgetTester tester,
        ) async {
          await _monter(tester, ecran, taille: taille, echelle: 2);
          // Un RenderFlex en debordement leve ici.
          expect(tester.takeException(), isNull, reason: ecran.nom);
          // Tout le contenu reste atteignable par le defilement : la
          // derniere rubrique ou action de l'ecran s'amene a la vue.
          final Finder dernier = find
              .descendant(
                of: find.byType(ecran.type),
                matching: find.byType(Text),
              )
              .last;
          await tester.ensureVisible(dernier);
          await stabiliser(tester);
          expect(tester.takeException(), isNull, reason: ecran.nom);
        });
      }
    }
  });

  group('Contraste du texte rendu (textContrastGuideline)', () {
    for (final Brightness luminosite in Brightness.values) {
      for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
        for (final _Ecran ecran in _ecrans) {
          testWidgets(
            '${ecran.nom} a ${taille.width.toInt()}, ${luminosite.name}',
            (WidgetTester tester) async {
              final SemanticsHandle semantique = tester.ensureSemantics();
              await _monter(
                tester,
                ecran,
                taille: taille,
                luminosite: luminosite,
              );
              await expectLater(tester, meetsGuideline(textContrastGuideline));
              semantique.dispose();
            },
          );
        }
      }
    }
  });
}
