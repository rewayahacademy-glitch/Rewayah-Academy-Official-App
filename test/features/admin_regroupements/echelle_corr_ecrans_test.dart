// ECHELLE-CORR-ECRANS-1 : la creation d'une classe depuis un regroupement a
// l'echelle de classes paralleles (DECISION-CLASSES-SIMULTANEES-2026-10-10).
//
// Ce que le test prouve :
// - la cle d'envoi est un UUID v4 (le parametre serveur `p_cle_idempotence`
//   est un `uuid`), stable tant que la feuille est ouverte (reessai apres
//   une reponse perdue = meme cle), neuve a la reouverture ;
// - 30 classes creees sur la meme cle (meme categorie, memes jours, meme
//   heure) portent 30 noms distincts (R16) ;
// - la ligne « N demandes → M classes possibles » remplace « N eleves sur
//   5 », le nombre de classes venant du serveur quand il le rend ;
// - aucune phrase ne promet d'ouvrir une classe incomplete ni qu'on pourra
//   la rejoindre ensuite.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/port_regroupements_admin.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_regroupements/feuille_classe_regroupement.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_libelles.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_page.dart';
import 'package:rewayah_academy/features/demo/regroupements_demo.dart';

/// Un UUID de version 4, variante RFC 4122.
final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

class _SansEnseignants implements PortEnseignantsClasse {
  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) async => const <EnseignantPropose>[];
}

RegroupementDemandes _reg(
  String id, {
  int eleves = 5,
  int quota = 5,
  int? classesPossibles,
  int? numeroProchaineClasse,
}) => RegroupementDemandes(
  id: id,
  public: PublicOffre.enfants,
  langueCode: 'fr',
  langueNom: 'Français',
  fuseau: 'Europe/Paris',
  occurrences: const <OccurrenceCreneau>[
    OccurrenceCreneau(jourIso: 1, heure: 18),
  ],
  nombreEleves: eleves,
  quota: quota,
  peutCreerClasse: true,
  classesPossibles: classesPossibles,
  numeroProchaineClasse: numeroProchaineClasse,
);

Future<void> _monter(
  WidgetTester tester,
  PortRegroupementsAdmin port, {
  Size taille = const Size(390, 4000),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portRegroupementsAdminProvider.overrideWithValue(port),
        portEnseignantsClasseProvider.overrideWithValue(_SansEnseignants()),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const RegroupementsPage(),
        ),
      ),
    ),
  );
  await _laisser(tester);
}

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _ouvrir(WidgetTester tester, String id) async {
  final Finder action = _cle('regroupement-action-$id');
  await tester.ensureVisible(action);
  await tester.tap(action);
  await _laisser(tester);
}

Future<void> _creer(WidgetTester tester) async {
  final Finder bouton = find.descendant(
    of: _cle('regroupement-creer'),
    matching: find.byType(ActionPrincipale),
  );
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await _laisser(tester);
}

Future<void> _choisirFemmes(WidgetTester tester) async {
  final Finder carte = _cle('regroupement-genre-${GenreClasse.femmes.name}');
  await tester.ensureVisible(carte);
  await tester.tap(carte);
  await tester.pump();
}

