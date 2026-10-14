import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/isolat_bidi.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';

/// Les trois registres d'un ecran vide.
///
/// **Le troisieme est celui qu'on oublie** : un tableau de bord
/// d'administration vide veut dire que tout va bien, et ne doit pas ressembler
/// a une panne (`docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 6).
enum RegistreVide {
  /// L'utilisateur peut agir : le constat, l'invitation, et le bouton.
  actionnable,

  /// L'utilisateur ne peut rien faire : le constat et la raison, sans bouton.
  ///
  /// « Votre enseignant n'a pas encore publie votre planning. » Proposer une
  /// action ici serait mentir sur ce que la personne peut obtenir.
  subi,

  /// C'est une bonne nouvelle : « Aucun dossier en attente. »
  ///
  /// Ton **neutre**, jamais de felicitations : l'operateur voit cet ecran
  /// vingt fois par jour.
  bonneNouvelle,
}

/// Etat vide illustre.
///
/// Obligatoire des qu'une liste peut etre vide. Un etat vide est une
/// **invitation**, pas une excuse : « Aucun cours aujourd'hui, ton prochain
/// cours est jeudi », jamais « Aucune donnee »
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, regles communes).
///
/// D'ou l'API : [message] est obligatoire et [invitation] fortement attendue.
/// Un appel qui ne donne qu'un constat produit un ecran mort.
///
/// **Le lot C lui donne ses trois registres.** Avant lui, les trois cas
/// s'ecrivaient de la meme facon, avec la meme icone d'accent : une file vide
/// qui signifie « tout va bien » avait donc le meme visage qu'une attente
/// subie.
class EmptyState extends StatelessWidget {
  /// Cree un etat vide.
  const EmptyState({
    required this.message,
    super.key,
    this.invitation,
    this.icone,
    this.libelleAction,
    this.onAction,
    this.registre = RegistreVide.actionnable,
    this.encre,
  });

  /// La paire de la surface sur laquelle l'etat vide est pose, quand ce
  /// n'est pas celle de la page : la salle en direct (`surfaceInverse`,
  /// SALLE-ENCRE-1). L'icone, le constat et l'invitation en prennent l'encre.
  /// `null` : les encres du theme, faites pour `surfaceCanvas`.
  final AppColorPair? encre;

  /// Le constat, en une ligne courte.
  final String message;

  /// Ce que l'utilisateur peut faire ou attendre ensuite.
  final String? invitation;

  /// Icone d'illustration. Par defaut, celle du registre.
  final AppIcon? icone;

  /// Libelle du bouton d'action, quand une action a du sens.
  final String? libelleAction;

  /// L'action proposee.
  final VoidCallback? onAction;

  /// Le registre du vide.
  final RegistreVide registre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair fond = palette.surfaceCanvas;
    // RTL-ISOL-1 : un constat ou une invitation ecrits dans l'autre sens que
    // l'interface (phrase francaise encore sans traduction arabe) se posent
    // dans leur propre sens : la ponctuation reste a sa place, jamais
    // « .l'enseignant ». Le texte lui-meme n'est pas modifie (aucun
    // caractere d'isolat) : le centrage ne change pas, les lecteurs d'ecran
    // et les recherches par texte lisent la phrase telle quelle.
    final TextDirection sens = Directionality.of(context);
    Widget dansSonSens(String texte, Widget enfant) => Directionality(
      textDirection: sensDuTexte(texte) ?? sens,
      child: enfant,
    );
    // Un vide subi ne propose rien, meme si l'appelant a passe un bouton :
    // c'est le registre qui tranche, pas l'oubli de l'appelant.
    final bool avecAction =
        registre == RegistreVide.actionnable &&
        libelleAction != null &&
        onAction != null;

