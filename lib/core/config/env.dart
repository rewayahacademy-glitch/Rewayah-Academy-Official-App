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

  /// Vrai quand la configuration minimale est presente.
  static bool get configuree =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Message d'aide affiche quand la configuration manque, pour qu'un
  /// developpeur qui lance l'application sans `--dart-define` comprenne
  /// immediatement quoi faire.
  static const String aideConfiguration =
      'SUPABASE_URL et SUPABASE_ANON_KEY sont absents. '
      'Lancez avec --dart-define-from-file=dart_define.json, '
      'sur le modele de dart_define.example.json.';
}
