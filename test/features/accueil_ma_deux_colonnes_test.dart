// MA-2COL-1 : l'Accueil du Mode Accessibilite retrouve ses deux colonnes,
// comme la fiche ELV-02-MA le prevoit (DASH_STRATEGIE : « une colonne ;
// deux a partir de 840 / facteur de texte ; pas de Bento »).
//
// Depuis la VRAIE navigation (K-07) : l'application monte sur son routeur,
// session eleve en Mode Accessibilite, a `/eleve`. Une colonne sous le
// seuil, deux au-dessus ; le seuil est divise par le facteur de texte. En
// deux colonnes, « Avant le prochain cours » est au debut de la rangee,
// « Lire le Coran » puis l'aide a sa fin, en LTR comme en RTL. Hors
// contenu (vide, erreur, indisponible, tentative perdue), le Coran et l'aide
// restent, sous l'etat (D11). Aucun mot coupe a 320 x2 et a 1440, LTR et
// RTL, en deux colonnes. DASH-MA-PROD-b garde : hors ligne, « Reessayer »
// actif, aucun bouton grise.
//
// Contre-epreuve : sur le code de DASH-MA-PROD-b (une seule colonne a toute
// largeur), chaque cas ci-dessous echoue.
//
// MA-2COL-1b : franchir le seuil (fenetre redimensionnee, facteur de texte
// change) ne recree pas le bloc asynchrone : meme State, compteur de
// reessais et minuteries de chargement gardes. Contre-epreuve : avec
// `if (deuxColonnes) return haut;` (le bloc change de place dans l'arbre),
// le groupe « Franchir le seuil » echoue.

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/port_accueil_accessibilite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bloc_asynchrone.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_accessibilite.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../router/support_routeur.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';

const PortAccueilAccessibilite _contenu = PortAccueilAccessibiliteDemo(
  eleve: EleveDemoAccessibilite.mariam,
);

/// Un port dont la reponse arrive quand le test le decide.
class _PortEnAttente implements PortAccueilAccessibilite {
  const _PortEnAttente(this.reponse);

  final Future<DonneesAccueilAccessibilite> reponse;

  @override
  Future<DonneesAccueilAccessibilite> lire() => reponse;
}

/// Monte l'application sur son vrai routeur, session eleve en Mode
/// Accessibilite.
Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  PortAccueilAccessibilite? port = _contenu,
  bool horsLigne = false,
  double echelle = 1,
  ValueListenable<double>? echelleVariable,
  TextDirection sens = TextDirection.ltr,
  bool attendre = true,
}) async {
  // Le facteur de texte peut changer sans remonter l'application.
  final ValueListenable<double> facteur =
      echelleVariable ?? ValueNotifier<double>(echelle);
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Un nouveau montage repart d'un conteneur neuf (ses surcharges).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(
            sessionActive(AppRole.student, mode: InterfaceMode.enfant),
          ),
        ),
        if (port != null)
          portAccueilAccessibiliteProvider.overrideWithValue(port),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) =>
              MaterialApp.router(
                theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
                routerConfig: ref.read(routeurProvider),
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (BuildContext contexte, Widget? app) =>
                    ValueListenableBuilder<double>(
                      valueListenable: facteur,
                      builder: (BuildContext contexte, double f, Widget? _) =>
                          MediaQuery(
                            data: MediaQuery.of(contexte)
                                .copyWith(textScaler: TextScaler.linear(f)),
                            child: Directionality(
                              textDirection: sens,
                              child: app!,
                            ),
                          ),
                    ),
              ),
        ),
      ),
    ),
  );
  if (attendre) {
    await stabiliser(tester);
  }
}

/// La largeur utile de l'Accueil : celle que `PageShell` lui donne.
double _largeurUtile(WidgetTester tester) => tester
    .getSize(
      find
          .descendant(
            of: find.byType(AccueilAccessibilite),
            matching: find.byType(LayoutBuilder),
          )
          .first,
    )
    .width;

Rect _rect(WidgetTester tester, String texte) =>
    tester.getRect(find.text(texte));

