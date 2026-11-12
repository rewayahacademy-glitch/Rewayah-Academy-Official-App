// VISAGES (directeur, 12/11/2026, point 8 de
// docs/current/salle/PLAN-RETOURS-2026-11-12.md) : le fond doux de la salle,
// a travers la vraie page `/salle` (`SallePage`) et le faux moteur du
// harnais. Le visuel de l'ouverture (symbole et porte de lumiere) se pose
// derriere la grille en mode Classe, et jamais quand un document est
// presente.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/cadre_visage.dart';
import 'package:rewayah_academy/core/widgets/grille_visages.dart';
import 'package:rewayah_academy/core/widgets/porte_lumiere.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/scene_classe.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart'
    show TelephonePleinEcran;

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';
import '../../support/mushaf_15l.dart' show surchargesMadina15;
import '../../teaching_core/e/faux/faux_classe.dart';

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'teacher',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: true,
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
      seanceId: 's1',
      profilId: id,
      role: role,
      prenom: prenom,
      identifiantImmuable: 'RA-26-$id',
      etat: EtatPresence.presente,
      consolide: false,
      entreLe: DateTime.now(),
    );

List<Override> _surcharges(FauxMoteurSalle moteur) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: 't1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(FauxServiceVideo(acces0: _acces())),
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

/// Monte la salle de l'enseignant a 1440 x 900, trois cameras allumees, sans
/// rien presenter (mode Classe).
Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  Size taille = const Size(1440, 900),
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle()
    ..avecImage.addAll(<String>{'t1', 'e1', 'e2'});
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(moteur),
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', local: true),
    _personne('e1', 'student'),
    _personne('e2', 'student'),
  ]);
  await tester.pumpAndSettle();
  return moteur;
}

Future<void> _presenter(WidgetTester tester, FauxMoteurSalle moteur) async {
  await moteur.presenterContenu(
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

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final (Size taille, ThemeMode theme) in const <(Size, ThemeMode)>[
    (Size(1440, 900), ThemeMode.light),
    (Size(1440, 900), ThemeMode.dark),
    (Size(390, 844), ThemeMode.light),
  ]) {
    testWidgets('mode Classe ${taille.width.toInt()} ${theme.name} : le fond '
        'doux derriere la grille ; mode Document : aucun fond', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = await _monter(
        tester,
        theme: theme,
        taille: taille,
      );
      expect(tester.takeException(), isNull);
      final Finder fond = find.byKey(SceneClasse.cleFond);
      expect(find.byKey(GrilleVisages.cle), findsOneWidget);
      expect(fond, findsOneWidget);
      // Le visuel de l'ouverture, pose par le composant de la marque.
      expect(
        find.descendant(of: fond, matching: find.byType(PorteLumiere)),
        findsOneWidget,
      );
      // Tres faible opacite, image seule (aucun texte dessous).
      final double opacite = tester.widget<Opacity>(fond).opacity;
      expect(opacite, lessThanOrEqualTo(0.12));
      expect(opacite, greaterThan(0));
      expect(
        find.descendant(of: fond, matching: find.byType(RichText)),
        findsNothing,
      );
      // SOUS les visages : aucun cadre n'est dans le fond (ils sont peints
      // apres lui, dans la meme scene).
      expect(
        find.descendant(of: fond, matching: find.byType(CadreVisage)),
        findsNothing,
      );
      expect(find.byType(CadreVisage), findsWidgets);

      if (taille.width >= 840) {
        await _presenter(tester, moteur);
        expect(tester.takeException(), isNull);
        expect(find.byKey(TelephonePleinEcran.clePage), findsOneWidget);
        expect(fond, findsNothing);
      }
    });
  }
}
