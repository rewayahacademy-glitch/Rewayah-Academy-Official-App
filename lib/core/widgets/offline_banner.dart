import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../reseau/service_reseau.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Bandeau de degradation reseau.
///
/// Un seul composant, calibre une fois, jamais reecrit par ecran
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 2).
///
/// Le hors ligne ne bloque qu'une chose : l'entree en seance et la validation
/// d'un rapport. Le reste reste consultable depuis le cache, et un rapport se
/// met en file d'attente au lieu d'echouer. Le texte du bandeau dit donc ce qui
/// continue de marcher, pas seulement ce qui est casse.
///
/// L'etat vient de [horsLigneProvider] et non d'un abonnement propre a ce
/// widget : `ELV-02` grise son bloc « Rejoindre » sur le meme fait, et deux
/// abonnements independants finiraient par se contredire a l'ecran.
///
/// **Le lot C le passe au registre doux.** Il occupait un aplat ambre sature
/// sur toute la largeur, en permanence, sur chaque ecran d'un appareil sans
/// reseau, alors que la regle n'autorise qu'une zone pleine
/// par ecran et la reserve a l'action principale
/// (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 3). Il prend desormais
/// `washWarning` en fond, `inkWarning` en encre, et un filet fort en tete qui
/// le detache de la barre.
class OfflineBanner extends ConsumerWidget {
  /// Cree le bandeau.
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tant que la reponse n'est pas la, l'appareil est repute en ligne : un
    // bandeau affiche pendant la premiere frame clignoterait sur chaque ecran.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (!horsLigne) {
      return const SizedBox.shrink();
    }

    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washWarning;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paire.background,
          border: Border(bottom: palette.borderStrong.asBorderSide()),
        ),
        child: Padding(
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
              Ecart.hSm,
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
      ),
    );
  }
}