/// Deux colonnes : la rangee existe ; « Avant le prochain cours » et « Lire
/// le Coran » partent a la meme hauteur, les taches au debut de la ligne de
/// lecture, le Coran a sa fin ; l'aide sous le Coran.
void _verifierDeuxColonnes(WidgetTester tester, TextDirection sens) {
  expect(find.byKey(AccueilAccessibilite.cleDeuxColonnes), findsOneWidget);
  final Rect taches = _rect(tester, LibellesGroupe.avantProchainCours);
  final Rect coran = _rect(tester, t.accessibilite.accueil.lireCoran);
  final Rect aide = _rect(tester, t.accessibilite.accueil.aide);
  expect(coran.top, lessThan(taches.bottom), reason: 'Coran a cote');
  if (sens == TextDirection.ltr) {
    expect(coran.left, greaterThan(taches.right));
  } else {
    expect(coran.right, lessThan(taches.left));
  }
  expect(aide.top, greaterThan(coran.bottom), reason: 'aide en dernier');
}

/// Une colonne : « Lire le Coran » commence sous « Avant le prochain
/// cours ».
void _verifierUneColonne(WidgetTester tester) {
  expect(find.byKey(AccueilAccessibilite.cleDeuxColonnes), findsNothing);
  final Rect taches = _rect(tester, LibellesGroupe.avantProchainCours);
  final Rect coran = _rect(tester, t.accessibilite.accueil.lireCoran);
  expect(coran.top, greaterThan(taches.bottom));
}

/// Hors contenu : le Coran et l'aide restent, une fois chacun, sous l'etat.
void _coranEtAideSousLEtat(WidgetTester tester, Key etat) {
  expect(find.byKey(etat), findsOneWidget);
  expect(find.text(t.accessibilite.accueil.lireCoran), findsOneWidget);
  expect(find.text(t.accessibilite.accueil.aide), findsOneWidget);
  expect(
    _rect(tester, t.accessibilite.accueil.lireCoran).top,
    greaterThan(tester.getRect(find.byKey(etat)).bottom),
  );
}

