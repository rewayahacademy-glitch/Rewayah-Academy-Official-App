import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

EleveDuFoyer _enfant({
  String id = 'e1',
  String prenom = 'Amina',
  InterfaceMode mode = InterfaceMode.enfant,
  CameraPolicy camera = CameraPolicy.forbidden,
  String? cleAvatar,
}) => EleveDuFoyer(
  id: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-AD-000001',
  mode: mode,
  camera: camera,
  cleAvatar: cleAvatar,
);

Affectation _affectation({String eleveId = 'e1'}) => Affectation(
  id: 'a1',
  enseignantId: 't1',
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'TEACH-AD-000001',
  eleveId: eleveId,
  elevePrenom: 'Amina',
  creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
  depuis: DateTime(2026, 9, 1),
);

/// Une fenetre haute : une carte d'eleve porte un renvoi et trois demandes,
/// et un `ListView` ne construit pas ce qui n'est pas visible.
void _fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<Override> _surcharges({
  required FauxServiceAppairage appairage,
  FauxServicePlanning? planning,
  FauxServiceMatching? matching,
  FauxServiceRegles? regles,
}) => <Override>[
  serviceAppairageProvider.overrideWithValue(appairage),
  servicePlanningProvider.overrideWithValue(planning ?? FauxServicePlanning()),
  serviceMatchingProvider.overrideWithValue(matching ?? FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(regles ?? FauxServiceRegles()),
];

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAppairage appairage,
  FauxServicePlanning? planning,
  FauxServiceMatching? matching,
  FauxServiceRegles? regles,
}) async {
  _fenetreHaute(tester);
  await tester.pumpWidget(
    hote(
      const ReglagesEnfantPage(),
      surcharges: _surcharges(
        appairage: appairage,
        planning: planning,
        matching: matching,
        regles: regles,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Monte l'application sur son vrai routeur et demande `/tuteur/reglages`.
Future<GoRouter> _monterRouteur(
  WidgetTester tester,
  FauxServiceAppairage appairage,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.guardian)),
        appairage: appairage,
      ),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurReglages);
  await stabiliser(tester);
  return routeur;
}

