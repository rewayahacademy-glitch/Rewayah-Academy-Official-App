// Captures du lot NAV-SOUS-LIENS (14/11/2026, regle 19 des consignes du
// directeur) : le panneau de la direction montre les pages du domaine ouvert
// (Personnes, page Candidatures), en trois sections ; a 1024 et 800 le rail
// et son panneau ouvert par-dessus la page avec un voile ; au telephone (390)
// rien ne change et la page garde son selecteur. 1440, 1024, 800 et 390, en
// francais et en arabe, clair et sombre ; plus le menu du rail replie et le
// texte a 200 %. Le VRAI AdminShell, sans personne connectee (aucune donnee
// reelle). Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

/// Ce que la capture montre en plus de l'etat de repos.
enum _Geste {
  /// Le panneau tel qu'il s'ouvre.
  aucun,

  /// Tablette : le panneau ouvert par-dessus la page, avec son voile.
  panneauOuvert,

  /// Ordinateur : le panneau replie, le menu des pages de Personnes ouvert.
  menuRail,
}

typedef _Cas = ({
  String nom,
  Size vue,
  double texte,
  ThemeMode theme,
  AppLocale langue,
  _Geste geste,
});

final List<_Cas> _cas = <_Cas>[
  for (final Size vue in const <Size>[
    Size(1440, 900),
    Size(1024, 768),
    Size(800, 1000),
    Size(390, 844),
  ])
    for (final AppLocale langue in const <AppLocale>[
      AppLocale.fr,
      AppLocale.ar,
    ])
      for (final ThemeMode theme in const <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ])
        (
          nom:
              '${vue.width.toInt()}_${langue.name}_'
              '${theme == ThemeMode.light ? 'clair' : 'sombre'}',
          vue: vue,
          texte: 1,
          theme: theme,
          langue: langue,
          geste: _Geste.aucun,
        ),
  for (final Size vue in const <Size>[Size(1024, 768), Size(800, 1000)])
    for (final AppLocale langue in const <AppLocale>[
      AppLocale.fr,
      AppLocale.ar,
    ])
      (
        nom: '${vue.width.toInt()}_${langue.name}_clair_panneau_ouvert',
        vue: vue,
        texte: 1,
        theme: ThemeMode.light,
        langue: langue,
        geste: _Geste.panneauOuvert,
      ),
  (
    nom: '800_fr_sombre_panneau_ouvert',
    vue: const Size(800, 1000),
    texte: 1,
    theme: ThemeMode.dark,
    langue: AppLocale.fr,
    geste: _Geste.panneauOuvert,
  ),
  for (final AppLocale langue in const <AppLocale>[AppLocale.fr, AppLocale.ar])
    (
      nom: '1440_${langue.name}_clair_rail_menu',
      vue: const Size(1440, 900),
      texte: 1,
      theme: ThemeMode.light,
      langue: langue,
      geste: _Geste.menuRail,
    ),
  (
    nom: '1440_fr_clair_x2',
    vue: const Size(1440, 900),
    texte: 2,
    theme: ThemeMode.light,
    langue: AppLocale.fr,
    geste: _Geste.aucun,
  ),
];

void main() {
  group(
    'Capture : sous-liens du panneau de la direction',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final _Cas c in _cas) {
        testWidgets(c.nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(c.langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, c.vue, 1);
          final List<SousLien> personnes = ongletsPersonnes();
          await tester.pumpWidget(
            hoteCapture(
              AdminShell(
                domaines: domainesAdmin(voitDirection: true),
                domaineActif: AdminDomaine.personnes,
                onAller: (_) {},
                onCompte: () {},
                onDeconnexion: () {},
                sousLiens: sousLiensAdmin(politiqueRevueKyc: true),
                cheminCourant: Routes.adminPersonnesCandidatures,
                child: PageShell(
                  titre: t.admin.candidatures.titre,
                  // Au telephone, la page garde son selecteur ; des 600, le
                  // panneau porte deja ces pages et la page ne le repete pas.
                  entete: SousNavigationDomaine(
                    onglets: personnes,
                    indexActif: personnes.indexWhere(
                      (SousLien o) =>
                          o.chemin == Routes.adminPersonnesCandidatures,
                    ),
                  ),
                  child: const SizedBox(height: 200),
                ),
              ),
              surcharges: <Override>[sansPersonneConnectee()],
              themeMode: c.theme,
              echelleTexte: c.texte,
              interfaceMode: InterfaceMode.standard,
            ),
          );
          await stabiliser(tester);
          switch (c.geste) {
            case _Geste.aucun:
              break;
            case _Geste.panneauOuvert:
              await tester.tap(find.byKey(AdminShell.boutonPanneauKey));
              await tester.pumpAndSettle();
            case _Geste.menuRail:
              await tester.tap(find.byKey(AdminShell.boutonPanneauKey));
              await stabiliser(tester);
              await tester.tap(
                find.descendant(
                  of: find.byKey(AdminShell.railKey),
                  matching: find.byTooltip(AdminDomaine.personnes.libelle),
                ),
              );
              await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'nav-sous-liens_${c.nom}')}',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 1));
        });
      }
    },
  );
}
