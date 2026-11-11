// Lot RUBAN-TELEPHONE (directeur, 11/11/2026 : « il faut que tout soit bien
// coordonne et ne pas agir comme des entites differentes »), la seconde
// moitie du modele des modes d'affichage (docs/current/salle/
// MODES-AFFICHAGE.md §2, §3, §4, §5), dans la vraie salle (`SallePage`) :
// - une personne, un cadre : jamais deux cadres de la meme personne, pour
//   les quatre roles, en mode Classe et Document, a 390, 820 et 1440 ;
// - un seul cadre partout : la vignette et la capsule passent par
//   `CadreVisage` ;
// - eleve au telephone : un seul cadre, l'enseignant, meme quand un camarade
//   recite ; ecran large : le recitant dans la bande de cote, hors de la page ;
// - enseignant au telephone : la capsule montre le recitant en mode Document ;
// - seul dans la salle : son propre cadre sous l'attente, camera allumee ;
// - les passages entre modes : depart, arrivee, interrompu, mouvement reduit,
//   rien ne se rejoue au masquage ni a une reconnexion ;
// - les phrases d'etat de l'eleve passent en haut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/passage_visages.dart';
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
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/scene_classe.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart'
    show typeParoleSalle;
import 'package:rewayah_academy/features/salle_seance/media_salle.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_enseignant.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';
import '../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../teaching_core/e/faux/faux_classe.dart';

const String _seance = 's1';

