// LANGUES (directeur, 14/11/2026) : la traduction de courtoisie du contrat
// d'enseignant servi par le serveur. Ce que le test prouve : en arabe et en
// anglais, le texte traduit se lit sous le francais, avec son titre et la
// mention « la version francaise fait foi » ; en francais, rien ; sans ligne
// serveur, sans port de traduction ou avec un texte altere, rien non plus ;
// et la signature reste celle du francais (meme version, meme empreinte).
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_signature_contrat.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/consentements/texte_observation.dart';
import 'package:rewayah_academy/features/recrutement/signature_contrat_page.dart';

import '../../support/demo/recrutement_demo.dart';
import '../../support/harnais.dart';
import '../../support/monter_recrutement.dart';

String _sha(String texte) =>
    crypto.sha256.convert(utf8.encode(texte)).toString();

/// Un port de signature qui sait aussi lire des traductions.
class _PortAvecTraduction extends SignatureContratDemo
    implements PortTraductionContrat {
  _PortAvecTraduction(this.traductions, {this.alterer = false});

  /// Les traductions du serveur, par langue.
  final Map<String, String> traductions;

  /// Vrai : l'empreinte annoncee n'est pas celle du texte.
  final bool alterer;

  final List<String> signatures = <String>[];

  @override
  Future<TraductionContrat?> traduction(
    SorteContrat kind,
    String version,
    String locale,
  ) async {
    final String? texte = traductions[locale];
    if (texte == null) return null;
    return TraductionContrat(
      locale: locale,
      version: version,
      texte: texte,
      sha256: alterer ? _sha('autre texte') : _sha(texte),
    );
  }

  @override
  Future<Signature> signerContrat(
    SorteContrat kind,
    String version,
    String nomSaisi,
  ) {
    signatures.add(version);
    return super.signerContrat(kind, version, nomSaisi);
  }
}

const String _texteEn = 'Courtesy copy of the teacher contract.\n\nArticle 1.';
const String _texteAr = 'نسخة للاطلاع من عقد المعلم.\n\nالمادة 1.';

Future<void> _monter(WidgetTester tester, PortSignatureContrat? port) =>
    monterRecrutement(
      tester,
      chemin: Routes.attenteContrat,
      autres: <String>[Routes.attente],
      ecran: (_) => const SignatureContratPage(),
      surcharges: <Override>[
        portSignatureContratProvider.overrideWithValue(port),
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
      ],
    );

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final Finder traduction = find.byKey(
    const ValueKey<String>('signature-traduction-texte'),
  );

  testWidgets('en anglais : la traduction, son titre et la mention', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await _monter(
      tester,
      _PortAvecTraduction(<String, String>{'en': _texteEn, 'ar': _texteAr}),
    );
    await laisser(tester);
    expect(traduction, findsOneWidget);
    expect(find.textContaining('Courtesy copy'), findsOneWidget);
    expect(find.text('Courtesy translation'), findsOneWidget);
    expect(find.text(t.juridique.traduction), findsOneWidget);
    // Le texte francais du serveur reste affiche, au-dessus.
    expect(
      find.byKey(const ValueKey<String>('signature-texte')),
      findsOneWidget,
    );
  });

  testWidgets('en arabe : la traduction arabe', (WidgetTester tester) async {
    LocaleSettings.setLocaleSync(AppLocale.ar);
    await _monter(
      tester,
      _PortAvecTraduction(<String, String>{'en': _texteEn, 'ar': _texteAr}),
    );
    await laisser(tester);
    expect(traduction, findsOneWidget);
    expect(find.textContaining('نسخة للاطلاع'), findsOneWidget);
    expect(find.textContaining('Courtesy copy'), findsNothing);
  });

  testWidgets('en francais : aucune traduction', (WidgetTester tester) async {
    await _monter(
      tester,
      _PortAvecTraduction(<String, String>{'en': _texteEn, 'ar': _texteAr}),
    );
    await laisser(tester);
    expect(traduction, findsNothing);
    expect(find.text(t.juridique.traduction), findsNothing);
  });

  testWidgets('sans ligne serveur pour cette langue : rien', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await _monter(tester, _PortAvecTraduction(<String, String>{}));
    await laisser(tester);
    expect(traduction, findsNothing);
    expect(
      find.byKey(const ValueKey<String>('signature-texte')),
      findsOneWidget,
    );
  });

  testWidgets('port sans lecture de traduction : rien', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await _monter(tester, SignatureContratDemo());
    await laisser(tester);
    expect(traduction, findsNothing);
  });

  testWidgets('traduction alteree (empreinte fausse) : rien', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await _monter(
      tester,
      _PortAvecTraduction(<String, String>{'en': _texteEn}, alterer: true),
    );
    await laisser(tester);
    expect(traduction, findsNothing);
  });

  testWidgets('la signature reste celle du francais', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final _PortAvecTraduction port = _PortAvecTraduction(<String, String>{
      'en': _texteEn,
    });
    await _monter(tester, port);
    await laisser(tester);
    await tester.tap(find.byType(CaseAccordTexte));
    await laisser(tester);
    await tester.tap(find.byKey(const ValueKey<String>('signature-signer')));
    await laisser(tester);
    final ContratCourant fr = await port.contratCourant(
      SorteContrat.contratEnseignant,
    );
    expect(port.signatures, <String>[fr.version]);
  });
}
