// HORLOGE-ET-LIEU, partie B : a l'inscription dans une classe, la famille lit ce
// que devient l'heure du cours chez elle au prochain changement d'heure
// (« Chez vous : 19:00, puis 20:00 a partir du dimanche 28 mars 2027. »). Le
// calcul est fait par la base (`public.apercu_offre_horaire`) ; rien quand
// l'heure ne change jamais, ou quand le serveur ne repond pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_creneau.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_offre.dart';

import '../../support/harnais.dart';

class _Port implements PortApercuOffre {
  _Port(this.reponse);

  final Map<String, Object?>? reponse;
  final List<DemandeApercuOffre> demandes = <DemandeApercuOffre>[];

  @override
  Future<ApercuCreneau?> lire({
    required String offreId,
    required String fuseau,
  }) async {
    demandes.add((offreId: offreId, fuseau: fuseau));
    return ApercuCreneau.lire(reponse);
  }
}

const Map<String, Object?> _change = <String, Object?>{
  'jour_maintenant': 3,
  'maintenant': '19:00',
  'meme': false,
  'date_changement': '2027-03-28',
  'jour_apres': 3,
  'heure_apres': '20:00',
};

Future<void> _monter(
  WidgetTester tester,
  _Port port, {
  double echelle = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 800),
          textScaler: TextScaler.linear(echelle),
        ),
        child: const Scaffold(
          body: LigneApercuOffre(offreId: 'o1', fuseau: 'Europe/Paris'),
        ),
      ),
      surcharges: <Override>[portApercuOffreProvider.overrideWithValue(port)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  test('la phrase : l heure chez soi, puis l heure apres le changement', () {
    final String? phrase = phraseApercuOffre(ApercuCreneau.lire(_change)!);
    expect(phrase, startsWith('Chez vous'));
    expect(phrase, contains('19:00'));
    expect(phrase, contains('20:00'));
    expect(phrase, contains('28 mars 2027'));
  });

  test('l heure ne change jamais : aucune phrase', () {
    expect(
      phraseApercuOffre(
        ApercuCreneau.lire(<String, Object?>{
          'jour_maintenant': 3,
          'maintenant': '21:00',
          'meme': true,
        })!,
      ),
      isNull,
    );
  });

  for (final double echelle in <double>[1, 2]) {
    testWidgets('320 px, texte x$echelle : la ligne sous l offre', (
      tester,
    ) async {
      final _Port port = _Port(_change);
      await _monter(tester, port, echelle: echelle);
      expect(find.byKey(LigneApercuOffre.cle), findsOneWidget);
      expect(find.textContaining('20:00'), findsOneWidget);
      expect(port.demandes.single, (offreId: 'o1', fuseau: 'Europe/Paris'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sans reponse du serveur : aucune phrase, jamais une heure '
      'fabriquee', (tester) async {
    await _monter(tester, _Port(null));
    expect(find.byKey(LigneApercuOffre.cle), findsNothing);
  });

  testWidgets('en arabe : la meme ligne', (tester) async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await _monter(tester, _Port(_change));
    expect(find.byKey(LigneApercuOffre.cle), findsOneWidget);
    expect(find.textContaining('20:00'), findsOneWidget);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
}
