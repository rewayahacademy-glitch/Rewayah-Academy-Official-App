// ENTREE-PRAXIS : les captures de la page d'entree, etat par etat, pour les
// poser a cote de la maquette « Praxis vous accueille »
// (`docs/current/captures/E2E/pe-entree-praxis/`). Saute sans CAPTURE_DIR.
//
//   CAPTURE_DIR=docs/current/captures/E2E/pe-entree-praxis/application \
//     flutter test --no-pub test/features/connexion/entree_praxis_capture_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/vivant/entree/lumiere_entree.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../capture/outil_capture.dart';

class _Auth implements ServiceAuth {
  _Auth(this.etat);
  final String etat;

  @override
  Future<void> envoyerLienCourriel(String courriel, {String? jetonControle}) {
    switch (etat) {
      case 'envoi':
        return Completer<void>().future;
      case 'serveur':
        throw const AuthException('panne', statusCode: '500');
      case 'trop':
        throw const AuthException('trop', statusCode: '429');
      case 'sansInvitation':
        throw const AuthException('Signups not allowed for otp');
    }
    return Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Reseau implements ServiceReseau {
  _Reseau(this.flux);
  final Stream<bool> flux;
  @override
  Stream<bool> horsLigne() => flux;
}

const String _adresse = 'amina.b@exemple.com';

/// Les etats captures : nom, secondes d'attente avant la capture.
const List<(String, int)> _etats = <(String, int)>[
  ('arrivee', 13),
  ('saisie', 11),
  ('adresse', 11),
  ('envoi', 10),
  ('envoye', 11),
  ('serveur', 11),
  ('trop', 11),
  ('horsLigne', 12),
  ('session', 11),
  ('sansInvitation', 11),
  ('candidat', 13),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await chargerPolicesDuDepot();
    await Atelier.preparer();
  });

  group('captures de la page d entree', skip: sautSansCapture, () {
    for (final (String format, Size taille, double densite)
        in <(String, Size, double)>[
          ('tel', const Size(390, 844), 2),
          ('large', const Size(1440, 900), 1),
        ]) {
      for (final bool sombre in <bool>[false, true]) {
        for (final String langue in <String>['fr', 'ar']) {
          for (final (String etat, int secondes) in _etats) {
            final String nom =
                '$format-${sombre ? 'sombre' : 'clair'}-$langue--$etat';
            testWidgets(nom, (WidgetTester tester) async {
              fixerVueCapture(tester, taille, densite);
              masquerRubanDebug();
              LocaleSettings.setLocaleSync(
                langue == 'ar' ? AppLocale.ar : AppLocale.fr,
              );
              addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
              sessionTermineeParLeServeur.value = etat == 'session';
              addTearDown(() => sessionTermineeParLeServeur.value = false);
              final StreamController<bool> reseau = StreamController<bool>();
              addTearDown(reseau.close);
              reseau.add(false);
              await tester.pumpWidget(
                RepaintBoundary(
                  key: cadreCapture,
                  child: ProviderScope(
                    overrides: <Override>[
                      serviceAuthProvider.overrideWithValue(_Auth(etat)),
                      serviceReseauProvider.overrideWithValue(
                        _Reseau(reseau.stream),
                      ),
                      demoAuthActiveProvider.overrideWithValue(false),
                    ],
                    child: TranslationProvider(
                      child: MaterialApp(
                        theme: AppTheme.pour(
                          InterfaceMode.standard,
                          Brightness.light,
                        ),
                        darkTheme: AppTheme.pour(
                          InterfaceMode.standard,
                          Brightness.dark,
                        ),
                        themeMode: sombre ? ThemeMode.dark : ThemeMode.light,
                        builder: (BuildContext context, Widget? enfant) =>
                            Directionality(
                              textDirection: langue == 'ar'
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              child: enfant!,
                            ),
                        home: ConnexionPage(
                          urlRetour: Uri.parse(
                            etat == 'candidat'
                                ? 'https://exemple.test/connexion?mode=creer&candidature=1'
                                : 'https://exemple.test/connexion',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              Future<void> attendre(int ms) async {
                for (int i = 0; i < ms ~/ 50; i++) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
              }

              await attendre(400);
              const Set<String> saisis = <String>{
                'saisie',
                'adresse',
                'envoi',
                'envoye',
                'serveur',
                'trop',
                'sansInvitation',
              };
              if (etat == 'horsLigne') reseau.add(true);
              if (saisis.contains(etat)) {
                final String texte = etat == 'adresse'
                    ? _adresse.replaceAll('@', '.')
                    : _adresse;
                final Finder champ = find.byKey(
                  const ValueKey<String>('connexion-courriel'),
                );
                if (etat == 'saisie') {
                  for (int i = 1; i <= texte.length; i++) {
                    await tester.enterText(champ, texte.substring(0, i));
                    await attendre(150);
                  }
                } else {
                  await tester.enterText(champ, texte);
                  await attendre(200);
                  final ActionPrincipale bouton = tester
                      .widgetList<ActionPrincipale>(
                        find.byType(ActionPrincipale),
                      )
                      .firstWhere(
                        (ActionPrincipale b) =>
                            b.niveau == NiveauAction.principale,
                      );
                  bouton.onPress!();
                }
              }
              await attendre(secondes * 1000);
              await capturer(tester, nom);
            });
          }
        }
      }
    }
  });
}
