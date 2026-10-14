// Revue COM-FUS : captures de recette d'une bulle de canal qui ne porte
// qu'un vocal (texte vide : la bulle va du nom de l'auteur au lecteur
// `LecteurVocalRecu`), dans le vrai Studio, a 390 et 1440, en francais et en
// arabe (RTL).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures de test.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';

import '../features/com_studio/support_studio.dart' as studio;
import 'outil_capture.dart';

/// Le vocal recu : 0:28, lisible.
final PieceJointe _vocal = PieceJointe(
  reference: ReferencePieceJointe('vocal_capture'),
  nom: 'message-vocal.m4a',
  nature: NaturePieceJointe.vocal,
  typeLisible: 'Audio',
  duree: const Duration(seconds: 28),
  peutOuvrir: true,
);

/// Le canal : un message texte, puis un message qui ne porte qu'un vocal.
Canal _canal() {
  final Canal base = studio.canalSimple();
  return Canal(
    resume: base.resume,
    membres: base.membres,
    messages: <MessageCommunication>[
      MessageCommunication(
        id: 'c1-texte',
        auteur: base.membres.last,
        texte: 'Planning de la semaine.',
        envoyeLe: studio.maintenantTest,
      ),
      MessageCommunication(
        id: 'c1-vocal',
        auteur: base.membres.last,
        texte: '',
        envoyeLe: studio.maintenantTest,
        piecesJointes: <PieceJointe>[_vocal],
      ),
    ],
    capacites: base.capacites,
  );
}

/// Ecrit en PNG la page entiere (la frontiere de repeinte de la route).
Future<String> _capturerPage(WidgetTester tester, String nom) async {
  RenderObject? o = tester.renderObject(find.byType(Scaffold).first);
  while (o != null && o is! RenderRepaintBoundary) {
    o = o.parent;
  }
  final RenderRepaintBoundary boite = o! as RenderRepaintBoundary;
  final String chemin = cheminSortie(nom);
  await tester.runAsync(() async {
    final ui.Image image = await boite.toImage();
    final ByteData? png = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    await File(chemin).parent.create(recursive: true);
    await File(chemin).writeAsBytes(png!.buffer.asUint8List());
  });
  return chemin;
}

void main() {
  group(
    'Capture : revue COM-FUS, bulle vocale seule',
    skip: sautSansCapture,
    () {
      setUpAll(() async {
        await chargerPolicesDuDepot();
      });

      for (final (Size taille, AppLocale langue) in <(Size, AppLocale)>[
        (const Size(390, 844), AppLocale.fr),
        (const Size(390, 844), AppLocale.ar),
        (const Size(1440, 900), AppLocale.fr),
        (const Size(1440, 900), AppLocale.ar),
      ]) {
        final String nom =
            'com_fus_bulle_vocale_${taille.width.toInt()}_'
            '${langue.languageCode}';
        testWidgets(nom, (WidgetTester tester) async {
          await studio.monterStudio(
            tester,
            port: studio.FauxStudio(canaux: <Canal>[_canal()]),
            depart: cheminCanalStudio('c1'),
            taille: taille,
            langue: langue,
          );
          final Finder lecteur = find.descendant(
            of: find.byType(FilDiscussion),
            matching: find.byType(LecteurVocalRecu),
          );
          expect(lecteur, findsOneWidget);
          await tester.ensureVisible(lecteur);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await _capturerPage(tester, nom)}');
        });
      }
    },
  );
}
