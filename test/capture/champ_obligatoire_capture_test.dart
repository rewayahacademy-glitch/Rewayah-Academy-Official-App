// CHAMP-OBLIGATOIRE (directeur, 08/11/2026 : « les champs obligatoires
// doivent avoir une étoile rouge ou point ») : captures de « Qui est
// l'élève ? », l'ajout d'un profil eleve par le tuteur, avant et apres la
// marque partagee. Francais et arabe, 390 x 844 et 1440 x 900, clair, vierge
// puis apres un essai d'envoi sans rien remplir. Donnees de test seulement.
// Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../fixtures/tuteur/faux_creation_profil_eleve.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

/// `avant` sur la base, `apres` avec le lot.
const String _phase = String.fromEnvironment('PHASE', defaultValue: 'apres');

Future<void> _monter(WidgetTester tester, {required bool essai}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: FauxServiceAppairage()
            ..elevesRendus = FoyersFictifs.foyerA,
        ),
        horlogeFoyerProvider.overrideWithValue(() => DateTime(2026, 9, 24, 12)),
        portCreationProfilEleveProvider.overrideWithValue(
          FauxCreationProfilEleve(resultat: const ProfilCree()),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurAjouterEnfant);
  await stabiliser(tester);
  await tester.tap(find.text(t.foyer.ajout.pourQui.enfantTitre));
  await stabiliser(tester);
  await tester.tap(find.byKey(FormulaireProfilEleve.actionKey));
  await stabiliser(tester);
  if (essai) {
    await tester.tap(find.byKey(FormulaireProfilEleve.actionKey));
    await stabiliser(tester);
    // Le haut du formulaire, ou sont les champs.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await stabiliser(tester);
  }
}

void main() {
  group('Capture : CHAMP-OBLIGATOIRE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final bool arabe in <bool>[false, true]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        for (final bool essai in <bool>[false, true]) {
          final String nom =
              '${_phase}_identite_${essai ? 'essai' : 'vierge'}_'
              '${arabe ? 'ar' : 'fr'}_'
              '${taille.width.toInt()}x${taille.height.toInt()}';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(
              () =>
                  LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
            );
            addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
            fixerVueCapture(tester, taille, 1);
            await _monter(tester, essai: essai);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });
}
