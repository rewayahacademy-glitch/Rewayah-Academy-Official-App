// Captures du lot NAV-REFONTE, etape 2a (decisions du directeur du
// 09/11/2026) : le halo du cercle Compte (urgent, a lire), pendant la
// rotation puis en lueur fixe, la tuile du Mode Accessibilite, et la feuille
// « En ce moment ». 320 (la colonne laterale de 1440 ne porte pas encore le
// halo : etape 3), texte x1 et x2, clair et sombre, arabe.
//
// Scene composee avec le VRAI NavShell et les vraies destinations du tuteur ;
// donnees de test seulement. Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

enum _Moment { rotation, lueur, feuille }

typedef _Cas = ({
  String nom,
  bool urgent,
  _Moment moment,
  double texte,
  ThemeMode theme,
  AppLocale langue,
  InterfaceMode mode,
});

const Size _tel = Size(320, 700);

final List<_Cas> _cas = <_Cas>[
  for (final (String n, bool u) in <(String, bool)>[
    ('urgent', true),
    ('a-lire', false),
  ]) ...<_Cas>[
    (
      nom: '${n}_rotation_320_x1_clair',
      urgent: u,
      moment: _Moment.rotation,
      texte: 1,
      theme: ThemeMode.light,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
    (
      nom: '${n}_lueur_320_x1_clair',
      urgent: u,
      moment: _Moment.lueur,
      texte: 1,
      theme: ThemeMode.light,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
    (
      nom: '${n}_lueur_320_x1_sombre',
      urgent: u,
      moment: _Moment.lueur,
      texte: 1,
      theme: ThemeMode.dark,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
    (
      nom: '${n}_feuille_320_x1_clair',
      urgent: u,
      moment: _Moment.feuille,
      texte: 1,
      theme: ThemeMode.light,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
  ],
  (
    nom: 'urgent_lueur_320_x2_clair',
    urgent: true,
    moment: _Moment.lueur,
    texte: 2,
    theme: ThemeMode.light,
    langue: AppLocale.fr,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'urgent_feuille_320_x2_sombre',
    urgent: true,
    moment: _Moment.feuille,
    texte: 2,
    theme: ThemeMode.dark,
    langue: AppLocale.fr,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'a-lire_lueur_320_x1_arabe',
    urgent: false,
    moment: _Moment.lueur,
    texte: 1,
    theme: ThemeMode.light,
    langue: AppLocale.ar,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'urgent_feuille_320_x1_arabe',
    urgent: true,
    moment: _Moment.feuille,
    texte: 1,
    theme: ThemeMode.light,
    langue: AppLocale.ar,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'urgent_tuile_320_x1_accessibilite',
    urgent: true,
    moment: _Moment.lueur,
    texte: 1,
    theme: ThemeMode.light,
    langue: AppLocale.fr,
    mode: InterfaceMode.enfant,
  ),
  (
    nom: 'a-lire_tuile_320_x2_accessibilite_sombre',
    urgent: false,
    moment: _Moment.lueur,
    texte: 2,
    theme: ThemeMode.dark,
    langue: AppLocale.fr,
    mode: InterfaceMode.enfant,
  ),
];

void main() {
  group('Capture : halo du cercle Compte', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Cas c in _cas) {
      testWidgets(c.nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(c.langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, _tel, 1);
        final List<Destination> destinations = destinationsPour(
          role: AppRole.guardian,
          mode: c.mode,
        );
        final EtatHaloCompte halo = c.urgent
            ? EtatHaloCompte.urgent(
                titre: 'Remplacement : une réponse est attendue',
                detail: 'Classe de tajwid, ce soir à 18 h',
                chemin: Routes.tuteurNotifications,
              )
            : EtatHaloCompte.nouveau(
                nombre: 2,
                chemin: Routes.tuteurNotifications,
              );
        await tester.pumpWidget(
          hoteCapture(
            NavShell(
              destinations: destinations,
              indexActif: 0,
              onAller: (_) {},
              halo: halo,
              child: PageShell(
                titre: destinations.first.libelle,
                child: const SizedBox(height: 200),
              ),
            ),
            surcharges: <Override>[sansPersonneConnectee()],
            themeMode: c.theme,
            echelleTexte: c.texte,
            interfaceMode: c.mode,
          ),
        );
        switch (c.moment) {
          case _Moment.rotation:
            // Au milieu du premier tour, apres le retournement.
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 1100));
          case _Moment.lueur:
            await tester.pumpAndSettle();
          case _Moment.feuille:
            await tester.pumpAndSettle();
            await tester.tap(
              find.bySemanticsLabel(halo.nomAccessible(t.nav.tuteur.compte)),
            );
            await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'nav-halo_${c.nom}')}');
      });
    }
  });
}
