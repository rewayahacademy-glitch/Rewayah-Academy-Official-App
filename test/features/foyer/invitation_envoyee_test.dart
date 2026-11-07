// INVITATION-SECOND-ADULTE (07/11/2026) : le titulaire voit son invitation en
// attente, son echeance, et la renvoie (meme invitation, meme adresse,
// nouveau code ; trois fois au plus ; echeance inchangee).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/invitation_envoyee.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';

class _Port implements PortInvitationEnvoyee {
  _Port(this.reponses);

  final List<ResultatRenvoi> reponses;
  final List<String> cles = <String>[];

  @override
  Future<InvitationEnAttente?> lire() async => null;

  @override
  Future<ResultatRenvoi> renvoyer(String cle) async {
    cles.add(cle);
    return reponses.removeAt(0);
  }
}

final InvitationEnAttente _attente = InvitationEnAttente(
  courriel: 'ami@example.test',
  expireLe: DateTime.utc(2026, 11, 14, 10),
  renvoisRestants: 3,
);

Widget _page(_Port port, {InvitationEnAttente? attente}) => ProviderScope(
  overrides: <Override>[
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    portInvitationEnvoyeeProvider.overrideWithValue(port),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: InvitationEnvoyeePage(
        invitation: const InvitationEnvoyee(courriel: 'ami@example.test'),
        attente: attente,
        onRetour: () {},
        onAnnulee: () {},
      ),
    ),
  ),
);

Future<void> _renvoyer(WidgetTester tester) async {
  final Finder bouton = find.byKey(InvitationEnvoyeePage.renvoyerKey);
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  group('lecture du serveur', () {
    test('mon_invitation_envoyee : en attente, ou rien', () {
      final InvitationEnAttente? a = invitationEnAttenteDepuis(<String, Object>{
        'etat': 'en_attente',
        'courriel': 'ami@example.test',
        'expire_le': '2026-11-14T10:00:00Z',
        'renvois_restants': 2,
      });
      expect(a?.courriel, 'ami@example.test');
      expect(a?.renvoisRestants, 2);
      expect(
        invitationEnAttenteDepuis(<String, Object>{'etat': 'aucune'}),
        isNull,
      );
      expect(invitationEnAttenteDepuis(null), isNull);
    });

    test('renvoyer_invitation_conjoint : chaque etat', () {
      expect(
        resultatRenvoiDepuis(<String, Object>{
          'etat': 'renvoyee',
          'renvois_restants': 1,
        }),
        isA<RenvoiFait>().having(
          (RenvoiFait r) => r.renvoisRestants,
          'restants',
          1,
        ),
      );
      expect(
        resultatRenvoiDepuis(<String, Object>{'etat': 'limite'}),
        isA<RenvoiLimite>(),
      );
      expect(
        resultatRenvoiDepuis(<String, Object>{'etat': 'perimee'}),
        isA<RenvoiPerimee>(),
      );
      expect(
        resultatRenvoiDepuis(<String, Object>{'etat': 'aucune'}),
        isA<RenvoiPerimee>(),
      );
      expect(resultatRenvoiDepuis('x'), isA<RenvoiEchecReseau>());
    });
  });

  group('la page de l invitation envoyee', () {
    testWidgets('echeance, renvois restants, « Renvoyer l invitation »', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(<ResultatRenvoi>[const RenvoiFait(2)]);
      await tester.pumpWidget(_page(port, attente: _attente));
      await tester.pumpAndSettle();
      expect(
        find.text(
          t.adulte.invitation.valableJusquau(
            date: dateEcheance(_attente.expireLe),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.adulte.invitation.renvoisRestants(n: 3)),
        findsOneWidget,
      );
      // Seconde lecture (07/11) : si la creation du compte echoue, renvoyer.
      expect(find.text(t.adulte.invitation.renvoyerSiEchec), findsOneWidget);
      await _renvoyer(tester);
      expect(port.cles, hasLength(1));
      expect(
        find.text(
          t.adulte.invitation.renvoyeePhrase(courriel: 'ami@example.test'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('une coupure garde la cle : aucun second e-mail', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(<ResultatRenvoi>[
        const RenvoiEchecReseau(),
        const RenvoiFait(2),
      ]);
      await tester.pumpWidget(_page(port, attente: _attente));
      await tester.pumpAndSettle();
      await _renvoyer(tester);
      expect(find.text(t.adulte.invitation.renvoiEchecTitre), findsOneWidget);
      expect(find.byType(EtatSysteme), findsOneWidget);
      await _renvoyer(tester);
      expect(port.cles, hasLength(2));
      expect(port.cles[0], port.cles[1]);
    });

    testWidgets(
      'limite atteinte : la phrase le dit, le bouton n est plus rendu',
      (WidgetTester tester) async {
        final _Port port = _Port(<ResultatRenvoi>[const RenvoiLimite()]);
        await tester.pumpWidget(_page(port, attente: _attente));
        await tester.pumpAndSettle();
        await _renvoyer(tester);
        expect(find.text(t.adulte.invitation.renvoiLimite), findsOneWidget);
        expect(find.byKey(InvitationEnvoyeePage.renvoyerKey), findsNothing);
      },
    );

    testWidgets('plus aucun renvoi : pas de bouton, jamais grise', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _page(
          _Port(<ResultatRenvoi>[]),
          attente: InvitationEnAttente(
            courriel: 'ami@example.test',
            expireLe: DateTime.utc(2026, 11, 14),
            renvoisRestants: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(InvitationEnvoyeePage.renvoyerKey), findsNothing);
      expect(find.byKey(InvitationEnvoyeePage.annulerKey), findsOneWidget);
    });

    testWidgets('demonstration (sans lecture du serveur) : pas de renvoi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_page(_Port(<ResultatRenvoi>[])));
      await tester.pumpAndSettle();
      expect(find.byKey(InvitationEnvoyeePage.renvoyerKey), findsNothing);
    });
  });
}
