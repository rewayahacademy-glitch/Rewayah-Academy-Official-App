// Fiche 1 (26/10/2026, docs/current/maquettes/salle/
// FICHE-1-TELEPHONE-2026-10-26.md) : la salle de l'enseignant au telephone et
// sur l'iPad en portrait, a 390 x 844 et 834 x 1194, texte x1 et x2,
// francais et arabe. Un test par ligne de la fiche, nomme « ligne N ».
//
// Captures (fiche, « Captures a produire ») seulement avec CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
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
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/barre_outils_salle.dart';
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
const Size _ipad = Size(834, 1194);

Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  String role = 'teacher',
  Size taille = _telephone,
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(role, moteur),
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
  setUpAll(() async {
    if (dossierCapture == null) return;
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

          testWidgets('$nom : ligne 1, au repos, la capsule et « Commandes » '
              'seulement', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            expect(find.byType(SalleOrdinateur), findsNothing);
            await _attendreLeRepos(tester);
            final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
            final Finder commandes = find.byKey(
              TelephonePleinEcran.cleCommandesRepos,
            );
            expect(capsule.hitTestable(), findsOneWidget);
            expect(commandes.hitTestable(), findsOneWidget);
            // Rien d'autre : ni pilule d'etat, ni Eleves, ni croix, ni texte.
            expect(_horsDe(tester, <Finder>[capsule, commandes]), isEmpty);
            expect(find.byType(PiluleEtatSalle), findsNothing);
            expect(
              find.byKey(const ValueKey<String>('salle-eleves')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey<String>('salle-ranger-support')),
              findsNothing,
            );
            // La capsule en haut au centre, « Commandes » en bas au centre.
            final Rect c = tester.getRect(capsule);
            final Rect k = tester.getRect(commandes);
            expect(c.center.dx, moreOrLessEquals(taille.width / 2, epsilon: 1));
            expect(k.center.dx, moreOrLessEquals(taille.width / 2, epsilon: 1));
            expect(c.bottom, lessThan(taille.height / 4));
            expect(k.top, greaterThan(taille.height * 3 / 4));
            expect(tester.takeException(), isNull);
          });

          testWidgets('$nom : ligne 2, la capsule : vignette, point vert, '
              'oeil', (WidgetTester tester) async {
            await _monter(tester, taille: taille, texte: texte);
            await _attendreLeRepos(tester);
            final Finder capsule = find.byKey(CapsuleVideoTelephone.cle);
            expect(capsule, findsOneWidget);
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
            expect(fond.color, AppPalette.of(ctx).piluleSalle.background);
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
            expect(tester.takeException(), isNull);
            verifierUnSeulBoutonPlein(tester);
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
            expect(dans(find.text('Amina')), findsOneWidget);
            expect(dans(find.text(t.commun.roles.enseignant)), findsOneWidget);
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
              greaterThan(tester.getRect(dans(find.text('Amina'))).bottom),
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

          testWidgets('$nom : les eleves en feuille, cartes qui se deplient', (
            WidgetTester tester,
          ) async {
            await _monter(tester, taille: taille, texte: texte);
            // « Eleves » de la pilule ouvre la feuille.
            await _toucher(tester);
            await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
            await tester.pumpAndSettle();
            expect(find.byKey(FeuilleElevesTelephone.cle), findsOneWidget);
            expect(find.byType(PanneauEleves), findsOneWidget);
            expect(find.text('Yasmine'), findsWidgets);
            // ignore: avoid_print
            print(
              'DBG feuille ${tester.getRect(find.byKey(FeuilleElevesTelephone.cle))} dock ${tester.getRect(_dock)} yas ${find.text('Yasmine').evaluate().map((Element e) => tester.getRect(find.byWidget(e.widget))).toList()}',
            );
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
    await tester.tap(find.byKey(TelephonePleinEcran.cleCommandesToucher));
    await tester.pumpAndSettle();
    await capturerVue(tester, 'salle-390-commandes-support');
    await _onglet(tester, t.salle.seance.commandes.ongletOutils);
    await capturerVue(tester, 'salle-390-commandes-outils');
    await tester.tap(find.byKey(TelephonePleinEcran.cleEleves));
    await tester.pumpAndSettle();
    await capturerVue(tester, 'salle-390-eleves');
  });
}
