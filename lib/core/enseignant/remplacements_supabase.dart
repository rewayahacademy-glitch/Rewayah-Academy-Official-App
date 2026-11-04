// Les adaptateurs Supabase de l'absence sur une seance et de la reponse a une
// offre de remplacement (B-09), sur les RPC `declarer_absence_seance` et
// `prendre_remplacement` (migration 20261011185954).
//
// Le serveur decide de tout : le titulaire, la compatibilite du remplacant
// (genre, KYC, compte actif), la prise atomique. L'etat rendu est celui de
// sa reponse, jamais calcule ici (E6, E7).
//
// Le tableau commun des offres (`PortRemplacements.suivre`) se lit par la RPC
// `offres_remplacement` (migration 20261016100800), deja filtree par genre
// et par compatibilite cote serveur ; il se relit tant que l'ecran ecoute (la
// table des remplacements n'est publiee a aucun client).

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'absence_remplacement.dart';
import 'port_remplacements.dart';

const String _espaceCles = '6f1d2c84-93a7-5b0e-8c41-2e7a9d5b3f60';

/// La cle d'idempotence d'une action sur une seance : la meme seance et la
/// meme action donnent toujours la meme cle, d'un essai a l'autre.
String cleRemplacement(String action, String seanceId) =>
    const Uuid().v5(_espaceCles, '$action:$seanceId');

/// L'etat d'absence lu dans la reponse du serveur ; `null` s'il est inconnu.
EtatAbsence? etatAbsenceServeur(Object? reponse) {
  if (reponse is! Map) return null;
  return switch (reponse['etat']) {
    'absence_declaree' => EtatAbsence.enregistree,
    'remplacement_pris' ||
    'remplacement_designe_admin' => EtatAbsence.remplacantConfirme,
    _ => null,
  };
}

/// La declaration d'absence servie par Supabase.
class DeclarationAbsenceSupabase implements DeclarationAbsence {
  /// Cree l'adaptateur sur le client de l'application.
  const DeclarationAbsenceSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtatAbsence?> declarer(String seanceId) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'declarer_absence_seance',
        params: <String, dynamic>{
          'p_session_id': seanceId,
          'p_cle_idempotence': cleRemplacement('absence', seanceId),
        },
      );
      return etatAbsenceServeur(reponse);
    } on PostgrestException {
      // Refus (pas le titulaire, seance passee, absence deja declaree) : la
      // demande n'a pas abouti, l'ecran ne suppose aucun etat.
      return null;
    }
  }
}

/// La reponse a une offre de remplacement servie par Supabase.
class ReponseRemplacementSupabase implements ReponseRemplacement {
  /// Cree l'adaptateur sur le client de l'application.
  const ReponseRemplacementSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> assurer(OffreRemplacement offre) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'prendre_remplacement',
        params: <String, dynamic>{
          'p_session_id': offre.seanceId,
          'p_cle_idempotence': cleRemplacement('prise', offre.seanceId),
        },
      );
      // Seul `acceptee` confirme le remplacant ; `dejaPrise` ne change rien.
      return reponse is Map && reponse['etat'] == 'acceptee';
    } on PostgrestException {
      return false;
    }
  }
}

/// L'intervalle de relecture du tableau commun, tant que l'ecran l'ecoute.
const Duration intervalleOffresRemplacement = Duration(seconds: 30);

/// [charger] tout de suite, puis toutes les [intervalle], tant que le flux est
/// ecoute. Une erreur est emise et termine le flux, comme avant.
///
/// R9 (30/10/2026) : **une minuterie annulable, et non une boucle `async*`
/// sur `Stream.periodic`.** Annulee, la boucle n'apprenait l'annulation qu'a
/// son `yield` suivant, donc APRES une lecture de plus : un appel
/// `offres_remplacement` partait jusqu'a 30 s apres la deconnexion, et
/// revenait en 401 (23 s apres la sortie de l'enseignant pendant l'essai K4
/// du 24/10). Meme convention que `presenceSeanceProvider`.
Stream<T> relectureCadencee<T>(
  Duration intervalle,
  Future<T> Function() charger,
) {
  Timer? minuterie;
  late final StreamController<T> sortie;

  Future<void> lire() async {
    try {
      final T valeur = await charger();
      if (!sortie.isClosed) sortie.add(valeur);
    } on Object catch (erreur, pile) {
      minuterie?.cancel();
      if (!sortie.isClosed) {
        sortie.addError(erreur, pile);
        unawaited(sortie.close());
      }
    }
  }

  sortie = StreamController<T>(
    onListen: () {
      unawaited(lire());
      minuterie = Timer.periodic(intervalle, (Timer _) => unawaited(lire()));
    },
    onCancel: () => minuterie?.cancel(),
  );
  return sortie.stream;
}

