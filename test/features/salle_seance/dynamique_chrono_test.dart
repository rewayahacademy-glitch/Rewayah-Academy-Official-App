// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026, retours sur la salle, points 2,
// 3 et 5) : la Dynamique chrono, composant seul.
//
// Remplace les tests de l'ile ILE-SALLE (11/11/2026, `pilule_ile_test.dart`) :
// la mention et le mot d'etat ne sont plus dans l'ile (ils ne se replient
// plus, `LigneEtatSalle`), l'ile ne se deplie plus d'elle-meme a l'entree ni
// a un changement d'etat ; elle se deplie d'un toucher et se replie seule.
//
// - repliee : une ligne, l'anneau, « Reste 40:00 » visible, les marques en
//   points lus ;
// - un toucher deplie : chaque marque en clair, la commande de la pause de qui
//   la pilote ; repli seul ([AppMouvement.dynamiqueChronoDepliee]) ou au
//   second toucher ;
// - 320 px, texte x2, fr et ar : une ligne, rien ne deborde ;
// - mouvement reduit : meme information ;
// - l'alerte passagere (type pret, aucune emise par la salle) : titre et
//   actions, depart seul, trace laissee en marque.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/marque_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../support/demo/seance_demo.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 11, 17);
final DateTime _maintenant = _t0.add(const Duration(minutes: 20));
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
);

const MarqueChrono _retard = MarqueChrono.presence(
  libelle: 'En retard',
  ton: TonEtat.avertissement,
);
const MarqueChrono _recite = MarqueChrono.recitation(
  libelle: 'Yasmine récite',
);

VueSeance _vue({RoleSeance role = RoleSeance.eleve, PauseSeance? pause}) =>
    DonneesSeanceDemo.vue(
      role,
      EtatDemoSalle.repos,
    ).copyWith(chrono: _bornes, pause: pause);

