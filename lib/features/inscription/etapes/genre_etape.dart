import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
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
      explication: t.inscription.genreRaison,
      libelleAction: t.commun.continuer,
      onAction: genre == null ? null : () => avancerDepuis(context, _route),
      onRetour: () => reculerDepuis(context, _route),
      enfant: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: CarteChoixInscription(
                key: const Key('inscription-genre-homme'),
                icone: AppIcons.profil,
                titre: t.inscription.genreHomme,
                verticale: true,
                retenue: genre == Genre.homme,
                onPress: () => controleur.choisirGenre(Genre.homme),
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: CarteChoixInscription(
                key: const Key('inscription-genre-femme'),
                icone: AppIcons.profil,
                titre: t.inscription.genreFemme,
                verticale: true,
                retenue: genre == Genre.femme,
                onPress: () => controleur.choisirGenre(Genre.femme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
