import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'avatar_nom.dart';
import 'pastille_etat_seance.dart';
import 'pressable.dart';

/// Le point de statut d'un profil, pris dans `AppPalette.pointsStatut`.
enum PointStatut {
  /// En seance, present.
  succes,

  /// A venir, a surveiller.
  attention,

  /// Interrompu, bloque.
  alerte,

  /// Inactif.
  neutre,
}

/// Un profil du [SelecteurProfils].
///
/// Le point de statut est **toujours double** par [etat], le sous-libelle
/// visible : un point seul ne dit rien a qui ne distingue pas les couleurs, et
/// rien du tout a un lecteur d'ecran.
@immutable
class ProfilSelectionnable {
  /// Cree un profil.
  const ProfilSelectionnable({
    required this.id,
    required this.prenom,
    required this.etat,
    this.urlPhoto,
    this.point,
    this.enDirect = false,
    this.annulee = false,
  });

  /// Vrai quand la seance du profil est annulee : l'icone d'annulation
  /// remplace le point (ANNUL-VIS-1). Le mot est dans [etat].
  final bool annulee;

  /// Vrai quand la seance du profil est en direct : le point bat doucement
  /// (le meme point que la pastille « En direct », ON-AIR-1).
  final bool enDirect;

  /// L'identifiant du profil eleve.
  final String id;

  /// Le prenom affiche. Le profil du titulaire figure avec son prenom, jamais
  /// sous le mot « enfant ».
  final String prenom;

  /// L'etat reel, en mots courts, venu du meme calcul que la carte de seance :
  /// « En seance », « Dans 3 h », « Aucun cours ».
  final String etat;

  /// Photo reelle (URL signee courte), sinon l'initiale.
  final String? urlPhoto;

  /// Le point de statut. `null` : pas de point.
  final PointStatut? point;
}

/// Le selecteur de profils eleves de l'Accueil et de l'Historique (maquettes
/// V1, V2, V8 D2 ; manifeste visuel Tuteur V1 section 3.4).
///
/// Une rangee d'avatars : initiale ou photo, point de statut cercle de la
/// couleur du fond, prenom, sous-libelle d'etat ; le profil selectionne
/// porte un anneau `surfacePrimary` de 2 et son sous-libelle passe en encre
/// d'accent. Le dernier item, « Ajouter », ouvre l'ajout d'un profil eleve.
/// Defilement horizontal sur telephone ; sur les grands ecrans, la meme
/// rangee, alignee au debut, avec des avatars plus grands (48 contre 64).
///
/// Chaque item est une cible d'au moins 48, lue « Prenom, etat » et annoncee
/// « selectionne » ; « Ajouter » est lu « Ajouter un profil eleve ».
class SelecteurProfils extends StatelessWidget {
  /// Cree un selecteur.
  const SelecteurProfils({
    required this.profils,
    required this.selectionId,
    required this.onSelection,
    super.key,
    this.onAjouter,
  });

  /// Les profils, dans l'ordre rendu par le contrat K1.
  final List<ProfilSelectionnable> profils;

  /// L'identifiant du profil selectionne.
  final String? selectionId;

  /// Rappele avec l'identifiant du profil presse.
  final ValueChanged<String> onSelection;

  /// L'ajout d'un profil eleve. Sans lui, pas d'item « Ajouter ».
  final VoidCallback? onAjouter;

  /// Diametre d'avatar sur telephone : 48 ([AppAvatar.moyen]).
  static const double diametreMobile = AppAvatar.moyen;

  /// Diametre d'avatar sur tablette et bureau : 64 ([AppAvatar.grand]).
  static const double diametreLarge = AppAvatar.grand;

  /// Diametre du point de statut.
  static const double diametrePoint = AppSpacing.md;

  /// Epaisseur de l'anneau de selection et du contour « Ajouter ».
  static const double epaisseurAnneau = 2;

  @override
  Widget build(BuildContext context) {
    final double diametre = AppGabarit.de(context) == Gabarit.mobile
        ? diametreMobile
        : diametreLarge;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final ProfilSelectionnable profil in profils) ...<Widget>[
            _Item(
              profil: profil,
              selectionne: profil.id == selectionId,
              diametre: diametre,
              onPress: () => onSelection(profil.id),
            ),
            Ecart.hMd,
          ],
          if (onAjouter != null)
            _Ajouter(diametre: diametre, onPress: onAjouter!),
        ],
      ),
    );
  }
}

/// La couronne d'un avatar : l'avatar, sa marge de 4, et l'anneau eventuel.
class _Couronne extends StatelessWidget {
  const _Couronne({required this.diametre, required this.child, this.anneau});

