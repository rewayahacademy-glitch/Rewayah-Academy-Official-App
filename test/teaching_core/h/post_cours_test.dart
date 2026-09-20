import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/cache/sync/file_rapports.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_parcours/port_post_cours.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_parcours/post_cours_vm.dart';
import 'package:rewayah_academy/core/tc_parcours/source_contenu_seance.dart';

import 'faux/faux_enseignant.dart';
import 'faux/faux_ports_externes.dart';

const String _seance = 's1';
const String _groupe = 'g1';
const String _coran = 'res-coran';
final DateTime _debut = DateTime(2026, 9, 20, 17);

ParticipantBrouillon _participant({
  String id = 'e1',
  String prenom = 'Amina',
  EtatPresence presence = EtatPresence.presente,
}) => ParticipantBrouillon(
  membre: MembreSeance(
    studentId: id,
    identifiantImmuable: 'RA-$id',
    prenom: prenom,
  ),
  presence: presence,
);

BrouillonCahier _brouillon({
  bool dejaDepose = false,
  int dureeMinutes = 52,
  String? groupeId = _groupe,
  List<ParticipantBrouillon>? participants,
}) => BrouillonCahier(
  seanceId: _seance,
  debut: _debut,
  fin: _debut.add(const Duration(minutes: 60)),
  statut: StatutSeance.terminee,
  dureeMinutes: dureeMinutes,
  minutesInterruption: 0,
  dejaDepose: dejaDepose,
  groupeId: groupeId,
  participants:
      participants ?? <ParticipantBrouillon>[_participant()],
  evenements: const <EvenementSeance>[],
);

TeacherStudentProjection _projection({
  String prenom = 'Amina',
  String academyId = 'RA-e1',
  EtatPresenceProjete etat = EtatPresenceProjete.present,
}) => TeacherStudentProjection(
  firstName: prenom,
  academyId: academyId,
  liveStatus: etat,
  interfaceGuidee: false,
);

ContentRange _versets({int premier = 255, int dernier = 257}) => ContentRange(
  resourceId: _coran,
  debut: ContentPosition.ayah(
    resourceId: _coran,
    sourate: 2,
    ayah: premier,
  ),
  fin: ContentPosition.ayah(resourceId: _coran, sourate: 2, ayah: dernier),
);

/// Le montage complet, tel qu'Agent Z le composera.
({
  PostCoursDepuisCahier postCours,
  FauxServiceEnseignant service,
  FauxDepotRapports depot,
  FauxRoster roster,
  FauxContenuSeance contenu,
  FauxAssignations assignations,
})
_montage({
  BrouillonCahier? brouillon,
  List<TeacherStudentProjection>? eleves,
  Map<String, List<ContentRange>> ranges =
      const <String, List<ContentRange>>{},
  Map<String, ContentPosition> reprises = const <String, ContentPosition>{},
}) {
  final FauxServiceEnseignant service = FauxServiceEnseignant()
    ..brouillonRendu = brouillon ?? _brouillon();
  final FauxDepotRapports depot = FauxDepotRapports();
  final FauxRoster roster = FauxRoster(
    eleves: eleves ?? <TeacherStudentProjection>[_projection()],
  );
  final FauxContenuSeance contenu = FauxContenuSeance(
    ranges: ranges,
    reprisesDeSeance: reprises,
  );
  final FauxAssignations assignations = FauxAssignations();

  return (
    postCours: PostCoursDepuisCahier(
      service,
      SoumissionCahier(FileRapports(depot), depot, service),
      roster,
      contenu,
      assignations,
      'ens-1',
    ),
    service: service,
    depot: depot,
    roster: roster,
    contenu: contenu,
    assignations: assignations,
  );
}

