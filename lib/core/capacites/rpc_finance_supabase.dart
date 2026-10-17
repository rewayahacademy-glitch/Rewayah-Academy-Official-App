// Appel et decodage stricts des RPC de lecture finance (BF1, migrations
// 20261017160000 et 20261017160100).
//
// **Aucun calcul** : chaque montant arrive en unites mineures + ISO 4217,
// deja arrete par le serveur. Le decodage refuse une forme inattendue
// (`FormatException`) plutot que de completer une valeur manquante.
//
// Erreurs : une fonction absente du serveur (PGRST202, migration pas encore
// appliquee) se dit [CapaciteIndisponible] ; un refus (42501), une autre
// erreur serveur ou une coupure reseau remontent tels quels, pour que l'ecran
// dise l'erreur ou le hors ligne, jamais une liste vide.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/finances_profil.dart';
import '../finance/montant.dart';
import '../finance/mouvements_profil.dart';
import 'capacite_indisponible.dart';

/// Un appel RPC : le nom de la fonction et ses parametres. Injecte pour les
/// tests ; en production, `client.rpc`.
typedef AppelRpc = Future<Object?> Function(
  String fonction,
  Map<String, dynamic>? params,
);

/// L'appel RPC servi par le client Supabase de l'application.
AppelRpc appelRpcSupabase(SupabaseClient client) =>
    (String fonction, Map<String, dynamic>? params) =>
        client.rpc<Object?>(fonction, params: params);

/// Appelle [fonction] ; une RPC absente du serveur devient
/// [CapaciteIndisponible] ([dependance]).
Future<Object?> appelerFinance(
  AppelRpc appel,
  String fonction,
  String dependance, [
  Map<String, dynamic>? params,
]) async {
  try {
    return await appel(fonction, params);
  } on PostgrestException catch (e) {
    if (e.code == 'PGRST202') throw CapaciteIndisponible(dependance);
    rethrow;
  }
}

/// Un objet JSON, ou [FormatException].
Map<String, dynamic> objetJson(Object? v, String cle) {
  if (v is Map) return Map<String, dynamic>.from(v);
  throw FormatException('objet JSON invalide: $cle');
}

/// Une liste JSON, ou [FormatException].
List<Object?> listeJson(Object? v, String cle) {
  if (v is List) return List<Object?>.from(v);
  throw FormatException('liste JSON invalide: $cle');
}

/// Un texte non vide.
String texteJson(Map<String, dynamic> j, String cle) {
  final Object? v = j[cle];
  if (v is String && v.isNotEmpty) return v;
  throw FormatException('texte absent ou invalide: $cle');
}

/// Un texte nullable.
String? texteNullableJson(Map<String, dynamic> j, String cle) {
  final Object? v = j[cle];
  if (v == null || v is String) return v as String?;
  throw FormatException('texte invalide: $cle');
}

/// Un entier.
int entierJson(Map<String, dynamic> j, String cle) {
  final Object? v = j[cle];
  if (v is int) return v;
  throw FormatException('entier absent ou invalide: $cle');
}

/// Un booleen.
bool booleenJson(Map<String, dynamic> j, String cle) {
  final Object? v = j[cle];
  if (v is bool) return v;
  throw FormatException('booleen absent ou invalide: $cle');
}

/// Un montant `{mineur, devise}`.
Montant montantJson(Object? v, String cle) {
  final Map<String, dynamic> m = objetJson(v, cle);
  final Object? mineur = m['mineur'];
  final Object? devise = m['devise'];
  if (mineur is int &&
      devise is String &&
      RegExp(r'^[A-Z]{3}$').hasMatch(devise)) {
    return Montant(mineur, devise);
  }
  throw FormatException('montant invalide: $cle');
}

/// Un montant nullable.
Montant? montantNullableJson(Object? v, String cle) =>
    v == null ? null : montantJson(v, cle);

/// Une date civile `AAAA-MM-JJ`, a minuit local.
DateTime dateJson(Object? v, String cle) {
  if (v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
    final DateTime d = DateTime.parse(v);
    if (d.toIso8601String().substring(0, 10) == v) return d;
  }
  throw FormatException('date invalide: $cle');
}

/// Un horodatage serveur, rendu en heure locale.
DateTime instantJson(Object? v, String cle) {
  if (v is String) {
    final DateTime? d = DateTime.tryParse(v);
    if (d != null) return d.toLocal();
  }
  throw FormatException('horodatage invalide: $cle');
}

/// L'etat financier rendu par le serveur.
EtatFinancier etatFinancierJson(Object? v) => switch (v) {
  'finance' => EtatFinancier.finance,
  'essai' => EtatFinancier.essai,
  'manque' => EtatFinancier.manque,
  'en_confirmation' => EtatFinancier.enConfirmation,
  'expire' => EtatFinancier.expire,
  'pause' => EtatFinancier.pause,
  'a_regulariser' => EtatFinancier.aRegulariser,
  _ => throw FormatException('etat financier inconnu: $v'),
};

