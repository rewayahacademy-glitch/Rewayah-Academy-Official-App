import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart'
    show cahiersEnFileProvider;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

// HEURES-ACCUEIL-ENSEIGNANT (directeur, 11/11/2026) : sur « Aujourd'hui », la
// carte « Prochaine seance » et la ligne de « Ma journee » disent LA MEME
// heure pour la meme Classe, celle du fuseau du profil (une seule source,
// `heureChezMoi`), et le nom de la Classe n'est jamais precede d'un second
// « Classe » (« Classe Classe Coran »). Fuseau du profil : Asia/Tokyo (+9 h),
// qui ne peut pas etre celui de l'appareil de test.

final DateTime _maintenant = DateTime.utc(2026, 11, 12, 5);

final SeanceEnseignant _seance = SeanceEnseignant(
  id: 's1',
  debut: DateTime.utc(2026, 11, 12, 10),
  fin: DateTime.utc(2026, 11, 12, 10, 45),
  statut: StatutSeance.planifiee,
  nbParticipants: 4,
  cahierDepose: false,
  groupeId: 'g1',
  groupeLibelle: 'Classe Coran',
);

final MonHorloge _tokyo = MonHorloge.lire(const <String, Object?>{
  'maintenant': '2026-11-12T05:00:00Z',
  'moi': <String, Object?>{'fuseau': 'Asia/Tokyo', 'decalage_secondes': 32400},
});

List<Override> _surcharges() => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: 'ens-1',
        householdId: 'h1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  monHorlogeProvider.overrideWith((Ref _) async => _tokyo),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  cahiersEnFileProvider.overrideWith((Ref _) async => const <String>{}),
  maintenantJourneeProvider.overrideWithValue(() => _maintenant),
  seancesEnseignantProvider.overrideWith(
    (Ref _) async => <SeanceEnseignant>[_seance],
  ),
  cahiersEnRetardProvider.overrideWith(
    (Ref _) async => const <CahierEnRetard>[],
  ),
  reglagesPriereProvider('ens-1').overrideWith((Ref _) async => null),
  valeurRegleProvider((profilId: 'ens-1', cle: CleRegle.pauseEntreCours))
      .overrideWith((Ref _) async => 10),
];

Future<void> _monter(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(),
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const JourneePage(),
        ),
      ),
    ),
  );
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => poserMonHorlogePourTest(_tokyo));
  tearDown(() => poserMonHorlogePourTest(null));

  testWidgets('Prochaine seance et Ma journee : la meme heure (fuseau du '
      'profil)', (WidgetTester tester) async {
    await _monter(tester);
    final String plage = t.enseignant.journee.plage(
      debut: '19:00',
      fin: '19:45',
    );
    // La carte « Prochaine seance » et la ligne de « Ma journee ».
    expect(
      find.textContaining(plage, findRichText: true),
      findsNWidgets(2),
      reason: 'les deux blocs disent 19:00-19:45, heure de Tokyo',
    );
    expect(find.textContaining('10:00', findRichText: true), findsNothing);
  });

  testWidgets('le nom de la Classe ne repete jamais « Classe »', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    expect(
      find.textContaining('Classe Classe', findRichText: true),
      findsNothing,
    );
    expect(find.text('Classe Coran'), findsNWidgets(2));
  });

  // R3 : « Aujourd'hui » de l'enseignant, donnees de test seulement (fuseau
  // de profil Asia/Tokyo, Classe « Classe Coran »). Jamais sans CAPTURE_DIR.
  group('Capture : HEURES-ACCUEIL-ENSEIGNANT', skip: sautSansCapture, () {
    setUp(masquerRubanDebug);
    for (final (
          String nom,
          double largeur,
          ThemeMode mode,
          String langue,
          double echelle,
        )
        in <(String, double, ThemeMode, String, double)>[
          ('journee_390_clair', 390, ThemeMode.light, 'fr', 1),
          ('journee_390_sombre', 390, ThemeMode.dark, 'fr', 1),
          ('journee_390_arabe', 390, ThemeMode.light, 'ar', 1),
          ('journee_390_texte2', 390, ThemeMode.light, 'fr', 2),
          ('journee_1440_clair', 1440, ThemeMode.light, 'fr', 1),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        if (langue == 'ar') {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        }
        fixerVueCapture(tester, Size(largeur, echelle == 2 ? 3200 : 1900), 1);
        await tester.pumpWidget(
          hoteCapture(
            const JourneePage(),
            surcharges: _surcharges(),
            themeMode: mode,
            echelleTexte: echelle,
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }
  });
}
