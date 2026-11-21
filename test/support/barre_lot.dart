// La barre du lot tient sur une rangee (pilote, 21/11/2026) : deux gestes en
// boutons a l'ordinateur, le reste dans le menu « Autres actions » ; un seul
// menu « Actions » au telephone. Les tests demandent ici l'operation d'un
// geste, ou qu'elle soit.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/lot_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/selection_lot.dart';

/// Ce qu'il faut toucher pour lancer [geste] : son bouton ([cle]) quand il
/// est dans la barre, sinon son entree du menu de la barre, ouvert ici.
Future<Finder> operationDeLot(
  WidgetTester tester,
  Key cle,
  GesteLot geste,
) async {
  final Finder direct = find.byKey(cle);
  if (direct.evaluate().isNotEmpty) return direct;
  final Finder menu = find.byKey(BarreLot.cleAutres);
  await tester.ensureVisible(menu);
  await tester.pump();
  await tester.tap(menu);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return find.text(libelleGesteLot(geste)).last;
}

/// Les gestes que la barre du lot offre, boutons et menu confondus. [cle] :
/// la cle du bouton d'un geste. Le menu est ouvert, lu, puis referme.
Future<Set<GesteLot>> gestesOffertsDuLot(
  WidgetTester tester,
  Key Function(GesteLot geste) cle,
) async {
  final Set<GesteLot> offerts = <GesteLot>{
    for (final GesteLot g in GesteLot.values)
      if (find.byKey(cle(g)).evaluate().isNotEmpty) g,
  };
  final Finder menu = find.byKey(BarreLot.cleAutres);
  if (menu.evaluate().isEmpty) return offerts;
  await tester.ensureVisible(menu);
  await tester.pump();
  await tester.tap(menu);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  for (final GesteLot g in GesteLot.values) {
    if (find.text(libelleGesteLot(g)).evaluate().isNotEmpty) offerts.add(g);
  }
  await tester.tapAt(const Offset(2, 2));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return offerts;
}
