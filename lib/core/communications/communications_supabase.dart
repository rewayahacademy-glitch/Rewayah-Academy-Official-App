// Le socle partage des adaptateurs Supabase des Communications (COM-BACK-1) :
// l'appel RPC, les libelles injectes, la cle d'idempotence et la lecture
// prudente des reponses du serveur.
//
// Le serveur rend des DONNEES (prenom, titre, libelle de Classe, code de
// public), jamais un texte redige : la redaction est faite ici, par des
// libelles injectes ([LibellesCommunication]), pour que le francais et
// l'arabe restent dans slang. Aucun role n'est lu : les droits sont recalcules
// par le serveur a chaque appel (migrations 20261016090000 et 20261016090100).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'modeles_communication.dart';

/// Un appel RPC : nom de la fonction, parametres, reponse JSON decodee.
typedef AppelRpc = Future<Object?> Function(
  String fonction,
  Map<String, dynamic> parametres,
);

/// L'appel RPC du client Supabase de l'application.
AppelRpc appelRpcSupabase(SupabaseClient client) =>
    (String fonction, Map<String, dynamic> parametres) =>
        client.rpc<Object?>(fonction, params: parametres);

/// Les mots que l'adaptateur compose a partir des donnees du serveur.
abstract interface class LibellesCommunication {
  /// Le nom d'une Classe (« Classe An-Nour »).
  String classe(String libelle);

  /// L'equipe d'administration, sans nom de personne.
  String administration();

  /// Une famille (un foyer).
  String famille();

  /// Un enseignant : son titre (`sayid`, `sayyida`, ou nul) et son prenom.
  String enseignant({required String prenom, String? nom, String? titre});

  /// Un objet sans nom rendu par le serveur (dossier, profil de paiement).
  String objet(TypeObjetLie type);

  /// Un public d'annonce : `toutes`, `familles` ou `enseignants`.
  String publicAnnonce(String code);
}

/// Les codes d'erreur du serveur qui disent « pas pour vous » ou « pas
/// encore deploye » : la capacite est indisponible, ce n'est pas une panne.
bool estRefusOuAbsence(Object erreur) =>
    erreur is PostgrestException &&
    (erreur.code == '42501' ||
        erreur.code == 'PGRST202' ||
        erreur.code == '42883');

const String _espaceCles = '0d6c1f52-7a3b-5e49-9c18-4b2e6f8a1d37';
final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Vrai si [valeur] est un identifiant que le serveur peut lire.
bool estUuid(String valeur) => _uuid.hasMatch(valeur);

/// La cle d'idempotence envoyee au serveur : la meme cle d'ecran donne
/// toujours le meme uuid, d'un essai a l'autre.
String cleServeur(String cleEcran) => const Uuid().v5(_espaceCles, cleEcran);

/// Une liste JSON, ou une erreur de format.
List<Map<String, dynamic>> listeJson(Object? valeur) {
  if (valeur is! List) throw const FormatException('Liste attendue.');
  return <Map<String, dynamic>>[for (final Object? e in valeur) objetJson(e)];
}

/// Un objet JSON, ou une erreur de format.
Map<String, dynamic> objetJson(Object? valeur) {
  if (valeur is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(valeur);
}

/// Un texte obligatoire.
String texteJson(Map<String, dynamic> m, String cle) {
  final Object? v = m[cle];
  if (v is! String || v.isEmpty) throw FormatException('Champ $cle invalide.');
  return v;
}

/// Un texte facultatif.
String? texteOptionnel(Map<String, dynamic> m, String cle) {
  final Object? v = m[cle];
  return v is String && v.isNotEmpty ? v : null;
}

/// Un instant obligatoire, rendu en UTC.
DateTime instantJson(Map<String, dynamic> m, String cle) {
  final DateTime? d = DateTime.tryParse(texteJson(m, cle));
  if (d == null) throw FormatException('Instant $cle invalide.');
  return d.toUtc();
}

/// Un instant facultatif, rendu en UTC.
DateTime? instantOptionnel(Map<String, dynamic> m, String cle) {
  final String? v = texteOptionnel(m, cle);
  return v == null ? null : DateTime.tryParse(v)?.toUtc();
}

/// Une personne ou une partie rendue par le serveur, nommee par [libelles].
///
/// Natures : `equipe` (l'Administration, jamais une personne nommee), `foyer`
/// (une famille ; sa fonction dit les enfants concernes), `profil` (un
/// enseignant nomme par son titre et son prenom, sinon par son prenom).
Participant participantJson(
  Map<String, dynamic> m,
  LibellesCommunication libelles,
) {
  final String id = texteJson(m, 'id');
  final bool soi = m['est_soi'] == true;
  switch (m['nature']) {
    case 'equipe':
      return Participant(
        id: id,
        nomAffiche: libelles.administration(),
        estSoi: soi,
      );
    case 'foyer':
      final Object? eleves = m['eleves'];
      final List<String> prenoms = <String>[
        if (eleves is List)
          for (final Object? e in eleves)
            if (e is String && e.isNotEmpty) e,
      ];
      return Participant(
        id: id,
        nomAffiche: libelles.famille(),
        fonction: prenoms.isEmpty ? null : prenoms.join(', '),
        estSoi: soi,
      );
    case 'profil':
      final String prenom = texteJson(m, 'prenom');
      return Participant(
        id: id,
        nomAffiche: m['fonction'] == 'enseignant'
            ? libelles.enseignant(
                prenom: prenom,
                nom: texteOptionnel(m, 'nom'),
                titre: texteOptionnel(m, 'titre'),
              )
            : prenom,
        estSoi: soi,
      );
    default:
      throw const FormatException('Nature de participant inconnue.');
  }
}

/// L'objet d'un fil ou d'une conversation, nomme par [libelles]. Sans
/// destination : l'adaptateur ne connait pas l'espace de la personne qui lit.
ObjetLie objetLieJson(Map<String, dynamic> m, LibellesCommunication libelles) {
  final TypeObjetLie type = TypeObjetLie.depuis(texteOptionnel(m, 'type'));
  final String? classe = texteOptionnel(m, 'classe');
  final String? prenom = texteOptionnel(m, 'prenom');
  final String libelle = switch (type) {
    TypeObjetLie.eleve when prenom != null => prenom,
    TypeObjetLie.classe when classe != null => libelles.classe(classe),
    TypeObjetLie.remplacement when classe != null => libelles.classe(classe),
    _ => libelles.objet(type),
  };
  return ObjetLie(type: type, id: texteJson(m, 'id'), libelle: libelle);
}
