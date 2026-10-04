// COM-F : etats generiques des communications (spec sections 22 et 25), sur
// EtatSysteme, Skeleton, BlocAsynchrone et OfflineBanner. Chaque etat se rend
// avec le texte de la spec ; une capacite absente n'offre jamais
// « Reessayer » ; le hors ligne suit horsLigneProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';

import '../../support/hote_theme.dart';

const Key _action = ValueKey<String>('etat-systeme-action');

void main() {
  final e = t.com.socle.composants.etats;

  testWidgets('chargement : squelette annonce', (WidgetTester tester) async {
    await tester.pumpWidget(
      hoteTheme(const VueEtatCommunication(etat: EtatCommunication.chargement)),
    );
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byKey(VueEtatCommunication.cleChargement), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('vide : le vide propre a l ecran, sans action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        VueEtatCommunication(
          etat: EtatCommunication.vide,
          titreVide: t.com.messages.vide,
        ),
      ),
    );
    expect(find.text(t.com.messages.vide), findsOneWidget);
    expect(find.byKey(_action), findsNothing);
  });

  testWidgets('erreur : texte de la spec et « Reessayer » qui relance', (
    WidgetTester tester,
  ) async {
    int relances = 0;
    await tester.pumpWidget(
      hoteTheme(
        VueEtatCommunication(
          etat: EtatCommunication.erreur,
          onReessayer: () => relances++,
        ),
      ),
    );
    expect(find.text(e.erreurTitre), findsOneWidget);
    expect(find.text(e.erreur), findsOneWidget);
    await tester.tap(find.byKey(_action));
    expect(relances, 1);
  });

  testWidgets('indisponible : ni echec ni vide, jamais « Reessayer »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        VueEtatCommunication(
          etat: EtatCommunication.indisponible,
          onReessayer: () {},
          dependance: 'COM-BR-04',
        ),
      ),
    );
    expect(find.text(e.indisponibleTitre), findsOneWidget);
    expect(find.byKey(_action), findsNothing);
    // La dependance n'est jamais affichee.
    expect(find.textContaining('COM-BR'), findsNothing);
    expect(
      VueEtatCommunication.depuisErreur(
        const CapaciteIndisponible('COM-BR-04'),
      ),
      EtatCommunication.indisponible,
    );
    expect(
      VueEtatCommunication.depuisErreur(Exception('reseau')),
      EtatCommunication.erreur,
    );
  });

  testWidgets('hors ligne et permission refusee : textes de la spec', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(const VueEtatCommunication(etat: EtatCommunication.horsLigne)),
    );
    expect(find.text(e.horsLigne), findsOneWidget);
    expect(
      tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
      NatureEtat.horsLigne,
    );

    await tester.pumpWidget(
      hoteTheme(
        const VueEtatCommunication(etat: EtatCommunication.permissionRefusee),
      ),
    );
    expect(find.text(e.permissionRefusee), findsOneWidget);
  });

  group('BandeauHorsLigneCommunication suit le reseau', () {
    for (final bool horsLigne in <bool>[true, false]) {
      testWidgets(horsLigne ? 'hors ligne : bandeau' : 'en ligne : rien', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTheme(
            const BandeauHorsLigneCommunication(),
            surcharges: [
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(horsLigne),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(OfflineBanner),
          horsLigne ? findsOneWidget : findsNothing,
        );
        expect(
          find.text(e.horsLigne),
          horsLigne ? findsOneWidget : findsNothing,
        );
      });
    }
  });

  group('BlocCommunication', () {
    testWidgets('capacite indisponible : etat indisponible, sans action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTheme(
          BlocCommunication<List<int>>(
            valeur: const AsyncValue<List<int>>.error(
              CapaciteIndisponible('COM-BR-01'),
              StackTrace.empty,
            ),
            construire: (List<int> v) => Text('${v.length}'),
            onReessayer: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(e.indisponibleTitre), findsOneWidget);
      expect(find.byKey(_action), findsNothing);
    });

    testWidgets('echec : texte des communications et « Reessayer »', (
      WidgetTester tester,
    ) async {
      int relances = 0;
      await tester.pumpWidget(
        hoteTheme(
          BlocCommunication<List<int>>(
            valeur: AsyncValue<List<int>>.error(
              Exception('reseau'),
              StackTrace.empty,
            ),
            construire: (List<int> v) => Text('${v.length}'),
            onReessayer: () => relances++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(e.erreur), findsOneWidget);
      await tester.tap(find.byKey(_action));
      expect(relances, 1);
    });

    testWidgets('vide puis contenu', (WidgetTester tester) async {
      await tester.pumpWidget(
        hoteTheme(
          BlocCommunication<List<int>>(
            valeur: const AsyncValue<List<int>>.data(<int>[]),
            construire: (List<int> v) => Text('contenu ${v.length}'),
            titreVide: t.com.messages.vide,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.com.messages.vide), findsOneWidget);

      await tester.pumpWidget(
        hoteTheme(
          BlocCommunication<List<int>>(
            valeur: const AsyncValue<List<int>>.data(<int>[1, 2]),
            construire: (List<int> v) => Text('contenu ${v.length}'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('contenu 2'), findsOneWidget);
    });
  });
}
