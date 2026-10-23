// ADM-21 x CAND-07 : la ligne « Autres competences » de la candidature, lue par
// la direction. Ce que le test prouve :
// - ce que la personne a repondu se lit en mots : chaque competence avec son
//   niveau (a la troisieme personne), la disponibilite, l'accord ; jamais un code
//   du serveur (`comptabilite`, `mi_temps`, `metier`) ;
// - le texte « Autre domaine » est dit tel que la personne l'a ecrit ;
// - sans reponse : une phrase, jamais un bloc vide ; avant le lot serveur (aucune
//   cle), la meme phrase ;
// - sans accord : la ligne dit de ne proposer aucune mission ; avec accord, la
//   date ;
// - une competence ajoutee par la direction depuis prend son libelle du
//   catalogue ; sans catalogue lu, une phrase neutre, jamais son code ;
// - le bloc est lu seul, sans geste ni bouton ; il vient apres les reponses de
//   la candidature ; il se lit aux gabarits les plus durs, en arabe aussi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/bloc_autres_competences.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_autres_competences.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_coupe_mots_rendu.dart';
import '../../support/garde_interface.dart';
import 'hote_candidature.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

ReponsesAutresCompetences _reponses({
  Map<String, String> domaines = const <String, String>{
    'comptabilite': 'metier',
    'reseaux_sociaux': 'experience',
    'autre': 'debutant',
  },
  String? autreTexte = 'Secrétariat médical',
  String disponibilite = 'mi_temps',
  bool accord = true,
}) => ReponsesAutresCompetences.depuisJson(
  reponsesJsonDeTest(
    domaines: domaines,
    autreTexte: autreTexte,
    disponibilite: disponibilite,
    accord: accord,
  ),
)!;

FauxCandidaturesDirection _port({ReponsesAutresCompetences? reponses}) =>
    FauxCandidaturesDirection(
      details: <DetailCandidature>[detailTest(autresCompetences: reponses)],
    );

