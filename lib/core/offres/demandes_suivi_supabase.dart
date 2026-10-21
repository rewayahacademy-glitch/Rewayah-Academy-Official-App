import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_suivi_demandes.dart';

/// Suivi privé des demandes d'horaires, rendu par le RPC borné au foyer courant.
class DemandesSuiviSupabase implements PortSuiviDemandes {
  const DemandesSuiviSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<SuiviDemande>> suivre() async* {
    yield await _charger();
    // Le port ne possède pas de canal Realtime sécurisé : la lecture reste
    // bornée au foyer par le RPC et n'est relancée que tant que l'écran écoute.
    await for (final void _ in Stream<void>.periodic(
      const Duration(seconds: 30),
    )) {
      yield await _charger();
    }
  }

  Future<List<SuiviDemande>> _charger() async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'suivi_demandes_horaires_foyer',
    );
    return rows.map(_suiviDepuisJson).toList(growable: false);
  }

  SuiviDemande _suiviDepuisJson(dynamic raw) {
    if (raw is! Map) {
      throw const FormatException('Suivi de demande invalide');
    }
    final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
    final List<dynamic> rawOccurrences =
        (row['occurrences'] as List<dynamic>?) ?? const <dynamic>[];
    final EtapeDemande etape = switch (row['etape']) {
      'envoyee' => EtapeDemande.envoyee,
      'classe_validee' => EtapeDemande.classeValidee,
      'enseignant_affecte' => EtapeDemande.enseignantAffecte,
      'close' => EtapeDemande.close,
      _ => throw const FormatException('Etape de demande inconnue'),
    };
    return SuiviDemande(
      demandeId: row['demande_id'] as String,
      eleveId: row['eleve_id'] as String,
      prenom: row['prenom'] as String? ?? '',
      etape: etape,
      creneau: CreneauDemande(
        occurrences: rawOccurrences.map((dynamic item) {
          if (item is! Map) {
            throw const FormatException('Occurrence de demande invalide');
          }
          final Map<String, dynamic> occurrence = Map<String, dynamic>.from(
            item,
          );
          return OccurrenceCreneau(
            jourIso: (occurrence['jour_iso'] as num).toInt(),
            heure: (occurrence['heure'] as num).toInt(),
            minute: (occurrence['minute'] as num?)?.toInt() ?? 0,
          );
        }),
      ),
      fuseauIana: row['fuseau_iana'] as String,
      personnalise: row['personnalisee'] as bool? ?? false,
      enseignant: row['enseignant'] as String?,
      debutCours: DateTime.tryParse(row['debut_cours'] as String? ?? ''),
      motif: _motifDepuisCode(row['motif'] as String?),
      peutChoisirAutreCreneau:
          row['peut_choisir_autre_creneau'] as bool? ?? false,
    );
  }

  MotifCloture? _motifDepuisCode(String? code) => switch (code) {
    'retrait_famille' => MotifCloture.retraitFamille,
    'offre_retiree' => MotifCloture.offreRetiree,
    'classe_non_constituee' => MotifCloture.classeNonConstituee,
    'refus_direction' => MotifCloture.refusDirection,
    'deja_en_classe' => MotifCloture.dejaEnClasse,
    _ => null,
  };
}
