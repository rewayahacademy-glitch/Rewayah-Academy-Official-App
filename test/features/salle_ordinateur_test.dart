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
import 'package:rewayah_academy/features/salle_seance/panneau_bibliotheque_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';

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
  });
}
