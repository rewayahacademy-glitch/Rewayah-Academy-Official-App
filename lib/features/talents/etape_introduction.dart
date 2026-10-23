// La premiere etape de « Vos autres talents » (`CAND-07`) : dire pourquoi
// l'academie le demande, avant de demander.
//
// Transparence voulue par le directeur (22/10/2026) : « leur dire pourquoi
// l'academie pourrait avoir besoin d'eux sur un autre domaine ». Le texte
// d'introduction est celui de la proposition ; quatre tuiles disent ensuite
// l'essentiel : c'est facultatif et sans effet sur la candidature d'enseignant,
// ce que devient la reponse, la liberte de la modifier ou de la retirer, et le
// fait que cette page ne promet aucune mission.
library;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../candidature/presentation_etape.dart';

/// Le corps de l'introduction : les quatre tuiles.
class EtapeIntroduction extends StatelessWidget {
  /// Cree le corps.
  const EtapeIntroduction({super.key});

  /// Le texte d'introduction, lu sous le titre de la page.
  static String get texte => t.recrutement.talents.intro.texte;

  @override
  Widget build(BuildContext context) {
    final i = t.recrutement.talents.intro;
    return TuilesInformation(
      tuiles: <TuileInformation>[
        TuileInformation(AppIcons.info, i.facultatif.titre, i.facultatif.texte),
        TuileInformation(AppIcons.verrou, i.usage.titre, i.usage.texte),
        TuileInformation(AppIcons.succes, i.liberte.titre, i.liberte.texte),
        TuileInformation(AppIcons.annonce, i.missions.titre, i.missions.texte),
      ],
    );
  }
}
