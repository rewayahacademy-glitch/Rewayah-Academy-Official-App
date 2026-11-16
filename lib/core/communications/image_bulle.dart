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
import '../widgets/skeleton.dart' show ReflecAttente;
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
///
/// IMAGES-CORRECTIF (directeur, 16/11/2026) :
/// - tant que les pixels n'arrivent pas, la couleur moyenne porte le reflet lent
///   du squelette ([ReflecAttente]) ; il s'arrete des la premiere image, et
///   reste fixe sous mouvement reduit ;
/// - si la miniature est en echec (adresse refusee, objet illisible) ou si le
///   serveur n'en a pas rendu, [repli] va chercher l'image complete : jamais un
///   aplat muet.
class ImageDeBulle extends StatefulWidget {
  /// La cle du reflet d'attente, pour les tests.
  static const Key cleReflet = ValueKey<String>('image-bulle-reflet');

  /// Cree l'image de bulle.
  const ImageDeBulle({
    required this.image,
    required this.taille,
    super.key,
    this.adresse,
    this.progression,
    this.enPreparation = false,
    this.repli,
    this.adresseIntrouvable = false,
    this.attend = true,
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

  /// Va chercher l'image complete quand la miniature manque ; `null` : pas de
  /// repli.
  final Future<AdresseImage?> Function()? repli;

  /// Vrai quand la lecture des miniatures est finie et n'a rien rendu pour
  /// cette image : le repli part sans attendre une erreur.
  final bool adresseIntrouvable;

  /// Faux quand rien n'arrivera (envoi en echec) : le reflet ne tourne pas.
  final bool attend;

  @override
  State<ImageDeBulle> createState() => _EtatImageDeBulle();
}

class _EtatImageDeBulle extends State<ImageDeBulle> {
  /// La premiere image est arrivee : le reflet s'arrete.
  bool _cadre = false;

  /// La miniature a echoue au chargement.
  bool _echecMiniature = false;

  AdresseImage? _repli;
  bool _repliDemande = false;
  bool _repliEchoue = false;

  void _signaler(VoidCallback fait) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fait);
    });
  }

  void _chercherRepli() {
    final Future<AdresseImage?> Function()? repli = widget.repli;
    if (repli == null || _repliDemande) return;
    _repliDemande = true;
    repli().then<void>(
      (AdresseImage? a) {
        if (!mounted) return;
        setState(() {
          _repli = a;
          _repliEchoue = a == null;
        });
      },
      onError: (Object _) {
        if (mounted) setState(() => _repliEchoue = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ImageDeBulle w = widget;
    final Color fond =
        couleurDepuisHex(w.image.couleurMoyenne) ??
        palette.surfaceSunken.background;
    final double pixels = MediaQuery.devicePixelRatioOf(context);
    final int cache = (w.taille.largeur * pixels).round();
    final bool sansMiniature =
        w.adresse == null && w.adresseIntrouvable || _echecMiniature;
    if (sansMiniature && !_repliDemande) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _chercherRepli();
      });
    }
    // Les pixels affiches : le repli s'il est arrive, sinon la miniature.
    final AdresseImage? a = _repli ?? (_echecMiniature ? null : w.adresse);
    final Duration fondu = Mouvement.duree(context, Mouvement.moyen);
    Widget? pixelsImage;
    if (a != null) {
      Widget apparition(
        BuildContext _,
        Widget enfant,
        int? cadre,
        bool synchrone,
      ) {
        if (cadre != null && !_cadre) _signaler(() => _cadre = true);
        if (synchrone) return enfant;
        return AnimatedOpacity(
          opacity: cadre == null ? 0 : 1,
          duration: fondu,
          curve: Mouvement.entree,
          child: enfant,
        );
      }

      Widget absente(BuildContext _, Object _, StackTrace? _) {
        // La miniature echoue : le repli prend le relais. Le repli lui-meme
        // en echec laisse la couleur moyenne, sans reflet.
        if (_repli == null && !_echecMiniature) {
          _signaler(() => _echecMiniature = true);
        } else if (_repli != null && !_repliEchoue) {
          _signaler(() => _repliEchoue = true);
        }
        return const SizedBox.shrink();
      }

      pixelsImage = a.octets != null
          ? Image.memory(
              a.octets!,
              key: ValueKey<String>(a.url),
              fit: BoxFit.cover,
              cacheWidth: cache,
              frameBuilder: apparition,
              errorBuilder: absente,
              gaplessPlayback: true,
            )
          : Image.network(
              a.url,
              key: ValueKey<String>(a.url),
              fit: BoxFit.cover,
              cacheWidth: cache,
              frameBuilder: apparition,
              errorBuilder: absente,
              gaplessPlayback: true,
              // Navigateur : l'image se lit d'abord par octets (decodee a sa
              // taille), mais si le stockage n'envoie pas d'en-tete CORS sur le
              // GET, la lecture par octets est refusee : l'image passe alors
              // par une balise <img>, qui n'en exige pas. Sans cela, la bulle
              // restait un aplat de la couleur moyenne (production, 16/11).
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            );
    }
    // Le reflet tourne tant que les pixels n'arrivent pas, et s'arrete des la
    // premiere image, ou quand tout a echoue.
    final bool abandonne = _repliEchoue || (sansMiniature && w.repli == null);
    final bool reflet = w.attend && !_cadre && !abandonne;
    final bool sombre = Theme.of(context).brightness == Brightness.dark;
    final Widget surface = ColoredBox(color: fond);
    return Semantics(
      image: true,
      label: t.com.messages.images.imageJointe,
      child: SizedBox(
        width: w.taille.largeur,
        height: w.taille.hauteur,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (reflet)
              ReflecAttente(
                key: ImageDeBulle.cleReflet,
                lumiere: sombre
                    ? palette.surfaceSunken.onBackground
                    : palette.surfaceRaised.background,
                child: surface,
              )
            else
              surface,
            ?pixelsImage,
            if (w.progression != null || w.enPreparation)
              Center(child: _CercleEnvoi(progression: w.progression)),
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
