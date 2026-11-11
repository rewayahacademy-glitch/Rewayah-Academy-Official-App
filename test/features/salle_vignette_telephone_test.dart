// Lot VIGNETTE-TELEPHONE (directeur, 11/11/2026 : « est-ce qu'on peut bouger
// les vignettes de video ou les cacher comme on le veut ? ... je parlais du
// mobile, telephone »). La vraie composition de l'eleve dans `/salle`
// (`TelephonePleinEcran`), page presentee par l'enseignant :
// - glisser la vignette au-dela d'un bord la range ; une languette reste sur
//   ce bord, a la hauteur du rangement ;
// - un glissement court ne range rien ; un appui la met toujours en grand ;
// - la poignee range d'un simple appui (WCAG 2.5.7), la languette la ramene
//   d'un appui ou d'un tirage ; clavier et lecteur d'ecran ;
// - l'etat range reste pendant la seance (masquage a 3 s, camera eteinte
//   puis rallumee) ; rien n'est envoye au serveur ;
// - arabe : les bords sont miroites ; 320 x 568, 390 x 844, 820 x 1180,
//   1440 x 900 ; texte x2 ; clair et sombre.
//
// Captures (docs/current/captures/E2E/vignette-telephone/) seulement avec
// CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/languette_bord.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';

import '../capture/outil_capture.dart';
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

