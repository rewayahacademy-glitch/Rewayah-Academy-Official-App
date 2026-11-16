// IMAGES-CORRECTIF (directeur, 16/11/2026, l'envoi d'image essaye en
// production) :
// 1. une image sans legende ne montre aucun texte, ni dans la bulle ni dans
//    la liste (« Photo » avec une icone) ;
// 2. la bulle locale garde l'identifiant du message serveur : une seule bulle
//    pendant l'envoi, en echec, et apres la confirmation ;
// 3. une bulle en echec garde sa place dans l'ordre du fil et ouvre un menu
//    « Reessayer » / « Supprimer » ;
// 4. le stockage qui refuse l'envoi se dit sans mot technique.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_test;
import 'package:rewayah_academy/core/communications/image_bulle.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/communications/phrases_images.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/fichiers/selecteur_image.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/ligne_conversation.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';

import '../../support/echec_bulle.dart';
import '../../support/hote_theme.dart';
import '../../support/image_png.dart';
import '../../support/plugin_compression.dart';

const ImageMessage _image = ImageMessage(
  id: 'img-9',
  largeur: 800,
  hauteur: 600,
  couleurMoyenne: '#a1b2c3',
);

MessageFil _serveur({
  required String id,
  required DateTime instant,
  String texte = 'Bonjour',
  ImageMessage? image,
  bool deSoi = false,
}) => MessageFil(
  id: id,
  auteur: deSoi ? 'Vous' : 'Amina',
  texte: texte,
  horodatage: '10:00',
  deSoi: deSoi,
  instant: instant,
  image: image,
);

