import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
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
/// Le nom et la ligne de role ne sont jamais coupes au milieu d'un mot, meme
/// a 200 % sur 320 px ([TexteSansCoupure]) : FI-2-CORR-R l'avait pose sur la
/// carte d'un membre du Foyer, la revue FI-VAGUE-R (R8-03) l'a mesure sur
/// chaque ecran Finance (« Classe An- / Nour », « sep / tembre »).
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
    this.cercleEnHaut = false,
    this.texteEtire = false,
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
    bool cercleEnHaut = false,
    bool texteEtire = false,
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
         cercleEnHaut: cercleEnHaut,
         texteEtire: texteEtire,
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

  /// En ligne seulement : vrai pour poser le cercle **en haut** de la rangee
  /// au lieu de le centrer sur le texte. Pour une carte qui porte le bandeau
  /// de couleur d'un profil (K-62) : le bandeau part du bord haut de la
  /// carte et doit retrouver le cercle a la meme place quelle que soit la
  /// hauteur du texte (texte agrandi, legende sur plusieurs lignes).
  final bool cercleEnHaut;

  /// En ligne seulement : vrai pour que le texte prenne toute la place
  /// restante, et que [fin] aille donc au bout de la rangee quelle que soit
  /// la longueur du prenom (carte d'un membre du Foyer, revue FI-2-R M1).
  /// Faux par defaut : [fin] suit le texte.
  final bool texteEtire;

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
            TexteSansCoupure(
              affiche,
              textAlign: TextAlign.center,
              style: styleDuNom,
            ),
          if (ligneRole != null)
            TexteSansCoupure(
              ligneRole,
              textAlign: TextAlign.center,
              style: styleDuRole,
            ),
        ],
      ),
      DispositionAvatar.enLigne => Row(
        mainAxisSize: ajuste ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: cercleEnHaut
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: <Widget>[
          cercleHabille,
          SizedBox(width: ecart ?? AppSpacing.md),
          Flexible(
            fit: texteEtire ? FlexFit.tight : FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TexteSansCoupure(affiche, style: styleDuNom),
                if (roleWidget != null)
                  roleWidget!
                else if (ligneRole != null)
                  TexteSansCoupure(ligneRole, style: styleDuRole),
              ],
            ),
          ),
          if (fin != null) ...<Widget>[Ecart.hSm, fin!],
        ],
      ),
    };
  }
}

/// **La tuile video sans image** : le seul rendu d'un cadre video dont la
/// camera ne publie pas (salle de seance, salle du controleur, classe live,
/// vignette de l'enseignant). VIDEO-TUILE-1, revue du directeur du 02/10/2026 :
/// « le nom est colle a gauche de l'avatar au lieu du centre ».
///
/// - le petit cercle ([AppAvatar.moyen]) et le nom **centre juste dessous**,
///   ensemble au centre de la tuile, sur le meme axe vertical ;
/// - le cadre ne pose plus d'etiquette de nom en bas a gauche dans ce cas ;
/// - le micro coupe ([libelleMicroCoupe]) se pose a cote du nom ; un
///   emplacement vide de meme largeur lui fait face, pour que le nom reste
///   centre sur le cercle ;
/// - « Sans image » ne s'ecrit pas : le cercle le dit deja. Le lecteur d'ecran
///   le garde dans la semantique ([libelleSansImage]) ;
/// - rien ne deborde : le nom passe a la ligne entre deux mots, jamais au
///   milieu d'un mot ([TexteSansCoupure]) ni avec des points de suspension, et
///   le bloc se reduit ([FittedBox]) quand la tuile est trop courte, a 200 %
///   de texte comme a six visages ;
/// - [coin] (barres de reseau) reste dans le coin bas de fin de la tuile.
class TuileSansImage extends StatelessWidget {
  /// Cree la tuile.
  const TuileSansImage({
    required this.prenom,
    required this.nom,
    super.key,
    this.libelleSansImage,
    this.libelleMicroCoupe,
    this.styleNom,
    this.couleurIcone,
    this.coin,
  });

  /// Le prenom, source des initiales du cercle.
  final String prenom;

  /// Le nom affiche sous le cercle (« Sayyid Ibrahim », « Vous »).
  final String nom;

  /// Ce que le lecteur d'ecran ajoute au nom (« Sans image »).
  final String? libelleSansImage;

  /// Le libelle du micro coupe ; `null` quand le micro est ouvert.
  final String? libelleMicroCoupe;

  /// Le style du nom, dans l'encre du registre de la tuile.
  final TextStyle? styleNom;

  /// La couleur de l'icone de micro coupe.
  final Color? couleurIcone;

  /// Un indicateur pose dans le coin bas de fin (signal reseau).
  final Widget? coin;

  /// La taille de l'icone de micro, et de l'emplacement qui lui fait face.
  static const double _icone = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle style = styleNom ?? textes.labelMedium ?? const TextStyle();
    final bool microCoupe = libelleMicroCoupe != null;

    final Widget bloc = LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: contraintes.hasBoundedWidth
                    ? (contraintes.maxWidth - 2 * AppSpacing.sm).clamp(
                        0,
                        double.infinity,
                      )
                    : double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ExcludeSemantics(
                    child: AvatarTile(
                      key: const ValueKey<String>('tuile-sans-image-cercle'),
                      prenom: prenom,
                      diametre: AppAvatar.moyen,
                    ),
                  ),
                  Ecart.vXs,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (microCoupe) ...<Widget>[
                        Icon(
                          AppIcons.microCoupe.repos,
                          size: _icone,
                          color: couleurIcone ?? style.color,
                        ),
                        Ecart.hXs,
                      ],
                      Flexible(
                        child: TexteSansCoupure(
                          nom,
                          key: const ValueKey<String>('tuile-sans-image-nom'),
                          textAlign: TextAlign.center,
                          style: style,
                        ),
                      ),
                      // L'emplacement qui fait face au micro : le nom reste
                      // centre sur le cercle.
                      if (microCoupe) ...<Widget>[
                        Ecart.hXs,
                        const SizedBox(width: _icone),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: <String>[
        nom,
        if (libelleMicroCoupe case final String micro) micro,
        if (libelleSansImage case final String sans) sans,
      ].join(', '),
      child: ExcludeSemantics(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: bloc),
            if (coin case final Widget indicateur)
              PositionedDirectional(
                end: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: indicateur,
              ),
          ],
        ),
      ),
    );
  }
}

/// Ce qui occupe un cadre video sans image (vignette d'observation) : un petit
/// cercle, centre dans la zone libre du cadre, avec au
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
