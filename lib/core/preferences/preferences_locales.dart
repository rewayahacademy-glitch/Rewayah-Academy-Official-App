import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appairage/profils_locaux.dart' show baseLocaleProvider;
import '../cache/db/app_database.dart';

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

  /// La luminosite reellement affichee, [systeme] etant celle que le systeme
  /// d'exploitation demande (`MediaQuery.platformBrightnessOf`).
  ///
  /// C'est ce que reflete la bascule soleil / lune de l'en-tete : elle montre
  /// le theme affiche, meme quand le choix est « Systeme ».
  Brightness luminosite(Brightness systeme) => switch (this) {
    PreferenceTheme.systeme => systeme,
    PreferenceTheme.clair => Brightness.light,
    PreferenceTheme.sombre => Brightness.dark,
  };

  /// Relit une valeur persistee ; `null` si elle est absente ou inconnue.
  static PreferenceTheme? depuis(String? valeur) {
    for (final PreferenceTheme p in values) {
      if (p.name == valeur) {
        return p;
      }
    }
    return null;
  }
}

/// Preferences de comportement conservees pendant la vie de l'application.
///
/// Le theme est **persiste** sur l'appareil (voir [persistanceApparenceProvider]
/// et [StockagePreferences]) et **applique** par `RewayahApp`. Les autres
/// reglages restent en memoire : ils n'ont encore aucun consommateur hors de
/// la page Reglages.
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

/// Porte les changements locaux de la page Reglages et de la bascule de theme
/// de l'en-tete. **Une seule preference de theme** : les deux entrees ecrivent
/// ici, `RewayahApp` lit ici.
class PreferencesLocalesControleur extends Notifier<PreferencesLocales> {
  /// Vrai des qu'un choix de theme a ete fait pendant cette session : la
  /// lecture du stockage, qui peut arriver apres, ne l'ecrase jamais.
  bool _themeChoisi = false;

  @override
  PreferencesLocales build() => const PreferencesLocales();

  /// Change le theme immediatement (page Apparence : Systeme, Clair, Sombre).
  void theme(PreferenceTheme valeur) {
    _themeChoisi = true;
    state = state.copyWith(theme: valeur);
  }

  /// La bascule soleil / lune de l'en-tete : passe au theme oppose a celui
  /// qui est affiche ([affichee], voir [PreferenceTheme.luminosite]).
  ///
  /// Elle quitte donc « Systeme » pour un choix explicite ; « Systeme » se
  /// retrouve dans la page Apparence, qui ecrit la meme preference.
  void basculerClairSombre(Brightness affichee) => theme(
    affichee == Brightness.dark ? PreferenceTheme.clair : PreferenceTheme.sombre,
  );

  /// Restaure le theme persiste au lancement, sauf si un choix a deja ete fait
  /// entre-temps.
  void restaurerTheme(PreferenceTheme valeur) {
    if (_themeChoisi) {
      return;
    }
    state = state.copyWith(theme: valeur);
  }

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

/// Clef de la preference de theme dans le stockage local.
const String clefPreferenceTheme = 'apparence.theme';

/// Un stockage cle/valeur local, durable et **non sensible**.
///
/// Jamais un jeton ni un code : ceux-la passent par le coffre securise
/// (`StockageSecurise`).
abstract interface class StockagePreferences {
  /// La valeur de [clef], ou `null` si elle n'a jamais ete ecrite.
  Future<String?> lire(String clef);

  /// Ecrit [valeur] sous [clef], en remplacant l'ancienne.
  Future<void> ecrire(String clef, String valeur);
}

/// Le stockage sur la table cle/valeur `PreferenceLocale` de la base locale
/// Drift : le seul stockage non sensible du depot, ouvert a « tout agent qui
/// a besoin d'une preference d'affichage durable » (`app_database.dart`).
class StockagePreferencesDrift implements StockagePreferences {
  /// Cree le stockage sur la base locale.
  const StockagePreferencesDrift(this._base);

  final AppDatabase _base;

  @override
  Future<String?> lire(String clef) async {
    final PreferenceLocaleData? ligne =
        await (_base.select(_base.preferenceLocale)..where(
              ($PreferenceLocaleTable p) => p.clef.equals(clef),
            ))
            .getSingleOrNull();
    return ligne?.valeur;
  }

  @override
  Future<void> ecrire(String clef, String valeur) async {
    await _base
        .into(_base.preferenceLocale)
        .insertOnConflictUpdate(
          PreferenceLocaleCompanion.insert(clef: clef, valeur: valeur),
        );
  }
}

/// Le stockage en memoire, pour la vie de l'application seulement.
///
/// Sert aux tests et au web : `AppDatabase` ouvre `driftDatabase` sans
/// options web, ce qui leve une erreur des la construction dans un
/// navigateur. Tant que la base locale n'est pas configuree pour le web, le
/// theme choisi y vit le temps de la session.
class StockagePreferencesMemoire implements StockagePreferences {
  /// Cree le stockage, avec des valeurs de depart facultatives.
  StockagePreferencesMemoire([Map<String, String>? valeurs])
    : valeurs = <String, String>{...?valeurs};

  /// Les valeurs ecrites.
  final Map<String, String> valeurs;

  @override
  Future<String?> lire(String clef) async => valeurs[clef];

  @override
  Future<void> ecrire(String clef, String valeur) async {
    valeurs[clef] = valeur;
  }
}

/// Le stockage des preferences d'affichage de cet appareil.
final Provider<StockagePreferences> stockagePreferencesProvider =
    Provider<StockagePreferences>(
      (Ref ref) => kIsWeb
          ? StockagePreferencesMemoire()
          : StockagePreferencesDrift(ref.watch(baseLocaleProvider)),
    );

/// Relie la preference de theme a son stockage : une lecture au montage, une
/// ecriture a chaque changement.
///
/// **Monte par `RewayahApp` seulement** : un ecran teste seul, ou la page
/// Reglages montee dans un test, ne touche jamais la base locale. Une panne
/// du stockage ne casse rien : la preference reste en memoire pour la
/// session.
final Provider<void> persistanceApparenceProvider = Provider<void>((Ref ref) {
  final StockagePreferences stockage = ref.watch(stockagePreferencesProvider);
  final PreferencesLocalesControleur controleur = ref.read(
    preferencesLocalesProvider.notifier,
  );

  Future<void> restaurer() async {
    try {
      final PreferenceTheme? lu = PreferenceTheme.depuis(
        await stockage.lire(clefPreferenceTheme),
      );
      if (lu != null && ref.mounted) {
        controleur.restaurerTheme(lu);
      }
    } on Object catch (erreur) {
      debugPrint('Preference de theme illisible, reste en memoire : $erreur');
    }
  }

  Future<void> ecrire(PreferenceTheme valeur) async {
    try {
      await stockage.ecrire(clefPreferenceTheme, valeur.name);
    } on Object catch (erreur) {
      debugPrint('Preference de theme non ecrite, reste en memoire : $erreur');
    }
  }

  unawaited(restaurer());
  ref.listen<PreferenceTheme>(
    preferencesLocalesProvider.select((PreferencesLocales p) => p.theme),
    (PreferenceTheme? avant, PreferenceTheme apres) {
      if (avant != apres) {
        unawaited(ecrire(apres));
      }
    },
  );
});

/// Le mode de theme a donner a `MaterialApp`, tire de la preference.
final Provider<ThemeMode> modeThemeProvider = Provider<ThemeMode>(
  (Ref ref) => ref.watch(
    preferencesLocalesProvider.select((PreferencesLocales p) => p.theme.mode),
  ),
);