    // [serre] : une hauteur bornee trop courte pour un texte agrandi. L'icone
    // est une illustration ; c'est elle qui cede la place au texte, de moitie,
    // jamais le constat ni l'invitation (SALLE-ERR-320-1).
    Widget corps({required bool serre}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconTheme(
          data:
              (encre != null
                      ? AppInkColor(encre!.onBackground)
                      : _encre(palette))
                  .asIconTheme(
                    // Multiples de l'echelle, pas des valeurs ponctuelles.
                    size:
                        (metriques.estEnfant
                            ? AppSpacing.xxxl * 3
                            : AppSpacing.xxxl * 2) /
                        (serre ? 2 : 1),
                  ),
          child: Icon((icone ?? _iconeParDefaut).repos),
        ),
        if (serre) Ecart.vMd else Ecart.vXl,
        // Aucun mot coupe, meme a 320 px et texte x2 (« aujourd'hu / i »,
        // ELV-VIDE-COUPE-1 ; « l'acadé / mie », DASH-MA-PROD) : le
        // constat et l'invitation passent a la ligne entre les mots ; le
        // mot le plus long se reduit juste assez pour tenir. A l'echelle
        // 1, rien ne change.
        dansSonSens(
          message,
          TexteSansCoupure(
            message,
            textAlign: TextAlign.center,
            style: (encre ?? fond).applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        if (invitation != null) ...<Widget>[
          Ecart.vSm,
          dansSonSens(
            invitation!,
            TexteSansCoupure(
              invitation!,
              textAlign: TextAlign.center,
              style: (encre?.applyTo ?? palette.inkMuted.applyTo)(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        // L'ecart avant le bouton appartient au texte : quand la place
        // manque, il defile avec lui au lieu de repousser le bouton.
        if (avecAction) serre ? Ecart.vLg : Ecart.vXxl,
      ],
    );

    // Le bouton n'est pas redessine ici : c'est le meme composant que celui
    // de toutes les autres actions principales du produit.
    final Widget? bouton = avecAction
        ? ActionPrincipale(
            libelle: libelleAction!,
            onPress: onAction,
            pleineLargeur: false,
          )
        : null;
    final EdgeInsets marge = EdgeInsets.all(metriques.marge);

    // Un etat vide ne deborde jamais, et **son action reste toujours a
    // l'ecran** (SALLE-ERR-320-1). Dans une hauteur bornee -- le panneau de
    // la salle, la barre du Mode Accessibilite, texte agrandi, 320 px --,
    // seul le texte defile, au-dessus d'un bouton qui ne bouge pas. Quand la
    // place suffit, la colonne prend la taille de son contenu et se centre :
    // le rendu est exactement celui d'avant, a l'echelle 1 comme a 1440.
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        if (!c.hasBoundedHeight) {
          return Center(
            child: Padding(
              padding: marge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[corps(serre: false), ?bouton],
              ),
            ),
          );
        }
        final bool serre =
            MediaQuery.textScalerOf(context).scale(1) > 1 &&
            c.maxHeight < AppSpacing.respiration * 5;
        // Une region plus basse que le bouton et ses marges ne peut pas le
        // garder pose : tout defile alors d'un bloc, plutot que de deborder.
        if (bouton != null && c.maxHeight < AppSpacing.respiration * 2) {
          return SingleChildScrollView(
            padding: marge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                corps(serre: serre),
                bouton,
              ],
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: SingleChildScrollView(
                  padding: bouton == null ? marge : marge.copyWith(bottom: 0),
                  child: corps(serre: serre),
                ),
              ),
              if (bouton != null)
                Padding(padding: marge.copyWith(top: 0), child: bouton),
            ],
          ),
        );
      },
    );
  }

  /// L'icone qui va avec le registre.
  AppIcon get _iconeParDefaut => switch (registre) {
    RegistreVide.actionnable => AppIcons.rienAAfficher,
    RegistreVide.subi => AppIcons.rienAAfficher,
    RegistreVide.bonneNouvelle => AppIcons.succes,
  };

  /// L'encre de l'illustration.
  ///
  /// L'accent appelle a agir, l'encre neutre constate, le vert dit que c'est
  /// bien ainsi. Trois registres, trois encres, aucun aplat.
  AppInkColor _encre(AppPalette palette) => switch (registre) {
    RegistreVide.actionnable => palette.inkAccent,
    RegistreVide.subi => palette.inkMuted,
    RegistreVide.bonneNouvelle => palette.inkSuccess,
  };
}
