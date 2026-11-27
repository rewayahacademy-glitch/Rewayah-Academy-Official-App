import 'libelle_appareil_natif.dart'
    if (dart.library.js_interop) 'libelle_appareil_web.dart'
    as plateforme;

/// SALLE-SECOND-APPAREIL (directeur, 23/11/2026) : l'etiquette lisible de
/// l'appareil, « Chrome · Android ». **Jamais une adresse IP** : seulement le
/// navigateur et le systeme, que l'on montre a la personne pour qu'elle
/// reconnaisse l'appareil qui demande a entrer.
String libelleAppareilCourant() => libelleDepuisAgent(
  plateforme.agentUtilisateur(),
  repli: plateforme.systemeNatif(),
);

/// Lit un agent utilisateur de navigateur : navigateur et systeme.
///
/// [repli] est le systeme connu hors navigateur (application) : sans agent, on
/// dit « Application · Android ».
String libelleDepuisAgent(String agent, {String repli = ''}) {
  if (agent.isEmpty) {
    return repli.isEmpty ? 'Application' : 'Application · $repli';
  }
  final String navigateur = switch (agent) {
    final String a when a.contains('Edg/') => 'Edge',
    final String a when a.contains('OPR/') || a.contains('Opera') => 'Opera',
    final String a when a.contains('Firefox/') => 'Firefox',
    final String a when a.contains('Chrome/') || a.contains('CriOS/') =>
      'Chrome',
    final String a when a.contains('Safari/') => 'Safari',
    _ => 'Navigateur',
  };
  final String systeme = switch (agent) {
    final String a when a.contains('Android') => 'Android',
    final String a when a.contains('iPhone') || a.contains('iPad') => 'iOS',
    final String a when a.contains('Windows') => 'Windows',
    final String a when a.contains('Mac OS') || a.contains('Macintosh') =>
      'macOS',
    final String a when a.contains('CrOS') => 'ChromeOS',
    final String a when a.contains('Linux') => 'Linux',
    _ => '',
  };
  return systeme.isEmpty ? navigateur : '$navigateur · $systeme';
}
