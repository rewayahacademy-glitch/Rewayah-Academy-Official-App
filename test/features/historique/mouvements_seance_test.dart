// Detail d'une seance passee -> « Voir les mouvements associes » (LT-12),
// sur le VRAI routeur et la coquille du tuteur. Le lien n'existe que si un
// mouvement lu porte cette seance et cet eleve (constat 12) : un seul ouvre
// son detail, plusieurs ouvrent la liste filtree sur l'eleve ; le retour
// ramene a la seance. En production (DB-FIN-02 indisponible), aucun lien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/compte/mouvements_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_seance_page.dart';

import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import 'support_historique.dart';

const String _seanceId = 's-presente';

final String _seance = Uri(
  path: Routes.seancePour(_seanceId),
  queryParameters: <String, String>{'eleve': FoyersFictifs.a1.id},
).toString();

MouvementSolde _mvt(String id, {String? seanceId, String? profilId}) =>
    MouvementSolde(
      id: id,
      profilId: profilId ?? FoyersFictifs.a1.id,
      natureServeur: 'demo_consommation',
      statutServeur: 'demo_confirme',
      montantSigneMineur: -100,
      devise: FinanceFoyerDemo.devise,
      date: DateTime.utc(2026, 9, 8, 16, 45),
      seanceId: seanceId,
    );

/// La demonstration, avec des mouvements choisis par le test.
class _Finance extends FinanceFoyerDemo {
  const _Finance(this.liste);

  final List<MouvementSolde> liste;

  @override
  Future<List<MouvementSolde>> mouvements({String? profilId}) async =>
      <MouvementSolde>[
        for (final MouvementSolde m in liste)
          if (profilId == null || m.profilId == profilId) m,
      ];

  @override
  Future<MouvementSolde?> mouvement(String id) async {
    for (final MouvementSolde m in liste) {
      if (m.id == id) {
        return m;
      }
    }
    return null;
  }
}

Future<GoRouter> _monter(
  WidgetTester tester,
  List<MouvementSolde> liste, {
  Size taille = const Size(390, 844),
}) => monterHistorique(
  tester,
  depart: _seance,
  taille: taille,
  autres: <Override>[
    portFinanceFoyerProvider.overrideWithValue(_Finance(liste)),
  ],
);

Future<void> _taperLien(WidgetTester tester) async {
  final Finder lien = find.byKey(DetailSeancePage.voirMouvementsKey);
  await tester.ensureVisible(lien);
  await stabiliser(tester);
  await tester.tap(lien);
  await stabiliser(tester);
}

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('${taille.width.toInt()} un mouvement lie : seance -> son '
        'detail -> retour a la seance', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, <MouvementSolde>[
        _mvt('m-lie', seanceId: _seanceId),
        _mvt('m-autre', seanceId: 'autre-seance'),
      ], taille: taille);
      expect(find.byType(DetailSeancePage), findsOneWidget);
      expect(find.text(t.historique.seance.voirMouvements), findsOneWidget);

      await _taperLien(tester);
      expect(Uri.parse(lieu(routeur)).path, Routes.mouvementPour('m-lie'));
      expect(find.byType(DetailMouvementPage), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), _seance);
      expect(find.byType(DetailSeancePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('plusieurs mouvements lies : liste filtree sur l eleve, '
      'retour a la seance', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester, <MouvementSolde>[
      _mvt('m-1', seanceId: _seanceId),
      _mvt('m-2', seanceId: _seanceId),
    ]);

    await _taperLien(tester);
    final Uri ici = Uri.parse(lieu(routeur));
    expect(ici.path, Routes.tuteurCompteMouvements);
    expect(ici.queryParameters['profil'], FoyersFictifs.a1.id);
    expect(find.byType(MouvementsComptePage), findsOneWidget);

    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), _seance);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mouvements lisibles mais aucun lie a cette seance ni a cet '
      'eleve : aucun lien', (WidgetTester tester) async {
    await _monter(tester, <MouvementSolde>[
      _mvt('m-autre-seance', seanceId: 'autre-seance'),
      _mvt('m-sans-seance'),
      _mvt('m-autre-eleve', seanceId: _seanceId, profilId: 'autre-eleve'),
    ]);
    expect(find.byType(DetailSeancePage), findsOneWidget);
    expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
    expect(find.byKey(DetailSeancePage.voirMouvementsKey), findsNothing);
  });

  testWidgets('production : DB-FIN-02 indisponible, aucun lien', (
    WidgetTester tester,
  ) async {
    await monterHistorique(tester, depart: _seance);
    expect(find.byType(DetailSeancePage), findsOneWidget);
    expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
    expect(find.byKey(DetailSeancePage.voirMouvementsKey), findsNothing);
    expect(find.text(t.historique.seance.voirMouvements), findsNothing);
  });
}
