import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le choix local du theme. Il ne modifie aucune preference de profil distante.
enum PreferenceTheme {
  systeme,
  clair,
  sombre;

  /// La valeur attendue par [MaterialApp].
  ThemeMode get mode => switch (this) {
    PreferenceTheme.systeme => ThemeMode.system,
    PreferenceTheme.clair => ThemeMode.light,
    PreferenceTheme.sombre => ThemeMode.dark,
  };
}

/// Preferences de comportement conservees pendant la vie de l'application.
///
/// Le depot ne possede pas encore de stockage dedie aux preferences locales.
/// Ce modele reste donc volontairement en memoire : il rend le parcours
/// testable maintenant, sans faire croire qu'une ecriture distante a reussi.
@immutable
class PreferencesLocales {
  /// Cree les valeurs locales par defaut.
  const PreferencesLocales({
    this.theme = PreferenceTheme.systeme,
    this.animationsReduites = false,
    this.effetsReduits = false,
    this.notificationsCours = true,
    this.notificationsFoyer = true,
    this.economieDonnees = false,
    this.lectureGrande = false,
  });

  /// Theme d'affichage local.
  final PreferenceTheme theme;

  /// Desactive les transitions decoratives.
  final bool animationsReduites;

  /// Retire les ombres et filtres decoratifs.
  final bool effetsReduits;

  /// Notifications liees aux cours.
  final bool notificationsCours;

  /// Notifications liees au foyer.
  final bool notificationsFoyer;

  /// Preference de qualite media locale.
  final bool economieDonnees;

  /// Taille de lecture preferee, quand le moteur la supporte.
  final bool lectureGrande;

  /// Retourne une copie avec les valeurs modifiees.
  PreferencesLocales copyWith({
    PreferenceTheme? theme,
    bool? animationsReduites,
    bool? effetsReduits,
    bool? notificationsCours,
    bool? notificationsFoyer,
    bool? economieDonnees,
    bool? lectureGrande,
  }) => PreferencesLocales(
    theme: theme ?? this.theme,
    animationsReduites: animationsReduites ?? this.animationsReduites,
    effetsReduits: effetsReduits ?? this.effetsReduits,
    notificationsCours: notificationsCours ?? this.notificationsCours,
    notificationsFoyer: notificationsFoyer ?? this.notificationsFoyer,
    economieDonnees: economieDonnees ?? this.economieDonnees,
    lectureGrande: lectureGrande ?? this.lectureGrande,
  );
}

/// Controleur de preferences locales, sans mutation metier.
final NotifierProvider<PreferencesLocalesControleur, PreferencesLocales>
preferencesLocalesProvider =
    NotifierProvider<PreferencesLocalesControleur, PreferencesLocales>(
      PreferencesLocalesControleur.new,
    );

/// Porte les changements locaux de la page Reglages.
class PreferencesLocalesControleur extends Notifier<PreferencesLocales> {
  @override
  PreferencesLocales build() => const PreferencesLocales();

  /// Change le theme immediatement.
  void theme(PreferenceTheme valeur) => state = state.copyWith(theme: valeur);

  /// Change la reduction des animations.
  void animations(bool valeur) =>
      state = state.copyWith(animationsReduites: valeur);

  /// Change la reduction des effets.
  void effets(bool valeur) => state = state.copyWith(effetsReduits: valeur);

  /// Change l'abonnement local aux cours.
  void notificationsCours(bool valeur) =>
      state = state.copyWith(notificationsCours: valeur);

  /// Change l'abonnement local aux nouvelles du foyer.
  void notificationsFoyer(bool valeur) =>
      state = state.copyWith(notificationsFoyer: valeur);

  /// Active l'economie de donnees locale.
  void economieDonnees(bool valeur) =>
      state = state.copyWith(economieDonnees: valeur);

  /// Change la taille de lecture locale.
  void lectureGrande(bool valeur) =>
      state = state.copyWith(lectureGrande: valeur);
}
