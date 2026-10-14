/// Le bas d'une feuille d'administration (CLASSE-FORM-1), commun a la
/// creation d'une classe (`groupes_page.dart`) et a la creation depuis des
/// demandes semblables (OFFRES-ADM-1, `admin_regroupements`) : un seul
/// endroit pour la place du bouton plein, sa largeur et son repli hors ligne.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/action_principale.dart';

/// Le message d'un echec ou d'un champ manquant, a l'encre d'alerte, lu des
/// qu'il parait.
class MessageAlerte extends StatelessWidget {
  /// Cree le message.
  const MessageAlerte(this.message, {super.key});

  /// Le message.
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: TexteSansCoupure(
      message,
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}

/// Le seul bouton plein d'une feuille, en bas, au bord de fin ; pleine
/// largeur sur telephone et tablette seulement (contrat B). Hors ligne, il
/// n'est pas rendu : une phrase dit pourquoi (pieges deja payes).
class BasDeFeuille extends ConsumerWidget {
  /// Cree le bas de feuille.
  const BasDeFeuille({
    required this.libelle,
    required this.enCours,
    required this.onPress,
    required this.horsLigne,
    super.key,
  });

  /// Le libelle du bouton.
  final String libelle;

  /// Vrai le temps d'un envoi deja parti.
  final bool enCours;

  /// Le geste.
  final VoidCallback onPress;

  /// La phrase rendue a la place du bouton, sans reseau.
  final String horsLigne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(horsLigneProvider).value ?? false) {
      return TexteSansCoupure(
        horsLigne,
        style: AppPalette.of(context).inkWarning.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      );
    }
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ActionPrincipale(
        libelle: libelle,
        enCours: enCours,
        pleineLargeur: !bureau,
        onPress: onPress,
      ),
    );
  }
}
