// HORLOGE-ET-LIEU (R3, directeur, 01/11/2026 : pas de capture, pas de fusion) :
// les ecrans touches par le lot, rendus avec les vraies polices et le vrai theme.
//
//   - la page de la ville (`/ville`, tuteur) ;
//   - l'etape de la ville de la candidature d'un enseignant ;
//   - la ligne d'apercu a l'inscription dans une classe (« Chez vous : ... ») ;
//   - le bloc des changements d'heure a venir de la direction ;
//   - l'heure chez soi, puis « Heure de La Mecque » (HeureDouble).
//
// 390 et 1440 de large, clair et sombre, francais et arabe. Prefixe des PNG :
// `horloge_lieu_`. Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).
//
//   CAPTURE_DIR=docs/current/captures/E2E/horloge-lieu \
//     flutter test test/capture/horloge_lieu_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu.dart';
import 'package:rewayah_academy/core/lieu/lieu_direction.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_creneau.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_offre.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/heure_double.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/port_interlocuteurs.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/admin_comptes/changements_heure.dart';
import 'package:rewayah_academy/features/candidature/ville_etape.dart';
import 'package:rewayah_academy/features/ville/ville_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

const SessionState _tuteur = SessionState(
  resolue: true,
  role: AppRole.guardian,
  profileId: 'u1',
  householdId: 'h1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

const List<Ville> _villes = <Ville>[
  Ville(
    id: 1,
    nom: 'Paris',
    nomAr: 'باريس',
    paysCode: 'FR',
    region: 'Île-de-France',
    fuseau: 'Europe/Paris',
    milliers: 2138,
  ),
  Ville(
    id: 2,
    nom: 'Conakry',
    nomAr: 'كوناكري',
    paysCode: 'GN',
    region: 'Conakry',
    fuseau: 'Africa/Conakry',
    milliers: 1660,
  ),
  Ville(
    id: 3,
    nom: 'Lyon',
    paysCode: 'FR',
    region: 'Auvergne-Rhône-Alpes',
    fuseau: 'Europe/Paris',
    milliers: 522,
  ),
];

class _PortVilles extends LieuAbsent {
  @override
  Future<List<Ville>> proposees(int decalageMinutes) async => _villes;

  @override
  Future<List<Ville>> rechercher(String texte) async => _villes;

  @override
  Future<EtatLieu> aFournir() async =>
      const EtatLieu(requis: true, reportsRestants: 2, reportsMax: 3);
}

class _PortApercu implements PortApercuOffre {
  @override
  Future<ApercuCreneau?> lire({
    required String offreId,
    required String fuseau,
  }) async => ApercuCreneau.lire(<String, Object?>{
    'jour_maintenant': 3,
    'maintenant': '19:00',
    'meme': false,
    'date_changement': '2027-03-28',
    'jour_apres': 3,
    'heure_apres': '20:00',
  });
}

class _PortInterlocuteurs implements PortInterlocuteurs {
  const _PortInterlocuteurs(this.lus);
  final InterlocuteursClasse lus;

  @override
  Future<InterlocuteursClasse?> lire(String groupeId) async => lus;
}

const Map<String, Object?> _paris = <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 3600,
  'prochain_changement': '2027-03-28T01:00:00Z',
  'decalage_apres': 7200,
  'changement_suivant': '2027-10-31T01:00:00Z',
};
const Map<String, Object?> _riyad = <String, Object?>{
  'fuseau': 'Asia/Riyadh',
  'decalage_secondes': 10800,
  'prochain_changement': null,
};

