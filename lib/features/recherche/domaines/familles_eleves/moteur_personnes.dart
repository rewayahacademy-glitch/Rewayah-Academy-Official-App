import '../../../../core/capacites/port_acces_foyer.dart';
import '../../../../core/capacites/port_classes_foyer.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../classes_supports/pagination_domaine.dart';
import 'port_resolution_ra.dart';

/// Le moteur « Familles et eleves » (RECH-D2, spec RECH-03 §3, §7.2).
///
/// Deux entrees, jamais melangees :
///
/// - **Par nom**, dans le seul foyer de la personne : les profils que
///   `PortAccesFoyer` rend deja a l'ecran du foyer, par prenom. Le second
///   adulte du foyer lit le meme foyer, donc voit les memes profils. Deux
///   homonymes restent deux resultats distincts, departages par leur classe
///   quand elle est connue. Aucun profil d'un autre foyer n'existe ici.
/// - **Par identifiant d'academie exact** : seulement une saisie qui est un
///   RA complet ([identifiantRaExact]) part vers [PortResolutionRa]. Le
///   serveur decide ; l'application ne garde ni registre ni index, ne
///   complete pas un debut d'identifiant, et rend le meme vide pour un RA
///   inconnu, d'un autre foyer ou retire (non-enumerabilite).
///
/// Champs cherches par nom : le prenom, rien d'autre. Champs rendus : le
/// prenom et la classe ; ni solde, ni echeance d'acces, ni coordonnee.
///
/// **Reserve** : le filtre par nom est local, sur le petit corpus deja
/// autorise du foyer ; demonstration seulement, jamais raccorde en
/// production. La resolution du RA est toujours serveur.
class MoteurPersonnesFoyer implements MoteurRechercheDomaine {
  /// Cree le moteur.
  const MoteurPersonnesFoyer({
    required this.foyer,
    required this.classes,
    required this.resolutionRa,
    this.espacesParNom = const <EspaceRecherche>{EspaceRecherche.famille},
    this.espacesParRa = const <EspaceRecherche>{
      EspaceRecherche.famille,
      EspaceRecherche.administration,
    },
  });

  /// Les profils du foyer.
  final PortAccesFoyer foyer;

  /// Les classes de chaque profil, pour departager les homonymes.
  final PortClassesFoyer classes;

  /// La resolution serveur d'un RA exact.
  final PortResolutionRa resolutionRa;

  /// Les espaces qui cherchent un profil de leur foyer par son prenom.
  final Set<EspaceRecherche> espacesParNom;

  /// Les espaces qui peuvent presenter un RA exact au serveur.
  final Set<EspaceRecherche> espacesParRa;

  @override
  DomaineRecherche get domaine => DomaineRecherche.personnes;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      espacesParNom.contains(contexte.espace) ||
      espacesParRa.contains(contexte.espace);

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    final EspaceRecherche espace = contexte.espace;
    if (!await disponiblePour(contexte)) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final String? ra = identifiantRaExact(requete);
    if (ra != null && espacesParRa.contains(espace)) {
      return _parIdentifiant(ra, contexte, cle, curseur, limite);
    }
    if (!espacesParNom.contains(espace)) {
      // Un espace sans recherche par nom (administration) qui ne presente pas
      // un RA complet recoit le meme vide qu'un RA inconnu.
      return pageDeResultats(
        domaine: domaine,
        contexte: contexte,
        requeteNormalisee: cle,
        trouves: const <ResultatRecherche>[],
        curseur: curseur,
        limite: limite,
      );
    }
    return _parNom(contexte, cle, curseur, limite);
  }

  Future<ReponseDomaine> _parIdentifiant(
    String ra,
    ContexteRecherche contexte,
    String cle,
    String? curseur,
    int limite,
  ) async {
    final ElevePourRa? trouve = await resolutionRa.resoudre(ra);
    return pageDeResultats(
      domaine: domaine,
      contexte: contexte,
      requeteNormalisee: cle,
      trouves: <ResultatRecherche>[
        if (trouve != null)
          ResultatRecherche(
            type: TypeResultat.personne,
            reference: trouve.eleveId,
            titre: trouve.prenom,
            contexte: trouve.classe == null
                ? t.recherche.contexte.personneParIdentifiant
                : t.recherche.contexte.personneParIdentifiantClasse(
                    classe: trouve.classe!,
                  ),
            cible: CibleRecherche(
              kind: KindCible.eleve,
              reference: trouve.eleveId,
            ),
          ),
      ],
      curseur: curseur,
      limite: limite,
    );
  }

  Future<ReponseDomaine> _parNom(
    ContexteRecherche contexte,
    String cle,
    String? curseur,
    int limite,
  ) async {
    final List<AccesBeneficiaire> profils = await foyer.acces();
    final List<ResultatRecherche> trouves = <ResultatRecherche>[];
    for (final AccesBeneficiaire p in profils) {
      if (!correspondTousLesTermes(normaliserPourRecherche(p.prenom), cle)) {
        continue;
      }
      final String? classe = await _classeDe(p.eleveId);
      trouves.add(
        ResultatRecherche(
          type: TypeResultat.personne,
          reference: p.eleveId,
          titre: p.prenom,
          contexte: classe == null
              ? t.recherche.contexte.personneFoyer
              : t.recherche.contexte.personneFoyerClasse(classe: classe),
          cible: CibleRecherche(kind: KindCible.eleve, reference: p.eleveId),
        ),
      );
    }
    return pageDeResultats(
      domaine: domaine,
      contexte: contexte,
      requeteNormalisee: cle,
      trouves: trouves,
      curseur: curseur,
      limite: limite,
    );
  }

  /// La premiere classe active du profil ; une classe illisible ne fait ni
  /// disparaitre le profil ni echouer la recherche : il est rendu sans classe.
  Future<String?> _classeDe(String eleveId) async {
    try {
      final List<ClasseFoyer> liste = await classes.classesDe(eleveId);
      for (final ClasseFoyer c in liste) {
        if (c.classe.actif) return c.classe.libelle;
      }
    } on Object {
      return null;
    }
    return null;
  }
}
