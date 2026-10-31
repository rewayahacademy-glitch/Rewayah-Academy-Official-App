/// Les remplacements vus par la direction (finir REMPL-1, 31/10/2026).
///
/// **Ce que le serveur porte, et que Flutter ne decide jamais** (migration
/// `20261102400000_remplacements_direction.sql`) :
/// - qui peut remplacer une seance : les enseignants libres a l'instant exact
///   de la seance (R12, regle stricte), chacun avec `genreCompatible` ;
/// - la designation (`designer_remplacant_admin`) : un enseignant de l'autre
///   genre n'est accepte que sur choix explicite ([horsGenre]), trace en base ;
/// - l'agregat d'une periode, par titulaire et par classe, et l'etat de chaque
///   seance concernee. Aucun seuil : la decision reste a la direction.
///
/// Sans port ([portRemplacementsDirectionProvider] vaut `null`), rien n'est
/// rendu : aucune action, aucun chiffre invente.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// L'etat d'une seance qui a un evenement de remplacement.
enum EtatRemplacementSeance {
  /// Le titulaire a declare son absence ; personne ne l'a encore remplace.
  absenceDeclaree,

  /// Un collegue l'a prise, ou la direction a designe un remplacant.
  remplacee,
}

/// Une seance concernee par un remplacement.
@immutable
class RemplacementSeanceDirection {
  /// Cree la ligne.
  const RemplacementSeanceDirection({
    required this.seanceId,
    required this.etat,
    this.remplacant,
    this.horsGenre = false,
  });

  /// La seance.
  final String seanceId;

  /// Son etat.
  final EtatRemplacementSeance etat;

  /// Le nom du remplacant, quand la seance est remplacee.
  final String? remplacant;

  /// Vrai quand la direction a choisi un enseignant hors du genre de la
  /// classe (R12, choix trace).
  final bool horsGenre;
}

/// Les remplacements d'un titulaire dans une classe, sur la periode.
@immutable
class RemplacementsTitulaire {
  /// Cree la ligne.
  const RemplacementsTitulaire({
    required this.titulaireId,
    required this.titulaire,
    required this.groupeId,
    required this.classe,
    required this.seances,
    required this.remplacees,
    required this.sansRemplacant,
    this.numeroDansFamille,
  });

  /// Le titulaire.
  final String titulaireId;

  /// Son nom.
  final String titulaire;

  /// La classe.
  final String groupeId;

  /// Le nom de la classe.
  final String classe;

  /// R16 : le numero de la classe parmi ses classes paralleles.
  final int? numeroDansFamille;

  /// Les seances ou le titulaire a ete absent ou remplace.
  final int seances;

  /// Celles qui ont un remplacant.
  final int remplacees;

  /// Celles qui n'en ont pas (encore).
  final int sansRemplacant;
}

/// Le bilan d'une periode.
@immutable
class BilanRemplacements {
  /// Cree le bilan.
  const BilanRemplacements({required this.parTitulaire, required this.seances});

  /// Par titulaire et par classe, le plus de seances d'abord.
  final List<RemplacementsTitulaire> parTitulaire;

  /// L'etat de chaque seance concernee, par identifiant de seance.
  final Map<String, RemplacementSeanceDirection> seances;
}

/// Un enseignant libre a l'heure exacte d'une seance.
@immutable
class RemplacantPossible {
  /// Cree la ligne.
  const RemplacantPossible({
    required this.id,
    required this.nom,
    required this.identifiant,
    required this.genreCompatible,
  });

  /// L'enseignant.
  final String id;

  /// Son nom.
  final String nom;

  /// Son identifiant immuable, qui departage deux homonymes.
  final String identifiant;

  /// Vrai quand son genre convient a la classe ; faux, il ne peut etre
  /// designe que par un choix explicite de la direction (R12).
  final bool genreCompatible;
}

/// La reponse du serveur a une designation.
enum ResultatDesignation {
  /// Le remplacant est designe.
  designe,

  /// Il n'est plus libre a l'heure de la seance.
  occupe,

