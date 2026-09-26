import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../support/dossiers_production.dart';
import '../support/harnais.dart';

/// Fait defiler jusqu'a un libelle puis tape dessus, comme l'administrateur.
Future<void> _taper(WidgetTester tester, String libelle) async {
  final Finder cible = find.text(libelle);
  await tester.scrollUntilVisible(
    cible,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Retient `decider` et compte les appels ; le reste va a la demonstration.
class _PortRetenu implements PortRevueDossiers {
  _PortRetenu(this._base);

  final PortRevueDossiers _base;
  final Completer<void> porte = Completer<void>();
  int appels = 0;

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) => _base.listerDossiers(curseur: curseur, limite: limite, role: role);

  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) =>
      _base.dossierPourRevue(dossierId);

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) => _base.demanderVuePiece(dossierId: dossierId, documentId: documentId);

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) async {
    appels++;
    await porte.future;
    return _base.decider(
      dossierId: dossierId,
      revisionAttendue: revisionAttendue,
      decision: decision,
      commandeId: commandeId,
      verificationsFaites: verificationsFaites,
      motif: motif,
    );
  }

  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) => _base.resultatDecision(dossierId: dossierId, commandeId: commandeId);
}

/// Rend visible puis tape (la revue ouverte directement n'a pas de liste).
Future<void> _toucher(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ADM-02 sous la demonstration admin, sans serveur', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await tester.pumpWidget(
      hote(
        const DossiersPage(),
        surcharges: surchargesDemoAdmin(environnement: 'staging', etat: etat),
      ),
    );
    await tester.pumpAndSettle();
    // AD-5 : la page montre la file ; taper la premiere ligne ouvre la revue.
    await ouvrirPremierDossier(tester);

    // Le plus ancien dossier synthetique d'abord, piece jamais montree.
    // AD-6 : titre de la revue, piece jamais montree, raison dite.
    expect(find.text("Dossier d'Omar Haddad"), findsOneWidget);
    // AD-7 : la piece s'ouvre par « Voir la piece », jamais en ligne.
    expect(find.text(t.dossiers.revue.pieceIndisponible), findsNothing);
    expect(find.text(t.dossiers.revue.voirPiece), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    for (final String point in <String>[
      t.dossiers.pointLisible,
      t.dossiers.pointNom,
      t.dossiers.pointValidite,
    ]) {
      await _taper(tester, point);
    }
    await _taper(tester, t.dossiers.approuver);
    // AD-8 : 02E s'ouvre ; rien n'est decide avant la confirmation.
    expect(find.text(t.dossiers.validation.titre), findsOneWidget);
    expect(etat.nombreDecisions, 0);
    await tester.tap(find.text(t.dossiers.approuver).last);
    await tester.pumpAndSettle();
    expect(find.text(t.dossiers.validation.succes), findsOneWidget);
    expect(etat.nombreDecisions, 1);

    expect(
      etat.dossiers[DonneesDossiersDemo.enseignantNominal]!.statut,
      StatutRevue.valide,
    );
    expect(find.text('Omar Haddad'), findsNothing);
    expect(find.text('Amina Benali'), findsOneWidget);
  });

  testWidgets('AD-8 : Entree n envoie pas ; double tap = un seul envoi', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    final _PortRetenu port = _PortRetenu(RevueDossiersDemo(etat));
    final List<Override> s = surchargesDemoAdmin(
      environnement: 'staging',
      etat: etat,
    );
    s[1] = portRevueDossiersProvider.overrideWithValue(port);
    await tester.pumpWidget(hote(const DossiersPage(), surcharges: s));
    await tester.pumpAndSettle();
    await ouvrirPremierDossier(tester);

    await _toucher(tester, t.dossiers.refuser);
    await tester.enterText(find.byType(TextField), 'Motif fictif.');
    await tester.pumpAndSettle();
    // Entree dans le champ multiligne : aucune decision, 02D reste ouverte.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(port.appels, 0);
    expect(find.text(t.dossiers.refus.champ), findsOneWidget);
    // Deux taps dans le meme frame, avant toute reconstruction.
    final Finder confirmer = find.text(t.dossiers.refuser).last;
    await tester.tap(confirmer);
    await tester.tap(confirmer);
    await tester.pump();
    expect(port.appels, 1);
    port.porte.complete();
    await tester.pumpAndSettle();
    expect(port.appels, 1);
    expect(etat.nombreDecisions, 1);
    expect(find.text(t.dossiers.refus.succes), findsOneWidget);
  });

  testWidgets('AD-8 : refus a reponse perdue (07), une seule decision', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await tester.pumpWidget(
      hote(
        const DossiersPage(),
        surcharges: surchargesDemoAdmin(environnement: 'staging', etat: etat),
      ),
    );
    await tester.pumpAndSettle();
    final Finder ligne = find.bySemanticsLabel(
      RegExp('Ouvrir le dossier d.In'),
    );
    await tester.ensureVisible(ligne.first);
    await tester.pumpAndSettle();
    await tester.tap(ligne.first);
    await tester.pumpAndSettle();

    await _toucher(tester, t.dossiers.refuser);
    await tester.enterText(find.byType(TextField), 'Motif fictif.');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.dossiers.refuser).last);
    await tester.pumpAndSettle();

    // Reponse perdue : jamais un echec certain, aucune relance seule.
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    expect(etat.nombreDecisions, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(etat.nombreDecisions, 1);

    // Surface fermee : le statut reste sous les actions, les deux
    // decisions fermees (P-ADM-10.6).
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(t.dossiers.refus.corps), findsNothing);
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    for (final String l in <String>[t.dossiers.refuser, t.dossiers.approuver]) {
      final ActionPrincipale a = tester.widget<ActionPrincipale>(
        find
            .ancestor(of: find.text(l), matching: find.byType(ActionPrincipale))
            .first,
      );
      expect(a.onPress, isNull, reason: l);
    }

    // Premiere relecture : encore en attente ; seconde : reussie, une fois.
    await _toucher(tester, t.dossiers.decision.verifierResultat);
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    await _toucher(tester, t.dossiers.decision.verifierResultat);
    expect(find.text(t.dossiers.refus.succes), findsOneWidget);
    expect(etat.nombreDecisions, 1);
  });
}
