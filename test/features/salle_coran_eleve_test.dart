// Lot CORAN-ELEVE (directeur, 11/11/2026) : « rien ne recouvre le texte du
// Coran chez l'eleve ». La vraie composition de l'eleve dans `/salle`
// (`TelephonePleinEcran`), page presentee par l'enseignant, a 390 x 844,
// 820 x 1180, 1280 x 800 et 1440 x 900, clair et sombre, francais et arabe,
// texte x1 et x1,3 : l'ile, la pilule de l'appel, la vignette de l'enseignant
// et le zoom ne recouvrent jamais la boite de la page (texte et numero de
// page compris).
//
// Captures (docs/current/captures/E2E/coran-eleve/) seulement avec
// CAPTURE_DIR.

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
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/glisser_page.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart'
    show cleLigneMadina15;

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

List<Override> _surcharges(FauxMoteurSalle moteur) => <Override>[
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
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideo(acces0: _acces('student')),
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

Future<void> _monterEleve(
  WidgetTester tester, {
  required Size taille,
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(moteur),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', false, camera: true),
    _personne('e1', 'student', true),
    _personne('e2', 'student', false),
  ]);
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
  // Un toucher ramene les commandes (elles se masquent au delai) : on
  // verifie l'etat le plus charge, tout visible.
  await tester.tapAt(const Offset(AppSpacing.xs, AppSpacing.xs));
  await tester.pumpAndSettle();
}

final Finder _page = find.byKey(TelephonePleinEcran.clePage);
final Finder _ile = find.byKey(const ValueKey<String>('ligne-etat-telephone'));
final Finder _dock = find.byType(DockSeance);
final Finder _vignette = find.byType(VignetteVideo);
final Finder _zoom = find.byKey(const ValueKey<String>('salle-zoom'));

/// La page et tout ce qui flotte : deux a deux, aucun recouvrement, et rien
/// ne sort de l'ecran.
void _verifierRienSurLaPage(WidgetTester tester, Size ecran) {
  expect(_page, findsOneWidget);
  final List<Finder> elements = <Finder>[
    _page,
    _ile,
    _dock,
    if (_vignette.evaluate().isNotEmpty) _vignette,
    if (_zoom.evaluate().isNotEmpty) _zoom,
  ];
  // Chacun contre la page (le texte et le numero de page y sont).
  for (final Finder f in elements.skip(1)) {
    verifierSansChevauchement(tester, <Finder>[_page, f]);
  }
  verifierSansChevauchement(tester, elements);
  final Rect fenetre = Offset.zero & ecran;
  for (final Finder f in elements) {
    final Rect r = tester.getRect(f.first);
    expect(
      fenetre.inflate(toleranceGarde).contains(r.topLeft) &&
          fenetre.inflate(toleranceGarde).contains(r.bottomRight),
      isTrue,
      reason: '$f sort de l\'ecran : $r',
    );
  }
}

