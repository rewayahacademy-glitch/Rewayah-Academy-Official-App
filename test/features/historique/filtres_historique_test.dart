// Fonctions pures de l'Historique du tuteur (lot E, sous-paquet 2) : statut
// apres la seance, filtres, durees, dates, fuseau, lecture des classes des
// seances, groupement des visites.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/suivi/groupes_seances.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart';
import 'package:rewayah_academy/features/suivi_foyer/vue_suivi_foyer.dart';

import '../../fixtures/tuteur/faux_observation.dart';
import '../../fixtures/tuteur/foyers.dart';
import 'support_historique.dart';

LigneSuivi _ligne(EtatPresence? etat, {StatutSeance? statut}) {
  final Seance s = seanceFictive(
    id: 's',
    ilYAJours: 2,
    statut: statut ?? StatutSeance.terminee,
  );
  return seancesPassees(
    seances: <Seance>[s],
    presences: etat == null
        ? null
        : <PresenceParticipant>[
            presenceFictive(s, etat, arriveeApres: const Duration(minutes: 12)),
          ],
    maintenant: maintenantHistorique,
    eleveId: FoyersFictifs.a1.id,
  ).single;
}

void main() {
  group('statut apres la seance', () {
    test('une coupure, un depart, un calcul non confirme : verification', () {
      for (final EtatPresence e in <EtatPresence>[
        EtatPresence.deconnectee,
        EtatPresence.enReconnexion,
        EtatPresence.sortie,
        EtatPresence.confirmationEnAttente,
        EtatPresence.enAttente,
        EtatPresence.planifiee,
        EtatPresence.enConnexion,
      ]) {
        expect(
          statutDe(_ligne(e)),
          StatutHistorique.verification,
          reason: '$e',
        );
      }
      // Presence illisible : l'inconnu, jamais l'absence (J3).
      expect(statutDe(_ligne(null)), StatutHistorique.verification);
    });

    test('presence, retard avec minutes, absence du serveur', () {
      expect(
        statutDe(_ligne(EtatPresence.presente)),
        StatutHistorique.presence,
      );
      expect(
        statutDe(_ligne(EtatPresence.reconnectee)),
        StatutHistorique.presence,
      );
      expect(
        libelleStatut(_ligne(EtatPresence.enRetard)),
        t.historique.etat.retard(minutes: 12),
      );
      expect(statutDe(_ligne(EtatPresence.absente)), StatutHistorique.absence);
      expect(StatutHistorique.absence.libelle, t.presence.absente);
      expect(StatutHistorique.verification.ton, TonEtat.neutre);
    });

    test('le sort du cours prime sur l etat de l eleve', () {
      expect(
        statutDe(_ligne(EtatPresence.absente, statut: StatutSeance.annulee)),
        StatutHistorique.annule,
      );
      expect(
        statutDe(
          _ligne(EtatPresence.absente, statut: StatutSeance.enseignantAbsent),
        ),
        StatutHistorique.nonTenu,
      );
      // Non tenu : jamais le ton d'alerte (ce n'est pas le fait de l'eleve).
      expect(StatutHistorique.nonTenu.ton, isNot(TonEtat.alerte));
    });
  });

  group('seances passees et filtres', () {
    test(
      'ni seance a venir, ni seance d un autre eleve, ordre decroissant',
      () {
        final List<LigneSuivi> lignes = seancesPassees(
          seances: seancesFoyerA,
          presences: presencesFoyerA,
          maintenant: maintenantHistorique,
          eleveId: FoyersFictifs.a1.id,
        );
        expect(lignes.map((LigneSuivi l) => l.seance.id), <String>[
          's-presente',
          's-retard',
          's-coupure',
          's-annulee',
          's-non-tenue',
        ]);
        expect(
          seancesPasseesParEleve(seancesFoyerA, maintenantHistorique),
          <String, int>{FoyersFictifs.a1.id: 5, FoyersFictifs.a2.id: 1},
        );
      },
    );

    test('classe, periode et statut se cumulent', () {
      final List<LigneSuivi> lignes = seancesPassees(
        seances: seancesFoyerA,
        presences: presencesFoyerA,
        maintenant: maintenantHistorique,
        eleveId: FoyersFictifs.a1.id,
      );
      List<String> ids(FiltresHistorique<StatutHistorique> f) => filtrerSeances(
        lignes,
        f,
        classeDe: (String id) => id == 's-retard' ? 'c1' : null,
        maintenant: maintenantHistorique,
      ).map((LigneSuivi l) => l.seance.id).toList();

      expect(ids(const FiltresHistorique<StatutHistorique>()).length, 5);
      expect(
        ids(const FiltresHistorique<StatutHistorique>(classeId: 'c1')),
        <String>['s-retard'],
      );
      expect(
        ids(
          const FiltresHistorique<StatutHistorique>(
            periode: PeriodeHistorique.septJours,
          ),
        ),
        <String>['s-presente', 's-retard', 's-coupure'],
      );
      expect(
        ids(
          const FiltresHistorique<StatutHistorique>(
            statut: StatutHistorique.annule,
          ),
        ),
        <String>['s-annulee'],
      );
      expect(
        const FiltresHistorique<StatutHistorique>().avecClasse('c1').actifs,
        isTrue,
      );
    });

    test('periodes en jours civils', () {
      final DateTime m = DateTime(2026, 3, 31, 10);
      expect(PeriodeHistorique.toute.debut(m), isNull);
      expect(PeriodeHistorique.septJours.debut(m), DateTime(2026, 3, 24));
      expect(PeriodeHistorique.trenteJours.debut(m), DateTime(2026, 3, 1));
      expect(PeriodeHistorique.troisMois.debut(m), DateTime(2025, 12, 31));
    });
  });

  group('mises en forme', () {
    test('durees', () {
      expect(dureeLisible(const Duration(seconds: 48)), '48\u00A0s');
      expect(dureeLisible(const Duration(minutes: 2)), '2\u00A0min');
      expect(
        dureeLisible(const Duration(seconds: 102)),
        '1\u00A0min\u00A042\u00A0s',
      );
      expect(dureeLisible(const Duration(hours: 1)), '1\u00A0h');
      expect(dureeLisible(const Duration(minutes: 65)), '1\u00A0h\u00A005');
      expect(dureeLisible(const Duration(seconds: -5)), '0\u00A0s');
    });

    test('dates, plage et decalage', () {
      final DateTime d = DateTime(2026, 9, 23, 18, 5);
      expect(dateCourte(d), '23 sept. 2026');
      expect(dateLongueHistorique(d), 'mercredi 23 septembre 2026');
      expect(plageHoraire(d, d.add(const Duration(hours: 1))), '18:05 - 19:05');
      expect(decalageUtc(d), matches(RegExp(r'^[+-]\d{2}:\d{2}$')));
    });
  });

  group('lectures', () {
    test('classes des seances : une ligne sans classe est ignoree', () {
      expect(
        groupesDepuisLignes(<Map<String, dynamic>>[
          <String, dynamic>{'id': 's1', 'groupe_id': 'g1'},
          <String, dynamic>{'id': 's2', 'groupe_id': null},
          <String, dynamic>{'groupe_id': 'g3'},
        ]),
        <String, String>{'s1': 'g1'},
      );
    });

    test('visites : statut, resume, duree jamais recollee', () {
      final List<ObservationsSeance> groupes = grouperObservations(
        visitesFoyerA(),
      );
      final ObservationsSeance deux = groupes.firstWhere(
        (ObservationsSeance o) => o.seanceId == 's-presente',
      );
      expect(statutObservationDe(deux), StatutObservation.sortieNonEnregistree);
      expect(deux.dureeTotaleConfirmee, isNull);
      expect(
        resumeVisites(deux),
        '${t.historique.observations.visites(n: 2)} · '
        '${t.historique.observations.dureeNonConfirmee}',
      );
      final ObservationsSeance une = groupes.firstWhere(
        (ObservationsSeance o) => o.seanceId == 's-a2',
      );
      expect(statutObservationDe(une), StatutObservation.terminee);
      expect(
        resumeVisites(une),
        '${t.historique.observations.visiteUne} · 48\u00A0s',
      );
      // Aucune ligne incomplete n'est completee.
      expect(
        grouperObservations(<Map<String, dynamic>>[
          ligneVisite()..remove('entered_at'),
        ]),
        isEmpty,
      );
    });
  });
}
