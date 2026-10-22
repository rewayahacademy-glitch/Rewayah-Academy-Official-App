// CAND-01 : le parcours (etapes, reponses, brouillon), sans widget.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/creneaux_declares.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/features/candidature/controleur_parcours.dart';
import 'package:rewayah_academy/features/candidature/modele_questions.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';

Questionnaire _q({int versionBrouillon = 0, Map<String, Object?>? reponses}) =>
    Questionnaire.depuisJson(
      questionnaireJsonDeTest(
        versionBrouillon: versionBrouillon,
        dernieresReponses: reponses,
      ),
    );

ParcoursControleur _c({
  FauxMaCandidature? port,
  Map<String, Object?> reponses = const <String, Object?>{},
  Set<String> cartes = const <String>{},
  int versionBrouillon = 0,
}) => ParcoursControleur(
  questionnaire: _q(versionBrouillon: versionBrouillon),
  port: port,
  reponses: reponses,
  cartesADemander: cartes,
);

List<String> _codes(List<EtapeParcours> etapes) => <String>[
  for (final EtapeParcours e in etapes)
    switch (e) {
      EtapePresentation(:final int rang) => 'presentation$rang',
      EtapeChamp(:final ChampQuestionnaire champ) => champ.code,
      EtapeRecapitulatif() => 'recapitulatif',
    },
];

