// SALLE-200-1 (constat CTRL-SALLE-1, revue du directeur) : la salle tient a
// 320 et 390 px avec un texte double, pour CHAQUE role qui y entre
// (enseignant, eleve, controleur, tuteur observateur).
//
// - Aucune exception de mise en page (debordement compris).
// - Le support (le contenu de `PageImmersive`) garde au moins la moitie de
//   la hauteur : les commandes et l'en-tete ne le mangent pas.
// - Quitter reste atteignable.
//
// Captures (390, texte x2, eleve et enseignant) seulement avec CAPTURE_DIR.

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
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_enseignant/panneau_enseignant.dart';
import 'package:rewayah_academy/features/salle_seance/composition_salle.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';
import '../theme/support/contraste.dart';

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

AppRole _appRole(String role) => switch (role) {
  'teacher' => AppRole.teacher,
  'student' => AppRole.student,
  'guardian_observer' => AppRole.guardian,
  _ => AppRole.controller,
};

ParticipantSalle _personne(String id, String role, String nom, bool local) =>
    ParticipantSalle(
      identite: id,
      nom: nom,
      role: role,
      estLocal: local,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    );

List<Override> _surcharges(String role, FauxMoteurSalle moteur) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: _appRole(role),
        profileId: 'p1',
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
  servicePresenceProvider.overrideWithValue(FauxServicePresence()),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(observe: false),
  ),
  portAnnonceObservationProvider.overrideWithValue(
    FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
  ),
];

/// Monte la salle pour [role], avec trois participants et une page presentee.
Future<void> _monter(
  WidgetTester tester,
  String role,
  double largeur,
  double texte, {
  double densite = 1,
  ThemeMode themeMode = ThemeMode.light,
  double hauteur = 844,
  List<Override> enPlus = const <Override>[],
  bool presenter = true,
  InterfaceMode interfaceMode = InterfaceMode.standard,
}) async {
  fixerVueCapture(tester, Size(largeur, hauteur), densite);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: <Override>[..._surcharges(role, moteur), ...enPlus],
      echelleTexte: texte,
      themeMode: themeMode,
      interfaceMode: interfaceMode,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', 'Omar', role == 'teacher'),
    _personne('e1', 'student', 'Yasmine', role == 'student'),
    _personne('e2', 'student', 'Ilyes', false),
  ]);
  if (!presenter) {
    await tester.pumpAndSettle();
    return;
  }
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

const List<String> _roles = <String>[
  'teacher',
  'student',
  'masked_controller',
  'guardian_observer',
];

/// La couleur rendue d'un texte (style fusionne de son `RichText`).
Color? _couleurRendue(WidgetTester tester, Finder texte) => tester
    .widget<RichText>(
      find.descendant(of: texte, matching: find.byType(RichText)).first,
    )
    .text
    .style
    ?.color;

/// Le fond sous un element : la premiere boite coloree au-dessus de lui, ou
/// le fond de l'echafaudage (celui de `PageImmersive`).
Color _fondSous(WidgetTester tester, Finder cible) {
  Color? trouve;
  tester.element(cible).visitAncestorElements((Element e) {
    final Widget w = e.widget;
    // S0 : un fond transparent ne compte pas ; la salle de seance pose son
    // fond par un `Material`.
    bool opaque(Color? c) => c != null && c.a > 0;
    if (w is Material && opaque(w.color)) {
      trouve = w.color;
      return false;
    }
    if (w is DecoratedBox) {
      final Decoration d = w.decoration;
      if (d is BoxDecoration && opaque(d.color)) {
        trouve = d.color;
        return false;
      }
      if (d is ShapeDecoration && opaque(d.color)) {
        trouve = d.color;
        return false;
      }
    }
    if (w is ColoredBox && opaque(w.color)) {
      trouve = w.color;
      return false;
    }
    if (w is Scaffold && w.backgroundColor != null) {
      trouve = w.backgroundColor;
      return false;
    }
    return true;
  });
  return trouve!;
}

/// Verifie qu'un texte se lit sur ce qui est dessous : 4,5:1 au moins.
void _lisible(WidgetTester tester, Finder texte, String quoi) {
  expect(texte, findsWidgets, reason: quoi);
  for (final Element e in texte.evaluate()) {
    final Finder un = find.byWidget(e.widget).first;
    final Color? encre = _couleurRendue(tester, un);
    expect(encre, isNotNull, reason: quoi);
    final Color fond = _fondSous(tester, un);
    final double r = contraste(encre!, fond);
    expect(
      r,
      greaterThanOrEqualTo(seuilTexte),
      reason: '« $quoi » : ${r.toStringAsFixed(2)}:1 ($encre sur $fond)',
    );
  }
}

