import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'page_shell.dart';

/// La coquille d'une page de parcours : une question, une action.
///
/// **Pages courtes, jamais un formulaire qui empile les champs** (ADR-013). La
/// coquille tient ce qui se repete d'une page a l'autre : ou l'on en est,
/// combien de temps il reste, comment revenir, et l'unique bouton qui avance.
///
/// L'estimation de temps restant n'est pas un ornement : sur ce type d'ecran,
/// l'incertitude coute plus cher que la longueur
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, `TUT-00c`).
///
/// **Le lot C l'a remontee de `lib/features/inscription/` vers ici**, et posee
/// sur `PageShell` : c'est un composant partage, employe par l'inscription
/// comme par l'ajout d'un enfant, pas un detail de l'inscription
/// (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 1). Elle avait son propre
/// `Scaffold`, sa propre gouttiere et son propre bandeau hors ligne : trois
/// choses que le gabarit de page tient desormais pour tout le produit.
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
    final TextTheme textes = Theme.of(context).textTheme;

    return PageShell(
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Les deux elements sont flexibles, et c'est une correction : a 200
          // pour cent de taille de texte comme en mode enfant, « Retour » et
          // « Etape 2 sur 3 » ne tenaient plus sur une ligne et la Row
          // debordait de huit points. Le catalogue de galerie l'a trouve.
          Row(
            children: <Widget>[
              if (onRetour != null)
                Flexible(
                  child: ActionPrincipale(
                    libelle: t.commun.retour,
                    onPress: onRetour,
                    niveau: NiveauAction.tertiaire,
                    pleineLargeur: false,
                  ),
                ),
              const Spacer(),
              Flexible(
                child: Text(
                  t.inscription.etapeSur(n: numero, total: total),
                  textAlign: TextAlign.end,
                  style: textes.bodySmall,
                ),
              ),
            ],
          ),
          Ecart.vMd,
          _Progression(numero: numero, total: total),
        ],
      ),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (souscription != null) ...<Widget>[souscription!, Ecart.vMd],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(question, style: textes.headlineSmall ?? const TextStyle()),
          if (explication != null) ...<Widget>[
            Ecart.vSm,
            Text(explication!, style: textes.bodyMedium),
          ],
          Ecart.vXxl,
          enfant,
        ],
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

    return Semantics(
      label: t.inscription.etapeSur(n: numero, total: total),
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          for (int i = 1; i <= total; i++)
            Expanded(
              child: Padding(
                // Directionnel : en arabe, la progression se lit de droite a
                // gauche et l'ecart doit suivre.
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: SizedBox(
                  height: AppSpacing.xs,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.arrondiFull,
                      // La piste d'une barre de progression est une surface
                      // enfoncee (`01-systeme-visuel.md` section 2) : elle
                      // etait transparente avec un filet, donc invisible sur
                      // le fond de page.
                      color: i <= numero
                          ? palette.surfacePrimary.background
                          : palette.surfaceSunken.background,
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
