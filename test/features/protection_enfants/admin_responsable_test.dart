// PE (18/10/2026) : Configuration > Protection des enfants.
//
// Ce que le test prouve : les deux reglages vides disent « Non renseigne » ;
// la saisie du courriel est verifiee avant l'envoi ; un nom valide part vers la
// bonne cle de `app_config` ; une panne de lecture se dit avec « Reessayer ».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/protection_enfants/responsable_protection.dart';
import 'package:rewayah_academy/features/admin_configuration_protection_enfants/protection_enfants_page.dart';

import '../../support/harnais.dart';

class _Lecture implements PortResponsableProtection {
  _Lecture(this.valeur, {this.panne = false});

  ResponsableProtection valeur;
  bool panne;

  @override
  Future<ResponsableProtection> lire() async {
    if (panne) {
      throw Exception('reseau');
    }
    return valeur;
  }
}

class _Ecriture implements ServiceConfiguration {
  final List<({String cle, Object valeur})> ecrites =
      <({String cle, Object valeur})>[];

  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async => <ValeurConfig>[];

  @override
  Future<void> ecrire(String cle, Object valeur) async =>
      ecrites.add((cle: cle, valeur: valeur));
}

Future<void> _monter(
  WidgetTester tester,
  _Lecture lecture,
  _Ecriture ecriture,
) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const ProtectionEnfantsPage(),
      surcharges: <Override>[
        portResponsableProtectionProvider.overrideWithValue(lecture),
        serviceConfigurationProvider.overrideWithValue(ecriture),
        peutReglerPolitiqueKycProvider.overrideWithValue(false),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('vide par defaut : deux lignes « Non renseigne »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Lecture(ResponsableProtection.aucun), _Ecriture());

    expect(find.byKey(ProtectionEnfantsPage.nomKey), findsOneWidget);
    expect(find.byKey(ProtectionEnfantsPage.courrielKey), findsOneWidget);
    expect(find.text(t.admin.protectionEnfants.nonRenseigne), findsNWidgets(2));
  });

  testWidgets('un nom valide part vers la cle du nom', (
    WidgetTester tester,
  ) async {
    final _Ecriture ecriture = _Ecriture();
    await _monter(tester, _Lecture(ResponsableProtection.aucun), ecriture);

    await tester.tap(find.byKey(ProtectionEnfantsPage.nomKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ProtectionEnfantsPage.champKey),
      'Sayyid Yusuf',
    );
    await tester.tap(find.byKey(ProtectionEnfantsPage.enregistrerKey));
    await tester.pumpAndSettle();

    expect(ecriture.ecrites, hasLength(1));
    expect(ecriture.ecrites.single.cle, ClesProtectionEnfants.nom);
    expect(ecriture.ecrites.single.valeur, 'Sayyid Yusuf');
  });

  testWidgets('un courriel invalide est refuse avant l envoi', (
    WidgetTester tester,
  ) async {
    final _Ecriture ecriture = _Ecriture();
    await _monter(tester, _Lecture(ResponsableProtection.aucun), ecriture);

    await tester.tap(find.byKey(ProtectionEnfantsPage.courrielKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ProtectionEnfantsPage.champKey),
      'pas un courriel',
    );
    await tester.tap(find.byKey(ProtectionEnfantsPage.enregistrerKey));
    await tester.pumpAndSettle();

    expect(ecriture.ecrites, isEmpty);
    expect(
      find.text(t.admin.protectionEnfants.courrielInvalide),
      findsOneWidget,
    );
  });

  testWidgets('un courriel vide retire le responsable', (
    WidgetTester tester,
  ) async {
    final _Ecriture ecriture = _Ecriture();
    await _monter(
      tester,
      _Lecture(const ResponsableProtection(courriel: 'a@b.test')),
      ecriture,
    );

    await tester.tap(find.byKey(ProtectionEnfantsPage.courrielKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ProtectionEnfantsPage.champKey), '');
    await tester.tap(find.byKey(ProtectionEnfantsPage.enregistrerKey));
    await tester.pumpAndSettle();

    expect(ecriture.ecrites.single.cle, ClesProtectionEnfants.courriel);
    expect(ecriture.ecrites.single.valeur, '');
  });

  testWidgets('lecture impossible : la panne se dit', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      _Lecture(ResponsableProtection.aucun, panne: true),
      _Ecriture(),
    );

    expect(find.text(t.admin.protectionEnfants.erreur), findsOneWidget);
    expect(find.text(t.commun.reessayer), findsOneWidget);
    expect(find.byKey(ProtectionEnfantsPage.nomKey), findsNothing);
  });
}
