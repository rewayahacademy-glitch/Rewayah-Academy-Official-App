// PROFIL-ADULTE-PLACE (directeur, 08/11/2026) : captures de l'ajout d'un
// profil eleve par le tuteur. Etape 1 « Pour qui est ce profil eleve ? »,
// etape 2 « Qui est l'eleve ? », et, apres le lot, l'arrivee sur « Creer mon
// profil eleve » depuis « Moi-meme ». Francais et arabe, 390 x 844 et
// 1440 x 900, clair. Donnees de test seulement. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_profil_eleve_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../fixtures/tuteur/faux_capacites.dart';
import '../fixtures/tuteur/faux_creation_profil_eleve.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

/// Ce que montre chaque capture.
enum _Etat { pourQui, identite, moiMeme }

/// Le dossier de sortie : `avant` sur la base, `apres` avec le lot.
const String _phase = String.fromEnvironment('PHASE', defaultValue: 'apres');

Future<void> _monter(WidgetTester tester, _Etat etat) async {
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
        // Comme en production (main.dart branche le serveur) : le tuteur n'a
        // pas encore son profil eleve, la page le lui propose.
        portProfilEleveTitulaireProvider.overrideWithValue(
          FauxProfilEleveTitulaire(),
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
  if (etat == _Etat.pourQui) {
    return;
  }
  await tester.tap(
    find.text(
      etat == _Etat.moiMeme
          ? t.foyer.ajout.pourQui.moiTitre
          : t.foyer.ajout.pourQui.enfantTitre,
    ),
  );
  await stabiliser(tester);
  await tester.tap(find.byKey(FormulaireProfilEleve.actionKey));
  await stabiliser(tester);
}

void main() {
  group('Capture : PROFIL-ADULTE-PLACE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final bool arabe in <bool>[false, true]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        for (final _Etat etat in <_Etat>[
          _Etat.pourQui,
          _Etat.identite,
          if (_phase == 'apres') _Etat.moiMeme,
        ]) {
          final String nom =
              '${_phase}_${etat.name}_${arabe ? 'ar' : 'fr'}_'
              '${taille.width.toInt()}x${taille.height.toInt()}';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(
              () =>
                  LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
            );
            addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
            fixerVueCapture(tester, taille, 1);
            await _monter(tester, etat);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }
  });
}
