// PRAXIS-IMAGE : l'image du directeur, en code, comme avatar de Praxis.
// Rendue a 24, 32 et 48 points ; reservee au code serveur `praxis` ; captures
// agrandies en clair et en sombre (sautees sans CAPTURE_DIR).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_praxis.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/features/com_messages/avatar_participant.dart';

import '../../capture/outil_capture.dart';

const Participant _praxis = Participant(
  id: 'praxis',
  nomAffiche: 'Praxis',
  officiel: true,
  compteOfficiel: 'praxis',
);
const Participant _autreOfficiel = Participant(
  id: 'staff',
  nomAffiche: 'Staff',
  officiel: true,
  compteOfficiel: 'staff',
);
const Participant _officielSansCode = Participant(
  id: 'ancien',
  nomAffiche: 'Praxis',
  officiel: true,
);
const Participant _personne = Participant(id: 'p', nomAffiche: 'Mariam');

Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  ThemeMode mode = ThemeMode.light,
  Size taille = const Size(400, 300),
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(body: Center(child: enfant)),
      themeMode: mode,
    ),
  );
  await tester.pump();
}

void main() {
  test('le PNG est reduit et valide', () {
    expect(octetsImagePraxis.sublist(0, 8), <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ], reason: 'signature PNG');
    expect(octetsImagePraxis.length, lessThan(40 * 1024));
  });

  for (final double d in <double>[24, 32, 48]) {
    testWidgets('taille $d : image ronde de $d points', (tester) async {
      await _monter(tester, ImagePraxis(diametre: d));
      expect(tester.getSize(find.byType(ImagePraxis)), Size(d, d));
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.gaplessPlayback, isTrue);
      expect(image.filterQuality, FilterQuality.medium);
      expect(image.semanticLabel, '\u2066#Ra_Praxis\u2069');
    });
  }

  testWidgets('seul le code praxis recoit l\'image', (tester) async {
    Future<int> compte(Participant p) async {
      await _monter(
        tester,
        AvatarParticipant(participant: p, repli: p.nomAffiche, diametre: 40),
      );
      return find.byType(ImagePraxis).evaluate().length;
    }

    expect(await compte(_praxis), 1);
    expect(
      await compte(_autreOfficiel),
      0,
      reason: 'un autre compte officiel ne reçoit PAS l\'image de Praxis',
    );
    expect(
      await compte(_officielSansCode),
      0,
      reason: 'un serveur sans code : jamais devine d\'après le nom',
    );
    expect(await compte(_personne), 0);
  });

  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('praxis-avatar-${mode.name}', (tester) async {
        fixerVueCapture(tester, const Size(520, 260), 2);
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 16,
                  children: <Widget>[
                    ImagePraxis(diametre: 24),
                    ImagePraxis(diametre: 32),
                    ImagePraxis(diametre: 48),
                    ImagePraxis(diametre: 160),
                  ],
                ),
              ),
            ),
            themeMode: mode,
          ),
        );
        await tester.pump();
        final BuildContext ctx = tester.element(find.byType(Scaffold));
        await tester.runAsync(
          () => precacheImage(MemoryImage(octetsImagePraxis), ctx),
        );
        await tester.pump();
        await capturer(tester, 'PRAXIS-IMAGE/praxis-avatar-${mode.name}');
      });
    }
  }, skip: sautSansCapture);
}
