// Plan de composition du 26/10/2026 (point h) : la salle de l'enseignant sur
// ordinateur, a 1440 x 900 et 1280 x 720, texte x1 et x2, clair et sombre,
// francais et arabe (panneaux miroites : les Eleves a droite, la
// Bibliotheque a gauche en arabe). Un seul bouton plein, aucun chevauchement
// entre les zones, aucune carte collee ; l'eleve n'a ni panneau ni liste.
//
// Captures 1440 (repos, eleve deplie, bibliotheque depliee, focus, barre
// d'outils) seulement avec CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/commande_salle.dart'
    show TonTuileSalle, TuileCommandeSalle;
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/barre_outils_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart'
    show BoutonPlusAppel;
import 'package:rewayah_academy/features/salle_seance/panneau_bibliotheque_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/pilule_etat_salle.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';

import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart'
    show TelephonePleinEcran;
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart'
    show cleLigneMadina15;

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

List<Override> _surcharges(
  String role,
  FauxMoteurSalle moteur, {
  bool pageLisible = true,
}) => <Override>[
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
  // La page 42 se lit (sinon son etat d'erreur pose « Reessayer »).
  if (pageLisible) ...surchargesMadina15(page: 42),
  if (pageLisible)
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

Future<void> _monter(
  WidgetTester tester, {
  String role = 'teacher',
  Size taille = const Size(1440, 900),
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  bool pageLisible = true,
  bool cameraEnseignant = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(role, moteur, pageLisible: pageLisible),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', role == 'teacher', camera: cameraEnseignant),
    _personne('e1', 'student', role == 'student'),
    _personne('e2', 'student', false),
  ]);
  await tester.pumpAndSettle();
  final ContenuPresente contenu = ContenuPresente(
    page: 42,
    sourate: 2,
    verset: 255,
    presentePar: 't1',
    emisLe: DateTime.now(),
  );
  // L'enseignant presente ; l'eleve recoit (il ne presente rien : le faux
  // moteur refuse, comme le vrai, faute de capacite).
  if (role == 'teacher') {
    await moteur.presenterContenu(contenu);
  } else {
    moteur.publierContenu(contenu);
  }
  await tester.pumpAndSettle();
}

/// La largeur du texte de la page (une ligne justifiee) et la hauteur du
/// bloc des quinze lignes : la taille de lecture reelle du Coran.
Size _texteDeLaPage(WidgetTester tester) {
  final Size ligne = tester.getSize(find.byKey(cleLigneMadina15(3)));
  return Size(ligne.width, ligne.height * 15);
}

bool _carte(Widget w) {
  final Key? cle = w.key;
  if (cle is! ValueKey<String>) return false;
  return cle.value.startsWith('eleve-') ||
      cle.value.startsWith('bibliotheque-support-');
}

