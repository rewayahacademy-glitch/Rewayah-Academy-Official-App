// PE (18/10/2026) : le code de conduite de l'enseignant.
//
// Ce que le test prouve : le texte est lu en entier avec sa case, jamais
// precochee ; sans case, rien n'est envoye et la phrase dit pourquoi ; avec la
// case, l'acceptation part par le mecanisme des consentements existant, avec
// la sorte et la version du code (celle que la base exige) ; une acceptation
// deja faite est montree avec sa date et sa version, sans case ; une panne
// d'enregistrement se dit et laisse la case cochee ; une panne de lecture se
// dit et se relance ; aucune acceptation n'est presumee.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_consentements.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/code_conduite/code_conduite.dart';

import '../../support/harnais.dart';
import '../../teaching_core/h/support/hote_h.dart';

/// Un port qui garde ce qu'il enregistre, et le relit ensuite.
class _Port extends FauxPortConsentements {
  @override
  Future<void> accepter({
    required SorteContrat sorte,
    required String version,
  }) async {
    await super.accepter(sorte: sorte, version: version);
    signeesRendues = <Acceptation>[
      Acceptation(
        sorte: sorte,
        version: version,
        accepteeLe: DateTime(2026, 10, 18, 9),
      ),
      ...signeesRendues,
    ];
  }
}

