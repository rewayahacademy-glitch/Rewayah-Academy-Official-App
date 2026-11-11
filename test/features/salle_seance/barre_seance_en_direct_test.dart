import 'dart:async';

// La barre « Seance toujours en direct » (directeur, 31/10/2026), devenue une
// ile a deux formes (ILE-SALLE, 11/11/2026) : elle se montre hors de la salle
// tant que l'appel est tenu, ramene a la salle d'un appui, se cache sur
// /salle, se deplie d'elle-meme quand le lien est perdu, dit les cinq
// dernieres minutes a qui conduit la seance, et n'offre le micro qu'a qui
// peut parler (capacite du jeton, jamais le role).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';
import 'package:rewayah_academy/features/salle_seance/barre_seance_en_direct.dart';
import 'package:rewayah_academy/features/salle_seance/bornes_salle.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

AccesSalle _acces({required bool voix, bool conduit = false}) => AccesSalle(
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
    peutModerer: conduit,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

final DateTime _t0 = DateTime.utc(2026, 11, 11, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
  depassementMax: const Duration(minutes: 15),
);

void main() {
  late FauxMoteurSalle moteur;
  late ControleurSessionPersistante controleur;
  late GoRouter routeur;
  BilletSalle? billetRecu;
  late DateTime maintenant;
  late int signaux;

  Future<void> monter(
    WidgetTester tester, {
    required bool voix,
    bool conduit = false,
    BornesChrono? bornes,
    String libelle = '',
    Size taille = const Size(390, 844),
    double echelle = 1,
    Brightness luminosite = Brightness.light,
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    moteur = FauxMoteurSalle();
    controleur = ControleurSessionPersistante(moteur, FauxServiceVideo());
    addTearDown(controleur.liberer);
    controleur.adopter(
      cours: SessionEnCours(
        sessionId: 's1',
        groupeId: 'g1',
        libelleGroupe: libelle,
      ),
      acces: _acces(voix: voix, conduit: conduit),
    );
    billetRecu = null;
    signaux = 0;
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
        overrides: <Override>[
          controleurSessionProvider.overrideWithValue(controleur),
          bornesSalleProvider.overrideWith((Ref _, CleBornesSalle _) => bornes),
          horlogeChronoProvider.overrideWithValue(() => maintenant),
          signalChronoProvider.overrideWithValue(() => signaux++),
        ],
        child: TranslationProvider(
          child: MediaQuery(
            data: MediaQueryData(
              size: taille,
              textScaler: TextScaler.linear(echelle),
            ),
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, luminosite),
              routerConfig: routeur,
              builder: (BuildContext _, Widget? enfant) => BarreSeanceEnDirect(
                routeur: routeur,
                child: enfant ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() => maintenant = _t0.add(const Duration(minutes: 20)));

  testWidgets('hors de la salle : l ile compacte, puis un appui ramene a la '
      'salle avec un billet neuf, et l ile s y cache', (
    WidgetTester tester,
  ) async {
    await monter(tester, voix: true);
    expect(find.text(t.etat.enDirect), findsOneWidget);
    expect(find.byKey(BarreSeanceEnDirect.cleMicro), findsOneWidget);
    expect(find.byKey(BarreSeanceEnDirect.cleDetail), findsNothing);

    await tester.tap(find.byKey(BarreSeanceEnDirect.cleRetour));
    await tester.pump();
    await tester.pump();
    expect(find.text('salle'), findsOneWidget);
    expect(billetRecu?.sessionId, 's1');
    expect(billetRecu?.groupeId, 'g1');
    expect(find.text(t.etat.enDirect), findsNothing);
  });

  // UX-011 (31/10/2026) : le tuteur entre par `push` (« Rejoindre la salle
  // avec … ») ; go_router garde alors l'adresse de l'ecran d'en dessous. La
  // barre ne propose jamais de retourner dans la salle a qui y est.
  testWidgets('UX-011 : entre dans la salle par push, l ile se cache', (
    WidgetTester tester,
  ) async {
    await monter(tester, voix: true);
    expect(find.byKey(BarreSeanceEnDirect.cleIle), findsOneWidget);

    unawaited(routeur.push(Routes.salle));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('salle'), findsOneWidget);
    expect(find.byKey(BarreSeanceEnDirect.cleIle), findsNothing);
    expect(find.text(t.etat.enDirect), findsNothing);

    routeur.pop();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(BarreSeanceEnDirect.cleIle), findsOneWidget);
  });

  testWidgets('sans droit de parler, pas de micro ; lien perdu, l ile se '
      'deplie et dit la reconnexion ; lien revenu, elle redevient compacte ; '
      'fin d appel, plus d ile', (WidgetTester tester) async {
    await monter(tester, voix: false);
    expect(find.text(t.etat.enDirect), findsOneWidget);
    expect(find.byKey(BarreSeanceEnDirect.cleMicro), findsNothing);

    moteur.poser(EtatSalle.reconnexion);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(BarreSeanceEnDirect.cleDetail), findsOneWidget);
    expect(find.text(t.salle.secours.reconnexion), findsOneWidget);
    expect(find.text(t.salle.reconnexionCourt), findsOneWidget);
    await tester.pumpAndSettle();

    moteur.poser(EtatSalle.connecte);
    await tester.pumpAndSettle();
    expect(find.byKey(BarreSeanceEnDirect.cleDetail), findsNothing);
    expect(find.text(t.salle.secours.reconnexion), findsNothing);

    moteur.poser(EtatSalle.reconnexion);
    await tester.pumpAndSettle();
    moteur.poser(EtatSalle.echec);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.salle.secours.reconnexion), findsNothing);
    expect(find.text(t.etat.enDirect), findsNothing);
    expect(find.text('journee'), findsOneWidget);
  });

  testWidgets('compacte : le temps restant, sobre ; le chevron deplie le nom '
      'de la Classe, le mot du micro et « Retourner dans la salle », puis '
      'replie', (WidgetTester tester) async {
    await monter(tester, voix: true, bornes: _bornes, libelle: 'Al-Fatiha');
    expect(find.byKey(BarreSeanceEnDirect.cleChrono), findsOneWidget);
    expect(
      ChronoVivant.chiffresDe(
        tester.widget<ChronoVivant>(find.byType(ChronoVivant)).chrono,
      ),
      '40:00',
    );
    expect(tester.widget<ChronoVivant>(find.byType(ChronoVivant)).sobre, true);
    expect(find.text('Al-Fatiha'), findsNothing);
    final double hauteurCompacte = tester
        .getSize(find.byKey(BarreSeanceEnDirect.cleIle))
        .height;
    // Repliee, l'ile garde sa place : rien ne recouvre la page.
    await tester.pump();
    verifierSansChevauchement(tester, <Finder>[
      find.byKey(BarreSeanceEnDirect.cleIle),
      find.text('journee'),
    ]);
    final Rect pageAvant = tester.getRect(find.text('journee'));

    await tester.tap(find.byKey(BarreSeanceEnDirect.cleChevron));
    await tester.pumpAndSettle();
    expect(find.text('Al-Fatiha'), findsOneWidget);
    expect(find.text(t.salle.microCoupe), findsOneWidget);
    expect(find.text(t.salle.retourner), findsOneWidget);
    expect(
      tester.getSize(find.byKey(BarreSeanceEnDirect.cleIle)).height,
      greaterThan(hauteurCompacte),
    );
    // Directeur, 11/11/2026 : depliee, l'ile se pose SUR la page ; la page
    // n'est ni poussee ni reduite.
    expect(tester.getRect(find.text('journee')), pageAvant);

    await tester.tap(find.text(t.salle.retourner));
    await tester.pump();
    await tester.pump();
    expect(find.text('salle'), findsOneWidget);
  });

  testWidgets('le chevron se commande au clavier', (WidgetTester tester) async {
    await monter(tester, voix: false, bornes: _bornes, libelle: 'Al-Fatiha');
    // Le chevron focalise s'active a la barre d'espace (WCAG 2.1.1). Limite
    // connue, signalee au pilote : la touche Tab de la page ne sort pas de
    // la portee de focus de sa route, et l'ile est posee au-dessus du
    // Navigator (structure d'avant ce lot).
    Focus.of(
      tester.element(
        find.descendant(
          of: find.byKey(BarreSeanceEnDirect.cleChevron),
          matching: find.byType(Icon),
        ),
      ),
    ).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Al-Fatiha'), findsOneWidget);
  });

  testWidgets('qui conduit la seance : a cinq minutes de la fin, l ile se '
      'deplie d elle-meme, sonne une fois, puis se replie', (
    WidgetTester tester,
  ) async {
    maintenant = _t0.add(const Duration(minutes: 54, seconds: 58));
    await monter(tester, voix: true, conduit: true, bornes: _bornes);
    expect(tester.widget<ChronoVivant>(find.byType(ChronoVivant)).sobre, false);
    expect(find.text(t.salle.ile.conclure), findsNothing);

    maintenant = _t0.add(const Duration(minutes: 55, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    expect(find.text(t.salle.ile.conclure), findsOneWidget);
    expect(signaux, 1);

    maintenant = maintenant.add(AppMouvement.ilePassage);
    await tester.pump(AppMouvement.ilePassage);
    await tester.pumpAndSettle();
    expect(find.text(t.salle.ile.conclure), findsNothing);
    expect(find.byKey(BarreSeanceEnDirect.cleDetail), findsNothing);
  });

  testWidgets('qui ne conduit pas : ni phrase ni signal a cinq minutes', (
    WidgetTester tester,
  ) async {
    maintenant = _t0.add(const Duration(minutes: 54, seconds: 58));
    await monter(tester, voix: true, bornes: _bornes);
    maintenant = _t0.add(const Duration(minutes: 55, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    expect(find.text(t.salle.ile.conclure), findsNothing);
    expect(find.byKey(BarreSeanceEnDirect.cleDetail), findsNothing);
    expect(signaux, 0);
  });

  testWidgets('qui conduit : fin prevue atteinte, « séance toujours en '
      'direct »', (WidgetTester tester) async {
    maintenant = _t0.add(const Duration(minutes: 59, seconds: 59));
    await monter(tester, voix: true, conduit: true, bornes: _bornes);
    maintenant = _t0.add(const Duration(minutes: 60, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    expect(find.text(t.salle.ile.finAtteinte), findsOneWidget);
  });

  for (final Brightness luminosite in Brightness.values) {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets('320 px, texte x2, ${luminosite.name}, ${langue.name} : '
          'compacte et depliee tiennent, cibles de 48', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await monter(
          tester,
          voix: true,
          conduit: true,
          bornes: _bornes,
          libelle: 'Al-Fatiha',
          taille: const Size(320, 700),
          echelle: 2,
          luminosite: luminosite,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(BarreSeanceEnDirect.cleChevron)).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester.getRect(find.byKey(BarreSeanceEnDirect.cleIle)).right,
          lessThanOrEqualTo(320),
        );
        await tester.tap(find.byKey(BarreSeanceEnDirect.cleChevron));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Al-Fatiha'), findsOneWidget);
        expect(
          tester.getRect(find.byKey(BarreSeanceEnDirect.cleIle)).right,
          lessThanOrEqualTo(320),
        );
      });
    }
  }
}