Future<void> _poser(
  WidgetTester tester,
  VueSeance vue, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  bool reduit = false,
  bool micro = false,
  List<MarqueChrono> marques = const <MarqueChrono>[],
  AlerteChrono? alerte,
  VoidCallback? onPause,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horlogeChronoProvider.overrideWithValue(() => _maintenant),
      ],
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
            disableAnimations: reduit,
          ),
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DynamiqueChrono(
                    vue: vue,
                    avecChrono: true,
                    largeurMax: taille.width - 32,
                    microOuvert: micro,
                    marques: marques,
                    alerte: alerte,
                    onPause: onPause,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

bool _depliee() => find.byKey(DynamiqueChrono.cleDepliee).evaluate().isNotEmpty;

const Key _barre = ValueKey<String>('pilule-etat-salle');

Future<void> _toucher(WidgetTester tester) async {
  await tester.tap(find.byKey(DynamiqueChrono.cleDeplier));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('repliee a l entree : une ligne, « Reste » visible, les '
      'marques en points lus', (WidgetTester tester) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _poser(tester, _vue(), marques: <MarqueChrono>[_retard, _recite]);
    expect(_depliee(), isFalse);
    expect(find.byType(ChronoVivant), findsOneWidget);
    expect(find.text(t.salle.seance.chrono.reste), findsOneWidget);
    // Les marques ne sont pas ecrites, elles sont lues.
    expect(find.text('En retard'), findsNothing);
    expect(find.bySemanticsLabel('En retard'), findsOneWidget);
    expect(find.bySemanticsLabel('Yasmine récite'), findsOneWidget);
    // La mention n'est plus dans la barre (elle ne se replie jamais).
    expect(find.text(t.salle.bandeauPermanent), findsNothing);
    // Une ligne : la cible de 48, la barre de la meme hauteur.
    final Size barre = tester.getSize(find.byKey(_barre));
    expect(barre.height, closeTo(48, 1));
    expect(
      tester.getSize(find.byKey(DynamiqueChrono.cleDeplier)).height,
      greaterThanOrEqualTo(48),
    );
    semantique.dispose();
  });

  testWidgets('un toucher deplie : les marques en clair ; repli seul, puis '
      'au second toucher', (WidgetTester tester) async {
    await _poser(tester, _vue(), marques: <MarqueChrono>[_retard, _recite]);
    final Rect place = tester.getRect(find.byKey(_barre));
    await _toucher(tester);
    expect(_depliee(), isTrue);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Yasmine récite'), findsOneWidget);
    // Depliee par-dessus : la place reservee ne bouge pas.
    expect(tester.getRect(find.byKey(_barre)), place);
    // Le meme chrono (jamais recree).
    expect(find.byType(ChronoVivant), findsOneWidget);

    await tester.pump(AppMouvement.dynamiqueChronoDepliee);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_depliee(), isFalse);

    await _toucher(tester);
    expect(_depliee(), isTrue);
    await _toucher(tester);
    expect(_depliee(), isFalse);
  });

  testWidgets('enseignant : la pause en marque, « Démarrer la pause » dans la '
      'barre depliee seulement', (WidgetTester tester) async {
    int demandes = 0;
    await _poser(
      tester,
      _vue(
        role: RoleSeance.enseignant,
        pause: PauseSeance(
          statut: StatutPause.programmee,
          dureePrevueMinutes: 10,
          debutPrevuUtc: _maintenant.add(const Duration(minutes: 21)),
          peutPiloter: true,
        ),
      ),
      onPause: () => demandes++,
    );
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
    expect(find.byKey(ChronoSalle.clePause), findsNothing);
    await _toucher(tester);
    expect(
      tester.widget<Text>(find.byKey(ChronoSalle.clePause)).data,
      contains('21'),
    );
    await tester.tap(find.byKey(ChronoSalle.cleCommandePause));
    expect(demandes, 1);
  });

  testWidgets('eleve : aucune commande de pause, meme depliee', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      _vue(
        pause: PauseSeance(
          statut: StatutPause.programmee,
          dureePrevueMinutes: 10,
          debutPrevuUtc: _maintenant.add(const Duration(minutes: 21)),
        ),
      ),
      onPause: () {},
    );
    await _toucher(tester);
    expect(find.byKey(ChronoSalle.clePause), findsOneWidget);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
  });

  testWidgets('mouvement reduit : meme information, depliage et repli', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      _vue(),
      reduit: true,
      marques: <MarqueChrono>[_retard],
    );
    expect(find.text(t.salle.seance.chrono.reste), findsOneWidget);
    await tester.tap(find.byKey(DynamiqueChrono.cleDeplier));
    await tester.pump();
    expect(_depliee(), isTrue);
    expect(find.text('En retard'), findsOneWidget);
    // Rien ne tourne apres le geste : aucune image a dessiner.
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(AppMouvement.dynamiqueChronoDepliee);
    await tester.pump();
    expect(_depliee(), isFalse);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('320 px, texte x2, ${langue.name} : une ligne repliee, '
        'depliee lisible, aucun debordement', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      await _poser(
        tester,
        _vue(),
        taille: const Size(320, 700),
        echelle: 2,
        micro: true,
        marques: <MarqueChrono>[_retard, _recite],
      );
      expect(tester.takeException(), isNull);
      final Rect barre = tester.getRect(find.byKey(_barre));
      expect(barre.right, lessThanOrEqualTo(320 - 16 + 1));
      expect(barre.left, greaterThanOrEqualTo(16 - 1));
      // Une ligne : la hauteur d'une ligne de texte x2, pas deux.
      expect(barre.height, lessThan(80));
      expect(find.byKey(DynamiqueChrono.cleMicroOuvert), findsOneWidget);
      await _toucher(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('En retard'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(DynamiqueChrono.cleDepliee)).right,
        lessThanOrEqualTo(320),
      );
    });
  }

  testWidgets('alerte passagere : titre et actions, depart seul, trace '
      'laissee en marque ; aucune n est emise par defaut', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _vue());
    expect(find.byKey(DynamiqueChrono.cleAlerte), findsNothing);
    int oui = 0;
    final AlerteChrono alerte = AlerteChrono(
      id: 'a1',
      titre: 'Titre de test',
      actions: <ActionAlerteChrono>[
        ActionAlerteChrono(libelle: 'Oui', onPress: () => oui++),
        ActionAlerteChrono(libelle: 'Non', onPress: () {}),
      ],
      duree: const Duration(seconds: 3),
      trace: _recite,
    );
    await _poser(tester, _vue(), alerte: alerte);
    expect(find.byKey(DynamiqueChrono.cleAlerte), findsOneWidget);
    expect(find.text('Titre de test'), findsOneWidget);
    expect(find.text('Oui'), findsOneWidget);
    expect(find.text('Non'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(DynamiqueChrono.cleAlerte), findsNothing);
    expect(_depliee(), isFalse);
    // La trace reste, en marque lue.
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Yasmine récite'), findsOneWidget);
    semantique.dispose();
    // La meme alerte ne se rejoue pas.
    await _poser(tester, _vue(), alerte: alerte);
    expect(find.byKey(DynamiqueChrono.cleAlerte), findsNothing);
    expect(oui, 0);
  });
}
