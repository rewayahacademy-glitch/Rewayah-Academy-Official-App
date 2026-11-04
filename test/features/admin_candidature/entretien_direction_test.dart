// V2-a (04/11/2026) : le bloc Entretien de la fiche candidature (ADM-21).
//
// Ce que le test prouve :
// - l'adaptateur traduit chaque refus du serveur, envoie le debut en UTC avec
//   la version attendue et la cle, et ne garde que les entretiens de la
//   candidature ;
// - les trois capacites de V1-a sont lues (une cle absente vaut faux, une
//   regle desactivee vaut `null`) ;
// - « Planifier l'entretien » n'est propose que si le serveur l'ouvre et que
//   la candidature attend un entretien ; rien ne part tant qu'il manque un
//   champ ; le geste part avec la version attendue ; le refus des fondateurs se
//   dit en mots, dans la feuille ;
// - l'entretien ouvert montre la date, les fondateurs, les participants, les
//   comptes rendus et les entrees et sorties ; ajouter, retirer et consigner
//   passent chacun par une feuille ; hors ligne, aucun geste ;
// - sans port, la section dit qu'elle attend son branchement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/entretiens_direction_supabase.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_entretien_direction.dart';
import 'package:rewayah_academy/core/candidature/port_entretiens_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/admin_candidature/bloc_entretien.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import 'hote_candidature.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

const CapacitesCandidatures _caps = CapacitesCandidatures(
  peutLire: true,
  genreLecteurConnu: true,
  peutDecider: true,
  peutChoisirParticipants: true,
  peutMenerEntretien: true,
  fondateursExiges: 2,
  gestes: <String, bool>{
    'planifierEntretien': true,
    'consignerEntretien': true,
  },
);

const ResultatGeste _resultat = ResultatGeste(
  candidature: EtatApresGeste(
    version: 4,
    issue: IssueCandidature.enCours,
    enPause: false,
  ),
);

class _FauxEntretiens implements PortEntretiensDirection {
  _FauxEntretiens({
    this.liste = const <EntretienCandidature>[],
    this.detail,
    this.refusPlanifier,
  });

  List<EntretienCandidature> liste;
  DetailEntretien? detail;
  Exception? refusPlanifier;

  final List<Map<String, Object?>> planifies = <Map<String, Object?>>[];
  final List<(String, String)> ajouts = <(String, String)>[];
  final List<(String, String)> retraits = <(String, String)>[];
  final List<(IssueEntretien, String?, int)> consignes =
      <(IssueEntretien, String?, int)>[];

  static const List<PersonnelEntretien> personnelTest = <PersonnelEntretien>[
    PersonnelEntretien(
      profilId: 'p-hafsa',
      prenom: 'Hafsa',
      nom: 'Kader',
      fondateur: true,
    ),
    PersonnelEntretien(
      profilId: 'p-salma',
      prenom: 'Salma',
      nom: 'Idrissi',
      fondateur: true,
    ),
    PersonnelEntretien(profilId: 'p-leila', prenom: 'Leila', nom: 'Benkacem'),
  ];

  @override
  Future<List<EntretienCandidature>> entretiens(String candidatureId) async =>
      liste;

  @override
  Future<DetailEntretien> lire(String sessionId) async => detail!;

  @override
  Future<List<PersonnelEntretien>> personnel(String candidatureId) async =>
      personnelTest;

