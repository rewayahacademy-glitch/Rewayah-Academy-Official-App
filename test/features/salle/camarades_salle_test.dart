// CAMARADES (directeur, 12/11/2026, journal D-040) : « il faut que les autres
// eleves voient celui qui recite, au moins une partie du nom, la photo [...]
// mais la vraie video, c'est seulement celui qui recite ; sinon on ne voit
// que sa photo. »
//
// A travers la vraie page `/salle` (`SallePage`) et le faux moteur du
// harnais, en mode Classe (la grille), eleve enfant (Interface guidee) et
// eleve adulte, a 390 et 1440 :
// - chaque camarade a son prenom (lu par `camaradesSalleProvider`, jamais le
//   nom de famille), meme chez un enfant ;
// - un camarade camera allumee qui ne recite pas est montre sans video (sa
//   photo, ou sa couleur et son initiale) ;
// - celui qui recite est en video, l'enseignant aussi ;
// - chez l'enseignant, rien ne change : toutes les cameras.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart'
    show MessagePedagogique;
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/cadre_visage.dart';
import 'package:rewayah_academy/core/widgets/grille_visages.dart';
import 'package:rewayah_academy/features/salle/annuaire_seance.dart'
    show CamaradeSeance;
import 'package:rewayah_academy/features/salle/camarades_salle.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart'
    show typeParoleSalle;

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';
import '../../support/mushaf_15l.dart' show surchargesMadina15;
import '../../teaching_core/e/faux/faux_classe.dart';

const String _seance = 's1';

/// Le port des camarades, comme le serveur le rendrait a l'eleve e1.
class _Camarades implements PortCamaradesSalle {
  const _Camarades();

  @override
  Future<List<CamaradeSeance>> camarades() async => const <CamaradeSeance>[
    (id: 'e2', prenom: 'Ilyes'),
    (id: 'e3', prenom: 'Sara'),
  ];
}

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

ParticipantSalle _personne(String id, String role, {bool local = false}) =>
    ParticipantSalle(
      identite: id,
      nom: '',
      role: role,
      estLocal: local,
      micro: false,
      camera: true,
      parle: false,
      qualite: QualiteLien.bonne,
    );

PresenceParticipant _ligne(String id, String prenom, String role) =>
    PresenceParticipant(
      seanceId: _seance,
      profilId: id,
      role: role,
      prenom: prenom,
      identifiantImmuable: 'RA-26-$id',
      etat: EtatPresence.presente,
      consolide: false,
      entreLe: DateTime.now(),
    );

/// Qui regarde : un enfant (Interface guidee), un adulte autonome, ou
/// l'enseignant.
enum _Regard { enfant, adulte, enseignant }

List<Override> _surcharges(_Regard regard, FauxMoteurSalle moteur) {
  final bool enseignant = regard == _Regard.enseignant;
  return <Override>[
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(
        SessionState(
          resolue: true,
          role: switch (regard) {
            _Regard.enfant => AppRole.student,
            _Regard.adulte => AppRole.guardian,
            _Regard.enseignant => AppRole.teacher,
          },
          eleveAutonome: regard == _Regard.adulte,
          interfaceMode: regard == _Regard.enfant
              ? InterfaceMode.enfant
              : InterfaceMode.standard,
          profileId: enseignant ? 't1' : 'e1',
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
        ),
      ),
    ),
    servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
    serviceVideoProvider.overrideWithValue(
      FauxServiceVideo(acces0: _acces(enseignant ? 'teacher' : 'student')),
    ),
    moteurSalleProvider.overrideWithValue(moteur),
    // La presence ne donne a l'eleve que l'enseignant et lui-meme : le
    // prenom des camarades vient de la lecture de ce lot.
    servicePresenceProvider.overrideWithValue(
      FauxServicePresence(
        lignes: <PresenceParticipant>[
          _ligne('t1', 'Amina', 'teacher'),
          _ligne('e1', 'Yasmine', 'student'),
          if (enseignant) ...<PresenceParticipant>[
            _ligne('e2', 'Ilyes', 'student'),
            _ligne('e3', 'Sara', 'student'),
          ],
        ],
      ),
    ),
    portCamaradesSalleProvider.overrideWithValue(const _Camarades()),
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
    pageCoranProvider.overrideWith(
      (Ref _, int n) async => PageCoran(
        numero: n,
        versets: <VersetCoran>[
          VersetCoran(
            sourateNumero: 2,
            numero: 255,
            texte: 'verset',
            pageNumero: n,
          ),
        ],
      ),
    ),
  ];
}

