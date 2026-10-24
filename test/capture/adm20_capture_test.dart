// Captures d'ADM-20 (la file des candidatures de la direction), sur la VRAIE
// application et le vrai routeur en demonstration d'administration : la
// barre laterale, les onglets de Personnes (« Candidatures » au rang de
// l'ancien « Invitations »), la file elle-meme.
//
// Etats : contenu, recherche sans resultat, erreur, hors ligne
// sans donnees, capacite indisponible, vide, genre du lecteur inconnu,
// exception du super-admin avec alertes a zero ; 390x844 et 1440x900, clair ;
// le sombre ; l'arabe de droite a gauche.
//
// Les donnees sont fictives, posees par le double du port
// (`test/fixtures/candidature/faux_candidatures_direction.dart`) : aucune
// personne reelle. Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).
//
// Pas de capture du mode selection : sur le vrai routeur, `ADM-22` n'existe pas
// encore et le mode n'est pas offert (ni « Selectionner », ni barre). Il est
// prouve par les tests de widget de la page.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Quatorze candidatures fictives, couvrant chaque etape, chaque etat et les
/// marques d'informations manquantes.
List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(
    id: 'a1',
    nom: 'Amina Diallo',
    courrielAObtenir: true,
    indicatifAConfirmer: true,
    derniereActivite: DateTime.utc(2026, 10, 22, 8),
  ),
  ligneTest(
    id: 'b2',
    nom: 'Bilal Haddad',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienAPlanifier,
    paysResidence: 'FR',
    paiement: EtatVersement.aVerifier,
    derniereActivite: DateTime.utc(2026, 10, 21, 17),
  ),
  ligneTest(
    id: 'c3',
    nom: 'Carla Mendes',
    etape: EtapeCandidature.confirmee,
    etat: null,
    indisponible: true,
    indisponibleJusquAu: DateTime.utc(2026, 11, 3),
    paysResidence: 'PT',
    derniereActivite: DateTime.utc(2026, 10, 21, 9),
  ),
  ligneTest(
    id: 'd4',
    nom: 'Dina Saidi',
    etape: EtapeCandidature.invitee,
    etat: null,
    paiement: EtatVersement.inconnu,
    paysResidence: null,
    derniereActivite: DateTime.utc(2026, 10, 20, 14),
  ),
  ligneTest(
    id: 'e5',
    nom: 'Emna Gharbi',
    etat: EtatCandidature.aCompleter,
    enPause: true,
    repriseLe: DateTime.utc(2026, 11, 10),
    paiement: EtatVersement.incompatible,
    paysResidence: 'TN',
    derniereActivite: DateTime.utc(2026, 10, 20, 9),
  ),
  ligneTest(
    id: 'f6',
    nom: 'Farah Nasser',
    etat: EtatCandidature.paiementNonDisponible,
    paysResidence: 'EG',
    paiement: EtatVersement.incompatible,
    derniereActivite: DateTime.utc(2026, 10, 19, 11),
  ),
  ligneTest(
    id: 'g7',
    nom: 'Ghita Alaoui',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienPlanifie,
    paysResidence: 'MA',
    derniereActivite: DateTime.utc(2026, 10, 19, 8),
  ),
  ligneTest(
    id: 'h8',
    nom: 'Hamza Benali',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.decisionEnAttente,
    paysResidence: 'CA',
    derniereActivite: DateTime.utc(2026, 10, 18, 16),
  ),
  ligneTest(
    id: 'i9',
    nom: 'Ibtissem Cherif',
    etape: EtapeCandidature.confirmee,
    etat: null,
    restreinte: true,
    paysResidence: 'FR',
    derniereActivite: DateTime.utc(2026, 10, 18, 9),
  ),
  ligneTest(
    id: 'j10',
    nom: 'Jamal Ouedraogo',
    etat: EtatCandidature.aCompleter,
    paysResidence: 'BF',
    courrielAObtenir: true,
    derniereActivite: DateTime.utc(2026, 10, 17, 10),
  ),
  ligneTest(
    id: 'k11',
    nom: 'Khadija Sow',
    etape: EtapeCandidature.confirmee,
    etat: null,
    paysResidence: 'SN',
    paiement: EtatVersement.compatible,
    derniereActivite: DateTime.utc(2026, 10, 16, 15),
  ),
  ligneTest(
    id: 'l12',
    nom: 'Lamine Camara',
    issue: IssueCandidature.refusee,
    paysResidence: 'GN',
    derniereActivite: DateTime.utc(2026, 10, 15, 9),
  ),
  ligneTest(
    id: 'm13',
    nom: 'Maryam Qureshi',
    issue: IssueCandidature.retiree,
    paysResidence: 'GB',
    derniereActivite: DateTime.utc(2026, 10, 14, 9),
  ),
  ligneTest(
    id: 'n14',
    nom: 'Nour El Houda Bensalem',
    etape: EtapeCandidature.recue,
    etat: null,
    paysResidence: 'DZ',
    paiement: EtatVersement.inconnu,
    derniereActivite: DateTime.utc(2026, 10, 13, 9),
  ),
];

