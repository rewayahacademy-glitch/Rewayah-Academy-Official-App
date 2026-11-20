// Lot RACINE (PE-D8, PE-D9, PE-D11 ; directeur, 19/11/2026) : rien ne
// pousse la page, la mise a jour se propose, la selection redevient normale,
// les champs prennent le sens du texte tape.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/fraicheur/avis_flottant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/version/bandeau_nouvelle_version.dart';
import 'package:rewayah_academy/core/version/nouvelle_version.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/champ_recherche.dart';
import 'package:rewayah_academy/core/widgets/selection_racine.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';
import 'package:rewayah_academy/features/com_messages/bandeau_messages_hors_direct.dart';

import '../../capture/outil_capture.dart';

/// Une version nouvelle, deja vue.
class _VersionNouvelle extends SurveillanceVersion {
  @override
  bool build() => true;
}

/// Les messages hors direct, sans canal.
class _VeilleTombee extends EtatVeilleMessagesControleur {
  @override
  EtatVeilleMessages build() => const EtatVeilleMessages(enDirect: false);
}

const Key _cleContenu = ValueKey<String>('contenu');

/// Un ecran sous la couche des avis : un titre tout en haut, a toucher.
Widget _ecran({List<Widget> avis = const <Widget>[], VoidCallback? onTitre}) =>
    CoucheAvis(
      avis: avis,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              ActionPrincipale(
                key: _cleContenu,
                libelle: 'Titre',
                onPress: onTitre ?? () {},
                pleineLargeur: false,
              ),
            ],
          ),
        ),
      ),
    );

