// DISPO-1, reprise apres verification croisee : les echecs d'enregistrement
// d'une plage selon leur SENS (ajout ou retrait non confirme) et le nouvel
// essai qui renvoie TOUTES les operations encore non confirmees.
//
// Contre-epreuve : les deux premiers tests echouent sur eb0a8b08 (message
// « aucune heure n'est enregistree » pour des retraits refuses ; second envoi
// qui oublie l'heure 22 et se ferme sur un faux succes). Ils n'emploient que
// des cles presentes des deux cotes, plus des textes litteraux, pour que
// l'ancien code compile.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/creneaux/feuille_plage.dart';
import 'package:rewayah_academy/features/creneaux/plages.dart';

import '../../support/harnais.dart';

const String _monId = 't1';

const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

List<Creneau> _plage(int jour, int de, int a) => <Creneau>[
  for (int h = de; h < a; h++)
    Creneau(jour: jour, heure: h, fuseau: 'Europe/Paris'),
];

/// Refuse les retraits de certaines heures ; peut aussi refuser la lecture
/// des Classes engagees.
class _Planning extends FauxServicePlanning {
  final Set<int> retraitsRefuses = <int>{};
  bool affectationsEnEchec = false;

  @override
  Future<void> retirer({
    required String profilId,
    required Creneau creneau,
  }) async {
    if (retraitsRefuses.contains(creneau.heure)) {
      throw StateError('refus ${creneau.heure}');
    }
    return super.retirer(profilId: profilId, creneau: creneau);
  }

  @override
  Future<List<Affectation>> affectations() async {
    if (affectationsEnEchec) {
      throw StateError('lecture');
    }
    return super.affectations();
  }
}

/// Un reseau qui peut tomber pendant le test.
class _Reseau implements ServiceReseau {
  final StreamController<bool> flux = StreamController<bool>.broadcast();
  bool courant = false;

  @override
  Stream<bool> horsLigne() async* {
    yield courant;
    yield* flux.stream;
  }

  void couper() {
    courant = true;
    flux.add(true);
  }
}

Future<void> _monter(
  WidgetTester tester,
  _Planning planning, {
  ServiceReseau? reseau,
}) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
        serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
        servicePlanningProvider.overrideWithValue(planning),
        serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
        serviceReseauProvider.overrideWithValue(reseau ?? FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const CreneauxPage(),
        ),
      ),
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

Finder get _feuille => find.byType(FeuillePlage);

Finder _dansFeuille(String texte) =>
    find.descendant(of: _feuille, matching: find.text(texte));

String _de(int h) => t.enseignant.creneaux.plageDe(heure: '$h');
String _a(int h) => t.enseignant.creneaux.plageA(heure: '$h');

Future<void> _choisir(
  WidgetTester tester, {
  required String courant,
  required String voulu,
}) async {
  await _toucher(tester, _dansFeuille(courant));
  await _toucher(tester, find.text(voulu).last);
}

/// Les textes de la feuille, mis bout a bout.
String _texteFeuille(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: _feuille, matching: find.byType(Text)),
    )
    .map((Text w) => w.data ?? w.textSpan?.toPlainText() ?? '')
    .join(' | ');

Set<int> _heuresPosees(_Planning p, int jour) => <int>{
  for (final Creneau c in p.creneaux[_monId] ?? const <Creneau>[])
    if (c.jour == jour) c.heure,
};

