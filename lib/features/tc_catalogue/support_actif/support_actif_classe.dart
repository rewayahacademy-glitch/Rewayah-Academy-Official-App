/// CAP29-G : ce que la classe voit du support presente (spec CAP-29 §3.1, §6.3).
///
/// L'eleve (et le tuteur qui accompagne) **suit automatiquement** : l'ecran ne
/// porte aucun bouton « Suivre l'enseignant ». Il dit l'etat du support
/// presente, rien d'autre ; l'ouverture d'une fiche ou du lecteur existant est
/// un lien, jamais un rendu ici (le Coran n'est jamais rendu par cet ecran).
///
/// Cinq etats : attente de la premiere reponse (squelette), aucun support
/// presente, support presente, support retire en cours de seance, erreur ou
/// connexion perdue avec relance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:go_router/go_router.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
import '../../../core/router/routes.dart';
import '../../../core/tc_bibliotheque/content_position.dart';
import '../../../core/tc_bibliotheque/library_resource.dart';
import '../../../core/tc_bibliotheque/port_support_actif.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/skeleton.dart';
import '../libelles_bibliotheque.dart';
import '../routes_tc_b.dart';

/// Le flux du support actif d'une seance.
final StreamProviderFamily<SupportActif?, String> supportActifProvider =
    StreamProvider.family<SupportActif?, String>(
      (Ref ref, String seanceId) =>
          ref.watch(portSupportActifProvider)!.suivre(seanceId),
    );

/// Le support presente a la classe de [seanceId].
class SupportActifClasse extends ConsumerWidget {
  /// Cree l'ecran.
  const SupportActifClasse({required this.seanceId, super.key});

  /// La seance suivie.
  final String seanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = t.tc.bibliotheque.actif;
    if (ref.watch(portSupportActifProvider) == null) {
      return EtatSysteme(
        key: const ValueKey<String>('actif-indisponible'),
        nature: NatureEtat.indisponible,
        titre: a.indisponibleTitre,
        phrase: a.indisponible,
        dependance: 'BR-1',
      );
    }
    final AsyncValue<SupportActif?> etat = ref.watch(
      supportActifProvider(seanceId),
    );
    return switch (etat) {
      AsyncValue<SupportActif?>(hasError: true) =>
        etat.error is SupportActifHorsLigne
            ? EtatSansDonnees(
                key: const ValueKey<String>('actif-sans-donnees'),
                quoi: a.sansDonnees,
                onAction: () => ref.invalidate(supportActifProvider(seanceId)),
              )
            : EtatSysteme(
                key: const ValueKey<String>('actif-erreur'),
                nature: NatureEtat.echecServeur,
                phrase: a.erreur,
                onAction: () => ref.invalidate(supportActifProvider(seanceId)),
              ),
      AsyncValue<SupportActif?>(hasValue: true) => _Contenu(
        actif: etat.requireValue,
      ),
      _ => const Skeleton.texte(
        key: ValueKey<String>('actif-chargement'),
        lignes: 3,
      ),
    };
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.actif});

  final SupportActif? actif;

  @override
  Widget build(BuildContext context) {
    final a = t.tc.bibliotheque.actif;
    final SupportActif? s = actif;
    if (s == null) {
      return EmptyState(
        key: const ValueKey<String>('actif-aucun'),
        message: a.aucun,
        invitation: a.aucunDetail,
      );
    }
    final TextTheme textes = Theme.of(context).textTheme;
    if (s.retire) {
      return AppCard(
        key: const ValueKey<String>('actif-retire'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              liveRegion: true,
              child: TexteSansCoupure(
                a.retire(titre: s.titre),
                style: textes.titleMedium,
              ),
            ),
            Ecart.vSm,
            Text(a.retireDetail),
          ],
        ),
      );
    }
    final ContentPosition? p = s.position;
    return AppCard(
      key: const ValueKey<String>('actif-contenu'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(a.titre, style: textes.labelMedium),
          Ecart.vXs,
          Semantics(
            liveRegion: true,
            header: true,
            child: TexteSansCoupure(
              s.titre,
              key: const ValueKey<String>('actif-titre'),
              style: textes.titleLarge,
            ),
          ),
          Ecart.vXs,
          TexteSansCoupure(
            <String>[
              libelleTypeRessource(s.type),
              if (s.numeroVersion != null)
                a.version(numero: '${s.numeroVersion}'),
              if (p != null && p.page != null) a.page(page: '${p.page}'),
            ].join(' · '),
            style: textes.bodySmall,
          ),
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: const ValueKey<String>('actif-ouvrir'),
              libelle: s.type == TypeRessource.quran
                  ? a.ouvrirCoran
                  : a.ouvrirFiche,
              // Un lien vers l'ecran existant : jamais un rendu ici.
              onPress: () => GoRouter.of(context).go(
                s.type == TypeRessource.quran
                    ? Routes.tcMushaf
                    : RoutesTcB.versRessource(s.resourceId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
