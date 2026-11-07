import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import '../router/fil_ariane.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'lien_fleche.dart';

export '../router/fil_ariane.dart' show SegmentFil;

/// Le fil d'Ariane, **seul composant** de sa fonction (FIL-ARIANE, directeur,
/// 06/11/2026 ; il generalise le fil de la fiche de l'eleve, maquette 06).
///
/// Chaque segment qui mene quelque part est un lien ([LienFleche] sans
/// fleche, cible de 48) ; les segments suivants sont precedes de « › », en
/// encre attenuee ; la page courante, en dernier, est du texte attenue qui ne
/// se touche pas. En arabe, le fil se lit de droite a gauche : le [Wrap] suit
/// la `Directionality`, et le chevron « › » est un caractere miroir.
///
/// `PageShell` le pose lui-meme au-dessus du titre, sur tablette et
/// ordinateur, depuis l'arbre des routes ([filAriane]) ; une page qui
/// connait mieux son chemin (la fiche de l'eleve, dont le prenom vient des
/// donnees) le passe en `ligneSousTitre`, et `PageShell` ne pose alors pas le
/// sien : jamais deux fils sur une page.
class FilAriane extends StatelessWidget {
  /// Cree le fil.
  const FilAriane({required this.segments, super.key});

  /// La cle du lien d'un segment, par son chemin (tests, robots).
  static Key cleSegment(String chemin) => ValueKey<String>('filAriane:$chemin');

  /// La cle du fil pose par `PageShell`.
  static const Key cleFil = ValueKey<String>('filAriane');

  /// Les segments, du plus haut a la page courante.
  final List<SegmentFil> segments;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
    );
    final List<Widget> morceaux = <Widget>[];
    for (int i = 0; i < segments.length; i++) {
      final SegmentFil segment = segments[i];
      final String? chemin = segment.chemin;
      if (chemin == null) {
        // La page courante : « › Mariam », d'un seul texte.
        morceaux.add(
          Text(
            i == 0
                ? segment.libelle
                : t.nav.filAriane.suite(libelle: segment.libelle),
            style: attenue,
          ),
        );
        continue;
      }
      if (i > 0) {
        morceaux.add(
          ExcludeSemantics(
            child: Text(t.nav.filAriane.separateur, style: attenue),
          ),
        );
      }
      morceaux.add(
        // L'identifiant se lit dans l'arbre d'accessibilite du web
        // (`flt-semantics-identifier`) : le robot de FIL-ARIANE y trouve
        // chaque segment sans dependre de la langue.
        Semantics(
          identifier: 'filAriane:$chemin',
          child: LienFleche(
            key: cleSegment(chemin),
            libelle: segment.libelle,
            fleche: false,
            onPress: () => GoRouter.of(context).go(chemin),
          ),
        ),
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: morceaux,
    );
  }
}
