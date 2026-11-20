// PE-D1 MESSAGERIE-FIABLE, relecture adverse de la PR 657 (pilote, 20/11),
// point 5 a : la legende d'une image n'est pas perdue quand le depot de
// l'image echoue APRES le retour du message, meme quand le serveur rend la cle
// d'envoi de ce message (rapprochement par cle).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/fichiers/selecteur_image.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/echec_bulle.dart';
import '../../support/hote_theme.dart';
import '../../support/image_png.dart';
import '../../support/plugin_compression.dart';

Future<void> _attendreMoteur(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

void main() {
  late Uint8List png;

  setUpAll(() async {
    png = await fabriquerPng(160, 100);
  });

  testWidgets('depot en echec apres le message : la legende reste, une '
      'seule fois, avec « non confirme »', (WidgetTester tester) async {
    simulerPluginCompression();
    fixerVue(tester, const Size(390, 844));
    final DateTime t0 = DateTime.utc(2026, 11, 20, 10);
    final Completer<void> depot = Completer<void>();
    String? idLocal;
    Widget monter(List<MessageFil> messages) => hoteTheme(
      FilDiscussion(
        messages: messages,
        textes: textesFilCommunication(),
        onEnvoyerMessage: (String _, String _) async {},
        onEnvoyerImage:
            (String id, String _, ImagePrete _, ProgressionImage p) async {
              idLocal = id;
              p.messageCree('srv-1');
              p.depotCree('dep-1');
              await depot.future;
            },
        choisirImage: (SourceImage _) async => png,
        deuxChoixPhoto: false,
        horloge: () => t0,
      ),
      defilant: false,
    );
    await tester.pumpWidget(monter(const <MessageFil>[]));
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Ma page 3');
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.cleImage));
    await _attendreMoteur(tester);

    // Le depot echoue.
    depot.completeError(const EchecImage(RefusImage.envoiStockage));
    await tester.pumpAndSettle();

    // La relecture rend le message (legende, image en attente) AVEC la cle
    // de la bulle : la bulle locale ne s'efface pas pour autant.
    await tester.pumpWidget(
      monter(<MessageFil>[
        MessageFil(
          id: 'srv-1',
          auteur: 'Vous',
          texte: 'Ma page 3',
          horodatage: '10:00',
          deSoi: true,
          instant: t0.add(const Duration(seconds: 1)),
          idLocal: idLocal,
          cleEnvoiConnue: true,
          image: const ImageMessage(
            id: 'dep-1',
            largeur: 160,
            hauteur: 100,
            etat: EtatImageMessage.enAttente,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(idLocal, isNotNull);
    expect(find.text('Ma page 3'), findsOneWidget);
    expect(find.text(ligneEchec), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('message-srv-1')), findsNothing);
  });
}
