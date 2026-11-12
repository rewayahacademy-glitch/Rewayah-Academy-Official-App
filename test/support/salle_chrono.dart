// DYNAMIQUE-CHRONO-1 : monte la vraie page `/salle` (`SallePage`, faux moteur
// du harnais) avec un chrono, une pause programmee (chez l'enseignant), la
// page 42 du Coran presentee, pour les tests et les captures du lot.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/bornes_salle.dart';

import '../capture/outil_capture.dart';
import '../teaching_core/e/faux/faux_classe.dart';
import 'harnais.dart';
import 'mushaf_15l.dart' show surchargesMadina15;

const String _seance = 's1';

String _profil(String role) => role == 'teacher' ? 't1' : 'e1';

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ParticipantSalle _personne(String id, String role, {required bool local}) =>
    ParticipantSalle(
      identite: id,
      nom: '',
      role: role,
      estLocal: local,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    );

PresenceParticipant _ligne(
  String id,
  String prenom,
  String role, {
  EtatPresence etat = EtatPresence.presente,
}) => PresenceParticipant(
  seanceId: _seance,
  profilId: id,
  role: role,
  prenom: prenom,
  identifiantImmuable: 'RA-26-$id',
  etat: etat,
  consolide: false,
  entreLe: DateTime.now(),
);

/// Les surcharges de la salle du lot : chrono de 90 min commence il y a
/// 52 min (reste 38 min), pause programmee dans 21 min chez l'enseignant.
List<Override> surchargesSalleChrono(
  String role,
  FauxMoteurSalle moteur, {
  EtatPresence etatEleve = EtatPresence.presente,
  DateTime? maintenant,
}) {
  final DateTime t0 = (maintenant ?? DateTime.now().toUtc()).subtract(
    const Duration(minutes: 52),
  );
  return <Override>[
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(
        SessionState(
          resolue: true,
          role: role == 'teacher' ? AppRole.teacher : AppRole.student,
          profileId: _profil(role),
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
      FauxServicePresence(
        lignes: <PresenceParticipant>[
          _ligne('t1', 'Amina', 'teacher'),
          _ligne('e1', 'Yasmine', 'student', etat: etatEleve),
        ],
      ),
    ),
    portAnnonceObservationEnfantProvider.overrideWithValue(
      FauxAnnonceObservationEnfant(observe: false),
    ),
    portAnnonceObservationProvider.overrideWithValue(
      FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
    ),
    ...surchargesMadina15(page: 42),
    profilEnseignantParIdProvider.overrideWith(
      (Ref _, String id) async => id == 't1'
          ? const ProfilEnseignant(
              prenom: 'Amina',
              identifiant: 'RA-26-t1',
              titre: 'sayyida',
            )
          : null,
    ),
    bornesSalleProvider.overrideWith(
      (Ref _, CleBornesSalle _) => BornesChrono(
        debutUtc: t0,
        finPrevueUtc: t0.add(const Duration(minutes: 90)),
      ),
    ),
    pauseSeanceProvider.overrideWith(
      (Ref _, String _) async => PauseSeance(
        statut: StatutPause.programmee,
        dureePrevueMinutes: 10,
        debutPrevuUtc: DateTime.now().toUtc().add(
          const Duration(minutes: 21),
        ),
        peutPiloter: true,
      ),
    ),
  ];
}

/// Monte `/salle` pour [role] dans la fenetre [taille], la page 42 du Coran
/// presentee a la classe.
Future<FauxMoteurSalle> monterSalleChrono(
  WidgetTester tester, {
  required String role,
  required Size taille,
  ThemeMode theme = ThemeMode.light,
  double echelleTexte = 1,
  double densite = 1,
  bool mouvementReduit = false,
  bool page = true,
  EtatPresence etatEleve = EtatPresence.presente,
  EdgeInsets zoneSure = EdgeInsets.zero,
}) async {
  fixerVueCapture(tester, taille, densite, zoneSure: zoneSure);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: mouvementReduit),
          child: const SallePage(seanceId: _seance),
        ),
      ),
      surcharges: surchargesSalleChrono(role, moteur, etatEleve: etatEleve),
      themeMode: theme,
      echelleTexte: echelleTexte,
    ),
  );
  await tester.pumpAndSettle();
  moteur
    ..publier(<ParticipantSalle>[
      _personne('t1', 'teacher', local: role == 'teacher'),
      _personne('e1', 'student', local: role != 'teacher'),
    ])
    ..publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
  if (page) {
    moteur.publierContenu(
      ContenuPresente(
        page: 42,
        sourate: 2,
        verset: 255,
        presentePar: 't1',
        emisLe: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
  }
  return moteur;
}
