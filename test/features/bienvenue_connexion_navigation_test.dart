// Sous-paquet LA-1 (bienvenue, connexion, recuperation) : boutons tapes
// depuis la navigation reelle (routeur de l'application), pas seulement
// `routeur.go`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/recuperation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

import '../router/support_routeur.dart';
import '../support/harnais.dart';

void main() {
  group('LA-1 : navigation reelle', () {
    testWidgets('depuis /connexion, « Lien expire ou jamais recu ? » mene a la '
        'recuperation, et le retour revient sur la connexion', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.connexion,
        source: FausseSourceSession(),
      );

      final Finder probleme = find.text(t.connexion.probleme);
      await tester.ensureVisible(probleme);
      await tester.pumpAndSettle();
      await tester.tap(probleme);
      await tester.pumpAndSettle();

      expect(lieu(routeur), Routes.connexionRecuperation);
      expect(find.byType(RecuperationPage), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();

      expect(lieu(routeur), Routes.connexion);
    });

    testWidgets(
      'depuis /connexion, « Decouvrir Rewayah Academy » mene a /bienvenue, '
      'puis « Commencer » ramene a /connexion',
      (WidgetTester tester) async {
        final GoRouter routeur = await monterRouteur(
          tester,
          Routes.connexion,
          source: FausseSourceSession(),
        );

        final Finder decouvrir = find.text(t.connexion.decouvrir);
        await tester.ensureVisible(decouvrir);
        await tester.pumpAndSettle();
        await tester.tap(decouvrir);
        await tester.pumpAndSettle();

        expect(lieu(routeur), Routes.bienvenue);

        final Finder commencer = find.text(t.bienvenue.commencer);
        await tester.ensureVisible(commencer);
        await tester.pumpAndSettle();
        await tester.tap(commencer);
        await tester.pumpAndSettle();

        expect(lieu(routeur), Routes.connexion);
      },
    );

    testWidgets(
      'une URL de retour avec error_code=otp_expired mene a la recuperation '
      'avec le motif « expire »',
      (WidgetTester tester) async {
        final FauxServiceAuth auth = FauxServiceAuth();
        await tester.pumpWidget(
          hoteRoutant(
            depart: Routes.connexion,
            routes: <RouteBase>[
              GoRoute(
                path: Routes.connexion,
                builder: (BuildContext context, GoRouterState state) =>
                    ConnexionPage(
                      urlRetour: Uri.parse(
                        'https://app.test/connexion#error_code=otp_expired&error=access_denied',
                      ),
                    ),
              ),
              GoRoute(
                path: Routes.connexionRecuperation,
                builder: (BuildContext context, GoRouterState state) =>
                    RecuperationPage(
                      motif: motifDepuisUrlRetour(
                        Uri(queryParameters: state.uri.queryParameters),
                      ),
                    ),
              ),
            ],
            surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RecuperationPage), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('recuperation-motif')),
          findsOneWidget,
        );
        expect(
          find.text(t.connexion.recuperation.lienExpireTitre),
          findsOneWidget,
        );
      },
    );
  });

  group('LA-1 : « Renvoyer le lien »', () {
    Future<FauxServiceAuth> monter(WidgetTester tester) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await tester.pumpWidget(
        hote(
          const ConnexionPage(),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );
      await tester.enterText(find.byType(TextField), 'fatou@example.test');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
      return auth;
    }

    testWidgets('renvoye : un second lien part, le message change', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await monter(tester);

      await tester.tap(find.text(t.connexion.renvoyer));
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, <String>[
        'fatou@example.test',
        'fatou@example.test',
      ]);
      expect(
        find.text(t.connexion.renvoye(courriel: 'fatou@example.test')),
        findsOneWidget,
      );
    });

    testWidgets('trop tot : le serveur limite, la phrase le dit', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await monter(tester);
      auth.erreurAJeter = const AuthException(
        'over_email_send_rate_limit',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      );

      await tester.tap(find.text(t.connexion.renvoyer));
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.erreurTropTot), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('connexion-erreur-renvoi')),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : le reseau ne repond pas, la phrase le dit', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await monter(tester);
      auth.erreurAJeter = AuthRetryableFetchException(
        message: 'Failed host lookup',
      );

      await tester.tap(find.text(t.connexion.renvoyer));
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.horsLigne), findsOneWidget);
    });

    testWidgets('un second appui pendant l envoi ne double pas la demande', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await monter(tester);

      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byKey(const ValueKey<String>('connexion-renvoyer')),
      );
      bouton.onPress!();
      bouton.onPress!();
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, <String>[
        'fatou@example.test',
        'fatou@example.test',
      ]);
    });
  });

  group('LA-1 : recuperation d acces', () {
    testWidgets('motif expire : l encart et l envoi fonctionnent', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await tester.pumpWidget(
        hote(
          const RecuperationPage(motif: MotifRecuperation.expire),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );

      expect(
        find.text(t.connexion.recuperation.lienExpireTitre),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('recuperation-courriel')),
        'sayyid@example.test',
      );
      await tester.pumpAndSettle();
      final Finder envoyer = find.text(t.connexion.recuperation.envoyer);
      await tester.ensureVisible(envoyer);
      await tester.pumpAndSettle();
      await tester.tap(envoyer);
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, <String>['sayyid@example.test']);
      expect(find.text(t.connexion.recuperation.envoyeTitre), findsOneWidget);
    });

    testWidgets('motif refuse : l encart dit un refus, pas une expiration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const RecuperationPage(motif: MotifRecuperation.refuse),
          surcharges: <Override>[
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          ],
        ),
      );

      expect(
        find.text(t.connexion.recuperation.lienRefuseTitre),
        findsOneWidget,
      );
      expect(find.text(t.connexion.recuperation.lienExpireTitre), findsNothing);
    });

    testWidgets('sans motif : aucun encart, la saisie reste nue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const RecuperationPage(),
          surcharges: <Override>[
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('recuperation-motif')),
        findsNothing,
      );
    });

    testWidgets('une adresse incomplete n envoie rien et le dit', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await tester.pumpWidget(
        hote(
          const RecuperationPage(),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('recuperation-courriel')),
        'pas-une-adresse',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.recuperation.envoyer));
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, isEmpty);
      expect(find.text(t.connexion.erreurCourriel), findsOneWidget);
    });

    testWidgets('un echec d envoi se dit et n avance pas l ecran', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth()
        ..erreurAJeter = StateError('reseau');
      await tester.pumpWidget(
        hote(
          const RecuperationPage(),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('recuperation-courriel')),
        'fatou@example.test',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.recuperation.envoyer));
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.erreurEnvoi), findsOneWidget);
      expect(find.text(t.connexion.recuperation.envoyeTitre), findsNothing);
    });

    testWidgets(
      'le retour de la recuperation (PageShell) mene bien a la connexion',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hoteRoutant(
            depart: Routes.connexionRecuperation,
            routes: <RouteBase>[
              GoRoute(
                path: Routes.connexion,
                builder: (BuildContext context, GoRouterState state) =>
                    const ConnexionPage(),
              ),
              GoRoute(
                path: Routes.connexionRecuperation,
                builder: (BuildContext context, GoRouterState state) =>
                    const RecuperationPage(),
              ),
            ],
            surcharges: <Override>[
              serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DisqueRetour));
        await tester.pumpAndSettle();

        expect(find.byType(ConnexionPage), findsOneWidget);
      },
    );
  });

  group('LA-1 : unites', () {
    test('motifDepuisUrlRetour lit le fragment et la requete', () {
      expect(
        motifDepuisUrlRetour(
          Uri.parse('https://app.test/connexion#error_code=otp_expired'),
        ),
        MotifRecuperation.expire,
      );
      expect(
        motifDepuisUrlRetour(
          Uri.parse('https://app.test/connexion?error_code=otp_expired'),
        ),
        MotifRecuperation.expire,
      );
      expect(
        motifDepuisUrlRetour(
          Uri.parse('https://app.test/connexion#error=access_denied'),
        ),
        MotifRecuperation.refuse,
      );
      expect(
        motifDepuisUrlRetour(Uri.parse('https://app.test/connexion')),
        isNull,
      );
    });

    test('cheminRecuperation porte le motif dans la requete', () {
      expect(
        cheminRecuperation(MotifRecuperation.expire),
        '${Routes.connexionRecuperation}?motif=expire',
      );
      expect(cheminRecuperation(null), Routes.connexionRecuperation);
    });

    test('issueEchecEnvoi classe les erreurs', () {
      expect(
        issueEchecEnvoi(AuthRetryableFetchException(message: 'sans reseau')),
        IssueEnvoiLien.horsLigne,
      );
      expect(
        issueEchecEnvoi(
          const AuthException(
            'trop de demandes',
            statusCode: '429',
            code: 'over_email_send_rate_limit',
          ),
        ),
        IssueEnvoiLien.tropTot,
      );
      expect(
        issueEchecEnvoi(const AuthException('refus')),
        IssueEnvoiLien.erreur,
      );
      expect(
        issueEchecEnvoi(StateError('Failed host lookup')),
        IssueEnvoiLien.horsLigne,
      );
      expect(issueEchecEnvoi(StateError('autre')), IssueEnvoiLien.erreur);
    });
  });
}
