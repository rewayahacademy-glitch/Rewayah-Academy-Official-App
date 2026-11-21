// PERSONNES-UNE-PAGE, etape (b) : captures de la page unique « Personnes », sur
// la VRAIE application et le vrai routeur en demonstration d'administration :
// la coque est dans chaque PNG. Onglets a icones ; a l'ordinateur, la liste et
// l'apercu cote a cote (un eleve, un candidat). Personnes fictives.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Les PNG du lot
// sont ranges dans `docs/current/captures/E2E/personnes-page/`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart'
    show ControleCandidature, DetailCandidature;
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart'
    show LigneCandidature;
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/demo/mode_demonstration.dart';
import 'outil_capture.dart';

const List<String> _prenoms = <String>[
  'Amine',
  'Salma',
  'Yasmine',
  'Ismael',
  'Maryam',
  'Hamza',
  'Lina',
  'Zaynab',
  'Idriss',
  'Nadia',
  'Bilal',
  'Sara',
];
const List<String> _noms = <String>['Essai', 'Fictif', 'Exemple', 'Modele'];

CompteAdmin _compte(int i, AppRole role) => CompteAdmin(
  profilId: 'p-$i',
  identifiant: 'RA-26-${4100 + i}',
  prenom: _prenoms[i % _prenoms.length],
  nom: _noms[(i * 3) % _noms.length],
  role: role,
  etat: i % 7 == 3 ? AccountStatus.pendingKyc : AccountStatus.active,
  inscritLe: DateTime.now().subtract(Duration(days: 3 + i)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: i % 4 != 0,
  enfantsDuFoyer: role == AppRole.guardian ? 1 + i % 3 : 0,
  detailsServis: true,
  tranche: role == AppRole.student
      ? (i % 5 == 0 ? TrancheAge.adulte : TrancheAge.enfant)
      : null,
  classeLibelle: role == AppRole.student && i % 4 != 0
      ? 'Lecture, samedi 10 h'
      : null,
  classeNumero: role == AppRole.student && i % 4 != 0 ? 1 + i % 2 : null,
  classesActives: role == AppRole.student && i % 4 != 0 ? 1 : 0,
  tuteurId: role == AppRole.student && i % 5 != 0 ? 't-$i' : null,
  tuteurPrenom: role == AppRole.student && i % 5 != 0
      ? '${_prenoms[(i + 4) % _prenoms.length]} ${_noms[i % _noms.length]}'
      : null,
  admissionATraiter: i % 7 == 3 && role != AppRole.admin,
);

final List<CompteAdmin> _comptes = <CompteAdmin>[
  for (int i = 0; i < 28; i++) _compte(i, AppRole.student),
  for (int i = 30; i < 44; i++) _compte(i, AppRole.guardian),
  _compte(50, AppRole.admin),
  _compte(51, AppRole.accountant),
];

final List<LigneEnseignant> _enseignants = <LigneEnseignant>[
  for (int i = 0; i < 18; i++)
    LigneEnseignant(
      dossier: ligneTest(
        id: 'c$i',
        reference: 'CAND-${10000 + i}',
        nom:
            '${_prenoms[(i + 2) % _prenoms.length]} ${_noms[i % _noms.length]}',
        etape: i % 5 == 4
            ? EtapeCandidature.confirmee
            : EtapeCandidature.prequalification,
      ),
      phase: i % 5 == 4 ? PhaseEnseignant.enPoste : PhaseEnseignant.candidat,
      quiAttend: i % 5 == 4 ? null : (i.isEven ? 'direction' : 'candidat'),
    ),
];

/// Ce que `lire_candidature` rend en plus, pour la synthese de l'apercu :
/// ce qui manque, la piece, la derniere connexion.
DetailCandidature _enrichi(DetailCandidature d) => DetailCandidature(
  ligne: d.ligne,
  version: d.version,
  documents: d.documents,
  provenance: d.provenance,
  controles: const <ControleCandidature>[
    ControleCandidature(
      nom: 'piece_validee',
      valeur: false,
      cause: 'piece_a_verifier',
    ),
  ],
  derniereConnexionServie: true,
  derniereConnexion: DateTime.now().subtract(const Duration(days: 1)),
  manquants: const <String>['pays_versement'],
);

class _Enseignants implements PortEnseignants {
  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async => PageEnseignants(
    lignes: _enseignants,
    total: 608,
    page: 1,
    taillePage: 50,
  );
}

Future<void> _monter(
  WidgetTester tester,
  String route, {
  required ThemeMode mode,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        comptesProvider.overrideWith((Ref ref) async => _comptes),
        portEnseignantsProvider.overrideWithValue(_Enseignants()),
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(
            capacitesRendues: capacitesGestes,
            lignes: <LigneCandidature>[
              for (final LigneEnseignant l in _enseignants) l.dossier,
            ],
            details: <DetailCandidature>[
              for (final (int i, LigneEnseignant l) in _enseignants.indexed)
                _enrichi(
                  detailTest(
                    id: l.dossier.id,
                    reference: l.dossier.reference,
                    nom:
                        '${_prenoms[(i + 2) % _prenoms.length]} '
                        '${_noms[i % _noms.length]}',
                    recueLe: DateTime.now().subtract(const Duration(days: 12)),
                  ),
                ),
            ],
          ),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(route);
  await stabiliser(tester);
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PERSONNES (b) : la page unique', skip: sautSansCapture, () {
    const String base = Routes.adminPersonnes;
    const Size bureau = Size(1440, 900);
    const Size telephone = Size(390, 844);
    const String eleve = '$base?onglet=eleves&element=RA-26-4101';
    const String candidat = '$base?onglet=enseignants&element=CAND-10000';

    final List<(String, String, Size, ThemeMode, AppLocale)> cas =
        <(String, String, Size, ThemeMode, AppLocale)>[
          ('eleve_1440_fr_clair', eleve, bureau, ThemeMode.light, AppLocale.fr),
          (
            'candidat_1440_fr_clair',
            candidat,
            bureau,
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'candidat_1440_ar_sombre',
            candidat,
            bureau,
            ThemeMode.dark,
            AppLocale.ar,
          ),
          ('eleve_1440_en_clair', eleve, bureau, ThemeMode.light, AppLocale.en),
          (
            'candidat_1024_ar_clair',
            candidat,
            const Size(1024, 768),
            ThemeMode.light,
            AppLocale.ar,
          ),
          (
            'eleves_390_fr_clair',
            '$base?onglet=eleves',
            telephone,
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'enseignants_390_ar_sombre',
            '$base?onglet=enseignants',
            telephone,
            ThemeMode.dark,
            AppLocale.ar,
          ),
          (
            'eleves_filtre_1440_fr_clair',
            '$base?onglet=eleves&etat=attente&q=e',
            bureau,
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'eleves_filtre_390_ar_clair',
            '$base?onglet=eleves&etat=attente',
            telephone,
            ThemeMode.light,
            AppLocale.ar,
          ),
          (
            'familles_390_ar_clair',
            '$base?onglet=familles',
            telephone,
            ThemeMode.light,
            AppLocale.ar,
          ),
          (
            'equipe_390_en_clair',
            '$base?onglet=equipe',
            telephone,
            ThemeMode.light,
            AppLocale.en,
          ),
          (
            'familles_1024_fr_clair',
            '$base?onglet=familles&element=RA-26-4131',
            const Size(1024, 768),
            ThemeMode.light,
            AppLocale.fr,
          ),
        ];
    for (final (String, String, Size, ThemeMode, AppLocale) c in cas) {
      testWidgets('personnes ${c.$1}', (WidgetTester tester) async {
        await LocaleSettings.setLocale(c.$5);
        fixerVueCapture(tester, c.$3, c.$3.width < 500 ? 2 : 1);
        await _monter(tester, c.$2, mode: c.$4);
        debugPrint('PNG ${await capturer(tester, 'personnes_${c.$1}')}');
      });
    }
  });
}
