import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/visibilite_montants.dart';
import '../finance/format_montant.dart';
import '../finance/montant.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import 'montant_argent.dart';

/// Un montant sensible (`SensitiveAmount`, spec Finance operationnelle §7.1 ;
/// CPT-F), masque par-dessus [MontantArgent], sans second formateur.
///
/// - **masque par defaut** a chaque session, revele par la bascule globale
///   (`visibiliteMontantsProvider`, R-FIN-01 a 03) ;
/// - **masque de longueur fixe par devise** (DR-06) : « •• •••,•• $ » pour
///   10 $ comme pour 1 000 000 $, pour ne jamais trahir l'ordre de grandeur ;
///   une devise sans decimales perd la virgule, rien d'autre ;
/// - lu « Montant masque » par un lecteur d'ecran (spec §46), jamais le
///   chiffre ; affiche, il est lu avec sa devise par [MontantArgent] ;
/// - chiffres tabulaires et meme corps que [MontantArgent] : la colonne ne
///   bouge pas quand on revele.
///
/// Pour la confirmation d'un payout, qui doit **toujours** montrer le montant
/// exact (§7.5, R-FIN-04), on pose un [MontantArgent] directement : ce
/// widget n'a volontairement aucun parametre « toujours visible ».
///
/// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A).
class MontantSensible extends ConsumerWidget {
  /// Cree le montant.
  const MontantSensible(
    this.montant, {
    super.key,
    this.signe = false,
    this.taille = TailleMontant.corps,
    this.attenue = false,
  });

  /// Le montant, entier en unites mineures et sa devise.
  final Montant montant;

  /// Vrai pour poser aussi le signe d'un montant positif, une fois revele.
  final bool signe;

  /// La taille, celle de [MontantArgent].
  final TailleMontant taille;

  /// Vrai pour un montant secondaire (encre attenuee).
  final bool attenue;

  /// Le point du masque.
  static const String point = '•';

  /// Le masque d'une devise : toujours deux groupes de points pour la partie
  /// entiere, puis autant de points que de decimales. La longueur ne depend
  /// jamais de la valeur.
  static String masquePour(String devise) {
    final int decimales = decimalesDe(devise);
    const String entier = '$point$point $point$point$point';
    final String nombre = decimales == 0
        ? entier
        : '$entier,${point * decimales}';
    return '$nombre ${symboleDe(devise)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool affiche = ref.watch(visibiliteMontantsProvider);
    if (affiche) {
      return MontantArgent(
        montant,
        signe: signe,
        taille: taille,
        attenue: attenue,
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base =
        switch (taille) {
          TailleMontant.corps => textes.bodyLarge,
          TailleMontant.titre => textes.titleLarge,
          TailleMontant.grand => textes.displaySmall,
        } ??
        const TextStyle();
    final Widget texte = Text(
      masquePour(montant.devise),
      maxLines: 1,
      style: (attenue ? palette.inkMuted : palette.inkStrong).applyTo(
        AppTypography.tabulaire(base),
      ),
    );
    final Widget corps = taille == TailleMontant.grand
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: texte,
          )
        : texte;
    return Semantics(
      label: t.comptable.commun.montantMasque,
      excludeSemantics: true,
      child: corps,
    );
  }
}
