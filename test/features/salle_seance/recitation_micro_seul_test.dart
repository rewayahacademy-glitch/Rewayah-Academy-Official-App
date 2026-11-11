// RECITATION-MICRO-SEUL (directeur, 11/11/2026, journal D-022) : pendant
// « Faire reciter », le serveur ferme le MICRO des camarades, pas leur camera.
// A l'ecran d'un camarade : pas de bouton de micro (un bouton qui ne peut pas
// aboutir n'est pas rendu), la phrase « Votre micro est fermé pendant que …
// récite. », et le bouton de la camera, qui marche. Un eleve dont le profil
// interdit la camera n'a ni l'un ni l'autre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/video/publication_differee.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/seance_demo.dart';

const String _phrase = 'Votre micro est fermé pendant que Yasmine récite.';
const String _phraseTu = 'Ton micro est fermé pendant que Yasmine récite.';
const String _phraseGuidee = 'Yasmine récite. Ton micro attend.';

final Finder _statut = find.byKey(
  const ValueKey<String>('statut-micro-en-attente'),
);
final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));
final Finder _boutonMicro = find.byKey(const ValueKey<String>('bouton-micro'));

/// Le bouton de la camera du dock, allumee ou eteinte.
final Finder _boutonCamera = find.byWidgetPredicate(
  (Widget w) =>
      w is BoutonAppel &&
      (w.icone == AppIcons.camera || w.icone == AppIcons.cameraCoupee),
);

AccesSalle _acces({required bool camera}) =>
    AccesSalle.depuisJson(<String, dynamic>{
      'ws_url': 'wss://exemple',
      'token': 'jeton',
      'room_name': 'salle',
      'provider': 'cloud',
      'role': 'student',
      'expire_le': '2026-11-11T18:05:00Z',
      'capabilities': <String, dynamic>{
        'can_publish': true,
        'can_publish_video': camera,
        'can_publish_data': false,
        'can_subscribe': true,
        'hidden': false,
      },
    });

VueSalle _salle(AccesSalle acces) => VueSalle.depuis(
  materielPret: true,
  acces: acces,
  etatMoteur: EtatSalle.connecte,
  participants: const <ParticipantSalle>[],
  qualite: QualiteLien.bonne,
);

/// Ce que le serveur accorde a un camarade pendant la recitation : la liste
/// des sources que LiveKit annonce, lue comme le fait le moteur.
AccesSalle _pendantRecitation(AccesSalle avant, {required bool camera}) {
  final ({bool micro, bool camera}) droits = droitsAccordes(
    peutPublier: camera,
    sources: camera ? const <String>['CAMERA'] : const <String>[],
  );
  return accesApresPermissions(
    avant,
    peutPublier: camera,
    micro: droits.micro,
    camera: droits.camera,
  )!;
}

VueSeance _vue(
  RoleSeance role, {
  bool camera = true,
  bool? tutoiement = false,
}) => DonneesSeanceDemo.vue(role, EtatDemoSalle.repos).copyWith(
  microEnAttente: true,
  recitantPrenom: 'Yasmine',
  cameraAutorisee: camera,
  tutoiement: tutoiement,
);

