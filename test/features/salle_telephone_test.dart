// Fiche 1 (26/10/2026, docs/current/maquettes/salle/
// FICHE-1-TELEPHONE-2026-10-26.md) : la salle de l'enseignant au telephone et
// sur l'iPad en portrait, a 390 x 844 et 834 x 1194, texte x1 et x2,
// francais et arabe. Un test par ligne de la fiche, nomme « ligne N ».
//
// Captures (fiche, « Captures a produire ») seulement avec CAPTURE_DIR.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/barre_outils_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_bibliotheque_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart'
    show PanneauSeance;
import 'package:rewayah_academy/features/salle_seance/pilule_etat_salle.dart';
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
    _personne('e1', 'student', role == 'student'),
    _personne('e2', 'student', false),
  ]);
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
Future<void> _toucher(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();
}

/// Ouvre le tiroir des Commandes (« Commandes » au toucher, ligne 3).
Future<void> _ouvrirTiroir(WidgetTester tester) async {
  await _toucher(tester);
  await tester.tap(find.byKey(TelephonePleinEcran.cleCommandesToucher));
  await tester.pumpAndSettle();
}

/// Les textes et icones touchables a l'ecran (ce qu'on voit et qu'on peut
/// toucher), hors des zones [permises] ; la page elle-meme est toujours
/// permise.
List<({String texte, Rect cadre})> _horsDe(
  WidgetTester tester,
  List<Finder> permises,
) {
  final List<({String texte, Rect cadre})> hors =
      <({String texte, Rect cadre})>[];
  final List<Finder> zones = <Finder>[
    find.byKey(TelephonePleinEcran.clePage),
    ...permises,
  ];
  for (final Element e in find.byType(RichText).hitTestable().evaluate()) {
    final bool dedans = zones.any(
      (Finder z) => find
          .descendant(of: z, matching: find.byWidget(e.widget))
          .evaluate()
          .isNotEmpty,
    );
    if (!dedans) {
      hors.add((
        texte: (e.widget as RichText).text.toPlainText(),
        cadre: tester.getRect(find.byWidget(e.widget)),
      ));
    }
  }
  return hors;
}

/// Ligne 14 : dans l'etat courant, rien ne se recouvre parmi les objets
/// poses sur la page, aucun mot coupe, cibles de 48 au moins.
void _verifierLigne14(WidgetTester tester, String etat) {
  expect(tester.takeException(), isNull, reason: etat);
  final List<Finder> objets = <Finder>[
    for (final Key k in <Key>[
      CapsuleVideoTelephone.cle,
      ProfilTelephone.cle,
      const ValueKey<String>('dock-seance'),
      TelephonePleinEcran.cleCommandesRepos,
      TelephonePleinEcran.cleCommandesToucher,
      TiroirCommandesTelephone.cle,
      FeuilleElevesTelephone.cle,
      const ValueKey<String>('salle-zoom'),
    ])
      if (find.byKey(k).hitTestable().evaluate().isNotEmpty) find.byKey(k),
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

/// Le bord de debut de l'ecran est-il a gauche ?
bool _ltr() => LocaleSettings.currentLocale != AppLocale.ar;

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

/// La pilule de l'appel posee en bas de la salle, sous le panneau [dedans].
Finder _piluleDuBas(WidgetTester tester, Finder dedans) {
  final Rect panneau = tester.getRect(dedans);
  return find.byWidgetPredicate((Widget w) {
    if (w.key != const ValueKey<String>('dock-seance')) return false;
    final Rect r = tester.getRect(find.byWidget(w));
    return r.top >= panneau.bottom - 0.5;
  });
}

/// La pilule de l'appel.
final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));

/// Ligne 12 : chaque commande se trouve au plus une fois a l'ecran (ce qu'on
/// voit et touche), par son nom peint et par sa cle.
void _aucuneCommandeEnDouble(WidgetTester tester, String etat) {
  final List<String> noms = <String>[
    t.salle.micro,
    t.salle.microCoupe,
    t.salle.camera,
    t.salle.cameraCoupee,
    t.salle.seance.eleves,
    t.salle.quitter,
    t.salle.seance.commandes.affichageTableau,
    t.salle.seance.outils.pointeur,
    t.salle.seance.outils.ecrire,
    t.salle.seance.commandes.declencheur,
  ];
  for (final String n in noms) {
    expect(
      find.text(n).hitTestable().evaluate().length,
      lessThanOrEqualTo(1),
      reason: '« $n » deux fois ($etat)',
    );
  }
  for (final String k in <String>[
    'bouton-micro',
    'bouton-tableau',
    'salle-eleves',
    'telephone-pilule-eleves',
    'telephone-capsule-voir',
    'salle-ranger-support',
  ]) {
    expect(
      find.byKey(ValueKey<String>(k)).hitTestable().evaluate().length,
      lessThanOrEqualTo(1),
      reason: '$k deux fois ($etat)',
    );
  }
}

bool _carte(Widget w) {
  final Key? cle = w.key;
  if (cle is! ValueKey<String>) return false;
  return cle.value.startsWith('eleve-') ||
      cle.value.startsWith('bibliotheque-support-');
}

