// Captures du lot NAV-REFONTE, etape 2a (decisions du directeur du
// 09/11/2026) et 2b (10/11/2026) : le halo du cercle Compte (urgent, salle
// ouverte, a lire), pendant la
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
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

enum _Moment { rotation, lueur, feuille }

typedef _Cas = ({
  String nom,
  NatureHalo nature,
  _Moment moment,
  double texte,
  ThemeMode theme,
  AppLocale langue,
  InterfaceMode mode,
});

const Size _tel = Size(320, 700);

final List<_Cas> _cas = <_Cas>[
  for (final (String n, NatureHalo u) in <(String, NatureHalo)>[
    ('urgent', NatureHalo.urgent),
    ('a-lire', NatureHalo.nouveau),
    // Etape 2b (10/11/2026) : la salle ouverte, halo vert qui respire.
    ('salle', NatureHalo.salle),
  ]) ...<_Cas>[
    (
      nom: '${n}_rotation_320_x1_clair',
      nature: u,
      moment: _Moment.rotation,
      texte: 1,
      theme: ThemeMode.light,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
    (
      nom: '${n}_lueur_320_x1_clair',
      nature: u,
      moment: _Moment.lueur,
      texte: 1,
      theme: ThemeMode.light,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
    (
      nom: '${n}_lueur_320_x1_sombre',
      nature: u,
      moment: _Moment.lueur,
      texte: 1,
      theme: ThemeMode.dark,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
    (
      nom: '${n}_feuille_320_x1_clair',
      nature: u,
      moment: _Moment.feuille,
      texte: 1,
      theme: ThemeMode.light,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
  ],
  (
    nom: 'urgent_lueur_320_x2_clair',
    nature: NatureHalo.urgent,
    moment: _Moment.lueur,
    texte: 2,
    theme: ThemeMode.light,
    langue: AppLocale.fr,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'urgent_feuille_320_x2_sombre',
    nature: NatureHalo.urgent,
    moment: _Moment.feuille,
    texte: 2,
    theme: ThemeMode.dark,
    langue: AppLocale.fr,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'a-lire_lueur_320_x1_arabe',
    nature: NatureHalo.nouveau,
    moment: _Moment.lueur,
    texte: 1,
    theme: ThemeMode.light,
    langue: AppLocale.ar,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'urgent_feuille_320_x1_arabe',
    nature: NatureHalo.urgent,
    moment: _Moment.feuille,
    texte: 1,
    theme: ThemeMode.light,
    langue: AppLocale.ar,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'urgent_tuile_320_x1_accessibilite',
    nature: NatureHalo.urgent,
    moment: _Moment.lueur,
    texte: 1,
    theme: ThemeMode.light,
    langue: AppLocale.fr,
    mode: InterfaceMode.enfant,
  ),
  (
    nom: 'a-lire_tuile_320_x2_accessibilite_sombre',
    nature: NatureHalo.nouveau,
    moment: _Moment.lueur,
    texte: 2,
    theme: ThemeMode.dark,
    langue: AppLocale.fr,
    mode: InterfaceMode.enfant,
  ),
  (
    nom: 'salle_lueur_320_x1_arabe',
    nature: NatureHalo.salle,
    moment: _Moment.lueur,
    texte: 1,
    theme: ThemeMode.light,
    langue: AppLocale.ar,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'salle_feuille_320_x2_sombre',
    nature: NatureHalo.salle,
    moment: _Moment.feuille,
    texte: 2,
    theme: ThemeMode.dark,
    langue: AppLocale.fr,
    mode: InterfaceMode.standard,
  ),
  (
    nom: 'salle_tuile_320_x1_accessibilite',
    nature: NatureHalo.salle,
    moment: _Moment.lueur,
    texte: 1,
    theme: ThemeMode.light,
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
        final EtatHaloCompte halo = switch (c.nature) {
          NatureHalo.urgent => EtatHaloCompte.urgent(
            titre: 'Remplacement : une réponse est attendue',
            detail: 'Classe de tajwid, ce soir à 18 h',
            chemin: Routes.tuteurNotifications,
          ),
          NatureHalo.salle => EtatHaloCompte.salle(
            action: t.classe.seance.rejoindreAvec(prenom: 'Yasmine'),
            chemin: Routes.tuteurAccueil,
            agir: (BuildContext _) {},
          ),
          NatureHalo.nouveau => EtatHaloCompte.nouveau(
            nombre: 2,
            chemin: Routes.tuteurNotifications,
          ),
        };
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
            // Au milieu du premier tour (au plus fort de la premiere
            // respiration pour la salle), apres le retournement.
            await tester.pump();
            await tester.pump(
              c.nature == NatureHalo.salle
                  ? AppMouvement.respirationHalo ~/ 2
                  : const Duration(milliseconds: 1100),
            );
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
