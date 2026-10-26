// Plan de composition du 26/10/2026, §4 (PR B) : la salle de l'enseignant au
// telephone, a 390 x 844 et 360 x 780, texte x1 et x2, francais et arabe.
//
// Au repos, la page seule et « Commandes » en bas ; au toucher, la capsule
// video en haut et la pilule micro, camera, quitter en bas ; « Commandes »
// deplie le tiroir (Support, Outils, Seance) ; « Eleves » ouvre la feuille.
// Rien ne se recouvre, aucun mot coupe, un seul bouton plein, cartes
// separees de 16.
//
// Captures 390 (repos, toucher, les trois onglets, eleves) seulement avec
// CAPTURE_DIR.

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
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/barre_outils_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart'
    show BoutonPlusAppel;
import 'package:rewayah_academy/features/salle_seance/panneau_bibliotheque_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_enseignant.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/garde_interface.dart';
import '../support/harnais.dart';
import '../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../teaching_core/e/faux/faux_classe.dart';

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

List<Override> _surcharges(String role, FauxMoteurSalle moteur) => <Override>[
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

const Size _telephone = Size(390, 844);
const Size _petit = Size(360, 780);

Future<void> _monter(
  WidgetTester tester, {
  String role = 'teacher',
  Size taille = _telephone,
  double texte = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(role, moteur),
      echelleTexte: texte,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', role == 'teacher'),
    _personne('e1', 'student', role == 'student'),
    _personne('e2', 'student', false),
  ]);
  await tester.pumpAndSettle();
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

/// Les commandes se masquent apres le delai : la salle revient au repos.
Future<void> _attendreLeRepos(WidgetTester tester) async {
  await tester.pump(AppMouvement.masquageSalle + const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Les commandes se masquent au delai : un toucher les ramene.
Future<void> _toucher(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();
}

/// Ouvre le tiroir des Commandes (le « Plus » de la pilule).
Future<void> _ouvrirTiroir(WidgetTester tester) async {
  await _toucher(tester);
  await tester.tap(find.byKey(BoutonPlusAppel.cle));
  await tester.pumpAndSettle();
}

/// Change d'onglet, que le selecteur du core soit en rangee segmentee ou,
/// faute de place (360 en texte x2), en menu deroulant (ONGLETS-1).
Future<void> _onglet(WidgetTester tester, String libelle) async {
  final Finder menu = find.byType(MenuFiltre<OngletTiroir>);
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(libelle).hitTestable().last);
  await tester.pumpAndSettle();
  // Le menu se referme par sa route : son barrage absorbe les touchers tant
  // qu'elle s'efface.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

/// La pilule de l'appel posee en bas de la salle, hors du panneau [dedans]
/// (l'onglet Seance du tiroir porte la sienne, sous la meme cle).
Finder _piluleDuBas(WidgetTester tester, Finder dedans) {
  final Rect panneau = tester.getRect(dedans);
  return find.byWidgetPredicate((Widget w) {
    if (w.key != const ValueKey<String>('dock-seance')) return false;
    final Rect r = tester.getRect(find.byWidget(w));
    return r.top >= panneau.bottom - 0.5;
  });
}

bool _carte(Widget w) {
  final Key? cle = w.key;
  if (cle is! ValueKey<String>) return false;
  return cle.value.startsWith('eleve-') ||
      cle.value.startsWith('bibliotheque-support-');
}

void main() {
  setUpAll(() async {
    if (dossierCapture == null) return;
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group(langue.languageCode, () {
      setUp(() => LocaleSettings.setLocale(langue));
      for (final Size taille in <Size>[_telephone, _petit]) {
        for (final double texte in <double>[1, 2]) {
          final String nom =
              '${taille.width.toInt()}x${taille.height.toInt()}, '
              'texte x${texte.toInt()}';

          testWidgets('$nom : au repos, la page et « Commandes » ; au '
              'toucher, la capsule et la pilule', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            expect(find.byType(SalleOrdinateur), findsNothing);
            // Au repos (les commandes masquees) : « Commandes » seul en bas.
            await _attendreLeRepos(tester);
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesRepos),
              findsOneWidget,
            );
            expect(find.byKey(TiroirCommandesTelephone.cle), findsNothing);
            // La pilule reste montee, masquee : rien ne s'y touche.
            expect(find.byKey(BoutonPlusAppel.cle).hitTestable(), findsNothing);
            await _toucher(tester);
            // Au toucher : la capsule, la pilule, et « Commandes » dedans.
            expect(find.byKey(CapsuleVideoTelephone.cle), findsOneWidget);
            expect(find.byKey(BoutonPlusAppel.cle), findsOneWidget);
            expect(tester.takeException(), isNull);
            verifierUnSeulBoutonPlein(tester);
            verifierSansChevauchement(tester, <Finder>[
              find.byKey(CapsuleVideoTelephone.cle),
              find.byKey(const ValueKey<String>('dock-seance')),
            ]);
          });

          testWidgets('$nom : le tiroir, ses trois onglets, rien ne se '
              'recouvre', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _ouvrirTiroir(tester);
            final Finder tiroir = find.byKey(TiroirCommandesTelephone.cle);
            expect(tiroir, findsOneWidget);
            // Support : la Bibliotheque, sans sa croix (le tiroir a
            // « Reduire »).
            expect(find.byType(PanneauBibliothequeSalle), findsOneWidget);
            expect(
              find.byKey(const ValueKey<String>('bibliotheque-fermer')),
              findsNothing,
            );
            // Outils : les tuiles nommees.
            await _onglet(tester, t.salle.seance.commandes.ongletOutils);
            expect(
              find.byKey(TiroirCommandesTelephone.cleOutils),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey<String>('bouton-tableau')),
              findsOneWidget,
            );
            // Seance : micro, camera, eleves, quitter.
            await _onglet(tester, t.salle.seance.commandes.ongletSeance);
            expect(
              find.byKey(TiroirCommandesTelephone.cleSeance),
              findsOneWidget,
            );
            expect(
              find.byKey(TiroirCommandesTelephone.cleEleves),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            verifierAucunMotCoupe(tester, tiroir);
            // Le tiroir ne recouvre jamais la pilule de l'appel (celle du
            // bas : l'onglet Seance porte la sienne, dans le tiroir).
            verifierSansChevauchement(tester, <Finder>[
              tiroir,
              _piluleDuBas(tester, tiroir),
            ]);
            verifierUnSeulBoutonPlein(tester);
          });

          testWidgets('$nom : les eleves en feuille, cartes qui se deplient', (
            WidgetTester tester,
          ) async {
            await _monter(tester, taille: taille, texte: texte);
            await _toucher(tester);
            // Le bouton rond « Eleves » du haut, et la tuile de l'onglet
            // Seance, ouvrent la meme feuille.
            await tester.tap(
              find.byKey(const ValueKey<String>('salle-eleves')),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(FeuilleElevesTelephone.cle), findsOneWidget);
            expect(find.byType(PanneauEleves), findsOneWidget);
            expect(find.text('Yasmine'), findsWidgets);
            // La carte d'un eleve se deplie sur place (comme sur ordinateur).
            await tester.tap(find.text('Yasmine').first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(verifierAucuneCarteCollee(tester, estCarte: _carte), 2);
            final Finder feuille = find.byKey(FeuilleElevesTelephone.cle);
            verifierSansChevauchement(tester, <Finder>[
              feuille,
              _piluleDuBas(tester, feuille),
            ]);
          });
        }
      }
    });
  }

  testWidgets('eleve au telephone : ni capsule, ni tiroir, ni « Commandes »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: 'student');
    await _toucher(tester);
    expect(find.byKey(CapsuleVideoTelephone.cle), findsNothing);
    expect(find.byKey(TelephonePleinEcran.cleCommandesRepos), findsNothing);
    expect(find.byKey(TiroirCommandesTelephone.cle), findsNothing);
    expect(find.byType(PanneauEleves), findsNothing);
  });

  testWidgets('la barre d ecriture tient dans le tiroir : les dix couleurs '
      'restent atteignables', (WidgetTester tester) async {
    await _monter(tester);
    await _ouvrirTiroir(tester);
    await _onglet(tester, t.salle.seance.commandes.ongletOutils);
    await tester.tap(
      find
          .byKey(const ValueKey<String>('salle-outil-${'ecrire'}'))
          .hitTestable()
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(BarreOutilsSalle), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Chaque couleur reste atteignable : la rangee defile au doigt.
    final Finder couleurs = find.byKey(
      const ValueKey<String>('barre-outils-couleurs'),
    );
    expect(couleurs, findsOneWidget);
    final Finder derniere = find.byKey(
      const ValueKey<String>('barre-couleur-marron'),
    );
    expect(derniere, findsOneWidget);
    final Finder defilement = find.ancestor(
      of: couleurs,
      matching: find.byType(Scrollable),
    );
    expect(defilement, findsWidgets);
    await tester.drag(couleurs, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(derniere.hitTestable(), findsOneWidget);
  });

  testWidgets('captures 390', (WidgetTester tester) async {
    if (dossierCapture == null) return;
    await _monter(tester);
    await _attendreLeRepos(tester);
    await capturerVue(tester, 'salle-390-repos');
    await _toucher(tester);
    await capturerVue(tester, 'salle-390-toucher');
    await tester.tap(find.byKey(BoutonPlusAppel.cle));
    await tester.pumpAndSettle();
    await capturerVue(tester, 'salle-390-commandes-support');
    await _onglet(tester, t.salle.seance.commandes.ongletOutils);
    await capturerVue(tester, 'salle-390-commandes-outils');
    await _onglet(tester, t.salle.seance.commandes.ongletSeance);
    await capturerVue(tester, 'salle-390-commandes-seance');
    await tester.tap(find.byKey(const ValueKey<String>('salle-eleves')));
    await tester.pumpAndSettle();
    await capturerVue(tester, 'salle-390-eleves');
  });
}
