import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/genre` : deux cartes cote a cote, aucune preselection.
class GenreEtape extends ConsumerWidget {
  /// Cree l'etape.
  const GenreEtape({super.key});

  static const String _route = Routes.inscriptionGenre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrouillonInscription brouillon = ref.watch(
      brouillonInscriptionProvider,
    );
    exigerEtapesPrecedentes(context, brouillon, _route);
    final BrouillonInscriptionControleur controleur = ref.read(
      brouillonInscriptionProvider.notifier,
    );
    final Genre? genre = brouillon.genre;

    return CoquilleEtape(
      route: _route,
      question: t.inscription.genreQuestion,
      // K-47 : la seule raison dite est la relecture de la piece, qui ne
      // concerne que l'enseignant ; aucune explication pour le tuteur.
      explication: brouillon.usage == UsageInscription.enseignant
          ? t.inscription.genreRaison
          : null,
      libelleAction: t.commun.continuer,
      onAction: genre == null ? null : () => avancerDepuis(context, _route),
      onRetour: () => reculerDepuis(context, _route),
      // Le groupe partage, sans carte « Autre », en disposition cote a cote
      // (demande A-5.2, maquette « onboarding Mble d »).
      enfant: ChoiceCardGroup(
        key: const Key('inscription-genre'),
        autoriserSaisieLibre: false,
        coteACote: true,
        valeurInitiale: genre == null
            ? null
            : ReponseChoix(valeurs: <String>{genre.name}),
        options: <OptionChoix>[
          OptionChoix(
            valeur: Genre.homme.name,
            libelle: t.inscription.genreHomme,
            icone: AppIcons.homme,
          ),
          OptionChoix(
            valeur: Genre.femme.name,
            libelle: t.inscription.genreFemme,
            icone: AppIcons.femme,
          ),
        ],
        onChange: (ReponseChoix reponse) {
          for (final Genre g in <Genre>[Genre.homme, Genre.femme]) {
            if (reponse.valeurs.contains(g.name)) {
              controleur.choisirGenre(g);
            }
          }
        },
      ),
    );
  }
}
