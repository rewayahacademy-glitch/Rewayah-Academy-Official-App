// AD-8 (HL-A-4) : les decisions ADM-02D / ADM-02E depuis la VRAIE coque admin
// et le vrai routeur, en demonstration (`?demo=admin`). Chaque geste part
// d'un bouton reel (K-07) : Personnes dans la coque, la ligne du dossier,
// puis « Refuser le dossier » / « Valider le dossier ». Reprend les tests
// AD-8 qui montaient la page seule, et prouve le glisser contre `PopScope`
// et le clavier ouvert a 390 (Q-AD8-5).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
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

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  required EtatRevueDemo etat,
  PortRevueDossiers? port,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final List<Override> demo = surchargesDemoAdmin(
    environnement: 'staging',
    etat: etat,
  );
  if (port != null) {
    demo[1] = portRevueDossiersProvider.overrideWithValue(port);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: demo,
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(Routes.admin);
  await _stabiliser(tester);
}

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

/// Personnes depuis la coque (tiroir sur mobile, barre laterale sur bureau),
/// puis la ligne du dossier.
Future<void> _ouvrir(WidgetTester tester, String prenom) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  await tester.tap(
    find.descendant(
      of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
}

/// Rend visible puis tape le PREMIER libelle (le bouton de la revue).
Future<void> _toucher(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle).first);
  await _stabiliser(tester);
  await tester.tap(find.text(libelle).first);
  await _stabiliser(tester);
}

/// Le champ de motif de 02D, par son etiquette.
Finder get _champMotif => find
    .descendant(
      of: find.ancestor(
        of: find.text(t.dossiers.refus.champ),
        matching: find.byType(ZoneSaisie),
      ),
      matching: find.byType(TextField),
    )
    .first;

/// FORM-L1 : le motif libre s'ecrit apres « Autre », derniere puce.
Future<void> _ouvrirAutre(WidgetTester tester) async {
  if (find.byKey(SelecteurMotif.cleAutre).evaluate().isEmpty) return;
  if (find.text(t.dossiers.refus.champ).evaluate().isNotEmpty) return;
  await tester.ensureVisible(find.byKey(SelecteurMotif.cleAutre));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(SelecteurMotif.cleAutre));
  await tester.pumpAndSettle();
}

const Size _mobile = Size(390, 844);
const Size _bureau = Size(1440, 900);

