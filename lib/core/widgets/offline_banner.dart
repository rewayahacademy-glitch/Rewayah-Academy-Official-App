import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../reseau/service_reseau.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
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
  const OfflineBanner({super.key})
    : message = null,
      sousTexte = null,
      icone = null,
      encadre = false;

  /// Cree le bandeau avec un [message] fourni par l'appelant, sans lire
  /// [horsLigneProvider] : la salle de seance (lot CL-7) y pose l'etat que
  /// lui donne le moteur (reseau faible, reconnexion). Meme rendu, meme
  /// registre doux, meme region vivante : extension additive, pas une copie.
  ///
  /// [sousTexte] : une seconde ligne (Interface guidee, reseau faible).
  /// [icone] : par defaut, l'icone hors ligne.
  /// [encadre] : vrai quand le bandeau suit les marges de la page
  /// (contrat A) au lieu d'aller d'un bord a l'autre : filet sur les quatre
  /// cotes et rayon `AppRadius.arrondiSm`, comme le retour local.
  const OfflineBanner.message({
    required String this.message,
    this.sousTexte,
    this.icone,
    this.encadre = false,
    super.key,
  });

  /// Le texte fourni, ou `null` pour le bandeau hors ligne de l'appareil.
  final String? message;

  /// La seconde ligne, ou `null`.
  final String? sousTexte;

  /// L'icone de tete, ou `null` pour l'icone hors ligne.
  final IconData? icone;

  /// Vrai : bandeau borne par les marges de la page, cadre arrondi.
  final bool encadre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? fourni = message;
    if (fourni != null) {
      return _Bandeau(
        message: fourni,
        sousTexte: sousTexte,
        icone: icone ?? AppIcons.horsLigne.repos,
        encadre: encadre,
      );
    }
    // Tant que la reponse n'est pas la, l'appareil est repute en ligne : un
    // bandeau affiche pendant la premiere frame clignoterait sur chaque ecran.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (!horsLigne) {
      return const SizedBox.shrink();
    }
    return _Bandeau(
      message: t.reseau.horsLigne,
      icone: AppIcons.horsLigne.repos,
    );
  }
}

/// Une emprise au coin de fin, au-dessus de l'application (le repere
/// « Démonstration » de l'apercu) : le bandeau de pleine largeur garde son
/// texte hors de cette emprise, sans que les ecrans le sachent.
class ReserveCoinFin extends InheritedWidget {
  /// Reserve [largeur] au coin superieur de fin pour [child].
  const ReserveCoinFin({
    required this.largeur,
    required super.child,
    super.key,
  });

  /// La largeur reservee, depuis le bord de fin.
  final double largeur;

  /// La reserve en vigueur, 0 sans repere.
  static double de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReserveCoinFin>()?.largeur ??
      0;

  @override
  bool updateShouldNotify(ReserveCoinFin oldWidget) =>
      largeur != oldWidget.largeur;
}

/// Le rendu commun des deux constructeurs.
class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.message,
    required this.icone,
    this.sousTexte,
    this.encadre = false,
  });

  final String message;
  final String? sousTexte;
  final IconData icone;
  final bool encadre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washWarning;
    final TextStyle style = paire.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    final String? suite = sousTexte;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: encadre
            ? BoxDecoration(
                color: paire.background,
                border: Border.fromBorderSide(
                  palette.borderStrong.asBorderSide(),
                ),
                borderRadius: AppRadius.arrondiSm,
              )
            : BoxDecoration(
                color: paire.background,
                border: Border(bottom: palette.borderStrong.asBorderSide()),
              ),
        // Pleine largeur, en tete : le texte s'arrete avant l'emprise du coin
        // de fin (repere de l'apercu), jamais masque.
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.lg,
            end: encadre
                ? AppSpacing.lg
                : math.max(AppSpacing.lg, ReserveCoinFin.de(context)),
            top: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              IconTheme(
                data: IconThemeData(
                  color: paire.onBackground,
                  size: AppSpacing.xl,
                ),
                child: Icon(icone),
              ),
              Ecart.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(message, style: style),
                    if (suite != null) Text(suite, style: style),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
