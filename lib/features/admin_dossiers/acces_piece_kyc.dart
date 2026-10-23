/// BACK-FRONT-KYC-DIR-1 : ce que l'ecran de revue dit des droits d'ouverture
/// des pieces (`port_acces_pieces_kyc.dart`).
///
/// - [BandeauExceptionKyc] : en tete de la revue, tant que l'exception super
///   admin est active pour la personne connectee ;
/// - [LigneAccesPiece] : a la place du bouton « Voir la piece » quand
///   l'ouverture est refusee (une phrase par raison, jamais de bouton grise)
///   ou en attente de verification ; avec une legende quand l'ouverture est
///   permise par l'exception (elle sera tracee).
///
/// Aucune donnee KYC ici : ni nom de piece, ni lien, ni genre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dossier/port_acces_pieces_kyc.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/bandeau_attention.dart';

/// Le bandeau « Exception super admin active » ; silencieux sans port, hors
/// exception, en chargement et en echec (le verdict par dossier parle alors).
class BandeauExceptionKyc extends ConsumerWidget {
  /// Cree le bandeau.
  const BandeauExceptionKyc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(exceptionKycActiveProvider).value != true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BandeauAttention(
        key: const ValueKey<String>('bandeau-exception-kyc'),
        titre: t.dossiers.accesKyc.exceptionTitre,
        message: t.dossiers.accesKyc.exceptionMessage,
      ),
    );
  }
}

/// Le texte d'un refus.
String libelleRefusPiece(RefusPieceKyc raison) => switch (raison) {
  RefusPieceKyc.genreDifferent => t.dossiers.accesKyc.refus.genreDifferent,
  RefusPieceKyc.adminSansGenre => t.dossiers.accesKyc.refus.adminSansGenre,
  RefusPieceKyc.profilNonAutorise =>
    t.dossiers.accesKyc.refus.profilNonAutorise,
};