  @override
  Future<ResultatGeste> planifier({
    required String candidatureId,
    required DateTime debut,
    required int dureeMinutes,
    required List<String> participants,
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    planifies.add(<String, Object?>{
      'candidature': candidatureId,
      'debut': debut,
      'duree': dureeMinutes,
      'participants': participants,
      'version': versionAttendue,
      'cle': cleIdempotence,
    });
    if (refusPlanifier case final Exception r) throw r;
    return _resultat;
  }

  @override
  Future<void> ajouter(String sessionId, String profilId) async =>
      ajouts.add((sessionId, profilId));

  @override
  Future<void> retirer(String sessionId, String profilId) async =>
      retraits.add((sessionId, profilId));

  @override
  Future<ResultatGeste> consigner({
    required String sessionId,
    required IssueEntretien issue,
    required String? motif,
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    consignes.add((issue, motif, versionAttendue));
    return _resultat;
  }
}

final EntretienCandidature _ouvert = EntretienCandidature(
  sessionId: 's1',
  candidatureId: 'c1',
  debut: DateTime.utc(2026, 11, 10, 14),
  fin: DateTime.utc(2026, 11, 10, 14, 45),
  participants: 2,
  fondateurs: 2,
);

final DetailEntretien _detailOuvert = DetailEntretien(
  sessionId: 's1',
  participants: const <ParticipantEntretien>[
    ParticipantEntretien(
      profilId: 'p-hafsa',
      prenom: 'Hafsa',
      nom: 'Kader',
      fondateur: true,
    ),
    ParticipantEntretien(
      profilId: 'p-salma',
      prenom: 'Salma',
      nom: 'Idrissi',
      fondateur: true,
    ),
  ],
  comptesRendus: <CompteRenduEntretien>[
    CompteRenduEntretien(
      auteurId: 'p-hafsa',
      texte: 'Lecture soignée, tajwid solide.',
      avis: AvisEntretien.favorable,
      ecritLe: DateTime.utc(2026, 11, 10, 15),
    ),
  ],
  presences: <PresenceEntretien>[
    PresenceEntretien(
      profilId: 'p-hafsa',
      arrivee: true,
      le: DateTime.utc(2026, 11, 10, 13, 58),
    ),
  ],
);

Future<void> _monter(
  WidgetTester tester,
  _FauxEntretiens? entretiens, {
  DetailCandidature? detail,
  CapacitesCandidatures capacites = _caps,
  bool horsLigne = false,
}) => monterCandidature(
  tester,
  port: FauxCandidaturesDirection(
    capacitesRendues: capacites,
    details: <DetailCandidature>[
      detail ??
          detailTest(
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
          ),
    ],
  ),
  horsLigne: horsLigne,
  largeur: 1440,
  surcharges: <Override>[
    portEntretiensDirectionProvider.overrideWithValue(entretiens),
  ],
);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Adaptateur', () {
    test('les refus propres a l\'entretien', () {
      expect(
        () => refusEntretien(<String, dynamic>{
          'erreur': 'fondateurs_insuffisants',
          'exiges': 2,
          'presents': 1,
        }),
        throwsA(
          isA<FondateursInsuffisants>()
              .having((FondateursInsuffisants f) => f.exiges, 'exiges', 2)
              .having((FondateursInsuffisants f) => f.presents, 'presents', 1),
        ),
      );
      expect(
        () =>
            refusEntretien(<String, dynamic>{'erreur': 'compte_rendu_requis'}),
        throwsA(isA<CompteRenduRequis>()),
      );
      expect(
        () => refusEntretien(<String, dynamic>{
          'erreur': 'entretien_deja_consigne',
        }),
        throwsA(isA<EntretienConsigne>()),
      );
    });

    test('« absente » : l\'entretien ou la candidature, selon le geste', () {
      expect(
        () => refusEntretien(<String, dynamic>{
          'erreur': 'absente',
        }, absenteEstEntretien: true),
        throwsA(isA<EntretienIntrouvable>()),
      );
      expect(
        () => refusEntretien(<String, dynamic>{'erreur': 'absente'}),
        throwsA(isA<CandidatureIntrouvable>()),
      );
    });

    test('les refus du moteur passent au moteur', () {
      expect(
        () => refusEntretien(<String, dynamic>{
          'erreur': 'conflit_candidature',
          'versionCourante': 5,
        }),
        throwsA(isA<ConflitGeste>()),
      );
      expect(() => refusEntretien(<String, dynamic>{}), returnsNormally);
    });

    test('planifier : le debut en UTC, la version et la cle', () {
      final Map<String, dynamic> p = parametresPlanifier(
        candidatureId: 'c1',
        debut: DateTime.utc(2026, 11, 10, 14),
        dureeMinutes: 45,
        participants: const <String>['p1', 'p2'],
        versionAttendue: 3,
        cleIdempotence: 'cand-x',
      );
      expect(p['p_debut'], '2026-11-10T14:00:00.000Z');
      expect(p['p_version_attendue'], 3);
      expect(p['p_cle_idempotence'], 'cand-x');
      expect(p['p_participants'], const <String>['p1', 'p2']);
    });

    test('seuls les entretiens de la candidature sont gardes', () {
      final List<EntretienCandidature> l = entretiensDepuisJson(<Object?>[
        <String, Object?>{
          'session_id': 's1',
          'candidature_id': 'c1',
          'debut': '2026-11-10T14:00:00+00:00',
          'fin': '2026-11-10T14:45:00+00:00',
          'participants': 2,
          'fondateurs': 1,
        },
        <String, Object?>{
          'session_id': 's2',
          'candidature_id': 'c2',
          'debut': '2026-11-11T14:00:00+00:00',
          'fin': '2026-11-11T14:45:00+00:00',
        },
        <String, Object?>{'session_id': 's3', 'candidature_id': 'c1'},
      ], 'c1');
      expect(l.single.sessionId, 's1');
      expect(l.single.dureeMinutes, 45);
      expect(l.single.ouvert, isTrue);
    });

    test('les trois capacites de V1-a', () {
      final CapacitesCandidatures c = CapacitesCandidatures.depuisJson(
        const <String, dynamic>{
          'peutPoserFondateur': true,
          'peutChoisirParticipants': true,
          'fondateursExiges': 2,
        },
      );
      expect(c.peutPoserFondateur, isTrue);
      expect(c.peutChoisirParticipants, isTrue);
      expect(c.fondateursExiges, 2);
      final CapacitesCandidatures sans = CapacitesCandidatures.depuisJson(
        const <String, dynamic>{'fondateursExiges': null},
      );
      expect(sans.peutPoserFondateur, isFalse);
      expect(sans.fondateursExiges, isNull);
    });
  });

  group('Planifier', () {
    testWidgets('sans port : la section attend son branchement', (
      WidgetTester tester,
    ) async {
      await _monter(tester, null);
      expect(
        find.descendant(
          of: find.byKey(SectionEntretien.cle),
          matching: find.text(t.commun.etats.branchementServeur),
        ),
        findsOneWidget,
      );
    });

    testWidgets('propose seulement quand la candidature attend un entretien', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxEntretiens(),
        detail: detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.decisionEnAttente,
        ),
      );
      expect(find.text(t.admin.candidatures.entretien.aucun), findsOneWidget);
      expect(find.byKey(SectionEntretien.clePlanifier), findsNothing);
    });

    testWidgets('hors ligne : aucun geste', (WidgetTester tester) async {
      await _monter(tester, _FauxEntretiens(), horsLigne: true);
      expect(find.byKey(SectionEntretien.clePlanifier), findsNothing);
    });

    testWidgets('rien ne part tant qu\'il manque un champ, puis le geste part '
        'avec la version attendue', (WidgetTester tester) async {
      final _FauxEntretiens port = _FauxEntretiens();
      await _monter(tester, port);
      final f = t.admin.candidatures.entretien.feuille;
      await _toucher(tester, find.byKey(SectionEntretien.clePlanifier));
      expect(_cle('feuille-planifier-entretien'), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.entretien.minimum(n: '2')),
        findsWidgets,
      );

      await _toucher(tester, _cle('entretien-valider'));
      expect(port.planifies, isEmpty);
      expect(find.text(f.jourManquant), findsOneWidget);
      expect(find.text(f.heureManquante), findsOneWidget);
      expect(find.text(f.participantsManquants), findsOneWidget);

      tester
          .widget<ChampDate>(find.byType(ChampDate))
          .onChoix(DateTime(2026, 10, 30));
      tester
          .widget<MenuFiltre<int>>(_cle('entretien-heure'))
          .onChoix(14 * 60 + 30);
      await tester.pumpAndSettle();
      await _toucher(tester, _cle('personnel-p-hafsa'));
      await _toucher(tester, _cle('personnel-p-leila'));
      expect(find.text(f.fondateursChoisis(n: '1')), findsOneWidget);

      await _toucher(tester, _cle('entretien-valider'));
      final Map<String, Object?> envoi = port.planifies.single;
      expect(envoi['debut'], DateTime(2026, 10, 30, 14, 30));
      expect(envoi['duree'], 45);
      expect(envoi['participants'], <String>['p-hafsa', 'p-leila']);
      expect(envoi['version'], 3);
      expect(envoi['cle'], isA<String>());
      expect(_cle('feuille-planifier-entretien'), findsNothing);
      expect(
        find.text(t.admin.candidatures.entretien.retours.planifie),
        findsOneWidget,
      );
    });

    testWidgets('le refus des fondateurs se dit en mots, dans la feuille', (
      WidgetTester tester,
    ) async {
      final _FauxEntretiens port = _FauxEntretiens(
        refusPlanifier: const FondateursInsuffisants(exiges: 2, presents: 1),
      );
      await _monter(tester, port);
      await _toucher(tester, find.byKey(SectionEntretien.clePlanifier));
      tester
          .widget<ChampDate>(find.byType(ChampDate))
          .onChoix(DateTime(2026, 10, 30));
      tester.widget<MenuFiltre<int>>(_cle('entretien-heure')).onChoix(10 * 60);
      await tester.pumpAndSettle();
      await _toucher(tester, _cle('personnel-p-hafsa'));
      await _toucher(tester, _cle('entretien-valider'));
      expect(_cle('feuille-planifier-entretien'), findsOneWidget);
      expect(
        find.text(
          t.admin.candidatures.entretien.refus.fondateurs(
            exiges: '2',
            presents: '1',
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('Entretien ouvert', () {
    testWidgets('date, fondateurs, participants, compte rendu, entrees', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxEntretiens(
          liste: <EntretienCandidature>[_ouvert],
          detail: _detailOuvert,
        ),
        detail: detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienPlanifie,
        ),
      );
      final e = t.admin.candidatures.entretien;
      expect(find.text(e.fondateurs(n: '2')), findsOneWidget);
      expect(find.text(e.minimum(n: '2')), findsOneWidget);
      expect(find.text('Hafsa Kader'), findsWidgets);
      expect(find.text('Salma Idrissi'), findsOneWidget);
      expect(find.text('Lecture soignée, tajwid solide.'), findsOneWidget);
      expect(find.text(e.avis.favorable), findsOneWidget);
      expect(find.textContaining('Hafsa Kader\u2069 à'), findsOneWidget);
      expect(find.byKey(SectionEntretien.clePlanifier), findsNothing);
    });

    testWidgets('ajouter, retirer, consigner : chacun par sa feuille', (
      WidgetTester tester,
    ) async {
      final _FauxEntretiens port = _FauxEntretiens(
        liste: <EntretienCandidature>[_ouvert],
        detail: _detailOuvert,
      );
      await _monter(
        tester,
        port,
        detail: detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienPlanifie,
        ),
      );

      // Ajouter : seul le personnel qui ne participe pas encore est propose.
      await _toucher(tester, _cle('entretien-ajouter'));
      expect(_cle('personnel-p-hafsa'), findsNothing);
      await _toucher(tester, _cle('personnel-p-leila'));
      await _toucher(tester, _cle('entretien-valider'));
      expect(port.ajouts, <(String, String)>[('s1', 'p-leila')]);
      expect(
        find.text(
          t.admin.candidatures.entretien.retours.ajoute(nom: 'Leila Benkacem'),
        ),
        findsOneWidget,
      );

      // Retirer : une confirmation, puis le geste.
      await _toucher(tester, _cle('entretien-retirer-p-salma'));
      expect(_cle('feuille-retirer-participant'), findsOneWidget);
      await _toucher(tester, _cle('entretien-valider'));
      expect(port.retraits, <(String, String)>[('s1', 'p-salma')]);

      // Consigner : un motif pour toute issue sauf « tenu ».
      await _toucher(tester, _cle('entretien-consigner'));
      await _toucher(tester, _cle('issue-annule'));
      await _toucher(tester, _cle('entretien-valider'));
      expect(port.consignes, isEmpty);
      await tester.enterText(_cle('entretien-motif'), 'Indisponible.');
      await tester.pumpAndSettle();
      await _toucher(tester, _cle('entretien-valider'));
      expect(port.consignes.single, (
        IssueEntretien.annule,
        'Indisponible.',
        3,
      ));
    });

    testWidgets('sans le droit de choisir : ni ajouter ni retirer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxEntretiens(
          liste: <EntretienCandidature>[_ouvert],
          detail: _detailOuvert,
        ),
        capacites: const CapacitesCandidatures(
          peutLire: true,
          genreLecteurConnu: true,
        ),
        detail: detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienPlanifie,
        ),
      );
      expect(_cle('entretien-ajouter'), findsNothing);
      expect(_cle('entretien-retirer-p-salma'), findsNothing);
      expect(_cle('entretien-consigner'), findsNothing);
      expect(find.text('Salma Idrissi'), findsOneWidget);
    });
  });
}
