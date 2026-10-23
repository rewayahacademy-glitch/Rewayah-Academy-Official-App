import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import '../presence/service_presence.dart';
import '../reseau/sondage_regulier.dart';
import 'port_roster_enseignant.dart';
import 'roster_classe_vm.dart';
import 'teacher_student_projection.dart';

/// Projette les quatorze etats de `presence_state` sur les neuf du contrat.
///
/// **La seule correspondance du lot, et elle vit ici.** Une conversion dupliquee
/// dans un widget divergerait au premier etat ajoute -- et l'invariant J4
/// interdit justement d'en ajouter un quinzieme en base, ce qui rend cette table
/// stable et verifiable.
///
/// Deux choix meritent d'etre nommes :
///
/// - `excusee` devient [EtatPresenceProjete.absent]. L'excuse est une decision
///   administrative ; le roster live dit ou est la personne, et elle n'est pas
///   la. L'information « c'est excuse » n'est pas perdue, elle n'appartient
///   simplement pas a cette projection -- elle est demandee en section 1 de
///   `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_E.md` ;
/// - les trois etats de consolidation deviennent [EtatPresenceProjete.inconnu],
///   **jamais `absent`** : ils qualifient une seance close, pas une place dans
///   la salle.
EtatPresenceProjete projeterEtatPresence(EtatPresence etat) => switch (etat) {
  EtatPresence.planifiee ||
  EtatPresence.enAttente => EtatPresenceProjete.attendu,
  EtatPresence.enConnexion => EtatPresenceProjete.enConnexion,
  EtatPresence.presente ||
  EtatPresence.reconnectee => EtatPresenceProjete.present,
  EtatPresence.enRetard => EtatPresenceProjete.enRetard,
  EtatPresence.deconnectee => EtatPresenceProjete.deconnecte,
  EtatPresence.enReconnexion => EtatPresenceProjete.enReconnexion,
  EtatPresence.sortie => EtatPresenceProjete.sorti,
  EtatPresence.absente || EtatPresence.excusee => EtatPresenceProjete.absent,
  EtatPresence.confirmationEnAttente ||
  EtatPresence.corrigeeManuel ||
  EtatPresence.finalisee ||
  EtatPresence.inconnu => EtatPresenceProjete.inconnu,
};

/// Lit une ligne de `teacher_roster_v` comme un volet **pedagogique**.
///
/// Quatre colonnes et rien d'autre : `first_name`, `immutable_id`, `level`,
/// `riwaya`. **`last_name` a ete retire de cette vue en 0005** (ADR-008,
/// defaut 3.8), et personne ne le reintroduit, pas meme une initiale.
///
/// `riwaya` est disponible et **volontairement pas projetee** : elle ne figure
/// pas au contrat, et un agent n'ajoute pas un champ parce que la vue le lui
/// offre.
///
/// [EtatPresenceProjete.inconnu] est pose ici a dessein : cette lecture ne sait
/// rien de la presence. C'est `presence_seance_v` qui le dira, et [composerRoster]
/// qui fusionnera les deux -- dans cet ordre.
TeacherStudentProjection ficheDepuisRosterV(Map<String, dynamic> json) =>
    TeacherStudentProjection(
      firstName: json['first_name'] as String? ?? '',
      academyId: json['immutable_id'] as String? ?? '',
      level: json['level'] as String?,
      liveStatus: EtatPresenceProjete.inconnu,
      // `teacher_roster_v` ne porte pas `interface_mode`, et `student_profiles`
      // n'accorde aucune policy select a l'enseignant. Le repli est `false`,
      // soit l'interface standard : promettre une Interface guidee qu'on n'a
      // pas lue serait pire que de ne pas l'annoncer. Demande en section 1 de
      // `TC_CONTRACT_REQUEST_E.md`.
      interfaceGuidee: false,
    );

