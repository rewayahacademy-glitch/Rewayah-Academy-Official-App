// SOCLE-PROGRAMME (seconde revue, 12/11/2026) : l'ecran Programmes de la
// direction, a travers le VRAI routeur (`/admin/pedagogie/programmes`, session
// de la direction) :
//   - la date limite d'une etape est la valeur rendue par le serveur, affichee
//     et renvoyee telle quelle (14 prevues, 19 au plus : jamais 18 par x 1,3),
//     et la direction peut la modifier ;
//   - un refus de publication pour incoherence des sommes, ou faute du niveau
//     des bases complet, se lit en mots simples, jamais le code brut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/choix_nombre.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

const NiveauProgramme _voyelles = NiveauProgramme(
  id: 'n2',
  codeTechnique: 'BASES-2',
  nomHumain: 'Lire avec les voyelles',
  cycle: 'Les bases',
  ordre: 2,
  description: null,
  objectifs: <String>['Lit le tanwin', 'Lit la chadda', 'Lit la chadda'],
  durees: <String, DureeEtape>{
    'enfant_6_9': DureeEtape(prevue: 14, limite: 19),
    'enfant_10_13': DureeEtape(prevue: 11, limite: 14),
    'ado_14_17': DureeEtape(prevue: 9, limite: 13),
    'adulte_18_plus': DureeEtape(prevue: 6, limite: 8),
  },
  complet: true,
);

class _Faux implements ServiceProgramme, ServiceContenuProgramme {
  _Faux(this.refus);

  final String refus;
  Map<String, DureeEtape>? durees;

  @override
  Future<List<VersionProgramme>> versions() async => <VersionProgramme>[
    VersionProgramme(
      id: 'v2',
      statut: StatutVersionProgramme.brouillon,
      numeroVersion: 2,
      creeParIdentifiant: 'x',
      creeParPrenom: null,
      creeParNom: null,
      publieeAt: null,
      nombreNiveaux: 1,
      createdAt: DateTime.utc(2026, 11, 12),
    ),
  ];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      const <NiveauProgramme>[_voyelles];

  @override
  Future<String> creerVersion({String? versionSourceId}) async => 'v3';

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async => 'n';

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {}

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) async {}

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) async => throw PostgrestException(message: refus);

  @override
  Future<void> modifierContenu({
    required String niveauId,
    required List<String> objectifs,
    required PlageSupport? plage,
    required Map<String, DureeEtape> durees,
  }) async => this.durees = durees;

  @override
  Future<void> preremplirBases(String versionId) async {}
}

Future<_Faux> _monter(WidgetTester tester, String refus) async {
  final _Faux faux = _Faux(refus);
  await monterRouteur(
    tester,
    Routes.adminPedagogieProgrammes,
    source: FausseSourceSession(sessionActive(AppRole.admin)),
    taille: const Size(1440, 2400),
    surcharges: <Override>[
      serviceProgrammeProvider.overrideWithValue(faux),
      serviceContenuProgrammeProvider.overrideWithValue(faux),
    ],
  );
  await stabiliser(tester);
  return faux;
}

Future<void> _publier(WidgetTester tester) async {
  await tester.tap(find.text(t.admin.programmes.publierVersion).first);
  await stabiliser(tester);
  await tester.enterText(
    find.descendant(
      of: find.byType(ZoneSaisie),
      matching: find.byType(EditableText),
    ),
    'Version 2 des bases',
  );
  await tester.tap(find.text(t.admin.programmes.publierVersionEnvoyer).last);
  await stabiliser(tester);
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('la date limite rendue par le serveur s affiche et repart telle '
      'quelle ; la direction la modifie', (WidgetTester tester) async {
    final _Faux faux = await _monter(tester, 'x');
    await tester.tap(
      find.byWidgetPredicate(
        (Widget w) =>
            w is MenuActions &&
            (w.objet ?? '').contains('Lire avec les voyelles'),
      ),
    );
    await stabiliser(tester);
    await tester.tap(find.text(t.admin.programmes.contenu.ouvrir).last);
    await stabiliser(tester);
    final Finder limite69 = find.byKey(
      const ValueKey<String>('contenu-limite-enfant_6_9'),
    );
    expect(tester.widget<ChoixNombre>(limite69).valeur, 19);
    // La direction ajoute une semaine a la date limite des 10-13 ans.
    final Finder limite1013 = find.byKey(
      const ValueKey<String>('contenu-limite-enfant_10_13'),
    );
    await tester.ensureVisible(limite1013);
    await tester.tap(
      find.descendant(
        of: limite1013,
        matching: find.bySemanticsLabel(
          t.admin.programmes.contenu.limitePlus(
            tranche: t.admin.programmes.contenu.tranche1013,
          ),
        ),
      ),
    );
    await stabiliser(tester);
    final Finder enregistrer = find.text(
      t.admin.programmes.contenu.enregistrer,
    );
    await tester.ensureVisible(enregistrer);
    await tester.tap(enregistrer);
    await stabiliser(tester);
    expect(faux.durees, isNotNull);
    expect(faux.durees!['enfant_6_9']!.prevue, 14);
    expect(faux.durees!['enfant_6_9']!.limite, 19);
    expect(faux.durees!['enfant_10_13']!.limite, 15);
    expect(faux.durees!['adulte_18_plus']!.limite, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refus de publication pour incoherence des sommes : en mots '
      'simples', (WidgetTester tester) async {
    await _monter(tester, 'programme_incoherent: Les bases, 6 à 9 ans');
    await _publier(tester);
    expect(
      find.text(
        t.admin.programmes.contenu.publierIncoherent(
          niveau: 'Les bases, 6 à 9 ans',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('programme_incoherent'), findsNothing);
  });

  testWidgets('refus de publication sans le niveau des bases : en mots '
      'simples', (WidgetTester tester) async {
    await _monter(tester, 'programme_sans_bases: version 2');
    await _publier(tester);
    expect(
      find.text(t.admin.programmes.contenu.publierSansBases),
      findsOneWidget,
    );
    expect(find.textContaining('programme_sans_bases'), findsNothing);
  });
}