const List<Size> _tailles = <Size>[
  Size(390, 844),
  Size(820, 1180),
  Size(1280, 800),
  Size(1440, 900),
];

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group(langue.languageCode, () {
      setUp(() => LocaleSettings.setLocale(langue));
      for (final Size taille in _tailles) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          for (final double texte in <double>[1, 1.3]) {
            testWidgets(
              'eleve ${taille.width.toInt()}x${taille.height.toInt()}, '
              '${theme.name}, texte x$texte : rien ne recouvre la page',
              (WidgetTester tester) async {
                await _monterEleve(
                  tester,
                  taille: taille,
                  texte: texte,
                  theme: theme,
                );
                _verifierRienSurLaPage(tester, taille);
              },
            );
          }
        }
      }
    });
  }

  // Ordinateur et tablette en paysage : la vignette et les commandes vont
  // dans les bandes vides des cotes, la page garde toute la hauteur.
  for (final Size taille in <Size>[
    const Size(1280, 800),
    const Size(1440, 900),
  ]) {
    testWidgets('eleve ${taille.width.toInt()} : la page garde toute la '
        'hauteur, le reste est sur les cotes', (WidgetTester tester) async {
      await _monterEleve(tester, taille: taille);
      final Rect page = tester.getRect(_page);
      expect(page.height, closeTo(taille.height, toleranceGarde));
      for (final Finder f in <Finder>[_ile, _dock, _vignette]) {
        final Rect r = tester.getRect(f.first);
        expect(
          r.right <= page.left + toleranceGarde ||
              r.left >= page.right - toleranceGarde,
          isTrue,
          reason: '$f doit etre dans une bande de cote : $r / page $page',
        );
      }
    });
  }

  // Point 4 du lot : l'eleve suit la page de la classe. Un glissement ne
  // tourne rien et le dit un court instant ; la page reste celle de la classe.
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('eleve ${taille.width.toInt()} : glisser sur la page de la '
        'classe le dit, sans rien tourner', (WidgetTester tester) async {
      await _monterEleve(tester, taille: taille);
      expect(find.text(t.salle.coranEleve.pageDeLaClasse), findsNothing);
      await tester.fling(_page, const Offset(300, 0), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(
          of: find.byKey(GlisserPage.cleMessage),
          matching: find.textContaining(t.salle.coranEleve.pageDeLaClasse),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  // Mesures du lot (UX_REVIEW_CORAN-ELEVE.md) : la boite de la page et la
  // taille reelle du texte (largeur d'une ligne justifiee) chez l'eleve.
  // Avant le lot (meme test sur 4e6e63f48) : 390 x 844, page 390 x 844,
  // ligne 377 ; 820 x 1180, page 820 x 1180, ligne 628 ; 1280 x 800, page
  // 622 x 800, ligne 426 ; 1440 x 900, page 700 x 900, ligne 479.
  // Apres : sur ordinateur, rien ne change (tout est passe sur les cotes) ;
  // au telephone et a la tablette en portrait, la page s'arrete entre l'ile
  // et les commandes de l'appel : le texte perd 14 % (390) et 20 % (820).
  // C'est le prix de « rien ne recouvre le texte » : question posee au
  // directeur dans la revue.
  final Map<double, ({double avant, double part})> lignes =
      <double, ({double avant, double part})>{
        390: (avant: 377, part: 0.85),
        820: (avant: 628, part: 0.79),
        1280: (avant: 426, part: 1),
        1440: (avant: 479, part: 1),
      };
  for (final Size taille in _tailles) {
    testWidgets('mesure, eleve ${taille.width.toInt()} : la ligne du texte '
        'garde sa taille', (WidgetTester tester) async {
      await _monterEleve(tester, taille: taille);
      final Rect page = tester.getRect(_page);
      final Size ligne = tester.getSize(find.byKey(cleLigneMadina15(3)));
      // ignore: avoid_print
      print(
        'MESURE ${taille.width.toInt()}x${taille.height.toInt()} : page '
        '${page.width.toStringAsFixed(0)} x ${page.height.toStringAsFixed(0)}'
        ', ligne ${ligne.width.toStringAsFixed(0)} x '
        '${ligne.height.toStringAsFixed(1)}',
      );
      final ({double avant, double part}) attendu = lignes[taille.width]!;
      expect(
        ligne.width,
        greaterThanOrEqualTo(attendu.avant * attendu.part - toleranceGarde),
      );
    });
  }

  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(820, 1180),
    const Size(1440, 900),
  ]) {
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('captures, eleve ${taille.width.toInt()}, ${theme.name}', (
        WidgetTester tester,
      ) async {
        if (dossierCapture == null) return;
        await _monterEleve(tester, taille: taille, theme: theme);
        await capturerVue(
          tester,
          'apres-eleve-${taille.width.toInt()}-${theme.name}',
        );
      });
    }
  }
  testWidgets('capture, eleve 1440, arabe', (WidgetTester tester) async {
    if (dossierCapture == null) return;
    await LocaleSettings.setLocale(AppLocale.ar);
    await _monterEleve(tester, taille: const Size(1440, 900));
    await capturerVue(tester, 'apres-eleve-1440-ar');
  });
}
