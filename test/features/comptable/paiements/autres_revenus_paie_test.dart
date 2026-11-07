// REVENUS-VERITE point 5 : la carte « Autres revenus » du detail de paie.
// La direction (capacite peutAttribuer rendue par le serveur) attribue et
// annule ; la comptabilite lit ; un serveur d'avant le lot : pas de carte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_autres_revenus.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/comptable/paiements/autres_revenus_paie.dart';

import '../../../support/garde_interface.dart';
import '../../../support/harnais.dart';
import 'support_paiements.dart';

class _Port implements PortAutresRevenus {
  _Port({required this.peutAttribuer, this.indisponible = false});

  final bool peutAttribuer;
  final bool indisponible;
  final List<AutreRevenu> lignes = <AutreRevenu>[
    const AutreRevenu(
      id: 'a1',
      nature: NatureAutreRevenu.mission,
      libelle: 'Remplacement du 12',
      montant: Montant(2500, 'USD'),
    ),
  ];
  final List<Map<String, Object>> attributions = <Map<String, Object>>[];
  final List<String> annulations = <String>[];

  @override
  Future<AutresRevenusMois> lister(String enseignantId, DateTime mois) async {
    if (indisponible) throw const CapaciteIndisponible('REVENUS-VERITE-5');
    return AutresRevenusMois(
      mois: mois,
      devise: 'USD',
      peutAttribuer: peutAttribuer,
      aideInternetPolitique: const Montant(1000, 'USD'),
      lignes: List<AutreRevenu>.of(lignes),
    );
  }

  @override
  Future<void> attribuer({
    required String enseignantId,
    required DateTime mois,
    required NatureAutreRevenu nature,
    required String libelle,
    required int montantMineur,
    required String cle,
  }) async {
    attributions.add(<String, Object>{
      'enseignant': enseignantId,
      'nature': nature,
      'libelle': libelle,
      'montant': montantMineur,
      'cle': cle,
    });
    lignes.add(
      AutreRevenu(
        id: 'n${lignes.length}',
        nature: nature,
        libelle: libelle,
        montant: Montant(montantMineur, 'USD'),
      ),
    );
  }

  @override
  Future<void> annuler(String id) async {
    annulations.add(id);
    lignes.removeWhere((AutreRevenu l) => l.id == id);
  }
}

Future<int> _monter(
  WidgetTester tester,
  _Port port, {
  Size taille = const Size(390, 1400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  int relectures = 0;
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CarteAutresRevenus(
              enseignantId: 'b1',
              mois: DateTime(2026, 11),
              nom: 'Maryam Bah',
              onChange: () => relectures++,
            ),
          ),
        ),
      ),
      surcharges: <Override>[
        portAutresRevenusProvider.overrideWithValue(port),
        ...surchargesCommunes(montantsAffiches: true),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return relectures;
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('direction : les lignes, « Annuler » et « Attribuer »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(peutAttribuer: true));
    expect(find.text('Remplacement du 12'), findsOneWidget);
    expect(find.text(t.commun.autresRevenus.mission), findsOneWidget);
    expect(find.byKey(CarteAutresRevenus.cleAttribuer), findsOneWidget);
    expect(find.byKey(CarteAutresRevenus.cleAnnuler('a1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comptabilite : la carte se lit seulement', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(peutAttribuer: false));
    expect(find.text('Remplacement du 12'), findsOneWidget);
    expect(find.byKey(CarteAutresRevenus.cleAttribuer), findsNothing);
    expect(find.byKey(CarteAutresRevenus.cleAnnuler('a1')), findsNothing);
  });

  testWidgets('serveur d avant le lot : aucune carte', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(peutAttribuer: true, indisponible: true));
    expect(find.byKey(CarteAutresRevenus.cle), findsNothing);
  });

  testWidgets('attribuer l aide Internet : nom et montant de la politique '
      'proposes, une seule attribution, puis relecture', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(peutAttribuer: true);
    await _monter(tester, port);
    await tester.tap(find.byKey(CarteAutresRevenus.cleAttribuer));
    await tester.pumpAndSettle();
    expect(
      find.text(t.admin.finance.autres.feuilleTitre(nom: 'Maryam Bah')),
      findsOneWidget,
    );
    await tester.tap(find.text(t.commun.autresRevenus.aideInternet).last);
    await tester.pumpAndSettle();
    final Finder bouton = find.byKey(FeuilleAttribution.cleConfirmer);
    await tester.ensureVisible(bouton);
    await tester.pumpAndSettle();
    expect(
      find.text(
        t.admin.finance.autres.confirmer(
          montant: formaterMontant(const Montant(1000, 'USD')),
        ),
      ),
      findsOneWidget,
    );
    verifierUnSeulBoutonPlein(tester);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(port.attributions, hasLength(1));
    expect(port.attributions.single['nature'], NatureAutreRevenu.aideInternet);
    expect(
      port.attributions.single['libelle'],
      t.commun.autresRevenus.aideInternet,
    );
    expect(port.attributions.single['montant'], 1000);
    expect(find.byKey(FeuilleAttribution.cleConfirmer), findsNothing);
    expect(find.text(t.commun.autresRevenus.aideInternet), findsWidgets);
  });

  testWidgets('une saisie invalide se dit sous son champ, rien ne part', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(peutAttribuer: true);
    await _monter(tester, port);
    await tester.tap(find.byKey(CarteAutresRevenus.cleAttribuer));
    await tester.pumpAndSettle();
    final Finder bouton = find.byKey(FeuilleAttribution.cleConfirmer);
    await tester.ensureVisible(bouton);
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.text(t.admin.finance.autres.erreurLibelle), findsOneWidget);
    expect(find.text(t.admin.finance.autres.erreurMontant), findsOneWidget);
    expect(port.attributions, isEmpty);
  });

  testWidgets('annuler demande confirmation, puis annule', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(peutAttribuer: true);
    await _monter(tester, port);
    await tester.tap(find.byKey(CarteAutresRevenus.cleAnnuler('a1')));
    await tester.pumpAndSettle();
    expect(find.text(t.admin.finance.autres.annulerTitre), findsWidgets);
    await tester.tap(find.text(t.admin.finance.autres.annulerOui));
    await tester.pumpAndSettle();
    expect(port.annulations, <String>['a1']);
    expect(find.text('Remplacement du 12'), findsNothing);
    expect(find.text(t.admin.finance.autres.vide), findsOneWidget);
  });

  testWidgets('en arabe, a 320 : aucun debordement', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await _monter(
      tester,
      _Port(peutAttribuer: true),
      taille: const Size(320, 1400),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(t.admin.finance.autres.titre), findsOneWidget);
  });
}
