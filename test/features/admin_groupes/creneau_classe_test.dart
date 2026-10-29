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
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_groupes/feuille_reglages_classe.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../../support/garde_interface.dart';
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

  /// D2 (29/10/2026) : les creneaux de la Classe et les gestes recus.
  List<CreneauClasse> creneaux = <CreneauClasse>[(jour: 2, heure: 18)];
  final List<(CreneauClasse, CreneauClasse, String)> modifications =
      <(CreneauClasse, CreneauClasse, String)>[];
  final List<(CreneauClasse, String)> retraits = <(CreneauClasse, String)>[];
  final List<(GenreClasse, String)> genres = <(GenreClasse, String)>[];

  @override
  Future<List<CreneauClasse>> lister(String groupeId) async => creneaux;

  @override
  Future<int> modifier({
    required String groupeId,
    required CreneauClasse ancien,
    required CreneauClasse nouveau,
    required String motif,
  }) async {
    if (echec case final Exception e) throw e;
    modifications.add((ancien, nouveau, motif));
    return rendu;
  }

  @override
  Future<int> retirer({
    required String groupeId,
    required CreneauClasse creneau,
    required String motif,
  }) async {
    if (echec case final Exception e) throw e;
    retraits.add((creneau, motif));
    return rendu;
  }

  @override
  Future<void> reglerGenre({
    required String groupeId,
    required GenreClasse genre,
    required String motif,
  }) async {
    if (echec case final Exception e) throw e;
    genres.add((genre, motif));
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
  await _ouvrirReglages(tester);
  await _presser(
    tester,
    find.byKey(const ValueKey<String>('reglages-ajouter-creneau')),
  );
}

/// D2 et D1 (29/10/2026) : « Creneaux et genre », depuis le menu de la Classe.
Future<void> _ouvrirReglages(WidgetTester tester) async {
  await _presser(tester, find.byType(MenuActions).first);
  await _presser(tester, find.text(t.admin.groupes.reglagesClasse.action).last);
}

Future<void> _monter(
  WidgetTester tester,
  _FauxCreneaux creneaux, [
  Size taille = const Size(1440, 1600),
]) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_hote(creneaux));
  await tester.pumpAndSettle();
  await _ouvrirReglages(tester);
}

/// Ouvre le menu d'un creneau de la liste, puis l'entree [libelle].
Future<void> _gesteCreneau(WidgetTester tester, String libelle) async {
  await _presser(
    tester,
    find
        .descendant(
          of: find.byType(FeuilleReglagesClasse),
          matching: find.byType(MenuActions),
        )
        .first,
  );
  await _presser(tester, find.text(libelle).last);
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

  group('D2 et D1 (29/10/2026) : creneaux et genre de la Classe', () {
    final r = t.admin.groupes.reglagesClasse;

    testWidgets('la liste dit les creneaux de la semaine et le genre', (
      WidgetTester tester,
    ) async {
      final _FauxCreneaux creneaux = _FauxCreneaux()
        ..creneaux = <CreneauClasse>[
          (jour: 1, heure: 18),
          (jour: 3, heure: 18),
        ];
      await _monter(tester, creneaux);
      expect(find.text(r.creneauxTitre), findsOneWidget);
      expect(
        find.text(libelleCreneauClasse((jour: 1, heure: 18))),
        findsOneWidget,
      );
      expect(
        find.text(libelleCreneauClasse((jour: 3, heure: 18))),
        findsOneWidget,
      );
      expect(find.text(r.genreTitre), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsWidgets);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('modifier un creneau : nouveau jour, nouvelle heure et motif '
        'partent ; la consequence est dite avant', (WidgetTester tester) async {
      final _FauxCreneaux creneaux = _FauxCreneaux();
      await _monter(tester, creneaux);
      await _gesteCreneau(tester, r.modifierCreneau);
      expect(find.text(r.consequence), findsOneWidget);
      // Sans motif : la phrase le dit, rien ne part.
      await _presser(tester, find.text(r.envoyerModifier).last);
      expect(find.text(r.manqueMotif), findsOneWidget);
      expect(creneaux.modifications, isEmpty);

      await _presser(
        tester,
        find.byKey(const ValueKey<String>('reglages-jour-4')),
      );
      await _presser(
        tester,
        find.byKey(const ValueKey<String>('reglages-heure')),
      );
      await _presser(
        tester,
        find.text(t.admin.groupes.formulaire.heureValeur(heure: '20')).last,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('reglages-motif')),
        'Enseignant indisponible le mardi',
      );
      await _presser(tester, find.text(r.envoyerModifier).last);
      expect(creneaux.modifications.single.$1, (jour: 2, heure: 18));
      expect(creneaux.modifications.single.$2, (jour: 4, heure: 20));
      expect(
        creneaux.modifications.single.$3,
        'Enseignant indisponible le mardi',
      );
      expect(find.text(r.faitModifie(n: 4)), findsOneWidget);
    });

    testWidgets('retirer le dernier creneau : le refus du serveur se dit en '
        'une phrase', (WidgetTester tester) async {
      final _FauxCreneaux creneaux = _FauxCreneaux()
        ..echec = const CreneauRefuse(MotifRefusCreneau.dernier);
      await _monter(tester, creneaux);
      await _gesteCreneau(tester, r.retirerCreneau);
      await tester.enterText(
        find.byKey(const ValueKey<String>('reglages-motif')),
        'Fin du créneau',
      );
      await _presser(tester, find.text(r.envoyerRetirer).last);
      expect(find.text(r.refusDernier), findsOneWidget);
    });

    testWidgets('retirer un creneau : le motif part, le nombre de seances '
        'annulees est dit', (WidgetTester tester) async {
      final _FauxCreneaux creneaux = _FauxCreneaux()..rendu = 3;
      await _monter(tester, creneaux);
      await _gesteCreneau(tester, r.retirerCreneau);
      await tester.enterText(
        find.byKey(const ValueKey<String>('reglages-motif')),
        'Moins de séances',
      );
      await _presser(tester, find.text(r.envoyerRetirer).last);
      expect(creneaux.retraits.single, (
        (jour: 2, heure: 18),
        'Moins de séances',
      ));
      expect(find.text(r.faitRetire(n: 3)), findsOneWidget);
    });

    testWidgets('genre : hommes, femmes ou mixte, avec un motif', (
      WidgetTester tester,
    ) async {
      final _FauxCreneaux creneaux = _FauxCreneaux();
      await _monter(tester, creneaux);
      await _presser(
        tester,
        find.byKey(const ValueKey<String>('reglages-modifier-genre')),
      );
      expect(find.text(t.admin.groupes.formulaire.genreMixte), findsOneWidget);
      await _presser(tester, find.text(r.envoyerGenre).last);
      expect(find.text(r.manqueGenre), findsOneWidget);
      await _presser(
        tester,
        find.byKey(const ValueKey<String>('reglages-genre-mixte')),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('reglages-motif')),
        'Pas assez d enseignantes',
      );
      await _presser(tester, find.text(r.envoyerGenre).last);
      expect(creneaux.genres.single.$1, GenreClasse.mixte);
      expect(find.text(r.faitGenre), findsOneWidget);
    });
  });
}
