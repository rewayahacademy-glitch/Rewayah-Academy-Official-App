// SALLE-2-ENTRETIEN (07/11/2026) : les creneaux d'entretien de la direction.
//
// Ce que le test prouve : la liste (moment, etat, cote, langues, personnes),
// le vide qui invite a ouvrir, l'erreur qui relit, le hors ligne sans geste,
// la capacite indisponible ; « Ouvrir un creneau » n'envoie rien d'incomplet
// et dit chaque manque, puis envoie cote, debut, duree, langues (ordre du
// questionnaire) et personnes ; un refus du serveur reste dans la feuille,
// en mots ; « Retirer ce creneau » n'existe que sur un creneau libre.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/creneaux_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_entretien_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/admin_candidature/creneaux_entretien_page.dart';

import '../../support/monter_recrutement.dart';

const String _chemin = '/admin/personnes/candidatures/creneaux';

class _FauxCreneaux implements PortCreneauxDirection {
  _FauxCreneaux(this.creneaux, {this.refusOuvrir, this.erreurLire});

  List<CreneauDirection> creneaux;
  Exception? refusOuvrir;
  Exception? erreurLire;
  final List<Map<String, Object?>> ouverts = <Map<String, Object?>>[];
  final List<String> annules = <String>[];

  @override
  Future<List<CreneauDirection>> lister({int jours = 30}) async {
    if (erreurLire != null) throw erreurLire!;
    return creneaux;
  }

  @override
  Future<List<PersonnelEntretien>> personnel() async =>
      const <PersonnelEntretien>[
        PersonnelEntretien(
          profilId: 'p-un',
          prenom: 'Personne',
          nom: 'Une',
          fondateur: true,
        ),
        PersonnelEntretien(profilId: 'p-deux', prenom: 'Personne', nom: 'Deux'),
      ];

  @override
  Future<void> ouvrir({
    required String cote,
    required DateTime debut,
    required int dureeMinutes,
    required List<String> langues,
    required List<String> participants,
  }) async {
    if (refusOuvrir != null) throw refusOuvrir!;
    ouverts.add(<String, Object?>{
      'cote': cote,
      'debut': debut,
      'duree': dureeMinutes,
      'langues': langues,
      'participants': participants,
    });
  }

  @override
  Future<void> annuler(String creneauId) async => annules.add(creneauId);
}

CreneauDirection _creneau(String id, EtatCreneau etat) => CreneauDirection(
  id: id,
  cote: 'male',
  debut: DateTime(2026, 11, 12, 10),
  fin: DateTime(2026, 11, 12, 10, 45),
  langues: const <String>['francais', 'poular'],
  participants: 2,
  fondateurs: 1,
  etat: etat,
);

