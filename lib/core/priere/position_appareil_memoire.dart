import 'position_appareil_modele.dart';

export 'position_appareil_modele.dart';

/// Hors web : aucune geolocalisation disponible.
Future<PositionAppareil> lirePositionAppareil() =>
    Future<PositionAppareil>.error(const PositionNonPartagee());
