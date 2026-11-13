// HORLOGE-ET-LIEU, partie B (H5 et H6) : la direction voit la ville de chaque
// enseignant dans les Comptes, la verifie d'un geste du menu de ligne, et lit
// ce qui ne concorde pas. Rien n'est corrige seul.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu_direction.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_comptes/changements_heure.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste);

  final List<CompteAdmin> _liste;

  @override
  Future<List<CompteAdmin>> comptes() async => _liste;
}

class _Direction implements PortLieuDirection {
  _Direction({
    required this.lieuxLus,
    required this.incoherencesLues,
    this.changements = const <ChangementHeureAVenir>[],
    this.changementsEnEchec = false,
  });

  final List<ChangementHeureAVenir> changements;
  final bool changementsEnEchec;

  @override
  Future<List<ChangementHeureAVenir>> changementsHeure({int jours = 60}) async {
    if (changementsEnEchec) throw StateError('hors service');
    return changements;
  }

  final List<LieuEnseignantDirection> lieuxLus;
  final List<IncoherenceLieu> incoherencesLues;
  final List<String> verifiees = <String>[];
  bool echec = false;

  @override
  Future<List<LieuEnseignantDirection>> lieux() async => lieuxLus;

  @override
  Future<List<IncoherenceLieu>> incoherences() async => incoherencesLues;

  @override
  Future<void> verifier(String profilId) async {
    if (echec) throw StateError('refus');
    verifiees.add(profilId);
  }
}

