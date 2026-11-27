// La dette de la famille (PAIEMENT-FAMILLE-ACCES, D7, 23/11/2026) : les frais
// d'une contestation bancaire perdue vont a la famille, jamais au solde d'un
// enfant. Lue par `ma_dette_famille()` ; l'application ne calcule rien.

import 'package:flutter/foundation.dart';

import 'montant.dart';

/// Pourquoi une dette existe.
enum MotifDetteFamille {
  /// Les frais d'une contestation bancaire perdue.
  fraisContestationPerdue('frais_contestation_perdue'),

  /// Un motif que cette version ne connait pas : dit sans code technique.
  autre('');

  const MotifDetteFamille(this.valeurSql);

  /// La valeur du serveur.
  final String valeurSql;

  /// Lit un motif ; une valeur inconnue vaut [autre], jamais un echec.
  static MotifDetteFamille depuisSql(String? valeur) => values.firstWhere(
    (MotifDetteFamille m) => m.valeurSql.isNotEmpty && m.valeurSql == valeur,
    orElse: () => autre,
  );
}

/// Une dette ouverte.
@immutable
class LigneDetteFamille {
  /// Cree la ligne.
  const LigneDetteFamille({
    required this.montant,
    required this.motif,
    required this.creeLe,
  });

  /// Le montant du serveur.
  final Montant montant;

  /// Le motif.
  final MotifDetteFamille motif;

  /// Le jour ou la dette est nee.
  final DateTime creeLe;
}

/// Les dettes ouvertes du foyer.
@immutable
class DetteFamille {
  /// Cree la dette.
  const DetteFamille({required this.lignes, this.total});

  /// Aucune dette.
  static const DetteFamille aucune = DetteFamille(
    lignes: <LigneDetteFamille>[],
  );

  /// Les dettes ouvertes, la plus ancienne d'abord.
  final List<LigneDetteFamille> lignes;

  /// Le total du serveur, `null` sans dette.
  final Montant? total;

  /// Vrai quand au moins une dette reste a regler.
  bool get ouverte => lignes.isNotEmpty && total != null;

  /// Lit la reponse de `ma_dette_famille()` ; [FormatException] sur une forme
  /// inattendue (jamais une valeur completee).
  static DetteFamille depuisJson(Object? brut) {
    if (brut is! Map) throw const FormatException('dette: objet attendu');
    final Object? lignesBrutes = brut['lignes'];
    if (lignesBrutes is! List) throw const FormatException('dette: lignes');
    final List<LigneDetteFamille> lignes = <LigneDetteFamille>[];
    for (final Object? l in lignesBrutes) {
      if (l is! Map) throw const FormatException('dette: ligne');
      final Object? mineur = l['montant_mineur'];
      final Object? devise = l['devise'];
      final Object? cree = l['cree_le'];
      if (mineur is! int || devise is! String || cree is! String) {
        throw const FormatException('dette: ligne incomplete');
      }
      final DateTime? date = DateTime.tryParse(cree);
      if (date == null) throw const FormatException('dette: date');
      lignes.add(
        LigneDetteFamille(
          montant: Montant(mineur, devise),
          motif: MotifDetteFamille.depuisSql(l['motif'] as String?),
          creeLe: date,
        ),
      );
    }
    if (lignes.isEmpty) return aucune;
    final Object? total = brut['total_mineur'];
    if (total is! int) throw const FormatException('dette: total');
    return DetteFamille(
      lignes: List<LigneDetteFamille>.unmodifiable(lignes),
      total: Montant(total, lignes.first.montant.devise),
    );
  }
}
