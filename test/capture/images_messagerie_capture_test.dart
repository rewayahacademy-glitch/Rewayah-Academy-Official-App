// Captures R3 du lot IMAGES-MESSAGERIE : le fil avec images portrait et
// paysage, image retiree, coeurs seul et compte, l'envoi en cours, l'apercu
// en grand. Sautees sans `CAPTURE_DIR` (voir `LISEZ-MOI.md`).

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/fichiers/selecteur_image.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../support/plugin_compression.dart';
import 'outil_capture.dart';

/// Une « photo » : un degrade et quelques formes, pour qu'on voie le rendu.
Future<Uint8List> _photo(int l, int h, List<Color> couleurs) async {
  final ui.PictureRecorder enregistreur = ui.PictureRecorder();
  final ui.Canvas toile = ui.Canvas(enregistreur);
  final Rect cadre = Rect.fromLTWH(0, 0, l.toDouble(), h.toDouble());
  toile.drawRect(
    cadre,
    Paint()
      ..shader = ui.Gradient.linear(cadre.topLeft, cadre.bottomRight, couleurs),
  );
  toile.drawCircle(
    Offset(l * 0.7, h * 0.3),
    l * 0.12,
    Paint()..color = const Color.fromARGB(220, 255, 255, 255),
  );
  toile.drawRect(
    Rect.fromLTWH(0, h * 0.72, l.toDouble(), h * 0.28),
    Paint()..color = const Color.fromARGB(90, 0, 0, 0),
  );
  final ui.Image image = await enregistreur.endRecording().toImage(l, h);
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

class _Source implements SourceImagesFil {
  _Source(this.octets);

  final Map<String, Uint8List> octets;

  AdresseImage _a(String id) => AdresseImage(
    url: 'demo:$id',
    expireLe: DateTime.now().add(const Duration(hours: 1)),
    octets: octets[id],
  );

  @override
  Future<Map<String, AdresseImage>> miniatures() async =>
      <String, AdresseImage>{for (final String id in octets.keys) id: _a(id)};

  @override
  Future<AdresseImage?> image(String imageId) async => _a(imageId);
}

MessageFil _m(
  String id,
  String auteur,
  String texte, {
  bool deSoi = false,
  ImageMessage? image,
  int coeurs = 0,
  bool aime = false,
  int minute = 0,
}) => MessageFil(
  id: id,
  auteur: auteur,
  texte: texte,
  horodatage: '10:0$minute',
  deSoi: deSoi,
  instant: DateTime.utc(2026, 11, 16, 10, minute),
  image: image,
  coeurs: coeurs,
  aimeParMoi: aime,
  remise: deSoi ? RemiseMessage.lu : null,
);

Widget _ecran({
  required List<MessageFil> messages,
  SourceImagesFil? images,
  bool groupe = true,
  bool pleinEcran = false,
  Future<Uint8List?> Function(SourceImage)? choisir,
  EnvoiImageFil? envoi,
}) => Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FilDiscussion(
        messages: messages,
        textes: textesFilCommunication(),
        afficherAuteur: groupe,
        // Le telephone (390) est la page plein ecran, sans phrase d'aide sous le
        // champ (FINITIONS-MESSAGERIE) ; le bureau garde le fil en colonne.
        pleinEcran: pleinEcran,
        onEnvoyer: (String _) async {},
        images: images,
        onAimer: (String id, bool aime) async =>
            EtatCoeur(coeurs: aime ? 1 : 0, aimeParMoi: aime),
        onEnvoyerImage: envoi == null
            ? null
            : (String _, String t, ImagePrete i, ProgressionImage p) =>
                  envoi(t, 'cle', i, p),
        choisirImage: choisir ?? (SourceImage _) async => null,
        deuxChoixPhoto: false,
        horloge: () => DateTime.utc(2026, 11, 16, 11),
      ),
    ),
  ),
);