/// Monte la VRAIE application en demonstration d'administration, ouverte sur
/// la file, avec le port [port]. La demonstration pose deja le port des
/// invitations d'enseignant : le lien « Invitations » est rendu.
Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection port, {
  ThemeMode mode = ThemeMode.light,
  bool horsLigne = false,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
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
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
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

/// Remonte toutes les listes verticales en haut.
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
  debugPrint('PNG ${await capturer(tester, 'ADM-20/$nom')}');
}

/// Defile jusqu'au widget de cle [cle], en haut de la fenetre, puis capture.
Future<void> _photoSur(WidgetTester tester, String cle, String nom) async {
  final Finder f = find.byKey(ValueKey<String>(cle));
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.02);
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, 'ADM-20/$nom')}');
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('ADM-20 : captures', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', _telephone),
      ('1440', _bureau),
    ]) {
      final bool tel = taille == _telephone;
      final EdgeInsets zone = tel ? _zoneSure : EdgeInsets.zero;

      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('contenu $nom ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1, zoneSure: zone);
          await _monter(
            tester,
            FauxCandidaturesDirection(
              lignes: _lignes(),
              capacitesRendues: capacitesQuiDecide,
            ),
            mode: mode,
          );
          await _photo(tester, 'contenu_${nom}_${mode.name}');
          // La liste elle-meme, defilee jusqu'au total.
          await _photoSur(
            tester,
            'candidatures-total',
            'contenu-liste_${nom}_${mode.name}',
          );
        });
      }

      testWidgets('recherche sans resultat $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, FauxCandidaturesDirection(lignes: _lignes()));
        await tester.enterText(
          find.byKey(const ValueKey<String>('candidatures-recherche')),
          'zzz',
        );
        await stabiliser(tester);
        await _photoSur(
          tester,
          'candidatures-recherche',
          'aucun-resultat_${nom}_clair',
        );
      });

      testWidgets('erreur $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          FauxCandidaturesDirection(
            erreurLister: (int _) => StateError('panne'),
          ),
        );
        await _photo(tester, 'erreur_${nom}_clair');
      });

      testWidgets('hors ligne, rien de lu $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          FauxCandidaturesDirection(
            erreurLister: (int _) => StateError('panne'),
          ),
          horsLigne: true,
        );
        await _photo(tester, 'hors-ligne_${nom}_clair');
      });

      testWidgets('capacite indisponible $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, const CandidaturesDirectionIndisponible());
        await _photo(tester, 'indisponible_${nom}_clair');
      });

      testWidgets('vide $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, FauxCandidaturesDirection());
        await _photo(tester, 'vide_${nom}_clair');
      });

      testWidgets('genre inconnu $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          FauxCandidaturesDirection(
            erreurLister: (int _) => const GenreLecteurInconnu(),
          ),
        );
        await _photo(tester, 'genre-inconnu_${nom}_clair');
      });

      testWidgets('exception du super-admin et alertes a zero $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          FauxCandidaturesDirection(
            lignes: _lignes(),
            capacitesRendues: const CapacitesCandidatures(
              peutLire: true,
              peutLireHorsGenre: true,
              gestes: <String, bool>{'garderPourSuivi': true},
            ),
            alertes: const CompteursAlertes(
              bloquees: 0,
              entretiensEnRetard: 0,
              informationsManquantes: 0,
              confirmeesIndisponibles: 0,
            ),
          ),
        );
        await _photo(tester, 'exception-alertes-zero_${nom}_clair');
      });

      testWidgets('arabe de droite a gauche $nom clair', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          FauxCandidaturesDirection(
            lignes: _lignes(),
            capacitesRendues: capacitesQuiDecide,
          ),
        );
        await _photo(tester, 'arabe_${nom}_clair');
        await _photoSur(
          tester,
          'candidatures-total',
          'arabe-liste_${nom}_clair',
        );
      });
    }
  });
}
