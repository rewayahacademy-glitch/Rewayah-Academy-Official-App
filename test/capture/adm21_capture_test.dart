// Captures d'ADM-21 (une candidature ouverte par la direction), sur la VRAIE
// application et le vrai routeur en demonstration d'administration : la barre
// laterale, la page de la candidature, ses feuilles de gestes.
//
// Etats : contenu (Salle d'examen, versement a verifier), prochaine action,
// fin de page, historique, feuille d'un geste motive (refus), feuille du
// complement (elements choisis, aucun texte libre), refus nomme du serveur (controles non satisfaits),
// contact ouvert, erreur de lecture, capacite indisponible, hors portee, hors
// ligne ; 390x844 et 1440x900, clair ; le sombre ; l'arabe de droite a gauche.
//
// Les donnees sont fictives, posees par le double du port
// (`test/fixtures/candidature/faux_candidatures_direction.dart`) : aucune
// personne reelle. Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Une candidature fictive en Salle d'examen, versement a verifier : ce qui se
/// voit au premier regard, la prochaine action est de confirmer le moyen.
FauxCandidaturesDirection _port({
  DetailCandidature? detail,
  Object? Function(int)? erreurLire,
  Object? Function(DemandeGeste, int)? erreurGeste,
}) => FauxCandidaturesDirection(
  capacitesRendues: capacitesGestes,
  details: <DetailCandidature>[detail ?? detailTest()],
  erreurLire: erreurLire,
  erreurGeste: erreurGeste,
  contacts: const <String, ContactCandidat>{
    'c1': ContactCandidat(
      courriel: 'amina.diallo@exemple.org',
      telephone: '+221771234567',
    ),
  },
  moyens: const <String, MoyensConfirmes>{
    'SN': MoyensConfirmes(
      virementBancaire: true,
      operateurs: <OperateurPaiement>[
        OperateurPaiement(code: 'orange_money', nom: 'Orange Money'),
      ],
    ),
  },
  historiques: <String, List<EvenementCandidature>>{
    'c1': <EvenementCandidature>[
      evenementTest(
        id: 4,
        type: 'transition',
        auteur: AuteurEvenement.candidat,
        quand: DateTime.utc(2026, 10, 18, 14),
        etapeAvant: EtapeCandidature.prequalification,
        etapeApres: EtapeCandidature.prequalification,
        etatAvant: EtatCandidature.aCompleter,
        etatApres: EtatCandidature.enExamen,
      ),
      evenementTest(
        id: 3,
        type: 'transition',
        auteur: AuteurEvenement.direction,
        quand: DateTime.utc(2026, 10, 17, 9, 30),
        etapeAvant: EtapeCandidature.prequalification,
        etapeApres: EtapeCandidature.prequalification,
        etatAvant: EtatCandidature.enExamen,
        etatApres: EtatCandidature.aCompleter,
        motif: 'Disponibilites a preciser pour le soir.',
      ),
      evenementTest(
        id: 2,
        type: 'controle',
        auteur: AuteurEvenement.systeme,
        quand: DateTime.utc(2026, 10, 16, 8),
      ),
      evenementTest(
        id: 1,
        type: 'creee',
        auteur: AuteurEvenement.systeme,
        quand: DateTime.utc(2026, 10, 1, 9),
      ),
    ],
  },
);

/// Monte la VRAIE application en demonstration d'administration, ouverte sur
/// la candidature `CAND-0000C1`, avec le port [port].
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
        horlogeFormulairesProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 22, 12),
        ),
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
  unawaited(
    routeur.push<void>(
      Routes.adminPersonnesCandidaturePour('CAND-0000C1'),
      extra: 'c1',
    ),
  );
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
  debugPrint('PNG ${await capturer(tester, 'ADM-21/$nom')}');
}

