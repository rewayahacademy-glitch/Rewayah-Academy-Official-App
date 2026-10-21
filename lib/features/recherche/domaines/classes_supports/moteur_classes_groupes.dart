import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../../core/tc_groupe/group_summary_vm.dart';
import '../../../../core/tc_groupe/port_groupes.dart';
import 'pagination_domaine.dart';

/// Le moteur « Classes » (RECH-D1, spec RECH-03 §3 « Classes inscrites ») :
/// les classes **de la personne**, lues sur `PortGroupes.mesGroupes()`, le
/// port que l'Accueil et l'Espace Classe lisent deja. Aucune classe d'autrui,
/// aucun catalogue d'offres (celui-ci reste distinct, `PortCatalogueClasses`).
///
/// Champs cherches : le nom de la classe, le cours, le niveau et le nom
/// d'affichage de l'enseignant ; rien d'autre n'est lu (ni effectif, ni
/// coordonnees). Champs rendus : le nom, une ligne de contexte courte.
/// L'ouverture reautorise la classe (route canonique).
///
/// Une classe fermee (`actif` faux) n'est jamais trouvee. Aucune copie des
/// classes n'est gardee entre deux recherches : un retrait de droit se voit
/// a la recherche suivante (SEC-R06, R19).
///
/// **Reserve** : le filtre est local, sur un petit corpus charge en entier
/// (les classes de la personne) : il n'est pas un moteur serveur et n'a aucun
/// sens pour un volume. Il n'est raccorde qu'en demonstration ; la recherche
/// reelle des classes est l'affaire du moteur serveur (ligne Contrats C-32).
class MoteurClassesGroupes implements MoteurRechercheDomaine {
  /// Cree le moteur sur [port], ouvert aux [espaces].
  const MoteurClassesGroupes(
    this.port, {
    this.espaces = const <EspaceRecherche>{
      EspaceRecherche.famille,
      EspaceRecherche.eleve,
      EspaceRecherche.eleveGuide,
      EspaceRecherche.enseignant,
    },
  });

  /// Le port des classes de la personne.
  final PortGroupes port;

  /// Les espaces qui peuvent chercher dans leurs classes.
  final Set<EspaceRecherche> espaces;

  @override
  DomaineRecherche get domaine => DomaineRecherche.classes;

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
    final List<GroupSummaryVM> groupes = await port.mesGroupes();
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      for (final GroupSummaryVM g in groupes)
        if (g.actif && correspondTousLesTermes(_champs(g), cle))
          ResultatRecherche(
            type: TypeResultat.classe,
            reference: g.groupeId,
            titre: g.libelle,
            contexte: _contexte(g),
            cible: CibleRecherche(
              kind: KindCible.classe,
              reference: g.groupeId,
            ),
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

  /// Les seuls champs ou une correspondance peut tomber.
  static String _champs(GroupSummaryVM g) => normaliserPourRecherche(
    <String>[
      g.libelle,
      ?g.nomCours,
      ?g.niveauHumain,
      g.enseignant.nomAffichage,
    ].join(' '),
  );

  /// La ligne de contexte : le cours et le niveau, jamais un identifiant.
  static String? _contexte(GroupSummaryVM g) {
    final List<String> parts = <String>[?g.nomCours, ?g.niveauHumain];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
