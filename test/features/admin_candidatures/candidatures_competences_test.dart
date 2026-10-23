// ADM-20 x CAND-07 : chercher une personne par ses autres competences. Ce que le
// test prouve :
// - quatre menus de plus (domaine, niveau, disponibilite, accord), sous « Plus »
//   avec les autres menus : chacun filtre AU SERVEUR (le filtre part avec le
//   bon axe, la page revient a 1), et se relache par « Tous » ;
// - le domaine se choisit par famille (liste fermee que l'application nomme) ou
//   par competence quand le catalogue de la direction est lu ; sans catalogue, les
//   familles seules, jamais un code ;
// - le niveau est « au moins » : deux valeurs (« a de l'experience ou plus », « en
//   fait son metier »), jamais « debute » ;
// - le rappel des filtres, quand rien ne correspond, nomme les axes en mots ;
// - les axes se cumulent, et « Effacer les filtres » les relache ;
// - la rangee et la feuille « Plus » se lisent aux gabarits les plus durs, en
//   arabe aussi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_autres_competences.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart';
import 'package:rewayah_academy/features/talents/libelles_talents.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_autres_competences.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_coupe_mots_rendu.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import '../../support/rangee_plus.dart';
import 'hote_candidatures.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

const String _domaine = 'candidatures-filtre-competence';
const String _niveau = 'candidatures-filtre-competence-niveau';
const String _disponibilite = 'candidatures-filtre-competence-disponibilite';
const String _accord = 'candidatures-filtre-competence-accord';

FauxCandidaturesDirection _port() => FauxCandidaturesDirection(
  lignes: <LigneCandidature>[
    ligneTest(id: 'a1', nom: 'Amina Diallo'),
    ligneTest(id: 'b2', nom: 'Bilal Haddad'),
  ],
);

List<Override> _catalogue() => <Override>[
  portCatalogueCompetencesProvider.overrideWithValue(
    FauxCatalogueCompetences(
      json: <String, dynamic>{
        'familles': famillesDeTest,
        'competences': catalogueJsonDeTest(
          avecVersion: true,
          ajoutees: <Map<String, Object?>>[
            entreeJsonDeTest(
              'traduction_ourdou',
              famille: 'communication',
              libelle: 'Traduction vers l\'ourdou',
            ),
          ],
        ),
        'peutModifier': true,
      },
    ),
  ),
];

