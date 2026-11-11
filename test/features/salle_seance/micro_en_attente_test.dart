// MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026, defaut SEC-1) : tant que
// l'enseignant n'est pas dans la salle, le serveur refuse le micro d'un
// eleve. A l'ecran : le bouton du micro n'est pas rendu (un bouton qui ne peut
// pas aboutir n'est pas rendu), une phrase courte et douce dit pourquoi ; le
// droit rendu, le bouton apparait et le micro reste ferme.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
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

const String _vous = 'Votre micro s\'ouvrira quand votre enseignant sera là.';
const String _tu = 'Ton micro s\'ouvrira quand ton enseignant sera là.';
const String _guidee = 'Ton micro attend ton enseignant.';

final Finder _statut = find.byKey(
  const ValueKey<String>('statut-micro-en-attente'),
);
final Finder _dock = find.byKey(const ValueKey<String>('dock-seance'));
final Finder _boutonMicro = find.byKey(const ValueKey<String>('bouton-micro'));

AccesSalle _acces({bool differee = true, String role = 'student'}) =>
    AccesSalle.depuisJson(<String, dynamic>{
      'ws_url': 'wss://exemple',
      'token': 'jeton',
      'room_name': 'salle',
      'provider': 'cloud',
      'role': role,
      'expire_le': '2026-11-11T18:05:00Z',
      'capabilities': const <String, dynamic>{
        'can_publish': true,
        'can_publish_video': false,
        'can_publish_data': false,
        'can_subscribe': true,
        'hidden': false,
      },
      'publication_differee': differee,
    });

VueSalle _salle(AccesSalle acces) => VueSalle.depuis(
  materielPret: true,
  acces: acces,
  etatMoteur: EtatSalle.connecte,
  participants: const <ParticipantSalle>[],
  qualite: QualiteLien.bonne,
);

VueSeance _vue(RoleSeance role, {bool attente = true, bool? tutoiement}) =>
    DonneesSeanceDemo.vue(
      role,
      EtatDemoSalle.repos,
    ).copyWith(microEnAttente: attente, tutoiement: tutoiement);

/// Les commandes telles que la salle les pose : le micro suit le droit.
ActionsSeance _actions({required bool peutParler, VoidCallback? onMicro}) =>
    ActionsSeance(
      onRetour: () {},
      onQuitter: () {},
      onMicro: peutParler ? (onMicro ?? () {}) : null,
    );