/// Monte la salle : l'enseignant, l'eleve e1 et deux camarades, toutes les
/// cameras allumees (le faux moteur a une image pour chacun), e3 recite.
Future<FauxMoteurSalle> _monter(
  WidgetTester tester,
  _Regard regard, {
  Size taille = const Size(1440, 900),
  ThemeMode theme = ThemeMode.light,
  String? recitant = 'e3',
}) async {
  fixerVueCapture(tester, taille, 1);
  final bool enseignant = regard == _Regard.enseignant;
  final FauxMoteurSalle moteur = FauxMoteurSalle()
    ..avecImage.addAll(<String>['t1', 'e1', 'e2', 'e3']);
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: _seance),
      surcharges: _surcharges(regard, moteur),
      themeMode: theme,
      interfaceMode: regard == _Regard.enfant
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', local: enseignant),
    _personne('e1', 'student', local: !enseignant),
    _personne('e2', 'student'),
    _personne('e3', 'student'),
  ]);
  moteur.publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
  if (recitant != null) {
    moteur.recevoirDonnees(
      PaquetDonnees(
        sujet: sujetProtocolePedagogique,
        charge: messageVersOctets(
          MessagePedagogique(
            type: typeParoleSalle,
            sessionId: _seance,
            emetteurProfilId: 't1',
            charge: <String, dynamic>{'profil': recitant, 'prenom': 'Sara'},
            emisLeUtc: DateTime.utc(2026, 11, 12, 10),
          ),
        ),
        fiable: true,
        emetteurIdentite: 't1',
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }
  return moteur;
}

/// Le cadre de la grille de [id].
CadreVisage _cadre(WidgetTester tester, String id) => tester
    .widgetList<CadreVisage>(
      find.descendant(
        of: find.byKey(GrilleVisages.cle),
        matching: find.byType(CadreVisage),
      ),
    )
    .singleWhere((CadreVisage c) => c.personneId == id);

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('camaradesDepuisReponse', () {
    test('prenom seul, soi ecarte, lignes illisibles ecartees', () {
      expect(
        camaradesDepuisReponse(<Object?>[
          <String, Object?>{
            'profile_id': 'e1',
            'prenom': 'Yasmine',
            'est_moi': true,
          },
          <String, Object?>{
            'profile_id': 'e2',
            'prenom': ' Ilyes ',
            'est_moi': false,
          },
          <String, Object?>{'profile_id': 'e3', 'prenom': 'Ilyes'},
          <String, Object?>{'profile_id': '', 'prenom': 'X'},
          <String, Object?>{'profile_id': 'e4', 'prenom': ''},
          <String, Object?>{'profile_id': 5, 'prenom': 'Y'},
          'ligne',
        ]),
        <CamaradeSeance>[
          (id: 'e2', prenom: 'Ilyes'),
          (id: 'e3', prenom: 'Ilyes'),
        ],
      );
      expect(camaradesDepuisReponse(null), isEmpty);
      expect(camaradesDepuisReponse(<String, Object?>{}), isEmpty);
    });
  });

  for (final _Regard regard in <_Regard>[_Regard.enfant, _Regard.adulte]) {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets('eleve ${regard.name} ${taille.width.toInt()} : prenoms, '
          'video du recitant et de l\'enseignant, photo des autres', (
        WidgetTester tester,
      ) async {
        await _monter(tester, regard, taille: taille);
        expect(tester.takeException(), isNull);

        // Chaque camarade a son prenom, jamais un nom de famille.
        expect(_cadre(tester, 'e2').nom, 'Ilyes');
        expect(_cadre(tester, 'e3').nom, 'Sara');
        // e2 a sa camera allumee, mais ne recite pas : aucune video.
        expect(_cadre(tester, 'e2').image, isNull);
        // e3 recite : sa video ; l'enseignant : la sienne.
        expect(_cadre(tester, 'e3').image, isNotNull);
        expect(_cadre(tester, 't1').image, isNotNull);
      });
    }
  }

  testWidgets('eleve : sans recitation, aucun camarade en video', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Regard.enfant, recitant: null);
    expect(_cadre(tester, 'e2').image, isNull);
    expect(_cadre(tester, 'e3').image, isNull);
    expect(_cadre(tester, 't1').image, isNotNull);
    expect(_cadre(tester, 'e2').nom, 'Ilyes');
  });

  for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
    testWidgets('enseignant ${taille.width.toInt()} : rien ne change, toutes '
        'les cameras des eleves', (WidgetTester tester) async {
      await _monter(tester, _Regard.enseignant, taille: taille);
      expect(tester.takeException(), isNull);
      for (final String id in <String>['e1', 'e2', 'e3']) {
        expect(_cadre(tester, id).image, isNotNull, reason: id);
      }
    });
  }

  // Captures R3 : CAPTURE_DIR=docs/current/captures/E2E/camarades.
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, Size taille, ThemeMode theme, AppLocale langue)
        in <(String, Size, ThemeMode, AppLocale)>[
          (
            'grille-eleve-enfant-390-clair',
            Size(390, 844),
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'grille-eleve-enfant-1440-clair',
            Size(1440, 900),
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'grille-eleve-enfant-1440-sombre',
            Size(1440, 900),
            ThemeMode.dark,
            AppLocale.fr,
          ),
          (
            'grille-eleve-enfant-390-arabe',
            Size(390, 844),
            ThemeMode.light,
            AppLocale.ar,
          ),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        await _monter(tester, _Regard.enfant, taille: taille, theme: theme);
        // L'annonce passagere du geste (« Sara recite ») s'efface seule.
        await tester.pump(AppMouvement.annonceGesteMaintien);
        await tester.pumpAndSettle();
        await capturer(tester, nom);
      });
    }
  }, skip: sautSansCapture);
}
