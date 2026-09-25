import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'avatar_tile.dart';
import 'groupe_reglages.dart';
import 'selecteur_profils.dart';

/// La selection nominative de profils, pour la recharge (S03) et
/// l'annulation d'acces (S09) ; planches « Recharger » et « Gerer les acces ».
///
/// A la difference du [SelecteurProfils] de l'Accueil (un seul profil, en
/// rangee d'avatars), elle retient **plusieurs** profils, avec « Tout
/// selectionner » en tete. Elle reprend son modele [ProfilSelectionnable] :
/// `etat` porte ici la ligne sous le prenom (« Solde : 24,00 XTS »).
///
/// Controlee : l'ecran tient la selection et la recoit par [onChange]. Chaque
/// case est une cible de 48, lue avec le prenom et sa legende ; « Tout
/// selectionner » est cochee, decochee ou mixte. Le compte des profils
/// retenus est annonce a chaque changement.
class SelectionProfils extends StatelessWidget {
  /// Cree la selection.
  const SelectionProfils({
    required this.profils,
    required this.selection,
    required this.onChange,
    super.key,
    this.titre,
  });

  /// Les profils proposes, dans l'ordre rendu par le serveur.
  final List<ProfilSelectionnable> profils;

  /// Les identifiants retenus.
  final Set<String> selection;

  /// Rappele avec la nouvelle selection.
  final ValueChanged<Set<String>> onChange;

  /// Le titre du groupe, facultatif.
  final String? titre;

  bool get _tous =>
      profils.isNotEmpty &&
      profils.every((ProfilSelectionnable p) => selection.contains(p.id));

  void _basculer(String id) => onChange(
    selection.contains(id)
        ? (Set<String>.of(selection)..remove(id))
        : (Set<String>.of(selection)..add(id)),
  );

  void _basculerTous() => onChange(
    _tous
        ? <String>{}
        : <String>{for (final ProfilSelectionnable p in profils) p.id},
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final double diametre = AppMetriques.of(context).cibleTactile;
    final int retenus = profils
        .where((ProfilSelectionnable p) => selection.contains(p.id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          titre: titre,
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: t.finance.toutSelectionner,
              icone: AppIcons.foyer,
              controle: _Case(
                child: Checkbox(
                  tristate: true,
                  value: _tous ? true : (retenus == 0 ? false : null),
                  onChanged: (bool? _) => _basculerTous(),
                ),
              ),
            ),
            for (final ProfilSelectionnable profil in profils)
              LigneRubrique(
                libelle: profil.prenom,
                meneur: AvatarTile(
                  prenom: profil.prenom,
                  urlSignee: profil.urlPhoto,
                  diametre: diametre,
                ),
                legende: profil.etat,
                controle: _Case(
                  child: Checkbox(
                    value: selection.contains(profil.id),
                    onChanged: (bool? _) => _basculer(profil.id),
                  ),
                ),
              ),
          ],
        ),
        Ecart.vSm,
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
          child: Semantics(
            liveRegion: true,
            child: Text(
              t.finance.profilsSelectionnes(nombre: retenus),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La case a cocher, sur un fond `Material` transparent : la ligne n'en porte
/// pas, et la case en a besoin pour son halo de pression.
class _Case extends StatelessWidget {
  const _Case({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Material(type: MaterialType.transparency, child: child);
}
