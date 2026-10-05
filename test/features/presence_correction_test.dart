import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/presence/vue_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/features/presence_correction/presence_correction.dart';
import 'package:rewayah_academy/features/presence_correction/presence_correction_page.dart';

import '../support/harnais.dart';

const PresenceCorrectionLibelles _libelles = PresenceCorrectionLibelles(
  titre: 'Presence',
  corriger: 'Correction manuelle',
  excuser: 'Absence excusee',
  confirmation: 'Confirmer la decision',
  motif: 'Motif',
  motifRequis: 'Le motif est obligatoire.',
  confirmer: 'Confirmer',
  annuler: 'Annuler',
  mutationEnCours: 'Enregistrement en cours',
  succes: 'Decision enregistree',
  erreur: 'La decision n a pas abouti.',
  horsLigne: 'Impossible de corriger sans reseau.',
  journalisation: 'Cette decision sera journalisee.',
);

final PresenceParticipant _participant = PresenceParticipant(
  seanceId: 'session-1',
  profilId: 'profile-1',
  role: 'student',
  prenom: 'Aicha',
  identifiantImmuable: 'STUD-000001',
  etat: EtatPresence.confirmationEnAttente,
  consolide: false,
  debutSeance: DateTime(2026, 9, 14, 10),
);

VuePresence _vue() => VuePresence.depuis(
  ligne: _participant,
  maintenant: DateTime(2026, 9, 14, 10, 45),
);

class _AdaptateurFaux implements PresenceCorrectionAdaptateur {
  final List<PresenceCorrectionCommande> commandes =
      <PresenceCorrectionCommande>[];
  Completer<void>? attente;
  Object? erreur;

  @override
  Future<void> appliquer(PresenceCorrectionCommande commande) async {
    commandes.add(commande);
    final Object? erreurLocale = erreur;
    if (erreurLocale != null) {
      // ignore: only_throw_errors
      throw erreurLocale;
    }
    final Completer<void>? attenteLocale = attente;
    if (attenteLocale != null) {
      await attenteLocale.future;
    }
  }
}

Widget _monter(
  _AdaptateurFaux adaptateur, {
  PresenceCorrectionCapacites capacites = const PresenceCorrectionCapacites(
    peutCorriger: true,
    peutExcuser: true,
  ),
  List<Override> surcharges = const <Override>[],
  PresenceCorrectionLibelles libelles = _libelles,
}) => hote(
  PresenceCorrectionPage(
    cible: PresenceCorrectionCible(ligne: _participant, vue: _vue()),
    capacites: capacites,
    adaptateur: adaptateur,
    libelles: libelles,
  ),
  surcharges: surcharges,
);

