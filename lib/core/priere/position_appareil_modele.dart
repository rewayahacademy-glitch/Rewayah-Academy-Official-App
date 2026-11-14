import 'package:flutter/foundation.dart';

/// La position lue sur l'appareil, avec son fuseau IANA. Le serveur l'arrondit
/// au centieme de degre avant de l'ecrire : l'application n'en garde rien.
@immutable
class PositionAppareil {
  /// Cree une position.
  const PositionAppareil({
    required this.latitude,
    required this.longitude,
    required this.fuseau,
  });

  /// Latitude, en degres.
  final double latitude;

  /// Longitude, en degres.
  final double longitude;

  /// Le fuseau IANA de l'appareil (par exemple `Africa/Conakry`).
  final String fuseau;
}

/// La position n'a pas pu etre lue : refus, delai depasse, appareil sans
/// geolocalisation. L'ecran dit « Position non partagee » et propose de
/// reessayer ; il ne demande jamais de coordonnees.
class PositionNonPartagee implements Exception {
  /// Cree l'exception.
  const PositionNonPartagee();

  @override
  String toString() => 'PositionNonPartagee';
}
