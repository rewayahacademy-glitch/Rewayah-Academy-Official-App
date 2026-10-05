import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/libelles_observation.dart';
import '../../core/tc_observation/vue_budget_observation.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'barre_commandes_observation.dart' show seuilTexteEmpile;

/// En deca de ce reste, le bandeau passe au ton d'avertissement.
///
/// Un seuil d'**affichage**, pas une regle : il ne raccourcit ni n'allonge
/// quoi que ce soit, il prepare seulement le tuteur a la fin de sa visite.
const Duration seuilFinProcheObservation = Duration(seconds: 30);

/// Le decompte « 01:42 » : minutes et secondes, toujours sur deux chiffres.
///
/// Arrondi vers le haut a la seconde, comme [VueBudgetObservation.secondesRestantes] :
/// « 00:00 » n'apparait qu'a la fin reelle.
String decompteLisible(VueBudgetObservation budget) {
  final int total = budget.secondesRestantes;
  final String minutes = (total ~/ 60).toString().padLeft(2, '0');
  final String secondes = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$secondes';
}

/// Les visites qui resteront apres celle-ci, selon le serveur.
///
/// La visite en cours est deja comptee dans `visitesUtilisees` (le rang de la
/// visite en cours, [VueBudgetObservation.rangVisite]) : une visite ecourtee
/// est consommee et n'est pas reconduite (decision du directeur, `03` section
/// 1 bis-4). Jamais negatif.
int visitesRestantesApres(VueBudgetObservation budget) {
  final int reste = budget.visitesMax - budget.visitesUtilisees;
  return reste < 0 ? 0 : reste;
}

/// Le bandeau pleine largeur en haut de la salle (decision du directeur, `03`
/// section 1 bis-5) : le **temps restant, seconde par seconde**, et le
/// **nombre de visites restantes** pour la seance.
///
/// **Un affichage, jamais la limite.** Le chiffre vient du moteur de visite,
/// borne par la derniere valeur serveur ([VueBudgetObservation]) : une horloge
/// locale ne l'allonge pas, une reconnexion ne le remet pas a zero.
///
/// Remplace la pastille « Visite 1/2 · 01:42 » des maquettes M3, M4 et D1 :
/// le directeur a demande un bandeau, plus lisible qu'une pastille d'en-tete.
class BandeauDecompteVisite extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauDecompteVisite({
    required this.budget,
    super.key,
    this.budgetIncertain = false,
  });

  /// Le compte a rebours. `null` : le serveur n'a encore rien dit, le bandeau
  /// le dit plutot que d'inventer un chiffre.
  final VueBudgetObservation? budget;

  /// Vrai quand la derniere relecture du budget a echoue.
  final bool budgetIncertain;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VueBudgetObservation? b = budget;
    final bool finProche =
        b != null && b.restantAffiche <= seuilFinProcheObservation;
    final AppColorPair paire = finProche
        ? palette.washWarning
        : palette.washAccent;
    final v = t.tc.observation.visite;

    final String? visites = b == null
        ? null
        : visitesRestantesLisible(
            restantes: visitesRestantesApres(b),
            max: b.visitesMax,
          );
    final String lu = <String>[
      if (b != null) v.decompteLu(duree: dureeVisiteLisible(b.restantAffiche)),
      ?visites,
      if (budgetIncertain || b == null) v.budgetIncertain,
    ].join('. ');

    // Texte tres agrandi : le decompte, puis les visites sur leur propre ligne.
    final bool empile =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >
        seuilTexteEmpile;
    final Widget icone = IconTheme(
      data: IconThemeData(color: paire.onBackground, size: AppSpacing.xl),
      child: Icon(AppIcons.attente.repos),
    );
    final Widget decompte = b == null
        ? const SizedBox.shrink()
        : Wrap(
            // Un `Wrap` plutot qu'une ligne : a 200 % de texte, « restantes »
            // passe sous le chiffre au lieu de deborder.
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            children: <Widget>[
              Text(
                decompteLisible(b),
                key: const ValueKey<String>('decompte-visite'),
                style: paire.applyTo(
                  AppTypography.chiffre(taille: 22, poids: FontWeight.w700),
                ),
              ),
              Text(
                v.restantes,
                style: paire.applyTo(textes.labelMedium ?? const TextStyle()),
              ),
            ],
          );

    return Semantics(
      container: true,
      label: lu,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: paire.decoration(borderRadius: AppRadius.arrondiSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (empile) ...<Widget>[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: <Widget>[icone, decompte],
                ),
                if (visites != null) ...<Widget>[
                  Ecart.vXs,
                  Text(
                    visites,
                    style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
                  ),
                ],
              ] else
                Row(
                  children: <Widget>[
                    icone,
                    Ecart.hSm,
                    // PAGESHELL-200-1c : le decompte et les visites
                    // partagent la largeur. Quand ils ne tiennent pas cote a
                    // cote (320 px a 100 %, 130 % sur telephone), les
                    // visites passent sous le decompte au lieu d'etre
                    // ecrasees a une lettre par ligne (bandeau de 696 px a
                    // 320x568 et 130 %) et de faire deborder la ligne.
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          decompte,
                          if (visites != null)
                            Text(
                              visites,
                              textAlign: TextAlign.end,
                              style: paire.applyTo(
                                textes.bodySmall ?? const TextStyle(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (budgetIncertain || b == null) ...<Widget>[
                Ecart.vXs,
                Text(
                  v.budgetIncertain,
                  style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
