import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/skeleton.dart';
import 'textes_dossier.dart';

/// Construit l'image d'une URL courte. `NetworkImage` en production ; les
/// tests posent une image en memoire.
final Provider<ImageProvider<Object> Function(Uri url)> imagePieceProvider =
    Provider<ImageProvider<Object> Function(Uri url)>(
      (Ref ref) =>
          (Uri url) => NetworkImage(url.toString()),
    );

/// Ouvre la visionneuse de la piece (AD-7) par le composant partage
/// [AppBottomSheet.ouvrirLecture]. La future se complete a la fermeture,
/// quel qu'en soit le chemin : l'appelant y rend le focus.
Future<void> ouvrirVisionneusePiece(
  BuildContext context, {
  required DossierPourRevue dossier,
  ValueChanged<bool>? onLecture,
}) async {
  final TypePiece? type = dossier.typePiece;
  await AppBottomSheet.ouvrirLecture<void>(
    context,
    titre: t.dossiers.revue.piece,
    sousTitre: type == null ? null : libelleTypePiece(type),
    libelleFermer: t.dossiers.visionneuse.fermerPiece,
    constructeur: (BuildContext _) =>
        VisionneusePiece(dossier: dossier, onLecture: onLecture),
  );
}

enum _Etat {
  chargement,
  contenu,
  format,
  erreur,
  indisponible,
  expire,
  accesRetire,
  horsLigne,
  aucune,
}

class _AgrandirIntent extends Intent {
  const _AgrandirIntent();
}

class _ReduireIntent extends Intent {
  const _ReduireIntent();
}

class _AjusterIntent extends Intent {
  const _AjusterIntent();
}

/// La visionneuse : lecture et zoom seulement, jamais de decision.
class VisionneusePiece extends ConsumerStatefulWidget {
  /// Cree la visionneuse du dossier.
  const VisionneusePiece({required this.dossier, super.key, this.onLecture});

  /// Le dossier dont la piece est lue.
  final DossierPourRevue dossier;

  /// Vrai quand la piece s'est affichee (premiere image peinte) ; faux sur
  /// un echec de lecture (erreur, format, acces retire, indisponible,
  /// aucune). La revue y ouvre ou referme ses verifications (P-ADM-06).
  final ValueChanged<bool>? onLecture;

  /// Echelle maximale (400 %).
  static const double echelleMax = 4;

  /// Pas des commandes nommees (25 %).
  static const double pas = 0.25;

  @override
  ConsumerState<VisionneusePiece> createState() => _VisionneusePieceState();
}