/// Defile jusqu'au widget de cle [cle], en haut de la fenetre, puis capture.
Future<void> _photoSur(WidgetTester tester, Key cle, String nom) async {
  final Finder f = find.byKey(cle);
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.02);
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, 'ADM-21/$nom')}');
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('ADM-21 : captures', skip: sautSansCapture, () {
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
          await _monter(tester, _port(), mode: mode);
          await _photo(tester, 'contenu_${nom}_${mode.name}');
          await _photoSur(
            tester,
            BlocProchaineAction.cle,
            'action_${nom}_${mode.name}',
          );
          await _photoSur(
            tester,
            BlocReponses.cle,
            'reponses_${nom}_${mode.name}',
          );
          await _photoSur(
            tester,
            BlocPieceEntretien.cle,
            'fin_${nom}_${mode.name}',
          );
          await _photoSur(
            tester,
            BlocHistorique.cle,
            'historique_${nom}_${mode.name}',
          );
        });
      }

      testWidgets('feuille du refus $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        await tester.tap(find.byKey(BlocProchaineAction.cleMenu));
        await stabiliser(tester);
        await tester.tap(find.text(t.admin.candidatures.gestes.refuser));
        await stabiliser(tester);
        await tester.enterText(
          find.descendant(
            of: find.byKey(FeuilleGeste.cleMotif),
            matching: find.byType(EditableText),
          ),
          'Niveau insuffisant pour les debutants.',
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('modele-refus_niveau')),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ADM-21/refus_${nom}_clair')}',
        );
      });

      testWidgets('feuille du complement $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        await tester.tap(find.byKey(BlocProchaineAction.cleMenu));
        await stabiliser(tester);
        await tester.tap(
          find.text(t.admin.candidatures.gestes.demanderComplement),
        );
        await stabiliser(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('element-disponibilites')),
        );
        await stabiliser(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('element-versement')),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ADM-21/complement_${nom}_clair')}',
        );
        await tester.ensureVisible(find.byKey(FeuilleGeste.cleValider));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ADM-21/complement-bas_${nom}_clair')}',
        );
      });

      testWidgets('refus nomme du serveur $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          _port(
            detail: detailTest(paiement: EtatVersement.compatible),
            erreurGeste: (DemandeGeste _, int _) =>
                const ControlesNonSatisfaits(<({String nom, String? cause})>[
                  (nom: 'cadre_religieux', cause: 'non_accepte'),
                  (nom: 'questionnaire_complet', cause: 'perime'),
                ]),
          ),
        );
        await tester.ensureVisible(find.byKey(BlocProchaineAction.cleBouton));
        await stabiliser(tester);
        await tester.tap(find.byKey(BlocProchaineAction.cleBouton));
        await stabiliser(tester);
        await tester.ensureVisible(find.byKey(FeuilleGeste.cleValider));
        await stabiliser(tester);
        await tester.tap(find.byKey(FeuilleGeste.cleValider));
        await stabiliser(tester);
        await tester.ensureVisible(find.byKey(FeuilleGeste.cleRefus));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ADM-21/refus-serveur_${nom}_clair')}',
        );
      });

      testWidgets('contact ouvert $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        await Scrollable.ensureVisible(
          tester.element(find.byKey(BlocContact.cleVoir)),
          alignment: 0.3,
        );
        await stabiliser(tester);
        await tester.tap(find.byKey(BlocContact.cleVoir));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ADM-21/contact_${nom}_clair')}',
        );
      });

      testWidgets('erreur de lecture $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          _port(erreurLire: (int _) => StateError('panne')),
        );
        await _photo(tester, 'erreur_${nom}_clair');
      });

      testWidgets('hors portee $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          _port(erreurLire: (int _) => const CandidatureHorsPortee()),
        );
        await _photo(tester, 'hors-portee_${nom}_clair');
      });

      testWidgets('capacite indisponible $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, const CandidaturesDirectionIndisponible());
        await _photo(tester, 'indisponible_${nom}_clair');
      });

      testWidgets('hors ligne $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port(), horsLigne: true);
        await _photo(tester, 'hors-ligne_${nom}_clair');
      });

      testWidgets('arabe de droite a gauche $nom clair', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        await _photo(tester, 'arabe_${nom}_clair');
        await _photoSur(
          tester,
          BlocReponses.cle,
          'arabe-reponses_${nom}_clair',
        );
      });
    }
  });
}
