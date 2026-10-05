// Lot I (COM-RC5), D-FUS-3 choix a (decision du directeur du 05/10, revue
// COM-R, R-03) : sur une page des Communications hors ligne, un seul
// bandeau, celui des Communications. Le bandeau generique de `PageShell`
// (`reseau.horsLigne`, « l'envoi attendra ») n'y est plus pose ; les autres
// ecrans le gardent.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../com_annonces/admin_banc.dart' as annonces;
import '../com_communaute/banc_communaute.dart' as communaute;
import '../com_studio/support_studio.dart' as studio;
import '../historique/support_historique.dart' as historique;
import 'support_messages.dart' as messages;

void _unSeulBandeau() {
  expect(find.byType(OfflineBanner), findsOneWidget);
  expect(find.text(t.reseau.horsLigne), findsNothing);
  expect(find.text(t.com.socle.composants.etats.horsLigne), findsOneWidget);
}

void main() {
  group('D-FUS-3 : un seul bandeau hors ligne sur les Communications', () {
    testWidgets('Messages, fil ouvert', (WidgetTester tester) async {
      await messages.monterMessages(
        tester,
        port: messages.portDemo(RoleDemoCommunications.enseignant),
        depart: messages.cheminFilTest('fil-adam'),
        horsLigne: true,
      );
      _unSeulBandeau();
    });

    testWidgets('Studio', (WidgetTester tester) async {
      await studio.monterStudio(
        tester,
        port: studio.portDemo(),
        horsLigne: true,
      );
      _unSeulBandeau();
    });

    testWidgets('Communaute', (WidgetTester tester) async {
      await communaute.monterCommunaute(tester, horsLigne: true);
      _unSeulBandeau();
    });

    testWidgets('Administration des communications (annonces)', (
      WidgetTester tester,
    ) async {
      await annonces.monterAdministration(tester, horsLigne: true);
      _unSeulBandeau();
    });

    testWidgets('Publier une annonce de Classe', (WidgetTester tester) async {
      await annonces.monterPublierClasse(tester, horsLigne: true);
      _unSeulBandeau();
    });

    testWidgets('hors des Communications, le bandeau generique reste', (
      WidgetTester tester,
    ) async {
      await historique.monterHistorique(tester, horsLigne: true);
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      final PageShell page = tester.widget<PageShell>(
        find.byType(PageShell).first,
      );
      expect(page.bandeauHorsLigne, isA<OfflineBanner>());
    });
  });
}
