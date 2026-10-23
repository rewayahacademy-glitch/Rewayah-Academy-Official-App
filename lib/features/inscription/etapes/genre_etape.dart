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
    // Lot E2 : chaque option s'explique. L'enseignant lit pourquoi sa piece
    // d'identite en depend ; les autres, a quoi sert la reponse.
    final bool enseignant = brouillon.usage == UsageInscription.enseignant;
    // Lot F2 : le comptable ne suit pas de cours et ne depose pas de piece ;
    // aucune des deux explications ne le concerne.
    final bool comptable = brouillon.usage == UsageInscription.comptable;

    return CoquilleEtape(
      route: _route,
      choix: true,
      question: t.inscription.genreQuestion,
      // K-47 : la seule raison dite est la relecture de la piece, qui ne
      // concerne que l'enseignant ; aucune explication pour le tuteur.
      explication: enseignant ? t.inscription.genreRaison : null,
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
            explication: comptable
                ? null
                : enseignant
                ? t.inscription.genreHommeEnseignant
                : t.inscription.genreHommeExplication,
            icone: AppIcons.homme,
            illustration: IllustrationChoix(
              AppIcons.homme,
              autour: <AppIcon>[
                if (enseignant) AppIcons.verrou else AppIcons.classes,
              ],
            ),
          ),
          OptionChoix(
            valeur: Genre.femme.name,
            libelle: t.inscription.genreFemme,
            explication: comptable
                ? null
                : enseignant
                ? t.inscription.genreFemmeEnseignant
                : t.inscription.genreFemmeExplication,
            icone: AppIcons.femme,
            illustration: IllustrationChoix(
              AppIcons.femme,
              autour: <AppIcon>[
                if (enseignant) AppIcons.verrou else AppIcons.classes,
              ],
            ),
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
