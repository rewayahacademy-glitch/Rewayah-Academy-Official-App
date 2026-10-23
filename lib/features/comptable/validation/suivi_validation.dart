// Le suivi d'une demande de validation, cote Comptable (CPT-VAL-1, decision
// Q-8 = (a) du 05/10 ; CPT-BR-09). Apres « Demander validation », l'objet
// (paiement, obligation ponctuelle) dit ou en est sa demande, telle que la
// source la rend : « Validation demandee », puis « Validee » (par qui, quand)
// ou « Refusee » avec son motif. Rien n'est deduit par l'ecran.
//
// Sans demande pour cet objet, ou quand la source n'est pas branchee
// (`CapaciteIndisponible`, la page porte deja son propre etat honnete), le
// suivi ne pose rien. Une lecture echouee le dit, avec « Reessayer ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderOrFamily;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_validations_finance.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/status_pill.dart';

/// Les demandes de validation d'un objet, rendues par la source (la plus
/// recente d'abord).
final FutureProviderFamily<List<DemandeValidation>, String>
demandesValidationObjetProvider =
    FutureProvider.family<List<DemandeValidation>, String>(
      (Ref ref, String objetId) => ref
          .watch(portValidationsFinanceProvider)
          .demandes(FiltreDemandesValidation(objetId: objetId)),
      retry: (int _, Object _) => null,
      dependencies: <ProviderOrFamily>[portValidationsFinanceProvider],
    );

/// Le suivi de la derniere demande de validation de [objetId].
class SuiviValidation extends ConsumerWidget {
  /// Cree le suivi.
  const SuiviValidation({
    required this.objetId,
    super.key,
    this.marge = const EdgeInsetsDirectional.only(top: AppSpacing.lg),
  });

  /// L'objet (obligation payable, obligation de contractuel, mouvement).
  final String objetId;

  /// L'espace pose autour du bandeau, seulement quand il s'affiche.
  final EdgeInsetsDirectional marge;

  Widget _marge(Widget enfant) => Padding(padding: marge, child: enfant);

  /// La cle du bandeau de suivi.
  static const Key cle = ValueKey<String>('suivi-validation');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = t.comptable.validation;
    final AsyncValue<List<DemandeValidation>> valeur = ref.watch(
      demandesValidationObjetProvider(objetId),
    );
    final Object? erreur = valeur.hasError ? valeur.error : null;
    if (erreur != null) {
      if (erreur is CapaciteIndisponible) return const SizedBox.shrink();
      return _marge(
        BandeauAttention(
          key: cle,
          titre: t.comptable.paiements.actions.demanderValidation,
          message: v.erreurSuivi,
          ton: TonEtat.alerte,
          action: LienFleche(
            libelle: v.reessayer,
            legende: true,
            onPress: () =>
                ref.invalidate(demandesValidationObjetProvider(objetId)),
          ),
        ),
      );
    }
    final List<DemandeValidation>? demandes = valeur.value;
    if (demandes == null || demandes.isEmpty) return const SizedBox.shrink();
    final DemandeValidation d = demandes.first;
    final String decideur = d.decideur ?? '';
    final String quand = dateComptable(d.dateDecision ?? d.date);
    return _marge(
      BandeauAttention(
        key: cle,
        titre: libelleDemandeValidation(d.etat),
        message: switch (d.etat) {
          EtatDemandeValidation.enAttente => v.suiviEnAttente(
            date: dateComptable(d.date),
          ),
          EtatDemandeValidation.validee => v.suiviValidee(
            decideur: decideur,
            date: quand,
          ),
          EtatDemandeValidation.refusee => v.suiviRefusee(
            decideur: decideur,
            date: quand,
            motif: d.motifDecision ?? '',
          ),
        },
        ton: tonDemandeValidation(d.etat),
      ),
    );
  }
}
