/// R3 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) : le decoupage de N
/// demandes en classes, montre a la direction avant qu'elle confirme.
///
/// Avec N demandes, un minimum m et un maximum M (valeurs d'`app_config`,
/// jamais ecrites dans le client), le serveur cree ⌊N/M⌋ classes pleines. Le
/// reste devient une classe s'il atteint m ; sinon il attend dans le
/// regroupement. Une classe n'est jamais creee sous le minimum.
///
/// Fonction pure : elle ne decide rien, elle dit ce que le serveur fera.
/// Sans minimum rendu, le reste attend (aucun minimum n'est invente).
library;

import 'package:flutter/foundation.dart';

/// Le decoupage de N demandes en classes.
@immutable
class DecoupageClasses {
  /// Cree un decoupage.
  const DecoupageClasses({
    required this.pleines,
    required this.tailleMax,
    required this.derniere,
    required this.enAttente,
  });

  /// Le nombre de classes pleines.
  final int pleines;

  /// L'effectif d'une classe pleine (le maximum).
  final int tailleMax;

  /// L'effectif de la derniere classe quand le reste atteint le minimum.
  /// Nul : le reste n'ouvre pas de classe.
  final int? derniere;

  /// Le nombre d'eleves qui attendent dans le regroupement.
  final int enAttente;

  /// Le nombre de classes creees : les pleines et la derniere.
  int get classes => pleines + (derniere == null ? 0 : 1);

  @override
  bool operator ==(Object other) =>
      other is DecoupageClasses &&
      other.pleines == pleines &&
      other.tailleMax == tailleMax &&
      other.derniere == derniere &&
      other.enAttente == enAttente;

  @override
  int get hashCode => Object.hash(pleines, tailleMax, derniere, enAttente);
}

/// Decoupe [demandes] en classes de [maximum] eleves au plus. [minimum] nul :
/// le reste attend toujours.
DecoupageClasses decouperDemandes({
  required int demandes,
  required int maximum,
  int? minimum,
}) {
  if (maximum <= 0 || demandes <= 0) {
    return DecoupageClasses(
      pleines: 0,
      tailleMax: maximum < 0 ? 0 : maximum,
      derniere: null,
      enAttente: demandes < 0 ? 0 : demandes,
    );
  }
  final int pleines = demandes ~/ maximum;
  final int reste = demandes % maximum;
  final bool ouvre = reste > 0 && minimum != null && reste >= minimum;
  return DecoupageClasses(
    pleines: pleines,
    tailleMax: maximum,
    derniere: ouvre ? reste : null,
    enAttente: ouvre ? 0 : reste,
  );
}
