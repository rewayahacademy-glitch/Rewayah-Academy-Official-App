// MA-TUTOIEMENT-1 (decision A4 = a) : dans la VRAIE salle (`SallePage`), en
// Mode Accessibilite, l'ecran de fin suit l'age de l'eleve, jamais la
// presentation : un enfant est tutoye, un adulte vouvoye, et un age inconnu
// (port neutre de l'application avant BR-1, aucune surcharge) vouvoie.
//
// Avant le correctif, la salle passait `tutoiement: true` en dur : l'adulte
// lisait « Tu as quitte la seance ».

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/age_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/accueil_eleve/apres_seance_accessibilite.dart';

import 'support_ma_apres1.dart';

void main() {
  for (final (String nom, AgeEleve? age, bool tu)
      in <(String, AgeEleve?, bool)>[
        ('enfant (mineur connu)', AgeEleve.mineur, true),
        ('adulte connu', AgeEleve.adulte, false),
        ('age inconnu, port neutre de l application', null, false),
      ]) {
    testWidgets('MA-TUTOIEMENT-1 : vraie salle, $nom : '
        '${tu ? 'tutoye' : 'vouvoye'}', (WidgetTester tester) async {
      await quitterLaSalleMa(
        tester,
        groupes: GroupesMaApres(() async => null),
        age: age,
      );
      expect(find.byType(ApresSeanceAccessibilite), findsOneWidget);
      expect(
        find.text(t.accessibilite.apres.quitteTitre),
        tu ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(t.salle.fin.quitteTitre),
        tu ? findsNothing : findsOneWidget,
      );
      expect(
        find.text(t.accessibilite.apres.quittePhrase),
        tu ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(t.salle.fin.quittePhrase),
        tu ? findsNothing : findsOneWidget,
      );
      // L'etat vide suit le meme registre.
      expect(
        find.text(t.accessibilite.apres.vide),
        tu ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(t.accessibilite.apres.videVous),
        tu ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
