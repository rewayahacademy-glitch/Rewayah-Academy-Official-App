// L'onglet « A valider » de la Finance de la direction (decision Q-8 = (a)
// du directeur, 05/10 ; CPT-VAL-1 ; CPT-BR-09). Il recoit les demandes du
// Comptable : paiement sensible (coordonnees changees recemment, beneficiaire
// lie a l'operateur, premier paiement), retrait de la Reserve strategique ou
// sortie d'un coffre protege, obligation ponctuelle, sa propre paie.
//
// Rendu DANS le `PageShell` de `FinancePage`, jamais une seconde page. Lit
// `PortValidationsFinance` : en production le port rend
// `CapaciteIndisponible('CPT-BR-09')` et l'onglet dit « Pas encore
// disponible », sans demande ni bouton (K-59, BR-1). La demonstration
// (`/demo/finance?ecran=aValider`) le surcharge par le registre unique
// partage avec `/demo/comptable`.
//
// Cinq etats : chargement (squelette), contenu (« A decider » puis
// « Decidees recemment »), vide (« Rien a valider »), erreur (« Reessayer »)
// et hors ligne. Aucun widget ne lit un role : chaque demande porte ce que
// la personne connectee peut en faire (`approuver`, ou bloquee
// `autoPaiement` quand c'est sa propre demande). Les montants de la liste
// sont masquables ; le montant exact se lit dans la decision.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/capacites/port_validations_finance.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/section_header.dart';
import '../reserve_delegation/composants_politique.dart' show BlocPolitique;
import 'decision_validation.dart';

/// Toutes les demandes visibles par la personne connectee, rendues par la
/// source (les en attente d'abord, l'ordre de la source ensuite).
final FutureProvider<List<DemandeValidation>> demandesValidationProvider =
    FutureProvider<List<DemandeValidation>>(
      (Ref ref) => ref
          .watch(portValidationsFinanceProvider)
          .demandes(FiltreDemandesValidation.tout),
      // Pas de retentative silencieuse derriere « Reessayer ».
      retry: (int _, Object _) => null,
      dependencies: <ProviderOrFamily>[portValidationsFinanceProvider],
    );

/// Le libelle d'une nature de demande.
String libelleNatureValidation(NatureDemandeValidation nature) {
  final n = t.comptable.validation.natures;
  return switch (nature) {
    NatureDemandeValidation.payoutSensible => n.payoutSensible,
    NatureDemandeValidation.retraitReserve => n.retraitReserve,
    NatureDemandeValidation.obligationAApprouver => n.obligationAApprouver,
    NatureDemandeValidation.payoutDuComptable => n.payoutDuComptable,
    NatureDemandeValidation.sortieCoffreProtege => n.sortieCoffreProtege,
  };
}

/// Vrai quand la source dit que la personne connectee a fait cette demande
/// (capacite rendue, jamais un nom compare).
bool estSaPropreDemande(DemandeValidation d) =>
    d.permissions.raisonDe(ActionFinance.approuver) ==
    RaisonBlocage.autoPaiement;

/// Le corps de l'onglet « A valider ».
class AValiderBloc extends ConsumerWidget {
  /// Cree le corps.
  const AValiderBloc({super.key});

  /// La cle de l'etat vide.
  static const Key cleVide = ValueKey<String>('a-valider-vide');

  /// La cle de la carte d'une demande.
  static Key cleDemande(String id) => ValueKey<String>('a-valider-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.comptable.validation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          v.sousTitre,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: BasculeMontants(avecEtat: true),
        ),
        Ecart.vXl,
        BlocPolitique<List<DemandeValidation>>(
          fournisseur: demandesValidationProvider,
          construire: (List<DemandeValidation> demandes) =>
              _Liste(demandes: demandes),
        ),
      ],
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste({required this.demandes});

  final List<DemandeValidation> demandes;

  Future<void> _ouvrir(
    BuildContext context,
    WidgetRef ref,
    DemandeValidation d,
  ) async {
    final bool change = await ouvrirDecisionValidation(context, d);
    if (change) ref.invalidate(demandesValidationProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = t.comptable.validation;
    final List<DemandeValidation> enAttente = <DemandeValidation>[
      for (final DemandeValidation d in demandes)
        if (d.etat == EtatDemandeValidation.enAttente) d,
    ];
    final List<DemandeValidation> decidees = <DemandeValidation>[
      for (final DemandeValidation d in demandes)
        if (d.etat != EtatDemandeValidation.enAttente) d,
    ];
    Widget cartes(List<DemandeValidation> liste) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < liste.length; i++) ...<Widget>[
          if (i > 0) Ecart.vMd,
          CarteDemandeValidation(
            key: AValiderBloc.cleDemande(liste[i].id),
            demande: liste[i],
            onOuvrir: () => _ouvrir(context, ref, liste[i]),
          ),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: v.aDecider, compteur: enAttente.length),
        if (enAttente.isEmpty)
          EmptyState(
            key: AValiderBloc.cleVide,
            message: v.videTitre,
            invitation: v.videPhrase,
            registre: RegistreVide.subi,
          )
        else
          cartes(enAttente),
        if (decidees.isNotEmpty) ...<Widget>[
          Ecart.vSection,
          SectionHeader(titre: v.decidees, compteur: decidees.length),
          cartes(decidees),
        ],
      ],
    );
  }
}

/// La carte d'une demande dans la liste : nature, objet, demandeur et date,
/// montant (masquable), etat ; la raison et la decision dans la feuille.
class CarteDemandeValidation extends StatelessWidget {
  /// Cree la carte.
  const CarteDemandeValidation({
    required this.demande,
    required this.onOuvrir,
    super.key,
  });

  /// La demande.
  final DemandeValidation demande;

  /// Ouvre la decision.
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.comptable.validation;
    final DemandeValidation d = demande;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String? decideur = d.decideur;
    final DateTime? quand = d.dateDecision;
    final String? decision = decideur == null || quand == null
        ? null
        : d.etat == EtatDemandeValidation.validee
        ? v.valideePar(decideur: decideur, date: dateComptable(quand))
        : v.refuseePar(decideur: decideur, date: dateComptable(quand));
    final String? motif = d.motifDecision;
    return AppCard(
      onPress: onOuvrir,
      libelleSemantique: v.ouvrir(objet: d.objet),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                libelleNatureValidation(d.nature),
                style: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
              PastilleDemandeValidation(d.etat),
            ],
          ),
          Ecart.vXs,
          Text(
            d.objet,
            style: palette.inkStrong.applyTo(
              textes.bodyLarge ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            v.demandePar(demandeur: d.demandeur, date: dateComptable(d.date)),
            style: attenue,
          ),
          if (decision != null) ...<Widget>[
            Ecart.vXs,
            Text(decision, style: attenue),
          ],
          if (motif != null) ...<Widget>[
            Ecart.vXs,
            Text(v.motif(motif: motif), style: attenue),
          ],
          if (d.etat == EtatDemandeValidation.enAttente &&
              estSaPropreDemande(d)) ...<Widget>[
            Ecart.vXs,
            Text(v.votreDemandeTitre, style: attenue),
          ],
          Ecart.vSm,
          MontantSensible(d.montant),
        ],
      ),
    );
  }
}
