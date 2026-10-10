import 'modeles_recherche.dart';

/// Les budgets de la recherche (spec RECH-03 §6.2, §13.3).
///
/// **Valeurs proposees, non mesurees** : elles ne s'ajustent que sur des
/// mesures de recette. Les durees sont posees en microsecondes pour rester des
/// durees metier (hors `AppMouvement`, qui ne regit que les animations).
abstract final class BudgetsRecherche {
  /// Delai apres la derniere frappe : ~250 ms.
  static const Duration delaiSaisie = Duration(
    microseconds: 250 * Duration.microsecondsPerMillisecond,
  );

  /// L'attente normale d'un domaine : a 2 s, l'ecran dit que la recherche
  /// dure plus que prevu, sans retirer les resultats deja recus.
  static const Duration seuilLenteur = Duration(seconds: 2);

  /// Le delai d'une demande cliente : 3 s. N'arrete pas la requete SQL, que
  /// le serveur borne de son cote (~1,5 s proposees).
  static const Duration delaiDemande = Duration(seconds: 3);

  /// Le nombre de caracteres minimal d'une recherche large.
  static const int longueurMinimale = 3;

  /// Le nombre de caracteres minimal d'un mot arabe dans un domaine borne.
  static const int longueurMinimaleArabe = 2;

  /// La taille maximale de la requete.
  static const int longueurMaximale = 160;

  /// Le nombre maximal de termes.
  static const int termesMaximum = 8;

  /// Les domaines interroges en meme temps (fan-out borne).
  static const int domainesSimultanes = 3;

  /// Les resultats d'un domaine dans la fenetre commune.
  static const int limiteCommune = 5;

  /// Les resultats d'une page d'un domaine detaille.
  static const int limitePage = 20;

  /// Le plafond technique d'une page, que le serveur applique aussi.
  static const int plafondPage = 50;
}

/// Ce que vaut le texte saisi, avant tout appel.
enum ValiditeRequete {
  /// Champ vide : aucun appel, aucun balayage (§5 « Initial »).
  vide,

  /// Trop court pour une recherche large : « Saisissez au moins 3
  /// caracteres. »
  tropCourte,

  /// Assez long : la recherche peut partir.
  valide,
}

/// Une requete nettoyee et jugee.
class RequeteNormalisee {
  const RequeteNormalisee._(this.texte, this.validite);

  /// Nettoie et juge [brut] pour un [contexte].
  ///
  /// Un mot arabe court n'est admis (deux caracteres) que dans un domaine
  /// borne (`domaineCible`), jamais sur la surface commune (§6.2).
  factory RequeteNormalisee.de(String brut, ContexteRecherche contexte) {
    final List<String> termes = brut
        .trim()
        .split(RegExp(r'\s+'))
        .where((String t) => t.isNotEmpty)
        .take(BudgetsRecherche.termesMaximum)
        .toList();
    String texte = termes.join(' ');
    if (texte.length > BudgetsRecherche.longueurMaximale) {
      texte = texte.substring(0, BudgetsRecherche.longueurMaximale).trimRight();
    }
    if (texte.isEmpty) {
      return const RequeteNormalisee._('', ValiditeRequete.vide);
    }
    final int minimum = _arabe.hasMatch(texte) && contexte.domaineCible != null
        ? BudgetsRecherche.longueurMinimaleArabe
        : BudgetsRecherche.longueurMinimale;
    return RequeteNormalisee._(
      texte,
      texte.runes.length < minimum
          ? ValiditeRequete.tropCourte
          : ValiditeRequete.valide,
    );
  }

  /// Le texte nettoye : espaces replies, borne a
  /// [BudgetsRecherche.longueurMaximale] caracteres et
  /// [BudgetsRecherche.termesMaximum] termes.
  final String texte;

  /// Ce qu'il vaut.
  final ValiditeRequete validite;

  static final RegExp _arabe = RegExp(r'[؀-ۿ]');
}