AccesSalle _acces(String role, {bool differee = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher' || role == 'student',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  publicationDifferee: differee,
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

String _profil(String role) => switch (role) {
  'teacher' => 't1',
  'guardian_observer' => 'g1',
  'masked_controller' => 'c1',
  _ => 'e1',
};

ParticipantSalle _personne(
  String id,
  String role, {
  required bool local,
  bool camera = true,
}) => ParticipantSalle(
  identite: id,
  nom: '',
  role: role,
  estLocal: local,
  micro: false,
  camera: camera,
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

List<Override> _surcharges(
  String role,
  FauxMoteurSalle moteur, {
  bool differee = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: switch (role) {
          'teacher' => AppRole.teacher,
          'guardian_observer' => AppRole.guardian,
          'masked_controller' => AppRole.controller,
          _ => AppRole.student,
        },
        profileId: _profil(role),
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideo(acces0: _acces(role, differee: differee)),
  ),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(
    FauxServicePresence(
      lignes: <PresenceParticipant>[
        _ligne('t1', 'Amina', 'teacher'),
        _ligne('e1', 'Yasmine', 'student'),
        _ligne('e2', 'Ilyes', 'student'),
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

/// La classe : l'enseignant, deux eleves, et la personne devant l'ecran.
List<ParticipantSalle> _classe(String role, {bool seul = false}) {
  final String moi = _profil(role);
  return <ParticipantSalle>[
    if (!seul) ...<ParticipantSalle>[
      _personne('t1', 'teacher', local: moi == 't1'),
      _personne('e1', 'student', local: moi == 'e1'),
      _personne('e2', 'student', local: false),
    ],
    if (seul || (moi != 't1' && moi != 'e1'))
      _personne(moi, role, local: true, camera: seul || role == 'student'),
  ];
}

Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  required String role,
  Size taille = const Size(390, 844),
  ThemeMode theme = ThemeMode.light,
  bool document = true,
  bool seul = false,
  bool cameraSeul = true,
  bool differee = false,
  bool mouvementReduit = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  if (mouvementReduit) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final FauxMoteurSalle moteur = FauxMoteurSalle()
    ..avecImage.addAll(<String>['t1', 'e1', 'e2', 'g1', 'c1']);
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: _seance),
      surcharges: _surcharges(role, moteur, differee: differee),
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  final List<ParticipantSalle> classe = seul
      ? <ParticipantSalle>[
          _personne(_profil(role), role, local: true, camera: cameraSeul),
        ]
      : _classe(role);
  moteur.publier(classe);
  moteur.publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
  if (document) await _presenter(tester, moteur);
  return moteur;
}

ContenuPresente get _page42 => ContenuPresente(
  page: 42,
  sourate: 2,
  verset: 255,
  presentePar: 't1',
  emisLe: DateTime.now(),
);

Future<void> _presenter(WidgetTester tester, FauxMoteurSalle moteur) async {
  moteur.publierContenu(_page42);
  await tester.pumpAndSettle();
}

/// L'enseignant donne la parole a [profil] (recu par la classe).
Future<void> _parole(
  WidgetTester tester,
  FauxMoteurSalle moteur,
  String profil,
  String prenom,
) async {
  moteur.recevoirDonnees(
    PaquetDonnees(
      sujet: sujetProtocolePedagogique,
      charge: messageVersOctets(
        MessagePedagogique(
          type: typeParoleSalle,
          sessionId: _seance,
          emetteurProfilId: 't1',
          charge: <String, dynamic>{'profil': profil, 'prenom': prenom},
          emisLeUtc: DateTime.utc(2026, 11, 11, 10),
        ),
      ),
      fiable: true,
      emetteurIdentite: 't1',
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

/// Un toucher de l'ecran : les commandes reviennent.
Future<void> _toucher(WidgetTester tester) async {
  await tester.tapAt(const Offset(4, 4));
  await tester.pumpAndSettle();
}

/// Les cadres a l'ecran, par personne.
Map<String, int> _cadresParPersonne(WidgetTester tester) {
  final Map<String, int> n = <String, int>{};
  for (final CadreVisage c in tester.widgetList<CadreVisage>(
    find.byType(CadreVisage),
  )) {
    final String id = c.personneId ?? c.nom;
    n[id] = (n[id] ?? 0) + 1;
  }
  return n;
}

void _verifierUnCadreParPersonne(WidgetTester tester, String contexte) {
  final Map<String, int> n = _cadresParPersonne(tester);
  for (final MapEntry<String, int> e in n.entries) {
    expect(e.value, 1, reason: '$contexte : ${e.key} a ${e.value} cadres');
  }
}

const List<String> _roles = <String>[
  'teacher',
  'student',
  'guardian_observer',
  'masked_controller',
];
const List<Size> _tailles = <Size>[
  Size(390, 844),
  Size(820, 1180),
  Size(1440, 900),
];

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Une personne, un cadre (MODES-AFFICHAGE §2, regle 1)', () {
    for (final String role in _roles) {
      for (final Size taille in _tailles) {
        final String nom = '$role ${taille.width.toInt()}';
        testWidgets('$nom : mode Classe', (WidgetTester tester) async {
          await _monter(tester, role: role, taille: taille, document: false);
          await _toucher(tester);
          _verifierUnCadreParPersonne(tester, '$nom classe');
          expect(find.byType(CadreVisage), findsWidgets);
          expect(tester.takeException(), isNull);
        });
        testWidgets('$nom : mode Document, un eleve recite', (
          WidgetTester tester,
        ) async {
          final FauxMoteurSalle moteur = await _monter(
            tester,
            role: role,
            taille: taille,
          );
          if (role != 'teacher') await _parole(tester, moteur, 'e2', 'Ilyes');
          await _toucher(tester);
          _verifierUnCadreParPersonne(tester, '$nom document');
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Le ruban chez l eleve (MODES-AFFICHAGE §4)', () {
    testWidgets('390 : un seul cadre, l enseignant, meme quand un camarade '
        'recite ; c est LE cadre de la salle', (WidgetTester tester) async {
      final FauxMoteurSalle moteur = await _monter(tester, role: 'student');
      await _toucher(tester);
      expect(_cadresParPersonne(tester), <String, int>{'t1': 1});
      await _parole(tester, moteur, 'e2', 'Ilyes');
      await _toucher(tester);
      expect(_cadresParPersonne(tester), <String, int>{'t1': 1});
      expect(find.byKey(cleRecitantBande), findsNothing);
      // La vignette est une enveloppe de CadreVisage, et garde ses gestes.
      expect(
        find.descendant(
          of: find.byKey(VignetteAimantee.cle),
          matching: find.byType(CadreVisage),
        ),
        findsOneWidget,
      );
      expect(find.byKey(VignetteAimantee.clePoignee), findsOneWidget);
    });

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('1440 ${sens.name} : l enseignant, puis le recitant dans la '
          'bande de cote, hors de la page', (WidgetTester tester) async {
        if (sens == TextDirection.rtl) {
          LocaleSettings.setLocaleSync(AppLocale.ar);
        }
        final FauxMoteurSalle moteur = await _monter(
          tester,
          role: 'student',
          taille: const Size(1440, 900),
        );
        await _parole(tester, moteur, 'e2', 'Ilyes');
        await _toucher(tester);
        expect(_cadresParPersonne(tester), <String, int>{'t1': 1, 'e2': 1});
        final Finder recitant = find.byKey(cleRecitantBande);
        expect(recitant, findsOneWidget);
        expect(
          tester
              .widget<CadreVisage>(
                find.descendant(
                  of: recitant,
                  matching: find.byType(CadreVisage),
                ),
              )
              .personneId,
          'e2',
        );
        final Rect r = tester.getRect(recitant);
        final Rect page = tester.getRect(
          find.byKey(TelephonePleinEcran.clePage),
        );
        expect(r.overlaps(page), isFalse, reason: 'rien ne recouvre la page');
        final Rect prof = tester.getRect(find.byKey(VignetteAimantee.cle));
        expect(prof.overlaps(r), isFalse);
        // Bande de debut pour le recitant, bande de fin pour l'enseignant.
        if (sens == TextDirection.ltr) {
          expect(r.right, lessThanOrEqualTo(page.left));
          expect(prof.left, greaterThanOrEqualTo(page.right));
        } else {
          expect(r.left, greaterThanOrEqualTo(page.right));
          expect(prof.right, lessThanOrEqualTo(page.left));
        }
        // Meme taille que l'enseignant.
        expect(r.width, moreOrLessEquals(prof.width, epsilon: 1));
      });
    }
  });

  group('La capsule de l enseignant au telephone (D-027, §4)', () {
    Widget hote({String? recitant, TextDirection sens = TextDirection.ltr}) {
      const VueSeance vue = VueSeance(
        role: RoleSeance.enseignant,
        nomEnseignant: 'Amina',
        initialesEnseignant: 'A',
        nomClasse: 'Classe',
        signalEnseignant: 3,
      );
      return hoteCapture(
        Directionality(
          textDirection: sens,
          child: PorteeMediaSalle(
            identiteVignette: 't1',
            identiteRecitant: recitant,
            onBasculerScene: () {},
            cadre:
                (
                  String id, {
                  String? libelleNom,
                  Widget? coin,
                  bool detache = false,
                }) => CadreVisage(
                  nom: id == 't1' ? 'Vous' : 'Ilyes',
                  prenom: id,
                  personneId: id,
                  libelleNom: libelleNom,
                  coin: coin,
                ),
            child: Center(
              child: CapsuleVideoTelephone(
                vue: vue,
                onDeplier: () {},
                onReduireSalle: () {},
                recitant: recitant,
              ),
            ),
          ),
        ),
      );
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${sens.name} : reduire, le cadre, voir la classe ; cibles '
          'de 48, ecarts egaux', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 1);
        await tester.pumpWidget(hote(sens: sens));
        await tester.pumpAndSettle();
        final Rect reduire = tester.getRect(
          find.byKey(CapsuleVideoTelephone.cleReduireSalle),
        );
        final Rect cadre = tester.getRect(
          find.byKey(CapsuleVideoTelephone.cleDeplier),
        );
        final Rect voir = tester.getRect(
          find.byKey(CapsuleVideoTelephone.cleVoir),
        );
        for (final Rect r in <Rect>[reduire, voir]) {
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
        }
        final bool ltr = sens == TextDirection.ltr;
        // Ordre de lecture : reduire, cadre, voir la classe.
        expect(
          ltr ? reduire.right <= cadre.left : reduire.left >= cadre.right,
          isTrue,
        );
        expect(
          ltr ? cadre.right <= voir.left : cadre.left >= voir.right,
          isTrue,
        );
        final double e1 = ltr
            ? cadre.left - reduire.right
            : reduire.left - cadre.right;
        final double e2 = ltr
            ? voir.left - cadre.right
            : cadre.left - voir.right;
        expect(e1, moreOrLessEquals(e2, epsilon: 0.5));
        // Le cadre de la salle, l'enseignant lui-meme, ses barres dedans.
        final CadreVisage c = tester.widget(find.byType(CadreVisage));
        expect(c.personneId, 't1');
        expect(find.byKey(CadreVisage.cleCoin), findsOneWidget);
      });
    }

    testWidgets('mode Document, un eleve recite : la capsule le montre, sans '
        'les barres du lien de l enseignant', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(hote(recitant: 'e2'));
      await tester.pumpAndSettle();
      final CadreVisage c = tester.widget(find.byType(CadreVisage));
      expect(c.personneId, 'e2');
      expect(c.libelleNom, startsWith('Vidéo'));
      expect(find.byKey(CadreVisage.cleCoin), findsNothing);
    });

    testWidgets('dans la vraie salle : mode Classe, la capsule montre '
        'l enseignant (le recitant est dans la grille)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, role: 'teacher', document: false);
      await _toucher(tester);
      final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
      expect(capsule, findsOneWidget);
      expect(
        tester
            .widget<CadreVisage>(
              find.descendant(of: capsule, matching: find.byType(CadreVisage)),
            )
            .personneId,
        't1',
      );
      _verifierUnCadreParPersonne(tester, 'enseignant classe');
    });
  });

  group('Seul dans la salle (§3, precise le 11/11)', () {
    testWidgets('eleve, camera allumee : son cadre sous l attente, a la '
        'largeur du bloc (directeur, 11/11 soir), dans la mise en page', (
      WidgetTester tester,
    ) async {
      await _monter(tester, role: 'student', document: false, seul: true);
      final Finder moi = find.byKey(SceneClasse.cleMoiSeul);
      expect(moi, findsOneWidget);
      // Les memes bords que le bloc d'attente (marges de 24), borne comme
      // un cadre de la grille ; 4:3.
      final Rect bloc = tester.getRect(
        find.byKey(const ValueKey<String>('salle-attente')),
      );
      final Rect cadre = tester.getRect(moi);
      expect(cadre.width, lessThanOrEqualTo(SceneClasse.largeurMoiSeul));
      expect(cadre.center.dx, closeTo(bloc.center.dx, 1));
      if (bloc.width - 48 <= SceneClasse.largeurMoiSeul) {
        expect(cadre.left, closeTo(bloc.left + 24, 1));
        expect(cadre.right, closeTo(bloc.right - 24, 1));
      }
      expect(cadre.width / cadre.height, closeTo(4 / 3, 0.02));
      final Finder attente = find.byKey(
        const ValueKey<String>('salle-attente'),
      );
      expect(find.descendant(of: attente, matching: moi), findsOneWidget);
      expect(
        tester.getRect(moi).top,
        greaterThan(
          tester.getRect(find.text(t.salle.seulEnseignantDetail)).bottom,
        ),
      );
    });

    // Directeur, 11/11 (soir) : rien ne flotte, rien n'est coupe. A toute
    // taille d'ecran le cadre de soi tient en entier dans le bloc d'attente,
    // centre sur son axe, en 4:3 ; il touche les marges de cote (ecran
    // etroit) ou s'arrete a la marge du bas (ecran large et bas).
    for (final Size taille in const <Size>[
      Size(320, 568),
      Size(390, 844),
      Size(820, 1180),
      Size(1280, 720),
      Size(1440, 900),
    ]) {
      for (final String role in const <String>['student', 'teacher']) {
        final String nom =
            '$role ${taille.width.toInt()} x ${taille.height.toInt()}';
        testWidgets('$nom, seul, camera allumee : son cadre entier dans le '
            'bloc, jamais coupe', (WidgetTester tester) async {
          await _monter(
            tester,
            role: role,
            taille: taille,
            document: false,
            seul: true,
          );
          final Finder moi = find.byKey(SceneClasse.cleMoiSeul);
          if (dossierCapture != null && role == 'student') {
            await capturerVue(tester, 'seul-eleve-${taille.width.toInt()}');
          }
          expect(tester.takeException(), isNull);
          // Sur ordinateur, l'enseignant a deja son cadre dans le panneau
          // des Eleves : une personne, un cadre. Sur un tres petit
          // telephone, le plus petit cadre ne tient pas sous l'attente : pas
          // de cadre du tout, jamais un cadre coupe.
          if (moi.evaluate().isEmpty) {
            expect(
              role == 'teacher' || taille.height < 600,
              isTrue,
              reason: nom,
            );
            return;
          }
          final Rect bloc = tester.getRect(
            find.byKey(const ValueKey<String>('salle-attente')),
          );
          final Rect cadre = tester.getRect(moi);
          expect(cadre.center.dx, closeTo(bloc.center.dx, 1), reason: nom);
          expect(
            cadre.width,
            lessThanOrEqualTo(SceneClasse.largeurMoiSeul),
            reason: nom,
          );
          expect(cadre.width / cadre.height, closeTo(4 / 3, 0.02), reason: nom);
          expect(cadre.left, greaterThanOrEqualTo(bloc.left + 23), reason: nom);
          expect(
            cadre.bottom,
            lessThanOrEqualTo(bloc.bottom - 23),
            reason: '$nom : le cadre est coupe en bas',
          );
        });
      }
    }

    testWidgets('eleve, camera eteinte : l attente seule', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        role: 'student',
        document: false,
        seul: true,
        cameraSeul: false,
      );
      expect(find.byKey(SceneClasse.cleMoiSeul), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('salle-attente')),
        findsOneWidget,
      );
    });

    testWidgets('enseignant : son image est deja dans la capsule, aucun '
        'second cadre', (WidgetTester tester) async {
      await _monter(tester, role: 'teacher', document: false, seul: true);
      expect(find.byKey(SceneClasse.cleMoiSeul), findsNothing);
    });
  });

  group('Les passages entre modes (§5)', () {
    testWidgets('Classe vers Document : la grille part vers la vignette, la '
        'vignette et la page arrivent, puis plus rien ne bouge', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = await _monter(
        tester,
        role: 'student',
        document: false,
      );
      expect(find.byKey(cleGrilleSortante), findsNothing);
      moteur.publierContenu(_page42);
      await tester.pump();
      await tester.pump();
      // Depart : la grille qui part est la, elle ne recoit aucun geste.
      expect(find.byKey(cleGrilleSortante), findsOneWidget);
      expect(find.byKey(cleGrilleSortante).hitTestable(), findsNothing);
      // La page arrive en fondu : un voile du fond s'efface au-dessus d'elle,
      // sans recevoir de geste.
      expect(find.byKey(cleVoilePage), findsOneWidget);
      expect(find.byKey(cleVoilePage).hitTestable(), findsNothing);
      // A mi-chemin, elle a retreci.
      await tester.pump(AppMouvement.deplacementEntree ~/ 2);
      final Transform milieu = tester.widget<Transform>(
        find
            .descendant(
              of: find.ancestor(
                of: find.byKey(cleGrilleSortante),
                matching: find.byKey(PassageVisages.cle),
              ),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(milieu.transform.storage[0], lessThan(1));
      // Arrivee : la grille est retiree, la page et la vignette sont la.
      await tester.pumpAndSettle();
      expect(find.byKey(cleGrilleSortante), findsNothing);
      expect(find.byKey(cleVoilePage), findsNothing);
      expect(find.byKey(TelephonePleinEcran.clePage), findsOneWidget);
      // Le masquage des commandes ne rejoue rien.
      await tester.pump(
        AppMouvement.masquageSalle + const Duration(seconds: 1),
      );
      await tester.pump();
      expect(find.byKey(cleGrilleSortante), findsNothing);
      // Une reconnexion (la classe republiee) ne rejoue rien.
      moteur.poser(EtatSalle.reconnexion);
      await tester.pump();
      moteur.poser(EtatSalle.connecte);
      moteur.publier(_classe('student'));
      await tester.pump();
      expect(find.byKey(cleGrilleSortante), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Document vers Classe : la grille revient en grandissant, '
        'plus vite', (WidgetTester tester) async {
      await _monter(tester, role: 'student');
      await _toucher(tester);
      await tester.tap(find.byKey(const ValueKey<String>('vignette-en-grand')));
      await tester.pump();
      await tester.pump();
      final Finder passage = find.byKey(PassageVisages.cle);
      expect(passage, findsWidgets);
      // Fini aux deux tiers de l'aller.
      await tester.pump(AppMouvement.deplacementSortie);
      await tester.pumpAndSettle();
      expect(find.byKey(TelephonePleinEcran.clePage), findsNothing);
      _verifierUnCadreParPersonne(tester, 'retour en Classe');
      expect(tester.takeException(), isNull);
    });

    testWidgets('interrompu : retour en Classe pendant le depart, rien ne '
        'reste, une personne un cadre', (WidgetTester tester) async {
      final FauxMoteurSalle moteur = await _monter(
        tester,
        role: 'student',
        document: false,
      );
      moteur.publierContenu(_page42);
      await tester.pump();
      await tester.pump(AppMouvement.deplacementEntree ~/ 3);
      await _toucher(tester);
      final Finder enGrand = find.byKey(
        const ValueKey<String>('vignette-en-grand'),
      );
      if (enGrand.evaluate().isNotEmpty) {
        await tester.tap(enGrand.first);
      }
      await tester.pumpAndSettle();
      expect(find.byKey(cleGrilleSortante), findsNothing);
      _verifierUnCadreParPersonne(tester, 'interrompu');
      expect(tester.takeException(), isNull);
    });

    testWidgets('mouvement reduit : fondu seul, aucune echelle', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = await _monter(
        tester,
        role: 'student',
        document: false,
        mouvementReduit: true,
      );
      moteur.publierContenu(_page42);
      await tester.pump();
      await tester.pump();
      await tester.pump(AppMouvement.fonduEntree ~/ 2);
      for (final Transform tr in tester.widgetList<Transform>(
        find.descendant(
          of: find.byKey(PassageVisages.cle),
          matching: find.byType(Transform),
        ),
      )) {
        expect(tr.transform.storage[0], moreOrLessEquals(1));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(cleGrilleSortante), findsNothing);
    });
  });

  group('Les phrases d etat de l eleve passent en haut (cahier §8)', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} : le micro en attente, en haut, '
          'jamais sur la pilule du bas', (WidgetTester tester) async {
        await _monter(tester, role: 'student', taille: taille, differee: true);
        await _toucher(tester);
        final Finder statut = find.byKey(
          const ValueKey<String>('statut-micro-en-attente'),
        );
        expect(statut, findsOneWidget);
        expect(
          find.descendant(of: find.byKey(cleStatutEnHaut), matching: statut),
          findsOneWidget,
        );
        expect(tester.getRect(statut).top, lessThan(taille.height / 4));
        final Finder dock = find.byKey(const ValueKey<String>('dock-seance'));
        expect(find.descendant(of: dock, matching: statut), findsNothing);
      });
    }
  });
}