ParticipantSalle _personne(
  String id,
  String role,
  bool local, {
  bool camera = false,
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
      seanceId: 's1',
      profilId: id,
      role: role,
      prenom: prenom,
      identifiantImmuable: 'RA-26-$id',
      etat: EtatPresence.presente,
      consolide: false,
      entreLe: DateTime.now(),
    );

List<Override> _surcharges(FauxMoteurSalle moteur, FauxServiceVideo video) =>
    <Override>[
      sourceSessionProvider.overrideWithValue(
        FausseSourceSession(
          const SessionState(
            resolue: true,
            role: AppRole.student,
            profileId: 'e1',
            accountStatus: AccountStatus.active,
            lectureProfil: LectureProfil.presente,
          ),
        ),
      ),
      servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
      serviceVideoProvider.overrideWithValue(video),
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

/// La salle de l'eleve, page presentee, camera de l'enseignant allumee ;
/// un toucher a ramene les commandes (la vignette est visible).
Future<({FauxMoteurSalle moteur, FauxServiceVideo video})> _monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  bool mouvementReduit = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  if (mouvementReduit) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  final FauxServiceVideo video = FauxServiceVideo(acces0: _acces('student'));
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(moteur, video),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(_classe(camera: true));
  moteur.publierQualite(QualiteLien.bonne);
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
  await _toucher(tester);
  return (moteur: moteur, video: video);
}

List<ParticipantSalle> _classe({required bool camera}) => <ParticipantSalle>[
  _personne('t1', 'teacher', false, camera: camera),
  _personne('e1', 'student', true),
];

/// Un toucher de l'ecran (hors d'un bouton) : les commandes reviennent.
Future<void> _toucher(WidgetTester tester) async {
  await tester.tapAt(const Offset(AppSpacing.xs, AppSpacing.xs));
  await tester.pumpAndSettle();
}

final Finder _vignette = find.byKey(VignetteAimantee.cle);
final Finder _poignee = find.byKey(VignetteAimantee.clePoignee);
final Finder _languette = find.byKey(VignetteAimantee.cleLanguette);
final Finder _page = find.byKey(TelephonePleinEcran.clePage);

/// Glisse la vignette vers le bord [droite] de [ecart] points (lentement :
/// seule la distance decide).
Future<void> _glisser(
  WidgetTester tester, {
  required bool droite,
  required double ecart,
}) async {
  await tester.timedDrag(
    _vignette,
    Offset(droite ? ecart : -ecart, 0),
    const Duration(seconds: 1),
  );
  await tester.pumpAndSettle();
}

void _verifierRangee(WidgetTester tester, Size ecran, {required bool droite}) {
  expect(_vignette, findsNothing, reason: 'la vignette est rangee');
  expect(_poignee, findsNothing);
  expect(_languette, findsOneWidget);
  final Rect r = tester.getRect(_languette);
  // La cible fait 48 sur 48 ; elle colle au bord et reste dans l'ecran.
  expect(r.width, closeTo(LanguetteBord.cible, toleranceGarde));
  expect(r.height, closeTo(LanguetteBord.cible, toleranceGarde));
  if (droite) {
    expect(r.right, closeTo(ecran.width, toleranceGarde));
  } else {
    expect(r.left, closeTo(0, toleranceGarde));
  }
  expect(r.top, greaterThanOrEqualTo(0));
  expect(r.bottom, lessThanOrEqualTo(ecran.height));
  // A l'oeil, la languette ne fait que 24 de large.
  final Rect visible = tester.getRect(
    find.descendant(
      of: _languette,
      matching: find.byKey(const ValueKey<String>('languette-visible')),
    ),
  );
  expect(visible.width, closeTo(LanguetteBord.largeurVisible, toleranceGarde));
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
    // L'arabe est une bibliotheque differee : chargee ici, hors du temps
    // simule des tests, puis choisie sans attente dans un test.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('390 : glisser au-dela du bord droit range la vignette, la '
      'languette reste a sa hauteur', (WidgetTester tester) async {
    const Size ecran = Size(390, 844);
    await _monter(tester);
    expect(_vignette, findsOneWidget);
    expect(_poignee, findsOneWidget);
    final Rect avant = tester.getRect(_vignette);
    await _glisser(tester, droite: true, ecart: 150);
    _verifierRangee(tester, ecran, droite: true);
    // La languette est a la hauteur de la vignette rangee.
    expect(
      tester.getRect(_languette).center.dy,
      closeTo(avant.center.dy, toleranceGarde + 1),
    );
    // La page n'a pas bouge : elle garde l'ecran entier.
    expect(tester.getSize(_page), ecran);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390 : un glissement court ne range pas, la vignette revient '
      'a son coin', (WidgetTester tester) async {
    await _monter(tester);
    final Rect avant = tester.getRect(_vignette);
    await _glisser(tester, droite: true, ecart: 30);
    expect(_languette, findsNothing);
    expect(_vignette, findsOneWidget);
    final Rect apres = tester.getRect(_vignette);
    expect(apres.left, closeTo(avant.left, 0.5));
    expect(apres.top, closeTo(avant.top, 0.5));
    // Meme lance vite, un glissement court ne range pas.
    await tester.fling(_vignette, const Offset(24, 0), 3000);
    await tester.pumpAndSettle();
    expect(_languette, findsNothing);
    expect(tester.getRect(_vignette).left, closeTo(avant.left, 0.5));
  });

  testWidgets('390 : un appui sur la vignette la met toujours en grand', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    expect(_page, findsOneWidget);
    await tester.tap(_vignette);
    await tester.pumpAndSettle();
    // La video passe en grand a la place de la page ; rien n'est range.
    expect(_page, findsNothing);
    expect(_languette, findsNothing);
  });

  testWidgets('390 : la poignee range d un appui, la languette ramene d un '
      'appui au coin le plus proche', (WidgetTester tester) async {
    const Size ecran = Size(390, 844);
    await _monter(tester);
    final Rect avant = tester.getRect(_vignette);
    await tester.tap(_poignee);
    await tester.pumpAndSettle();
    _verifierRangee(tester, ecran, droite: true);
    await tester.tap(_languette);
    await tester.pumpAndSettle();
    expect(_languette, findsNothing);
    expect(_vignette, findsOneWidget);
    final Rect apres = tester.getRect(_vignette);
    expect(apres.left, closeTo(avant.left, 0.5));
    expect(apres.top, closeTo(avant.top, 0.5));
  });

  testWidgets('390 : tirer la languette vers l interieur ramene la vignette ;'
      ' un tirage trop court la laisse rangee', (WidgetTester tester) async {
    const Size ecran = Size(390, 844);
    await _monter(tester);
    await _glisser(tester, droite: true, ecart: 150);
    _verifierRangee(tester, ecran, droite: true);
    // Tirage court et lent (au-dela du seuil du glisser, en deca de 24) :
    // elle reste rangee.
    await tester.timedDrag(
      _languette,
      const Offset(-20, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    _verifierRangee(tester, ecran, droite: true);
    // Tirage franc : elle revient au coin du haut, a droite.
    await tester.timedDrag(
      _languette,
      const Offset(-80, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(_languette, findsNothing);
    final Rect r = tester.getRect(_vignette);
    expect(r.right, closeTo(ecran.width - AppSpacing.lg, 0.5));
    expect(r.center.dy, lessThan(ecran.height / 2));
  });

  testWidgets('390 : rangee en bas, elle revient au coin du bas', (
    WidgetTester tester,
  ) async {
    const Size ecran = Size(390, 844);
    await _monter(tester);
    // D'abord au coin du bas a gauche, puis rangee a gauche.
    await tester.timedDrag(
      _vignette,
      const Offset(-250, 500),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(_vignette).center.dy, greaterThan(ecran.height / 2));
    await _glisser(tester, droite: false, ecart: 150);
    _verifierRangee(tester, ecran, droite: false);
    expect(tester.getRect(_languette).center.dy, greaterThan(ecran.height / 2));
    await tester.tap(_languette);
    await tester.pumpAndSettle();
    final Rect r = tester.getRect(_vignette);
    expect(r.left, closeTo(AppSpacing.lg, 0.5));
    expect(r.center.dy, greaterThan(ecran.height / 2));
  });

  testWidgets('390 : l etat range reste pendant la seance (masquage a 3 s, '
      'camera eteinte puis rallumee)', (WidgetTester tester) async {
    const Size ecran = Size(390, 844);
    final ({FauxMoteurSalle moteur, FauxServiceVideo video}) salle =
        await _monter(tester);
    final int demandes = salle.video.demandes.length;
    final int paquets = salle.moteur.donneesPubliees.length;
    await _glisser(tester, droite: true, ecart: 150);
    _verifierRangee(tester, ecran, droite: true);
    // Ranger la video ne touche qu'a l'affichage chez soi : rien n'est
    // envoye (ni a la salle, ni au serveur), aucune camera ni aucun micro
    // n'est demande.
    expect(salle.video.demandes.length, demandes);
    expect(salle.moteur.donneesPubliees.length, paquets);
    expect(salle.moteur.cameraDemandee, isEmpty);
    expect(salle.moteur.microDemande, isEmpty);
    expect(salle.moteur.departs, 0);
    // Au repos, la languette se masque avec les commandes : la page est
    // seule.
    await tester.pump(AppMouvement.ileMention + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pump(AppMouvement.masquageSalle + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_languette.hitTestable(), findsNothing);
    // Un toucher : elle revient, toujours rangee.
    await _toucher(tester);
    _verifierRangee(tester, ecran, droite: true);
    // Camera de l'enseignant eteinte : ni vignette ni languette (rien a
    // montrer) ; rallumee : la languette revient, l'affichage n'est jamais
    // force.
    salle.moteur.publier(_classe(camera: false));
    await tester.pumpAndSettle();
    expect(_languette, findsNothing);
    expect(_vignette, findsNothing);
    salle.moteur.publier(_classe(camera: true));
    await tester.pumpAndSettle();
    await _toucher(tester);
    _verifierRangee(tester, ecran, droite: true);
  });

  testWidgets('arabe 390 : la vignette est en haut a gauche, elle se range '
      'au bord gauche', (WidgetTester tester) async {
    const Size ecran = Size(390, 844);
    LocaleSettings.setLocaleSync(AppLocale.ar);
    await _monter(tester);
    expect(tester.getRect(_vignette).center.dx, lessThan(ecran.width / 2));
    // La poignee est au bord gauche.
    expect(tester.getRect(_poignee).left, closeTo(0, toleranceGarde));
    await _glisser(tester, droite: false, ecart: 150);
    _verifierRangee(tester, ecran, droite: false);
    await tester.tap(_languette);
    await tester.pumpAndSettle();
    expect(tester.getRect(_vignette).left, closeTo(AppSpacing.lg, 0.5));
  });

  testWidgets('lecteur d ecran : « Ranger la video de ... », « Montrer la '
      'video de ... »', (WidgetTester tester) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester);
    final String ranger = t.salle.vignette.ranger(deNom: '').trim();
    final String montrer = t.salle.vignette.montrer(deNom: '').trim();
    expect(
      tester.getSemantics(_poignee).label,
      allOf(startsWith(ranger), contains('Amina')),
    );
    await tester.tap(_poignee);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(_languette).label,
      allOf(startsWith(montrer), contains('Amina')),
    );
    semantique.dispose();
  });

  testWidgets('clavier : Entree sur la poignee range et donne le focus a la '
      'languette ; Entree sur la languette ramene la vignette', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    tester.widget<LanguetteBord>(_poignee).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_languette, findsOneWidget);
    final FocusNode noeud = tester.widget<LanguetteBord>(_languette).focusNode!;
    expect(noeud.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_languette, findsNothing);
    expect(_vignette, findsOneWidget);
    expect(tester.widget<LanguetteBord>(_poignee).focusNode!.hasFocus, isTrue);
  });

  testWidgets('reduire les animations : rangee et rappelee sans mouvement', (
    WidgetTester tester,
  ) async {
    await _monter(tester, mouvementReduit: true);
    await tester.tap(_poignee);
    await tester.pump();
    expect(_languette, findsOneWidget);
    expect(_vignette, findsNothing);
    await tester.tap(_languette);
    await tester.pump();
    expect(_vignette, findsOneWidget);
  });

  // Tailles, themes et texte double : ranger puis rappeler, la languette
  // reste dans l'ecran et ne recouvre ni l'ile ni la pilule de l'appel.
  for (final Size taille in <Size>[
    const Size(320, 568),
    const Size(390, 844),
    const Size(820, 1180),
    const Size(1440, 900),
  ]) {
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      for (final double texte in <double>[1, 2]) {
        testWidgets(
          '${taille.width.toInt()}x${taille.height.toInt()}, ${theme.name}, '
          'texte x$texte : ranger et rappeler',
          (WidgetTester tester) async {
            await _monter(tester, taille: taille, theme: theme, texte: texte);
            // L'ile se replie apres la mention de l'entree ; un toucher
            // ramene les commandes.
            await tester.pump(
              AppMouvement.ileMention + const Duration(seconds: 1),
            );
            await tester.pumpAndSettle();
            await _toucher(tester);
            await tester.tap(_poignee);
            await tester.pumpAndSettle();
            _verifierRangee(tester, taille, droite: true);
            verifierSansChevauchement(tester, <Finder>[
              _languette,
              find.byKey(const ValueKey<String>('ligne-etat-telephone')),
            ]);
            if (taille.width >= taille.height) {
              // Ordinateur : la languette vit au bord de la bande, hors de
              // la page.
              verifierSansChevauchement(tester, <Finder>[_languette, _page]);
            }
            await tester.tap(_languette);
            await tester.pumpAndSettle();
            expect(_vignette, findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  // Captures : montree, rangee avec sa languette, rappelee.
  for (final ({Size taille, ThemeMode theme, AppLocale langue}) cas
      in <({Size taille, ThemeMode theme, AppLocale langue})>[
        (
          taille: const Size(390, 844),
          theme: ThemeMode.light,
          langue: AppLocale.fr,
        ),
        (
          taille: const Size(390, 844),
          theme: ThemeMode.dark,
          langue: AppLocale.fr,
        ),
        (
          taille: const Size(390, 844),
          theme: ThemeMode.light,
          langue: AppLocale.ar,
        ),
        (
          taille: const Size(820, 1180),
          theme: ThemeMode.light,
          langue: AppLocale.fr,
        ),
        (
          taille: const Size(1440, 900),
          theme: ThemeMode.light,
          langue: AppLocale.fr,
        ),
        (
          taille: const Size(1440, 900),
          theme: ThemeMode.dark,
          langue: AppLocale.fr,
        ),
      ]) {
    final String nom =
        'eleve-${cas.taille.width.toInt()}-${cas.theme.name}'
        '${cas.langue == AppLocale.ar ? '-ar' : ''}';
    testWidgets('captures, $nom', (WidgetTester tester) async {
      if (dossierCapture == null) return;
      LocaleSettings.setLocaleSync(cas.langue);
      await _monter(tester, taille: cas.taille, theme: cas.theme);
      await capturerVue(tester, '$nom-1-montree');
      await _glisser(
        tester,
        droite: cas.langue != AppLocale.ar,
        ecart: cas.taille.width * 0.4,
      );
      await capturerVue(tester, '$nom-2-rangee');
      await tester.tap(_languette);
      await tester.pumpAndSettle();
      await capturerVue(tester, '$nom-3-rappelee');
    });
  }
}
