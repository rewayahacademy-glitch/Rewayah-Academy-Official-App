// Captures de `/tc/classe` rendue par la salle de seance unique (T8).
// Sautees sans CAPTURE_DIR.
//
// CLV-06 (enseignant, visite) et CLV-07 (panneau Eleves, fiche de Mariam
// depliee), rendues par `ClasseLivePage` avec le faux moteur de
// `test/teaching_core/e/faux/faux_classe.dart`, en 390x844 @3 et 1440x900 @1,
// clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';

import '../../capture/outil_capture.dart';
import '../../teaching_core/e/faux/faux_classe.dart';
import '../../teaching_core/e/support/hote_classe.dart';

class _Taille {
  const _Taille(this.nom, this.logique, this.densite, this.zone);
  final String nom;
  final Size logique;
  final double densite;
  final EdgeInsets zone;
}

const List<_Taille> _tailles = <_Taille>[
  _Taille('390x844@3', Size(390, 844), 3, EdgeInsets.only(top: 47, bottom: 34)),
  _Taille('1440x900@1', Size(1440, 900), 1, EdgeInsets.zero),
];

SessionClockVM _horloge({required bool depassee}) {
  final DateTime debut = DateTime.utc(2026, 9, 26, 14, 15);
  return SessionClockVM(
    sessionId: 's1',
    debutUtc: debut,
    finPrevueUtc: debut.add(const Duration(minutes: 60)),
    joinOpensAtUtc: debut.subtract(const Duration(minutes: 15)),
    fenetreAcces: const Duration(minutes: 15),
    graceApresFin: const Duration(minutes: 30),
    horlogeUtilisateur: const HorlogeAffichee(
      fuseauIana: 'Europe/London',
      libelleVille: 'Londres',
      heureLocaleRendue: '15:16',
      dateLocaleRendue: '26 sept. 2026',
    ),
    phase: depassee ? PhaseSeance.prolongee : PhaseSeance.enCours,
    restant: depassee ? null : const Duration(minutes: 32),
    rejoindreOuvert: true,
    calculeeAUtc: debut.add(const Duration(minutes: 28)),
  );
}

List<PresenceParticipant> _inscrits() => <PresenceParticipant>[
  presenceDe(profilId: 'p1', prenom: 'Mariam', identifiant: 'RA-Mariam'),
  presenceDe(
    profilId: 'p2',
    prenom: 'Yusuf',
    identifiant: 'RA-Yusuf',
    etat: EtatPresence.enAttente,
  ),
  presenceDe(
    profilId: 'p3',
    prenom: 'Aïcha',
    identifiant: 'RA-Aicha',
    etat: EtatPresence.deconnectee,
  ),
  presenceDe(
    profilId: 't1',
    prenom: 'Amina',
    role: 'teacher',
    identifiant: 'RA-Amina',
  ),
];

List<TeacherStudentProjection> _fiches() => <TeacherStudentProjection>[
  TeacherStudentProjection(
    firstName: 'Mariam',
    academyId: 'RA-Mariam',
    level: 'Niveau 1',
    activeGoals: const <String>['Chapitre 1 (les bonnes manières)'],
    lastLesson: ResumeSeance(
      dateUtc: DateTime.utc(2026, 9, 24, 14),
      pointARevoir: 'Pages 24 à 26',
    ),
    recentAttendance: const AssiduiteRecente(presences: 3, total: 3),
    currentAssignments: <LearningAssignment>[
      LearningAssignment(
        id: 'a1',
        groupId: 'g1',
        studentId: 'RA-Mariam',
        resourceId: 'r1',
        purpose: IntentionPedagogique.aRevoir,
        instructions: 'Écoute de la récitation',
        startsAtUtc: DateTime.utc(2026, 9, 24),
        createdBy: 't1',
        status: StatutAssignation.enCours,
      ),
    ],
    liveStatus: EtatPresenceProjete.present,
    interfaceGuidee: false,
  ),
];

