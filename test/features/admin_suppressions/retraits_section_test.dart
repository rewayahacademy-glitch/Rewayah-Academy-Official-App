// SUPPRIMER-bis : Personnes > Suppressions, section « Comptes supprimes ».
// La liste des retraits (filtre d'etat, page suivante), « Restaurer » rendu
// seulement quand le serveur le permet, le resultat qui dit les classes a
// reprendre, les etats vide, refus et indisponible. 390 et 1440, un seul
// bouton plein au plus.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/capacites/port_suppressions_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/admin_suppressions/retraits_section.dart';
import 'package:rewayah_academy/features/admin_suppressions/suppressions_page.dart';

import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

class _Demandes implements PortSuppressionsAdmin {
  @override
  Future<List<DemandeSuppressionAdmin>> lister() async =>
      <DemandeSuppressionAdmin>[];

  @override
  Future<ResultatTraitementSuppression> traiter(String id) async =>
      ResultatTraitementSuppression.traitee;
}

RetraitCompte _r(
  String id, {
  String nom = 'Awa Bah',
  bool restaurable = true,
  DateTime? anonymise,
  DateTime? restaure,
  SourceRetrait source = SourceRetrait.direction,
}) => RetraitCompte(
  retraitId: 'r-$id',
  profilId: 'p-$id',
  matricule: 'RA-26-4817',
  nom: nom,
  role: AppRole.student,
  source: source,
  retireLe: DateTime(2026, 11, 3, 10),
  anonymiserLe: DateTime(2026, 12, 3, 10),
  anonymiseLe: anonymise,
  restaureLe: restaure,
  restaurable: restaurable,
);

class _Port implements PortRetraitsComptes {
  _Port(this.pages);

  /// Les pages par etat ; la seconde page est rendue quand un curseur vient.
  Map<EtatRetraits, List<PageRetraits>> pages;
  Object? erreur;
  List<ResultatRestauration> Function(List<String>)? restauration;
  final List<(EtatRetraits, CurseurRetraits?)> lectures =
      <(EtatRetraits, CurseurRetraits?)>[];
  final List<List<String>> restaurations = <List<String>>[];

  @override
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  }) async {
    lectures.add((etat, apres));
    final Object? e = erreur;
    if (e != null) throw e;
    final List<PageRetraits> p =
        pages[etat] ??
        <PageRetraits>[const PageRetraits(lignes: <RetraitCompte>[])];
    return apres == null ? p.first : p.last;
  }

  @override
  Future<List<ResultatRestauration>> restaurer(List<String> ids) async {
    restaurations.add(ids);
    return restauration!(ids);
  }

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) => throw UnimplementedError();

  @override
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(String eleveId) =>
      throw UnimplementedError();
}

Future<void> _monter(
  WidgetTester tester,
  _Port port, {
  double largeur = 390,
}) async {
  await monterRecrutement(
    tester,
    chemin: '/admin/personnes/suppressions',
    ecran: (_) => const SuppressionsPage(),
    autres: <String>[
      '/admin/personnes/dossiers',
      '/admin/personnes/comptes',
      '/admin/personnes/invitations',
      '/admin/personnes/reprises',
      '/admin/personnes/import',
    ],
    surcharges: <Override>[
      portSuppressionsAdminProvider.overrideWithValue(_Demandes()),
      portRetraitsComptesProvider.overrideWithValue(port),
    ],
    largeur: largeur,
  );
  await laisser(tester);
  await tester.tap(find.text('Comptes supprimés'));
  await laisser(tester);
}

