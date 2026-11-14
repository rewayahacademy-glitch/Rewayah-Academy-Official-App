// Lot CORAN-ELEVE (directeur, 11/11/2026) : « rien ne recouvre le texte du
// Coran chez l'eleve ». La vraie composition de l'eleve dans `/salle`
// (`TelephonePleinEcran`), page presentee par l'enseignant, a 390 x 844,
// 820 x 1180, 1280 x 800 et 1440 x 900, clair et sombre, francais et arabe,
// texte x1 et x1,3. Ordinateur : l'ile, la pilule de l'appel, la vignette et
// le zoom sont dans les bandes de cote, jamais sur la page. Telephone et
// tablette en portrait (pilote, 11/11) : la page a l'ecran entier ; au repos,
// seule l'ile repliee est posee dessus ; au toucher, les commandes passent
// par-dessus puis s'effacent. Interface guidee : la page entre deux rangees.
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
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/bornes_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
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
  bool micro = false,
}) => ParticipantSalle(
  identite: id,
  nom: '',
  role: role,
  estLocal: local,
  micro: micro,
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
  // DYNAMIQUE-CHRONO-1 : le chrono servi, comme en production (la barre
  // porte le temps ; sans bornes, elle n'a rien a dire).
  bornesSalleProvider.overrideWith(
    (Ref _, CleBornesSalle _) => BornesChrono(
      debutUtc: DateTime.now().toUtc().subtract(const Duration(minutes: 20)),
      finPrevueUtc: DateTime.now().toUtc().add(const Duration(minutes: 40)),
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

Future<FauxMoteurSalle> _monterEleve(
  WidgetTester tester, {
  required Size taille,
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  InterfaceMode mode = InterfaceMode.standard,
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(moteur),
      echelleTexte: texte,
      themeMode: theme,
      interfaceMode: mode,
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
  await _toucher(tester);
  return moteur;
}

/// Un toucher de l'ecran (hors d'un bouton) : les commandes reviennent.
///
/// DYNAMIQUE-CHRONO-1 : en portrait, le coin de l'ecran est la rangee
/// reservee de la Dynamique chrono ; le toucher se fait juste dessous.
Future<void> _toucher(WidgetTester tester) async {
  final Finder rangee = find.byKey(TelephonePleinEcran.cleRangeeChrono);
  final double haut = rangee.evaluate().isEmpty
      ? 0
      : tester.getRect(rangee).bottom;
  await tester.tapAt(Offset(AppSpacing.xs, haut + AppSpacing.xs));
  await tester.pumpAndSettle();
}

/// Le repos : la mention de l'entree replie l'ile, les commandes se masquent
/// au delai.
Future<void> _attendreLeRepos(WidgetTester tester) async {
  await tester.pump(AppMouvement.ileMention + const Duration(seconds: 1));
  await tester.pumpAndSettle();
  await tester.pump(AppMouvement.masquageSalle + const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Ce qui flotte et se masque : plus rien de touchable ni de visible.
void _verifierMasques(WidgetTester tester) {
  for (final Finder f in <Finder>[_dock, _vignette, _zoom]) {
    expect(f.hitTestable(), findsNothing, reason: '$f encore la au repos');
  }
  for (final AnimatedOpacity o in tester.widgetList<AnimatedOpacity>(
    find.ancestor(of: _dock, matching: find.byType(AnimatedOpacity)),
  )) {
    expect(o.opacity, 0);
  }
}

final Finder _page = find.byKey(TelephonePleinEcran.clePage);
final Finder _ile = find.byKey(const ValueKey<String>('ligne-etat-telephone'));

/// DYNAMIQUE-CHRONO-1 : la zone reservee (la barre, le mot d'etat, la
/// mention permanente).
final Finder _zone = find.byKey(ZoneChrono.cle);
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
    _zone,
    _dock,
    if (_vignette.evaluate().isNotEmpty) _vignette,
    if (_zoom.evaluate().isNotEmpty) _zoom,
  ];
  // Chacun contre la page (le texte et le numero de page y sont).
  for (final Finder f in elements.skip(1)) {
    verifierSansChevauchement(tester, <Finder>[_page, f]);
  }
  // La barre est dans sa zone : seule la zone compte entre elles deux.
  verifierSansChevauchement(
    tester,
    elements.where((Finder f) => f != _ile).toList(),
  );
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
              '${theme.name}, texte x$texte : rien ne reste sur la page',
              (WidgetTester tester) async {
                await _monterEleve(
                  tester,
                  taille: taille,
                  texte: texte,
                  theme: theme,
                );
                if (taille.width >= taille.height) {
                  // Ordinateur : tout est dans les bandes de cote, meme
                  // au toucher.
                  _verifierRienSurLaPage(tester, taille);
                  return;
                }
                // Telephone et tablette en portrait (pilote, 11/11) : au
                // toucher, les commandes passent par-dessus la page sans
                // se recouvrir entre elles...
                verifierSansChevauchement(tester, <Finder>[
                  _zone,
                  _dock,
                  if (_vignette.evaluate().isNotEmpty) _vignette,
                ]);
                // ... puis s'effacent seules. DYNAMIQUE-CHRONO-1 (directeur,
                // 12/11/2026 : « le chrono cache le document ») : au repos,
                // la page a toute la largeur et la hauteur laissee sous la
                // rangee reservee de la Dynamique chrono ; rien n'est pose
                // dessus (avant ce lot : page plein ecran, ile posee dessus).
                await _attendreLeRepos(tester);
                _verifierMasques(tester);
                final Rect rangee = tester.getRect(
                  find.byKey(TelephonePleinEcran.cleRangeeChrono),
                );
                final Rect page = tester.getRect(_page);
                expect(page.width, moreOrLessEquals(taille.width));
                expect(page.top, moreOrLessEquals(rangee.bottom));
                expect(page.bottom, moreOrLessEquals(taille.height));
                verifierSansChevauchement(tester, <Finder>[
                  find.byKey(TelephonePleinEcran.cleRangeeChrono),
                  _page,
                ]);
                verifierSansChevauchement(tester, <Finder>[_zone, _page]);
                expect(_ile, findsOneWidget);
                // Un simple toucher ne dit pas « la page suit celle de
                // l'enseignant » (seul un glissement le dit).
                await _toucher(tester);
                expect(
                  find.textContaining(t.salle.coranEleve.pageDeLaClasse),
                  findsNothing,
                );
                await _attendreLeRepos(tester);
                // L'ile reste au repos, touchable. Micro ferme : aucun
                // signe de micro.
                expect(
                  find.byKey(DynamiqueChrono.cleDeplier).hitTestable(),
                  findsOneWidget,
                );
                expect(
                  find.byKey(DynamiqueChrono.cleMicroOuvert),
                  findsNothing,
                );
                // La barre repliee reste petite : une ligne.
                final Rect ile = tester.getRect(_ile);
                expect(ile.width, lessThan(taille.width * 0.7));
                expect(ile.height, lessThanOrEqualTo(48 + toleranceGarde));
                expect(tester.takeException(), isNull);
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

  // Point 3 de la reprise du pilote : le micro ouvert reste su quand les
  // commandes sont masquees (icone et nom lu dans l'ile repliee).
  testWidgets('eleve 390 : micro ouvert, l ile repliee le dit au repos', (
    WidgetTester tester,
  ) async {
    final FauxMoteurSalle moteur = await _monterEleve(
      tester,
      taille: const Size(390, 844),
    );
    List<ParticipantSalle> classe({required bool micro}) => <ParticipantSalle>[
      _personne('t1', 'teacher', false, camera: true),
      _personne('e1', 'student', true, micro: micro),
      _personne('e2', 'student', false),
    ];
    moteur.publier(classe(micro: true));
    await tester.pumpAndSettle();
    await _attendreLeRepos(tester);
    _verifierMasques(tester);
    final Finder signe = find.byKey(DynamiqueChrono.cleMicroOuvert);
    expect(signe, findsOneWidget);
    final SemanticsHandle semantique = tester.ensureSemantics();
    expect(
      tester.getSemantics(signe),
      matchesSemantics(label: t.salle.microOuvert),
    );
    semantique.dispose();
    // Micro referme : le signe part.
    moteur.publier(classe(micro: false));
    await tester.pumpAndSettle();
    expect(signe, findsNothing);
  });

  // Interface guidee (pilote, 11/11) : un enfant voit toujours ses boutons.
  // En portrait, la page se pose entre deux rangees, et rien ne se masque.
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(820, 1180),
  ]) {
    testWidgets('guidee ${taille.width.toInt()} : la page entre deux '
        'rangees, les commandes ne se masquent jamais', (
      WidgetTester tester,
    ) async {
      await _monterEleve(tester, taille: taille, mode: InterfaceMode.enfant);
      await _attendreLeRepos(tester);
      expect(_dock.hitTestable(), findsOneWidget);
      verifierSansChevauchement(tester, <Finder>[_page, _dock]);
      // DYNAMIQUE-CHRONO-1 : en Interface guidee, pas de chrono (regle
      // inchangee) ; la zone reservee garde le mot d'etat et la mention.
      verifierSansChevauchement(tester, <Finder>[_page, _zone]);
      if (_vignette.evaluate().isNotEmpty) {
        verifierSansChevauchement(tester, <Finder>[_page, _vignette]);
      }
      expect(tester.takeException(), isNull);
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
  // Apres (pilote, 11/11 : « sans compacter la page du Coran ») : la meme
  // taille partout. Sur ordinateur, tout est sur les cotes ; au telephone et
  // a la tablette en portrait, la page garde l'ecran entier et les commandes
  // passent par-dessus au toucher, puis s'effacent. Seule l'Interface guidee
  // en portrait a une page plus petite (entre ses deux rangees).
  // PAGES-FLUIDES (directeur, 12/11/2026 : « un cadre et des marges, pour
  // lire sans que ca coince sur les cotes ») : la page se pose dans une
  // marge (16 de chaque cote au telephone, davantage quand la boite le
  // permet ; reserve de 12 ou 16 en haut et en bas). Ce que le texte y perd,
  // mesure ici : 390 : 377 -> 346 (-8 %) ; 820 : 628 -> 611 (-3 %) ;
  // 1280 : 426 -> 409 (-4 %) ; 1440 : 479 -> 462 (-4 %). La garde suit la
  // nouvelle taille ; elle reste une garde contre tout autre retrecissement.
  // DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026 : « le chrono cache le
  // document ») : la rangee reservee de la barre prend le haut de l'ecran
  // (64 a 820 x 1180) ; la page, bornee par sa hauteur a 820, perd 611 ->
  // 577 (-6 %). A 390, la page est bornee par sa largeur : rien ne change.
  final Map<double, double> lignes = <double, double>{
    390: 346,
    820: 577,
    1280: 409,
    1440: 462,
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
      expect(ligne.width, closeTo(lignes[taille.width]!, toleranceGarde));
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
        final String nom = 'apres-eleve-${taille.width.toInt()}-${theme.name}';
        if (taille.width >= taille.height) {
          await capturerVue(tester, nom);
          return;
        }
        await _attendreLeRepos(tester);
        await capturerVue(tester, '$nom-repos');
        await _toucher(tester);
        await capturerVue(tester, '$nom-toucher');
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
