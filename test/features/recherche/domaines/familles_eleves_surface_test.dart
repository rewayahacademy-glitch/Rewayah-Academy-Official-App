// RECH-D2, surface : la route /recherche du tuteur sur le foyer de
// demonstration (ports reels de la demo : AccesFoyerDemo, ClassesFoyerDemo,
// ResolutionRaDemo). Un RA exact retrouve l'eleve ; un debut de RA ou un RA
// etranger ne rend rien et ne dit rien (spec RECH-03 §3, §7.2 ; REC-02).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/moteurs_familles_eleves.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/port_resolution_ra.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/resolution_ra_demo.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;

import '../../../router/support_routeur.dart';
import '../../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection? direction,
}) async {
  await monterRouteur(
    tester,
    Routes.recherche,
    source: FausseSourceSession(sessionActive(AppRole.guardian)),
    taille: taille,
    echelle: echelle,
    direction: direction,
    surcharges: <Override>[
      portAccesFoyerProvider.overrideWithValue(const AccesFoyerDemo()),
      portResolutionRaProvider.overrideWithValue(
        const ResolutionRaDemo(<String, ElevePourRa>{
          'RA-AB0012': ElevePourRa(
            eleveId: DonneesDemo.aichaId,
            prenom: 'Aïcha',
            classe: 'Coran, niveau 1',
          ),
          'RA-CD0034': ElevePourRa(
            eleveId: DonneesDemo.yusufId,
            prenom: 'Yusuf',
            classe: 'Arabe, niveau 2',
          ),
        }),
      ),
      // Seul le domaine des personnes : la surface lit les ports de la demo.
      moteursRechercheProvider.overrideWith(moteursFamillesEleves),
    ],
  );
}

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('un prenom du foyer : le profil, avec sa classe', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _chercher(tester, 'aicha');
    expect(find.text('Aïcha'), findsWidgets);
    expect(find.textContaining('Profil de votre foyer'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un RA exact retrouve l\'eleve du foyer', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _chercher(tester, 'RA-CD0034');
    expect(find.text('Yusuf'), findsWidgets);
    expect(find.textContaining('Trouvé par son identifiant'), findsWidgets);
    expect(find.textContaining('Arabe, niveau 2'), findsWidgets);
  });

  testWidgets('un debut de RA et un RA etranger : meme vide, sans indice', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _chercher(tester, 'RA-CD');
    final bool videDebut = find
        .text('Aucun résultat pour cette recherche.')
        .evaluate()
        .isNotEmpty;
    await _chercher(tester, 'RA-ZZ9999');
    final bool videEtranger = find
        .text('Aucun résultat pour cette recherche.')
        .evaluate()
        .isNotEmpty;
    expect(videDebut, isTrue);
    expect(videEtranger, isTrue);
    expect(find.text('Yusuf'), findsNothing);
    expect(find.textContaining('RA-ZZ9999 n'), findsNothing);
  });

  testWidgets('320 px, texte x2 : sans debordement', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(320, 640), echelle: 2);
    await _chercher(tester, 'yusuf');
    expect(find.text('Yusuf'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));

    testWidgets('RTL : sans debordement', (WidgetTester tester) async {
      await _monter(tester, direction: TextDirection.rtl);
      await _chercher(tester, 'RA-AB0012');
      expect(tester.takeException(), isNull);
      expect(find.byType(SectionHeader), findsWidgets);
      expect(find.byType(SettingRow), findsWidgets);
    });
  });
}
