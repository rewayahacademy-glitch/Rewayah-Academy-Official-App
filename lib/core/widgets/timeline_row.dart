import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../planning/journee.dart';
import '../priere/libelle_priere.dart';
import '../tc_groupe/libelles_tc_groupe.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Une entree de la journee : un cours, une pause ou une priere.
///
/// **Le meme composant pour les trois sortes.** `ENS-02` demande une seule
/// colonne du haut vers le bas, ou chaque interruption se lit a sa place dans
/// le deroule et jamais dans un encadre a cote. Un ecran qui choisirait une
/// ligne differente selon la sorte casserait cette colonne ; c'est pourquoi le
/// composant decide lui-meme du libelle et de l'icone a partir de la sorte
/// (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 2). Ce qui distingue les
/// trois est le libelle, jamais la seule couleur.
class TimelineRow extends StatelessWidget {
  /// Cree une ligne de journee.
  const TimelineRow({required this.entree, super.key});

  /// L'entree de la journee a montrer.
  final EntreeJournee entree;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // L'encre secondaire se choisit sur la surface : `inkFaint` tombe a 4,48
    // sur la surface enfoncee, et c'est le seul trou de la rampe.
    final AppInkColor encres = palette.encreSecondaireSur(
      palette.surfaceCanvas,
    );
    final int minutes = entree.duree.inMinutes;

    // Une seance se lit d'un tenant : plage, libelle, eleves et duree (W-243).
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: encres.asIconTheme(size: AppSpacing.xl),
            child: Icon(_icone(entree.sorte).repos),
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t.enseignant.journee.plage(
                    debut: _hhmm(entree.debut),
                    fin: _hhmm(entree.fin),
                  ),
                  style: encres.applyTo(textes.bodySmall ?? const TextStyle()),
                ),
                Text(_libelle(entree), style: textes.titleMedium),
                if (entree.sorte == SorteEntree.cours)
                  Text(
                    entree.seance?.eleveIdentifiant ?? '',
                    style: encres.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
              ],
            ),
          ),
          Ecart.hSm,
          Text(
            // DUREE-INSECABLE-1 : « 45 min » jamais scinde.
            LibellesGroupe.insecable(
              t.enseignant.journee.duree(minutes: '$minutes'),
            ),
            style: encres.applyTo(textes.bodySmall ?? const TextStyle()),
          ),
        ],
      ),
    );
  }
}

/// L'icone de la sorte : le temps qui travaille, une pause, une priere.
AppIcon _icone(SorteEntree sorte) => switch (sorte) {
  SorteEntree.cours => AppIcons.cours,
  SorteEntree.pause => AppIcons.pause,
  SorteEntree.priere => AppIcons.priere,
};

/// Le libelle d'une entree, selon sa sorte.
///
/// Une seance de Classe (sans eleve unique, `eleveId` vide) porte deja son
/// nom, « Classe An-Nour » : il est dit seul, sans « Cours avec la »
/// (recette EN-12, decision EN-RC).
String _libelle(EntreeJournee entree) => switch (entree.sorte) {
  SorteEntree.cours when entree.seance?.eleveId.isEmpty ?? false =>
    entree.seance!.elevePrenom,
  SorteEntree.cours => t.enseignant.journee.ligneCours(
    prenom: entree.seance?.elevePrenom ?? '',
  ),
  SorteEntree.pause => t.enseignant.journee.lignePause,
  SorteEntree.priere =>
    entree.interruption == null
        ? t.enseignant.journee.lignePause
        : libellePriere(entree.interruption!.priere),
};

/// L'heure locale d'un instant, sur deux chiffres.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';
