// `PayableObligationRow` (spec §30, §39 ; CPT-PAY-1) : une obligation payable
// dans la liste W02, en ligne de tableau au bureau (colonnes de §30, dans
// l'ordre de la planche H04) et en carte sur telephone et tablette (§45 :
// « tables transformees en listes »).
//
// Le montant est un `MontantSensible` en lecture seule, jamais un champ
// (R-FIN-16) ; la destination est rendue masquee par la source ; l'action
// vient des permissions de l'obligation (DR-19), jamais d'un role.

import 'package:flutter/material.dart';

import '../../../core/capacites/port_obligations_payables.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/data_collection.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import 'paiements_donnees.dart';

/// Les gestes d'une ligne, poses par la page.
@immutable
class GestesObligation {
  /// Cree les gestes.
  const GestesObligation({
    required this.selection,
    required this.ouvrir,
    required this.basculer,
    required this.relancer,
    this.payer,
    this.demanderValidation,
    this.horsLigne = false,
  });

  /// Les identifiants retenus.
  final Set<String> selection;

  /// Ouvre le detail W03.
  final void Function(ObligationPayable o) ouvrir;

  /// Retient ou relache la ligne.
  final void Function(ObligationPayable o, bool retenue) basculer;

  /// Ouvre le profil de paiement du beneficiaire (W07), ou vit la relance.
  final void Function(ObligationPayable o) relancer;

  /// Ouvre la confirmation d'un paiement (CPT-PAY-2), ou `null` tant
  /// qu'elle n'est pas posee.
  final void Function(ObligationPayable o)? payer;

  /// Ouvre la confirmation d'un paiement sensible (« Demander validation »).
  final void Function(ObligationPayable o)? demanderValidation;

  /// Vrai hors ligne : aucun paiement ne part, le bouton cede la place a
  /// une phrase.
  final bool horsLigne;
}

/// La destination en une ligne courte, masquee par la source.
String destinationCourte(DestinationMasquee? d) => d == null
    ? t.comptable.commun.destinationAucune
    : t.comptable.commun.destinationMasquee(type: d.type, suffixe: d.suffixe);

/// La ligne secondaire : « Enseignant · Octobre 2026 ».
String typeEtPeriode(ObligationPayable o) =>
    '${libelleTypeBeneficiaire(o.beneficiaire.type)} · ${o.periode}';

/// Les colonnes du tableau W02 (spec §30), dans l'ordre : selection,
/// beneficiaire, type, periode / objet, montant, destination, echeance,
/// statut, action.
List<ColonneDonnees<ObligationPayable>> colonnesObligations(
  GestesObligation gestes,
) {
  final c = t.comptable.paiements.colonnes;
  return <ColonneDonnees<ObligationPayable>>[
    ColonneDonnees<ObligationPayable>(
      titre: '',
      texte: (ObligationPayable o) => '',
      rendu: (BuildContext _, ObligationPayable o) =>
          CaseObligation(obligation: o, gestes: gestes),
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.beneficiaire,
      texte: (ObligationPayable o) => o.beneficiaire.nom,
      role: RoleColonne.identifiante,
      flex: 4,
      rendu: (BuildContext context, ObligationPayable o) =>
          _Cellule(c.beneficiaire, o.beneficiaire.nom, fort: true),
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.type,
      texte: (ObligationPayable o) =>
          libelleTypeBeneficiaire(o.beneficiaire.type),
      flex: 2,
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.periode,
      texte: (ObligationPayable o) => o.periode,
      flex: 3,
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.montant,
      texte: (ObligationPayable o) => t.comptable.commun.montantMasque,
      flex: 3,
      tabulaire: true,
      rendu: (BuildContext _, ObligationPayable o) =>
          MontantSensible(o.montant),
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.destination,
      texte: (ObligationPayable o) => destinationCourte(o.destination),
      flex: 3,
      rendu: (BuildContext _, ObligationPayable o) =>
          _Cellule(c.destination, destinationCourte(o.destination)),
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.echeance,
      texte: (ObligationPayable o) => dateComptable(o.echeance),
      flex: 3,
      tabulaire: true,
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.statut,
      texte: (ObligationPayable o) => libellePaiementSortant(o.etat),
      flex: 4,
      rendu: (BuildContext _, ObligationPayable o) =>
          PastillePaiementSortant(o.etat),
    ),
    ColonneDonnees<ObligationPayable>(
      titre: c.action,
      texte: (ObligationPayable o) => '',
      flex: 4,
      rendu: (BuildContext _, ObligationPayable o) =>
          ActionObligation(obligation: o, gestes: gestes),
    ),
  ];
}

/// Une cellule de texte, lue avec le titre de sa colonne.
class _Cellule extends StatelessWidget {
  const _Cellule(this.colonne, this.valeur, {this.fort = false});

  final String colonne;
  final String valeur;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return Semantics(
      label: '$colonne : $valeur',
      excludeSemantics: true,
      child: Text(
        valeur,
        style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(base),
      ),
    );
  }
}

/// La case de selection, seulement si la ligne peut entrer dans un lot.
class CaseObligation extends StatelessWidget {
  /// Cree la case.
  const CaseObligation({
    required this.obligation,
    required this.gestes,
    super.key,
  });

  /// L'obligation.
  final ObligationPayable obligation;

