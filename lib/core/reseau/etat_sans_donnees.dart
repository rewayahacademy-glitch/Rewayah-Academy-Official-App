import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import '../widgets/etat_systeme.dart';

// Hors ligne se dit UNE fois (EA-HL-DOUBLE-1, decision du 04/10 deleguee par
// le directeur, K-42) : le bandeau de `PageShell` est LE signal. Une page
// n'ajoute un bloc que si elle ne peut rien afficher, et ce bloc dit ce qui
// manque, jamais « hors ligne » ni « pas de reseau »
// (`docs/current/03_DESIGN_SYSTEM_ET_UX.md`, section « Etats »).

/// Hors ligne, une lecture en echec qui garde sa derniere valeur se montre
/// telle quelle : ce qui est deja la reste consultable, et le bandeau dit
/// deja pourquoi rien ne se met a jour. En ligne, ou sans valeur, la lecture
/// est rendue intacte.
AsyncValue<T> lectureHorsLigne<T>(
  AsyncValue<T> lecture, {
  required bool horsLigne,
}) => horsLigne && lecture.hasError && lecture.hasValue
    ? AsyncData<T>(lecture.requireValue)
    : lecture;

/// Vrai quand une lecture ne peut rien afficher a cause du reseau : hors
/// ligne, en echec, sans valeur deja lue. Une capacite absente reste dite
/// indisponible, reseau ou non.
bool sansDonneesHorsLigne(
  AsyncValue<Object?> lecture, {
  required bool horsLigne,
}) =>
    horsLigne &&
    lecture.hasError &&
    !lecture.hasValue &&
    lecture.error is! CapaciteIndisponible;

/// Le bloc d'une page hors ligne qui ne peut rien afficher : il dit ce qui
/// manque ([quoi]) et propose de relire, sans redire l'absence de reseau que
/// le bandeau de `PageShell` porte deja.
///
/// La nature reste [NatureEtat.horsLigne] : son icone et son ton
/// d'avertissement, pas ceux d'un echec du serveur, qui n'a rien refuse.
class EtatSansDonnees extends StatelessWidget {
  /// Cree le bloc.
  const EtatSansDonnees({required this.quoi, super.key, this.onAction});

  /// Ce qui manque, en une phrase (« Votre classe n'a pas pu etre chargee »).
  final String quoi;

  /// Relit ce qui manque. Sans lui, aucun bouton n'est rendu.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => EtatSysteme(
    nature: NatureEtat.horsLigne,
    titre: quoi,
    // Phrase vide : le bandeau dit deja le reste.
    phrase: '',
    onAction: onAction,
  );
}
