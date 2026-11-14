// Captures R3 du lot SALLE2-ENTRETIEN / SALLE2-FICHE (directeur, 14/11/2026),
// sur la VRAIE application et le vrai routeur en demonstration
// d'administration :
//   - la fiche de candidature sur ordinateur (1440x900) et telephone
//     (390x844) : decision Accepter / Demander une precision / Refuser,
//     puis Accueillir dans l'equipe / Ne pas accueillir, la piece ouverte et
//     decidee sur place, aucun bloc vide ;
//   - la carte de l'entretien du candidat (proche : lumiere orange ; salle
//     ouverte : lumiere verte et « Rejoindre l'entretien ») ;
//   - les entretiens du jour de la personne qui les mene.
//
// Donnees fictives (doubles des ports) : aucune personne reelle. Saute sans
// CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/entretien_candidat.dart';
import 'package:rewayah_academy/core/candidature/entretiens_temps_reel.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/piece_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_candidature/entretiens_du_jour.dart';
import 'package:rewayah_academy/features/candidature/carte_entretien_proche.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/demo/mode_demonstration.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Une candidature fictive en Salle d'examen, versement a verifier : ce qui se
/// voit au premier regard, la prochaine action est de confirmer le moyen.
FauxCandidaturesDirection _port({
  DetailCandidature? detail,
  Object? Function(int)? erreurLire,
  Object? Function(DemandeGeste, int)? erreurGeste,
}) => FauxCandidaturesDirection(
  capacitesRendues: capacitesGestes,
  details: <DetailCandidature>[detail ?? detailTest()],
  erreurLire: erreurLire,
  erreurGeste: erreurGeste,
  contacts: const <String, ContactCandidat>{
    'c1': ContactCandidat(
      courriel: 'amina.diallo@exemple.org',
      telephone: '+221771234567',
    ),
  },
  moyens: const <String, MoyensConfirmes>{
    'SN': MoyensConfirmes(
      virementBancaire: true,
      operateurs: <OperateurPaiement>[
        OperateurPaiement(code: 'orange_money', nom: 'Orange Money'),
      ],
    ),
  },
  historiques: <String, List<EvenementCandidature>>{
    'c1': <EvenementCandidature>[
      evenementTest(
        id: 4,
        type: 'transition',
        auteur: AuteurEvenement.candidat,
        quand: DateTime.utc(2026, 10, 18, 14),
        etapeAvant: EtapeCandidature.prequalification,
        etapeApres: EtapeCandidature.prequalification,
        etatAvant: EtatCandidature.aCompleter,
        etatApres: EtatCandidature.enExamen,
      ),
      evenementTest(
        id: 3,
        type: 'transition',
        auteur: AuteurEvenement.direction,
        quand: DateTime.utc(2026, 10, 17, 9, 30),
        etapeAvant: EtapeCandidature.prequalification,
        etapeApres: EtapeCandidature.prequalification,
        etatAvant: EtatCandidature.enExamen,
        etatApres: EtatCandidature.aCompleter,
        motif: 'Disponibilites a preciser pour le soir.',
      ),
      evenementTest(
        id: 2,
        type: 'controle',
        auteur: AuteurEvenement.systeme,
        quand: DateTime.utc(2026, 10, 16, 8),
      ),
      evenementTest(
        id: 1,
        type: 'creee',
        auteur: AuteurEvenement.systeme,
        quand: DateTime.utc(2026, 10, 1, 9),
      ),
    ],
  },
);

/// Monte la VRAIE application en demonstration d'administration, ouverte sur
/// la candidature `CAND-0000C1`, avec le port [port].
Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection port, {
  ThemeMode mode = ThemeMode.light,
  bool horsLigne = false,
  List<Override> extra = const <Override>[],
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
        horlogeFormulairesProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 22, 12),
        ),
        ...extra,
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
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
  unawaited(
    routeur.push<void>(
      Routes.adminPersonnesCandidaturePour('CAND-0000C1'),
      extra: 'c1',
    ),
  );
  await stabiliser(tester);
  await stabiliser(tester);
}

/// Remonte toutes les listes verticales en haut.
Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

const String _lot = 'salle2-entretien';

Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  debugPrint('PNG ${await capturer(tester, '$_lot/$nom')}');
}

/// La piece du candidat fictif, en attente : la revue de demonstration
/// (`demo-dossier-01`) s'ouvre sur la fiche.
final Override _pieceEnAttente = lirePieceCandidatureProvider.overrideWithValue(
  (String _) async => const PieceCandidature(
    statut: StatutPieceCandidature.enAttente,
    profilId: 'demo-dossier-01',
    documentId: 'demo-piece-01',
  ),
);

