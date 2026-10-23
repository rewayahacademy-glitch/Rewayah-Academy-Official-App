// CAND-01 : le parcours (etapes, reponses, disponibilites, brouillon), sans
// widget.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/features/candidature/controleur_parcours.dart';
import 'package:rewayah_academy/features/candidature/modele_questions.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';

Questionnaire _q({
  int versionBrouillon = 0,
  Map<String, Object?>? reponses,
  bool moyensConnus = true,
}) => Questionnaire.depuisJson(
  questionnaireJsonDeTest(
    versionBrouillon: versionBrouillon,
    dernieresReponses: reponses,
    moyensConnus: moyensConnus,
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
      EtapeDisponibilites(:final SousEtapeDisponibilites sous) =>
        'dispo.${sous.name}',
      EtapeRecapitulatif() => 'recapitulatif',
    },
];

/// Le code de l'etape courante.
String _ici(ParcoursControleur c) => _codes(<EtapeParcours>[c.courante]).single;

void main() {
  group('planifierParcours', () {
    test('trois presentations, une etape par champ, le recapitulatif', () {
      final List<EtapeParcours> etapes = planifierParcours(_q());
      // 16 champs poses seuls, trois ecrans de disponibilites (jours, heures,
      // semaine), 3 presentations et le recapitulatif.
      expect(etapes.length, 3 + 16 + 3 + 1);
      expect(_codes(etapes).take(3), <String>[
        'presentation1',
        'presentation2',
        'presentation3',
      ]);
      expect(_codes(etapes).last, 'recapitulatif');
    });

    test('le public puis le fuseau se posent avant les disponibilites', () {
      final List<String> codes = _codes(planifierParcours(_q()));
      final int jours = codes.indexOf('dispo.jours');
      expect(codes[jours - 1], 'fuseauIana');
      expect(codes[jours - 2], 'publics');
      expect(codes.where((String c) => c == 'fuseauIana').length, 1);
      expect(codes.where((String c) => c == 'publics').length, 1);
    });

    test('l ordre du serveur, les disponibilites en ecrans', () {
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
        'publics',
        'fuseauIana',
        'dispo.jours',
        'dispo.heures',
        'dispo.semaine',
        'classesSouhaitees',
        'debutPossible',
        'paysResidence',
        'paysVersement',
        'compteBancaire',
        'operateurs',
        'moyensAccessibles',
      ]);
    });

    test('« memes heures ? » demande deux jours, le jour par jour un « non »', () {
      List<String> dispo({required int jours, bool? memes}) =>
          _codes(planifierParcours(_q(), nombreJours: jours, memesHeures: memes))
              .where((String c) => c.startsWith('dispo.'))
              .toList();
      expect(dispo(jours: 1), <String>[
        'dispo.jours',
        'dispo.heures',
        'dispo.semaine',
      ]);
      expect(dispo(jours: 3), <String>[
        'dispo.jours',
        'dispo.heures',
        'dispo.memes',
        'dispo.semaine',
      ]);
      expect(dispo(jours: 3, memes: true), dispo(jours: 3));
      expect(dispo(jours: 3, memes: false), <String>[
        'dispo.jours',
        'dispo.heures',
        'dispo.memes',
        'dispo.parJour',
        'dispo.semaine',
      ]);
      // Un seul jour : jamais de « non » a une question qu'on ne pose pas.
      expect(dispo(jours: 1, memes: false), dispo(jours: 1));
    });

    test('sans presentation, le parcours commence aux questions', () {
      expect(
        _codes(planifierParcours(_q(), avecPresentation: false)).first,
        'langueMaternelle',
      );
    });

    test('les moyens de paiement connus sans option ne se posent pas', () {
      final List<String> codes = _codes(
        planifierParcours(_q(moyensConnus: false)),
      );
      expect(codes, isNot(contains('moyensAccessibles')));
      expect(codes, contains('operateurs'));
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
      c.modifier('languesExplication');
      expect((c.courante as EtapeChamp).champ.code, 'languesExplication');
      expect(c.avancer(), isFalse);
      expect((c.courante as EtapeChamp).champ.code, 'languesExplication');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondre('languesExplication', <String>['poular']);
      expect(c.manque(c.courante), isNull);
      expect(c.avancer(), isTrue);
    });

    test('la langue maternelle est facultative : on continue sans elle', () {
      final ParcoursControleur c = _c();
      c.avancer();
      c.avancer();
      c.avancer();
      expect((c.courante as EtapeChamp).champ.code, 'langueMaternelle');
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
    test('les langues d explication n ont aucun plafond', () {
      final ParcoursControleur c = _c();
      final List<String> toutes = <String>[
        for (final OptionQuestionnaire o
            in c.questionnaire.champ('languesExplication')!.options)
          o.code,
      ];
      expect(toutes.length, greaterThan(10));
      c.repondre('languesExplication', toutes);
      c.modifier('languesExplication');
      expect(c.manque(c.courante), isNull);
    });

    test('l arabe n est pas une langue d explication', () {
      final ParcoursControleur c = _c();
      expect(
        c.questionnaire
            .champ('languesExplication')!
            .options
            .map((OptionQuestionnaire o) => o.code),
        isNot(contains('ar')),
      );
      expect(
        c.questionnaire
            .champ('langueMaternelle')!
            .options
            .map((OptionQuestionnaire o) => o.code),
        contains('ar'),
      );
    });

    test('un choix multiple vide ne passe pas', () {
      final ParcoursControleur c = _c();
      c.modifier('riwayat');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondre('riwayat', <String>[]);
      expect(c.manque(c.courante), ManqueReponse.aucune);
      expect(c.reponse('riwayat'), isNull);
    });

    test('les operateurs et les moyens de paiement sont facultatifs', () {
      final ParcoursControleur c = _c();
      c.modifier('operateurs');
      expect(c.manque(c.courante), isNull);
      c.modifier('moyensAccessibles');
      expect(c.manque(c.courante), isNull);
    });

    test('oui ou non : false est une reponse', () {
      final ParcoursControleur c = _c();
      c.modifier('compteBancaire');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondre('compteBancaire', false);
      expect(c.manque(c.courante), isNull);
    });

    test('le nombre de Classes est une reponse exigee', () {
      final ParcoursControleur c = _c();
      c.modifier('classesSouhaitees');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondre('classesSouhaitees', '2');
      expect(c.manque(c.courante), isNull);
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

  group('les disponibilites, heure par heure', () {
    ParcoursControleur c0() {
      final ParcoursControleur c = _c();
      c.repondre('publics', <String>['6_9']);
      return c;
    }

    test('aucun jour : on ne passe pas, puis on passe avec un jour', () {
      final ParcoursControleur c = c0()..modifier('disponibilitesDeclarees');
      expect(_ici(c), 'dispo.jours');
      expect(c.manque(c.courante), ManqueReponse.aucunJour);
      c.basculerJour(1);
      expect(c.manque(c.courante), isNull);
      expect(c.jours, <int>[1]);
    });

    test('un jour sans heure de debut : on ne passe pas', () {
      final ParcoursControleur c = c0()..modifier('disponibilitesDeclarees');
      c
        ..basculerJour(1)
        ..avancer();
      expect(_ici(c), 'dispo.heures');
      expect(c.manque(c.courante), ManqueReponse.aucuneHeure);
      c.basculerHeure(1, 18);
      expect(c.manque(c.courante), isNull);
    });

    test('des enfants : les heures envoyees sont les heures de debut', () {
      final ParcoursControleur c = c0()
        ..basculerJour(1)
        ..basculerHeure(1, 18)
        ..basculerHeure(1, 19)
        ..basculerHeure(1, 20);
      expect(c.reponse('disponibilitesDeclarees'), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '21:00'},
      ]);
    });

    test('des adultes : l heure suivante est declaree aussi (90 minutes)', () {
      final ParcoursControleur c = _c();
      c.repondre('publics', <String>['adultes']);
      c
        ..basculerJour(1)
        ..basculerHeure(1, 18);
      expect(c.reponse('disponibilitesDeclarees'), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
      ]);
    });

    test('changer de public recalcule les heures declarees', () {
      final ParcoursControleur c = c0()
        ..basculerJour(1)
        ..basculerHeure(1, 18);
      expect(c.reponse('disponibilitesDeclarees'), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '19:00'},
      ]);
      c.repondre('publics', <String>['6_9', 'adultes']);
      expect(c.reponse('disponibilitesDeclarees'), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
      ]);
      c.repondre('publics', <String>['14_17']);
      expect(c.reponse('disponibilitesDeclarees'), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '19:00'},
      ]);
    });

    test('une heure retiree retire sa plage, plus d heure : plus de reponse', () {
      final ParcoursControleur c = c0()
        ..basculerJour(1)
        ..basculerHeure(1, 18)
        ..basculerHeure(1, 18);
      expect(c.reponse('disponibilitesDeclarees'), isNull);
    });

    test('les heures du premier jour valent pour tous, tant qu on ne dit pas non',
        () {
      final ParcoursControleur c = c0()
        ..choisirJours(<int>{1, 3, 5})
        ..basculerHeure(1, 18)
        ..basculerHeure(1, 19);
      expect(c.debutsDuJour(3), <int>[18, 19]);
      expect(c.debutsDuJour(5), <int>[18, 19]);
      expect(c.reponse('disponibilitesDeclarees'), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
        <String, Object?>{'jour': 3, 'debut': '18:00', 'fin': '20:00'},
        <String, Object?>{'jour': 5, 'debut': '18:00', 'fin': '20:00'},
      ]);
    });

    test('un jour ajoute reprend les heures du premier jour', () {
      final ParcoursControleur c = c0()
        ..basculerJour(1)
        ..basculerHeure(1, 18)
        ..basculerJour(4);
      expect(c.debutsDuJour(4), <int>[18]);
      c.basculerJour(4);
      expect(c.jours, <int>[1]);
      expect(c.debutsDuJour(4), isEmpty);
    });

    test('« non » : chaque jour se regle seul, jusqu au reglage de chacun', () {
      final ParcoursControleur c = c0()
        ..choisirJours(<int>{1, 3})
        ..basculerHeure(1, 18)
        ..repondreMemes(oui: false);
      expect(c.memesHeures, isFalse);
      c.basculerHeure(3, 20);
      expect(c.debutsDuJour(1), <int>[18]);
      expect(c.debutsDuJour(3), <int>[18, 20]);
      // Le premier jour ne tire plus les autres.
      c.basculerHeure(1, 9);
      expect(c.debutsDuJour(3), <int>[18, 20]);
      c.basculerHeure(3, 18);
      c.basculerHeure(3, 20);
      expect(c.jourSansHeure, 3);
      expect(c.manque(const EtapeDisponibilites(
        ChampQuestionnaire(
          code: 'disponibilitesDeclarees',
          carte: 'disponibilites',
          type: TypeChamp.creneaux,
          requis: true,
        ),
        SousEtapeDisponibilites.parJour,
      )), ManqueReponse.jourSansHeure);
    });

    test('« oui » recopie les heures du premier jour partout', () {
      final ParcoursControleur c = c0()
        ..choisirJours(<int>{1, 3})
        ..basculerHeure(1, 18)
        ..repondreMemes(oui: false);
      c.basculerHeure(3, 20);
      c.repondreMemes(oui: true);
      expect(c.debutsDuJour(3), <int>[18]);
    });

    test('moins de deux jours : la question « memes heures ? » s efface', () {
      final ParcoursControleur c = c0()
        ..choisirJours(<int>{1, 3})
        ..repondreMemes(oui: false);
      expect(c.memesHeures, isFalse);
      c.basculerJour(3);
      expect(c.memesHeures, isNull);
      expect(_codes(c.etapes), isNot(contains('dispo.memes')));
    });

    test('« memes heures ? » sans reponse ne passe pas', () {
      final ParcoursControleur c = c0()
        ..modifier('disponibilitesDeclarees')
        ..choisirJours(<int>{1, 3})
        ..basculerHeure(1, 18)
        ..avancer()
        ..avancer();
      expect(_ici(c), 'dispo.memes');
      expect(c.manque(c.courante), ManqueReponse.aucune);
      c.repondreMemes(oui: true);
      expect(c.manque(c.courante), isNull);
    });

    test('un raccourci remplace les jours choisis, en gardant leurs heures', () {
      final ParcoursControleur c = c0()
        ..choisirJours(<int>{1, 3, 5})
        ..basculerHeure(1, 18);
      c.choisirJours(<int>{3, 5, 6});
      expect(c.jours, <int>[3, 5, 6]);
      expect(c.debutsDuJour(3), <int>[18]);
      expect(c.debutsDuJour(6), <int>[18]);
      expect(c.debutsDuJour(1), isEmpty);
    });

    test('un brouillon d enfants rend les heures de debut', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      expect(c.jours, <int>[1, 3, 5]);
      expect(c.debutsDuJour(1), <int>[18, 19]);
      expect(c.memesHeures, isTrue);
    });

    test('un brouillon dont les jours different : « non » deja repondu', () {
      final ParcoursControleur c = _c(
        reponses: <String, Object?>{
          ...reponsesCompletesDeTest(),
          'disponibilitesDeclarees': <Map<String, Object?>>[
            <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
            <String, Object?>{'jour': 3, 'debut': '20:00', 'fin': '21:00'},
          ],
        },
      );
      expect(c.memesHeures, isFalse);
      expect(_codes(c.etapes), contains('dispo.parJour'));
      expect(c.debutsDuJour(3), <int>[20]);
    });

    test('un brouillon d adultes ne rend que les debuts qui tiennent 90 minutes',
        () {
      final ParcoursControleur c = _c(
        reponses: <String, Object?>{
          ...reponsesCompletesDeTest(),
          'publics': <String>['adultes'],
          'disponibilitesDeclarees': <Map<String, Object?>>[
            <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
            <String, Object?>{'jour': 3, 'debut': '18:00', 'fin': '19:00'},
          ],
        },
      );
      // Mercredi 18 h seul ne tient pas un cours d'adultes : aucun debut.
      expect(c.jours, <int>[1]);
      expect(c.debutsDuJour(1), <int>[18]);
    });

    test('modifier les disponibilites parcourt leurs ecrans puis revient au '
        'recapitulatif', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      expect(c.courante, isA<EtapeRecapitulatif>());
      c.modifier('disponibilitesDeclarees');
      expect(_ici(c), 'dispo.jours');
      expect(c.depuisRecap, isTrue);
      c.avancer();
      expect(_ici(c), 'dispo.heures');
      expect(c.depuisRecap, isTrue);
      c.avancer();
      expect(_ici(c), 'dispo.memes');
      c.avancer();
      expect(_ici(c), 'dispo.semaine');
      c.avancer();
      expect(c.courante, isA<EtapeRecapitulatif>());
      expect(c.depuisRecap, isFalse);
    });

    test('reculer depuis la modification des disponibilites remonte d un ecran, '
        'puis revient au recapitulatif', () {
      final ParcoursControleur c = _c(reponses: reponsesCompletesDeTest());
      c.modifier('disponibilitesDeclarees');
      c.avancer();
      expect(_ici(c), 'dispo.heures');
      c.reculer();
      expect(_ici(c), 'dispo.jours');
      c.reculer();
      expect(c.courante, isA<EtapeRecapitulatif>());
    });

    test('chaque ecran des disponibilites enregistre le brouillon', () async {
      final FauxMaCandidature port = FauxMaCandidature();
      final ParcoursControleur c = _c(port: port);
      c.repondre('publics', <String>['6_9']);
      c.modifier('disponibilitesDeclarees');
      c
        ..basculerJour(1)
        ..avancer()
        ..basculerHeure(1, 18)
        ..avancer();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(port.brouillons.length, 2);
      expect(port.brouillons.last['disponibilitesDeclarees'], <Object?>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '19:00'},
      ]);
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

    test('un complement sur les disponibilites ouvre leurs ecrans', () {
      final ParcoursControleur c = _c(
        reponses: reponsesCompletesDeTest(),
        cartes: <String>{'disponibilites'},
      );
      // La carte « disponibilites » porte aussi le fuseau, pose avant les jours.
      expect(_ici(c), 'fuseauIana');
      expect(c.aCompleter(c.courante), isTrue);
      c.avancer();
      expect(_ici(c), 'dispo.jours');
      expect(c.aCompleter(c.courante), isTrue);
    });

    test('reponsesValables ecarte ce que le serveur refuserait', () {
      final Map<String, Object?> gardees = reponsesValables(
        _q(),
        <String, Object?>{
          'langueMaternelle': 'klingon',
          'languesExplication': <Object?>['poular', 3, 'inconnue', 'ar'],
          'niveauMemorisationDeclare': 'coran_entier',
          'ijazaPresentable': 'peut_etre',
          'compteBancaire': 'oui',
          'paysResidence': 'GN',
          'riwayat': <Object?>['hafs'],
          'classesSouhaitees': '9',
          'publics': <Object?>['adultes', 'enfant'],
          'disponibilitesDeclarees': <Object?>[],
        },
      );
      expect(gardees['langueMaternelle'], isNull);
      expect(gardees['languesExplication'], <String>['poular']);
      expect(gardees['niveauMemorisationDeclare'], 'coran_entier');
      expect(gardees['ijazaPresentable'], isNull);
      expect(gardees['compteBancaire'], isNull);
      expect(gardees['paysResidence'], 'GN');
      expect(gardees['riwayat'], <String>['hafs']);
      expect(gardees['classesSouhaitees'], isNull);
      expect(gardees['publics'], <String>['adultes']);
      expect(gardees['disponibilitesDeclarees'], isNull);
    });

    test('reponsesValables ecarte l ancienne forme des disponibilites', () {
      final Map<String, Object?> gardees = reponsesValables(
        _q(),
        <String, Object?>{
          'disponibilitesDeclarees': <String, Object?>{
            'fuseau': 'Africa/Conakry',
            'creneaux': <Map<String, Object?>>[
              <String, Object?>{'jour': 1, 'debut': '08:30', 'fin': '12:00'},
            ],
          },
        },
      );
      expect(gardees['disponibilitesDeclarees'], isNull);
    });

    test('reponsesValables garde des plages bien formees', () {
      final Map<String, Object?> gardees = reponsesValables(
        _q(),
        <String, Object?>{
          'disponibilitesDeclarees': <Map<String, Object?>>[
            <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '24:00'},
          ],
        },
      );
      expect(gardees['disponibilitesDeclarees'], isNotNull);
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
