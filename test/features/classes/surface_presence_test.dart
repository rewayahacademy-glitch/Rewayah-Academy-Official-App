import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/features/classes/surface_presence.dart';

import '../../support/harnais.dart';

final DateTime _maintenant = DateTime(2026, 9, 21, 17, 12);

PresenceParticipant _ligne({
  required String profilId,
  required String prenom,
  required EtatPresence etat,
  String role = 'student',
  DateTime? entreLe,
}) => PresenceParticipant(
  seanceId: 's1',
  profilId: profilId,
  role: role,
  prenom: prenom,
  identifiantImmuable: 'STUD-$profilId',
  etat: etat,
  consolide: false,
  entreLe: entreLe,
  debutSeance: DateTime(2026, 9, 21, 17),
);

Future<void> _poser(
  WidgetTester tester,
  List<PresenceParticipant>? lignes,
) async {
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: SurfacePresence(
            lignes: lignes,
            maintenant: _maintenant,
            monProfilId: 'moi',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('les etats viennent du serveur, mot par mot', (
    WidgetTester tester,
  ) async {
    await _poser(tester, <PresenceParticipant>[
      _ligne(
        profilId: 'e1',
        prenom: 'Amina',
        etat: EtatPresence.presente,
        entreLe: DateTime(2026, 9, 21, 17),
      ),
      _ligne(profilId: 'e2', prenom: 'Ibrahim', etat: EtatPresence.absente),
      _ligne(profilId: 'e3', prenom: 'Nour', etat: EtatPresence.enRetard),
      _ligne(
        profilId: 't1',
        prenom: 'Aminata',
        etat: EtatPresence.presente,
        role: 'teacher',
      ),
    ]);

    expect(tester.takeException(), isNull);
    // Chaque etat porte son mot : l'invariant J7.
    expect(find.text(t.presence.presente), findsNWidgets(2));
    expect(find.text(t.presence.absente), findsOneWidget);
    expect(find.text(t.presence.enRetard), findsOneWidget);
    // Le temps se date depuis l'entree constatee par le serveur, jamais
    // depuis un minuteur de l'appareil : « depuis 12 min » a 17 h 12.
    expect(
      find.textContaining(t.presence.entreeMinutes(minutes: '12')),
      findsOneWidget,
    );
    // L'ecran le dit : l'etat est calcule par le serveur.
    expect(find.text(t.classes.presence.source), findsOneWidget);
    // L'enseignant vient en dernier, apres les eleves par prenom.
    final double yAmina = tester.getTopLeft(find.text('Amina')).dy;
    final double yAminata = tester.getTopLeft(find.text('Aminata')).dy;
    expect(yAminata, greaterThan(yAmina));
  });

  testWidgets('une presence indisponible se dit, jamais « Absence »', (
    WidgetTester tester,
  ) async {
    await _poser(tester, null);

    expect(find.text(t.classes.presence.indisponible), findsOneWidget);
    expect(find.text(t.presence.absente), findsNothing);
  });

  testWidgets('ma propre ligne se nomme « Votre presence »', (
    WidgetTester tester,
  ) async {
    await _poser(tester, <PresenceParticipant>[
      _ligne(profilId: 'moi', prenom: 'Karim', etat: EtatPresence.enAttente),
    ]);
    expect(find.text(t.presence.mienne), findsOneWidget);
    expect(find.text('Karim'), findsNothing);
  });
}
