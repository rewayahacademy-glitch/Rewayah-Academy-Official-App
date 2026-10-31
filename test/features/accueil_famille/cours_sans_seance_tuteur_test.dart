// Defaut du 30/10/2026, cote tuteur (et adulte titulaire, compte tuteur) : la
// carte de la Classe dit le cours du moment tire de l'horloge de la Classe
// quand sa seance n'existe pas encore, au lieu de la seance de la semaine
// suivante.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';

import '../../fixtures/tuteur/faux_seances_famille.dart';

void main() {
  final DateTime debut = DateTime.utc(2026, 10, 30, 18);
  final DateTime maintenant = DateTime.utc(2026, 10, 30, 18, 25);
  const HorlogeAffichee paris = HorlogeAffichee(
    fuseauIana: 'Europe/Paris',
    libelleVille: 'Paris',
    heureLocaleRendue: '19:00',
    dateLocaleRendue: 'Vendredi 30 octobre',
  );

  SessionClockVM horloge({String? sessionId}) => SessionClockVM.depuisFenetre(
    fenetre: FenetreSeance(
      debutUtc: debut,
      finPrevueUtc: debut.add(const Duration(minutes: 90)),
      fenetreAcces: const Duration(minutes: 20),
      graceApresFin: const Duration(minutes: 15),
    ),
    maintenantServeurUtc: maintenant,
    horlogeUtilisateur: paris,
    sessionId: sessionId,
  );

  final SeanceFamille semaineSuivante = seanceFictive(
    debutUtc: debut.add(const Duration(days: 7)),
    duree: const Duration(minutes: 90),
  );

  test(
    'sans seance, avant la seance creee : le cours du moment, en direct',
    () {
      final SeanceFamille? cours = coursSansSeanceAvant(
        horloge(),
        prochaine: semaineSuivante,
        eleveId: 'e1',
        groupeId: 'g-garcons',
      );
      expect(cours, isNotNull);
      expect(cours!.debutUtc, debut);
      expect(cours.groupeId, 'g-garcons');
      expect(cours.enseignant, semaineSuivante.enseignant);
      expect(cours.heureFoyer, paris);
      expect(
        AffichageSeance.depuis(cours, maintenantServeurUtc: maintenant).etat,
        EtatSeanceFamille.enDirect,
      );
    },
  );

  test('sans aucune seance creee : le cours du moment quand meme', () {
    expect(
      coursSansSeanceAvant(
        horloge(),
        prochaine: null,
        eleveId: 'e1',
        groupeId: 'g-garcons',
      )?.statutServeur,
      StatutSeance.planifiee,
    );
  });

  test('l horloge porte sa seance, ou il n y a pas d horloge : rien', () {
    expect(
      coursSansSeanceAvant(
        horloge(sessionId: 's1'),
        prochaine: semaineSuivante,
        eleveId: 'e1',
        groupeId: 'g',
      ),
      isNull,
    );
    expect(
      coursSansSeanceAvant(
        null,
        prochaine: semaineSuivante,
        eleveId: 'e1',
        groupeId: 'g',
      ),
      isNull,
    );
  });
}
