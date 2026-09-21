import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/classes/domaine/conformite.dart';
import 'package:rewayah_academy/features/classes/domaine/erreur_domaine.dart';
import 'package:rewayah_academy/features/classes/domaine/providers.dart';

import '../../support/harnais.dart';
import 'faux/faux_ports_classes.dart';

class _FauxComptes implements ServiceComptes {
  _FauxComptes(this.lignes);

  final List<CompteAdmin> lignes;

  @override
  Future<List<CompteAdmin>> comptes() async => lignes;
}

CompteAdmin _compte({
  required String id,
  required AppRole role,
  String prenom = 'Aicha',
}) => CompteAdmin(
  profilId: id,
  identifiant: id,
  prenom: prenom,
  nom: 'Sow',
  role: role,
  etat: AccountStatus.pendingKyc,
  inscritLe: DateTime.now().subtract(const Duration(days: 3)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 2,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

const ConformiteCompte _requise = ConformiteCompte(
  exigence: ExigenceKyc.requise,
  etat: EtatKyc.nonCommence,
  contratAccepte: true,
);

const ConformiteCompte _dispensee = ConformiteCompte(
  exigence: ExigenceKyc.dispensee,
  etat: EtatKyc.dispense,
  contratAccepte: true,
);

Future<FauxPortConformite> _monter(
  WidgetTester tester, {
  required List<CompteAdmin> comptes,
  required Map<String, ConformiteCompte> conformites,
  Object? erreurEcriture,
}) async {
  // Le cadre est large a dessein : la colonne d'actions de `DataCollection`
  // n'existe qu'a partir du rendu tabulaire.
  tester.view.physicalSize = const Size(1400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final FauxPortConformite port = FauxPortConformite(parCompte: conformites)
    ..erreurEcriture = erreurEcriture;
  await tester.pumpWidget(
    hote(
      const ComptesPage(),
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_FauxComptes(comptes)),
        portConformiteProvider.overrideWithValue(port),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return port;
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('l exigence et l etat KYC se lisent separement', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      comptes: <CompteAdmin>[
        _compte(id: 'T1', role: AppRole.teacher),
        _compte(id: 'G1', role: AppRole.guardian, prenom: 'Fatou'),
      ],
      conformites: <String, ConformiteCompte>{
        'T1': _requise,
        'G1': const ConformiteCompte(
          exigence: ExigenceKyc.optionnelle,
          etat: EtatKyc.verifie,
          contratAccepte: true,
        ),
      },
    );

    expect(tester.takeException(), isNull);
    expect(find.text(t.classes.conformite.exigenceRequise), findsOneWidget);
    expect(find.text(t.classes.conformite.etatNonCommence), findsOneWidget);
    expect(find.text(t.classes.conformite.exigenceOptionnelle), findsOneWidget);
    expect(find.text(t.classes.conformite.etatVerifie), findsOneWidget);
    // Seul l'enseignant porte une action de dispense.
    expect(find.byType(MenuActions), findsOneWidget);
  });

  testWidgets(
    'dispenser : une confirmation courte, un motif requis, une ecriture',
    (WidgetTester tester) async {
      final FauxPortConformite port = await _monter(
        tester,
        comptes: <CompteAdmin>[_compte(id: 'T1', role: AppRole.teacher)],
        conformites: <String, ConformiteCompte>{'T1': _requise},
      );

      await _presser(tester, find.byType(MenuActions));
      await _presser(tester, find.text(t.classes.conformite.actionDispenser).last);

      // La feuille nomme la personne et dit la consequence en clair.
      expect(
        find.text(t.classes.conformite.dispenserTitre(libelle: 'Aicha Sow')),
        findsOneWidget,
      );
      expect(
        find.text(
          t.classes.conformite.dispenserConsequence(libelle: 'Aicha Sow'),
        ),
        findsOneWidget,
      );
      // Sans motif, rien ne part.
      ActionPrincipale envoi = tester.widget<ActionPrincipale>(
        find.widgetWithText(
          ActionPrincipale,
          t.classes.conformite.dispenserEnvoyer,
        ),
      );
      expect(envoi.onPress, isNull);
      expect(port.ecritures, isEmpty);

      await tester.enterText(
        find.byType(TextField).last,
        'Enseignante connue de l academie depuis 2019',
      );
      await tester.pumpAndSettle();
      envoi = tester.widget<ActionPrincipale>(
        find.widgetWithText(
          ActionPrincipale,
          t.classes.conformite.dispenserEnvoyer,
        ),
      );
      expect(envoi.onPress, isNotNull);

      await _presser(
        tester,
        find.widgetWithText(
          ActionPrincipale,
          t.classes.conformite.dispenserEnvoyer,
        ),
      );

      expect(port.ecritures, hasLength(1));
      expect(port.ecritures.single.profilId, 'T1');
      expect(port.ecritures.single.requise, isFalse);
      expect(port.ecritures.single.motif, contains('2019'));
      expect(find.text(t.classes.conformite.enregistre), findsOneWidget);
    },
  );

  testWidgets('une dispense se retablit, et le menu le dit', (
    WidgetTester tester,
  ) async {
    final FauxPortConformite port = await _monter(
      tester,
      comptes: <CompteAdmin>[_compte(id: 'T1', role: AppRole.teacher)],
      conformites: <String, ConformiteCompte>{'T1': _dispensee},
    );

    expect(find.text(t.classes.conformite.exigenceDispensee), findsOneWidget);
    await _presser(tester, find.byType(MenuActions));
    await _presser(tester, find.text(t.classes.conformite.actionRetablir).last);
    await tester.enterText(find.byType(TextField).last, 'Piece demandee');
    await tester.pumpAndSettle();
    await _presser(
      tester,
      find.widgetWithText(ActionPrincipale, t.classes.conformite.retablirEnvoyer),
    );

    expect(port.ecritures.single.requise, isTrue);
  });

  testWidgets('un echec d ecriture se dit en langage humain, dans la feuille', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      comptes: <CompteAdmin>[_compte(id: 'T1', role: AppRole.teacher)],
      conformites: <String, ConformiteCompte>{'T1': _requise},
      erreurEcriture: const EchecDomaine(MotifEchec.capaciteAbsente),
    );

    await _presser(tester, find.byType(MenuActions));
    await _presser(tester, find.text(t.classes.conformite.actionDispenser).last);
    await tester.enterText(find.byType(TextField).last, 'motif');
    await tester.pumpAndSettle();
    await _presser(
      tester,
      find.widgetWithText(ActionPrincipale, t.classes.conformite.dispenserEnvoyer),
    );

    expect(
      find.text(
        t.classes.conformite.echec(message: t.classes.erreur.capaciteAbsente),
      ),
      findsOneWidget,
    );
    expect(find.text(t.classes.conformite.enregistre), findsNothing);
  });
}
