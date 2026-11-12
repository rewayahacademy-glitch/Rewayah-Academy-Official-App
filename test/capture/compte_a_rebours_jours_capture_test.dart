// COMPTE-A-REBOURS-JOURS (12/11/2026) : la carte de seance a 110 h 14 de
// l'heure du cours, pour l'eleve (tutoye), l'adulte et le tuteur, en FR et AR.
// Avant : « Cours dans 110 h 14 ». Apres : des jours.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../support/carte_session_fournie.dart';
import '../support/demo/accessibilite_demo.dart';
import '../support/demo/classe_demo.dart';
import 'outil_capture.dart';

typedef _Cas = ({String nom, RoleEspaceGroupe role, bool tutoiement});

const List<_Cas> _cas = <_Cas>[
  (nom: 'eleve_mineur', role: RoleEspaceGroupe.eleve, tutoiement: true),
  (nom: 'eleve_adulte', role: RoleEspaceGroupe.eleve, tutoiement: false),
  (nom: 'tuteur', role: RoleEspaceGroupe.tuteur, tutoiement: false),
];

GroupHomeVM _espace(RoleEspaceGroupe role, Duration avant) {
  final GroupHomeVM base = DonneesAccessibiliteDemo.espaceAccueil(
    MomentDemoAccessibilite.avant,
  );
  return GroupHomeVM(
    identite: base.identite,
    role: role,
    horloge: SessionClockVM.depuisFenetre(
      fenetre: DonneesClasseDemo.fenetre,
      maintenantServeurUtc: DonneesClasseDemo.debutUtc.subtract(avant),
      horlogeUtilisateur: DonneesClasseDemo.horlogeUtilisateur,
      sessionId: 'demo-seance-an-nour',
      connecte: false,
    ),
    avantProchainCours: base.avantProchainCours,
    bibliotheque: base.bibliotheque,
    afficheConseilAppareil: false,
  );
}

void main() {
  group('Capture : COMPTE-A-REBOURS-JOURS', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final _Cas cas in _cas) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        final TextDirection sens = langue == AppLocale.ar
            ? TextDirection.rtl
            : TextDirection.ltr;
        testWidgets('${cas.nom}_${langue.languageCode}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 640), 1);
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await tester.pumpWidget(
            ProviderScope(
              child: TranslationProvider(
                child: RepaintBoundary(
                  key: cadreCapture,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    locale: langue.flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                    builder: (BuildContext c, Widget? app) =>
                        Directionality(textDirection: sens, child: app!),
                    home: Scaffold(
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: carteSessionDeTest(
                          espace: _espace(
                            cas.role,
                            const Duration(hours: 110, minutes: 14),
                          ),
                          tutoiement: cas.tutoiement,
                          onRejoindre: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await stabiliser(tester);
          expect(find.byType(CarteSession), findsOneWidget);
          expect(find.textContaining('110'), findsNothing);
          expect(tester.takeException(), isNull);
          await capturer(tester, '${cas.nom}_${langue.languageCode}');
        });
      }
    }
  });
}
