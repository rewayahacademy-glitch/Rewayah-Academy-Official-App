// SALLE (garde-cap et pilote, 11/11/2026) : un ENFANT etait vouvoye dans la
// salle, parce que l'age de l'eleve n'etait jamais lu (port neutre « avant
// BR-1 », sans date). La salle lit maintenant le type de l'eleve devant
// l'ecran sur le serveur (`student_profiles.student_type`), une fois.
//
// Ces tests echouent sans la correction : la vue de la seance d'un eleve
// mineur restait au vouvoiement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/age_eleve.dart';
import 'package:rewayah_academy/core/accessibilite/age_eleve_supabase.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';
import '../../support/mushaf_15l.dart' show surchargesMadina15;
import '../../teaching_core/e/faux/faux_classe.dart';

/// La lecture du serveur, comptee : une fois par eleve, jamais plus.
class _LectureFixe implements PortLectureAgeEleve {
  _LectureFixe(this.ages);

  final Map<String, AgeEleve> ages;
  final List<String> lus = <String>[];

  @override
  Future<AgeEleve> lire(String eleveId) async {
    lus.add(eleveId);
    return ages[eleveId] ?? AgeEleve.inconnu;
  }
}

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

List<Override> _surcharges(
  String role,
  FauxMoteurSalle moteur,
  _LectureFixe lecture,
) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: role == 'teacher' ? AppRole.teacher : AppRole.student,
        profileId: role == 'teacher' ? 't1' : 'e1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideo(acces0: _acces(role)),
  ),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(
    FauxServicePresence(lignes: const <PresenceParticipant>[]),
  ),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(observe: false),
  ),
  portAnnonceObservationProvider.overrideWithValue(
    FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
  ),
  ...surchargesMadina15(page: 42),
  profilEnseignantParIdProvider.overrideWith((Ref _, String id) async => null),
  pageCoranProvider.overrideWith(
    (Ref _, int n) async =>
        PageCoran(numero: n, versets: const <VersetCoran>[]),
  ),
  portLectureAgeEleveProvider.overrideWithValue(lecture),
];

Future<_LectureFixe> _monter(
  WidgetTester tester, {
  String role = 'student',
  Map<String, AgeEleve> ages = const <String, AgeEleve>{},
}) async {
  fixerVueCapture(tester, const Size(390, 844), 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  final _LectureFixe lecture = _LectureFixe(ages);
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(role, moteur, lecture),
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    ParticipantSalle(
      identite: role == 'teacher' ? 't1' : 'e1',
      nom: '',
      role: role,
      estLocal: true,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    ),
  ]);
  await tester.pumpAndSettle();
  return lecture;
}

bool? _tutoiement(WidgetTester tester) =>
    tester.widget<SalleSeance>(find.byType(SalleSeance)).vue.tutoiement;

void main() {
  group('le type du serveur devient un age, sans rien calculer', () {
    test('minor : mineur ; autonomous : adulte ; le reste : inconnu', () {
      expect(LectureAgeEleveSupabase.depuisType('minor'), AgeEleve.mineur);
      expect(LectureAgeEleveSupabase.depuisType('autonomous'), AgeEleve.adulte);
      expect(LectureAgeEleveSupabase.depuisType(null), AgeEleve.inconnu);
      expect(LectureAgeEleveSupabase.depuisType('autre'), AgeEleve.inconnu);
    });

    test('le vrai adaptateur : il traduit, et un echec rend inconnu', () async {
      Future<String?> mineur(String _) async => 'minor';
      Future<String?> echec(String _) async => throw StateError('reseau');
      expect(
        await LectureAgeEleveSupabase.avecLecture(mineur).lire('e1'),
        AgeEleve.mineur,
      );
      expect(
        await LectureAgeEleveSupabase.avecLecture(echec).lire('e1'),
        AgeEleve.inconnu,
      );
    });
  });

  group('/salle', () {
    testWidgets('eleve enfant : tutoiement dans /salle', (
      WidgetTester tester,
    ) async {
      final _LectureFixe lecture = await _monter(
        tester,
        ages: const <String, AgeEleve>{'e1': AgeEleve.mineur},
      );
      expect(_tutoiement(tester), isTrue);
      // Une seule lecture pour cet eleve, gardee le temps de la session.
      expect(lecture.lus, <String>['e1']);
      // Vu sur le banc le 11/11 au soir : seul avant son enseignant, l'enfant
      // lisait « Restez sur cet ecran... votre enseignant » au-dessus de
      // « Ton micro s'ouvrira ». La scene d'attente le tutoie aussi.
      expect(find.text(t.salle.seulEnseignantDetailTutoie), findsOneWidget);
      expect(find.text(t.salle.seulEnseignantDetail), findsNothing);
      expect(find.text(t.salle.seulEnseignant), findsNothing);
      expect(find.textContaining('Votre'), findsNothing);
      expect(find.textContaining('votre'), findsNothing);
    });

    testWidgets('eleve adulte : vouvoiement', (WidgetTester tester) async {
      await _monter(
        tester,
        ages: const <String, AgeEleve>{'e1': AgeEleve.adulte},
      );
      expect(_tutoiement(tester), isFalse);
      expect(find.text(t.salle.seulEnseignantDetail), findsOneWidget);
      expect(find.text(t.salle.seulEnseignantDetailTutoie), findsNothing);
    });

    testWidgets('age inconnu du serveur : vouvoiement, comme avant', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(_tutoiement(tester), isFalse);
    });

    // Revue du garde-cap du 11/11/2026 (B3) : la page ne lit plus le role.
    // Le profil d'un enseignant n'a pas de fiche d'eleve : le serveur ne rend
    // rien, l'age reste inconnu, la salle vouvoie.
    testWidgets("l'enseignant : vous", (WidgetTester tester) async {
      final _LectureFixe lecture = await _monter(tester, role: 'teacher');
      expect(lecture.lus, <String>['t1']);
      expect(_tutoiement(tester), isFalse);
      expect(find.text(t.salle.seulEleveDetail), findsOneWidget);
    });
  });
}
