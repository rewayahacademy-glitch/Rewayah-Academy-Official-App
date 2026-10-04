// La demonstration des beneficiaires, de la relance et de « Recevoir mes
// paiements » (CPT-BR-06, 11, 16). Posee vide par CPT-F ; **propriete de la
// voie CPT-BEN ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §44
// a tenir par CPT-BEN : 2 infos manquantes, 1 methode modifiee recemment,
// 1 externe « Invitation envoyee ». La relance reste « preparee », jamais
// « envoyee » (CPT-BR-11) ; aucune coordonnee reelle (numeros fictifs non
// conformes).

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_beneficiaires_paiement.dart';
import '../../../core/capacites/port_mes_moyens_paiement.dart';
import '../../../core/capacites/port_relance_paiement.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';

/// Les beneficiaires en demonstration : vides tant que CPT-BEN-1 ne les a
/// pas remplis.
class BeneficiairesPaiementDemo implements PortBeneficiairesPaiement {
  /// Cree le double.
  const BeneficiairesPaiementDemo();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-06');

  @override
  Future<List<ProfilPaiementBeneficiaire>> liste(
    FiltreBeneficiaires filtre,
  ) async => const <ProfilPaiementBeneficiaire>[];

  @override
  Future<ProfilPaiementBeneficiaire> profil(String beneficiaireId) =>
      Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> demanderMiseAJour(String beneficiaireId) =>
      Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> suspendre({
    required String beneficiaireId,
    required String motif,
  }) => Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> reprendre(String beneficiaireId) =>
      Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> marquerVerificationRequise(
    String beneficiaireId,
  ) => Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal(String beneficiaireId) async =>
      const <EntreeJournal>[];
}

/// La relance en demonstration : « Relance preparee (demonstration) », avec
/// le message modele §27.3, jamais envoyee.
class RelancePaiementDemo implements PortRelancePaiement {
  /// Cree le double.
  const RelancePaiementDemo();

  @override
  Future<RelancePreparee> relancer(String beneficiaireId) async =>
      RelancePreparee(
        filId: 'fil-$typeObjetProfilPaiement-$beneficiaireId',
        beneficiaireId: beneficiaireId,
        messageModele: t.comptable.commun.relancePreparee,
      );
}

/// Mes moyens de paiement en demonstration : aucun moyen tant que CPT-BEN-2
/// n'a pas pose ses etats.
class MesMoyensPaiementDemo implements PortMesMoyensPaiement {
  /// Cree le double.
  const MesMoyensPaiementDemo();

  static const EtatMesMoyensPaiement _aucun = EtatMesMoyensPaiement(
    etat: EtatProfilPaiement.aucunMoyen,
  );

  @override
  Future<EtatMesMoyensPaiement> etat() async => _aucun;

  @override
  Future<EtatMesMoyensPaiement> ajouter(
    BrouillonMoyenPaiement brouillon,
  ) async => _aucun;

  @override
  Future<EtatMesMoyensPaiement> remplacer({
    required String moyenId,
    required BrouillonMoyenPaiement brouillon,
  }) async => _aucun;

  @override
  Future<EtatMesMoyensPaiement> supprimer(String moyenId) async => _aucun;

  @override
  Future<EtatMesMoyensPaiement> choisirPreferee(String moyenId) async => _aucun;

  @override
  Future<List<EntreeJournal>> journal() async => const <EntreeJournal>[];
}

/// Les surcharges de la demonstration des beneficiaires.
List<Override> surchargesDemoBeneficiaires() => <Override>[
  portBeneficiairesPaiementProvider.overrideWithValue(
    const BeneficiairesPaiementDemo(),
  ),
  portRelancePaiementProvider.overrideWithValue(const RelancePaiementDemo()),
  portMesMoyensPaiementProvider.overrideWithValue(
    const MesMoyensPaiementDemo(),
  ),
];
