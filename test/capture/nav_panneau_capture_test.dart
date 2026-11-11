// Captures du lot NAV-REFONTE, etape 3 (brief du garde-cap du 09/11/2026,
// feu vert du pilote du 11/11/2026) : le panneau de la tablette et de
// l'ordinateur, un seul bouton carre, le Compte au pied (photo, prenom,
// menu) ; 320 (la barre du telephone, inchangee), 800 et 1440, texte x1 et
// x2, clair et sombre, arabe, Mode Accessibilite ; ouvert, replie, menu
// ouvert, halo.
//
// Scene composee avec le VRAI NavShell et les vraies destinations
// (`destinationsPour`), sans personne connectee (aucune donnee reelle) ; le
// contenu de page est un gabarit vide. Saute sans CAPTURE_DIR
// (test/capture/LISEZ-MOI.md).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/avatar_compte.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../router/support_routeur.dart' show sessionActive;
import '../support/harnais.dart'
    show FausseSourceSession, sansPersonneConnectee;
import 'outil_capture.dart';

typedef _Cas = ({
  String nom,
  AppRole role,
  Size vue,
  double texte,
  ThemeMode theme,
  AppLocale langue,
  InterfaceMode mode,
  bool basculer,
  bool menu,
  bool halo,
  bool demo,
});

const Size _tel = Size(320, 700);
const Size _tablette = Size(800, 1000);
const Size _bureau = Size(1440, 900);

_Cas _c(
  String nom, {
  AppRole role = AppRole.teacher,
  Size vue = _bureau,
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  AppLocale langue = AppLocale.fr,
  InterfaceMode mode = InterfaceMode.standard,
  bool basculer = false,
  bool menu = false,
  bool halo = false,
  bool demo = false,
}) => (
  nom: nom,
  role: role,
  vue: vue,
  texte: texte,
  theme: theme,
  langue: langue,
  mode: mode,
  basculer: basculer,
  menu: menu,
  halo: halo,
  demo: demo,
);

final List<_Cas> _cas = <_Cas>[
  // Compte de demonstration (pilote, 11/11/2026) : prenom fictif et photo
  // synthetique servie en local ; jamais une personne reelle.
  _c('demo_1440_x1_clair_ouvert', demo: true),
  _c('demo_1440_x1_clair_replie', demo: true, basculer: true),
  _c('demo_1440_x1_sombre_menu', demo: true, theme: ThemeMode.dark, menu: true),
  _c('demo_1440_x1_arabe_ouvert', demo: true, langue: AppLocale.ar),
  _c('demo_800_x2_clair_replie', demo: true, vue: _tablette, texte: 2),
  _c('enseignant_1440_x1_clair_ouvert'),
  _c('enseignant_1440_x1_clair_replie', basculer: true),
  _c('enseignant_1440_x1_clair_menu', menu: true),
  _c('enseignant_1440_x2_clair_ouvert', texte: 2),
  _c('enseignant_1440_x1_sombre_ouvert', theme: ThemeMode.dark),
  _c(
    'enseignant_1440_x2_sombre_menu',
    texte: 2,
    theme: ThemeMode.dark,
    menu: true,
  ),
  _c('enseignant_1440_x1_arabe_ouvert', langue: AppLocale.ar),
  _c('enseignant_1440_x1_arabe_replie', langue: AppLocale.ar, basculer: true),
  _c('enseignant_1440_x1_halo_menu', halo: true, menu: true),
  _c('tuteur_1440_x1_clair_ouvert', role: AppRole.guardian),
  _c(
    'tuteur_1440_x1_accessibilite_ouvert',
    role: AppRole.guardian,
    mode: InterfaceMode.enfant,
  ),
  _c('enseignant_800_x1_clair_replie', vue: _tablette),
  _c(
    'enseignant_800_x2_sombre_replie',
    vue: _tablette,
    texte: 2,
    theme: ThemeMode.dark,
  ),
  _c('enseignant_800_x1_clair_ouvert', vue: _tablette, basculer: true),
  _c(
    'tuteur_800_x1_accessibilite_replie',
    role: AppRole.guardian,
    vue: _tablette,
    mode: InterfaceMode.enfant,
  ),
  _c(
    'tuteur_800_x2_accessibilite_arabe_replie',
    role: AppRole.guardian,
    vue: _tablette,
    texte: 2,
    langue: AppLocale.ar,
    mode: InterfaceMode.enfant,
  ),
  _c('enseignant_320_x1_clair', vue: _tel),
  _c('enseignant_320_x2_sombre', vue: _tel, texte: 2, theme: ThemeMode.dark),
];

