// IMAGE-EXPEDITEUR (urgence production, 16/11/2026) : la photo ne se peignait
// ni chez l'expediteur ni chez le destinataire. Reproduit dans Chromium (build
// web release, Playwright) : le stockage n'envoie pas d'en-tete CORS sur le
// GET ; `Image.network` lit par octets (fetch), le navigateur refuse, la bulle
// reste un aplat de la couleur moyenne, et le repli vers l'image complete
// echoue de la meme facon. Avec `WebHtmlElementStrategy.fallback`, l'image
// passe par une balise <img>, qui n'exige aucun en-tete CORS, et se peint.
//
// Le test de VM ne peut pas rejouer le navigateur : il prouve que la bulle
// demande bien ce repli (une adresse reseau de la bulle, de la miniature comme
// de l'image complete), dans l'enchainement exact de l'expediteur : envoi,
// confirmation, relecture du fil, bulle avec pixels. La preuve du rendu est la
// capture Chromium (`docs/current/captures/E2E/IMAGE-EXPEDITEUR/`).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_bulle.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/fichiers/selecteur_image.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/hote_theme.dart';
import '../../support/image_png.dart';
import '../../support/plugin_compression.dart';

const ImageMessage _image = ImageMessage(
  id: 'dep-1',
  largeur: 600,
  hauteur: 600,
  couleurMoyenne: '#67201c',
);

/// Les images ne sont servies que par adresse reseau (comme R2), jamais par
/// octets.
class _SourceReseau implements SourceImagesFil {
  final List<String> demandes = <String>[];

  AdresseImage _a(String nom) => AdresseImage(
    url: 'https://stockage.test/$nom?signature=x',
    expireLe: DateTime.now().add(const Duration(hours: 1)),
  );

  @override
  Future<Map<String, AdresseImage>> miniatures({bool frais = false}) async {
    demandes.add('miniatures');
    return <String, AdresseImage>{'dep-1': _a('miniature.jpg')};
  }

  @override
  Future<AdresseImage?> image(String imageId) async {
    demandes.add('image');
    return _a('image.jpg');
  }
}

/// La strategie web du fournisseur d'une image de la bulle.
WebHtmlElementStrategy _strategie(Image image) {
  final ImageProvider<Object> p = image.image is ResizeImage
      ? (image.image as ResizeImage).imageProvider
      : image.image;
  return (p as NetworkImage).webHtmlElementStrategy;
}

void main() {
  late Uint8List png;
  setUpAll(() async => png = await fabriquerPng(160, 100));

  testWidgets('une adresse reseau passe par la balise <img> en repli', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(1440, 900));
    await tester.pumpWidget(
      hoteTheme(
        Center(
          child: ImageDeBulle(
            image: _image,
            taille: const TailleImageBulle(300, 300),
            adresse: AdresseImage(
              url: 'https://stockage.test/miniature.jpg',
              expireLe: DateTime.utc(2099),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      _strategie(tester.widget<Image>(find.byType(Image))),
      WebHtmlElementStrategy.fallback,
      reason: 'sans cela, un GET sans en-tete CORS laisse la bulle sans photo',
    );
  });

  testWidgets('expediteur : envoi, confirmation, relecture, bulle avec photo', (
    WidgetTester tester,
  ) async {
    simulerPluginCompression();
    fixerVue(tester, const Size(1440, 900));
    final _SourceReseau source = _SourceReseau();
    final Completer<void> confirmation = Completer<void>();
    Widget monter(List<MessageFil> messages) => hoteTheme(
      FilDiscussion(
        messages: messages,
        textes: textesFilCommunication(),
        onEnvoyer: (String _) async {},
        images: source,
        choisirImage: (SourceImage _) async => png,
        deuxChoixPhoto: false,
        onEnvoyerImage:
            (String _, String _, ImagePrete _, ProgressionImage p) async {
              p.messageCree('srv-1');
              p.depotCree('dep-1');
              await confirmation.future;
            },
      ),
      defilant: false,
    );
    await tester.pumpWidget(monter(const <MessageFil>[]));
    await tester.tap(find.byKey(FilDiscussion.cleImage));
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    // Envoi en cours : la bulle locale, avec ses pixels (octets locaux).
    expect(find.byType(ImageDeBulle), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Confirmation, puis relecture du fil : la copie serveur est confirmee.
    confirmation.complete();
    await tester.pump();
    await tester.pumpWidget(
      monter(<MessageFil>[
        MessageFil(
          id: 'srv-1',
          auteur: 'Vous',
          texte: '[image]',
          horodatage: '14:34',
          deSoi: true,
          instant: DateTime.utc(2026, 11, 16, 14, 34),
          image: _image,
        ),
      ]),
    );
    // La lecture des adresses des miniatures aboutit.
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    // Une seule bulle, celle du serveur : sa miniature est une adresse reseau
    // qui garde le repli <img> (le GET du stockage peut n'avoir aucun en-tete
    // CORS), et l'image complete demandee en repli de meme.
    expect(find.byType(ImageDeBulle), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(source.demandes, contains('miniatures'));
    expect(
      _strategie(tester.widget<Image>(find.byType(Image))),
      WebHtmlElementStrategy.fallback,
    );
  });
}
