// L4-05 : la demonstration du tuteur dit vrai. Prenoms des demandes dans le
// foyer, fin d'acces plausible, phrase « pas encore relie » sous condition,
// aucune navigation vers /tuteur/parcours sans eleve.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart'
    show SlotAction;
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_famille/liste_preparation.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/suivi_demandes_demo.dart';

Future<void> _monter(
  WidgetTester tester,
  AsyncValue<List<SlotAction>?>? travail,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      home: Scaffold(body: ListePreparation(travail: travail)),
    ),
  );
  await tester.pump();
}

void main() {
  test(
    '(a) les prenoms des demandes de la demonstration sont ceux du foyer',
    () {
      final Set<String> foyer = <String>{
        for (final e in DonneesDemo.eleves) e.prenom,
      };
      final SuiviDemandesDemo suivi = SuiviDemandesDemo.foyer();
      expect(suivi.demandes, isNotEmpty);
      for (final d in suivi.demandes) {
        expect(foyer, contains(d.prenom));
      }
      for (final String etranger in <String>['Inès', 'Bilal']) {
        expect(suivi.demandes.map((d) => d.prenom), isNot(contains(etranger)));
      }
    },
  );

  test('(b) finAcces : apres aujourd hui, avant aujourd hui + 90 jours', () {
    final DateTime maintenant = DateTime.now();
    expect(DonneesDemo.finAcces.isAfter(maintenant), isTrue);
    expect(
      DonneesDemo.finAcces.isBefore(maintenant.add(const Duration(days: 90))),
      isTrue,
    );
    // Bornes : fin du mois suivant, y compris en decembre.
    expect(
      DonneesDemo.finAccesDepuis(DateTime(2026, 12, 15)),
      DateTime.utc(2027, 1, 31),
    );
    expect(
      DonneesDemo.finAccesDepuis(DateTime(2026, 1, 31)),
      DateTime.utc(2026, 2, 28),
    );
  });

  test('(e) le double de demonstration rend un travail realiste', () async {
    final travail = await const TravailAVenirDemo().avantProchainCours(
      groupeId: 'g',
    );
    expect(travail, isNotEmpty);
  });

  testWidgets('(e) avec un travail : pas de phrase « pas encore relie »', (
    WidgetTester tester,
  ) async {
    final travail = await const TravailAVenirDemo().avantProchainCours(
      groupeId: 'g',
    );
    await _monter(tester, AsyncValue.data(travail));
    expect(find.text(t.tuteur.accueil.travailIndisponible), findsNothing);
    expect(find.text(travail.first.libelle), findsOneWidget);
  });

  testWidgets('(e) CapaciteIndisponible : la phrase est rendue', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const AsyncValue<List<SlotAction>?>.error(
        CapaciteIndisponible('travail'),
        StackTrace.empty,
      ),
    );
    expect(find.text(t.tuteur.accueil.travailIndisponible), findsOneWidget);
  });

  testWidgets('(e) une panne ordinaire n est pas « pas encore relie »', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      AsyncValue<List<SlotAction>?>.error(StateError('x'), StackTrace.empty),
    );
    expect(find.text(t.tuteur.accueil.travailIndisponible), findsNothing);
    expect(find.text(t.tuteur.accueil.travailIllisible), findsOneWidget);
  });

  test('(f) aucune navigation vers /tuteur/parcours sans identifiant', () {
    final RegExp nu = RegExp(r'Routes\.tuteurParcours\b(?!\s*\()');
    final List<String> fautifs = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      final String src = f.readAsStringSync();
      for (final RegExpMatch m in nu.allMatches(src)) {
        final String suite = src.substring(
          m.end,
          (m.end + 12).clamp(0, src.length),
        );
        // Autorise la definition de la route et son chemin parametre.
        if (!suite.startsWith('}/:eleveId') && !suite.startsWith('/')) {
          if (!f.path.endsWith('routes.dart')) {
            fautifs.add('${f.path}: ${src.substring(m.start, m.end)}$suite');
          }
        }
      }
    }
    expect(fautifs, isEmpty);
    expect(
      RegExp(r'go\(\s*Routes\.tuteurParcours\s*\)').hasMatch(
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File f) => f.path.endsWith('.dart'))
            .map((File f) => f.readAsStringSync())
            .join('\n'),
      ),
      isFalse,
    );
  });
}
