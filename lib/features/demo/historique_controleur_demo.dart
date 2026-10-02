// L'Historique du controleur en demonstration (CT-7) : les trois rapports de
// `DonneesControleurDemo.rapports`, completes de leurs faits, observation et
// complements, en memoire. Rien ne part (K-28).

import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../controleur/compte_rendu_controle.dart';
import '../controleur/historique_controleur.dart';
import '../controleur/observation_controle.dart';
import 'controleur_demo.dart';

/// Le port de demonstration : la lecture repond apres un court delai.
class HistoriqueDemo implements PortHistorique {
  /// Cree le port.
  const HistoriqueDemo();

  @override
  Future<List<RapportControle>> rapports() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return <RapportControle>[
      for (final RapportControleurDemo r in DonneesControleurDemo.rapports)
        _rapport(r),
    ];
  }

  static RapportControle _rapport(RapportControleurDemo r) {
    final String titre = switch (r.titreEnseignant) {
      TitreEnseignant.sayyid => LibellesGroupe.sayyid,
      TitreEnseignant.sayyida => LibellesGroupe.sayyida,
    };
    final StatutRapport statut = switch (r.statut) {
      StatutRapportDemo.envoye => StatutRapport.envoye,
      StatutRapportDemo.complementAjoute => StatutRapport.complementAjoute,
      StatutRapportDemo.aTerminer => StatutRapport.aTerminer,
    };
    final String enseignant = '$titre ${r.enseignant}';
    return switch (r.id) {
      // Al-Badr, 24/09 : une observation « A suivre », puis un complement.
      'demo-rapport-0924' => RapportControle(
        id: r.id,
        missionId: r.missionId,
        classe: r.classe,
        enseignant: enseignant,
        debut: r.date,
        dureeObservee: r.dureeObservee,
        statut: statut,
        faits: _faits(DonneesControleurDemo.faitsSeanceFinie),
        choix: ChoixCompteRendu.ajouterObservation,
        observation: const ObservationControle(
          important: false,
          nature: NatureObservation.aSuivre,
          domaine: DomaineObservation.respectCadre,
          personne: PersonneConcernee.enseignant,
          texte: 'La séance a commencé avec huit minutes de retard.',
        ),
        presents: const <String>['Bilal K.', 'Hafsa D.', 'Ilyas M.', 'Sara T.'],
        complements: <ComplementRapport>[
          ComplementRapport(
            date: DateTime(2026, 9, 24, 17, 55),
            texte:
                "Le retard venait d'une coupure de connexion de "
                "l'enseignant, rétablie à 17 h 08.",
          ),
        ],
      ),
      // An-Nour, 21/09 : rien a signaler.
      'demo-rapport-0921' => RapportControle(
        id: r.id,
        missionId: r.missionId,
        classe: r.classe,
        enseignant: enseignant,
        debut: r.date,
        dureeObservee: r.dureeObservee,
        statut: statut,
        faits: FaitsVisite(
          debutPrevu: DateTime(2026, 9, 21, 18),
          finPrevue: DateTime(2026, 9, 21, 18, 45),
          debutReel: DateTime(2026, 9, 21, 18),
          finReelle: DateTime(2026, 9, 21, 18, 44),
          participantsAttendus: 3,
          participantsPresents: 3,
          reconnexions: 0,
        ),
        choix: ChoixCompteRendu.rienASignaler,
        presents: const <String>['Aïcha N.', 'Mariam S.', 'Yusuf B.'],
      ),
      // A terminer : pas de detail, la ligne reprend le compte rendu.
      _ => RapportControle(
        id: r.id,
        missionId: r.missionId,
        classe: r.classe,
        enseignant: enseignant,
        debut: r.date,
        dureeObservee: r.dureeObservee,
        statut: statut,
      ),
    };
  }

  static FaitsVisite _faits(FaitsAutomatiquesDemo f) => FaitsVisite(
    debutPrevu: f.debutPrevu,
    finPrevue: f.debutPrevu.add(f.dureePrevue),
    debutReel: f.debutReel,
    finReelle: f.finReelle,
    participantsAttendus: f.participantsAttendus,
    participantsPresents: f.participantsPresents,
    reconnexions: f.reconnexions,
  );
}
