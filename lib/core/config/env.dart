import 'dart:convert';

/// Configuration d'execution, injectee a la compilation.
///
/// **Aucune valeur reelle n'est ecrite dans le depot.** Les cles vivent dans
/// les secrets GitHub et Supabase, jamais en dur
/// (`docs/agent-onboarding.md` etape D). Voir `dart_define.example.json` pour
/// la forme attendue.
///
/// Lancement local :
/// ```
/// flutter run --dart-define-from-file=dart_define.json
/// ```
abstract final class Env {
  /// URL de l'API Supabase du projet `gggmtelinlpseweouyav`.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Cle publiable Supabase. Publique par nature : ce sont la RLS et les
  /// droits SQL qui protegent, jamais le secret de cette cle.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Active la galerie de composants sur la route `/_galerie`.
  ///
  /// Faux par defaut : une version de production ne contient pas la galerie.
  static const bool galerieActive = bool.fromEnvironment('GALERIE');

  /// Active le Playground de developpement (racine dediee a la simulation de
  /// personnes, etats et donnees).
  ///
  /// Faux par defaut : une version de production ne compile pas le Playground.
  static const bool playgroundActif = bool.fromEnvironment('PLAYGROUND');

  /// Active le raccourci de connexion par courriel fictif, sans Supabase
  /// (`SessionControleur.ouvrirDemo`).
  ///
  /// Faux par defaut : une version de production ne compile pas ce raccourci.
  static const bool authParMotDePasseActive = bool.fromEnvironment(
    'AUTH_PAR_MOT_DE_PASSE',
  );

  /// DSN Sentry du projet Flutter (onboarding etape F, critere 0.6).
  ///
  /// Vide par defaut, et c'est voulu : **sans DSN, la supervision ne demarre
  /// pas du tout.** Un poste de developpement, un test et le Playground
  /// n'envoient donc rien, et le quota du compte n'est pas mange par du bruit
  /// local. Le DSN n'est pas un secret au sens strict -- il part dans le
  /// binaire client, c'est sa nature -- mais il reste hors du depot comme les
  /// autres cles, parce qu'il donne le droit d'ecrire dans le tableau de bord.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN_FLUTTER');

  /// Environnement declare a Sentry : `production`, `staging` ou
  /// `developpement`.
  ///
  /// Vaut `developpement` par defaut pour qu'une compilation qui oublie de le
  /// declarer ne vienne jamais se melanger aux erreurs de production. Les
  /// variantes reelles par cible viendront avec l'etape G de l'onboarding.
  static const String environnement = String.fromEnvironment(
    'ENVIRONNEMENT',
    defaultValue: 'developpement',
  );

  /// Vrai quand la configuration minimale est presente et plausible.
  static bool get configuree =>
      _urlSupabaseValide(supabaseUrl) && cleSupabaseValide(supabaseAnonKey);

  /// Vérifie une clé client Supabase sans l'afficher ni faire d'appel réseau.
  ///
  /// Les anciennes clés `anon` sont des JWT HS256 portant les claims
  /// Supabase attendus. Les nouvelles clés publishable sont opaques et
  /// commencent par `sb_publishable_`. Cette vérification bloque les
  /// placeholders et les chaînes mal formées ; elle ne remplace pas la RLS
  /// ni une vérification de connexion au projet.
  static bool cleSupabaseValide(String value) {
    final String key = value.trim();
    if (key != value || key.isEmpty || _estPlaceholder(key)) {
      return false;
    }

    if (key.startsWith('sb_publishable_')) {
      return RegExp(r'^sb_publishable_[A-Za-z0-9_-]{24,}$').hasMatch(key);
    }

    final List<String> parts = key.split('.');
    if (parts.length != 3 ||
        parts.any(
          (String part) => !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(part),
        )) {
      return false;
    }

    try {
      final dynamic header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      final dynamic payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return header is Map &&
          payload is Map &&
          header['alg'] == 'HS256' &&
          payload['iss'] == 'supabase' &&
          payload['role'] == 'anon';
    } on FormatException {
      return false;
    }
  }

  static bool _urlSupabaseValide(String value) {
    final Uri? uri = Uri.tryParse(value);
    return value == value.trim() &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        !_estPlaceholder(uri.host);
  }

  static bool _estPlaceholder(String value) {
    final String lower = value.toLowerCase();
    return lower.contains('dummy') ||
        lower.contains('fake') ||
        lower.contains('factice') ||
        lower.contains('placeholder') ||
        lower.contains('playground') ||
        lower.contains('never-used') ||
        lower.contains('example');
  }

  /// Vrai quand la supervision est configuree et doit donc demarrer.
  static bool get supervisionActive => sentryDsn.isNotEmpty;

  /// Message d'aide affiche quand la configuration manque, pour qu'un
  /// developpeur qui lance l'application sans `--dart-define` comprenne
  /// immediatement quoi faire.
  static const String aideConfiguration =
      'SUPABASE_URL et SUPABASE_ANON_KEY sont absents ou invalides. '
      'Lancez avec --dart-define-from-file=dart_define.json, '
      'sur le modele de dart_define.example.json.';
}
