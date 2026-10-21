import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

import '../fixtures/tuteur/faux_seances_famille.dart';
import '../fixtures/tuteur/foyers.dart';

/// Debut de la seance de la table de verite : 17 h UTC le jour fige.
final DateTime _t0 = DateTime.utc(2026, 9, 21, 17);

EtatSeanceFamille _etat(SeanceFamille s, Duration decalage) =>
    etatSeanceFamille(s, maintenantServeurUtc: _t0.add(decalage));

Duration? _restant(SeanceFamille s, Duration decalage) =>
    restantAvant(s, maintenantServeurUtc: _t0.add(decalage));

Seance _ligne({
  required String id,
  required String eleveId,
  required DateTime debut,
  Duration duree = const Duration(minutes: 45),
  StatutSeance? statut = StatutSeance.planifiee,
}) => Seance(
  id: id,
  debut: debut,
  fin: debut.add(duree),
  statut: statut,
  eleveId: eleveId,
  elevePrenom: '',
  eleveIdentifiant: '',
  enseignantId: 'enseignant-x',
  enseignantPrenom: 'Enseignant X',
  enseignantIdentifiant: '',
);

void main() {
  final SeanceFamille planifiee = seanceFictive(debutUtc: _t0);

  group('K2 : table de verite de l etat d une seance', () {
    test('avant la fenetre : a venir, compte a rebours jusqu au debut', () {
      expect(
        _etat(planifiee, const Duration(minutes: -21)),
        EtatSeanceFamille.aVenir,
      );
      expect(
        _restant(planifiee, const Duration(minutes: -21)),
        const Duration(minutes: 21),
      );
    });

    test('a T-20 exactement, la salle est ouverte', () {
      expect(
        _etat(planifiee, const Duration(minutes: -20)),
        EtatSeanceFamille.salleOuverte,
      );
      expect(
        _restant(planifiee, const Duration(minutes: -20)),
        const Duration(minutes: 20),
      );
    });

    test('la fenetre vient de join_opens_at_utc, pas d une duree courante', () {
      // L'horloge rend une ouverture a T-20 mais une « fenetre courante » de
      // 10 min (configuration changee apres materialisation) : c'est
      // l'instant d'ouverture rendu qui fait foi, comme cote serveur.
      final SessionClockVM horloge = SessionClockVM(
        sessionId: 's1',
        debutUtc: _t0,
        finPrevueUtc: _t0.add(const Duration(minutes: 45)),
        joinOpensAtUtc: _t0.subtract(const Duration(minutes: 20)),
        fenetreAcces: const Duration(minutes: 10),
        graceApresFin: const Duration(minutes: 15),
        horlogeUtilisateur: heureRendue('Europe/Paris', 'Paris', '19:00'),
        phase: PhaseSeance.avantFenetre,
        rejoindreOuvert: false,
        calculeeAUtc: instantServeurFige,
      );
      final SeanceFamille avecHorloge = avecHorlogeServeur(
        seanceFictive(debutUtc: _t0, avecHorloge: false),
        horloge,
      );

      expect(
        avecHorloge.fenetre?.joinOpensAtUtc,
        _t0.subtract(const Duration(minutes: 20)),
      );
      expect(
        _etat(avecHorloge, const Duration(minutes: -15)),
        EtatSeanceFamille.salleOuverte,
      );
      expect(avecHorloge.heureFoyer?.heureLocaleRendue, '19:00');
    });

    test('au debut et pendant : en direct, sans compte a rebours', () {
      expect(_etat(planifiee, Duration.zero), EtatSeanceFamille.enDirect);
      expect(
        _etat(planifiee, const Duration(minutes: 30)),
        EtatSeanceFamille.enDirect,
      );
      expect(_restant(planifiee, Duration.zero), isNull);
    });

    test(
      'apres la fin prevue, pendant la grace : prolongee, jamais negatif',
      () {
        expect(
          _etat(planifiee, const Duration(minutes: 50)),
          EtatSeanceFamille.prolongee,
        );
        expect(_restant(planifiee, const Duration(minutes: 50)), isNull);
        expect(
          planifiee.fenetre!.restantA(_t0.add(const Duration(minutes: 50))),
          isNull,
        );
      },
    );

    test(
      'une seance que le serveur dit en cours reste prolongee apres la grace',
      () {
        final SeanceFamille enCours = seanceFictive(
          debutUtc: _t0,
          statut: StatutSeance.enCours,
        );

        expect(
          _etat(enCours, const Duration(minutes: 90)),
          EtatSeanceFamille.prolongee,
        );
        // Ouverte par l'enseignant avant la fenetre : la salle est ouverte.
        expect(
          _etat(enCours, const Duration(minutes: -30)),
          EtatSeanceFamille.salleOuverte,
        );
      },
    );

    test('fin et grace passees sans statut clos : terminee', () {
      expect(
        _etat(planifiee, const Duration(minutes: 61)),
        EtatSeanceFamille.terminee,
      );
    });

    test('le serveur dit terminee : terminee, quelle que soit l heure', () {
      final SeanceFamille close = seanceFictive(
        debutUtc: _t0,
        statut: StatutSeance.terminee,
      );

      expect(
        _etat(close, const Duration(minutes: 10)),
        EtatSeanceFamille.terminee,
      );
    });

    test('annulee et annulee tardive priment sur l horloge', () {
      final SeanceFamille annulee = seanceFictive(
        debutUtc: _t0,
        statut: StatutSeance.annulee,
      );
      final SeanceFamille tardive = seanceFictive(
        debutUtc: _t0,
        statut: StatutSeance.annuleeTard,
      );

      expect(
        _etat(annulee, const Duration(minutes: -5)),
        EtatSeanceFamille.annulee,
      );
      expect(_restant(annulee, const Duration(minutes: -5)), isNull);
      expect(
        _etat(tardive, const Duration(minutes: 10)),
        EtatSeanceFamille.annuleeTardive,
      );
    });

    test('non tenue : enseignant absent, eleve absent, incident technique', () {
      for (final StatutSeance statut in <StatutSeance>[
        StatutSeance.enseignantAbsent,
        StatutSeance.eleveAbsent,
        StatutSeance.incidentTechnique,
      ]) {
        expect(
          _etat(seanceFictive(debutUtc: _t0, statut: statut), Duration.zero),
          EtatSeanceFamille.nonTenue,
          reason: statut.name,
        );
      }
    });

    test('horloge absente : horaire incertain, aucun etat d ouverture', () {
      // Ni instant serveur, ni fenetre : jamais « Salle ouverte » ni « En
      // direct », jamais de compte a rebours.
      expect(
        etatSeanceFamille(planifiee, maintenantServeurUtc: null),
        EtatSeanceFamille.horaireIncertain,
      );
      expect(restantAvant(planifiee, maintenantServeurUtc: null), isNull);

      final SeanceFamille sansFenetre = seanceFictive(
        debutUtc: _t0,
        avecHorloge: false,
      );
      expect(
        _etat(sansFenetre, Duration.zero),
        EtatSeanceFamille.horaireIncertain,
      );
      expect(_restant(sansFenetre, const Duration(minutes: -30)), isNull);
    });

    test('sans horloge, un statut annule ou clos tranche encore', () {
      expect(
        etatSeanceFamille(
          seanceFictive(debutUtc: _t0, statut: StatutSeance.annulee),
          maintenantServeurUtc: null,
        ),
        EtatSeanceFamille.annulee,
      );
      expect(
        etatSeanceFamille(
          seanceFictive(debutUtc: _t0, statut: StatutSeance.terminee),
          maintenantServeurUtc: null,
        ),
        EtatSeanceFamille.terminee,
      );
    });

    test('reportee n est jamais produit, et aucun restant n est negatif', () {
      final List<StatutSeance?> statuts = <StatutSeance?>[
        ...StatutSeance.values,
        null,
      ];
      for (final StatutSeance? statut in statuts) {
        final SeanceFamille s = seanceFictive(debutUtc: _t0, statut: statut);
        for (int minutes = -120; minutes <= 180; minutes += 5) {
          final Duration decalage = Duration(minutes: minutes);
          expect(_etat(s, decalage), isNot(EtatSeanceFamille.reportee));
          final Duration? reste = _restant(s, decalage);
          expect(reste == null || !reste.isNegative, isTrue);
        }
      }
    });

    test('changement d heure : l arithmetique reste en UTC', () {
      // Nuit du 24 au 25 octobre 2026 : Paris passe de UTC+2 a UTC+1. Une
      // seance le 25 a 9 h UTC se lit 10:00 a Paris et 09:00 a Abidjan, deux
      // heures RENDUES par le serveur. Vu le 24 a 21 h UTC (23:00 a Paris),
      // l'horloge murale de Paris dirait 11 h d'attente ; le temps reel est de
      // 12 h, et c'est lui qu'on affiche.
      final DateTime debut = DateTime.utc(2026, 10, 25, 9);
      final SeanceFamille apresBascule = seanceFictive(
        debutUtc: debut,
        heureFoyer: heureRendue(
          'Europe/Paris',
          'Paris',
          '10:00',
          date: 'Dimanche 25 octobre',
        ),
        heureGroupe: heureRendue(
          'Africa/Abidjan',
          'Abidjan',
          '09:00',
          date: 'Dimanche 25 octobre',
        ),
      );
      final DateTime veille = DateTime.utc(2026, 10, 24, 21);

      expect(
        restantAvant(apresBascule, maintenantServeurUtc: veille),
        const Duration(hours: 12),
      );
      expect(apresBascule.heureFoyer?.heureLocaleRendue, '10:00');
      expect(apresBascule.heureGroupe?.heureLocaleRendue, '09:00');
      expect(apresBascule.dureePrevue, const Duration(minutes: 45));
      expect(
        etatSeanceFamille(apresBascule, maintenantServeurUtc: veille),
        EtatSeanceFamille.aVenir,
      );
    });
  });

  group('K2 : choix de la prochaine et de la derniere seance', () {
    final String a1 = FoyersFictifs.a1.id;
    final String a2 = FoyersFictifs.a2.id;
    final List<SeanceFamille> seances = <SeanceFamille>[
      seanceFictive(
        seanceId: 'hier',
        eleveId: a1,
        debutUtc: _t0.subtract(const Duration(days: 1)),
        statut: StatutSeance.terminee,
      ),
      seanceFictive(
        seanceId: 'aujourdhui-annulee',
        eleveId: a1,
        debutUtc: _t0,
        statut: StatutSeance.annulee,
      ),
      seanceFictive(
        seanceId: 'semaine-prochaine',
        eleveId: a1,
        debutUtc: _t0.add(const Duration(days: 7)),
      ),
      seanceFictive(seanceId: 'autre-eleve', eleveId: a2, debutUtc: _t0),
    ];

    test('une annulation a venir reste la prochaine seance', () {
      expect(
        prochaineParmi(
          seances,
          eleveId: a1,
          referenceUtc: instantServeurFige,
        )?.seanceId,
        'aujourdhui-annulee',
      );
    });

    test('une fois son creneau passe, la suivante prend la place', () {
      expect(
        prochaineParmi(
          seances,
          eleveId: a1,
          referenceUtc: _t0.add(const Duration(hours: 2)),
        )?.seanceId,
        'semaine-prochaine',
      );
    });

    test('une seance declaree en cours l emporte sur l heure', () {
      final List<SeanceFamille> avecDirect = <SeanceFamille>[
        ...seances,
        seanceFictive(
          seanceId: 'debordement',
          eleveId: a1,
          debutUtc: _t0.subtract(const Duration(hours: 3)),
          statut: StatutSeance.enCours,
        ),
      ];

      expect(
        prochaineParmi(
          avecDirect,
          eleveId: a1,
          referenceUtc: instantServeurFige,
        )?.seanceId,
        'debordement',
      );
    });

    test('la derniere seance est la plus recente des seances passees', () {
      expect(
        derniereParmi(
          seances,
          eleveId: a1,
          referenceUtc: instantServeurFige,
        )?.seanceId,
        'hier',
      );
      expect(
        derniereParmi(
          seances,
          eleveId: a1,
          referenceUtc: _t0.add(const Duration(hours: 2)),
        )?.seanceId,
        'aujourdhui-annulee',
      );
    });

    test('jamais la seance d un autre eleve', () {
      expect(
        prochaineParmi(
          seances,
          eleveId: a2,
          referenceUtc: instantServeurFige,
        )?.seanceId,
        'autre-eleve',
      );
      expect(
        prochaineParmi(
          seances,
          eleveId: FoyersFictifs.b1.id,
          referenceUtc: instantServeurFige,
        ),
        isNull,
      );
    });
  });

  group('K2 : l adaptateur sur mes_seances_v', () {
    final String a1 = FoyersFictifs.a1.id;
    final List<Seance> lignes = <Seance>[
      _ligne(
        id: 's-passee',
        eleveId: a1,
        debut: _t0.subtract(const Duration(days: 2)),
        statut: StatutSeance.terminee,
      ),
      _ligne(id: 's-prochaine', eleveId: a1, debut: _t0),
      _ligne(id: 's-prochaine', eleveId: FoyersFictifs.a2.id, debut: _t0),
    ];

    SeancesFamilleDepuisPlanning sansHorloge() => SeancesFamilleDepuisPlanning(
      lireSeances: () async => lignes,
      horlogeAppareilUtc: () => instantServeurFige,
    );

    test(
      'sans horloge serveur : capacite indisponible et horaire incertain',
      () async {
        final SeancesFamilleDepuisPlanning port = sansHorloge();

        await expectLater(
          port.maintenantServeurUtc(),
          throwsA(
            isA<CapaciteIndisponible>().having(
              (CapaciteIndisponible c) => c.dependance,
              'dependance',
              'DB-TRV-07',
            ),
          ),
        );
        final SeanceFamille? prochaine = await port.prochaine(a1);
        expect(prochaine?.seanceId, 's-prochaine');
        expect(prochaine?.fenetre, isNull);
        expect(prochaine?.heureFoyer, isNull);
        expect(prochaine?.debutUtc.isUtc, isTrue);
        expect(
          etatSeanceFamille(
            prochaine!,
            maintenantServeurUtc: instantServeurFige,
          ),
          EtatSeanceFamille.horaireIncertain,
        );
      },
    );

    test('avec horloge serveur : fenetre et heures rendues', () async {
      final SeancesFamilleDepuisPlanning port = SeancesFamilleDepuisPlanning(
        lireSeances: () async => lignes,
        horlogeAppareilUtc: () => DateTime.utc(2000),
        lireMaintenantServeur: () async => instantServeurFige,
        lireHorloge: (String seanceId) async => SessionClockVM.depuisFenetre(
          fenetre: FenetreSeance(
            debutUtc: _t0,
            finPrevueUtc: _t0.add(const Duration(minutes: 45)),
            fenetreAcces: const Duration(minutes: 20),
            graceApresFin: const Duration(minutes: 15),
          ),
          maintenantServeurUtc: instantServeurFige,
          sessionId: seanceId,
          horlogeUtilisateur: heureRendue('Europe/Paris', 'Paris', '19:00'),
        ),
      );

      final SeanceFamille? prochaine = await port.prochaine(a1);
      expect(
        prochaine?.fenetre?.joinOpensAtUtc,
        _t0.subtract(const Duration(minutes: 20)),
      );
      expect(prochaine?.heureFoyer?.libelleVille, 'Paris');
      expect(
        etatSeanceFamille(
          prochaine!,
          maintenantServeurUtc: await port.maintenantServeurUtc(),
        ),
        EtatSeanceFamille.aVenir,
      );
    });

    test(
      'la derniere seance et l historique filtre, le plus recent d abord',
      () async {
        final SeancesFamilleDepuisPlanning port = sansHorloge();

        expect((await port.derniere(a1))?.seanceId, 's-passee');
        final List<SeanceFamille> historique = await port.historique(
          eleveId: a1,
          periode: DateTimeRange(
            start: _t0.subtract(const Duration(days: 3)),
            end: _t0,
          ),
        );
        expect(historique.map((SeanceFamille s) => s.seanceId), <String>[
          's-prochaine',
          's-passee',
        ]);
      },
    );

    test(
      'deux enfants dans la meme seance se departagent par eleveId',
      () async {
        final SeancesFamilleDepuisPlanning port = sansHorloge();

        expect(
          (await port.seance(
            's-prochaine',
            eleveId: FoyersFictifs.a2.id,
          ))?.eleveId,
          FoyersFictifs.a2.id,
        );
        expect(await port.seance('inconnue'), isNull);
      },
    );

    test('le planning date est une capacite indisponible', () async {
      await expectLater(
        sansHorloge().planning(
          groupeId: 'g1',
          eleveId: a1,
          periode: DateTimeRange(
            start: _t0,
            end: _t0.add(const Duration(days: 7)),
          ),
        ),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible c) => c.dependance,
            'dependance',
            'DB-CRS-03',
          ),
        ),
      );
    });

    test('suivre emet la seance, ou dit qu elle est introuvable', () async {
      final SeancesFamilleDepuisPlanning port = sansHorloge();

      expect(
        (await port.suivre('s-prochaine', eleveId: a1).first).seanceId,
        's-prochaine',
      );
      await expectLater(
        port.suivre('inconnue').first,
        throwsA(isA<SeanceIntrouvable>()),
      );
    });
  });
}
