// Le support des tests COM-STU-3 (Mode focus) : un canal long (pour que la
// position de lecture compte), les reperes du Focus et de ce qu'il masque.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_studio/focus/bascule_focus.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';

import 'support_studio.dart';

/// Un canal de [nombre] messages longs, pour que le fil defile.
Canal canalLong({
  String id = 'c1',
  String nom = 'Coordination',
  int nombre = 30,
  bool ecrire = true,
}) {
  final Canal base = canalSimple(id: id, nom: nom, ecrire: ecrire);
  const Participant autre = Participant(
    id: 'autre',
    nomAffiche: 'Mariam',
    fonction: 'Coordination',
  );
  return Canal(
    resume: base.resume,
    membres: base.membres,
    capacites: base.capacites,
    messages: <MessageCommunication>[
      for (int i = 0; i < nombre; i++)
        MessageCommunication(
          id: '$id-long-$i',
          auteur: autre,
          texte:
              'Message $i : le planning du trimestre est en ligne, merci de '
              'relire les creneaux du mercredi et de signaler tout conflit '
              'avant vendredi.',
          envoyeLe: maintenantTest.subtract(Duration(minutes: 5 * (40 - i))),
        ),
    ],
  );
}

/// Le port des tests du Focus : un canal long et un second canal.
FauxStudio portFocus({bool ecrire = true}) => FauxStudio(
  canaux: <Canal>[
    canalLong(ecrire: ecrire),
    canalSimple(id: 'c2', nom: 'Planning'),
  ],
);

/// « Mode focus », dans l'en-tete du canal.
final Finder entrerFocus = find.byKey(BasculeFocus.cleEntrer);

/// « Quitter le focus », dans le bandeau de sortie.
final Finder quitterFocus = find.byKey(BasculeFocus.cleQuitter);

/// La position de lecture du fil (sa premiere zone defilante).
ScrollPosition positionFil(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(FilDiscussion),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// Le controleur du champ du fil.
TextEditingController champFil(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(FilDiscussion.champKey)).controller!;

/// Le noeud de focus clavier d'une action ([cle]).
FocusNode noeudAction(WidgetTester tester, Finder action) =>
    tester.widget<ActionPrincipale>(action).focusNode!;

/// Entre dans le Focus par « Mode focus ».
Future<void> entrer(WidgetTester tester) async {
  // COM-RC (R-02) : a texte agrandi ou sur une vue basse, l'en-tete du canal
  // defile avec les messages ; « Mode focus » se retrouve en remontant le fil.
  if (entrerFocus.evaluate().isEmpty) {
    positionFil(tester).jumpTo(0);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(entrerFocus);
  await tester.tap(entrerFocus);
  await tester.pumpAndSettle();
}

/// Quitte le Focus par « Quitter le focus ».
Future<void> quitter(WidgetTester tester) async {
  await tester.tap(quitterFocus);
  await tester.pumpAndSettle();
}
