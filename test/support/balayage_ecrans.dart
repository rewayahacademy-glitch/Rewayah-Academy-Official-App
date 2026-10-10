// COUPE-MOTS-FOND-1 : le balayage des ecrans par la garde du rendu
// (`garde_coupe_mots_rendu.dart`).
//
// Chaque ecran est monte, avec les vraies polices, a chaque gabarit de la
// fiche (320 x 568 texte x2, 390 x 844, 1440 x 900 texte x2), en francais
// (LTR) et en arabe (RTL), en interface standard et en Interface guidee ;
// la page est defilee de haut en bas et chaque paragraphe visible est
// mesure. Un ecran est soit une page isolee sur ses doubles, soit une
// coquille de role en demonstration sur son routeur, a une adresse.
//
// Donnees : doubles en memoire et demonstrations, jamais un service reel.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../capture/outil_capture.dart';
import 'dette_coupe_mots.dart';
import 'garde_coupe_mots_rendu.dart';

/// Un ecran du balayage : une page isolee ([page]) ou un routeur
/// ([routeur]) ouvert a [depart].
typedef EcranBalayage = ({
  String nom,
  Widget Function()? page,
  GoRouter Function(WidgetRef ref)? routeur,
  String? depart,
  List<Override> Function() surcharges,
});

/// Une configuration mesuree.
typedef ConfigBalayage = ({
  GabaritGarde gabarit,
  AppLocale langue,
  InterfaceMode interface,
});

/// Toutes les configurations de la fiche : trois gabarits, deux sens, deux
/// presentations.
List<ConfigBalayage> configsBalayage() => <ConfigBalayage>[
  for (final GabaritGarde g in gabaritsGarde)
    for (final AppLocale l in const <AppLocale>[AppLocale.fr, AppLocale.ar])
      for (final InterfaceMode i in const <InterfaceMode>[
        InterfaceMode.standard,
        InterfaceMode.enfant,
      ])
        (gabarit: g, langue: l, interface: i),
];

/// Le nom court d'une configuration.
String nomConfig(ConfigBalayage c) =>
    '${c.gabarit.nom} ${c.langue.name} '
    '${c.interface == InterfaceMode.enfant ? 'guidee' : 'standard'}';

/// Ne garde de [base] que les surcharges dont le fournisseur n'est pas
/// surcharge par [plus], puis ajoute [plus] : une surcharge par
/// fournisseur.
List<Override> fusionnerSurcharges(List<Override> base, List<Override> plus) {
  final Set<Object> remplaces = <Object>{
    for (final Override o in plus) o.origin,
  };
  return <Override>[
    for (final Override o in base)
      if (!remplaces.contains(o.origin)) o,
    ...plus,
  ];
}

/// Monte [ecran] dans la configuration [c].
Future<void> monterEcranBalayage(
  WidgetTester tester,
  EcranBalayage ecran,
  ConfigBalayage c,
) async {
  LocaleSettings.setLocaleSync(c.langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, c.gabarit.taille, 1);
  GoRouter? r;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: ecran.surcharges(),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              Widget echelle(BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(c.gabarit.echelle)),
                child: app!,
              );
              final ThemeData theme = AppTheme.pour(
                c.interface,
                Brightness.light,
              );
              final Locale locale = TranslationProvider.of(context)
                  .flutterLocale;
              if (ecran.routeur case final GoRouter Function(WidgetRef) f) {
                r ??= f(ref);
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  locale: locale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  builder: echelle,
                  routerConfig: r,
                );
              }
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: theme,
                locale: locale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: echelle,
                home: ecran.page!(),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (ecran.depart case final String d) {
    r!.go(d);
    await stabiliser(tester);
  }
}

/// Declare un test par configuration pour chaque ecran de [ecrans] :
/// l'ecran entier, defile, ne porte aucun defaut de texte, sauf
/// [exceptions] (texte entier exclu, avec sa raison ecrite par l'appelant,
/// par defaut la dette connue `detteCoupeMots`,
/// par nom d'ecran).
void balayer(
  List<EcranBalayage> ecrans, {
  Map<String, Set<String>> exceptions = detteCoupeMots,
  List<ConfigBalayage>? configs,
}) {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  for (final EcranBalayage ecran in ecrans) {
    for (final ConfigBalayage c in configs ?? configsBalayage()) {
      testWidgets('${ecran.nom} ${nomConfig(c)} : aucun mot coupe ni rogne', (
        WidgetTester tester,
      ) async {
        await monterEcranBalayage(tester, ecran, c);
        final List<String> fautes = await defautsEcranDefile(
          tester,
          exceptions: exceptions[ecran.nom] ?? const <String>{},
          ligneVisuelleRtl:
              c.langue != AppLocale.ar ||
              ecransTraduitsEnArabe.contains(ecran.nom),
        );
        expect(fautes, isEmpty, reason: '${ecran.nom} ${nomConfig(c)}');
      });
    }
  }
}
