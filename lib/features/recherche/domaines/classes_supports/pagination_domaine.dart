import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';

/// La page d'une liste deja autorisee et filtree, par curseur opaque.
///
/// Les adaptateurs de RECH-D1 filtrent un petit corpus **entierement charge et
/// deja autorise** par son propriete (les classes de la personne, le catalogue
/// que sa politique d'acces laisse voir) : jamais un balayage de toute la
/// base (spec §6.1). Le curseur est lie au domaine, a l'espace et a la
/// requete : un curseur d'un autre contexte est refuse (`curseurPerime`).
ReponseDomaine pageDeResultats({
  required DomaineRecherche domaine,
  required ContexteRecherche contexte,
  required String requeteNormalisee,
  required List<ResultatRecherche> trouves,
  required String? curseur,
  required int limite,
}) {
  final String empreinte =
      '${domaine.name}|${contexte.espace.name}|$requeteNormalisee';
  int depart = 0;
  if (curseur != null) {
    final List<String> parties = curseur.split('.');
    final bool valide =
        parties.length == 3 &&
        parties[0] == 'c1' &&
        parties[1] == empreinte.hashCode.toString() &&
        int.tryParse(parties[2]) != null;
    if (!valide) {
      return ReponseEchec(domaine, StatutRecherche.curseurPerime);
    }
    depart = int.parse(parties[2]);
  }
  final int borne = limite.clamp(1, BudgetsRecherche.plafondPage);
  final int debut = depart.clamp(0, trouves.length);
  final int fin = (debut + borne).clamp(0, trouves.length);
  final bool aPlus = fin < trouves.length;
  return ReponseOk(
    domaine,
    elements: trouves.sublist(debut, fin),
    curseurSuivant: aPlus ? 'c1.${empreinte.hashCode}.$fin' : null,
    aPlus: aPlus,
  );
}
