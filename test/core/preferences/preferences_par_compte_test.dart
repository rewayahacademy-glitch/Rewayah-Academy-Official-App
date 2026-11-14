// PREFERENCES-PAR-COMPTE (directeur, 11/11/2026) : le theme et la langue sont
// portes par le COMPTE, pas par l'appareil. Test exige par le pilote : compte A
// en sombre et en arabe, deconnexion, compte B en Systeme et en francais, puis
// retour a A, de nouveau en sombre et en arabe.

import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_langues_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_compte.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';

const String _a = 'profil-a';
const String _b = 'profil-b';

/// Le compte connecte, pilote par le test.
class _Compte extends Notifier<ComptePreferences> {
  @override
  ComptePreferences build() =>
      const ComptePreferences(profil: null, resolue: false);

  void connecter(String profil) =>
      state = ComptePreferences(profil: profil, resolue: true);

  void personne() =>
      state = const ComptePreferences(profil: null, resolue: true);
}

final NotifierProvider<_Compte, ComptePreferences> _compte =
    NotifierProvider<_Compte, ComptePreferences>(_Compte.new);

/// Le serveur : une ligne par compte, lue et ecrite par le compte connecte.
class _Serveur {
  final Map<String, String> themes = <String, String>{};
  final Map<String, String> langues = <String, String>{};
  final List<String> ecritures = <String>[];
  String? connecte;
}

class _ThemeServeur implements PortThemeCompte {
  _ThemeServeur(this.s);
  final _Serveur s;

  @override
  Future<String> lire() async => s.themes[s.connecte!] ?? 'systeme';

  @override
  Future<void> regler(String theme) async {
    s.ecritures.add('theme:$theme');
    s.themes[s.connecte!] = theme;
  }
}

class _LangueServeur implements PortLanguesCommunication {
  _LangueServeur(this.s);
  final _Serveur s;

  @override
  Future<List<LangueCommunication>> lister() async =>
      const <LangueCommunication>[];

  @override
  Future<String?> maLangue() async => s.langues[s.connecte!];

  @override
  Future<void> regler(String code) async {
    s.ecritures.add('langue:$code');
    s.langues[s.connecte!] = code;
  }
}

/// Un lancement de l'application (ou la memoire remise a zero apres une
/// deconnexion) : un conteneur neuf sur le meme appareil et le meme serveur.
ProviderContainer _lancer(StockagePreferencesMemoire appareil, _Serveur s) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      stockagePreferencesProvider.overrideWithValue(appareil),
      lecturePreferencesImmediateProvider.overrideWithValue(appareil),
      compteDesPreferencesProvider.overrideWith(
        (Ref ref) => ref.watch(_compte),
      ),
      portThemeCompteProvider.overrideWithValue(_ThemeServeur(s)),
      portLanguesCommunicationProvider.overrideWithValue(_LangueServeur(s)),
    ],
  );
  addTearDown(c.dispose);
  // Monte la persistance comme le fait RewayahApp.
  c.listen<void>(persistanceApparenceProvider, (void _, void _) {});
  c.listen<void>(persistanceLangueProvider, (void _, void _) {});
  return c;
}

Future<void> _connecter(ProviderContainer c, _Serveur s, String profil) async {
  s.connecte = profil;
  c.read(_compte.notifier).connecter(profil);
  await pumpEventQueue();
}

PreferencesLocales _prefs(ProviderContainer c) =>
    c.read(preferencesLocalesProvider);

