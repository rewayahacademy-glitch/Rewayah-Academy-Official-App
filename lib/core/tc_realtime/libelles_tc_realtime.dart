/// La facade de libelles du lot F, en attendant slang.
///
/// **Mecanisme impose par la decision D-03.** Neuf agents paralleles et un seul
/// `assets/i18n/fr.i18n.json` : chaque libelle vit ici, annote de la clef qu'il
/// prendra, et la meme liste est deposee dans
/// `docs/teaching-core/i18n/tc_i18n_F.json`. **Agent Z** fusionne, regenere,
/// remplace ces constantes par `t.tc.realtime.*` et supprime ce fichier.
///
/// **Il n'y en a que deux, et c'est normal : le lot F n'a pas d'interface.**
/// Ces deux phrases existent parce que seul le protocole sait qu'il est
/// degrade, et parce que deux ecrans qui inventeraient la meme phrase
/// finiraient par en dire deux versions differentes. Agent E les affiche dans
/// la coque de Classe Live.
///
/// **Aucune phrase de reussite.** Une presentation qui arrive est visible : une
/// reussite visuellement evidente ne declenche aucune notification. Seuls les
/// echecs sont explicites, et ces deux libelles en sont.
///
/// Les libelles portent leurs accents : ce sont des textes lus par des
/// utilisateurs, pas des commentaires de code.
library;

/// Les deux etats de protocole qu'une Classe Live doit pouvoir dire.
abstract final class LibellesRealtime {
  /// TC-I18N: cle=tc.realtime.transport.partage_indisponible
  ///
  /// Affiche quand `PortTransportDonnees.disponibilite` ne vaut pas `complet` :
  /// le cours a lieu, la voix et l'image passent, mais le support presente ne
  /// suit pas les autres appareils. **Le dire plutot que de laisser
  /// l'enseignant tourner des pages que personne ne voit.**
  static const String partageIndisponible =
      'Le partage du support n’est pas disponible sur ce serveur. '
      'Le cours continue, mais les autres appareils ne suivront pas la page.';

  /// TC-I18N: cle=tc.realtime.etat.restauration_impossible
  ///
  /// Affiche quand `PortEtatPartage.restaurer` echoue a l'arrivee ou apres une
  /// reconnexion. **Distinct de « rien n'est presente »** : ne pas savoir n'est
  /// pas la meme chose que savoir qu'il n'y a rien.
  static const String restaurationImpossible =
      'Impossible de retrouver le support en cours. '
      'Demandez à l’enseignant de le présenter à nouveau.';
}