  /// Il ne peut pas remplacer cette seance (compte, genre sans choix
  /// explicite).
  incompatible,

  /// La seance a deja un remplacant.
  dejaPris,

  /// La seance n'est plus a venir.
  seanceIndisponible,
}

/// La reponse du serveur a une reaffectation de Classe
/// (`reaffecter_enseignant_classe`, migration 20261103100000).
enum ResultatReaffectation {
  /// La Classe et ses seances a venir sont confiees au nouvel enseignant.
  reaffecte,

  /// Cet enseignant assure deja la Classe : rien n'a change.
  dejaEnPlace,

  /// Il n'est pas libre aux horaires de la Classe.
  occupe,

  /// Il ne peut pas la reprendre (compte, langue, genre du public, plafond).
  incompatible,

  /// La Classe n'est plus active ou n'a plus d'enseignant.
  classeIndisponible,
}

/// Le port des remplacements de la direction.
abstract interface class PortRemplacementsDirection {
  /// Le bilan des seances qui commencent entre [debut] et [fin].
  Future<BilanRemplacements> periode(DateTime debut, DateTime fin);

  /// Les enseignants libres a l'heure exacte de la seance.
  Future<List<RemplacantPossible>> possibles(String seanceId);

  /// Designe [remplacantId] pour la seance ; [horsGenre] est le choix
  /// explicite d'un enseignant de l'autre genre.
  Future<ResultatDesignation> designer({
    required String seanceId,
    required String remplacantId,
    required bool horsGenre,
  });

  /// Les enseignants qui peuvent reprendre la Classe [groupeId] (le serveur
  /// applique les regles de l'affectation, unicite a l'heure comprise).
  Future<List<RemplacantPossible>> possiblesReaffectation(String groupeId);

  /// Retire la Classe a son enseignant et la confie a [enseignantId], pour
  /// les seances a venir.
  Future<ResultatReaffectation> reaffecter({
    required String groupeId,
    required String enseignantId,
  });
}

/// Le port : absent tant que `main.dart` ne le pose pas.
final Provider<PortRemplacementsDirection?> portRemplacementsDirectionProvider =
    Provider<PortRemplacementsDirection?>((Ref _) => null);

/// Le bilan de la semaine qui commence le lundi donne ; `null` sans port.
final FutureProviderFamily<BilanRemplacements?, DateTime>
remplacementsSemaineProvider =
    FutureProvider.family<BilanRemplacements?, DateTime>((
      Ref ref,
      DateTime lundi,
    ) {
      final PortRemplacementsDirection? port = ref.watch(
        portRemplacementsDirectionProvider,
      );
      if (port == null) return Future<BilanRemplacements?>.value();
      return port.periode(
        lundi,
        DateTime(lundi.year, lundi.month, lundi.day + 7),
      );
    }, retry: (int _, Object _) => null);

/// Les remplacants possibles d'une seance.
final FutureProviderFamily<List<RemplacantPossible>, String>
remplacantsPossiblesProvider =
    FutureProvider.family<List<RemplacantPossible>, String>((
      Ref ref,
      String seanceId,
    ) {
      final PortRemplacementsDirection? port = ref.watch(
        portRemplacementsDirectionProvider,
      );
      if (port == null) {
        return Future<List<RemplacantPossible>>.value(
          const <RemplacantPossible>[],
        );
      }
      return port.possibles(seanceId);
    }, retry: (int _, Object _) => null);

/// Les enseignants qui peuvent reprendre une Classe.
final FutureProviderFamily<List<RemplacantPossible>, String>
enseignantsReaffectationProvider =
    FutureProvider.family<List<RemplacantPossible>, String>((
      Ref ref,
      String groupeId,
    ) {
      final PortRemplacementsDirection? port = ref.watch(
        portRemplacementsDirectionProvider,
      );
      if (port == null) {
        return Future<List<RemplacantPossible>>.value(
          const <RemplacantPossible>[],
        );
      }
      return port.possiblesReaffectation(groupeId);
    }, retry: (int _, Object _) => null);
