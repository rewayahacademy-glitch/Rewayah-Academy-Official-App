// FAC-F-01 : l'acces suspendu pour paiement (migration 20261018170000).
//
// Ce que ces tests tiennent :
// - l'enfant lit « Accès à cette classe temporairement indisponible. Ton
//   tuteur peut gérer l'accès. » et jamais une cause, un montant ni le mot
//   « paiement » ;
// - le tuteur lit le motif et dispose du bouton Payer, qui mene a la recharge
//   existante avec l'eleve deja coche ;
// - l'eleve adulte lit son propre motif et le meme bouton ;
// - l'adaptateur ne rend a l'enfant aucune place (le serveur ne la lui donne
//   pas) et la rend au tuteur ;
// - les trois notifications (relance, suspension, retablissement) ont un
//   libelle, un type et la destination Payer.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/acces_supabase.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/acces_finance/acces_finance.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

final DateTime _maintenant = DateTime.utc(2026, 11, 4, 12);

AccesBeneficiaire _suspendu() => AccesBeneficiaire(
  eleveId: 'e1',
  prenom: 'Yasmine',
  etatAffiche: EtatAccesAffiche.sansEcheance,
  seancesPayantesOuvertes: false,
  place: EtatPlace.suspenduPaiement,
  datePlace: DateTime(2026, 11, 4),
);

/// Un hote avec un vrai routeur : le bouton Payer mene a la recharge.
Widget _hote(Widget ecran, {Brightness luminosite = Brightness.light}) {
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: ecran),
      ),
      GoRoute(
        path: Routes.tuteurFoyerRecharge,
        builder: (_, GoRouterState etat) => Scaffold(
          body: Text('recharge:${etat.uri.queryParameters['profils']}'),
        ),
      ),
    ],
  );
  return TranslationProvider(
    child: MaterialApp.router(
      routerConfig: routeur,
      theme: AppTheme.pour(InterfaceMode.standard, luminosite),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  );
}

