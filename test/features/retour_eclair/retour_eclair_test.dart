// NON-BRANCHE-LIVRAISON 5 (08/11/2026) : le Retour eclair.
// - Eleve : apres une seance terminee, la carte pose la question quand le
//   serveur en pose une ; l'envoi est instantane, et revient a l'etat
//   d'avant, avec une phrase et « Reessayer », s'il echoue
//   (DECISION-FLUIDITE §1).
// - Enseignant : la tendance de comprehension de la Classe, agregee, au-dessus
//   du seuil ; un echec dit comme une panne.
// Chaque test ci-dessous est ROUGE sans ce lot.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/tc_flux_academique/carte_feedback_seance.dart';
import 'package:rewayah_academy/features/tc_flux_academique/tendance_feedback_classe.dart';

import '../../support/harnais.dart';

const QuestionFeedback _question = QuestionFeedback(
  id: 'comprehension',
  intitule: 'Avez-vous compris la leçon ?',
  libelles: <ReponseFeedback, String>{
    ReponseFeedback.difficile: 'Difficile',
    ReponseFeedback.bien: 'Bien',
    ReponseFeedback.tresBien: 'Très bien',
  },
);

class _Port implements PortFeedback {
  _Port({
    this.echecs = const <MotifEchecFeedback?>[],
    this.tendanceLue,
    this.question = _question,
  });

  final QuestionFeedback question;

  /// Le resultat de chaque envoi, dans l'ordre (`null` : reussi).
  final List<MotifEchecFeedback?> echecs;
  final Future<TendanceFeedback> Function()? tendanceLue;
  final List<ReponseFeedback> envois = <ReponseFeedback>[];

  @override
  Future<QuestionFeedback?> questionPour(String sessionId) async => question;

  @override
  Future<void> soumettre({
    required String sessionId,
    required String questionId,
    required ReponseFeedback reponse,
  }) async {
    final int i = envois.length;
    envois.add(reponse);
    final MotifEchecFeedback? motif = i < echecs.length ? echecs[i] : null;
    if (motif != null) throw EchecFeedback(motif);
  }

  @override
  Future<TendanceFeedback> tendance({required String groupeId}) =>
      tendanceLue!();
}