void main() {
  group('planifierParcours', () {
    test('trois presentations, une etape par champ, le recapitulatif', () {
      final List<EtapeParcours> etapes = planifierParcours(_q());
      expect(etapes.length, 3 + 16 + 1);
      expect(_codes(etapes).take(3), <String>[
        'presentation1',
        'presentation2',
        'presentation3',
      ]);
      expect(_codes(etapes).last, 'recapitulatif');
    });

    test('le fuseau se confirme avant la grille des plages', () {
      final List<String> codes = _codes(planifierParcours(_q()));
      expect(
        codes.indexOf('fuseauIana'),
        codes.indexOf('disponibilitesDeclarees') - 1,
      );
      expect(codes.where((String c) => c == 'fuseauIana').length, 1);
    });

    test('l ordre des champs est celui du serveur', () {
      final List<String> codes = _codes(planifierParcours(_q()))
          .where(
            (String c) => !c.startsWith('presentation') && c != 'recapitulatif',
          )
          .toList();
      expect(codes, <String>[
        'langueMaternelle',
        'languesExplication',
        'niveauMemorisationDeclare',
        'niveauLectureTajwid',
        'riwayat',
        'ijazaPresentable',
        'experienceDebutants',
        'fuseauIana',
        'disponibilitesDeclarees',
        'heuresParSemaine',
        'debutPossible',
        'publics',
        'paysResidence',
        'paysVersement',
        'compteBancaire',
        'operateurs',
      ]);
    });

    test('sans presentation, le parcours commence aux questions', () {
      expect(
        _codes(planifierParcours(_q(), avecPresentation: false)).first,
        'langueMaternelle',
      );
    });

    test('chaque champ du serveur a une forme connue', () {
      for (final EtapeParcours e in planifierParcours(_q())) {
        if (e is EtapeChamp) {
          expect(modelesQuestions[e.champ.code], isNotNull);
          expect(e.forme, isA<FormeQuestion>());
        }
      }
    });
  });

  group('un parcours neuf', () {
    test('commence a la presentation, sans reponse', () {
      final ParcoursControleur c = _c();
      expect(c.index, 0);
      expect(c.courante, isA<EtapePresentation>());
      expect(c.estPremiere, isTrue);
    });

    test('avancer exige une reponse, sans rien bouger', () {
      final ParcoursControleur c = _c();
      c.avancer();
      c.avancer();
      c.avancer(); // presentations
      expect((c.courante as EtapeChamp).champ.code, 'langueMaternelle');
      expect(c.avancer(), isFalse);
      expect((c.courante as EtapeChamp).champ.code, 'langueMaternelle');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondre('langueMaternelle', 'poular');
      expect(c.manque(c.courante), isNull);
      expect(c.avancer(), isTrue);
    });

    test('reculer revient d une etape, jamais avant la premiere', () {
      final ParcoursControleur c = _c();
      c.reculer();
      expect(c.index, 0);
      c.avancer();
      c.reculer();
      expect(c.index, 0);
    });
  });

  group('les reponses', () {
    test('plusieurs reponses : un maximum, ici dix langues', () {
      final ParcoursControleur c = _c();
      c.repondre('languesExplication', <String>[
        'poular',
        'francais',
        'english',
        'ar',
        'ff',
        'ha',
        'wo',
        'ps',
        'ur',
        'snk',
        'bm',
      ]);
      c.modifier('languesExplication');
      expect(c.manque(c.courante), ManqueReponse.trop);
      c.repondre('languesExplication', <String>['poular']);
      expect(c.manque(c.courante), isNull);
    });

    test('un choix multiple vide ne passe pas', () {
      final ParcoursControleur c = _c();
      c.modifier('riwayat');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondre('riwayat', <String>[]);
      expect(c.manque(c.courante), ManqueReponse.aucune);
      expect(c.reponse('riwayat'), isNull);
    });

    test('les operateurs sont facultatifs', () {
      final ParcoursControleur c = _c();
      c.modifier('operateurs');
      expect(c.manque(c.courante), isNull);
    });

    test('oui ou non : false est une reponse', () {
      final ParcoursControleur c = _c();
      c.modifier('compteBancaire');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondre('compteBancaire', false);
      expect(c.manque(c.courante), isNull);
    });

    test('la grille exige au moins une plage entiere', () {
      final ParcoursControleur c = _c();
      c.repondre('fuseauIana', 'Europe/Paris');
      c.modifier('disponibilitesDeclarees');
      expect(c.manque(c.courante), ManqueReponse.aucunePlage);
      c.declarerPlages(const CreneauxDeclares().bascule(jour: 1, plage: 2));
      expect(c.manque(c.courante), isNull);
      expect(c.reponse('disponibilitesDeclarees'), <String, Object?>{
        'fuseau': 'Europe/Paris',
        'creneaux': <Map<String, Object?>>[
          <String, Object?>{'jour': 1, 'debut': '08:00', 'fin': '12:00'},
        ],
      });
    });

    test('sans fuseau, les plages ne se declarent pas', () {
      final ParcoursControleur c = _c();
      c.declarerPlages(const CreneauxDeclares().bascule(jour: 1, plage: 2));
      expect(c.reponse('disponibilitesDeclarees'), isNull);
    });

    test('changer de fuseau change celui des plages, pas leurs heures', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      c.repondre('fuseauIana', 'Asia/Riyadh');
      final Map<String, Object?> plages =
          c.reponse('disponibilitesDeclarees')! as Map<String, Object?>;
      expect(plages['fuseau'], 'Asia/Riyadh');
      expect((plages['creneaux']! as List<Object?>).first, <String, Object?>{
        'jour': 1,
        'debut': '16:00',
        'fin': '24:00',
      });
    });

    test('changer de pays de versement vide les operateurs', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      expect(c.valeurs('operateurs'), <String>{'orange_money'});
      c.repondre('paysVersement', 'SA');
      expect(c.reponse('operateurs'), isNull);
    });

    test('le pays de versement repart du pays de residence, une fois', () {
      final ParcoursControleur c = _c();
      c.modifier('paysResidence');
      c.repondre('paysResidence', 'GN');
      c.avancer();
      expect(c.reponse('paysVersement'), 'GN');
      // Une reponse deja donnee n'est pas ecrasee.
      c.repondre('paysVersement', 'SA');
      c.modifier('paysResidence');
      c.repondre('paysResidence', 'FR');
      c.avancer();
      expect(c.reponse('paysVersement'), 'SA');
    });

    test('l envoi ne porte que des champs du questionnaire', () {
      final ParcoursControleur c = _c(
        reponses: <String, Object?>{
          ...reponsesCompletesDeTest(),
          'champInconnu': 'x',
        },
      );
      expect(c.reponsesPourEnvoi().containsKey('champInconnu'), isFalse);
      expect(c.reponsesPourEnvoi()['langueMaternelle'], 'poular');
    });
  });

  group('reprendre un brouillon', () {
    test('un brouillon saute la presentation et ouvre la premiere question sans reponse', () {
      final ParcoursControleur c = _c(
        reponses: <String, Object?>{
          'langueMaternelle': 'poular',
          'languesExplication': <String>['poular'],
        },
      );
      expect(c.etapes.first, isA<EtapeChamp>());
      expect(
        (c.courante as EtapeChamp).champ.code,
        'niveauMemorisationDeclare',
      );
    });

    test('un parcours complet ouvre le recapitulatif', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      expect(c.courante, isA<EtapeRecapitulatif>());
    });

    test('un complement demande ouvre la premiere carte nommee', () {
      final ParcoursControleur c = _c(
        reponses: reponsesCompletesDeTest(),
        cartes: <String>{'publics'},
      );
      expect((c.courante as EtapeChamp).champ.code, 'publics');
      expect(c.aCompleter(c.courante), isTrue);
      c.modifier('langueMaternelle');
      expect(c.aCompleter(c.courante), isFalse);
    });

    test('reponsesValables ecarte ce que le serveur refuserait', () {
      final Map<String, Object?> gardees = reponsesValables(
        _q(),
        <String, Object?>{
          'langueMaternelle': 'klingon',
          'languesExplication': <Object?>['poular', 3, 'inconnue'],
          'niveauMemorisationDeclare': 'coran_entier',
          'compteBancaire': 'oui',
          'paysResidence': 'GN',
          'riwayat': <Object?>['hafs'],
          'disponibilitesDeclarees': <String, Object?>{'creneaux': <Object>[]},
        },
      );
      expect(gardees['langueMaternelle'], isNull);
      expect(gardees['languesExplication'], <String>['poular']);
      expect(gardees['niveauMemorisationDeclare'], 'coran_entier');
      expect(gardees['compteBancaire'], isNull);
      expect(gardees['paysResidence'], 'GN');
      expect(gardees['riwayat'], <String>['hafs']);
      expect(gardees['disponibilitesDeclarees'], isNull);
    });
  });

  group('modifier depuis le recapitulatif', () {
    test('continuer ramene au recapitulatif, pas a l etape suivante', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      expect(c.courante, isA<EtapeRecapitulatif>());
      c.modifier('ijazaPresentable');
      expect(c.depuisRecap, isTrue);
      expect((c.courante as EtapeChamp).champ.code, 'ijazaPresentable');
      c.repondre('ijazaPresentable', 'oui');
      c.avancer();
      expect(c.courante, isA<EtapeRecapitulatif>());
      expect(c.depuisRecap, isFalse);
    });

    test('retour depuis une modification ramene au recapitulatif', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      c.modifier('publics');
      c.reculer();
      expect(c.courante, isA<EtapeRecapitulatif>());
    });
  });

  group('le brouillon', () {
    test('chaque etape franchie l enregistre, versions enchainees', () async {
      final FauxMaCandidature port = FauxMaCandidature();
      final ParcoursControleur c = _c(port: port);
      c.avancer();
      c.avancer();
      c.avancer();
      c.repondre('langueMaternelle', 'poular');
      c.avancer();
      c.repondre('languesExplication', <String>['poular']);
      c.avancer();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(port.brouillons.length, 2);
      expect(port.brouillons.first, <String, Object?>{
        'langueMaternelle': 'poular',
      });
      expect(port.versionsBrouillonRecues, <int>[0, 1]);
    });

    test('une presentation franchie n ecrit rien', () async {
      final FauxMaCandidature port = FauxMaCandidature();
      final ParcoursControleur c = _c(port: port);
      c.avancer();
      await Future<void>.delayed(Duration.zero);
      expect(port.brouillons, isEmpty);
    });

    test(
      'un conflit : la reponse recente prend la place, une seule reprise',
      () async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(versionBrouillon: 4),
        );
        // Le brouillon est a la version 4 au serveur ; le parcours croit 2.
        final ParcoursControleur c = ParcoursControleur(
          questionnaire: Questionnaire.depuisJson(
            questionnaireJsonDeTest(versionBrouillon: 2),
          ),
          port: port,
          reponses: const <String, Object?>{},
        );
        c.modifier('langueMaternelle');
        c.repondre('langueMaternelle', 'poular');
        c.avancer();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(port.versionsBrouillonRecues, <int>[2, 4]);
        expect(port.brouillons.length, 1);
        expect(c.brouillonNonGarde, isFalse);
      },
    );

    test('hors ligne : rien ne bloque, rien ne s annonce', () async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurBrouillon = const HorsLigneCandidature();
      final ParcoursControleur c = _c(port: port);
      c.modifier('langueMaternelle');
      c.repondre('langueMaternelle', 'poular');
      expect(c.avancer(), isTrue);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.brouillonNonGarde, isFalse);
      expect(c.reponse('langueMaternelle'), 'poular');
    });

    test('une autre erreur se dit, les reponses restent', () async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurBrouillon = const ReponsesInvalides(<String>['riwayat']);
      final ParcoursControleur c = _c(port: port);
      c.modifier('langueMaternelle');
      c.repondre('langueMaternelle', 'poular');
      c.avancer();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.brouillonNonGarde, isTrue);
      expect(c.reponse('langueMaternelle'), 'poular');
    });
  });
}
