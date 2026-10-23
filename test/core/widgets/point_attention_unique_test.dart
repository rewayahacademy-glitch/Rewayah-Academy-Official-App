// SUPERPOS-1b (09/10/2026, reserve 2 de la relecture SUPERPOS-1-R2) : la
// regle « un seul point d'attention » sur les ecrans audites par SUPERPOS-1.
//
// La regle (SUPERPOS-1, decide par delegation le 05/10 ; `lib/CLAUDE.md` :
// « Une seule zone pleine par ecran : l'action principale. Alertes et badges
// prennent le registre doux ») : un ecran n'a qu'une zone pleine, son action
// principale ; le repere « Démonstration », le bandeau hors ligne, le
// bandeau d'observation et le bandeau d'alerte urgente sont au registre doux
// et dans le flux ; dans le fil de discussion, rien n'est plein (le seul
// element d'accent est l'icone d'envoi). La fiche SUPERPOS-1 la disait
// « conforme, lue dans le code et sur les captures, pas de test dedie ».
//
// Mesure sur le rendu : une zone pleine est une surface rendue d'au moins
// 24 x 24, peinte d'une couleur pleine du theme (aplats `surfacePrimary`,
// `surfaceActionDouce` du CTA, `surfaceSuccess`, `surfaceWarning`,
// `surfaceAlert`, `surfaceInverse`, et les couleurs vives du `ColorScheme`).
// Les pastilles et points d'etat, plus petits, ne sont pas des zones.
//
// Contre-epreuve faite le 09/10 : avec l'ancien repere (`Banner` d'angle en
// `colorScheme.tertiary`, tete `6e2c91c4`, d'avant SUPERPOS-1), les tests
// « apercu » echouent (deux zones pleines : le ruban et le bouton) ; le
// bandeau hors ligne ou celui d'observation repeint en `surfaceWarning`, ou
// le bandeau d'alerte urgente en `surfaceAlert` : 4 echecs sur 12 chacun
// (les quatre tests « apercu »).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bandeau_observation.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';
import 'package:rewayah_academy/features/alertes/bandeau_alerte_urgente.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

/// Taille, echelle du texte, sens, luminosite, interface.
typedef _Vue = (Size, double, TextDirection, Brightness, InterfaceMode);

const List<_Vue> _vues = <_Vue>[
  (
    Size(320, 640),
    2,
    TextDirection.ltr,
    Brightness.light,
    InterfaceMode.standard,
  ),
  (Size(320, 640), 2, TextDirection.rtl, Brightness.dark, InterfaceMode.enfant),
  (
    Size(390, 844),
    1,
    TextDirection.ltr,
    Brightness.light,
    InterfaceMode.enfant,
  ),
  (
    Size(1440, 900),
    1,
    TextDirection.ltr,
    Brightness.dark,
    InterfaceMode.standard,
  ),
];

String _nom(_Vue v) =>
    '${v.$1.width.toInt()} x${v.$2.toInt()} ${v.$3.name} ${v.$4.name} '
    '${v.$5.name}';

/// Les couleurs pleines du theme de [context].
Set<int> _couleursPleines(BuildContext context) {
  final AppPalette p = AppPalette.of(context);
  final ColorScheme s = Theme.of(context).colorScheme;
  return <Color>{
    p.surfacePrimary.background,
    p.surfaceActionDouce.background,
    p.surfaceSuccess.background,
    p.surfaceWarning.background,
    p.surfaceAlert.background,
    p.surfaceInverse.background,
    s.primary,
    s.secondary,
    s.tertiary,
    s.error,
    s.inverseSurface,
  }.map((Color c) => c.toARGB32()).toSet();
}

/// La couleur de fond que [w] peint, ou `null`.
Color? _fond(Widget w) => switch (w) {
  DecoratedBox(:final Decoration decoration) => switch (decoration) {
    BoxDecoration(:final Color? color) => color,
    ShapeDecoration(:final Color? color) => color,
    _ => null,
  },
  ColoredBox(:final Color color) => color,
  Material(:final MaterialType type, :final Color? color) =>
    type == MaterialType.transparency ? null : color,
  Banner(:final Color color) => color,
  Ink(:final Decoration? decoration) =>
    decoration is BoxDecoration ? decoration.color : null,
  _ => null,
};

/// Les zones pleines de l'ecran : tout ce qui est rendu (et non hors scene),
/// y compris sous la pliure, que l'on atteint en defilant.
List<Element> _zonesPleines(WidgetTester tester) {
  final BuildContext racine = tester.element(find.byType(Scaffold).first);
  final Set<int> pleines = _couleursPleines(racine);
  return find
      .byWidgetPredicate((Widget w) {
        final Color? c = _fond(w);
        return c != null && c.a > 0 && pleines.contains(c.toARGB32());
      })
      .evaluate()
      .where((Element e) {
        final RenderObject? r = e.renderObject;
        return r is RenderBox &&
            r.hasSize &&
            r.size.width >= 24 &&
            r.size.height >= 24;
      })
      .toList();
}