Future<void> _monter(
  WidgetTester tester,
  VueSeance vue, {
  required bool peutParler,
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
  VoidCallback? onMicro,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(
        vue: vue,
        local: const EtatLocalSeance(microOuvert: false),
        actions: _actions(peutParler: peutParler, onMicro: onMicro),
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

  group('la vue lit le droit du serveur', () {
    test('jeton differe : pas de bouton, la salle le sait', () {
      final VueSalle salle = _salle(_acces());
      expect(salle.peutParler, isFalse);
      expect(salle.peutMontrer, isFalse);
      expect(salle.microEnAttente, isTrue);
      final VueSeance? seance = DepuisSalle.vue(
        salle: salle,
        mode: InterfaceMode.standard,
      );
      expect(seance?.microEnAttente, isTrue);
    });

    test('le serveur rend le droit : le bouton revient, plus de phrase', () {
      final AccesSalle rendu = accesApresPermissions(
        _acces(),
        peutPublier: true,
        camera: false,
      )!;
      final VueSalle salle = _salle(rendu);
      expect(salle.peutParler, isTrue);
      expect(salle.microEnAttente, isFalse);
      expect(
        DepuisSalle.vue(
          salle: salle,
          mode: InterfaceMode.standard,
        )?.texteMicroEnAttente,
        isNull,
      );
    });

    test('jeton ordinaire : rien ne change', () {
      final VueSalle salle = _salle(_acces(differee: false));
      expect(salle.peutParler, isTrue);
      expect(salle.microEnAttente, isFalse);
    });
  });

  group('la phrase', () {
    test('adulte : vouvoiement', () {
      expect(
        _vue(RoleSeance.eleve, tutoiement: false).texteMicroEnAttente,
        _vous,
      );
    });

    test('enfant en interface standard : tutoiement', () {
      expect(_vue(RoleSeance.eleve, tutoiement: true).texteMicroEnAttente, _tu);
    });

    test('Interface guidee : la phrase courte', () {
      expect(_vue(RoleSeance.guidee).texteMicroEnAttente, _guidee);
      expect(_guidee.length, lessThan(_tu.length));
    });

    test('sans attente, ou pour l\'enseignant : aucune phrase', () {
      expect(
        _vue(RoleSeance.eleve, attente: false).texteMicroEnAttente,
        isNull,
      );
      expect(_vue(RoleSeance.enseignant).texteMicroEnAttente, isNull);
    });

    test('en attente, « Caméra désactivée pour ce profil. » ne se dit pas', () {
      final VueSeance vue = _vue(RoleSeance.eleve)
          .copyWith(cameraAutorisee: false);
      expect(vue.texteCameraInterdite, isNull);
      expect(
        vue.copyWith(microEnAttente: false).texteCameraInterdite,
        isNotNull,
      );
    });

    test('arabe : les phrases existent', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(
        _vue(RoleSeance.eleve, tutoiement: false).texteMicroEnAttente,
        'سيُفتح ميكروفونك عند حضور معلمك.',
      );
      expect(
        _vue(RoleSeance.guidee).texteMicroEnAttente,
        'ميكروفونك ينتظر معلمك.',
      );
    });
  });

  group('dans la salle de l\'eleve', () {
    for (final (Size taille, String nom) in <(Size, String)>[
      (const Size(390, 844), '390'),
      (const Size(1440, 900), '1440'),
    ]) {
      testWidgets('$nom : la phrase, au-dessus du dock, sans bouton micro', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          _vue(RoleSeance.eleve, tutoiement: false),
          peutParler: false,
          taille: taille,
        );
        expect(find.text(_vous), findsOneWidget);
        expect(_statut, findsOneWidget);
        expect(
          tester.getBottomLeft(_statut).dy,
          lessThanOrEqualTo(tester.getTopLeft(_dock).dy),
        );
        // Le bouton du micro n'est pas rendu, ni ouvert ni coupe.
        expect(_boutonMicro, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('320 et texte x2 : la phrase reflue, rien ne deborde', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _vue(RoleSeance.eleve, tutoiement: false),
        peutParler: false,
        taille: const Size(320, 700),
        echelleTexte: 2,
      );
      expect(find.text(_vous), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lue par le lecteur d\'ecran, sans action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _monter(
        tester,
        _vue(RoleSeance.eleve, tutoiement: false),
        peutParler: false,
      );
      final SemanticsNode noeud = tester.getSemantics(find.text(_vous));
      expect(noeud.label, _vous);
      expect(noeud.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      poignee.dispose();
    });

    testWidgets('Interface guidee : la phrase courte', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _vue(RoleSeance.guidee), peutParler: false);
      expect(find.text(_guidee), findsOneWidget);
      expect(find.text(_tu), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le droit arrive : le bouton apparait, le micro reste ferme', (
      WidgetTester tester,
    ) async {
      int appuis = 0;
      await _monter(
        tester,
        _vue(RoleSeance.eleve, attente: false, tutoiement: false),
        peutParler: true,
        onMicro: () => appuis++,
      );
      expect(_statut, findsNothing);
      expect(find.text(_vous), findsNothing);
      // Le bouton est la, montre coupe : rien ne s'est ouvert seul.
      expect(_boutonMicro, findsOneWidget);
      expect(tester.widget<BoutonAppel>(_boutonMicro).bascule, isFalse);
      expect(appuis, 0);
      // Et c'est l'eleve qui l'ouvre.
      await tester.tap(_boutonMicro);
      await tester.pump();
      expect(appuis, 1);
    });

    testWidgets('l\'enseignant ne lit jamais la phrase', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _vue(RoleSeance.enseignant),
        peutParler: true,
        taille: const Size(1440, 900),
      );
      expect(_statut, findsNothing);
      expect(find.byType(StatutMicroEnAttente), findsNothing);
    });
  });
}