void main() {
  for (final double largeur in <double>[390, 1440]) {
    testWidgets('$largeur : restaurer dit les classes a reprendre', (
      tester,
    ) async {
      final _Port port = _Port(<EtatRetraits, List<PageRetraits>>{
        EtatRetraits.enCours: <PageRetraits>[
          PageRetraits(lignes: <RetraitCompte>[_r('a')]),
        ],
      });
      port.restauration = (List<String> ids) => <ResultatRestauration>[
        ResultatRestauration(
          id: ids.single,
          restaure: true,
          classesQuittees: 2,
        ),
      ];
      await _monter(tester, port, largeur: largeur);
      expect(
        find.textContaining('sans remettre l\'élève dans ses classes'),
        findsOneWidget,
      );
      final Finder restaurer = find.byKey(RetraitsSection.restaurerKey('r-a'));
      expect(restaurer, findsOneWidget);
      expect(find.text('Restaurer le compte de Awa Bah'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await tester.ensureVisible(restaurer);
      await tester.tap(restaurer);
      await laisser(tester);
      expect(port.restaurations.single, <String>['p-a']);
      final String retour = tester
          .widget<Text>(find.byKey(RetraitsSection.retourKey))
          .data!;
      expect(retour, contains('Le compte de Awa Bah est restauré'));
      expect(retour, contains('Il avait quitté 2 classes'));
      // La liste est relue apres le geste.
      expect(port.lectures.length, 2);
    });
  }

  testWidgets('un retrait non restaurable dit pourquoi, sans bouton', (
    tester,
  ) async {
    await _monter(
      tester,
      _Port(<EtatRetraits, List<PageRetraits>>{
        EtatRetraits.enCours: <PageRetraits>[
          PageRetraits(lignes: <RetraitCompte>[_r('a', restaurable: false)]),
        ],
      }),
    );
    expect(find.byKey(RetraitsSection.restaurerKey('r-a')), findsNothing);
    expect(
      find.textContaining('Il ne peut pas être restauré ici'),
      findsOneWidget,
    );
  });

  testWidgets('filtre Anonymises : relit cet etat, sans bouton', (
    tester,
  ) async {
    final _Port port = _Port(<EtatRetraits, List<PageRetraits>>{
      EtatRetraits.enCours: <PageRetraits>[
        PageRetraits(lignes: <RetraitCompte>[_r('a')]),
      ],
      EtatRetraits.anonymises: <PageRetraits>[
        PageRetraits(
          lignes: <RetraitCompte>[
            _r(
              'b',
              nom: '',
              restaurable: false,
              anonymise: DateTime(2026, 12, 3),
              source: SourceRetrait.tuteur,
            ),
          ],
        ),
      ],
    });
    // Au bureau, les quatre puces tiennent sur la rangee.
    await _monter(tester, port, largeur: 1440);
    await tester.tap(
      find.byKey(RetraitsSection.filtreKey(EtatRetraits.anonymises)),
    );
    await laisser(tester);
    expect(port.lectures.last.$1, EtatRetraits.anonymises);
    expect(find.textContaining('Nom effacé'), findsOneWidget);
    expect(find.text('Anonymisé'), findsWidgets);
    expect(find.text('Un tuteur'), findsOneWidget);
    expect(find.byKey(RetraitsSection.restaurerKey('r-b')), findsNothing);
  });

  testWidgets('page suivante par le curseur du serveur', (tester) async {
    final CurseurRetraits curseur = CurseurRetraits(
      apresLe: DateTime(2026, 11, 3, 10),
      apresId: 'r-a',
    );
    final _Port port = _Port(<EtatRetraits, List<PageRetraits>>{
      EtatRetraits.enCours: <PageRetraits>[
        PageRetraits(lignes: <RetraitCompte>[_r('a')], suivant: curseur),
        PageRetraits(lignes: <RetraitCompte>[_r('b', nom: 'Sara Ba')]),
      ],
    });
    await _monter(tester, port);
    final Finder plus = find.byKey(RetraitsSection.plusKey);
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await laisser(tester);
    expect(port.lectures.last.$2, same(curseur));
    expect(find.textContaining('Sara Ba'), findsWidgets);
    expect(find.byKey(RetraitsSection.plusKey), findsNothing);
  });

  testWidgets('vide, puis refus de droit', (tester) async {
    final _Port port = _Port(<EtatRetraits, List<PageRetraits>>{});
    await _monter(tester, port);
    expect(find.text('Aucun compte supprimé en cours.'), findsOneWidget);
  });

  testWidgets('refus de droit : la phrase dit quoi faire', (tester) async {
    final _Port port = _Port(<EtatRetraits, List<PageRetraits>>{})
      ..erreur = const PermissionInsuffisante('SUPPRIMER');
    await _monter(tester, port);
    expect(
      find.byKey(const ValueKey<String>('retraits-refuse')),
      findsOneWidget,
    );
  });

  testWidgets('port absent : indisponible', (tester) async {
    await monterRecrutement(
      tester,
      chemin: '/admin/personnes/suppressions',
      ecran: (_) => const SuppressionsPage(),
      autres: <String>['/admin/personnes/comptes'],
      surcharges: <Override>[
        portSuppressionsAdminProvider.overrideWithValue(_Demandes()),
      ],
    );
    await laisser(tester);
    await tester.tap(find.text('Comptes supprimés'));
    await laisser(tester);
    expect(
      find.byKey(const ValueKey<String>('retraits-indisponible')),
      findsOneWidget,
    );
  });
}
