// ONBOARDING-BOUCLE (directeur, 14/11/2026) : le code a 6 chiffres du courriel
// de connexion, saisi dans le meme navigateur, ouvre la session ; un
// questionnaire deja rempli sur l'appareil se dit sur la creation du compte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/saisie_code_courriel.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart'
    show UsageInscription;
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';
import 'package:rewayah_academy/features/parcours_offres/libelles_parcours.dart'
    show MomentJournee;
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../support/harnais.dart';

class _Repondu extends QuestionnaireControleur {
  @override
  QuestionnaireInscription build() => const QuestionnaireInscription(
    usage: UsageInscription.moi,
    niveauTitulaire: NiveauDeclare.lectureLente,
    objectif: ObjectifApprentissage.memoriser,
    moments: <MomentJournee>{MomentJournee.soir},
    langue: 'francais',
  );
}

Future<void> _monter(
  WidgetTester tester,
  FauxServiceAuth auth, {
  ModeConnexion mode = ModeConnexion.connexion,
  bool repondu = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    hote(
      ConnexionPage(mode: mode),
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(auth),
        demoAuthActiveProvider.overrideWithValue(false),
        environnementConnexionProvider.overrideWithValue('production'),
        if (repondu)
          questionnaireInscriptionProvider.overrideWith(_Repondu.new),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _envoyerLeLien(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('connexion-courriel')),
    'famille@exemple.com',
  );
  await tester.pump();
  await tester.tap(find.text(t.connexion.envoyerLien));
  await tester.pumpAndSettle();
}

void main() {
  test('chiffresDuCode ne garde que six chiffres', () {
    expect(chiffresDuCode('123 456'), '123456');
    expect(chiffresDuCode('12-34-56-78'), '123456');
    expect(chiffresDuCode('ab1'), '1');
    expect(chiffresDuCode(''), '');
  });

  testWidgets('le code saisi ouvre la session dans ce navigateur', (
    WidgetTester tester,
  ) async {
    final FauxServiceAuth auth = FauxServiceAuth();
    await _monter(tester, auth);
    await _envoyerLeLien(tester);
    expect(find.byKey(SaisieCodeCourriel.cleChamp), findsOneWidget);

    await tester.enterText(find.byKey(SaisieCodeCourriel.cleChamp), '123 456');
    await tester.pump();
    await tester.ensureVisible(find.byKey(SaisieCodeCourriel.cleBouton));
    await tester.tap(find.byKey(SaisieCodeCourriel.cleBouton));
    await tester.pumpAndSettle();

    expect(auth.codesVerifies, hasLength(1));
    expect(auth.codesVerifies.single.courriel, 'famille@exemple.com');
    expect(auth.codesVerifies.single.code, '123456');
  });

  testWidgets('un code trop court dit ce qui manque, sans appel', (
    WidgetTester tester,
  ) async {
    final FauxServiceAuth auth = FauxServiceAuth();
    await _monter(tester, auth);
    await _envoyerLeLien(tester);

    await tester.enterText(find.byKey(SaisieCodeCourriel.cleChamp), '123');
    await tester.pump();
    await tester.ensureVisible(find.byKey(SaisieCodeCourriel.cleBouton));
    await tester.tap(find.byKey(SaisieCodeCourriel.cleBouton));
    await tester.pumpAndSettle();

    expect(find.text(t.connexion.code.erreurLongueur), findsOneWidget);
    expect(auth.codesVerifies, isEmpty);
  });

  testWidgets('un code refusé par le serveur le dit et dit quoi faire', (
    WidgetTester tester,
  ) async {
    final FauxServiceAuth auth = FauxServiceAuth();
    await _monter(tester, auth);
    await _envoyerLeLien(tester);
    auth.erreurAJeter = const AuthException('Token has expired');

    await tester.enterText(find.byKey(SaisieCodeCourriel.cleChamp), '654321');
    await tester.pump();
    await tester.ensureVisible(find.byKey(SaisieCodeCourriel.cleBouton));
    await tester.tap(find.byKey(SaisieCodeCourriel.cleBouton));
    await tester.pumpAndSettle();

    expect(find.text(t.connexion.code.erreurCode), findsOneWidget);
  });

  testWidgets('création avec questionnaire rempli : la ligne et le lien', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      FauxServiceAuth(),
      mode: ModeConnexion.creation,
      repondu: true,
    );
    expect(
      find.text(t.inscription.questionnaire.acces.reponsesGardees),
      findsOneWidget,
    );
    expect(find.text(t.connexion.revoirReponses), findsOneWidget);
  });

  testWidgets('connexion ordinaire : pas de ligne sur les réponses', (
    WidgetTester tester,
  ) async {
    await _monter(tester, FauxServiceAuth(), repondu: true);
    expect(
      find.text(t.inscription.questionnaire.acces.reponsesGardees),
      findsNothing,
    );
  });
}
