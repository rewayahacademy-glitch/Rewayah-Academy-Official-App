import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/filter_pill.dart';

/// Un membre du foyer, tel que le selecteur le nomme.
@immutable
class MembreChoix {
  /// Cree un membre.
  const MembreChoix({required this.id, required this.prenom});

  /// L'identifiant du profil. Jamais affiche.
  final String id;

  /// Le prenom.
  final String prenom;
}

/// « Pour qui ? » : le membre du foyer concerne, avant tout choix de Classe.
///
/// **Le tuteur choisit d'abord le membre** (contrat, section 4). Le produit
/// dit « membres du foyer », jamais une categorie generique « enfants » : un
/// eleve adulte autonome est un foyer d'une personne, et le meme ecran le
/// sert. Avec un seul membre, le choix est fait et le selecteur ne se rend pas :
/// un controle sans choix n'est pas un controle.
class SelecteurMembre extends StatelessWidget {
  /// Cree le selecteur.
  const SelecteurMembre({
    required this.membres,
    required this.selectionne,
    required this.onChoisir,
    super.key,
  });

  /// Les membres du foyer.
  final List<MembreChoix> membres;

  /// Le membre retenu.
  final String? selectionne;

  /// Appele au choix.
  final void Function(String membreId) onChoisir;

  @override
  Widget build(BuildContext context) {
    if (membres.length < 2) {
      return const SizedBox.shrink();
    }
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.classes.foyer.pourQui,
          style: palette.inkMuted.applyTo(
            textes.labelMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final MembreChoix membre in membres)
              FilterPill(
                libelle: membre.prenom,
                retenue: membre.id == selectionne,
                onPress: () => onChoisir(membre.id),
              ),
          ],
        ),
      ],
    );
  }
}