Future<void> _monter(
  WidgetTester tester,
  FauxPortConsentements port, {
  bool horsLigne = false,
}) async {
  telephone(tester);
  await tester.pumpWidget(
    hoteH(
      const ContenuCodeConduite(),
      surcharges: <Override>[
        portConsentementsProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith(
          (Ref ref) => Stream<bool>.value(horsLigne),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  final String versionCode = VersionsContrat.pour(
    SorteContrat.codeConduiteEnseignant,
  );

  group('PE : code de conduite de l enseignant', () {
    test('la sorte et la version sont celles que la base exige', () {
      expect(
        SorteContrat.codeConduiteEnseignant.valeurSql,
        'teacher_conduct_code',
      );
      expect(versionCode, '2026-10-19');
      expect(acceptationCodeConduite(<Acceptation>[]), isNull);
      // Une autre version signee ne vaut pas acceptation de la courante.
      expect(
        acceptationCodeConduite(<Acceptation>[
          Acceptation(
            sorte: SorteContrat.codeConduiteEnseignant,
            version: 'ancienne',
            accepteeLe: DateTime(2026),
          ),
        ]),
        isNull,
      );
    });

    test('le texte definitif du 19/10/2026 : audio garde, parent, bouton exact', () {
      final List<String> r = t.codeConduite.regles;
      // La phrase sur l'audio est gardee (decision repetee du directeur).
      expect(r[0], contains('enregistré en audio'));
      expect(r[0], contains('Un parent peut aussi assister au cours'));
      expect(r[1], contains('Vous voyez le prénom de vos élèves'));
      expect(r[3], contains('hors de l\'application'));
      expect(r[6], contains('prédicateurs'));
      // Le libelle du bouton et de la categorie sont ceux de l'application.
      expect(
        r[7],
        contains('\u00ab\u00a0${t.tc.parcours.signalement.titre}\u00a0\u00bb'),
      );
      expect(
        r[7],
        contains(
          '\u00ab\u00a0${t.tc.parcours.signalement.categorieValeur.securiteEnfant}\u00a0\u00bb',
        ),
      );
      for (final String regle in r) {
        expect(regle, isNot(contains('\u2014')));
      }
    });

    testWidgets('le texte est lu en entier, la case n est pas precochee', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port();
      await _monter(tester, port);

      expect(find.text(t.codeConduite.intro), findsOneWidget);
      for (final String regle in t.codeConduite.regles) {
        expect(find.text(regle), findsOneWidget);
      }
      expect(t.codeConduite.regles, hasLength(9));
      final Checkbox casee = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(casee.value, isFalse);
      expect(find.byKey(ContenuCodeConduite.accepteKey), findsNothing);
    });

    testWidgets('sans la case, rien n est envoye et la phrase dit pourquoi', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port();
      await _monter(tester, port);

      await _toucher(tester, find.byKey(ContenuCodeConduite.accepterKey));

      expect(port.accepteEnregistre, isEmpty);
      expect(find.text(t.contrat.caseRequise), findsOneWidget);
    });

    testWidgets('avec la case, l acceptation part avec la version du code', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port();
      await _monter(tester, port);

      await _toucher(tester, find.byKey(ContenuCodeConduite.caseKey));
      await _toucher(tester, find.byKey(ContenuCodeConduite.accepterKey));

      expect(port.accepteEnregistre, hasLength(1));
      expect(
        port.accepteEnregistre.single.sorte,
        SorteContrat.codeConduiteEnseignant,
      );
      expect(port.accepteEnregistre.single.version, versionCode);
      // L'ecran relit : plus de case, la date et la version sont dites.
      expect(find.byKey(ContenuCodeConduite.caseKey), findsNothing);
      expect(
        find.text(
          t.codeConduite.accepteLe(date: '18/10/2026', version: versionCode),
        ),
        findsOneWidget,
      );
    });

    testWidgets('une acceptation deja faite est montree, figee', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port()
        ..signeesRendues = <Acceptation>[
          Acceptation(
            sorte: SorteContrat.codeConduiteEnseignant,
            version: versionCode,
            accepteeLe: DateTime(2026, 10, 5),
          ),
        ];
      await _monter(tester, port);

      expect(find.byKey(ContenuCodeConduite.accepteKey), findsOneWidget);
      expect(find.byKey(ContenuCodeConduite.accepterKey), findsNothing);
      expect(
        find.text(
          t.codeConduite.accepteLe(date: '05/10/2026', version: versionCode),
        ),
        findsOneWidget,
      );
    });

    testWidgets('une panne d enregistrement se dit, la case reste cochee', (
      WidgetTester tester,
    ) async {
      final _FauxEchec port = _FauxEchec();
      await _monter(tester, port);

      await _toucher(tester, find.byKey(ContenuCodeConduite.caseKey));
      port.panneAAccepter = true;
      await _toucher(tester, find.byKey(ContenuCodeConduite.accepterKey));

      expect(find.text(t.codeConduite.erreur), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(port.accepteEnregistre, isEmpty);
    });

    testWidgets('hors ligne, la phrase du contrat est dite', (
      WidgetTester tester,
    ) async {
      final _FauxEchec port = _FauxEchec();
      await _monter(tester, port, horsLigne: true);

      await _toucher(tester, find.byKey(ContenuCodeConduite.caseKey));
      port.panneAAccepter = true;
      await _toucher(tester, find.byKey(ContenuCodeConduite.accepterKey));

      expect(find.text(t.contrat.horsLigne), findsOneWidget);
    });

    testWidgets('lecture impossible : la panne se dit et se relance', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port()..erreurAJeter = Exception('reseau');
      await _monter(tester, port);

      expect(find.byKey(ContenuCodeConduite.erreurLectureKey), findsOneWidget);
      expect(find.text(t.codeConduite.erreurLecture), findsOneWidget);
      // Aucune acceptation n'est presumee sur une lecture en panne.
      expect(find.byKey(ContenuCodeConduite.accepteKey), findsNothing);

      port.erreurAJeter = null;
      await _toucher(tester, find.text(t.commun.reessayer));
      expect(find.byKey(ContenuCodeConduite.caseKey), findsOneWidget);
    });
  });
}

/// Un port dont l'ecriture peut tomber en panne, la lecture restant bonne.
class _FauxEchec extends FauxPortConsentements {
  bool panneAAccepter = false;

  @override
  Future<void> accepter({
    required SorteContrat sorte,
    required String version,
  }) async {
    if (panneAAccepter) {
      throw Exception('panne');
    }
    await super.accepter(sorte: sorte, version: version);
  }
}
