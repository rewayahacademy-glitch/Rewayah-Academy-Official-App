// Captures R3 du lot IMAGES-CORRECTIF : l'envoi en cours, l'echec avec
// « Reessayer » et « Supprimer », le fil apres l'envoi (une seule bulle), un
// message arrive apres une bulle en echec, et le fil du destinataire (photo
// seule, sans texte). Sautees sans `CAPTURE_DIR` (voir `LISEZ-MOI.md`).

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
  DateTime? horloge,
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
        horloge: () => horloge ?? DateTime.utc(2026, 11, 16, 11),
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
  late Uint8List paysage;

  setUpAll(() async {
    await chargerPolicesDuDepot();
    paysage = await _photo(1600, 1000, const <Color>[
      Color(0xFF3B4C9B),
      Color(0xFFD9738A),
    ]);
  });

  final List<(String, Size, double, AppLocale)> vues =
      <(String, Size, double, AppLocale)>[
        ('390_fr', const Size(390, 844), 2, AppLocale.fr),
        ('390_ar', const Size(390, 844), 2, AppLocale.ar),
      ];

  const ImageMessage grande = ImageMessage(
    id: 'l',
    largeur: 1600,
    hauteur: 1000,
    couleurMoyenne: '#8a5a9a',
  );

  group('IMAGES-CORRECTIF', skip: sautSansCapture, () {
    for (final (String nom, Size taille, double densite, AppLocale langue)
        in vues) {
      Future<void> preparer(WidgetTester tester) async {
        simulerPluginCompression();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, taille, densite);
        masquerRubanDebug();
      }

      Widget monter({
        required List<MessageFil> messages,
        required EnvoiImageFil envoi,
        DateTime? horloge,
      }) => hoteCapture(
        _ecran(
          pleinEcran: true,
          messages: messages,
          images: _Source(<String, Uint8List>{'l': paysage}),
          choisir: (SourceImage _) async => paysage,
          envoi: envoi,
          horloge: horloge,
        ),
      );

      MessageFil copie({required EtatImageMessage etat}) => _m(
        'srv-1',
        'Vous',
        '[image]',
        deSoi: true,
        minute: 5,
        image: ImageMessage(
          id: 'l',
          largeur: grande.largeur,
          hauteur: grande.hauteur,
          couleurMoyenne: grande.couleurMoyenne,
          etat: etat,
        ),
      );

      final MessageFil avant = _m(
        'a',
        'Amina',
        'Envoyez-moi la page 12 en photo',
        minute: 1,
      );

      testWidgets('envoi en cours : une seule bulle $nom', (
        WidgetTester tester,
      ) async {
        await preparer(tester);
        await tester.pumpWidget(
          monter(
            messages: <MessageFil>[avant],
            envoi:
                (String _, String _, ImagePrete _, ProgressionImage p) async {
                  p.messageCree('srv-1');
                  p(0.45);
                  await Completer<void>().future;
                },
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(FilDiscussion.cleImage));
        await _moteur(tester);
        await tester.pumpWidget(
          monter(
            messages: <MessageFil>[
              avant,
              copie(etat: EtatImageMessage.enAttente),
            ],
            envoi: (
              String _,
              String _,
              ImagePrete _,
              ProgressionImage _,
            ) async {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await capturer(tester, 'envoi_en_cours_$nom');
      });

      testWidgets('echec avec Reessayer et Supprimer $nom', (
        WidgetTester tester,
      ) async {
        await preparer(tester);
        await tester.pumpWidget(
          monter(
            messages: <MessageFil>[avant],
            envoi:
                (String _, String _, ImagePrete _, ProgressionImage p) async {
                  p.messageCree('srv-1');
                  throw const EchecImage(RefusImage.envoiStockage);
                },
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(FilDiscussion.cleImage));
        await _moteur(tester);
        await tester.pumpAndSettle();
        await capturer(tester, 'echec_$nom');
        await tester.tap(find.byKey(FilDiscussion.cleLigneEchec));
        await tester.pumpAndSettle();
        await capturer(tester, 'echec_menu_$nom');
      });

      testWidgets('un message arrive apres la bulle en echec $nom', (
        WidgetTester tester,
      ) async {
        await preparer(tester);
        Widget fil(List<MessageFil> messages) => monter(
          // La bulle est envoyee a 10 h 10 : le message de 10 h 30 passe dessous.
          horloge: DateTime.utc(2026, 11, 16, 10, 10),
          messages: messages,
          envoi: (String _, String _, ImagePrete _, ProgressionImage _) async =>
              throw const EchecImage(RefusImage.envoiStockage),
        );
        await tester.pumpWidget(fil(<MessageFil>[avant]));
        await tester.pump();
        await tester.tap(find.byKey(FilDiscussion.cleImage));
        await _moteur(tester);
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          fil(<MessageFil>[
            avant,
            _m(
              'b',
              'Amina',
              'Pas de souci, envoyez quand vous pouvez',
              minute: 30,
            ),
          ]),
        );
        await tester.pumpAndSettle();
        await capturer(tester, 'echec_ordre_$nom');
      });

      testWidgets('apres l\'envoi : une seule bulle $nom', (
        WidgetTester tester,
      ) async {
        await preparer(tester);
        await tester.pumpWidget(
          monter(
            messages: <MessageFil>[avant],
            envoi:
                (String _, String _, ImagePrete _, ProgressionImage p) async {
                  p.messageCree('srv-1');
                },
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(FilDiscussion.cleImage));
        await _moteur(tester);
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          monter(
            messages: <MessageFil>[
              avant,
              copie(etat: EtatImageMessage.confirmee),
            ],
            envoi: (
              String _,
              String _,
              ImagePrete _,
              ProgressionImage _,
            ) async {},
          ),
        );
        await _moteur(tester);
        await capturer(tester, 'apres_envoi_$nom');
      });

      testWidgets('cote destinataire : photo seule, sans texte $nom', (
        WidgetTester tester,
      ) async {
        await preparer(tester);
        await tester.pumpWidget(
          hoteCapture(
            _ecran(
              pleinEcran: true,
              images: _Source(<String, Uint8List>{'l': paysage}),
              messages: <MessageFil>[
                _m(
                  'a',
                  'Vous',
                  'Envoyez-moi la page 12 en photo',
                  deSoi: true,
                  minute: 1,
                ),
                _m('srv-1', 'Amina', '[image]', image: grande, minute: 5),
              ],
            ),
          ),
        );
        await _moteur(tester);
        await capturer(tester, 'destinataire_$nom');
      });
    }
  });
}
