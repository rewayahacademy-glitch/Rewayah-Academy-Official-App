// Captures de la dette D2 (08/11/2026) : dans Personnes, Comptes, un compte
// supprime disparait de la liste aussitot la reponse du serveur, sans
// deconnexion. Avant le geste, puis apres. 390x844 @3 et 1440x900 @1, clair,
// francais. Donnees de test uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

CompteAdmin _eleve(String id, String prenom, String nom) => CompteAdmin(
  profilId: 'p-$id',
  identifiant: id,
  prenom: prenom,
  nom: nom,
  role: AppRole.student,
  etat: AccountStatus.active,
  inscritLe: DateTime(2026, 10, 20),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: 0,
  detailsServis: true,
);

/// Le serveur : le compte supprime n'est plus rendu.
class _Serveur implements ServiceComptes, PortRetraitsComptes {
  final List<CompteAdmin> lus = <CompteAdmin>[
    _eleve('STUDENT-AA-000001', 'Lina', 'Diallo'),
    _eleve('STUDENT-AA-000002', 'Yacine', 'Kane'),
    _eleve('STUDENT-AA-000003', 'Sara', 'Ba'),
  ];

  @override
  Future<List<CompteAdmin>> comptes() async =>
      List<CompteAdmin>.of(lus, growable: false);

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) async {
    lus.removeWhere((CompteAdmin c) => ids.contains(c.profilId));
    return <ResultatRetrait>[
      for (final String id in ids)
        ResultatRetrait(
          id: id,
          retire: true,
          anonymiserLe: DateTime(2026, 12, 8),
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Capture : D2, un compte supprime quitte la liste', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      final String format =
          '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
      testWidgets(format, (WidgetTester tester) async {
        fixerVueCapture(tester, taille, densite);
        final _Serveur serveur = _Serveur();
        await tester.pumpWidget(
          hoteCapture(
            const ComptesPage(requete: <String, String>{'vue': 'eleves'}),
            surcharges: <Override>[
              serviceComptesProvider.overrideWithValue(serveur),
              portRetraitsComptesProvider.overrideWithValue(serveur),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            ],
          ),
        );
        await stabiliser(tester);
        expect(find.textContaining('Lina'), findsWidgets);
        debugPrint('PNG ${await capturer(tester, 'd2_${format}_avant')}');

        await tester.tap(find.byType(MenuActions).first);
        await stabiliser(tester);
        await tester.tap(find.text('Supprimer ce compte'));
        await stabiliser(tester);
        await tester.tap(find.text('Supprimer le compte').last);
        await stabiliser(tester);
        expect(find.textContaining('Lina'), findsNothing);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'd2_${format}_apres')}');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
