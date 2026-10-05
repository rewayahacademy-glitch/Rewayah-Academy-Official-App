// CARTES-PERSO-1 (revue) : le tuteur lit les cartes de la Classe sur la VRAIE
// page `ClasseTuteurPage`, montee par le vrai routeur. La capacite de
// modifier est fausse (celle que le serveur rendrait au tuteur) : les cartes
// se lisent, ne se pressent pas, et le lien se copie.
//
// Donnees : fixtures de `support_classe.dart` et le port de demonstration
// des cartes (`surchargesCartesClasseDemo`). Aucun service reel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../../router/support_routeur.dart';
import 'support_classe.dart';

Future<void> _monter(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesClasse(),
        ...surchargesCartesClasseDemo(classeA, peutModifier: false),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.classePour(classeA, eleveId: eleveA1));
  await stabiliser(tester);
}

void main() {
  for (final Size taille in const <Size>[Size(390, 3000), Size(1440, 2000)]) {
    final String l = '${taille.width.toInt()}';
    testWidgets('Classe du tuteur, $l : les cartes de l enseignant se lisent, '
        'sans modification', (WidgetTester tester) async {
      await _monter(tester, taille);
      expect(find.byType(ClasseTuteurPage), findsOneWidget);
      final Finder bloc = find.descendant(
        of: find.byType(ClasseTuteurPage),
        matching: find.byType(BlocCartesClasse),
      );
      expect(bloc, findsOneWidget);
      final Finder cartes = find.byType(VueCarteClasse);
      expect(cartes, findsNWidgets(3));
      // Ordre de la Classe : devoir, lien, rappel (positions 0, 1, 2).
      final List<String> titres = tester
          .widgetList<VueCarteClasse>(cartes)
          .map((VueCarteClasse v) => v.carte.titre)
          .toList();
      expect(titres, <String>[
        'Réviser la sourate Al-Fil',
        'Récitation modèle',
        'Pas de séance pendant les vacances',
      ]);
      // Capacite fausse : aucune carte ne se presse, aucun ajout, aucune
      // phrase de l'enseignant.
      for (final VueCarteClasse v in tester.widgetList<VueCarteClasse>(
        cartes,
      )) {
        expect(v.onModifier, isNull, reason: v.carte.titre);
      }
      expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
      expect(
        find.text(isolerSens(t.classe.cartes.contexteEnseignant)),
        findsNothing,
      );
      // Le lien est une action de lecture.
      final Finder copier = find.widgetWithText(
        LienFleche,
        t.classe.cartes.copierLien(titre: isolerSens('Récitation modèle')),
      );
      expect(copier, findsOneWidget);
      // Toucher une carte n'ouvre rien.
      await tester.ensureVisible(cartes.first);
      await stabiliser(tester);
      await tester.tap(cartes.first, warnIfMissed: false);
      await stabiliser(tester);
      expect(find.byType(FeuilleCarteClasse), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
