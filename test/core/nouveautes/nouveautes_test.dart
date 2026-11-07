// NOUVEAUTES (07/11/2026) : le badge « Nouveau », son marquage a la premiere
// ouverture, et l'onglet « Historique » du tuteur (barre basse et colonne).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/nouveautes/nouveautes.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../../support/hote_theme.dart';

class _FauxPort implements PortNouveautes {
  _FauxPort(this.cles);

  final Set<String> cles;
  final List<String> marquees = <String>[];

  @override
  Future<Set<String>> mes() async => <String>{...cles};

  @override
  Future<void> marquerVue(String cle) async {
    marquees.add(cle);
    cles.remove(cle);
  }
}

Future<void> _monterOnglets(
  WidgetTester tester,
  _FauxPort port, {
  required Size vue,
  List<String>? allees,
}) async {
  fixerVue(tester, vue);
  final List<Destination> destinations = destinationsPour(
    role: AppRole.guardian,
    mode: InterfaceMode.standard,
  );
  await tester.pumpWidget(
    hoteTheme(
      NavShell(
        destinations: destinations,
        indexActif: 0,
        libellesDansLeRail: true,
        onAller: (String chemin) => allees?.add(chemin),
        child: const SizedBox.shrink(),
      ),
      defilant: false,
      surcharges: <Override>[portNouveautesProvider.overrideWithValue(port)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('le badge se montre seulement si le serveur le signale, lu '
      '« nouveau »', (WidgetTester tester) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      hoteTheme(
        const Column(
          children: <Widget>[
            BadgeNouveau(cle: CleNouveaute.couleurProfil),
            BadgeNouveau(cle: CleNouveaute.exportWise),
          ],
        ),
        surcharges: <Override>[
          portNouveautesProvider.overrideWithValue(
            _FauxPort(<String>{CleNouveaute.couleurProfil}),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.nouveautes.badge), findsOneWidget);
    expect(find.bySemanticsLabel(t.nouveautes.lu), findsOneWidget);
    semantique.dispose();
  });

  testWidgets('sans lecture du serveur, aucun badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(const BadgeNouveau(cle: CleNouveaute.couleurProfil)),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.nouveautes.badge), findsNothing);
  });

  test('vue : le badge part et le serveur est appele une seule fois', () async {
    final _FauxPort port = _FauxPort(<String>{
      CleNouveaute.couleurProfil,
      CleNouveaute.moyenPaiement,
    });
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[portNouveautesProvider.overrideWithValue(port)],
    );
    addTearDown(c.dispose);
    await c.read(nouveautesProvider.future);
    await c.read(nouveautesProvider.notifier).vue(CleNouveaute.couleurProfil);
    await c.read(nouveautesProvider.notifier).vue(CleNouveaute.couleurProfil);
    await c.read(nouveautesProvider.notifier).vue(CleNouveaute.exportWise);
    expect(port.marquees, <String>[CleNouveaute.couleurProfil]);
    expect(c.read(nouveautesProvider).value, <String>{
      CleNouveaute.moyenPaiement,
    });
  });

  for (final (String nom, Size vue) in <(String, Size)>[
    ('telephone, barre basse', const Size(390, 844)),
    ('bureau, colonne', vueBureau),
  ]) {
    testWidgets('onglet Historique ($nom) : badge, lu « Historique, nouveau », '
        'parti au premier appui', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      final _FauxPort port = _FauxPort(<String>{CleNouveaute.historiqueClasse});
      final List<String> allees = <String>[];
      await _monterOnglets(tester, port, vue: vue, allees: allees);
      final String lu = '${t.nav.tuteur.historique}, ${t.nouveautes.lu}';
      expect(find.text(t.nouveautes.badge), findsOneWidget);
      expect(find.bySemanticsLabel(lu), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(lu));
      await tester.pumpAndSettle();
      expect(port.marquees, <String>[CleNouveaute.historiqueClasse]);
      expect(allees, isNotEmpty);
      expect(find.text(t.nouveautes.badge), findsNothing);
      expect(find.bySemanticsLabel(t.nav.tuteur.historique), findsWidgets);
      semantique.dispose();
    });
  }

  testWidgets('arabe : le badge dit « جديد »', (WidgetTester tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    await _monterOnglets(
      tester,
      _FauxPort(<String>{CleNouveaute.historiqueClasse}),
      vue: const Size(390, 844),
    );
    expect(find.text('جديد'), findsOneWidget);
  });
}
