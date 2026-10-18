// Adaptateur FAC-F-01 : l'acces des eleves, lu par `mon_acces` (la personne
// connectee) et `acces_du_foyer` (un tuteur du foyer), migration
// 20261018170000.
//
// **Ce que chaque lecteur recoit** : l'enfant ne recoit qu'une ouverture
// (`seancesPayantesOuvertes: false`), jamais une cause ni un montant ; le
// tuteur et l'eleve adulte recoivent en plus `place: suspendu_paiement`. Le
// serveur en decide, l'ecran ne deduit rien d'une date ni d'un solde.
//
// Erreurs : une fonction absente du serveur (PGRST202, migration pas encore
// appliquee) se dit [CapaciteIndisponible] ; un refus, une autre erreur ou une
// coupure reseau remontent tels quels, jamais une liste vide.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_acces_foyer.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'FI-BR-08';

/// L'acces des eleves du foyer servi par Supabase (`acces_du_foyer`).
class AccesFoyerSupabase implements PortAccesFoyer {
  /// Cree l'adaptateur sur le client de l'application.
  AccesFoyerSupabase(SupabaseClient client, {DateTime Function()? maintenant})
    : _appel = appelRpcSupabase(client),
      _maintenant = maintenant ?? DateTime.now;

  /// Cree l'adaptateur sur un appel injecte (tests).
  AccesFoyerSupabase.avecAppel(this._appel, {DateTime Function()? maintenant})
    : _maintenant = maintenant ?? DateTime.now;

  final AppelRpc _appel;
  final DateTime Function() _maintenant;

  @override
  Future<List<AccesBeneficiaire>> acces() async {
    final Object? brut = await appelerFinance(
      _appel,
      'acces_du_foyer',
      _dependance,
    );
    return <AccesBeneficiaire>[
      for (final Object? ligne in listeJson(brut, 'acces'))
        accesBeneficiaireJson(ligne, maintenantUtc: _maintenant().toUtc()),
    ];
  }
}

/// L'acces de la personne connectee servi par Supabase (`mon_acces`).
class MonAccesSupabase implements PortMonAcces {
  /// Cree l'adaptateur sur le client de l'application.
  MonAccesSupabase(SupabaseClient client, {DateTime Function()? maintenant})
    : _appel = appelRpcSupabase(client),
      _maintenant = maintenant ?? DateTime.now;

  /// Cree l'adaptateur sur un appel injecte (tests).
  MonAccesSupabase.avecAppel(this._appel, {DateTime Function()? maintenant})
    : _maintenant = maintenant ?? DateTime.now;

  final AppelRpc _appel;
  final DateTime Function() _maintenant;

  /// `null` quand la personne connectee n'a pas de profil eleve.
  @override
  Future<AccesBeneficiaire?> monAcces() async {
    final Object? brut = await appelerFinance(_appel, 'mon_acces', _dependance);
    return brut == null
        ? null
        : accesBeneficiaireJson(brut, maintenantUtc: _maintenant().toUtc());
  }
}

/// Un acces rendu par le serveur ; [FormatException] sur une forme inattendue.
AccesBeneficiaire accesBeneficiaireJson(
  Object? brut, {
  required DateTime maintenantUtc,
}) {
  final Map<String, dynamic> j = objetJson(brut, 'acces');
  final Object? fin = j['finAcces'];
  final DateTime? finAcces = fin == null ? null : instantJson(fin, 'finAcces');
  final Object? ouvert = j['seancesPayantesOuvertes'];
  final Object? gere = j['gereSonAcces'];
  if ((ouvert != null && ouvert is! bool) || (gere != null && gere is! bool)) {
    throw const FormatException('acces: booleen invalide');
  }
  final Object? jourPlace = j['datePlace'];
  return AccesBeneficiaire(
    eleveId: texteJson(j, 'eleveId'),
    prenom: texteJson(j, 'prenom'),
    finAcces: finAcces,
    etatAffiche: etatAccesAffiche(
      finAcces: finAcces,
      maintenantUtc: maintenantUtc,
    ),
    seancesPayantesOuvertes: ouvert as bool?,
    place: _placeJson(j['place']),
    datePlace: jourPlace == null ? null : dateJson(jourPlace, 'datePlace'),
    gereSonAcces: gere as bool?,
  );
}

EtatPlace? _placeJson(Object? v) => switch (v) {
  null => null,
  'suspendu_paiement' => EtatPlace.suspenduPaiement,
  'liberee' => EtatPlace.liberee,
  'reactivee' => EtatPlace.reactivee,
  _ => throw FormatException('place inconnue: $v'),
};
