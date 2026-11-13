import 'dart:async';

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
import 'package:rewayah_academy/core/i18n/dates_appareil.dart';
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
// « Classe » (« Classe Classe Coran »). Cas du directeur : l'enseignant a
// Riyad (UTC+3), une eleve a Conakry (UTC+0), un compte sans fuseau ; et un
// fuseau qui arrive apres le premier rendu de la page.

final DateTime _maintenant = DateTime.utc(2026, 11, 12, 5);

// La seance de production : 16:00 UTC (19:00 a Riyad, 16:00 a Conakry).
final SeanceEnseignant _seance = SeanceEnseignant(
  id: 's1',
  debut: DateTime.utc(2026, 11, 12, 16),
  fin: DateTime.utc(2026, 11, 12, 17, 15),
  statut: StatutSeance.planifiee,
  nbParticipants: 4,
  cahierDepose: false,
  groupeId: 'g1',
  groupeLibelle: 'Classe Coran',
);

MonHorloge _horloge(String fuseau, int decalageSecondes) =>
    MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T05:00:00Z',
      'moi': <String, Object?>{
        'fuseau': fuseau,
        'decalage_secondes': decalageSecondes,
      },
    });

/// L'enseignant en Arabie saoudite (UTC+3).
final MonHorloge _riyad = _horloge('Asia/Riyadh', 10800);

/// Une personne en Guinee (UTC+0).
final MonHorloge _conakry = _horloge('Africa/Conakry', 0);

/// La lecture du fuseau telle qu'en production : le provider pose la lecture
/// globale (`chezMoi`) puis la rend. [lecture] nulle : compte sans fuseau.
Future<MonHorloge?> Function(Ref) _fournisseur(
  Future<MonHorloge?> Function() lecture,
) => (Ref _) async {
  final MonHorloge? lu = await lecture();
  poserMonHorlogePourTest(lu);
  return lu;
};

List<Override> _surcharges({
  Future<MonHorloge?> Function(Ref)? horloge,
}) => <Override>[
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
  monHorlogeProvider.overrideWith(horloge ?? _fournisseur(() async => _riyad)),
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
  pausePrevueProvider.overrideWith((Ref _, String _) async => null),
  valeurRegleProvider((profilId: 'ens-1', cle: CleRegle.pauseEntreCours))
      .overrideWith((Ref _) async => 10),
];

Future<void> _monter(
  WidgetTester tester, {
  Future<MonHorloge?> Function(Ref)? horloge,
}) async {
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(horloge: horloge),
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
  setUp(() => poserMonHorlogePourTest(null));
  tearDown(() => poserMonHorlogePourTest(null));

  String plage(String debut, String fin) =>
      t.enseignant.journee.plage(debut: debut, fin: fin);

  // Chacun voit l'heure dans SON fuseau, celui de son compte, calculee depuis
  // l'instant UTC de la seance ; les deux blocs disent la meme.
  for (final (String qui, MonHorloge? horloge, String debut, String fin)
      in <(String, MonHorloge?, String, String)>[
        ('enseignant a Riyad (UTC+3)', _riyad, '19:00', '20:15'),
        ('compte a Conakry (UTC+0)', _conakry, '16:00', '17:15'),
      ]) {
    testWidgets('$qui : Prochaine seance et Ma journee disent $debut', (
      WidgetTester tester,
    ) async {
      await _monter(tester, horloge: _fournisseur(() async => horloge));
      expect(
        find.textContaining(plage(debut, fin), findRichText: true),
        findsNWidgets(2),
        reason: 'les deux blocs, au fuseau du compte',
      );
    });
  }

  // Le cas reel du directeur : l'enseignant a Riyad (UTC+3), l'eleve a
  // Conakry (UTC+0), la meme seance ; l'appareil dans un TROISIEME fuseau
  // (preuve : `TZ=America/Montreal flutter test <ce fichier>`). Chacun voit
  // SON heure dans les deux blocs, exactement 3 h d'ecart entre eux, et
  // jamais l'heure de l'appareil.
  testWidgets('Riyad et Conakry, appareil dans un 3e fuseau : chacun son heure '
      'dans les deux blocs, 3 h d ecart', (WidgetTester tester) async {
    final Duration appareil = DateTime.now().timeZoneOffset;
    final bool troisiemeFuseau =
        appareil != Duration.zero && appareil != const Duration(hours: 3);
    final String heureAppareil = heureDeLAppareil(_seance.debut.toLocal());
    final Map<String, String> vu = <String, String>{};
    for (final (String qui, MonHorloge horloge) in <(String, MonHorloge)>[
      ('enseignant', _riyad),
      ('eleve', _conakry),
    ]) {
      await _monter(tester, horloge: _fournisseur(() async => horloge));
      final String debut = heureChezMoi(_seance.debut);
      final String fin = heureChezMoi(_seance.fin);
      expect(
        find.textContaining(plage(debut, fin), findRichText: true),
        findsNWidgets(2),
        reason: '$qui : les deux blocs a son heure',
      );
      if (troisiemeFuseau) {
        expect(
          find.textContaining(heureAppareil, findRichText: true),
          findsNothing,
          reason: '$qui : jamais l heure de l appareil ($heureAppareil)',
        );
      }
      vu[qui] = debut;
      await tester.pumpWidget(const SizedBox());
    }
    expect(vu['enseignant'], '19:00');
    expect(vu['eleve'], '16:00');
    int minutes(String hhmm) =>
        int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3));
    expect(minutes(vu['enseignant']!) - minutes(vu['eleve']!), 180);
  });

  testWidgets('compte sans fuseau : les deux blocs a l heure de l appareil', (
    WidgetTester tester,
  ) async {
    await _monter(tester, horloge: _fournisseur(() async => null));
    final String debut = heureDeLAppareil(_seance.debut.toLocal());
    final String fin = heureDeLAppareil(_seance.fin.toLocal());
    expect(
      find.textContaining(plage(debut, fin), findRichText: true),
      findsNWidgets(2),
    );
  });

  testWidgets(
    'le fuseau arrive apres le premier rendu : la page se redessine',
    (WidgetTester tester) async {
      final Completer<MonHorloge?> arrivee = Completer<MonHorloge?>();
      await _monter(tester, horloge: _fournisseur(() => arrivee.future));
      // Avant la lecture : l'heure de l'appareil, dans les deux blocs.
      final String avant = heureDeLAppareil(_seance.debut.toLocal());
      expect(find.textContaining(avant, findRichText: true), findsNWidgets(2));
      arrivee.complete(_riyad);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.textContaining(plage('19:00', '20:15'), findRichText: true),
        findsNWidgets(2),
        reason: 'les deux blocs passent au fuseau du profil',
      );
    },
  );

  test('la meme seance cote eleve en Guinee (UTC+0) : 16:00', () {
    poserMonHorlogePourTest(_conakry);
    expect(heureChezMoi(_seance.debut), '16:00');
    poserMonHorlogePourTest(_riyad);
    expect(heureChezMoi(_seance.debut), '19:00');
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
  // de profil Asia/Riyadh, Classe « Classe Coran »). Jamais sans CAPTURE_DIR.
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
