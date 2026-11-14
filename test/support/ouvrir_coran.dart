// ESPACE-APPRENDRE (lot 5, 12/11/2026) : le Coran n'est plus une destination de
// la barre de l'eleve, c'est un document de la Bibliotheque de l'espace
// Apprendre. Ce geste, **celui de la personne**, y mene : toucher « Apprendre »
// dans la barre, puis la carte « Coran » de la Bibliotheque. Partage par les
// tests du lecteur du Coran qui montaient jusque-la par la barre.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/apprendre/documents_apprendre.dart'
    show idDocumentCoran;
import 'package:rewayah_academy/core/apprendre/planche_documents.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../router/support_routeur.dart' show stabiliser;

/// Touche « Apprendre » dans la vraie barre, puis la carte « Coran ».
Future<void> ouvrirLeCoranParApprendre(WidgetTester tester) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(NavShell),
          matching: find.bySemanticsLabel(t.nav.eleve.apprendre),
        )
        .last,
  );
  await stabiliser(tester);
  final Finder coran = find.byKey(
    PlancheDocuments.cleDocument(idDocumentCoran),
  );
  await tester.ensureVisible(coran);
  await stabiliser(tester);
  await tester.tap(coran);
  await stabiliser(tester);
}
