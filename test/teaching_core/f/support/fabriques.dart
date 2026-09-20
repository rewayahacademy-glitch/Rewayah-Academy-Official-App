import 'package:rewayah_academy/core/tc_etat_partage/ports_externes/content_position.dart';
import 'package:rewayah_academy/core/tc_etat_partage/ports_externes/content_range.dart';
import 'package:rewayah_academy/core/tc_etat_partage/ports_externes/marqueur_semantique.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// Les fabriques communes aux tests du lot F.
///
/// Elles vivent sous `test/teaching_core/f/` parce que `test/support/` est
/// interdit aux agents Teaching Core (decision D-06) : un fichier de 40 Ko deja
/// modifie par le chantier enseignant est un point de collision certain.

/// La seance de reference des tests.
const String seanceF = 'seance-f';

/// Une autre seance, pour prouver qu'un paquet etranger est ecarte.
const String autreSeance = 'seance-etrangere';

/// L'enseignant, seul porteur de `can_publish_data`.
const String profilEnseignant = 'prof-1';

/// Un eleve.
const String profilEleve = 'eleve-1';

/// Un second eleve, destinataire du rappel discret.
const String profilEleveDeux = 'eleve-2';

/// Une position de page.
ContentPosition positionPage(int page, {String resourceId = 'res-1'}) =>
    ContentPosition.page(resourceId: resourceId, page: page);

/// Une plage de pages.
ContentRange plagePages(
  int debut,
  int fin, {
  String resourceId = 'res-1',
}) => ContentRange(
  resourceId: resourceId,
  debut: positionPage(debut, resourceId: resourceId),
  fin: positionPage(fin, resourceId: resourceId),
);

/// Un marqueur semantique pose sur une plage de pages.
MarqueurSemantique marqueur(
  String id,
  int debut,
  int fin, {
  IntentionPedagogique intention = IntentionPedagogique.aRevoir,
  String? note,
}) => MarqueurSemantique(
  id: id,
  plage: plagePages(debut, fin),
  intention: intention,
  note: note,
);

/// Un etat partage complet, parametrable.
SharedContentState etatPartage({
  int revision = 0,
  String sessionId = seanceF,
  String resourceId = 'res-1',
  String? resourceVersionId,
  int page = 3,
  ModeAffichagePartage mode = ModeAffichagePartage.page,
  ContentRange? plage,
  List<ContentRange> masquees = const <ContentRange>[],
  List<MarqueurSemantique> marqueurs = const <MarqueurSemantique>[],
  ContentPosition? reprise,
  String updatedBy = profilEnseignant,
}) => SharedContentState(
  sessionId: sessionId,
  resourceId: resourceId,
  resourceVersionId: resourceVersionId,
  contentPosition: positionPage(page, resourceId: resourceId),
  contentRange: plage,
  displayMode: mode,
  hiddenRanges: masquees,
  semanticMarkers: marqueurs,
  groupResumePosition: reprise,
  revision: revision,
  updatedBy: updatedBy,
  // Instant fixe : un test ne depend jamais de l'horloge de la machine qui le
  // joue. La revision, pas l'horodatage, porte l'ordre.
  updatedAtUtc: DateTime.utc(2026, 9, 20, 10),
);

/// Les capacites signees d'un enseignant : seul role a porter
/// `can_publish_data` (`autoriser_jeton_video`).
const CapacitesTransport capacitesEnseignant = CapacitesTransport(
  identiteLocale: profilEnseignant,
  peutPublier: true,
  peutPublierDonnees: true,
  invisible: false,
);

/// Les capacites d'un eleve : il publie sa voix, jamais des donnees.
const CapacitesTransport capacitesEleve = CapacitesTransport(
  identiteLocale: profilEleve,
  peutPublier: true,
  peutPublierDonnees: false,
  invisible: false,
);

/// Les capacites d'un second eleve.
const CapacitesTransport capacitesEleveDeux = CapacitesTransport(
  identiteLocale: profilEleveDeux,
  peutPublier: true,
  peutPublierDonnees: false,
  invisible: false,
);

/// Les capacites d'un controleur : invisible, muet, sans donnees (D-16).
const CapacitesTransport capacitesControleur = CapacitesTransport(
  identiteLocale: 'controleur-1',
  peutPublier: false,
  peutPublierDonnees: false,
  invisible: true,
);

/// Un message pedagogique quelconque.
MessagePedagogique message({
  required String type,
  String sessionId = seanceF,
  String emetteur = profilEnseignant,
  Map<String, dynamic> charge = const <String, dynamic>{},
  int minute = 0,
}) => MessagePedagogique(
  type: type,
  sessionId: sessionId,
  emetteurProfilId: emetteur,
  charge: charge,
  emisLeUtc: DateTime.utc(2026, 9, 20, 10, minute),
);

/// L'acces tel que `create-room-token` le rend, pour un role donne.
///
/// Recopie du patron de `test/features/salle_test.dart` : seul `teacher` porte
/// `can_publish_data`, exactement comme `autoriser_jeton_video()` le calcule.
AccesSalle accesSalle(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  expireLe: DateTime.utc(2026, 9, 20, 11),
);
