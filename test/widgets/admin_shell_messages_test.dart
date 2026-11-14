// MESSAGERIE-TEMPS-REEL (14/11/2026) : quand un message attend la direction,
// l'acces aux Messages se pose dans l'en-tete de la coquille, avec son nombre,
// au telephone comme sur ordinateur ; le toucher mene aux Messages. Sans
// message, rien n'est pose.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

const Key _cle = ValueKey<String>('admin-messages-non-lus');

Widget _shell({int nonLus = 0, void Function(String)? onAller}) => AdminShell(
  domaines: domainesAdmin(voitDirection: true),
  domaineActif: AdminDomaine.accueil,
  onAller: onAller ?? (String _) {},
  onCompte: () {},
  messages: nonLus == 0
      ? null
      : ClocheNotifications(
          key: _cle,
          icone: AppIcons.discussion,
          nonLues: nonLus,
          onPress: () => onAller?.call(Routes.adminCommunicationsMessages),
          libelleSemantique: t.com.messages.direct.iconeNonLus(nombre: nonLus),
        ),
  child: const PageShell(titre: 'Accueil', child: SizedBox()),
);

void main() {
  for (final double largeur in <double>[320, 599, 1440]) {
    testWidgets('$largeur : l\'acces aux Messages et son nombre', (
      WidgetTester tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = Size(largeur, 900);
      tester.view.devicePixelRatio = 1;
      String? alle;
      await tester.pumpWidget(
        hote(_shell(nonLus: 3, onAller: (String c) => alle = c)),
      );
      await tester.pump();
      expect(find.byKey(_cle), findsOneWidget);
      await tester.tap(find.byKey(_cle));
      await tester.pump();
      expect(alle, Routes.adminCommunicationsMessages);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sans message, rien n\'est pose', (WidgetTester tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(hote(_shell()));
    await tester.pump();
    expect(find.byKey(_cle), findsNothing);
  });
}
