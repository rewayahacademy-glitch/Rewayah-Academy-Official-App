import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../support/harnais.dart';

final DateTime _maintenant = DateTime(2026, 9, 13, 10, 30);

void _fenetre(WidgetTester tester, {double largeur = 1400}) {
  tester.view.physicalSize = Size(largeur, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Seance _seance({
  required String id,
  required int ilYAMinutes,
  StatutSeance? statut = StatutSeance.terminee,
}) {
  final DateTime debut = _maintenant.subtract(Duration(minutes: ilYAMinutes));
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(const Duration(minutes: 60)),
    statut: statut,
    eleveId: 'eleve-1',
    elevePrenom: 'Sofia',
    eleveIdentifiant: 'STUD-000001',
    enseignantId: 'ens-1',
    enseignantPrenom: 'Rachid',
    enseignantIdentifiant: 'TEACH-000001',
  );
}

PresenceParticipant _presence({
  required String seanceId,
  EtatPresence etat = EtatPresence.absente,
  bool consolide = false,
}) => PresenceParticipant(
  seanceId: seanceId,
  profilId: 'eleve-1',
  role: 'student',
  prenom: 'Sofia',
  identifiantImmuable: 'STUD-000001',
  etat: etat,
  consolide: consolide,
);

Future<void> _monter(WidgetTester tester, FauxServiceSuivi suivi) async {
  await tester.pumpWidget(
    hote(
      SuiviElevePage(horloge: () => _maintenant),
      surcharges: <Override>[serviceSuiviProvider.overrideWithValue(suivi)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Suivi élève : contenu visible', () {
    testWidgets('affiche le cours, la date, l enseignant et sa présence', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 's1', ilYAMinutes: 90)],
          presencesRendues: <PresenceParticipant>[
            _presence(seanceId: 's1', etat: EtatPresence.finalisee),
          ],
        ),
      );

      expect(find.text(t.eleve.suivi.cours), findsOneWidget);
      expect(
        find.text(t.eleve.suivi.aujourdhui(heure: '09:00')),
        findsOneWidget,
      );
      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
      expect(find.text(t.presence.finalisee), findsOneWidget);
      expect(find.text('Sofia'), findsNothing);
      expect(find.text('STUD-000001'), findsNothing);
    });

    testWidgets('ne montre pas la décision de correction', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 's1', ilYAMinutes: 90)],
          presencesRendues: <PresenceParticipant>[
            _presence(
              seanceId: 's1',
              etat: EtatPresence.presente,
              consolide: true,
            ),
          ],
        ),
      );

      expect(find.text(t.presence.presente), findsOneWidget);
      expect(find.text(t.presence.consolide), findsNothing);
    });

    testWidgets('inconnu ne devient jamais absence', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 's1', ilYAMinutes: 90)],
          presencesRendues: null,
        ),
      );

      expect(find.text(t.presence.inconnu), findsOneWidget);
      expect(find.text(t.presence.absente), findsNothing);
    });

    testWidgets('un cours annule ne rend pas une presence', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            _seance(id: 's1', ilYAMinutes: 90, statut: StatutSeance.annulee),
          ],
        ),
      );

      expect(find.text(t.eleve.suivi.annule), findsOneWidget);
      expect(find.text(t.eleve.suivi.moi), findsNothing);
    });
  });

  group('Suivi élève : états de données', () {
    testWidgets('affiche un squelette pendant la lecture initiale', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceSuivi suivi = FauxServiceSuivi()
        ..delai = const Duration(milliseconds: 50);
      await tester.pumpWidget(
        hote(
          SuiviElevePage(horloge: () => _maintenant),
          surcharges: <Override>[serviceSuiviProvider.overrideWithValue(suivi)],
        ),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('affiche un état vide sans action backend', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(tester, FauxServiceSuivi());

      expect(find.text(t.eleve.suivi.vide), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('affiche une erreur et permet de relire', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceSuivi suivi = FauxServiceSuivi()
        ..erreurAJeter = StateError('reseau');
      await _monter(tester, suivi);

      expect(find.text(t.eleve.suivi.erreur), findsOneWidget);

      suivi
        ..erreurAJeter = null
        ..seancesRendues = <Seance>[_seance(id: 's1', ilYAMinutes: 90)];
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();

      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
    });
  });

  testWidgets('reste lisible en RTL avec un texte à 200 pour cent', (
    WidgetTester tester,
  ) async {
    _fenetre(tester, largeur: 390);
    await tester.pumpWidget(
      hote(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SuiviElevePage(horloge: () => _maintenant),
          ),
        ),
        surcharges: <Override>[
          serviceSuiviProvider.overrideWithValue(
            FauxServiceSuivi(
              seancesRendues: <Seance>[_seance(id: 's1', ilYAMinutes: 90)],
              presencesRendues: <PresenceParticipant>[
                _presence(seanceId: 's1', etat: EtatPresence.enRetard),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Rachid'), findsOneWidget);
    expect(find.text(t.presence.enRetard), findsOneWidget);
  });
}