void main() {
  group('l enfant', () {
    test('la phrase du guide, mot pour mot, sans cause', () {
      expect(
        '${t.argent.acces.enfantTitre}. ${t.argent.acces.enfantMessage}',
        "Accès à cette classe temporairement indisponible. Ton tuteur peut gérer l'accès.",
      );
    });

    testWidgets('lit la copie neutre : ni argent, ni paiement, ni suspension', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const BandeauAccesEnfant()));
      await tester.pumpAndSettle();
      expect(find.text(t.argent.acces.enfantTitre), findsOneWidget);
      expect(find.text("Ton tuteur peut gérer l'accès."), findsOneWidget);
      final RegExp interdit = RegExp(
        r'pay|manque|usd|\$|€|solde|régularis|financ|suspen|\d',
        caseSensitive: false,
      );
      for (final Text texte in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          interdit.hasMatch(texte.data ?? ''),
          isFalse,
          reason: texte.data,
        );
      }
      // Aucun lien Payer pour l'enfant.
      expect(find.byKey(BandeauPlace.payerKey), findsNothing);
    });

    test(
      'l adaptateur ne lui rend ni cause ni date, seulement l ouverture',
      () {
        final AccesBeneficiaire a = accesBeneficiaireJson(<String, dynamic>{
          'eleveId': 'e1',
          'prenom': 'Yasmine',
          'finAcces': null,
          'seancesPayantesOuvertes': false,
          'place': null,
          'datePlace': null,
          'gereSonAcces': false,
        }, maintenantUtc: _maintenant);
        expect(a.seancesPayantesOuvertes, isFalse);
        expect(a.place, isNull);
        expect(a.datePlace, isNull);
        expect(a.gereSonAcces, isFalse);
        expect(ouvertureSeances(a), OuvertureSeances.fermees);
        expect(phrasePlace(a, prenom: 'Yasmine'), isNull);
        expect(BandeauPlace.pour(a, prenom: 'Yasmine'), isNull);
      },
    );
  });

  group('le tuteur', () {
    test('lit le motif, avec le prenom', () {
      expect(
        phrasePlace(_suspendu(), prenom: 'Yasmine'),
        "Le paiement du mois n'est pas reçu. Yasmine ne peut plus rejoindre "
        'ses séances. Son compte et ses contenus restent accessibles.',
      );
    });

    testWidgets('voit le bandeau, le motif et le bouton Payer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(BandeauPlace.pour(_suspendu(), prenom: 'Yasmine')!),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauPlace.suspenduKey), findsOneWidget);
      expect(find.text(t.argent.acces.suspenduTitre), findsOneWidget);
      expect(
        find.text(t.argent.acces.suspenduPaiementTuteur(prenom: 'Yasmine')),
        findsOneWidget,
      );
      expect(find.byKey(BandeauPlace.payerKey), findsOneWidget);
      expect(find.text(t.adulte.recharge.payerSeul), findsOneWidget);
    });

    testWidgets('Payer ouvre la recharge avec l eleve deja coche', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(BandeauPlace.pour(_suspendu(), prenom: 'Yasmine')!),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BandeauPlace.payerKey));
      await tester.pumpAndSettle();
      expect(find.text('recharge:e1'), findsOneWidget);
    });

    test('l adaptateur lui rend la cause et le jour', () {
      final AccesBeneficiaire a = accesBeneficiaireJson(<String, dynamic>{
        'eleveId': 'e1',
        'prenom': 'Yasmine',
        'finAcces': null,
        'seancesPayantesOuvertes': false,
        'place': 'suspendu_paiement',
        'datePlace': '2026-11-04',
        'gereSonAcces': false,
      }, maintenantUtc: _maintenant);
      expect(a.place, EtatPlace.suspenduPaiement);
      expect(a.datePlace, DateTime(2026, 11, 4));
      expect(a.place.ferme, isTrue);
    });

    test('un eleve a jour ne lit aucune fermeture', () {
      final AccesBeneficiaire a = accesBeneficiaireJson(<String, dynamic>{
        'eleveId': 'e2',
        'prenom': 'Bilal',
        'finAcces': '2027-01-01T00:00:00Z',
        'seancesPayantesOuvertes': null,
        'place': null,
        'datePlace': null,
        'gereSonAcces': false,
      }, maintenantUtc: _maintenant);
      expect(a.seancesPayantesOuvertes, isNull);
      expect(a.place.ferme, isFalse);
      expect(a.etatAffiche, EtatAccesAffiche.actif);
      expect(ouvertureSeances(a), OuvertureSeances.inconnue);
    });

    test('une forme inattendue est refusee, jamais completee', () {
      expect(
        () => accesBeneficiaireJson(<String, dynamic>{
          'eleveId': 'e1',
          'prenom': 'Yasmine',
          'place': 'inconnue',
        }, maintenantUtc: _maintenant),
        throwsFormatException,
      );
    });
  });

  group('l eleve adulte', () {
    test('lit son propre motif, a la deuxieme personne', () {
      expect(
        phrasePlace(_suspendu()),
        "Le paiement du mois n'est pas reçu. Vous ne pouvez plus rejoindre "
        'vos séances. Votre compte et vos contenus restent accessibles.',
      );
    });

    testWidgets('voit le meme bouton Payer', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(BandeauPlace.pour(_suspendu())!));
      await tester.pumpAndSettle();
      expect(find.text(t.argent.acces.suspenduPaiementAdulte), findsOneWidget);
      await tester.tap(find.byKey(BandeauPlace.payerKey));
      await tester.pumpAndSettle();
      expect(find.text('recharge:e1'), findsOneWidget);
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets(
        '320 px, texte 200 %, ${luminosite.name} : sans debordement',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: _hote(
                BandeauPlace.pour(_suspendu(), prenom: 'Yasmine')!,
                luminosite: luminosite,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(BandeauPlace.payerKey), findsOneWidget);
        },
      );
    }
  });

  group('les notifications', () {
    NotificationTuteur depuis(String evenement) =>
        notificationDepuis(<String, dynamic>{
          'id': 'n1',
          'evenement': evenement,
          'params': <String, dynamic>{'jours_avant': 7},
          'destination': '/tuteur/foyer/recharge',
          'cree_le': '2026-10-25T05:15:00Z',
          'lu_le': null,
        }, titrePour: contenuNotificationPour);

    test('la relance, la suspension et le retablissement', () {
      final NotificationTuteur relance = depuis('paiement_relance');
      expect(relance.titre, t.notifications.evenements.paiementRelance);
      expect(relance.type, TypeNotification.accesFinance);
      expect(relance.destination, '/tuteur/foyer/recharge');
      expect(
        depuis('acces_suspendu_paiement').titre,
        t.notifications.evenements.accesSuspenduPaiement,
      );
      expect(
        depuis('acces_retabli_paiement').titre,
        t.notifications.evenements.accesRetabliPaiement,
      );
    });

    test('aucun montant ni chiffre dans les libelles', () {
      for (final String texte in <String>[
        t.notifications.evenements.paiementRelance,
        t.notifications.evenements.accesSuspenduPaiement,
        t.notifications.evenements.accesRetabliPaiement,
      ]) {
        expect(RegExp(r'\d|\$|USD').hasMatch(texte), isFalse, reason: texte);
      }
    });
  });
}