void main() {
  // LANGUES-1 : l'appareil de test annonce « en-US », desormais traduit ; ces
  // tests veulent une langue d'appareil inconnue, qui retombe sur le francais.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = const <Locale>[
      Locale('es'),
    ];
  });
  tearDown(() async {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearLocalesTestValue();
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  test('A en sombre et en arabe, deconnexion, B en Systeme et en francais, '
      'retour a A en sombre et en arabe', () async {
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire();
    final _Serveur serveur = _Serveur();

    // 1. A se connecte et choisit sombre et arabe.
    ProviderContainer c = _lancer(appareil, serveur);
    await _connecter(c, serveur, _a);
    c.read(preferencesLocalesProvider.notifier).theme(PreferenceTheme.sombre);
    // La ligne « Langue » du compte (E, P1) passe par choisirLangueCompte.
    expect(await reglerLangueCompte(c.read, PreferenceLangue.arabe), isTrue);
    await pumpEventQueue();
    expect(LocaleSettings.currentLocale, AppLocale.ar);
    expect(serveur.themes[_a], 'sombre', reason: 'le theme part au compte');
    expect(serveur.langues[_a], 'ar', reason: 'la langue part au compte');
    expect(appareil.valeurs['$clefPreferenceTheme.$_a'], 'sombre');
    expect(appareil.valeurs[clefPreferenceTheme], 'systeme');

    // 2. Deconnexion : l'etape de `Deconnexion`, puis la memoire remise a
    //    zero (conteneur neuf), sans personne connectee.
    await oublierPreferencesDuCompte(appareil);
    serveur.connecte = null;
    c.dispose();
    c = _lancer(appareil, serveur);
    expect(
      _prefs(c).theme,
      PreferenceTheme.systeme,
      reason: 'avant la premiere image, jamais le theme du compte sorti',
    );
    c.read(_compte.notifier).personne();
    await pumpEventQueue();
    expect(_prefs(c).theme, PreferenceTheme.systeme);
    expect(_prefs(c).langue, PreferenceLangue.systeme);
    // L'appareil de test parle anglais (non traduit) : le francais.
    expect(LocaleSettings.currentLocale, AppLocale.fr);
    expect(appareil.valeurs[clefPointeurCompte], '');

    // 3. B se connecte, sans reglage : Systeme et francais.
    await _connecter(c, serveur, _b);
    expect(_prefs(c).theme, PreferenceTheme.systeme);
    expect(_prefs(c).langue, PreferenceLangue.systeme);
    expect(LocaleSettings.currentLocale, AppLocale.fr);

    // 4. B sort, A revient : de nouveau sombre et arabe.
    await oublierPreferencesDuCompte(appareil);
    c.dispose();
    c = _lancer(appareil, serveur);
    c.read(_compte.notifier).personne();
    await pumpEventQueue();
    await _connecter(c, serveur, _a);
    expect(_prefs(c).theme, PreferenceTheme.sombre);
    expect(_prefs(c).langue, PreferenceLangue.arabe);
    expect(LocaleSettings.currentLocale, AppLocale.ar);

    // Les reglages repris du cache ou du serveur ne repartent jamais au
    // serveur : seuls les deux choix de A y ont ete ecrits.
    expect(serveur.ecritures, <String>['theme:sombre', 'langue:ar']);
  });

  test('CANDIDATURE-UX : la langue choisie sans compte devient celle du compte '
      'qui nait, jamais la langue de l appareil', () async {
    // L'appareil du directeur parle arabe ; le candidat choisit le francais.
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = const <Locale>[
      Locale('ar'),
    ];
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire();
    final _Serveur serveur = _Serveur();
    final ProviderContainer c = _lancer(appareil, serveur);
    // Connecte a Google, sans profil encore : personne.
    c.read(_compte.notifier).personne();
    await pumpEventQueue();
    c
        .read(preferencesLocalesProvider.notifier)
        .langue(PreferenceLangue.francais);
    await pumpEventQueue();
    expect(LocaleSettings.currentLocale, AppLocale.fr);

    // « Envoyer ma candidature » cree le profil : le compte nait.
    await _connecter(c, serveur, _a);
    expect(_prefs(c).langue, PreferenceLangue.francais);
    expect(LocaleSettings.currentLocale, AppLocale.fr);
    expect(appareil.valeurs['$clefPreferenceLangue.$_a'], 'francais');
    expect(serveur.langues[_a], 'fr', reason: 'la langue part au compte');

    // Deconnexion puis retour : la langue du compte revient.
    await oublierPreferencesDuCompte(appareil);
    c.dispose();
    final ProviderContainer d = _lancer(appareil, serveur);
    d.read(_compte.notifier).personne();
    await pumpEventQueue();
    await _connecter(d, serveur, _a);
    expect(_prefs(d).langue, PreferenceLangue.francais);
    expect(LocaleSettings.currentLocale, AppLocale.fr);
  });

  test(
    'CANDIDATURE-UX : l anglais choisi sans compte part au compte',
    () async {
      final StockagePreferencesMemoire appareil = StockagePreferencesMemoire();
      final _Serveur serveur = _Serveur();
      final ProviderContainer c = _lancer(appareil, serveur);
      c.read(_compte.notifier).personne();
      await pumpEventQueue();
      c
          .read(preferencesLocalesProvider.notifier)
          .langue(PreferenceLangue.anglais);
      await pumpEventQueue();
      await _connecter(c, serveur, _a);
      expect(_prefs(c).langue, PreferenceLangue.anglais);
      expect(serveur.langues[_a], 'en');
    },
  );

  test('B a ses propres reglages : ils s appliquent, ceux de A non', () async {
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire(
      <String, String>{
        clefPointeurCompte: _a,
        '$clefPreferenceTheme.$_a': 'sombre',
        '$clefPreferenceLangue.$_a': 'arabe',
      },
    );
    final _Serveur serveur = _Serveur()
      ..themes[_a] = 'sombre'
      ..langues[_a] = 'ar'
      ..themes[_b] = 'clair'
      ..langues[_b] = 'fr';

    final ProviderContainer c = _lancer(appareil, serveur);
    // Avant que la session soit connue : le dernier compte (A).
    expect(_prefs(c).theme, PreferenceTheme.sombre);
    // La session dit B (A n'est plus connecte sur cet appareil).
    await _connecter(c, serveur, _b);
    expect(_prefs(c).theme, PreferenceTheme.clair);
    expect(_prefs(c).langue, PreferenceLangue.francais);
    expect(LocaleSettings.currentLocale, AppLocale.fr);
    expect(appareil.valeurs[clefPointeurCompte], _b);
  });

  test('sur un autre appareil, sans cache, le serveur fait foi', () async {
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire();
    final _Serveur serveur = _Serveur()
      ..themes[_a] = 'sombre'
      ..langues[_a] = 'ar';
    final ProviderContainer c = _lancer(appareil, serveur);
    await _connecter(c, serveur, _a);
    expect(_prefs(c).theme, PreferenceTheme.sombre);
    expect(_prefs(c).langue, PreferenceLangue.arabe);
    expect(appareil.valeurs['$clefPreferenceTheme.$_a'], 'sombre');
    expect(serveur.ecritures, isEmpty);
  });

  test(
    'session expiree sans deconnexion : retour au defaut, pointeur efface',
    () async {
      final StockagePreferencesMemoire appareil = StockagePreferencesMemoire();
      final _Serveur serveur = _Serveur()
        ..themes[_a] = 'sombre'
        ..langues[_a] = 'ar';
      final ProviderContainer c = _lancer(appareil, serveur);
      await _connecter(c, serveur, _a);
      expect(_prefs(c).theme, PreferenceTheme.sombre);

      c.read(_compte.notifier).personne();
      await pumpEventQueue();
      expect(_prefs(c).theme, PreferenceTheme.systeme);
      expect(_prefs(c).langue, PreferenceLangue.systeme);
      expect(LocaleSettings.currentLocale, AppLocale.fr);
      expect(appareil.valeurs[clefPointeurCompte], '');
      expect(appareil.valeurs[clefPreferenceTheme], 'systeme');
      // Le cache de A reste, pour son retour.
      expect(appareil.valeurs['$clefPreferenceTheme.$_a'], 'sombre');
    },
  );

  test('sans compte avant, le choix fait sur l appareil reste', () async {
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire(
      <String, String>{
        clefVersionPreferences: versionPreferences,
        clefPreferenceTheme: 'sombre',
      },
    );
    final ProviderContainer c = _lancer(appareil, _Serveur());
    expect(_prefs(c).theme, PreferenceTheme.sombre);
    c.read(_compte.notifier).personne();
    await pumpEventQueue();
    expect(_prefs(c).theme, PreferenceTheme.sombre);
  });

  test('herite d avant le lot : « sombre » sur l appareil, aucun compte, '
      'demarrage en Systeme (garde-cap)', () async {
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire(
      <String, String>{
        clefPreferenceTheme: 'sombre',
        clefPreferenceLangue: 'arabe',
      },
    );
    expect(lirePreferenceImmediate(appareil, clefPreferenceTheme), isNull);
    final ProviderContainer c = _lancer(appareil, _Serveur());
    expect(_prefs(c).theme, PreferenceTheme.systeme);
    c.read(_compte.notifier).personne();
    await pumpEventQueue();
    expect(_prefs(c).theme, PreferenceTheme.systeme);
    expect(_prefs(c).langue, PreferenceLangue.systeme);
    expect(appareil.valeurs[clefPreferenceTheme], 'systeme');
    expect(appareil.valeurs[clefPreferenceLangue], 'systeme');
    expect(appareil.valeurs[clefVersionPreferences], versionPreferences);

    // Apres la purge, un choix fait sans compte est garde et relu.
    c.read(preferencesLocalesProvider.notifier).theme(PreferenceTheme.sombre);
    await pumpEventQueue();
    expect(lirePreferenceImmediate(appareil, clefPreferenceTheme), 'sombre');
  });

  test('lecture avant la premiere image : pointeur, compte, puis appareil', () {
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire(
      <String, String>{
        clefVersionPreferences: versionPreferences,
        clefPreferenceTheme: 'clair',
        '$clefPreferenceTheme.$_a': 'sombre',
      },
    );
    expect(lirePreferenceImmediate(appareil, clefPreferenceTheme), 'clair');
    appareil.valeurs[clefPointeurCompte] = _a;
    expect(lirePreferenceImmediate(appareil, clefPreferenceTheme), 'sombre');
    appareil.valeurs[clefPointeurCompte] = _b;
    expect(
      lirePreferenceImmediate(appareil, clefPreferenceTheme),
      'clair',
      reason: 'un compte sans cache retombe sur la cle de l appareil',
    );
    appareil.valeurs[clefPointeurCompte] = '';
    expect(lirePreferenceImmediate(appareil, clefPreferenceTheme), 'clair');
  });

  test('la langue du compte : francais, arabe et anglais (LANGUES-1)', () {
    expect(langueCompteDepuis('fr'), PreferenceLangue.francais);
    expect(langueCompteDepuis('ar'), PreferenceLangue.arabe);
    expect(langueCompteDepuis('en'), PreferenceLangue.anglais);
    expect(langueCompteDepuis('es'), isNull);
    expect(langueCompteDepuis(null), isNull);
    expect(languesDuCompte, <PreferenceLangue>[
      PreferenceLangue.francais,
      PreferenceLangue.arabe,
      PreferenceLangue.anglais,
    ]);
    expect(codeLangueCompte(PreferenceLangue.anglais), 'en');
    expect(codeLangueCompte(PreferenceLangue.arabe), 'ar');
    expect(codeLangueCompte(PreferenceLangue.francais), 'fr');
  });

  test('un changement de langue hors de la ligne du compte ne part jamais au '
      'serveur : un seul ecrivain, jamais deux appels', () async {
    final StockagePreferencesMemoire appareil = StockagePreferencesMemoire();
    final _Serveur serveur = _Serveur();
    final ProviderContainer c = _lancer(appareil, serveur);
    await _connecter(c, serveur, _a);
    c.read(preferencesLocalesProvider.notifier).langue(PreferenceLangue.arabe);
    await pumpEventQueue();
    expect(serveur.ecritures, isEmpty);
    expect(appareil.valeurs['$clefPreferenceLangue.$_a'], 'arabe');

    expect(await reglerLangueCompte(c.read, PreferenceLangue.francais), isTrue);
    await pumpEventQueue();
    expect(serveur.ecritures, <String>['langue:fr']);
  });

  test(
    'le serveur refuse la langue : faux, l interface garde le choix',
    () async {
      final StockagePreferencesMemoire appareil = StockagePreferencesMemoire();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          stockagePreferencesProvider.overrideWithValue(appareil),
          lecturePreferencesImmediateProvider.overrideWithValue(appareil),
          portLanguesCommunicationProvider.overrideWithValue(
            const LanguesCommunicationIndisponibles(),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(await reglerLangueCompte(c.read, PreferenceLangue.arabe), isFalse);
      expect(_prefs(c).langue, PreferenceLangue.arabe);
    },
  );
}
