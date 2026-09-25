// Outils des tests de la consultation admin des observations (lot E,
// sous-paquet 3). L'application se monte sur son VRAI routeur avec une
// session d'administration ; les parcours se TOUCHENT (onglets de Securite et
// audit, barre laterale). Donnees : doubles isoles, aucun Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/tc_observation/historique_observations_admin_supabase.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_observations/annuaire_observations.dart';

import '../../fixtures/tuteur/faux_observation.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Une ligne de visite a une date fixe (heure locale).
Map<String, dynamic> visiteAdmin({
  required String id,
  required DateTime entree,
  int? secondes = 120,
  String seance = 's1',
  String observateur = 'tuteur-fatoumata',
  String enfant = 'eleve-mariam',
  String groupe = 'classe-an-nour',
  int rang = 1,
}) => ligneVisite(
  id: id,
  seanceId: seance,
  groupeId: groupe,
  observateur: observateur,
  enfantId: enfant,
  entree: entree.toUtc().toIso8601String(),
  sortie: secondes == null
      ? null
      : entree.add(Duration(seconds: secondes)).toUtc().toIso8601String(),
  duree: secondes,
  rang: rang,
);

/// Le jeu de la maquette D3 : deux visites le 23/09 (dont une ouverte ici,
/// pour montrer « Sortie non enregistree »), une le 21/09.
List<Map<String, dynamic>> visitesD3() => <Map<String, dynamic>>[
  visiteAdmin(id: 'v1', entree: DateTime(2026, 9, 23, 18, 12)),
  visiteAdmin(
    id: 'v2',
    entree: DateTime(2026, 9, 23, 18, 35),
    secondes: 102,
    rang: 2,
  ),
  visiteAdmin(
    id: 'v3',
    seance: 's0',
    entree: DateTime(2026, 9, 21, 18, 10),
    secondes: null,
  ),
];

/// La consultation admin, en memoire : une page par appel, dans l'ordre de
/// [pages] ; chaque recherche est gardee.
class FauxHistoriqueObservationsAdmin
    implements PortHistoriqueObservationsAdmin {
  FauxHistoriqueObservationsAdmin({
    List<List<Map<String, dynamic>>>? pages,
    this.erreur,
    this.delai,
  }) : pages = pages ?? <List<Map<String, dynamic>>>[visitesD3()];

  /// Les pages rendues : la derniere n'a pas de curseur.
  List<List<Map<String, dynamic>>> pages;

  /// Ce que la lecture doit jeter.
  Exception? erreur;

  /// Un delai de lecture.
  Duration? delai;

  /// Les recherches demandees, dans l'ordre.
  final List<(FiltreObservationsAdmin, String?)> recherches =
      <(FiltreObservationsAdmin, String?)>[];

  @override
  Future<({List<ObservationsSeance> lignes, String? curseur})> rechercher(
    FiltreObservationsAdmin filtre, {
    String? curseur,
  }) async {
    recherches.add((filtre, curseur));
    if (delai case final Duration d) {
      await Future<void>.delayed(d);
    }
    if (erreur case final Exception e) {
      throw e;
    }
    final int index = curseur == null ? 0 : int.parse(curseur);
    final List<Map<String, dynamic>> page = index < pages.length
        ? pages[index]
        : const <Map<String, dynamic>>[];
    return (
      lignes: grouperParObservateur(page),
      curseur: index + 1 < pages.length ? '${index + 1}' : null,
    );
  }
}

/// Un annuaire en memoire.
class FauxAnnuaire implements AnnuaireObservations {
  FauxAnnuaire({this.enPanne = false});

  /// Vrai : chaque lecture echoue.
  bool enPanne;

  /// Les recherches demandees.
  final List<String> recherches = <String>[];

  static const Map<String, String> _noms = <String, String>{
    'tuteur-fatoumata': 'Fatoumata Diallo',
    'eleve-mariam': 'Mariam Diallo',
  };

  static const List<ClasseAnnuaire> _classes = <ClasseAnnuaire>[
    (id: 'classe-an-nour', libelle: 'An-Nour'),
    (id: 'classe-al-huda', libelle: 'Al-Huda'),
  ];

  @override
  Future<Map<String, String>> noms(Set<String> ids) async {
    if (enPanne) {
      throw Exception('annuaire');
    }
    return <String, String>{
      for (final String id in ids)
        if (_noms[id] case final String n) id: n,
    };
  }

  @override
  Future<Map<String, String>> classes(Set<String> ids) async {
    if (enPanne) {
      throw Exception('annuaire');
    }
    return <String, String>{
      for (final ClasseAnnuaire c in _classes)
        if (ids.contains(c.id)) c.id: c.libelle,
    };
  }

  @override
  Future<List<ClasseAnnuaire>> classesEnCours() async =>
      enPanne ? throw Exception('annuaire') : _classes;

  @override
  Future<List<PersonneAnnuaire>> chercher(String texte) async {
    recherches.add(texte);
    final String m = texte.toLowerCase();
    return <PersonneAnnuaire>[
      for (final MapEntry<String, String> e in _noms.entries)
        if (e.value.toLowerCase().contains(m))
          PersonneAnnuaire(
            id: e.key,
            nom: e.value,
            estTuteur: e.key.startsWith('tuteur'),
          ),
    ];
  }
}

/// Monte l'application (session admin) sur son vrai routeur, puis va a
/// [depart].
Future<GoRouter> monterAdmin(
  WidgetTester tester,
  String depart, {
  Size? taille = const Size(1440, 900),
  PortHistoriqueObservationsAdmin? port,
  AnnuaireObservations? annuaire,
  FauxServiceJournal? journal,
  bool horsLigne = false,
  ThemeMode mode = ThemeMode.light,
  Key? cadre,
}) async {
  if (taille != null) {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(AppRole.admin))),
        serviceJournalProvider.overrideWithValue(
          journal ?? FauxServiceJournal(),
        ),
        annuaireObservationsProvider.overrideWithValue(
          annuaire ?? FauxAnnuaire(),
        ),
        if (port != null)
          portHistoriqueObservationsAdminProvider.overrideWithValue(port),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadre,
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
  if (horsLigne) {
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    (c.read(serviceReseauProvider) as FauxServiceReseau).horsLigneRendu = true;
    c.invalidate(horsLigneProvider);
  }
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Touche l'onglet [libelle] de la sous-navigation de Securite et audit.
Future<void> toucherOnglet(WidgetTester tester, String libelle) async {
  await tester.tap(find.widgetWithText(Tab, libelle));
  await stabiliser(tester);
}