/// Le tableau commun des remplacements servi par Supabase.
class RemplacementsSupabase implements PortRemplacements, PortPretRemplacement {
  /// Cree l'adaptateur sur le client de l'application.
  const RemplacementsSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<OffreCommune>> suivre() =>
      relectureCadencee(intervalleOffresRemplacement, _charger);

  Future<List<OffreCommune>> _charger() async {
    final Object? brut = await _client.rpc<Object?>('offres_remplacement');
    if (brut is! List) throw const FormatException('Liste attendue.');
    return List<OffreCommune>.unmodifiable(<OffreCommune>[
      for (final Object? o in brut)
        if (o is Map)
          if (offreCommuneJson(Map<String, dynamic>.from(o))
              case final OffreCommune offre)
            offre,
    ]);
  }

  @override
  Future<ResultatPriseRemplacement> prendre(String seanceId) async {
    final Object? reponse = await _client.rpc<Object?>(
      'prendre_remplacement',
      params: <String, dynamic>{
        'p_session_id': seanceId,
        'p_cle_idempotence': cleRemplacement('prise', seanceId),
      },
    );
    return switch (reponse is Map ? reponse['etat'] : null) {
      'acceptee' => ResultatPriseRemplacement.acceptee,
      'dejaPrise' => ResultatPriseRemplacement.dejaPrise,
      _ => throw const FormatException('Reponse de prise inconnue.'),
    };
  }

  @override
  Future<ResultatPret> seDeclarerPret(String seanceId) async {
    final Object? reponse = await _client.rpc<Object?>(
      'se_declarer_pret_remplacement',
      params: <String, dynamic>{'p_session_id': seanceId},
    );
    return switch (reponse is Map ? reponse['etat'] : null) {
      'retenu' => ResultatPret.retenu,
      'dejaRetenu' => ResultatPret.dejaRetenu,
      'fermee' => ResultatPret.fermee,
      _ => throw const FormatException('Reponse inconnue.'),
    };
  }
}

/// Une offre rendue par `offres_remplacement` ; nulle quand elle est
/// incomplete (une ligne mal formee ne masque pas les autres).
OffreCommune? offreCommuneJson(Map<String, dynamic> o) {
  final DateTime? debut = o['debut'] is String
      ? DateTime.tryParse(o['debut'] as String)?.toLocal()
      : null;
  final DateTime? fin = o['fin'] is String
      ? DateTime.tryParse(o['fin'] as String)?.toLocal()
      : null;
  final EtatOffreCommune? etat = switch (o['etat']) {
    'ouverte' => EtatOffreCommune.ouverte,
    'prise_par_moi' => EtatOffreCommune.priseParMoi,
    'prise_par_un_collegue' => EtatOffreCommune.priseParUnCollegue,
    'preparation' => EtatOffreCommune.preparation,
    'pret_moi' => EtatOffreCommune.pretParMoi,
    'pret_collegue' => EtatOffreCommune.pretParUnCollegue,
    _ => null,
  };
  if (o['seance_id'] is! String || debut == null || fin == null) return null;
  if (etat == null) return null;
  return OffreCommune(
    offre: OffreRemplacement(
      seanceId: o['seance_id'] as String,
      groupeId: o['groupe_id'] as String?,
      classe: o['classe'] as String? ?? '',
      numeroDansFamille: (o['numero_dans_famille'] as num?)?.toInt(),
      debut: debut,
      fin: fin,
      nbEleves: (o['nb_eleves'] as num?)?.toInt() ?? 0,
    ),
    etat: etat,
  );
}
