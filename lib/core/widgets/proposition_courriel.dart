import 'package:flutter/material.dart';

import '../auth/suggestion_courriel.dart';
import '../i18n/strings.g.dart';
import '../theme/app_spacing.dart';
import 'lien_fleche.dart';

/// PE-A8 (retours terrain R25) : sous un champ d'adresse electronique,
/// « Vouliez-vous dire ali@gmail.com ? » quand le domaine tape ressemble a un
/// domaine courant mal ecrit ([proposerCourriel]).
///
/// Une proposition, jamais une correction : rien ne change tant que la
/// personne ne touche pas la ligne ; la toucher remplace l'adresse du champ,
/// puis appelle [onAccepte] (pour que l'ecran relise le champ, comme a une
/// frappe). L'envoi n'est jamais bloque, et la ligne disparait des que
/// l'adresse ne ressemble plus a une faute. Rien ne s'affiche (pas meme un
/// espace) quand il n'y a rien a proposer.
class PropositionCourriel extends StatelessWidget {
  /// Cree la proposition pour le champ que tient [controleur].
  const PropositionCourriel({
    required this.controleur,
    this.onAccepte,
    super.key,
  });

  /// Le controleur du champ d'adresse.
  final TextEditingController controleur;

  /// Appele apres que la personne a accepte la proposition.
  final VoidCallback? onAccepte;

  /// La cle du lien de la proposition (tests).
  static const Key cleLien = ValueKey<String>('proposition-courriel');

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controleur,
        builder: (BuildContext context, TextEditingValue valeur, Widget? _) {
          final String? propose = proposerCourriel(valeur.text);
          if (propose == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: LienFleche(
                key: cleLien,
                alignerEnDebut: true,
                fleche: false,
                libelle: t.formulaire.courrielPropose(adresse: propose),
                onPress: () {
                  controleur.value = TextEditingValue(
                    text: propose,
                    selection: TextSelection.collapsed(offset: propose.length),
                  );
                  onAccepte?.call();
                },
              ),
            ),
          );
        },
      );
}
