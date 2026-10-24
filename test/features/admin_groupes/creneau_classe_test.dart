// B2.2 bis (c), plan de nuit du pilote (24/10/2026) : l'ecran Classes de la
// direction ajoute un creneau a une Classe. Le serveur
// (`ajouter_creneau_classe_admin`) est prouve par
// supabase/tests/scenarios_seances_cloche_concierge.sql ; ici, l'ecran : le
// geste, le jour et l'heure envoyes, la phrase d'un refus, jamais le SQL.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creneaux_classe.dart';
import 'package:rewayah_academy/core/capacites/port_creation_classe.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/affectation_refusee.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../../support/harnais.dart' show FauxServiceReseau;
import '../support_form_l2.dart';

class _FauxCreneaux implements ServiceCreneauxClasse {
  final List<(String, int, int)> ajouts = <(String, int, int)>[];
  Exception? echec;
  int rendu = 4;

  @override
  Future<int> ajouter({
    required String groupeId,
    required int jour,
    required int heure,
  }) async {
    if (echec case final Exception e) throw e;
    ajouts.add((groupeId, jour, heure));
    return rendu;
  }
}

Widget _hote(_FauxCreneaux creneaux) => ProviderScope(
  overrides: <Override>[
    ...surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
    portEnseignantsClasseProvider.overrideWithValue(
      FauxEnseignantsClasse(const []),
    ),
    portCreationClasseProvider.overrideWithValue(FauxCreationClasse()),
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    serviceCreneauxClasseProvider.overrideWithValue(creneaux),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const GroupesPage(),
    ),
  ),
);

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _ouvrirFeuille(
  WidgetTester tester,
  _FauxCreneaux creneaux,
  Size taille,
) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_hote(creneaux));
  await tester.pumpAndSettle();
  await _presser(tester, find.byType(MenuActions).first);
  await _presser(tester, find.text(t.admin.groupes.actionAjouterCreneau).last);
}

Future<void> _choisir(WidgetTester tester, int jour, int heure) async {
  await _presser(tester, find.byKey(ValueKey<String>('creneau-jour-$jour')));
  await _presser(tester, find.byKey(const ValueKey<String>('creneau-heure')));
  await _presser(
    tester,
    find.text(t.admin.groupes.formulaire.heureValeur(heure: '$heure')).last,
  );
}

void main() {
  final c = t.admin.groupes.creneau;

  testWidgets('le menu de la Classe ouvre « Ajouter un créneau » : jour et '
      'heure partent au serveur, la feuille se ferme', (
    WidgetTester tester,
  ) async {
    final _FauxCreneaux creneaux = _FauxCreneaux();
    await _ouvrirFeuille(tester, creneaux, const Size(1440, 1600));
    expect(find.text(c.contexte), findsOneWidget);

    await _choisir(tester, 4, 18);
    await _presser(tester, find.text(c.envoyer).last);
    expect(creneaux.ajouts.single.$2, 4);
    expect(creneaux.ajouts.single.$3, 18);
    expect(find.text(c.contexte), findsNothing);
  });

  testWidgets(
    'sans jour ni heure : la phrase dit ce qui manque, rien ne part',
    (WidgetTester tester) async {
      final _FauxCreneaux creneaux = _FauxCreneaux();
      await _ouvrirFeuille(tester, creneaux, const Size(320, 900));
      await _presser(tester, find.text(c.envoyer).last);
      expect(
        find.text(t.admin.groupes.formulaire.manqueCreneau),
        findsOneWidget,
      );
      expect(creneaux.ajouts, isEmpty);
    },
  );

  testWidgets('le serveur avait deja ce creneau : la phrase le dit, la '
      'feuille reste ouverte', (WidgetTester tester) async {
    final _FauxCreneaux creneaux = _FauxCreneaux()..rendu = 0;
    await _ouvrirFeuille(tester, creneaux, const Size(1440, 1600));
    await _choisir(tester, 5, 10);
    await _presser(tester, find.text(c.envoyer).last);
    expect(find.text(c.dejaLa), findsOneWidget);
    expect(find.text(c.contexte), findsOneWidget);
  });

  testWidgets('refus du predicat (chevauchement) : sa phrase, jamais le SQL', (
    WidgetTester tester,
  ) async {
    final _FauxCreneaux creneaux = _FauxCreneaux()
      ..echec = const AffectationRefusee(
        MotifRefusAffectation.chevauchementSeance,
      );
    await _ouvrirFeuille(tester, creneaux, const Size(1440, 1600));
    await _choisir(tester, 3, 9);
    await _presser(tester, find.text(c.envoyer).last);
    expect(
      find.text(t.admin.groupes.refusDeplacement.chevauchementSeance),
      findsOneWidget,
    );
    expect(find.textContaining('chevauchement avec'), findsNothing);
    expect(find.text(c.contexte), findsOneWidget);
  });

  testWidgets('autre echec : la phrase dit quoi faire', (
    WidgetTester tester,
  ) async {
    final _FauxCreneaux creneaux = _FauxCreneaux()..echec = Exception('x');
    await _ouvrirFeuille(tester, creneaux, const Size(1440, 1600));
    await _choisir(tester, 1, 8);
    await _presser(tester, find.text(c.envoyer).last);
    expect(find.text(c.erreur), findsOneWidget);
  });
}
