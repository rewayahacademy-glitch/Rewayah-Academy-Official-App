// IMAGES-MESSAGERIE (plan du directeur du 16/11/2026), partie interface :
// - la bulle avec image reserve sa place avant le chargement ;
// - une image retiree n'est jamais un cadre vide ;
// - l'apercu en grand (ouverture, fermeture) ;
// - le double toucher met le coeur, retour arriere si l'appel echoue ;
// - l'icone image est absente quand le compte ne peut pas joindre ;
// - l'envoi optimiste, avec « Reessayer ».

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/apercu_image.dart';
import 'package:rewayah_academy/core/communications/image_bulle.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/communications/pastille_coeur.dart';
import 'package:rewayah_academy/core/communications/phrases_images.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/images_du_fil.dart';

import '../../support/hote_theme.dart';
import '../../support/image_png.dart';
import 'support_messages.dart';

class _Source implements SourceImagesFil {
  _Source(this.octets);

  final Uint8List octets;
  int lecturesMiniatures = 0;
  int lecturesImage = 0;

  @override
  Future<Map<String, AdresseImage>> miniatures() async {
    lecturesMiniatures++;
    return <String, AdresseImage>{
      'img-1': AdresseImage(
        url: 'demo:img-1',
        expireLe: DateTime.now().add(const Duration(hours: 1)),
        octets: octets,
      ),
    };
  }

  @override
  Future<AdresseImage?> image(String imageId) async {
    lecturesImage++;
    return AdresseImage(
      url: 'demo:$imageId',
      expireLe: DateTime.now().add(const Duration(hours: 1)),
      octets: octets,
    );
  }
}

MessageFil _message({
  String id = 'm1',
  String texte = 'Regardez',
  ImageMessage? image,
  int coeurs = 0,
  bool aime = false,
  bool deSoi = false,
}) => MessageFil(
  id: id,
  auteur: deSoi ? 'Vous' : 'Amina',
  texte: texte,
  horodatage: '10:00',
  deSoi: deSoi,
  instant: DateTime.utc(2026, 11, 16, 10),
  image: image,
  coeurs: coeurs,
  aimeParMoi: aime,
);

const ImageMessage _paysage = ImageMessage(
  id: 'img-1',
  largeur: 1600,
  hauteur: 1000,
  couleurMoyenne: '#c83c28',
);
const ImageMessage _portrait = ImageMessage(
  id: 'img-1',
  largeur: 800,
  hauteur: 1600,
  couleurMoyenne: '#3c28c8',
);

Future<void> _monter(
  WidgetTester tester, {
  required List<MessageFil> messages,
  SourceImagesFil? images,
  Future<EtatCoeur> Function(String, bool)? onAimer,
  EnvoiImageForTest? onEnvoyerImage,
  Future<Uint8List?> Function()? choisir,
  Size vue = const Size(390, 844),
}) async {
  fixerVue(tester, vue);
  await tester.pumpWidget(
    hoteTheme(
      FilDiscussion(
        messages: messages,
        textes: textesFilCommunication(),
        onEnvoyer: (String _) async {},
        images: images,
        onAimer: onAimer,
        onEnvoyerImage: onEnvoyerImage,
        choisirImage: choisir ?? () async => null,
        afficherAuteur: true,
      ),
      defilant: false,
    ),
  );
  await tester.pump();
}

