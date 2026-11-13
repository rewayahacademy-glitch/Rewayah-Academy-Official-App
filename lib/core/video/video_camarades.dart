// CAMARADES (directeur, 12/11/2026) : « la vraie video, c'est seulement
// celui qui recite ; sinon on ne voit que sa photo. »
//
// Chez un ELEVE qui regarde, la camera d'un camarade (un autre eleve) n'est
// recue que pendant que ce camarade recite ; celle de l'enseignant qui
// conduit la seance l'est toujours. Ce que voient l'enseignant, le tuteur
// qui assiste et le controleur ne change pas. Le son n'est jamais concerne.
//
// Ce fichier porte la regle, pure, sans SDK : le moteur (`LiveKitSession
// Provider`) s'en sert pour ne pas s'ABONNER a la piste, l'ecran
// (`videoMontree`, `media_salle.dart`) pour ne pas la montrer. Une seule
// regle, deux endroits qui la tiennent.
//
// Limite, dite au directeur (journal D-040) : c'est le client qui choisit
// ses abonnements. Le jeton signe de chaque eleve garde `can_subscribe`, et
// un client modifie pourrait encore s'abonner a la camera d'un camarade.
// Pour le fermer cote serveur, il faudrait que la fonction de la recitation
// (ou une fonction de la salle) pose les permissions d'abonnement LiveKit
// (`UpdateSubscriptions` / permissions de piste) depuis le serveur.

import 'dart:convert';

import 'publication_differee.dart' show roleQuiConduit;
import 'video_session_provider.dart' show AccesSalle;

/// La cle des metadonnees de la salle LiveKit qui porte la recitation,
/// ecrite par le serveur seul (`supabase/functions/_shared/recitation.ts`).
const String cleRecitationSalle = 'recitation';

/// L'identite de l'eleve qui recite, lue dans les metadonnees de la salle
/// ([metadonnees], ecrites par le serveur), ou `null` : aucune recitation,
/// ou metadonnees illisibles (dans le doute, aucun camarade n'est montre en
/// video).
String? recitantDesMetadonnees(String? metadonnees) {
  if (metadonnees == null || metadonnees.isEmpty) return null;
  try {
    final Object? brut = jsonDecode(metadonnees);
    if (brut is! Map<String, dynamic>) return null;
    final Object? recitation = brut[cleRecitationSalle];
    if (recitation is! Map<String, dynamic>) return null;
    final Object? recitant = recitation['recitant'];
    if (recitant is! String || recitant.trim().isEmpty) return null;
    return recitant.trim();
  } on FormatException {
    return null;
  }
}

/// LA regle : la video de [identite] (role [roleDistant] dans la seance)
/// est-elle recue et montree chez la personne qui regarde ?
///
/// - [regardEleve] faux (enseignant, tuteur, controleur, direction) : tout,
///   comme avant ;
/// - soi-meme ([local]) : toujours (sa propre image) ;
/// - chez un eleve : l'enseignant qui conduit ([roleQuiConduit]), et le
///   camarade qui recite ([recitant]) ; personne d'autre.
bool videoRecue({
  required bool regardEleve,
  required bool local,
  required String roleDistant,
  required String identite,
  required String? recitant,
}) {
  if (!regardEleve || local) return true;
  if (roleDistant == roleQuiConduit) return true;
  return recitant != null && recitant.isNotEmpty && identite == recitant;
}

/// Vrai quand le role du jeton ([role]) est celui d'un eleve.
bool roleEleve(String? role) => role == AccesSalle.roleEleve;

/// Une piste distante, vue par la regle : ce qu'il faut pour decider de s'y
/// abonner ou non, sans SDK. Le moteur adapte les publications LiveKit ; les
/// tests passent un faux.
abstract interface class PisteDistante {
  /// L'identite du participant qui publie (son profil).
  String get identite;

  /// Son role dans la seance, signe par le serveur.
  String get role;

  /// Vrai pour une piste d'image (camera) ; faux pour le son, jamais
  /// touche par la regle.
  bool get estVideo;

  /// Vrai quand la piste est recue.
  bool get abonnee;

  /// S'abonner a la piste.
  Future<void> abonner();

  /// Se desabonner de la piste.
  Future<void> desabonner();
}

/// Aligne les abonnements VIDEO de la personne qui regarde sur la regle
/// ([videoRecue]).
///
/// - une piste de son n'est jamais touchee ;
/// - une camera qui ne doit pas etre recue est desabonnee ;
/// - chez un eleve seulement, une camera qui doit l'etre (l'enseignant, le
///   camarade qui se met a reciter) est rabonnee, sauf si l'image est
///   suspendue ([videoSuspendue] : « audio seul » demande, ou repli d'un lien
///   mauvais) ; ailleurs, rien n'est rabonne ici : l'enseignant et
///   l'observateur gardent exactement le comportement d'avant ce lot.
Future<void> accorderAbonnementsVideo({
  required String roleLocal,
  required String? recitant,
  required Iterable<PisteDistante> pistes,
  bool videoSuspendue = false,
}) async {
  final bool eleve = roleEleve(roleLocal);
  for (final PisteDistante piste in pistes.toList()) {
    if (!piste.estVideo) continue;
    final bool voulue = videoRecue(
      regardEleve: eleve,
      local: false,
      roleDistant: piste.role,
      identite: piste.identite,
      recitant: recitant,
    );
    if (!voulue && piste.abonnee) {
      await piste.desabonner();
    } else if (voulue && !piste.abonnee && eleve && !videoSuspendue) {
      await piste.abonner();
    }
  }
}