/// Un ecran, un theme, une langue, une largeur : monte par le vrai routeur
/// de test, capture toute la vue.
Future<void> _capturer(
  WidgetTester tester, {
  required String nom,
  required Widget ecran,
  required List<Override> surcharges,
  required bool clair,
  required bool arabe,
  required double largeur,
}) async {
  await LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, Size(largeur, largeur > 600 ? 900 : 1000), 1);
  masquerRubanDebug();
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/',
      themeMode: clair ? ThemeMode.light : ThemeMode.dark,
      direction: arabe ? TextDirection.rtl : TextDirection.ltr,
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        ...surcharges,
      ],
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (BuildContext _, GoRouterState _) => ecran),
        GoRoute(
          path: Routes.tuteurAccueil,
          builder: (BuildContext _, GoRouterState _) => const SizedBox(),
        ),
      ],
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturerVue(tester, nom)}');
}

void main() {
  group('Capture : HORLOGE-ET-LIEU', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });
    tearDown(() => poserMonHorlogePourTest(null));

    final MonHorloge horloge = MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T22:00:00Z',
      'moi': _paris,
      'academie': _riyad,
    });
    final InterlocuteursClasse lus = InterlocuteursClasse.lire(
      const <String, Object?>{
        'maintenant': '2026-11-12T22:00:00Z',
        'moi': _paris,
      },
    );

    final List<(String, Widget Function(), List<Override> Function())> ecrans =
        <(String, Widget Function(), List<Override> Function())>[
          (
            'ville',
            () => const VillePage(),
            () => <Override>[
              portLieuProvider.overrideWithValue(_PortVilles()),
              sourceSessionProvider.overrideWithValue(
                FausseSourceSession(_tuteur),
              ),
            ],
          ),
          (
            'candidature_ville',
            () => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: VilleEtape(
                  options: const <String>['Europe/Paris', 'Africa/Conakry'],
                  choisi: null,
                  onChange: (String _) {},
                ),
              ),
            ),
            () => <Override>[portLieuProvider.overrideWithValue(_PortVilles())],
          ),
          (
            'apercu_offre',
            () => const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: LigneApercuOffre(offreId: 'o1', fuseau: 'Europe/Paris'),
              ),
            ),
            () => <Override>[
              portApercuOffreProvider.overrideWithValue(_PortApercu()),
            ],
          ),
          (
            'changements_heure',
            () => const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: BlocChangementsHeure(),
              ),
            ),
            () => <Override>[
              changementsHeureProvider.overrideWith(
                (Ref _) async => <ChangementHeureAVenir>[
                  ChangementHeureAVenir(
                    fuseau: 'Europe/Paris',
                    transition: DateTime.utc(2027, 3, 28, 1),
                    decalageAvant: const Duration(hours: 1),
                    decalageApres: const Duration(hours: 2),
                    familles: 14,
                    enseignants: 2,
                  ),
                ],
              ),
            ],
          ),
          (
            'heure_double',
            () => Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: HeureDouble(
                  groupeId: 'g1',
                  // Mercredi 18/11/2026, 18:00 UTC : 19 h a Paris, 21 h a La Mecque.
                  instantUtc: DateTime.utc(2026, 11, 18, 18),
                ),
              ),
            ),
            () => <Override>[
              monHorlogeProvider.overrideWith((Ref _) async => horloge),
              portInterlocuteursProvider.overrideWithValue(
                _PortInterlocuteurs(lus),
              ),
            ],
          ),
        ];

    for (final (
          String nom,
          Widget Function() ecran,
          List<Override> Function() surcharges,
        )
        in ecrans) {
      for (final double largeur in <double>[390, 1440]) {
        for (final bool clair in <bool>[true, false]) {
          for (final bool arabe in <bool>[false, true]) {
            final String fichier =
                'horloge_lieu_${nom}_${largeur.toInt()}_'
                '${clair ? 'clair' : 'sombre'}_${arabe ? 'ar' : 'fr'}';
            testWidgets(fichier, (WidgetTester tester) async {
              poserMonHorlogePourTest(horloge);
              await _capturer(
                tester,
                nom: fichier,
                ecran: ecran(),
                surcharges: surcharges(),
                clair: clair,
                arabe: arabe,
                largeur: largeur,
              );
            });
          }
        }
      }
    }
  });
}