void main() {
  group('PE-D11 : plus de selection globale', () {
    test('la racine ne pose plus de SelectionArea', () {
      final String source = File('lib/app.dart').readAsStringSync();
      expect(source.contains('SelectionRacine('), isFalse);
      expect(source.contains('SelectionArea('), isFalse);
    });

    testWidgets('un appui long sur un bouton n\'ouvre aucun menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteCapture(_ecran()));
      await tester.longPress(find.byKey(_cleContenu));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableRegion), findsNothing);
      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
    });

    testWidgets('TexteSelectionnable : le texte se copie, toucher ailleurs '
        'efface la selection', (WidgetTester tester) async {
      String copie = '';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            copie =
                (appel.arguments as Map<Object?, Object?>)['text']! as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        hoteCapture(
          const Scaffold(
            body: Column(
              children: <Widget>[
                TexteSelectionnable(child: Text('Assalamu alaykum')),
                SizedBox(height: 200, width: 200, key: _cleContenu),
              ],
            ),
          ),
        ),
      );
      final SelectableRegionState region = tester.state(
        find.byType(SelectableRegion),
      );
      // Le focus d'abord, comme un appui long : la zone peut le prendre.
      await tester.longPress(find.text('Assalamu alaykum'));
      await tester.pump();
      region.selectAll();
      await tester.pump();
      region.contextMenuButtonItems
          .singleWhere(
            (ContextMenuButtonItem b) => b.type == ContextMenuButtonType.copy,
          )
          .onPressed!
          .call();
      await tester.pump();
      expect(copie, 'Assalamu alaykum');
      region.selectAll();
      await tester.pump();
      // Le noeud de focus de la zone se laisse prendre (l'ancien global avait
      // `canRequestFocus: false` : sa selection ne s'effacait jamais). Sur le
      // web, toucher hors de la zone lui retire le focus (`TapRegion` du
      // SDK) ; ici, on retire le focus directement.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(FocusManager.instance.primaryFocus, isNotNull);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(
        region.contextMenuButtonItems.any(
          (ContextMenuButtonItem b) => b.type == ContextMenuButtonType.copy,
        ),
        isFalse,
        reason: 'perdre le focus efface la selection',
      );
    });
  });

  group('PE-D11 : le sens du texte tape', () {
    testWidgets('recherche : arabe de droite a gauche, latin de gauche a '
        'droite, recalcule a la frappe', (WidgetTester tester) async {
      final TextEditingController c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        hoteCapture(
          Scaffold(
            body: ChampRecherche(
              controleur: c,
              libelle: 'Rechercher',
              aide: 'Un nom',
            ),
          ),
        ),
      );
      TextDirection? sens() =>
          tester.widget<TextField>(find.byType(TextField)).textDirection;
      expect(sens(), TextDirection.ltr);
      await tester.enterText(find.byType(TextField), 'يوسف');
      await tester.pump();
      expect(sens(), TextDirection.rtl);
      await tester.enterText(find.byType(TextField), 'Youssef');
      await tester.pump();
      expect(sens(), TextDirection.ltr);
    });

    testWidgets('champ d\'un message : sens de la frappe', (
      WidgetTester tester,
    ) async {
      final TextEditingController c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        hoteCapture(
          Scaffold(body: ZoneSaisie(controleur: c, sensDeLaFrappe: true)),
        ),
      );
      TextDirection? sens() =>
          tester.widget<TextField>(find.byType(TextField)).textDirection;
      await tester.enterText(find.byType(TextField), 'السلام عليكم');
      await tester.pump();
      expect(sens(), TextDirection.rtl);
      await tester.enterText(find.byType(TextField), 'Bonjour');
      await tester.pump();
      expect(sens(), TextDirection.ltr);
    });
  });

  group('PE-D8 : rien ne pousse la page', () {
    testWidgets('l\'avis flotte par-dessus : le contenu ne bouge pas, et se '
        'ferme seul', (WidgetTester tester) async {
      await tester.pumpWidget(
        hoteCapture(_ecran(avis: const <Widget>[BandeauAvisEphemere()])),
      );
      final Offset avant = tester.getTopLeft(find.byKey(_cleContenu));
      ProviderScope.containerOf(
        tester.element(find.byType(BandeauAvisEphemere)),
      ).read(avisEphemereProvider.notifier).dire(t.com.messages.direct.nouveau);
      await tester.pumpAndSettle();
      expect(find.text(t.com.messages.direct.nouveau), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(_cleContenu)), avant);
      await tester.pump(AppMouvement.retourLocalMaintien);
      await tester.pumpAndSettle();
      expect(find.text(t.com.messages.direct.nouveau), findsNothing);
    });

    testWidgets('l\'avis se ferme en le glissant vers le haut', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteCapture(_ecran(avis: const <Widget>[BandeauAvisEphemere()])),
      );
      ProviderScope.containerOf(
        tester.element(find.byType(BandeauAvisEphemere)),
      ).read(avisEphemereProvider.notifier).dire('Avis');
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(AvisFlottant.cleGlisser),
        const Offset(0, -200),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Avis'), findsNothing);
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(BandeauAvisEphemere)),
        ).read(avisEphemereProvider),
        isNull,
      );
    });

    testWidgets('Echap ferme l\'avis (contrat §9)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteCapture(_ecran(avis: const <Widget>[BandeauAvisEphemere()])),
      );
      ProviderScope.containerOf(
        tester.element(find.byType(BandeauAvisEphemere)),
      ).read(avisEphemereProvider.notifier).dire('Avis');
      await tester.pumpAndSettle();
      expect(find.text('Avis'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Avis'), findsNothing);
    });

    testWidgets('« Messages pas en direct » : un signe qui se masque', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteCapture(
          const Scaffold(body: BandeauMessagesHorsDirect()),
          surcharges: <Override>[
            etatVeilleMessagesProvider.overrideWith(_VeilleTombee.new),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.byKey(BandeauMessagesHorsDirect.cle), findsOneWidget);
      await tester.tap(find.byKey(BandeauMessagesHorsDirect.cleMasquer));
      await tester.pump();
      expect(find.byKey(BandeauMessagesHorsDirect.cle), findsNothing);
    });
  });

  group('PE-D9 : la mise a jour se propose', () {
    test('mise a jour au retour : apres une vraie absence, hors seance', () {
      bool decide({
        bool remise = true,
        Duration absence = absenceAvantMiseAJour,
        bool enSeance = false,
      }) => miseAJourAuRetour(
        nouvelle: true,
        remise: remise,
        absence: absence,
        enSeance: enSeance,
      );
      expect(decide(), isTrue);
      expect(decide(remise: false), isFalse);
      expect(decide(absence: const Duration(minutes: 2)), isFalse);
      expect(decide(enSeance: true), isFalse);
    });

    Future<ProviderContainer> monter(
      WidgetTester tester, {
      required VoidCallback recharger,
      required DateTime Function() maintenant,
    }) async {
      await tester.pumpWidget(
        hoteCapture(
          _ecran(
            avis: <Widget>[
              BandeauNouvelleVersion(
                recharger: recharger,
                maintenant: maintenant,
              ),
            ],
          ),
          surcharges: <Override>[
            nouvelleVersionProvider.overrideWith(_VersionNouvelle.new),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(BandeauNouvelleVersion)),
      );
    }

    testWidgets('« Mettre a jour » recharge', (WidgetTester tester) async {
      int recharges = 0;
      await monter(
        tester,
        recharger: () => recharges++,
        maintenant: DateTime.now,
      );
      expect(find.text(t.miseAJour.prete), findsOneWidget);
      await tester.tap(find.byKey(BandeauNouvelleVersion.cleMettre));
      expect(recharges, 1);
    });

    testWidgets('« Plus tard » range l\'avis ; il ne revient pas ; retour '
        'apres une vraie absence : mise a jour', (WidgetTester tester) async {
      int recharges = 0;
      DateTime horloge = DateTime(2026, 11, 20, 9);
      await monter(
        tester,
        recharger: () => recharges++,
        maintenant: () => horloge,
      );
      await tester.tap(find.byKey(BandeauNouvelleVersion.clePlusTard));
      await tester.pumpAndSettle();
      expect(find.text(t.miseAJour.prete), findsNothing);

      // Absence courte : rien.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      horloge = horloge.add(const Duration(minutes: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(recharges, 0);
      expect(find.text(t.miseAJour.prete), findsNothing);

      // Vraie absence : la mise a jour se fait seule.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      horloge = horloge.add(absenceAvantMiseAJour);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(recharges, 1);
    });
  });
}