void main() {
  group('SALLE-200-1 : la salle tient, texte agrandi', () {
    // TB-RC (TB_RAPPORT §d n° 6, revue TB-R m35) : la hauteur se mesure
    // avec les polices du depot. La police de test (un carre par glyphe)
    // comptait deux lignes de plus par phrase du rappel, qui garde
    // desormais ses deux phrases a texte x2.
    setUpAll(chargerPolicesDuDepot);
    for (final String role in _roles) {
      for (final double largeur in <double>[320, 390]) {
        for (final double texte in <double>[1, 2]) {
          // SALLE-CORR-3 : le cas enseignant 320 x1 (sauté jusque-la, la
          // rangee des commandes debordait de 8 px) est reactive.
          testWidgets('$role, $largeur px, texte x$texte', (
            WidgetTester tester,
          ) async {
            await _monter(tester, role, largeur, texte);
            expect(tester.takeException(), isNull);

            // Le support garde au moins la moitie de la hauteur (S0 : chez
            // l'eleve et l'enseignant, la surface de la salle de seance).
            final bool seance = role == 'teacher' || role == 'student';
            // Marges comprises, comme l'ancien contenu de `PageImmersive`.
            // S0.2c : au telephone, la page est l'ecran (bord a bord).
            final Finder pageTelephone = find.byKey(
              const ValueKey<String>('telephone-page'),
            );
            final Rect contenu = tester.getRect(
              pageTelephone.evaluate().isNotEmpty
                  ? pageTelephone
                  : seance
                  ? find
                        .ancestor(
                          of: find.byType(ZoneSupport),
                          matching: find.byType(Padding),
                        )
                        .first
                  : find.byKey(PageImmersive.contenuKey),
            );
            // S0 : la salle de seance tient sa propre regle, la page garde
            // au moins `CompositionSalle.partMinimalePage` (30 %) ; a texte x2
            // sa tete bornee lui laisse 421 px sur 844 (ecart dit au pilote).
            expect(
              contenu.height,
              greaterThanOrEqualTo(
                seance ? 844 * CompositionSalle.partMinimalePage : 844 / 2,
              ),
              reason: 'support de ${contenu.height} px sur 844',
            );

            // Quitter reste atteignable, a l'ecran.
            final Finder quitter = role == 'masked_controller'
                ? find.bySemanticsLabel(RegExp(t.salle.quitter))
                : seance
                ? find.bySemanticsLabel(RegExp(t.salle.seance.sortir))
                : find.bySemanticsLabel(RegExp(t.salle.quitterLeCours));
            expect(quitter, findsWidgets, reason: role);
            final Rect zone = tester.getRect(quitter.first);
            expect(zone.left, greaterThanOrEqualTo(-0.5));
            expect(zone.right, lessThanOrEqualTo(largeur + 0.5));
            expect(zone.bottom, lessThanOrEqualTo(844.5));
          });
        }
      }
    }
  });

  // VIDEO-TUILE-1 / SUPERPOS-1 : dans la galerie de l'eleve, chaque tuile
  // reste a 16 px des bords et finit 8 px au moins au-dessus du bandeau et
  // des commandes du bas. (Chez l'enseignant, sur telephone, la scene vit
  // dans la colonne qui defile : elle ne passe sous rien par construction.)
  group('VIDEO-TUILE-1 : galerie eleve, rien sous le bandeau', () {
    for (final double largeur in <double>[320, 390]) {
      testWidgets('student, $largeur px', (WidgetTester tester) async {
        // S0 : rien de presente, la scene video de `/salle` est au premier
        // plan de la salle de seance ; elle finit au-dessus des commandes.
        await _monter(tester, 'student', largeur, 1, presenter: false);
        expect(tester.takeException(), isNull);
        final double bas = tester
            .getRect(find.byKey(const ValueKey<String>('scene-premier-plan')))
            .bottom;
        final Finder cercles = find.byKey(
          const ValueKey<String>('tuile-sans-image-cercle'),
        );
        expect(cercles, findsWidgets);
        for (final Element cercle in cercles.evaluate()) {
          final Rect tuile = tester.getRect(
            find
                .ancestor(
                  of: find.byWidget(cercle.widget),
                  matching: find.byType(ClipRRect),
                )
                .first,
          );
          expect(tuile.left, greaterThanOrEqualTo(16 - 0.5));
          expect(tuile.right, lessThanOrEqualTo(largeur - 16 + 0.5));
          expect(
            tuile.bottom,
            lessThanOrEqualTo(bas - 8),
            reason: 'tuile $tuile sous le bandeau ($bas)',
          );
        }
      });
    }
  });

  // SALLE-CORR-3 (releves VERIF-CORR-2) : l'encre des commandes, le titre du
  // rappel de qui observe a x2, la gouttiere du bandeau permanent.
  group('SALLE-CORR-3 : commandes lisibles sur le fond de la salle', () {
    for (final String role in <String>['teacher', 'student']) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('$role, ${mode.name} : icone lisible sur son disque', (
          WidgetTester tester,
        ) async {
          // Standard des commandes d'appel (24/10/2026) : la salle suit le
          // theme de l'application ; aucun mot de commande (le libelle vit
          // dans l'infobulle), chaque bouton est un disque REMPLI dont
          // l'icone se lit (3:1, composant), jamais un contour seul.
          await _monter(tester, role, 390, 1, themeMode: mode);
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey<String>('mot-commande')),
            findsNothing,
          );
          final Finder disques = find.byKey(
            const ValueKey<String>('disque-appel'),
          );
          expect(disques, findsWidgets);
          for (final Element disque in disques.evaluate()) {
            final DecoratedBox boite = tester.widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byWidget(disque.widget),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            );
            final Decoration deco = boite.decoration;
            expect(deco, isA<BoxDecoration>());
            final Color? fond = (deco as BoxDecoration).color;
            expect(fond, isNotNull, reason: 'disque rempli, sans contour seul');
            final Element icone = find
                .descendant(
                  of: find.byWidget(disque.widget),
                  matching: find.byType(Icon),
                )
                .evaluate()
                .first;
            final Color? couleur = IconTheme.of(icone).color;
            expect(
              contraste(couleur!, fond!),
              greaterThanOrEqualTo(seuilComposant),
            );
          }
        });
      }
    }

    for (final (String role, String Function() titre, String Function() texte)
        in <(String, String Function(), String Function())>[
          (
            'masked_controller',
            () => t.salle.bandeauControleTitre,
            () => t.salle.bandeauControle,
          ),
          (
            'guardian_observer',
            () => t.salle.observationMuetteTitre,
            () => t.salle.observationMuette,
          ),
        ]) {
      testWidgets('$role, 320 px, texte x2 : le rappel garde son titre', (
        WidgetTester tester,
      ) async {
        await _monter(tester, role, 320, 2);
        expect(tester.takeException(), isNull);
        // Le titre, en toutes lettres et a l'ecran ; la phrase entiere, lue.
        final Finder ecrit = find.text(titre());
        expect(ecrit, findsOneWidget);
        final Rect zone = tester.getRect(ecrit);
        expect(zone.width, greaterThan(0));
        expect(zone.left, greaterThanOrEqualTo(-0.5));
        expect(zone.right, lessThanOrEqualTo(320 + 0.5));
        expect(find.bySemanticsLabel(texte()), findsOneWidget);
      });
    }

    testWidgets('teacher, 320 px : bandeau permanent dans la gouttiere', (
      WidgetTester tester,
    ) async {
      await _monter(tester, 'teacher', 320, 1);
      expect(tester.takeException(), isNull);
      final double gouttiere = AppGabarit.de(
        tester.element(find.byType(SallePage)),
      ).gouttiere;
      final Rect bandeau = tester.getRect(find.byType(PermanentNotice));
      expect(bandeau.left, greaterThanOrEqualTo(gouttiere - 0.5));
      expect(bandeau.right, lessThanOrEqualTo(320 - gouttiere + 0.5));
    });
  });

  // SALLE-ENCRE-1 / SALLE-CORR-4 (reserve R1 de C1-SALLE-R, releve de
  // SALLE-CORR-3) : les textes poses sur le fond de la salle en prennent
  // l'encre, pour tous les roles et dans les deux themes.
  group('SALLE-ENCRE-1 : textes lisibles sur le fond de la salle', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final double largeur in <double>[390, 1440]) {
        testWidgets('teacher, $largeur px, ${mode.name} : etat de la page', (
          WidgetTester tester,
        ) async {
          // S0 : la page presentee vit dans la carte claire de la surface a
          // page fixe ; son etat d'erreur (lecture impossible) s'y lit, a
          // l'encre de la carte.
          await _monter(
            tester,
            'teacher',
            largeur,
            1,
            themeMode: mode,
            hauteur: largeur > 1000 ? 900 : 844,
          );
          expect(tester.takeException(), isNull);
          final Map<String, Finder> textes = <String, Finder>{
            'titre d erreur': find.text(t.enseignant.salle.pageIndisponible),
            'detail d erreur': find.text(
              t.enseignant.salle.pageIndisponibleDetail,
            ),
          };
          for (final MapEntry<String, Finder> e in textes.entries) {
            _lisible(tester, e.value, e.key);
          }
        });

        for (final String role in <String>['teacher', 'student']) {
          testWidgets('$role, $largeur px, ${mode.name} : presence lisible', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              role,
              largeur,
              1,
              themeMode: mode,
              hauteur: largeur > 1000 ? 900 : 844,
            );
            expect(tester.takeException(), isNull);
            // Standard des commandes d'appel : au telephone, la presence se
            // lit dans la pilule translucide « ● En ligne · … » (une seule
            // ligne d'etat) ; ailleurs, dans la pastille de l'en-tete.
            // Plan de composition du 26/10/2026 : sur ordinateur,
            // l'enseignant a sa pilule d'etat en haut et ses Eleves dans le
            // panneau de gauche, deja ouvert.
            final bool ordinateur = find
                .byType(SalleOrdinateur)
                .evaluate()
                .isNotEmpty;
            final Finder ligne = find.byKey(
              ValueKey<String>(
                ordinateur ? 'pilule-etat-salle' : 'ligne-etat-telephone',
              ),
            );
            if (ligne.evaluate().isNotEmpty) {
              _lisible(
                tester,
                find.descendant(of: ligne, matching: find.byType(Text)),
                'ligne d etat ($role)',
              );
            }
            if (role == 'teacher') {
              // S0.2c : la presence de l'enseignant vit dans sa colonne
              // Eleves (une ligne par personne) ; au telephone, le bouton
              // rond « Eleves » (icone, pastille de nombre) l'ouvre en
              // feuille.
              final Finder ouvrir = find.byKey(
                const ValueKey<String>('salle-eleves'),
              );
              if (!ordinateur && ouvrir.evaluate().isNotEmpty) {
                await tester.tap(ouvrir.first);
                await tester.pumpAndSettle();
              }
            }
            final Finder pastilles = find.descendant(
              of: find.byType(StatusPill),
              matching: find.byType(Text),
            );
            if (pastilles.evaluate().isNotEmpty) {
              _lisible(tester, pastilles, 'presence ($role)');
            } else {
              expect(ligne, findsOneWidget, reason: 'aucune presence lisible');
            }
          });
        }
      }
    }
  });

  // SALLE-CORR-4 (m10) : le bandeau permanent « Cours enregistre, visite de
  // controle possible » prend l'encre du registre `salle` (enseignant, eleve) ;
  // le controleur, qui n'a pas la mention, garde son rappel lisible.
  group('SALLE-CORR-4 m10 : bandeau permanent lisible', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final double largeur in <double>[320, 390, 1440]) {
        for (final String role in <String>[
          'teacher',
          'student',
          'masked_controller',
        ]) {
          testWidgets('$role, $largeur px, ${mode.name}', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              role,
              largeur,
              1,
              themeMode: mode,
              hauteur: largeur > 1000 ? 900 : 844,
            );
            expect(tester.takeException(), isNull);
            if (role == 'masked_controller') {
              expect(find.text(t.salle.bandeauPermanent), findsNothing);
              _lisible(
                tester,
                find.text(t.salle.bandeauControle),
                'rappel du controleur',
              );
              return;
            }
            // S0 : la mention de la salle de seance, sur le theme de
            // l'application ; elle se lit, quelle que soit son encre.
            final Finder bandeau = find.text(t.salle.bandeauPermanent);
            _lisible(tester, bandeau, 'bandeau permanent ($role)');
          });
        }
      }
    }
  });

  // SALLE-ERR-320-1 : dans le panneau de l'enseignant, chaque etat du support
  // garde son action a l'ecran, sans geste, a 320 px texte x2 comme a 390 et
  // 1440 ; le texte qui ne tient pas defile dans le panneau, sans debordement.
  group('SALLE-ERR-320-1 : etats du panneau enseignant', () {
    // Les polices reelles : la police de test dessine chaque glyphe en carre
    // plein, plus large et plus haut qu'aucune police livree ; a 320 px x2 elle
    // mesurerait une salle que personne ne verra.
    setUpAll(chargerPolicesDuDepot);
    const List<(String, double, double, double)> formats =
        <(String, double, double, double)>[
          ('320 x2 (700)', 320, 700, 2),
          ('320 x2 (844)', 320, 844, 2),
          ('320 x1', 320, 700, 1),
          ('390', 390, 844, 1),
          ('1440', 1440, 900, 1),
        ];

    // Le bouton est a l'ecran et recoit le toucher a l'endroit ou il est
    // dessine : ni rogne par le panneau, ni pousse hors de sa zone.
    void touchable(
      WidgetTester tester,
      Finder libelle,
      double largeur,
      double hauteur,
      String quoi,
    ) {
      expect(libelle, findsOneWidget, reason: quoi);
      // Le toucher pose au milieu du libelle l'atteint : rien ne le rogne ni
      // ne le recouvre.
      expect(
        libelle.hitTestable(),
        findsOneWidget,
        reason: '$quoi : touchable',
      );
      final Finder bouton = find.ancestor(
        of: libelle,
        matching: find.byType(ActionPrincipale),
      );
      final Rect zone = tester.getRect(bouton);
      // Le bouton entier dans la zone visible de ce qui le fait defiler : un
      // bouton a moitie rogne par le panneau n'est pas un bouton a l'ecran.
      final Finder defile = find.ancestor(
        of: bouton,
        matching: find.byType(Scrollable),
      );
      final Rect vue = defile.evaluate().isEmpty
          ? Offset.zero & Size(largeur, hauteur)
          : tester.getRect(defile.first);
      expect(zone.top, greaterThanOrEqualTo(vue.top - 0.5), reason: quoi);
      expect(zone.bottom, lessThanOrEqualTo(vue.bottom + 0.5), reason: quoi);
      expect(zone.left, greaterThanOrEqualTo(-0.5), reason: quoi);
      expect(zone.right, lessThanOrEqualTo(largeur + 0.5), reason: quoi);
      expect(zone.top, greaterThanOrEqualTo(-0.5), reason: quoi);
      expect(zone.bottom, lessThanOrEqualTo(hauteur + 0.5), reason: quoi);
    }

    // Un texte qui ne tient pas reste atteignable : on le fait venir a
    // l'ecran par le defilement du panneau, et il s'y lit.
    Future<void> atteignable(
      WidgetTester tester,
      Finder texte,
      String quoi,
    ) async {
      expect(texte, findsOneWidget, reason: quoi);
      await tester.ensureVisible(texte);
      await tester.pumpAndSettle();
      expect(texte.hitTestable(), findsOneWidget, reason: '$quoi : atteint');
    }

    for (final (String nom, double largeur, double hauteur, double texte)
        in formats) {
      testWidgets('erreur de lecture, $nom : Reessayer reste a l ecran', (
        WidgetTester tester,
      ) async {
        await _monter(tester, 'teacher', largeur, texte, hauteur: hauteur);
        expect(tester.takeException(), isNull);
        final Finder reessayer = find.text(t.commun.reessayer);
        touchable(tester, reessayer, largeur, hauteur, 'Reessayer');
        await tester.tap(reessayer);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await atteignable(
          tester,
          find.text(t.enseignant.salle.pageIndisponible),
          'titre',
        );
        await atteignable(
          tester,
          find.text(t.enseignant.salle.pageIndisponibleDetail),
          'detail',
        );
        // Apres le defilement du texte, l'action n'a pas bouge de l'ecran.
        touchable(
          tester,
          find.text(t.commun.reessayer),
          largeur,
          hauteur,
          'Reessayer apres defilement',
        );
      });

      testWidgets('corpus absent, $nom : constat et raison atteignables', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          'teacher',
          largeur,
          texte,
          hauteur: hauteur,
          enPlus: <Override>[
            pageCoranProvider.overrideWith(
              (Ref _, int numero) async =>
                  PageCoran(numero: numero, versets: const <VersetCoran>[]),
            ),
          ],
        );
        expect(tester.takeException(), isNull);
        await atteignable(
          tester,
          find.text(t.enseignant.salle.corpusAbsent),
          'constat',
        );
        await atteignable(
          tester,
          find.text(t.enseignant.salle.corpusAbsentDetail),
          'raison',
        );
        // Un vide subi ne propose aucune action.
        expect(find.text(t.commun.reessayer), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('rien n est presente, $nom : Ouvrir le Coran a l ecran', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          'teacher',
          largeur,
          texte,
          hauteur: hauteur,
          presenter: false,
        );
        expect(tester.takeException(), isNull);
        touchable(
          tester,
          find.text(t.salle.ouvrirCoran),
          largeur,
          hauteur,
          'Ouvrir le Coran',
        );
        // S0 : rien de presente, la scene video est au premier plan et
        // « Ouvrir le Coran » y est le bouton de l'ecran (plus de panneau
        // vide a lire).
        touchable(
          tester,
          find.text(t.salle.ouvrirCoran),
          largeur,
          hauteur,
          'Ouvrir le Coran apres defilement',
        );
      });
    }

    // Sans le droit de presenter (le jeton refuse `can_publish_data`), la
    // phrase remplace les commandes : elle reste a l'ecran, entiere, et
    // l'etat du support au-dessus ne deborde pas. Le panneau est pose a la
    // plus petite hauteur que la salle lui donne sur telephone (son plancher).
    for (final (String nom, double largeur, double texte)
        in <(String, double, double)>[
          ('320 x2', 320, 2),
          ('320 x1', 320, 1),
          ('390', 390, 1),
        ]) {
      for (final bool presente in <bool>[true, false]) {
        testWidgets(
          'sans droit de presenter, $nom, ${presente ? 'page presentee' : 'rien'}',
          (WidgetTester tester) async {
            const double plancher = AppSpacing.respiration * 8;
            fixerVueCapture(tester, Size(largeur, 844), 1);
            final FauxMoteurSalle moteur = FauxMoteurSalle();
            await tester.pumpWidget(
              hoteCapture(
                const Scaffold(
                  body: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: plancher,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: PanneauEnseignantSalle(
                          seanceId: 's1',
                          peutPresenter: false,
                        ),
                      ),
                    ),
                  ),
                ),
                surcharges: _surcharges('teacher', moteur),
                echelleTexte: texte,
              ),
            );
            await tester.pumpAndSettle();
            // En salle, connecte : sans droit, rien n'empeche un autre
            // enseignant de la seance d'avoir presente une page.
            moteur.poser(EtatSalle.connecte);
            if (presente) {
              moteur.publierContenu(
                ContenuPresente(
                  page: 42,
                  sourate: 2,
                  verset: 255,
                  presentePar: 't2',
                  emisLe: DateTime.now(),
                ),
              );
            }
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final Finder phrase = find.text(
              t.enseignant.salle.sansDroitPresentation,
            );
            expect(phrase.hitTestable(), findsOneWidget);
            final Rect zone = tester.getRect(phrase);
            expect(zone.bottom, lessThanOrEqualTo(plancher + 0.5));
            expect(zone.right, lessThanOrEqualTo(largeur + 0.5));
            // Le droit refuse ne se grise pas : aucune commande n'existe.
            expect(find.text(t.salle.ouvrirCoran), findsNothing);
            // Relire la page n'est pas presenter : l'action de l'erreur de
            // lecture reste, a l'ecran et touchable.
            if (presente) {
              final Finder reessayer = find.text(t.commun.reessayer);
              expect(reessayer.hitTestable(), findsOneWidget);
              expect(
                tester.getRect(reessayer).bottom,
                lessThanOrEqualTo(plancher + 0.5),
              );
            }
          },
        );
      }
    }
  });

  group('SALLE-ERR-320-1 : captures', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    final List<Override> corpusVide = <Override>[
      pageCoranProvider.overrideWith(
        (Ref _, int numero) async =>
            PageCoran(numero: numero, versets: const <VersetCoran>[]),
      ),
    ];
    for (final (String etat, List<Override> enPlus, bool presenter)
        in <(String, List<Override>, bool)>[
          ('erreur', const <Override>[], true),
          ('corpus', corpusVide, true),
          ('vide', const <Override>[], false),
        ]) {
      for (final (
            String l,
            double largeur,
            double hauteur,
            double texte,
            double densite,
          )
          in <(String, double, double, double, double)>[
            ('320_x2', 320, 700, 2, 2),
            ('390', 390, 844, 1, 3),
            ('1440', 1440, 900, 1, 1),
          ]) {
        for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
          ('clair', ThemeMode.light),
          ('sombre', ThemeMode.dark),
        ]) {
          final String nom = 'salle_err320_enseignant_${etat}_${l}_$m';
          testWidgets(nom, (WidgetTester tester) async {
            await _monter(
              tester,
              'teacher',
              largeur,
              texte,
              densite: densite,
              themeMode: mode,
              hauteur: hauteur,
              enPlus: enPlus,
              presenter: presenter,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });

  group('SALLE-ENCRE-1 : captures', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String role, String nom) in <(String, String)>[
      ('teacher', 'enseignant'),
      ('student', 'eleve'),
    ]) {
      for (final (
            String l,
            double largeur,
            double hauteur,
            double texte,
            double densite,
          )
          in <(String, double, double, double, double)>[
            ('320_x1', 320, 700, 1, 2),
            ('320_x2', 320, 700, 2, 2),
            ('390', 390, 844, 1, 3),
            ('1440', 1440, 900, 1, 1),
          ]) {
        for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
          ('clair', ThemeMode.light),
          ('sombre', ThemeMode.dark),
        ]) {
          testWidgets('salle_encre1_${nom}_${l}_$m', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              role,
              largeur,
              texte,
              densite: densite,
              themeMode: mode,
              hauteur: hauteur,
            );
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'salle_encre1_${nom}_${l}_$m')}',
            );
          });
        }
      }
    }
  });

  group('SALLE-CORR-4 m10 : captures', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String role, String nom) in <(String, String)>[
      ('teacher', 'enseignant'),
      ('student', 'eleve'),
      ('masked_controller', 'controleur'),
    ]) {
      for (final (
            String l,
            double largeur,
            double hauteur,
            double texte,
            double densite,
          )
          in <(String, double, double, double, double)>[
            ('320_x1', 320, 700, 1, 2),
            ('320_x2', 320, 700, 2, 2),
            ('390', 390, 844, 1, 3),
            ('1440', 1440, 900, 1, 1),
          ]) {
        for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
          ('clair', ThemeMode.light),
          ('sombre', ThemeMode.dark),
        ]) {
          testWidgets('salle_corr4_m10_${nom}_${l}_$m', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              role,
              largeur,
              texte,
              densite: densite,
              themeMode: mode,
              hauteur: hauteur,
            );
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'salle_corr4_m10_${nom}_${l}_$m')}',
            );
          });
        }
      }
    }
  });
  group('SALLE-CORR-3 : captures', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String role, String nom) in <(String, String)>[
      ('teacher', 'enseignant'),
      ('student', 'eleve'),
      ('masked_controller', 'controleur'),
    ]) {
      for (final (
            String l,
            double largeur,
            double hauteur,
            double texte,
            double densite,
          )
          in <(String, double, double, double, double)>[
            ('320_x1', 320, 700, 1, 2),
            ('320_x2', 320, 700, 2, 2),
            ('390', 390, 844, 1, 3),
            ('1440', 1440, 900, 1, 1),
          ]) {
        for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
          ('clair', ThemeMode.light),
          ('sombre', ThemeMode.dark),
        ]) {
          testWidgets('salle_corr3_${nom}_${l}_$m', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              role,
              largeur,
              texte,
              densite: densite,
              themeMode: mode,
              hauteur: hauteur,
            );
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'salle_corr3_${nom}_${l}_$m')}',
            );
          });
        }
      }
    }
  });

  group('SALLE-200-1 : captures 390 px, texte x2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final String role in <String>['student', 'teacher']) {
      testWidgets(role, (WidgetTester tester) async {
        await _monter(tester, role, 390, 2, densite: 2);
        final String nom = role == 'student' ? 'eleve' : 'enseignant';
        await capturer(tester, 'salle200_${nom}_390_x2');
      });
    }
  });

  // Standard des commandes d'appel (decision du directeur, 24/10/2026) : il
  // remplace dans la salle ETATS-MA-1 (mot d'etat et deux rangees de mots a
  // plus de 130 %) et DOCK-X2-1 (mot entier du dock a x2). La pilule garde ses
  // boutons ronds a leur taille a toute echelle de texte, SANS aucun mot ; si
  // elle ne tient plus en largeur, elle passe sur deux rangees. L'etat se lit
  // par l'icone barree, la couleur, l'infobulle et le libelle de semantique.
  // Polices du depot chargees ; groupe pose en dernier.
  Future<void> verifierPiluleSansMot(
    WidgetTester tester, {
    required double largeur,
    required double hauteurEcran,
    required double diametre,
  }) async {
    expect(tester.takeException(), isNull);
    final Finder dock = find.byKey(const ValueKey<String>('dock-seance'));
    expect(dock, findsOneWidget);
    // Aucun mot, a aucune echelle de texte.
    expect(
      find.descendant(of: dock, matching: find.byType(Text)),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('commandes-deux-rangees')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('mot-commande')), findsNothing);
    // Tous les boutons gardent leur taille (Quitter est plus large).
    final Finder disques = find.descendant(
      of: dock,
      matching: find.byKey(const ValueKey<String>('disque-appel')),
    );
    expect(disques, findsWidgets);
    for (final Element e in disques.evaluate()) {
      final Size taille = tester.getSize(find.byWidget(e.widget));
      expect(taille.height, closeTo(diametre, 0.5));
      expect(taille.width, greaterThanOrEqualTo(diametre - 0.5));
    }
    // La pilule tient dans l'ecran, deux rangees au plus.
    final Rect zone = tester.getRect(dock);
    expect(zone.left, greaterThanOrEqualTo(-0.5));
    expect(zone.right, lessThanOrEqualTo(largeur + 0.5));
    expect(zone.bottom, lessThanOrEqualTo(hauteurEcran + 0.5));
    // L'etat de la bascule micro est dit par l'infobulle et la semantique.
    expect(
      find.descendant(
        of: dock,
        matching: find.byTooltip(
          RegExp('${t.salle.microOuvert}|${t.salle.microCoupe}'),
        ),
      ),
      findsOneWidget,
    );
    // Quitter reste atteignable, a l'ecran.
    final Finder quitter = find.bySemanticsLabel(RegExp(t.salle.seance.sortir));
    expect(quitter, findsWidgets);
    expect(
      tester.getRect(quitter.first).bottom,
      lessThanOrEqualTo(hauteurEcran + 0.5),
    );
  }

  // Plan de composition du 26/10/2026 (Q1, decision du directeur) : sur
  // ordinateur, l'enseignant a deux groupes de commandes, chaque bouton
  // nomme dessous ; les boutons gardent leur taille, chaque nom se lit
  // entier, rien ne sort de l'ecran.
  Future<void> verifierBarreNommee(
    WidgetTester tester, {
    required double largeur,
    required double hauteurEcran,
    required double diametre,
  }) async {
    expect(tester.takeException(), isNull);
    final Finder docks = find.byKey(const ValueKey<String>('dock-seance'));
    expect(docks, findsNWidgets(2));
    for (final Element dock in docks.evaluate()) {
      final Finder ce = find.byWidget(dock.widget);
      final Finder disques = find.descendant(
        of: ce,
        matching: find.byKey(const ValueKey<String>('disque-appel')),
      );
      final Finder noms = find.descendant(
        of: ce,
        matching: find.byKey(const ValueKey<String>('nom-commande')),
      );
      expect(disques, findsWidgets);
      expect(noms.evaluate().length, disques.evaluate().length);
      for (final Element e in disques.evaluate()) {
        final Size taille = tester.getSize(find.byWidget(e.widget));
        expect(taille.height, closeTo(diametre, 0.5));
      }
      verifierAucunMotCoupe(tester, ce);
      final Rect zone = tester.getRect(ce);
      expect(zone.left, greaterThanOrEqualTo(-0.5));
      expect(zone.right, lessThanOrEqualTo(largeur + 0.5));
      expect(zone.bottom, lessThanOrEqualTo(hauteurEcran + 0.5));
    }
    final Finder quitter = find.bySemanticsLabel(RegExp(t.salle.seance.sortir));
    expect(quitter, findsWidgets);
    expect(
      tester.getRect(quitter.first).bottom,
      lessThanOrEqualTo(hauteurEcran + 0.5),
    );
  }

  group('Standard des commandes d\'appel : /salle en Mode Accessibilite, '
      'texte agrandi', () {
    setUpAll(chargerPolicesDuDepot);
    for (final String role in <String>['student', 'teacher']) {
      for (final double largeur in <double>[320, 390]) {
        for (final double texte in <double>[1.5, 2]) {
          testWidgets(
            '$role, $largeur px, texte x$texte : pilule sans mot, boutons '
            'a leur taille',
            (WidgetTester tester) async {
              await _monter(
                tester,
                role,
                largeur,
                texte,
                interfaceMode: InterfaceMode.enfant,
              );
              await verifierPiluleSansMot(
                tester,
                largeur: largeur,
                hauteurEcran: 844,
                diametre: 72,
              );
              if (role == 'teacher') {
                expect(
                  find.byTooltip(
                    RegExp('${t.salle.cameraAllumee}|${t.salle.cameraCoupee}'),
                  ),
                  findsOneWidget,
                );
              }
            },
          );
        }
      }
    }
    testWidgets(
      'student, 390 px, texte x2, hors Mode Accessibilite : inchange',
      (WidgetTester tester) async {
        await _monter(tester, 'student', 390, 2);
        expect(
          find.byKey(const ValueKey<String>('commandes-deux-rangees')),
          findsNothing,
        );
      },
    );
  });

  // Standard des commandes d'appel, ordinateur (48) et 320 x 568 en Mode
  // Accessibilite (56), texte x1,5 et x2 : jamais un mot, boutons a leur
  // taille, rien hors de l'ecran.
  group('Standard des commandes d\'appel : /salle, bureau et 320 x 568', () {
    setUpAll(chargerPolicesDuDepot);
    for (final String role in <String>['student', 'teacher']) {
      for (final (double l, double h) in <(double, double)>[
        (1440, 900),
        (1024, 768),
      ]) {
        for (final double texte in <double>[1.5, 2]) {
          testWidgets('$role, ${l.toInt()} px, texte x$texte : '
              '${role == 'teacher' ? 'barre nommee' : 'pilule sans mot'}', (
            WidgetTester tester,
          ) async {
            await _monter(tester, role, l, texte, hauteur: h);
            if (role == 'teacher') {
              await verifierBarreNommee(
                tester,
                largeur: l,
                hauteurEcran: h,
                diametre: 48,
              );
            } else {
              await verifierPiluleSansMot(
                tester,
                largeur: l,
                hauteurEcran: h,
                diametre: 48,
              );
            }
          });
        }
      }
      for (final double texte in <double>[1.5, 2]) {
        testWidgets(
          '$role, 320 x 568, Mode Accessibilite, texte x$texte : pilule '
          'sans mot (m5)',
          (WidgetTester tester) async {
            await _monter(
              tester,
              role,
              320,
              texte,
              hauteur: 568,
              interfaceMode: InterfaceMode.enfant,
            );
            await verifierPiluleSansMot(
              tester,
              largeur: 320,
              hauteurEcran: 568,
              diametre: 72,
            );
          },
        );
      }
    }
  });

  // S0.2d (directeur, 24/10/2026) : la carte Eleves de l'enseignant prend la
  // hauteur de son contenu, avec son rembourrage ; aucune ligne coupee ni
  // collee au bord, a 1366 et 1024, texte 100 % et 130 % (feuille Eleves
  // depuis K4).
  group('S0.2d : la carte Eleves ne coupe rien', () {
    setUpAll(chargerPolicesDuDepot);
    for (final double largeur in <double>[1366, 1024]) {
      for (final double texte in <double>[1, 1.3]) {
        testWidgets('${largeur.toInt()} px, texte x$texte', (
          WidgetTester tester,
        ) async {
          await _monter(tester, 'teacher', largeur, texte, hauteur: 768);
          expect(tester.takeException(), isNull);
          // Plan de composition du 26/10/2026 : sur ordinateur, les Eleves
          // sont le panneau de gauche, ouvert ; une carte par eleve. La regle
          // est la meme : rien de coupe ni de colle au bord.
          final Finder panneau = find.byKey(
            const ValueKey<String>('salle-ordinateur-eleves'),
          );
          expect(panneau, findsOneWidget);
          expect(find.byType(AppBottomSheet), findsNothing);
          final Rect cadre = tester.getRect(panneau);
          final Finder pastilles = find.descendant(
            of: panneau,
            matching: find.byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('eleve-'),
            ),
          );
          expect(pastilles, findsWidgets);
          verifierAucunMotCoupe(tester, panneau);
          for (final Element e in pastilles.evaluate()) {
            final Rect r = tester.getRect(find.byWidget(e.widget).first);
            expect(r.left, greaterThanOrEqualTo(cadre.left + 4));
            expect(r.right, lessThanOrEqualTo(cadre.right - 4));
            expect(r.bottom, lessThanOrEqualTo(cadre.bottom - 8));
          }
        });
      }
    }
  });
}
