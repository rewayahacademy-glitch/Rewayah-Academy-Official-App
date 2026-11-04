import 'dart:convert';

/// Configuration d'execution, injectee a la compilation.
///
/// **Aucune valeur reelle n'est ecrite dans le depot.** Les cles vivent dans
/// les secrets GitHub et Supabase, jamais en dur
/// (`docs/archive/2026-09-pre-remise-a-plat/agent-onboarding.md` etape D). Voir `dart_define.example.json` pour
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

  /// Active la mise en page du Mushaf de Medine en 15 lignes (MUSHAF-15L) :
  /// `portLayoutMushafProvider` rend alors `LayoutMadina15` au lieu de
  /// `LayoutLignesIndisponible`.
  ///
  /// Vrai par defaut depuis le 16/10/2026 (constat du directeur : les
  /// versions deployees montraient la composition approchee, les captures du
  /// lot la page de Medine). `--dart-define=MUSHAF_15L=false` revient a
  /// l'ancienne composition.
  static const bool mushaf15L = bool.fromEnvironment(
    'MUSHAF_15L',
    defaultValue: true,
  );

  /// Le drapeau MUSHAF-15L effectivement applique (developpement et galerie
  /// l'allument).
  static bool get mushaf15LActif =>
      mushaf15L || galerieActive || playgroundActif;

  /// Active le raccourci de connexion par courriel fictif, sans Supabase
  /// (`SessionControleur.ouvrirDemo`).
  ///
  /// Faux par defaut : une version de production ne compile pas ce raccourci.
  static const bool authParMotDePasseActive = bool.fromEnvironment(
    'AUTH_PAR_MOT_DE_PASSE',
  );

  /// Ancien interrupteur de compilation de l'observation par le tuteur
  /// (contrat K4, point P3 du chantier Tuteur V1).
  ///
  /// **Sans effet depuis le lot O1 (02/11/2026).** L'observation ne s'ouvre
  /// plus par un drapeau de compilation : elle s'ouvre quand le serveur la
  /// permet (politique `politique_observation_effective`, budget
  /// `budget_observation`, porte `entrer_observation`, jeton sans
  /// publication), et elle se coupe cote serveur a la duree de la politique
  /// (`couper_visites_observation_echues`, tache `observation-coupure`). Les
  /// garanties que ce drapeau attendait (DB-OBS-01, 02, 03, 05) sont prouvees
  /// par `supabase/tests/scenarios_o1_observation.sql`. Le garder declare
  /// evite de casser une commande de compilation qui le passerait encore ;
  /// il ne ferme ni n'ouvre plus rien. L'interrupteur d'arret est en base :
  /// `app_config.observation.activee`, ou la politique d'une classe.
  static const bool observationTuteurReelle = bool.fromEnvironment(
    'OBSERVATION_TUTEUR_REELLE',
  );

  /// L'observation par le tuteur est-elle ouverte cote client ?
  ///
  /// **Toujours vrai depuis le lot O1** : le client n'en decide plus, le
  /// serveur dit oui ou non (politique fermee, quota, seance, acces paye) et
  /// l'ecran affiche sa reponse. Les ecrans le lisent par
  /// `observationTuteurReelleProvider`, jamais ici ; la demonstration le
  /// force a faux.
  ///
  /// Attention : les apercus de pull request sont compiles avec les cles de
  /// la production (`flutter-deploy.yml`) ; un apercu ouvre donc
  /// l'observation reelle, comme la production.
  static bool get observationTuteurReelleActive => observationTuteurReelleSelon(
    demandee: observationTuteurReelle,
    environnement: environnement,
  );

  /// La regle d'ouverture, pure pour etre verifiee sans compilation dediee.
  ///
  /// O1 (02/11/2026) : ouverte dans tous les environnements, quelle que soit
  /// la valeur compilee ; c'est le serveur qui ferme (voir
  /// [observationTuteurReelle]). Les parametres restent pour ne pas casser
  /// les appelants ; ils ne changent plus le resultat.
  static bool observationTuteurReelleSelon({
    required bool demandee,
    required String environnement,
  }) => true;

  /// L'adresse du site public (`https://hote`), sans chemin : l'origine des
  /// liens que l'application donne a partager (CAND-06, la carte « Faites
  /// connaitre Rewayah »).
  ///
  /// **Vide par defaut, et c'est voulu.** Sur le web, l'application et le site
  /// public sont servis par la meme origine (`flutter-deploy.yml` construit
  /// `fr/` a cote de l'application) : sans valeur, le lien prend l'origine de
  /// la page ouverte, comme `lienAvisPour`. Hors du web, sans valeur, aucun
  /// lien n'existe et la carte ne se propose pas. Une adresse invalide (pas de
  /// `https`, pas d'hote) est ignoree. Voir `lienOffre`
  /// (`lib/core/partage_offre/lien_offre.dart`).
  static const String siteUrl = String.fromEnvironment('SITE_URL');

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

  /// Vrai quand la compilation declare `ENVIRONNEMENT`. Faux, [environnement]
  /// n'est que la valeur par defaut : les demonstrations restent fermees en
  /// publication (DEMO-ENV-1).
  static const bool environnementDeclare = bool.hasEnvironment('ENVIRONNEMENT');

  /// Faux dans la compilation de production : les demonstrations (`/demo/*`,
  /// `?demo=`) n'y sont pas compilees du tout. Constante de compilation, pour
  /// que dart2js retire leur code de `main.dart.js` (213 Ko le 28/10/2026) ;
  /// la garde d'execution [environnementAutoriseDemo] reste la seconde porte.
  static const bool demoCompilee = environnement != 'production';

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
