// La grille des disponibilites (CAND-01) : les jours de la semaine par les
// plages de la journee, a toucher. Rien a taper : chaque cellule est une carte
// qui se touche (`AppCard`), retenue par un contour d'accent, une coche et le
// mot « choisie » pour le lecteur d'ecran, jamais par la couleur seule.
//
// Telephone : un bloc par jour, ses six plages sur deux rangees. Tablette et
// bureau : un tableau, les plages en colonnes, les jours en lignes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/candidature/creneaux_declares.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import 'libelles_parcours.dart';

/// Un appui sur une cellule : le jour (1 a 7) et la plage (0 a 5).
typedef AppuiCellule = void Function(int jour, int plage);

/// La grille jours par plages.
class GrilleCreneaux extends StatelessWidget {
  /// Cree la grille.
  const GrilleCreneaux({
    required this.creneaux,
    required this.onBascule,
    super.key,
  });

  /// Les plages declarees.
  final CreneauxDeclares creneaux;

  /// Appele quand une cellule est touchee.
  final AppuiCellule onBascule;

  /// La cle d'une cellule, pour les tests.
  static Key celluleKey(int jour, int plage) =>
      ValueKey<String>('creneau-$jour-$plage');

  /// La largeur d'une cellule qui montre « 16:00 - 20:00 » sur une ligne, a
  /// l'echelle 1 ; elle grandit avec la taille du texte.
  static const double largeurCellule = 88;

  /// La colonne des jours du tableau.
  static const double colonneJour = 112;

