import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/theme/app_spacing.dart';

/// « Comment ca marche ? » : les visites d'observation expliquees depuis la
/// politique EFFECTIVE (decision 03 section 1 bis-4). Aucune valeur n'est
/// codee ici : sans politique lue, l'ecran dit que les valeurs s'affichent
/// depuis la classe, il n'en invente pas.
///
/// Textes en cles `consentement.comment.*`, reutilisables par l'observation
/// (lot C-obs) sans import Dart (00_OWNERSHIP section 6 bis).
class ExplicationObservation extends StatelessWidget {
  /// Cree l'explication.
  const ExplicationObservation({super.key, this.politique});

  /// La politique effective de la classe, ou `null` hors d'une classe.
  final GuardianObservationPolicy? politique;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.consentement.comment.titre, style: textes.titleMedium),
        Ecart.vMd,
        for (final String phrase in phrasesExplication(politique))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(phrase, style: textes.bodyMedium),
          ),
      ],
    );
  }
}

/// Les phrases de « Comment ca marche ? » pour une politique donnee.
List<String> phrasesExplication(GuardianObservationPolicy? politique) {
  if (politique == null) {
    return <String>[
      t.consentement.comment.valeursIndisponibles,
      t.consentement.comment.parParent,
      t.consentement.comment.ecourtee,
      t.consentement.comment.ecouter,
      t.consentement.comment.sansMicro,
    ];
  }
  if (!politique.observationActivee || politique.maxVisitsPerSession <= 0) {
    return <String>[t.consentement.comment.fermee];
  }
  final int n = politique.maxVisitsPerSession;
  final Duration? parVisite = politique.maxParVisite;
  final int minutes = parVisite == null ? 0 : (parVisite.inSeconds / 60).ceil();
  return <String>[
    if (minutes > 0)
      t.consentement.comment.visites(n: n, minutes: minutes)
    else
      t.consentement.comment.visitesSansDuree(n: n),
    t.consentement.comment.parParent,
    t.consentement.comment.ecourtee,
    t.consentement.comment.ecouter,
    t.consentement.comment.sansMicro,
  ];
}
