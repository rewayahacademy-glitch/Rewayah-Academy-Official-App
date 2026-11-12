// COMPTE-ENSEIGNANT-IDENTITE (garde-cap, 12/11/2026) : le Compte de
// l'enseignant ouvre les pages du titulaire du compte, communes au tuteur
// (« Informations personnelles », « Methode de connexion »), sur son vrai
// routeur ; le retour ramene a son Compte. La page Informations lit le fuseau
// du profil par `mon_horloge` : sans fuseau, « Heure de cet appareil »,
// jamais une ville supposee. Donnees fictives.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/i18n/villes_fuseau.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/lignes_compte.dart';
import 'package:rewayah_academy/features/compte/securite_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

/// L'identite du titulaire, fictive.
class _Identite implements PortIdentiteTitulaire {
  @override
  Future<IdentiteTitulaire> lire() async => const IdentiteTitulaire(
    prenom: 'Aicha',
    nom: 'Diallo',
    courriel: 'enseignante@test.invalid',
    methodeConnexion: MethodeConnexion.lienCourriel,
    statut: AccountStatus.active,
  );

  @override
  Future<void> modifier({String? prenom, String? nom}) async {}
}

MonHorloge _horloge(String? fuseau) => MonHorloge(
  maintenantServeur: DateTime.utc(2026, 11, 12, 9),
  moi: fuseau == null
      ? null
      : FuseauVu(fuseau: fuseau, decalage: const Duration(hours: 3)),
);

List<Override> _surcharges({
  AppRole role = AppRole.teacher,
  FutureOr<MonHorloge?> Function()? horloge,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: role,
        profileId: 'ens-1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
  referentielLanguesProvider.overrideWith(
    (Ref _) async => const <LangueCours>[],
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  profilEnseignantProvider.overrideWith(
    (Ref _) async => const ProfilEnseignant(
      prenom: 'Aicha',
      identifiant: 'RA-26-0007',
      langues: <String>[],
      statutCompte: AccountStatus.active,
    ),
  ),
  portIdentiteTitulaireProvider.overrideWithValue(_Identite()),
  monHorlogeProvider.overrideWith(
    (Ref _) async => await (horloge?.call() ?? _horloge('Asia/Riyadh')),
  ),
];

/// Monte l'application sur son vrai routeur, a l'adresse demandee.
Future<GoRouter> _monter(WidgetTester tester, String depart) async {
  fixerVueCapture(tester, const Size(390, 2400), 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            routeur.go(depart);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// La page Informations seule, avec l'horloge [horloge].
Future<void> _monterInformations(
  WidgetTester tester,
  FutureOr<MonHorloge?> Function() horloge,
) async {
  fixerVueCapture(tester, const Size(390, 1200), 1);
  await tester.pumpWidget(
    hote(
      const InformationsComptePage(),
      surcharges: _surcharges(horloge: horloge),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    poserMonHorlogePourTest(null);
  });

  group('Compte de l enseignant', () {
    testWidgets('les deux lignes du titulaire, la methode lue de la session', (
      WidgetTester tester,
    ) async {
      await _monter(tester, Routes.enseignantProfil);
      expect(find.byType(ProfilEnseignantPage), findsOneWidget);
      expect(find.byKey(cleLigneInformationsCompte), findsOneWidget);
      expect(find.byKey(cleLigneConnexionCompte), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(cleLigneConnexionCompte),
          matching: find.text(t.compte.tuteur.securite.methodeLien),
        ),
        findsOneWidget,
      );
    });

    testWidgets('« Informations personnelles » ouvre la page commune, le '
        'retour ramene au Compte', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, Routes.enseignantProfil);
      await _toucher(tester, find.byKey(cleLigneInformationsCompte));
      expect(
        routeur.state.matchedLocation,
        Routes.enseignantProfilInformations,
      );
      expect(find.byType(InformationsComptePage), findsOneWidget);
      expect(find.text('Diallo'), findsOneWidget);
      expect(find.text('enseignante@test.invalid'), findsOneWidget);
      expect(find.text(villeDuFuseauLibelle('Asia/Riyadh')), findsOneWidget);
      await _toucher(tester, find.byType(DisqueRetour));
      expect(routeur.state.matchedLocation, Routes.enseignantProfil);
      expect(find.byType(ProfilEnseignantPage), findsOneWidget);
    });

    testWidgets('« Methode de connexion » ouvre la page commune, le retour '
        'ramene au Compte', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, Routes.enseignantProfil);
      await _toucher(tester, find.byKey(cleLigneConnexionCompte));
      expect(routeur.state.matchedLocation, Routes.enseignantProfilSecurite);
      expect(find.byType(SecuriteComptePage), findsOneWidget);
      await _toucher(tester, find.byType(DisqueRetour));
      expect(routeur.state.matchedLocation, Routes.enseignantProfil);
    });
  });

  group('Informations : le fuseau du profil, jamais suppose', () {
    testWidgets('fuseau du profil : sa ville', (WidgetTester tester) async {
      await _monterInformations(tester, () => _horloge('Africa/Conakry'));
      expect(
        find.text(villeDuFuseauLibelle('Africa/Conakry')),
        findsOneWidget,
      );
    });

    testWidgets('profil sans fuseau : « Heure de cet appareil », pas Paris', (
      WidgetTester tester,
    ) async {
      await _monterInformations(tester, () => _horloge(null));
      expect(
        find.text(t.compte.tuteur.pageInformations.fuseauAppareil),
        findsOneWidget,
      );
      expect(find.text(villeDuFuseauLibelle('Europe/Paris')), findsNothing);
    });

    testWidgets('lecture en echec : « Heure de cet appareil »', (
      WidgetTester tester,
    ) async {
      await _monterInformations(tester, () => throw StateError('hors ligne'));
      expect(
        find.text(t.compte.tuteur.pageInformations.fuseauAppareil),
        findsOneWidget,
      );
    });

    testWidgets('lecture en cours : « Non chargé »', (
      WidgetTester tester,
    ) async {
      final Completer<MonHorloge?> jamais = Completer<MonHorloge?>();
      await _monterInformations(tester, () => jamais.future);
      expect(
        find.text(t.compte.tuteur.pageInformations.fuseauIndisponible),
        findsOneWidget,
      );
    });
  });

  // R3 : le Compte de l'enseignant et les deux pages qu'il ouvre, 390, clair
  // (theme du routeur) ; sombre et arabe pour les pages communes. Donnees
  // fictives. Jamais sans CAPTURE_DIR.
  group('Capture : compte de l enseignant', skip: sautSansCapture, () {
    testWidgets('compte_390_clair', (WidgetTester tester) async {
      await _monter(tester, Routes.enseignantProfil);
      await tester.ensureVisible(find.byKey(cleLigneConnexionCompte));
      await stabiliser(tester);
      debugPrint('PNG ${await capturerVue(tester, 'compte_390_clair')}');
    });
    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe', AppLocale.ar, ThemeMode.light),
        ]) {
      testWidgets('pages_390_$nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 900), 1);
        for (final (String page, Widget ecran) in <(String, Widget)>[
          ('informations', const InformationsComptePage()),
          ('securite', const SecuriteComptePage()),
        ]) {
          await tester.pumpWidget(
            hoteCapture(ecran, surcharges: _surcharges(), themeMode: theme),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturerVue(tester, '${page}_390_$nom')}');
        }
      });
    }
  });
}