  /// L'echelle du texte choisie par la personne (1 par defaut).
  static double _echelle(BuildContext context) =>
      math.max(1, MediaQuery.textScalerOf(context).scale(14) / 14);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) {
      // Le tableau demande de la place pour six colonnes lisibles ; sinon, des
      // blocs par jour. Un texte agrandi passe plus tot aux blocs, puis a une
      // ou deux colonnes : jamais une heure coupee sur deux lignes.
      final double tableau =
          colonneJour +
          AppSpacing.sm +
          plagesParJour * (largeurCellule * _echelle(context) + AppSpacing.sm);
      return c.maxWidth >= tableau
          ? _tableau(context)
          : _blocs(context, c.maxWidth);
    },
  );

  Widget _tableau(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: colonneJour + AppSpacing.sm),
            for (int p = 0; p < plagesParJour; p++) ...<Widget>[
              if (p > 0) Ecart.hSm,
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      nomDePlage(p),
                      textAlign: TextAlign.center,
                      style: textes.labelLarge,
                    ),
                    Text(
                      _heures(p),
                      textAlign: TextAlign.center,
                      style: palette.inkMuted.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        Ecart.vMd,
        for (int j = 1; j <= joursParSemaine; j++) ...<Widget>[
          if (j > 1) Ecart.vSm,
          Row(
            children: <Widget>[
              SizedBox(
                width: colonneJour,
                child: Text(_jour(j), style: textes.titleSmall),
              ),
              Ecart.hSm,
              for (int p = 0; p < plagesParJour; p++) ...<Widget>[
                if (p > 0) Ecart.hSm,
                Expanded(
                  child: AppCard(
                    key: celluleKey(j, p),
                    marge: AppSpacing.sm,
                    selectionnee:
                        creneaux.etat(jour: j, plage: p) == EtatCellule.pleine,
                    libelleSemantique: _libelleSemantique(j, p),
                    onPress: () => onBascule(j, p),
                    child: _ContenuCellule(
                      etat: creneaux.etat(jour: j, plage: p),
                      plage: p,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _blocs(BuildContext context, double largeur) {
    final TextTheme textes = Theme.of(context).textTheme;
    // Trois, deux ou une colonne selon la place qu'il faut a une cellule.
    final int colonnes =
        ((largeur + AppSpacing.sm) /
                (largeurCellule * _echelle(context) + AppSpacing.sm))
            .floor()
            .clamp(1, 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int j = 1; j <= joursParSemaine; j++) ...<Widget>[
          if (j > 1) Ecart.vXl,
          Text(_jour(j), style: textes.titleMedium),
          Ecart.vSm,
          for (
            int ligne = 0;
            ligne < plagesParJour ~/ colonnes;
            ligne++
          ) ...<Widget>[
            if (ligne > 0) Ecart.vSm,
            Row(
              children: <Widget>[
                for (int k = 0; k < colonnes; k++) ...<Widget>[
                  if (k > 0) Ecart.hSm,
                  Expanded(
                    child: AppCard(
                      key: celluleKey(j, ligne * colonnes + k),
                      marge: AppSpacing.sm,
                      selectionnee:
                          creneaux.etat(jour: j, plage: ligne * colonnes + k) ==
                          EtatCellule.pleine,
                      libelleSemantique: _libelleSemantique(
                        j,
                        ligne * colonnes + k,
                      ),
                      onPress: () => onBascule(j, ligne * colonnes + k),
                      child: _ContenuCellule(
                        etat: creneaux.etat(
                          jour: j,
                          plage: ligne * colonnes + k,
                        ),
                        plage: ligne * colonnes + k,
                        avecNom: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ],
    );
  }

  /// Ce que le lecteur d'ecran dit d'une cellule : le jour, la plage, les
  /// heures, puis son etat si elle est retenue ou en partie.
  String _libelleSemantique(int jour, int plage) {
    final EtatCellule etat = creneaux.etat(jour: jour, plage: plage);
    final String etatLu = switch (etat) {
      EtatCellule.pleine => t.recrutement.parcours.creneaux.choisie,
      EtatCellule.partielle => t.recrutement.parcours.creneaux.partielle,
      EtatCellule.vide => '',
    };
    return <String>[
      t.recrutement.parcours.creneaux.jourCellule(
        jour: _jour(jour),
        plage: nomDePlage(plage),
      ),
      _heures(plage),
      if (etatLu.isNotEmpty) etatLu,
    ].join(', ');
  }

  static String _jour(int jour) {
    final String nom = t.disponibilites.joursLongs[jour - 1];
    return nom.isEmpty ? nom : nom[0].toUpperCase() + nom.substring(1);
  }

  /// « 08:00 - 12:00 », isole pour rester en ordre dans une phrase arabe.
  static String _heures(int plage) =>
      isolerSens('${_h(heureDebutPlage(plage))} - ${_h(heureFinPlage(plage))}');

  static String _h(int heure) => '${heure.toString().padLeft(2, '0')}:00';
}

/// Ce que la cellule montre : une icone d'etat (coche, plus, moins) et, sur
/// telephone, le nom de la plage et ses heures. Ce n'est pas une carte : la
/// carte est posee par la grille, qui en fixe l'ecart.
class _ContenuCellule extends StatelessWidget {
  const _ContenuCellule({
    required this.etat,
    required this.plage,
    this.avecNom = false,
  });

  final EtatCellule etat;
  final int plage;

  /// Vrai sur telephone : la cellule porte le nom de sa plage.
  final bool avecNom;

  @override
  Widget build(BuildContext context) {
    final bool pleine = etat == EtatCellule.pleine;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String heures = GrilleCreneaux._heures(plage);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.titreEcran),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: IconTheme(
              data: pleine
                  ? IconThemeData(
                      color: palette.washAccent.onBackground,
                      size: AppSpacing.xxl,
                    )
                  : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
              child: Icon(switch (etat) {
                EtatCellule.pleine => AppIcons.succes.actif,
                EtatCellule.partielle => AppIcons.moins.repos,
                EtatCellule.vide => AppIcons.ajouter.repos,
              }),
            ),
          ),
          if (avecNom) ...<Widget>[
            Ecart.vXs,
            ExcludeSemantics(
              child: Text(
                nomDePlage(plage),
                textAlign: TextAlign.center,
                style: textes.labelMedium,
              ),
            ),
            ExcludeSemantics(
              child: Text(
                heures,
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
