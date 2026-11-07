// Ce qu'il reste a configurer a un enseignant : UNE seule source, lue par
// « Premiers pas » (`BienvenueEnseignantPage`) et par la carte « Bienvenue dans
// l'equipe » de la Journee (`CarteBienvenueEquipe`) (garde-cap, 07/11/2026 :
// « l'accueil doit lui montrer ce qui lui reste a configurer, comme ses infos
// de banque »).
//
// Cinq elements, dans cet ordre : le versement (c'est la paie), la photo, les
// langues, le fuseau, les disponibilites. **Rien n'est calcule ici (E6)** : le
// versement vient de la capacite « mes coordonnees de versement », les quatre
// autres de `prerequis_enseignant` (serveur). Une lecture absente (en cours,
// en echec, capacite indisponible) n'affiche pas sa ligne et ne compte pas
// dans le total : on ne dit pas « a configurer » sur un doute.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_coordonnees_versement.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../paiements_recus/etat_coordonnees.dart';
import '../profil_enseignant/photo_publique.dart';
import 'bienvenue_page.dart';

/// Ce qu'il peut rester a configurer, dans l'ordre d'affichage.
enum ResteAConfigurer { versement, photo, langues, fuseau, disponibilites }

/// La liste de ce qu'il reste a configurer, et combien d'elements sont lus.
@immutable
class ListeAConfigurer {
  /// Cree la liste.
  const ListeAConfigurer({required this.restes, required this.lus});

  /// Ce qui reste a faire, dans l'ordre : le versement d'abord.
  final List<ResteAConfigurer> restes;

  /// Le nombre d'elements dont la lecture est connue (0 a 5).
  final int lus;

  /// Les cinq elements.
  static int get total => ResteAConfigurer.values.length;

  /// Le nombre d'elements lus et deja faits.
  int get faits => lus - restes.length;

  /// Tout est lu et tout est fait.
  bool get complete => lus == total && restes.isEmpty;
}

/// La liste, lue du serveur : **la seule source des deux ecrans**.
final Provider<ListeAConfigurer> listeAConfigurerProvider =
    Provider<ListeAConfigurer>(
      (Ref ref) {
        final AsyncValue<MesCoordonneesVersement> versement = ref.watch(
          mesCoordonneesVersementProvider,
        );
        final PrerequisEnseignant? p = ref.watch(prerequisEnseignantProvider);
        final bool versementLu = versement.hasValue;
        return ListeAConfigurer(
          lus: (versementLu ? 1 : 0) + (p == null ? 0 : 4),
          restes: <ResteAConfigurer>[
            if (versementLu && !versement.requireValue.complet)
              ResteAConfigurer.versement,
            if (p != null && !p.photo) ResteAConfigurer.photo,
            if (p != null && !p.langues) ResteAConfigurer.langues,
            if (p != null && !p.fuseau) ResteAConfigurer.fuseau,
            if (p != null && !p.disponibilites) ResteAConfigurer.disponibilites,
          ],
        );
      },
      dependencies: <ProviderOrFamily>[
        mesCoordonneesVersementProvider,
        prerequisEnseignantProvider,
      ],
    );

/// Ce qu'il reste a configurer, sans le compte.
final Provider<List<ResteAConfigurer>> resteAConfigurerProvider =
    Provider<List<ResteAConfigurer>>(
      (Ref ref) => ref.watch(listeAConfigurerProvider).restes,
      dependencies: <ProviderOrFamily>[listeAConfigurerProvider],
    );

/// Le libelle d'un element (les mots qui existent deja, aucun mot nouveau).
String libelleReste(ResteAConfigurer reste) => switch (reste) {
  ResteAConfigurer.versement => t.comptable.beneficiaires.recevoir.configurer,
  ResteAConfigurer.photo => t.enseignant.bienvenue.prerequisPhoto,
  ResteAConfigurer.langues => t.enseignant.bienvenue.prerequisLangues,
  ResteAConfigurer.fuseau => t.enseignant.bienvenue.prerequisFuseau,
  ResteAConfigurer.disponibilites => t.enseignant.bienvenue.declarer,
};

/// L'icone d'un element.
AppIcon iconeReste(ResteAConfigurer reste) => switch (reste) {
  ResteAConfigurer.versement => AppIcons.paiements,
  ResteAConfigurer.photo => AppIcons.image,
  ResteAConfigurer.langues => AppIcons.cours,
  ResteAConfigurer.fuseau => AppIcons.horloge,
  ResteAConfigurer.disponibilites => AppIcons.disponibilites,
};

/// Ouvre l'ecran qui regle [reste].
void allerVersReste(
  BuildContext context,
  ResteAConfigurer reste, {
  required String prenom,
}) {
  switch (reste) {
    case ResteAConfigurer.versement:
      unawaited(GoRouter.of(context).push(Routes.comptePaiementsRecus));
    case ResteAConfigurer.photo:
      unawaited(ouvrirPhotoPublique(context, prenom: prenom));
    case ResteAConfigurer.langues:
    case ResteAConfigurer.fuseau:
      GoRouter.of(context).go(Routes.enseignantProfil);
    case ResteAConfigurer.disponibilites:
      GoRouter.of(context).go(Routes.enseignantCreneaux);
  }
}
