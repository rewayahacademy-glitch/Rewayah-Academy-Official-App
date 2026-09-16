import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';

/// Supervision des erreurs d'execution (etape 0.6, onboarding etape F).
///
/// Un seul point d'entree : [demarrer], appele par `main()` avant tout le
/// reste. Tout ce qui concerne Sentry vit ici, et rien d'autre du produit
/// n'importe `sentry_flutter` -- le jour ou l'outil change, un seul fichier
/// bouge.
///
/// **Sans DSN, rien ne demarre.** C'est la meme discipline que la
/// configuration Supabase : un comportement qui doit tenir en production se
/// code en `if` et en sortie explicite, il ne se confie pas a un `assert` qui
/// disparait de la version compilee.
///
/// ## Ce que cette supervision n'envoie deliberement pas
///
/// Le produit filme des mineurs et manipule des dossiers KYC. Trois reglages
/// portent cette contrainte, et ils sont ecrits meme quand ils repetent la
/// valeur par defaut du paquet : une valeur par defaut qui compte se declare,
/// sinon une mise a jour du paquet peut la retourner sans que personne ne le
/// voie passer.
///
/// 1. Aucune capture d'ecran, jamais. Une erreur pendant une seance
///    enverrait le visage d'un enfant sur un service tiers.
/// 2. Aucune hierarchie de vues : elle emporte les libelles affiches, donc
///    des noms de personnes.
/// 3. Aucune donnee personnelle par defaut, et aucune identite d'utilisateur
///    n'est jamais posee sur la portee Sentry. Un rapport doit dire ce qui a
///    casse, pas a qui.
abstract final class Supervision {
  static bool _demarree = false;

  /// Vrai une fois [demarrer] passe avec un DSN.
  ///
  /// Faux sur un poste de developpement, dans les tests et dans le
  /// Playground : ils n'ont pas de DSN, donc pas de supervision.
  static bool get demarree => _demarree;

  /// Demarre la supervision si elle est configuree.
  ///
  /// Sans effet, et sans erreur, quand `SENTRY_DSN_FLUTTER` est absent :
  /// l'application doit se lancer normalement sur un poste qui n'a pas la
  /// cle. Appeler deux fois ne reinitialise rien.
  static Future<void> demarrer() async {
    if (_demarree || !Env.supervisionActive) {
      return;
    }

    await SentryFlutter.init((SentryFlutterOptions options) {
      options.dsn = Env.sentryDsn;
      options.environment = Env.environnement;

      // Les erreurs, rien que les erreurs. Une trace de performance porte les
      // noms de routes, donc des identifiants, et mange le quota du compte
      // sans rien apprendre tant que personne ne lit ces courbes.
      options.tracesSampleRate = 0.0;

      // Les trois reglages de confidentialite documentes en tete de classe.
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
      // `attachViewHierarchy` est marquee experimentale par le paquet. On
      // l'ecrit quand meme : ce qui protege des noms affiches ne se laisse pas
      // a une valeur par defaut qu'une mise a jour peut retourner. Si une
      // version future la retire, la compilation le dira, et c'est le bon
      // moment pour relire ce fichier.
      // ignore: experimental_member_use
      options.attachViewHierarchy = false;

      options.beforeSend = nettoyer;
    });

    _demarree = true;
  }

  /// Retire d'un evenement ce qui pourrait porter une identite.
  ///
  /// Une URL PostgREST transporte ses filtres dans sa chaine de requete
  /// (`?id=eq.<uuid>`, `?email=eq.<adresse>`). Le chemin suffit a comprendre
  /// quel appel a echoue ; la chaine de requete, elle, n'apprend rien de plus
  /// et peut nommer quelqu'un. On la coupe partout ou elle peut se trouver.
  ///
  /// Publique pour que `test/observabilite/supervision_test.dart` puisse la
  /// tenir : c'est la seule barriere entre un identifiant et un service tiers,
  /// et une barriere que personne ne teste finit par ceder.
  @visibleForTesting
  static SentryEvent? nettoyer(SentryEvent evenement, Hint hint) {
    final List<Breadcrumb>? miettes = evenement.breadcrumbs;
    if (miettes == null || miettes.isEmpty) {
      return evenement;
    }

    return evenement.copyWith(
      breadcrumbs: miettes.map(_nettoyerMiette).toList(),
    );
  }

  static Breadcrumb _nettoyerMiette(Breadcrumb miette) {
    final Map<String, dynamic>? donnees = miette.data;
    if (donnees == null) {
      return miette;
    }

    final Object? url = donnees['url'];
    if (url is! String || !url.contains('?')) {
      return miette;
    }

    return miette.copyWith(
      data: <String, dynamic>{
        ...donnees,
        'url': url.substring(0, url.indexOf('?')),
      },
    );
  }

  /// Envoie une erreur volontaire, pour le critere d'acceptation 0.6.
  ///
  /// N'est cablee sur aucun bouton du produit : elle se declenche depuis le
  /// Playground ou depuis un test manuel. Un bouton qui provoque une erreur
  /// n'a rien a faire dans une interface que des enfants utilisent.
  ///
  /// Retourne l'identifiant de l'evenement envoye, ou `null` quand la
  /// supervision n'est pas configuree.
  static Future<SentryId?> declencherErreurDeTest() async {
    if (!_demarree) {
      return null;
    }

    return Sentry.captureException(
      StateError('Erreur volontaire de verification (critere 0.6).'),
      stackTrace: StackTrace.current,
    );
  }
}
