import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/section_header.dart';
import 'libelles_parcours.dart';

/// Ou en est le parcours de chaque apprenant du foyer, a l'accueil.
///
/// **Additif, pose AU-DESSUS des cartes d'enfants et jamais a leur place.** Les
/// cinq phases existantes (`PhaseEnfant`) decrivent la vie d'un cours deja
/// affecte ; ce bloc decrit ce qui se passe avant. Fondre les deux aurait
/// oblige a reecrire un ecran couvert par ses tests, pour un gain nul.
///
/// **Il ne dit jamais qu'une place est reservee.** Les quatre etats que la
/// mission demande de distinguer -- preference enregistree, diagnostic a faire,
/// groupe en formation, groupe confirme -- sont dits avec ces mots-la, et la
/// phrase vient d'un seul endroit, `etapeParcours`, partage avec le parcours
/// lui-meme.
///
/// Le bloc disparait entierement quand tous les apprenants du foyer ont un
/// groupe confirme : un rappel sans objet est du bruit.
class BlocParcours extends ConsumerWidget {
  /// Cree le bloc.
  const BlocParcours({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ParcoursApprenant>> parcours = ref.watch(
      parcoursFoyerProvider,
    );
    final AsyncValue<ReglesAcademie> regles = ref.watch(reglesAcademieProvider);

    // Silencieux tant qu'on ne sait pas : un bloc « parcours a personnaliser »
    // affiche par defaut dirait a une famille deja inscrite qu'il lui manque
    // quelque chose. Idem pour les autres erreurs -- l'accueil porte deja son
    // propre message.
    //
    // Exception : backend du parcours absent sur ce serveur (0043 non
    // appliquee, 42P01 ou PGRST205). Indisponible honnete (K5), jamais un bloc
    // qui disparait sans rien dire. Aucune action : rien a faire ni a
    // reessayer.
    // (Pas de test isLoading : Riverpod 3 relance seul un fournisseur en
    // echec, l'etat reste alors en chargement AVEC l'erreur precedente.)
    if (parcours.hasError &&
        classerPanneParcours(parcours.error!) == PanneParcours.indisponible) {
      return const _CarteIndisponible();
    }
    if (!parcours.hasValue) {
      return const SizedBox.shrink();
    }

    final List<ParcoursApprenant> aSuivre = parcours.requireValue
        .where(
          (ParcoursApprenant p) =>
              etapeParcours(p) != EtapeParcours.groupeConfirme,
        )
        .toList(growable: false);

    if (aSuivre.isEmpty) {
      return const SizedBox.shrink();
    }

    final int? minimum = regles.value?.minimumLancement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.parcours.titre(prenom: aSuivre.first.prenom)),
        Ecart.vLg,
        for (final ParcoursApprenant p in aSuivre)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _Carte(apprenant: p, minimumLancement: minimum),
          ),
        Ecart.vXl,
      ],
    );
  }
}

/// Le questionnaire n'est pas encore ouvert par l'academie (K5).
class _CarteIndisponible extends StatelessWidget {
  const _CarteIndisponible();

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BentoTile(
          key: const Key('bloc-parcours-indisponible'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(t.parcours.indisponibleTitre, style: textes.titleMedium),
              Ecart.vSm,
              Text(t.parcours.indisponibleDetail, style: textes.bodyMedium),
            ],
          ),
        ),
        Ecart.vXl,
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.apprenant, required this.minimumLancement});

  final ParcoursApprenant apprenant;
  final int? minimumLancement;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final EtapeParcours etape = etapeParcours(apprenant);

    // Une seule action par carte : celle qui fait avancer. Un ecran d'attente
    // qui propose trois boutons donne l'illusion qu'on peut hater les choses.
    final (String?, String) action = switch (etape) {
      EtapeParcours.aPersonnaliser => (t.parcours.commencer, ''),
      EtapeParcours.horaireAChoisir => (t.parcours.voirHoraires, ''),
      EtapeParcours.offreIndisponible => (t.parcours.changerHoraire, ''),
      _ => (null, ''),
    };

    return BentoTile(
      // Le contour fort marque ce qui attend un geste, jamais ce qui attend
      // l'academie : la famille doit voir d'un coup d'oeil ce qui depend d'elle.
      contourFort: action.$1 != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(apprenant.prenom, style: textes.bodySmall),
          Ecart.vXs,
          Text(titreEtape(etape), style: textes.titleMedium),
          Ecart.vSm,
          Text(
            detailEtape(
              etape,
              prenom: apprenant.prenom,
              minimumLancement: minimumLancement,
            ),
            style: textes.bodyMedium,
          ),
          // Le fuseau a change depuis le choix : l'horaire n'a pas bouge pour
          // l'academie, mais il ne tombe plus a la meme heure chez la famille.
          // Le taire serait la laisser manquer son cours.
          if (apprenant.fuseauChange) ...<Widget>[
            Ecart.vMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconTheme(
                  data: palette.inkAlert.asIconTheme(size: AppSpacing.xl),
                  child: Icon(AppIcons.avertissement.repos),
                ),
                Ecart.hSm,
                Expanded(
                  child: Text(
                    t.parcours.fuseauChangeDetail,
                    style: palette.inkAlert.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (action.$1 != null) ...<Widget>[
            Ecart.vMd,
            ActionPrincipale(
              libelle: action.$1!,
              onPress: () =>
                  GoRouter.of(context)
                      .go(Routes.parcoursPour(apprenant.eleveId)),
            ),
          ],
        ],
      ),
    );
  }
}
