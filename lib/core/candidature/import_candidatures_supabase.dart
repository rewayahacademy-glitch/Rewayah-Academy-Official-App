// L'adaptateur Supabase de l'import des formulaires (`PortImportCandidatures`),
// sur les RPC de CAND-L3
// (`20261022000600_cand_l3_inscription_import_rapprochement.sql`) :
// `capacites_candidatures`, `apercu_import_formulaires` et
// `confirmer_import_formulaires`.
//
// Le serveur decide : lecture du fichier, reconnaissance des titres et des
// libelles, issues, groupes de doublons, jeton, idempotence, aal2. L'adaptateur
// ne lit rien du fichier, ne recalcule rien ; il traduit.
//
// - `42501` : le lecteur n'est pas le super-admin (`PermissionInsuffisante`).
// - `22023` : arguments hors bornes (`ImportInvalide`).
// - `PGRST202` / `42883` : la fonction n'est pas encore versee
//   (`CapaciteIndisponible`), pas une panne a reessayer.
// - Les refus metier arrivent **dans la reponse** (`{erreur: ...}`), toujours
//   sans ecriture : ils deviennent des erreurs typees.
// - Une coupure du reseau devient [ImportHorsLigne] : pour une confirmation,
//   l'import est non confirme et se rejoue avec la meme cle d'idempotence.
// - Toute autre erreur remonte telle quelle : l'ecran dit « n'a pas abouti »
//   avec « Reessayer », sans affirmer une cause.
//
// Les parametres sont ceux de la signature versee. Un mappage sans correction
// part en `p_mappage: null` (jamais `{}`), ce que le serveur lit comme « aucune
// correction ».
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'modeles_import_candidatures.dart';
import 'port_import_candidatures.dart';

/// L'import des formulaires servi par Supabase.
class ImportCandidaturesSupabase implements PortImportCandidatures {
  /// Cree l'adaptateur sur le client de l'application.
  ImportCandidaturesSupabase(SupabaseClient client)
    : _appel = ((String nom, [Map<String, dynamic>? params]) =>
          client.rpc<Object?>(nom, params: params));

  /// Cree l'adaptateur sur un appel injecte (tests).
  ImportCandidaturesSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String nom, [Map<String, dynamic>? params])
  _appel;

  @override
  Future<CapacitesImportCandidatures> capacites() async =>
      CapacitesImportCandidatures.depuisJson(
        await _executer('capacites_candidatures'),
      );

  @override
  Future<ApercuImport> apercu({
    required String csv,
    required String classeur,
    required String onglet,
    MappageColonnes mappage = MappageColonnes.aucun,
    String fuseau = 'UTC',
  }) async {
    final Map<String, dynamic> j = _objet(
      await _executer('apercu_import_formulaires', <String, dynamic>{
        'p_csv': csv,
        'p_classeur': classeur,
        'p_onglet': onglet,
        'p_mappage': mappage.versJson(),
        'p_fuseau': fuseau,
      }),
    );
    _refusDuServeur(j);
    return ApercuImport.depuisJson(j);
  }

  @override
  Future<RapportImport> confirmer({
    required String csv,
    required String classeur,
    required String onglet,
    required String jeton,
    required List<ChoixDoublon> choix,
    required String cleIdempotence,
    MappageColonnes mappage = MappageColonnes.aucun,
    String fuseau = 'UTC',
  }) async {
    final Map<String, dynamic> j = _objet(
      await _executer('confirmer_import_formulaires', <String, dynamic>{
        'p_csv': csv,
        'p_classeur': classeur,
        'p_onglet': onglet,
        'p_jeton': jeton,
        'p_choix': <Map<String, String>>[
          for (final ChoixDoublon c in choix) c.versJson(),
        ],
        'p_cle_idempotence': cleIdempotence,
        'p_mappage': mappage.versJson(),
        'p_fuseau': fuseau,
      }),
    );
    _refusDuServeur(j);
    return RapportImport.depuisJson(j);
  }

  Future<Object?> _executer(String nom, [Map<String, dynamic>? params]) async {
    try {
      return await _appel(nom, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(nom);
      if (e.code == '22023') throw ImportInvalide(e.message);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceImportCandidatures);
      }
      rethrow;
    } on Object catch (e) {
      if (_estErreurReseau(e)) throw const ImportHorsLigne();
      rethrow;
    }
  }
}

/// Traduit le `{erreur: ...}` du serveur en erreur typee. Sans `erreur`, ne
/// fait rien.
void _refusDuServeur(Map<String, dynamic> j) {
  final Object? code = j['erreur'];
  if (code == null) return;
  switch (code) {
    case 'double_verification_requise':
      throw const DoubleVerificationRequise();
    case 'fichier_illisible':
      final Object? cause = j['cause'];
      throw FichierIllisible(cause is String ? cause : '');
    case 'fichier_vide':
      throw const FichierVide();
    case 'entetes_ambigus':
      throw EntetesAmbigus(
        champs: _champs(j['champs']),
        colonnes: _colonnes(j['entetes']),
      );
    case 'mappage_incomplet':
      throw MappageIncomplet(
        champs: _manquants(j['champs']),
        colonnes: _colonnes(j['entetes']),
      );
    case 'jeton_perime':
      throw const JetonPerime();
    case 'cle_idempotence_reutilisee':
      throw const CleIdempotenceReutilisee();
    case 'choix_invalide':
      final Object? groupes = j['groupes'];
      throw ChoixInvalide(<String>[
        if (groupes is List)
          for (final Object? g in groupes)
            if (g is String) g,
      ]);
    default:
      throw ImportRefuseInconnu('$code');
  }
}

List<ChampFormulaire> _champs(Object? brut) {
  if (brut is! List) throw const FormatException('champs attendus');
  return <ChampFormulaire>[
    for (final Object? c in brut)
      ChampFormulaire.depuisCode(c) ?? (throw FormatException('champ : $c')),
  ];
}

List<ChampManquant> _manquants(Object? brut) {
  if (brut is! List) throw const FormatException('champs attendus');
  return <ChampManquant>[
    for (final Object? c in brut)
      ChampManquant.depuisCode(c) ?? (throw FormatException('champ : $c')),
  ];
}

List<ColonneLue> _colonnes(Object? brut) {
  if (brut is! List) throw const FormatException('entetes attendus');
  return <ColonneLue>[for (final Object? e in brut) ColonneLue.depuisJson(e)];
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('reponse attendue : un objet');
  return Map<String, dynamic>.from(v);
}

bool _estErreurReseau(Object error) {
  final String texte = error.toString();
  return texte.contains('SocketException') ||
      texte.contains('ClientException') ||
      texte.contains('TimeoutException') ||
      texte.contains('Failed host lookup') ||
      texte.contains('Connection refused');
}
