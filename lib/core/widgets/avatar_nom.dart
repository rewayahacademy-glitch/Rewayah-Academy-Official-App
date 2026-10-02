import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'avatar_tile.dart';

export 'avatar_tile.dart' show AppAvatar;

/// Comment l'avatar et son nom se posent l'un par rapport a l'autre.
enum DispositionAvatar {
  /// Avatar centre dans son bloc, nom centre dessous, sur le meme axe.
  vertical,

  /// Avatar au bord de debut, nom (et au plus une ligne de role) centre
  /// verticalement sur le cercle.
  enLigne,
}

/// Un avatar et son nom : **le seul couple avatar + nom de l'application**
/// (AVATAR-1, revue du directeur des 01 et 02/10/2026).
///
/// Les regles du directeur, fixees ici une fois pour toutes :
///
/// - l'avatar est un **petit cercle**, de la taille d'un jeton ([AppAvatar]) ;
/// - en disposition [DispositionAvatar.vertical], l'avatar est centre
///   horizontalement dans son bloc, le nom centre dessous : **ils partagent le
///   meme axe central** (le nom est un `Text` centre dans une colonne centree,
///   jamais aligne au debut) ;
/// - en disposition [DispositionAvatar.enLigne], le texte (nom, et au plus une
///   ligne de [role]) est **centre verticalement sur le cercle** ;
/// - le texte se reduit au strict necessaire : un nom, une ligne de role. Le
///   reste appartient a la carte qui porte l'avatar, pas a l'avatar ;
/// - **jamais de carre ni de fond carre derriere l'avatar** : le cercle reste
///   seul. Le bandeau de couleur du foyer (FOY-COUL-1) se pose sur le
///   conteneur (la carte), jamais sur l'avatar : ce composant n'a donc aucun
///   fond propre et reste compatible.
///
/// L'avatar est decoratif pour un lecteur d'ecran (ses initiales redisent le
/// nom) : il est exclu de la semantique, le nom et le role se lisent.
///
/// [avatar] remplace le cercle d'initiales quand l'ecran sait poser un portrait
/// (`PhotoEleve`, `PhotoEnseignant`) ; il doit rester un cercle de [diametre].
class AvatarNom extends StatelessWidget {
  /// Cree un couple avatar + nom. Preferer [AvatarNom.vertical] ou
  /// [AvatarNom.enLigne], qui disent la disposition.
  const AvatarNom({
    required this.prenom,
    required this.disposition,
    super.key,
    this.nom,
    this.role,
    this.urlSignee,
    this.diametre = AppAvatar.moyen,
    this.avatar,
    this.enveloppeAvatar,
    this.styleNom,
    this.styleRole,
    this.fin,
    this.ecart,
    this.afficherNom = true,
    this.ajuste = false,
    this.roleWidget,
  });

  /// Avatar centre, nom centre dessous.
  const AvatarNom.vertical({
    required String prenom,
    Key? key,
    String? nom,
    String? role,
    String? urlSignee,
    double diametre = AppAvatar.moyen,
    Widget? avatar,
    Widget Function(Widget avatar)? enveloppeAvatar,
    TextStyle? styleNom,
    TextStyle? styleRole,
    bool afficherNom = true,
  }) : this(
         prenom: prenom,
         disposition: DispositionAvatar.vertical,
         afficherNom: afficherNom,
         key: key,
         nom: nom,
         role: role,
         urlSignee: urlSignee,
         diametre: diametre,
         avatar: avatar,
         enveloppeAvatar: enveloppeAvatar,
         styleNom: styleNom,
         styleRole: styleRole,
       );

  /// Avatar au bord de debut, nom centre verticalement sur le cercle.
  const AvatarNom.enLigne({
    required String prenom,
    Key? key,
    String? nom,
    String? role,
    String? urlSignee,
    double diametre = AppAvatar.moyen,
    Widget? avatar,
    Widget Function(Widget avatar)? enveloppeAvatar,
    TextStyle? styleNom,
    TextStyle? styleRole,
    Widget? fin,
    double? ecart,
    bool ajuste = false,
    Widget? roleWidget,
  }) : this(
         prenom: prenom,
         disposition: DispositionAvatar.enLigne,
         key: key,
         nom: nom,
         role: role,
         urlSignee: urlSignee,
         diametre: diametre,
         avatar: avatar,
         enveloppeAvatar: enveloppeAvatar,
         styleNom: styleNom,
         styleRole: styleRole,
         fin: fin,
         ecart: ecart,
         ajuste: ajuste,
         roleWidget: roleWidget,
       );

  /// Le prenom, source des initiales de repli.
  final String prenom;

  /// La disposition.
  final DispositionAvatar disposition;

