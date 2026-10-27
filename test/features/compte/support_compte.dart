// Outils des tests du Compte du tuteur (lot E, chantier Tuteur V1).
//
// Deux montages :
// - [monterCompte] : l'application sur son VRAI routeur, avec la coquille du
//   tuteur, pour les parcours touches depuis la navigation ;
// - [monterEcran] : un ecran seul, pour les etats (hors ligne, echecs).
//
// Donnees : fixtures de test isolees (`test/fixtures/tuteur/`), aucun appel
// reseau, aucun Supabase.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/acces_foyer_depuis_eleves.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../fixtures/tuteur/faux_identite_titulaire.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// L'instant de reference des acces : 24 septembre 2026, 12 h UTC.
final DateTime maintenantCompte = DateTime.utc(2026, 9, 24, 12);

/// Les pieces signees, en memoire.
class FauxServiceAcceptations implements ServiceAcceptations {
  /// Cree le faux.
  FauxServiceAcceptations({this.rendues = const <Acceptation>[]});

  /// Ce que la lecture rend.
  List<Acceptation> rendues;

  @override
  Future<List<Acceptation>> acceptations(String profilId) async => rendues;
}

/// Une identite dont la lecture n'aboutit jamais (etat de chargement).
class IdentiteEnAttente implements PortIdentiteTitulaire {
  final Completer<IdentiteTitulaire> _jamais = Completer<IdentiteTitulaire>();

  @override
  Future<IdentiteTitulaire> lire() => _jamais.future;

  @override
  Future<void> modifier({String? prenom, String? nom}) async {}
}

/// Une identite dont la lecture echoue (panne, jamais une capacite absente).
class IdentiteEnEchec implements PortIdentiteTitulaire {
  /// Le nombre de lectures demandees.
  int lectures = 0;

  @override
  Future<IdentiteTitulaire> lire() async {
    lectures++;
    throw Exception('lecture impossible');
  }

  @override
  Future<void> modifier({String? prenom, String? nom}) async {}
}

/// L'acces du foyer par le VRAI adaptateur du lot E, sur des eleves fictifs
/// et une horloge figee.
PortAccesFoyer accesDe(List<EleveDuFoyer> eleves) => AccesFoyerDepuisEleves(
  lireEleves: () async => eleves,
  maintenantUtc: () => maintenantCompte,
);

/// Les surcharges propres au Compte : identite du titulaire A, acces lus par
/// l'adaptateur, pieces signees vides. Les autres ports gardent leur
/// implementation de production (« indisponible »).
List<Override> surchargesCompte({
  PortIdentiteTitulaire? identite,
  PortAccesFoyer? acces,
  ServiceAcceptations? acceptations,
  List<EleveDuFoyer> eleves = FoyersFictifs.foyerA,
}) => <Override>[
  // La deconnexion lit la file des cahiers puis vide la base locale avant de
  // fermer la session : en memoire ici, jamais la base locale de l'appareil
  // (qui ne repond pas sous test).
  depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
  baseLocaleEnMemoire(),
  portIdentiteTitulaireProvider.overrideWithValue(
    identite ?? FauxIdentiteTitulaire(),
  ),
  portAccesFoyerProvider.overrideWithValue(acces ?? accesDe(eleves)),
  serviceAcceptationsProvider.overrideWithValue(
    acceptations ?? FauxServiceAcceptations(),
  ),
];

/// Monte l'application sur son **vrai** routeur, avec un tuteur actif et le
/// foyer fictif A, puis va a [depart].
Future<GoRouter> monterCompte(
  WidgetTester tester, {
  String depart = Routes.tuteurCompte,
  Size taille = const Size(390, 844),
  List<Override> surcharges = const <Override>[],
  List<EleveDuFoyer> eleves = FoyersFictifs.foyerA,
  PortIdentiteTitulaire? identite,
  PortAccesFoyer? acces,
  ServiceAcceptations? acceptations,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = eleves;
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        ...surchargesCompte(
          identite: identite,
          acces: acces,
          acceptations: acceptations,
          eleves: eleves,
        ),
        ...surcharges,
      ],
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
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Monte un ecran seul, avec le vrai theme et la locale de l'application.
Future<void> monterEcran(
  WidgetTester tester,
  Widget ecran, {
  List<Override> surcharges = const <Override>[],
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) => MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ecran,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

/// Fait defiler jusqu'a [cible] puis la touche.
Future<void> toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}