/// Compose le roster a partir des deux lectures.
///
/// **Fonction pure**, comme `VueSalle.depuis` et `VuePresence.depuis` : le
/// croisement, le filtrage des roles, la projection d'etat et l'ordre se
/// verifient sans reseau, sans base et sans monter d'ecran.
///
/// **La presence est la source des INSCRITS**, pas des connectes : qui n'est
/// jamais arrive y figure quand meme, alors qu'il n'a aucune piste temps reel.
/// Batir un roster sur la seule liste LiveKit effacerait exactement ceux dont
/// l'enseignant doit savoir quelque chose.
///
/// Seuls les eleves entrent. L'enseignant, le tuteur observateur et le
/// controleur masque ont leur place ailleurs a l'ecran : le roster repond a
/// « ou en sont mes eleves », pas a « qui est connecte ».
///
/// L'etat vient **toujours** de la presence, jamais de la fiche : la fiche est
/// lue une fois, la presence toutes les vingt secondes. Prendre l'etat de la
/// fiche figerait le roster a l'entree.
List<TeacherStudentProjection> composerRoster({
  required List<PresenceParticipant> presences,
  Map<String, TeacherStudentProjection> fichesParAcademyId =
      const <String, TeacherStudentProjection>{},
}) {
  final List<TeacherStudentProjection> roster = <TeacherStudentProjection>[
    for (final PresenceParticipant p in presences)
      if (p.role == 'student')
        _fusionner(fichesParAcademyId[p.identifiantImmuable], p),
  ];
  // Ordre de lecture stable : le prenom. Un roster qui se reordonnerait a
  // chaque rafraichissement -- par etat, par exemple -- ferait bouger la ligne
  // sous le doigt de l'enseignant au moment ou il la touche.
  roster.sort(
    (TeacherStudentProjection a, TeacherStudentProjection b) =>
        a.firstName.compareTo(b.firstName),
  );
  return roster;
}

/// Une ligne de presence, enrichie de sa fiche quand elle existe.
///
/// Quand la fiche manque -- lecture partielle, eleve inscrit apres la lecture --
/// le prenom et l'identifiant de la presence suffisent : une ligne sans niveau
/// reste vraie, une ligne absente serait fausse.
TeacherStudentProjection _fusionner(
  TeacherStudentProjection? fiche,
  PresenceParticipant presence,
) {
  final EtatPresenceProjete etat = projeterEtatPresence(presence.etat);
  if (fiche == null) {
    return TeacherStudentProjection(
      firstName: presence.prenom,
      academyId: presence.identifiantImmuable,
      liveStatus: etat,
      interfaceGuidee: false,
    );
  }
  return TeacherStudentProjection(
    firstName: fiche.firstName.isEmpty ? presence.prenom : fiche.firstName,
    academyId: fiche.academyId.isEmpty
        ? presence.identifiantImmuable
        : fiche.academyId,
    level: fiche.level,
    curriculumPath: fiche.curriculumPath,
    currentUnit: fiche.currentUnit,
    activeGoals: fiche.activeGoals,
    lastLesson: fiche.lastLesson,
    resumePoints: fiche.resumePoints,
    recentAttendance: fiche.recentAttendance,
    currentAssignments: fiche.currentAssignments,
    authorizedPedagogicalNotes: fiche.authorizedPedagogicalNotes,
    liveStatus: etat,
    interfaceGuidee: fiche.interfaceGuidee,
  );
}

/// Le roster pedagogique lu sur les vues existantes.
///
/// **Aucune vue neuve n'est creee, et c'est la consigne.** `teacher_roster_v`
/// existe depuis 0001, a ete recreee en 0005 puis en 0014, est bornee a
/// `teacher_id = auth.uid()` -- et n'avait **aucun consommateur Dart**. La voici
/// branchee. `presence_seance_v` fournit l'etat, comme partout ailleurs dans le
/// produit.
///
/// Ce que ce service **ne fait pas** : il n'appelle jamais `groupe_detail()`,
/// qui rend `student_nom` et reste reserve a l'administration. L'ouvrir a
/// l'enseignant serait un contournement de l'ADR-008, pas une optimisation.
class RosterEnseignantSupabase implements PortRosterEnseignant {
  /// Cree le service.
  const RosterEnseignantSupabase(this._client);

