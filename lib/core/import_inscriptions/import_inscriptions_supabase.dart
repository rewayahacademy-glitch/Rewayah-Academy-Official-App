/// Adaptateur IMM-ACCUEIL-FRONT : l'import des inscriptions par les RPC de la
/// direction (`capacites_import_inscriptions`, `previsualiser_import_inscriptions`,
/// `confirmer_import_inscriptions`). Le jeton de la session decide ; aucune cle
/// de service. Les reponses sont lues strictement : une forme inattendue est une
/// erreur, jamais un zero silencieux.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'analyse_inscriptions.dart';
import 'port_import_inscriptions.dart';

/// L'import des inscriptions servi par Supabase.
class ImportInscriptionsSupabase implements PortImportInscriptions {
  /// Cree l'adaptateur sur le client de l'application.
  ImportInscriptionsSupabase(SupabaseClient client)
    : _appel = ((String nom, [Map<String, dynamic>? params]) =>
          client.rpc<Object?>(nom, params: params));

  /// Cree l'adaptateur sur un appel injecte (tests).
  ImportInscriptionsSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String nom, [Map<String, dynamic>? params])
  _appel;

  @override
  Future<CapacitesImport> capacites() async {
    final Map<String, dynamic> j = _objet(
      await _executer('capacites_import_inscriptions'),
    );
    return CapacitesImport(
      peutImporter: j['peutImporter'] == true,
      doubleVerificationRequise: j['doubleVerificationRequise'] == true,
      bornes: BornesAge(
        minimum: (j['ageMinimum'] as num?)?.toInt(),
        adulte: (j['ageAdulte'] as num?)?.toInt(),
      ),
    );
  }

  @override
  Future<ApercuServeur> apercu({
    required String elevesCsv,
    required String enseignantsCsv,
  }) async {
    final Map<String, dynamic> j = _objet(
      await _executer('previsualiser_import_inscriptions', <String, dynamic>{
        'p_eleves_csv': elevesCsv,
        'p_enseignants_csv': enseignantsCsv,
      }),
    );
    final Object? motifs = j['motifs_rejet'];
    if (motifs is! List) throw const FormatException('motifs_rejet');
    return ApercuServeur(
      foyers: _entier(j, 'foyers'),
      personnes: _entier(j, 'personnes'),
      doublons: _entier(j, 'doublons'),
      lignesRejetees: _entier(j, 'lignes_rejetees'),
      motifs: <MotifRejetServeur>[for (final Object? m in motifs) _motif(m)],
    );
  }

  @override
  Future<ResultatImport> confirmer({
    required String elevesCsv,
    required String enseignantsCsv,
    required List<OptionFoyer> options,
  }) async {
    final Map<String, dynamic> j = _objet(
      await _executer('confirmer_import_inscriptions', <String, dynamic>{
        'p_eleves_csv': elevesCsv,
        'p_enseignants_csv': enseignantsCsv,
        'p_options_foyers': <Map<String, dynamic>>[
          for (final OptionFoyer o in options.where(
            (OptionFoyer o) => !o.neutre,
          ))
            <String, dynamic>{
              'email': o.email,
              'a_patiente': o.aPatiente,
              if (o.motAccueil != null && o.motAccueil!.trim().isNotEmpty)
                'mot_accueil': o.motAccueil!.trim(),
              if (o.aPatiente &&
                  o.motPatience != null &&
                  o.motPatience!.trim().isNotEmpty)
                'mot_patience': o.motPatience!.trim(),
            },
        ],
      }),
    );
    return ResultatImport(
      foyersTraites: _entier(j, 'foyers_traites'),
      foyersCrees: _entier(j, 'foyers_crees'),
      personnesCreees: _entier(j, 'personnes_creees'),
      personnesDejaImportees: _entier(j, 'personnes_deja_importees'),
    );
  }

  Future<Object?> _executer(String nom, [Map<String, dynamic>? params]) async {
    try {
      return await _appel(nom, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const ImportRefuse();
      if (e.code == '22023') throw ImportInvalide(e.message);
      rethrow;
    } on Object catch (e) {
      if (_estErreurReseau(e)) throw const ImportHorsLigne();
      rethrow;
    }
  }
}

MotifRejetServeur _motif(Object? m) {
  if (m is! Map) throw const FormatException('motif de rejet');
  final Object? source = m['source'];
  final Object? ligne = m['row'];
  final Object? motif = m['reason'];
  if (ligne is! num || motif is! String) {
    throw const FormatException('motif de rejet');
  }
  return MotifRejetServeur(
    source: switch (source) {
      'eleves' => SourceImport.eleves,
      'enseignants' => SourceImport.enseignants,
      _ => throw const FormatException('source du rejet'),
    },
    ligne: ligne.toInt(),
    motif: motif,
  );
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('reponse attendue : un objet');
  return Map<String, dynamic>.from(v);
}

int _entier(Map<String, dynamic> j, String cle) {
  final Object? v = j[cle];
  if (v is! num) throw FormatException(cle);
  return v.toInt();
}

bool _estErreurReseau(Object error) {
  final String texte = error.toString();
  return texte.contains('SocketException') ||
      texte.contains('ClientException') ||
      texte.contains('TimeoutException') ||
      texte.contains('Failed host lookup') ||
      texte.contains('Connection refused');
}