  final double diametre;
  final Widget child;
  final BorderSide? anneau;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diametre + 2 * AppSpacing.xs,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: anneau == null ? null : Border.fromBorderSide(anneau!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: child,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.profil,
    required this.selectionne,
    required this.diametre,
    required this.onPress,
  });

  final ProfilSelectionnable profil;
  final bool selectionne;
  final double diametre;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final PointStatut? point = profil.point;
    final TextStyle styleNom = palette.inkStrong.applyTo(
      textes.labelLarge ?? const TextStyle(),
    );
    final TextStyle styleEtat =
        (selectionne ? palette.inkAccent : palette.inkMuted).applyTo(
          textes.bodySmall ?? const TextStyle(),
        );

    return Semantics(
      selected: selectionne,
      child: Pressable(
        onPress: onPress,
        libelleSemantique: t.commun.selecteurProfils.etiquette(
          prenom: profil.prenom,
          etat: profil.etat,
        ),
        arrondiFocus: AppRadius.arrondiSm,
        child: ExcludeSemantics(
          // AVATAR-1 : avatar centre, prenom et etat centres dessous sur le
          // meme axe (composant partage). L'anneau de selection et le point de
          // statut habillent le cercle sans le deformer.
          //
          // DUREE-INSECABLE-1 : l'item a la largeur de sa couronne, de son
          // prenom entier ou du plus long mot de son etat. L'etat passe a la
          // ligne entre ses mots (« Aucune / séance ») au lieu de deborder
          // de la rangee et d'etre rogne au bord de l'ecran (« Aucune séan »).
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _largeurItem(context, styleNom, styleEtat),
            ),
            child: AvatarNom.vertical(
              prenom: profil.prenom,
              urlSignee: profil.urlPhoto,
              diametre: diametre,
              role: profil.etat,
              styleNom: styleNom,
              styleRole: styleEtat,
              enveloppeAvatar: (Widget avatar) => Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  _Couronne(
                    diametre: diametre,
                    anneau: selectionne
                        ? BorderSide(
                            color: palette.surfacePrimary.background,
                            width: SelecteurProfils.epaisseurAnneau,
                          )
                        : null,
                    child: avatar,
                  ),
                  if (point != null)
                    PositionedDirectional(
                      end: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                      child: profil.annulee
                          ? PointAnnulation(cerclage: palette.surfaceCanvas)
                          : profil.enDirect
                          ? PointDirect(
                              diametre: SelecteurProfils.diametrePoint,
                              cerclage: palette.surfaceCanvas,
                            )
                          : SizedBox.square(
                              dimension: SelecteurProfils.diametrePoint,
                              child: DecoratedBox(
                                decoration: _couleurPoint(
                                  palette,
                                  point,
                                ).pastille(cerclage: palette.surfaceCanvas),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// La largeur maximale de l'item : couronne, prenom entier (une ligne,
  /// comme avant), plus long mot de l'etat, a l'echelle de texte courante.
  double _largeurItem(
    BuildContext context,
    TextStyle styleNom,
    TextStyle styleEtat,
  ) {
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextPainter nom = TextPainter(
      text: TextSpan(
        text: profil.prenom,
        style: DefaultTextStyle.of(context).style.merge(styleNom),
      ),
      textDirection: Directionality.of(context),
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    final double largeurNom = nom.width;
    nom.dispose();
    final double motEtat = largeurMotLePlusLong(
      context,
      profil.etat,
      styleEtat,
      echelle,
    );
    final double couronne = diametre + 2 * AppSpacing.xs;
    // La marge d'arrondi des glyphes (comme `TexteSansCoupure`).
    const double marge = 2;
    return <double>[
      couronne,
      largeurNom + marge,
      motEtat + marge,
    ].reduce((double a, double b) => a > b ? a : b);
  }

  static AppIndicatorColor _couleurPoint(
    AppPalette palette,
    PointStatut point,
  ) => switch (point) {
    PointStatut.succes => palette.pointsStatut.succes,
    PointStatut.attention => palette.pointsStatut.attention,
    PointStatut.alerte => palette.pointsStatut.alerte,
    PointStatut.neutre => palette.pointsStatut.neutre,
  };
}

class _Ajouter extends StatelessWidget {
  const _Ajouter({required this.diametre, required this.onPress});

  final double diametre;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // Contour plein dans les deux themes : le pointille des maquettes
    // sombres (V2 B, C) est ecarte par le manifeste.
    return Pressable(
      onPress: onPress,
      libelleSemantique: t.commun.selecteurProfils.ajouterSemantique,
      arrondiFocus: AppRadius.arrondiSm,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Couronne(
              diametre: diametre,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    palette.inkAccent.asBorderSide(
                      width: SelecteurProfils.epaisseurAnneau,
                    ),
                  ),
                ),
                child: Center(
                  child: IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                    child: Icon(AppIcons.ajouter.repos),
                  ),
                ),
              ),
            ),
            Ecart.vXs,
            Text(
              t.commun.selecteurProfils.ajouter,
              style: palette.inkAccent.applyTo(
                textes.labelLarge ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
