import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../support/harnais.dart';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 'teacher-1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

const ProfilEnseignant _profil = ProfilEnseignant(
  prenom: 'Mariam',
  identifiant: 'TEACH-000001',
  pays: 'GN',
  langues: <String>['français', 'arabe'],
  plafondHeures: 24,
  statutCompte: AccountStatus.active,
  verification: VerificationEnseignant.validee,
);

Widget _hoteProfil({
  required Widget enfant,
  required FutureOr<ProfilEnseignant?> Function() profil,
  List<Override> surcharges = const <Override>[],
}) {
  return hote(
    enfant,
    surcharges: <Override>[
      sourceSessionProvider.overrideWithValue(
        FausseSourceSession(_sessionEnseignant),
      ),
      profilEnseignantProvider.overrideWith((ref) => profil()),
      ...surcharges,
    ],
  );
}

void main() {
  test(
    'le contrat enseignant lit la relation existante sans valeur inventee',
    () {
      final ProfilEnseignant profil = ProfilEnseignant.depuisJson(
        <String, dynamic>{
          'first_name': ' Mariam ',
          'immutable_id': 'TEACH-000001',
          'account_status': 'active',
          'teacher_profiles': <Map<String, dynamic>>[
            <String, dynamic>{
              'country': 'GN',
              'languages': <String>['français', ' ', 'arabe'],
              'weekly_hours_cap': 24,
              'kyc_status': 'approved',
            },
          ],
        },
      );

      expect(profil.prenom, 'Mariam');
      expect(profil.langues, <String>['français', 'arabe']);
      expect(profil.plafondHeures, 24);
      expect(profil.verification, VerificationEnseignant.validee);
    },
  );

  testWidgets(
    'le profil affiche uniquement les informations enseignant connues',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _hoteProfil(
          enfant: const ProfilEnseignantPage(),
          profil: () async => _profil,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mariam'), findsOneWidget);
      expect(find.text('TEACH-000001'), findsOneWidget);
      expect(find.text('GN'), findsOneWidget);
      expect(find.textContaining('français'), findsOneWidget);
      expect(
        find.text(t.enseignant.profil.heures(nombre: '24')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.profil.verificationValidee),
        findsOneWidget,
      );
      expect(find.text(t.compte.nonDisponible), findsNothing);
      expect(find.text(t.compte.contact), findsNothing);
      expect(find.textContaining('€'), findsNothing);
    },
  );

  testWidgets('le profil expose son squelette pendant la lecture', (
    WidgetTester tester,
  ) async {
    final Completer<ProfilEnseignant?> attente = Completer<ProfilEnseignant?>();

    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _hoteProfil(
        enfant: const ProfilEnseignantPage(),
        profil: () => attente.future,
      ),
    );
    await tester.pump();

    expect(find.byType(Skeleton), findsOneWidget);
    expect(find.bySemanticsLabel(t.commun.chargement), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('un profil absent reste un etat vide sans action métier', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _hoteProfil(
        enfant: const ProfilEnseignantPage(),
        profil: () async => null,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(t.enseignant.profil.vide), findsOneWidget);
    expect(find.text(t.enseignant.profil.reessayer), findsNothing);
  });

  testWidgets('une erreur de lecture est récupérable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _hoteProfil(
        enfant: const ProfilEnseignantPage(),
        profil: () async => throw StateError('fixture'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.enseignant.profil.erreur), findsOneWidget);
    expect(find.text(t.enseignant.profil.reessayer), findsOneWidget);
  });

  testWidgets('hors ligne sans donnée connue est annoncé séparément', (
    WidgetTester tester,
  ) async {
    final Completer<ProfilEnseignant?> attente = Completer<ProfilEnseignant?>();

    await tester.pumpWidget(
      _hoteProfil(
        enfant: const ProfilEnseignantPage(),
        profil: () => attente.future,
        surcharges: <Override>[
          horsLigneProvider.overrideWith((ref) => Stream<bool>.value(true)),
        ],
      ),
    );
    await tester.pump();

    expect(find.text(t.enseignant.profil.horsLigne), findsOneWidget);
    expect(find.text(t.enseignant.profil.erreur), findsNothing);
  });

  testWidgets('le profil tient en RTL avec un texte à 200 pour cent', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 8000),
          textScaler: TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _hoteProfil(
            enfant: const ProfilEnseignantPage(),
            profil: () async => _profil,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mariam'), findsOneWidget);
    expect(find.text('TEACH-000001'), findsOneWidget);
  });
}
