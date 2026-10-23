// DASH-EA-PROD : monte l'application sur son VRAI routeur, avec une session
// d'eleve, et les doubles de l'Accueil adulte et de son historique. Partage
// par les tests de navigation et par le script de capture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/historique_seances_adulte_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart'
    show surchargesEleveDemo;

import '../../capture/outil_capture.dart' show cadreCapture;
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Ce que lit une source : une valeur, un echec, ou rien (chargement sans
/// fin). Absent : le fournisseur reel, indisponible comme en production.
sealed class Lecture<T> {
  const Lecture();
}

/// Une valeur.
class Valeur<T> extends Lecture<T> {
  /// Cree la lecture.
  const Valeur(this.valeur);

  /// La valeur rendue.
  final T valeur;
}

/// Un echec de lecture (reseau, serveur).
class Echec<T> extends Lecture<T> {
  /// Cree la lecture.
  const Echec();
}

/// Une lecture qui ne repond jamais.
class Attente<T> extends Lecture<T> {
  /// Cree la lecture.
  const Attente();
}

/// L'accueil du titulaire de la demonstration (Classe An-Nour).
AccueilAdulteVM accueilDemo() => DonneesAdulteDemo.accueil(
  GenreTitulaireDemo.homme,
  VueDemoAdulte.titulaire,
)!;

/// Les doubles d'une situation. [horsLigne] : l'appareil est hors ligne.
List<Override> surchargesAccueilAdulte({
  Lecture<AccueilAdulteVM>? accueil,
  Lecture<List<SeancePasseeAdulte>>? historique,
  bool horsLigne = false,
}) {
  Future<T> lire<T>(Lecture<T> l) => switch (l) {
    Valeur<T>(:final T valeur) => Future<T>.value(valeur),
    Echec<T>() => Future<T>.error(StateError('lecture (test)')),
    Attente<T>() => Completer<T>().future,
  };
  final Lecture<AccueilAdulteVM>? a = accueil;
  final Lecture<List<SeancePasseeAdulte>>? h = historique;
  return <Override>[
    ...surchargesEleveDemo(
      horsLigne ? EtatDemoClasse.horsLigne : EtatDemoClasse.aVenir,
    ),
    if (a != null) accueilAdulteProvider.overrideWith((Ref _) => lire(a)),
    if (h != null)
      historiqueSeancesAdulteProvider.overrideWith((Ref _) => lire(h)),
  ];
}

/// Monte l'application (vrai routeur, session d'eleve active), puis va a
/// [depart] s'il est donne. Le cadre de capture entoure l'application.
Future<GoRouter> monterAccueilAdulteReel(
  WidgetTester tester, {
  List<Override> surcharges = const <Override>[],
  String? depart,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  ThemeMode theme = ThemeMode.light,
  AppRole role = AppRole.guardian,
  bool autonome = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
        // EA-ROLE-1 : l'adulte est un compte tuteur dont le serveur sert la
        // capacite « eleve autonome » (C-24), jamais le role eleve.
        portCapaciteEleveProvider.overrideWithValue(
          PortCapaciteEleveFactice(
            autonomes: autonome ? <String>{'p-${role.valeurSql}'} : <String>{},
          ),
        ),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext _, WidgetRef ref, Widget? _) {
              // `watch`, comme `AppRouterDelegateHote` : un fournisseur sans
              // abonne a ses ecoutes en pause (Riverpod 3).
              routeur = ref.watch(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: theme,
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (BuildContext c, Widget? app) => MediaQuery(
                  data: MediaQuery.of(c)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: Directionality(textDirection: direction, child: app!),
                ),
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (depart != null) {
    routeur.go(depart);
    await stabiliser(tester);
  }
  return routeur;
}
