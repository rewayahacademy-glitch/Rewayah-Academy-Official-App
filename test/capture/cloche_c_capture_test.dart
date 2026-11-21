// CLOCHE-C (directeur, 21/11/2026) : captures R3 de la cloche, style C.
// Donnees de demonstration, aucun nom de personne. Jamais sans `CAPTURE_DIR`.
// Coquille reelle du tuteur (vrai routeur), vraies polices.
//
//   CAPTURE_DIR=docs/current/captures/E2E/CLOCHE-C \
//     flutter test test/capture/cloche_c_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/notifications/cloche/annonces_cloche.dart';
import 'package:rewayah_academy/features/notifications/cloche/contenu_cloche.dart';
import 'package:rewayah_academy/features/notifications/cloche/ligne_cloche.dart';

import '../features/notifications/support_cloche.dart';
import 'outil_capture.dart';

Future<void> _langue(WidgetTester tester, AppLocale langue) async {
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

typedef _Cas = ({
  String nom,
  Size taille,
  double densite,
  AppLocale langue,
  bool sombre,
  double echelle,
});

_Cas _cas(
  String nom,
  double l,
  double h, {
  AppLocale langue = AppLocale.fr,
  bool sombre = false,
  double echelle = 1,
}) => (
  nom: nom,
  taille: Size(l, h),
  densite: l < 840 ? 2 : 1,
  langue: langue,
  sombre: sombre,
  echelle: echelle,
);

Future<void> _monter(
  WidgetTester tester,
  _Cas c, {
  PortNotifications? port,
  SourceAnnoncesCloche? source,
  bool horsLigne = false,
}) async {
  await _langue(tester, c.langue);
  final bool ar = c.langue == AppLocale.ar;
  await monterCloche(
    tester,
    taille: c.taille,
    densite: c.densite,
    theme: c.sombre ? ThemeMode.dark : ThemeMode.light,
    echelle: c.echelle,
    horsLigne: horsLigne,
    port: port ?? FauxNotifsCloche(notifsDemo(arabe: ar)),
    source: source ?? FausseSourceAnnonces(annoncesDemo(arabe: ar)),
  );
}

/// Le titre de l'annonce traduite (toucher le centre de la ligne tomberait
/// sur son bouton « Ouvrir le lien »).
Finder _titreA1() => find
    .descendant(
      of: find.byKey(ContenuCloche.cleLigne('a-a1')),
      matching: find.byType(RichText),
    )
    .first;

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('CLOCHE-C captures', skip: sautSansCapture, () {
    setUp(masquerRubanDebug);

    final List<_Cas> ouverts = <_Cas>[
      _cas('01-ordinateur-1440-ouvert-fr', 1440, 900),
      _cas('02-ordinateur-1280-ouvert-fr', 1280, 800),
      _cas('03-ordinateur-1440-ouvert-sombre', 1440, 900, sombre: true),
      _cas('04-ordinateur-1440-ouvert-ar', 1440, 900, langue: AppLocale.ar),
      _cas('05-telephone-390-feuille-fr', 390, 844),
      _cas(
        '06-telephone-390-feuille-ar-sombre',
        390,
        844,
        langue: AppLocale.ar,
        sombre: true,
      ),
      _cas('07-telephone-320-feuille-texte-x2', 320, 700, echelle: 2),
      _cas(
        '08-ordinateur-1440-ouvert-ar-sombre',
        1440,
        900,
        langue: AppLocale.ar,
        sombre: true,
      ),
    ];

    for (final _Cas c in <_Cas>[
      _cas('1440', 1440, 900),
      _cas('390', 390, 844),
    ]) {
      testWidgets('00 ferme ${c.nom}', (WidgetTester tester) async {
        await _monter(tester, c);
        await capturer(tester, '00-ferme-${c.nom}');
      });
    }

    for (final _Cas c in ouverts) {
      testWidgets(c.nom, (WidgetTester tester) async {
        await _monter(tester, c);
        await ouvrirLaCloche(tester);
        await capturer(tester, c.nom);
      });
    }

    for (final _Cas c in <_Cas>[
      _cas('10-detail-1440', 1440, 900),
      _cas('11-detail-390', 390, 844),
      _cas('11-detail-390-ar', 390, 844, langue: AppLocale.ar),
    ]) {
      testWidgets('${c.nom} : detail d une annonce traduite, puis l original', (
        WidgetTester tester,
      ) async {
        await _monter(tester, c);
        await ouvrirLaCloche(tester);
        await tester.tap(_titreA1());
        await pas(tester);
        await capturer(tester, c.nom);
        if (find.byKey(ContenuCloche.cleOriginal).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(ContenuCloche.cleOriginal));
          await pas(tester);
          await capturer(tester, '${c.nom}-original');
        }
      });
    }

    for (final _Cas c in <_Cas>[
      _cas('12-fermeture-annuler-1440', 1440, 900),
      _cas('13-fermeture-annuler-390', 390, 844),
    ]) {
      testWidgets('${c.nom} : « Annuler » pendant 5 s', (
        WidgetTester tester,
      ) async {
        await _monter(tester, c);
        await ouvrirLaCloche(tester);
        await tester.tap(
          find.byKey(
            LigneCloche.cleFermer(ContenuCloche.cleLigne('a-a1').value),
          ),
        );
        await pas(tester, fois: 4);
        await capturer(tester, c.nom);
        await pas(tester, fois: 60);
        await capturer(tester, '${c.nom}-apres');
      });
    }

    for (final _Cas c in <_Cas>[
      _cas('1440', 1440, 900),
      _cas('390', 390, 844),
    ]) {
      testWidgets('14 chargement ${c.nom}', (WidgetTester tester) async {
        await _monter(
          tester,
          c,
          port: FauxNotifsCloche(
            const <NotificationTuteur>[],
            mode: ModeNotifs.attente,
          ),
          source: FausseSourceAnnonces(const <AnnonceCloche>[]),
        );
        await ouvrirLaCloche(tester);
        await capturer(tester, '14-chargement-${c.nom}');
      });
      testWidgets('15 erreur ${c.nom}', (WidgetTester tester) async {
        await _monter(
          tester,
          c,
          port: FauxNotifsCloche(notifsDemo(), mode: ModeNotifs.echec),
          source: FausseSourceAnnonces(const <AnnonceCloche>[], echec: true),
        );
        await ouvrirLaCloche(tester);
        await capturer(tester, '15-erreur-${c.nom}');
      });
      testWidgets('16 vide ${c.nom}', (WidgetTester tester) async {
        await _monter(
          tester,
          c,
          port: FauxNotifsCloche(const <NotificationTuteur>[]),
          source: FausseSourceAnnonces(const <AnnonceCloche>[]),
        );
        await ouvrirLaCloche(tester);
        await capturer(tester, '16-vide-${c.nom}');
      });
      testWidgets('17 hors ligne ${c.nom}', (WidgetTester tester) async {
        await _monter(tester, c, horsLigne: true);
        await ouvrirLaCloche(tester);
        await capturer(tester, '17-hors-ligne-${c.nom}');
      });
      testWidgets('18 tout lu ${c.nom}', (WidgetTester tester) async {
        await _monter(tester, c);
        await ouvrirLaCloche(tester);
        await tester.tap(find.byKey(ContenuCloche.cleToutLire));
        await pas(tester);
        await capturer(tester, '18-tout-lu-${c.nom}');
      });
    }

    for (final _Cas c in <_Cas>[
      _cas('21-page-complete-1440-fr', 1440, 900),
      _cas('22-page-complete-1280-fr', 1280, 800),
      _cas('23-page-complete-390-fr', 390, 844),
      _cas('24-page-complete-1440-ar', 1440, 900, langue: AppLocale.ar),
      _cas(
        '25-page-complete-390-ar-sombre',
        390,
        844,
        langue: AppLocale.ar,
        sombre: true,
      ),
      _cas('26-page-complete-1440-sombre', 1440, 900, sombre: true),
      _cas('27-page-complete-320-texte-x2', 320, 700, echelle: 2),
    ]) {
      testWidgets(c.nom, (WidgetTester tester) async {
        await _langue(tester, c.langue);
        final bool ar = c.langue == AppLocale.ar;
        await monterCloche(
          tester,
          taille: c.taille,
          densite: c.densite,
          theme: c.sombre ? ThemeMode.dark : ThemeMode.light,
          echelle: c.echelle,
          depart: Routes.tuteurNotifications,
          port: FauxNotifsCloche(notifsDemo(arabe: ar)),
          source: FausseSourceAnnonces(annoncesDemo(arabe: ar)),
        );
        await capturer(tester, c.nom);
      });
    }

    testWidgets('28 page complete : detail sur place, 1440', (
      WidgetTester tester,
    ) async {
      await _langue(tester, AppLocale.fr);
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        depart: Routes.tuteurNotifications,
        port: FauxNotifsCloche(notifsDemo()),
        source: FausseSourceAnnonces(annoncesDemo()),
      );
      await tester.tap(_titreA1());
      await pas(tester);
      await capturer(tester, '28-page-complete-detail-1440');
    });

    testWidgets('19 page suivante en cours', (WidgetTester tester) async {
      final List<AnnonceCloche> beaucoup = <AnnonceCloche>[
        for (int i = 0; i < 25; i++)
          AnnonceCloche(
            id: 'x$i',
            titre: 'Annonce de démonstration ${i + 1}',
            texte: 'Une ligne de texte de démonstration.',
            publieeLe: instantCloche.subtract(Duration(hours: 2 * i + 1)),
            vue: i > 2,
          ),
      ];
      await _monter(
        tester,
        _cas('19', 1440, 900),
        port: FauxNotifsCloche(const <NotificationTuteur>[]),
        source: FausseSourceAnnonces(beaucoup, suiteBloquee: true),
      );
      await ouvrirLaCloche(tester);
      await tester.ensureVisible(find.byKey(ContenuCloche.cleVoirPlus));
      await pas(tester, fois: 2);
      await capturer(tester, '19-pagination-avant-1440');
      await tester.tap(find.byKey(ContenuCloche.cleVoirPlus));
      await pas(tester, fois: 3);
      await capturer(tester, '20-pagination-en-cours-1440');
    });
  });
}
