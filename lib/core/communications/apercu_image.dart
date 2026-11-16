// IMAGES-MESSAGERIE : l'apercu en grand d'une image de message (plan du
// directeur du 16/11/2026) : plein ecran sur fond sombre, zoom a deux doigts
// et double toucher qui zoome (`InteractiveViewer`), glisser vers le bas ou
// croix pour fermer, le texte du message en bas, « Enregistrer l'image ».
//
// L'adresse de l'image COMPLETE n'est demandee qu'a l'ouverture (jamais
// prechargee) ; la miniature, deja a l'ecran, remplit la place en attendant.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../tc_telechargement/port_enregistrement_fichier.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/action_principale.dart';
import '../widgets/bouton_icone.dart';
import '../widgets/pressable.dart';
import 'image_bulle.dart';
import 'image_message.dart';

/// Ouvre l'apercu de [image]. [adresseComplete] est appelee UNE fois, a
/// l'ouverture ; [miniature] remplit la place en attendant.
Future<void> ouvrirApercuImage(
  BuildContext context, {
  required ImageMessage image,
  required Future<AdresseImage?> Function() adresseComplete,
  AdresseImage? miniature,
  String texte = '',
}) {
  // Les transitions viennent du theme (catalogue `AppTransitions`) : aucune
  // transition n'est definie ici.
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext _) => ApercuImage(
        image: image,
        adresseComplete: adresseComplete,
        miniature: miniature,
        texte: texte,
      ),
    ),
  );
}

/// L'ecran de l'apercu en grand.
class ApercuImage extends ConsumerStatefulWidget {
  /// Cree l'apercu.
  const ApercuImage({
    required this.image,
    required this.adresseComplete,
    super.key,
    this.miniature,
    this.texte = '',
  });

  /// L'image (dimensions, couleur moyenne).
  final ImageMessage image;

  /// Demande l'adresse de l'image complete (a l'ouverture seulement).
  final Future<AdresseImage?> Function() adresseComplete;

  /// La miniature deja connue.
  final AdresseImage? miniature;

  /// Le texte du message, au bas de l'ecran.
  final String texte;

  /// La cle de la croix, pour les tests.
  static const ValueKey<String> cleFermer = ValueKey<String>('apercu-fermer');

  /// La cle de « Enregistrer l'image », pour les tests.
  static const ValueKey<String> cleEnregistrer = ValueKey<String>(
    'apercu-enregistrer',
  );

  @override
  ConsumerState<ApercuImage> createState() => _ApercuImageState();
}

class _ApercuImageState extends ConsumerState<ApercuImage> {
  final TransformationController _transformation = TransformationController();
  late final Future<AdresseImage?> _complete = widget.adresseComplete();
  AdresseImage? _adresse;
  String? _etat;

  @override
  void initState() {
    super.initState();
    _complete.then<void>((AdresseImage? a) {
      if (mounted) setState(() => _adresse = a);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  double get _echelle => _transformation.value.getMaxScaleOnAxis();

  /// Le double toucher zoome (a 2,5), ou revient a la taille d'origine.
  void _doubleToucher() {
    _transformation.value = _echelle > 1.05
        ? Matrix4.identity()
        : (Matrix4.identity()..scaleByDouble(2.5, 2.5, 1, 1));
  }

  /// Glisser vers le bas, image non agrandie : on ferme.
  void _finGeste(ScaleEndDetails d) {
    if (_echelle <= 1.05 && d.velocity.pixelsPerSecond.dy > 700) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _enregistrer() async {
    setState(() => _etat = null);
    try {
      final AdresseImage? a = _adresse ?? await _complete;
      if (a == null) throw StateError('image retiree');
      final Uint8List octets =
          a.octets ?? (await http.readBytes(Uri.parse(a.url)));
      final String? destination = await ref
          .read(portEnregistrementFichierProvider)
          .enregistrerCopie(
            octets: octets,
            nomFichierPropose: 'image.jpg',
            typeMime: 'image/jpeg',
          );
      // Une annulation n'est pas une erreur : aucun message.
      if (mounted && destination != null) {
        setState(() => _etat = t.com.messages.images.enregistree);
      }
    } on Object {
      if (mounted) {
        setState(() => _etat = t.com.messages.images.enregistrementEchec);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AdresseImage? source = _adresse ?? widget.miniature;
    final TextStyle corps = palette.surfaceInverse.applyTo(
      Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
    );
    return Scaffold(
      backgroundColor: palette.surfaceInverse.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Pressable(
                      onPress: null,
                      onDoubleTap: _doubleToucher,
                      respecterCibleTactile: false,
                      libelleSemantique: t.com.messages.images.imageJointe,
                      child: InteractiveViewer(
                        transformationController: _transformation,
                        maxScale: 6,
                        onInteractionEnd: _finGeste,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: widget.image.rapport,
                            child: LayoutBuilder(
                              builder: (BuildContext _, BoxConstraints c) =>
                                  ImageDeBulle(
                                    image: widget.image,
                                    taille: TailleImageBulle(
                                      c.maxWidth,
                                      c.maxHeight,
                                    ),
                                    adresse: source,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (widget.texte.isNotEmpty) ...<Widget>[
                          Text(widget.texte, style: corps),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: ActionPrincipale(
                                key: ApercuImage.cleEnregistrer,
                                libelle: t.com.messages.images.enregistrer,
                                onPress: _enregistrer,
                                niveau: NiveauAction.secondaire,
                                pleineLargeur: false,
                                compacte: true,
                                prefixe: Icon(AppIcons.telecharger.repos),
                              ),
                            ),
                            if (_etat != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(_etat!, style: corps),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.sm,
              end: AppSpacing.sm,
              child: BoutonIcone(
                key: ApercuImage.cleFermer,
                icone: AppIcons.fermer,
                libelle: t.com.messages.images.fermer,
                onPress: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
