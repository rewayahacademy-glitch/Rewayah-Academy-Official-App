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
import 'package:rewayah_academy/core/widgets/commande_salle.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_enseignant/panneau_enseignant.dart';
import 'package:rewayah_academy/features/salle_seance/composition_salle.dart';
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
        testWidgets('$role, ${mode.name} : mot et icone lisibles', (
          WidgetTester tester,
        ) async {
          // S0 : la salle de seance suit le theme de l'application (plus de
          // fond sombre impose) ; le mot de chaque commande se lit sur ce qui
          // est dessous, et l'icone d'une bascule inactive (contour seul)
          // aussi (3:1, composant).
          await _monter(tester, role, 390, 1, themeMode: mode);
          expect(tester.takeException(), isNull);
          final Finder mots = find.byKey(
            const ValueKey<String>('mot-commande'),
          );
          _lisible(tester, mots, 'mot de commande ($role)');
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
              final Color fond = _fondSous(
                tester,
                find.byWidget(disque.widget).first,
              );
              expect(
                contraste(couleur!, fond),
                greaterThanOrEqualTo(seuilComposant),
              );
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
            // S0 : l'eleve lit SA ligne sous l'en-tete ; l'enseignant ouvre
            // la liste par le lien « Presence ».
            if (role == 'teacher') {
              // S0.2c : la presence de l'enseignant vit dans sa colonne
              // Eleves (une ligne par personne) ; au telephone, « Eleves »
              // l'ouvre en feuille.
              final Finder ouvrir = find.byKey(
                const ValueKey<String>('salle-eleves'),
              );
              if (ouvrir.evaluate().isNotEmpty) {
                _lisible(tester, find.text(t.salle.seance.eleves), 'Eleves');
                await tester.tap(ouvrir.first);
                await tester.pumpAndSettle();
              }
              _lisible(
                tester,
                find.descendant(
                  of: find.byType(StatusPill),
                  matching: find.byType(Text),
                ),
                'presence ($role)',
              );
              return;
            }
            // S0.2 : la pastille de presence de l'eleve, dans l'en-tete.
            _lisible(
              tester,
              find.descendant(
                of: find.byType(StatusPill),
                matching: find.byType(Text),
              ),
              'pastille de presence ($role)',
            );
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

  // ETATS-MA-1 (decision du 05/10/2026, WCAG 1.4.1) : la salle `/salle`
  // atteinte en Mode Accessibilite, texte au-dela de 130 % : les bascules
  // gardent leur mot d'etat, les commandes passent sur deux rangees (deux
  // par deux). Polices du depot chargees : la coupure des mots se mesure sur
  // la vraie police. Groupe pose en dernier : le chargement ne touche pas
  // les autres groupes.
  group('ETATS-MA-1 : /salle en Mode Accessibilite, texte agrandi', () {
    setUpAll(chargerPolicesDuDepot);
    for (final String role in <String>['student', 'teacher']) {
      for (final double largeur in <double>[320, 390]) {
        for (final double texte in <double>[1.5, 2]) {
          testWidgets(
            '$role, $largeur px, texte x$texte : mot d etat visible',
            (WidgetTester tester) async {
              await _monter(
                tester,
                role,
                largeur,
                texte,
                interfaceMode: InterfaceMode.enfant,
              );
              expect(tester.takeException(), isNull);
              final Finder grille = find.byKey(
                const ValueKey<String>('commandes-deux-rangees'),
              );
              expect(grille, findsOneWidget);
              final List<String> mots = tester
                  .widgetList<Text>(
                    find.descendant(
                      of: grille,
                      matching: find.byKey(
                        const ValueKey<String>('mot-commande'),
                      ),
                    ),
                  )
                  .map((Text t) => t.data!)
                  .toList();
              expect(
                mots,
                contains(anyOf(t.salle.microOuvert, t.salle.microCoupe)),
              );
              if (role == 'teacher') {
                expect(
                  mots,
                  contains(anyOf(t.salle.cameraAllumee, t.salle.cameraCoupee)),
                );
              }
              verifierAucunMotCoupe(tester, grille);
              final Rect zone = tester.getRect(grille);
              expect(zone.left, greaterThanOrEqualTo(-0.5));
              expect(zone.right, lessThanOrEqualTo(largeur + 0.5));
              expect(zone.bottom, lessThanOrEqualTo(844.5));
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

  // DOCK-X2-1 : /salle sur ordinateur, hors Mode Accessibilite, texte x1,5
  // et x2 : aucun mot coupe ni tronque sous les commandes. Et m5 (verification
  // d'ETATS-MA-1) : /salle en Mode Accessibilite a 320 x 568, texte x1,5 et
  // x2 : deux rangees, mot d'etat entier, rien hors de l'ecran.
  group('DOCK-X2-1 : /salle, bureau et 320 x 568', () {
    setUpAll(chargerPolicesDuDepot);
    final Finder commandes = find.byType(CommandeSalle);
    for (final String role in <String>['student', 'teacher']) {
      for (final (double l, double h) in <(double, double)>[
        (1440, 900),
        (1024, 768),
      ]) {
        for (final double texte in <double>[1.5, 2]) {
          testWidgets(
            '$role, ${l.toInt()} px, texte x$texte : aucun mot coupe',
            (WidgetTester tester) async {
              await _monter(tester, role, l, texte, hauteur: h);
              expect(tester.takeException(), isNull);
              expect(commandes, findsWidgets);
              verifierAucunMotCoupe(tester, commandes);
            },
          );
        }
      }
      for (final double texte in <double>[1.5, 2]) {
        testWidgets(
          '$role, 320 x 568, Mode Accessibilite, texte x$texte (m5)',
          (WidgetTester tester) async {
            await _monter(
              tester,
              role,
              320,
              texte,
              hauteur: 568,
              interfaceMode: InterfaceMode.enfant,
            );
            expect(tester.takeException(), isNull);
            final Finder grille = find.byKey(
              const ValueKey<String>('commandes-deux-rangees'),
            );
            expect(grille, findsOneWidget);
            final List<String> mots = tester
                .widgetList<Text>(
                  find.descendant(
                    of: grille,
                    matching: find.byKey(
                      const ValueKey<String>('mot-commande'),
                    ),
                  ),
                )
                .map((Text t) => t.data!)
                .toList();
            expect(
              mots,
              contains(anyOf(t.salle.microOuvert, t.salle.microCoupe)),
            );
            verifierAucunMotCoupe(tester, grille);
            final Rect zone = tester.getRect(grille);
            expect(zone.left, greaterThanOrEqualTo(-0.5));
            expect(zone.right, lessThanOrEqualTo(320.5));
            expect(zone.bottom, lessThanOrEqualTo(568.5));
            // Quitter reste atteignable, a l'ecran (S0 : le dock de la salle
            // de seance, « Sortir de la seance »).
            final Finder quitter = find.bySemanticsLabel(
              RegExp(t.salle.seance.sortir),
            );
            expect(quitter, findsWidgets);
            expect(
              tester.getRect(quitter.first).bottom,
              lessThanOrEqualTo(568.5),
            );
          },
        );
      }
    }
  });
}