void main() {
  testWidgets('retraits refuses : « retrait non confirme », les heures '
      'nommees, jamais « aucune heure enregistree »', (
    WidgetTester tester,
  ) async {
    final _Planning planning = _Planning()
      ..creneaux[_monId] = _plage(1, 17, 23)
      ..retraitsRefuses.addAll(<int>{21, 22});
    await _monter(tester, planning);

    await _toucher(tester, find.text(_de(17)));
    await _choisir(tester, courant: _a(23), voulu: _a(21));
    await _toucher(tester, find.text(t.enseignant.creneaux.enregistrerPlage));

    final String feuille = _texteFeuille(tester);
    expect(_feuille, findsOneWidget);
    expect(feuille, contains('Retrait non confirmé'));
    expect(feuille, contains(nommerHeure((jour: 1, heure: 21))));
    expect(feuille, contains(nommerHeure((jour: 1, heure: 22))));
    expect(feuille, isNot(contains("aucune heure n'est enregistrée")));
    expect(feuille, isNot(contains('bien enregistrées')));
    expect(feuille, isNot(contains('Ajout non confirmé')));
    // 17 h a 21 h reste pose : rien n'a ete pretendu sur ces heures.
    expect(_heuresPosees(planning, 1), <int>{17, 18, 19, 20, 21, 22});
  });

  testWidgets('nouvel essai : TOUTES les operations non confirmees '
      'repartent, succes seulement quand toutes passent', (
    WidgetTester tester,
  ) async {
    final _Planning planning = _Planning()
      ..creneaux[_monId] = _plage(1, 17, 23)
      ..retraitsRefuses.addAll(<int>{17, 22});
    await _monter(tester, planning);

    // Lundi 17-23 ramene a 19-20 : retirer 17, 18, 20, 21, 22.
    await _toucher(tester, find.text(_de(17)));
    await _choisir(tester, courant: _de(17), voulu: _de(19));
    await _choisir(tester, courant: _a(23), voulu: _a(20));
    await _toucher(tester, find.text(t.enseignant.creneaux.enregistrerPlage));

    expect(_feuille, findsOneWidget);
    expect(_heuresPosees(planning, 1), <int>{17, 19, 22});

    planning.retraitsRefuses.clear();
    await _toucher(tester, find.text(t.enseignant.creneaux.enregistrerPlage));

    // 17 ET 22 repartent ; le serveur ne garde que 19.
    expect(_heuresPosees(planning, 1), <int>{19});
    expect(_feuille, findsNothing);
    expect(
      find.text(
        t.enseignant.creneaux.plageEnregistree(
          jours: 'lundi',
          de: _de(19),
          a: _a(20),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('suppression refusee : retrait non confirme, quoi faire', (
    WidgetTester tester,
  ) async {
    final _Planning planning = _Planning()
      ..creneaux[_monId] = _plage(2, 17, 19)
      ..retraitsRefuses.add(18);
    await _monter(tester, planning);

    await _toucher(tester, find.text(_de(17)));
    await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));

    final String feuille = _texteFeuille(tester);
    expect(_feuille, findsOneWidget);
    expect(
      feuille,
      contains(
        t.enseignant.creneaux.retraitNonConfirme(
          heures: nommerHeure((jour: 2, heure: 18)),
        ),
      ),
    );
    expect(
      feuille,
      contains(
        t.enseignant.creneaux.echecQuoiFaire(
          action: t.enseignant.creneaux.supprimerPlage,
        ),
      ),
    );

    planning.retraitsRefuses.clear();
    await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));
    expect(_heuresPosees(planning, 2), isEmpty);
    expect(_feuille, findsNothing);
  });

  testWidgets('engagements non lus : dit, relance, et tout retrait est '
      'confirme par prudence', (WidgetTester tester) async {
    final _Planning planning = _Planning()
      ..creneaux[_monId] = _plage(4, 9, 10)
      ..affectationsEnEchec = true;
    await _monter(tester, planning);

    expect(
      find.text(t.enseignant.creneaux.engagementsNonConfirmes),
      findsOneWidget,
    );
    expect(find.text(t.commun.reessayer), findsOneWidget);

    await _toucher(tester, find.text(_de(9)));
    await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));
    expect(
      find.text(
        t.enseignant.creneaux.retraitSansEngagements(
          heures: nommerHeure((jour: 4, heure: 9)),
        ),
      ),
      findsOneWidget,
    );
    await _toucher(tester, find.text(t.commun.annuler));
    expect(planning.retires, isEmpty);
  });

  testWidgets('reseau perdu feuille ouverte : Enregistrer n est plus rendu, '
      'la feuille dit pourquoi', (WidgetTester tester) async {
    final _Reseau reseau = _Reseau();
    final _Planning planning = _Planning()
      ..creneaux[_monId] = _plage(1, 17, 19);
    await _monter(tester, planning, reseau: reseau);

    await _toucher(tester, find.text(_de(17)));
    expect(
      _dansFeuille(t.enseignant.creneaux.enregistrerPlage),
      findsOneWidget,
    );

    reseau.couper();
    await tester.pumpAndSettle();

    expect(_dansFeuille(t.enseignant.creneaux.enregistrerPlage), findsNothing);
    expect(_dansFeuille(t.enseignant.creneaux.supprimerPlage), findsNothing);
    expect(
      _dansFeuille(t.enseignant.creneaux.horsLigneFeuille),
      findsOneWidget,
    );
  });
}
