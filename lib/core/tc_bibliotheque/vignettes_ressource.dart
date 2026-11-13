import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` (meme convention que `donnees_catalogue.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Les vignettes deposees des documents (BIBLIOTHEQUE-UNE).
///
/// Une vignette est une image que la direction depose avec un document. Le
/// manifeste dit seulement qu'elle existe (`LibraryResource.aVignette`) : son
/// URL est **signee et delivree par le serveur** (fonction Edge
/// `bibliotheque-lecture`, action `vignettes`), courte, jamais gardee au-dela
/// de sa duree, jamais ecrite dans un manifeste. Sans vignette, ou quand
/// l'URL ne vient pas, la couverture par defaut du type s'applique.
abstract interface class PortVignettes {
  /// L'URL signee de la vignette du document [resourceId], ou `null` quand le
  /// document n'en a pas, que l'appelant ne le lit pas ou que le serveur ne
  /// repond pas : dans tous ces cas la couverture par defaut reste.
  Future<Uri?> urlDe(String resourceId);
}

/// Aucune vignette servie (tests, demonstration) : la couverture par defaut.
final class VignettesAucune implements PortVignettes {
  /// Cree le port vide.
  const VignettesAucune();

  @override
  Future<Uri?> urlDe(String resourceId) async => null;
}

/// Le port des vignettes employe par l'application.
final Provider<PortVignettes> portVignettesProvider = Provider<PortVignettes>(
  (Ref ref) => const VignettesAucune(),
);

/// L'URL signee de la vignette d'un document.
final FutureProviderFamily<Uri?, String> vignetteUrlProvider =
    FutureProvider.family<Uri?, String>(
      (Ref ref, String resourceId) =>
          ref.watch(portVignettesProvider).urlDe(resourceId),
    );
