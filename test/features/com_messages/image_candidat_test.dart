// IMAGE-CANDIDAT (directeur, 16/11/2026) : dans le dossier d'un candidat, la bulle
// du candidat montrait « [image] » sans photo (le depot avait ete refuse, 403, et
// aucune image ne s'etait rattachee au message).
// 1. un message dont le texte n'est que « [image] » et qui ne porte aucune image
//    n'est montre a personne ; avec son image, il se montre sans texte ;
// 2. un texte ecrit par une personne reste lisible, meme « Image » ;
// 3. sans envoi d'image offert par la page (le serveur ferme l'ecriture), le
//    bouton image n'est pas propose.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/hote_theme.dart';

const ImageMessage _image = ImageMessage(
  id: 'img-1',
  largeur: 800,
  hauteur: 600,
  couleurMoyenne: '#a1b2c3',
);

MessageFil _m(String id, String texte, {ImageMessage? image}) => MessageFil(
  id: id,
  auteur: 'Khadija',
  texte: texte,
  horodatage: '10:00',
  deSoi: false,
  instant: DateTime.utc(2026, 11, 16, 10, int.parse(id.substring(1))),
  image: image,
);

Future<void> _monter(
  WidgetTester tester,
  List<MessageFil> messages, {
  EnvoiImageFil? onEnvoyerImage,
  bool image = false,
}) async {
  fixerVue(tester, const Size(390, 844));
  await tester.pumpWidget(
    hoteTheme(
      FilDiscussion(
        messages: messages,
        textes: textesFilCommunication(),
        onEnvoyer: (String _) async {},
        onEnvoyerImage: onEnvoyerImage,
        pleinEcran: true,
      ),
      defilant: false,
    ),
  );
  // Une bulle d'image anime son attente : quelques images, jamais « settle ».
  if (image) {
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
}

Finder _bulle(String id) => find.byKey(ValueKey<String>('message-$id'));

void main() {
  testWidgets('« [image] » sans image : montre a personne', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <MessageFil>[
      _m('m1', '[image]'),
      _m('m2', 'Bonjour'),
    ]);
    expect(find.text('[image]'), findsNothing);
    expect(_bulle('m1'), findsNothing);
    expect(_bulle('m2'), findsOneWidget);
    expect(find.text('Bonjour'), findsOneWidget);
  });

  testWidgets('« [image] » avec son image : la bulle se montre sans le texte', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <MessageFil>[
      _m('m3', '[image]', image: _image),
    ], image: true);
    expect(_bulle('m3'), findsOneWidget);
    expect(find.text('[image]'), findsNothing);
  });

  testWidgets('un texte ecrit par une personne reste lisible, meme « Image »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <MessageFil>[_m('m4', 'Image')]);
    expect(_bulle('m4'), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
  });

  testWidgets('sans envoi d\'image offert : aucun bouton image', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <MessageFil>[_m('m2', 'Bonjour')]);
    expect(find.byKey(FilDiscussion.cleImage), findsNothing);
  });
}
