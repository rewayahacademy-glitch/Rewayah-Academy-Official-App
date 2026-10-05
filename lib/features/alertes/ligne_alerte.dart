import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/alertes/alerte.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/filtres_historique.dart';

/// Le mot de la gravite, toujours ecrit : la couleur ne dit jamais seule
/// qu'une alerte est urgente.
String libelleGravite(GraviteAlerte gravite) => switch (gravite) {
  GraviteAlerte.urgent => t.alertes.gravite.urgent,
  GraviteAlerte.important => t.alertes.gravite.important,
  GraviteAlerte.info => t.alertes.gravite.info,
};

/// La famille de couleur de la gravite : registre doux, jamais un aplat
/// sature (une seule zone pleine par ecran, l'action principale).
TonEtat tonGravite(GraviteAlerte gravite) => switch (gravite) {
  GraviteAlerte.urgent => TonEtat.alerte,
  GraviteAlerte.important => TonEtat.avertissement,
  GraviteAlerte.info => TonEtat.neutre,
};

/// Le titre d'une alerte tel qu'il s'affiche : un nom compose (« An-Nour »,
/// « Al-Falaq ») garde son trait d'union insecable et ne passe jamais a la
/// ligne en son milieu (lecon 8, COUPE-MOTS-1). Le lecteur d'ecran lit le
/// titre d'origine.
String titreAffiche(String titre) => titre.replaceAll('-', '\u2011');

/// « Le 5 oct. 2026 à 17:35 », en heure locale.
String quandAlerte(Alerte alerte) {
  final DateTime local = alerte.creeeLe.toLocal();
  return t.alertes.creeeLe(date: dateCourte(local), heure: heureMinute(local));
}

/// Les alertes deja triees, en UNE carte a lignes fines (K-55, contenus
/// lies). L'ordre n'est jamais refait ici : il vient de `trierAlertes`.
class ListeAlertes extends StatelessWidget {
  /// Cree la liste.
  const ListeAlertes({
    required this.alertes,
    required this.onOuvrir,
    super.key,
  });

  /// Les alertes, dans l'ordre de lecture.
  final List<Alerte> alertes;

  /// Ouvre la page ou une alerte se traite.
  final void Function(String chemin) onOuvrir;

  @override
  Widget build(BuildContext context) => CarteLignes(
    lignes: <Widget>[
      for (final Alerte a in alertes)
        LigneAlerte(
          key: ValueKey<String>('alerte-${a.id}'),
          alerte: a,
          onPress: switch (a.destination) {
            final String chemin => () => onOuvrir(chemin),
            null => null,
          },
        ),
    ],
  );
}

/// Une alerte : sa gravite en pastille ecrite, son titre, sa date ; un
/// chevron quand elle mene a la page ou elle se traite. Sans destination, la
/// ligne n'est pas une cible (aucun chevron, aucun geste, jamais grisee).
class LigneAlerte extends StatelessWidget {
  /// Cree la ligne.
  const LigneAlerte({required this.alerte, required this.onPress, super.key});

  /// L'alerte.
  final Alerte alerte;

  /// L'ouverture de sa page, ou `null`.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final DateTime local = alerte.creeeLe.toLocal();
    final String semantique = t.alertes.ligne(
      gravite: libelleGravite(alerte.gravite),
      titre: alerte.titre,
      date: dateLongueHistorique(local),
      heure: heureMinute(local),
    );
    if (onPress == null) {
      return Semantics(
        label: semantique,
        excludeSemantics: true,
        child: _contenu(context, null),
      );
    }
    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: semantique,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      constructeur: _contenu,
    );
  }

  Widget _contenu(BuildContext context, EtatPression? etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool actif = etat != null && (etat.survole || etat.presse);
    return ColoredBox(
      color: actif
          ? Color.alphaBlend(
              palette.calqueInteraction(presse: etat.presse),
              palette.surfaceRaised.background,
            )
          : palette.surfaceRaised.background,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.standard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      StatusPill(
                        libelle: libelleGravite(alerte.gravite),
                        ton: tonGravite(alerte.gravite),
                      ),
                      Ecart.vSm,
                      // Un mot trop long pour la place se reduit, jamais
                      // coupe (« Remplacem / ent » a 320 px, texte x2).
                      TexteSansCoupure(
                        titreAffiche(alerte.titre),
                        style: palette.inkStrong.applyTo(
                          textes.titleSmall ?? const TextStyle(),
                        ),
                      ),
                      Ecart.vXs,
                      Text(
                        quandAlerte(alerte),
                        style: palette.inkMuted.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onPress != null) ...<Widget>[
                  Ecart.hSm,
                  IconTheme(
                    data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                    child: Icon(AppIcons.chevron.repos),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
