// La salle de l'enseignant, CLV-06 (T4) : rail, outils, Eleves et Supports,
// pagination active, zoom, Reseau ; rien de cela chez l'eleve ni en guidee ;
// aucun debordement aux trois tailles, clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void _rien() {}
void _outil(OutilEnseignement _) {}
void _aller(String _) {}

const ActionsSeance _complet = ActionsSeance(
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
);

const ActionsSeance _sansOutil = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onReseau: _rien,
  onEleves: _rien,
  onSupports: _rien,
  onNaviguer: _aller,
);

const Map<String, Size> _tailles = <String, Size>{
  'mobile': Size(390, 844),
  'web etroit': Size(640, 1000),
  'desktop': Size(1440, 900),
};

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  RoleSeance role = RoleSeance.enseignant,
  EtatDemoSalle etat = EtatDemoSalle.visite,
  ActionsSeance actions = _complet,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleSeance(vue: DonneesSeanceDemo.vue(role, etat), actions: actions),
      themeMode: mode,
      interfaceMode: role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// Le point de visite clignote sans fin : pas de pumpAndSettle.
Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  for (final MapEntry<String, Size> taille in _tailles.entries) {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('enseignant ${taille.key} ${mode.name} : CLV-06, '
          'sans debordement', (WidgetTester tester) async {
        await _monter(tester, taille.value, mode: mode);
        expect(tester.takeException(), isNull);
        expect(find.text('Tuteur de Mariam observe.'), findsOneWidget);
        expect(
          find.text('Classe An-Nour · La séance se poursuit.'),
          findsOneWidget,
        );
        expect(find.text('Votre parent observe la séance.'), findsNothing);
        expect(find.text('Ton parent observe la séance.'), findsNothing);
        expect(find.text('Mariam'), findsNothing);
        expect(find.textContaining('Foyer'), findsNothing);
        expect(find.text('Agrandir'), findsNothing);
        expect(_cle('bouton-agrandir'), findsNothing);
        expect(find.textContaining('Terminer pour tous'), findsNothing);
        expect(find.textContaining('Prolonger'), findsNothing);
        expect(find.text('Élèves 1/3'), findsOneWidget);
        expect(find.text('Supports'), findsOneWidget);
        expect(find.text('Réseau'), findsOneWidget);
        for (final String outil in <String>[
          'Pointeur',
          'Marquer',
          'Masquer',
          'Annoter',
        ]) {
          expect(find.text(outil), findsOneWidget);
        }
        final bool desktop = taille.key == 'desktop';
        expect(
          _cle('pagination-support'),
          desktop ? findsOneWidget : findsNothing,
        );
        expect(_cle('zoom-local'), desktop ? findsOneWidget : findsNothing);
        expect(
          find.text('Zoom local, sans effet sur les autres'),
          findsNothing,
        );
        expect(_cle('rail-seance'), desktop ? findsOneWidget : findsNothing);
        expect(
          _cle('separateur-dock'),
          desktop ? findsOneWidget : findsNothing,
        );
        expect(_cle('signal-video'), findsOneWidget);
      });
    }
  }

  testWidgets('le compteur = le nombre de « Connecte » de la liste', (
    WidgetTester tester,
  ) async {
    final VueSeance vue = DonneesSeanceDemo.vue(
      RoleSeance.enseignant,
      EtatDemoSalle.visite,
    );
    final int connectes = vue.eleves
        .where((EleveSeance e) => e.statut == StatutEleveSeance.connecte)
        .length;
    expect(vue.compteurEleves, 'Élèves $connectes/${vue.eleves.length}');
    expect(vue.compteurEleves, 'Élèves 1/3');
  });

  for (final MapEntry<String, Size> taille in _tailles.entries) {
    testWidgets('outils absents si onOutil est nul (${taille.key})', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille.value, actions: _sansOutil);
      expect(tester.takeException(), isNull);
      expect(find.text('Pointeur'), findsNothing);
      expect(_cle('outil-pointeur'), findsNothing);
      expect(find.text('Élèves 1/3'), findsOneWidget);
    });

    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.eleve,
      RoleSeance.guidee,
    ]) {
      testWidgets('${role.name} ${taille.key} : rien de reserve a '
          "l'enseignant, meme avec tous les rappels", (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille.value, role: role);
        expect(tester.takeException(), isNull);
        for (final String texte in <String>[
          'Élèves 1/3',
          'Supports',
          'Réseau',
          'Pointeur',
          'Marquer',
          'Masquer',
          'Annoter',
          'Journée',
          'Classes',
          'Tuteur de Mariam observe.',
        ]) {
          expect(find.text(texte), findsNothing, reason: texte);
        }
        expect(_cle('rail-seance'), findsNothing);
        expect(_cle('pagination-support'), findsNothing);
        expect(_cle('bouton-reseau'), findsNothing);
        expect(find.textContaining('Foyer'), findsNothing);
      });
    }
  }

  testWidgets('desktop : rail sans « Foyer » ni « Séance en direct »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _tailles['desktop']!);
    for (final String entree in <String>[
      'Journée',
      'Classes',
      'Ressources',
      'Profil',
    ]) {
      expect(find.text(entree), findsOneWidget);
    }
    // Le seul « Séance en direct » est le titre, pas une entree du rail.
    expect(find.text('Séance en direct'), findsOneWidget);
    expect(find.text('Sayyida Amina'), findsWidgets);
    expect(find.text('SA'), findsOneWidget);
  });

  testWidgets('rail : la sortie passe par la confirmation de Quitter', (
    WidgetTester tester,
  ) async {
    String? route;
    fixerVueCapture(tester, _tailles['desktop']!, 1);
    await tester.pumpWidget(
      hoteCapture(
        SalleSeance(
          vue: DonneesSeanceDemo.vue(
            RoleSeance.enseignant,
            EtatDemoSalle.visite,
          ),
          actions: ActionsSeance(
            onQuitter: _rien,
            onNaviguer: (String r) => route = r,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Journée'));
    await _attendre(tester);
    expect(route, isNull);
    expect(find.text('Quitter et ouvrir le cahier'), findsOneWidget);
    expect(
      find.text('Vous passerez ensuite au cahier de transmission.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Quitter et ouvrir le cahier'));
    await _attendre(tester);
    expect(route, '/enseignant/journee');
  });

  testWidgets('Quitter (dock) : « Quitter et ouvrir le cahier »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _tailles['mobile']!);
    await tester.tap(find.text('Quitter'));
    await _attendre(tester);
    expect(find.text('Quitter et ouvrir le cahier'), findsOneWidget);
    // Spec CLV-06, textes exacts : « Rester », jamais « Annuler ».
    expect(find.text('Rester'), findsOneWidget);
    expect(find.text('Annuler'), findsNothing);
    expect(find.textContaining('Terminer pour tous'), findsNothing);
    expect(find.textContaining('Prolonger'), findsNothing);
  });

  // Geometrie mesuree avec les vraies polices du depot et la zone sure du
  // telephone, comme les captures : la police de test elargit tout texte.
  group('mise en page reelle', () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monterReel(WidgetTester tester, String taille) async {
      final bool mobile = taille == 'mobile';
      fixerVueCapture(
        tester,
        _tailles[taille]!,
        mobile ? 3 : 1,
        zoneSure: mobile
            ? const EdgeInsets.only(top: 47, bottom: 34)
            : EdgeInsets.zero,
      );
      await tester.pumpWidget(
        hoteCapture(
          SalleSeance(
            vue: DonneesSeanceDemo.vue(
              RoleSeance.enseignant,
              EtatDemoSalle.visite,
            ),
            actions: _complet,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final String taille in <String>['mobile', 'desktop']) {
      testWidgets('$taille : la diapositive entiere tient dans le support', (
        WidgetTester tester,
      ) async {
        await monterReel(tester, taille);
        final Rect support = tester.getRect(_cle('zone-support'));
        final Rect derniere = tester.getRect(
          find.text('Respecter les camarades.'),
        );
        // La troisieme consigne est entiere, au-dessus du fondu du bas.
        expect(derniere.bottom, lessThan(support.bottom - 16));
      });
    }

    testWidgets("vignette etroite : le nom de l'enseignante est entier", (
      WidgetTester tester,
    ) async {
      await monterReel(tester, 'mobile');
      final Finder vignette = _cle('vignette-video');
      final Rect cadre = tester.getRect(vignette);
      final Rect nom = tester.getRect(_cle('nom-video'));
      expect(
        find.descendant(of: vignette, matching: find.text('Sayyida Amina')),
        findsOneWidget,
      );
      expect(cadre.contains(nom.topLeft), isTrue);
      expect(cadre.contains(nom.bottomRight - const Offset(1, 1)), isTrue);
    });
  });
}
