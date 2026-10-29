import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/offres/offre_horaire.dart' show LangueCours;
import '../../../core/offres/service_offres.dart' show languesCoursProvider;
import '../../../core/router/routes.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/skeleton.dart';
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/langue` : la langue du cours, premiere question apres la
/// connexion pour « pour moi » et « mon enfant » (admission, lot B,
/// 29/10/2026).
///
/// Elle venait dans le questionnaire avant le compte (fiche du 29/10, ecran
/// 6) ; mais le referentiel des langues ne se lit pas sans compte (`0043` :
/// « anon n'a rien a faire ici »), et cette regle ne change pas pour une
/// question. Une langue pour toute la demande ; le nom vient du serveur.
class LangueEtape extends ConsumerWidget {
  /// Cree l'etape.
  const LangueEtape({super.key});

  static const String _route = Routes.inscriptionLangue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrouillonInscription brouillon = ref.watch(
      brouillonInscriptionProvider,
    );
    exigerEtapesPrecedentes(context, brouillon, _route);
    final AsyncValue<List<LangueCours>> langues = ref.watch(
      languesCoursProvider,
    );

    return CoquilleEtape(
      route: _route,
      question: t.parcours.langueQuestion,
      explication: t.parcours.langueRaison,
      libelleAction: t.commun.continuer,
      onAction: brouillon.langue == null
          ? null
          : () => avancerDepuis(context, brouillon, _route),
      onRetour: reculerDepuis(context, brouillon, _route),
      enfant: langues.hasValue
          ? ChoiceCardGroup(
              key: const Key('inscription-langue'),
              autoriserSaisieLibre: false,
              valeurInitiale: brouillon.langue == null
                  ? null
                  : ReponseChoix(valeurs: <String>{brouillon.langue!}),
              options: <OptionChoix>[
                for (final LangueCours l in langues.requireValue)
                  OptionChoix(valeur: l.code, libelle: l.nom),
              ],
              onChange: (ReponseChoix r) {
                if (r.valeurs.isNotEmpty) {
                  ref
                      .read(brouillonInscriptionProvider.notifier)
                      .choisirLangue(r.valeurs.first);
                }
              },
            )
          : langues.hasError
          ? EtatSysteme(
              nature: NatureEtat.echecServeur,
              libelleAction: t.commun.etats.actions.reessayer,
              onAction: () => ref.invalidate(languesCoursProvider),
            )
          : const Skeleton.liste(lignes: 3),
    );
  }
}
