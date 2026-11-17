// BE-2b (pilote, 17/11/2026) : le role `associe` n'ouvre que les candidatures.
// Son accueil est la liste des candidatures (le serveur la filtre sur ses
// missions) ; toute autre page de l'administration, y compris par adresse
// tapee, le ramene a cet accueil ; sa navigation ne montre que « Candidatures ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

import '../support/harnais.dart';
import 'support_routeur.dart';

SessionState _associe() => const SessionState(
  resolue: true,
  profileId: 'p-associe',
  householdId: null,
  role: AppRole.associe,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

String? _va(String chemin) => deciderRedirection(
  session: _associe(),
  cheminDemande: chemin,
  maintenant: DateTime.utc(2026, 11, 17, 10),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('redirection de l\'associe', () {
    test('sa racine est la liste des candidatures', () {
      expect(
        Routes.racinePour(AppRole.associe),
        Routes.adminPersonnesCandidatures,
      );
      expect(
        Routes.prefixePour(AppRole.associe),
        Routes.adminPersonnesCandidatures,
      );
      expect(Routes.notificationsPour(AppRole.associe), isNull);
    });

    test('les candidatures et un dossier s\'ouvrent', () {
      expect(_va(Routes.adminPersonnesCandidatures), isNull);
      expect(_va(Routes.adminPersonnesCandidaturePour('CAND-00001')), isNull);
    });

    test(
      'toute autre page de l\'administration le ramene aux candidatures',
      () {
        for (final String chemin in <String>[
          Routes.admin,
          Routes.adminPersonnesComptes,
          Routes.adminPersonnesDossiers,
          Routes.adminPersonnesImport,
          Routes.adminOperationsGroupes,
          Routes.adminNotifications,
          Routes.adminAlertes,
          Routes.adminCommunicationsMessages,
          Routes.enseignantJournee,
          Routes.tuteurAccueil,
          Routes.eleve,
        ]) {
          expect(
            _va(chemin),
            Routes.adminPersonnesCandidatures,
            reason: chemin,
          );
        }
      },
    );
  });

  group('navigation de l\'associe', () {
    testWidgets('1440 : le panneau ne propose que Personnes, jamais les autres '
        'domaines', (WidgetTester tester) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.adminPersonnesCandidatures,
        source: FausseSourceSession(_associe()),
        taille: const Size(1440, 900),
      );
      await tester.pumpAndSettle();
      expect(
        routeur.routeInformationProvider.value.uri.path,
        startsWith(Routes.adminPersonnesCandidatures),
      );
      for (final String libelle in <String>[
        t.nav.admin.finance,
        t.nav.admin.configuration,
        t.nav.admin.securite,
        t.nav.admin.operations,
        t.nav.admin.pedagogie,
      ]) {
        expect(find.text(libelle), findsNothing, reason: libelle);
      }
      expect(find.text(t.admin.comptes.titre), findsNothing);
    });
  });
}