void main() {
  group(
    'TUT-05 : photo, camera et interface ont une seule place, la fiche',
    () {
      testWidgets('aucun reglage de photo, de camera ni d interface ici', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          appairage: FauxServiceAppairage()
            ..elevesRendus = <EleveDuFoyer>[_enfant(prenom: 'Ibrahim')],
        );

        // Les anciens reglages ne sont plus rendus : ils vivent dans la fiche
        // de l'eleve (lot B, LB-3). Une fonction = un seul endroit.
        for (final String ancien in <String>[
          t.tuteur.reglages.photoAjouter,
          t.tuteur.reglages.photoChanger,
          t.tuteur.reglages.cameraAutoriser(prenom: 'Ibrahim'),
          t.tuteur.reglages.cameraRetirer(prenom: 'Ibrahim'),
          t.tuteur.reglages.modePasserStandard(prenom: 'Ibrahim'),
          t.tuteur.reglages.modePasserEnfant(prenom: 'Ibrahim'),
          t.tuteur.reglages.cameraInterdite(prenom: 'Ibrahim'),
        ]) {
          expect(find.text(ancien), findsNothing, reason: ancien);
        }
        // Un seul renvoi par eleve, vers sa fiche.
        expect(find.text(t.reglagesEnfant.renvoi), findsOneWidget);
        expect(
          find.text(t.reglagesEnfant.renvoiLegende(prenom: 'Ibrahim')),
          findsOneWidget,
        );
        // Aucun identifiant interne a l'ecran.
        expect(find.textContaining('STUD-'), findsNothing);
        expect(find.text(t.reglagesEnfant.intro), findsOneWidget);
      });

      testWidgets(
        'l adresse /tuteur/reglages mene au Foyer (C6, vrai routeur)',
        (WidgetTester tester) async {
          final GoRouter routeur = await _monterRouteur(
            tester,
            FauxServiceAppairage()..elevesRendus = <EleveDuFoyer>[_enfant()],
          );

          expect(lieu(routeur), Routes.tuteurFoyer);
          expect(find.byType(ReglagesEnfantPage), findsNothing);
        },
      );

      testWidgets('foyer vide : le vocabulaire est celui du profil eleve', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          appairage: FauxServiceAppairage()..elevesRendus = <EleveDuFoyer>[],
        );

        expect(find.text(t.enfant.aucun), findsOneWidget);
        expect(find.text(t.enfant.aucunDetail), findsOneWidget);
        expect(find.textContaining('Aucun enfant'), findsNothing);
        expect(find.textContaining('appairer'), findsNothing);
      });
    },
  );

  group('TUT-05 : les demandes du tuteur', () {
    testWidgets('sans enseignant, la reaffectation n est pas proposee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
      );

      // Un bouton qui ne peut pas aboutir n'est pas rendu : la base refuserait
      // « cet eleve n'a pas d'enseignant a changer » APRES le geste.
      expect(find.text(t.tuteur.reglages.demandeReaffectation), findsNothing);
      expect(
        find.text(t.tuteur.reglages.demandeSansEnseignant(prenom: 'Amina')),
        findsOneWidget,
      );
      // Les deux demandes de regle, elles, restent proposees.
      expect(find.text(t.tuteur.reglages.demandeDuree), findsOneWidget);
      expect(find.text(t.tuteur.reglages.demandeMinimum), findsOneWidget);
    });

    testWidgets('avec un enseignant, la reaffectation part avec son motif', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching();
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning()
          ..affectationsRendues = <Affectation>[_affectation()],
        matching: matching,
      );

      await tester.tap(find.text(t.tuteur.reglages.demandeReaffectation));
      await tester.pumpAndSettle();

      expect(
        find.text(t.tuteur.reglages.demandeTitreReaffectation(prenom: 'Amina')),
        findsOneWidget,
      );
      // Sans motif, le bouton n'aboutit pas : la base refuse une demande sans
      // lui, et l'ecran ne fait pas semblant.
      final Finder envoyer = find.widgetWithText(
        ActionPrincipale,
        t.tuteur.reglages.demandeEnvoyer,
      );
      expect(tester.widget<ActionPrincipale>(envoyer).onPress, isNull);

      await tester.enterText(find.byType(TextField), 'Horaire impossible');
      await tester.pumpAndSettle();
      await tester.tap(envoyer);
      await tester.pumpAndSettle();

      expect(matching.demandes, hasLength(1));
      expect(matching.demandes.single.sorte, SorteDemande.reaffectation);
      expect(matching.demandes.single.sujetId, 'e1');
      expect(matching.demandes.single.motif, 'Horaire impossible');
      expect(matching.demandes.single.valeur, isNull);
      expect(find.text(t.tuteur.reglages.demandeEnvoyee), findsOneWidget);
    });

    testWidgets('une demande de duree porte la valeur choisie', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching();
      // La valeur qui s'applique DEJA a cet enfant, lue par `regle_effective()`
      // et non par une constante : elle peut differer de celle de la
      // plateforme.
      final FauxServiceRegles regles = FauxServiceRegles()
        ..parProfil['e1'] = const <RegleProfil>[
          RegleProfil(
            cle: CleRegle.dureeSeance,
            valeurEffective: 45,
            valeurPlateforme: 60,
          ),
        ];

      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        matching: matching,
        regles: regles,
      );

      await tester.tap(find.text(t.tuteur.reglages.demandeDuree));
      await tester.pumpAndSettle();

      expect(
        find.text(
          LibellesGroupe.insecable(
            t.tuteur.reglages.demandeActuelle(minutes: '45'),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          LibellesGroupe.valeurSeule(
            t.tuteur.reglages.demandeMinutes(minutes: '30'),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Elle decroche');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ActionPrincipale, t.tuteur.reglages.demandeEnvoyer),
      );
      await tester.pumpAndSettle();

      expect(matching.demandes.single.sorte, SorteDemande.regle);
      expect(matching.demandes.single.valeur, 30);
    });
  });
}