  final SupabaseClient _client;

  /// Les fiches pedagogiques d'une seance, par identifiant d'academie.
  ///
  /// Rend une carte vide quand la vue ne repond rien : le roster reste lisible
  /// a partir de la seule presence, en perdant le niveau. Une exception ici
  /// couperait tout le roster pour une colonne d'appoint.
  Future<Map<String, TeacherStudentProjection>> _fiches(
    String sessionId,
  ) async {
    try {
      final List<Map<String, dynamic>> lignes = await _client
          .from('teacher_roster_v')
          .select()
          .eq('session_id', sessionId);
      return <String, TeacherStudentProjection>{
        for (final Map<String, dynamic> ligne in lignes)
          ficheDepuisRosterV(ligne).academyId: ficheDepuisRosterV(ligne),
      };
    } catch (erreur) {
      journalDev('fiches pedagogiques indisponibles : $erreur');
      return const <String, TeacherStudentProjection>{};
    }
  }

  @override
  Future<List<TeacherStudentProjection>> rosterDeSeance(
    String sessionId,
  ) async {
    final List<Map<String, dynamic>> lignes;
    try {
      lignes = await _client
          .from('presence_seance_v')
          .select()
          .eq('session_id', sessionId);
    } catch (erreur) {
      journalDev('roster indisponible : $erreur');
      throw const EchecRoster(MotifEchecRoster.lecture);
    }
    return composerRoster(
      presences: lignes.map(PresenceParticipant.depuisJson).toList(),
      fichesParAcademyId: await _fiches(sessionId),
    );
  }

  @override
  Future<List<TeacherStudentProjection>> rosterDeGroupe(String groupeId) =>
      // **Refuser explicitement plutot que rendre une liste vide.** Une liste
      // vide dirait « ce groupe n'a aucun membre » d'un groupe qui en a cinq :
      // `groupe_membres` ne porte que `student_id`, et la jointure vers
      // `profiles` est fermee a l'enseignant par la RLS.
      Future<List<TeacherStudentProjection>>.error(
        const EchecRoster(MotifEchecRoster.projectionAbsente),
      );

  @override
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  }) async {
    if (sessionId == null) {
      // Hors seance, la seule porte serait le roster de groupe, qui n'existe
      // pas cote serveur. On le dit, au lieu de rendre `null`, qui se lirait
      // comme « cet eleve n'existe pas ».
      throw const EchecRoster(MotifEchecRoster.projectionAbsente);
    }
    for (final TeacherStudentProjection eleve in await rosterDeSeance(
      sessionId,
    )) {
      if (eleve.academyId == academyId) {
        return eleve;
      }
    }
    return null;
  }

  @override
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId) {
    // **La meme cadence que la presence, et la meme constante.** Deux des
    // quatorze etats basculent avec le seul ecoulement du temps ; une cadence
    // propre au roster finirait par ne plus dire la meme chose que la ligne de
    // presence affichee a cote.
    //
    // L'ecran de Classe Live n'emprunte PAS ce chemin : il compose
    // `rosterClasseProvider` au-dessus de `presenceSeanceProvider`, la boucle
    // existante. Cette methode est la parce que le contrat l'exige, et pour un
    // consommateur hors Riverpod.
    final StreamController<List<TeacherStudentProjection>> sortie =
        StreamController<List<TeacherStudentProjection>>();
    SondageRegulier? sondage;

    Future<bool> lire() async {
      try {
        final List<TeacherStudentProjection> roster = await rosterDeSeance(
          sessionId,
        );
        if (!sortie.isClosed) {
          sortie.add(roster);
        }
        return true;
      } on EchecRoster catch (erreur) {
        // Le flux ne s'interrompt jamais sur une erreur : la lecture suivante a
        // lieu (apres un recul, `SondageRegulier`), et le reseau revient
        // souvent en trois secondes.
        journalDev('roster indisponible : $erreur');
        return false;
      }
    }

    sortie
      ..onListen = () {
        // Une minuterie annulable, et non une boucle `async*` qui attend : le
        // depot a MESURE le defaut inverse -- un `Future.delayed` continue de
        // courir apres la sortie de salle. R14 : decalage au hasard et recul
        // apres echec, cadence moyenne inchangee.
        sondage = SondageRegulier(cadence: cadencePresence, lire: lire)
          ..demarrer();
      }
      ..onCancel = () {
        sondage?.arreter();
        return sortie.close();
      };
    return sortie.stream;
  }
}

