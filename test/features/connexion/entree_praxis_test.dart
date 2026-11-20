// ENTREE-PRAXIS (directeur, 20/11/2026, maquette « Praxis vous accueille »
// confirmee) : la page d'entree posee sur la scene de Praxis.
//
// Ce que le test prouve :
// - **la verification anti-robot reste peinte et atteignable** : aucun
//   ancetre de la case n'a une opacite nulle, a aucun moment de la scene ;
//   le calque de Praxis ne la recouvre pas ; un toucher en son centre
//   l'atteint (telephone et ordinateur, francais et arabe) ;
// - la scene ne tourne pas en continu : Praxis s'endort, et sous « Reduire
//   les effets » plus rien ne bouge apres son arrivee ;
// - la situation jouee suit l'etat reel de la page (arrivee, saisie, adresse
//   fautive, envoi, lien envoye, echec, hors connexion, session coupee,
//   candidat) ;
// - le rendu : un seul bouton plein, rien ne se chevauche, la carte au bord
//   de fin sur ordinateur (au bord de debut en arabe), aucun debordement a
//   320 px et en texte x2 ;
// - la page se ferme au milieu d'une scene sans rien laisser derriere elle.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/anti_robot.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/controle_anti_robot.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/coquille_praxis.dart';
import 'package:rewayah_academy/features/connexion/scenes_entree.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../support/garde_interface.dart';

const ValueKey<String> _cleCourriel = ValueKey<String>('connexion-courriel');
const ValueKey<String> _cleCalque = ValueKey<String>('entree-praxis-calque');

class _Cle implements PortCleTurnstile {
  @override
  Future<String?> lire() async => '0xCleDuSite';
}

class _Controleur extends ControleurAntiRobot {
  _Controleur() {
    recevoirJeton('jeton-1');
  }
}

class _Auth implements ServiceAuth {
  _Auth({this.echec, this.attente});
  final Exception? echec;
  final Completer<void>? attente;
  int envois = 0;

