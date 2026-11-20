// ENTREE-PRAXIS : les captures de la page d'entree, etat par etat, pour les
// poser a cote de la maquette « Praxis vous accueille »
// (`docs/current/captures/E2E/pe-entree-praxis/`). Saute sans CAPTURE_DIR.
//
//   CAPTURE_DIR=docs/current/captures/E2E/pe-entree-praxis/application \
//     flutter test --no-pub test/features/connexion/entree_praxis_capture_test.dart
import 'dart:async';
import 'dart:io' show Platform;

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
import 'package:rewayah_academy/core/vivant/entree/scene_entree.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/coquille_praxis.dart';
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

/// Les etats captures et deux bornes en millisecondes depuis l'ouverture de
/// la page (celles des captures de la maquette, `entree-outils/lot-*.json`) :
/// la scene n'est pas jugee au repos avant la premiere, et on cesse de
/// l'attendre 8 secondes apres la seconde.
const List<(String, int, int)> _etats = <(String, int, int)>[
  ('arrivee', 8500, 12000),
  ('saisie', 7500, 10500),
  ('adresse', 7000, 9500),
  ('envoi', 6500, 8500),
  ('envoye', 6500, 9000),
  ('serveur', 7000, 10000),
  ('trop', 7000, 10500),
  ('horsLigne', 8500, 11000),
  ('session', 7000, 10500),
  ('sansInvitation', 7000, 10000),
  ('candidat', 8500, 12000),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await chargerPolicesDuDepot();
    await Atelier.preparer();
    // L'arabe est charge a la demande : une fois ici, puis retour au francais.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('captures de la page d entree', skip: sautSansCapture, () {
    for (final (String format, Size taille, double densite)
        in <(String, Size, double)>[
          ('tel', const Size(390, 844), 2),
          ('large', const Size(1440, 900), 1),
        ]) {
      for (final bool sombre in <bool>[false, true]) {
        for (final String langue in <String>['fr', 'ar']) {
          for (final (String etat, int t1, int t2) in _etats) {
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
              int ecoule = 0;
              Future<void> attendre(int ms) async {
                for (int i = 0; i < ms ~/ 50; i++) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
                ecoule += ms ~/ 50 * 50;
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
              // CAPTURE_INSTANTS=3000,4000,... : une suite d'images, pour
              // suivre une scene.
              final String? suite = Platform.environment['CAPTURE_INSTANTS'];
              if (suite != null) {
                for (final int t in suite.split(',').map(int.parse)) {
                  await attendre(t - ecoule);
                  await capturer(tester, '$nom@$t');
                }
                return;
              }
              // Deux moments de la scene, lus sur la regie (et non a l'heure :
              // l'horloge de la maquette, dans un navigateur, varie d'une
              // seconde d'un essai a l'autre) : « -1 », la phrase de Praxis
              // posee au-dessus de sa tete, tous ses mots nes, aucun encore
              // envole (a defaut, l'instant de la maquette) ; « -2 », la scene
              // revenue au repos, les mots partis dans la porte.
              final Theatre th = tester
                  .state<CoquillePraxisState>(find.byType(CoquillePraxis))
                  .regie
                  .th;
              bool posee() {
                final Parole? p = th.parole;
                return p != null &&
                    p.mots.isNotEmpty &&
                    p.mots.every((MotVol m) => m.ne && m.t.x > 0.98) &&
                    !p.mots.any((MotVol m) => m.part);
              }

              // La derniere phrase posee de la scene ecrase les precedentes.
              Parole? derniere;
              while (ecoule < t2 + 8000) {
                final Parole? p = th.parole;
                if (posee() && !identical(p, derniere)) {
                  derniere = p;
                  // Le temps que le dernier mot ne rebondisse plus.
                  await attendre(400);
                  if (identical(th.parole, p) && posee()) {
                    await capturer(tester, '$nom-1');
                  }
                }
                if (ecoule >= t1 && th.parole == null && !th.attend) break;
                await attendre(50);
              }
              if (derniere == null) await capturer(tester, '$nom-1');
              await attendre(400);
              await capturer(tester, '$nom-2');
            });
          }
        }
      }
    }
  });
}
