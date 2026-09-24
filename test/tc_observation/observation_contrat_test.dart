import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_observation/disponibilite_observation.dart';
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/vue_budget_observation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../fixtures/tuteur/faux_observation.dart';

DisponibiliteObservation _dispo({
  BudgetObservation? budget,
  GuardianObservationPolicy? politique = politiqueA2,
  EtatPresence? presence = EtatPresence.presente,
  bool activation = true,
  EtatSeanceFamille? etat = EtatSeanceFamille.enDirect,
  bool sansBudget = false,
}) => disponibiliteObservation(
  budget: sansBudget ? null : (budget ?? budgetDeuxVisites),
  politique: politique,
  presenceEnfant: presence,
  activationReelle: activation,
  etatSeance: etat,
);

MotifIndisponibilite? _motif(DisponibiliteObservation d) =>
    d is ObservationIndisponible ? d.motif : null;

void main() {
  group(
    'K4 : la politique normative est celle du serveur (2 x 120 s, 240 s)',
    () {
      test('les defauts normatifs, reserves aux tests, sont alignes', () {
        const GuardianObservationPolicy defauts =
            GuardianObservationPolicy.defautsNormatifs(policyVersion: 't');

        expect(defauts.maxVisitsPerSession, 2);
        expect(defauts.maxParVisite, const Duration(seconds: 120));
        expect(defauts.maxTotalObservationTime, const Duration(seconds: 240));
      });

      test('aucun code de lib/ n appelle les defauts normatifs', () {
        // Un ecran qui les afficherait promettrait 2 x 120 s a une classe dont
        // l'administration a regle autre chose : la valeur affichee vient
        // toujours de la politique effective rendue par le serveur.
        final List<String> appels = <String>[];
        for (final File fichier
            in Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where((File f) => f.path.endsWith('.dart'))) {
          final String chemin = fichier.path.replaceAll(r'\', '/');
          if (chemin.endsWith(
            'tc_observation/guardian_observation_policy.dart',
          )) {
            continue;
          }
          if (fichier.readAsStringSync().contains('defautsNormatifs')) {
            appels.add(chemin);
          }
        }
        expect(appels, isEmpty);
      });
    },
  );

  group('K4 : interrupteur OBSERVATION_TUTEUR_REELLE', () {
    test('faux par defaut, et toujours faux en production', () {
      expect(Env.observationTuteurReelle, isFalse);
      expect(Env.observationTuteurReelleActive, isFalse);
      expect(
        Env.observationTuteurReelleSelon(
          demandee: true,
          environnement: 'production',
        ),
        isFalse,
      );
      expect(
        Env.observationTuteurReelleSelon(
          demandee: true,
          environnement: 'staging',
        ),
        isTrue,
      );
      expect(
        Env.observationTuteurReelleSelon(
          demandee: false,
          environnement: 'developpement',
        ),
        isFalse,
      );
    });
  });

  group('K4 : disponibilite de l observation', () {
    test(
      'activation coupee : pas encore ouverte, visites dites quand meme',
      () {
        final DisponibiliteObservation d = _dispo(activation: false);

        expect(_motif(d), MotifIndisponibilite.garantieServeurAbsente);
        expect((d as ObservationIndisponible).visitesRestantes, 2);
      },
    );

    test('deux visites disponibles, puis la seconde et derniere', () {
      final DisponibiliteObservation deux = _dispo();
      final DisponibiliteObservation une = _dispo(budget: budgetUneRestante);

      expect(deux, isA<ObservationPossible>());
      expect((deux as ObservationPossible).visitesRestantes, 2);
      expect(deux.dureeProchaineVisite, const Duration(seconds: 120));
      expect((une as ObservationPossible).visitesRestantes, 1);
      // Une visite ecourtee est consommee : il n'en reste qu'une.
      expect(une.visitesUtilisees, 1);
    });

    test('visites epuisees, temps epuise, visite deja ouverte', () {
      expect(
        _motif(_dispo(budget: budgetEpuise)),
        MotifIndisponibilite.visitesEpuisees,
      );
      expect(
        _motif(
          _dispo(
            budget: budgetFictif(
              restant: Duration.zero,
              peutEntrer: false,
              motif: MotifRefusObservation.tempsEpuise,
            ),
          ),
        ),
        MotifIndisponibilite.tempsEpuise,
      );
      expect(
        _motif(_dispo(budget: budgetVisiteOuverte)),
        MotifIndisponibilite.visiteDejaOuverte,
      );
    });

    test('la seance decide avant le budget', () {
      expect(
        _motif(_dispo(etat: EtatSeanceFamille.aVenir)),
        MotifIndisponibilite.seanceNonCommencee,
      );
      expect(
        _motif(_dispo(etat: EtatSeanceFamille.terminee)),
        MotifIndisponibilite.seanceTerminee,
      );
      for (final EtatSeanceFamille etat in <EtatSeanceFamille>[
        EtatSeanceFamille.annulee,
        EtatSeanceFamille.annuleeTardive,
        EtatSeanceFamille.nonTenue,
      ]) {
        expect(
          _motif(_dispo(etat: etat)),
          MotifIndisponibilite.seanceNonTenue,
          reason: etat.name,
        );
      }
      // Un horaire incertain ne bloque rien : le serveur decide a l'entree.
      expect(
        _dispo(etat: EtatSeanceFamille.horaireIncertain),
        isA<ObservationPossible>(),
      );
    });

    test('sans budget lisible, rien n est propose', () {
      expect(
        _motif(_dispo(sansBudget: true)),
        MotifIndisponibilite.capaciteAbsente,
      );
    });

    test('une classe fermee par l administration', () {
      expect(
        _motif(_dispo(politique: politiqueFermee)),
        MotifIndisponibilite.observationDesactivee,
      );
      // Sans politique connue, le budget suffit.
      expect(_dispo(politique: null), isA<ObservationPossible>());
    });

    test('une presence non confirmee est en verification, jamais absente', () {
      final Set<MotifIndisponibilite> vus = <MotifIndisponibilite>{};
      for (final EtatPresence? presence in <EtatPresence?>[
        ...EtatPresence.values,
        null,
      ]) {
        final DisponibiliteObservation d = _dispo(presence: presence);
        final MotifIndisponibilite? motif = _motif(d);
        if (motif != null) {
          vus.add(motif);
        }
      }
      expect(vus, <MotifIndisponibilite>{
        MotifIndisponibilite.presenceEnVerification,
      });
      expect(
        _dispo(presence: EtatPresence.inconnu),
        isA<ObservationIndisponible>(),
      );
      expect(
        _dispo(presence: EtatPresence.enRetard),
        isA<ObservationPossible>(),
      );
    });

    test('un refus serveur se traduit sans deviner', () {
      expect(
        motifDepuisRefus(MotifRefusObservation.horsFenetre),
        MotifIndisponibilite.horsFenetre,
      );
      expect(
        motifDepuisRefus(MotifRefusObservation.seanceNonActive),
        MotifIndisponibilite.horsFenetre,
      );
      expect(
        motifDepuisRefus(MotifRefusObservation.lienTuteurAbsent),
        MotifIndisponibilite.lienAbsent,
      );
      expect(motifDepuisRefus(null), MotifIndisponibilite.capaciteAbsente);
    });
  });

  group('K4 : une visite deja ouverte n est pas une panne (23505)', () {
    test('la violation d unicite se nomme et ne se reessaye pas', () {
      final MotifEchecObservation motif = motifDeErreurPostgrest(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );

      expect(motif, MotifEchecObservation.visiteDejaOuverte);
      expect(
        const EchecObservation(MotifEchecObservation.visiteDejaOuverte)
            .seReessaye,
        isFalse,
      );
      expect(
        motifDepuisEchec(EchecObservation(motif)),
        MotifIndisponibilite.visiteDejaOuverte,
      );
      expect(
        motifDeErreurPostgrest(
          const PostgrestException(message: 'absente', code: '42883'),
        ),
        MotifEchecObservation.capaciteAbsente,
      );
      expect(
        motifDeErreurPostgrest(
          const PostgrestException(message: 'autre', code: 'XX000'),
        ),
        MotifEchecObservation.reseau,
      );
    });

    test('le budget lit la cle visite_en_cours, absente = faux', () {
      final Map<String, dynamic> ligne = <String, dynamic>{
        'policy_version': 'a2',
        'visites_utilisees': 1,
        'visites_max': 2,
        'restant_secondes': 70,
        'peut_entrer': true,
      };

      expect(BudgetObservation.depuisJson(ligne).visiteEnCours, isFalse);
      expect(
        BudgetObservation.depuisJson(<String, dynamic>{
          ...ligne,
          'visite_en_cours': true,
        }).visiteEnCours,
        isTrue,
      );
    });
  });

  group('K4 : compteur de visite', () {
    test('Visite 1/2, temps serveur, jamais allonge', () {
      final DateTime recu = DateTime.utc(2026, 9, 21, 17, 5);
      final BudgetObservation enVisite = budgetFictif(
        utilisees: 1,
        restant: const Duration(seconds: 102),
        visiteEnCours: true,
      );

      final CompteurVisite compteur = CompteurVisite.depuis(
        VueBudgetObservation.depuis(
          budget: enVisite,
          recuA: recu,
          // Une horloge d'appareil qui recule ne rend pas de temps.
          maintenant: recu.subtract(const Duration(seconds: 30)),
        ),
        confirmeParServeur: true,
      );

      expect(compteur.rang, 1);
      expect(compteur.total, 2);
      expect(compteur.restant, const Duration(seconds: 102));
      expect(compteur.confirmeParServeur, isTrue);
    });
  });

  group('K4 : historique des observations', () {
    test('une ligne complete se lit, une ligne incomplete est ecartee', () {
      final GuardianSessionVisit? fermee = GuardianSessionVisit.lire(
        ligneVisite(),
      );

      expect(fermee?.enCours, isFalse);
      expect(fermee?.durationSeconds, const Duration(seconds: 120));
      expect(fermee?.enteredAtUtc.isUtc, isTrue);
      expect(
        GuardianSessionVisit.lire(ligneVisite(sortie: null, duree: null))
            ?.enCours,
        isTrue,
      );
      for (final Map<String, dynamic> incomplete in <Map<String, dynamic>>[
        ligneVisite()..remove('entered_at'),
        ligneVisite()..remove('id'),
        ligneVisite()..remove('policy_version'),
        ligneVisite(role: 'role_inconnu'),
        ligneVisite(sortie: 'pas une date'),
      ]) {
        expect(GuardianSessionVisit.lire(incomplete), isNull);
      }
    });

    test('groupees par seance et enfant, la plus recente d abord', () {
      final List<ObservationsSeance> groupes = grouperObservations(
        <Map<String, dynamic>>[
          ligneVisite(id: 'v2', rang: 2, entree: '2026-09-21T17:20:00Z'),
          ligneVisite(),
          ligneVisite(
            id: 'v3',
            seanceId: 's2',
            entree: '2026-09-28T17:05:00Z',
            sortie: null,
            duree: null,
          ),
          ligneVisite(id: 'v4')..remove('entered_at'),
        ],
      );

      expect(groupes.map((ObservationsSeance g) => g.seanceId), <String>[
        's2',
        's1',
      ]);
      final ObservationsSeance s1 = groupes.last;
      expect(s1.nombreVisites, 2);
      expect(s1.visites.map((GuardianSessionVisit v) => v.visitNumber), <int>[
        1,
        2,
      ]);
      expect(s1.dureeTotaleConfirmee, const Duration(seconds: 240));
      // Une visite sans sortie : duree non confirmee, jamais recollee.
      expect(groupes.first.dureeTotaleConfirmee, isNull);
    });

    test('le faux historique rejoue la meme regle de groupement', () async {
      final FauxHistoriqueObservations faux = FauxHistoriqueObservations(
        lignes: <Map<String, dynamic>>[ligneVisite()],
      );

      expect((await faux.detail(seanceId: 's1'))?.nombreVisites, 1);
      expect(entreeAccordee.visite?.enCours, isTrue);
      expect(entreeRefusee.autorise, isFalse);
    });

    test('sans adaptateur livre, l historique est indisponible', () async {
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      for (final Future<Object?> lecture in <Future<Object?>>[
        conteneur.read(portHistoriqueObservationsProvider).mesObservations(),
        conteneur
            .read(portHistoriqueObservationsAdminProvider)
            .rechercher(const FiltreObservationsAdmin()),
      ]) {
        await expectLater(
          lecture,
          throwsA(
            isA<CapaciteIndisponible>().having(
              (CapaciteIndisponible c) => c.dependance,
              'dependance',
              'LOT-E',
            ),
          ),
        );
      }
    });
  });
}