  @override
  Future<void> envoyerLienCourriel(String courriel, {String? jetonControle}) {
    envois++;
    final Exception? e = echec;
    if (e != null) throw e;
    return attente?.future ?? Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Reseau implements ServiceReseau {
  _Reseau(this.flux);
  final Stream<bool> flux;
  @override
  Stream<bool> horsLigne() => flux;
}

Future<void> _monter(
  WidgetTester tester, {
  _Auth? auth,
  Size vue = const Size(390, 844),
  double texte = 1,
  bool sombre = false,
  TextDirection sens = TextDirection.ltr,
  bool controle = false,
  bool reduit = false,
  Stream<bool>? reseau,
  Uri? adresse,
}) async {
  tester.view.physicalSize = vue;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceAuthProvider.overrideWithValue(auth ?? _Auth()),
        serviceReseauProvider.overrideWithValue(
          _Reseau(reseau ?? Stream<bool>.value(false)),
        ),
        demoAuthActiveProvider.overrideWithValue(false),
        if (controle) ...<Override>[
          portCleTurnstileProvider.overrideWithValue(_Cle()),
          fabriqueControleurAntiRobotProvider.overrideWithValue(
            _Controleur.new,
          ),
        ],
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: sombre ? ThemeMode.dark : ThemeMode.light,
          builder: (BuildContext context, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(texte),
              disableAnimations: reduit,
            ),
            child: Directionality(textDirection: sens, child: enfant!),
          ),
          home: ConnexionPage(
            urlRetour: adresse ?? Uri.parse('https://exemple.test/connexion'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _passer(WidgetTester tester, int millisecondes) async {
  for (int i = 0; i < millisecondes ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

SituationEntree _situation(WidgetTester tester) =>
    tester.widget<CoquillePraxis>(find.byType(CoquillePraxis)).situation;

CoquillePraxisState _etat(WidgetTester tester) =>
    tester.state<CoquillePraxisState>(find.byType(CoquillePraxis));

Finder get _plein => find.byWidgetPredicate(
  (Widget w) => w is ActionPrincipale && w.niveau == NiveauAction.principale,
);

Future<void> _envoyer(WidgetTester tester, String adresse) async {
  await tester.enterText(find.byKey(_cleCourriel), adresse);
  await tester.pump();
  tester.widget<ActionPrincipale>(_plein).onPress!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Aucun ancetre de [cible] ne la rend invisible.
void _verifierPeinte(WidgetTester tester, Finder cible) {
  tester.element(cible).visitAncestorElements((Element ancetre) {
    final Widget w = ancetre.widget;
    if (w is Opacity) {
      expect(w.opacity, greaterThan(0), reason: 'Opacity nulle au-dessus');
    }
    if (w is FadeTransition) {
      expect(w.opacity.value, greaterThan(0), reason: 'fondu nul au-dessus');
    }
    if (w is AnimatedOpacity) {
      expect(w.opacity, greaterThan(0), reason: 'opacite animee nulle');
    }
    if (w is Offstage) {
      expect(w.offstage, isFalse, reason: 'hors scene');
    }
    if (w is Visibility) {
      expect(w.visible, isTrue, reason: 'invisible');
    }
    return true;
  });
}

/// Au centre de [cible], ce qui recoit le toucher appartient a la feuille du
/// formulaire : rien de la scene (calque de Praxis, decor) ne la recouvre.
void _verifierAtteinte(WidgetTester tester, Finder cible) {
  final RenderBox boite = tester.renderObject<RenderBox>(cible);
  final Offset centre = boite.localToGlobal(boite.size.center(Offset.zero));
  final RenderObject feuille = tester.renderObject(
    find.ancestor(of: cible, matching: find.byType(DecoratedBox)).first,
  );
  final HitTestResult touche = tester.hitTestOnBinding(centre);
  final Object devant = touche.path.first.target;
  RenderObject? r = devant is RenderObject ? devant : null;
  bool dansLaFeuille = false;
  while (r != null) {
    if (identical(r, feuille)) dansLaFeuille = true;
    r = r.parent;
  }
  expect(
    dansLaFeuille,
    isTrue,
    reason: 'la case de verification est recouverte par ${devant.runtimeType}',
  );
}

void main() {
  tearDown(() => sessionTermineeParLeServeur.value = false);

  group('la verification anti-robot reste peinte et atteignable', () {
    for (final Size vue in <Size>[const Size(390, 844), const Size(1440, 900)]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${vue.width.toInt()} px, ${sens.name}', (
          WidgetTester tester,
        ) async {
          await _monter(tester, vue: vue, sens: sens, controle: true);
          final Finder caseControle = find.byKey(ControleAntiRobot.cleControle);
          // A chaque moment de l'arrivee de Praxis, puis au repos.
          for (int i = 0; i < 180; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            if (i % 10 != 0) continue;
            expect(find.byType(ControleAntiRobot), findsOneWidget);
            _verifierPeinte(tester, caseControle);
            // Le calque de Praxis ne passe pas sur la case.
            final Rect calque = tester.getRect(find.byKey(_cleCalque));
            final Rect controle = tester.getRect(caseControle);
            expect(
              calque.intersect(controle).width <= 0 ||
                  calque.intersect(controle).height <= 0,
              isTrue,
              reason: 'le calque de la scene recouvre la case',
            );
            // Sous le bouton principal, comme avant.
            expect(
              controle.top,
              greaterThanOrEqualTo(tester.getRect(_plein).bottom - 0.5),
            );
          }
          await tester.ensureVisible(caseControle);
          await tester.pump();
          _verifierAtteinte(tester, caseControle);
          // Pendant un envoi et apres lui, toujours la.
          await _envoyer(tester, 'fatou@example.test');
          await _passer(tester, 3000);
          expect(find.byType(ControleAntiRobot), findsOneWidget);
          _verifierPeinte(tester, find.byType(ControleAntiRobot));
          final Rect calque = tester.getRect(find.byKey(_cleCalque));
          final Rect controle = tester.getRect(find.byType(ControleAntiRobot));
          expect(
            calque.intersect(controle).width <= 0 ||
                calque.intersect(controle).height <= 0,
            isTrue,
          );
        });
      }
    }
  });

  group('la scene ne tourne pas en continu', () {
    testWidgets('Praxis arrive, parle, puis s endort', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(_etat(tester).regie.eveillee, isTrue);
      // Le champ et le bouton sont la des la premiere image.
      expect(find.byKey(_cleCourriel), findsOneWidget);
      expect(_plein, findsOneWidget);
      await _passer(tester, 30000);
      expect(_etat(tester).regie.eveillee, isFalse);
      expect(tester.hasRunningAnimations, isFalse);
      // Un toucher sur lui le reveille.
      final Offset praxis = _etat(tester).regie.th.centrePraxis;
      await tester.tapAt(praxis);
      await tester.pump();
      expect(_etat(tester).regie.eveillee, isTrue);
      await _passer(tester, 15000);
      expect(_etat(tester).regie.eveillee, isFalse);
    });

    testWidgets('mouvement reduit : pose d un coup, plus rien ne bouge', (
      WidgetTester tester,
    ) async {
      await _monter(tester, reduit: true);
      await _passer(tester, 800);
      // Il est deja au premier plan, sans marche.
      expect(_etat(tester).regie.th.px.q, moreOrLessEquals(1, epsilon: 0.01));
      // Ses phrases se disent encore ; puis l'horloge s'arrete.
      await _passer(tester, 12000);
      expect(_etat(tester).regie.eveillee, isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('application en arriere-plan : l horloge s arrete', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(_etat(tester).regie.eveillee, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      expect(_etat(tester).regie.eveillee, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(_etat(tester).regie.eveillee, isTrue);
    });

    testWidgets('la page se ferme au milieu d une scene', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _passer(tester, 2000);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('la situation suit l etat de la page', () {
    testWidgets('arrivee, saisie, adresse fautive', (WidgetTester tester) async {
      final _Auth auth = _Auth();
      await _monter(tester, auth: auth);
      expect(_situation(tester), SituationEntree.arrivee);
      await tester.enterText(find.byKey(_cleCourriel), 'ami');
      await tester.pump();
      expect(_situation(tester), SituationEntree.saisie);
      await _envoyer(tester, 'amina.exemple.com');
      expect(_situation(tester), SituationEntree.adresse);
      expect(auth.envois, 0);
      expect(find.text(t.connexion.erreurCourriel), findsOneWidget);
      await _passer(tester, 20000);
    });

    testWidgets('envoi en cours puis lien envoye', (WidgetTester tester) async {
      final Completer<void> attente = Completer<void>();
      await _monter(tester, auth: _Auth(attente: attente));
      await _envoyer(tester, 'amina.b@exemple.com');
      expect(_situation(tester), SituationEntree.envoi);
      attente.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_situation(tester), SituationEntree.envoye);
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
      await _passer(tester, 20000);
    });

    for (final (String nom, Exception echec, SituationEntree attendue)
        in <(String, Exception, SituationEntree)>[
          (
            'trop de demandes',
            const AuthException('trop', statusCode: '429'),
            SituationEntree.tropEssais,
          ),
          (
            'panne du serveur',
            const AuthException('panne', statusCode: '500'),
            SituationEntree.serveur,
          ),
          (
            'adresse sans invitation',
            const AuthException('Signups not allowed for otp'),
            SituationEntree.sansInvitation,
          ),
        ]) {
      testWidgets('echec : $nom', (WidgetTester tester) async {
        await _monter(tester, auth: _Auth(echec: echec));
        await _envoyer(tester, 'amina.b@exemple.com');
        expect(_situation(tester), attendue);
        await _passer(tester, 20000);
      });
    }

    testWidgets('hors connexion : la porte s eteint, puis se rallume', (
      WidgetTester tester,
    ) async {
      final StreamController<bool> reseau = StreamController<bool>();
      addTearDown(reseau.close);
      reseau.add(false);
      await _monter(tester, reseau: reseau.stream);
      await _passer(tester, 3000);
      reseau.add(true);
      await tester.pump();
      await tester.pump();
      expect(_situation(tester), SituationEntree.horsLigne);
      await _passer(tester, 6000);
      expect(_etat(tester).regie.th.eclat.cible, lessThan(0.5));
      reseau.add(false);
      await tester.pump();
      await tester.pump();
      expect(_situation(tester), SituationEntree.retourLigne);
      await _passer(tester, 8000);
      expect(_etat(tester).regie.th.eclat.cible, moreOrLessEquals(1));
    });

    testWidgets('session coupee par le serveur', (WidgetTester tester) async {
      sessionTermineeParLeServeur.value = true;
      await _monter(tester);
      expect(_situation(tester), SituationEntree.session);
      await _passer(tester, 20000);
    });

    testWidgets('candidat : la scene d arrivee, son titre, une seule action', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: Uri.parse(
          'https://exemple.test/connexion?mode=creer&candidature=1',
        ),
      );
      expect(_situation(tester), SituationEntree.arrivee);
      expect(find.text(t.connexion.candidat.titre), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('connexion-mode')),
        findsNothing,
      );
      await _passer(tester, 20000);
    });
  });

  group('le rendu', () {
    for (final Size vue in <Size>[
      const Size(320, 640),
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final double texte in <double>[1, 2]) {
        for (final bool sombre in <bool>[false, true]) {
          for (final TextDirection sens in TextDirection.values) {
            testWidgets('${vue.width.toInt()} px, texte x$texte, '
                '${sombre ? 'sombre' : 'clair'}, ${sens.name}', (
              WidgetTester tester,
            ) async {
              await _monter(
                tester,
                vue: vue,
                texte: texte,
                sombre: sombre,
                sens: sens,
              );
              await _passer(tester, 1500);
              expect(tester.takeException(), isNull);
              verifierUnSeulBoutonPlein(tester);
              verifierSansChevauchement(tester, <Finder>[
                find.byKey(const ValueKey<String>('connexion-titre')),
                find.byType(TextField),
                _plein,
              ]);
              // Le bouton a la largeur du champ.
              expect(
                tester.getSize(_plein).width,
                moreOrLessEquals(tester.getSize(find.byType(TextField)).width),
              );
              final Rect champ = tester.getRect(find.byType(TextField));
              expect(champ.left, greaterThanOrEqualTo(0));
              expect(champ.right, lessThanOrEqualTo(vue.width));
              if (vue.width / texte >= 840) {
                // La carte au bord de fin : a gauche en arabe.
                if (sens == TextDirection.ltr) {
                  expect(champ.center.dx, greaterThan(vue.width / 2));
                } else {
                  expect(champ.center.dx, lessThan(vue.width / 2));
                }
                // La scene prend tout l'ecran derriere elle.
                expect(
                  tester.getSize(find.byType(CustomPaint).first).width,
                  greaterThan(0),
                );
              } else {
                // Telephone : le titre est sous la scene, la scene garde au
                // moins 38 % de la hauteur.
                final double titre = tester
                    .getTopLeft(
                      find.byKey(const ValueKey<String>('connexion-titre')),
                    )
                    .dy;
                expect(titre, greaterThan(vue.height * 0.38 - 26));
              }
              await _passer(tester, 18000);
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    }
  });
}
