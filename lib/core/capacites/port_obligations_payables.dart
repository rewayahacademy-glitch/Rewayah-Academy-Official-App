// Les obligations payables (`TeacherPayableObligation` etendu aux
// contractuels, spec §13, §14, §15, §30, §31 ; CPT-BR-01). Pose par CPT-F
// avec son interface complete ; **propriete de la voie CPT-PAY ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Le montant est **calcule a la source** : jamais un champ de saisie
// (R-FIN-16). Un recalcul = une nouvelle version (R-FIN-18). « Signaler un
// ecart » cree un signalement lie a une ligne, sans montant saisi
// (R-FIN-17). Consolidation par beneficiaire (§14.4) ; la Classe reste un
// filtre (§14.5).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Une obligation payable, consolidee par beneficiaire.
@immutable
class ObligationPayable {
  /// Cree l'obligation.
  const ObligationPayable({
    required this.id,
    required this.version,
    required this.periode,
    required this.beneficiaire,
    required this.montant,
    required this.etat,
    required this.echeance,
    this.lignes = const <LigneCalcul>[],
    this.destination,
    this.preuve,
    this.prestatairePrevu,
    this.permissions = PermissionsFinance.lectureSeule,
    this.classes = const <String>[],
  });

  /// L'identifiant.
  final String id;

  /// La version du calcul : un payout se soumet pour (id, version), et une
  /// version changee est refusee « recalculee » (DR-13).
  final String version;

  /// La periode lisible (« Octobre 2026 »).
  final String periode;

  /// Le beneficiaire.
  final IdentiteBeneficiaire beneficiaire;

  /// Les lignes de calcul, chacune avec sa source (§13.3).
  final List<LigneCalcul> lignes;

  /// Le montant final, dans sa devise. Jamais modifie ici (§13.2).
  final Montant montant;

  /// L'etat (§15).
  final EtatPaiementSortant etat;

  /// L'echeance.
  final DateTime echeance;

  /// La methode de payout prevue, masquee par la source.
  final DestinationMasquee? destination;

  /// La preuve ou la source du calcul, lisible.
  final String? preuve;

  /// Le prestataire prevu pour le payout, rendu (nom neutre).
  final String? prestatairePrevu;

  /// Ce que la source permet (`payer`, `demanderValidation`,
  /// `signalerEcart`...) et pourquoi le reste est bloque.
  final PermissionsFinance permissions;

  /// Les Classes concernees (filtre et detail analytique seulement).
  final List<String> classes;
}

/// Le filtre de la liste W02, lu depuis l'adresse par la page.
@immutable
class FiltreObligations {
  /// Cree le filtre.
  const FiltreObligations({this.filtre, this.type, this.classe});

  /// Aucun filtre.
  static const FiltreObligations tout = FiltreObligations();

  /// Le filtre d'etat (`?filtre=`).
  final FiltrePaiements? filtre;

  /// Le type de beneficiaire (`?type=`).
  final TypeBeneficiaire? type;

  /// La Classe (`?classe=`).
  final String? classe;

  /// Vrai quand aucun filtre n'est pose.
  bool get estVide => filtre == null && type == null && classe == null;

  // L'egalite par valeur : le filtre sert de cle a la lecture de la liste
  // (`obligationsPayablesProvider`), deux filtres egaux lisent une fois.
  @override
  bool operator ==(Object other) =>
      other is FiltreObligations &&
      other.filtre == filtre &&
      other.type == type &&
      other.classe == classe;

  @override
  int get hashCode => Object.hash(filtre, type, classe);
}

/// Un signalement d'ecart depose (§13.4).
@immutable
class SignalementEcart {
  /// Cree le signalement.
  const SignalementEcart({
    required this.id,
    required this.obligationId,
    required this.ligneId,
    required this.date,
  });

  /// L'identifiant du signalement.
  final String id;

  /// L'obligation.
  final String obligationId;

  /// La ligne de calcul visee.
  final String ligneId;

  /// La date de depot rendue par la source.
  final DateTime date;
}

/// Les obligations payables (CPT-BR-01).
abstract interface class PortObligationsPayables {
  /// La liste, filtree.
  Future<List<ObligationPayable>> liste(FiltreObligations filtre);

  /// Le detail d'une obligation (W03).
  Future<ObligationPayable> detail(String obligationId);

  /// « Signaler un ecart » sur une ligne, avec un motif choisi et **aucun
  /// montant** (R-FIN-17). [cleIdempotence] est generee par l'app une fois
  /// par signalement et rejouee telle quelle : un double appui ou une
  /// reponse perdue ne cree qu'un signalement (`CPT-BR.md` §1).
  Future<SignalementEcart> signalerEcart({
    required String obligationId,
    required String ligneId,
    required String motif,
    required String cleIdempotence,
  });

  /// Le journal d'une obligation (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String obligationId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-01).
class ObligationsPayablesIndisponibles implements PortObligationsPayables {
  /// Cree l'implementation.
  const ObligationsPayablesIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-01');

  @override
  Future<List<ObligationPayable>> liste(FiltreObligations filtre) =>
      Future<List<ObligationPayable>>.error(_manque);

  @override
  Future<ObligationPayable> detail(String obligationId) =>
      Future<ObligationPayable>.error(_manque);

  @override
  Future<SignalementEcart> signalerEcart({
    required String obligationId,
    required String ligneId,
    required String motif,
    required String cleIdempotence,
  }) => Future<SignalementEcart>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal(String obligationId) =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`paiements_demo.dart`).
final Provider<PortObligationsPayables> portObligationsPayablesProvider =
    Provider<PortObligationsPayables>(
      (Ref _) => const ObligationsPayablesIndisponibles(),
    );
