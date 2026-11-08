// « A traiter » : les alertes de la file **que le serveur sert vraiment**, sur
// une ligne, dans une seule carte (`ADM-20`). Quatre cartes egales sont
// interdites (`ENTREE:19`, K-55).
//
// REPRISE-CAND-3 (08/11/2026, pilote) : le comportement de la synthese de la
// PR 45, repris ici sur place. Le serveur (`lister_candidatures`) rend un
// entier pour « Informations manquantes » et « Confirmees indisponibles » ; il
// rend `NULL` pour « Bloquees » et « Entretiens en retard » (dette nommee dans
// le bilan du lot). Une alerte nulle **ne s'affiche pas** : ni « Disponible au
// branchement serveur », ni un zero qui ne serait pas lu. Le jour ou le serveur
// rend un entier pour l'une d'elles, elle s'affiche avec son mot et son nombre.
// Quand les quatre sont servies et valent zero, la carte dit « Rien a traiter ».
//
// Les nombres sont ceux du serveur, calcules dans la portee de genre du
// lecteur, sans les autres filtres. Une pause n'entre dans aucune alerte
// (`CONS` §10). Le total « N candidatures » reste dans la barre de la liste.
//
// Les alertes ne se touchent pas : poser le filtre d'une alerte demande une
// cle de filtre `alerte` que `lister_candidatures` ne connait pas, et un filtre
// approchant donnerait une liste qui ne compte pas ce que le compteur annonce.
// Un element qui ne peut pas aboutir n'est pas pressable.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';

/// La carte des alertes servies.
class CarteAlertes extends StatelessWidget {
  /// Cree la carte.
  const CarteAlertes({required this.compteurs, super.key});

  /// Les compteurs rendus par le serveur.
  final CompteursAlertes compteurs;

  /// La cle de la carte.
  static const Key cleCarte = ValueKey<String>('candidatures-alertes');

  /// La cle de l'alerte [nom] (`bloquees`, `entretiensEnRetard`,
  /// `informationsManquantes`, `confirmeesIndisponibles`), rendue seulement
  /// quand le serveur sert son nombre.
  static Key cleAlerte(String nom) =>
      ValueKey<String>('candidatures-alerte-$nom');

  /// La cle de la phrase « Rien a traiter ».
  static const Key cleRien = ValueKey<String>('candidatures-alertes-rien');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.candidatures.alertes;
    final s = t.admin.candidatures.liste.synthese;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    final int? bloquees = compteurs.bloquees;
    final int? retard = compteurs.entretiensEnRetard;
    final int? manquantes = compteurs.informationsManquantes;
    final int? indisponibles = compteurs.confirmeesIndisponibles;
    final bool rien = compteurs.rienATraiter;

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
          child: rien
              ? TexteSansCoupure(a.rien, key: cleRien, style: attenue)
              : Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (manquantes != null)
                      _Alerte(
                        nom: 'informationsManquantes',
                        icone: AppIcons.info,
                        texte: s.informationsManquantes(n: manquantes),
                      ),
                    if (indisponibles != null)
                      _Alerte(
                        nom: 'confirmeesIndisponibles',
                        icone: AppIcons.suspendre,
                        texte: s.confirmeesIndisponibles(n: indisponibles),
                      ),
                    if (bloquees != null)
                      _Alerte(
                        nom: 'bloquees',
                        icone: AppIcons.interdit,
                        texte: a.bloquees,
                        nombre: bloquees,
                      ),
                    if (retard != null)
                      _Alerte(
                        nom: 'entretiensEnRetard',
                        icone: AppIcons.horloge,
                        texte: a.entretiensEnRetard,
                        nombre: retard,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Une alerte servie : son icone, sa phrase (ou son mot et son nombre).
class _Alerte extends StatelessWidget {
  const _Alerte({
    required this.nom,
    required this.icone,
    required this.texte,
    this.nombre,
  });

  final String nom;
  final AppIcon icone;

  /// La phrase complete (« 12 informations manquantes »), ou le mot seul
  /// quand [nombre] est donne a part.
  final String texte;

  /// Le nombre, pour les alertes dont le texte n'a pas de pluriel.
  final int? nombre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle style = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final int? n = nombre;
    return Semantics(
      key: CarteAlertes.cleAlerte(nom),
      container: true,
      label: n == null ? texte : '$texte : $n',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icone.repos,
            size: AppSpacing.lg,
            color: palette.inkWarning.asIconTheme().color,
          ),
          Ecart.hXs,
          Flexible(child: TexteSansCoupure(texte, style: style)),
          if (n != null) ...<Widget>[
            Ecart.hSm,
            TexteSansCoupure(
              '$n',
              style: AppTypography.tabulaire(
                palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
