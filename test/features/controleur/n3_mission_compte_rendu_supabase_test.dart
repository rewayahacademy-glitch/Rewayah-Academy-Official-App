// N3, D3 : la lecture de `ma_mission_controle` et ce que l'envoi du compte
// rendu adresse au serveur.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_supabase.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/controleur/mission_controle_supabase.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  Map<String, dynamic> ligne({
    String seance = 'in_progress',
    String statut = 'attribuee',
  }) => <String, dynamic>{
    'id': 'm1',
    'session_id': 's1',
    'groupe_id': 'g1',
    'statut': statut,
    'classe': 'Classe Hafs 1',
    'enseignant_prenom': 'Ibrahim',
    'enseignant_titre': 'sayyid',
    'debut': '2026-11-03T14:00:00+00:00',
    'fin_prevue': '2026-11-03T15:00:00+00:00',
    'seance_statut': seance,
    'nombre_eleves': 4,
  };

  group('N3 D3 : la mission', () {
    test('aucune mission : `{}` rend nul', () {
      expect(missionDepuis(<String, dynamic>{}), isNull);
    });

    test('seance en direct : « Commencer le controle »', () {
      final MissionControle m = missionDepuis(ligne())!;
      expect(m.id, 'm1');
      expect(m.seanceId, 's1');
      expect(m.classe, 'Classe Hafs 1');
      expect(m.enseignant, '${t.tc.groupe.enseignant.sayyid} Ibrahim');
      expect(m.nombreEleves, 4);
      expect(m.etat, EtatMissionControle.enDirect);
      expect(m.dureePrevue, const Duration(hours: 1));
      expect(m.commencee, isFalse);
    });

    test('visite deja commencee : y revenir ne la recommence pas', () {
      expect(missionDepuis(ligne(statut: 'en_cours'))!.commencee, isTrue);
    });

    test('seance close : indisponible', () {
      expect(
        missionDepuis(ligne(seance: 'ended'))!.etat,
        EtatMissionControle.indisponible,
      );
    });

    test('projection incomplete : refusee', () {
      expect(
        () => missionDepuis(<String, dynamic>{'id': 'm1'}),
        throwsFormatException,
      );
    });
  });

  group('N3 D3 : le compte rendu', () {
    test('les trois reponses, nommees comme au serveur', () {
      expect(choixServeur(ChoixCompteRendu.rienASignaler), 'rien_a_signaler');
      expect(
        choixServeur(ChoixCompteRendu.ajouterObservation),
        'ajouter_observation',
      );
      expect(choixServeur(ChoixCompteRendu.pointImportant), 'point_important');
    });

    test('l\'eleve ne part que pour « un eleve precis »', () {
      const ObservationControle sur = ObservationControle(
        important: true,
        nature: NatureObservation.interventionAdmin,
        domaine: DomaineObservation.respectCadre,
        personne: PersonneConcernee.elevePrecis,
        eleveId: 'e1',
        texte: 'A voir.',
      );
      expect(observationServeur(sur), <String, dynamic>{
        'nature': 'intervention_admin',
        'domaine': 'respect_cadre',
        'personne': 'eleve_precis',
        'eleve_id': 'e1',
        'texte': 'A voir.',
      });
      const ObservationControle classe = ObservationControle(
        important: false,
        nature: NatureObservation.pointPositif,
        domaine: DomaineObservation.gestionClasse,
        personne: PersonneConcernee.classeEntiere,
        eleveId: 'e1',
        texte: '',
      );
      expect(observationServeur(classe).containsKey('eleve_id'), isFalse);
      expect(observationServeur(classe)['domaine'], 'gestion_classe');
    });
  });

  group('N3 D3 : le roster de la visite', () {
    test('prenom et initiale, jamais le nom entier', () {
      final List<EleveRoster> r = rosterDepuis(<Object?>[
        <String, dynamic>{'id': 'e1', 'prenom': 'Yasmine', 'initiale': 'B'},
        <String, dynamic>{'id': 'e2', 'prenom': 'Adam', 'initiale': null},
      ]);
      expect(r.map((EleveRoster e) => e.nomAffiche), <String>[
        'Yasmine B.',
        'Adam',
      ]);
      expect(r.first.id, 'e1');
    });

    test('ligne invalide : refusee', () {
      expect(
        () => rosterDepuis(<Object?>[
          <String, dynamic>{'prenom': 'Sans id'},
        ]),
        throwsFormatException,
      );
    });
  });
}
