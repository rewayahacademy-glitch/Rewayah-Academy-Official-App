import 'preferences_locales.dart';

/// Hors navigateur : le stockage en memoire, le temps de la session.
///
/// Jamais choisi en production hors web (voir `stockagePresentationProvider`) ;
/// il existe pour que le meme nom compile sur toutes les plateformes.
class StockagePreferencesNavigateur extends StockagePreferencesMemoire {
  /// Cree le stockage.
  StockagePreferencesNavigateur();
}
