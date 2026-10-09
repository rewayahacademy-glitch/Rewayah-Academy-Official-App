// COUPE-MOTS-4 : l'hote commun des tests d'ecran de l'etape. Vraies
// polices du depot, vraie locale (l'arabe donne le sens RTL), 320 px de
// large et texte x2 par defaut, Interface standard ou guidee.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart'
    show sessionActive, surchargesRouteur;
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart' show FausseSourceSession;

/// Les deux langues mesurees : francais (LTR) et arabe (RTL).
const List<AppLocale> languesCoupeMots4 = <AppLocale>[
  AppLocale.fr,
  AppLocale.ar,
];

/// Les deux presentations mesurees.
const List<InterfaceMode> interfacesCoupeMots4 = <InterfaceMode>[
  InterfaceMode.standard,
  InterfaceMode.enfant,
];

/// Le nom court d'une presentation, pour le nom d'un test.
String nomInterface(InterfaceMode i) =>
    i == InterfaceMode.enfant ? 'guidee' : 'standard';

/// A appeler dans `main` : charge les polices du depot et la locale arabe
/// (differee) une fois, hors du `FakeAsync` des tests.
void preparerCoupeMots4() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
}

/// Monte [construire] (appele APRES le changement de locale, pour que ses
/// libelles soient ceux de [langue]) a [largeur] px, texte [echelle].
Future<void> monterCoupeMots4(
  WidgetTester tester,
  Widget Function() construire, {
  required AppLocale langue,
  List<Override> surcharges = const <Override>[],
  InterfaceMode interface = InterfaceMode.standard,
  double largeur = 320,
  double hauteur = 4000,
  double echelle = 2,
}) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, Size(largeur, hauteur), 1);
  await tester.pumpWidget(
    hoteCapture(
      construire(),
      surcharges: surcharges,
      echelleTexte: echelle,
      interfaceMode: interface,
    ),
  );
  await stabiliser(tester);
}

/// COUPE-MOTS-4 : l'ecran ENTIER rendu, chaque `Scaffold` et chaque
/// feuille du bas ouverte par-dessus (corps, en-tetes, cartes, boutons).
final Finder ecranEntierCoupeMots4 = find.byWidgetPredicate(
  (Widget w) => w is Scaffold || w is BottomSheet,
);

/// COUPE-MOTS-4 : sur l'ecran entier, aucun mot coupe (un nom compose peut
/// passer a la ligne apres son trait d'union, chaque partie restant
/// entiere) et aucune ponctuation haute seule a la ligne.
void verifierEcranEntierCoupeMots4(WidgetTester tester) {
  expect(
    ecranEntierCoupeMots4,
    findsWidgets,
    reason: 'Aucun ecran monte a mesurer',
  );
  expect(tester.takeException(), isNull);
  expect(
    motsCoupes(tester, ecranEntierCoupeMots4, traitDUnionPermis: true),
    isEmpty,
    reason: 'Un mot coupe sur l ecran',
  );
  expect(
    ponctuationsIsolees(tester, ecranEntierCoupeMots4),
    isEmpty,
    reason: 'Une ponctuation haute seule a la ligne',
  );
}

/// COUPE-MOTS-4 (1) : les cartes de choix rendues ne coupent aucun mot (nom
/// compose entier), et le RESTE de l'ecran non plus
/// ([verifierEcranEntierCoupeMots4]). Echoue si aucune carte n'est rendue
/// (la mesure doit porter sur quelque chose).
void verifierCartesDeChoixEntieres(WidgetTester tester) {
  final Finder cartes = find.byType(ChoiceCardGroup);
  expect(cartes, findsWidgets, reason: 'Aucune carte de choix rendue');
  expect(tester.takeException(), isNull);
  expect(motsCoupes(tester, cartes), isEmpty);
  verifierEcranEntierCoupeMots4(tester);
}

/// Monte l'application sur son VRAI routeur, session [role], et va a
/// [depart] : 320 px, texte x2, vraie locale [langue].
Future<GoRouter> monterRouteCoupeMots4(
  WidgetTester tester, {
  required AppRole role,
  required String depart,
  required AppLocale langue,
  InterfaceMode interface = InterfaceMode.standard,
  ServiceAppairage? appairage,
  List<Override> autres = const <Override>[],
  double largeur = 320,
  double hauteur = 4000,
}) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, Size(largeur, hauteur), 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(role)),
          appairage: appairage,
        ),
        ...autres,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext contexte, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(interface, Brightness.light),
              locale: TranslationProvider.of(contexte).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext c, Widget? app) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: app!,
              ),
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
