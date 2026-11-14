// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : la lecture des reponses du
// serveur (forme exacte des fonctions de la migration 20261123910000) et ses
// refus, en motifs fermes. Pur, sans ecran.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/calendrier/port_calendrier.dart';

import '../../support/calendrier_pauses_faux.dart';

void main() {
  group('calendrier_ecole_liste', () {
    test('une liste complete', () {
      final List<EvenementCalendrier> l = evenementsDepuisJson(
        calendrierServeur(),
      );
      expect(l.length, 3);
      final EvenementCalendrier f = l.first;
      expect(f.type, TypeEvenement.fermeture);
      expect(f.categorie, CategorieFermeture.aidAlAdha);
      expect(f.du, DateTime(2027, 5, 16));
      expect(f.au, DateTime(2027, 5, 25));
      expect(f.jours, 10);
      expect(f.publie, isTrue);
      expect(f.elevesVises, 5);
      expect(f.seancesNeutralisees, 4);
      expect(f.commencee, isFalse);
      expect(l[1].publie, isFalse);
      expect(l[1].elevesVises, isNull);
      expect(l[2].portee, PorteeEvenement.tranche);
      expect(l[2].cohorte, 'enfant_10_13');
    });

    test('une ligne illisible est ecartee, jamais completee', () {
      final List<EvenementCalendrier> l = evenementsDepuisJson(<Object?>[
        <String, Object?>{'id': 'x', 'type': 'inconnu'},
        'pas une ligne',
        null,
        ligneCalendrier(
          id: 'ok',
          type: 'autre',
          titre: 'Une date',
          du: '2027-01-01',
          au: '2027-01-01',
        ),
      ]);
      expect(l.map((EvenementCalendrier e) => e.id), <String>['ok']);
      expect(evenementsDepuisJson(null), isEmpty);
      expect(evenementsDepuisJson(<String, Object?>{}), isEmpty);
    });

    test('un jour se lit et s ecrit AAAA-MM-JJ', () {
      expect(jourDepuisSql('2027-05-16'), DateTime(2027, 5, 16));
      expect(jourDepuisSql(null), isNull);
      expect(jourDepuisSql('demain'), isNull);
      expect(jourVersSql(DateTime(2027, 5, 6)), '2027-05-06');
    });
  });

  group('pauses_eleve_lecture', () {
    test('la regle, douze mois proposes, les pauses', () {
      final LecturePauses? l = LecturePauses.depuisJson(
        lecturePausesServeur(
          moisAccordes: 1,
          aLaDirection: <int>{3},
          etats: <int, String>{0: 'acceptee'},
          pauses: <Object?>[
            pauseServeur(
              id: 'a',
              statut: 'demandee',
              annulable: true,
              repondreAvant: '2026-11-15',
            ),
            pauseServeur(
              id: 'b',
              statut: 'refusee',
              motifDecision: 'Le programme s etire deja',
            ),
          ],
        ),
      );
      expect(l, isNotNull);
      expect(l!.prenom, 'Mariam');
      expect(l.regle.preavisJours, 7);
      expect(l.regle.plafondMois, 2);
      expect(l.regle.fenetreMois, 12);
      expect(l.regle.delaiReponseJours, 3);
      expect(l.moisAccordes, 1);
      expect(l.moisProposes.length, 12);
      expect(l.moisProposes.first.mois, DateTime(2026, 12));
      expect(l.moisProposes.first.etat, StatutPause.acceptee);
      expect(l.moisProposes[3].aLaDirection, isTrue);
      expect(l.moisProposes[4].aLaDirection, isFalse);
      expect(l.pauses.first.annulable, isTrue);
      expect(l.pauses.first.repondreAvant, DateTime(2026, 11, 15));
      expect(l.pauses[1].statut, StatutPause.refusee);
      expect(l.pauses[1].motifDecision, 'Le programme s etire deja');
    });

    test('sans regle lisible : rien, jamais suppose', () {
      expect(LecturePauses.depuisJson(null), isNull);
      expect(
        LecturePauses.depuisJson(<String, Object?>{
          'eleve_id': 'x',
          'regle': <String, Object?>{'preavis_jours': 7},
        }),
        isNull,
      );
    });

    test('la reponse de pause_demander', () {
      final ReponseDemandePause? r = ReponseDemandePause.depuisJson(
        <String, Object?>{
          'id': 'p',
          'statut': 'demandee',
          'debut': '2027-02-01',
          'fin': '2027-02-28',
          'repondre_avant': '2026-11-15',
        },
      );
      expect(r!.statut, StatutPause.demandee);
      expect(r.repondreAvant, DateTime(2026, 11, 15));
      expect(ReponseDemandePause.depuisJson(<String, Object?>{}), isNull);
    });
  });

  group('pauses_a_traiter', () {
    test('les demandes et les decisions recentes', () {
      final FilePauses f = FilePauses.depuisJson(fileServeur());
      expect(f.aTraiter.length, 2);
      expect(f.aTraiter.first.eleveNom, 'Mariam Benali');
      expect(f.aTraiter.first.moisAccordes, 2);
      expect(f.aTraiter.first.enRetard, isFalse);
      expect(f.aTraiter[1].enRetard, isTrue);
      expect(f.exceptionMoisMax, 3);
      expect(f.recentes.length, 2);
      expect(f.recentes.first.type, TypePause.exception);
      expect(f.recentes.first.decideeParNom, 'Direction Rewayah');
      expect(f.recentes.first.motif, 'Maladie soudaine');
      expect(f.recentes.first.terminable, isTrue);
      // Une pause deja terminee plus tot garde sa fin d'origine et son auteur.
      expect(f.recentes[1].terminable, isFalse);
      expect(f.recentes[1].finInitiale, DateTime(2026, 10, 31));
      expect(f.recentes[1].termineeParNom, 'Direction Rewayah');
    });

    test('une reponse vide ou illisible', () {
      expect(FilePauses.depuisJson(null).aTraiter, isEmpty);
      expect(FilePauses.depuisJson(fileServeur(vide: true)).recentes, isEmpty);
    });
  });

  group('les seances concernees et les conflits de retrait', () {
    test('seances concernees : jour et heure de La Mecque, de cote ou non', () {
      final ApercuSeances a = ApercuSeances.depuisJson(
        concerneesServeur(total: 3),
      );
      expect(a.total, 3);
      expect(a.seances.length, 3);
      expect(a.seances.first.classe, 'Classe 0');
      expect(a.seances.first.jour, DateTime(2027, 5, 16));
      expect(a.seances.first.heure, '15:00');
      expect(a.seances.first.deCote, isTrue);
      expect(a.seances[1].deCote, isFalse);
      expect(ApercuSeances.depuisJson(null).total, 0);
      expect(
        ApercuSeances.depuisJson(<String, Object?>{
          'total': 1,
          'seances': <Object?>[
            <String, Object?>{'classe': 'x'},
          ],
        }).seances,
        isEmpty,
      );
    });

    test('conflits : classe, jour, heure, enseignant, l autre cours', () {
      final ConflitsRetrait c = ConflitsRetrait.depuisJson(conflitsServeur());
      expect(c.nombre, 1);
      expect(c.conflits.single.classe, 'Classe Al-Noor');
      expect(c.conflits.single.heure, '11:00');
      expect(c.conflits.single.enseignant, 'Aïcha Haddad');
      expect(c.conflits.single.autreClasse, 'Classe Al-Huda');
      expect(c.conflits.single.autreHeure, '11:30');
      expect(ConflitsRetrait.depuisJson(null).nombre, 0);
    });
  });

  group('les refus du serveur, en motifs fermes', () {
    test('calendrier', () {
      expect(
        motifRefusCalendrier(
          code: '22023',
          message: 'calendrier_retrait_conflits',
        ),
        MotifRefusCalendrier.retraitConflits,
      );
      expect(
        motifRefusCalendrier(
          code: '22023',
          message: 'calendrier_fermeture_passee',
        ),
        MotifRefusCalendrier.fermeturePassee,
      );
      MotifRefusCalendrier m(String message, [String? code]) =>
          motifRefusCalendrier(code: code, message: message);
      expect(
        m('calendrier_fermeture_trop_longue', '22023'),
        MotifRefusCalendrier.fermetureTropLongue,
      );
      expect(
        m('calendrier_fermeture_commencee', '22023'),
        MotifRefusCalendrier.fermetureCommencee,
      );
      expect(
        m('calendrier_dates_invalides'),
        MotifRefusCalendrier.datesInvalides,
      );
      expect(
        m('calendrier_portee_invalide'),
        MotifRefusCalendrier.porteeInvalide,
      );
      expect(
        m('calendrier_evenement_invalide'),
        MotifRefusCalendrier.evenementInvalide,
      );
      expect(
        m('calendrier_evenement_introuvable'),
        MotifRefusCalendrier.introuvable,
      );
      expect(
        m('calendrier reserve a la direction', '42501'),
        MotifRefusCalendrier.nonAutorise,
      );
      expect(m('autre chose'), MotifRefusCalendrier.inconnu);
    });

    test('pause', () {
      MotifRefusPause m(String message, [String? code]) =>
          motifRefusPause(code: code, message: message);
      expect(m('pause_preavis', '22023'), MotifRefusPause.preavis);
      expect(m('pause_deja_demandee', '23505'), MotifRefusPause.dejaDemandee);
      expect(m('pause_mois_invalide'), MotifRefusPause.moisInvalide);
      expect(m('pause_non_annulable'), MotifRefusPause.nonAnnulable);
      expect(m('pause_motif_requis'), MotifRefusPause.motifRequis);
      expect(m('pause_deja_decidee'), MotifRefusPause.dejaDecidee);
      expect(m('pause_debut_passe'), MotifRefusPause.debutPasse);
      expect(m('pause_dates_invalides'), MotifRefusPause.datesInvalides);
      expect(
        m('pause_exception_trop_longue'),
        MotifRefusPause.exceptionTropLongue,
      );
      expect(m('pause_non_terminable'), MotifRefusPause.nonTerminable);
      expect(m('pause_eleve_introuvable'), MotifRefusPause.eleveIntrouvable);
      expect(m('pause refusee', '42501'), MotifRefusPause.nonAutorise);
      expect(m('autre chose'), MotifRefusPause.inconnu);
    });
  });
}