/// La finance d'un profil (`private.bf1_finance_profil`).
FinancesProfil financesProfilJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'finance');
  final Object? age = j['age'];
  final Object? essais = j['essaisUtilises'];
  if ((age != null && age is! int) || (essais != null && essais is! int)) {
    throw const FormatException('age ou essais invalides');
  }
  final Object? periode = j['periode'];
  final Object? debit = j['prochainDebit'];
  final Object? fin = j['finConservation'];
  return FinancesProfil(
    profilId: texteJson(j, 'profilId'),
    prenom: texteJson(j, 'prenom'),
    cleAccent: texteJson(j, 'cleAccent'),
    estAdulte: booleenJson(j, 'estAdulte'),
    cleAvatar: texteNullableJson(j, 'cleAvatar'),
    classe: texteNullableJson(j, 'classe'),
    age: age as int?,
    etat: etatFinancierJson(j['etat']),
    solde: montantJson(j['solde'], 'solde'),
    periode: periode == null
        ? null
        : PeriodeFinancee(
            debut: dateJson(objetJson(periode, 'periode')['debut'], 'debut'),
            fin: dateJson(objetJson(periode, 'periode')['fin'], 'fin'),
          ),
    prochainDebit: debit == null
        ? null
        : ProchainDebit(
            date: dateJson(objetJson(debit, 'prochainDebit')['date'], 'date'),
            montant: montantJson(
              objetJson(debit, 'prochainDebit')['montant'],
              'montant',
            ),
          ),
    mensualite: montantJson(j['mensualite'], 'mensualite'),
    lignesMensualite: List<LigneMensualite>.unmodifiable(<LigneMensualite>[
      for (final Object? l in listeJson(j['lignesMensualite'], 'lignes'))
        _ligneMensualite(objetJson(l, 'ligne')),
    ]),
    essaisUtilises: essais as int?,
    manque: montantNullableJson(j['manque'], 'manque'),
    finConservation: fin == null ? null : dateJson(fin, 'finConservation'),
  );
}

LigneMensualite _ligneMensualite(Map<String, dynamic> l) {
  final Object? rang = l['rang'];
  if (rang != null && rang is! int) throw const FormatException('rang');
  return LigneMensualite(
    nature: switch (l['nature']) {
      'tarif' => NatureLigneMensualite.tarif,
      'remise_rang' => NatureLigneMensualite.remiseRang,
      'prorata' => NatureLigneMensualite.prorata,
      'avoir' => NatureLigneMensualite.avoir,
      'taxe' => NatureLigneMensualite.taxe,
      final Object? n => throw FormatException('ligne inconnue: $n'),
    },
    montant: montantJson(l['montant'], 'montant'),
    rang: rang as int?,
  );
}

/// La nature d'un mouvement rendu par le serveur.
///
/// Le serveur distingue aussi `debit` (debit de seance), `correction`
/// (ajustement negatif) et `remboursement` : [NatureMouvement] n'a pas encore
/// de valeur pour eux (le libelle vit dans les ecrans), ils se rangent donc
/// sous [NatureMouvement.debitPeriode], leur montant restant signe tel que
/// rendu. A affiner quand l'ecran saura les nommer.
NatureMouvement natureMouvementJson(Object? v) => switch (v) {
  'recharge' => NatureMouvement.recharge,
  'avoir' => NatureMouvement.avoir,
  'remise' => NatureMouvement.remise,
  'taxe' => NatureMouvement.taxe,
  'debit_periode' ||
  'debit' ||
  'correction' ||
  'remboursement' => NatureMouvement.debitPeriode,
  _ => throw FormatException('nature de mouvement inconnue: $v'),
};

/// Un mouvement (`private.bf1_mouvement_json`).
MouvementProfil mouvementProfilJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'mouvement');
  final Object? periode = j['periode'];
  return MouvementProfil(
    id: texteJson(j, 'id'),
    date: instantJson(j['date'], 'date'),
    nature: natureMouvementJson(j['nature']),
    montant: montantJson(j['montant'], 'montant'),
    statut: switch (j['statut']) {
      'enregistre' => StatutMouvement.enregistre,
      'en_confirmation' => StatutMouvement.enConfirmation,
      final Object? s => throw FormatException('statut inconnu: $s'),
    },
    periode: periode == null ? null : dateJson(periode, 'periode'),
  );
}

/// Une liste de mouvements, dans l'ordre rendu.
List<MouvementProfil> mouvementsJson(Object? brut) =>
    List<MouvementProfil>.unmodifiable(<MouvementProfil>[
      for (final Object? m in listeJson(brut, 'mouvements'))
        mouvementProfilJson(m),
    ]);