void main() {
  group('Capture : /tc/classe sur la salle unique (T8)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, bool eleves, String role, InterfaceMode mode)
        in <(String, bool, String, InterfaceMode)>[
          (
            'cl_06_enseignant_visite_tc',
            false,
            'teacher',
            InterfaceMode.standard,
          ),
          ('cl_07_eleves_tc', true, 'teacher', InterfaceMode.standard),
          // Matrice des roles : la meme route, vue par l'eleve standard et la
          // guidee (rien de reserve a l'enseignant).
          ('cl_04_eleve_tc', false, 'student', InterfaceMode.standard),
          ('cl_05_guidee_tc', false, 'student', InterfaceMode.enfant),
        ]) {
      final bool enseignant = role == 'teacher';
      for (final _Taille taille in _tailles) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final bool desktop = taille.logique.width >= 1200;
          // Images : desktop en visite et « se poursuit » ; telephone CLV-06
          // en visite, CLV-07 sans visite avec « 32 min restantes ».
          final bool visite = enseignant && (desktop || !eleves);
          testWidgets('$nom ${taille.nom} ${theme.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(
              tester,
              taille.logique,
              taille.densite,
              zoneSure: taille.zone,
            );
            final FauxMoteurClasse moteur = FauxMoteurClasse();
            await tester.pumpWidget(
              hoteCapture(
                ClasseLivePage(
                  contexte: ContexteClasseLive(
                    sessionId: 's1',
                    groupeId: DonneesSeanceDemo.groupeDemo,
                    libelleGroupe: DonneesSeanceDemo.classe,
                    enseignant: const EnseignantDeClasse(
                      nomAffichage: 'Amina',
                      titre: TitreEnseignant.sayyida,
                    ),
                    horloge: _horloge(depassee: desktop),
                    supportActifId: 'r1',
                    descriptionSupport: DonneesSeanceDemo.support,
                    dock: (BuildContext _) => const SizedBox.shrink(),
                    bibliotheque: (BuildContext _) => const SizedBox.shrink(),
                    onNoter: () {},
                    onSignaler: () {},
                  ),
                ),
                themeMode: theme,
                interfaceMode: mode,
                surcharges: surchargesCapture(
                  moteur: moteur,
                  visite: visite,
                  role: role,
                ),
              ),
            );
            await stabiliser(tester);
            moteur.publier(<ParticipantSalle>[
              participantDe(
                identite: 't1',
                role: 'teacher',
                nom: 'Amina',
                local: enseignant,
                micro: true,
                camera: true,
              ),
              if (!enseignant)
                participantDe(
                  identite: 'p1',
                  role: 'student',
                  nom: 'Mariam',
                  local: true,
                ),
            ]);
            await stabiliser(tester);
            if (eleves) {
              await tester.tap(
                find.textContaining(t.salle.seance.eleves).first,
              );
              await stabiliser(tester);
            }
            expect(tester.takeException(), isNull);
            await capturer(
              tester,
              '${nom}_${taille.nom}_${theme == ThemeMode.dark ? 'dark' : 'light'}',
            );
          });
        }
      }
    }
  });
}

/// Les faux de la Classe Live, pour une capture.
List<Override> surchargesCapture({
  required FauxMoteurClasse moteur,
  required bool visite,
  String role = 'teacher',
}) => surchargesClasse(
  moteur: moteur,
  video: FauxServiceVideoClasse(acces0: accesDe(role)),
  preVol: FauxPreVolClasse(),
  presence: FauxPresenceClasse(lignes: _inscrits()),
  roster: FauxRosterEnseignant(fiches: _fiches()),
  annonces: FauxAnnonceObservation(
    lignes: visite
        ? const <AnnonceObservation>[
            AnnonceObservation(
              libelle: 'Tuteur de Mariam observe',
              enfantConcerneId: 'RA-Mariam',
              prenomEnfant: 'Mariam',
            ),
          ]
        : const <AnnonceObservation>[],
  ),
);