void main() {
  // Les polices du depot, toujours : les largeurs mesurees sont celles de
  // l'appareil (la police de test peint des carres, deux fois plus larges).
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group(langue.languageCode, () {
      setUp(() => LocaleSettings.setLocale(langue));
      for (final Size taille in <Size>[_telephone, _ipad]) {
        for (final double texte in <double>[1, 2]) {
          final String nom =
              '${taille.width.toInt()}x${taille.height.toInt()}, '
              'texte x${texte.toInt()}';

          testWidgets('$nom : ligne 1, au repos, « Commandes » seul, la '
              'page sur tout l\'ecran', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            expect(find.byType(SalleOrdinateur), findsNothing);
            await _attendreLeRepos(tester);
            final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
            final Finder commandes = find.byKey(
              TelephonePleinEcran.cleCommandesRepos,
            );
            // Pilote C10 : la capsule suit le toucher, absente au repos.
            expect(capsule.hitTestable(), findsNothing);
            expect(commandes.hitTestable(), findsOneWidget);
            // Rien d'autre : ni pilule d'etat, ni Eleves, ni croix, ni texte.
            expect(_horsDe(tester, <Finder>[commandes]), isEmpty);
            expect(find.byType(PiluleEtatSalle), findsNothing);
            expect(
              find.byKey(const ValueKey<String>('salle-eleves')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey<String>('salle-ranger-support')),
              findsNothing,
            );
            // « Commandes » en bas au centre.
            final Rect k = tester.getRect(commandes);
            expect(k.center.dx, moreOrLessEquals(taille.width / 2, epsilon: 1));
            expect(k.top, greaterThan(taille.height * 3 / 4));
            // Pilote C10 (loi du 24/10) : aucune bande reservee, la page a
            // la hauteur de l'ecran et touche son haut.
            final Rect p = tester.getRect(
              find.byKey(TelephonePleinEcran.clePage),
            );
            expect(p.top, moreOrLessEquals(0, epsilon: 1));
            expect(p.height, moreOrLessEquals(taille.height, epsilon: 1));
            expect(tester.takeException(), isNull);
          });

          testWidgets('$nom : ligne 2, la capsule : vignette, point vert, '
              'oeil', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _attendreLeRepos(tester);
            final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
            // Pilote C10 : au repos rien, au toucher la capsule en haut au
            // centre.
            expect(capsule.hitTestable(), findsNothing);
            await _toucher(tester);
            expect(capsule.hitTestable(), findsOneWidget);
            final Rect haut = tester.getRect(capsule);
            expect(
              haut.center.dx,
              moreOrLessEquals(taille.width / 2, epsilon: 1),
            );
            expect(haut.bottom, lessThan(taille.height / 4));
            Finder dans(Finder f) => find.descendant(of: capsule, matching: f);
            final Finder vignette = dans(
              find.byKey(const ValueKey<String>('vignette-video')),
            );
            final Finder point = dans(find.byKey(PointEtatTelephone.cle));
            final Finder oeil = dans(find.byKey(CapsuleVideoTelephone.cleVoir));
            expect(vignette, findsOneWidget);
            expect(point, findsOneWidget);
            expect(oeil, findsOneWidget);
            // De gauche a droite (de droite a gauche en arabe).
            final double xv = tester.getCenter(vignette).dx;
            final double xp = tester.getCenter(point).dx;
            final double xo = tester.getCenter(oeil).dx;
            expect(_ltr() ? xv < xp && xp < xo : xv > xp && xp > xo, isTrue);
            // Vert : aucun enregistrement reel (A-01).
            final BuildContext ctx = tester.element(point);
            final BoxDecoration deco =
                tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: point,
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration;
            expect(
              deco.color,
              AppPalette.of(ctx).pointsStatut.succes.debugValue,
            );
            // Sombre : la surface des pilules de la salle.
            final BoxDecoration fond =
                tester
                        .widget<DecoratedBox>(
                          find
                              .descendant(
                                of: capsule,
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration;
            // C1 : la couche sombre, la meme dans les deux themes.
            expect(fond.color, AppPalette.of(ctx).coucheSalle.background);
            expect(fond.color, AppPalette.claire().surfaceInverse.background);
            // Rien d'autre en haut de l'ecran.
            final Rect c = tester.getRect(capsule);
            await _toucher(tester);
            expect(
              _horsDe(tester, <Finder>[
                capsule,
              ]).where((h) => h.cadre.top <= c.bottom),
              isEmpty,
              reason: 'en haut hors de la capsule',
            );
            // Elle se masque avec la pilule au delai.
            await _attendreLeRepos(tester);
            expect(capsule.hitTestable(), findsNothing);
          });

          testWidgets('$nom : ligne 3, au toucher la pilule, « Commandes » '
              'au-dessus, au bord de fin', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _attendreLeRepos(tester);
            final Finder dock = find.byKey(
              const ValueKey<String>('dock-seance'),
            );
            expect(dock.hitTestable(), findsNothing);
            await _toucher(tester);
            expect(dock.hitTestable(), findsOneWidget);
            // Pilote C10 : et la capsule apparait en haut.
            expect(
              find.byKey(CapsuleVideoTelephone.cle).hitTestable(),
              findsOneWidget,
            );
            final Finder commandes = find.byKey(
              TelephonePleinEcran.cleCommandesToucher,
            );
            expect(commandes.hitTestable(), findsOneWidget);
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesRepos),
              findsNothing,
            );
            // Au-dessus de la pilule, au bord de fin (16 du bord).
            final Rect k = tester.getRect(commandes);
            final Rect d = tester.getRect(dock);
            expect(k.bottom, lessThanOrEqualTo(d.top));
            expect(
              _ltr() ? taille.width - k.right : k.left,
              moreOrLessEquals(16, epsilon: 1),
            );
            // Au delai, tout se masque de nouveau.
            await _attendreLeRepos(tester);
            expect(dock.hitTestable(), findsNothing);
            expect(commandes.hitTestable(), findsNothing);
            expect(
              find.byKey(CapsuleVideoTelephone.cle).hitTestable(),
              findsNothing,
            );
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesRepos).hitTestable(),
              findsOneWidget,
            );
            // Un panneau ouvert : la pilule reste.
            await _ouvrirTiroir(tester);
            await _attendreLeRepos(tester);
            expect(
              _piluleDuBas(
                tester,
                find.byKey(TiroirCommandesTelephone.cle),
              ).hitTestable(),
              findsOneWidget,
            );
            // Et la capsule, tant que le panneau est ouvert.
            expect(
              find.byKey(CapsuleVideoTelephone.cle).hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            verifierUnSeulBoutonPlein(tester);
          });

          testWidgets('$nom : lignes 1 a 3, video en grand : la capsule seule, '
              '« Revenir a la page »', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _toucher(tester);
            await tester.tap(find.byKey(CapsuleVideoTelephone.cleVoir));
            await tester.pumpAndSettle();
            final Finder scene = find.byKey(
              const ValueKey<String>('telephone-scene'),
            );
            expect(scene, findsOneWidget);
            expect(find.byKey(TelephonePleinEcran.clePage), findsNothing);
            final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
            expect(capsule, findsOneWidget);
            expect(
              find.byKey(CapsuleVideoTelephone.cleRevenir).hitTestable(),
              findsOneWidget,
            );
            expect(find.byKey(CapsuleVideoTelephone.cleVoir), findsNothing);
            expect(
              find.byKey(const ValueKey<String>('revenir-page')),
              findsNothing,
            );
            expect(find.byType(PiluleEtatSalle), findsNothing);
            expect(
              find.byKey(const ValueKey<String>('salle-eleves')),
              findsNothing,
            );
            // Au repos : la capsule et « Commandes », rien d'autre hors de la
            // scene.
            await _attendreLeRepos(tester);
            final Finder commandes = find.byKey(
              TelephonePleinEcran.cleCommandesRepos,
            );
            // Pilote C10 : sur la scene, rien a proteger, la capsule reste.
            expect(capsule.hitTestable(), findsOneWidget);
            expect(commandes.hitTestable(), findsOneWidget);
            expect(
              _horsDe(tester, <Finder>[capsule, commandes, scene]),
              isEmpty,
            );
            // Au toucher : la pilule et « Commandes » au-dessus.
            await _toucher(tester);
            expect(_dock.hitTestable(), findsOneWidget);
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesToucher).hitTestable(),
              findsOneWidget,
            );
            // « Revenir a la page ».
            await tester.tap(find.byKey(CapsuleVideoTelephone.cleRevenir));
            await tester.pumpAndSettle();
            expect(find.byKey(TelephonePleinEcran.clePage), findsOneWidget);
            expect(find.byKey(CapsuleVideoTelephone.cleVoir), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('$nom : lignes 1 a 3, scene sans aucune page : la '
              'capsule sans oeil', (WidgetTester tester) async {
            await _monter(
              tester,
              taille: taille,
              texte: texte,
              presenter: false,
            );
            final Finder scene = find.byKey(
              const ValueKey<String>('telephone-scene'),
            );
            expect(scene, findsOneWidget);
            final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
            expect(capsule, findsOneWidget);
            expect(find.byKey(CapsuleVideoTelephone.cleVoir), findsNothing);
            expect(find.byKey(CapsuleVideoTelephone.cleRevenir), findsNothing);
            expect(find.byType(PiluleEtatSalle), findsNothing);
            // « Ouvrir le Coran », seul bouton plein, au centre de la scene.
            final Finder ouvrir = find.byKey(
              const ValueKey<String>('action-scene'),
            );
            expect(ouvrir, findsOneWidget);
            expect(
              tester.getCenter(ouvrir).dx,
              moreOrLessEquals(taille.width / 2, epsilon: 1),
            );
            verifierUnSeulBoutonPlein(tester);
            expect(
              find.byKey(const ValueKey<String>('salle-eleves')),
              findsNothing,
            );
            await _attendreLeRepos(tester);
            final Finder commandes = find.byKey(
              TelephonePleinEcran.cleCommandesRepos,
            );
            // Pilote C10 : sur la scene, rien a proteger, la capsule reste.
            expect(capsule.hitTestable(), findsOneWidget);
            expect(commandes.hitTestable(), findsOneWidget);
            expect(
              _horsDe(tester, <Finder>[capsule, commandes, scene, ouvrir]),
              isEmpty,
            );
            await _toucher(tester);
            expect(_dock.hitTestable(), findsOneWidget);
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesToucher).hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          });

          testWidgets('$nom : C11, sans droit de presenter, « Commandes » '
              'mene au Tableau', (WidgetTester tester) async {
            // Pilote C11 (27/10) : enseignant sans support, peutPresenter
            // faux (pas de Bibliotheque), le Tableau seul : « Commandes »
            // reste, au repos, et le tiroir montre la ligne Tableau.
            await _monter(
              tester,
              taille: taille,
              texte: texte,
              presenter: false,
              donnees: false,
            );
            await _attendreLeRepos(tester);
            final Finder repos = find.byKey(
              TelephonePleinEcran.cleCommandesRepos,
            );
            expect(repos.hitTestable(), findsOneWidget);
            await tester.tap(repos);
            await tester.pumpAndSettle();
            expect(find.byKey(TiroirCommandesTelephone.cle), findsOneWidget);
            expect(
              find
                  .byKey(const ValueKey<String>('bouton-tableau'))
                  .hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          });

          testWidgets('$nom : C12, le bandeau de secours reste au repos, '
              'la capsule sous lui', (WidgetTester tester) async {
            // Pilote C12 (27/10) : une alerte n'est pas une commande (fiche
            // 0, regle 22) : elle reste tant que l'etat dure.
            final FauxMoteurSalle moteur = await _monter(
              tester,
              taille: taille,
              texte: texte,
            );
            moteur.publierQualite(QualiteLien.mediocre);
            await tester.pumpAndSettle();
            await _attendreLeRepos(tester);
            final Finder bandeau = find.text(t.salle.secours.reseauFaible);
            expect(bandeau.hitTestable(), findsOneWidget);
            final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
            expect(capsule.hitTestable(), findsNothing);
            // Aucune bande reservee : la page garde l'ecran entier.
            final Rect p = tester.getRect(
              find.byKey(TelephonePleinEcran.clePage),
            );
            expect(p.top, moreOrLessEquals(0, epsilon: 1));
            expect(p.height, moreOrLessEquals(taille.height, epsilon: 1));
            // Au toucher, la capsule se place sous le bandeau.
            await _toucher(tester);
            expect(bandeau.hitTestable(), findsOneWidget);
            expect(capsule.hitTestable(), findsOneWidget);
            expect(
              tester.getRect(capsule).top,
              greaterThanOrEqualTo(tester.getRect(bandeau).bottom),
            );
            // Le tiroir ouvert ne le recouvre pas.
            await tester.tap(
              find.byKey(TelephonePleinEcran.cleCommandesToucher),
            );
            await tester.pumpAndSettle();
            expect(bandeau.hitTestable(), findsOneWidget);
            verifierSansChevauchement(tester, <Finder>[
              find.byKey(TiroirCommandesTelephone.cle),
              bandeau,
            ]);
            expect(tester.takeException(), isNull);
          });

          testWidgets('$nom : ligne 5, la capsule deplie le profil', (
            WidgetTester tester,
          ) async {
            await _monter(tester, taille: taille, texte: texte);
            await _toucher(tester);
            // La ligne d'etat n'est nulle part avant.
            expect(find.byType(PiluleEtatSalle), findsNothing);
            await tester.tap(find.byKey(CapsuleVideoTelephone.cleDeplier));
            await tester.pumpAndSettle();
            final Finder profil = find.byKey(ProfilTelephone.cle);
            expect(profil, findsOneWidget);
            expect(find.byKey(CapsuleVideoTelephone.cle), findsNothing);
            Finder dans(Finder f) => find.descendant(of: profil, matching: f);
            expect(
              dans(find.byKey(const ValueKey<String>('vignette-video'))),
              findsOneWidget,
            );
            expect(dans(find.textContaining('Amina')), findsOneWidget);
            // C4 : le role suit le genre.
            expect(
              dans(find.text(t.salle.seance.contexte.enseignante)),
              findsOneWidget,
            );
            expect(dans(find.byKey(PointEtatTelephone.cle)), findsOneWidget);
            expect(
              dans(
                find.byKey(const ValueKey<String>('telephone-profil-signal')),
              ),
              findsOneWidget,
            );
            expect(
              dans(find.byKey(ProfilTelephone.cleReduire)),
              findsOneWidget,
            );
            // La ligne d'etat, dessous, une seule fois a l'ecran.
            expect(find.byType(PiluleEtatSalle), findsOneWidget);
            expect(dans(find.byType(PiluleEtatSalle)), findsOneWidget);
            expect(
              tester.getRect(dans(find.byType(PiluleEtatSalle))).top,
              greaterThan(
                tester.getRect(dans(find.textContaining('Amina'))).bottom,
              ),
            );
            expect(tester.takeException(), isNull);
            verifierAucunMotCoupe(tester, profil);
            // Il ne se masque pas au delai.
            await _attendreLeRepos(tester);
            expect(profil.hitTestable(), findsOneWidget);
            // « Reduire » le replie.
            await tester.tap(find.byKey(ProfilTelephone.cleReduire));
            await tester.pumpAndSettle();
            expect(profil, findsNothing);
            expect(find.byKey(CapsuleVideoTelephone.cle), findsOneWidget);
            // Un toucher de la page le replie aussi.
            await tester.tap(find.byKey(CapsuleVideoTelephone.cleDeplier));
            await tester.pumpAndSettle();
            expect(profil, findsOneWidget);
            // Sous la carte (texte x2 : elle descend loin), au-dessus de la
            // pilule.
            await tester.tapAt(Offset(taille.width / 2, taille.height * 0.7));
            await tester.pumpAndSettle();
            expect(profil, findsNothing);
          });

          testWidgets('$nom : ligne 4, la pilule : Micro, Camera, Eleves, '
              'Quitter', (WidgetTester tester) async {
            final FauxMoteurSalle moteur = await _monter(
              tester,
              taille: taille,
              texte: texte,
            );
            await _toucher(tester);
            expect(_dock.hitTestable(), findsOneWidget);
            Finder dans(Finder f) => find.descendant(of: _dock, matching: f);
            // Quatre disques nommes, et rien d'autre.
            final Finder disques = dans(
              find.byKey(const ValueKey<String>('disque-commande')),
            );
            expect(disques, findsNWidgets(4));
            final List<String> noms = <String>[
              for (final Element e in dans(
                find.byKey(const ValueKey<String>('nom-commande')),
              ).evaluate())
                (e.widget as Text).data!,
            ];
            final bool microOuvert = noms.contains(t.salle.micro);
            expect(noms, <String>[
              if (microOuvert) t.salle.micro else t.salle.microCoupe,
              if (noms.contains(t.salle.camera))
                t.salle.camera
              else
                t.salle.cameraCoupee,
              t.salle.seance.eleves,
              t.salle.quitter,
            ]);
            // Un seul disque plein, rouge : Quitter.
            final List<Color?> fonds = <Color?>[
              for (final Element e in disques.evaluate())
                ((e.widget as SizedBox).child! as DecoratedBox).decoration
                        is BoxDecoration
                    ? (((e.widget as SizedBox).child! as DecoratedBox)
                                  .decoration
                              as BoxDecoration)
                          .color
                    : null,
            ];
            expect(fonds.where((Color? c) => c != null), hasLength(1));
            expect(fonds.last, AppPalette.claire().surfaceAlert.background);
            // Micro coupe : icone barree et nom « Micro coupe » ; ouvert :
            // « Micro ». Aucun aplat violet dans les deux etats.
            expect(microOuvert, isFalse);
            expect(
              dans(find.byIcon(AppIcons.microCoupe.repos)),
              findsOneWidget,
            );
            moteur.publier(<ParticipantSalle>[
              _personne('t1', 'teacher', true, micro: true),
              _personne('e1', 'student', false),
              _personne('e2', 'student', false),
            ]);
            await tester.pumpAndSettle();
            expect(dans(find.text(t.salle.micro)), findsOneWidget);
            expect(dans(find.text(t.salle.microCoupe)), findsNothing);
            expect(dans(find.byIcon(AppIcons.micro.repos)), findsOneWidget);
            expect(
              <Color?>[
                for (final Element e in disques.evaluate())
                  (((e.widget as SizedBox).child! as DecoratedBox).decoration
                          as BoxDecoration)
                      .color,
              ].where((Color? c) => c != null),
              hasLength(1),
            );
            // Eleves porte le nombre d'eleves presents.
            final Finder eleves = find.byKey(TelephonePleinEcran.cleEleves);
            expect(eleves, findsOneWidget);
            final Finder pastille = find.descendant(
              of: eleves,
              matching: find.byKey(const ValueKey<String>('pastille-commande')),
            );
            expect(pastille, findsOneWidget);
            expect(
              find.descendant(of: pastille, matching: find.text('2')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            verifierAucunMotCoupe(tester, _dock);
            verifierUnSeulBoutonPlein(tester);
          });

          testWidgets('$nom : ligne 6, « Commandes » ouvre le tiroir au-dessus '
              'de la pilule', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _ouvrirTiroir(tester);
            final Finder tiroir = find.byKey(TiroirCommandesTelephone.cle);
            expect(tiroir, findsOneWidget);
            final Finder pilule = _piluleDuBas(tester, tiroir);
            expect(pilule.hitTestable(), findsOneWidget);
            // La pilule entiere, a l'ecran, sous le tiroir.
            final Rect p = tester.getRect(pilule);
            expect(tester.getRect(tiroir).bottom, lessThanOrEqualTo(p.top));
            expect(p.bottom, lessThanOrEqualTo(taille.height));
            expect(p.top, greaterThanOrEqualTo(0));
            // « Commandes » disparait tant que le tiroir est ouvert.
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesToucher).hitTestable(),
              findsNothing,
            );
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesRepos).hitTestable(),
              findsNothing,
            );
            await _attendreLeRepos(tester);
            expect(
              find.byKey(TelephonePleinEcran.cleCommandesRepos).hitTestable(),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
          });

          for (final ThemeMode theme in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            testWidgets('$nom, ${theme.name} : ligne 7, le tiroir : une surface, '
                'Support | Outils', (WidgetTester tester) async {
              await _monter(tester, taille: taille, texte: texte, theme: theme);
              await _ouvrirTiroir(tester);
              final Finder tiroir = find.byKey(TiroirCommandesTelephone.cle);
              final BuildContext ctx = tester.element(tiroir);
              final AppPalette palette = AppPalette.of(ctx);
              expect(
                Theme.of(ctx).brightness,
                theme == ThemeMode.dark ? Brightness.dark : Brightness.light,
              );
              // La surface du tiroir est celle du theme.
              final Iterable<Color?> fondsTiroir = <Color?>[
                for (final Element e
                    in find
                        .descendant(
                          of: tiroir,
                          matching: find.byType(DecoratedBox),
                        )
                        .evaluate())
                  if ((e.widget as DecoratedBox).decoration
                      case final BoxDecoration d)
                    d.color,
              ];
              expect(fondsTiroir, contains(palette.surfaceRaised.background));
              // En-tete : « Commandes » au debut, « Reduire » a la fin.
              final Finder titre = find.descendant(
                of: tiroir,
                matching: find.text(t.salle.seance.commandes.titre),
              );
              final Finder reduire = find.descendant(
                of: tiroir,
                matching: find.byKey(PanneauSeance.cleReduire),
              );
              expect(titre, findsOneWidget);
              expect(reduire, findsOneWidget);
              final double xt = tester.getCenter(titre).dx;
              final double xr = tester.getCenter(reduire).dx;
              expect(_ltr() ? xt < xr : xt > xr, isTrue);
              // Deux segments, pas d'onglet Seance. Texte x2 (cas limite,
              // ONGLETS-1) : si les deux mots ne tiennent pas, le selecteur du
              // core passe en menu, qui liste les deux.
              final Finder onglets = find.byKey(
                TiroirCommandesTelephone.cleOnglets,
              );
              final Finder menu = find.descendant(
                of: onglets,
                matching: find.byType(MenuFiltre<OngletTiroir>),
              );
              if (texte == 1) expect(menu, findsNothing);
              final bool enMenu = menu.evaluate().isNotEmpty;
              if (enMenu) {
                await tester.tap(menu);
                await tester.pumpAndSettle();
              }
              for (final String o in <String>[
                t.salle.seance.commandes.ongletSupport,
                t.salle.seance.commandes.ongletOutils,
              ]) {
                expect(find.text(o).hitTestable(), findsWidgets);
              }
              if (enMenu) {
                await tester.tap(
                  find
                      .text(t.salle.seance.commandes.ongletSupport)
                      .hitTestable()
                      .last,
                );
                await tester.pumpAndSettle();
                await tester.pump(const Duration(milliseconds: 400));
                await tester.pumpAndSettle();
              }
              expect(
                find.text(t.salle.seance.commandes.ongletSeance),
                findsNothing,
              );
              // Outils : les tuiles posees sur le tiroir, sans bloc d'une autre
              // couleur entre elles et lui (hors l'outil retenu lui-meme).
              await _onglet(tester, t.salle.seance.commandes.ongletOutils);
              final Finder tuiles = find.descendant(
                of: tiroir,
                matching: find.byKey(const ValueKey<String>('tuile-commande')),
              );
              expect(tuiles, findsWidgets);
              final Element racine = tiroir.evaluate().single;
              for (final Element tuile in tuiles.evaluate()) {
                tuile.visitAncestorElements((Element a) {
                  if (identical(a, racine)) return false;
                  if (a.widget
                      case DecoratedBox(decoration: final BoxDecoration d)
                      when d.color != null) {
                    expect(
                      d.color,
                      palette.surfaceRaised.background,
                      reason: 'bloc emboite sous une tuile',
                    );
                  }
                  return true;
                });
              }
              expect(tester.takeException(), isNull);
              verifierAucunMotCoupe(tester, tiroir);
            });
          }

          testWidgets('$nom : ligne 12, aucune commande en double', (
            WidgetTester tester,
          ) async {
            await _monter(tester, taille: taille, texte: texte);
            await _attendreLeRepos(tester);
            _aucuneCommandeEnDouble(tester, 'repos');
            await _toucher(tester);
            _aucuneCommandeEnDouble(tester, 'toucher');
            await tester.tap(find.byKey(CapsuleVideoTelephone.cleDeplier));
            await tester.pumpAndSettle();
            _aucuneCommandeEnDouble(tester, 'profil');
            await tester.tap(find.byKey(ProfilTelephone.cleReduire));
            await tester.pumpAndSettle();
            await _ouvrirTiroir(tester);
            _aucuneCommandeEnDouble(tester, 'tiroir Support');
            await _onglet(tester, t.salle.seance.commandes.ongletOutils);
            _aucuneCommandeEnDouble(tester, 'tiroir Outils');
            await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
            await tester.pumpAndSettle();
            expect(find.byKey(FeuilleElevesTelephone.cle), findsOneWidget);
            _aucuneCommandeEnDouble(tester, 'eleves');
          });

          testWidgets('$nom : ligne 14, rien ne se recouvre, aucun mot '
              'coupe, cibles de 48', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _attendreLeRepos(tester);
            _verifierLigne14(tester, 'repos');
            await _toucher(tester);
            _verifierLigne14(tester, 'toucher');
            await tester.tap(find.byKey(CapsuleVideoTelephone.cleDeplier));
            await tester.pumpAndSettle();
            _verifierLigne14(tester, 'profil');
            await tester.tap(find.byKey(ProfilTelephone.cleReduire));
            await tester.pumpAndSettle();
            await _ouvrirTiroir(tester);
            _verifierLigne14(tester, 'tiroir Support');
            await _onglet(tester, t.salle.seance.commandes.ongletOutils);
            await tester.tap(
              find.byKey(const ValueKey<String>('barre-outils-stylet')),
            );
            await tester.pumpAndSettle();
            _verifierLigne14(tester, 'tiroir Outils');
            await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
            await tester.pumpAndSettle();
            _verifierLigne14(tester, 'eleves');
          });

          testWidgets('$nom : ligne 15, tout suit le sens de lecture', (
            WidgetTester tester,
          ) async {
            await _monter(tester, taille: taille, texte: texte);
            final bool ltr = _ltr();
            expect(
              Directionality.of(tester.element(_dock)),
              ltr ? TextDirection.ltr : TextDirection.rtl,
            );
            await _toucher(tester);
            // La pilule : Micro au debut, Quitter a la fin.
            final double micro = tester
                .getCenter(find.byKey(const ValueKey<String>('bouton-micro')))
                .dx;
            final double eleves = tester
                .getCenter(find.byKey(TelephonePleinEcran.cleEleves))
                .dx;
            if (texte == 1) {
              expect(ltr ? micro < eleves : micro > eleves, isTrue);
            }
            // « Commandes » au toucher, au bord de fin.
            final Rect k = tester.getRect(
              find.byKey(TelephonePleinEcran.cleCommandesToucher),
            );
            expect(
              ltr ? taille.width - k.right : k.left,
              moreOrLessEquals(16, epsilon: 1),
            );
            // Le zoom, au bord de fin.
            final Rect z = tester.getRect(
              find.byKey(const ValueKey<String>('salle-zoom')),
            );
            expect(
              ltr ? taille.width - z.right : z.left,
              moreOrLessEquals(16, epsilon: 1),
            );
            // La capsule : vignette, point, oeil dans le sens de lecture.
            final double v = tester
                .getCenter(
                  find.descendant(
                    of: find.byKey(CapsuleVideoTelephone.cle),
                    matching: find.byKey(
                      const ValueKey<String>('vignette-video'),
                    ),
                  ),
                )
                .dx;
            final double o = tester
                .getCenter(find.byKey(CapsuleVideoTelephone.cleVoir))
                .dx;
            expect(ltr ? v < o : v > o, isTrue);
            // Le tiroir : « Commandes » au debut, « Reduire » a la fin.
            await tester.tap(
              find.byKey(TelephonePleinEcran.cleCommandesToucher),
            );
            await tester.pumpAndSettle();
            final Finder tiroir = find.byKey(TiroirCommandesTelephone.cle);
            final double xt = tester
                .getCenter(
                  find.descendant(
                    of: tiroir,
                    matching: find.text(t.salle.seance.commandes.titre),
                  ),
                )
                .dx;
            final double xr = tester
                .getCenter(
                  find.descendant(
                    of: tiroir,
                    matching: find.byKey(PanneauSeance.cleReduire),
                  ),
                )
                .dx;
            expect(ltr ? xt < xr : xt > xr, isTrue);
            expect(tester.takeException(), isNull);
          });

          for (final String autre in <String>[
            'student',
            'guardian_observer',
            'masked_controller',
          ]) {
            testWidgets('$nom : ligne 16, $autre inchange : ni capsule, ni '
                'tiroir, ni « Commandes »', (WidgetTester tester) async {
              await _monter(tester, role: autre, taille: taille, texte: texte);
              await _toucher(tester);
              for (final Key k in <Key>[
                CapsuleVideoTelephone.cle,
                ProfilTelephone.cle,
                TelephonePleinEcran.cleCommandesRepos,
                TelephonePleinEcran.cleCommandesToucher,
                TelephonePleinEcran.cleEleves,
                TiroirCommandesTelephone.cle,
                FeuilleElevesTelephone.cle,
                const ValueKey<String>('disque-commande'),
              ]) {
                expect(find.byKey(k), findsNothing, reason: '$k');
              }
              await _attendreLeRepos(tester);
              expect(
                find.byKey(TelephonePleinEcran.cleCommandesRepos),
                findsNothing,
              );
              expect(tester.takeException(), isNull);
            });
          }

          testWidgets('$nom : ligne 8, Outils : Stylo, Surligner, Gomme, '
              'Annuler, les couleurs', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _ouvrirTiroir(tester);
            await _onglet(tester, t.salle.seance.commandes.ongletOutils);
            final Finder outils = find.byKey(OutilsTelephone.cle);
            expect(outils, findsOneWidget);
            // Pilote C8 : a 600 et plus, le tiroir centre, 640 au plus, sans
            // ombre ; Stylo a sa taille de telephone.
            final Rect tiroir = tester.getRect(
              find.byKey(TiroirCommandesTelephone.cle),
            );
            if (taille.width >= 600) {
              expect(tiroir.width, lessThanOrEqualTo(640));
              // Texte x2 : le mot le plus long peut imposer plus de 120.
              expect(
                tiroir.center.dx,
                moreOrLessEquals(taille.width / 2, epsilon: 1),
              );
              expect(
                tester
                    .getRect(
                      find.byKey(const ValueKey<String>('barre-outils-stylet')),
                    )
                    .width,
                lessThanOrEqualTo(texte == 1 ? 120 : taille.width),
              );
            }
            final BoxDecoration feuille =
                tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.byKey(TiroirCommandesTelephone.cle),
                            matching: find.byKey(
                              const ValueKey<String>('panneau-seance-feuille'),
                            ),
                          ),
                        )
                        .decoration
                    as BoxDecoration;
            expect(feuille.boxShadow ?? const <BoxShadow>[], isEmpty);
            Finder cle(String k) => find.byKey(ValueKey<String>(k));
            final Finder stylo = cle('barre-outils-stylet');
            final Finder surligner = cle('barre-outils-surligneur');
            final Finder gomme = cle('barre-outils-gomme');
            final Finder annuler = cle('barre-outils-annuler');
            // Annuler toujours visible, meme sans rien a annuler (pilote,
            // 26/10).
            for (final Finder f in <Finder>[stylo, surligner, gomme, annuler]) {
              expect(f.hitTestable(), findsOneWidget);
            }
            for (final String n in <String>[
              t.tc.outils.trait.stylet,
              t.tc.outils.trait.surligneur,
              t.tc.outils.trait.gomme,
              t.tc.outils.trait.annuler,
            ]) {
              expect(
                find.descendant(of: outils, matching: find.text(n)),
                findsOneWidget,
              );
            }
            // Ni Pointeur, ni Ecrire, ni Retablir, ni epaisseurs au telephone.
            for (final String k in <String>[
              'salle-outil-pointeur',
              'salle-outil-ecrire',
              'barre-outils-retablir',
              'barre-outils-effacer',
              'barre-outils-epaisseur',
            ]) {
              expect(cle(k), findsNothing, reason: k);
            }
            // Quatre cases de meme largeur ; a x1, sur une rangee.
            final Rect rangee = tester.getRect(
              find.byKey(OutilsTelephone.cleTuiles),
            );
            final List<Rect> r = <Rect>[
              for (final Finder f in <Finder>[stylo, surligner, gomme, annuler])
                tester.getRect(f),
            ];
            for (final Rect x in r) {
              expect(x.width, moreOrLessEquals(r[0].width, epsilon: 0.5));
            }
            if (texte == 1) {
              expect(
                r[0].width,
                moreOrLessEquals(
                  math.min(120, (rangee.width - 3 * 8) / 4),
                  epsilon: 0.5,
                ),
              );
              expect(r[1].top, moreOrLessEquals(r[0].top, epsilon: 0.5));
              expect(r[2].top, moreOrLessEquals(r[0].top, epsilon: 0.5));
              expect(r[3].top, moreOrLessEquals(r[0].top, epsilon: 0.5));
            }
            // Sans rien a annuler, le toucher ne fait rien et ne casse rien.
            await tester.tap(annuler);
            await tester.pumpAndSettle();
            expect(annuler.hitTestable(), findsOneWidget);
            // Aucun outil retenu : aucune couleur.
            final Finder couleurs = cle('barre-outils-couleurs');
            expect(couleurs, findsNothing);
            Color? aplat(Finder f) =>
                (tester
                            .widget<DecoratedBox>(
                              find.descendant(
                                of: f,
                                matching: cle('tuile-commande'),
                              ),
                            )
                            .decoration
                        as BoxDecoration)
                    .color;
            // Stylo : lui seul en couleur ; les couleurs, qui defilent.
            await tester.tap(stylo);
            await tester.pumpAndSettle();
            expect(aplat(stylo), isNotNull);
            expect(aplat(surligner), isNull);
            expect(aplat(gomme), isNull);
            expect(couleurs, findsOneWidget);
            expect(
              find.ancestor(of: couleurs, matching: find.byType(Scrollable)),
              findsWidgets,
            );
            final Finder derniere = cle('barre-couleur-marron');
            await tester.ensureVisible(couleurs);
            await tester.pumpAndSettle();
            await tester.drag(
              couleurs,
              Offset(_ltr() ? -taille.width : taille.width, 0),
            );
            await tester.pumpAndSettle();
            expect(derniere.hitTestable(), findsOneWidget);
            // Gomme : plus de couleurs ; Surligner : de nouveau.
            await tester.tap(gomme);
            await tester.pumpAndSettle();
            expect(aplat(gomme), isNotNull);
            expect(aplat(stylo), isNull);
            expect(couleurs, findsNothing);
            await tester.tap(surligner);
            await tester.pumpAndSettle();
            expect(couleurs, findsOneWidget);
            expect(tester.takeException(), isNull);
            verifierAucunMotCoupe(tester, outils);
          });

          testWidgets('$nom : ligne 9, Support : Tableau, Bibliotheque, '
              '« Ranger le support »', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _ouvrirTiroir(tester);
            final Finder tiroir = find.byKey(TiroirCommandesTelephone.cle);
            Finder dans(Finder f) => find.descendant(of: tiroir, matching: f);
            // Le Tableau.
            expect(
              dans(find.byKey(const ValueKey<String>('bouton-tableau'))),
              findsOneWidget,
            );
            expect(
              dans(find.text(t.salle.seance.commandes.affichageTableau)),
              findsOneWidget,
            );
            // La Bibliotheque existante, sans sa croix ; la page du Coran y
            // est.
            expect(dans(find.byType(PanneauBibliothequeSalle)), findsOneWidget);
            expect(
              find.byKey(const ValueKey<String>('bibliotheque-fermer')),
              findsNothing,
            );
            // « Ranger le support », une ligne nommee, a la place de la croix
            // du haut (nulle part ailleurs).
            final Finder ranger = find.byKey(
              TiroirCommandesTelephone.cleRanger,
            );
            expect(ranger, findsOneWidget);
            expect(dans(ranger), findsOneWidget);
            expect(
              dans(find.text(t.salle.seance.rangement.rangerSupport)),
              findsOneWidget,
            );
            // Aucune croix hors du tiroir.
            for (final Element e
                in find
                    .byIcon(AppIcons.fermer.repos)
                    .hitTestable()
                    .evaluate()) {
              expect(
                dans(find.byWidget(e.widget)).evaluate(),
                isNotEmpty,
                reason: 'croix hors du tiroir',
              );
            }
            verifierAucunMotCoupe(tester, ranger);
            // La page du Coran, plus bas dans la liste.
            final Finder liste = find.byKey(PanneauBibliothequeSalle.cle);
            for (
              int i = 0;
              i < 20 &&
                  dans(find.text(t.salle.supports.coran)).evaluate().isEmpty;
              i++
            ) {
              await tester.drag(liste, const Offset(0, -120));
              await tester.pumpAndSettle();
            }
            expect(dans(find.text(t.salle.supports.coran)), findsWidgets);
            expect(tester.takeException(), isNull);
          });

          testWidgets('$nom : ligne 10, Eleves ouvre la feuille, a la place '
              'du tiroir', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _ouvrirTiroir(tester);
            expect(find.byKey(TiroirCommandesTelephone.cle), findsOneWidget);
            await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
            await tester.pumpAndSettle();
            final Finder feuille = find.byKey(FeuilleElevesTelephone.cle);
            expect(feuille, findsOneWidget);
            expect(find.byKey(TiroirCommandesTelephone.cle), findsNothing);
            expect(find.byType(PanneauEleves), findsOneWidget);
            expect(_piluleDuBas(tester, feuille).hitTestable(), findsOneWidget);
            // La carte d'un eleve se deplie sur place (comme sur ordinateur) ;
            // la presence de la seance est en tete de la feuille (pilote,
            // 27/10).
            expect(find.text('Yasmine'), findsWidgets);
            final Finder cartes = find.byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('eleve-'),
            );
            // La liste ne construit que ce qui est a l'ecran : elle defile
            // jusqu'aux cartes.
            for (int i = 0; i < 20 && cartes.evaluate().isEmpty; i++) {
              await tester.drag(
                find.byType(PanneauEleves),
                const Offset(0, -120),
              );
              await tester.pumpAndSettle();
            }
            final Finder carte = cartes.first;
            await tester.ensureVisible(carte);
            await tester.pumpAndSettle();
            await tester.tap(
              find.descendant(of: carte, matching: find.text('Yasmine')).first,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            // Texte x2 : la presence en tete laisse moins de place ; les
            // cartes visibles restent separees de 16.
            expect(
              verifierAucuneCarteCollee(tester, estCarte: _carte),
              texte == 1 ? 2 : greaterThanOrEqualTo(1),
            );
            expect(find.byType(PanneauEleves), findsOneWidget);
          });

          for (final bool elevesOuverts in <bool>[false, true]) {
            final String panneau = elevesOuverts ? 'eleves' : 'tiroir';
            testWidgets('$nom : ligne 11, $panneau : un seul panneau, ni sur '
                'la pilule ni sur la capsule ; Reduire et la page le '
                'referment', (WidgetTester tester) async {
              await _monter(tester, taille: taille, texte: texte);
              await _toucher(tester);
              Future<Finder> ouvrir() async {
                if (elevesOuverts) {
                  await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
                } else {
                  await tester.tap(
                    find.byKey(TelephonePleinEcran.cleCommandesToucher),
                  );
                }
                await tester.pumpAndSettle();
                return find.byKey(
                  elevesOuverts
                      ? FeuilleElevesTelephone.cle
                      : TiroirCommandesTelephone.cle,
                );
              }

              final Finder ouvert = await ouvrir();
              expect(ouvert, findsOneWidget);
              expect(
                find.byKey(
                  elevesOuverts
                      ? TiroirCommandesTelephone.cle
                      : FeuilleElevesTelephone.cle,
                ),
                findsNothing,
              );
              final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
              verifierSansChevauchement(tester, <Finder>[
                ouvert,
                _piluleDuBas(tester, ouvert),
              ]);
              verifierSansChevauchement(tester, <Finder>[ouvert, capsule]);
              // « Reduire » le referme.
              await tester.tap(
                find
                    .descendant(
                      of: ouvert,
                      matching: find.byKey(PanneauSeance.cleReduire),
                    )
                    .hitTestable()
                    .first,
              );
              await tester.pumpAndSettle();
              expect(ouvert, findsNothing);
              // Un toucher de la page, entre la capsule et le panneau, aussi.
              await _toucher(tester);
              await ouvrir();
              final double haut = tester.getRect(capsule).bottom;
              final double bas = tester.getRect(ouvert).top;
              expect(bas, greaterThan(haut));
              await tester.tapAt(Offset(taille.width / 2, (haut + bas) / 2));
              await tester.pumpAndSettle();
              expect(ouvert, findsNothing);
              if (!elevesOuverts) {
                // Pilote (26/10) : un outil retenu, le toucher de la page
                // dessine et le tiroir reste ouvert ; « Reduire » le ferme.
                await _toucher(tester);
                await ouvrir();
                await _onglet(tester, t.salle.seance.commandes.ongletOutils);
                await tester.tap(
                  find.byKey(const ValueKey<String>('barre-outils-stylet')),
                );
                await tester.pumpAndSettle();
                final double haut2 = tester.getRect(capsule).bottom;
                final double bas2 = tester.getRect(ouvert).top;
                await tester.tapAt(
                  Offset(taille.width / 2, (haut2 + bas2) / 2),
                );
                await tester.pumpAndSettle();
                expect(ouvert, findsOneWidget);
                await tester.tap(
                  find
                      .descendant(
                        of: ouvert,
                        matching: find.byKey(PanneauSeance.cleReduire),
                      )
                      .hitTestable()
                      .first,
                );
                await tester.pumpAndSettle();
                expect(ouvert, findsNothing);
              }
              expect(tester.takeException(), isNull);
            });
          }

          testWidgets('$nom : ligne 13, la pilule du zoom suit le toucher', (
            WidgetTester tester,
          ) async {
            await _monter(tester, taille: taille, texte: texte);
            final Finder zoom = find.byKey(
              const ValueKey<String>('salle-zoom'),
            );
            await _attendreLeRepos(tester);
            expect(zoom.hitTestable(), findsNothing);
            await _toucher(tester);
            expect(zoom, findsOneWidget);
            final Rect z = tester.getRect(zoom);
            // Pilote C7 : a 100 %, « + » seul, un bouton rond, sans case
            // vide.
            expect(
              find.byKey(const ValueKey<String>('salle-zoom-moins')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey<String>('salle-zoom-plus')),
              findsOneWidget,
            );
            expect(z.width, moreOrLessEquals(z.height, epsilon: 0.5));
            // Au bord de fin, a mi-hauteur.
            expect(
              _ltr() ? taille.width - z.right : z.left,
              moreOrLessEquals(16, epsilon: 1),
            );
            if (texte == 1) {
              expect(
                z.center.dy,
                moreOrLessEquals(taille.height / 2, epsilon: 1),
              );
            } else {
              // Texte agrandi (cas limite) : remonte au besoin, jamais sur
              // « Commandes » ni sur la pilule.
              expect(z.center.dy, lessThanOrEqualTo(taille.height / 2 + 1));
              expect(
                z.bottom,
                lessThanOrEqualTo(
                  tester
                      .getRect(
                        find.byKey(TelephonePleinEcran.cleCommandesToucher),
                      )
                      .top,
                ),
              );
            }
            // Jamais sur un panneau ouvert ni sur le profil.
            await tester.tap(
              find.byKey(TelephonePleinEcran.cleCommandesToucher),
            );
            await tester.pumpAndSettle();
            expect(zoom, findsNothing);
            await tester.tap(
              find.byKey(PanneauSeance.cleReduire).hitTestable().first,
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(CapsuleVideoTelephone.cleDeplier));
            await tester.pumpAndSettle();
            expect(zoom, findsNothing);
            expect(tester.takeException(), isNull);
          });
        }
      }
    });
  }

  // Ligne 14 : a 320 en texte x2, les noms peuvent se reduire a l'icone,
  // jamais disparaitre (les quatre disques restent).
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group('${langue.languageCode} 320', () {
      setUp(() => LocaleSettings.setLocale(langue));
      testWidgets('${langue.languageCode} 320x568, texte x2 : ligne 14', (
        WidgetTester tester,
      ) async {
        const Size petit = Size(320, 568);
        await _monter(tester, taille: petit, texte: 2);
        await _attendreLeRepos(tester);
        _verifierLigne14(tester, 'repos');
        await _toucher(tester);
        expect(
          find.descendant(
            of: _dock,
            matching: find.byKey(const ValueKey<String>('disque-commande')),
          ),
          findsNWidgets(4),
        );
        _verifierLigne14(tester, 'toucher');
        await _ouvrirTiroir(tester);
        _verifierLigne14(tester, 'tiroir');
        await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
        await tester.pumpAndSettle();
        _verifierLigne14(tester, 'eleves');
      });
    });
  }

  // Fiche 1, « Captures a produire » : a 390 x 844 et 834 x 1194, nommees
  // fiche1-<taille>-<etat>.png, avec CAPTURE_DIR seulement.
  for (final Size ecran in <Size>[_telephone, _ipad]) {
    final String taille = '${ecran.width.toInt()}x${ecran.height.toInt()}';
    testWidgets('captures de la fiche 1, $taille', (WidgetTester tester) async {
      if (dossierCapture == null) return;
      await _monter(tester, taille: ecran);
      await _attendreLeRepos(tester);
      await capturerVue(tester, 'fiche1-$taille-repos');
      await _toucher(tester);
      await capturerVue(tester, 'fiche1-$taille-toucher');
      await tester.tap(find.byKey(CapsuleVideoTelephone.cleDeplier));
      await tester.pumpAndSettle();
      await capturerVue(tester, 'fiche1-$taille-profil');
      await tester.tap(find.byKey(ProfilTelephone.cleReduire));
      await tester.pumpAndSettle();
      await _ouvrirTiroir(tester);
      await capturerVue(tester, 'fiche1-$taille-tiroir-support');
      await _onglet(tester, t.salle.seance.commandes.ongletOutils);
      await tester.tap(
        find.byKey(const ValueKey<String>('barre-outils-stylet')),
      );
      await tester.pumpAndSettle();
      await capturerVue(tester, 'fiche1-$taille-tiroir-outils');
      await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
      await tester.pumpAndSettle();
      await capturerVue(tester, 'fiche1-$taille-eleves');
    });
  }
}
