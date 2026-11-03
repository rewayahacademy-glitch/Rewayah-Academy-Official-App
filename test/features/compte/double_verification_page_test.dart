// MFA-DIRECTION : Compte > Securite de la direction. A activer : le flux du
// controleur (QR, cle, premier code) avec les textes de la direction, sans
// « Se deconnecter » ; code accepte : « activee ». Deja activee : la carte le
// dit. 390 et 1440, un seul bouton plein.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/compte/double_verification_page.dart';
import 'package:rewayah_academy/features/mfa_controleur/flux_mfa.dart';
import 'package:rewayah_academy/features/mfa_controleur/port_mfa.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

class _Port implements PortMfa {
  _Port(this.situationRendue);
  SituationMfa situationRendue;
  final List<String> codes = <String>[];

  @override
  Future<SituationMfa> situation() async => situationRendue;

  @override
  Future<EnrolementTotp> enroler() async => const EnrolementTotp(
    facteurId: 'f-nouveau',
    uri: 'otpauth://totp/Rewayah:d@test?secret=JBSWY3DPEHPK3PXP&issuer=Rewayah',
    secret: 'JBSWY3DPEHPK3PXP',
  );

  @override
  Future<void> verifier({
    required String facteurId,
    required String code,
  }) async {
    codes.add(code);
  }
}

Future<_Port> _monter(
  WidgetTester tester,
  SituationMfa situation, {
  double largeur = 390,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largeur, 1600);
  addTearDown(tester.view.reset);
  final _Port port = _Port(situation);
  await tester.pumpWidget(
    hote(
      const DoubleVerificationPage(),
      surcharges: <Override>[portMfaProvider.overrideWithValue(port)],
    ),
  );
  await tester.pumpAndSettle();
  return port;
}

void main() {
  for (final double largeur in <double>[390, 1440]) {
    testWidgets('$largeur : activer, premier code, puis activee', (
      tester,
    ) async {
      final _Port port = await _monter(
        tester,
        const MfaAEnroler(),
        largeur: largeur,
      );
      expect(find.text('Activez la double vérification'), findsOneWidget);
      expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      await tester.enterText(find.byKey(FluxMfa.champCodeKey), '123456');
      await tester.ensureVisible(find.byKey(FluxMfa.boutonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FluxMfa.boutonKey));
      await tester.pumpAndSettle();
      expect(port.codes, <String>['123456']);
      expect(find.byKey(DoubleVerificationPage.activeeKey), findsOneWidget);
    });
  }

  testWidgets('deja activee : la carte le dit, aucun enrolement', (
    tester,
  ) async {
    await _monter(tester, const MfaAVerifier('f1'));
    expect(find.byKey(DoubleVerificationPage.activeeKey), findsOneWidget);
    expect(find.byKey(FluxMfa.champCodeKey), findsNothing);
  });
}
