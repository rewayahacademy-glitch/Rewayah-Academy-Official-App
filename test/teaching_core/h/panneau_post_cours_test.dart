import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/cache/sync/file_rapports.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_parcours/libelles_tc_parcours.dart';
import 'package:rewayah_academy/core/tc_parcours/port_post_cours.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/content_position.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/content_range.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/teacher_student_projection.dart';
import 'package:rewayah_academy/features/tc_flux_academique/panneau_post_cours.dart';

import 'faux/faux_enseignant.dart';
import 'faux/faux_ports_externes.dart';
import 'support/hote_h.dart';

const String _seance = 's1';
const String _groupe = 'g1';
const String _coran = 'res-coran';
final DateTime _debut = DateTime(2026, 9, 20, 17);

BrouillonCahier _brouillon() => BrouillonCahier(
  seanceId: _seance,
  debut: _debut,
  fin: _debut.add(const Duration(minutes: 60)),
  statut: StatutSeance.terminee,
  dureeMinutes: 52,
  minutesInterruption: 0,
  dejaDepose: false,
  groupeId: _groupe,
  participants: const <ParticipantBrouillon>[
    ParticipantBrouillon(
      membre: MembreSeance(
        studentId: 'e1',
        identifiantImmuable: 'RA-e1',
        prenom: 'Amina',
      ),
      presence: EtatPresence.presente,
    ),
  ],
  evenements: const <EvenementSeance>[],
);

({List<Override> surcharges, FauxServiceEnseignant service}) _montage({
  List<TeacherStudentProjection>? eleves,
  Map<String, List<ContentRange>> ranges =
      const <String, List<ContentRange>>{},
  Map<String, ContentPosition> reprises = const <String, ContentPosition>{},
}) {
  final FauxServiceEnseignant service = FauxServiceEnseignant()
    ..brouillonRendu = _brouillon();
  final FauxDepotRapports depot = FauxDepotRapports();

  return (
    surcharges: <Override>[
      portPostCoursProvider.overrideWithValue(
        PostCoursDepuisCahier(
          service,
          SoumissionCahier(FileRapports(depot), depot, service),
          FauxRoster(
            eleves:
                eleves ??
                <TeacherStudentProjection>[
                  const TeacherStudentProjection(
                    firstName: 'Amina',
                    academyId: 'RA-e1',
                    liveStatus: EtatPresenceProjete.present,
                    interfaceGuidee: false,
                  ),
                ],
          ),
          FauxContenuSeance(ranges: ranges, reprisesDeSeance: reprises),
          FauxAssignations(),
          'ens-1',
        ),
      ),
    ],
    service: service,
  );
}

void main() {
  group('panneau d apres-cours', () {
    testWidgets('tout est prerempli, et le chemin nominal est un geste', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final montage = _montage();

      await tester.pumpWidget(
        hoteH(
          const PanneauPostCours(sessionId: _seance),
          surcharges: montage.surcharges,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(LibellesParcours.postCoursDuree(52)), findsOneWidget);
      expect(
        find.text(LibellesParcours.postCoursToutEstNominal),
        findsOneWidget,
      );
      // Rien n'est invente : ni position de reprise, ni travail.
      expect(
        find.text(LibellesParcours.postCoursRepriseInconnue),
        findsOneWidget,
      );
      expect(
        find.text(LibellesParcours.postCoursTravailAucun),
        findsOneWidget,
      );
    });

    testWidgets('la position et le travail proposes se lisent en clair', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final montage = _montage(
        ranges: <String, List<ContentRange>>{
          _seance: <ContentRange>[
            ContentRange(
              resourceId: _coran,
              debut: const ContentPosition.ayah(
                resourceId: _coran,
                sourate: 2,
                ayah: 255,
              ),
              fin: const ContentPosition.ayah(
                resourceId: _coran,
                sourate: 2,
                ayah: 257,
              ),
            ),
          ],
        },
        reprises: <String, ContentPosition>{
          _seance: const ContentPosition.ayah(
            resourceId: _coran,
            sourate: 2,
            ayah: 257,
          ),
        },
      );

      await tester.pumpWidget(
        hoteH(
          const PanneauPostCours(sessionId: _seance),
          surcharges: montage.surcharges,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sourate 2, verset 257'), findsOneWidget);
      expect(find.text('Sourate 2, versets 255 à 257'), findsOneWidget);
      expect(find.text(LibellesParcours.intentionRevoir), findsOneWidget);
    });

    testWidgets('valider cloture le cours en un seul tap', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final montage = _montage();

      await tester.pumpWidget(
        hoteH(
          const PanneauPostCours(sessionId: _seance),
          surcharges: montage.surcharges,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(LibellesParcours.postCoursValider));
      await tester.pumpAndSettle();

      expect(find.text(LibellesParcours.postCoursEnvoye), findsOneWidget);
      expect(montage.service.cahiersDeposes, hasLength(1));
    });

    testWidgets('hors ligne, le panneau promet la file, pas un envoi', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final montage = _montage();

      await tester.pumpWidget(
        hoteH(
          const PanneauPostCours(sessionId: _seance),
          surcharges: montage.surcharges,
        ),
      );
      await tester.pumpAndSettle();

      // La coupure survient entre la lecture et la validation : le cas reel.
      montage.service
        ..envoiIndisponible = true
        ..lectureIndisponible = true;

      await tester.tap(find.text(LibellesParcours.postCoursValider));
      await tester.pumpAndSettle();

      expect(find.text(LibellesParcours.postCoursEnFile), findsOneWidget);
      expect(montage.service.cahiersDeposes, isEmpty);
    });
  });
}
