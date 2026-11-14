// Lot TELEPHONE-REDUIT (directeur, 10-11/11/2026 ; cahier de la salle §9,
// docs/current/UX_REVIEW_TELEPHONE-REDUIT.md) : le telephone de l'enseignant
// garde a un geste ce qui sert a chaque cours ; « Reduire la salle » y est
// visible ; le chrono se lit au repos.
//
// Captures (avant / apres) seulement avec CAPTURE_DIR ; PHASE=avant pour
// l'etat d'avant le lot.

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
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart'
    show DockSeance;
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart'
    show PanneauSeance;
import 'package:rewayah_academy/features/salle_seance/telephone_enseignant.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../../teaching_core/e/faux/faux_classe.dart';

AccesSalle _acces(String role, {bool donnees = true}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher' && donnees,
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ParticipantSalle _personne(
  String id,
  String role,
  bool local, {
  bool micro = false,
}) => ParticipantSalle(
  identite: id,
  nom: '',
  role: role,
  estLocal: local,
  micro: micro,
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

List<Override> _surcharges(
  String role,
  FauxMoteurSalle moteur, {
  bool donnees = true,
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
        profileId: switch (role) {
          'teacher' => 't1',
          'guardian_observer' => 'g1',
          'masked_controller' => 'c1',
          _ => 'e1',
        },
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideo(acces0: _acces(role, donnees: donnees)),
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
  // Pilote C4 : Amina, enseignante, porte le titre feminin.
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

const Size _telephone = Size(390, 844);
const Size _ipad = Size(834, 1194);

Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  String role = 'teacher',
  Size taille = _telephone,
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  bool presenter = true,
  bool donnees = true,
  bool eleves = true,
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(role, moteur, donnees: donnees),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', role == 'teacher'),
    if (eleves) ...<ParticipantSalle>[
      _personne('e1', 'student', role == 'student'),
      _personne('e2', 'student', false),
    ],
  ]);
  // Defaut R-1 (11/11/2026) : les barres de reseau viennent de la qualite
  // mesuree ; le faux moteur la publie comme le fait le serveur de visio.
  moteur.publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
  if (!presenter) return moteur;
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
  return moteur;
}

/// Les commandes se masquent apres le delai : la salle revient au repos.
Future<void> _attendreLeRepos(WidgetTester tester) async {
  await tester.pump(AppMouvement.masquageSalle + const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Les commandes se masquent au delai : un toucher les ramene.
///
/// DYNAMIQUE-CHRONO-1 : le coin de l'ecran est la rangee reservee de la
/// Dynamique chrono ; le toucher se fait juste dessous, sur la page.
Future<void> _toucher(WidgetTester tester) async {
  final Finder rangee = find.byKey(TelephonePleinEcran.cleRangeeChrono);
  final double haut = rangee.evaluate().isEmpty
      ? 0
      : tester.getRect(rangee).bottom;
  await tester.tapAt(Offset(10, haut + 10));
  await tester.pumpAndSettle();
}

/// Ouvre le tiroir (« Plus », dans la barre, au toucher).
Future<void> _ouvrirTiroir(WidgetTester tester) async {
  await _toucher(tester);
  await tester.tap(find.byKey(TelephonePleinEcran.cleCommandesToucher));
  await tester.pumpAndSettle();
}

/// Change d'onglet (segments ou menu, ONGLETS-1).
Future<void> _onglet(WidgetTester tester, String libelle) async {
  final Finder menu = find.byType(MenuFiltre<OngletTiroir>);
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(libelle).hitTestable().last);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

const String _phase = String.fromEnvironment('PHASE', defaultValue: 'apres');

/// L'etat de la salle, en haut chez l'enseignant au telephone.
///
/// DYNAMIQUE-CHRONO-1 : ce harnais ne sert pas de chrono, la Dynamique chrono
/// n'y a rien a dire ; le mot d'etat de sa zone reservee, lui, est toujours
/// la (avant ce lot : l'ile, qui portait aussi le mot d'etat).
final Finder _ile = find.byKey(LigneEtatSalle.cleMot);

/// GRILLE-COMMANDES : la barre de l'enseignant, la seule.
final Finder _dock = find.byKey(BarreCommandesTelephone.cle);

/// La case du Pointeur, dans la barre.
final Finder _pointeur = find.byKey(BarreCommandesTelephone.clePointeur);

/// Les cases de la barre, dans l'ordre de lecture.
List<Rect> _cases(WidgetTester tester) {
  final List<Rect> cases = <Rect>[
    for (final Element e
        in find
            .descendant(
              of: _dock,
              matching: find.byKey(const ValueKey<String>('tuile-commande')),
            )
            .hitTestable()
            .evaluate())
      tester.getRect(find.byWidget(e.widget)),
  ];
  return cases..sort((Rect a, Rect b) => a.left.compareTo(b.left));
}

/// Rien ne se recouvre parmi les objets poses sur la page, aucun mot coupe,
/// cibles de 48 au moins.
void _verifierPlaces(WidgetTester tester, String etat) {
  expect(tester.takeException(), isNull, reason: etat);
  final List<Finder> objets = <Finder>[
    for (final Finder f in <Finder>[
      _ile,
      find.byKey(CapsuleVideoTelephone.cle),
      _dock,
      find.byKey(TiroirCommandesTelephone.cle),
      find.byKey(FeuilleElevesTelephone.cle),
    ])
      if (f.hitTestable().evaluate().isNotEmpty) f,
  ];
  if (objets.length > 1) verifierSansChevauchement(tester, objets);
  for (final Finder o in objets) {
    verifierAucunMotCoupe(tester, o);
    for (final Element e
        in find
            .descendant(of: o, matching: find.byType(Pressable))
            .hitTestable()
            .evaluate()) {
      final Size z = tester.getSize(find.byWidget(e.widget));
      expect(
        z.width >= 47.5 && z.height >= 47.5,
        isTrue,
        reason: '$etat : cible de ${z.width} x ${z.height}',
      );
    }
  }
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group(langue.languageCode, () {
      setUp(() => LocaleSettings.setLocale(langue));
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = '${langue.languageCode}, ${theme.name}';

        testWidgets("$nom : au repos, l'ile (chrono) se lit en haut, a la "
            'place de la capsule', (WidgetTester tester) async {
          await _monter(tester, theme: theme);
          await _attendreLeRepos(tester);
          expect(_ile.hitTestable(), findsOneWidget);
          // DYNAMIQUE-CHRONO-1 : au toucher, la capsule se pose sous la
          // rangee de la barre, qui reste ; le profil deplie ne redit plus la
          // ligne d'etat (une seule barre a l'ecran).
          await _toucher(tester);
          await tester.tap(find.byKey(CapsuleVideoTelephone.cleDeplier));
          await tester.pumpAndSettle();
          expect(_ile.hitTestable(), findsOneWidget);
          _verifierPlaces(tester, '$nom, profil');
        });

        testWidgets('$nom : « Reduire la salle » au debut de la capsule, '
            "seulement si l'appel continue hors de l'ecran", (
          WidgetTester tester,
        ) async {
          await _monter(tester, theme: theme);
          await _attendreLeRepos(tester);
          final Finder reduire = find.byKey(
            CapsuleVideoTelephone.cleReduireSalle,
          );
          // Au repos, masque avec la capsule.
          expect(reduire.hitTestable(), findsNothing);
          await _toucher(tester);
          expect(reduire.hitTestable(), findsOneWidget);
          // Au debut de la capsule (la place du retour d'un telephone).
          final Rect capsule = tester.getRect(
            find.byKey(CapsuleVideoTelephone.cle),
          );
          final Rect bouton = tester.getRect(reduire);
          final bool ltr = langue != AppLocale.ar;
          expect(
            ltr
                ? bouton.left - capsule.left < capsule.right - bouton.right
                : capsule.right - bouton.right < bouton.left - capsule.left,
            isTrue,
          );
          _verifierPlaces(tester, '$nom, toucher');
          // « Reduire la salle » n'est pas dans la barre : il est en haut.
          expect(
            find.descendant(
              of: _dock,
              matching: find.byKey(DockSeance.cleReduire),
            ),
            findsNothing,
          );
        });

        testWidgets('$nom : le tiroir sans onglets ni ecriture, la phrase dit '
            'ou ecrire', (WidgetTester tester) async {
          await _monter(tester, theme: theme);
          await _ouvrirTiroir(tester);
          expect(find.byKey(TiroirCommandesTelephone.cle), findsOneWidget);
          expect(find.byKey(TiroirCommandesTelephone.cleOnglets), findsNothing);
          expect(find.byType(MenuFiltre<OngletTiroir>), findsNothing);
          expect(
            find.byKey(const ValueKey<String>('barre-outils-stylet')),
            findsNothing,
          );
          // Tableau ferme : pas de ligne pour l'ouvrir.
          expect(
            find.byKey(const ValueKey<String>('bouton-tableau')),
            findsNothing,
          );
          expect(
            find.text(t.salle.telephone.ecrireAilleurs).hitTestable(),
            findsOneWidget,
          );
          // Ranger le support reste a un geste.
          expect(
            find.byKey(TiroirCommandesTelephone.cleRanger),
            findsOneWidget,
          );
          // La pilule reste sous le tiroir, jamais dessus.
          expect(
            tester.getRect(_dock).top,
            greaterThanOrEqualTo(
              tester.getRect(find.byKey(TiroirCommandesTelephone.cle)).bottom -
                  0.5,
            ),
          );
          _verifierPlaces(tester, '$nom, tiroir');
        });

        testWidgets('$nom : une seule barre, des cases egales et alignees, '
            'dans l\'ordre Micro, Camera, Eleves, Pointeur, Plus, Quitter', (
          WidgetTester tester,
        ) async {
          await _monter(tester, theme: theme);
          await _toucher(tester);
          // Plus de bouton « Commandes » ni de disque : la tuile commune.
          expect(
            find.byKey(const ValueKey<String>('declencheur-commandes')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey<String>('disque-commande')),
            findsNothing,
          );
          final List<Rect> cases = _cases(tester);
          expect(cases, hasLength(6));
          for (final Rect c in cases) {
            expect(c.width, closeTo(cases.first.width, 0.5));
            expect(c.top, closeTo(cases.first.top, 0.5));
            expect(c.height, closeTo(cases.first.height, 0.5));
          }
          // Les icones sur une meme ligne, a pas regulier.
          final List<Offset> icones = <Offset>[
            for (final Element e
                in find
                    .descendant(of: _dock, matching: find.byType(Icon))
                    .hitTestable()
                    .evaluate())
              tester.getCenter(find.byWidget(e.widget)),
          ]..sort((Offset a, Offset b) => a.dx.compareTo(b.dx));
          expect(icones, hasLength(6));
          final double pas = icones[1].dx - icones[0].dx;
          for (int i = 1; i < icones.length; i++) {
            expect(icones[i].dy, closeTo(icones.first.dy, 0.5));
            expect(icones[i].dx - icones[i - 1].dx, closeTo(pas, 0.5));
          }
          // L'ordre (de la colonne de l'ordinateur).
          final List<Key> ordre = <Key>[
            const ValueKey<String>('bouton-micro'),
            BarreCommandesTelephone.cleEleves,
            BarreCommandesTelephone.clePointeur,
            BarreCommandesTelephone.clePlus,
          ];
          final bool ltr = langue != AppLocale.ar;
          for (int i = 1; i < ordre.length; i++) {
            final double avant = tester.getCenter(find.byKey(ordre[i - 1])).dx;
            final double apres = tester.getCenter(find.byKey(ordre[i])).dx;
            expect(ltr ? avant < apres : avant > apres, isTrue, reason: '$i');
          }
          // Les noms sont fixes : l'etat ne change pas le mot.
          if (langue == AppLocale.fr) {
            for (final String nom in <String>[
              t.salle.micro,
              t.salle.camera,
              t.salle.seance.eleves,
              t.salle.seance.outils.pointeur,
              t.salle.seance.commandes.declencheur,
              t.salle.quitter,
            ]) {
              expect(
                find.descendant(of: _dock, matching: find.text(nom)),
                findsOneWidget,
                reason: nom,
              );
            }
            expect(find.text(t.salle.microCoupe), findsNothing);
          }
          _verifierPlaces(tester, '$nom, barre');
        });

        testWidgets('$nom : le Pointeur dans la barre ; tenu, il reste seul '
            'au repos, a sa place', (WidgetTester tester) async {
          await _monter(tester, theme: theme);
          await _attendreLeRepos(tester);
          expect(_pointeur.hitTestable(), findsNothing);
          await _toucher(tester);
          expect(_pointeur.hitTestable(), findsOneWidget);
          _verifierPlaces(tester, '$nom, pointeur');
          await tester.tap(
            find
                .byKey(const ValueKey<String>('salle-outil-pointeur'))
                .hitTestable(),
          );
          await tester.pumpAndSettle();
          final Rect place = tester.getRect(_pointeur.hitTestable());
          await _attendreLeRepos(tester);
          expect(_pointeur.hitTestable(), findsOneWidget);
          // A sa place, seul : rien n'a bouge, « Plus » n'est plus la.
          expect(tester.getRect(_pointeur.hitTestable()), place);
          expect(
            find.byKey(BarreCommandesTelephone.clePlus).hitTestable(),
            findsNothing,
          );
          _verifierPlaces(tester, '$nom, pointeur tenu au repos');
          // Un appui le repose.
          await tester.tap(
            find
                .byKey(const ValueKey<String>('salle-outil-pointeur'))
                .hitTestable(),
          );
          await tester.pumpAndSettle();
          await _attendreLeRepos(tester);
          expect(_pointeur.hitTestable(), findsNothing);
        });
      }
    });
  }

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group('${langue.languageCode} 360', () {
      setUp(() => LocaleSettings.setLocale(langue));
      testWidgets('${langue.languageCode} 360x640, texte x2 : rien ne se '
          'recouvre', (WidgetTester tester) async {
        await _monter(tester, taille: const Size(360, 640), texte: 2);
        await _attendreLeRepos(tester);
        _verifierPlaces(tester, 'repos');
        await _toucher(tester);
        _verifierPlaces(tester, 'toucher');
        await tester.tap(find.byKey(TelephonePleinEcran.cleCommandesToucher));
        await tester.pumpAndSettle();
        _verifierPlaces(tester, 'tiroir');
        expect(
          tester.getRect(_dock).top,
          greaterThanOrEqualTo(
            tester.getRect(find.byKey(TiroirCommandesTelephone.cle)).bottom -
                0.5,
          ),
        );
      });
    });
  }

  testWidgets("tablette 834 : le tiroir garde ses deux onglets et l'ecriture", (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: _ipad);
    await _ouvrirTiroir(tester);
    expect(find.byKey(TiroirCommandesTelephone.cleOnglets), findsOneWidget);
    expect(find.text(t.salle.telephone.ecrireAilleurs), findsNothing);
    // La meme barre que le telephone, Pointeur compris.
    expect(_pointeur, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('bouton-tableau')),
      findsOneWidget,
    );
  });

  for (final (AppLocale langue, ThemeMode theme) in <(AppLocale, ThemeMode)>[
    (AppLocale.fr, ThemeMode.light),
    (AppLocale.fr, ThemeMode.dark),
    (AppLocale.ar, ThemeMode.light),
  ]) {
    final String nom = '${langue.languageCode}-${theme.name}';
    group(nom, () {
      setUp(() => LocaleSettings.setLocale(langue));
      testWidgets('captures $_phase, 390x844, $nom', (
        WidgetTester tester,
      ) async {
        if (dossierCapture == null) return;
        await _monter(tester, theme: theme);
        await _attendreLeRepos(tester);
        await capturerVue(tester, '$_phase-390-$nom-repos');
        await _toucher(tester);
        await capturerVue(tester, '$_phase-390-$nom-toucher');
        await _ouvrirTiroir(tester);
        await capturerVue(tester, '$_phase-390-$nom-tiroir-support');
        if (_phase == 'avant') {
          await _onglet(tester, t.salle.seance.commandes.ongletOutils);
          await capturerVue(tester, '$_phase-390-$nom-tiroir-outils');
        } else {
          // Le Pointeur tenu, au repos.
          await tester.tap(
            find.byKey(PanneauSeance.cleReduire).hitTestable().first,
          );
          await tester.pumpAndSettle();
          await _toucher(tester);
          await tester.tap(
            find
                .byKey(const ValueKey<String>('salle-outil-pointeur'))
                .hitTestable(),
          );
          await tester.pumpAndSettle();
          await _attendreLeRepos(tester);
          await capturerVue(tester, '$_phase-390-$nom-pointeur-tenu');
        }
      });
    });
  }

  testWidgets('captures $_phase, 360x640 texte x2 et ordinateur 1440', (
    WidgetTester tester,
  ) async {
    if (dossierCapture == null) return;
    await _monter(tester, taille: const Size(360, 640), texte: 2);
    await _toucher(tester);
    await capturerVue(tester, '$_phase-360-x2-toucher');
    await tester.tap(find.byKey(TelephonePleinEcran.cleCommandesToucher));
    await tester.pumpAndSettle();
    await capturerVue(tester, '$_phase-360-x2-tiroir');
    await _monter(tester, taille: const Size(1440, 900));
    await capturerVue(tester, '$_phase-1440-fr-light-ordinateur');
  });
}
