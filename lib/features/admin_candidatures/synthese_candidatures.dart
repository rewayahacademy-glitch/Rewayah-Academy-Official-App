// La synthese de la file (`ADM-20`) : **une ligne**, posee juste au-dessus du
// tableau. Elle remplace la carte « A traiter » (quatre alertes, dont deux
// « Disponible au branchement serveur ») qui coutait 175 points de hauteur.
//
// Elle dit le nombre de candidatures du filtre, puis **les alertes que le
// serveur sert vraiment, avec leur nombre** : « Informations manquantes » et
// « Confirmees indisponibles ». Les deux autres (« Bloquees », « Entretiens en
// retard ») valent `NULL` cote serveur : elles ne s'affichent pas, jamais un
// « bientot » ni un zero qui ne serait pas lu. Quand les quatre sont servies et
// valent zero, la ligne dit « Rien a traiter ».
//
// **Les alertes ne se touchent pas** : poser le filtre d'une alerte demande une
// cle de filtre `alerte` que `lister_candidatures` ne connait pas, et aucun des
// filtres existants n'est equivalent (« Informations manquantes » compte aussi
// le complement demande en Salle de verification, « Confirmees indisponibles »
// n'a pas de filtre). Un filtre approchant donnerait une liste qui ne compte pas
// ce que le compteur annonce : un element qui ne peut pas aboutir n'est pas
// pressable. Les nombres sont ceux du serveur, calcules sur toute la portee du
// lecteur (sans les autres filtres) ; une pause n'entre dans aucune alerte
// (`CONS` §10).
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// La ligne de synthese : le compteur du filtre et les alertes servies.
class SyntheseCandidatures extends StatelessWidget {
  /// Cree la synthese.
  const SyntheseCandidatures({
    required this.total,
    required this.compteurs,
    this.alignement = WrapAlignment.start,
    super.key,
  });

  /// Le nombre de candidatures du filtre, rendu par le serveur, ou `null` tant
  /// que la lecture du filtre courant n'est pas arrivee : la synthese ne dit
  /// jamais le total d'une autre requete.
  final int? total;

  /// L'alignement des elements : au debut sous les filtres, a la fin quand la
  /// synthese partage la bande de la recherche.
  final WrapAlignment alignement;

  /// Les compteurs d'alertes rendus par le serveur.
  final CompteursAlertes compteurs;

  /// La cle du compteur de candidatures.
  static const Key cleTotal = ValueKey<String>('candidatures-total');

  /// La cle de la synthese.
  static const Key cleSynthese = ValueKey<String>('candidatures-synthese');

  /// La cle de l'alerte [nom] (`informationsManquantes`,
  /// `confirmeesIndisponibles`).
  static Key cleAlerte(String nom) =>
      ValueKey<String>('candidatures-alerte-$nom');

  /// La cle de la phrase « Rien a traiter ».
  static const Key cleRien = ValueKey<String>('candidatures-alertes-rien');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final s = t.admin.candidatures.liste.synthese;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    Widget alerte(String nom, AppIcon icone, String texte) => Row(
      key: cleAlerte(nom),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icone.actif,
          size: AppSpacing.lg,
          color: palette.inkWarning.asIconTheme().color,
        ),
        Ecart.hXs,
        Flexible(child: TexteSansCoupure(texte, style: attenue)),
      ],
    );

    final int? manquantes = compteurs.informationsManquantes;
    final int? indisponibles = compteurs.confirmeesIndisponibles;

    return Semantics(
      key: cleSynthese,
      container: true,
      child: Wrap(
        alignment: alignement,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (total != null)
            Semantics(
              header: true,
              liveRegion: true,
              child: TexteSansCoupure(
                t.admin.candidatures.total(n: total!),
                key: cleTotal,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
          if (compteurs.rienATraiter)
            TexteSansCoupure(
              t.admin.candidatures.alertes.rien,
              key: cleRien,
              style: attenue,
            ),
          if (manquantes != null && !compteurs.rienATraiter)
            alerte(
              'informationsManquantes',
              AppIcons.info,
              s.informationsManquantes(n: manquantes),
            ),
          if (indisponibles != null && !compteurs.rienATraiter)
            alerte(
              'confirmeesIndisponibles',
              AppIcons.suspendre,
              s.confirmeesIndisponibles(n: indisponibles),
            ),
        ],
      ),
    );
  }
}
