// L'accent d'un profil eleve (decision du directeur du 04/10/2026, K-62 ;
// guide Finance V4 §3).
//
// Une couleur douce par profil, **choisie par le tuteur** dans les reglages
// du profil. Elle sert a distinguer d'un coup d'oeil les profils d'un meme
// foyer : jamais un statut, un niveau, une alerte ni une couleur de classe
// (les classes gardent `AppPalette.teintesIdentite`). Elle est toujours posee
// a cote d'un prenom, jamais a sa place.
//
// La cle [name] est ce que la source stocke (FI-BR-19) : jamais une couleur
// libre. Les valeurs vivent dans `AppPalette.accentsProfil`.

/// Les accents de profil, dans l'ordre ou le tuteur les voit.
enum AccentProfil {
  /// Vert d'eau.
  menthe,

  /// Bleu clair.
  ciel,

  /// Violet doux.
  lavande,

  /// Rose.
  rose,

  /// Orange doux.
  peche,

  /// Beige dore.
  sable;

  /// L'accent de la cle [cle] rendue par une source, `null` pour une cle
  /// inconnue ou absente (aucun bandeau, jamais une couleur au hasard).
  static AccentProfil? depuisCle(String? cle) {
    for (final AccentProfil a in values) {
      if (a.name == cle) return a;
    }
    return null;
  }
}
