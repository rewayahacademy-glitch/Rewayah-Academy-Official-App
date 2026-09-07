import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';

/// La grille de la semaine, partagee par `TUT-04` et `ENS-06`.
///
/// **Le meme composant des deux cotes, au sens litteral.** Le tuteur pose les
/// heures possibles de son enfant, l'enseignant les siennes, et la base les
/// range dans la meme table : deux grilles jumelles finiraient par ne plus
/// afficher la meme chose (ADR-017).
///
/// On tape une case, elle bascule. Aucune saisie d'heures, aucun selecteur
/// horaire : c'est ce que demande `docs/produit/parcours-utilisateurs.md` pour
/// `TUT-04`.
class GrilleSemaine extends StatelessWidget {
  /// Cree une grille.
  const GrilleSemaine({
    required this.creneaux,
    required this.fuseau,
    required this.onBasculer,
    super.key,
    this.enCours = false,
  });

  /// Les cases actuellement posees.
  final List<Creneau> creneaux;

  /// Le fuseau dans lequel ces heures se lisent.
  final String fuseau;

  /// Appele au tap. La case passe en parametre, posee ou non.
  final void Function(Creneau creneau, bool posee) onBasculer;

  /// Vrai pendant un enregistrement : la grille ne repond plus, pour qu'un
  /// double tap ne parte pas deux fois.
  final bool enCours;

  /// La premiere heure affichee par defaut.
  static const int heureDebut = 6;

  /// La derniere heure affichee par defaut.
  static const int heureFin = 21;

  /// Les heures a afficher : la plage par defaut, **plus toute heure deja
  /// posee**. Une case existante hors plage resterait invisible, donc
  /// impossible a retirer, et son proprietaire ne saurait pas pourquoi un
  /// enseignant lui propose 5 heures du matin.
  List<int> get _heures {
    final Set<int> heures = <int>{
      for (int h = heureDebut; h <= heureFin; h++) h,
      ...creneaux.map((Creneau c) => c.heure),
    };
    return heures.toList()..sort();
  }

  bool _posee(int jour, int heure) => creneaux.any(
    (Creneau c) => c.jour == jour && c.heure == heure,
  );

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.disponibilites.fuseau(fuseau: fuseau),
          style: textes.bodySmall,
        ),
        Ecart.vSm,
        Row(
          children: <Widget>[
            SizedBox(width: metriques.cibleTactile, child: const Text('')),
            for (int jour = 1; jour <= 7; jour++)
              Expanded(
                child: Center(
                  child: Text(
                    t.disponibilites.joursCourts[jour - 1],
                    style: textes.labelMedium,
                  ),
                ),
              ),
          ],
        ),
        Ecart.vXs,
        for (final int heure in _heures)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: metriques.cibleTactile,
                  child: Text('${heure}h', style: textes.bodySmall),
                ),
                for (int jour = 1; jour <= 7; jour++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: _Case(
                        jour: jour,
                        heure: heure,
                        posee: _posee(jour, heure),
                        fuseau: fuseau,
                        actif: !enCours,
                        onBasculer: onBasculer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Case extends StatelessWidget {
  const _Case({
    required this.jour,
    required this.heure,
    required this.posee,
    required this.fuseau,
    required this.actif,
    required this.onBasculer,
  });

  final int jour;
  final int heure;
  final bool posee;
  final String fuseau;
  final bool actif;
  final void Function(Creneau creneau, bool posee) onBasculer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final String jourLong = t.disponibilites.joursLongs[jour - 1];

    final Widget corps = DecoratedBox(
      decoration: posee
          ? palette.surfacePrimary.decoration(
              borderRadius: BorderRadius.circular(metriques.rayon / 2),
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(metriques.rayon / 2),
              border: Border.fromBorderSide(
                palette.borderResting.asBorderSide(),
              ),
            ),
      child: SizedBox(height: metriques.cibleTactile),
    );

    if (!actif) {
      return corps;
    }

    return Pressable(
      onPress: () => onBasculer(
        Creneau(jour: jour, heure: heure, fuseau: fuseau),
        posee,
      ),
      // Le libelle dit l'etat ET ce que le geste fera : une case vide et une
      // case pleine ne se distinguent que par la couleur, ce qui ne suffit pas.
      libelleSemantique: posee
          ? t.disponibilites.cellulePosee(jour: jourLong, heure: '$heure')
          : t.disponibilites.celluleLibre(jour: jourLong, heure: '$heure'),
      respecterCibleTactile: false,
      child: corps,
    );
  }
}
