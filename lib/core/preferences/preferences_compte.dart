// PREFERENCES-PAR-COMPTE (directeur, 11/11/2026, relaye par le pilote) : le
// theme et la langue sont portes par le COMPTE, pas par l'appareil. Constat :
// regle sur un compte enseignant, le theme suivait sur le compte eleve du meme
// appareil.
//
// Ce fichier tient ce que la persistance des preferences
// (`preferences_locales.dart`) doit savoir du compte :
//
//   * qui est connecte ([compteDesPreferencesProvider]) ;
//   * le theme du compte au serveur ([PortThemeCompte], migration
//     20261123200000) ; la langue du compte est la langue de communication
//     (`PortLanguesCommunication`, migration 20261023140000), limitee ici au
//     francais et a l'arabe ;
//   * ce que la deconnexion efface sur l'appareil
//     ([oublierPreferencesDuCompte]).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';

/// Qui porte les preferences : le profil connecte, et si la session est
/// connue. Tant qu'elle ne l'est pas (`resolue` faux, au lancement), rien ne
/// change : l'appareil garde ce qu'il a lu avant la premiere image.
@immutable
class ComptePreferences {
  /// Cree la valeur.
  const ComptePreferences({required this.profil, required this.resolue});

  /// Le profil connecte, `null` sans personne.
  final String? profil;

  /// Vrai quand la session est connue (connectee ou non).
  final bool resolue;

  /// Vrai quand la session dit « personne n'est connecte ».
  bool get personne => resolue && profil == null;

  @override
  bool operator ==(Object other) =>
      other is ComptePreferences &&
      other.profil == profil &&
      other.resolue == resolue;

  @override
  int get hashCode => Object.hash(profil, resolue);
}

/// Le compte qui porte les preferences. Une session illisible (Supabase non
/// initialise, par exemple dans un test qui ne la surcharge pas) vaut
/// « inconnue » : rien ne change.
final Provider<ComptePreferences> compteDesPreferencesProvider =
    Provider<ComptePreferences>((Ref ref) {
      try {
        final SessionState s = ref.watch(sessionProvider);
        return ComptePreferences(profil: s.profileId, resolue: s.resolue);
      } on Object {
        return const ComptePreferences(profil: null, resolue: false);
      }
    });

/// Le theme du compte connecte (migration 20261123200000).
///
/// Les valeurs sont celles de `PreferenceTheme.name` : `systeme`, `clair`,
/// `sombre`.
abstract interface class PortThemeCompte {
  /// Le theme du compte (`ma_preference_theme`).
  Future<String> lire();

  /// Ecrit le theme du compte (`ma_preference_theme_regler`).
  Future<void> regler(String theme);
}

/// Tant qu'aucun adaptateur serveur n'est branche : le theme reste celui de
/// l'appareil pour ce compte.
class ThemeCompteIndisponible implements PortThemeCompte {
  /// Cree l'implementation.
  const ThemeCompteIndisponible();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'PREFERENCES-PAR-COMPTE',
  );

  @override
  Future<String> lire() => Future<String>.error(_absente);

  @override
  Future<void> regler(String theme) => Future<void>.error(_absente);
}

/// Le port du theme du compte.
final Provider<PortThemeCompte> portThemeCompteProvider =
    Provider<PortThemeCompte>((Ref ref) => const ThemeCompteIndisponible());
