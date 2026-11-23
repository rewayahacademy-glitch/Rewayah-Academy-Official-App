// La dette de la famille, dite en tete du Foyer (PAIEMENT-FAMILLE-ACCES, D7,
// 23/11/2026 ; regle du directeur : l'interface dit quoi, quand et pourquoi).
//
// Tout vient de `ma_dette_famille()` (`detteFamilleProvider`) : le montant, le
// motif et la date sont ceux du serveur, rien n'est calcule ici. Etats :
// chargement (squelette), contenu (le bandeau), vide (rien du tout), erreur
// et hors ligne (avec « Reessayer »). Sans source (`CapaciteIndisponible`) ou
// pour un compte qui n'a pas ce droit (`PermissionInsuffisante`, le second
// adulte), rien : ce n'est ni un echec ni une dette.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_dette_famille.dart';
import '../../core/finance/dette_famille.dart';
import '../../core/finance/format_montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import 'ligne_membre.dart' show dateEcheance;

/// Le motif d'une dette, en mots simples (jamais le code du serveur).
String libelleMotifDette(MotifDetteFamille motif) => switch (motif) {
  MotifDetteFamille.fraisContestationPerdue =>
    t.foyer.dette.motifs.fraisContestation,
  MotifDetteFamille.autre => t.foyer.dette.motifs.autre,
};

/// Le texte du bandeau : une phrase par dette (montant, motif, date), puis ce
/// que cela bloque, ce qui reste intact, et quoi faire.
String messageDetteFamille(DetteFamille dette) {
  final String lignes = dette.lignes
      .map(
        (LigneDetteFamille l) => t.foyer.dette.ligne(
          montant: formaterMontant(l.montant),
          motif: libelleMotifDette(l.motif),
          date: dateEcheance(l.creeLe),
        ),
      )
      .join(' ');
  return '$lignes ${t.foyer.dette.blocage}';
}

/// La carte de la dette de la famille, en tete du Foyer.
class CarteDetteFamille extends ConsumerWidget {
  /// Cree la carte.
  const CarteDetteFamille({super.key});

  /// Le bandeau de la dette.
  static const Key cle = Key('foyer.dette.bandeau');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DetteFamille> lecture = ref.watch(detteFamilleProvider);
    final Object? erreur = lecture.hasError ? lecture.error : null;
    if (erreur is CapaciteIndisponible || erreur is PermissionInsuffisante) {
      return const SizedBox.shrink();
    }
    final Widget corps;
    if (erreur != null) {
      void relire() => ref.invalidate(detteFamilleProvider);
      corps = (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSansDonnees(quoi: t.foyer.dette.sansDonnees, onAction: relire)
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: t.foyer.dette.indisponibleTitre,
              onAction: relire,
            );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 1);
    } else {
      final DetteFamille dette = lecture.requireValue;
      if (!dette.ouverte) return const SizedBox.shrink();
      corps = BandeauAttention(
        key: cle,
        titre: t.foyer.dette.titre(montant: formaterMontant(dette.total!)),
        message: messageDetteFamille(dette),
      );
    }
    // Sur ordinateur, la carte garde une largeur de lecture : jamais un
    // bandeau de telephone etire sur toute la page.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppGabarit.seuilEtendu),
          child: corps,
        ),
      ),
    );
  }
}
