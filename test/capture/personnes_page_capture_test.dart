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
import 'package:rewayah_academy/core/admin/port_fondateurs.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart'
    show ControleCandidature, DetailCandidature;
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart'
    show LigneCandidature;
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';

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
  // Chaque compte a son nom : deux comptes de meme nom se liraient comme un
  // doublon sur la planche.
  nom: _noms[(i * 3 + i ~/ 12) % _noms.length],
  role: role,
  etat: i % 7 == 3
      ? AccountStatus.pendingKyc
      : (i % 9 == 2 ? AccountStatus.provisionalActive : AccountStatus.active),
  inscritLe: DateTime.now().subtract(Duration(days: 3 + i)),
  // Un acces provisoire echu de temps en temps (filtre « Acces echus »).
  accesJusquAu: i % 9 == 2
      ? DateTime.now().subtract(const Duration(days: 2))
      : null,
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

PhaseEnseignant _phase(int i) => switch (i % 6) {
  4 => PhaseEnseignant.enPoste,
  5 => PhaseEnseignant.accueil,
  3 when i > 8 => PhaseEnseignant.disponible,
  _ => PhaseEnseignant.candidat,
};

// Dix-huit dossiers fictifs, chacun a son nom : deux personnes de meme nom
// se liraient comme un doublon sur la planche.
final List<LigneEnseignant> _enseignants = <LigneEnseignant>[
  for (int i = 0; i < 18; i++)
    LigneEnseignant(
      dossier: ligneTest(
        id: 'c$i',
        reference: 'CAND-${10000 + i}',
        nom:
            '${_prenoms[(i + 2) % _prenoms.length]} '
            '${_noms[(i + i ~/ 12) % _noms.length]}',
        etape: _phase(i) == PhaseEnseignant.candidat
            ? EtapeCandidature.prequalification
            : EtapeCandidature.confirmee,
        // Un dossier confirme n'a plus d'etat d'examen ; les candidats sont
        // « en examen » ou « a completer » : un filtre pose se voit dans la
        // liste et dans le compteur.
        etat: _phase(i) != PhaseEnseignant.candidat
            ? null
            : (i % 3 == 0
                  ? EtatCandidature.aCompleter
                  : EtatCandidature.enExamen),
      ),
      phase: _phase(i),
      quiAttend: switch (_phase(i)) {
        PhaseEnseignant.candidat => i.isEven ? 'direction' : 'candidat',
        PhaseEnseignant.accueil => 'enseignant',
        _ => null,
      },
    ),
];