/// Le catalogue de la direction, avec [ajoutees] en plus.
List<Override> _catalogue({
  List<Map<String, Object?>> ajoutees = const <Map<String, Object?>>[],
  Object? erreur,
}) => <Override>[
  portCatalogueCompetencesProvider.overrideWithValue(
    FauxCatalogueCompetences(
      json: <String, dynamic>{
        'familles': famillesDeTest,
        'competences': catalogueJsonDeTest(
          avecVersion: true,
          ajoutees: ajoutees,
        ),
        'peutModifier': true,
      },
    )..erreur = erreur,
  ),
];

Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection port, {
  List<Override> surcharges = const <Override>[],
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterCandidature(
  tester,
  port: port,
  surcharges: surcharges,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

/// Tout le texte visible du bloc.
String _texteDuBloc(WidgetTester tester) => <String>[
  for (final Element e
      in find
          .descendant(
            of: _cle('candidature-autres-competences'),
            matching: find.byType(Text),
          )
          .evaluate())
    if ((e.widget as Text).data case final String d) d,
].join('\n');

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  final r = t.admin.candidatures.detail.talents;

  group('des reponses enregistrees', () {
    testWidgets('chaque competence avec son niveau, la disponibilite et '
        'l accord', (WidgetTester tester) async {
      await _monter(
        tester,
        _port(reponses: _reponses()),
        surcharges: _catalogue(),
      );
      expect(_cle('candidature-autres-competences'), findsOneWidget);
      expect(find.text(r.titre), findsOneWidget);
      // Les competences, dans l'ordre du catalogue (communication d'abord).
      expect(
        find.descendant(
          of: _cle('candidature-talents-reseaux_sociaux'),
          matching: find.text(t.recrutement.talents.c.reseaux_sociaux.libelle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cle('candidature-talents-reseaux_sociaux'),
          matching: find.text(r.niveaux.experience),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cle('candidature-talents-comptabilite'),
          matching: find.text(r.niveaux.metier),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cle('candidature-talents-autre'),
          matching: find.text(r.niveaux.debutant),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cle('candidature-talents-disponibilite'),
          matching: find.text(
            t.recrutement.talents.disponibilite.mi_temps.libelle,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(BlocAutresCompetences.aucuneKey), findsNothing);
      expect(
        tester.getTopLeft(_cle('candidature-talents-reseaux_sociaux')).dy,
        lessThan(
          tester.getTopLeft(_cle('candidature-talents-comptabilite')).dy,
        ),
        reason: 'ordre du catalogue : communication avant finances',
      );
    });

    testWidgets('sans catalogue lu, les competences suivent l ordre des '
        'codes : une lecture stable', (WidgetTester tester) async {
      await _monter(tester, _port(reponses: _reponses()));
      final double comptabilite = tester
          .getTopLeft(_cle('candidature-talents-comptabilite'))
          .dy;
      final double reseaux = tester
          .getTopLeft(_cle('candidature-talents-reseaux_sociaux'))
          .dy;
      expect(comptabilite, lessThan(reseaux));
    });

    testWidgets('le texte « Autre domaine » se dit tel que la personne '
        'l a ecrit', (WidgetTester tester) async {
      await _monter(tester, _port(reponses: _reponses()));
      expect(
        find.descendant(
          of: _cle('candidature-talents-autre'),
          matching: find.text(r.autre(texte: 'Secrétariat médical')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('aucun code du serveur n est montre', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(reponses: _reponses()));
      final String texte = _texteDuBloc(tester);
      for (final String code in <String>[
        'comptabilite',
        'reseaux_sociaux',
        'mi_temps',
        'metier',
        'experience',
        'debutant',
        'quelques_heures',
      ]) {
        expect(texte, isNot(contains(code)), reason: code);
      }
    });

    testWidgets('l accord donne dit sa date', (WidgetTester tester) async {
      await _monter(tester, _port(reponses: _reponses()));
      final String texte = _texteDuBloc(tester);
      expect(texte, contains('22'));
      expect(texte, isNot(contains(r.accordAbsent)));
      expect(_cle('candidature-talents-accord'), findsOneWidget);
    });

    testWidgets('sans accord : ne proposer aucune mission', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(reponses: _reponses(accord: false)));
      expect(
        find.descendant(
          of: _cle('candidature-talents-accord'),
          matching: find.text(r.accordAbsent),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la mise a jour est datee', (WidgetTester tester) async {
      await _monter(tester, _port(reponses: _reponses()));
      expect(find.textContaining('Dernière mise à jour le'), findsOneWidget);
    });

    testWidgets('sans « Autre domaine », aucune ligne « Autre »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          reponses: _reponses(
            domaines: const <String, String>{'comptabilite': 'metier'},
            autreTexte: null,
          ),
        ),
      );
      expect(_cle('candidature-talents-autre'), findsNothing);
      expect(_cle('candidature-talents-comptabilite'), findsOneWidget);
    });
  });

  group('sans reponse', () {
    testWidgets('une phrase, jamais un bloc vide', (WidgetTester tester) async {
      await _monter(tester, _port());
      expect(find.byKey(BlocAutresCompetences.aucuneKey), findsOneWidget);
      expect(find.text(r.aucune), findsOneWidget);
      expect(_cle('candidature-talents-disponibilite'), findsNothing);
      expect(_cle('candidature-talents-accord'), findsNothing);
    });
  });

  group('le catalogue de la direction', () {
    testWidgets('une competence ajoutee depuis prend son libelle', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          reponses: _reponses(
            domaines: const <String, String>{'traduction_ourdou': 'metier'},
            autreTexte: null,
          ),
        ),
        surcharges: _catalogue(
          ajoutees: <Map<String, Object?>>[
            entreeJsonDeTest(
              'traduction_ourdou',
              famille: 'communication',
              libelle: 'Traduction vers l\'ourdou',
            ),
          ],
        ),
      );
      expect(
        find.descendant(
          of: _cle('candidature-talents-traduction_ourdou'),
          matching: find.text('Traduction vers l\'ourdou'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('traduction_ourdou'), findsNothing);
    });

    testWidgets('sans catalogue lu : une phrase neutre, jamais le code', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(
          reponses: _reponses(
            domaines: const <String, String>{'traduction_ourdou': 'metier'},
            autreTexte: null,
          ),
        ),
      );
      expect(
        find.descendant(
          of: _cle('candidature-talents-traduction_ourdou'),
          matching: find.text(r.competenceInconnue),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('traduction_ourdou'), findsNothing);
    });

    testWidgets('un catalogue en echec ne retire rien : la ligne se lit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _port(reponses: _reponses()),
        surcharges: _catalogue(erreur: Exception('panne')),
      );
      expect(_cle('candidature-talents-comptabilite'), findsOneWidget);
      expect(_cle('candidature-talents-reseaux_sociaux'), findsOneWidget);
    });
  });

  group('sa place et sa nature', () {
    testWidgets('apres les reponses de la candidature, sans bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _port(reponses: _reponses()));
      expect(
        tester.getTopLeft(_cle('candidature-autres-competences')).dy,
        greaterThan(tester.getTopLeft(find.byKey(BlocReponses.cle)).dy),
      );
      // Lecture seule : ni bouton ni champ dans le bloc.
      expect(
        find.descendant(
          of: _cle('candidature-autres-competences'),
          matching: find.byWidgetPredicate(
            (Widget w) => w is TextField || w is ElevatedButton,
          ),
        ),
        findsNothing,
      );
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('un seul bloc, en colonne large comme en colonne etroite', (
      WidgetTester tester,
    ) async {
      for (final double largeur in <double>[390, 1440]) {
        await _monter(tester, _port(reponses: _reponses()), largeur: largeur);
        expect(_cle('candidature-autres-competences'), findsOneWidget);
      }
    });
  });

  group('lisible aux gabarits les plus durs', () {
    for (final (String nom, double largeur, double echelle)
        in <(String, double, double)>[
          ('320 x2', 320, 2),
          ('390 x1', 390, 1),
          ('1440 x1', 1440, 1),
        ]) {
      testWidgets('francais, $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          _port(reponses: _reponses()),
          largeur: largeur,
          echelle: echelle,
        );
        expect(
          await defautsEcranDefile(tester),
          isEmpty,
          reason: 'defaut de texte, $nom',
        );
      });
    }

    testWidgets('arabe de droite a gauche, 320 x2', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        _port(reponses: _reponses(autreTexte: 'سكرتارية طبية')),
        largeur: 320,
        echelle: 2,
        direction: TextDirection.rtl,
      );
      expect(_cle('candidature-autres-competences'), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.detail.talents.titre),
        findsOneWidget,
      );
      expect(
        await defautsEcranDefile(tester),
        isEmpty,
        reason: 'defaut de texte, arabe 320 x2',
      );
    });
  });
}