void main() {
  // Les vraies polices seulement pour les captures.
  setUpAll(() async {
    if (dossierCapture == null) return;
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group(langue.languageCode, () {
      // La langue se pose hors de la zone de temps simulee du test : attendue
      // dedans, son chargement ne finit jamais.
      setUp(() => LocaleSettings.setLocale(langue));
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(1280, 720),
      ]) {
        for (final double texte in <double>[1, 2]) {
          for (final ThemeMode theme in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            testWidgets('enseignant ${langue.languageCode}, '
                '${taille.width.toInt()}x${taille.height.toInt()}, texte '
                'x${texte.toInt()}, ${theme.name} : trois panneaux, rien ne se '
                'recouvre', (WidgetTester tester) async {
              await _monter(tester, taille: taille, texte: texte, theme: theme);
              expect(tester.takeException(), isNull);
              expect(find.byType(SalleOrdinateur), findsOneWidget);
              final Rect gauche = tester.getRect(
                find.byKey(SalleOrdinateur.cleGauche),
              );
              final Rect centre = tester.getRect(
                find.byKey(SalleOrdinateur.cleCentre),
              );
              final Rect droite = tester.getRect(
                find.byKey(SalleOrdinateur.cleDroite),
              );
              // Miroir en arabe : les Eleves au bord de debut de lecture.
              if (langue == AppLocale.ar) {
                expect(gauche.left, greaterThan(centre.right - 0.5));
                expect(droite.right, lessThan(centre.left + 0.5));
              } else {
                expect(gauche.right, lessThan(centre.left + 0.5));
                expect(droite.left, greaterThan(centre.right - 0.5));
              }
              verifierSansChevauchement(tester, <Finder>[
                find.byKey(SalleOrdinateur.cleHaut),
                find.byKey(SalleOrdinateur.cleGauche),
                find.byKey(SalleOrdinateur.cleCentre),
                find.byKey(SalleOrdinateur.cleDroite),
                find.byKey(SalleOrdinateur.cleBas),
              ]);
              verifierUnSeulBoutonPlein(tester);
              final int cartes = verifierAucuneCarteCollee(
                tester,
                estCarte: _carte,
              );
              // A 720 et texte x2, les cartes peuvent etre sous le pli de leur
              // liste : la regle s'y verifie sur celles qui sont rendues.
              if (taille.height >= 900) expect(cartes, greaterThan(0));
              verifierAucunMotCoupe(tester, find.byKey(SalleOrdinateur.cleBas));
              // Decision du directeur du 26/10/2026 : une tuile se place du
              // cote du panneau qu'elle ouvre, en arabe comme en francais.
              final double filet = tester
                  .getCenter(
                    find.byKey(const ValueKey<String>('salle-barre-filet')),
                  )
                  .dx;
              bool memeCote(String cle, Rect panneau) {
                final double x = tester
                    .getCenter(find.byKey(ValueKey<String>(cle)))
                    .dx;
                return (x < filet) == (panneau.center.dx < filet);
              }

              expect(memeCote('salle-eleves', gauche), isTrue);
              expect(memeCote('salle-bibliotheque', droite), isTrue);
            });
          }
        }
      }
    });
  }

  testWidgets('eleve, 1440 : aucun panneau, aucune liste d eleves', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: 'student');
    expect(tester.takeException(), isNull);
    expect(find.byType(SalleOrdinateur), findsNothing);
    expect(find.byType(PanneauEleves), findsNothing);
    expect(find.byType(PanneauBibliothequeSalle), findsNothing);
    expect(find.byType(BarreOutilsSalle), findsNothing);
    // Q2 (directeur, 26/10) : aucune liste d'eleves. La galerie video de la
    // scene (existante, hors de ce lot) reste, et le rapport le dit.
    expect(
      find.byKey(const ValueKey<String>('salle-ordinateur-eleves')),
      findsNothing,
    );
  });

  testWidgets('1440 : un eleve deplie sur place, la Bibliotheque depliee, '
      'toujours un seul bouton plein ; focus ; barre d outils', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    if (dossierCapture != null) await capturerVue(tester, 'salle-1440-repos');

    final Finder ilyes = find.descendant(
      of: find.byType(PanneauEleves),
      matching: find.text('Ilyes'),
    );
    await tester.tap(ilyes);
    await tester.pumpAndSettle();
    // Les deux actions qui aboutissent dans `/salle` : reciter, rappeler.
    expect(find.text(t.salle.seance.faireReciter), findsOneWidget);
    expect(find.text(t.salle.seance.rappeler), findsOneWidget);
    expect(find.byType(AppBottomSheet), findsNothing);
    if (dossierCapture != null) {
      await capturerVue(tester, 'salle-1440-eleve-deplie');
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('bibliotheque-presenter-coran')),
      findsOneWidget,
    );
    verifierUnSeulBoutonPlein(tester);
    if (dossierCapture != null) {
      await capturerVue(tester, 'salle-1440-bibliotheque-depliee');
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(find.byKey(SalleOrdinateur.cleGauche), findsNothing);
    if (dossierCapture != null) await capturerVue(tester, 'salle-1440-focus');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('salle-outil-ecrire')));
    await tester.pumpAndSettle();
    expect(find.byKey(BarreOutilsSalle.cle), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (dossierCapture != null) {
      await capturerVue(tester, 'salle-1440-barre-outils');
    }
  });

  // K-56 (pilote, 26/10/2026) : la page presentee en erreur garde
  // « Reessayer » comme seul bouton plein ; « Presenter » passe en contour.
  testWidgets('page en erreur, Bibliotheque depliee : un seul bouton plein', (
    WidgetTester tester,
  ) async {
    await _monter(tester, pageLisible: false);
    expect(find.text(t.commun.reessayer), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
    );
    await tester.pumpAndSettle();
    final ActionPrincipale presenter = tester.widget<ActionPrincipale>(
      find.byKey(const ValueKey<String>('bibliotheque-presenter-coran')),
    );
    expect(presenter.niveau, NiveauAction.secondaire);
    verifierUnSeulBoutonPlein(tester);
  });

  // Revue de la PR 61 : Plus, puis Bibliotheque. Les Commandes se ferment et
  // la Bibliotheque prend la droite ; la fermer laisse la droite vide.
  testWidgets('Commandes ouvertes, Bibliotheque demandee : les Commandes se '
      'ferment, la Bibliotheque s ouvre', (WidgetTester tester) async {
    await _monter(tester);
    const Key commandes = ValueKey<String>('salle-ordinateur-commandes');
    await tester.tap(find.byKey(BoutonPlusAppel.cle));
    await tester.pumpAndSettle();
    expect(find.byKey(commandes), findsOneWidget);
    expect(find.byType(PanneauBibliothequeSalle), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('salle-bibliotheque')));
    await tester.pumpAndSettle();
    expect(find.byType(PanneauBibliothequeSalle), findsOneWidget);
    expect(find.byKey(commandes), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('bibliotheque-fermer')));
    await tester.pumpAndSettle();
    expect(find.byKey(SalleOrdinateur.cleDroite), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('barre du bas : une barre sombre, deux groupes de tuiles '
      'nommees, un filet entre eux, cibles de 48', (WidgetTester tester) async {
    await _monter(tester);
    final Rect barre = tester.getRect(find.byKey(SalleOrdinateur.cleBas));
    expect(barre.width, greaterThan(1440 - 2 * 16 - 1));
    expect(
      find.byKey(const ValueKey<String>('salle-barre-filet')),
      findsOneWidget,
    );
    final Finder tuiles = find.byType(TuileCommandeSalle);
    expect(tuiles, findsNWidgets(9));
    for (final Element e in tuiles.evaluate()) {
      final Size taille = tester.getSize(find.byWidget(e.widget));
      expect(taille.height, greaterThanOrEqualTo(48));
      expect(taille.width, greaterThanOrEqualTo(48));
    }
    final List<TonTuileSalle> tons = <TonTuileSalle>[
      for (final TuileCommandeSalle t in tester.widgetList(tuiles)) t.ton,
    ];
    expect(
      tons.where((TonTuileSalle t) => t == TonTuileSalle.quitter),
      hasLength(1),
    );
    // Decision du directeur du 26/10/2026 : une tuile se place du cote du
    // panneau qu'elle ouvre. Quitter reste le dernier.
    List<String> noms(String groupe) => <String>[
      for (final TuileCommandeSalle t in tester.widgetList(
        find.descendant(
          of: find.byKey(ValueKey<String>(groupe)),
          matching: tuiles,
        ),
      ))
        t.nom,
    ];
    expect(noms('salle-commandes-gauche'), <String>[
      t.salle.seance.eleves,
      t.salle.seance.outils.pointeur,
      t.salle.seance.outils.ecrire,
      t.salle.seance.commandes.affichageTableau,
      t.tc.outils.trait.plus,
    ]);
    final List<String> droite = noms('salle-commandes-droite');
    expect(droite, hasLength(4));
    expect(droite[2], t.salle.seance.commandes.bibliotheque);
    expect(droite.last, t.salle.quitter);
    expect(
      tester.widgetList<TuileCommandeSalle>(tuiles).last.ton,
      TonTuileSalle.quitter,
    );
  });

  // Lot SALLE-ORDINATEUR, demandes du directeur du 11/11/2026, sur sa capture
  // de l'enseignant a 1440 x 900.
  group('SALLE-ORDINATEUR', () {
    Finder tuile(String nom) => find.byWidgetPredicate(
      (Widget w) => w is TuileCommandeSalle && w.nom == nom,
    );
    Finder cartesEleves() => find.byWidgetPredicate((Widget w) {
      final Key? cle = w.key;
      return cle is ValueKey<String> && cle.value.startsWith('eleve-');
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      group('A ${langue.languageCode}', () {
        setUp(() => LocaleSettings.setLocale(langue));
        testWidgets(
          'A ${langue.languageCode} : la video de l enseignant est en '
          'tete du panneau des Eleves, a sa largeur, au bord des cartes, en '
          '4:3 ; aucune autre vignette',
          (WidgetTester tester) async {
            await _monter(tester);
            final Finder panneau = find.byKey(
              const ValueKey<String>('salle-ordinateur-eleves'),
            );
            final Finder video = find.byKey(SalleOrdinateur.cleVideo);
            expect(
              find.descendant(of: panneau, matching: video),
              findsOneWidget,
            );
            // Une seule video de l'enseignant a l'ecran : plus rien ne flotte.
            expect(find.byType(VignetteVideo), findsOneWidget);
            final Rect v = tester.getRect(video);
            final Rect carte = tester.getRect(cartesEleves().first);
            expect(v.left, closeTo(carte.left, 0.5));
            expect(v.right, closeTo(carte.right, 0.5));
            expect(v.width / v.height, closeTo(4 / 3, 0.01));
            // Plus grande qu'une carte d'eleve, et au-dessus d'elles.
            expect(
              v.height,
              greaterThan(tester.getSize(cartesEleves().last).height),
            );
            expect(v.bottom, lessThan(carte.top));
            expect(tester.takeException(), isNull);
          },
        );
      });
    }

    testWidgets('A : panneau ferme, la video part avec lui (rien ne flotte) ; '
        'la camera allumee se lit dans la barre du bas', (
      WidgetTester tester,
    ) async {
      // La camera de l'enseignant est allumee.
      await _monter(tester, cameraEnseignant: true);
      expect(
        tester.widget<TuileCommandeSalle>(tuile(t.salle.camera)).ton,
        TonTuileSalle.repos,
      );
      await tester.tap(find.byKey(const ValueKey<String>('salle-eleves')));
      await tester.pumpAndSettle();
      expect(find.byKey(SalleOrdinateur.cleGauche), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleVideo), findsNothing);
      expect(find.byType(VignetteVideo), findsNothing);
      // Le signe que la camera tourne : la tuile Camera, au repos (pas le
      // violet « eteinte »), et son libelle « Eteindre la camera ».
      final TuileCommandeSalle camera = tester.widget<TuileCommandeSalle>(
        tuile(t.salle.camera),
      );
      expect(camera.ton, TonTuileSalle.repos);
      expect(camera.libelle, startsWith(t.salle.fermerCamera));
      if (dossierCapture != null) {
        await capturerVue(tester, 'enseignant_1440_panneau-ferme');
      }
      // Rouvert : la video revient, en tete.
      await tester.tap(find.byKey(const ValueKey<String>('salle-eleves')));
      await tester.pumpAndSettle();
      expect(find.byKey(SalleOrdinateur.cleVideo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      group('B ${langue.languageCode}', () {
        setUp(() => LocaleSettings.setLocale(langue));
        for (final Size taille in <Size>[
          const Size(1280, 800),
          const Size(1440, 900),
          const Size(1920, 1080),
        ]) {
          for (final double texte in <double>[1, 1.3]) {
            testWidgets(
              'B ${langue.languageCode} ${taille.width.toInt()}, texte '
              'x$texte : une rangee, la Classe au debut, le support et ses '
              'outils au centre, la pilule a la fin, rien ne se recouvre',
              (WidgetTester tester) async {
                await _monter(tester, taille: taille, texte: texte);
                expect(tester.takeException(), isNull);
                final Rect classe = tester.getRect(
                  find.byKey(SalleOrdinateur.cleClasse),
                );
                final Rect support = tester.getRect(
                  find.byKey(SalleOrdinateur.cleSupport),
                );
                final Rect pilule = tester.getRect(
                  find.byType(PiluleEtatSalle),
                );
                final Rect haut = tester.getRect(
                  find.byKey(SalleOrdinateur.cleHaut),
                );
                // Une seule rangee : les trois groupes dans la hauteur du haut.
                for (final Rect r in <Rect>[classe, support, pilule]) {
                  expect(r.top, greaterThanOrEqualTo(haut.top - 0.5));
                  expect(r.bottom, lessThanOrEqualTo(haut.bottom + 0.5));
                }
                // Le support est au centre de la largeur.
                expect(support.center.dx, closeTo(taille.width / 2, 1));
                // Les outils colles au titre du support, dans son groupe.
                for (final Key cle in <Key>[
                  SalleOrdinateur.cleTitreSupport,
                  SalleOrdinateur.cleFocus,
                  const ValueKey<String>('salle-ranger-support'),
                ]) {
                  expect(
                    find.descendant(
                      of: find.byKey(SalleOrdinateur.cleSupport),
                      matching: find.byKey(cle),
                    ),
                    findsOneWidget,
                  );
                }
                // Debut et fin suivent le sens de lecture.
                final bool rtl = langue == AppLocale.ar;
                if (rtl) {
                  expect(classe.left, greaterThan(support.right));
                  expect(pilule.right, lessThan(support.left));
                } else {
                  expect(classe.right, lessThan(support.left));
                  expect(pilule.left, greaterThan(support.right));
                }
                verifierSansChevauchement(tester, <Finder>[
                  find.byKey(SalleOrdinateur.cleClasse),
                  find.byKey(SalleOrdinateur.cleSupport),
                  find.byType(PiluleEtatSalle),
                ]);
                verifierUnSeulBoutonPlein(tester);
              },
            );
          }
        }
      });
    }

    testWidgets('B : repli, la rangee etroite perd d abord le nom de '
        'l enseignant, sans debordement', (WidgetTester tester) async {
      await _monter(tester);
      expect(find.byKey(SalleOrdinateur.cleEnseignant), findsOneWidget);
      await _monter(tester, taille: const Size(860, 720), texte: 2);
      expect(tester.takeException(), isNull);
      expect(find.byKey(SalleOrdinateur.cleClasse), findsOneWidget);
      expect(find.byKey(SalleOrdinateur.cleEnseignant), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleFocus), findsOneWidget);
      verifierSansChevauchement(tester, <Finder>[
        find.byKey(SalleOrdinateur.cleClasse),
        find.byKey(SalleOrdinateur.cleSupport),
        find.byType(PiluleEtatSalle),
      ]);
    });

    testWidgets(
      'C : la page prend toute la hauteur entre la rangee du haut '
      'et la barre du bas, panneau ouvert comme ferme (mesure a 1440 x 900)',
      (WidgetTester tester) async {
        // Les vraies polices : la largeur du texte se mesure avec elles.
        await tester.runAsync(() async {
          await chargerPolicesDuDepot();
          await chargerPoliceMadina15();
        });
        await _monter(tester);
        final Rect haut = tester.getRect(find.byKey(SalleOrdinateur.cleHaut));
        final Rect bas = tester.getRect(find.byKey(SalleOrdinateur.cleBas));
        final Rect boite = tester.getRect(
          find.byKey(TelephonePleinEcran.clePage),
        );
        final Size page = _texteDeLaPage(tester);
        // ignore: avoid_print
        print('C 1440x900, panneaux ouverts : boite $boite, texte $page');
        expect(boite.top, closeTo(haut.bottom + 16, 0.5));
        expect(boite.bottom, closeTo(bas.top - 16, 0.5));
        expect(boite.height, greaterThan(690));
        if (dossierCapture != null) {
          await capturerVue(tester, 'enseignant_1440_coran-grand');
        }
        await tester.tap(find.byKey(const ValueKey<String>('salle-eleves')));
        await tester.pumpAndSettle();
        final Rect boiteFermee = tester.getRect(
          find.byKey(TelephonePleinEcran.clePage),
        );
        final Size pageFermee = _texteDeLaPage(tester);
        // ignore: avoid_print
        print(
          'C 1440x900, Eleves ferme : boite $boiteFermee, page $pageFermee',
        );
        expect(boiteFermee.height, closeTo(boite.height, 0.5));
        expect(pageFermee.height, greaterThanOrEqualTo(page.height - 0.5));
      },
    );

    testWidgets('C : l eleve sur ordinateur, la page sur toute la hauteur', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await chargerPolicesDuDepot();
        await chargerPoliceMadina15();
      });
      await _monter(tester, role: 'student');
      final Rect boite = tester.getRect(
        find.byKey(TelephonePleinEcran.clePage),
      );
      // ignore: avoid_print
      print('C eleve 1440x900 : boite $boite, texte ${_texteDeLaPage(tester)}');
      expect(boite.height, closeTo(900, 0.5));
      if (dossierCapture != null) await capturerVue(tester, 'eleve_1440');
    });
  });

  // Captures du lot (CAPTURE_DIR seulement) : enseignant a 1440, clair,
  // sombre et arabe ; 1280 et 1920 ; eleve a 1440 en sombre.
  for (final (
        String nom,
        Size taille,
        ThemeMode theme,
        AppLocale langue,
        String role,
      )
      in <(String, Size, ThemeMode, AppLocale, String)>[
        (
          'enseignant_1440_clair',
          const Size(1440, 900),
          ThemeMode.light,
          AppLocale.fr,
          'teacher',
        ),
        (
          'enseignant_1440_sombre',
          const Size(1440, 900),
          ThemeMode.dark,
          AppLocale.fr,
          'teacher',
        ),
        (
          'enseignant_1440_arabe',
          const Size(1440, 900),
          ThemeMode.light,
          AppLocale.ar,
          'teacher',
        ),
        (
          'enseignant_1280_clair',
          const Size(1280, 800),
          ThemeMode.light,
          AppLocale.fr,
          'teacher',
        ),
        (
          'enseignant_1920_sombre',
          const Size(1920, 1080),
          ThemeMode.dark,
          AppLocale.fr,
          'teacher',
        ),
        (
          'eleve_1440_sombre',
          const Size(1440, 900),
          ThemeMode.dark,
          AppLocale.fr,
          'student',
        ),
      ]) {
    group('capture $nom', () {
      setUp(() => LocaleSettings.setLocale(langue));
      testWidgets('capture $nom', (WidgetTester tester) async {
        await _monter(tester, taille: taille, theme: theme, role: role);
        expect(tester.takeException(), isNull);
        await capturerVue(tester, nom);
      }, skip: dossierCapture == null);
    });
  }
}