void main() {
  testWidgets('masque toute action quand la capacite serveur manque', (
    WidgetTester tester,
  ) async {
    final _AdaptateurFaux adaptateur = _AdaptateurFaux();

    await tester.pumpWidget(
      _monter(adaptateur, capacites: const PresenceCorrectionCapacites()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aicha'), findsOneWidget);
    expect(find.text(_libelles.corriger), findsNothing);
    expect(find.text(_libelles.excuser), findsNothing);
  });

  testWidgets('exige un motif avant de permettre la confirmation', (
    WidgetTester tester,
  ) async {
    final _AdaptateurFaux adaptateur = _AdaptateurFaux();

    await tester.pumpWidget(_monter(adaptateur));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_libelles.corriger));
    await tester.pumpAndSettle();

    expect(find.text(_libelles.motifRequis), findsOneWidget);
    final Finder confirmer = find.widgetWithText(
      ActionPrincipale,
      _libelles.confirmer,
    );
    // Jamais grise (K-56) : presse sans motif, il dit ce qui manque.
    expect(tester.widget<ActionPrincipale>(confirmer).onPress, isNotNull);

    await tester.tap(confirmer);
    await tester.pumpAndSettle();
    // Le message d'erreur remplace l'aide sous le champ.
    expect(find.text(_libelles.motifRequis), findsOneWidget);
    expect(adaptateur.commandes, isEmpty);
  });

  testWidgets('FORM-L1 : le motif propose part tel quel, « Autre » exige un '
      'texte', (WidgetTester tester) async {
    final _AdaptateurFaux adaptateur = _AdaptateurFaux();
    const PresenceCorrectionLibelles avecMotifs = PresenceCorrectionLibelles(
      titre: 'Presence',
      corriger: 'Correction manuelle',
      excuser: 'Absence excusee',
      confirmation: 'Confirmer la decision',
      motif: 'Motif',
      motifRequis: 'Le motif est obligatoire.',
      confirmer: 'Confirmer',
      annuler: 'Annuler',
      mutationEnCours: 'Enregistrement en cours',
      succes: 'Decision enregistree',
      erreur: 'La decision n a pas abouti.',
      horsLigne: 'Impossible de corriger sans reseau.',
      motifsCorrection: <String>['Coupure reseau', 'Arrivee en retard'],
      motifsExcuse: <String>['Absence prevenue'],
      motifManquant: 'Il manque le motif.',
    );

    await tester.pumpWidget(_monter(adaptateur, libelles: avecMotifs));
    await tester.pumpAndSettle();
    await tester.tap(find.text(avecMotifs.corriger));
    await tester.pumpAndSettle();
    expect(find.text('Absence prevenue'), findsNothing);
    final Finder confirmer = find.widgetWithText(
      ActionPrincipale,
      avecMotifs.confirmer,
    );

    await tester.tap(find.byKey(SelecteurMotif.cleAutre));
    await tester.pumpAndSettle();
    await tester.tap(confirmer);
    await tester.pumpAndSettle();
    expect(find.text(t.formulaire.motif.autreVide), findsOneWidget);
    expect(adaptateur.commandes, isEmpty);

    await tester.tap(find.text('Arrivee en retard'));
    await tester.pumpAndSettle();
    await tester.tap(confirmer);
    await tester.pumpAndSettle();
    expect(adaptateur.commandes.single.motif, 'Arrivee en retard');
  });

  testWidgets('la correction reste activable au clavier', (
    WidgetTester tester,
  ) async {
    final _AdaptateurFaux adaptateur = _AdaptateurFaux()
      ..attente = Completer<void>();

    await tester.pumpWidget(_monter(adaptateur));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text(_libelles.confirmation), findsOneWidget);
  });

  testWidgets('n affiche aucun succes optimiste pendant la mutation', (
    WidgetTester tester,
  ) async {
    final _AdaptateurFaux adaptateur = _AdaptateurFaux()
      ..attente = Completer<void>();

    await tester.pumpWidget(_monter(adaptateur));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_libelles.corriger));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Arrivee confirmee');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ActionPrincipale, _libelles.confirmer),
    );
    await tester.pump();

    expect(find.text(_libelles.mutationEnCours), findsOneWidget);
    expect(find.text(_libelles.succes), findsNothing);
    expect(find.text(t.presence.confirmationEnAttente), findsOneWidget);
    expect(adaptateur.commandes.single.etat, EtatPresence.corrigeeManuel);
    expect(adaptateur.commandes.single.motif, 'Arrivee confirmee');

    adaptateur.attente!.complete();
    await tester.pumpAndSettle();
    expect(find.text(_libelles.succes), findsOneWidget);
  });

  testWidgets('conserve une erreur serveur et laisse la decision rejouable', (
    WidgetTester tester,
  ) async {
    final _AdaptateurFaux adaptateur = _AdaptateurFaux()
      ..erreur = StateError('concurrence');

    await tester.pumpWidget(_monter(adaptateur));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_libelles.excuser));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Justificatif recu');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ActionPrincipale, _libelles.confirmer),
    );
    await tester.pumpAndSettle();

    expect(find.text(_libelles.erreur), findsOneWidget);
    expect(find.text(_libelles.succes), findsNothing);
    expect(find.text(_libelles.excuser), findsOneWidget);
  });

  testWidgets('retire les actions hors ligne et explique la limite', (
    WidgetTester tester,
  ) async {
    final _AdaptateurFaux adaptateur = _AdaptateurFaux();

    await tester.pumpWidget(
      _monter(
        adaptateur,
        surcharges: <Override>[
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_libelles.horsLigne), findsOneWidget);
    expect(find.text(_libelles.corriger), findsNothing);
    expect(find.text(_libelles.excuser), findsNothing);
    expect(adaptateur.commandes, isEmpty);
  });
}
