// COUPE-MOTS-4 (3) : dans Comptes (administration), l'identifiant
// « TEACHER-AS-000001 » se coupait a son trait d'union a 320 px en texte x2
// (« TEACHER-AS- / 000001 »). Il est affiche avec des traits d'union
// insecables (U+2011) : il passe entier a la ligne.
//
// Cartes (sous 1200) a 320 et 390, tableau a 1440 ; francais et arabe.
// Contre-epreuve : sur l'ancien code (5a52ff30), le test echoue a 320 x2 en
// nommant « TEACHER-AS-000001 ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart' show FauxServiceReseau;
import 'support_coupe_mots_4.dart';

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    for (final (String id, String? prenom) in <(String, String?)>[
      ('TEACHER-AS-000001', 'Aicha'),
      ('TEACHER-AS-000002', null),
    ])
      CompteAdmin(
        profilId: id,
        identifiant: id,
        prenom: prenom,
        nom: prenom == null ? null : 'Sow',
        role: AppRole.teacher,
        etat: AccountStatus.pendingKyc,
        inscritLe: DateTime.now().subtract(const Duration(days: 7)),
        accesJusquAu: null,
        foyerId: null,
        piece: EtatPiece.aucune,
        contrats: 2,
        aEnseignant: false,
        enfantsDuFoyer: 0,
      ),
  ];
}

/// Les paragraphes rendus qui portent l'identifiant, quel que soit son
/// trait d'union.
final RegExp _identifiant = RegExp('TEACHER[-‑]AS[-‑]00000[12]');

void main() {
  preparerCoupeMots4();

  for (final AppLocale langue in languesCoupeMots4) {
    for (final (double largeur, double echelle) in <(double, double)>[
      (320, 2),
      (390, 2),
      (390, 1),
      (1440, 1),
    ]) {
      testWidgets('${langue.name} $largeur x${echelle.toInt()} : '
          'l identifiant tient sur une ligne', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => const ComptesPage(),
          langue: langue,
          largeur: largeur,
          hauteur: largeur > 1000 ? 900 : 3000,
          echelle: echelle,
          surcharges: <Override>[
            serviceComptesProvider.overrideWithValue(_Comptes()),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        );
        expect(tester.takeException(), isNull);
        final Finder porteurs = find.byWidgetPredicate(
          (Widget w) => w is Text && _identifiant.hasMatch(w.data ?? ''),
        );
        expect(porteurs, findsWidgets);
        // Chaque mot de chaque paragraphe qui porte l'identifiant reste
        // entier : le trait d'union ne laisse pas « 000001 » seul a la ligne.
        expect(motsCoupes(tester, porteurs), isEmpty);
        // Et le trait d'union de l'identifiant est insecable a l'ecran : une
        // ligne pleine ne peut plus le couper la (« TEACHER-AS- / 000001 »).
        expect(
          find.textContaining('TEACHER\u2011AS\u2011000001'),
          findsWidgets,
        );
        expect(find.textContaining('TEACHER-AS-000001'), findsNothing);
        // Et l'ecran entier : aucun mot coupe, aucune ponctuation seule.
        verifierEcranEntierCoupeMots4(tester);
      });
    }
  }
}
