import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/pressable.dart';

/// La coquille d'une page de parcours : une question, une action.
///
/// **Pages courtes, jamais un formulaire qui empile les champs** (ADR-013). La
/// coquille tient ce qui se repete d'une page a l'autre : ou l'on en est,
/// combien de temps il reste, comment revenir, et l'unique bouton qui avance.
///
/// L'estimation de temps restant n'est pas un ornement : sur ce type d'ecran,
/// l'incertitude coute plus cher que la longueur
/// (`docs/produit/parcours-utilisateurs.md`, `TUT-00c`).
class PageParcours extends StatelessWidget {
  /// Cree une page de parcours.
  const PageParcours({
    required this.numero,
    required this.total,
    required this.question,
    required this.enfant,
    required this.libelleAction,
    required this.onAction,
    super.key,
    this.explication,
    this.onRetour,
    this.enCours = false,
    this.minutesRestantes,
    this.souscription,
  });

  /// Le rang de cette page, a partir de 1.
  final int numero;

  /// Le nombre de pages du parcours.
  final int total;

  /// La question posee, en une phrase.
  final String question;

  /// Ce qui explique la question, quand elle en a besoin.
  final String? explication;

  /// Le corps de la page.
  final Widget enfant;

  /// Le libelle de l'unique action.
  final String libelleAction;

  /// L'action. `null` tant que la reponse ne permet pas d'avancer.
  final VoidCallback? onAction;

  /// Le retour a la page precedente. `null` sur la premiere.
  final VoidCallback? onRetour;

  /// Vrai pendant un envoi.
  final bool enCours;

  /// Le temps restant estime, en minutes.
  final int? minutesRestantes;

  /// Une ligne sous le bouton, pour un refus ou une precision.
  final Widget? souscription;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const OfflineBanner(),
            Padding(
              padding: EdgeInsets.all(metriques.marge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (onRetour != null)
                        Pressable(
                          onPress: onRetour,
                          libelleSemantique: t.commun.retour,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              t.commun.retour,
                              style: palette.inkAccent.applyTo(
                                textes.labelLarge ?? const TextStyle(),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        t.inscription.etapeSur(n: numero, total: total),
                        style: textes.bodySmall,
                      ),
                    ],
                  ),
                  Ecart.vMd,
                  _Progression(numero: numero, total: total),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: metriques.marge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      question,
                      style: textes.headlineSmall ?? const TextStyle(),
                    ),
                    if (explication != null) ...<Widget>[
                      Ecart.vSm,
                      Text(explication!, style: textes.bodyMedium),
                    ],
                    Ecart.vXxl,
                    enfant,
                    Ecart.vXxl,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(metriques.marge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (souscription != null) ...<Widget>[
                    souscription!,
                    Ecart.vMd,
                  ],
                  ActionPrincipale(
                    libelle: libelleAction,
                    onPress: onAction,
                    enCours: enCours,
                  ),
                  if (minutesRestantes != null) ...<Widget>[
                    Ecart.vSm,
                    Text(
                      t.inscription.tempsRestant(minutes: minutesRestantes!),
                      textAlign: TextAlign.center,
                      style: textes.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La barre d'avancement du parcours.
///
/// Des segments plutot qu'une barre continue : on compte des pages, et un
/// enfant comme un parent presse lit mieux « trois traits sur cinq » qu'un
/// pourcentage.
class _Progression extends StatelessWidget {
  const _Progression({required this.numero, required this.total});

  final int numero;
  final int total;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair faite = palette.surfacePrimary;

    return Semantics(
      label: t.inscription.etapeSur(n: numero, total: total),
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          for (int i = 1; i <= total; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: SizedBox(
                  height: AppSpacing.xs,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      color: i <= numero ? faite.background : null,
                      border: i <= numero
                          ? null
                          : Border.fromBorderSide(
                              palette.borderResting.asBorderSide(),
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
