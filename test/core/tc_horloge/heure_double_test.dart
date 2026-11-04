// FUSEAUX : l'heure courante qui avance, chez soi et chez l'enseignant, a 390
// et a 1440 ; rien quand tout le monde vit a la meme heure ; le mouvement
// reduit ne retire pas l'heure.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/heure_double.dart';
import 'package:rewayah_academy/core/tc_horloge/port_interlocuteurs.dart';

import '../../support/harnais.dart';

class _Port implements PortInterlocuteurs {
  const _Port({this.memeFuseau = false});
  final bool memeFuseau;

  @override
  Future<InterlocuteursClasse?> lire(String groupeId) async =>
      InterlocuteursClasse.lire(<String, Object?>{
        'maintenant': '2026-11-04T07:00:30Z',
        'moi': <String, Object?>{
          'fuseau': 'Europe/Paris',
          'decalage_secondes': 3600,
          'prochain_changement': '2027-03-28T01:00:00Z',
          'decalage_apres': 7200,
          'changement_suivant': '2027-10-31T01:00:00Z',
        },
        'enseignant': <String, Object?>{
          'titre': 'sayyid',
          'prenom': 'Karim',
          'pays': 'CI',
          'remplacant': false,
          'fuseau': memeFuseau ? 'Europe/Paris' : 'Africa/Abidjan',
          'decalage_secondes': memeFuseau ? 3600 : 0,
          'prochain_changement': memeFuseau ? '2027-03-28T01:00:00Z' : null,
          'decalage_apres': memeFuseau ? 7200 : null,
          'changement_suivant': memeFuseau ? '2027-10-31T01:00:00Z' : null,
          'source': 'enseignant',
        },
      });
}

void main() {
  late DateTime appareil;

  Future<void> monter(
    WidgetTester tester, {
    double largeur = 390,
    bool memeFuseau = false,
    bool mouvementReduit = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(largeur, 900);
    addTearDown(tester.view.reset);
    appareil = DateTime.utc(2030, 1, 1, 12);
    await tester.pumpWidget(
      hote(
        MediaQuery(
          data: MediaQueryData(
            size: Size(largeur, 900),
            disableAnimations: mouvementReduit,
          ),
          child: Scaffold(
            body: HeureCouranteDouble(
              groupeId: 'g1',
              horlogeAppareil: () => appareil,
            ),
          ),
        ),
        surcharges: <Override>[
          portInterlocuteursProvider.overrideWithValue(
            _Port(memeFuseau: memeFuseau),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  for (final double largeur in <double>[390, 1440]) {
    testWidgets(
      '$largeur : 08:00 chez vous, 07:00 chez Sayyid Karim, et ca avance',
      (tester) async {
        await monter(tester, largeur: largeur);
        expect(find.text(t.tc.groupe.horloges.enCeMoment), findsOneWidget);
        expect(find.text('Chez Sayyid Karim'), findsOneWidget);
        expect(find.textContaining('08:00'), findsOneWidget);
        expect(find.textContaining('07:00'), findsOneWidget);
        // Une minute passe sur l'appareil : les deux heures avancent ensemble.
        appareil = appareil.add(const Duration(seconds: 60));
        await tester.pump(const Duration(seconds: 61));
        await tester.pumpAndSettle();
        expect(find.textContaining('08:01'), findsOneWidget);
        expect(find.textContaining('07:01'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('meme heure que l enseignant : aucune ligne courante', (
    tester,
  ) async {
    await monter(tester, memeFuseau: true);
    expect(find.byKey(HeureCouranteDouble.cle), findsNothing);
  });

  testWidgets('mouvement reduit : l heure est la, sans animation', (
    tester,
  ) async {
    await monter(tester, mouvementReduit: true);
    expect(find.textContaining('08:00'), findsOneWidget);
    appareil = appareil.add(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 61));
    // Sans animation, le changement est visible des la premiere image.
    expect(find.textContaining('08:01'), findsOneWidget);
  });
}
