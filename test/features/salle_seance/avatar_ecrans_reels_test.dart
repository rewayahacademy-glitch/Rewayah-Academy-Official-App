// AVATAR-1 : le defaut releve par le directeur (avatar decale du nom) est
// mesure sur les ecrans reels, pas seulement sur le composant : le panneau
// Eleves de la salle (ligne = avatar + prenom + statut) et le cadre video sans
// image (`AvatarSansImage`), a 320 px et texte x2.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        await stabiliser(tester);
        expect(tester.takeException(), isNull, reason: 'debordement');
        expect(find.byType(PanneauEleves), findsOneWidget);
        final Finder lignes = find.byType(AvatarNom);
        // A 320 px et texte x2, la feuille Eleves ne laisse aucune ligne
        // visible (liste paresseuse) : la mesure vaut pour les lignes rendues.
        if (vue.width > 320 || echelle == 1) {
          expect(lignes, findsWidgets);
        }
        int mesurees = 0;
        for (int i = 0; i < lignes.evaluate().length; i++) {
          final Finder ligne = lignes.at(i);
          final Finder cercle = find.descendant(
            of: ligne,
            matching: find.byType(AvatarTile),
          );
          if (cercle.evaluate().isEmpty) {
            continue;
          }
          final Rect c = tester.getRect(cercle.first);
          final Rect r = tester.getRect(ligne);
          // Le cercle et le bloc de texte partagent le meme centre vertical
          // (le bloc nom + statut est centre sur le cercle).
          final Finder textes = find.descendant(
            of: ligne,
            matching: find.byType(Text),
          );
          double haut = double.infinity;
          double bas = -double.infinity;
          for (int j = 0; j < textes.evaluate().length; j++) {
            if (find
                .descendant(
                  of: cercle.first,
                  matching: find.byWidget(tester.widget(textes.at(j))),
                )
                .evaluate()
                .isNotEmpty) {
              continue;
            }
            final Rect t = tester.getRect(textes.at(j));
            haut = haut < t.top ? haut : t.top;
            bas = bas > t.bottom ? bas : t.bottom;
          }
          expect(
            ((haut + bas) / 2 - c.center.dy).abs(),
            lessThanOrEqualTo(2),
            reason: 'ligne ${i + 1} : texte decale du cercle (${r.height})',
          );
          expect(haut, greaterThanOrEqualTo(c.top - toleranceGarde));
          mesurees++;
        }
        if (vue.width > 320 || echelle == 1) {
          expect(mesurees, greaterThan(0));
        }
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
