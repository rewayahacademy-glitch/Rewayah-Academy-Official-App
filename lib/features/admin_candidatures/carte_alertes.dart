// « A traiter » : les quatre alertes de la file, **dans une seule carte**
// (`ADM-20`, fiche : « une carte, quatre alertes, jamais confondues, chacune avec
// son mot, son icone et son nombre »). Quatre cartes egales sont interdites
// (`ENTREE:19`, K-55) : les quatre lignes habitent la meme carte.
//
// Les nombres sont ceux du serveur, calcules dans la portee de genre du
// lecteur. Un compteur que le serveur ne sert pas encore est dit seul
// (« Disponible au branchement serveur ») : jamais un zero qui ne serait pas lu.
// Une pause n'entre dans aucune alerte (`CONS` §10).
//
// Les alertes ne se touchent pas aujourd'hui : poser le filtre d'une alerte
// demande une cle de filtre `alerte` que `lister_candidatures` ne connait pas
// encore, et un filtre approchant donnerait une liste qui ne compte pas ce que
// le compteur annonce. Un element qui ne peut pas aboutir n'est pas pressable.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';

/// La carte des quatre alertes.
class CarteAlertes extends StatelessWidget {
  /// Cree la carte.
  const CarteAlertes({required this.compteurs, super.key});

  /// Les compteurs rendus par le serveur.
  final CompteursAlertes compteurs;

  /// La cle de la carte.
  static const Key cleCarte = ValueKey<String>('candidatures-alertes');

  /// La cle de l'alerte [nom] (`bloquees`, `entretiensEnRetard`,
  /// `informationsManquantes`, `confirmeesIndisponibles`).
  static Key cleAlerte(String nom) =>
      ValueKey<String>('candidatures-alerte-$nom');

  /// La cle de la phrase « Rien a traiter ».
  static const Key cleRien = ValueKey<String>('candidatures-alertes-rien');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.candidatures.alertes;
    final List<_Alerte> alertes = <_Alerte>[
      _Alerte(
        cle: 'bloquees',
        libelle: a.bloquees,
        icone: AppIcons.interdit,
        nombre: compteurs.bloquees,
      ),
      _Alerte(
        cle: 'entretiensEnRetard',
        libelle: a.entretiensEnRetard,
        icone: AppIcons.horloge,
        nombre: compteurs.entretiensEnRetard,
      ),
      _Alerte(
        cle: 'informationsManquantes',
        libelle: a.informationsManquantes,
        icone: AppIcons.info,
        nombre: compteurs.informationsManquantes,
      ),
      _Alerte(
        cle: 'confirmeesIndisponibles',
        libelle: a.confirmeesIndisponibles,
        icone: AppIcons.suspendre,
        nombre: compteurs.confirmeesIndisponibles,
      ),
    ];
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: SectionHeader(titre: t.admin.candidatures.aTraiter),
        ),
        Ecart.vMd,
        AppCard(
          key: cleCarte,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Grille(alertes: alertes),
              if (compteurs.rienATraiter) ...<Widget>[
                Ecart.vLg,
                TexteSansCoupure(
                  a.rien,
                  key: cleRien,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une alerte : son mot, son icone, son nombre.
class _Alerte {
  const _Alerte({
    required this.cle,
    required this.libelle,
    required this.icone,
    required this.nombre,
  });

  final String cle;
  final String libelle;
  final AppIcon icone;

  /// Le nombre servi, ou `null` quand le serveur ne le sert pas encore.
  final int? nombre;
}

/// Les quatre alertes : en colonne sur telephone et tablette (quatre lignes
/// d'une meme carte), cote a cote sur bureau. Le texte agrandi remet la
/// colonne : un mot ne se coupe jamais.
class _Grille extends StatelessWidget {
  const _Grille({required this.alertes});

  final List<_Alerte> alertes;

  @override
  Widget build(BuildContext context) {
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final bool texteGrand = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (bureau && !texteGrand) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < alertes.length; i++) ...<Widget>[
            if (i > 0) Ecart.hLg,
            Expanded(child: _Ligne(alerte: alertes[i], enColonne: true)),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.md,
      children: <Widget>[
        for (final _Alerte a in alertes)
          _Ligne(alerte: a, enColonne: texteGrand),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.alerte, required this.enColonne});

  final _Alerte alerte;

  /// Vrai : l'icone et le mot au-dessus du nombre (bureau, quatre cellules, ou
  /// texte agrandi) ; faux : une ligne, le mot au debut et le nombre au bord
  /// de fin. Un compteur non servi, qui se dit en une phrase, passe toujours
  /// sous son mot : une phrase ne se loge pas au bout d'une ligne.
  final bool enColonne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final int? n = alerte.nombre;
    final String servi = t.commun.etats.branchementServeur;
    final Widget nombre = n == null
        ? TexteSansCoupure(
            servi,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          )
        : TexteSansCoupure(
            '$n',
            style: AppTypography.tabulaire(
              palette.inkStrong.applyTo(textes.titleLarge ?? const TextStyle()),
            ),
          );
    final Widget mot = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          alerte.icone.repos,
          size: AppSpacing.xl,
          color: palette.inkMuted.asIconTheme().color,
        ),
        Ecart.hSm,
        Flexible(
          child: TexteSansCoupure(
            alerte.libelle,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
    final bool empile = enColonne || n == null;
    return Semantics(
      key: CarteAlertes.cleAlerte(alerte.cle),
      container: true,
      label: '${alerte.libelle} : ${n ?? servi}',
      excludeSemantics: true,
      child: empile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: <Widget>[mot, nombre],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: mot),
                Ecart.hMd,
                nombre,
              ],
            ),
    );
  }
}