class _VisionneusePieceState extends ConsumerState<VisionneusePiece> {
  /// Garde a travers les renouvellements : le zoom est conserve.
  final TransformationController _zoom = TransformationController();
  _Etat _etat = _Etat.chargement;
  VuePiece? _vue;
  ImageProvider<Object>? _image;
  Size _zone = Size.zero;
  final FocusNode _focusFermer = FocusNode(debugLabel: 'visionneuse-fermer');
  bool _lue = false;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_rafraichir);
    unawaited(_charger());
    // Focus initial sur un element qui porte un anneau (« Fermer »), jamais
    // sur un noeud invisible ; les raccourcis restent sur la surface.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusFermer.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _zoom
      ..removeListener(_rafraichir)
      ..dispose();
    _oublierImage();
    _focusFermer.dispose();
    super.dispose();
  }

  void _rafraichir() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Signale a la revue une lecture reussie (une fois) ou un echec.
  void _signaler(_Etat etat) {
    final ValueChanged<bool>? rappel = widget.onLecture;
    if (rappel == null) {
      return;
    }
    switch (etat) {
      case _Etat.erreur ||
          _Etat.format ||
          _Etat.accesRetire ||
          _Etat.indisponible ||
          _Etat.aucune:
        _lue = false;
        rappel(false);
      case _Etat.chargement || _Etat.contenu || _Etat.expire || _Etat.horsLigne:
        break;
    }
  }

  /// La premiere image peinte : la piece a ete vue.
  void _affichee() {
    if (_lue) {
      return;
    }
    _lue = true;
    final ValueChanged<bool>? rappel = widget.onLecture;
    if (rappel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => rappel(true));
    }
  }

  /// Purge l'image du cache : l'URL ne survit pas a la lecture.
  void _oublierImage() {
    unawaited(_image?.evict());
    _image = null;
  }

  Future<void> _charger() async {
    final String? documentId = widget.dossier.documentId;
    if (documentId == null) {
      setState(() => _etat = _Etat.aucune);
      _signaler(_Etat.aucune);
      return;
    }
    setState(() => _etat = _Etat.chargement);
    if (ref.read(horsLigneProvider).value ?? false) {
      setState(() => _etat = _Etat.horsLigne);
      return;
    }
    _Etat suivant;
    VuePiece? vue;
    try {
      vue = await ref
          .read(portRevueDossiersProvider)
          .demanderVuePiece(
            dossierId: widget.dossier.dossierId,
            documentId: documentId,
          );
      suivant = vue.typeMime.startsWith('image/')
          ? _Etat.contenu
          : _Etat.format;
    } on ErreurRevueDossier catch (e) {
      suivant = switch (e.code) {
        CodeErreurRevue.expire => _Etat.expire,
        CodeErreurRevue.typeNonPrisEnCharge => _Etat.format,
        CodeErreurRevue.interdit ||
        CodeErreurRevue.nonAutorise => _Etat.accesRetire,
        CodeErreurRevue.indisponibleTemporairement => _Etat.indisponible,
        _ => _Etat.erreur,
      };
    } on CapaciteIndisponible {
      suivant = _Etat.indisponible;
    } on Object {
      suivant = _Etat.erreur;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _oublierImage();
      _vue = suivant == _Etat.contenu ? vue : null;
      final SourcePiece? source = _vue?.source;
      if (source is SourcePieceUrl) {
        _image = ref.read(imagePieceProvider)(source.url);
      }
      _etat = suivant;
    });
    _signaler(suivant);
  }

  /// L'image n'a pas pu etre lue : expiree si l'echeance est passee.
  void _echecImage() {
    final VuePiece? vue = _vue;
    final bool expiree =
        vue != null && !DateTime.now().toUtc().isBefore(vue.expireLeUtc);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _etat == _Etat.contenu) {
        setState(() {
          _oublierImage();
          _vue = null;
          _etat = expiree ? _Etat.expire : _Etat.erreur;
        });
        _signaler(_etat);
      }
    });
  }

  double get _echelle => _zoom.value.getMaxScaleOnAxis();

  void _poserEchelle(double echelle) {
    final double e = echelle.clamp(1, VisionneusePiece.echelleMax);
    if ((e - 1).abs() < 1e-6) {
      _zoom.value = Matrix4.identity();
      return;
    }
    final Offset c = _zone.center(Offset.zero);
    _zoom.value = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(e, e, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }

  bool get _peutAgrandir => _echelle < VisionneusePiece.echelleMax - 1e-6;
  bool get _peutReduire => _echelle > 1 + 1e-6;

  void _agrandir() {
    if (_peutAgrandir) {
      const double p = VisionneusePiece.pas;
      _poserEchelle(((_echelle + 1e-6) / p).floor() * p + p);
    }
  }

  void _reduire() {
    if (_peutReduire) {
      const double p = VisionneusePiece.pas;
      _poserEchelle(((_echelle - 1e-6) / p).ceil() * p - p);
    }
  }

  void _ajuster() => _zoom.value = Matrix4.identity();

  void _fermer() => unawaited(Navigator.of(context).maybePop());

  @override
  Widget build(BuildContext context) {
    final bool contenu = _etat == _Etat.contenu;
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.equal): _AgrandirIntent(),
        SingleActivator(LogicalKeyboardKey.add): _AgrandirIntent(),
        SingleActivator(LogicalKeyboardKey.numpadAdd): _AgrandirIntent(),
        SingleActivator(LogicalKeyboardKey.minus): _ReduireIntent(),
        SingleActivator(LogicalKeyboardKey.numpadSubtract): _ReduireIntent(),
        SingleActivator(LogicalKeyboardKey.digit0): _AjusterIntent(),
        SingleActivator(LogicalKeyboardKey.numpad0): _AjusterIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AgrandirIntent: CallbackAction<_AgrandirIntent>(
            onInvoke: (_) => contenu ? _agrandir() : null,
          ),
          _ReduireIntent: CallbackAction<_ReduireIntent>(
            onInvoke: (_) => contenu ? _reduire() : null,
          ),
          _AjusterIntent: CallbackAction<_AjusterIntent>(
            onInvoke: (_) => contenu ? _ajuster() : null,
          ),
        },
        child: Focus(
          skipTraversal: true,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final Widget actions = _actions(contenu);
              // AD-11 (1.4.10) : a 400 % (320x256), la visionneuse n'a que
              // 108 de haut et les actions empilees en prennent 108 (16 en
              // bas). Sous 360, la piece garde la hauteur de la vue et les
              // actions defilent dessous ; au-dessus, rendu inchange.
              if (c.maxHeight.isFinite && c.maxHeight < 360) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(height: c.maxHeight, child: _corps(context)),
                      Ecart.vLg,
                      actions,
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _corps(context)),
                  Ecart.vLg,
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _actions(bool contenu) =>
      // Zoom au debut, « Fermer » au contenu a la fin, sur la meme
      // ligne ; OverflowBar mesure et empile seulement si le texte
      // agrandi deborde (maquette 02C, contrat B).
      OverflowBar(
        alignment: contenu
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          if (contenu)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _BoutonZoom(
                  icone: AppIcons.moins,
                  libelle: t.dossiers.visionneuse.reduire,
                  touche: '-',
                  onPress: _peutReduire ? _reduire : null,
                ),
                Ecart.hSm,
                _BoutonZoom(
                  icone: AppIcons.ajouter,
                  libelle: t.dossiers.visionneuse.agrandir,
                  touche: '+',
                  onPress: _peutAgrandir ? _agrandir : null,
                ),
                Ecart.hSm,
                _BoutonZoom(
                  icone: AppIcons.ajusterEcran,
                  libelle: t.dossiers.visionneuse.ajuster,
                  touche: '0',
                  onPress: _ajuster,
                ),
              ],
            ),
          // IntrinsicWidth : au contenu, jamais etire (comme les
          // actions de la revue).
          IntrinsicWidth(
            child: ActionPrincipale(
              libelle: t.commun.fermer,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              focusNode: _focusFermer,
              onPress: _fermer,
            ),
          ),
        ],
      );

  Widget _corps(BuildContext context) {
    final Traductions$dossiers$visionneuse$fr v = t.dossiers.visionneuse;
    Widget etat({
      required NatureEtat nature,
      required String phrase,
      String? action,
      VoidCallback? onAction,
    }) => Center(
      child: SingleChildScrollView(
        child: Semantics(
          liveRegion: true,
          child: EtatSysteme(
            nature: nature,
            titre: phrase,
            // Phrase vide : seul le texte exact de la spec s'affiche, sans la
            // phrase generique commun.etats.* (§11.5, §26 ter).
            phrase: '',
            libelleAction: action,
            onAction: onAction,
          ),
        ),
      ),
    );

    return switch (_etat) {
      _Etat.chargement => Semantics(
        liveRegion: true,
        label: v.chargement,
        child: Center(
          child: AspectRatio(
            aspectRatio: _PieceFictive.ratio,
            // Hauteur mesuree : `Skeleton` pose ses blocs dans une colonne
            // non bornee, une hauteur infinie y echoue (HL-A-3, capture).
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints boite) =>
                  Skeleton(hauteur: boite.maxHeight),
            ),
          ),
        ),
      ),
      _Etat.contenu => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          _zone = c.biggest;
          return ClipRect(
            child: InteractiveViewer(
              transformationController: _zoom,
              // Aucun geste (pincement, Ctrl+molette) sous 100 % (Q25).
              minScale: 1,
              maxScale: VisionneusePiece.echelleMax,
              child: Center(child: _imagePiece(context)),
            ),
          );
        },
      ),
      _Etat.format => etat(
        nature: NatureEtat.introuvable,
        phrase: v.formatNonPrisEnCharge,
      ),
      _Etat.erreur => etat(
        nature: NatureEtat.echecServeur,
        phrase: v.erreur,
        action: t.commun.reessayer,
        onAction: () => unawaited(_charger()),
      ),
      _Etat.indisponible => etat(
        nature: NatureEtat.indisponible,
        phrase: t.dossiers.revue.pieceIndisponible,
      ),
      _Etat.expire => etat(
        nature: NatureEtat.ressourceExpiree,
        phrase: v.expire,
        action: v.recharger,
        onAction: () => unawaited(_charger()),
      ),
      _Etat.accesRetire => etat(
        nature: NatureEtat.accesRefuse,
        phrase: v.accesRetire,
      ),
      _Etat.horsLigne => etat(
        nature: NatureEtat.horsLigne,
        phrase: v.horsLigne,
        action: t.commun.reessayer,
        onAction: () => unawaited(_charger()),
      ),
      _Etat.aucune => etat(nature: NatureEtat.aucunResultat, phrase: v.aucune),
    };
  }

  Widget _imagePiece(BuildContext context) {
    final ImageProvider<Object>? image = _image;
    if (image == null) {
      _affichee();
      return const _PieceFictive();
    }
    return Image(
      image: image,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      frameBuilder:
          (BuildContext context, Widget enfant, int? image, bool synchrone) {
            if (image != null || synchrone) {
              _affichee();
            }
            return enfant;
          },
      loadingBuilder:
          (BuildContext context, Widget enfant, ImageChunkEvent? progres) =>
              progres == null
              ? enfant
              : const AspectRatio(
                  aspectRatio: _PieceFictive.ratio,
                  child: Skeleton(hauteur: double.infinity, differe: false),
                ),
      // Aucun signalement : l'URL ne part ni en console ni dans Sentry.
      errorBuilder: (BuildContext context, Object erreur, StackTrace? pile) {
        _echecImage();
        return const SizedBox.shrink();
      },
    );
  }
}