/// Choisit [libelle] dans le menu de cle [cle].
Future<void> _choisir(WidgetTester tester, String cle, String libelle) async {
  await ouvrirMenuFiltre(tester, _cle(cle));
  await tester.tap(find.text(libelle).last);
  await tester.pumpAndSettle();
  await fermerPlus(tester);
  await laisser(tester);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  final f = t.admin.candidatures.filtres.talents;

  group('les quatre menus', () {
    testWidgets('chacun est pose, avec son libelle', (
      WidgetTester tester,
    ) async {
      await monterCandidatures(tester, port: _port());
      await ouvrirPlus(tester);
      for (final String cle in <String>[
        _domaine,
        _niveau,
        _disponibilite,
        _accord,
      ]) {
        expect(_cle(cle), findsWidgets, reason: cle);
      }
      expect(find.text(f.domaine), findsWidgets);
      expect(find.text(f.niveau), findsWidgets);
      expect(find.text(f.disponibilite), findsWidgets);
      expect(find.text(f.accord), findsWidgets);
    });

    testWidgets('le domaine filtre au serveur, par famille', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port);
      await _choisir(
        tester,
        _domaine,
        f.familleToutes(famille: titreFamille(FamilleCompetence.financesDroit)),
      );
      expect(port.appels.last.filtre.competenceDomaine, 'finances_droit');
      expect(port.appels.last.page, 1);
    });

    testWidgets('le niveau est « au moins » : deux valeurs, jamais '
        '« debute »', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port);
      await ouvrirMenuFiltre(tester, _cle(_niveau));
      expect(find.text(f.niveauExperience), findsWidgets);
      expect(find.text(f.niveauMetier), findsWidgets);
      expect(
        find.text(t.admin.candidatures.detail.talents.niveaux.debutant),
        findsNothing,
      );
      await tester.tap(find.text(f.niveauMetier).last);
      await tester.pumpAndSettle();
      await fermerPlus(tester);
      await laisser(tester);
      expect(
        port.appels.last.filtre.competenceNiveauMin,
        NiveauCompetence.metier,
      );
      expect(port.appels.last.page, 1);
    });

    testWidgets('la disponibilite est exacte : chaque valeur se choisit', (
      WidgetTester tester,
    ) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port);
      await _choisir(
        tester,
        _disponibilite,
        libelleDisponibilite(DisponibiliteMission.plus),
      );
      expect(
        port.appels.last.filtre.competenceDisponibilite,
        DisponibiliteMission.plus,
      );
    });

    testWidgets('l accord : donne ou non donne', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port);
      await _choisir(tester, _accord, f.accordDonne);
      expect(port.appels.last.filtre.competenceAccord, isTrue);
      await _choisir(tester, _accord, f.accordAbsent);
      expect(port.appels.last.filtre.competenceAccord, isFalse);
    });

    testWidgets('« Tous » relache l axe', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port);
      await _choisir(tester, _accord, f.accordDonne);
      expect(port.appels.last.filtre.competenceAccord, isTrue);
      await _choisir(tester, _accord, t.admin.candidatures.filtres.tous);
      expect(port.appels.last.filtre.competenceAccord, isNull);
      expect(port.appels.last.filtre.estVide, isTrue);
    });

    testWidgets('les axes se cumulent, le rappel les nomme et « Effacer » les '
        'relache d un coup', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port);
      await _choisir(tester, _niveau, f.niveauExperience);
      await _choisir(tester, _accord, f.accordDonne);
      final FiltreCandidatures filtre = port.appels.last.filtre;
      expect(filtre.competenceNiveauMin, NiveauCompetence.experience);
      expect(filtre.competenceAccord, isTrue);
      expect(filtre.nombreAxes, 2);
      // Personne ne correspond : l'ecran dit lesquels des filtres posent
      // question, et « Effacer » les relache.
      port.lignes.clear();
      await _choisir(
        tester,
        _disponibilite,
        libelleDisponibilite(DisponibiliteMission.plus),
      );
      expect(port.appels.last.filtre.nombreAxes, 3);
      expect(
        find.textContaining(f.niveauExperience),
        findsWidgets,
        reason: 'le rappel nomme le niveau',
      );
      expect(find.text(t.admin.journal.effacerFiltres), findsOneWidget);
      await tester.tap(find.text(t.admin.journal.effacerFiltres));
      await laisser(tester);
      expect(port.appels.last.filtre.estVide, isTrue);
    });
  });

  group('le domaine et le catalogue', () {
    testWidgets('sans catalogue lu : les familles seules, jamais un code', (
      WidgetTester tester,
    ) async {
      await monterCandidatures(tester, port: _port());
      await ouvrirMenuFiltre(tester, _cle(_domaine));
      for (final FamilleCompetence fam in FamilleCompetence.values) {
        if (fam == FamilleCompetence.autre) {
          continue;
        }
        expect(
          find.text(f.familleToutes(famille: titreFamille(fam))),
          findsWidgets,
          reason: fam.valeurSql,
        );
      }
      // Aucune competence nommee, aucun code.
      expect(find.text('Comptabilité'), findsNothing);
      expect(find.textContaining('comptabilite'), findsNothing);
    });

    testWidgets('avec le catalogue : chaque competence, dont celles que la '
        'direction a ajoutees', (WidgetTester tester) async {
      final FauxCandidaturesDirection port = _port();
      await monterCandidatures(tester, port: port, surcharges: _catalogue());
      await ouvrirMenuFiltre(tester, _cle(_domaine));
      expect(
        find.text(t.recrutement.talents.c.comptabilite.libelle),
        findsWidgets,
      );
      expect(find.text('Traduction vers l\'ourdou'), findsWidgets);
      expect(find.textContaining('traduction_ourdou'), findsNothing);
      await tester.tap(find.text('Traduction vers l\'ourdou').last);
      await tester.pumpAndSettle();
      await fermerPlus(tester);
      await laisser(tester);
      expect(port.appels.last.filtre.competenceDomaine, 'traduction_ourdou');
    });

    testWidgets('« Autre domaine » est une competence, pas une famille a '
        'part', (WidgetTester tester) async {
      await monterCandidatures(tester, port: _port(), surcharges: _catalogue());
      await ouvrirMenuFiltre(tester, _cle(_domaine));
      expect(
        find.text(
          f.familleToutes(famille: titreFamille(FamilleCompetence.autre)),
        ),
        findsNothing,
      );
      expect(find.text(t.recrutement.talents.c.autre.libelle), findsWidgets);
    });
  });

  group('le rappel des filtres', () {
    test('chaque axe se dit en mots, jamais en code', () {
      final String? rappel = rappelFiltres(
        const FiltreCandidatures(
          competenceDomaine: 'finances_droit',
          competenceNiveauMin: NiveauCompetence.metier,
          competenceDisponibilite: DisponibiliteMission.plus,
          competenceAccord: true,
        ),
      );
      expect(rappel, isNotNull);
      expect(rappel, contains(titreFamille(FamilleCompetence.financesDroit)));
      expect(rappel, contains(f.niveauMetier));
      expect(rappel, contains(libelleDisponibilite(DisponibiliteMission.plus)));
      expect(rappel, contains(f.accordDonne));
      for (final String code in <String>[
        'finances_droit',
        'metier',
        'plus',
        'competenceDomaine',
      ]) {
        expect(rappel, isNot(contains(code)), reason: code);
      }
    });

    test('au moins l experience : la phrase dit « ou plus »', () {
      expect(
        rappelFiltres(
          const FiltreCandidatures(
            competenceNiveauMin: NiveauCompetence.experience,
          ),
        ),
        contains(f.niveauExperience),
      );
    });

    test('sans accord : la phrase dit « sans accord »', () {
      expect(
        rappelFiltres(const FiltreCandidatures(competenceAccord: false)),
        contains(f.accordAbsent),
      );
    });

    test('un code de competence inconnu se dit par une phrase neutre', () {
      final String? rappel = rappelFiltres(
        const FiltreCandidatures(competenceDomaine: 'traduction_ourdou'),
      );
      expect(
        rappel,
        contains(t.admin.candidatures.detail.talents.competenceInconnue),
      );
      expect(rappel, isNot(contains('traduction_ourdou')));
    });
  });

  group('lisible aux gabarits les plus durs', () {
    for (final (String nom, double largeur, double echelle)
        in <(String, double, double)>[
          ('320 x2', 320, 2),
          ('390 x1', 390, 1),
          ('1440 x1', 1440, 1),
        ]) {
      testWidgets('francais, la feuille « Plus » a $nom', (
        WidgetTester tester,
      ) async {
        await monterCandidatures(
          tester,
          port: _port(),
          surcharges: _catalogue(),
          largeur: largeur,
          hauteur: 900,
          echelle: echelle,
        );
        await ouvrirPlus(tester);
        expect(
          await defautsEcranDefile(tester),
          isEmpty,
          reason: 'defaut de texte, $nom',
        );
        verifierUnSeulBoutonPlein(tester);
      });

      testWidgets('francais, le menu du domaine a $nom', (
        WidgetTester tester,
      ) async {
        await monterCandidatures(
          tester,
          port: _port(),
          surcharges: _catalogue(),
          largeur: largeur,
          hauteur: 900,
          echelle: echelle,
        );
        // La feuille « Plus » defile : le menu du domaine est amene dans la
        // vue avant d'etre touche.
        await ouvrirPlus(tester);
        await tester.ensureVisible(_cle(_domaine).last);
        await tester.pumpAndSettle();
        await tester.tap(_cle(_domaine).last);
        await tester.pumpAndSettle();
        expect(find.text('Traduction vers l\'ourdou'), findsWidgets);
        expect(
          await defautsEcranDefile(tester),
          isEmpty,
          reason: 'defaut de texte du menu, $nom',
        );
      });
    }

    testWidgets('arabe de droite a gauche, la feuille « Plus » a 320 x2', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await monterCandidatures(
        tester,
        port: _port(),
        surcharges: _catalogue(),
        largeur: 320,
        hauteur: 900,
        echelle: 2,
        direction: TextDirection.rtl,
      );
      await ouvrirPlus(tester);
      expect(_cle(_domaine), findsWidgets);
      expect(
        await defautsEcranDefile(tester),
        isEmpty,
        reason: 'defaut de texte, arabe 320 x2',
      );
    });
  });
}
