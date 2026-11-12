// BIBLIOTHEQUE-SALLE (directeur, 12/11/2026, point 10) : le bouton du milieu
// de la scene s'appelle « Bibliotheque » et fait le geste de la Bibliotheque
// de l'appareil : le panneau de droite sur ordinateur, le tiroir « Bibliotheque
// et outils » (« Plus ») sous 840 points. Rien ne s'ouvre au milieu.
//
// Captures R3 seulement avec CAPTURE_DIR.

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
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/media_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_bibliotheque_salle.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_enseignant.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';
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

ParticipantSalle _personne(String id, String role, bool local) =>
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
    (Ref _, String id) async => const ProfilEnseignant(
      prenom: 'Amina',
      identifiant: 'RA-26-t1',
      titre: 'sayyida',
    ),
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

/// La salle de l'enseignant, rien de presente : la scene et son bouton.
Future<void> _monter(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(moteur),
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', true),
    _personne('e1', 'student', false),
  ]);
  moteur.publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  final Finder bouton = find.byKey(ActionSousLaScene.cleBouton);
  final Finder coran = find.byKey(
    const ValueKey<String>('bibliotheque-support-coran'),
  );

  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    final String nom = '${taille.width.toInt()}';
    final bool ordinateur = taille.width >= 840;

    testWidgets('$nom : le bouton du milieu dit Bibliotheque', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille);
      expect(bouton, findsOneWidget);
      expect(
        find.descendant(
          of: bouton,
          matching: find.text(t.salle.seance.commandes.bibliotheque),
        ),
        findsOneWidget,
      );
      // Plus aucun « Ouvrir le Coran » au milieu.
      expect(find.text(t.salle.ouvrirCoran), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
      if (dossierCapture != null) {
        await capturerVue(tester, 'avant-$nom');
      }
    });

    testWidgets('$nom : le toucher ouvre l etagere, rien au milieu, '
        'le Coran en premier', (WidgetTester tester) async {
      await _monter(tester, taille);
      if (ordinateur) {
        // Defaut du 1440 : la Bibliotheque est deja ouverte ; on la ferme par
        // sa croix pour prouver que le bouton la rouvre.
        await tester.tap(
          find.byKey(const ValueKey<String>('bibliotheque-fermer')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PanneauBibliothequeSalle), findsNothing);
        if (dossierCapture != null) {
          await capturerVue(tester, 'avant-$nom-panneau-ferme');
        }
      } else {
        expect(find.byType(PanneauBibliothequeSalle), findsNothing);
      }
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      // L'etagere existante, au bon endroit : panneau (ordinateur) ou tiroir
      // (telephone).
      expect(find.byType(PanneauBibliothequeSalle), findsOneWidget);
      if (!ordinateur) {
        expect(find.byKey(TiroirCommandesTelephone.cle), findsOneWidget);
      }
      // Rien au milieu : ni feuille, ni boite, ni choix de sourate.
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      // Le Coran, premier (et seul) document, a un geste.
      expect(coran, findsOneWidget);
      final Iterable<Element> documents = find
          .byWidgetPredicate(
            (Widget w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'bibliotheque-support-',
                ),
          )
          .evaluate();
      expect(
        (documents.first.widget.key! as ValueKey<String>).value,
        'bibliotheque-support-coran',
      );
      expect(tester.takeException(), isNull);
      if (dossierCapture != null) {
        await capturerVue(tester, 'apres-$nom');
      }
    });
  }
}
