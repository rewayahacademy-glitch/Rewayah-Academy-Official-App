import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Bandeau de degradation reseau.
///
/// Un seul composant, calibre une fois, jamais reecrit par ecran
/// (`docs/architecture/etape-2-core-flutter.md` section 2).
///
/// Le hors ligne ne bloque qu'une chose : l'entree en seance et la validation
/// d'un rapport. Le reste reste consultable depuis le cache, et un rapport se
/// met en file d'attente au lieu d'echouer. Le texte du bandeau dit donc ce qui
/// continue de marcher, pas seulement ce qui est casse.
class OfflineBanner extends StatefulWidget {
  /// Cree le bandeau.
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<List<ConnectivityResult>>? _abonnement;
  bool _horsLigne = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialiser());
  }

  Future<void> _initialiser() async {
    final Connectivity connectivite = Connectivity();
    _appliquer(await connectivite.checkConnectivity());
    _abonnement = connectivite.onConnectivityChanged.listen(_appliquer);
  }

  void _appliquer(List<ConnectivityResult> resultats) {
    final bool horsLigne =
        resultats.isEmpty || resultats.every((ConnectivityResult r) => r == ConnectivityResult.none);
    if (mounted && horsLigne != _horsLigne) {
      setState(() => _horsLigne = horsLigne);
    }
  }

  @override
  void dispose() {
    unawaited(_abonnement?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_horsLigne) {
      return const SizedBox.shrink();
    }

    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.surfaceWarning;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: paire.background,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            IconTheme(
              data: IconThemeData(
                color: paire.onBackground,
                size: AppSpacing.xl,
              ),
              child: Icon(AppIcons.horsLigne.repos),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                t.reseau.horsLigne,
                style: paire.applyTo(
                  Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
