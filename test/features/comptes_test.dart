import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../support/harnais.dart';

/// Le defaut que cet ecran repare, mesure en production le 18 septembre 2026 :
/// trois enseignants inscrits attendaient depuis sept jours, contrats signes,
/// sans avoir depose leur piece d'identite. Aucun ecran de l'administration ne
/// les montrait, parce que `dossiers_en_attente()` comptait des **documents**
/// et non des personnes. Le tableau de bord affichait « 0 dossiers a valider »
/// sur une academie bloquee.
///
/// Ces tests portent donc sur un seul fait : **une personne sans piece est
/// visible, et dit ce qui manque.**
class _FauxServiceComptes implements ServiceComptes {
  _FauxServiceComptes(this._comptes, {this.echoue = false});

  final List<CompteAdmin> _comptes;
  final bool echoue;

  @override
  Future<List<CompteAdmin>> comptes() async {
    if (echoue) {
      throw StateError('lecture refusee');
    }
    return _comptes;
  }
}

CompteAdmin _compte({
  required String identifiant,
  required AccountStatus etat,
  AppRole role = AppRole.teacher,
  EtatPiece piece = EtatPiece.aucune,
  String? prenom = 'Aicha',
  int joursDepuisInscription = 7,
  int contrats = 2,
}) => CompteAdmin(
  profilId: identifiant,
  identifiant: identifiant,
  prenom: prenom,
  nom: prenom == null ? null : 'Sow',
  role: role,
  etat: etat,
  inscritLe: DateTime.now().subtract(Duration(days: joursDepuisInscription)),
  accesJusquAu: null,
  foyerId: null,
  piece: piece,
  contrats: contrats,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

void main() {
  Future<void> monter(
    WidgetTester tester,
    ServiceComptes service,
  ) async {
    await tester.pumpWidget(
      hote(
        const ComptesPage(),
        surcharges: <Override>[
          serviceComptesProvider.overrideWithValue(service),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'un enseignant inscrit sans piece deposee est visible et dit son etat',
    (WidgetTester tester) async {
      await monter(
        tester,
        _FauxServiceComptes(<CompteAdmin>[
          _compte(
            identifiant: 'TEACHER-AS-000001',
            etat: AccountStatus.pendingKyc,
          ),
        ]),
      );

      expect(tester.takeException(), isNull);
      // La personne existe a l'ecran, ce qui n'etait le cas d'aucun ecran
      // avant ce lot. `textContaining` et non `text` : sous 1200,
      // `DataCollection` replie le tableau en cartes et joint les colonnes
      // secondaires par un point median, donc l'identifiant vit dans une
      // chaine composee.
      expect(find.textContaining('Aicha Sow'), findsWidgets);
      expect(find.textContaining('TEACHER-AS-000001'), findsWidgets);
      // Et l'ecran nomme ce qui manque, au lieu de laisser une case vide.
      expect(find.textContaining('Aucune pièce déposée'), findsWidgets);
    },
  );

  testWidgets('le bandeau dit combien de personnes attendent une decision', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(identifiant: 'TEACHER-AS-000001', etat: AccountStatus.pendingKyc),
        _compte(identifiant: 'TEACHER-AS-000002', etat: AccountStatus.pendingKyc),
        _compte(
          identifiant: 'TEACHER-AD-000003',
          etat: AccountStatus.pendingKyc,
        ),
        _compte(
          identifiant: 'GUARDIAN-SR-000002',
          etat: AccountStatus.active,
          role: AppRole.guardian,
          piece: EtatPiece.validee,
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('3 personnes attendent une décision.'), findsOneWidget);
  });

  testWidgets('une lecture en echec le dit et laisse reessayer', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(const <CompteAdmin>[], echoue: true),
    );

    expect(
      find.text(
        "Les comptes n'ont pas pu être lus. Réessayez dans un instant.",
      ),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('un filtre qui ne laisse rien passer le dit', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'GUARDIAN-SR-000002',
          etat: AccountStatus.active,
          role: AppRole.guardian,
          piece: EtatPiece.validee,
        ),
      ]),
    );

    await tester.tap(find.text('Suspendu'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Aucun compte avec ce filtre'), findsOneWidget);
  });
}