Future<void> _moteur(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Uint8List portrait;
  late Uint8List paysage;

  setUpAll(() async {
    await chargerPolicesDuDepot();
    portrait = await _photo(800, 1200, const <Color>[
      Color(0xFF2E7D6B),
      Color(0xFFEFC24A),
    ]);
    paysage = await _photo(1600, 1000, const <Color>[
      Color(0xFF3B4C9B),
      Color(0xFFD9738A),
    ]);
  });

  final List<(String, Size, double, AppLocale)> vues =
      <(String, Size, double, AppLocale)>[
        ('390_fr', const Size(390, 844), 2, AppLocale.fr),
        ('390_ar', const Size(390, 844), 2, AppLocale.ar),
        ('1440_fr', const Size(1440, 900), 1, AppLocale.fr),
      ];

  group('IMAGES-MESSAGERIE', skip: sautSansCapture, () {
    for (final (String nom, Size taille, double densite, AppLocale langue)
        in vues) {
      testWidgets('fil avec images, image retiree, coeurs $nom', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, taille, densite);
        masquerRubanDebug();
        await tester.pumpWidget(
          hoteCapture(
            _ecran(
              pleinEcran: taille.width < 840,
              images: _Source(<String, Uint8List>{'p': portrait, 'l': paysage}),
              messages: <MessageFil>[
                _m(
                  'm1',
                  'Amina',
                  'La page 12, regardez ici',
                  image: const ImageMessage(
                    id: 'p',
                    largeur: 800,
                    hauteur: 1200,
                    couleurMoyenne: '#8aa05a',
                  ),
                  coeurs: 3,
                  minute: 1,
                ),
                _m(
                  'm2',
                  'Yacine',
                  '',
                  image: const ImageMessage(
                    id: 'l',
                    largeur: 1600,
                    hauteur: 1000,
                    couleurMoyenne: '#8a5a9a',
                  ),
                  coeurs: 1,
                  aime: true,
                  minute: 2,
                ),
                _m(
                  'm3',
                  'Vous',
                  'Merci, je la révise ce soir',
                  deSoi: true,
                  coeurs: 2,
                  minute: 3,
                ),
                _m(
                  'm4',
                  'Amina',
                  'Voici la page de la semaine dernière',
                  image: const ImageMessage(
                    id: 'x',
                    largeur: 1600,
                    hauteur: 1000,
                    etat: EtatImageMessage.supprimee,
                  ),
                  minute: 4,
                ),
              ],
            ),
          ),
        );
        await _moteur(tester);
        await capturer(tester, 'fil_$nom');
      });

      testWidgets('coeur seul, fil a deux $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, taille, densite);
        masquerRubanDebug();
        await tester.pumpWidget(
          hoteCapture(
            _ecran(
              pleinEcran: taille.width < 840,
              groupe: false,
              messages: <MessageFil>[
                _m(
                  'a',
                  'Amina',
                  'Bonjour, la leçon est prête',
                  coeurs: 1,
                  aime: true,
                ),
                _m('b', 'Vous', 'Merci !', deSoi: true, coeurs: 1, minute: 1),
              ],
            ),
          ),
        );
        await _moteur(tester);
        await capturer(tester, 'coeur_seul_$nom');
      });

      testWidgets('envoi en cours $nom', (WidgetTester tester) async {
        simulerPluginCompression();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, taille, densite);
        masquerRubanDebug();
        await tester.pumpWidget(
          hoteCapture(
            _ecran(
              pleinEcran: taille.width < 840,
              messages: const <MessageFil>[],
              choisir: (SourceImage _) async => paysage,
              envoi:
                  (
                    String texte,
                    String cle,
                    ImagePrete image,
                    ProgressionImage progression,
                  ) async {
                    progression(0.45);
                    await Completer<void>().future;
                  },
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(FilDiscussion.cleImage));
        await _moteur(tester);
        await capturer(tester, 'envoi_en_cours_$nom');
      });

      testWidgets('apercu en grand $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, taille, densite);
        masquerRubanDebug();
        await tester.pumpWidget(
          hoteCapture(
            _ecran(
              pleinEcran: taille.width < 840,
              images: _Source(<String, Uint8List>{'p': portrait}),
              messages: <MessageFil>[
                _m(
                  'm1',
                  'Amina',
                  'La page 12, regardez ici',
                  image: const ImageMessage(
                    id: 'p',
                    largeur: 800,
                    hauteur: 1200,
                  ),
                ),
              ],
            ),
          ),
        );
        await _moteur(tester);
        await tester.tap(find.byType(Image).first);
        await _moteur(tester);
        await capturer(tester, 'apercu_$nom');
      });
    }
  });
}