Future<void> _monter(
  WidgetTester tester,
  PortCreneauxDirection? port, {
  bool horsLigne = false,
}) => monterRecrutement(
  tester,
  chemin: _chemin,
  ecran: (_) => const CreneauxEntretienPage(),
  autres: <String>['/admin/personnes/candidatures'],
  surcharges: <Override>[
    if (port != null) portCreneauxDirectionProvider.overrideWithValue(port),
  ],
  horsLigne: horsLigne,
);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await laisser(tester);
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final c = t.admin.candidatures.creneaux;

  testWidgets('la liste : moment, etat, cote, langues, personnes ; retirer '
      'seulement un creneau libre', (WidgetTester tester) async {
    final _FauxCreneaux port = _FauxCreneaux(<CreneauDirection>[
      _creneau('libre', EtatCreneau.libre),
      _creneau('pris', EtatCreneau.reserve),
    ]);
    await _monter(tester, port);
    expect(_cle('creneau-libre'), findsOneWidget);
    expect(_cle('creneau-pris'), findsOneWidget);
    expect(find.textContaining(c.libre), findsOneWidget);
    expect(find.textContaining(c.reserve), findsOneWidget);
    expect(find.textContaining('Français'), findsWidgets);
    expect(_cle('creneau-retirer-libre'), findsOneWidget);
    expect(_cle('creneau-retirer-pris'), findsNothing);

    await _toucher(tester, _cle('creneau-retirer-libre'));
    await _toucher(tester, find.byKey(FeuilleRetirerCreneau.envoyerKey));
    expect(port.annules, <String>['libre']);
    expect(find.text(c.retireFait), findsOneWidget);
  });

  testWidgets('vide : la page invite a ouvrir un creneau', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _FauxCreneaux(<CreneauDirection>[]));
    expect(_cle('creneaux-vide'), findsOneWidget);
    expect(find.text(c.aucun), findsOneWidget);
    expect(find.text(c.ouvrir), findsOneWidget);
  });

  testWidgets('erreur : relire', (WidgetTester tester) async {
    await _monter(
      tester,
      _FauxCreneaux(<CreneauDirection>[], erreurLire: Exception('panne')),
    );
    expect(_cle('creneaux-erreur'), findsOneWidget);
  });

  testWidgets('port absent : capacite indisponible', (
    WidgetTester tester,
  ) async {
    await _monter(tester, null);
    expect(_cle('creneaux-indisponible'), findsOneWidget);
  });

  testWidgets('hors ligne : la liste reste, aucun geste', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      _FauxCreneaux(<CreneauDirection>[_creneau('libre', EtatCreneau.libre)]),
      horsLigne: true,
    );
    expect(_cle('creneau-libre'), findsOneWidget);
    expect(find.byKey(CreneauxEntretienPage.ouvrirKey), findsNothing);
    expect(_cle('creneau-retirer-libre'), findsNothing);
  });

  testWidgets('ouvrir : rien d\'incomplet ne part ; puis tout part, langues '
      'dans l\'ordre du questionnaire', (WidgetTester tester) async {
    final _FauxCreneaux port = _FauxCreneaux(<CreneauDirection>[
      _creneau('libre', EtatCreneau.libre),
    ]);
    await _monter(tester, port);
    await _toucher(tester, find.byKey(CreneauxEntretienPage.ouvrirKey));
    await _toucher(tester, find.byKey(FeuilleOuvrirCreneau.envoyerKey));
    expect(port.ouverts, isEmpty);
    expect(find.text(c.coteManquant), findsOneWidget);
    expect(find.text(c.languesManquantes), findsOneWidget);

    await _toucher(tester, _cle('creneau-cote-female'));
    tester
        .widget<ChampDate>(find.byType(ChampDate))
        .onChoix(DateTime(2026, 11, 20));
    tester.widget<MenuFiltre<int>>(_cle('creneau-heure')).onChoix(14 * 60);
    await tester.pumpAndSettle();
    await _toucher(tester, _cle('creneau-langue-francais'));
    await _toucher(tester, _cle('creneau-langue-poular'));
    await _toucher(tester, _cle('creneau-personnel-p-un'));
    await _toucher(tester, find.byKey(FeuilleOuvrirCreneau.envoyerKey));

    final Map<String, Object?> envoi = port.ouverts.single;
    expect(envoi['cote'], 'female');
    expect(envoi['debut'], DateTime(2026, 11, 20, 14));
    expect(envoi['duree'], 45);
    expect(envoi['langues'], <String>['poular', 'francais']);
    expect(envoi['participants'], <String>['p-un']);
    expect(find.text(c.ouvert), findsOneWidget);
  });

  testWidgets('un refus du serveur reste dans la feuille, en mots', (
    WidgetTester tester,
  ) async {
    final _FauxCreneaux port = _FauxCreneaux(<CreneauDirection>[
      _creneau('libre', EtatCreneau.libre),
    ], refusOuvrir: const RefusCreneau('langues_invalides'));
    await _monter(tester, port);
    await _toucher(tester, find.byKey(CreneauxEntretienPage.ouvrirKey));
    await _toucher(tester, _cle('creneau-cote-male'));
    tester
        .widget<ChampDate>(find.byType(ChampDate))
        .onChoix(DateTime(2026, 11, 20));
    tester.widget<MenuFiltre<int>>(_cle('creneau-heure')).onChoix(14 * 60);
    await tester.pumpAndSettle();
    await _toucher(tester, _cle('creneau-langue-francais'));
    await _toucher(tester, _cle('creneau-personnel-p-deux'));
    await _toucher(tester, find.byKey(FeuilleOuvrirCreneau.envoyerKey));
    expect(_cle('feuille-ouvrir-creneau'), findsOneWidget);
    expect(find.text(c.refusLangues), findsOneWidget);
  });
}
