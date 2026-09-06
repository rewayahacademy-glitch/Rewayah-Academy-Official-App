import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';

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

  /// Diametre de la tuile. Par defaut, deux fois la cible tactile du mode.
  final double? diametre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final double taille = diametre ?? metriques.cibleTactile * 2;
    final AppColorPair paire = palette.surfacePrimary;

    final Widget repli = _Initiales(prenom: prenom, paire: paire, taille: taille);

    if (urlSignee == null || urlSignee!.isEmpty) {
      return _cadre(taille, paire, repli);
    }

    return _cadre(
      taille,
      paire,
      Image.network(
        urlSignee!,
        width: taille,
        height: taille,
        fit: BoxFit.cover,
        // Meme repli que l'absence de photo : identique, jamais une erreur.
        errorBuilder: (BuildContext _, Object _, StackTrace? _) => repli,
        loadingBuilder:
            (BuildContext _, Widget enfant, ImageChunkEvent? progression) =>
                progression == null ? enfant : repli,
      ),
    );
  }

  Widget _cadre(double taille, AppColorPair paire, Widget contenu) {
    return ClipOval(
      child: SizedBox(
        width: taille,
        height: taille,
        child: ColoredBox(color: paire.background, child: contenu),
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
    return (mots.first.characters.first + mots[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
    return Center(
      child: Text(
        _lettres,
        style: paire.applyTo(base).copyWith(fontSize: taille * 0.36),
      ),
    );
  }
}
