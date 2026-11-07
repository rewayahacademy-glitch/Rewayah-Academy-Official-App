// Captures de PROFIL-TITULAIRE (pilote, 07/11/2026) : le profil eleve du
// titulaire (Dyna) apparait dans « Profils eleves » du Foyer, a cote des
// enfants ; puis son parcours commence a la langue, sans question d'age (la
// tranche adulte_18_plus est connue du serveur). 390x844 @3 et 1440x900 @1,
// en francais et en arabe.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures isolees.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_profil_eleve_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';

import '../fixtures/tuteur/faux_capacites.dart';
import '../fixtures/tuteur/foyers.dart';
import '../parcours/faux_service_offres.dart';
import '../router/support_routeur.dart';
import '../support/harnais.dart';
import 'outil_capture.dart' hide stabiliser;

/// Le profil eleve du titulaire, tel que `profils_du_foyer_v` le rend
/// desormais : son propre identifiant de profil.
const EleveDuFoyer _dyna = EleveDuFoyer(
  id: 'p-guardian',
  prenom: 'Dyna',
  identifiantImmuable: 'RA-26-4817',
  mode: InterfaceMode.standard,
  camera: CameraPolicy.forbidden,
);

Future<void> _monter(WidgetTester tester, String depart) async {
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = <EleveDuFoyer>[...FoyersFictifs.foyerA, _dyna];
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        // Le profil existe : le Foyer ne propose plus de le creer (UX-023).
        portProfilEleveTitulaireProvider.overrideWithValue(
          FauxProfilEleveTitulaire()..present = true,
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final ProviderContainer conteneur = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  (conteneur.read(serviceOffresProvider) as FauxServiceOffres).parcoursRendu =
      <ParcoursApprenant>[
        const ParcoursApprenant(
          eleveId: 'p-guardian',
          prenom: 'Dyna',
          diagnostic: StatutDiagnostic.nonRequis,
          cohorteCode: 'adulte_18_plus',
          cohorteNom: '18 ans et plus',
        ),
      ];
  conteneur.invalidate(parcoursFoyerProvider);
  routeur.go(depart);
  await stabiliser(tester);
}

void main() {
  group('Capture : PROFIL-TITULAIRE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    final List<(String, String)> ecrans = <(String, String)>[
      ('foyer', Routes.tuteurFoyer),
      ('parcours', Routes.parcoursPour('p-guardian')),
    ];

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (String nom, String chemin) in ecrans) {
        for (final (Size taille, double densite) in <(Size, double)>[
          (const Size(390, 844), 3),
          (const Size(1440, 900), 1),
        ]) {
          final String format =
              '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
          testWidgets('$format, $nom, ${langue.languageCode}', (
            WidgetTester tester,
          ) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(
              tester,
              taille,
              densite,
              zoneSure: densite == 3
                  ? const EdgeInsets.only(top: 47, bottom: 34)
                  : EdgeInsets.zero,
            );
            await _monter(tester, chemin);
            if (nom == 'foyer') {
              expect(find.text('Dyna'), findsWidgets);
              expect(
                find.textContaining('${t.foyer.membre.vous} · '),
                findsOneWidget,
              );
            } else {
              expect(find.byKey(ParcoursOffresPage.ageKey), findsNothing);
              expect(find.text(t.parcours.langueQuestion), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'pt_${nom}_${format}_${langue.languageCode}')}',
            );
          });
        }
      }
    }
  });
}