void main() {
  group(
    'Capture : panneau de navigation (tablette, ordinateur)',
    skip: sautSansCapture,
    () {
      late HttpServer serveur;
      setUpAll(() async {
        await chargerPolicesDuDepot();
        final Uint8List photo = await _photoDeDemonstration();
        serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        serveur.listen((HttpRequest r) async {
          r.response.headers.contentType = ContentType('image', 'png');
          r.response.add(photo);
          await r.response.close();
        });
      });
      tearDownAll(() => serveur.close(force: true));

      for (final _Cas c in _cas) {
        testWidgets(c.nom, (WidgetTester tester) async {
          // Le compte de demonstration charge sa photo par HTTP local : le
          // client reseau factice de flutter_test repondrait 400.
          if (c.demo) HttpOverrides.global = null;
          await tester.runAsync(() => LocaleSettings.setLocale(c.langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, c.vue, 1);
          final List<Destination> destinations = destinationsPour(
            role: c.role,
            mode: c.mode,
          );
          await tester.pumpWidget(
            hoteCapture(
              NavShell(
                destinations: destinations,
                indexActif: 0,
                onAller: (_) {},
                onDeconnexion: () {},
                libellesDansLeRail: c.role != AppRole.guardian,
                halo: c.halo
                    ? EtatHaloCompte.nouveau(
                        nombre: 2,
                        chemin: '/notifications',
                      )
                    : null,
                child: PageShell(
                  titre: destinations.first.libelle,
                  child: const SizedBox(height: 200),
                ),
              ),
              surcharges: c.demo
                  ? <Override>[
                      sourceSessionProvider.overrideWithValue(
                        FausseSourceSession(sessionActive(AppRole.teacher)),
                      ),
                      prenomDuCompteProvider.overrideWith(
                        (Ref _) async => 'Yasmine',
                      ),
                      photoPersonneProvider.overrideWith(
                        (Ref _, String _) async =>
                            'http://127.0.0.1:${serveur.port}/photo.png',
                      ),
                    ]
                  : <Override>[sansPersonneConnectee()],
              themeMode: c.theme,
              echelleTexte: c.texte,
              interfaceMode: c.mode,
            ),
          );
          await stabiliser(tester);
          if (c.demo) {
            // La photo se charge par le reseau local, hors du temps simule.
            for (int i = 0; i < 3; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 300)),
              );
              await stabiliser(tester);
            }
          }
          if (c.basculer) {
            await tester.tap(find.byKey(NavShell.boutonRepliKey));
            await stabiliser(tester);
          }
          if (c.menu) {
            await tester.tap(find.byKey(NavShell.piedCompteKey));
            await stabiliser(tester);
          }
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, 'nav-panneau_${c.nom}')}');
          // Le chargement de la photo laisse des minuteries : on demonte la
          // scene et on laisse le temps simule les solder.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 1));
        });
      }
    },
  );
}

/// Une photo synthetique (degrade et silhouette), dessinee ici : aucune image
/// d'une personne reelle.
Future<Uint8List> _photoDeDemonstration() async {
  const double t = 256;
  final ui.PictureRecorder enregistreur = ui.PictureRecorder();
  final Canvas toile = Canvas(enregistreur);
  toile.drawRect(
    const Rect.fromLTWH(0, 0, t, t),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(t, t),
        const <Color>[Color(0xFFB9A4F2), Color(0xFF6538E4)],
      ),
  );
  final Paint silhouette = Paint()..color = const Color(0xFFF3EEFF);
  toile.drawCircle(const Offset(t / 2, t * 0.4), t * 0.18, silhouette);
  toile.drawOval(
    const Rect.fromLTWH(t * 0.18, t * 0.64, t * 0.64, t * 0.6),
    silhouette,
  );
  final ui.Image image = await enregistreur.endRecording().toImage(
    t.toInt(),
    t.toInt(),
  );
  final ByteData? octets = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  return octets!.buffer.asUint8List();
}
