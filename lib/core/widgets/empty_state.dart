import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
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
  });

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
    // Un vide subi ne propose rien, meme si l'appelant a passe un bouton :
    // c'est le registre qui tranche, pas l'oubli de l'appelant.
    final bool avecAction =
        registre == RegistreVide.actionnable &&
        libelleAction != null &&
        onAction != null;

    // Un etat vide ne deborde jamais : centre quand la place suffit, defilant
    // sinon (barre du Mode Accessibilite plus haute, texte agrandi, 320 px).
    Widget centre(Widget contenu) => LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => c.hasBoundedHeight
          ? SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Center(child: contenu),
              ),
            )
          : Center(child: contenu),
    );

    return centre(
      Padding(
        padding: EdgeInsets.all(metriques.marge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconTheme(
              data: _encre(palette).asIconTheme(
                // Multiples de l'echelle, pas des valeurs ponctuelles.
                size: metriques.estEnfant
                    ? AppSpacing.xxxl * 3
                    : AppSpacing.xxxl * 2,
              ),
              child: Icon((icone ?? _iconeParDefaut).repos),
            ),
            Ecart.vXl,
            // Aucun mot coupe, meme a 320 px et texte x2 (« aujourd'hu / i »,
            // ELV-VIDE-COUPE-1 ; « l'acadé / mie », DASH-MA-PROD) : le
            // constat et l'invitation passent a la ligne entre les mots ; le
            // mot le plus long se reduit juste assez pour tenir. A l'echelle
            // 1, rien ne change.
            TexteSansCoupure(
              message,
              textAlign: TextAlign.center,
              style: fond.applyTo(textes.titleLarge ?? const TextStyle()),
            ),
            if (invitation != null) ...<Widget>[
              Ecart.vSm,
              TexteSansCoupure(
                invitation!,
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
            if (avecAction) ...<Widget>[
              Ecart.vXxl,
              // Le bouton n'est pas redessine ici : c'est le meme composant que
              // celui de toutes les autres actions principales du produit.
              ActionPrincipale(
                libelle: libelleAction!,
                onPress: onAction,
                pleineLargeur: false,
              ),
            ],
          ],
        ),
      ),
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
