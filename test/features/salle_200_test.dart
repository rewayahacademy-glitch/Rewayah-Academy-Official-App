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
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';

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
}) async {
  fixerVueCapture(tester, Size(largeur, hauteur), densite);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(role, moteur),
      echelleTexte: texte,
      themeMode: themeMode,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', 'Omar', role == 'teacher'),
    _personne('e1', 'student', 'Yasmine', role == 'student'),
    _personne('e2', 'student', 'Ilyes', false),
  ]);
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

            // Le support garde au moins la moitie de la hauteur.
            final Rect contenu = tester.getRect(
              find.byKey(PageImmersive.contenuKey),
            );
            expect(
              contenu.height,
              greaterThanOrEqualTo(844 / 2),
              reason: 'support de ${contenu.height} px sur 844',
            );

            // Quitter reste atteignable, a l'ecran.
            final Finder quitter = role == 'masked_controller'
                ? find.bySemanticsLabel(RegExp(t.salle.quitter))
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
        await _monter(tester, 'student', largeur, 1);
        expect(tester.takeException(), isNull);
        final double bas = tester
            .getRect(find.byKey(PageImmersive.contenuKey))
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
        testWidgets('$role, ${mode.name} : mot et icone a l encre du fond', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, 390, 1, themeMode: mode);
          expect(tester.takeException(), isNull);
          final AppPalette palette = AppPalette.of(
            tester.element(find.byType(SallePage)),
          );
          final Color fond = palette.surfaceInverse.background;
          final Color encre = palette.surfaceInverse.onBackground;
          final Finder mots = find.byKey(
            const ValueKey<String>('mot-commande'),
          );
          expect(mots, findsWidgets);
          for (final Element mot in mots.evaluate()) {
            final Text texte = mot.widget as Text;
            expect(texte.style?.color, encre, reason: '« ${texte.data} »');
          }
          // Une bascule inactive n'a que son contour : son icone se pose sur
          // le fond de la salle, et doit s'y lire.
          int transparents = 0;
          for (final Element disque
              in find
                  .byKey(const ValueKey<String>('disque-appel'))
                  .evaluate()) {
            final DecoratedBox boite = tester.widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byWidget(disque.widget),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            );
            final Decoration deco = boite.decoration;
            if (deco is BoxDecoration && deco.color == null) {
              transparents++;
              final Element icone = find
                  .descendant(
                    of: find.byWidget(disque.widget),
                    matching: find.byType(Icon),
                  )
                  .evaluate()
                  .first;
              final Color? couleur = IconTheme.of(icone).color;
              expect(couleur, encre);
              expect(couleur, isNot(fond));
            }
          }
          expect(transparents, greaterThan(0));
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
}
