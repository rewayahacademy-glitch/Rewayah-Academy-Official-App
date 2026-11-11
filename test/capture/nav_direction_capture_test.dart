// Captures du lot NAV-REFONTE, etape 4, part sans decision ouverte (feu vert
// du pilote du 11/11/2026) : la colonne de la direction, bouton fixe du
// panneau (a partir de 1200), compte au pied (photo, nom, menu), huit
// domaines inchanges ; 800 (rail fige) et 1440, texte x1 et x2, clair et
// sombre, arabe, menu ouvert. Le VRAI AdminShell, sans personne connectee
// (aucune donnee reelle). Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/avatar_compte.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../router/support_routeur.dart' show sessionActive;
import '../support/harnais.dart'
    show FausseSourceSession, sansPersonneConnectee;
import 'compte_demonstration.dart';
import 'outil_capture.dart';

typedef _Cas = ({
  String nom,
  Size vue,
  double texte,
  ThemeMode theme,
  AppLocale langue,
  bool basculer,
  bool menu,
  bool demo,
});

_Cas _c(
  String nom, {
  Size vue = const Size(1440, 900),
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  AppLocale langue = AppLocale.fr,
  bool basculer = false,
  bool menu = false,
  bool demo = false,
}) => (
  nom: nom,
  vue: vue,
  texte: texte,
  theme: theme,
  langue: langue,
  basculer: basculer,
  menu: menu,
  demo: demo,
);

final List<_Cas> _cas = <_Cas>[
  // Compte de demonstration de la direction (pilote, 11/11/2026) : prenom
  // fictif et photo synthetique servie en local, jamais une personne reelle.
  _c('demo_1440_x1_clair_ouvert', demo: true),
  _c('demo_1440_x1_clair_replie', demo: true, basculer: true),
  _c('demo_1440_x1_sombre_menu', demo: true, theme: ThemeMode.dark, menu: true),
  _c('demo_1440_x1_arabe_ouvert', demo: true, langue: AppLocale.ar),
  _c(
    'demo_800_x2_clair_rail',
    demo: true,
    vue: const Size(800, 1000),
    texte: 2,
  ),
  _c('1440_x1_clair_ouvert'),
  _c('1440_x1_clair_replie', basculer: true),
  _c('1440_x1_clair_menu', menu: true),
  _c('1440_x2_clair_ouvert', texte: 2),
  _c('1440_x1_sombre_menu', theme: ThemeMode.dark, menu: true),
  _c('1440_x1_arabe_ouvert', langue: AppLocale.ar),
  _c('1440_x1_arabe_replie', langue: AppLocale.ar, basculer: true),
  _c('800_x1_clair_rail', vue: const Size(800, 1000)),
  _c(
    '800_x2_sombre_rail',
    vue: const Size(800, 1000),
    texte: 2,
    theme: ThemeMode.dark,
  ),
];

void main() {
  group('Capture : panneau de la direction', skip: sautSansCapture, () {
    late HttpServer serveur;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      final Uint8List photo = await photoDeDemonstration();
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
        // La photo de demonstration passe par HTTP local : le client
        // factice de flutter_test repondrait 400.
        if (c.demo) HttpOverrides.global = null;
        await tester.runAsync(() => LocaleSettings.setLocale(c.langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, c.vue, 1);
        await tester.pumpWidget(
          hoteCapture(
            AdminShell(
              domaines: domainesAdmin(voitDirection: true),
              domaineActif: AdminDomaine.accueil,
              onAller: (_) {},
              onCompte: () {},
              onDeconnexion: () {},
              child: PageShell(
                titre: AdminDomaine.accueil.libelle,
                child: const SizedBox(height: 200),
              ),
            ),
            surcharges: c.demo
                ? <Override>[
                    sourceSessionProvider.overrideWithValue(
                      FausseSourceSession(sessionActive(AppRole.admin)),
                    ),
                    prenomDuCompteProvider.overrideWith(
                      (Ref _) async => prenomDeDemonstration,
                    ),
                    photoPersonneProvider.overrideWith(
                      (Ref _, String _) async =>
                          'http://127.0.0.1:${serveur.port}/photo.png',
                    ),
                  ]
                : <Override>[sansPersonneConnectee()],
            themeMode: c.theme,
            echelleTexte: c.texte,
            interfaceMode: InterfaceMode.standard,
          ),
        );
        await stabiliser(tester);
        if (c.demo) {
          for (int i = 0; i < 3; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)),
            );
            await stabiliser(tester);
          }
        }
        if (c.basculer) {
          await tester.tap(find.byKey(AdminShell.boutonPanneauKey));
          await stabiliser(tester);
        }
        if (c.menu) {
          await tester.tap(find.byKey(NavShell.piedCompteKey));
          await stabiliser(tester);
        }
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'nav-direction_${c.nom}')}');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
      });
    }
  });
}