/// Le roster enseignant employe par l'application.
final Provider<PortRosterEnseignant> portRosterEnseignantProvider =
    Provider<PortRosterEnseignant>(
      (Ref ref) => RosterEnseignantSupabase(Supabase.instance.client),
    );

/// Le roster d'une seance, pour l'emplacement roster de l'Espace Groupe
/// (Agent A) hors Classe Live.
///
/// **Ne catch pas `EchecRoster`**, contrairement a [fichesSeanceProvider] :
/// ici la distinction disponible/indisponible EST l'invariant a tenir
/// (`RosterClasseVM.indisponible` face a une liste vide, J3), pas un detail a
/// absorber en silence.
final FutureProviderFamily<List<TeacherStudentProjection>, String>
rosterSeanceEnseignantProvider =
    FutureProvider.family<List<TeacherStudentProjection>, String>(
      (Ref ref, String sessionId) =>
          ref.watch(portRosterEnseignantProvider).rosterDeSeance(sessionId),
    );

/// Les fiches pedagogiques d'une seance, lues une fois.
///
/// Une seule lecture suffit : le prenom, l'identifiant d'academie et le niveau
/// d'un eleve ne changent pas pendant un cours. L'etat, lui, change -- et il
/// vient de `presenceSeanceProvider`, qui le relit deja.
final FutureProviderFamily<List<TeacherStudentProjection>, String>
fichesSeanceProvider =
    FutureProvider.family<List<TeacherStudentProjection>, String>((
      Ref ref,
      String seanceId,
    ) async {
      try {
        return await ref
            .watch(portRosterEnseignantProvider)
            .rosterDeSeance(seanceId);
      } on EchecRoster {
        // L'indisponibilite se dit par le roster compose, pas par une exception
        // qui laisserait l'ecran sur un etat d'echec definitif.
        return const <TeacherStudentProjection>[];
      }
    });

/// Le roster de la classe, pret a afficher.
///
/// **Compose, jamais relu.** Il croise deux providers : la presence, dont la
/// boucle de vingt secondes est deja ecrite et deja testee, et les fiches
/// pedagogiques, lues une fois. Aucune seconde boucle n'est ouverte.
final ProviderFamily<RosterClasseVM, String> rosterClasseProvider =
    Provider.family<RosterClasseVM, String>((Ref ref, String seanceId) {
      // `.value` et surtout pas un filtrage par le type de l'AsyncValue : les
      // trois cas qui rendent `null` -- pas encore charge, lecture refusee,
      // reseau coupe -- se disent de la meme facon, par l'indisponibilite.
      final List<PresenceParticipant>? presences = ref
          .watch(presenceSeanceProvider(seanceId))
          .value;
      if (presences == null) {
        return RosterClasseVM.indisponible;
      }
      final List<TeacherStudentProjection> fiches =
          ref.watch(fichesSeanceProvider(seanceId)).value ??
          const <TeacherStudentProjection>[];
      return RosterClasseVM(
        eleves: composerRoster(
          presences: presences,
          fichesParAcademyId: <String, TeacherStudentProjection>{
            for (final TeacherStudentProjection f in fiches) f.academyId: f,
          },
        ),
        disponible: true,
      );
    });