Future<void> _monter(
  WidgetTester tester,
  Widget ecran,
  _Port port, {
  bool pleinEcran = false,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      pleinEcran ? ecran : Scaffold(body: SingleChildScrollView(child: ecran)),
      surcharges: <Override>[portFeedbackProvider.overrideWithValue(port)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('eleve', () {
    testWidgets('fin de seance : la carte suit le resultat', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port();
      await _monter(
        tester,
        ResultatSeance(
          issue: IssueSeance.terminee,
          onRetour: () {},
          complement: const CarteFeedbackSeance(sessionId: 's1'),
        ),
        port,
        pleinEcran: true,
      );
      expect(
        find.text(t.tc.parcours.feedback.comprehension.intitule),
        findsOneWidget,
      );
      await tester.tap(find.text(t.tc.parcours.feedback.comprehension.bien));
      await tester.pumpAndSettle();
      expect(port.envois, <ReponseFeedback>[ReponseFeedback.bien]);
      expect(find.text(t.tc.parcours.feedback.merci), findsOneWidget);
    });

    testWidgets('envoi perdu : retour a la question, une phrase et '
        '« Reessayer » qui renvoie la meme reponse', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(
        echecs: const <MotifEchecFeedback?>[MotifEchecFeedback.ecriture, null],
      );
      await _monter(tester, const CarteFeedbackSeance(sessionId: 's1'), port);
      await tester.tap(
        find.text(t.tc.parcours.feedback.comprehension.tresBien),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.tc.parcours.feedback.merci), findsNothing);
      expect(find.byKey(CarteFeedbackSeance.nonPartieKey), findsOneWidget);
      expect(
        find.text(t.tc.parcours.feedback.comprehension.intitule),
        findsOneWidget,
      );
      await tester.tap(find.byKey(CarteFeedbackSeance.reessayerKey));
      await tester.pumpAndSettle();
      expect(port.envois, <ReponseFeedback>[
        ReponseFeedback.tresBien,
        ReponseFeedback.tresBien,
      ]);
      expect(find.text(t.tc.parcours.feedback.merci), findsOneWidget);
      expect(find.byKey(CarteFeedbackSeance.nonPartieKey), findsNothing);
    });

    testWidgets('reponse deja deposee (double tap) : le merci reste', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(
        echecs: const <MotifEchecFeedback?>[MotifEchecFeedback.dejaDepose],
      );
      await _monter(tester, const CarteFeedbackSeance(sessionId: 's1'), port);
      await tester.tap(find.text(t.tc.parcours.feedback.comprehension.bien));
      await tester.pumpAndSettle();
      expect(find.text(t.tc.parcours.feedback.merci), findsOneWidget);
      expect(find.byKey(CarteFeedbackSeance.nonPartieKey), findsNothing);
    });

    test('la vraie salle monte la carte apres une seance terminee', () {
      final String salle = File('lib/features/salle/salle_page.dart')
          .readAsStringSync();
      expect(
        salle,
        contains(
          'complement: sortie == IssueSeance.terminee\n'
          '            ? CarteFeedbackSeance(sessionId: widget.seanceId)',
        ),
      );
    });
  });

  group('enseignant', () {
    testWidgets('au-dessus du seuil : la repartition, anonyme', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const BlocTendanceFeedback(groupeId: 'c1'),
        _Port(
          tendanceLue: () async => const TendanceFeedback(
            groupeId: 'c1',
            nombreEchantillons: 10,
            seuilMinimum: 5,
            visibleParEnseignant: true,
            repartition: <ReponseFeedback, double>{
              ReponseFeedback.difficile: 0.2,
              ReponseFeedback.bien: 0.5,
              ReponseFeedback.tresBien: 0.3,
            },
          ),
        ),
      );
      expect(find.byKey(BlocTendanceFeedback.visibleKey), findsOneWidget);
      final f = t.tc.parcours.feedback;
      expect(
        find.text(
          <String>[
            f.tendance.ligne(reponse: f.comprehension.difficile, part: '20'),
            f.tendance.ligne(reponse: f.comprehension.bien, part: '50'),
            f.tendance.ligne(reponse: f.comprehension.tresBien, part: '30'),
            f.tendance.anonyme,
          ].join('\n'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sous le seuil : la phrase, aucune part', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const BlocTendanceFeedback(groupeId: 'c1'),
        _Port(
          tendanceLue: () async => const TendanceFeedback(
            groupeId: 'c1',
            nombreEchantillons: 2,
            seuilMinimum: 5,
            visibleParEnseignant: false,
          ),
        ),
      );
      expect(find.byKey(BlocTendanceFeedback.sousSeuilKey), findsOneWidget);
      expect(find.text(t.tc.parcours.feedback.tendance.sousSeuil), findsOne);
    });

    testWidgets('echec : dit comme une panne, relu au toucher', (
      WidgetTester tester,
    ) async {
      int appels = 0;
      await _monter(
        tester,
        const BlocTendanceFeedback(groupeId: 'c1'),
        _Port(
          tendanceLue: () async {
            appels++;
            if (appels == 1) throw StateError('panne');
            return const TendanceFeedback(
              groupeId: 'c1',
              nombreEchantillons: 0,
              seuilMinimum: 5,
              visibleParEnseignant: false,
            );
          },
        ),
      );
      expect(find.byKey(BlocTendanceFeedback.echecKey), findsOneWidget);
      expect(
        find.text(t.tc.parcours.feedback.tendance.sousSeuil),
        findsNothing,
      );
      await tester.tap(find.text(t.tc.parcours.feedback.tendance.illisible));
      await tester.pumpAndSettle();
      expect(appels, 2);
      expect(find.byKey(BlocTendanceFeedback.sousSeuilKey), findsOneWidget);
    });

    testWidgets('pendant la lecture : rien', (WidgetTester tester) async {
      final Completer<TendanceFeedback> jamais = Completer<TendanceFeedback>();
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const Scaffold(body: BlocTendanceFeedback(groupeId: 'c1')),
          surcharges: <Override>[
            portFeedbackProvider.overrideWithValue(
              _Port(tendanceLue: () => jamais.future),
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.byKey(BlocTendanceFeedback.echecKey), findsNothing);
      expect(find.byKey(BlocTendanceFeedback.sousSeuilKey), findsNothing);
      expect(find.byKey(BlocTendanceFeedback.visibleKey), findsNothing);
    });

    testWidgets('sans serveur : rien, pas de « pas assez de retours » '
        'invente', (WidgetTester tester) async {
      await tester.pumpWidget(
        hote(const Scaffold(body: BlocTendanceFeedback(groupeId: 'c1'))),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BlocTendanceFeedback.sousSeuilKey), findsNothing);
      expect(find.byKey(BlocTendanceFeedback.echecKey), findsNothing);
    });

    test('la fiche de la classe monte la tendance', () {
      final String fiche = File(
        'lib/features/fiche_groupe/fiche_groupe_page.dart',
      ).readAsStringSync();
      expect(fiche, contains('BlocTendanceFeedback(groupeId: groupe.id)'));
    });
  });

  group('mots de la question', () {
    testWidgets('identifiant inconnu : aucune carte, jamais le texte du '
        'serveur', (WidgetTester tester) async {
      await _monter(
        tester,
        const CarteFeedbackSeance(sessionId: 's1'),
        _Port(
          question: const QuestionFeedback(
            id: 'inconnue',
            intitule: 'Texte francais du serveur',
            libelles: <ReponseFeedback, String>{
              ReponseFeedback.difficile: 'a',
              ReponseFeedback.bien: 'b',
              ReponseFeedback.tresBien: 'c',
            },
          ),
        ),
      );
      expect(find.text('Texte francais du serveur'), findsNothing);
      expect(find.byType(CarteFeedbackSeance), findsOneWidget);
      expect(find.text(t.tc.parcours.feedback.merci), findsNothing);
    });

    testWidgets('interface arabe : les mots arabes, jamais le francais du '
        'serveur', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      await _monter(
        tester,
        const CarteFeedbackSeance(sessionId: 's1'),
        _Port(),
      );
      expect(
        find.text(t.tc.parcours.feedback.comprehension.intitule),
        findsOneWidget,
      );
      expect(find.text(_question.intitule), findsNothing);
      expect(find.text('Bien'), findsNothing);
    });

    testWidgets('Interface guidee : la question tutoie', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: SingleChildScrollView(
              child: CarteFeedbackSeance(sessionId: 's1'),
            ),
          ),
          surcharges: <Override>[
            portFeedbackProvider.overrideWithValue(_Port()),
          ],
          mode: InterfaceMode.enfant,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.tc.parcours.feedback.comprehension.intituleTu),
        findsOneWidget,
      );
    });

    test('aucune etiquette du client ne contredit le sens d une valeur du '
        'serveur (0065)', () {
      // Les questions telles que la migration les pose.
      final String sql = File(
        'supabase/migrations/0065_feedback_questions_and_private_aggregate.sql',
      ).readAsStringSync();
      final RegExp ligne = RegExp(r"\('([a-z_]+)', '[^']*',\s*'(\{[^']*\})'\)");
      final Map<String, Map<String, dynamic>> serveur =
          <String, Map<String, dynamic>>{
            for (final RegExpMatch m in ligne.allMatches(sql))
              m.group(1)!: jsonDecode(m.group(2)!) as Map<String, dynamic>,
          };
      expect(serveur.keys.toSet(), <String>{
        'comprehension',
        'rythme',
        'participation',
      });
      // Le sens de chaque valeur, en francais : les mots du serveur, ou leur
      // equivalent declare ici. Un changement de l'un ou de l'autre fait
      // echouer ce test.
      const Map<String, Map<String, String>> equivalents =
          <String, Map<String, String>>{
            'comprehension': <String, String>{
              'Difficile': 'Pas vraiment',
              'Bien': 'Plutôt oui',
              'Très bien': 'Tout à fait',
            },
          };
      for (final MapEntry<String, Map<String, dynamic>> q in serveur.entries) {
        final TextesQuestionFeedback? client = TextesQuestionFeedback.pour(
          q.key,
          tutoiement: false,
        );
        expect(client, isNotNull, reason: 'question ${q.key} sans texte');
        for (final ReponseFeedback r in ReponseFeedback.values) {
          final String motServeur = q.value[r.valeurSql] as String;
          final String attendu = equivalents[q.key]?[motServeur] ?? motServeur;
          expect(
            client!.reponse(r),
            attendu,
            reason: '${q.key}.${r.valeurSql} : le serveur dit « $motServeur »',
          );
        }
      }
    });
  });
}
