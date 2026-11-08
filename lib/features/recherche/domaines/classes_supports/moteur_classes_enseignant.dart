import '../../../../core/enseignant/modeles_enseignant.dart';
import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import 'pagination_domaine.dart';

/// Le moteur « Classes » de l'ENSEIGNANT (RECH-D1, RECHERCHE-LIVRAISON,
/// 08/11/2026, verdict du garde-cap sur la PR 347).
///
/// Les classes de l'enseignant ne se lisent pas par `PortGroupes` : en
/// production il lit `mes_groupes_famille_v`, qui filtre sur l'eleve et le foyer
/// et ne rend AUCUNE ligne a un enseignant. Un moteur branche dessus aurait dit
/// « aucun resultat » a l'enseignant pour une classe qu'il enseigne : un vide
/// presente comme confirme alors qu'il est faux. Ce moteur lit la source que
/// « Mes classes » lit deja (`ServiceEnseignant.groupes`, vue `mes_groupes_v`,
/// groupes actifs de l'enseignant connecte).
///
/// Champ cherche : le nom de la classe, rien d'autre. Champ rendu : le nom.
/// Aucune copie n'est gardee entre deux recherches ([lire] relit a chaque
/// appel : un retrait se voit a la recherche suivante) ; une erreur de lecture
/// remonte, c'est une panne, jamais un vide.
class MoteurClassesEnseignant implements MoteurRechercheDomaine {
  /// Cree le moteur sur [lire], les classes actives de l'enseignant connecte.
  const MoteurClassesEnseignant(this.lire);

  /// La lecture des classes de l'enseignant (fraiche a chaque appel).
  final Future<List<GroupeEnseignant>> Function() lire;

  @override
  DomaineRecherche get domaine => DomaineRecherche.classes;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      contexte.espace == EspaceRecherche.enseignant;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (contexte.espace != EspaceRecherche.enseignant) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final List<GroupeEnseignant> classes = await lire();
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      for (final GroupeEnseignant g in classes)
        if (correspondTousLesTermes(normaliserPourRecherche(g.libelle), cle))
          ResultatRecherche(
            type: TypeResultat.classe,
            reference: g.id,
            titre: g.libelle,
            cible: CibleRecherche(kind: KindCible.classe, reference: g.id),
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
