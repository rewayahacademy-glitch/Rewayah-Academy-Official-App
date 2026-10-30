// Concierge (a), tuteur (decision du pilote, 24/10/2026) : la carte de la
// Classe et l'Accueil du tuteur montrent « Rejoindre la salle avec {prenom} »
// des que l'horloge de la Classe (tiree des creneaux, meme sans seance) ouvre
// la porte ; le concierge rend la seance, puis la salle s'ouvre avec le billet
// de l'eleve. Sans seance rendue : K-59, sous le bouton.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_groupe/concierge_seance.dart';
import 'package:rewayah_academy/core/tc_groupe/concierge_seance_memoire.dart';
import 'package:rewayah_academy/core/tc_horloge/horloge_vivante.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/rejoindre_avec_eleve.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../../router/support_routeur.dart';
import 'support_classe.dart';

const String _a1 = eleveA1;
const String _classe = classeA;
const String _rendue = 's-rendue';

/// L'horloge de la Classe, sans seance : porte ouverte depuis cinq minutes,
/// ou le cours dans trois heures.
SessionClockVM _horloge({required bool ouverte}) {
  final DateTime debut = DateTime.utc(2026, 10, 25, 17);
  return SessionClockVM.depuisFenetre(
    fenetre: FenetreSeance(
      debutUtc: debut,
      finPrevueUtc: debut.add(const Duration(minutes: 60)),
      fenetreAcces: const Duration(minutes: 20),
      graceApresFin: const Duration(minutes: 15),
    ),
    maintenantServeurUtc: debut.subtract(
      ouverte ? const Duration(minutes: 15) : const Duration(hours: 3),
    ),
    sessionId: null,
    horlogeUtilisateur: const HorlogeAffichee(
      fuseauIana: 'Europe/Paris',
      libelleVille: 'Paris',
      heureLocaleRendue: '18:00',
      dateLocaleRendue: 'Dimanche 25 octobre',
    ),
  );
}

Future<void> _monter(
  WidgetTester tester, {
  required String depart,
  required bool ouverte,
  required ConciergeMemoire concierge,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  final SessionClockVM horloge = _horloge(ouverte: ouverte);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesClasse(seances: const <SeanceFamille>[]),
        horlogeClasseVivanteProvider(_classe)
            .overrideWith((Ref _) => Stream<SessionClockVM?>.value(horloge)),
        portConciergeProvider.overrideWithValue(concierge),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  final String classe = Routes.classePour(_classe, eleveId: _a1);

  testWidgets('carte de la Classe, aucune seance, porte ouverte : le '
      'concierge rend la seance, la salle s ouvre avec le billet de l eleve', (
    WidgetTester tester,
  ) async {
    final ConciergeMemoire concierge = ConciergeMemoire(
      seances: const <String, String>{_classe: _rendue},
    );
    await _monter(tester, depart: classe, ouverte: true, concierge: concierge);
    final Finder bouton = find.byKey(BoutonRejoindreClasseAvecEleve.cle);
    expect(bouton, findsOneWidget);
    expect(
      find.text(t.classe.seance.rejoindreAvec(prenom: 'Élève A1')),
      findsOneWidget,
    );
    expect(find.text(t.classe.seance.aucune), findsNothing);

    await _toucher(tester, bouton);
    expect(concierge.appels, <String>[_classe]);
    final Finder salle = find.byType(SallePage);
    expect(salle, findsOneWidget);
    expect(tester.widget<SallePage>(salle).seanceId, _rendue);
    expect(tester.widget<SallePage>(salle).eleveId, _a1);
  });

  testWidgets('carte de la Classe : sans seance rendue, K-59 sous le bouton, '
      'pas de salle', (WidgetTester tester) async {
    final ConciergeMemoire concierge = ConciergeMemoire();
    await _monter(tester, depart: classe, ouverte: true, concierge: concierge);
    await _toucher(tester, find.byKey(BoutonRejoindreClasseAvecEleve.cle));
    expect(concierge.appels, <String>[_classe]);
    expect(find.byType(SallePage), findsNothing);
    expect(find.byKey(BoutonRejoindreClasseAvecEleve.cleRefus), findsOneWidget);
    expect(find.text(t.classe.entree.revenirAvant), findsWidgets);
  });

  testWidgets('carte de la Classe, porte fermee : aucun bouton, « aucune '
      'seance » comme avant', (WidgetTester tester) async {
    final ConciergeMemoire concierge = ConciergeMemoire();
    await _monter(tester, depart: classe, ouverte: false, concierge: concierge);
    expect(find.byKey(BoutonRejoindreClasseAvecEleve.cle), findsNothing);
    expect(find.text(t.classe.seance.aucune), findsOneWidget);
    expect(concierge.appels, isEmpty);
  });

  testWidgets('Accueil du tuteur, aucune seance, porte ouverte : le bandeau '
      '« Rejoindre la salle avec » ouvre la salle par le concierge', (
    WidgetTester tester,
  ) async {
    final ConciergeMemoire concierge = ConciergeMemoire(
      seances: const <String, String>{_classe: _rendue},
    );
    await _monter(
      tester,
      depart: Routes.tuteurAccueil,
      ouverte: true,
      concierge: concierge,
    );
    expect(find.byType(AccueilFamillePage), findsOneWidget);
    expect(find.byKey(AccueilFamillePage.rejoindreKey), findsOneWidget);
    await _toucher(tester, find.byKey(BoutonRejoindreClasseAvecEleve.cle));
    expect(concierge.appels, <String>[_classe]);
    final Finder salle = find.byType(SallePage);
    expect(salle, findsOneWidget);
    expect(tester.widget<SallePage>(salle).seanceId, _rendue);
    expect(tester.widget<SallePage>(salle).eleveId, _a1);
  });

  testWidgets('Accueil du tuteur, porte fermee : aucun bandeau de salle', (
    WidgetTester tester,
  ) async {
    final ConciergeMemoire concierge = ConciergeMemoire();
    await _monter(
      tester,
      depart: Routes.tuteurAccueil,
      ouverte: false,
      concierge: concierge,
    );
    expect(find.byKey(BoutonRejoindreClasseAvecEleve.cle), findsNothing);
  });
}
