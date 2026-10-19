// Mes donnees : la copie des donnees de la personne et la demande de
// suppression de son compte (CPT-SUPPR-EXPORT, migration 20261018150000).
//
// Le serveur decide de tout : ce que la copie contient (la personne et, pour
// un tuteur, son foyer, jamais un secret ni une note interne), le delai de
// reflexion (`app_config`), ce qui reste du (solde, seances a venir). Flutter
// affiche et enregistre le fichier ; il ne calcule rien.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Une demande de suppression de compte, en cours.
@immutable
class DemandeSuppression {
  /// Cree la demande.
  const DemandeSuppression({
    required this.id,
    required this.delaiJours,
    required this.demandeeLe,
    required this.echeanceLe,
  });

  /// L'identifiant de la demande.
  final String id;

  /// Le delai de reflexion applique a cette demande, en jours.
  final int delaiJours;

  /// Le moment de la demande.
  final DateTime demandeeLe;

  /// Le moment a partir duquel la direction peut traiter la demande.
  final DateTime echeanceLe;

  @override
  bool operator ==(Object other) =>
      other is DemandeSuppression &&
      other.id == id &&
      other.delaiJours == delaiJours &&
      other.demandeeLe == demandeeLe &&
      other.echeanceLe == echeanceLe;

  @override
  int get hashCode => Object.hash(id, delaiJours, demandeeLe, echeanceLe);
}

/// Ce que l'ecran dit de la suppression : la demande en cours s'il y en a une,
/// le delai de reflexion en vigueur, et ce qui reste (solde, seances).
@immutable
class SituationSuppression {
  /// Cree la situation.
  const SituationSuppression({
    required this.delaiJours,
    required this.montantsDus,
    required this.seancesAVenir,
    this.demande,
  });

  /// La demande en cours, ou `null`.
  final DemandeSuppression? demande;

  /// Le delai de reflexion en vigueur (celui d'une prochaine demande), en jours.
  final int delaiJours;

  /// Les montants restant a regler, par devise (aucun : rien n'est du).
  final List<Montant> montantsDus;

  /// Le nombre de seances encore prevues pour la personne ou son foyer.
  final int seancesAVenir;

  /// Vrai quand un solde reste a regler.
  bool get soldeDu => montantsDus.isNotEmpty;
}

/// La copie des donnees, prete a enregistrer.
@immutable
class CopieDonnees {
  /// Cree la copie.
  const CopieDonnees({required this.octets, required this.nomFichier});

  /// Le JSON, en UTF-8.
  final List<int> octets;

  /// Le nom de fichier propose.
  final String nomFichier;
}

/// Mes donnees (contrat CPT-SUPPR-EXPORT).
abstract interface class PortMesDonnees {
  /// La copie des donnees de la personne (et de son foyer pour un tuteur).
  Future<CopieDonnees> exporter();

  /// La demande en cours et la situation. Lecture seule.
  Future<SituationSuppression> situation();

  /// Demande la suppression du compte ; [motif] est facultatif (500 signes au
  /// plus). Une demande deja en cours est rendue telle quelle.
  Future<void> demander({String? motif});

  /// Annule la demande en cours.
  Future<void> annuler();
}

/// Tant qu'aucun adaptateur serveur n'est branche (demonstration, tests) :
/// rien n'est affiche, aucun lien mort.
class MesDonneesIndisponibles implements PortMesDonnees {
  /// Cree l'implementation.
  const MesDonneesIndisponibles();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'CPT-SUPPR-EXPORT',
  );

  @override
  Future<CopieDonnees> exporter() => Future<CopieDonnees>.error(_absente);

  @override
  Future<SituationSuppression> situation() =>
      Future<SituationSuppression>.error(_absente);

  @override
  Future<void> demander({String? motif}) => Future<void>.error(_absente);

  @override
  Future<void> annuler() => Future<void>.error(_absente);
}

/// Le port de mes donnees.
final Provider<PortMesDonnees> portMesDonneesProvider =
    Provider<PortMesDonnees>((Ref ref) => const MesDonneesIndisponibles());
