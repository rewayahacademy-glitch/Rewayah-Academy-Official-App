// VISION-RECRUTEMENT (directeur, 14/11/2026) : « qui attend quoi de qui ».
//
// Une seule lecture serveur, `attentes_recrutement()` (migration
// 20261126500000), des nombres seulement, dans la portee du lecteur (son
// genre, ou les deux pour le super-admin). L'ecran ne recalcule rien : il
// range les etats rendus en trois attentes (l'academie, la personne, un moyen
// de versement) et lit les dates rendues.
//
// Sans port, ou tant que la migration n'est pas installee, la lecture rend
// `CapaciteIndisponible` et la carte ne s'affiche pas : jamais un zero qui ne
// serait pas lu.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'modeles_candidature.dart';

/// L'identifiant de la dependance serveur (migration 20261126500000), pour la
/// trace et les tests : jamais affiche.
const String dependanceAttentesRecrutement = 'VISION-RECRUTEMENT';

/// Un nombre et la plus ancienne derniere activite de ce qu'il compte.
@immutable
class Attente {
  /// Cree une attente.
  const Attente({required this.nombre, this.plusAncien});

  /// Aucune personne.
  static const Attente aucune = Attente(nombre: 0);

  /// Lit `{"nombre": n, "plusAncien": "…"}` ; tout autre forme vaut [aucune].
  factory Attente.depuisJson(Object? brut) {
    if (brut is! Map) return aucune;
    final Object? n = brut['nombre'];
    final Object? d = brut['plusAncien'];
    return Attente(
      nombre: n is int && n >= 0 ? n : 0,
      plusAncien: d is String ? DateTime.tryParse(d) : null,
    );
  }

  /// Le nombre de personnes.
  final int nombre;

  /// La plus ancienne derniere activite, ou `null`.
  final DateTime? plusAncien;

  @override
  bool operator ==(Object other) =>
      other is Attente &&
      other.nombre == nombre &&
      other.plusAncien == plusAncien;

  @override
  int get hashCode => Object.hash(nombre, plusAncien);
}

/// Ce que le serveur rend.
@immutable
class AttentesRecrutement {
  /// Cree les attentes.
  const AttentesRecrutement({
    this.parEtat = const <EtatCandidature, Attente>{},
    this.pieceAValider = Attente.aucune,
    this.enPause = 0,
    this.creneauxOuverts = 0,
    this.entretiensSansIssue = 0,
    this.deuxCotes = false,
  });

  /// Lit la reponse de `attentes_recrutement()`.
  factory AttentesRecrutement.depuisJson(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('Attentes attendues.');
    }
    final Object? etats = brut['etats'];
    int entier(String cle) {
      final Object? v = brut[cle];
      return v is int && v >= 0 ? v : 0;
    }

    return AttentesRecrutement(
      parEtat: <EtatCandidature, Attente>{
        if (etats is Map)
          for (final MapEntry<Object?, Object?> e in etats.entries)
            if (EtatCandidature.depuisSql(e.key) case final EtatCandidature k)
              k: Attente.depuisJson(e.value),
      },
      pieceAValider: Attente.depuisJson(brut['pieceAValider']),
      enPause: entier('enPause'),
      creneauxOuverts: entier('creneauxOuverts'),
      entretiensSansIssue: entier('entretiensSansIssue'),
      deuxCotes: brut['deuxCotes'] == true,
    );
  }

  /// Les candidatures en cours, hors pause, par etat.
  final Map<EtatCandidature, Attente> parEtat;

  /// Les pieces d'identite deposees qui attendent une decision.
  final Attente pieceAValider;

  /// Les candidatures en pause.
  final int enPause;

  /// Les creneaux d'entretien ouverts a venir, libres.
  final int creneauxOuverts;

  /// Les entretiens planifies sans issue consignee.
  final int entretiensSansIssue;

  /// Vrai : le lecteur compte les deux cotes (super-admin).
  final bool deuxCotes;

  /// L'attente d'un etat.
  Attente etat(EtatCandidature e) => parEtat[e] ?? Attente.aucune;
}

/// Le port de lecture.
// ignore: one_member_abstracts
abstract interface class PortAttentesRecrutement {
  /// Les attentes, dans la portee du lecteur. `CapaciteIndisponible` tant que
  /// le serveur ne sert pas la lecture.
  Future<AttentesRecrutement> lire();
}

/// Le port : absent avant le branchement serveur.
final Provider<PortAttentesRecrutement?> portAttentesRecrutementProvider =
    Provider<PortAttentesRecrutement?>((Ref _) => null);

/// Les attentes. Sans port : [CapaciteIndisponible]. Relues a chaque
/// ouverture de la page et apres un geste (invalidation).
final FutureProvider<AttentesRecrutement> attentesRecrutementProvider =
    FutureProvider.autoDispose<AttentesRecrutement>((Ref ref) {
      final PortAttentesRecrutement? port = ref.watch(
        portAttentesRecrutementProvider,
      );
      if (port == null) {
        return Future<AttentesRecrutement>.error(
          const CapaciteIndisponible(dependanceAttentesRecrutement),
        );
      }
      return port.lire();
    }, retry: (int _, Object _) => null);
