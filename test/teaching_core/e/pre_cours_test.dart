import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/tc_classe_live/pre_vol_classe.dart';

import 'support/hote_classe.dart';

/// Le pre-cours par role (spec section 9.5).
///
/// **Trois comportements, et ils ne se ressemblent pas** : l'enseignant voit son
/// preflight, l'eleve ne voit rien tant que rien ne bloque, le tuteur n'est
/// meme pas teste.
void main() {
  const ResultatPreVol complet = ResultatPreVol(
    microDisponible: true,
    cameraDisponible: true,
    sortieAudioDisponible: true,
    permissionRefusee: false,
  );
  const ResultatPreVol sansMicro = ResultatPreVol(
    microDisponible: false,
    cameraDisponible: true,
    sortieAudioDisponible: true,
    permissionRefusee: false,
  );
  const ResultatPreVol refuse = ResultatPreVol(
    microDisponible: false,
    cameraDisponible: false,
    sortieAudioDisponible: false,
    permissionRefusee: true,
  );
  const ResultatPreVol sansCamera = ResultatPreVol(
    microDisponible: true,
    cameraDisponible: false,
    sortieAudioDisponible: true,
    permissionRefusee: false,
  );

  group('detail par role', () {
    test('enseignant : preflight complet', () {
      final VuePreCours vue = VuePreCours.depuis(
        role: RoleSalle.enseignant,
        resultat: complet,
      );
      expect(vue.detail, DetailPreCours.complet);
      expect(vue.visible, isTrue);
      expect(vue.bloque, isFalse);
    });

    test('eleve : verifications silencieuses', () {
      final VuePreCours vue = VuePreCours.depuis(
        role: RoleSalle.eleve,
        resultat: complet,
      );
      expect(vue.detail, DetailPreCours.silencieux);
      // Un enfant de sept ans n'a pas a lire un bilan materiel.
      expect(vue.visible, isFalse);
    });

    test('eleve : l action n apparait que si un probleme bloque', () {
      final VuePreCours vue = VuePreCours.depuis(
        role: RoleSalle.eleve,
        resultat: sansMicro,
      );
      expect(vue.visible, isTrue);
      expect(vue.bloque, isTrue);
      expect(vue.motif, MotifPreCours.microAbsent);
    });

    test('tuteur : aucun test micro ni camera', () {
      final VuePreCours vue = VuePreCours.depuis(
        role: RoleSalle.tuteurObservateur,
        resultat: refuse,
      );
      // Sa politique d'observation lui interdit micro et camera : les tester
      // serait au mieux inutile, au pire une demande de permission injustifiee.
      expect(vue.detail, DetailPreCours.aucun);
      expect(vue.visible, isFalse);
      expect(vue.bloque, isFalse);
    });

    test('controleur : aucun test non plus', () {
      expect(
        VuePreCours.depuis(
          role: RoleSalle.controleur,
          resultat: refuse,
        ).detail,
        DetailPreCours.aucun,
      );
    });
  });

  group('regles de blocage', () {
    test('le micro est la seule impasse bloquante', () {
      // Pour une academie de Coran, l'audio prime sur la video : un cours se
      // suit a la voix.
      final VuePreCours vue = VuePreCours.depuis(
        role: RoleSalle.enseignant,
        resultat: sansCamera,
      );
      expect(vue.bloque, isFalse);
      expect(vue.cameraPresente, isFalse);
      expect(vue.motif, isNull);
    });

    test('une permission refusee se distingue d un micro absent', () {
      // C'est la seule cause qui se repare sans changer de materiel.
      expect(
        VuePreCours.depuis(
          role: RoleSalle.enseignant,
          resultat: refuse,
        ).motif,
        MotifPreCours.permissionRefusee,
      );
    });

    test('pas encore mesure n est pas aucun micro', () {
      // Confondre les deux refuserait l'entree a qui a un micro.
      final VuePreCours vue = VuePreCours.depuis(
        role: RoleSalle.enseignant,
        resultat: null,
      );
      expect(vue.bloque, isFalse);
      expect(vue.motif, isNull);
    });
  });

  group('rendu', () {
    testWidgets('l enseignant lit ses deux lignes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteClasse(
          PreCours(
            vue: VuePreCours.depuis(
              role: RoleSalle.enseignant,
              resultat: sansCamera,
            ),
            onReessayer: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text(t.tc.classe.prevol.microOk), findsOneWidget);
      expect(find.text(t.tc.classe.prevol.cameraAbsente), findsOneWidget);
      // Rien ne bloque : aucun bouton de reparation.
      expect(find.text(t.tc.classe.prevol.reessayer), findsNothing);
    });

    testWidgets('un eleve sans probleme ne voit rien du tout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteClasse(
          PreCours(
            vue: VuePreCours.depuis(
              role: RoleSalle.eleve,
              resultat: complet,
            ),
            onReessayer: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('un blocage propose de remesurer', (
      WidgetTester tester,
    ) async {
      int mesures = 0;
      await tester.pumpWidget(
        hoteClasse(
          PreCours(
            vue: VuePreCours.depuis(
              role: RoleSalle.eleve,
              resultat: refuse,
            ),
            onReessayer: () => mesures++,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(t.tc.classe.prevol.permissionRefusee),
        findsOneWidget,
      );
      await tester.tap(find.text(t.tc.classe.prevol.reessayer));
      await tester.pump();
      expect(mesures, 1);
    });
  });
}
