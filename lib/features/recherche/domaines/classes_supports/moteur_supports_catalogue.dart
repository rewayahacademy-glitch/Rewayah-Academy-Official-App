import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../../core/tc_bibliotheque/library_resource.dart';
import '../../../../core/tc_bibliotheque/port_catalogue.dart';
import 'pagination_domaine.dart';

/// Le moteur « Supports » (RECH-D1, spec RECH-03 §3 « Supports /
/// Bibliotheque ») : une **vue** de `PortCatalogue`, le catalogue que la
/// Bibliotheque lit deja. Il ne cree ni second catalogue ni second moteur : la
/// visibilite (politique d'acces, groupe, retrait) est celle du catalogue.
///
/// Champs rendus : le titre, une ligne « categorie · type ». Jamais d'adresse
/// de fichier ni de lien signe : l'ouverture passe par la fiche de la
/// ressource, qui reautorise (SEC-R13). Le texte coranique n'est ni cherche ni
/// rendu ici (rendu du Coran interdit, spec §3 « Coran »).
///
/// **Reserve** : le catalogue est charge en entier par son port et filtre
/// localement ; en production ce port est vide tant que CAP29-0 et la couche
/// serveur ne sont pas la : ce moteur n'y est donc pas raccorde (un catalogue
/// vide ne vaut pas un vide confirme).
class MoteurSupportsCatalogue implements MoteurRechercheDomaine {
  /// Cree le moteur sur [catalogue], ouvert aux [espaces].
  const MoteurSupportsCatalogue(
    this.catalogue, {
    this.espaces = const <EspaceRecherche>{
      EspaceRecherche.famille,
      EspaceRecherche.eleve,
      EspaceRecherche.eleveGuide,
      EspaceRecherche.enseignant,
    },
  });

  /// Le catalogue de la Bibliotheque.
  final PortCatalogue catalogue;

  /// Les espaces qui peuvent chercher dans les supports.
  final Set<EspaceRecherche> espaces;

  @override
  DomaineRecherche get domaine => DomaineRecherche.supports;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      espaces.contains(contexte.espace);

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (!espaces.contains(contexte.espace)) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final List<LibraryResource> ressources = await catalogue.rechercher(
      requete,
    );
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      for (final LibraryResource r in ressources)
        ResultatRecherche(
          type: TypeResultat.support,
          reference: r.id,
          titre: r.title,
          contexte: r.category,
          cible: CibleRecherche(kind: KindCible.support, reference: r.id),
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