void main() {
  testWidgets('390 : un refus passe par 02D, jamais sans motif', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, _mobile, etat: etat);
    await _ouvrir(tester, 'Omar');
    await _toucher(tester, t.dossiers.refuser);
    expect(find.text(t.dossiers.refus.corps), findsOneWidget);
    expect(find.text(t.dossiers.refus.aide), findsOneWidget);

    await tester.tap(find.text(t.dossiers.refuser).last);
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.erreurVide), findsOneWidget);
    await _ouvrirAutre(tester);
    await tester.enterText(_champMotif, '   ');
    await tester.tap(find.text(t.dossiers.refuser).last);
    await _stabiliser(tester);
    // « Autre » vide : le selecteur precise que c'est le champ qui manque.
    expect(find.text(t.formulaire.motif.autreVide), findsOneWidget);
    expect(etat.nombreDecisions, 0);

    await _ouvrirAutre(tester);
    await tester.enterText(_champMotif, 'Photo illisible.');
    await _stabiliser(tester);
    await tester.tap(find.text(t.dossiers.refuser).last);
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(etat.nombreDecisions, 1);
    expect(find.text(t.dossiers.refus.succes), findsOneWidget);
    expect(find.text(t.dossiers.refus.corps), findsNothing);
  });

  testWidgets('390 : un motif saisi n est pas perdu (Annuler, Echap)', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, _mobile, etat: etat);
    await _ouvrir(tester, 'Omar');
    await _toucher(tester, t.dossiers.refuser);
    await _ouvrirAutre(tester);
    await tester.enterText(_champMotif, 'Photo floue.');
    await _stabiliser(tester);
    await tester.tap(find.text(t.commun.annuler));
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.abandonQuestion), findsOneWidget);
    await tester.tap(find.text(t.dossiers.refus.continuerSaisie));
    await _stabiliser(tester);
    expect(find.text('Photo floue.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.abandonQuestion), findsOneWidget);
    await tester.tap(find.text(t.dossiers.refus.abandonner));
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.corps), findsNothing);
    expect(etat.nombreDecisions, 0);
  });

  testWidgets('390 : glisser 02D vers le bas avec un motif pose la question '
      'd abandon (PopScope), sans rien envoyer', (WidgetTester tester) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, _mobile, etat: etat);
    await _ouvrir(tester, 'Omar');
    await _toucher(tester, t.dossiers.refuser);
    await _ouvrirAutre(tester);
    await tester.enterText(_champMotif, 'Photo floue.');
    await _stabiliser(tester);

    // FORM-L1 : les puces de motifs allongent la feuille ; le glissement
    // doit depasser la moitie de sa hauteur pour demander la fermeture.
    await tester.drag(
      find.text(t.dossiers.refus.titre).last,
      const Offset(0, 700),
    );
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.abandonQuestion), findsOneWidget);
    // La feuille est toujours la, motif intact.
    expect(find.text(t.dossiers.refus.corps), findsOneWidget);
    expect(find.text('Photo floue.'), findsOneWidget);

    await tester.tap(find.text(t.dossiers.refus.continuerSaisie));
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.abandonQuestion), findsNothing);
    expect(find.text('Photo floue.'), findsOneWidget);

    // Un fling rapide pose la meme question ; « Abandonner » ferme.
    await tester.fling(
      find.text(t.dossiers.refus.titre).last,
      const Offset(0, 300),
      2000,
    );
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.abandonQuestion), findsOneWidget);
    await tester.tap(find.text(t.dossiers.refus.abandonner));
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.corps), findsNothing);
    expect(etat.nombreDecisions, 0);
  });

  testWidgets('390 : glisser 02D vide la ferme, sans question', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, _mobile, etat: etat);
    await _ouvrir(tester, 'Omar');
    await _toucher(tester, t.dossiers.refuser);
    await tester.drag(
      find.text(t.dossiers.refus.titre).last,
      const Offset(0, 500),
    );
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.abandonQuestion), findsNothing);
    expect(find.text(t.dossiers.refus.corps), findsNothing);
  });

  testWidgets('390, clavier ouvert : ni le champ ni les actions sous le '
      'clavier, et Refuser se tape', (WidgetTester tester) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, _mobile, etat: etat);
    await _ouvrir(tester, 'Omar');
    await _toucher(tester, t.dossiers.refuser);
    const double clavier = 336;
    tester.view.viewInsets = const FakeViewPadding(bottom: clavier);
    await _stabiliser(tester);
    await _ouvrirAutre(tester);
    await tester.enterText(_champMotif, 'Photo illisible.');
    await _stabiliser(tester);

    const double limite = 844 - clavier;
    final Rect champ = tester.getRect(_champMotif);
    expect(champ.top, greaterThanOrEqualTo(0));
    expect(champ.bottom, lessThanOrEqualTo(limite));
    for (final String l in <String>[t.commun.annuler, t.dossiers.refuser]) {
      final Rect r = tester.getRect(
        find
            .ancestor(
              of: find.text(l).last,
              matching: find.byType(ActionPrincipale),
            )
            .first,
      );
      expect(r.bottom, lessThanOrEqualTo(limite), reason: l);
      expect(r.top, greaterThanOrEqualTo(0), reason: l);
    }

    await tester.tap(find.text(t.dossiers.refuser).last);
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(etat.nombreDecisions, 1);
    expect(find.text(t.dossiers.refus.succes), findsOneWidget);
  });

  testWidgets('1440 : Entree n envoie pas ; double tap = un seul envoi', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    final _PortRetenu port = _PortRetenu(RevueDossiersDemo(etat));
    await _monter(tester, _bureau, etat: etat, port: port);
    await _ouvrir(tester, 'Omar');
    await _toucher(tester, t.dossiers.refuser);
    await _ouvrirAutre(tester);
    await tester.enterText(_champMotif, 'Motif fictif.');
    await _stabiliser(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _stabiliser(tester);
    expect(port.appels, 0);
    expect(find.text(t.dossiers.refus.champ), findsOneWidget);
    final Finder confirmer = find.text(t.dossiers.refuser).last;
    await tester.tap(confirmer);
    await tester.tap(confirmer);
    await tester.pump();
    expect(port.appels, 1);
    port.porte.complete();
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(port.appels, 1);
    expect(etat.nombreDecisions, 1);
    expect(find.text(t.dossiers.refus.succes), findsOneWidget);
  });

  testWidgets('1440 : refus a reponse perdue (07), une seule decision', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, _bureau, etat: etat);
    await _ouvrir(tester, 'Inès');
    await _toucher(tester, t.dossiers.refuser);
    await _ouvrirAutre(tester);
    await tester.enterText(_champMotif, 'Motif fictif.');
    await _stabiliser(tester);
    await tester.tap(find.text(t.dossiers.refuser).last);
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    expect(etat.nombreDecisions, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(etat.nombreDecisions, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _stabiliser(tester);
    expect(find.text(t.dossiers.refus.corps), findsNothing);
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    // HL-A-5 : resultat inconnu, l'emplacement dit l'etat ; aucun bouton
    // grise au-dessus.
    for (final String l in <String>[t.dossiers.refuser, t.dossiers.approuver]) {
      expect(find.text(l), findsNothing, reason: l);
    }

    await _toucher(tester, t.dossiers.decision.verifierResultat);
    expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
    await _toucher(tester, t.dossiers.decision.verifierResultat);
    expect(find.text(t.dossiers.refus.succes), findsOneWidget);
    expect(etat.nombreDecisions, 1);
  });
  testWidgets(
    '1440 : la validation passe par 02E, rien avant la confirmation',
    (WidgetTester tester) async {
      final EtatRevueDemo etat = EtatRevueDemo.initial();
      await _monter(tester, _bureau, etat: etat);
      await _ouvrir(tester, 'Omar');
      for (final String point in <String>[
        t.dossiers.pointLisible,
        t.dossiers.pointNom,
        t.dossiers.pointValidite,
      ]) {
        await _toucher(tester, point);
      }
      await _toucher(tester, t.dossiers.approuver);
      expect(find.text(t.dossiers.validation.titre), findsOneWidget);
      expect(etat.nombreDecisions, 0);
      await tester.tap(find.text(t.dossiers.approuver).last);
      await _stabiliser(tester);
      await _stabiliser(tester);
      expect(find.text(t.dossiers.validation.succes), findsOneWidget);
      expect(etat.nombreDecisions, 1);
      expect(
        etat.dossiers[DonneesDossiersDemo.enseignantNominal]!.statut,
        StatutRevue.valide,
      );
    },
  );
}