  /// Le nom affiche, quand il differe du [prenom] (« Sayyid Youssef »).
  /// `null` : le [prenom] est affiche.
  final String? nom;

  /// Au plus une ligne de role, sous le nom. `null` : aucune.
  final String? role;

  /// A la place de [role] : l'unique ligne de role quand elle porte un signe
  /// (point de statut) en plus du texte. Compte comme la ligne de role.
  final Widget? roleWidget;

  /// URL signee de la photo, quand l'ecran en a une.
  final String? urlSignee;

  /// Le diametre du cercle, pris dans [AppAvatar].
  final double diametre;

  /// Un avatar deja construit (portrait), a la place des initiales.
  final Widget? avatar;

  /// Habille le cercle sans le deformer : anneau de selection, pastille de
  /// statut. Recoit le cercle, rend un widget de meme encombrement central.
  final Widget Function(Widget avatar)? enveloppeAvatar;

  /// Style du nom ; par defaut `labelLarge` en encre forte.
  final TextStyle? styleNom;

  /// Style du role ; par defaut `bodySmall` en encre attenuee.
  final TextStyle? styleRole;

  /// En ligne seulement : ce qui ferme la rangee (chevron, valeur).
  final Widget? fin;

  /// Faux quand le nom est deja ecrit juste a cote par le conteneur (cadre de
  /// salle : le nom est sur le bandeau du cadre) : seuls restent le cercle et,
  /// au plus, la ligne de [role].
  final bool afficherNom;

  /// En ligne seulement : vrai pour une rangee qui prend la largeur de son
  /// contenu (en-tete, menu) au lieu de remplir celle de son parent.
  final bool ajuste;

  /// En ligne seulement : l'espace entre le cercle et le texte
  /// (defaut [AppSpacing.md]).
  final double? ecart;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleDuNom =
        styleNom ??
        palette.inkStrong.applyTo(textes.labelLarge ?? const TextStyle());
    final TextStyle styleDuRole =
        styleRole ??
        palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle());
    final String affiche = nom ?? prenom;
    final String? ligneRole = (role == null || role!.isEmpty) ? null : role;

    final Widget cercle = ExcludeSemantics(
      child: SizedBox.square(
        dimension: diametre,
        child:
            avatar ??
            AvatarTile(
              prenom: prenom,
              urlSignee: urlSignee,
              diametre: diametre,
            ),
      ),
    );
    final Widget cercleHabille = enveloppeAvatar == null
        ? cercle
        : enveloppeAvatar!(cercle);

    return switch (disposition) {
      DispositionAvatar.vertical => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          cercleHabille,
          if (afficherNom || ligneRole != null) Ecart.vXs,
          if (afficherNom)
            Text(affiche, textAlign: TextAlign.center, style: styleDuNom),
          if (ligneRole != null)
            Text(ligneRole, textAlign: TextAlign.center, style: styleDuRole),
        ],
      ),
      DispositionAvatar.enLigne => Row(
        mainAxisSize: ajuste ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          cercleHabille,
          SizedBox(width: ecart ?? AppSpacing.md),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(affiche, style: styleDuNom),
                if (roleWidget != null)
                  roleWidget!
                else if (ligneRole != null)
                  Text(ligneRole, style: styleDuRole),
              ],
            ),
          ),
          if (fin != null) ...<Widget>[Ecart.hSm, fin!],
        ],
      ),
    };
  }
}

/// Ce qui occupe un cadre video sans image (salle, classe live, vignette
/// d'observation) : un petit cercle, centre dans la zone libre du cadre, avec au
/// plus une ligne de legende dessous.
///
/// Le cadre pose son propre nom en bas ([reserveBas] laisse la place a cette
/// bande) : l'avatar ne le redit pas. [FittedBox] reduit le bloc plutot que de
/// le laisser deborder, dans une vignette courte comme a 200 % de texte
/// (CTRL-SALLE-1 : « l'avatar deborde de son cadre »).
class AvatarSansImage extends StatelessWidget {
  /// Cree le bloc.
  const AvatarSansImage({
    required this.prenom,
    super.key,
    this.legende,
    this.styleLegende,
    this.reserveBas = AppSpacing.xxxl,
  });

  /// Le prenom, source des initiales.
  final String prenom;

  /// La ligne de legende (« Sans image »), ou `null` quand le cadre est trop
  /// court pour la porter.
  final String? legende;

  /// Le style de la legende, dans l'encre du registre du cadre.
  final TextStyle? styleLegende;

  /// La hauteur laissee libre en bas, pour la bande du nom du cadre.
  final double reserveBas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        end: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: reserveBas,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AvatarNom.vertical(
            prenom: prenom,
            afficherNom: false,
            role: legende,
            styleRole: styleLegende,
          ),
        ),
      ),
    );
  }
}