/// Un bouton icone de 48, libelle et info-bulle issus de l'i18n.
class _BoutonZoom extends StatelessWidget {
  const _BoutonZoom({
    required this.icone,
    required this.libelle,
    required this.touche,
    required this.onPress,
  });

  final AppIcon icone;
  final String libelle;

  /// La touche du raccourci, dite dans l'info-bulle (pas un texte a
  /// traduire : le symbole de la touche).
  final String touche;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Tooltip(
      message: t.dossiers.visionneuse.infoBulle(
        action: libelle,
        touche: touche,
      ),
      excludeFromSemantics: true,
      child: Pressable(
        onPress: onPress,
        actif: onPress != null,
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiFull,
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: AppTouchTarget.standard,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  palette.contourCarte.asBorderSide(),
                ),
              ),
              child: Center(
                child: IconTheme(
                  data: (onPress == null ? palette.inkMuted : palette.inkAccent)
                      .asIconTheme(size: AppSpacing.xxl),
                  child: Icon(icone.repos),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La piece de demonstration, dessinee par code : un cadre aux proportions
/// d'une carte, la mention « Document fictif », un rectangle neutre et quatre
/// barres. Aucun nom, aucune date, aucun embleme, aucun asset.
class _PieceFictive extends StatelessWidget {
  const _PieceFictive();

  /// Le rapport largeur / hauteur d'une carte (ID-1).
  static const double ratio = 1.586;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color neutre = palette.borderHairline.asBorderSide().color;
    Widget barre(double fraction) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: fraction,
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          height: AppSpacing.md,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: neutre,
              borderRadius: AppRadius.arrondiFull,
            ),
          ),
        ),
      ),
    );
    final Widget carte = DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: AppRadius.arrondiLg,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              t.dossiers.visionneuse.documentFictif,
              style: palette.surfaceSunken.applyTo(
                Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vLg,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 0.78,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: neutre,
                        borderRadius: AppRadius.arrondiSm,
                      ),
                    ),
                  ),
                  Ecart.hLg,
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        for (final double f in <double>[0.9, 0.7, 0.8, 0.5])
                          barre(f),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return AspectRatio(
      aspectRatio: ratio,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          // AD-11 (1.4.10) : a 400 % (320x256) la piece n'a que 123x60, moins
          // que ses marges (34 en bas). La piece tient lieu d'image : sous
          // 240 de large, elle est dessinee a sa taille nominale, texte non
          // agrandi, puis reduite comme une image (le zoom l'agrandit).
          // Au-dessus, rendu inchange.
          if (c.maxWidth >= 240) return carte;
          return FittedBox(
            child: SizedBox(
              width: 320,
              height: 320 / ratio,
              child: MediaQuery.withNoTextScaling(child: carte),
            ),
          );
        },
      ),
    );
  }
}
