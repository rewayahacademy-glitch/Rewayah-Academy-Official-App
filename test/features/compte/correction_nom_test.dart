// NOM-PROPRE (INCIDENT-CANDIDATS, 14/11/2026) : la regle du nom propre, le
// garde a l'ouverture et l'ecran court de correction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/identite/nom_propre.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/compte/correction_nom.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

class _Candidate extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: 'p-candidate',
    accountStatus: AccountStatus.pendingKyc,
    lectureProfil: LectureProfil.presente,
  );
}

class _FauxPort implements PortNomPropre {
  _FauxPort({required this.etat, this.erreur});

  EtatNomPropre etat;
  Exception? erreur;
  final List<(String, String)> corrections = <(String, String)>[];

  @override
  Future<EtatNomPropre> lire() async => etat;

  @override
  Future<void> corriger({required String prenom, required String nom}) async {
    corrections.add((prenom, nom));
    final Exception? e = erreur;
    if (e != null) throw e;
    etat = EtatNomPropre(aCorriger: false, prenom: prenom, nom: nom);
  }
}

const Key _app = Key('application');

List<Override> _surcharges(_FauxPort port) => <Override>[
  sessionProvider.overrideWith(_Candidate.new),
  portNomPropreProvider.overrideWithValue(port),
];

const Widget _garde = GardeNomPropre(
  child: Scaffold(body: Text('application', key: _app)),
);

Future<void> _monter(WidgetTester tester, _FauxPort port) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hote(_garde, surcharges: _surcharges(port)));
  await tester.pumpAndSettle();
}

void main() {
  group('la regle', () {
    test('lettres de toutes ecritures, harakat, apostrophes acceptees', () {
      for (final String v in <String>[
        'مُحَمَّد',
        'عبد الله',
        "Zoë-Anne d'Arc",
        'O’Neil',
        'Lê Văn',
        ' Asma ',
      ]) {
        expect(nomPropreValide(v), isTrue, reason: v);
      }
    });

    test('chiffres, une seule lettre, signes, emoji refuses', () {
      for (final String v in <String>[
        '٠',
        '١٢٣',
        'Ali2',
        'A',
        '..',
        '😀ab',
        '',
        '   ',
      ]) {
        expect(nomPropreValide(v), isFalse, reason: v);
      }
    });
  });

  group('le garde', () {
    testWidgets('nom juste : l application, rien d autre', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(etat: const EtatNomPropre(aCorriger: false)),
      );
      expect(find.byKey(_app), findsOneWidget);
      expect(find.text(t.inscription.nomPropre.titre), findsNothing);
    });

    testWidgets('nom « ٠ » : l ecran de correction, champs vides', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(
          etat: const EtatNomPropre(aCorriger: true, prenom: '٠', nom: '٠'),
        ),
      );
      expect(find.byKey(_app), findsNothing);
      expect(find.text(t.inscription.nomPropre.titre), findsOneWidget);
      expect(find.text(t.inscription.commeSurLaPiece), findsOneWidget);
      expect(find.text('٠'), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('un chiffre : la phrase sous le champ, rien n est envoye', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(
        etat: const EtatNomPropre(aCorriger: true, prenom: '٠', nom: '٠'),
      );
      await _monter(tester, port);
      await tester.enterText(find.byKey(CorrectionNomPage.prenomKey), 'Asma2');
      await tester.enterText(find.byKey(CorrectionNomPage.nomKey), 'Jamil');
      await tester.tap(find.byKey(CorrectionNomPage.enregistrerKey));
      await tester.pumpAndSettle();
      expect(find.text(t.inscription.nomEnLettresPrenom), findsOneWidget);
      expect(port.corrections, isEmpty);
    });

    testWidgets('nom corrige : envoye, puis l application', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(
        etat: const EtatNomPropre(aCorriger: true, prenom: '٠', nom: '٠'),
      );
      await _monter(tester, port);
      await tester.enterText(find.byKey(CorrectionNomPage.prenomKey), 'أسماء');
      await tester.enterText(find.byKey(CorrectionNomPage.nomKey), 'جميل');
      await tester.tap(find.byKey(CorrectionNomPage.enregistrerKey));
      await tester.pumpAndSettle();
      expect(port.corrections, <(String, String)>[('أسماء', 'جميل')]);
      expect(find.byKey(_app), findsOneWidget);
    });

    testWidgets('envoi non confirme : la phrase K-59, l ecran reste', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(
        etat: const EtatNomPropre(aCorriger: true, prenom: '٠', nom: '٠'),
        erreur: Exception('coupure'),
      );
      await _monter(tester, port);
      await tester.enterText(find.byKey(CorrectionNomPage.prenomKey), 'Asma');
      await tester.enterText(find.byKey(CorrectionNomPage.nomKey), 'Jamil');
      await tester.tap(find.byKey(CorrectionNomPage.enregistrerKey));
      await tester.pumpAndSettle();
      expect(find.text(t.inscription.nomPropre.nonConfirme), findsOneWidget);
      expect(find.byKey(_app), findsNothing);
    });
  });

  // Captures R3 : CAPTURE_DIR=docs/current/captures/E2E/incident-candidats.
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, ThemeMode theme, AppLocale langue)
        in <(String, ThemeMode, AppLocale)>[
          ('correction-nom-390-clair', ThemeMode.light, AppLocale.fr),
          ('correction-nom-390-sombre', ThemeMode.dark, AppLocale.fr),
          ('correction-nom-390-arabe', ThemeMode.light, AppLocale.ar),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            _garde,
            surcharges: _surcharges(
              _FauxPort(
                etat: const EtatNomPropre(
                  aCorriger: true,
                  prenom: '٠',
                  nom: '٠',
                ),
              ),
            ),
            themeMode: theme,
          ),
        );
        await stabiliser(tester);
        await capturer(tester, nom);
      });
    }
  }, skip: sautSansCapture);
}
