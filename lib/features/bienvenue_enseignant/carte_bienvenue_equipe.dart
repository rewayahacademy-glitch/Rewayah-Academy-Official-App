// SALLE-3-ACCUEIL (plan des trois salles, accepte par le directeur le
// 07/11/2026) : la carte « Bienvenue dans l'equipe » de l'espace enseignant
// qui n'a pas encore de Classe. En tete, ce qui reste a configurer (coordonnees
// de versement, disponibilites, photo publique), puis le rappel des
// remplacements.
//
// **Rien n'est calcule ici (E6).** Chaque ligne vient d'une lecture du serveur
// deja existante : la capacite « mes coordonnees de versement »
// (`mesCoordonneesVersementProvider`), les disponibilites declarees
// (`disponibilitesProvider`) et la cle de la photo publique du profil. Une
// lecture pas encore rendue, ou qui echoue, n'affiche pas sa ligne : on ne dit
// pas « a configurer » sur une supposition. Une ligne faite disparait.
//
// Le rappel des remplacements ne promet que ce que l'ecran fait : l'offre
// s'affiche sur la page Journee. La notification sur l'appareil (PUSH-1) viendra
// avec son propre texte.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/port_coordonnees_versement.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import '../paiements_recus/etat_coordonnees.dart';
import '../profil_enseignant/photo_publique.dart';

/// Ce qu'il reste a configurer, dans l'ordre de la carte.
enum ResteAConfigurer { versement, disponibilites, photo }

/// Ce qu'il reste a configurer, d'apres les lectures du serveur. Vide tant que
/// rien n'est lu : jamais une supposition.
final Provider<List<ResteAConfigurer>> resteAConfigurerProvider =
    Provider<List<ResteAConfigurer>>(
      (Ref ref) {
        final String? monId = ref.watch(sessionProvider).profileId;
        final AsyncValue<MesCoordonneesVersement> versement = ref.watch(
          mesCoordonneesVersementProvider,
        );
        final AsyncValue<ProfilEnseignant?> profil = ref.watch(
          profilEnseignantProvider,
        );
        final AsyncValue<List<Creneau>>? dispos = monId == null
            ? null
            : ref.watch(disponibilitesProvider(monId));
        return <ResteAConfigurer>[
          if (versement.hasValue && !versement.requireValue.complet)
            ResteAConfigurer.versement,
          if (dispos != null && dispos.hasValue && dispos.requireValue.isEmpty)
            ResteAConfigurer.disponibilites,
          if (profil.hasValue &&
              profil.value != null &&
              (profil.value!.clePhoto ?? '').isEmpty)
            ResteAConfigurer.photo,
        ];
      },
      dependencies: <ProviderOrFamily>[
        mesCoordonneesVersementProvider,
        profilEnseignantProvider,
        disponibilitesProvider,
      ],
    );

/// La carte « Bienvenue dans l'equipe ».
class CarteBienvenueEquipe extends ConsumerWidget {
  /// Cree la carte.
  const CarteBienvenueEquipe({super.key});

  /// La cle de la carte.
  static const Key cle = ValueKey<String>('carte-bienvenue-equipe');

  /// La cle de la ligne d'un reste a configurer.
  static Key cleLigne(ResteAConfigurer r) =>
      ValueKey<String>('bienvenue-equipe-${r.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final r = t.enseignant.bienvenue.equipe;
    final List<ResteAConfigurer> restes = ref.watch(resteAConfigurerProvider);
    final String prenom =
        ref.watch(profilEnseignantProvider).value?.prenom.trim() ?? '';

    String libelle(ResteAConfigurer reste) => switch (reste) {
      ResteAConfigurer.versement =>
        t.comptable.beneficiaires.recevoir.configurer,
      ResteAConfigurer.disponibilites => t.enseignant.bienvenue.declarer,
      ResteAConfigurer.photo => t.enseignant.bienvenue.prerequisPhoto,
    };
    void ouvrir(ResteAConfigurer reste) => switch (reste) {
      ResteAConfigurer.versement => unawaited(
        context.push(Routes.comptePaiementsRecus),
      ),
      ResteAConfigurer.disponibilites => context.go(Routes.enseignantCreneaux),
      ResteAConfigurer.photo => unawaited(
        ouvrirPhotoPublique(context, prenom: prenom),
      ),
    };

    return AppCard(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              r.titre,
              style: palette.inkStrong.applyTo(
                textes.titleLarge ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          TexteSansCoupure(restes.isEmpty ? r.toutPret : r.intro, style: doux),
          if (restes.isNotEmpty) ...<Widget>[
            Ecart.vLg,
            Semantics(
              header: true,
              child: TexteSansCoupure(
                r.aConfigurer,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            for (final ResteAConfigurer reste in restes)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: LienFleche(
                  key: cleLigne(reste),
                  libelle: libelle(reste),
                  onPress: () => ouvrir(reste),
                ),
              ),
          ],
          Ecart.vLg,
          Semantics(
            header: true,
            child: TexteSansCoupure(
              r.remplacementTitre,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
          TexteSansCoupure(r.remplacement, style: doux),
        ],
      ),
    );
  }
}