void main() {
  group('Cle d envoi (p_cle_idempotence : uuid)', () {
    test('nouvelleCleEnvoi rend un UUID v4, different a chaque appel', () {
      final Set<String> cles = <String>{
        for (int i = 0; i < 200; i++) nouvelleCleEnvoi(),
      };
      expect(cles, hasLength(200));
      for (final String cle in cles) {
        expect(cle, matches(_uuidV4));
      }
    });

    testWidgets('reessai apres une reponse perdue : meme cle UUID ; '
        'reouverture : cle neuve', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo(
        depart: <RegroupementDemandes>[_reg('a'), _reg('b')],
      );
      await _monter(tester, port);
      await _ouvrir(tester, 'a');
      await _choisirFemmes(tester);
      port.horsLigne = true;
      await _creer(tester);
      expect(find.text(t.admin.regroupements.nonConfirmee), findsOneWidget);
      port.horsLigne = false;
      await _creer(tester);
      expect(port.clesRecues, hasLength(2));
      expect(port.clesRecues.first, matches(_uuidV4));
      expect(port.clesRecues.last, port.clesRecues.first);
      expect(_cle('regroupement-feuille-enseignant'), findsOneWidget);

      // Une autre feuille : une autre cle.
      Navigator.of(tester.element(_cle('regroupement-feuille-enseignant')))
          .pop();
      await _laisser(tester);
      await _ouvrir(tester, 'b');
      await _choisirFemmes(tester);
      await _creer(tester);
      expect(port.clesRecues, hasLength(3));
      expect(port.clesRecues.last, matches(_uuidV4));
      expect(port.clesRecues.last, isNot(port.clesRecues.first));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('R16 : 30 classes paralleles, 30 noms distincts', () {
    test('le meme nom deduit, 30 numeros : 30 noms differents', () {
      final List<String> noms = <String>[
        for (int n = 1; n <= 30; n++)
          nomClasseRegroupee(
            ClasseSansEnseignant(
              classeId: 'c$n',
              libelle: nomDeduit(_reg('r'), GenreClasse.hommes),
              numeroDansFamille: n,
            ),
          ),
      ];
      expect(noms.toSet(), hasLength(30));
      expect(noms.first, contains(nomDeduit(_reg('r'), GenreClasse.hommes)));
      expect(noms.first, endsWith('n° 1'));
    });

    test('la feuille annonce le numero de la prochaine classe', () {
      expect(
        nomDeduitDistinct(_reg('r', numeroProchaineClasse: 31), null),
        endsWith('n° 31'),
      );
      // Sans numero rendu, le nom deduit seul : rien n'est invente.
      expect(nomDeduitDistinct(_reg('r'), null), nomDeduit(_reg('r'), null));
    });

    testWidgets('a l ecran : 30 cartes de classes, 30 titres distincts', (
      WidgetTester tester,
    ) async {
      final List<RegroupementDemandes> regs = <RegroupementDemandes>[
        for (int n = 1; n <= 30; n++)
          RegroupementDemandes(
            id: 'r$n',
            public: PublicOffre.enfants,
            langueCode: 'fr',
            langueNom: 'Français',
            fuseau: 'Europe/Paris',
            occurrences: const <OccurrenceCreneau>[
              OccurrenceCreneau(jourIso: 1, heure: 18),
            ],
            nombreEleves: 5,
            quota: 5,
            classe: ClasseSansEnseignant(
              classeId: 'c$n',
              libelle: 'Garçons, lundi 18 h',
              numeroDansFamille: n,
              peutAffecterEnseignant: true,
            ),
          ),
      ];
      // L3 : au bureau, les 25 lignes de la page tiennent a l'ecran.
      await _monter(
        tester,
        RegroupementsDemo(depart: regs),
        taille: const Size(1440, 4000),
      );
      final List<String> titres = <String>[
        // L3 (relecture du pilote) : le format du regroupement, plus le
        // numero R16 qui distingue les classes paralleles.
        for (int n = 1; n <= 30; n++) 'Lundi · 18\u00a0h · n°\u00a0$n',
      ];
      // Les numeros presents a l'ecran, avec leur titre distinct.
      Set<int> presents() {
        final Set<int> vus = <int>{};
        for (int n = 1; n <= 30; n++) {
          if (_cle('regroupement-r$n').evaluate().isEmpty) continue;
          expect(
            find.descendant(
              of: _cle('regroupement-r$n'),
              matching: find.text(titres[n - 1]),
            ),
            findsOneWidget,
          );
          vus.add(n);
        }
        return vus;
      }

      // R17 : une page de 25, puis les cinq dernieres.
      final Set<int> premiere = presents();
      expect(premiere, hasLength(25));
      final Finder suivante = _cle('nav-suivant');
      await tester.ensureVisible(suivante.first);
      await tester.tap(suivante.first);
      await _laisser(tester);
      final Set<int> seconde = presents();
      expect(seconde, hasLength(5));
      expect(premiere.union(seconde), hasLength(30));
      expect(titres.toSet(), hasLength(30));
      await tester.pumpWidget(const SizedBox());
    });
  });

  // L3 (01/11/2026) : le menu « ... » d'une classe creee s'ouvre aussi au
  // telephone (carte), et propose « Voir la classe ».
  testWidgets('telephone : le menu de la classe creee s ouvre', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      RegroupementsDemo(
        depart: <RegroupementDemandes>[
          RegroupementDemandes(
            id: 'r1',
            public: PublicOffre.enfants,
            langueCode: 'fr',
            langueNom: 'Français',
            fuseau: 'Europe/Paris',
            occurrences: const <OccurrenceCreneau>[
              OccurrenceCreneau(jourIso: 1, heure: 18),
            ],
            nombreEleves: 5,
            quota: 5,
            classe: const ClasseSansEnseignant(
              classeId: 'c1',
              libelle: 'Garçons, lundi 18 h',
              peutAffecterEnseignant: true,
            ),
          ),
        ],
      ),
    );
    await tester.tap(find.byType(MenuActions));
    await _laisser(tester);
    expect(find.text(t.admin.regroupements.voirClasse), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  group('R3 : « N demandes → M classes possibles »', () {
    test('le nombre de classes vient du serveur quand il le rend', () {
      expect(
        libelleDemandesClasses(_reg('r', eleves: 12, classesPossibles: 2)),
        '12 demandes → 2 classes possibles',
      );
      expect(
        libelleDemandesClasses(_reg('r', eleves: 3)),
        '3 demandes → aucune classe possible',
      );
      expect(
        libelleDemandesClasses(_reg('r', eleves: 1)),
        '1 demande → aucune classe possible',
      );
      // Repli sans valeur serveur : les classes pleines au quota, jamais une
      // classe sous le quota.
      expect(
        libelleDemandesClasses(_reg('r', eleves: 11)),
        '11 demandes → 2 classes possibles',
      );
    });

    testWidgets('carte : la ligne remplacee, aucune promesse d ouverture', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        RegroupementsDemo(
          depart: <RegroupementDemandes>[
            _reg('pret', eleves: 12, classesPossibles: 2),
            _reg('incomplet', eleves: 3),
          ],
        ),
        // L3 : au bureau, la colonne « Demandes » a sa cellule.
        taille: const Size(1440, 4000),
      );
      expect(find.text('12 demandes → 2 classes possibles'), findsOneWidget);
      expect(find.text('3 demandes → aucune classe possible'), findsOneWidget);
      expect(find.textContaining('élèves sur'), findsNothing);
      expect(find.textContaining('quand même'), findsNothing);
      expect(find.textContaining('pourront la rejoindre'), findsNothing);
      expect(_cle('regroupement-action-incomplet'), findsNothing);
      expect(_cle('regroupement-action-pret'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