class _Entretien implements PortEntretienCandidat {
  const _Entretien(this.entretien);
  final MonEntretien entretien;
  @override
  Future<List<CreneauOuvert>> creneaux() async => const <CreneauOuvert>[];
  @override
  Future<MonEntretien?> monEntretien() async => entretien;
  @override
  Future<IssueReservation> reserver({
    required String creneau,
    required int version,
    required String cle,
  }) async => (entretien: entretien, refus: null);
}

/// Monte un widget seul sous le vrai theme.
Future<void> _seul(
  WidgetTester tester,
  Widget enfant,
  List<Override> surcharges, {
  Size taille = _telephone,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surcharges,
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: enfant,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  await stabiliser(tester);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('SALLE2 : captures', skip: sautSansCapture, () {
    for (final (Size taille, String nom) vue in <(Size, String)>[
      (_bureau, '1440'),
      (_telephone, '390'),
    ]) {
      testWidgets(
        'fiche : Accepter, Demander une precision, Refuser (${vue.$2})',
        (WidgetTester tester) async {
          fixerVueCapture(
            tester,
            vue.$1,
            1,
            zoneSure: vue.$1 == _telephone ? _zoneSure : EdgeInsets.zero,
          );
          await _monter(
            tester,
            _port(detail: detailTest(paiement: EtatVersement.compatible)),
            extra: <Override>[_pieceEnAttente],
          );
          expect(
            find.text(t.admin.candidatures.decision.accepter),
            findsOneWidget,
          );
          await _photo(tester, 'fiche_decision_${vue.$2}');
        },
      );

      testWidgets('fiche : Accueillir ou Ne pas accueillir (${vue.$2})', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(
          tester,
          vue.$1,
          1,
          zoneSure: vue.$1 == _telephone ? _zoneSure : EdgeInsets.zero,
        );
        await _monter(
          tester,
          _port(
            detail: detailTest(
              etape: EtapeCandidature.verifications,
              etat: EtatCandidature.decisionEnAttente,
            ),
          ),
          extra: <Override>[_pieceEnAttente],
        );
        expect(
          find.text(t.admin.candidatures.decision.nePasAccueillir),
          findsOneWidget,
        );
        await _photo(tester, 'fiche_accueillir_${vue.$2}');
      });
    }

    final DateTime maintenant = DateTime.now();
    for (final (String nom, Duration avant) cas in <(String, Duration)>[
      ('proche', const Duration(minutes: 25)),
      ('ouvert', const Duration(minutes: 6)),
    ]) {
      testWidgets('carte de l entretien du candidat : ${cas.$1}', (
        WidgetTester tester,
      ) async {
        final DateTime debut = maintenant.add(cas.$2);
        await _seul(tester, const CarteEntretienProche(), <Override>[
          portEntretienCandidatProvider.overrideWithValue(
            _Entretien(
              MonEntretien(
                seanceId: 's1',
                debut: debut,
                fin: debut.add(const Duration(minutes: 45)),
                ouvertureLe: debut.subtract(const Duration(minutes: 10)),
                statut: 'planned',
              ),
            ),
          ),
          horlogeCarteEntretienProvider.overrideWithValue(() => maintenant),
        ]);
        await _photo(tester, 'candidat_carte_${cas.$1}_390');
      });
    }

    testWidgets('entretiens du jour de la personne qui les mene', (
      WidgetTester tester,
    ) async {
      final DateTime debut = maintenant.add(const Duration(minutes: 5));
      await _seul(
        tester,
        const EntretiensDuJour(ficheOuverte: true),
        <Override>[
          lireEntretiensProvider.overrideWithValue(
            () async => <EntretienDuJour>[
              EntretienDuJour(
                sessionId: 's1',
                reference: 'CAND-0000C1',
                nom: 'Amina Diallo',
                debut: debut,
                fin: debut.add(const Duration(minutes: 45)),
                jeParticipe: true,
              ),
              EntretienDuJour(
                sessionId: 's2',
                reference: 'CAND-0000C2',
                nom: 'Khadija Ba',
                debut: debut.add(const Duration(hours: 3)),
                fin: debut.add(const Duration(hours: 3, minutes: 45)),
                jeParticipe: true,
              ),
            ],
          ),
          horlogeEntretiensDuJourProvider.overrideWithValue(() => maintenant),
        ],
        taille: _bureau,
      );
      await _photo(tester, 'direction_entretiens_du_jour_1440');
    });
  });
}