/// Les pieces a verifier (etape d), personnes fictives.
final List<DossierAValider> _pieces = <DossierAValider>[
  for (int i = 0; i < 4; i++)
    DossierAValider(
      documentId: 'doc-$i',
      profilId: 'pp-$i',
      type: null,
      cleObjet: null,
      deposeLe: DateTime.now().subtract(Duration(days: 2 + i)),
      prenom: _prenoms[(i + 6) % _prenoms.length],
      nom: _noms[i % _noms.length],
      identifiantImmuable: 'RA-26-${7700 + i}',
      role: AppRole.teacher,
      candidatureId: i.isEven ? 'c$i' : null,
      candidatureReference: i.isEven ? 'CAND-${10000 + i}' : null,
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
  }) async {
    final List<LigneEnseignant> lignes = <LigneEnseignant>[
      for (final LigneEnseignant l in _enseignants)
        if (filtre.phase == null || l.phase == filtre.phase) l,
    ];
    return PageEnseignants(
      lignes: lignes,
      total: lignes.length,
      page: 1,
      taillePage: 50,
      compteurs: CompteursEnseignants(
        parPhase: <PhaseEnseignant, int>{
          for (final PhaseEnseignant p in PhaseEnseignant.values)
            p: _enseignants.where((LigneEnseignant l) => l.phase == p).length,
        },
      ),
    );
  }
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
        // Etape (f) : la coche « fondateur » est servie (personne ne l'a).
        fondateursProvider.overrideWith((Ref ref) async => <String>{}),
        piecesAVerifierProvider.overrideWith((Ref ref) async => _pieces),
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
                        '${_noms[(i + i ~/ 12) % _noms.length]}',
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

  test('le jeu de demonstration ne porte pas deux fois le meme nom', () {
    for (final AppRole role in AppRole.values) {
      final List<String> noms = <String>[
        for (final CompteAdmin c in _comptes)
          if (c.role == role) c.libelle,
      ];
      expect(noms.toSet(), hasLength(noms.length), reason: '$role : $noms');
    }
    final List<String> dossiers = <String>[
      for (final LigneEnseignant l in _enseignants) l.dossier.nomComplet,
    ];
    expect(dossiers.toSet(), hasLength(dossiers.length));
  });

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
          // Etape (d) : les vues de l'onglet des enseignants.
          (
            'vue_candidats_1440_fr_clair',
            '$base?onglet=enseignants&vue=candidats&etat=enExamen'
                '&element=CAND-10001',
            bureau,
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'vue_actifs_1440_ar_clair',
            '$base?onglet=enseignants&vue=actifs&element=CAND-10004',
            bureau,
            ThemeMode.light,
            AppLocale.ar,
          ),
          (
            'vue_candidats_390_fr_clair',
            '$base?onglet=enseignants&vue=candidats&etat=aCompleter',
            telephone,
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'vue_pieces_390_ar_clair',
            '$base?onglet=enseignants&vue=pieces',
            telephone,
            ThemeMode.light,
            AppLocale.ar,
          ),
          (
            'vue_accueil_1440_en_sombre',
            '$base?onglet=enseignants&vue=accueil&element=CAND-10005',
            bureau,
            ThemeMode.dark,
            AppLocale.en,
          ),
          (
            'vue_pieces_1440_fr_clair',
            '$base?onglet=enseignants&vue=pieces&element=RA-26-7700',
            bureau,
            ThemeMode.light,
            AppLocale.fr,
          ),
          // Etape (f) : les gestes des comptes dans la page unique.
          (
            'gestes_famille_1440_fr_clair',
            '$base?onglet=familles&element=RA-26-4131',
            bureau,
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'gestes_equipe_1440_ar_clair',
            '$base?onglet=equipe&element=RA-26-4150',
            bureau,
            ThemeMode.light,
            AppLocale.ar,
          ),
          (
            'gestes_eleves_390_fr_clair',
            '$base?onglet=eleves&acces=echus',
            telephone,
            ThemeMode.light,
            AppLocale.fr,
          ),
          (
            'gestes_familles_390_ar_clair',
            '$base?onglet=familles',
            telephone,
            ThemeMode.light,
            AppLocale.ar,
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

  // Etape (f) point 2 : menu par ligne, cases, barre du lot, tri.
  group('PERSONNES (f2) : selection, lot, tri', skip: sautSansCapture, () {
    const String base = Routes.adminPersonnes;
    const Size bureau = Size(1440, 900);
    const Size telephone = Size(390, 844);
    const String candidats =
        '$base?onglet=enseignants&vue=candidats&tri=recente';
    const String eleves = '$base?onglet=eleves&tri=-nom';
    for (final (String, String, Size, AppLocale) c
        in <(String, String, Size, AppLocale)>[
          ('lot_candidats_1440_fr', candidats, bureau, AppLocale.fr),
          ('lot_candidats_1440_ar', candidats, bureau, AppLocale.ar),
          ('lot_candidats_390_fr', candidats, telephone, AppLocale.fr),
          ('lot_candidats_390_ar', candidats, telephone, AppLocale.ar),
          ('lot_eleves_1440_fr', eleves, bureau, AppLocale.fr),
          ('lot_eleves_390_ar', eleves, telephone, AppLocale.ar),
        ]) {
      testWidgets('personnes ${c.$1}', (WidgetTester tester) async {
        await LocaleSettings.setLocale(c.$4);
        fixerVueCapture(tester, c.$3, c.$3.width < 500 ? 2 : 1);
        await _monter(tester, c.$2, mode: ThemeMode.light);
        // Deux lignes cochees : la barre de ce qui est retenu apparait.
        final Finder cases = find.byType(CaseACocher);
        final int n = cases.evaluate().length;
        expect(n, greaterThan(2));
        await tester.tap(cases.at(n > 3 ? 1 : 0));
        await stabiliser(tester);
        // Au telephone, la barre des comptes vient en tete : la seconde
        // case peut etre sortie de l'ecran.
        final int m = find.byType(CaseACocher).evaluate().length;
        if (m > 0) {
          await tester.tap(
            find.byType(CaseACocher).at((n > 3 ? 2 : 1).clamp(0, m - 1)),
          );
        }
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'personnes_${c.$1}')}');
      });
    }
  });
}
