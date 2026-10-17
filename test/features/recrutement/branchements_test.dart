// RECRUT-ECRANS : les branchements des nouveaux ecrans dans les parcours
// existants, sans rien changer tant que les ports serveur sont absents.
//
// - `ContratPage` ouvre la signature serveur pour un enseignant des que le
//   port existe, et garde l'ancien parcours sans port ; un tuteur garde
//   toujours les conditions ;
// - le lien « J'ai un code d'invitation » de l'inscription mene au code d'invitation
//   quand le serveur verifie les invitations, et garde l'ancien parcours
//   sinon (ou si un code valide est deja retenu).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/resignature_contrat.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/recrutement/port_signature_contrat.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/recrutement_demo.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/recrutement/signature_contrat_page.dart';

import '../../support/harnais.dart';
import '../../support/monter_recrutement.dart';

Future<void> _monterContrat(
  WidgetTester tester, {
  required AppRole role,
  PortSignatureContrat? port,
}) => monterRecrutement(
  tester,
  chemin: Routes.attenteContrat,
  autres: <String>[Routes.attente],
  ecran: (_) => const ContratPage(),
  surcharges: <Override>[
    serviceDossierProvider.overrideWithValue(
      FauxServiceDossier()
        ..demonstration = true
        ..etatRendu = EtatDossier(
          profilExiste: true,
          role: role,
          statutCompte: AccountStatus.pendingKyc,
          accuseSigne: true,
        ),
    ),
    portSignatureContratProvider.overrideWithValue(port),
    // La re-signature lit la session : elle a son propre test.
    resignatureContratEnseignantProvider.overrideWithValue(false),
  ],
);

Future<void> _monterUsage(
  WidgetTester tester, {
  PortVerificationInvitation? verification,
  String? codeRetenu,
}) => monterRecrutement(
  tester,
  chemin: Routes.inscriptionUsage,
  autres: <String>[Routes.inscriptionIdentite, Routes.inscriptionInvitation],
  ecran: (_) => const UsageEtape(),
  surcharges: <Override>[
    sansPersonneConnectee(),
    serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
    portVerificationInvitationProvider.overrideWithValue(verification),
    if (codeRetenu != null)
      codeInvitationRetenuProvider.overrideWith(
        () => _CodeDejaRetenu(codeRetenu),
      ),
  ],
);

class _CodeDejaRetenu extends CodeInvitationRetenu {
  _CodeDejaRetenu(this._code);
  final String _code;
  @override
  String? build() => _code;
}

void main() {
  group('ContratPage', () {
    testWidgets('enseignant avec le port : la signature serveur', (
      tester,
    ) async {
      await _monterContrat(
        tester,
        role: AppRole.teacher,
        port: SignatureContratDemo(),
      );
      expect(find.byType(SignatureContratPage), findsOneWidget);
    });

    testWidgets('enseignant sans port : l\'ancien parcours', (tester) async {
      await _monterContrat(tester, role: AppRole.teacher);
      expect(find.byType(SignatureContratPage), findsNothing);
      expect(find.text(t.contrat.accepter), findsOneWidget);
    });

    testWidgets('tuteur : les conditions, port ou non', (tester) async {
      await _monterContrat(
        tester,
        role: AppRole.guardian,
        port: SignatureContratDemo(),
      );
      expect(find.byType(SignatureContratPage), findsNothing);
      expect(find.text(t.contrat.accepter), findsOneWidget);
    });
  });

  group('inscription enseignant', () {
    Future<void> toucherLienEnseignant(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('inscription-lien-enseignant')));
      await laisser(tester);
    }

    testWidgets(
      'serveur branche, aucun code : le code d\'invitation d\'abord',
      (tester) async {
        await _monterUsage(tester, verification: InvitationsDemo());
        await toucherLienEnseignant(tester);
        expect(
          find.text('temoin:${Routes.inscriptionInvitation}'),
          findsOneWidget,
        );
      },
    );

    testWidgets('serveur branche, code deja retenu : on poursuit', (
      tester,
    ) async {
      await _monterUsage(
        tester,
        verification: InvitationsDemo(),
        codeRetenu: 'DEMO-VALIDE',
      );
      await toucherLienEnseignant(tester);
      expect(find.text('temoin:${Routes.inscriptionIdentite}'), findsOneWidget);
    });

    testWidgets('sans serveur : le champ du code, jamais l\'ancien parcours', (
      tester,
    ) async {
      await _monterUsage(tester);
      await toucherLienEnseignant(tester);
      expect(
        find.text('temoin:${Routes.inscriptionInvitation}'),
        findsOneWidget,
      );
    });
  });
}