  /// Les gestes de la page.
  final GestesObligation gestes;

  /// La cle de la case d'une obligation, pour les tests.
  static Key cleDe(String obligationId) =>
      ValueKey<String>('case-obligation-$obligationId');

  @override
  Widget build(BuildContext context) {
    if (!estSelectionnable(obligation)) {
      return const SizedBox.shrink();
    }
    final bool retenue = gestes.selection.contains(obligation.id);
    return Semantics(
      label: t.comptable.paiements.actions.selectionner(
        nom: obligation.beneficiaire.nom,
      ),
      excludeSemantics: true,
      checked: retenue,
      child: Checkbox(
        key: cleDe(obligation.id),
        value: retenue,
        onChanged: (bool? valeur) =>
            gestes.basculer(obligation, valeur ?? false),
      ),
    );
  }
}

/// L'action d'une ligne : un bouton quand la source permet d'agir, la
/// raison rendue quand elle ne le permet pas (« Traitement par un autre
/// responsable requis », R-FIN-15), « Voir » sinon. Jamais un bouton grise.
class ActionObligation extends StatelessWidget {
  /// Cree l'action.
  const ActionObligation({
    required this.obligation,
    required this.gestes,
    super.key,
  });

  /// L'obligation.
  final ObligationPayable obligation;

  /// Les gestes de la page.
  final GestesObligation gestes;

  /// La cle du bouton d'une obligation, pour les tests.
  static Key cleDe(String obligationId) =>
      ValueKey<String>('action-obligation-$obligationId');

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.paiements.actions;
    final ObligationPayable o = obligation;
    final RaisonBlocage? raison = raisonSansPaiement(o);
    Widget voir() => LienFleche(
      key: cleDe(o.id),
      libelle: a.voir,
      legende: true,
      onPress: () => gestes.ouvrir(o),
    );
    Widget phrase(String texte) => Text(
      texte,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle()),
    );
    switch (actionDe(o)) {
      case ActionLigne.payer:
        final void Function(ObligationPayable)? payer = gestes.payer;
        if (payer == null) return voir();
        if (gestes.horsLigne) {
          return phrase(t.comptable.paiements.horsLigneCourt);
        }
        return ActionPrincipale(
          key: cleDe(o.id),
          libelle: a.payer,
          niveau: NiveauAction.secondaire,
          compacte: true,
          onPress: () => payer(o),
        );
      case ActionLigne.demanderValidation:
        final void Function(ObligationPayable)? demander =
            gestes.demanderValidation;
        if (demander == null || gestes.horsLigne) {
          return phrase(libelleRaisonBlocage(RaisonBlocage.validationRequise));
        }
        return ActionPrincipale(
          key: cleDe(o.id),
          libelle: a.demanderValidation,
          niveau: NiveauAction.secondaire,
          compacte: true,
          onPress: () => demander(o),
        );
      case ActionLigne.relancer:
        return LienFleche(
          key: cleDe(o.id),
          libelle: a.relancer,
          legende: true,
          onPress: () => gestes.relancer(o),
        );
      case ActionLigne.voir:
        if (raison == RaisonBlocage.autoPaiement) {
          return phrase(libelleRaisonBlocage(raison!));
        }
        // DELEG-FIN-1 : une operation en attente ou bloquee par une
        // delegation dit pourquoi, avec la raison rendue par la source.
        if (raison != null && raisonsDelegation.contains(raison)) {
          return Column(
            key: ValueKey<String>('raison-obligation-${o.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[phrase(libelleRaisonBlocage(raison)), voir()],
          );
        }
        return voir();
    }
  }
}

/// La carte d'une obligation, sur telephone et tablette : la case, le nom,
/// « type · periode », la destination, puis le montant et le statut, puis
/// l'action. Tout se replie a 320 de large et a texte double.
class CarteObligation extends StatelessWidget {
  /// Cree la carte.
  const CarteObligation({
    required this.obligation,
    required this.gestes,
    super.key,
  });

  /// L'obligation.
  final ObligationPayable obligation;

  /// Les gestes de la page.
  final GestesObligation gestes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ObligationPayable o = obligation;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    return AppCard(
      onPress: () => gestes.ouvrir(o),
      libelleSemantique: o.beneficiaire.nom,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (estSelectionnable(o)) ...<Widget>[
            CaseObligation(obligation: o, gestes: gestes),
            Ecart.hXs,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  o.beneficiaire.nom,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
                Ecart.vXs,
                Text(typeEtPeriode(o), style: attenue),
                Ecart.vXs,
                Text(destinationCourte(o.destination), style: attenue),
                Ecart.vSm,
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    MontantSensible(o.montant),
                    PastillePaiementSortant(o.etat),
                  ],
                ),
                Ecart.vSm,
                Text(
                  '${t.comptable.paiements.colonnes.echeance} : '
                  '${dateComptable(o.echeance)}',
                  style: attenue,
                ),
                Ecart.vSm,
                ActionObligation(obligation: o, gestes: gestes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le filtre complet de la page, tel qu'il part a la source.
FiltreObligations filtreDe({
  FiltrePaiements? filtre,
  TypeBeneficiaire? type,
  String? classe,
}) => FiltreObligations(filtre: filtre, type: type, classe: classe);
