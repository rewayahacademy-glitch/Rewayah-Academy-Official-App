// Plan de composition du 26/10/2026 (point h) : la salle de l'enseignant sur
// ordinateur, a 1440 x 900 et 1280 x 720, texte x1 et x2, clair et sombre,
// francais et arabe (panneaux miroites : les Eleves a droite, la
// Bibliotheque a gauche en arabe). Un seul bouton plein, aucun chevauchement
// entre les zones, aucune carte collee ; l'eleve n'a ni panneau ni liste.
//
// Captures 1440 (repos, eleve deplie, bibliotheque depliee, focus, barre
// d'outils) seulement avec CAPTURE_DIR.

import 'dart:io' show Platform;
import 'dart:math' as math;

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
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_bibliotheque_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart'
    show TelephonePleinEcran, margeFlechePage;
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart'
    show cleLigneMadina15, ratioHauteurPageMadina15;

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
                find.byKey(SalleOrdinateur.cleTete),
                find.byKey(SalleOrdinateur.cleGauche),
                find.byKey(SalleOrdinateur.cleCentre),
                find.byKey(SalleOrdinateur.cleDroite),
                find.byKey(SalleOrdinateur.cleCommandes),
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
              // CORAN-GRAND (directeur, 11/11/2026) : la colonne des
              // commandes au bord de debut de lecture, avant les Eleves (ecart
              // date a la regle du 26/10 « une tuile du cote du panneau
              // qu'elle ouvre » : toutes les tuiles sont du meme cote).
              final Rect colonne = tester.getRect(
                find.byKey(SalleOrdinateur.cleCommandes),
              );
              if (langue == AppLocale.ar) {
                expect(colonne.left, greaterThan(gauche.right - 0.5));
              } else {
                expect(colonne.right, lessThan(gauche.left + 0.5));
              }
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

  // BARRE-ORDINATEUR (directeur, 11/11/2026) : la barre du bas de
  // l'enseignant sur ordinateur, simplifiee et regroupee. Remplace les tests
  // de la barre du 26/10 (deux groupes et « Plus »).
  group('BARRE-ORDINATEUR', () {
    final Finder tuiles = find.byType(TuileCommandeSalle);
    TuileCommandeSalle tuile(WidgetTester tester, String nom) =>
        tester.widget<TuileCommandeSalle>(
          find.byWidgetPredicate(
            (Widget w) => w is TuileCommandeSalle && w.nom == nom,
          ),
        );
    List<String> noms(WidgetTester tester, Key groupe) => <String>[
      for (final TuileCommandeSalle t in tester.widgetList(
        find.descendant(of: find.byKey(groupe), matching: tuiles),
      ))
        t.nom,
    ];
    Map<String, Rect> places(WidgetTester tester) => <String, Rect>{
      for (final Element e in tuiles.evaluate())
        (e.widget as TuileCommandeSalle).nom: tester.getRect(
          find.byWidget(e.widget),
        ),
    };
    List<String> tenues(WidgetTester tester) => <String>[
      for (final TuileCommandeSalle t in tester.widgetList(tuiles))
        if (t.ton == TonTuileSalle.retenu) t.nom,
    ];

    testWidgets('cinq groupes nommes, chaque tuile a sa place, aucun « Plus », '
        'un seul rouge, cibles de 48', (WidgetTester tester) async {
      await _monter(tester);
      expect(find.byKey(BoutonPlusAppel.cle), findsNothing);
      expect(noms(tester, const ValueKey<String>('salle-barre-voix')), <String>[
        t.salle.micro,
        t.salle.camera,
      ]);
      expect(
        noms(tester, const ValueKey<String>('salle-barre-classe')),
        <String>[t.salle.seance.eleves],
      );
      expect(noms(tester, const ValueKey<String>('salle-barre-page')), <String>[
        t.salle.seance.outils.pointeur,
        t.salle.seance.outils.ecrire,
      ]);
      expect(
        noms(tester, const ValueKey<String>('salle-barre-support')),
        <String>[
          t.salle.seance.commandes.bibliotheque,
          t.salle.seance.commandes.affichageTableau,
        ],
      );
      expect(
        noms(tester, const ValueKey<String>('salle-barre-sortir')),
        <String>[t.salle.sortie.reduireNom, t.salle.quitter],
      );
      // Les groupes se lisent par leur nom.
      for (final String nom in <String>[
        t.salle.barre.groupes.voix,
        t.salle.barre.groupes.classe,
        t.salle.barre.groupes.page,
        t.salle.barre.groupes.support,
        t.salle.barre.groupes.sortir,
      ]) {
        expect(find.bySemanticsLabel(nom), findsOneWidget);
      }
      for (final Element e in tuiles.evaluate()) {
        final Size taille = tester.getSize(find.byWidget(e.widget));
        expect(taille.height, greaterThanOrEqualTo(48));
        expect(taille.width, greaterThanOrEqualTo(48));
      }
      expect(
        tester
            .widgetList<TuileCommandeSalle>(tuiles)
            .where((TuileCommandeSalle t) => t.ton == TonTuileSalle.quitter),
        hasLength(1),
      );
      // Au repos, rien n'est tenu et rien n'est violet sans raison : le
      // tableau ferme est au repos, plus « coupe ».
      expect(tenues(tester), isEmpty);
      expect(
        tuile(tester, t.salle.seance.commandes.affichageTableau).ton,
        TonTuileSalle.repos,
      );
      // CORAN-GRAND : une seule colonne, toutes les tuiles a la meme largeur,
      // dans l'ordre des groupes de haut en bas ; Quitter tout en bas.
      final Map<String, Rect> p = places(tester);
      expect(<double>{
        for (final Rect r in p.values) r.left.roundToDouble(),
      }, hasLength(1));
      expect(<double>{
        for (final Rect r in p.values) r.width.roundToDouble(),
      }, hasLength(1));
      final List<String> ordre = <String>[
        t.salle.micro,
        t.salle.camera,
        t.salle.seance.eleves,
        // GRILLE-COMMANDES (vraie application, 11/11/2026) : on ouvre un
        // document, puis on agit sur la page. Pointeur et Ecrire, qui ne
        // servent pas sans document, sont le dernier groupe du haut : leur
        // place vide ne fait plus un trou au milieu de la colonne.
        t.salle.seance.commandes.bibliotheque,
        t.salle.seance.commandes.affichageTableau,
        t.salle.seance.outils.pointeur,
        t.salle.seance.outils.ecrire,
        t.salle.sortie.reduireNom,
        t.salle.quitter,
      ];
      for (int i = 1; i < ordre.length; i++) {
        expect(p[ordre[i]]!.top, greaterThan(p[ordre[i - 1]]!.bottom - 0.5));
      }
      // Les noms sont peints a 1440 x 900 (la colonne a la hauteur).
      expect(
        find.byKey(const ValueKey<String>('nom-commande')),
        findsNWidgets(ordre.length),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('un seul outil tenu a la fois, dit par trois signaux ; le '
        'tableau ouvert se lit par le trait ; rien ne bouge', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final Map<String, Rect> avant = places(tester);
      final IconData pointeurAuRepos = tuile(
        tester,
        t.salle.seance.outils.pointeur,
      ).icone;
      final Rect page = tester.getRect(find.byKey(TelephonePleinEcran.clePage));

      await tester.tap(
        find.byKey(const ValueKey<String>('salle-outil-pointeur')),
      );
      await tester.pumpAndSettle();
      expect(tenues(tester), <String>[t.salle.seance.outils.pointeur]);
      final TuileCommandeSalle pointeur = tuile(
        tester,
        t.salle.seance.outils.pointeur,
      );
      expect(pointeur.selectionne, isTrue);
      // L'icone pleine : le deuxieme signal, apres l'aplat.
      expect(pointeur.icone, isNot(pointeurAuRepos));
      expect(
        pointeur.infobulle,
        startsWith(
          t.salle.barre.outilTenu(outil: t.salle.seance.outils.pointeur),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('salle-outil-ecrire')),
      );
      await tester.pumpAndSettle();
      expect(tenues(tester), <String>[t.salle.seance.outils.ecrire]);
      // La palette se pose contre la page, du cote d'Ecrire ; la page ne
      // bouge pas d'un point, aucune tuile non plus.
      final Rect palette = tester.getRect(find.byKey(BarreOutilsSalle.cle));
      final Rect pageApres = tester.getRect(
        find.byKey(TelephonePleinEcran.clePage),
      );
      expect(pageApres.height, closeTo(page.height, 0.5));
      expect(pageApres.top, closeTo(page.top, 0.5));
      expect(palette.right, lessThanOrEqualTo(pageApres.left + 0.5));
      expect(pageApres.width, closeTo(page.width, 0.5));
      // CORAN-GRAND : la palette prend la place du panneau des Eleves.
      final Rect gauche = tester.getRect(find.byKey(SalleOrdinateur.cleGauche));
      expect(palette.left, greaterThanOrEqualTo(gauche.left - 0.5));
      expect(palette.right, lessThanOrEqualTo(gauche.right + 0.5));
      expect(
        palette.overlaps(
          tester.getRect(find.byKey(SalleOrdinateur.cleCommandes)),
        ),
        isFalse,
      );
      expect(places(tester), avant);

      await tester.tap(find.byKey(const ValueKey<String>('bouton-tableau')));
      await tester.pumpAndSettle();
      final TuileCommandeSalle tableau = tuile(
        tester,
        t.salle.seance.commandes.affichageTableau,
      );
      expect(tableau.ton, TonTuileSalle.ouvert);
      expect(tableau.selectionne, isTrue);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('bouton-tableau')),
          matching: find.byKey(const ValueKey<String>('trait-ouvert')),
        ),
        findsOneWidget,
      );
      // Le panneau des Eleves se ferme : sa tuile perd son trait, rien ne
      // glisse dans la barre.
      await tester.tap(find.byKey(const ValueKey<String>('salle-eleves')));
      await tester.pumpAndSettle();
      expect(tuile(tester, t.salle.seance.eleves).ton, TonTuileSalle.repos);
      expect(places(tester), avant);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clavier : P, E, T, Echap ; la touche dans l infobulle', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(
        tuile(tester, t.salle.seance.outils.pointeur).infobulle,
        t.salle.barre.infobulle(
          etat: t.salle.seance.outils.pointeur,
          touche: 'P',
        ),
      );
      expect(tuile(tester, t.salle.seance.eleves).infobulle, contains('R'));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();
      expect(tenues(tester), <String>[t.salle.seance.outils.pointeur]);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(tenues(tester), <String>[t.salle.seance.outils.ecrire]);
      expect(find.byKey(BarreOutilsSalle.cle), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tenues(tester), isEmpty);
      expect(find.byKey(BarreOutilsSalle.cle), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();
      expect(
        tuile(tester, t.salle.seance.commandes.affichageTableau).ton,
        TonTuileSalle.ouvert,
      );
      expect(tester.takeException(), isNull);
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      group('langue ${langue.languageCode}', () {
        setUp(() => LocaleSettings.setLocale(langue));
        for (final Size taille in <Size>[
          const Size(1280, 800),
          const Size(1440, 900),
          const Size(1920, 1080),
        ]) {
          for (final double texte in <double>[1, 1.3]) {
            for (final ThemeMode theme in <ThemeMode>[
              ThemeMode.light,
              ThemeMode.dark,
            ]) {
              testWidgets('${langue.languageCode} ${taille.width.toInt()}, '
                  'texte x$texte, ${theme.name} : une rangee, aucun mot coupe, '
                  'la palette contre la page sans la recouvrir', (
                WidgetTester tester,
              ) async {
                await _monter(
                  tester,
                  taille: taille,
                  texte: texte,
                  theme: theme,
                );
                await tester.tap(
                  find.byKey(const ValueKey<String>('salle-outil-ecrire')),
                );
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                verifierAucunMotCoupe(
                  tester,
                  find.byKey(SalleOrdinateur.cleBas),
                );
                // CORAN-GRAND : une seule colonne, a toutes les tailles.
                expect(<double>{
                  for (final Rect r in places(tester).values)
                    r.left.roundToDouble(),
                }, hasLength(1));
                final Rect palette = tester.getRect(
                  find.byKey(BarreOutilsSalle.cle),
                );
                final Rect page = tester.getRect(
                  find.byKey(TelephonePleinEcran.clePage),
                );
                // La palette est du cote du debut de lecture, contre la page.
                if (langue == AppLocale.ar) {
                  expect(palette.left, greaterThanOrEqualTo(page.right - 0.5));
                } else {
                  expect(palette.right, lessThanOrEqualTo(page.left + 0.5));
                }
                verifierSansChevauchement(tester, <Finder>[
                  find.byKey(SalleOrdinateur.cleTete),
                  find.byKey(BarreOutilsSalle.cle),
                  find.byKey(SalleOrdinateur.cleCentre),
                  find.byKey(SalleOrdinateur.cleCommandes),
                ]);
                verifierUnSeulBoutonPlein(tester);
              });
            }
          }
        }
      });
    }
  });

  // Les mots de la palette se mesurent avec les vraies polices (la police
  // de test peint chaque lettre en carre de 14 : « Moyen » y prend 70).
  for (final double texte in <double>[1, 1.3]) {
    testWidgets('BARRE-ORDINATEUR, vraies polices, 1280x800, texte x$texte : '
        'aucun mot coupe dans la palette ni dans la barre', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await chargerPolicesDuDepot();
        await chargerPoliceMadina15();
      });
      await _monter(tester, taille: const Size(1280, 800), texte: texte);
      await tester.tap(
        find.byKey(const ValueKey<String>('salle-outil-ecrire')),
      );
      await tester.pumpAndSettle();
      verifierAucunMotCoupe(tester, find.byKey(BarreOutilsSalle.cle));
      verifierAucunMotCoupe(tester, find.byKey(SalleOrdinateur.cleBas));
      final Set<double> bords = <double>{
        for (final Element e in find.byType(TuileCommandeSalle).evaluate())
          tester.getRect(find.byWidget(e.widget)).left.roundToDouble(),
      };
      expect(bords, hasLength(1), reason: 'la colonne tient sur une colonne');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('captures BARRE-ORDINATEUR', (WidgetTester tester) async {
    final String? dossier = dossierCapture;
    if (dossier == null) return;
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      final String th = theme == ThemeMode.light ? 'clair' : 'sombre';
      await _monter(tester, theme: theme);
      await capturerVue(tester, 'barre_1440_repos_$th');
      await tester.tap(
        find.byKey(const ValueKey<String>('salle-outil-ecrire')),
      );
      await tester.pumpAndSettle();
      await capturerVue(tester, 'barre_1440_ecrire-tenu_$th');
      await tester.tap(
        find.byKey(const ValueKey<String>('salle-outil-ecrire')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('salle-outil-pointeur')),
      );
      await tester.pumpAndSettle();
      await capturerVue(tester, 'barre_1440_pointeur-tenu_$th');
    }
    await _monter(tester, taille: const Size(1280, 800));
    await capturerVue(tester, 'barre_1280_repos_clair');
    await _monter(tester, taille: const Size(1920, 1080), texte: 1.3);
    await capturerVue(tester, 'barre_1920_texte-1.3_clair');
  });

  group('captures arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    testWidgets('captures BARRE-ORDINATEUR en arabe', (
      WidgetTester tester,
    ) async {
      if (dossierCapture == null) return;
      await _monter(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('salle-outil-ecrire')),
      );
      await tester.pumpAndSettle();
      await capturerVue(tester, 'barre_1440_arabe_ecrire-tenu');
    });
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
          'A ${langue.languageCode} : le cadre de l enseignant est en tete '
          'du panneau des Eleves, sous sa tete, sur TOUTE la largeur du '
          'panneau (directeur, 11/11 soir), au plus le sixieme de l ecran ; '
          'aucune autre vignette',
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
            // RUBAN-ORDINATEUR : l'enseignant est un cadre de la salle
            // (CadreVisage) ; plus aucune VignetteVideo, rien ne flotte.
            expect(find.byType(VignetteVideo), findsNothing);
            final Rect v = tester.getRect(video);
            final Rect carte = tester.getRect(cartesEleves().first);
            expect(v.left, greaterThanOrEqualTo(carte.left - 0.5));
            expect(v.right, lessThanOrEqualTo(carte.right + 0.5));
            expect(v.center.dx, closeTo(carte.center.dx, 1));
            final double hauteurEcran =
                tester.view.physicalSize.height / tester.view.devicePixelRatio;
            final Size attendue = tailleCadreEnseignant(
              largeur: carte.width,
              hauteurEcran: hauteurEcran,
            );
            expect(v.size, attendue);
            // Aligne sur les cartes des eleves, bord a bord : il ne flotte
            // plus au milieu du panneau.
            expect(v.left, closeTo(carte.left, 1));
            expect(v.right, closeTo(carte.right, 1));
            // Jamais plus haut que 4:3, jamais plus du sixieme de l'ecran.
            expect(v.width / v.height, greaterThanOrEqualTo(4 / 3 - 0.02));
            expect(v.height, lessThanOrEqualTo(hauteurEcran / 6 + 0.5));
            // Plus grand qu'une carte d'eleve, et au-dessus d'elles ; sous la
            // tete du panneau.
            expect(
              v.height,
              greaterThan(tester.getSize(cartesEleves().last).height),
            );
            expect(v.bottom, lessThan(carte.top));
            expect(
              tester.getRect(find.byKey(SalleOrdinateur.cleTeteEleves)).bottom,
              lessThan(v.top),
            );
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

    // CORAN-GRAND (directeur, 11/11/2026) : la page prend toute la hauteur ;
    // tout ce qui n'est pas elle est dans la colonne, les panneaux ou les
    // marges de la page ; rien ne la recouvre. Quatre tailles, panneaux
    // ouverts et fermes, clair et sombre, francais et arabe, texte x1 et x1,3.
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      group('B ${langue.languageCode}', () {
        setUp(() => LocaleSettings.setLocale(langue));
        for (final Size taille in <Size>[
          const Size(1280, 720),
          const Size(1280, 800),
          const Size(1440, 900),
          const Size(1920, 1080),
        ]) {
          for (final double texte in <double>[1, 1.3]) {
            for (final ThemeMode theme in <ThemeMode>[
              ThemeMode.light,
              ThemeMode.dark,
            ]) {
              for (final bool ouverts in <bool>[true, false]) {
                testWidgets('B ${langue.languageCode} ${taille.width.toInt()}x'
                    '${taille.height.toInt()}, texte x$texte, ${theme.name}, '
                    'panneaux ${ouverts ? 'ouverts' : 'fermes'} : la page a '
                    'toute la hauteur, ses fleches et ses outils a cote, rien '
                    'ne la recouvre', (WidgetTester tester) async {
                  await _monter(
                    tester,
                    taille: taille,
                    texte: texte,
                    theme: theme,
                  );
                  if (!ouverts) {
                    await tester.tap(
                      find.byKey(const ValueKey<String>('salle-eleves')),
                    );
                    await tester.pumpAndSettle();
                    if (find
                        .byKey(SalleOrdinateur.cleDroite)
                        .evaluate()
                        .isNotEmpty) {
                      await tester.tap(
                        find.byKey(
                          const ValueKey<String>('salle-bibliotheque'),
                        ),
                      );
                      await tester.pumpAndSettle();
                    }
                    expect(find.byKey(SalleOrdinateur.cleGauche), findsNothing);
                    expect(find.byKey(SalleOrdinateur.cleDroite), findsNothing);
                  }
                  expect(tester.takeException(), isNull);
                  final Rect page = tester.getRect(
                    find.byKey(TelephonePleinEcran.clePage),
                  );
                  final Rect centre = tester.getRect(
                    find.byKey(SalleOrdinateur.cleCentre),
                  );
                  // Toute la hauteur que la largeur permet, fleches
                  // comprises ; panneaux fermes, toute la hauteur de
                  // l'ecran, aux marges pres.
                  final double attendue = math.min(
                    centre.height,
                    (centre.width - 2 * margeFlechePage) *
                        ratioHauteurPageMadina15,
                  );
                  expect(page.height, closeTo(attendue, 1));
                  expect(page.center.dy, closeTo(centre.center.dy, 0.5));
                  if (!ouverts) {
                    expect(page.height, closeTo(taille.height - 32, 0.5));
                  }
                  // Les fleches restent, a mi-hauteur de la page.
                  expect(
                    find.byKey(const ValueKey<String>('fleches-page-salle')),
                    findsOneWidget,
                  );
                  final Rect zoom = tester.getRect(
                    find.byKey(const ValueKey<String>('salle-zoom')),
                  );
                  final Rect outils = tester.getRect(
                    find.byKey(SalleOrdinateur.cleSupport),
                  );
                  // GRILLE-COMMANDES (11/11/2026) : ranger, focus et zoom
                  // sont UNE pile, dans la marge de fin, au-dessus de la
                  // fleche, dans le centre.
                  final bool rtl = langue == AppLocale.ar;
                  if (rtl) {
                    expect(outils.right, lessThanOrEqualTo(page.left + 0.5));
                  } else {
                    expect(outils.left, greaterThanOrEqualTo(page.right - 0.5));
                  }
                  expect(outils.contains(zoom.center), isTrue);
                  expect(zoom.center.dx, closeTo(outils.center.dx, 0.5));
                  for (final Rect r in <Rect>[zoom, outils]) {
                    expect(r.top, greaterThanOrEqualTo(centre.top - 0.5));
                    expect(r.bottom, lessThan(page.center.dy - 32));
                  }
                  verifierSansChevauchement(tester, <Finder>[
                    find.byKey(TelephonePleinEcran.clePage),
                    find.byKey(SalleOrdinateur.cleTete),
                    find.byKey(SalleOrdinateur.cleCommandes),
                    find.byKey(SalleOrdinateur.cleSupport),
                    if (ouverts) ...<Finder>[
                      find.byKey(SalleOrdinateur.cleGauche),
                      find.byKey(SalleOrdinateur.cleDroite),
                    ],
                  ]);
                  // La colonne au bord de debut, dans l'ecran, sans
                  // defilement.
                  final Rect colonne = tester.getRect(
                    find.byKey(SalleOrdinateur.cleCommandes),
                  );
                  expect(colonne.top, greaterThanOrEqualTo(0));
                  expect(colonne.bottom, lessThanOrEqualTo(taille.height));
                  if (rtl) {
                    expect(colonne.right, closeTo(taille.width - 16, 0.5));
                  } else {
                    expect(colonne.left, closeTo(16, 0.5));
                  }
                  expect(
                    find.descendant(
                      of: find.byKey(SalleOrdinateur.cleCommandes),
                      matching: find.byType(Scrollable),
                    ),
                    findsNothing,
                  );
                  verifierUnSeulBoutonPlein(tester);
                });
              }
            }
          }
        }
      });
    }

    testWidgets('B : repli, la colonne garde ses neuf tuiles sans defiler ; '
        'quand la hauteur manque, les noms partent (icone et infobulle)', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await chargerPolicesDuDepot();
        await chargerPoliceMadina15();
      });
      final Finder noms = find.byKey(const ValueKey<String>('nom-commande'));
      await _monter(tester);
      // GRILLE-COMMANDES : la tete ne porte plus le nom de la Classe.
      expect(find.byKey(SalleOrdinateur.cleClasse), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleTitreSupport), findsOneWidget);
      expect(noms, findsNWidgets(9));
      // 1280 x 720, texte x1,3 : la colonne ne tient plus avec les noms.
      await _monter(tester, taille: const Size(1280, 720), texte: 1.3);
      expect(tester.takeException(), isNull);
      expect(noms, findsNothing);
      expect(find.byType(TuileCommandeSalle), findsNWidgets(9));
      for (final TuileCommandeSalle tuile in tester.widgetList(
        find.byType(TuileCommandeSalle),
      )) {
        expect(tuile.infobulle, isNotNull);
      }
      // Le plus petit ordinateur, texte x2 : rien ne deborde, le focus reste.
      await _monter(tester, taille: const Size(860, 720), texte: 2);
      expect(tester.takeException(), isNull);
      expect(find.byKey(SalleOrdinateur.cleFocus), findsOneWidget);
      expect(find.byType(TuileCommandeSalle), findsNWidgets(9));
    });

    testWidgets(
      'C : la page prend toute la hauteur de l ecran, aux marges pres '
      '(mesure a 1440 x 900, vraies polices)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await chargerPolicesDuDepot();
          await chargerPoliceMadina15();
        });
        await _monter(tester);
        final Rect boite = tester.getRect(
          find.byKey(TelephonePleinEcran.clePage),
        );
        // Panneaux ouverts : la largeur borne un peu la page (moins de 3 %).
        expect(boite.height, greaterThan(840));
        await tester.tap(find.byKey(const ValueKey<String>('salle-eleves')));
        await tester.pumpAndSettle();
        final Rect fermee = tester.getRect(
          find.byKey(TelephonePleinEcran.clePage),
        );
        expect(fermee.top, closeTo(16, 0.5));
        expect(fermee.height, closeTo(900 - 32, 0.5));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('C : focus (F), la page seule a pleine hauteur ; il reste la '
        'colonne en icones, l ile, et les outils contre la page', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1280, 720));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      expect(find.byKey(SalleOrdinateur.cleGauche), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleDroite), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleClasse), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleTitreSupport), findsNothing);
      expect(find.byType(DynamiqueChrono), findsOneWidget);
      expect(find.byKey(SalleOrdinateur.cleFocus), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nom-commande')), findsNothing);
      expect(find.byType(TuileCommandeSalle), findsNWidgets(9));
      final Rect page = tester.getRect(find.byKey(TelephonePleinEcran.clePage));
      expect(page.height, closeTo(720 - 32, 0.5));
      verifierSansChevauchement(tester, <Finder>[
        find.byKey(TelephonePleinEcran.clePage),
        find.byKey(SalleOrdinateur.cleTete),
        find.byKey(SalleOrdinateur.cleCommandes),
        find.byKey(SalleOrdinateur.cleSupport),
      ]);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      expect(find.byKey(SalleOrdinateur.cleGauche), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

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

  // CORAN-GRAND (directeur, 11/11/2026 : « Sur PC, il faut que le Coran soit
  // grand ») : la taille du texte de la page de l'enseignant, avec les vraies
  // polices, panneaux ouverts puis fermes. Ce test tourne avant et apres le
  // lot (il ne lit que la page et les tuiles Eleves et Bibliotheque) ; les
  // chiffres sont dans docs/current/UX_REVIEW_CORAN-GRAND.md.
  for (final Size taille in <Size>[
    const Size(1440, 900),
    const Size(1280, 720),
  ]) {
    testWidgets('CORAN-GRAND mesure ${taille.width.toInt()}x'
        '${taille.height.toInt()} : texte de la page, panneaux ouverts puis '
        'fermes', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await chargerPolicesDuDepot();
        await chargerPoliceMadina15();
      });
      await _monter(tester, taille: taille);
      final String nom = '${taille.width.toInt()}x${taille.height.toInt()}';
      final Size ouverts = _texteDeLaPage(tester);
      final Rect boiteOuverts = tester.getRect(
        find.byKey(TelephonePleinEcran.clePage),
      );
      final String? capture = Platform.environment['CORAN_GRAND_ETIQUETTE'];
      if (dossierCapture != null && capture != null) {
        await capturerVue(tester, '${capture}_${nom}_panneaux-ouverts');
      }
      await tester.tap(find.byKey(const ValueKey<String>('salle-eleves')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('salle-bibliotheque')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SalleOrdinateur.cleGauche), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleDroite), findsNothing);
      final Size fermes = _texteDeLaPage(tester);
      final Rect boiteFermes = tester.getRect(
        find.byKey(TelephonePleinEcran.clePage),
      );
      if (dossierCapture != null && capture != null) {
        await capturerVue(tester, '${capture}_${nom}_panneaux-fermes');
      }
      // ignore: avoid_print
      print(
        'CORAN-GRAND $nom ouverts : texte ${ouverts.width.toStringAsFixed(0)}'
        ' x ${ouverts.height.toStringAsFixed(0)} (boite $boiteOuverts) ; '
        'fermes : texte ${fermes.width.toStringAsFixed(0)} x '
        '${fermes.height.toStringAsFixed(0)} (boite $boiteFermes)',
      );
      expect(tester.takeException(), isNull);
    });
  }

  // Captures CORAN-GRAND (CAPTURE_DIR et CORAN_GRAND_ETIQUETTE : « avant »
  // sur la base, « apres » sur le lot) : vraies polices, fond de la salle.
  for (final (
        String nom,
        Size taille,
        ThemeMode theme,
        AppLocale langue,
        bool focus,
      )
      in <(String, Size, ThemeMode, AppLocale, bool)>[
        (
          '1440x900_clair',
          const Size(1440, 900),
          ThemeMode.light,
          AppLocale.fr,
          false,
        ),
        (
          '1440x900_sombre',
          const Size(1440, 900),
          ThemeMode.dark,
          AppLocale.fr,
          false,
        ),
        (
          '1440x900_arabe',
          const Size(1440, 900),
          ThemeMode.light,
          AppLocale.ar,
          false,
        ),
        (
          '1440x900_focus',
          const Size(1440, 900),
          ThemeMode.light,
          AppLocale.fr,
          true,
        ),
        (
          '1280x720_sombre',
          const Size(1280, 720),
          ThemeMode.dark,
          AppLocale.fr,
          false,
        ),
        (
          '1280x720_arabe',
          const Size(1280, 720),
          ThemeMode.light,
          AppLocale.ar,
          false,
        ),
        (
          '1280x720_focus',
          const Size(1280, 720),
          ThemeMode.dark,
          AppLocale.fr,
          true,
        ),
      ]) {
    group('CORAN-GRAND capture $nom', () {
      setUp(() => LocaleSettings.setLocale(langue));
      testWidgets('CORAN-GRAND capture $nom', (WidgetTester tester) async {
        final String? etiquette = Platform.environment['CORAN_GRAND_ETIQUETTE'];
        if (dossierCapture == null || etiquette == null) return;
        await tester.runAsync(() async {
          await chargerPolicesDuDepot();
          await chargerPoliceMadina15();
        });
        await _monter(tester, taille: taille, theme: theme);
        // L'ile au repos : la mention de l'entree se replie apres 10 s.
        await tester.pump(const Duration(seconds: 11));
        await tester.pumpAndSettle();
        if (focus) {
          await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await capturerVue(tester, '${etiquette}_$nom');
      });
    });
  }
}
