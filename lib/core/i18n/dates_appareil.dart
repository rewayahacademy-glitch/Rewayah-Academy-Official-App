// La date et l'heure de l'appareil, en mots (`commun.dates`).
//
// Remontees de `features/accueil_famille/bloc_seance.dart` (qui les
// re-exporte) pour que le socle des communications (`core/communications`)
// les lise sans dependre d'une fonctionnalite (revue COM-R, R-07).

import 'strings.g.dart';

/// L'heure locale de l'appareil, « 13:45 ».
///
/// Seulement quand aucune heure n'est rendue par le serveur, et toujours
/// accompagnee du libelle « Heure de cet appareil » : ce n'est pas un fuseau
/// devine, c'est l'aveu de la source.
String heureDeLAppareil(DateTime local) =>
    '${local.hour.toString().padLeft(2, '0')}:'
    '${local.minute.toString().padLeft(2, '0')}';

/// La date locale de l'appareil, « Lundi 21 septembre », par les libelles
/// `commun.dates` (jamais une liste de noms en dur).
String dateDeLAppareil(DateTime local) => t.commun.dates.jourDate(
  jour: t.commun.dates.jours[local.weekday - 1],
  numero: local.day,
  mois: t.commun.dates.mois[local.month - 1],
);
