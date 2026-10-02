// AVATAR-1 : le defaut releve par le directeur (avatar decale du nom) est
// mesure sur les ecrans reels, pas seulement sur le composant : le panneau
// Eleves de la salle (ligne = avatar + prenom + statut) et le cadre video sans
// image (`AvatarSansImage`), a 320 px et texte x2.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';

void _rien() {}
void _outil(OutilEnseignement _) {}
void _aller(String _) {}
void _eleve(EleveSeance _) {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onAgrandir: _rien,
  onReseau: _rien,
  onEleves: _rien,
  onSupports: _rien,
  onOutil: _outil,
  onPagePrecedente: _rien,
  onPageSuivante: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onNaviguer: _aller,
  onRappeler: _eleve,
  onChoisirPourReciter: _eleve,
  onNoter: _eleve,
  onSignaler: _eleve,
);

void main() {
  for (final Size vue in <Size>[const Size(320, 640), const Size(1440, 900)]) {
    for (final double echelle in <double>[1, 2]) {
      final String ou = '${vue.width.toInt()} px, texte x${echelle.toInt()}';

      testWidgets('panneau Eleves : chaque cercle est centre sur son prenom, '
          '$ou', (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        final VueSeance v = DonneesSeanceDemo.vue(
          RoleSeance.enseignant,
          EtatDemoSalle.eleves,
        ).copyWith(panneau: PanneauOuvert.eleves);
        await tester.pumpWidget(
          hoteCapture(
            SalleSeance(vue: v, actions: _actions),
            echelleTexte: echelle,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'debordement');
        final Finder panneau = find.byType(PanneauEleves);
        expect(panneau, findsOneWidget);
        final Finder lignes = find.descendant(
          of: panneau,
          matching: find.byType(AvatarNom),
        );
        expect(lignes, findsWidgets);
        int mesurees = 0;
        for (final EleveSeance e in v.eleves) {
          final Finder nom = find.descendant(
            of: panneau,
            matching: find.text(e.prenom),
          );
          if (nom.evaluate().isEmpty) {
            continue;
          }
          final Finder ligne = find.ancestor(
            of: nom.first,
            matching: find.byType(AvatarNom),
          );
          final Finder cercle = find.descendant(
            of: ligne.first,
            matching: find.byType(AvatarTile),
          );
          if (cercle.evaluate().isEmpty) {
            continue;
          }
          final Rect n = tester.getRect(nom.first);
          final Rect c = tester.getRect(cercle.first);
          // Le prenom est dans la hauteur du cercle (une ligne de statut
          // peut le suivre) et son bord haut ne passe pas sous le cercle.
          expect(
            n.top,
            greaterThanOrEqualTo(c.top - toleranceGarde),
            reason: '${e.prenom} : prenom plus haut que son cercle',
          );
          expect(
            n.left,
            greaterThanOrEqualTo(c.right - toleranceGarde),
            reason: '${e.prenom} : prenom doit suivre le cercle',
          );
          mesurees++;
        }
        expect(mesurees, greaterThan(0));
      });

      testWidgets('cadre video sans image : cercle centre, nom absent du '
          'cercle, contenu dans le cadre, $ou', (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        const Key cadre = ValueKey<String>('cadre-sans-image');
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: Center(
                child: SizedBox(
                  key: cadre,
                  width: 160,
                  height: 120,
                  child: AvatarSansImage(
                    prenom: 'Abderrahmane',
                    legende: 'Sans image',
                  ),
                ),
              ),
            ),
            echelleTexte: echelle,
          ),
        );
        expect(tester.takeException(), isNull, reason: 'debordement');
        verifierContenu(tester, find.byType(AvatarTile), find.byKey(cadre));
        verifierMemeAxe(
          tester,
          find.byType(AvatarTile),
          find.text('Sans image'),
        );
        verifierMemeAxe(tester, find.byType(AvatarTile), find.byKey(cadre));
      });
    }
  }
}
