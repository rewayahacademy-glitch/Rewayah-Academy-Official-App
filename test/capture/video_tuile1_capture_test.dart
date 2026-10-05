// VIDEO-TUILE-1 : les tuiles video sans image (cercle + nom centre dessous) et
// la marge laterale de la galerie, a 320 et 390 px. Jamais sans `CAPTURE_DIR`
// (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import 'outil_capture.dart';

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

Future<void> _capturerControleur(
  WidgetTester tester,
  String fichier,
  Size taille,
) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: cheminDemoSalleControleur,
    routes: routesDemoControleur('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext contexte) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: ThemeMode.light,
              locale: TranslationProvider.of(contexte).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : VIDEO-TUILE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('320', const Size(320, 700)),
      ('390', const Size(390, 844)),
    ]) {
      testWidgets('ctrl_salle_$l', (WidgetTester tester) async {
        await _capturerControleur(tester, 'ctrl_salle_$l', taille);
      });
      for (final (String, RoleSeance, EtatDemoSalle, PanneauOuvert?) cas
          in <(String, RoleSeance, EtatDemoSalle, PanneauOuvert?)>[
            ('salle_eleve', RoleSeance.eleve, EtatDemoSalle.repos, null),
            (
              'panneau_eleves',
              RoleSeance.enseignant,
              EtatDemoSalle.eleves,
              PanneauOuvert.eleves,
            ),
          ]) {
        testWidgets('${cas.$1}_$l', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1);
          VueSeance v = DonneesSeanceDemo.vue(cas.$2, cas.$3);
          if (cas.$4 != null) {
            v = v.copyWith(panneau: cas.$4);
          }
          await tester.pumpWidget(
            hoteCapture(SalleSeance(vue: v, actions: _actions)),
          );
          await tester.pump();
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, '${cas.$1}_$l')}');
        });
      }
    }
  });
}
