import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Une note de 1 a 5 etoiles (avis des familles, DECISION-AVIS-2026-10-19).
///
/// **Seul point d'entree de cette fonction.** Deux usages :
///
///   * saisie ([onChange] donne) : cinq etoiles, chacune une cible de 48
///     (`AppTouchTarget.standard`), lue par le lecteur d'ecran comme un groupe
///     de choix exclusifs (« Note : 4 sur 5 », la note retenue marquee
///     selectionnee). Appuyer sur l'etoile retenue ne la relache pas : une
///     note se corrige, elle ne s'efface pas ;
///   * lecture ([onChange] nul) : les etoiles ne se touchent pas, la rangee se
///     lit en une phrase (« Note : 4 sur 5 »).
///
/// Les etoiles pleines et vides ne different jamais par la couleur seule : la
/// graisse de l'icone change (pleine ou contour) et la note est aussi dite en
/// mots au lecteur d'ecran.
class NoteEtoiles extends StatelessWidget {
  /// Cree la rangee.
  const NoteEtoiles({required this.valeur, super.key, this.onChange});

  /// La note retenue, de 0 (aucune) a 5.
  final int valeur;

  /// Appele avec la note touchee. Nul : lecture seule.
  final ValueChanged<int>? onChange;

  /// Le nombre d'etoiles.
  static const int maximum = 5;

  /// La cle de l'etoile [n] (de 1 a 5), pour les tests.
  static Key etoileKey(int n) => ValueKey<String>('note-etoile-$n');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ValueChanged<int>? geste = onChange;
    final List<Widget> etoiles = <Widget>[
      for (int n = 1; n <= maximum; n++)
        _Etoile(
          key: etoileKey(n),
          rang: n,
          pleine: n <= valeur,
          palette: palette,
          onChange: geste,
          retenue: n == valeur,
        ),
    ];
    if (geste != null) {
      return Semantics(
        container: true,
        child: Wrap(
          // Choix de formulaire, pas un filtre : cinq etoiles d'une meme note.
          spacing: AppSpacing.xs,
          children: etoiles,
        ),
      );
    }
    return Semantics(
      container: true,
      label: t.avis.form.note.lue(n: valeur),
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: etoiles),
      ),
    );
  }
}

class _Etoile extends StatelessWidget {
  const _Etoile({
    required this.rang,
    required this.pleine,
    required this.palette,
    required this.onChange,
    required this.retenue,
    super.key,
  });

  final int rang;
  final bool pleine;
  final AppPalette palette;
  final ValueChanged<int>? onChange;
  final bool retenue;

  @override
  Widget build(BuildContext context) {
    final bool saisie = onChange != null;
    final Widget icone = Icon(
      AppIcons.etoile.resoudre(selectionne: pleine),
      size: saisie ? AppSpacing.section : AppSpacing.lg,
    );
    final Widget colore = IconTheme(
      data: (pleine ? palette.inkAccent : palette.borderStrong).asIconTheme(
        size: saisie ? AppSpacing.section : AppSpacing.lg,
      ),
      child: icone,
    );
    if (!saisie) return colore;
    return Pressable(
      onPress: () => onChange!(rang),
      libelleSemantique: t.avis.form.note.etoile(n: rang),
      selectionne: retenue,
      child: SizedBox.square(
        dimension: AppTouchTarget.standard,
        child: Center(child: colore),
      ),
    );
  }
}
