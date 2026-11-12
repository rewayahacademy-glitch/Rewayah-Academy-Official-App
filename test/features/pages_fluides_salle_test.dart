// PAGES-FLUIDES (directeur, 12/11/2026, apres une vraie seance) :
// (12) « Les pages du Coran et de tout document sont trop pres des bords. Il
// faut un cadre et des marges, pour lire sans que ca coince sur les cotes,
// et pour laisser la place aux informations. »
//
// Dans la vraie page `/salle` (`SallePage`, faux moteur du harnais) : a
// 390 x 844 et a 1440 x 900, la page presentee a une marge laterale d'au
// moins 16 dans sa boite, une reserve en haut et en bas, un arrondi, et rien
// ne deborde. Ce n'est pas la preuve en production.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_enseignant/page_coran_salle.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';
import '../support/mushaf_15l.dart' show surchargesMadina15;
import '../teaching_core/e/faux/faux_classe.dart';

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

List<Override> _surcharges(String role, FauxMoteurSalle moteur) => <Override>[
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
        _ligne('e1', 'Yasmine', 'student'),
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
];

/// Monte `/salle` pour [role] dans la fenetre [taille], la page 42 du
/// Coran presentee a la classe (aussi employe par la capture du lot).
Future<FauxMoteurSalle> monterSalleAvecPage(
  WidgetTester tester, {
  required String role,
  required Size taille,
  ThemeMode theme = ThemeMode.light,
  double densite = 1,
}) async {
  fixerVueCapture(tester, taille, densite);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: _seance),
      surcharges: _surcharges(role, moteur),
      themeMode: theme,
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
  return moteur;
}

/// La largeur utile de la page composee : celle d'une ligne de texte.
double largeurUtilePage(WidgetTester tester) =>
    tester.getSize(find.byKey(cleLigneMadina15(3))).width;

void main() {
  for (final (String nom, Size taille) in <(String, Size)>[
    ('telephone 390 x 844', const Size(390, 844)),
    ('ordinateur 1440 x 900', const Size(1440, 900)),
  ]) {
    for (final String role in <String>['teacher', 'student']) {
      testWidgets('$role, $nom : la page a un cadre et des marges', (
        WidgetTester tester,
      ) async {
        await monterSalleAvecPage(tester, role: role, taille: taille);
        expect(tester.takeException(), isNull);
        expect(find.byKey(PageCoranSalle.cle), findsOneWidget);

        final Rect fond = tester.getRect(
          find.byKey(TelephonePleinEcran.cleFondPage),
        );
        final Rect cadre = tester.getRect(
          find.byKey(SurfacePageFixe.cleCadrePlein),
        );
        // Une marge laterale reelle (16 au moins), de chaque cote.
        expect(cadre.left - fond.left, greaterThanOrEqualTo(AppSpacing.lg));
        expect(fond.right - cadre.right, greaterThanOrEqualTo(AppSpacing.lg));
        // Une reserve en haut et en bas.
        expect(cadre.top - fond.top, greaterThanOrEqualTo(AppSpacing.md));
        expect(fond.bottom - cadre.bottom, greaterThanOrEqualTo(AppSpacing.md));
        // Rien ne sort de la fenetre.
        expect(cadre.left, greaterThanOrEqualTo(AppSpacing.lg));
        expect(cadre.right, lessThanOrEqualTo(taille.width - AppSpacing.lg));
        // La page arrondie.
        final ClipRRect clip = tester.widget<ClipRRect>(
          find.byKey(SurfacePageFixe.cleCadrePlein),
        );
        expect(clip.borderRadius, arrondiPageSalle);
        // Le texte tient dans le cadre.
        final Rect ligne = tester.getRect(find.byKey(cleLigneMadina15(3)));
        expect(ligne.left, greaterThanOrEqualTo(cadre.left - 0.5));
        expect(ligne.right, lessThanOrEqualTo(cadre.right + 0.5));
        debugPrint(
          'PAGES-FLUIDES $role $nom : cadre ${cadre.width.toStringAsFixed(1)}'
          ' x ${cadre.height.toStringAsFixed(1)}, largeur utile du texte '
          '${largeurUtilePage(tester).toStringAsFixed(1)}',
        );
      });
    }
  }
}
