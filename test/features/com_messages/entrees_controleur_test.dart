// COM-MSG-2 (K-07) : l'entree « mission controleur ». Le controleur ecrit a
// l'Administration depuis son ecran Echanges, INCHANGE (C13, 02_DECOUPAGE
// COM-MSG-2) : il l'atteint par la destination Echanges de sa vraie
// coquille, et aucune route Messages ne lui est ajoutee. L'Administration lit
// ces fils dans son onglet Messages (`entrees_admin_test.dart`).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

void main() {
  testWidgets('390 : la destination Echanges de la coquille ouvre l ecran '
      'Echanges, sans Messages metier', (WidgetTester tester) async {
    final GoRouter routeur = await monterRouteur(
      tester,
      Routes.controleurHistorique,
      source: FausseSourceSession(sessionActive(AppRole.controller)),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(NavShell.barreBasseKey),
        matching: find.text(t.nav.controleur.echanges),
      ),
    );
    await stabiliser(tester);
    expect(
      routeur.routerDelegate.currentConfiguration.uri.path,
      Routes.controleurEchanges,
    );
    expect(find.byType(EchangesControleurPage), findsOneWidget);
    expect(find.byType(MessagesPage), findsNothing);
    expect(find.byType(EntreeMessagesContexte), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('aucune route Messages sous /controleur ; la page du controleur ne '
      'mene a aucune liste de Messages', () {
    final ProviderContainer conteneur = ProviderContainer(
      overrides: surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.controller)),
      ),
    );
    addTearDown(conteneur.dispose);
    final List<String> declares = cheminsDeclares(
      conteneur.read(routeurProvider),
    );
    expect(
      declares.where(
        (String c) => c.startsWith('${Routes.controleur}/messages'),
      ),
      isEmpty,
    );
    expect(cheminMessagesDepuis(Routes.controleurEchanges), isNull);
  });
}
