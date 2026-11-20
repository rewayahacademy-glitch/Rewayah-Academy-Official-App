// PRAXIS-VISIBLE : le travail de Praxis dans la file des candidatures.
//
//  - [MarqueTravailPraxis] : sous le nom d'une ligne, discretement, la pile
//    ou Praxis a range le dossier et son etiquette (« Praxis : Pret a decider
//    · Pepite »), quand elles existent ;
//  - [LienTravailPraxis] : le lien vers la page « Le travail de Praxis », avec
//    le nombre de dossiers ranges.
//
// La liste est paginee au serveur (`lister_candidatures`), qui ne connait ni
// la pile ni l'etiquette : elle ne peut pas etre filtree par elles sans un
// changement du serveur. Le filtre vit donc dans la page « Le travail de
// Praxis » (adresse `?pile=…&etiquette=…`).
//
// Une lecture qui echoue, un refus du serveur (lecteur qui n'est pas la
// direction) ou rien a dire : rien n'est rendu, la file reste celle d'avant.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/agent/travail_praxis.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import 'libelles_praxis.dart';

/// La pile et l'etiquette de Praxis pour le dossier [reference], ou rien.
class MarqueTravailPraxis extends ConsumerWidget {
  /// Cree la marque.
  const MarqueTravailPraxis({required this.reference, super.key});

  /// La reference du dossier (`CAND-...`).
  final String reference;

  /// La cle de la marque, pour les tests.
  static Key cle(String reference) =>
      ValueKey<String>('candidature-praxis-travail-$reference');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PilePraxis? pile;
    for (final RangementPraxis r
        in ref.watch(rangementsPraxisProvider).value?.lignes ??
            const <RangementPraxis>[]) {
      if (r.reference == reference) pile = r.pile;
    }
    EtiquettePraxis? etiquette;
    for (final ImpressionPraxis i
        in ref.watch(impressionsPraxisProvider).value?.lignes ??
            const <ImpressionPraxis>[]) {
      if (i.reference == reference) etiquette = i.etiquette;
    }
    if (pile == null && etiquette == null) return const SizedBox.shrink();
    final String quoi = <String>[
      if (pile != null) libellePile(pile),
      if (etiquette != null) libelleEtiquette(etiquette),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: TexteSansCoupure(
        t.admin.praxis.travail.marque(quoi: quoi),
        key: cle(reference),
        style: AppPalette.of(context).inkMuted.applyTo(
          Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Le lien « Le travail de Praxis » de la file, ou rien.
class LienTravailPraxis extends ConsumerWidget {
  /// Cree le lien.
  const LienTravailPraxis({super.key});

  /// La cle du lien, pour les tests.
  static const Key cle = ValueKey<String>('candidatures-travail-praxis');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PageRangements? lus = ref.watch(rangementsPraxisProvider).value;
    if (lus == null) return const SizedBox.shrink();
    final tr = t.admin.praxis.travail;
    final String detail = tr.lienDetail(n: '${lus.total}');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LienFleche(
            key: cle,
            libelle: tr.lien,
            alignerEnDebut: true,
            libelleSemantique: '${tr.lien}, $detail',
            onPress: () => unawaited(
              context.push<void>(Routes.adminPersonnesTravailPraxis),
            ),
          ),
          ExcludeSemantics(
            child: TexteSansCoupure(
              detail,
              style: AppPalette.of(context).inkMuted.applyTo(
                Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
