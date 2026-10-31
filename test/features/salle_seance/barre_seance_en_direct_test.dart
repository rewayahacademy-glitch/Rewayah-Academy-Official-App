// La barre « Seance toujours en direct » (directeur, 31/10/2026) : elle se
// montre hors de la salle tant que l'appel est tenu, ramene a la salle d'un
// appui, se cache sur /salle, dit le lien perdu, et n'offre le micro qu'a qui
// peut parler (capacite du jeton, jamais le role).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/features/salle_seance/barre_seance_en_direct.dart';

import '../../support/harnais.dart';

AccesSalle _acces({required bool voix}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: voix ? 'teacher' : 'guardian',
  capacites: CapacitesSalle(
    peutPublier: voix,
    peutPublierVideo: false,
    peutPublierDonnees: false,
    peutRecevoir: true,
    invisible: false,
    peutModerer: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

void main() {
  late FauxMoteurSalle moteur;
  late ControleurSessionPersistante controleur;
  late GoRouter routeur;
  BilletSalle? billetRecu;

  Future<void> monter(WidgetTester tester, {required bool voix}) async {
    moteur = FauxMoteurSalle();
    controleur = ControleurSessionPersistante(moteur, FauxServiceVideo());
    addTearDown(controleur.liberer);
    controleur.adopter(
      cours: const SessionEnCours(
        sessionId: 's1',
        groupeId: 'g1',
        libelleGroupe: '',
      ),
      acces: _acces(voix: voix),
    );
    billetRecu = null;
    routeur = GoRouter(
      initialLocation: Routes.enseignantJournee,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.enseignantJournee,
          builder: (BuildContext _, GoRouterState _) => const Text('journee'),
        ),
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState etat) {
            billetRecu = etat.extra as BilletSalle?;
            return const Text('salle');
          },
        ),
      ],
    );
    addTearDown(routeur.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controleurSessionProvider.overrideWithValue(controleur)],
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            routerConfig: routeur,
            builder: (BuildContext _, Widget? enfant) => BarreSeanceEnDirect(
              routeur: routeur,
              child: enfant ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('hors de la salle : la barre, puis un appui ramene a la salle '
      'avec un billet neuf, et la barre s y cache', (
    WidgetTester tester,
  ) async {
    await monter(tester, voix: true);
    expect(find.text(t.tc.groupe.temps.prolongee), findsOneWidget);
    expect(find.byType(BoutonIcone), findsOneWidget);

    await tester.tap(find.text(t.salle.retourner));
    await tester.pump();
    await tester.pump();
    expect(find.text('salle'), findsOneWidget);
    expect(billetRecu?.sessionId, 's1');
    expect(billetRecu?.groupeId, 'g1');
    expect(find.text(t.tc.groupe.temps.prolongee), findsNothing);
  });

  testWidgets('sans droit de parler, pas de micro ; lien perdu, la phrase de '
      'reconnexion ; fin d appel, plus de barre', (WidgetTester tester) async {
    await monter(tester, voix: false);
    expect(find.text(t.tc.groupe.temps.prolongee), findsOneWidget);
    expect(find.byType(BoutonIcone), findsNothing);

    moteur.poser(EtatSalle.reconnexion);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.salle.secours.reconnexion), findsOneWidget);

    moteur.poser(EtatSalle.echec);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.salle.secours.reconnexion), findsNothing);
    expect(find.text(t.tc.groupe.temps.prolongee), findsNothing);
    expect(find.text('journee'), findsOneWidget);
  });
}
