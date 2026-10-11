import '../../../../core/i18n/strings.g.dart';
import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../controleur/mission_controle.dart';
import '../classes_supports/pagination_domaine.dart';

/// Le moteur « Controle » (RECH-D3, spec RECH-03 §2 « Controleur », §3
/// « Controle ») : **la mission du controleur, zero ou une** (CT-2, BR-CT-03),
/// jamais un planning ni une liste.
///
/// - Champs cherches : le nom distinct de la classe et le nom d'affichage de
///   l'enseignant (ce que la page de la mission montre deja). **Pas** le
///   nombre d'eleves, **aucun** nom d'eleve, **aucun** rapport, aucun fil :
///   le roster, le rapport brut et le fil de mission gardent leurs projections
///   distinctes (REC-04).
/// - **Une mission expiree refuse** : indisponible, ou terminee depuis plus
///   que la marge, elle rend `contexteRevoque`, jamais un resultat ni un vide
///   (SEC-R06, SEC-R15). Le droit ne se prolonge pas par un resultat garde.
/// - Sans mission : vide confirme, sans aucun indice sur une autre mission ni
///   sur l'existence de classes (SEC-R01, REC-04).
/// - Un controleur ne voit jamais d'autre domaine ; un autre espace n'a pas
///   ce domaine.
///
/// [lire] rend la mission courante (`missionControleProvider`) ; [maintenant]
/// est injectable pour les tests.
class MoteurControleMission implements MoteurRechercheDomaine {
  /// Cree le moteur.
  MoteurControleMission({
    required this.lire,
    DateTime Function()? maintenant,
    this.marge = const Duration(minutes: 30),
  }) : maintenant = maintenant ?? DateTime.now;

  /// Lit la mission courante, ou `null` quand il n'y en a pas.
  final Future<MissionControle?> Function() lire;

  /// L'horloge.
  final DateTime Function() maintenant;

  /// Le temps pendant lequel une mission terminee reste ouverte a la recherche
  /// (la fin d'une visite, le compte rendu).
  final Duration marge;

  @override
  DomaineRecherche get domaine => DomaineRecherche.controle;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      contexte.espace == EspaceRecherche.controleur;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (contexte.espace != EspaceRecherche.controleur) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final MissionControle? mission = await lire();
    final String cle = normaliserPourRecherche(requete);
    if (mission == null) {
      // Zero mission : vide confirme, sans le moindre indice.
      return pageDeResultats(
        domaine: domaine,
        contexte: contexte,
        requeteNormalisee: cle,
        trouves: const <ResultatRecherche>[],
        curseur: curseur,
        limite: limite,
      );
    }
    final bool expiree =
        mission.etat == EtatMissionControle.indisponible ||
        maintenant().isAfter(mission.finPrevue.add(marge));
    if (expiree) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String champs = normaliserPourRecherche(
      '${mission.classeDistincte} ${mission.enseignant}',
    );
    final String reference = mission.id ?? mission.seanceId;
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      if (correspondTousLesTermes(champs, cle))
        ResultatRecherche(
          type: TypeResultat.mission,
          reference: reference,
          titre: mission.classeDistincte,
          contexte: t.recherche.contexte.missionEnseignant(
            enseignant: mission.enseignant,
          ),
          cible: CibleRecherche(kind: KindCible.mission, reference: reference),
        ),
    ];
    return pageDeResultats(
      domaine: domaine,
      contexte: contexte,
      requeteNormalisee: cle,
      trouves: trouves,
      curseur: curseur,
      limite: limite,
    );
  }
}