void main() {
  group('preparer : tout est deduit, rien n est redemande', () {
    test('la duree est celle de la base, jamais recalculee', () async {
      final montage = _montage(brouillon: _brouillon(dureeMinutes: 52));

      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      // 52 minutes, et non les 60 minutes de l'intervalle debut/fin : le depot
      // sait deja deduire quatre durees differentes pour une meme seance, et en
      // calculer une cinquieme donnerait deux chiffres pour le meme cours.
      expect(vm.dureeReelle, const Duration(minutes: 52));
      expect(vm.sessionId, _seance);
      expect(vm.notesExceptions, isNull);
    });

    test('les exceptions passent devant, la regle vient d Agent E', () async {
      final montage = _montage(
        eleves: <TeacherStudentProjection>[
          _projection(prenom: 'Bilal', academyId: 'RA-e2'),
          _projection(
            prenom: 'Amina',
            academyId: 'RA-e1',
            etat: EtatPresenceProjete.inconnu,
          ),
        ],
      );

      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      expect(vm.exceptions.single.academyId, 'RA-e1');
      expect(vm.participantsOrdonnes.first.academyId, 'RA-e1');
      expect(vm.toutEstNominal, isFalse);
    });

    test('tout nominal ouvre le chemin d un seul geste', () async {
      final PostCoursVM vm = await _montage().postCours.preparer(_seance);

      expect(vm.exceptions, isEmpty);
      expect(vm.toutEstNominal, isTrue);
    });

    test('un roster non projete ne bloque pas la cloture', () async {
      final montage = _montage();
      montage.roster.projectionAbsente = true;

      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      expect(vm.participants, isEmpty);
      // Ni nominal, ni exception : on ne declare pas « tout va bien » sur une
      // seance dont on ne sait rien.
      expect(vm.toutEstNominal, isFalse);
    });

    test('une seance introuvable est nommee, pas silencieuse', () async {
      final FauxServiceEnseignant service = FauxServiceEnseignant();
      final FauxDepotRapports depot = FauxDepotRapports();
      final PostCoursDepuisCahier postCours = PostCoursDepuisCahier(
        service,
        SoumissionCahier(FileRapports(depot), depot, service),
        FauxRoster(),
        const ContenuSeanceIndisponible(),
        FauxAssignations(),
        'ens-1',
      );

      expect(
        () => postCours.preparer(_seance),
        throwsA(
          isA<EchecPostCours>().having(
            (EchecPostCours e) => e.motif,
            'motif',
            MotifEchecPostCours.seanceIntrouvable,
          ),
        ),
      );
    });
  });

  group('preparer : la position et le travail sont proposes', () {
    test('sans trace de contenu, rien n est invente', () async {
      final PostCoursVM vm = await _montage().postCours.preparer(_seance);

      expect(vm.positionDeRepriseProposee, isNull);
      expect(vm.rangesTravailles, isEmpty);
      expect(vm.travailPropose, isEmpty);
    });

    test('une plage travaillee devient un travail a revoir', () async {
      final montage = _montage(
        ranges: <String, List<ContentRange>>{
          _seance: <ContentRange>[_versets()],
        },
        reprises: <String, ContentPosition>{
          _seance: const ContentPosition.ayah(
            resourceId: _coran,
            sourate: 2,
            ayah: 257,
          ),
        },
      );

      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      expect(vm.positionDeRepriseProposee, isNotNull);
      expect(vm.positionDeRepriseProposee!.ayah, 257);
      expect(vm.rangesTravailles, hasLength(1));
      expect(vm.travailPropose, hasLength(1));
      expect(vm.travailPropose.single.purpose, IntentionPedagogique.aRevoir);
      expect(vm.travailPropose.single.groupId, _groupe);
      expect(vm.travailPropose.single.contentRange, _versets());
    });

    test('la proposition ne depasse pas le plafond du bloc', () async {
      final montage = _montage(
        ranges: <String, List<ContentRange>>{
          _seance: <ContentRange>[
            for (int i = 0; i < 5; i++)
              _versets(premier: 1 + i * 10, dernier: 5 + i * 10),
          ],
        },
      );

      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      expect(vm.rangesTravailles, hasLength(5));
      expect(vm.travailPropose, hasLength(3));
    });

    test('une seance sans groupe ne propose aucun travail', () async {
      // Un cours individuel anterieur au pivot du 19 septembre : les
      // assignations sont des objets de groupe.
      final montage = _montage(
        brouillon: _brouillon(groupeId: null),
        ranges: <String, List<ContentRange>>{
          _seance: <ContentRange>[_versets()],
        },
      );

      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      expect(vm.travailPropose, isEmpty);
    });
  });

  group('enregistrer : le hors ligne passe par la file existante', () {
    test('en ligne, le cahier part et la file reste vide', () async {
      final montage = _montage();
      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      final SortCahier sort = await montage.postCours.deposer(vm);

      expect(sort, SortCahier.envoye);
      expect(montage.service.cahiersDeposes, hasLength(1));
      expect(montage.depot.rapports, isEmpty);
      expect(montage.service.cahiersDeposes.single.seanceId, _seance);
    });

    test('hors ligne, le cahier est mis en file et rien n est perdu', () async {
      final montage = _montage();
      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      // La coupure survient APRES la lecture : c'est le cas reel, et c'est
      // celui ou le constat retenu par `preparer` devient indispensable.
      montage.service
        ..envoiIndisponible = true
        ..lectureIndisponible = true;

      final SortCahier sort = await montage.postCours.deposer(vm);

      expect(sort, SortCahier.enFile);
      expect(montage.service.cahiersDeposes, isEmpty);
      expect(montage.depot.rapports, hasLength(1));
      expect(montage.depot.rapports.single.sessionId, _seance);
    });

    test('le rejeu garde la meme cle d idempotence', () async {
      final montage = _montage();
      final PostCoursVM vm = await montage.postCours.preparer(_seance);
      montage.service.envoiIndisponible = true;
      await montage.postCours.deposer(vm);

      final String cle = montage.depot.rapports.single.cleIdempotence;

      // Le reseau revient : la file rejoue sans regenerer la cle, ce qui permet
      // a la contrainte d'unicite de refuser un doublon en base.
      montage.service.envoiIndisponible = false;
      final SoumissionCahier soumission = SoumissionCahier(
        FileRapports(montage.depot),
        montage.depot,
        montage.service,
      );
      await soumission.rejouer();

      expect(montage.service.cahiersDeposes.single.cle, cle);
      expect(montage.depot.rapports, isEmpty);
    });

    test('la note d exception voyage comme note de groupe', () async {
      final montage = _montage();
      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      await montage.postCours.deposer(
        vm.avecNotes('  Bilal a quitte la salle a mi-parcours.  '),
      );

      final Map<String, dynamic> contenu =
          montage.service.cahiersDeposes.single.contenu;
      expect(contenu['note_groupe'], 'Bilal a quitte la salle a mi-parcours.');
    });

    test('une decision par eleve, et « Continuer » par defaut', () async {
      final montage = _montage(
        brouillon: _brouillon(
          participants: <ParticipantBrouillon>[
            _participant(),
            _participant(id: 'e2', prenom: 'Bilal'),
          ],
        ),
      );
      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      await montage.postCours.deposer(vm);

      final List<Object?> eleves =
          montage.service.cahiersDeposes.single.contenu['eleves']!
              as List<Object?>;
      expect(eleves, hasLength(2));
      expect(
        (eleves.first! as Map<String, dynamic>)['confirme'],
        isTrue,
      );
    });

    test('un cahier deja depose ne se redepose pas', () async {
      final montage = _montage(brouillon: _brouillon(dejaDepose: true));
      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      final SortCahier sort = await montage.postCours.deposer(vm);

      expect(sort, SortCahier.envoye);
      expect(montage.service.cahiersDeposes, isEmpty);
      expect(montage.depot.rapports, isEmpty);
    });
  });

  group('enregistrer : le travail propose est pose a la validation', () {
    test('chaque proposition validee devient une assignation', () async {
      final montage = _montage(
        ranges: <String, List<ContentRange>>{
          _seance: <ContentRange>[_versets()],
        },
      );
      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      await montage.postCours.deposer(vm);

      expect(montage.assignations.creations, hasLength(1));
      expect(
        montage.assignations.creations.single.purpose,
        IntentionPedagogique.aRevoir,
      );
    });

    test('une proposition retiree n est pas posee', () async {
      final montage = _montage(
        ranges: <String, List<ContentRange>>{
          _seance: <ContentRange>[_versets()],
        },
      );
      final PostCoursVM vm = await montage.postCours.preparer(_seance);

      await montage.postCours.deposer(
        vm.avecTravail(const <LearningAssignment>[]),
      );

      expect(montage.assignations.creations, isEmpty);
    });

    test('un travail non pose est nomme, et le cahier reste parti', () async {
      final montage = _montage(
        ranges: <String, List<ContentRange>>{
          _seance: <ContentRange>[_versets()],
        },
      );
      final PostCoursVM vm = await montage.postCours.preparer(_seance);
      montage.assignations.ecritureIndisponible = true;

      await expectLater(
        montage.postCours.deposer(vm),
        throwsA(
          isA<EchecPostCours>().having(
            (EchecPostCours e) => e.motif,
            'motif',
            MotifEchecPostCours.travailNonPose,
          ),
        ),
      );

      // Le compte rendu, lui, est bien parti : l'ordre des deux ecritures est
      // porteur d'information.
      expect(montage.service.cahiersDeposes, hasLength(1));
    });
  });
}
