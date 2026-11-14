// INCIDENT-CANDIDATS (14/11/2026) : un candidat dont la photo est deja
// enregistree au serveur le voit dit en mots, et le lien propose de la
// remplacer, jamais d'en « choisir » une comme si elle manquait.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

class _Candidat extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: 'p-candidat',
    accountStatus: AccountStatus.pendingKyc,
    lectureProfil: LectureProfil.presente,
  );
}

List<Override> _surcharges(String? url) => <Override>[
  sessionProvider.overrideWith(_Candidat.new),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  photoPersonneProvider.overrideWith(
    (Ref ref, String id) async => id == 'p-candidat' ? url : null,
  ),
];

const String _url = 'https://exemple.invalid/photo.jpg';

const Widget _editeur = Material(
  child: SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: EditeurPhotoPublique(prenom: ''),
  ),
);

Future<void> _monter(WidgetTester tester, {required String? url}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hote(_editeur, surcharges: _surcharges(url)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('photo deja au serveur : « enregistree » et « Remplacer »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, url: _url);
    expect(find.byKey(EditeurPhotoPublique.enregistreeKey), findsOneWidget);
    expect(find.text(t.enseignant.photo.enregistree), findsOneWidget);
    expect(find.text(t.enseignant.photo.remplacer), findsOneWidget);
    expect(find.text(t.enseignant.photo.choisir), findsNothing);
  });

  testWidgets('aucune photo : « Choisir une photo », rien d enregistre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, url: null);
    expect(find.byKey(EditeurPhotoPublique.enregistreeKey), findsNothing);
    expect(find.text(t.enseignant.photo.choisir), findsOneWidget);
  });

  // Captures R3 : CAPTURE_DIR=docs/current/captures/E2E/incident-candidats.
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, ThemeMode theme, AppLocale langue)
        in <(String, ThemeMode, AppLocale)>[
          ('photo-enregistree-390-clair', ThemeMode.light, AppLocale.fr),
          ('photo-enregistree-390-sombre', ThemeMode.dark, AppLocale.fr),
          ('photo-enregistree-390-arabe', ThemeMode.light, AppLocale.ar),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            _editeur,
            surcharges: _surcharges(_url),
            themeMode: theme,
          ),
        );
        await stabiliser(tester);
        await capturer(tester, nom);
      });
    }
  }, skip: sautSansCapture);
}
