// VISAGES (directeur, 12/11/2026, points 7, 8 et 9) : captures de TEST de la
// grille de la Classe, rendue par la vraie page `/salle` (`SallePage`) et le
// faux moteur du harnais : un enseignant qui parle (camera allumee : l'image
// du faux moteur est un aplat vide, la lumiere se voit sur le fond du
// cadre), une eleve avec photo (image de test servie en local), un eleve
// sans photo (sa couleur et son initiale), soi-meme. Le fond doux est
// derriere la grille. Les vagues sont figees (`HaloLumiere.boucleVoix`).
// Ce n'est pas la vraie application : la preuve qui fait foi reste le banc.
//
// CAPTURE_DIR=docs/current/captures/E2E/visages \
//   flutter test test/capture/visages_capture_test.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/grille_visages.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';
import 'outil_capture.dart';

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'student',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: false,
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

/// Une photo de test (pas un vrai visage) : un buste stylise sur un fond
/// doux, encode en PNG.
Future<Uint8List> _photoDeTest() async {
  const double cote = 256;
  final ui.PictureRecorder enregistreur = ui.PictureRecorder();
  Canvas(enregistreur)
    ..drawRect(
      const Rect.fromLTWH(0, 0, cote, cote),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF9FC6D8), Color(0xFF5D8AA8)],
        ).createShader(const Rect.fromLTWH(0, 0, cote, cote)),
    )
    ..drawOval(
      const Rect.fromLTWH(40, 170, 176, 150),
      Paint()..color = const Color(0xFF2F3E5C),
    )
    ..drawCircle(
      const Offset(128, 110),
      58,
      Paint()..color = const Color(0xFFC99A74),
    )
    ..drawArc(
      const Rect.fromLTWH(66, 46, 124, 110),
      3.3,
      2.9,
      true,
      Paint()..color = const Color(0xFF3A2A22),
    );
  final ui.Image image = await enregistreur.endRecording().toImage(
    cote.toInt(),
    cote.toInt(),
  );
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

/// Le port des photos du test : seule Yasmine (e0) a une photo ; le
/// serveur ne rend rien pour les autres (comme un eleve sans photo, ou une
/// photo que l'appelant n'a pas le droit de voir).
class _Photos extends PhotosNeutres {
  const _Photos(this.url);

  final String url;

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) async =>
      <String, SourcePhoto>{
        if (profileIds.contains('e0'))
          'e0': const SourcePhoto(seau: 'avatars', cle: 'e0.png'),
      };

  @override
  Future<String> urlSignee(String seau, String cle) async => url;

  @override
  Future<String> televerser({
    required String profileId,
    required String seau,
    required PhotoEnfant photo,
  }) => Future<String>.error(UnsupportedError('test'));
}

List<ParticipantSalle> _classe() => const <ParticipantSalle>[
  ParticipantSalle(
    identite: 't1',
    nom: 'Omar',
    role: 'teacher',
    estLocal: false,
    micro: true,
    camera: true,
    parle: true,
    qualite: QualiteLien.bonne,
  ),
  ParticipantSalle(
    identite: 'e0',
    nom: 'Yasmine',
    role: 'student',
    estLocal: false,
    micro: true,
    camera: false,
    parle: false,
    qualite: QualiteLien.bonne,
  ),
  ParticipantSalle(
    identite: 'e1',
    nom: 'Ilyes',
    role: 'student',
    estLocal: false,
    micro: false,
    camera: false,
    parle: false,
    qualite: QualiteLien.bonne,
  ),
  ParticipantSalle(
    identite: 'e2',
    nom: 'Maryam',
    role: 'student',
    estLocal: false,
    micro: true,
    camera: false,
    parle: false,
    qualite: QualiteLien.bonne,
  ),
  ParticipantSalle(
    identite: 'e3',
    nom: 'Khadija',
    role: 'student',
    estLocal: true,
    micro: true,
    camera: true,
    parle: false,
    qualite: QualiteLien.bonne,
  ),
];

void main() {
  HttpServer? serveur;
  String url = '';

  group('Capture : VISAGES', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      final Uint8List photo = await _photoDeTest();
      final HttpServer s = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      s.listen((HttpRequest r) async {
        r.response.headers.contentType = ContentType('image', 'png');
        r.response.add(photo);
        await r.response.close();
      });
      serveur = s;
      url = 'http://127.0.0.1:${s.port}/e0.png';
    });
    tearDownAll(() async => serveur?.close(force: true));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size taille, String nomTaille) in const <(Size, String)>[
      (Size(390, 844), '390'),
      (Size(1440, 900), '1440'),
    ]) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nomTheme = theme == ThemeMode.dark ? 'sombre' : 'clair';
        testWidgets('grille $nomTaille $nomTheme', (WidgetTester tester) async {
          // La photo de test est servie en local : le client factice de
          // flutter_test repondrait 400.
          HttpOverrides.global = null;
          fixerVueCapture(tester, taille, taille.width < 600 ? 2 : 1);
          final FauxMoteurSalle moteur = FauxMoteurSalle()
            ..avecImage.addAll(<String>['t1', 'e3']);
          await tester.pumpWidget(
            hoteCapture(
              const SallePage(seanceId: 's1'),
              surcharges: <Override>[
                sourceSessionProvider.overrideWithValue(
                  FausseSourceSession(
                    const SessionState(
                      resolue: true,
                      role: AppRole.student,
                      profileId: 'e3',
                      accountStatus: AccountStatus.active,
                      lectureProfil: LectureProfil.presente,
                    ),
                  ),
                ),
                servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
                serviceVideoProvider.overrideWithValue(
                  FauxServiceVideo(acces0: _acces()),
                ),
                moteurSalleProvider.overrideWithValue(moteur),
                servicePresenceProvider.overrideWithValue(
                  FauxServicePresence(),
                ),
                portAnnonceObservationEnfantProvider.overrideWithValue(
                  FauxAnnonceObservationEnfant(observe: false),
                ),
                portAnnonceObservationProvider.overrideWithValue(
                  FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
                ),
                portPhotosProvider.overrideWithValue(_Photos(url)),
              ],
              themeMode: theme,
            ),
          );
          await tester.pumpAndSettle();
          moteur.publier(_classe());
          await tester.pumpAndSettle();
          // La photo arrive par le reseau local : de vraies attentes.
          for (int i = 0; i < 5; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 200)),
            );
            await tester.pump();
          }
          await tester.pumpAndSettle();
          expect(find.byKey(GrilleVisages.cle), findsOneWidget);
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'visages_grille_${nomTaille}_$nomTheme')}',
          );
          // La salle partie, ses minuteries s'arretent ; la connexion HTTP
          // de la photo de test garde 15 s de repos avant de se fermer.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 16));
        });
      }
    }
  });
}