/// Laisse le moteur d'images terminer (decodage reel hors du temps simule).
Future<void> _attendreMoteur(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

typedef EnvoiImageForTest = Future<void> Function(
  String,
  String,
  ImagePrete,
  ProgressionImage,
);

void main() {
  late Uint8List png;

  setUpAll(() async {
    png = await fabriquerPng(160, 100);
  });

  group('la bulle avec image', () {
    testWidgets('la place est reservee au rapport, avant le chargement', (
      WidgetTester tester,
    ) async {
      final Completer<Map<String, AdresseImage>> attente =
          Completer<Map<String, AdresseImage>>();
      await _monter(
        tester,
        messages: <MessageFil>[_message(image: _paysage)],
        images: _SourceLente(attente.future),
      );
      final Finder image = find.byType(ImageDeBulle);
      expect(image, findsOneWidget);
      final Size taille = tester.getSize(image);
      expect(taille.width / taille.height, closeTo(1.6, 0.01));
      // L'image n'est pas arrivee : la couleur moyenne remplit la place.
      expect(find.byType(Image), findsNothing);
      final Size avant = tester.getSize(image);
      attente.complete(<String, AdresseImage>{
        'img-1': AdresseImage(
          url: 'demo:img-1',
          expireLe: DateTime.now().add(const Duration(hours: 1)),
          octets: png,
        ),
      });
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      // Rien ne saute au chargement.
      expect(tester.getSize(find.byType(ImageDeBulle)), avant);
    });

    testWidgets('une image portrait ne depasse pas 320 au telephone', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        messages: <MessageFil>[_message(image: _portrait)],
        images: _Source(png),
      );
      final Size taille = tester.getSize(find.byType(ImageDeBulle));
      expect(taille.height, lessThanOrEqualTo(320));
      expect(taille.width / taille.height, closeTo(0.5, 0.01));
    });

    testWidgets('une image paysage va a 400 de haut au plus sur ordinateur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        messages: <MessageFil>[
          _message(
            image: const ImageMessage(id: 'img-1', largeur: 800, hauteur: 1600),
          ),
        ],
        images: _Source(png),
        vue: const Size(1440, 900),
      );
      expect(
        tester.getSize(find.byType(ImageDeBulle)).height,
        lessThanOrEqualTo(400),
      );
    });

    testWidgets('la miniature est lue UNE fois par fil, jamais par image', (
      WidgetTester tester,
    ) async {
      final _Source source = _Source(png);
      await _monter(
        tester,
        messages: <MessageFil>[
          _message(image: _paysage),
          _message(
            id: 'm2',
            image: const ImageMessage(id: 'img-1', largeur: 4, hauteur: 3),
          ),
        ],
        images: source,
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(source.lecturesMiniatures, 1);
      expect(source.lecturesImage, 0, reason: 'jamais prechargee');
    });
  });

  group('une image retiree', () {
    testWidgets('une fine ligne, pas de cadre vide, le texte reste lisible', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        messages: <MessageFil>[
          _message(
            texte: 'Voici la page',
            image: const ImageMessage(
              id: 'img-1',
              largeur: 1600,
              hauteur: 1000,
              etat: EtatImageMessage.supprimee,
            ),
          ),
        ],
        images: _Source(png),
      );
      expect(find.byType(ImageDeBulle), findsNothing);
      expect(find.text(t.com.messages.images.retiree), findsOneWidget);
      expect(find.text('Voici la page'), findsOneWidget);
    });
  });

  group('l\'apercu en grand', () {
    testWidgets('toucher l\'image l\'ouvre, la croix le ferme', (
      WidgetTester tester,
    ) async {
      final _Source source = _Source(png);
      await _monter(
        tester,
        messages: <MessageFil>[_message(image: _paysage)],
        images: source,
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(source.lecturesImage, 0);
      await tester.tap(find.byType(ImageDeBulle));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.byType(ApercuImage), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Regardez'), findsWidgets, reason: 'texte en bas');
      expect(find.byKey(ApercuImage.cleEnregistrer), findsOneWidget);
      expect(source.lecturesImage, 1, reason: 'demandee a l\'ouverture');
      await tester.tap(find.byKey(ApercuImage.cleFermer));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.byType(ApercuImage), findsNothing);
    });

    testWidgets('glisser vers le bas ferme', (WidgetTester tester) async {
      await _monter(
        tester,
        messages: <MessageFil>[_message(image: _paysage)],
        images: _Source(png),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.tap(find.byType(ImageDeBulle));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.fling(
        find.byType(InteractiveViewer),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.byType(ApercuImage), findsNothing);
    });
  });

  group('les coeurs', () {
    testWidgets('le double toucher pose le coeur tout de suite', (
      WidgetTester tester,
    ) async {
      final Completer<EtatCoeur> reponse = Completer<EtatCoeur>();
      final List<(String, bool)> appels = <(String, bool)>[];
      await _monter(
        tester,
        messages: <MessageFil>[_message()],
        onAimer: (String id, bool aime) {
          appels.add((id, aime));
          return reponse.future;
        },
      );
      expect(find.byType(PastilleCoeur), findsNothing);
      await tester.tap(find.text('Regardez'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Regardez'));
      await tester.pump();
      // Affichage optimiste : avant la reponse du serveur.
      expect(find.byType(PastilleCoeur), findsOneWidget);
      expect(appels, <(String, bool)>[('m1', true)]);
      expect(
        find.bySemanticsLabel(t.com.messages.images.aimeParVous),
        findsOneWidget,
      );
      reponse.complete(const EtatCoeur(coeurs: 1, aimeParMoi: true));
      await tester.pumpAndSettle();
      expect(find.byType(PastilleCoeur), findsOneWidget);
    });

    testWidgets('l\'appel qui echoue ramene le coeur en arriere', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        messages: <MessageFil>[_message()],
        onAimer: (String id, bool aime) =>
            Future<EtatCoeur>.error(StateError('non')),
      );
      await tester.tap(find.text('Regardez'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Regardez'));
      await tester.pumpAndSettle();
      expect(find.byType(PastilleCoeur), findsNothing);
      expect(find.text(t.com.messages.images.coeurEchec), findsOneWidget);
    });

    testWidgets('un second double toucher retire le coeur', (
      WidgetTester tester,
    ) async {
      final List<bool> appels = <bool>[];
      await _monter(
        tester,
        messages: <MessageFil>[_message(coeurs: 1, aime: true)],
        onAimer: (String id, bool aime) async {
          appels.add(aime);
          return EtatCoeur(coeurs: aime ? 1 : 0, aimeParMoi: aime);
        },
      );
      expect(find.byType(PastilleCoeur), findsOneWidget);
      await tester.tap(find.text('Regardez'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Regardez'));
      await tester.pumpAndSettle();
      expect(appels, <bool>[false]);
      expect(find.byType(PastilleCoeur), findsNothing);
    });

    testWidgets(
      'un coeur de l\'autre : plein, sans nombre, dans un fil a deux',
      (WidgetTester tester) async {
        fixerVue(tester, const Size(390, 844));
        await tester.pumpWidget(
          hoteTheme(
            FilDiscussion(
              messages: <MessageFil>[_message(coeurs: 1)],
              afficherAuteur: false,
              textes: textesFilCommunication(),
              onEnvoyer: (String _) async {},
              onAimer: (String id, bool aime) async =>
                  const EtatCoeur(coeurs: 1, aimeParMoi: false),
            ),
            defilant: false,
          ),
        );
        await tester.pump();
        expect(find.byType(PastilleCoeur), findsOneWidget);
        final Icon icone = tester.widget<Icon>(
          find.descendant(
            of: find.byType(PastilleCoeur),
            matching: find.byType(Icon),
          ),
        );
        expect(icone.icon, AppIcons.coeur.actif, reason: 'jamais un contour');
        expect(
          find.descendant(
            of: find.byType(PastilleCoeur),
            matching: find.byType(Text),
          ),
          findsNothing,
          reason: 'pas de nombre dans un fil a deux',
        );
      },
    );

    testWidgets('aucun coeur : aucune pastille', (WidgetTester tester) async {
      await _monter(tester, messages: <MessageFil>[_message()]);
      expect(find.byType(PastilleCoeur), findsNothing);
    });

    testWidgets('le compte ne s\'ecrit que dans un fil de groupe', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        messages: <MessageFil>[_message(coeurs: 3)],
        onAimer: (String id, bool aime) async =>
            const EtatCoeur(coeurs: 3, aimeParMoi: false),
      );
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('l\'icone image', () {
    testWidgets('rendue quand l\'envoi d\'image est ouvert', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        messages: const <MessageFil>[],
        onEnvoyerImage: (
          String _,
          String _,
          ImagePrete _,
          ProgressionImage _,
        ) async {},
      );
      expect(find.byKey(FilDiscussion.cleImage), findsOneWidget);
    });

    testWidgets('absente quand le compte ne peut pas joindre', (
      WidgetTester tester,
    ) async {
      await _monter(tester, messages: const <MessageFil>[]);
      expect(find.byKey(FilDiscussion.cleImage), findsNothing);
    });

    test('un compte eleve mineur n\'a pas d\'envoi d\'image', () {
      final ImagesDuFil mineur = ImagesDuFil(
        FauxMessagesMetier(),
        'fil',
        peutJoindre: false,
      );
      final ImagesDuFil adulte = ImagesDuFil(
        FauxMessagesMetier(),
        'fil',
        peutJoindre: true,
      );
      expect(mineur.envoyer, isNull);
      expect(adulte.envoyer, isNotNull);
    });
  });

  group('l\'envoi d\'une image', () {
    testWidgets('la bulle apparait tout de suite, puis le refus a sa phrase', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      final List<String> textes = <String>[];
      await _monter(
        tester,
        messages: const <MessageFil>[],
        choisir: () async => png,
        onEnvoyerImage:
            (
              String id,
              String texte,
              ImagePrete image,
              ProgressionImage progression,
            ) async {
              textes.add(texte);
              progression(0.4);
              await attente.future;
              throw const EchecImage(RefusImage.limiteHoraire);
            },
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Ma page');
      await tester.tap(find.byKey(FilDiscussion.cleImage));
      await _attendreMoteur(tester);
      expect(find.byType(ImageDeBulle), findsOneWidget);
      expect(find.text('Ma page'), findsOneWidget);
      expect(textes, <String>['Ma page'], reason: 'texte dans le meme message');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      attente.complete();
      await tester.pumpAndSettle();
      expect(
        find.text(phraseRefusImage(RefusImage.limiteHoraire)),
        findsOneWidget,
      );
      // Une limite horaire ne change pas en reessayant : pas de bouton.
      expect(
        find.text(t.com.socle.composants.composer.reessayer),
        findsNothing,
      );
    });

    testWidgets('une panne passagere propose « Reessayer »', (
      WidgetTester tester,
    ) async {
      int essais = 0;
      await _monter(
        tester,
        messages: const <MessageFil>[],
        choisir: () async => png,
        onEnvoyerImage:
            (String _, String _, ImagePrete _, ProgressionImage _) async {
              essais++;
              if (essais == 1) throw const EchecImage(RefusImage.envoiStockage);
            },
      );
      await tester.tap(find.byKey(FilDiscussion.cleImage));
      await _attendreMoteur(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(phraseRefusImage(RefusImage.envoiStockage)),
        findsOneWidget,
      );
      await tester.tap(find.text(t.com.socle.composants.composer.reessayer));
      await tester.pumpAndSettle();
      expect(essais, 2);
      expect(
        find.text(phraseRefusImage(RefusImage.envoiStockage)),
        findsNothing,
      );
    });
  });
}

class _SourceLente implements SourceImagesFil {
  _SourceLente(this._miniatures);

  final Future<Map<String, AdresseImage>> _miniatures;

  @override
  Future<Map<String, AdresseImage>> miniatures() => _miniatures;

  @override
  Future<AdresseImage?> image(String imageId) async => null;
}
