// Captures de CAND-NOM-LATIN (decision du directeur du 23/10/2026, « Les noms
// dans une seule ecriture sur les listes ») :
//
// - la question de plus a l'inscription du candidat (etape d'identite), quand
//   le nom saisi est en arabe : 390x844, francais et arabe de droite a gauche ;
// - la confirmation dans la Salle d'examen (390x844, francais et arabe) ;
// - la colonne Nom de la file des candidatures de la direction : nom latin,
//   nom d'origine en petit dessous, marque « a confirmer » (1440x900 et 390).
//
// Les donnees sont fictives. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_inscription_candidat.dart';
import 'package:rewayah_academy/core/candidature/port_nom_latin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../fixtures/candidature/faux_inscription_candidat.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../fixtures/candidature/faux_nom_latin.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Le nom arabe des captures (donnees inventees).
const String _prenomArabe = 'محمد';
const String _nomArabe = 'الدوسري';

/// L'etape d'identite du candidat enseignant, avec un nom en arabe saisi.
Future<void> _monterInscription(
  WidgetTester tester, {
  Size taille = _telephone,
}) async {
  fixerVueCapture(tester, taille, 1, zoneSure: _zoneSure);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.inscriptionUsage,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.inscriptionUsage,
        builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
      ),
      GoRoute(
        path: Routes.inscriptionIdentite,
        builder: (BuildContext _, GoRouterState _) => const IdentiteEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionGenre,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Center(child: Text('GENRE'))),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        portInscriptionCandidatProvider.overrideWithValue(
          FauxInscriptionCandidat(),
        ),
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
  await tester.pumpAndSettle();
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
      .read(brouillonInscriptionProvider.notifier)
      .deposerSansCode();
  routeur.go(Routes.inscriptionIdentite);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('inscription-prenom')),
    _prenomArabe,
  );
  await tester.enterText(find.byKey(const Key('inscription-nom')), _nomArabe);
  await tester.pumpAndSettle();
}

/// La file des candidatures en demonstration d'administration.
Future<void> _monterListe(
  WidgetTester tester,
  PortCandidaturesDirection port,
) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
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
  routeur.go(Routes.adminPersonnesCandidatures);
  await stabiliser(tester);
  await stabiliser(tester);
}

List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(
    id: 'a1',
    nom: 'أحمد بن علي',
    nomLatin: 'Ahmed Ben Ali',
    derniereActivite: DateTime.utc(2026, 10, 22, 8),
  ),
  ligneTest(
    id: 'b2',
    nom: 'يوسف الدوسري',
    nomLatinAConfirmer: true,
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienAPlanifier,
    paysResidence: 'SA',
    derniereActivite: DateTime.utc(2026, 10, 21, 17),
  ),
  ligneTest(
    id: 'c3',
    nom: 'Amina Diallo',
    nomLatin: 'Amina Diallo',
    paysResidence: 'FR',
    derniereActivite: DateTime.utc(2026, 10, 20, 9),
  ),
  ligneTest(
    id: 'd4',
    nom: 'فاطمة الزهراء',
    nomLatin: 'Fatima Zahra',
    paysResidence: 'MA',
    derniereActivite: DateTime.utc(2026, 10, 19, 9),
  ),
  ligneTest(
    id: 'e5',
    nom: 'مريم',
    nomLatinAConfirmer: true,
    etape: EtapeCandidature.recue,
    etat: null,
    paysResidence: 'EG',
    derniereActivite: DateTime.utc(2026, 10, 18, 9),
  ),
  ligneTest(
    id: 'f6',
    nom: 'Bilal Haddad',
    nomLatin: 'Bilal Haddad',
    paysResidence: 'DZ',
    derniereActivite: DateTime.utc(2026, 10, 17, 9),
  ),
];

Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  debugPrint('PNG ${await capturer(tester, 'CAND-NOM-LATIN/$nom')}');
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('CAND-NOM-LATIN : captures', skip: sautSansCapture, () {
    testWidgets('inscription : la question de plus, francais 390', (
      WidgetTester tester,
    ) async {
      await _monterInscription(tester);
      await _photo(tester, 'inscription_fr_390');
    });

    testWidgets('inscription : la question de plus, arabe 390', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monterInscription(tester);
      await _photo(tester, 'inscription_ar_390');
    });

    for (final (String langue, AppLocale locale) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('Salle d\'examen : la confirmation, $langue 390', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        fixerVueCapture(tester, _telephone, 1, zoneSure: _zoneSure);
        await monterQuestionnaire(
          tester,
          port: FauxMaCandidature(),
          surchargesEnPlus: <Override>[
            portNomLatinProvider.overrideWithValue(
              FauxNomLatin(nomComplet: '$_prenomArabe $_nomArabe'),
            ),
          ],
        );
        debugPrint(
          'PNG ${await capturerVue(tester, 'CAND-NOM-LATIN/salle_examen_${langue}_390')}',
        );
      });
    }

    for (final (String nom, Size taille) in <(String, Size)>[
      ('1440', _bureau),
      ('390', _telephone),
    ]) {
      testWidgets('la file des candidatures, nom latin, $nom', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(
          tester,
          taille,
          1,
          zoneSure: taille == _telephone ? _zoneSure : EdgeInsets.zero,
        );
        await _monterListe(
          tester,
          FauxCandidaturesDirection(
            lignes: _lignes(),
            capacitesRendues: capacitesQuiDecide,
          ),
        );
        await _photo(tester, 'liste_fr_$nom');
      });
    }
  });
}
