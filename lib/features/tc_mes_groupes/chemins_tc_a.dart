/// Les chemins des ecrans d'Agent A, sous le prefixe reserve `/tc/`.
///
/// **Ils ne sont pas promus dans `lib/core/router/routes.dart`.** Ce fichier est
/// protege, et `tool/verifier_jetons.dart` refuse un second `GoRouter` dans
/// `lib/`. Agent Z promeut ces constantes a l'integration, appelle
/// `routesTcA()` depuis `app_router.dart` et ajuste `redirection.dart`.
///
/// **Piege nomme** : `redirection.dart` renvoie toute route hors prefixe de
/// role vers la racine du role. Un ecran pose sans cet ajustement sera
/// inatteignable. Et une route sans entree de navigation n'existe pas : voir la
/// section 7 de `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_A.md`.
abstract final class CheminsTcA {
  /// La liste des groupes de l'appelant.
  static const String mesGroupes = '/tc/groupes';

  /// Le segment de l'Espace Groupe, relatif a [mesGroupes].
  static const String segmentEspaceGroupe = ':groupeId';

  /// Le nom du parametre de chemin.
  static const String parametreGroupe = 'groupeId';

  /// L'Espace Groupe d'un groupe donne.
  static String espaceGroupe(String groupeId) => '$mesGroupes/$groupeId';
}
