import '../../../../core/capacites/port_encaissements.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../classes_supports/pagination_domaine.dart';

/// Le moteur « Finance » (RECH-D4, spec RECH-03 §3 « Finance », §12) : les
/// encaissements que la comptabilite lit deja, par **reference** ou par nom de
/// famille, rien d'autre.
///
/// Il ne recode ni FI ni CPT : il lit `PortEncaissements.liste`, la source de
/// l'ecran des encaissements, avec sa propre recherche. Aucun droit
/// supplementaire : seul l'espace comptable est servi, et le port refuse de
/// lui-meme (exception = panne, jamais un vide). **Les montants ne sont ni
/// cherches ni rendus** : le resultat porte la reference, la famille, la date
/// et l'etat, jamais brut, frais, net, moyen ni prestataire. Les montants se
/// lisent dans l'ecran du module, selon les droits du module.
///
/// **Reserve** : filtre sur la liste que le module charge deja ;
/// demonstration seulement, jamais raccorde en production (le serveur de
/// recherche financiere est a Codex).
class MoteurEncaissements implements MoteurRechercheDomaine {
  /// Cree le moteur sur [port].
  const MoteurEncaissements(this.port);

  /// Les encaissements de la comptabilite.
  final PortEncaissements port;

  @override
  DomaineRecherche get domaine => DomaineRecherche.finances;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      contexte.espace == EspaceRecherche.comptable;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (contexte.espace != EspaceRecherche.comptable) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final List<Encaissement> liste = await port.liste(
      FiltreEncaissements(recherche: requete.trim()),
    );
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      for (final Encaissement e in liste)
        if (correspondTousLesTermes(
          normaliserPourRecherche('${e.reference} ${e.famille}'),
          cle,
        ))
          ResultatRecherche(
            type: TypeResultat.operation,
            reference: e.id,
            titre: e.reference,
            contexte: t.recherche.contexte.encaissement(famille: e.famille),
            cible: CibleRecherche(kind: KindCible.operation, reference: e.id),
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
