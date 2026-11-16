// IMAGES-MESSAGERIE : l'image dans une bulle (plan du directeur du 16/11/2026).
//
// - le rapport largeur / hauteur est connu d'avance : la place est reservee
//   (`tailleImageBulle`), rien ne saute au chargement ;
// - pendant le chargement, la place est peinte de la couleur moyenne, puis
//   l'image apparait en fondu (duree de `Mouvement`) ;
// - la miniature se decode a sa taille d'affichage (`cacheWidth`) ;
// - une image retiree (90 jours) n'est JAMAIS un cadre vide : une fine ligne
//   discrete la dit (`LigneImageRetiree`).

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/mouvement.dart';
import '../tc_groupe/libelles_tc_groupe.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'image_message.dart';

/// La hauteur la plus grande d'une image dans une bulle : 320 au telephone,
/// 400 sur ordinateur.
double hauteurMaxImageBulle(double largeurEcran) =>
    largeurEcran >= 840 ? 400 : 320;

/// Les dimensions de la place reservee a une image.
@immutable
class TailleImageBulle {
  /// Cree la taille.
  const TailleImageBulle(this.largeur, this.hauteur);

  /// La largeur.
  final double largeur;

  /// La hauteur.
  final double hauteur;
}

/// La place de [image] dans au plus [largeurMax] x [hauteurMax], le rapport
/// conserve.
TailleImageBulle tailleImageBulle(
  ImageMessage image, {
  required double largeurMax,
  required double hauteurMax,
}) {
  double l = largeurMax;
  double h = l / image.rapport;
  if (h > hauteurMax) {
    h = hauteurMax;
    l = h * image.rapport;
  }
  return TailleImageBulle(math.max(1, l), math.max(1, h));
}

/// La couleur d'un `#rrggbb` du serveur ; `null` si illisible.
Color? couleurDepuisHex(String? hex) {
  if (hex == null) return null;
  final RegExpMatch? m = RegExp(
    r'^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$',
  ).firstMatch(hex);
  if (m == null) return null;
  return Color.fromARGB(
    255,
    int.parse(m.group(1)!, radix: 16),
    int.parse(m.group(2)!, radix: 16),
    int.parse(m.group(3)!, radix: 16),
  );
}

/// L'image d'une bulle : sa place reservee, la couleur moyenne, puis l'image
/// en fondu. [progression] (0 a 1) peint un petit cercle d'envoi par-dessus.
class ImageDeBulle extends StatelessWidget {
  /// Cree l'image de bulle.
  const ImageDeBulle({
    required this.image,
    required this.taille,
    super.key,
    this.adresse,
    this.progression,
    this.enPreparation = false,
  });

  /// L'image rendue par le serveur (dimensions, couleur moyenne).
  final ImageMessage image;

  /// La place reservee.
  final TailleImageBulle taille;

  /// L'adresse de la miniature, ou `null` tant qu'elle n'est pas arrivee.
  final AdresseImage? adresse;

  /// L'envoi en cours, de 0 a 1 ; `null` : aucun cercle.
  final ValueListenable<double>? progression;

  /// L'image se prepare sur l'appareil : le cercle tourne sans valeur.
  final bool enPreparation;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color fond =
        couleurDepuisHex(image.couleurMoyenne) ??
        palette.surfaceSunken.background;
    final double pixels = MediaQuery.devicePixelRatioOf(context);
    final int cache = (taille.largeur * pixels).round();
    final AdresseImage? a = adresse;
    final Duration fondu = Mouvement.duree(context, Mouvement.moyen);
    Widget? pixelsImage;
    if (a != null) {
      Widget apparition(
        BuildContext _,
        Widget enfant,
        int? cadre,
        bool synchrone,
      ) {
        if (synchrone) return enfant;
        return AnimatedOpacity(
          opacity: cadre == null ? 0 : 1,
          duration: fondu,
          curve: Mouvement.entree,
          child: enfant,
        );
      }

      Widget absente(BuildContext _, Object _, StackTrace? _) =>
          const SizedBox.shrink();
      pixelsImage = a.octets != null
          ? Image.memory(
              a.octets!,
              fit: BoxFit.cover,
              cacheWidth: cache,
              frameBuilder: apparition,
              errorBuilder: absente,
              gaplessPlayback: true,
            )
          : Image.network(
              a.url,
              fit: BoxFit.cover,
              cacheWidth: cache,
              frameBuilder: apparition,
              errorBuilder: absente,
              gaplessPlayback: true,
            );
    }
    return Semantics(
      image: true,
      label: t.com.messages.images.imageJointe,
      child: SizedBox(
        width: taille.largeur,
        height: taille.hauteur,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: fond),
            ?pixelsImage,
            if (progression != null || enPreparation)
              Center(child: _CercleEnvoi(progression: progression)),
          ],
        ),
      ),
    );
  }
}

/// Le petit cercle de progression d'un envoi, sur un disque sombre.
class _CercleEnvoi extends StatelessWidget {
  const _CercleEnvoi({required this.progression});

  final ValueListenable<double>? progression;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    Widget cercle(double? valeur) => Semantics(
      liveRegion: true,
      label: valeur == null
          ? t.com.messages.images.preparation
          : LibellesGroupe.valeurSeule(
              t.com.messages.images.envoiEnCours(
                pourcent: '${(valeur * 100).round()}',
              ),
            ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surfaceInverse.background,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SizedBox.square(
            dimension: AppSpacing.xxl,
            child: CircularProgressIndicator(
              value: valeur,
              strokeWidth: 3,
              color: palette.surfaceInverse.onBackground,
            ),
          ),
        ),
      ),
    );
    final ValueListenable<double>? p = progression;
    if (p == null) return cercle(null);
    return ValueListenableBuilder<double>(
      valueListenable: p,
      builder: (BuildContext _, double valeur, Widget? _) =>
          cercle(valeur <= 0 ? null : valeur),
    );
  }
}

/// Une image retiree ou expiree : une fine ligne discrete, a la place du cadre
/// vide, de la largeur de son contenu.
class LigneImageRetiree extends StatelessWidget {
  /// Cree la ligne.
  const LigneImageRetiree({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          AppIcons.imageRetiree.repos,
          size: AppSpacing.lg,
          color: palette.inkMuted.asIconTheme().color,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(t.com.messages.images.retiree, style: corps)),
      ],
    );
  }
}