void main() {
  group('Une colonne sous le seuil, deux au-dessus', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('390 : une colonne ; 1440 : deux, ${sens.name}', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: const Size(390, 2400), sens: sens);
        expect(_largeurUtile(tester), lessThan(seuilDeuxColonnesAccueil));
        _verifierUneColonne(tester);

        await _monter(tester, taille: const Size(1440, 2400), sens: sens);
        expect(
          _largeurUtile(tester),
          greaterThanOrEqualTo(seuilDeuxColonnesAccueil),
        );
        _verifierDeuxColonnes(tester, sens);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('au pixel pres : une colonne a 839 de largeur utile, deux '
        'a 840', (WidgetTester tester) async {
      // La largeur utile suit celle de la fenetre a gouttieres et coquille
      // constantes : on la mesure, puis on vise le seuil exact.
      await _monter(tester, taille: const Size(1100, 2400));
      final double ecart = 1100 - _largeurUtile(tester);
      await _monter(
        tester,
        taille: Size(seuilDeuxColonnesAccueil + ecart - 1, 2400),
      );
      expect(_largeurUtile(tester), seuilDeuxColonnesAccueil - 1);
      _verifierUneColonne(tester);
      await _monter(
        tester,
        taille: Size(seuilDeuxColonnesAccueil + ecart, 2400),
      );
      expect(_largeurUtile(tester), seuilDeuxColonnesAccueil);
      _verifierDeuxColonnes(tester, TextDirection.ltr);
    });
  });

  group('Le seuil est divise par le facteur de texte', () {
    testWidgets('1440 : deux colonnes juste sous W / 840, une juste '
        'au-dessus ; jamais deux a 200 %', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(1440, 3200));
      final double largeur = _largeurUtile(tester);
      final double limite = largeur / seuilDeuxColonnesAccueil;
      expect(limite, greaterThan(1), reason: 'deux colonnes a 100 %');

      await _monter(
        tester,
        taille: const Size(1440, 3200),
        echelle: limite - 0.02,
      );
      expect(_largeurUtile(tester), largeur);
      _verifierDeuxColonnes(tester, TextDirection.ltr);

      await _monter(
        tester,
        taille: const Size(1440, 3200),
        echelle: limite + 0.02,
      );
      expect(_largeurUtile(tester), largeur);
      _verifierUneColonne(tester);

      await _monter(tester, taille: const Size(1440, 3200), echelle: 2);
      _verifierUneColonne(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('Deux colonnes, chaque etat (D11)', () {
    const Size bureau = Size(1440, 2400);

    testWidgets('contenu en deux colonnes ; vide, erreur, indisponible : '
        'une colonne, le Coran et l aide sous l etat', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: bureau);
      _verifierDeuxColonnes(tester, TextDirection.ltr);
      for (final (PortAccueilAccessibilite?, Key) cas
          in <(PortAccueilAccessibilite?, Key)>[
            (
              const PortAccueilAccessibiliteDemo(
                eleve: EleveDemoAccessibilite.idriss,
                situation: SituationAccueilDemo.vide,
              ),
              AccueilAccessibilite.cleVide,
            ),
            (
              const PortAccueilAccessibiliteDemo(
                eleve: EleveDemoAccessibilite.mariam,
                situation: SituationAccueilDemo.erreur,
              ),
              AccueilAccessibilite.cleErreur,
            ),
            (null, AccueilAccessibilite.cleIndisponible),
          ]) {
        await _monter(tester, taille: bureau, port: cas.$1);
        expect(find.byKey(AccueilAccessibilite.cleDeuxColonnes), findsNothing);
        _coranEtAideSousLEtat(tester, cas.$2);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('chargement : squelette fidele en deux colonnes, puis '
        'tentative perdue : le Coran et l aide restent', (
      WidgetTester tester,
    ) async {
      final Completer<DonneesAccueilAccessibilite> attente =
          Completer<DonneesAccueilAccessibilite>();
      await _monter(
        tester,
        taille: bureau,
        port: _PortEnAttente(attente.future),
        attendre: false,
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Le squelette a la forme du contenu : la rangee des deux colonnes,
      // le Coran et l'aide deja a leur place.
      expect(
        find.descendant(
          of: find.byKey(AccueilAccessibilite.cleSquelette),
          matching: find.byKey(AccueilAccessibilite.cleDeuxColonnes),
        ),
        findsOneWidget,
      );
      expect(find.text(t.accessibilite.accueil.lireCoran), findsOneWidget);
      expect(find.text(t.accessibilite.accueil.aide), findsOneWidget);

      // Passe le delai maximal : la tentative est perdue (echec par defaut
      // du bloc), le Coran et l'aide restent (D11).
      await tester.pump(AppDelais.requeteMax);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(AccueilAccessibilite.cleSquelette), findsNothing);
      expect(find.text(t.accessibilite.accueil.lireCoran), findsOneWidget);
      expect(find.text(t.accessibilite.accueil.aide), findsOneWidget);
      expect(find.byKey(AccueilAccessibilite.cleDeuxColonnes), findsNothing);
      attente.complete(_contenu.lire());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('hors ligne (DASH-MA-PROD-b garde) : deux colonnes, '
        '« Reessayer » actif, aucun bouton grise', (WidgetTester tester) async {
      await _monter(tester, taille: bureau, horsLigne: true);
      _verifierDeuxColonnes(tester, TextDirection.ltr);
      final Iterable<ActionPrincipale> actions = tester
          .widgetList<ActionPrincipale>(find.byType(ActionPrincipale));
      expect(actions, isNotEmpty);
      for (final ActionPrincipale a in actions) {
        expect(a.onPress, isNotNull, reason: a.libelle);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Franchir le seuil ne recree pas le bloc (MA-2COL-1b)', () {
    const PortAccueilAccessibilite enEchec = PortAccueilAccessibiliteDemo(
      eleve: EleveDemoAccessibilite.mariam,
      situation: SituationAccueilDemo.erreur,
    );
    final Finder bloc = find.byType(
      BlocAsynchrone<DonneesAccueilAccessibilite>,
    );
    final Finder reessayer = find.text(t.commun.etats.actions.reessayer);

    /// Epuise les reessais : la phrase remplace le bouton.
    Future<void> epuiser(WidgetTester tester) async {
      for (int i = 0; i < BlocAsynchrone.reessaisMax; i++) {
        await tester.tap(reessayer);
        await stabiliser(tester);
      }
      expect(reessayer, findsNothing);
      expect(find.text(t.commun.etats.reessaisEpuises), findsOneWidget);
    }

    /// Le bloc est le meme et n'a pas oublie ses reessais.
    void memeBloc(WidgetTester tester, State<StatefulWidget> avant) {
      expect(reessayer, findsNothing);
      expect(find.text(t.commun.etats.reessaisEpuises), findsOneWidget);
      expect(identical(tester.state(bloc), avant), isTrue);
    }

    testWidgets('fenetre redimensionnee : 390 -> 1440 -> 390, reessais '
        'epuises gardes', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(390, 2400), port: enEchec);
      expect(_largeurUtile(tester), lessThan(seuilDeuxColonnesAccueil));
      await epuiser(tester);
      final State<StatefulWidget> avant = tester.state(bloc);

      tester.view.physicalSize = const Size(1440, 2400);
      await stabiliser(tester);
      expect(
        _largeurUtile(tester),
        greaterThanOrEqualTo(seuilDeuxColonnesAccueil),
      );
      memeBloc(tester, avant);

      tester.view.physicalSize = const Size(390, 2400);
      await stabiliser(tester);
      expect(_largeurUtile(tester), lessThan(seuilDeuxColonnesAccueil));
      memeBloc(tester, avant);
      expect(tester.takeException(), isNull);
    });

    testWidgets('facteur de texte change a 1440 : 100 % -> 200 % -> 100 %, '
        'reessais epuises gardes', (WidgetTester tester) async {
      final ValueNotifier<double> facteur = ValueNotifier<double>(1);
      addTearDown(facteur.dispose);
      await _monter(
        tester,
        taille: const Size(1440, 3200),
        port: enEchec,
        echelleVariable: facteur,
      );
      await epuiser(tester);
      final State<StatefulWidget> avant = tester.state(bloc);

      facteur.value = 2;
      await stabiliser(tester);
      expect(
        _largeurUtile(tester) / 2,
        lessThan(seuilDeuxColonnesAccueil),
        reason: 'une colonne a 200 %',
      );
      memeBloc(tester, avant);

      facteur.value = 1;
      await stabiliser(tester);
      memeBloc(tester, avant);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chargement : la minuterie de perte court a travers le '
        'seuil, elle ne repart pas de zero', (WidgetTester tester) async {
      final Completer<DonneesAccueilAccessibilite> attente =
          Completer<DonneesAccueilAccessibilite>();
      await _monter(
        tester,
        taille: const Size(1440, 2400),
        port: _PortEnAttente(attente.future),
        attendre: false,
      );
      // Le routeur monte l'Accueil : le bloc nait, ses minuteries partent.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(AccueilAccessibilite.cleSquelette), findsOneWidget);
      final Duration moitie = AppDelais.requeteMax ~/ 2;
      await tester.pump(moitie);
      expect(find.byKey(AccueilAccessibilite.cleSquelette), findsOneWidget);
      final State<StatefulWidget> avant = tester.state(bloc);

      // Le seuil est franchi a mi-attente.
      tester.view.physicalSize = const Size(390, 2400);
      await tester.pump();
      expect(find.byKey(AccueilAccessibilite.cleSquelette), findsOneWidget);

      // L'autre moitie ecoulee : la tentative est perdue, comme si la
      // fenetre n'avait pas bouge.
      await tester.pump(moitie + const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(AccueilAccessibilite.cleSquelette), findsNothing);
      expect(reessayer, findsOneWidget);
      expect(identical(tester.state(bloc), avant), isTrue);
      attente.complete(_contenu.lire());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Aucun mot coupe (lecon 8), deux colonnes et une, LTR et RTL', () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('contenu, 320 x2 (une colonne) puis 1440 (deux), '
          '${sens.name}', (WidgetTester tester) async {
        await _monter(
          tester,
          taille: const Size(320, 3200),
          echelle: 2,
          sens: sens,
        );
        _verifierUneColonne(tester);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);

        await _monter(tester, taille: const Size(1440, 3200), sens: sens);
        _verifierDeuxColonnes(tester, sens);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
