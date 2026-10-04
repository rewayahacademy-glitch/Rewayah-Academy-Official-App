import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/visibilite_montants.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'bouton_icone.dart';

/// Le controle global de visibilite des montants
/// (`FinanceAmountVisibilityToggle`, spec §7.2 ; CPT-F) : « Afficher les
/// montants » / « Masquer les montants ».
///
/// Agit sur **toute** la surface Comptable (un seul etat,
/// `visibiliteMontantsProvider`), pour la session seulement (§7.3). Un
/// [BoutonIcone] dont le libelle lu dit l'action, oeil ouvert quand les
/// montants sont masques (on peut les afficher), oeil barre quand ils sont
/// affiches ; avec [avecEtat], le mot d'etat (« Montants masques ») est
/// ecrit a cote, comme sur la planche H00, pour qu'on sache sans toucher.
///
/// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A).
class BasculeMontants extends ConsumerWidget {
  /// Cree la bascule.
  const BasculeMontants({super.key, this.avecEtat = false});

  /// Vrai pour ecrire le mot d'etat a cote du bouton.
  final bool avecEtat;

  /// La cle du bouton, pour les tests et la recette.
  static const Key cleBouton = ValueKey<String>('bascule-montants');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool affiches = ref.watch(visibiliteMontantsProvider);
    final Widget bouton = BoutonIcone(
      key: cleBouton,
      icone: affiches ? AppIcons.masquer : AppIcons.oeil,
      libelle: affiches
          ? t.comptable.commun.masquerMontants
          : t.comptable.commun.afficherMontants,
      onPress: ref.read(visibiliteMontantsProvider.notifier).basculer,
    );
    if (!avecEtat) return bouton;
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            affiches
                ? t.comptable.commun.montantsAffiches
                : t.comptable.commun.montantsMasques,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.hSm,
        bouton,
      ],
    );
  }
}