Future<void> _monter(
  WidgetTester tester,
  VueSeance vue, {
  required bool peutMontrer,
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
  bool cameraAllumee = true,
  VoidCallback? onCamera,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(
        vue: vue,
        local: EtatLocalSeance(
          microOuvert: false,
          cameraAllumee: cameraAllumee,
        ),
        // Comme `/salle` les pose : le micro suit `peutParler` (faux pendant
        // la recitation), la camera suit `peutMontrer`.
        actions: ActionsSeance(
          onRetour: () {},
          onQuitter: () {},
          onCamera: peutMontrer ? (onCamera ?? () {}) : null,
        ),
      ),
      echelleTexte: echelleTexte,
      interfaceMode: vue.role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await stabiliser(tester);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('la vue lit le droit du serveur, source par source', () {
    test('camarade avec camera : pas de micro, la camera reste', () {
      final VueSalle salle = _salle(
        _pendantRecitation(_acces(camera: true), camera: true),
      );
      expect(salle.peutParler, isFalse);
      expect(salle.peutMontrer, isTrue);
      expect(salle.microEnAttente, isTrue);
      final VueSeance seance = DepuisSalle.vue(
        salle: salle,
        mode: InterfaceMode.standard,
      )!;
      expect(seance.microEnAttente, isTrue);
      expect(seance.cameraAutorisee, isTrue);
      expect(seance.commandesDock, contains(CommandeDock.camera));
    });

    test('camera interdite par le profil : ni micro ni camera', () {
      final VueSalle salle = _salle(
        _pendantRecitation(_acces(camera: false), camera: false),
      );
      expect(salle.peutParler, isFalse);
      expect(salle.peutMontrer, isFalse);
      expect(salle.microEnAttente, isTrue);
      final VueSeance seance = DepuisSalle.vue(
        salle: salle,
        mode: InterfaceMode.standard,
      )!;
      expect(seance.commandesDock, isNot(contains(CommandeDock.camera)));
      // La phrase du profil ne se dit pas en meme temps que celle du micro.
      expect(seance.texteCameraInterdite, isNull);
    });

    test('la recitation finie : le bouton du micro revient', () {
      final AccesSalle pendant = _pendantRecitation(
        _acces(camera: true),
        camera: true,
      );
      final AccesSalle apres = accesApresPermissions(
        pendant,
        peutPublier: true,
        micro: true,
        camera: true,
      )!;
      final VueSalle salle = _salle(apres);
      expect(salle.peutParler, isTrue);
      expect(salle.peutMontrer, isTrue);
      expect(salle.microEnAttente, isFalse);
    });
  });

  group('la phrase dit la vraie raison', () {
    test('vouvoiement, tutoiement, Interface guidee', () {
      expect(_vue(RoleSeance.eleve).texteMicroEnAttente, _phrase);
      expect(
        _vue(RoleSeance.eleve, tutoiement: true).texteMicroEnAttente,
        _phraseTu,
      );
      expect(_vue(RoleSeance.guidee).texteMicroEnAttente, _phraseGuidee);
    });
  });

  group('dans la salle d\'un camarade, pendant la recitation', () {
    for (final (Size taille, String nom) in <(Size, String)>[
      (const Size(390, 844), '390'),
      (const Size(1440, 900), '1440'),
    ]) {
      testWidgets('$nom : la phrase, pas de bouton micro, la camera marche', (
        WidgetTester tester,
      ) async {
        int appuis = 0;
        await _monter(
          tester,
          _vue(RoleSeance.eleve),
          peutMontrer: true,
          taille: taille,
          onCamera: () => appuis++,
        );
        expect(find.text(_phrase), findsOneWidget);
        expect(_statut, findsOneWidget);
        expect(
          tester.getBottomLeft(_statut).dy,
          lessThanOrEqualTo(tester.getTopLeft(_dock).dy),
        );
        expect(_boutonMicro, findsNothing);
        // Le bouton de la camera est la, montre allumee, et il repond.
        expect(_boutonCamera, findsOneWidget);
        expect(tester.widget<BoutonAppel>(_boutonCamera).bascule, isTrue);
        expect(tester.widget<BoutonAppel>(_boutonCamera).actif, isTrue);
        await tester.tap(_boutonCamera);
        await tester.pump();
        expect(appuis, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('camera interdite par le profil : ni micro ni camera, la '
        'phrase seule', (WidgetTester tester) async {
      await _monter(
        tester,
        _vue(RoleSeance.eleve, camera: false),
        peutMontrer: false,
      );
      expect(find.text(_phrase), findsOneWidget);
      expect(_boutonMicro, findsNothing);
      expect(_boutonCamera, findsNothing);
      expect(find.byType(StatutCameraInterdite), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 et texte x2 : la phrase reflue, la camera reste', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _vue(RoleSeance.eleve),
        peutMontrer: true,
        taille: const Size(320, 700),
        echelleTexte: 2,
      );
      expect(find.text(_phrase), findsOneWidget);
      expect(_boutonCamera, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Interface guidee : la phrase courte, la camera reste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _vue(RoleSeance.guidee), peutMontrer: true);
      expect(find.text(_phraseGuidee), findsOneWidget);
      expect(_boutonMicro, findsNothing);
      expect(_boutonCamera, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
