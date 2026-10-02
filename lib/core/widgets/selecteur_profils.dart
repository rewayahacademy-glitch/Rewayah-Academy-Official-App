import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'avatar_tile.dart';
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
  });

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
/// rangee, alignee au debut, avec des avatars plus grands (56 contre 72).
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

  /// Diametre d'avatar sur telephone : 56.
  static const double diametreMobile = AppSpacing.titreEcran + AppSpacing.sm;

  /// Diametre d'avatar sur tablette et bureau : 72.
  static const double diametreLarge = AppSpacing.respiration + AppSpacing.sm;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
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
                    child: AvatarTile(
                      prenom: profil.prenom,
                      urlSignee: profil.urlPhoto,
                      diametre: diametre,
                    ),
                  ),
                  if (point != null)
                    PositionedDirectional(
                      end: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                      child: profil.enDirect
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
              Ecart.vXs,
              Text(
                profil.prenom,
                style: palette.inkStrong.applyTo(
                  textes.labelLarge ?? const TextStyle(),
                ),
              ),
              Text(
                profil.etat,
                style: (selectionne ? palette.inkAccent : palette.inkMuted)
                    .applyTo(textes.bodySmall ?? const TextStyle()),
              ),
            ],
          ),
        ),
      ),
    );
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