Finder _bulleLocale() => find.byWidgetPredicate(
  (Widget w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('message-local-'),
);

Finder _bulle(String id) => find.byKey(ValueKey<String>('message-$id'));

Future<void> _attendreMoteur(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

Widget _fil({
  required List<MessageFil> messages,
  required Uint8List photo,
  EnvoiImage? onEnvoyerImage,
  Future<void> Function(String)? onAnnulerImage,
  Future<void> Function(String)? onEnvoyer,
  DateTime Function()? horloge,
}) => hoteTheme(
  FilDiscussion(
    messages: messages,
    textes: textesFilCommunication(),
    onEnvoyer: onEnvoyer ?? (String _) async {},
    onEnvoyerImage: onEnvoyerImage,
    onAnnulerImage: onAnnulerImage,
    choisirImage: (SourceImage _) async => photo,
    deuxChoixPhoto: false,
    horloge: horloge ?? DateTime.now,
  ),
  defilant: false,
);

typedef EnvoiImage = Future<void> Function(
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

  group('1. une image sans legende', () {
    test('le texte de remplissage est une constante, deux formes lues', () {
      expect(texteImageSeule, '[image]');
      expect(estTexteImageSeule('[image]'), isTrue);
      expect(estTexteImageSeule(' Image '), isTrue);
      expect(estTexteImageSeule('Image de la page 3'), isFalse);
      expect(estTexteImageSeule(''), isFalse);
    });

    for (final String texte in <String>['[image]', 'Image']) {
      testWidgets('la bulle d\'image « $texte » n\'ecrit aucun texte', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, const Size(390, 844));
        await tester.pumpWidget(
          _fil(
            photo: png,
            messages: <MessageFil>[
              _serveur(
                id: 'm1',
                instant: DateTime.utc(2026, 11, 16, 10),
                texte: texte,
                image: _image,
              ),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(ImageDeBulle), findsOneWidget);
        expect(find.text(texte), findsNothing);
      });
    }

    testWidgets('un message sans image qui dit « Image » reste ecrit', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _fil(
          photo: png,
          messages: <MessageFil>[
            _serveur(
              id: 'm1',
              instant: DateTime.utc(2026, 11, 16, 10),
              texte: 'Image',
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Image'), findsOneWidget);
    });

    Map<String, dynamic> fil(String texte, {Object? image}) =>
        <String, dynamic>{
          'id': '7c400000-0000-4000-8000-0000000000f9',
          'objet': <String, dynamic>{
            'type': 'classe',
            'id': '7c400000-0000-4000-8000-0000000000c1',
            'libelle': 'Classe 1',
          },
          'parties': <Object>[],
          'dernier_message_le': '2026-11-16T10:00:00Z',
          'non_lus': 0,
          'messages': <Map<String, dynamic>>[
            <String, dynamic>{'texte': texte, 'image': ?image},
          ],
        };
    const Map<String, dynamic> serveurImage = <String, dynamic>{
      'id': 'img-9',
      'largeur': 800,
      'hauteur': 600,
      'etat': 'confirmee',
    };

    test('l\'apercu de la liste : photo seule, sans texte', () {
      for (final String texte in <String>['[image]', 'Image']) {
        final r = resumeFilJson(
          fil(texte, image: serveurImage),
          const LibellesCommunicationSlang(),
        );
        expect(r.apercuPhoto, isTrue, reason: texte);
        expect(r.apercu, isNull, reason: texte);
      }
      final legende = resumeFilJson(
        fil('Ma page', image: serveurImage),
        const LibellesCommunicationSlang(),
      );
      expect(legende.apercuPhoto, isFalse);
      expect(legende.apercu, 'Ma page');
      final sansImage = resumeFilJson(
        fil('Image'),
        const LibellesCommunicationSlang(),
      );
      expect(sansImage.apercuPhoto, isFalse);
      expect(sansImage.apercu, 'Image');
    });

    testWidgets('la ligne de la liste dit « Photo », avec une icone image', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          LigneConversation(
            meneur: const SizedBox.square(dimension: 48),
            titre: 'Amina',
            apercu: t.com.messages.images.photoApercu,
            apercuPhoto: true,
            onPress: () {},
          ),
        ),
      );
      expect(find.text(t.com.messages.images.photoApercu), findsOneWidget);
      expect(find.text('[image]'), findsNothing);
      expect(find.byIcon(AppIcons.image.repos), findsOneWidget);
    });

    test('« Photo » existe en francais, anglais et arabe', () {
      expect(t.com.messages.images.photoApercu, 'Photo');
    });
  });

  group('2. une seule bulle a tout moment', () {
    testWidgets('en cours, en echec, puis apres la confirmation', (
      WidgetTester tester,
    ) async {
      simulerPluginCompression();
      fixerVue(tester, const Size(390, 844));
      final DateTime t0 = DateTime.utc(2026, 11, 16, 10);
      Completer<void> attente = Completer<void>();
      int essais = 0;
      final List<String> annules = <String>[];
      Widget monter(List<MessageFil> messages) => _fil(
        photo: png,
        messages: messages,
        horloge: () => t0,
        onAnnulerImage: (String id) async => annules.add(id),
        onEnvoyerImage:
            (String _, String _, ImagePrete _, ProgressionImage p) async {
              essais++;
              p.messageCree('srv-1');
              p.depotCree('dep-1');
              await attente.future;
            },
      );
      final MessageFil copieEnAttente = _serveur(
        id: 'srv-1',
        instant: t0.add(const Duration(seconds: 1)),
        texte: '[image]',
        deSoi: true,
        image: const ImageMessage(
          id: 'dep-1',
          largeur: 160,
          hauteur: 100,
          etat: EtatImageMessage.enAttente,
        ),
      );
      await tester.pumpWidget(monter(const <MessageFil>[]));
      await tester.tap(find.byKey(FilDiscussion.cleImage));
      await _attendreMoteur(tester);

      // En cours : le serveur rend sa copie, la bulle locale la couvre.
      await tester.pumpWidget(monter(<MessageFil>[copieEnAttente]));
      await tester.pump();
      expect(_bulleLocale(), findsOneWidget);
      expect(_bulle('srv-1'), findsNothing);
      expect(find.byType(ImageDeBulle), findsOneWidget);

      // Echec : toujours une seule bulle, avec la phrase vraie et le menu.
      attente.completeError(const EchecImage(RefusImage.envoiStockage));
      await tester.pumpAndSettle();
      expect(_bulleLocale(), findsOneWidget);
      expect(_bulle('srv-1'), findsNothing);
      expect(find.byType(ImageDeBulle), findsOneWidget);
      expect(
        find.text(phraseRefusImage(RefusImage.envoiStockage)),
        findsOneWidget,
      );
      expect(find.text(ligneEchec), findsOneWidget);

      // Reessayer : le meme message, la meme bulle.
      attente = Completer<void>();
      await choisirActionEchec(
        tester,
        t.com.socle.composants.composer.reessayer,
      );
      expect(essais, 2);
      expect(_bulleLocale(), findsOneWidget);
      attente.complete();
      await tester.pumpAndSettle();
      expect(
        _bulleLocale(),
        findsOneWidget,
        reason: 'envoyee, pas encore relue',
      );
      expect(_bulle('srv-1'), findsNothing);

      // L'image est confirmee et relue : la bulle locale s'efface.
      await tester.pumpWidget(
        monter(<MessageFil>[
          _serveur(
            id: 'srv-1',
            instant: t0.add(const Duration(seconds: 1)),
            texte: '[image]',
            deSoi: true,
            image: const ImageMessage(id: 'dep-1', largeur: 160, hauteur: 100),
          ),
        ]),
      );
      await tester.pump();
      expect(_bulleLocale(), findsNothing);
      expect(_bulle('srv-1'), findsOneWidget);
      expect(find.byType(ImageDeBulle), findsOneWidget);
      expect(annules, isEmpty);
    });

    testWidgets('« Supprimer » annule le depot et retire la bulle', (
      WidgetTester tester,
    ) async {
      simulerPluginCompression();
      fixerVue(tester, const Size(390, 844));
      final List<String> annules = <String>[];
      await tester.pumpWidget(
        _fil(
          photo: png,
          messages: const <MessageFil>[],
          onAnnulerImage: (String id) async => annules.add(id),
          onEnvoyerImage:
              (String _, String _, ImagePrete _, ProgressionImage p) async {
                p.messageCree('srv-1');
                p.depotCree('dep-1');
                throw const EchecImage(RefusImage.envoiStockage);
              },
        ),
      );
      await tester.tap(find.byKey(FilDiscussion.cleImage));
      await _attendreMoteur(tester);
      await tester.pumpAndSettle();
      expect(_bulleLocale(), findsOneWidget);
      await choisirActionEchec(tester, t.com.messages.images.supprimerEchec);
      expect(annules, <String>['dep-1']);
      expect(_bulleLocale(), findsNothing);
      expect(find.byType(ImageDeBulle), findsNothing);
    });
  });

  group('3. la bulle en echec garde sa place', () {
    testWidgets('un message arrive apres elle s\'affiche sous elle', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      final DateTime t0 = DateTime.utc(2026, 11, 16, 10);
      Widget monter(List<MessageFil> messages) => _fil(
        photo: png,
        messages: messages,
        horloge: () => t0.add(const Duration(minutes: 5)),
        onEnvoyer: (String _) async => throw StateError('hors ligne'),
      );
      final MessageFil avant = _serveur(
        id: 'a',
        instant: t0,
        texte: 'Message ancien',
      );
      await tester.pumpWidget(monter(<MessageFil>[avant]));
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Mon essai');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(find.text(ligneEchec), findsOneWidget);

      await tester.pumpWidget(
        monter(<MessageFil>[
          avant,
          _serveur(
            id: 'b',
            instant: t0.add(const Duration(minutes: 10)),
            texte: 'Recu apres',
          ),
        ]),
      );
      await tester.pump();
      final double ancien = tester.getTopLeft(find.text('Message ancien')).dy;
      final double essai = tester.getTopLeft(find.text('Mon essai')).dy;
      final double apres = tester.getTopLeft(find.text('Recu apres')).dy;
      expect(ancien, lessThan(essai));
      expect(essai, lessThan(apres), reason: 'le recu apres passe en dessous');
    });

    testWidgets('la ligne et l\'icone ouvrent « Reessayer » et « Supprimer »', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _fil(
          photo: png,
          messages: const <MessageFil>[],
          onEnvoyer: (String _) async => throw StateError('hors ligne'),
        ),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Mon essai');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(FilDiscussion.cleIconeEchec), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsNothing);

      await tester.tap(find.byKey(FilDiscussion.cleIconeEchec));
      await tester.pumpAndSettle();
      expect(
        find.text(t.com.socle.composants.composer.reessayer),
        findsOneWidget,
      );
      expect(find.text(t.com.messages.images.supprimerEchec), findsOneWidget);
      await tester.tap(find.text(t.com.messages.images.supprimerEchec));
      await tester.pumpAndSettle();
      expect(find.text('Mon essai'), findsNothing);
      expect(find.text(ligneEchec), findsNothing);
    });

    testWidgets('une limite qui ne change pas : seulement « Supprimer »', (
      WidgetTester tester,
    ) async {
      simulerPluginCompression();
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _fil(
          photo: png,
          messages: const <MessageFil>[],
          onEnvoyerImage: (
            String _,
            String _,
            ImagePrete _,
            ProgressionImage _,
          ) async => throw const EchecImage(RefusImage.limiteHoraire),
        ),
      );
      await tester.tap(find.byKey(FilDiscussion.cleImage));
      await _attendreMoteur(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(phraseRefusImage(RefusImage.limiteHoraire)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(FilDiscussion.cleIconeEchec));
      await tester.pumpAndSettle();
      expect(find.text(t.com.messages.images.supprimerEchec), findsOneWidget);
      expect(
        find.text(t.com.socle.composants.composer.reessayer),
        findsNothing,
      );
    });
  });

  group('4. le stockage refuse l\'envoi', () {
    test('la phrase dit que l\'envoi n\'a pas abouti, sans mot technique', () {
      final String phrase = phraseRefusImage(RefusImage.envoiStockage);
      expect(
        phrase,
        'L\'envoi de l\'image n\'a pas abouti. Réessayez plus tard.',
      );
      for (final String technique in <String>[
        'stockage',
        'adresse',
        'serveur',
        'R2',
        'URL',
        'CORS',
      ]) {
        expect(phrase.toLowerCase(), isNot(contains(technique.toLowerCase())));
      }
    });
  });

  group('l\'adaptateur', () {
    const String fil = '7c400000-0000-4000-8000-0000000000f9';
    const String depotId = '7c400000-0000-4000-8000-0000000000d9';
    final ImagePrete prete = ImagePrete(
      octets: Uint8List.fromList(<int>[1, 2, 3]),
      mime: 'image/jpeg',
      largeur: 10,
      hauteur: 10,
      miniature: Uint8List.fromList(<int>[4, 5]),
      mimeMiniature: 'image/webp',
    );

    MessagesMetierSupabase adaptateur({
      required List<String> appels,
      required http.Client transport,
    }) => MessagesMetierSupabase(
      (String f, Map<String, dynamic> p) async {
        appels.add(f);
        return <String, dynamic>{'id': 'msg-1'};
      },
      libelles: const LibellesCommunicationSlang(),
      fonctions: (String f, Map<String, dynamic> corps) async {
        appels.add('$f:${corps['action']}');
        if (corps['action'] == 'demander') {
          return <String, dynamic>{
            'image_id': depotId,
            'image': <String, dynamic>{
              'url': 'https://r2.test/a',
              'en_tetes_exiges': <String, String>{'content-type': 'image/jpeg'},
            },
            'miniature': <String, dynamic>{
              'url': 'https://r2.test/b',
              'en_tetes_exiges': <String, String>{'content-type': 'image/webp'},
            },
          };
        }
        return const <String, dynamic>{};
      },
      transport: transport,
    );

    test('le suivi rend l\'id du message puis celui du depot', () async {
      final List<String> appels = <String>[];
      final List<String> suivi = <String>[];
      await adaptateur(
        appels: appels,
        transport: http_test.MockClient(
          (http.Request _) async => http.Response('', 200),
        ),
      ).envoyerImage(
        fil,
        '[image]',
        'cle-1',
        prete,
        progression: ProgressionImage(
          (double _) {},
          surMessage: (String id) => suivi.add('message:$id'),
          surDepot: (String id) => suivi.add('depot:$id'),
        ),
      );
      expect(suivi, <String>['message:msg-1', 'depot:$depotId']);
      expect(appels.last, 'message-image-depot:confirmer');
    });

    test('le PUT refuse : l\'echec est dit, jamais de confirmation', () async {
      final List<String> appels = <String>[];
      final List<String> suivi = <String>[];
      Object? echec;
      try {
        await adaptateur(
          appels: appels,
          transport: http_test.MockClient(
            (http.Request _) async => throw http.ClientException('cors'),
          ),
        ).envoyerImage(
          fil,
          '[image]',
          'cle-1',
          prete,
          progression: ProgressionImage(
            (double _) {},
            surMessage: (String id) => suivi.add('message:$id'),
            surDepot: (String id) => suivi.add('depot:$id'),
          ),
        );
      } on EchecImage catch (e) {
        echec = e;
      }
      expect((echec! as EchecImage).refus, RefusImage.envoiStockage);
      expect(appels, isNot(contains('message-image-depot:confirmer')));
      // Les identifiants sont connus avant l'echec : « Supprimer » peut annuler.
      expect(suivi, <String>['message:msg-1', 'depot:$depotId']);
    });

    test(
      'annulerImage appelle l\'action annuler, jamais sur un faux id',
      () async {
        final List<String> appels = <String>[];
        final MessagesMetierSupabase a = adaptateur(
          appels: appels,
          transport: http_test.MockClient(
            (http.Request _) async => http.Response('', 200),
          ),
        );
        await a.annulerImage(depotId);
        await a.annulerImage('pas-un-uuid');
        expect(appels, <String>['message-image-depot:annuler']);
      },
    );
  });
  group('5. la miniature qui ne se peint pas (bug du 16/11 en production)', () {
    const String fil = '7c400000-0000-4000-8000-0000000000f9';

    test(
      'la liste gardee ne connait pas une image arrivee apres elle',
      () async {
        int lectures = 0;
        final MessagesMetierSupabase port = MessagesMetierSupabase(
          (String f, Map<String, dynamic> p) async => <String, dynamic>{},
          libelles: const LibellesCommunicationSlang(),
          fonctions: (String f, Map<String, dynamic> corps) async {
            lectures++;
            return <String, dynamic>{
              'images': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'a',
                  'url': 'https://r2.test/a',
                  'expire_dans_secondes': 3600,
                },
                if (lectures > 1)
                  <String, dynamic>{
                    'id': 'b',
                    'url': 'https://r2.test/b',
                    'expire_dans_secondes': 3600,
                  },
              ],
            };
          },
        );
        expect((await port.urlsMiniatures(fil)).keys, <String>['a']);
        // Sans [frais], la liste gardee est rendue : « b » en est absente.
        expect((await port.urlsMiniatures(fil)).keys, <String>['a']);
        expect(lectures, 1);
        // Avec [frais], le serveur est relu et « b » apparait.
        expect((await port.urlsMiniatures(fil, frais: true)).keys, <String>[
          'a',
          'b',
        ]);
        expect(lectures, 2);
      },
    );

    testWidgets('une image arrivee pendant que le fil est ouvert se peint', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(1440, 900));
      final List<bool> demandes = <bool>[];
      final _SourceGardee source = _SourceGardee(png, demandes);
      MessageFil confirmee(String id, int minute) => _serveur(
        id: 'm-$id',
        instant: DateTime.utc(2026, 11, 16, 10, minute),
        texte: '[image]',
        image: ImageMessage(id: id, largeur: 160, hauteur: 100),
      );
      Widget monter(List<MessageFil> messages) => hoteTheme(
        FilDiscussion(
          messages: messages,
          textes: textesFilCommunication(),
          onEnvoyer: (String _) async {},
          images: source,
          deuxChoixPhoto: false,
        ),
        defilant: false,
      );
      await tester.pumpWidget(monter(<MessageFil>[confirmee('a', 1)]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      // Le destinataire recoit une seconde image alors que le fil est ouvert.
      await tester.pumpWidget(
        monter(<MessageFil>[confirmee('a', 1), confirmee('b', 2)]),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(Image), findsNWidgets(2));
      expect(demandes, <bool>[false, false, true]);
    });

    testWidgets('miniature en echec : l\'image complete la remplace', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      int replis = 0;
      await tester.pumpWidget(
        hoteTheme(
          Center(
            child: ImageDeBulle(
              image: _image,
              taille: const TailleImageBulle(200, 150),
              // Des octets illisibles : la miniature echoue au decodage.
              adresse: AdresseImage(
                url: 'miniature-cassee',
                expireLe: DateTime.utc(2099),
                octets: Uint8List.fromList(<int>[1, 2, 3, 4]),
              ),
              repli: () async {
                replis++;
                return AdresseImage(
                  url: 'image-complete',
                  expireLe: DateTime.utc(2099),
                  octets: png,
                );
              },
            ),
          ),
        ),
      );
      for (int i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(replis, 1);
      final Image affichee = tester.widget<Image>(find.byType(Image));
      expect(
        (affichee.image as ResizeImage).imageProvider,
        isA<MemoryImage>().having(
          (MemoryImage m) => m.bytes.length,
          'octets de l\'image complete',
          png.length,
        ),
      );
    });

    testWidgets('aucune adresse rendue : le repli part sans attendre', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      int replis = 0;
      await tester.pumpWidget(
        hoteTheme(
          Center(
            child: ImageDeBulle(
              image: _image,
              taille: const TailleImageBulle(200, 150),
              adresseIntrouvable: true,
              repli: () async {
                replis++;
                return AdresseImage(
                  url: 'image-complete',
                  expireLe: DateTime.utc(2099),
                  octets: png,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(replis, 1);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('6. un effet de chargement agreable', () {
    Widget bulle({AdresseImage? adresse, bool reduit = false}) => hoteTheme(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduit),
        child: Center(
          child: ImageDeBulle(
            image: _image,
            taille: const TailleImageBulle(200, 150),
            adresse: adresse,
          ),
        ),
      ),
    );

    testWidgets('un reflet tourne tant que les pixels n\'arrivent pas', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(bulle());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(ImageDeBulle.cleReflet), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('il s\'arrete des la premiere image', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(bulle());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(ImageDeBulle.cleReflet), findsOneWidget);
      await tester.pumpWidget(
        bulle(
          adresse: AdresseImage(
            url: 'x',
            expireLe: DateTime.utc(2099),
            octets: png,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(ImageDeBulle.cleReflet), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('sous « reduire les animations » : fixe, rien ne tourne', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(bulle(reduit: true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
    });

    test('le reflet prend sa duree dans app_mouvement', () {
      expect(AppMouvement.refletSquelette, const Duration(milliseconds: 1800));
    });
  });
}

/// Une source qui garde sa premiere liste : sans [frais], une image arrivee
/// depuis n'y figure pas (comme le port, qui garde la liste une heure).
class _SourceGardee implements SourceImagesFil {
  _SourceGardee(this.octets, this.demandes);

  final Uint8List octets;
  final List<bool> demandes;

  AdresseImage _a() => AdresseImage(
    url: 'demo',
    expireLe: DateTime.now().add(const Duration(hours: 1)),
    octets: octets,
  );

  @override
  Future<Map<String, AdresseImage>> miniatures({bool frais = false}) async {
    demandes.add(frais);
    return <String, AdresseImage>{'a': _a(), if (frais) 'b': _a()};
  }

  @override
  Future<AdresseImage?> image(String imageId) async => _a();
}
