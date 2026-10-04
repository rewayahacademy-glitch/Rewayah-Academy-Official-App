import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/visibilite_montants.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_gabarit.dart';
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
/// Le mot d'etat cede la place au titre (CPT-F-CORR) : il n'est ecrit que
/// sur tablette et bureau, et seulement s'il tient dans le quart de la
/// largeur ([partMaxEtat]) a la taille de texte choisie. En dessous
/// (telephone, texte agrandi), la bascule se reduit au bouton seul : son
/// libelle lu dit toujours l'action, son infobulle dit l'etat puis l'action.
/// Pose dans les actions d'un `EntetePage` (enfant non flexible), le mot
/// d'etat prenait sinon toute la largeur et cassait le titre lettre par
/// lettre a 320 px, texte x2.
///
/// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A).
class BasculeMontants extends ConsumerWidget {
  /// Cree la bascule.
  const BasculeMontants({super.key, this.avecEtat = false});

  /// Vrai pour ecrire le mot d'etat a cote du bouton.
  final bool avecEtat;

  /// La cle du bouton, pour les tests et la recette.
  static const Key cleBouton = ValueKey<String>('bascule-montants');

  /// La part maximale de la largeur de l'ecran que le mot d'etat peut
  /// occuper ; au-dela, il n'est pas ecrit.
  static const double partMaxEtat = 0.25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool affiches = ref.watch(visibiliteMontantsProvider);
    final String action = affiches
        ? t.comptable.commun.masquerMontants
        : t.comptable.commun.afficherMontants;
    final String etat = affiches
        ? t.comptable.commun.montantsAffiches
        : t.comptable.commun.montantsMasques;
    final TextStyle? styleEtat = avecEtat
        ? AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          )
        : null;
    final bool etatEcrit =
        styleEtat != null && _etatTient(context, etat, styleEtat);
    final Widget bouton = BoutonIcone(
      key: cleBouton,
      icone: affiches ? AppIcons.masquer : AppIcons.oeil,
      libelle: action,
      infobulle: avecEtat && !etatEcrit ? '$etat\n$action' : null,
      onPress: ref.read(visibiliteMontantsProvider.notifier).basculer,
    );
    if (!etatEcrit) return bouton;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(child: Text(etat, style: styleEtat)),
        Ecart.hSm,
        bouton,
      ],
    );
  }

  /// Vrai quand le mot d'etat peut etre ecrit sans prendre la place du
  /// titre : hors telephone, et sur une ligne d'au plus [partMaxEtat] de la
  /// largeur de l'ecran a l'echelle de texte courante.
  static bool _etatTient(BuildContext context, String etat, TextStyle style) {
    if (AppGabarit.de(context) == Gabarit.mobile) return false;
    final TextPainter mesure = TextPainter(
      text: TextSpan(text: etat, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double largeur = mesure.width;
    mesure.dispose();
    return largeur <= MediaQuery.sizeOf(context).width * partMaxEtat;
  }
}