CompteAdmin _compte(String id, String prenom) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-${id.hashCode.abs() % 9000 + 1000}',
  prenom: prenom,
  nom: 'Test',
  role: AppRole.teacher,
  etat: AccountStatus.active,
  inscritLe: DateTime.now().subtract(const Duration(days: 30)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 2,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

Future<void> _monter(
  WidgetTester tester,
  _Direction port, {
  double largeur = 1440,
  String vue = 'enseignants',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largeur, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      ComptesPage(requete: <String, String>{'vue': vue}),
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(
          _Comptes(<CompteAdmin>[
            _compte('e1', 'Aminata'),
            _compte('e2', 'Karim'),
            _compte('e3', 'Salma'),
          ]),
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portLieuDirectionProvider.overrideWithValue(port),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

_Direction _port() => _Direction(
  lieuxLus: const <LieuEnseignantDirection>[
    LieuEnseignantDirection(
      profilId: 'e1',
      ville: 'Conakry',
      paysCode: 'GN',
      verifie: false,
    ),
    LieuEnseignantDirection(
      profilId: 'e2',
      ville: 'Paris',
      paysCode: 'FR',
      verifie: true,
    ),
  ],
  incoherencesLues: const <IncoherenceLieu>[
    IncoherenceLieu(
      profilId: 'e3',
      enseignant: 'Salma Test',
      type: TypeIncoherenceLieu.sansVille,
    ),
  ],
);

Future<void> _ouvrirMenu(WidgetTester tester, String nom) async {
  await tester.tap(
    find.byWidgetPredicate(
      (Widget w) => w is MenuActions && w.objet == '$nom Test',
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('lecture : seules les lignes d enseignants et de types connus', () {
    expect(IncoherenceLieu.lireEnseignant(null), isNull);
    expect(
      IncoherenceLieu.lireEnseignant(<String, Object?>{
        'profil_id': 'x',
        'role': 'guardian',
        'type': 'sans_ville',
      }),
      isNull,
    );
    expect(
      IncoherenceLieu.lireEnseignant(<String, Object?>{
        'profil_id': 'x',
        'role': 'teacher',
        'type': 'inconnu',
      }),
      isNull,
    );
    expect(
      IncoherenceLieu.lireEnseignant(<String, Object?>{
        'profil_id': 'x',
        'role': 'teacher',
        'prenom': 'Aminata',
        'nom': 'Test',
        'type': 'pays_fuseau',
      })?.enseignant,
      'Aminata Test',
    );
  });

  testWidgets('la colonne Ville, avec « Ville a verifier » et « non choisie »', (
    tester,
  ) async {
    await _monter(tester, _port());
    expect(find.text(t.lieu.colonneVille), findsOneWidget);
    expect(
      find.textContaining(
        '${t.lieu.villeLigne(ville: 'Conakry', pays: 'Guinée')} · ${t.lieu.nonVerifiee}',
      ),
      findsOneWidget,
    );
    expect(
      find.text(t.lieu.villeLigne(ville: 'Paris', pays: 'France')),
      findsOneWidget,
    );
    expect(find.text(t.lieu.villeAbsente), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le bandeau dit ce qui ne concorde pas, sans rien corriger', (
    tester,
  ) async {
    await _monter(tester, _port());
    expect(
      find.byKey(const ValueKey<String>('comptes-villes-a-verifier')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Salma Test\u00a0: ${t.lieu.incSansVille}'),
      findsOneWidget,
    );
  });

  testWidgets('« Verifier la ville » : seulement pour une ville non verifiee, '
      'et le geste passe par le port', (tester) async {
    final _Direction port = _port();
    await _monter(tester, port);
    await _ouvrirMenu(tester, 'Karim');
    expect(
      find.text(t.lieu.verifier(deNom: deDevant('Karim Test'))),
      findsNothing,
    );
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await _ouvrirMenu(tester, 'Aminata');
    expect(
      find.text(t.lieu.verifier(deNom: deDevant('Aminata Test'))),
      findsOneWidget,
    );
    await tester.tap(
      find.text(t.lieu.verifier(deNom: deDevant('Aminata Test'))),
    );
    await tester.pumpAndSettle();
    expect(port.verifiees, <String>['e1']);
    expect(
      find.text(t.lieu.villeVerifiee(deNom: deDevant('Aminata Test'))),
      findsOneWidget,
    );
  });

  testWidgets('une verification refusee le dit', (tester) async {
    final _Direction port = _port()..echec = true;
    await _monter(tester, port);
    await _ouvrirMenu(tester, 'Aminata');
    await tester.tap(
      find.text(t.lieu.verifier(deNom: deDevant('Aminata Test'))),
    );
    await tester.pumpAndSettle();
    expect(port.verifiees, isEmpty);
    expect(find.text(t.lieu.verifierEchec), findsOneWidget);
  });

  testWidgets('390 px : la vue tient sans debordement', (tester) async {
    await _monter(tester, _port(), largeur: 390);
    expect(tester.takeException(), isNull);
  });

  group('I7 : les changements d heure a venir, par fuseau', () {
    final ChangementHeureAVenir paris = ChangementHeureAVenir(
      fuseau: 'Europe/Paris',
      transition: DateTime.utc(2027, 3, 28, 1),
      decalageAvant: const Duration(hours: 1),
      decalageApres: const Duration(hours: 2),
      familles: 12,
      enseignants: 3,
    );

    test('lecture et decalage', () {
      expect(libelleDecalageUtc(const Duration(hours: 1)), 'UTC+1');
      expect(
        libelleDecalageUtc(const Duration(hours: 5, minutes: 30)),
        'UTC+5:30',
      );
      expect(libelleDecalageUtc(const Duration(hours: -5)), 'UTC-5');
      expect(
        ChangementHeureAVenir.lire(<String, Object?>{'fuseau': 'x'}),
        isNull,
      );
      final ChangementHeureAVenir? lu = ChangementHeureAVenir.lire(
        <String, Object?>{
          'fuseau': 'Europe/Paris',
          'transition_utc': '2027-03-28T01:00:00+00:00',
          'jours_restants': 135,
          'decalage_avant_secondes': 3600,
          'decalage_apres_secondes': 7200,
          'familles': 12,
          'enseignants': 3,
        },
      );
      expect(lu?.familles, 12);
      expect(lu?.decalageApres, const Duration(hours: 2));
    });

    for (final String vue in <String>['familles', 'enseignants']) {
      testWidgets('$vue : la date, la ville, le nombre de personnes, le '
          'decalage', (tester) async {
        await _monter(
          tester,
          _Direction(
            lieuxLus: const <LieuEnseignantDirection>[],
            incoherencesLues: const <IncoherenceLieu>[],
            changements: <ChangementHeureAVenir>[paris],
          ),
          vue: vue,
        );
        expect(find.byKey(BlocChangementsHeure.cle), findsOneWidget);
        expect(find.text(t.lieu.changementsTitre), findsOneWidget);
        expect(
          find.textContaining(
            t.lieu.changementsLigne(
              date: 'dimanche 28 mars 2027',
              ville: 'Paris',
              familles: '12',
              enseignants: '3',
              avant: 'UTC+1',
              apres: 'UTC+2',
            ),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('aucun changement : l ecran le dit, il n est pas vide', (
      tester,
    ) async {
      await _monter(
        tester,
        _Direction(
          lieuxLus: const <LieuEnseignantDirection>[],
          incoherencesLues: const <IncoherenceLieu>[],
        ),
        vue: 'familles',
      );
      expect(
        find.text(t.lieu.changementsAucun(jours: '$joursChangementsHeure')),
        findsOneWidget,
      );
    });

    testWidgets('lecture en echec : la phrase dit quoi faire', (tester) async {
      await _monter(
        tester,
        _Direction(
          lieuxLus: const <LieuEnseignantDirection>[],
          incoherencesLues: const <IncoherenceLieu>[],
          changementsEnEchec: true,
        ),
        vue: 'enseignants',
      );
      expect(find.text(t.lieu.changementsErreur), findsOneWidget);
    });

    testWidgets('390 px : aucun debordement', (tester) async {
      await _monter(
        tester,
        _Direction(
          lieuxLus: const <LieuEnseignantDirection>[],
          incoherencesLues: const <IncoherenceLieu>[],
          changements: <ChangementHeureAVenir>[paris],
        ),
        largeur: 390,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