/// Au plus une zone pleine, et c'est l'action principale.
void _verifierUnPointDAttention(WidgetTester tester, {required int attendues}) {
  final List<Element> zones = _zonesPleines(tester);
  // Plusieurs widgets peuvent peindre la meme surface (un `Material` et son
  // `DecoratedBox`) : on compte les surfaces, par leur porteur.
  final Set<Element> surfaces = <Element>{
    for (final Element e in zones) _porteur(e) ?? e,
  };
  expect(
    surfaces.length,
    attendues,
    reason: 'zones pleines : ${zones.map((Element e) => e.widget.runtimeType)}',
  );
  for (final Element e in zones) {
    expect(
      _porteur(e),
      isNotNull,
      reason: '${e.widget.runtimeType} plein hors de l action principale',
    );
  }
}

/// L'`ActionPrincipale` qui contient [e], ou `null`.
Element? _porteur(Element e) {
  Element? trouve;
  e.visitAncestorElements((Element a) {
    if (a.widget is ActionPrincipale) {
      trouve = a;
      return false;
    }
    return true;
  });
  return trouve;
}

Future<void> _monter(WidgetTester tester, _Vue v, Widget page) async {
  tester.view.physicalSize = v.$1;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = v.$2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        alertesProvider.overrideWith(
          (Ref _) => Stream<List<Alerte>>.value(<Alerte>[
            Alerte(
              id: 'a1',
              gravite: GraviteAlerte.urgent,
              titre: 'Classe sans enseignant',
              creeeLe: DateTime(2026, 10, 9, 16, 50),
            ),
          ]),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(v.$5, v.$4),
          builder: (BuildContext _, Widget? enfant) => Directionality(
            textDirection: v.$3,
            child: RepereDemonstration(child: enfant),
          ),
          home: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final _Vue v in _vues) {
    testWidgets('${_nom(v)} : apercu, bandeaux et action principale : une '
        'seule zone pleine, l action principale', (WidgetTester tester) async {
      await _monter(
        tester,
        v,
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const OfflineBanner.message(
                    message:
                        'Les dossiers pourront être validés quand la '
                        'connexion reviendra.',
                  ),
                  const BandeauObservation(
                    observation: Observation(identiteMasquee: true),
                  ),
                  BandeauAlerteUrgente(onOuvrir: () {}),
                  const Text('Dossiers à valider'),
                  ActionPrincipale(libelle: 'Valider', onPress: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(RepereDemonstration.bandeKey), findsOneWidget);
      expect(find.byKey(BandeauAlerteUrgente.cle), findsOneWidget);
      _verifierUnPointDAttention(tester, attendues: 1);
    });

    testWidgets('${_nom(v)} : fil de discussion, texte saisi : aucune zone '
        'pleine', (WidgetTester tester) async {
      await _monter(
        tester,
        v,
        PageShell(
          titre: 'Classe Al-Badr',
          defilante: false,
          child: FilDiscussion(
            messages: const <MessageFil>[
              MessageFil(
                id: '1',
                auteur: 'Administration',
                texte: 'Merci, c est noté.',
                horodatage: '09:30',
                deSoi: false,
              ),
            ],
            textes: TextesFilDiscussion(
              aideChamp: 'Répondre à l administration…',
              libelleChamp: 'Répondre à l administration',
              envoyer: 'Envoyer',
              champVide: 'Écrivez un message pour pouvoir l envoyer.',
              enCours: 'Envoi en cours.',
              envoye: 'Envoyé.',
              echec: 'L envoi n est pas confirmé.',
              reessayer: 'Réessayer',
              auteurSoi: 'Vous',
              annonce: (String a, String t) => '$a : $t',
            ),
            onEnvoyer: (String _) async {},
          ),
        ),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(FilDiscussion.envoyerKey), findsOneWidget);
      _verifierUnPointDAttention(tester, attendues: 0);
    });

    testWidgets('${_nom(v)} : formulaire a zone de saisie : une seule zone '
        'pleine, l action principale', (WidgetTester tester) async {
      final TextEditingController motif = TextEditingController();
      addTearDown(motif.dispose);
      await _monter(
        tester,
        v,
        PageShell(
          titre: 'Refuser le dossier',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ZoneSaisie(
                controleur: motif,
                libelle: 'Motif du refus',
                explication: 'Le motif est envoyé à la famille.',
                erreur: 'Écrivez le motif avant d envoyer.',
                minLignes: 3,
              ),
              ActionPrincipale(libelle: 'Envoyer', onPress: () {}),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      _verifierUnPointDAttention(tester, attendues: 1);
    });
  }
}
