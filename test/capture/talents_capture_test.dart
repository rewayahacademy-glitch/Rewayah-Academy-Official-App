// Captures de CAND-07 (« Vos autres talents », le parcours facultatif de la salle
// d'attente) : l'introduction, les competences par famille, les niveaux, la
// disponibilite et l'accord, les reponses enregistrees, la tuile du portail, puis
// les etats (pas encore ouvert, termine, erreur, hors ligne, pas encore branche,
// reponses retirees) et le cote direction (ligne de la fiche, filtre de la
// liste). 390x844 et 1440x900, clair ; le sombre ; l'arabe de droite a gauche.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../features/talents/hote_talents.dart';
import '../fixtures/candidature/faux_autres_competences.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

/// Monte la page sous le vrai theme, dans le cadre de capture.
Future<void> _monter(
  WidgetTester tester, {
  required FauxAutresCompetences? port,
  Size taille = _telephone,
  ThemeMode mode = ThemeMode.light,
  String depart = Routes.attenteTalents,
  bool horsLigne = false,
  double echelle = 1,
  bool attendre = true,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: routesTalents(),
  );
  await tester.pumpWidget(
    ProviderScope(
      // Une portee neuve a chaque montage : sans elle, une lecture gardee par la
      // precedente se retrouverait sur la capture suivante.
      key: UniqueKey(),
      overrides: surchargesTalents(
        port: port,
        etat: etatEnvoye(),
        horsLigne: horsLigne,
      ),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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

/// Capture le haut de la page.
Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  await capturer(tester, nom);
}

/// Fait defiler jusqu'au widget de cle [cle] (sans le toucher), puis capture.
Future<void> _photoSur(WidgetTester tester, String cle, String nom) async {
  final Finder f = cleTalents(cle);
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.02);
  await tester.pump();
  await capturer(tester, nom);
}

/// Les reponses d'un parcours rempli : deux competences, une disponibilite.
Map<String, Object?> _reponses({bool accord = true}) => reponsesJsonDeTest(
  domaines: const <String, String>{
    'comptabilite': 'metier',
    'reseaux_sociaux': 'experience',
    'assistanat': 'debutant',
  },
  disponibilite: 'mi_temps',
  accord: accord,
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group(
    'CAND-07 : captures de « Vos autres talents »',
    skip: sautSansCapture,
    () {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', _telephone),
        ('1440', _bureau),
      ]) {
        testWidgets('parcours $nom clair', (WidgetTester tester) async {
          await _monter(tester, port: FauxAutresCompetences(), taille: taille);
          await _photo(tester, 'introduction_${nom}_clair');
          await passerLIntroduction(tester);
          await _photo(tester, 'competences-haut_${nom}_clair');
          await toucherTalents(tester, 'talent-reseaux_sociaux');
          await toucherTalents(tester, 'talent-design_graphique');
          await toucherTalents(tester, 'talent-comptabilite');
          await _photoSur(
            tester,
            'talents-famille-pedagogie',
            'competences-milieu_${nom}_clair',
          );
          await toucherTalents(tester, 'talent-autre');
          await tester.enterText(
            find.descendant(
              of: cleTalents('talents-autre-champ'),
              matching: find.byType(TextField),
            ),
            'Secrétariat médical',
          );
          await tester.pump();
          await _photoSur(
            tester,
            'talents-autre-champ',
            'competences-autre_${nom}_clair',
          );
          // Sans niveau : le message dit lequel manque.
          await continuerTalents(tester);
          await _photo(tester, 'niveaux_${nom}_clair');
          await continuerTalents(tester);
          await _photo(tester, 'niveaux-manque_${nom}_clair');
        });

        testWidgets('disponibilite $nom clair', (WidgetTester tester) async {
          await _monter(tester, port: FauxAutresCompetences(), taille: taille);
          await passerLIntroduction(tester);
          await toucherTalents(tester, 'talent-comptabilite');
          await continuerTalents(tester);
          final Finder ligne = cleTalents('talents-niveau-comptabilite');
          await tester.tap(
            find.descendant(
              of: ligne,
              matching: find.text(libelleNiveauTest(NiveauCompetence.metier)),
            ),
          );
          await tester.pumpAndSettle();
          await continuerTalents(tester);
          await _photo(tester, 'disponibilite_${nom}_clair');
          await toucherTalents(tester, 'talents-dispo-mi_temps');
          await toucherTalents(tester, 'talents-accord');
          await _photo(tester, 'disponibilite-choix_${nom}_clair');
        });

        testWidgets('reponses enregistrees $nom clair', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            port: FauxAutresCompetences(
              lectureJson: autresCompetencesJsonDeTest(
                version: 2,
                reponses: _reponses(),
              ),
            ),
            taille: taille,
          );
          await _photo(tester, 'reponses_${nom}_clair');
        });

        testWidgets('portail $nom clair', (WidgetTester tester) async {
          await _monter(
            tester,
            port: FauxAutresCompetences(),
            taille: taille,
            depart: Routes.attente,
          );
          await _photoSur(
            tester,
            'portail-talents',
            'portail-tuile_${nom}_clair',
          );
        });

        testWidgets('etats $nom clair', (WidgetTester tester) async {
          await _monter(
            tester,
            port: FauxAutresCompetences(
              lectureJson: autresCompetencesJsonDeTest(
                ouvert: false,
                raison: 'questionnaire_non_envoye',
              ),
            ),
            taille: taille,
          );
          await _photo(tester, 'non-envoye_${nom}_clair');
          await _monter(
            tester,
            port: FauxAutresCompetences(
              lectureJson: autresCompetencesJsonDeTest(
                ouvert: false,
                raison: 'candidature_close',
              ),
            ),
            taille: taille,
          );
          await _photo(tester, 'clos_${nom}_clair');
          await _monter(
            tester,
            port: FauxAutresCompetences(
              lectureJson: autresCompetencesJsonDeTest(
                ouvert: false,
                raison: 'candidature_close',
                version: 2,
                reponses: _reponses(),
              ),
            ),
            taille: taille,
          );
          await _photo(tester, 'reponses-candidature-close_${nom}_clair');
          await _monter(
            tester,
            port: FauxAutresCompetences()
              ..erreurLectureDurable = Exception('panne'),
            taille: taille,
          );
          await _photo(tester, 'erreur_${nom}_clair');
          await _monter(tester, port: null, taille: taille);
          await _photo(tester, 'pas-encore-ouvert_${nom}_clair');
          await _monter(
            tester,
            port: FauxAutresCompetences()
              ..erreurLectureDurable = const CapaciteIndisponible('x'),
            taille: taille,
            horsLigne: true,
          );
          await _photo(tester, 'indisponible-hors-ligne_${nom}_clair');
        });

        testWidgets('chargement $nom clair', (WidgetTester tester) async {
          final Completer<void> attente = Completer<void>();
          await _monter(
            tester,
            port: FauxAutresCompetences()..attente = attente,
            taille: taille,
            attendre: false,
          );
          await tester.pump(const Duration(milliseconds: 400));
          await _photo(tester, 'chargement_${nom}_clair');
          attente.complete();
          await tester.pumpAndSettle();
        });

        testWidgets('hors ligne $nom clair', (WidgetTester tester) async {
          await _monter(
            tester,
            port: FauxAutresCompetences(),
            taille: taille,
            horsLigne: true,
          );
          await passerLIntroduction(tester);
          await toucherTalents(tester, 'talent-comptabilite');
          await continuerTalents(tester);
          await tester.tap(
            find.descendant(
              of: cleTalents('talents-niveau-comptabilite'),
              matching: find.text(libelleNiveauTest(NiveauCompetence.metier)),
            ),
          );
          await tester.pumpAndSettle();
          await continuerTalents(tester);
          await toucherTalents(tester, 'talents-dispo-mi_temps');
          await _photo(tester, 'hors-ligne-enregistrer_${nom}_clair');
        });
      }

      // Le gabarit le plus dur : 320 de large, texte x2. Les niveaux passent en
      // lignes a choix unique, et la barre du bas garde la place du contenu.
      testWidgets('niveaux 320 x2 clair', (WidgetTester tester) async {
        await _monter(
          tester,
          port: FauxAutresCompetences(),
          taille: const Size(320, 568),
          echelle: 2,
        );
        await passerLIntroduction(tester);
        await toucherTalents(tester, 'talent-reseaux_sociaux');
        await toucherTalents(tester, 'talent-comptabilite');
        await continuerTalents(tester);
        await _photo(tester, 'niveaux_320x2_clair');
        await continuerTalents(tester);
        await _photo(tester, 'niveaux-manque_320x2_clair');
      });

      testWidgets('sombre 390', (WidgetTester tester) async {
        await _monter(
          tester,
          port: FauxAutresCompetences(),
          mode: ThemeMode.dark,
        );
        await _photo(tester, 'introduction_390_sombre');
        await passerLIntroduction(tester);
        await toucherTalents(tester, 'talent-comptabilite');
        await _photo(tester, 'competences_390_sombre');
        await _monter(
          tester,
          port: FauxAutresCompetences(
            lectureJson: autresCompetencesJsonDeTest(
              version: 2,
              reponses: _reponses(),
            ),
          ),
          mode: ThemeMode.dark,
        );
        await _photo(tester, 'reponses_390_sombre');
      });

      testWidgets('sombre 1440', (WidgetTester tester) async {
        await _monter(
          tester,
          port: FauxAutresCompetences(),
          taille: _bureau,
          mode: ThemeMode.dark,
        );
        await passerLIntroduction(tester);
        await toucherTalents(tester, 'talent-comptabilite');
        await _photo(tester, 'competences_1440_sombre');
      });

      testWidgets('arabe 390', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(tester, port: FauxAutresCompetences());
        await _photo(tester, 'introduction_390_arabe');
        await passerLIntroduction(tester);
        await toucherTalents(tester, 'talent-comptabilite');
        await toucherTalents(tester, 'talent-reseaux_sociaux');
        await _photo(tester, 'competences_390_arabe');
        await continuerTalents(tester);
        await _photo(tester, 'niveaux_390_arabe');
      });

      testWidgets('arabe 1440', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(tester, port: FauxAutresCompetences(), taille: _bureau);
        await passerLIntroduction(tester);
        await toucherTalents(tester, 'talent-comptabilite');
        await _photo(tester, 'competences_1440_arabe');
      });
    },
  );
}

/// Le libelle d'un niveau, dans la langue courante.
String libelleNiveauTest(NiveauCompetence n) => switch (n) {
  NiveauCompetence.debutant => t.recrutement.talents.niveaux.debutant.libelle,
  NiveauCompetence.experience =>
    t.recrutement.talents.niveaux.experience.libelle,
  NiveauCompetence.metier => t.recrutement.talents.niveaux.metier.libelle,
};
