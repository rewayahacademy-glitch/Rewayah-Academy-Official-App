import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderListenable` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../features/inscription/questionnaire/memoire_appareil.dart';
import '../appairage/profils_locaux.dart' show baseLocaleProvider;
import '../cache/db/app_database.dart';
import '../capacites/port_langues_communication.dart';
import '../i18n/langue_demarrage.dart';
import '../i18n/strings.g.dart';
import '../observabilite/journal_dev.dart';
import '../theme/polices_differees.dart' show chargerPoliceArabe;
import 'preferences_compte.dart';

/// Le choix du theme. Porte par le compte (PREFERENCES-PAR-COMPTE, 11/11/2026) :
/// garde au serveur et dans le cache de ce compte sur l'appareil
/// ([persistanceApparenceProvider]).
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

/// Le choix local de la langue de l'application (lot 22 a, PREFERENCES-WEB).
///
/// « Systeme » suit la langue de l'appareil ([appliquerLangueDeLAppareil]) ;
/// un autre choix impose sa langue sur cet appareil, garde d'une session a
/// l'autre par le meme stockage que le theme.
enum PreferenceLangue {
  systeme,
  francais,
  arabe;

  /// La langue imposee, ou `null` pour suivre l'appareil.
  AppLocale? get langue => switch (this) {
    PreferenceLangue.systeme => null,
    PreferenceLangue.francais => AppLocale.fr,
    PreferenceLangue.arabe => AppLocale.ar,
  };

  /// Relit une valeur persistee ; `null` si elle est absente ou inconnue.
  static PreferenceLangue? depuis(String? valeur) {
    for (final PreferenceLangue p in values) {
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
    this.langue = PreferenceLangue.systeme,
    this.animationsReduites = false,
    this.effetsReduits = false,
    this.notificationsCours = true,
    this.notificationsFoyer = true,
    this.economieDonnees = false,
    this.lectureGrande = false,
    this.raccourcisSalle = true,
  });

  /// Theme d'affichage local.
  final PreferenceTheme theme;

  /// Langue de l'application sur cet appareil.
  final PreferenceLangue langue;

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

  /// Les raccourcis clavier de la salle sur ordinateur (E19, EN-KB) : M, V,
  /// R, B. Desactivables ici (WCAG 2.1.4). Persiste sur l'appareil par
  /// [persistanceRaccourcisProvider].
  final bool raccourcisSalle;

  /// Retourne une copie avec les valeurs modifiees.
  PreferencesLocales copyWith({
    PreferenceTheme? theme,
    PreferenceLangue? langue,
    bool? animationsReduites,
    bool? effetsReduits,
    bool? notificationsCours,
    bool? notificationsFoyer,
    bool? economieDonnees,
    bool? lectureGrande,
    bool? raccourcisSalle,
  }) => PreferencesLocales(
    theme: theme ?? this.theme,
    langue: langue ?? this.langue,
    animationsReduites: animationsReduites ?? this.animationsReduites,
    effetsReduits: effetsReduits ?? this.effetsReduits,
    notificationsCours: notificationsCours ?? this.notificationsCours,
    notificationsFoyer: notificationsFoyer ?? this.notificationsFoyer,
    economieDonnees: economieDonnees ?? this.economieDonnees,
    lectureGrande: lectureGrande ?? this.lectureGrande,
    raccourcisSalle: raccourcisSalle ?? this.raccourcisSalle,
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

  /// Vrai des qu'un choix de raccourcis a ete fait pendant cette session.
  bool _raccourcisChoisis = false;

  /// Vrai des qu'un choix de langue a ete fait pendant cette session.
  bool _langueChoisie = false;

  /// SOMBRE-SANS-ECLAIR (directeur, 11/11/2026) : le theme choisi est connu
  /// **avant la premiere image**. Sur le web, le stockage du navigateur se lit
  /// sans attendre ([lecturePreferencesImmediateProvider]) : le controleur part
  /// du theme persiste. Hors web, il part de « Systeme », puis
  /// [persistanceApparenceProvider] le restaure. Sans cela, chaque chargement
  /// de page peignait ses premieres images en clair avant de basculer.
  @override
  PreferencesLocales build() {
    final PreferenceTheme? memorise = _themeImmediat(
      ref.read(lecturePreferencesImmediateProvider),
    );
    return memorise == null
        ? const PreferencesLocales()
        : PreferencesLocales(theme: memorise);
  }

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
    affichee == Brightness.dark
        ? PreferenceTheme.clair
        : PreferenceTheme.sombre,
  );

  /// Restaure le theme persiste au lancement, sauf si un choix a deja ete fait
  /// entre-temps.
  void restaurerTheme(PreferenceTheme valeur) {
    if (_themeChoisi) {
      return;
    }
    state = state.copyWith(theme: valeur);
  }

  /// Vrai quand le theme a ete choisi par la personne depuis le dernier
  /// changement de compte.
  bool get themeChoisi => _themeChoisi;

  /// Vrai quand la langue a ete choisie par la personne depuis le dernier
  /// changement de compte.
  bool get langueChoisie => _langueChoisie;

  /// Un autre compte arrive : ses reglages remplaceront le theme affiche.
  void oublierChoixTheme() => _themeChoisi = false;

  /// Un autre compte arrive : ses reglages remplaceront la langue affichee.
  void oublierChoixLangue() => _langueChoisie = false;

  /// Change la langue (Reglages : Systeme, Francais, Arabe). L'application
  /// la prend tout de suite ([persistanceLangueProvider]).
  void langue(PreferenceLangue valeur) {
    _langueChoisie = true;
    state = state.copyWith(langue: valeur);
  }

  /// Restaure la langue persistee au lancement, sauf si un choix a deja ete
  /// fait entre-temps.
  void restaurerLangue(PreferenceLangue valeur) {
    if (_langueChoisie) {
      return;
    }
    state = state.copyWith(langue: valeur);
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

  /// Active ou desactive les raccourcis clavier de la salle (E19).
  void raccourcisSalle(bool valeur) {
    _raccourcisChoisis = true;
    state = state.copyWith(raccourcisSalle: valeur);
  }

  /// Restaure le choix persiste au lancement, sauf si un choix a deja ete
  /// fait entre-temps.
  void restaurerRaccourcisSalle({required bool actifs}) {
    if (_raccourcisChoisis) {
      return;
    }
    state = state.copyWith(raccourcisSalle: actifs);
  }
}

/// Le theme persiste, lu sans attendre quand [lecture] existe ; `null` sinon,
/// ou si la lecture echoue (la preference reste « Systeme »).
PreferenceTheme? _themeImmediat(LecturePreferencesImmediate? lecture) {
  if (lecture == null) {
    return null;
  }
  try {
    return PreferenceTheme.depuis(
      lirePreferenceImmediate(lecture, clefPreferenceTheme),
    );
  } on Object {
    return null;
  }
}

/// Un stockage qui se lit sans attendre : le navigateur (`localStorage`) et
/// la memoire des tests. Il permet de connaitre une preference d'affichage
/// avant la premiere image (SOMBRE-SANS-ECLAIR).
abstract interface class LecturePreferencesImmediate {
  /// La valeur de [clef], lue sans attendre, ou `null`.
  String? lireImmediat(String clef);
}

/// Le stockage lisible sans attendre de cet appareil : le navigateur sur le
/// web ; aucun ailleurs (la base locale se lit en asynchrone). Les tests le
/// surchargent par [StockagePreferencesMemoire].
final Provider<LecturePreferencesImmediate?>
lecturePreferencesImmediateProvider = Provider<LecturePreferencesImmediate?>(
  (Ref _) => kIsWeb ? const StockagePreferencesNavigateur() : null,
);

/// Clef de la preference de theme dans le stockage local.
const String clefPreferenceTheme = 'apparence.theme';

/// Clef de la preference de langue dans le stockage local.
const String clefPreferenceLangue = 'apparence.langue';

/// Clef du pointeur vers le dernier compte connecte sur cet appareil
/// (PREFERENCES-PAR-COMPTE) : son identifiant de profil, vide apres une
/// deconnexion. Le script d'`index.html` le lit avant Flutter.
const String clefPointeurCompte = 'compte.dernier';

/// La clef de [clef] pour le compte [profil] (`apparence.theme.<profil>`) ;
/// la clef de l'appareil, sans compte.
String clefDuCompte(String clef, String? profil) =>
    profil == null || profil.isEmpty ? clef : '$clef.$profil';

/// La valeur de [clef] avant que la session soit connue : celle du dernier
/// compte connecte (par le pointeur), sinon celle de l'appareil. Meme ordre
/// que le script d'`index.html`.
String? lirePreferenceImmediate(
  LecturePreferencesImmediate lecture,
  String clef,
) {
  final String? pointeur = lecture.lireImmediat(clefPointeurCompte);
  if (pointeur != null && pointeur.isNotEmpty) {
    final String? duCompte = lecture.lireImmediat(clefDuCompte(clef, pointeur));
    if (duCompte != null) return duCompte;
  }
  return lecture.lireImmediat(clef);
}

/// [lirePreferenceImmediate], sur un stockage qui se lit en asynchrone.
Future<String?> lirePreferenceAuLancement(
  StockagePreferences stockage,
  String clef,
) async {
  final String? pointeur = await stockage.lire(clefPointeurCompte);
  if (pointeur != null && pointeur.isNotEmpty) {
    final String? duCompte = await stockage.lire(clefDuCompte(clef, pointeur));
    if (duCompte != null) return duCompte;
  }
  return stockage.lire(clef);
}

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
        await (_base.select(_base.preferenceLocale)
              ..where(($PreferenceLocaleTable p) => p.clef.equals(clef)))
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

/// Le stockage en memoire, pour la vie de l'application seulement (tests).
class StockagePreferencesMemoire
    implements StockagePreferences, LecturePreferencesImmediate {
  /// Cree le stockage, avec des valeurs de depart facultatives.
  StockagePreferencesMemoire([Map<String, String>? valeurs])
    : valeurs = <String, String>{...?valeurs};

  /// Les valeurs ecrites.
  final Map<String, String> valeurs;

  @override
  Future<String?> lire(String clef) async => valeurs[clef];

  @override
  String? lireImmediat(String clef) => valeurs[clef];

  @override
  Future<void> ecrire(String clef, String valeur) async {
    valeurs[clef] = valeur;
  }
}

/// Le stockage du navigateur (`localStorage`), sur le web.
///
/// `AppDatabase` ouvre `driftDatabase` sans options web, ce qui leve une
/// erreur des la construction dans un navigateur : le web garde donc ses
/// preferences dans la memoire de l'appareil deja utilisee par l'inscription
/// (`memoire_appareil`, aucune dependance nouvelle). Jamais rien de sensible.
/// Hors web, ces fonctions ne sont qu'une memoire de session : seul le web
/// prend ce stockage.
class StockagePreferencesNavigateur
    implements StockagePreferences, LecturePreferencesImmediate {
  /// Cree le stockage.
  const StockagePreferencesNavigateur();

  /// Prefixe des clefs, pour ne croiser aucune autre clef du navigateur.
  static const String prefixe = 'rewayah.preferences.';

  @override
  Future<String?> lire(String clef) async =>
      lireMemoireAppareil('$prefixe$clef');

  @override
  String? lireImmediat(String clef) => lireMemoireAppareil('$prefixe$clef');

  @override
  Future<void> ecrire(String clef, String valeur) async =>
      ecrireMemoireAppareil('$prefixe$clef', valeur);
}

/// Le stockage des preferences d'affichage de cet appareil : le navigateur
/// sur le web (lot 22 a : avant, une memoire perdue a chaque rechargement),
/// la base locale ailleurs.
final Provider<StockagePreferences> stockagePreferencesProvider =
    Provider<StockagePreferences>(
      (Ref ref) => kIsWeb
          ? const StockagePreferencesNavigateur()
          : StockagePreferencesDrift(ref.watch(baseLocaleProvider)),
    );

/// La langue choisie sur cet appareil, lue **avant le premier ecran**
/// (`main`) : sur le web, le stockage du navigateur se lit sans attendre.
/// Hors web, `null` ici ; [persistanceLangueProvider] la restaure ensuite.
PreferenceLangue? langueMemoriseeAuDemarrage() => kIsWeb
    ? PreferenceLangue.depuis(
        lirePreferenceImmediate(
          const StockagePreferencesNavigateur(),
          clefPreferenceLangue,
        ),
      )
    : null;

/// Applique [choix] : sa langue s'il en impose une, sinon celle de
/// l'appareil. Ne leve jamais.
///
/// En arabe, la police arabe d'interface est chargee a ce moment-la, en
/// arriere-plan ([chargerPoliceArabe]) : jamais en francais (regle du
/// directeur du 05/11).
Future<AppLocale> appliquerPreferenceLangue(PreferenceLangue? choix) async {
  final AppLocale langue = await _appliquerLangue(choix?.langue);
  if (langue == AppLocale.ar) {
    unawaited(chargerPoliceArabe());
  }
  return langue;
}

Future<AppLocale> _appliquerLangue(AppLocale? imposee) async {
  if (imposee == null) {
    return appliquerLangueDeLAppareil();
  }
  try {
    await LocaleSettings.setLocale(imposee);
    return imposee;
  } on Object catch (erreur) {
    journalDev('Langue $imposee non chargee, langue de l appareil : $erreur');
    return appliquerLangueDeLAppareil();
  }
}

/// Relie une preference d'affichage (theme ou langue) a son stockage **par
/// compte** et au serveur (PREFERENCES-PAR-COMPTE, directeur, 11/11/2026).
///
/// * Au lancement, tant que la session n'est pas connue, la valeur vient du
///   dernier compte connecte sur cet appareil ([lirePreferenceAuLancement]).
/// * A la connexion d'un compte : son cache sur l'appareil, puis sa valeur au
///   serveur, qui fait foi. Rien du compte precedent ne passe.
/// * Sans personne connectee apres un compte (deconnexion, session expiree) :
///   retour au defaut de l'appareil (« Systeme »), jamais aux reglages du
///   compte sorti. Sans compte avant, le choix fait sur l'appareil reste.
/// * Un choix de la personne est ecrit dans le cache de son compte, et au
///   serveur quand elle est connectee. Un reglage repris du cache ou du
///   serveur n'est jamais renvoye au serveur.
///
/// Une panne du stockage ou du serveur ne casse rien : elle est journalisee
/// et la preference reste en memoire.
void _persisterParCompte<T extends Enum>({
  required Ref ref,
  required String clef,
  required String nom,
  required T? Function(String? valeur) depuis,
  required T parDefaut,
  required ProviderListenable<T> selection,
  required void Function(T valeur) restaurer,
  required void Function() oublierChoix,
  required bool Function() choisi,
  required Future<T?> Function() lireServeur,
  required Future<void> Function(T valeur) ecrireServeur,
  void Function(T valeur)? appliquer,
}) {
  final StockagePreferences stockage = ref.watch(stockagePreferencesProvider);
  final ComptePreferences auMontage = ref.read(compteDesPreferencesProvider);
  String? profil = auMontage.profil;
  bool connu = auMontage.resolue;
  // Chaque changement de compte ouvre une generation : une lecture lente
  // d'un compte precedent n'est jamais appliquee au suivant.
  int generation = 0;

  Future<String?> lire(String c) async {
    try {
      return await stockage.lire(c);
    } on Object catch (erreur) {
      journalDev('Preference $nom illisible, reste en memoire : $erreur');
      return null;
    }
  }

  Future<void> ecrire(String c, String valeur) async {
    try {
      await stockage.ecrire(c, valeur);
    } on Object catch (erreur) {
      journalDev('Preference $nom non ecrite, reste en memoire : $erreur');
    }
  }

  void appliquerSiCourant(int g, T? valeur) {
    if (valeur != null && ref.mounted && g == generation) {
      restaurer(valeur);
    }
  }

  Future<void> adopterServeur(int g) async {
    try {
      appliquerSiCourant(g, await lireServeur());
    } on Object catch (erreur) {
      journalDev('Preference $nom du compte non lue au serveur : $erreur');
    }
  }

  Future<void> passerAuCompte(String? nouveau) async {
    final int g = ++generation;
    final String? ancien = profil;
    profil = nouveau;
    if (nouveau != null) {
      oublierChoix();
      await ecrire(clefPointeurCompte, nouveau);
      appliquerSiCourant(
        g,
        depuis(await lire(clefDuCompte(clef, nouveau))) ?? parDefaut,
      );
      await adopterServeur(g);
      return;
    }
    final String? pointeur = await lire(clefPointeurCompte);
    if (g != generation || !ref.mounted) {
      return;
    }
    if (ancien == null && (pointeur == null || pointeur.isEmpty)) {
      // Aucun compte avant : le choix fait sur cet appareil reste.
      appliquerSiCourant(g, depuis(await lire(clef)));
      return;
    }
    oublierChoix();
    restaurer(parDefaut);
    await ecrire(clef, parDefaut.name);
    await ecrire(clefPointeurCompte, '');
  }

  Future<void> lancement() async {
    final int g = generation;
    try {
      appliquerSiCourant(
        g,
        depuis(await lirePreferenceAuLancement(stockage, clef)),
      );
    } on Object catch (erreur) {
      journalDev('Preference $nom illisible, reste en memoire : $erreur');
    }
  }

  unawaited(connu ? passerAuCompte(profil) : lancement());

  ref.listen<ComptePreferences>(compteDesPreferencesProvider, (
    ComptePreferences? _,
    ComptePreferences apres,
  ) {
    if (!apres.resolue || (connu && apres.profil == profil)) {
      return;
    }
    connu = true;
    unawaited(passerAuCompte(apres.profil));
  });

  ref.listen<T>(selection, (T? avant, T apres) {
    if (avant == apres) {
      return;
    }
    unawaited(ecrire(clefDuCompte(clef, profil), apres.name));
    appliquer?.call(apres);
    if (profil != null && choisi()) {
      unawaited(() async {
        try {
          await ecrireServeur(apres);
        } on Object catch (erreur) {
          journalDev(
            'Preference $nom du compte non ecrite au serveur : $erreur',
          );
        }
      }());
    }
  });
}

/// La langue du compte au serveur : la langue de communication, quand elle
/// est le francais ou l'arabe (les deux langues de l'application) ; `null`
/// sinon, et le cache du compte reste.
PreferenceLangue? langueDuCompte(String? code) => switch (code) {
  'fr' => PreferenceLangue.francais,
  'ar' => PreferenceLangue.arabe,
  _ => null,
};

/// Relie la preference de langue a son stockage par compte, au serveur et a
/// l'application : a chaque changement, une ecriture et la langue appliquee
/// (`LocaleSettings`, que `TranslationProvider` fait redessiner).
///
/// Au serveur, la langue du compte est sa langue de communication
/// (`ma_langue_communication_regler`) : « Francais » ecrit `fr`, « Arabe »
/// ecrit `ar`. « Systeme » n'a pas de valeur au serveur : il reste dans le
/// cache du compte sur cet appareil.
/// **Monte par `RewayahApp` seulement**, comme [persistanceApparenceProvider].
final Provider<void> persistanceLangueProvider = Provider<void>((Ref ref) {
  final PreferencesLocalesControleur controleur = ref.read(
    preferencesLocalesProvider.notifier,
  );
  _persisterParCompte<PreferenceLangue>(
    ref: ref,
    clef: clefPreferenceLangue,
    nom: 'de langue',
    depuis: PreferenceLangue.depuis,
    parDefaut: PreferenceLangue.systeme,
    selection: preferencesLocalesProvider.select(
      (PreferencesLocales p) => p.langue,
    ),
    restaurer: controleur.restaurerLangue,
    oublierChoix: controleur.oublierChoixLangue,
    choisi: () => controleur.langueChoisie,
    lireServeur: () async => langueDuCompte(
      await ref.read(portLanguesCommunicationProvider).maLangue(),
    ),
    ecrireServeur: (PreferenceLangue valeur) async {
      final String? code = switch (valeur) {
        PreferenceLangue.francais => 'fr',
        PreferenceLangue.arabe => 'ar',
        PreferenceLangue.systeme => null,
      };
      if (code != null) {
        await ref.read(portLanguesCommunicationProvider).regler(code);
      }
    },
    appliquer: (PreferenceLangue valeur) =>
        unawaited(appliquerPreferenceLangue(valeur)),
  );
});

/// Relie la preference de theme a son stockage par compte et au serveur
/// (`ma_preference_theme`, `ma_preference_theme_regler`).
///
/// **Monte par `RewayahApp` seulement** : un ecran teste seul, ou la page
/// Reglages montee dans un test, ne touche jamais la base locale. Une panne
/// du stockage ne casse rien : la preference reste en memoire pour la
/// session.
final Provider<void> persistanceApparenceProvider = Provider<void>((Ref ref) {
  final PreferencesLocalesControleur controleur = ref.read(
    preferencesLocalesProvider.notifier,
  );
  _persisterParCompte<PreferenceTheme>(
    ref: ref,
    clef: clefPreferenceTheme,
    nom: 'de theme',
    depuis: PreferenceTheme.depuis,
    parDefaut: PreferenceTheme.systeme,
    selection: preferencesLocalesProvider.select(
      (PreferencesLocales p) => p.theme,
    ),
    restaurer: controleur.restaurerTheme,
    oublierChoix: controleur.oublierChoixTheme,
    choisi: () => controleur.themeChoisi,
    lireServeur: () async =>
        PreferenceTheme.depuis(await ref.read(portThemeCompteProvider).lire()),
    ecrireServeur: (PreferenceTheme valeur) =>
        ref.read(portThemeCompteProvider).regler(valeur.name),
  );
});

/// Ce que la deconnexion efface sur l'appareil (PREFERENCES-PAR-COMPTE) : le
/// pointeur vers le dernier compte, et le theme et la langue de l'appareil
/// remis a « Systeme » ; la langue de l'appareil est appliquee tout de suite.
/// Le cache de chaque compte reste : il sert a son prochain retour. Ne leve
/// jamais.
Future<void> oublierPreferencesDuCompte(StockagePreferences stockage) async {
  try {
    await stockage.ecrire(clefPointeurCompte, '');
    await stockage.ecrire(clefPreferenceTheme, PreferenceTheme.systeme.name);
    await stockage.ecrire(clefPreferenceLangue, PreferenceLangue.systeme.name);
  } on Object catch (erreur) {
    journalDev('Preferences du compte non oubliees : $erreur');
  }
  await appliquerPreferenceLangue(PreferenceLangue.systeme);
}

/// Le mode de theme a donner a `MaterialApp`, tire de la preference.
final Provider<ThemeMode> modeThemeProvider = Provider<ThemeMode>(
  (Ref ref) => ref.watch(
    preferencesLocalesProvider.select((PreferencesLocales p) => p.theme.mode),
  ),
);

/// Clef de la preference de repli de la navigation laterale.
const String clefNavigationRepliee = 'navigation.repliee';

/// Le choix de repli de la navigation laterale **sur cet appareil**
/// (manifeste visuel Tuteur V1, section 4.2 point 4).
///
/// `null` suit la largeur : rail replie sur tablette, barre laterale depliee
/// sur bureau. `true` ou `false` est le choix du bouton de repli, garde tant
/// que l'appareil n'en fait pas un autre. Sur telephone, il n'a aucun effet :
/// la navigation y est une barre basse.
final NotifierProvider<NavigationReplieeControleur, bool?>
navigationReplieeProvider =
    NotifierProvider<NavigationReplieeControleur, bool?>(
      NavigationReplieeControleur.new,
    );

/// Porte le choix du bouton de repli.
class NavigationReplieeControleur extends Notifier<bool?> {
  /// Vrai des qu'un choix a ete fait pendant cette session : la lecture du
  /// stockage, qui peut arriver apres, ne l'ecrase jamais.
  bool _choisi = false;

  @override
  bool? build() => null;

  /// Replie (`true`) ou deplie (`false`) la navigation laterale.
  void choisir({required bool repliee}) {
    _choisi = true;
    state = repliee;
  }

  /// Restaure le choix persiste au lancement, sauf si un choix a deja ete
  /// fait entre-temps.
  void restaurer({required bool repliee}) {
    if (_choisi) {
      return;
    }
    state = repliee;
  }
}

/// Relie le choix de repli a son stockage, comme [persistanceApparenceProvider]
/// le fait pour le theme : une lecture au montage, une ecriture a chaque
/// changement. **Monte par `RewayahApp` seulement.**
final Provider<void> persistanceNavigationProvider = Provider<void>((Ref ref) {
  final StockagePreferences stockage = ref.watch(stockagePreferencesProvider);
  final NavigationReplieeControleur controleur = ref.read(
    navigationReplieeProvider.notifier,
  );

  Future<void> restaurer() async {
    try {
      final String? lu = await stockage.lire(clefNavigationRepliee);
      if (ref.mounted && (lu == 'true' || lu == 'false')) {
        controleur.restaurer(repliee: lu == 'true');
      }
    } on Object catch (erreur) {
      journalDev('Repli de navigation illisible, reste en memoire : $erreur');
    }
  }

  Future<void> ecrire(bool repliee) async {
    try {
      await stockage.ecrire(clefNavigationRepliee, '$repliee');
    } on Object catch (erreur) {
      journalDev('Repli de navigation non ecrit, reste en memoire : $erreur');
    }
  }

  unawaited(restaurer());
  ref.listen<bool?>(navigationReplieeProvider, (bool? avant, bool? apres) {
    if (apres != null && avant != apres) {
      unawaited(ecrire(apres));
    }
  });
});

/// Clef de la preference des raccourcis clavier de la salle (EN-KB).
const String clefRaccourcisSalle = 'salle.raccourcis';

/// Relie le choix des raccourcis de la salle a son stockage, comme
/// [persistanceNavigationProvider] : une lecture au montage, une ecriture a
/// chaque changement. **Monte par `RewayahApp` seulement.**
final Provider<void> persistanceRaccourcisProvider = Provider<void>((Ref ref) {
  final StockagePreferences stockage = ref.watch(stockagePreferencesProvider);
  final PreferencesLocalesControleur controleur = ref.read(
    preferencesLocalesProvider.notifier,
  );

  Future<void> restaurer() async {
    try {
      final String? lu = await stockage.lire(clefRaccourcisSalle);
      if (ref.mounted && (lu == 'true' || lu == 'false')) {
        controleur.restaurerRaccourcisSalle(actifs: lu == 'true');
      }
    } on Object catch (erreur) {
      journalDev('Raccourcis de salle illisibles, en memoire : $erreur');
    }
  }

  Future<void> ecrire(bool actifs) async {
    try {
      await stockage.ecrire(clefRaccourcisSalle, '$actifs');
    } on Object catch (erreur) {
      journalDev('Raccourcis de salle non ecrits, en memoire : $erreur');
    }
  }

  unawaited(restaurer());
  ref.listen<bool>(
    preferencesLocalesProvider.select(
      (PreferencesLocales p) => p.raccourcisSalle,
    ),
    (bool? avant, bool apres) {
      if (avant != apres) {
        unawaited(ecrire(apres));
      }
    },
  );
});
