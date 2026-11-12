// ANTI-CRASH (garde-cap, 12/11/2026, ordre du directeur : « l'app ne doit
// jamais planter ») : le garde-fou global des erreurs d'execution.
//
// Trois portes, posees une fois par `main()` apres `Supervision.demarrer` :
//
// 1. `ErrorWidget.builder` : une erreur dans le `build` d'un widget donnait un
//    rectangle gris en version publiee (rouge en developpement), ou un ecran
//    vide quand l'erreur etait haut placee. Elle donne maintenant une petite
//    carte « Cet element n'a pas pu s'afficher » avec « Reessayer », a la place
//    du seul element fautif : le reste de l'ecran (coquille, barre) reste
//    utilisable.
// 2. `FlutterError.onError` : ENCHAINE au gestionnaire deja pose (celui de
//    Sentry quand la supervision tourne, sinon l'affichage par defaut de
//    Flutter), jamais ecrase.
// 3. `PlatformDispatcher.instance.onError` (erreurs asynchrones non
//    attrapees) : enchaine de meme, puis rend `true` : l'erreur est
//    journalisee et remontee, l'application continue.

import 'dart:ui' show ErrorCallback;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/action_principale.dart';

/// Pose les trois portes. Idempotent : un second appel ne rechaine rien.
void installerGardeErreurs() {
  if (_installe) return;
  _installe = true;

  ErrorWidget.builder = (FlutterErrorDetails details) =>
      CarteErreurElement(details: details);

  final FlutterExceptionHandler? precedent = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (precedent != null) {
      precedent(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final ErrorCallback? precedentPlateforme =
      PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object erreur, StackTrace pile) {
    precedentPlateforme?.call(erreur, pile);
    debugPrint('Erreur non attrapee : $erreur');
    // Journalisee (et remontee par Sentry, chaine ci-dessus) : jamais un
    // arret de l'application.
    return true;
  };
}

bool _installe = false;

/// Remet l'etat d'installation a zero, pour les tests seulement.
@visibleForTesting
void reinitialiserGardeErreurs() => _installe = false;

/// La carte qui remplace un element dont le `build` a echoue.
///
/// Elle ne depend d'AUCUN ancetre obligatoire : sans `Theme` de l'application,
/// sans `MediaQuery`, sans `Directionality`, elle s'affiche encore (couleurs
/// de la palette claire, sens de la langue choisie). Le bouton « Reessayer »
/// n'existe que sous le theme de l'application (le composant d'action le
/// lit) : il reconstruit l'element fautif.
class CarteErreurElement extends StatelessWidget {
  /// Cree la carte.
  const CarteErreurElement({required this.details, super.key});

  /// L'erreur, pour la trace (jamais affichee a la personne).
  final FlutterErrorDetails details;

  /// Les cles, pour les tests.
  static const Key carteKey = ValueKey<String>('carte-erreur-element');
  static const Key reessayerKey = ValueKey<String>('carte-erreur-reessayer');

  @override
  Widget build(BuildContext context) {
    final AppPalette? duTheme = Theme.of(context).extension<AppPalette>();
    final AppPalette palette = duTheme ?? AppPalette.claire();
    final TextDirection sens =
        Directionality.maybeOf(context) ??
        (LocaleSettings.currentLocale == AppLocale.ar
            ? TextDirection.rtl
            : TextDirection.ltr);
    final TextStyle? styleTheme = duTheme == null
        ? null
        : Theme.of(context).textTheme.bodyMedium;
    final TextStyle style = (styleTheme ?? const TextStyle()).copyWith(
      color: palette.surfaceRaised.onBackground,
    );
    return Directionality(
      textDirection: sens,
      child: Semantics(
        container: true,
        child: Container(
          key: carteKey,
          margin: const EdgeInsets.all(AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.surfaceRaised.background,
            borderRadius: AppRadius.arrondiSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.commun.erreurElement, style: style),
              if (duTheme != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                ActionPrincipale(
                  key: reessayerKey,
                  libelle: t.commun.reessayer,
                  niveau: NiveauAction.tertiaire,
                  onPress: () => _reessayer(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Reconstruit l'element dont le `build` a echoue : c'est le parent direct
  /// de cette carte.
  static void _reessayer(BuildContext context) {
    context.visitAncestorElements((Element parent) {
      parent.markNeedsBuild();
      return false;
    });
  }
}
