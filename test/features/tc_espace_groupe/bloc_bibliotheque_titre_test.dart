// BLOC-BIB-1 (revue BENTO-3b-R, C5 et m2) : a texte double, le titre de
// la section Bibliotheque (« Ressources de la classe » sur l'accueil adulte,
// « Ressources recentes » sur l'Espace Classe enseignant) garde la taille des autres titres
// de section et passe a la ligne entre les mots ; il n'est plus reduit en
// bloc. « Voir tout » est place comme celui des « Dernieres seances » :
// sous le titre, au bord de debut.
//
// La taille mesuree est la taille RENDUE : taille de police x echelle du
// texte du paragraphe x echelle de la transformation jusqu'a l'ecran (une
// reduction en bloc par `FittedBox` n'apparait que dans cette derniere).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart'
    show EnteteVoirTout;
import 'package:rewayah_academy/features/demo/classe_demo.dart'
    show EtatDemoClasse;
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

/// Le paragraphe rendu dont le texte est exactement [texte], sous [ou].
RenderParagraph _paragraphe(WidgetTester tester, Finder ou, String texte) {
  final List<RenderParagraph> trouves = <RenderParagraph>[];
  void visiter(RenderObject r) {
    if (r is RenderParagraph && r.text.toPlainText() == texte) trouves.add(r);
    r.visitChildren(visiter);
  }

  for (final Element e in ou.evaluate()) {
    final RenderObject? r = e.renderObject;
    if (r != null) visiter(r);
  }
  expect(trouves, hasLength(1), reason: 'un seul paragraphe « $texte »');
  return trouves.single;
}

/// La taille de police a l'ecran, en pixels logiques : l'echelle de la
/// transformation est lue sur la largeur rendue (la matrice garde 1 sur
/// l'axe z, son maximum ne dit rien d'une reduction a plat).
double _tailleRendue(RenderParagraph p) {
  final double police = p.text.style?.fontSize ?? 14;
  final Rect rendu = MatrixUtils.transformRect(
    p.getTransformTo(null),
    Offset.zero & p.size,
  );
  final double transformation = rendu.width / p.size.width;
  return p.textScaler.scale(police) * transformation;
}

/// Les lignes du paragraphe (une ligne par boite de hauteur distincte).
int _lignes(RenderParagraph p) {
  final List<TextBox> boites = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
  );
  return boites.map((TextBox b) => b.top.round()).toSet().length;
}

Future<void> _monter(
  WidgetTester tester,
  String adresse,
  double largeur,
  TextDirection sens,
) async {
  tester.view.physicalSize = Size(largeur, 4400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: <RouteBase>[...routesDemoAdulte('dev'), ...routesDemoClasse('dev')],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext c, Widget? app) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(textDirection: sens, child: app!),
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Les mesures de texte n'ont de sens qu'avec les vraies polices.
  setUpAll(chargerPolicesDuDepot);

  for (final double largeur in const <double>[320, 390]) {
    for (final TextDirection sens in TextDirection.values) {
      final String cas = '${largeur.toInt()} px, texte x2, ${sens.name}';

      testWidgets('accueil adulte, $cas : « Ressources de la classe » a la '
          'taille de « Dernieres seances » et « Mon parcours », '
          '« Voir tout » dessous au meme bord', (WidgetTester tester) async {
        await _monter(
          tester,
          adresseDemoAdulte(EcranDemoAdulte.accueil),
          largeur,
          sens,
        );
        expect(tester.takeException(), isNull);
        final Finder bloc = find.byType(BlocBibliotheque);
        expect(bloc, findsOneWidget);
        final Finder ecran = find.byType(Scaffold).first;

        final RenderParagraph ressources = _paragraphe(
          tester,
          bloc,
          t.adulte.accueil.ressources,
        );
        final RenderParagraph dernieres = _paragraphe(
          tester,
          ecran,
          t.adulte.accueil.dernieresSeances,
        );
        final RenderParagraph parcours = _paragraphe(
          tester,
          ecran,
          t.adulte.accueil.parcours,
        );
        final double reference = _tailleRendue(dernieres);
        expect(_tailleRendue(parcours), closeTo(reference, 0.01));
        expect(_tailleRendue(ressources), closeTo(reference, 0.01));
        // Trois mots a cette taille : retour a la ligne, pas de reduction.
        expect(_lignes(ressources), greaterThan(1));
        verifierAucunMotCoupe(tester, bloc);

        // « Voir tout » : sous le titre, au bord de debut, comme celui des
        // dernieres seances.
        final Finder liens = find.text(t.tuteur.accueil.voirTout);
        expect(liens, findsNWidgets(2));
        final Finder lienRessources = find.descendant(
          of: bloc,
          matching: find.text(LibellesGroupe.bibliothequeVoirTout),
        );
        expect(lienRessources, findsOneWidget);
        final Finder lienDernieres = find.descendant(
          of: find.byType(EnteteVoirTout),
          matching: find.text(t.tuteur.accueil.voirTout),
        );
        final Rect titreR = MatrixUtils.transformRect(
          ressources.getTransformTo(null),
          Offset.zero & ressources.size,
        );
        final Rect lienR = tester.getRect(lienRessources);
        expect(lienR.top, greaterThanOrEqualTo(titreR.bottom));
        double debut(Rect r) => sens == TextDirection.ltr ? r.left : r.right;
        expect(
          debut(lienR),
          closeTo(debut(tester.getRect(lienDernieres)), 0.5),
        );
      });

      // L'Espace Groupe de l'eleve titre la section « Bibliotheque », un seul
      // mot qui tenait deja : l'ancienne reduction n'y etait pas visible.
      // L'Espace Classe de l'enseignant (EN-3) passe « Ressources recentes »
      // au meme bloc : c'est lui qui la montrait.
      testWidgets('Espace Classe enseignant, $cas : « Ressources recentes » a '
          'la taille de « Progression de la Classe »', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          adresseDemoClasse(RoleEntree.enseignant, EtatDemoClasse.aVenir),
          largeur,
          sens,
        );
        expect(tester.takeException(), isNull);
        final Finder bloc = find.byType(BlocBibliotheque);
        expect(bloc, findsOneWidget);
        final RenderParagraph titre = _paragraphe(
          tester,
          bloc,
          t.enseignant.ficheGroupe.ressourcesTitre,
        );
        final RenderParagraph progression = _paragraphe(
          tester,
          find.byType(Scaffold).first,
          t.enseignant.ficheGroupe.progressionTitre,
        );
        expect(_tailleRendue(titre), closeTo(_tailleRendue(progression), 0.01));
        verifierAucunMotCoupe(tester, bloc);
      });
    }
  }
}
