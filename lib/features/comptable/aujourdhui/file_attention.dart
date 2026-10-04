// La file d'attention d'Aujourd'hui (`FinanceAttentionQueue` et
// `FinanceAlertRow`, spec §39 ; CPT-JOUR) : des habits de `SignalRow`,
// jamais une recopie (`UX_REVIEW_FINANCE_COMPTABLE_L0.md` §4).
//
// « A traiter » et « Alertes » sont deux listes disjointes (DR-10) : la
// source dit a laquelle appartient chaque element, l'ecran ne le deduit pas.
// Chaque ligne ouvre l'ecran canonique deja filtre par la route rendue
// (spec §5.1) ; aucune ligne ne paie (DR-11).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/port_aujourdhui_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/signal_row.dart';
import '../../../core/widgets/status_pill.dart';

/// Le libelle d'un type d'alerte (§28), tel que la spec le nomme.
String libelleTypeAlerte(TypeAlerteComptable type) {
  final a = t.comptable.alertes;
  return switch (type) {
    TypeAlerteComptable.enseignantsAPayer => a.enseignantsAPayer,
    TypeAlerteComptable.contractuelsAEcheance => a.contractuelsAEcheance,
    TypeAlerteComptable.infosManquantes => a.infosManquantes,
    TypeAlerteComptable.payoutEchoue => a.payoutEchoue,
    TypeAlerteComptable.paiementFamilleEchoue => a.paiementFamilleEchoue,
    TypeAlerteComptable.transactionNonRapprochee => a.transactionNonRapprochee,
    TypeAlerteComptable.remboursementEnAttente => a.remboursementEnAttente,
    TypeAlerteComptable.reserveSousObjectif => a.reserveSousObjectif,
    TypeAlerteComptable.soldePrestataireInsuffisant =>
      a.soldePrestataireInsuffisant,
    TypeAlerteComptable.methodeModifieeRecemment => a.methodeModifieeRecemment,
    TypeAlerteComptable.doublonPotentiel => a.doublonPotentiel,
    TypeAlerteComptable.validationRequise => a.validationRequise,
  };
}

/// L'icone d'un type d'alerte : celles que CPT-F a posees pour la vague.
AppIcon iconeTypeAlerte(TypeAlerteComptable type) => switch (type) {
  TypeAlerteComptable.enseignantsAPayer => AppIcons.paiements,
  TypeAlerteComptable.contractuelsAEcheance => AppIcons.contractuel,
  TypeAlerteComptable.infosManquantes => AppIcons.beneficiaire,
  TypeAlerteComptable.payoutEchoue => AppIcons.sortieArgent,
  TypeAlerteComptable.paiementFamilleEchoue => AppIcons.entreeArgent,
  TypeAlerteComptable.transactionNonRapprochee => AppIcons.rapprochement,
  TypeAlerteComptable.remboursementEnAttente => AppIcons.encaissement,
  TypeAlerteComptable.reserveSousObjectif => AppIcons.reserve,
  TypeAlerteComptable.soldePrestataireInsuffisant => AppIcons.coffre,
  TypeAlerteComptable.methodeModifieeRecemment => AppIcons.verrou,
  TypeAlerteComptable.doublonPotentiel => AppIcons.avertissement,
  TypeAlerteComptable.validationRequise => AppIcons.attente,
};

/// La famille de ton d'un type d'alerte : un echec est une alerte, ce qui
/// bloque un paiement un avertissement, le reste neutre. Le mot et l'icone
/// disent la meme chose (jamais la couleur seule).
TonEtat tonTypeAlerte(TypeAlerteComptable type) => switch (type) {
  TypeAlerteComptable.payoutEchoue ||
  TypeAlerteComptable.paiementFamilleEchoue ||
  TypeAlerteComptable.doublonPotentiel => TonEtat.alerte,
  TypeAlerteComptable.infosManquantes ||
  TypeAlerteComptable.validationRequise ||
  TypeAlerteComptable.reserveSousObjectif ||
  TypeAlerteComptable.soldePrestataireInsuffisant ||
  TypeAlerteComptable.methodeModifieeRecemment => TonEtat.avertissement,
  TypeAlerteComptable.enseignantsAPayer ||
  TypeAlerteComptable.contractuelsAEcheance ||
  TypeAlerteComptable.transactionNonRapprochee ||
  TypeAlerteComptable.remboursementEnAttente => TonEtat.neutre,
};

/// Une ligne de la file (`FinanceAlertRow`) : « Enseignants a payer : 12 »,
/// depuis quand, et le chevron vers l'ecran canonique.
class LigneAttention extends StatelessWidget {
  /// Cree la ligne.
  const LigneAttention(this.element, {super.key});

  /// L'element rendu par la source.
  final ElementAttention element;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    final DateTime? depuis = element.depuis;
    return SignalRow(
      key: ValueKey<String>('attention-${element.id}'),
      phrase: a.elementCompteur(
        libelle: libelleTypeAlerte(element.type),
        n: element.compteur,
      ),
      icone: iconeTypeAlerte(element.type),
      ton: tonTypeAlerte(element.type),
      anciennete: depuis == null
          ? null
          : a.elementDepuis(date: dateComptable(depuis)),
      onPress: () => context.go(element.route),
    );
  }
}

/// Une liste de la file (`FinanceAttentionQueue`) : les lignes, espacees,
/// ou son vide en registre « bonne nouvelle » (rien a traiter n'est pas une
/// panne).
class FileAttention extends StatelessWidget {
  /// Cree la liste.
  const FileAttention({
    required this.elements,
    required this.vide,
    super.key,
    this.videDetail,
    this.limite,
  });

  /// Les elements, dans l'ordre de la source.
  final List<ElementAttention> elements;

  /// Le constat quand la liste est vide.
  final String vide;

  /// La precision du vide, quand il y en a une.
  final String? videDetail;

  /// Le nombre maximal de lignes rendues (telephone) ; nul : toutes.
  final int? limite;

  @override
  Widget build(BuildContext context) {
    if (elements.isEmpty) {
      return EmptyState(
        message: vide,
        invitation: videDetail,
        registre: RegistreVide.bonneNouvelle,
      );
    }
    final int? max = limite;
    final List<ElementAttention> rendus = max == null || elements.length <= max
        ? elements
        : elements.sublist(0, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < rendus.length; i++) ...<Widget>[
          if (i > 0) Ecart.vLg,
          LigneAttention(rendus[i]),
        ],
      ],
    );
  }
}
