import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Les diametres d'avatar, pris dans l'echelle des jetons (AVATAR-1).
///
/// **Un avatar est un petit cercle.** Trois tailles suffisent : [petit] pour
/// une pile ou une ligne dense, [moyen] pour une ligne de liste ou une tuile,
/// [grand] pour l'en-tete d'une fiche. Au-dela, ce n'est plus un avatar mais un
/// portrait, et il se pose dans un cadre qui le dit (editeur de photo).
abstract final class AppAvatar {
  /// 32 : pile d'avatars, ligne dense.
  static const double petit = AppSpacing.xxxl;

  /// 48 : ligne de liste, tuile, selecteur sur telephone. Taille par defaut.
  static const double moyen = AppTouchTarget.standard;

  /// 64 : en-tete de fiche, selecteur sur grand ecran.
  static const double grand = AppSpacing.respiration;
}

/// Photo de profil d'un eleve, avec repli sur les initiales.
///
/// Trois regles issues de l'ADR-012 :
///
/// 1. L'image se charge par **URL signee de courte duree**, generee a la
///    demande cote serveur. Jamais une URL publique stable, jamais une adresse
///    stockee en dur.
/// 2. Le repli en cas d'echec de chargement est **visuellement identique** au
///    repli sans photo : jamais une icone d'erreur brute. Un enfant qui voit un
///    triangle rouge a la place de son visage comprend qu'il a casse quelque
///    chose.
/// 3. La photo n'est jamais exposee a l'enseignant ni aux autres eleves. Les
///    vues `teacher_roster_v` et `session_peers_v` ne la portent pas, ce
///    composant n'est donc pas rendu dans ces contextes.
///
/// **Le lot C change son repli.** Il etait peint en `surfacePrimary`, c'est-a
/// dire en aplat violet sature : sur `TUT-01`, quatre enfants sans photo
/// faisaient quatre aplats pleins, la ou la regle n'en autorise qu'un par
/// ecran. Il prend desormais la teinte du domaine foyer, `washFamily`, et un
/// contour `borderStrong` qui le detache de la carte
/// (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 1).
class AvatarTile extends StatelessWidget {
  /// Cree une tuile d'avatar.
  const AvatarTile({
    required this.prenom,
    super.key,
    this.urlSignee,
    this.diametre,
  });

  /// Le prenom, source des initiales de repli.
  final String prenom;

  /// URL signee de courte duree. `null` tant qu'aucune photo n'est ajoutee.
  final String? urlSignee;

  /// Diametre de la tuile, pris dans [AppAvatar]. Par defaut [AppAvatar.moyen] :
  /// un avatar est un petit cercle, jamais deux fois la cible tactile du mode
  /// (une tuile de 144 debordait de son cadre dans la salle).
  final double? diametre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double taille = diametre ?? AppAvatar.moyen;
    final AppColorPair paire = palette.washFamily;

    final Widget repli = _Initiales(
      prenom: prenom,
      paire: paire,
      taille: taille,
    );

    final Widget contenu = urlSignee == null || urlSignee!.isEmpty
        ? repli
        : Image.network(
            urlSignee!,
            width: taille,
            height: taille,
            fit: BoxFit.cover,
            // Meme repli que l'absence de photo : identique, jamais une erreur.
            errorBuilder: (BuildContext _, Object _, StackTrace? _) => repli,
            loadingBuilder: (
              BuildContext _,
              Widget enfant,
              ImageChunkEvent? progression,
            ) => progression == null ? enfant : repli,
          );

    return SizedBox(
      width: taille,
      height: taille,
      child: DecoratedBox(
        // Le contour se pose en PREMIER PLAN : derriere l'image, il serait
        // recouvert par elle et l'avatar photographie n'aurait plus de bord.
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.fromBorderSide(palette.borderStrong.asBorderSide()),
        ),
        child: ClipOval(
          child: ColoredBox(color: paire.background, child: contenu),
        ),
      ),
    );
  }
}

class _Initiales extends StatelessWidget {
  const _Initiales({
    required this.prenom,
    required this.paire,
    required this.taille,
  });

  final String prenom;
  final AppColorPair paire;
  final double taille;

  String get _lettres {
    final List<String> mots = prenom
        .trim()
        .split(RegExp(r'\s+'))
        .where((String m) => m.isNotEmpty)
        .toList();
    if (mots.isEmpty) {
      return '';
    }
    if (mots.length == 1) {
      return mots.first.characters.first.toUpperCase();
    }
    final String premiere = mots.first.characters.first;
    final String seconde = mots[1].characters.first;
    // L'arabe lie ses lettres : deux initiales accolees formeraient un mot
    // (« سيدة مريم » donnait « سم », « poison »). L'antiliant (U+200C) les
    // garde isolees, lues comme deux initiales (COM-RC tour 7).
    if (_arabe.hasMatch(premiere) && _arabe.hasMatch(seconde)) {
      return '$premiere\u200C$seconde';
    }
    return (premiere + seconde).toUpperCase();
  }

  static final RegExp _arabe = RegExp(r'[\u0600-\u06FF\u0750-\u077F]');

  @override
  Widget build(BuildContext context) {
    // Le style chiffre, a la taille de la tuile : une initiale n'est pas un
    // titre, et retailler un style DM Sans par `copyWith(fontSize:)` laisserait
    // son axe `opsz` cale sur l'ancienne taille.
    //
    // Le disque a un diametre fixe : a 200 % de texte, deux initiales
    // debordaient et le cercle les coupait (« MA » lu « M », capture 0b du
    // 24/09/2026). Elles tiennent desormais dans le carre inscrit du disque,
    // reduites seulement si elles n'y tiennent pas.
    return Center(
      child: SizedBox.square(
        dimension: taille * 0.7,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _lettres,
            style: paire.applyTo(AppTypography.chiffre(taille: taille * 0.36)),
          ),
        ),
      ),
    );
  }
}
