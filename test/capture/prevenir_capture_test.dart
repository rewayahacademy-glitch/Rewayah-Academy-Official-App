// Captures de CAND-PREVENIR (« Prevenir par e-mail ») : la feuille qui envoie le
// lien d'inscription aux personnes des formulaires importes, sur la VRAIE page
// des candidatures, ouverte par son lien.
//
// Trois etats : envoi possible, apres l'envoi (il reste du monde), inscription
// fermee. 390x844 et 1440x900, clair, francais.
//
// Les comptes sont ceux du double du port
// (`test/fixtures/candidature/faux_prevenir_candidats.dart`) : aucune personne
// reelle, aucune adresse. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/prevenir_candidats.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../fixtures/candidature/faux_prevenir_candidats.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

const CapacitesCandidatures _caps = CapacitesCandidatures(
  peutLire: true,
  genreLecteurConnu: true,
  gestes: <String, bool>{'consignerPrevenu': true},
);

/// Monte la page des candidatures dans le cadre de capture, puis ouvre la
/// feuille par son lien.
Future<void> _monter(
  WidgetTester tester,
  FauxPrevenirCandidats faux,
  Size taille,
) async {
  fixerVueCapture(
    tester,
    taille,
    1,
    zoneSure: taille.width < 600 ? _zoneSure : EdgeInsets.zero,
  );
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminPersonnesCandidatures,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.adminPersonnesCandidatures,
        builder: (BuildContext _, GoRouterState _) => const CandidaturesPage(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(
            lignes: <LigneCandidature>[
              ligneTest(id: 'a1', nom: 'Personne Test 01'),
              ligneTest(id: 'b2', nom: 'Personne Test 02'),
            ],
            capacitesRendues: _caps,
          ),
        ),
        portPrevenirCandidatsProvider.overrideWithValue(faux),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final Finder lien = find.byKey(
    const ValueKey<String>('candidatures-prevenir'),
  );
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien);
  await stabiliser(tester);
}

Future<void> _photo(WidgetTester tester, String nom) async {
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('CAND-PREVENIR : captures', skip: sautSansCapture, () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', _telephone),
      ('1440', _bureau),
    ]) {
      testWidgets('envoi possible $nom', (WidgetTester tester) async {
        await _monter(tester, FauxPrevenirCandidats(), taille);
        await _photo(tester, '1-envoi-possible_${nom}_fr');
      });

      testWidgets('apres l\'envoi $nom', (WidgetTester tester) async {
        final FauxPrevenirCandidats faux = FauxPrevenirCandidats(
          apercuRendu: const ApercuPrevenir(
            aPrevenir: 450,
            dejaPrevenus: 12,
            dejaInscrits: 30,
            inscriptionOuverte: true,
          ),
        );
        await _monter(tester, faux, taille);
        await _photo(tester, '2-avant-envoi-gros_${nom}_fr');
        final Finder envoyer = find.byKey(FeuillePrevenir.cleEnvoyer);
        await tester.ensureVisible(envoyer);
        await tester.pump();
        await tester.tap(envoyer);
        await stabiliser(tester);
        await _photo(tester, '3-apres-envoi_${nom}_fr');
      });

      testWidgets('inscription fermee $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          FauxPrevenirCandidats(
            apercuRendu: const ApercuPrevenir(
              aPrevenir: 5,
              dejaPrevenus: 2,
              dejaInscrits: 3,
              inscriptionOuverte: false,
            ),
          ),
          taille,
        );
        await _photo(tester, '4-inscription-fermee_${nom}_fr');
      });
    }
  });
}
