// COM-STU-2 : Le Studio, Aujourd'hui (`StudioTodayBoard`, COM-W00, COM-M04 ;
// spec section 7, section 8.1, section 17 COM-W00, section 23, section 25),
// rendu par la vraie `StudioPage` a son adresse `/admin/studio`. Mesures a
// 390, 768 et 1440, en francais et en arabe (RTL), clair et sombre, texte
// x2 ; etats avec activite, vide, chargement, erreur, hors ligne,
// indisponible ; R-COM-08 sur les lignes d'activite.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/communications/etats_communication.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/features/com_studio/activite.dart';
import 'package:rewayah_academy/features/com_studio/aujourdhui_page.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';

import '../../support/garde_interface.dart';
import 'support_studio.dart';

const Size _mobile = Size(390, 844);
const Size _tablette = Size(768, 1024);
const Size _bureau = Size(1440, 900);

/// L'activite de la demonstration, a l'heure fixe des tests.
ActiviteStudioDemo _activiteDemo({
  SituationDemoStudio situation = SituationDemoStudio.normale,
}) => ActiviteStudioDemo(situation: situation, maintenant: maintenantTest);

/// Une activite reglable : contenu, echec, attente.
class _FausseActivite implements PortActiviteStudio {
  _FausseActivite({
    this.lignes = const <ActiviteStudio>[],
    this.erreur,
    this.attente,
  });

  List<ActiviteStudio> lignes;
  Exception? erreur;
  Completer<void>? attente;
  int lectures = 0;

  @override
  Future<List<ActiviteStudio>> activites() async {
    lectures++;
    final Completer<void>? a = attente;
    if (a != null) await a.future;
    final Exception? e = erreur;
    if (e != null) throw e;
    return lignes;
  }

  @override
  Future<void> marquerLu(String activiteId) async {}
}

Future<void> _monterAujourdhui(
  WidgetTester tester, {
  PortActiviteStudio? activite,
  SituationDemoStudio situation = SituationDemoStudio.normale,
  Size taille = _bureau,
  AppLocale langue = AppLocale.fr,
  double echelleTexte = 1,
  Brightness luminosite = Brightness.light,
  bool horsLigne = false,
  bool stabiliser = true,
}) async {
  await monterStudio(
    tester,
    port: portDemo(situation: situation),
    depart: Routes.adminStudio,
    activite: activite ?? _activiteDemo(situation: situation),
    brouillons: brouillonsStudioDemo(situation),
    taille: taille,
    langue: langue,
    echelleTexte: echelleTexte,
    luminosite: luminosite,
    horsLigne: horsLigne,
    stabiliser: stabiliser,
  );
}

/// Les titres des sept blocs, dans l'ordre de la spec (section 7).
List<String> _titresBlocs() {
  final b = t.com.studio.aujourdhui.blocs;
  return <String>[
    b.aTraiter,
    b.mentions,
    b.decisions,
    b.echeances,
    b.activite,
    b.brouillons,
    b.acces,
  ];
}

int _valeurIndicateur(WidgetTester tester, String libelle) => tester
    .widget<StatTile>(
      find.byWidgetPredicate(
        (Widget w) => w is StatTile && w.libelle == libelle,
      ),
    )
    .valeur;

Finder _dansBloc(RubriqueAujourdhui r, Finder cible) => find.descendant(
  of: find.byKey(TableauAujourdhui.cleBloc(r)),
  matching: cible,
);

void main() {
  group("Aujourd'hui avec activite (spec section 7)", () {
    testWidgets("1440 : l'accueil du Studio, sept blocs en trois colonnes, "
        'les indicateurs au-dessus', (WidgetTester tester) async {
      await _monterAujourdhui(tester);
      expect(find.byType(TableauAujourdhui), findsOneWidget);
      final NavShell nav = tester.widget<NavShell>(find.byType(NavShell));
      expect(nav.indexActif, VueStudio.aujourdhui.index);
      expect(find.text(t.com.studio.aujourdhui.titre), findsWidgets);

      for (final String titre in _titresBlocs()) {
        expect(find.text(titre), findsWidgets, reason: titre);
      }
      // Trois colonnes fonctionnelles (COM-W00), de gauche a droite.
      for (int i = 0; i < 3; i++) {
        expect(find.byKey(TableauAujourdhui.cleColonne(i)), findsOneWidget);
      }
      final double x0 = tester
          .getTopLeft(find.byKey(TableauAujourdhui.cleColonne(0)))
          .dx;
      final double x1 = tester
          .getTopLeft(find.byKey(TableauAujourdhui.cleColonne(1)))
          .dx;
      final double x2 = tester
          .getTopLeft(find.byKey(TableauAujourdhui.cleColonne(2)))
          .dx;
      expect(x0 < x1 && x1 < x2, isTrue);
      // Les indicateurs sont au-dessus des blocs.
      expect(
        tester.getBottomLeft(find.byKey(TableauAujourdhui.cleIndicateurs)).dy,
        lessThan(
          tester.getTopLeft(find.byKey(TableauAujourdhui.cleColonne(0))).dy,
        ),
      );
      final i = t.com.studio.aujourdhui.indicateurs;
      expect(_valeurIndicateur(tester, i.aTraiter), 2);
      expect(_valeurIndicateur(tester, i.mentions), 2);
      expect(_valeurIndicateur(tester, i.decisions), 2);
      expect(_valeurIndicateur(tester, i.nonLus), 6);

      // Chaque ligne est dans SON bloc, une seule fois.
      expect(
        _dansBloc(
          RubriqueAujourdhui.aTraiter,
          find.text(
            'Paiement de septembre non confirmé pour la famille Haddad',
          ),
        ),
        findsOneWidget,
      );
      expect(
        _dansBloc(
          RubriqueAujourdhui.mentions,
          find.text('Samira vous a mentionnée'),
        ),
        findsOneWidget,
      );
      expect(
        _dansBloc(
          RubriqueAujourdhui.echeances,
          find.text('Clôture du mois de septembre'),
        ),
        findsOneWidget,
      );
      expect(find.text('Samira vous a mentionnée'), findsOneWidget);
      // Le brouillon de la demonstration, dans son bloc.
      expect(
        find.descendant(
          of: find.byKey(TableauAujourdhui.cleBrouillons),
          matching: find.text(
            t.com.studio.brouillons.dansCanal(nom: 'Admissions'),
          ),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      expect(
        verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) =>
              w is GroupeReglages || w is AppCard || w is StatTile,
        ),
        greaterThan(6),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets("l'urgence va en tete de A traiter, et le badge le dit en "
        'mots (jamais la couleur seule)', (WidgetTester tester) async {
      await _monterAujourdhui(tester);
      final double urgent = tester
          .getTopLeft(
            find.text(
              'Paiement de septembre non confirmé pour la famille Haddad',
            ),
          )
          .dy;
      final double dossier = tester
          .getTopLeft(
            find.text('Dossier de la famille Karim prêt pour une décision'),
          )
          .dy;
      expect(urgent, lessThan(dossier));
      expect(
        find.descendant(
          of: find.byKey(BoiteActivite.cleBadge('act-paiement')),
          matching: find.text(t.com.socle.composants.badge.urgent),
        ),
        findsOneWidget,
      );
      // Les echeances vont de la plus proche a la plus lointaine.
      expect(
        tester.getTopLeft(find.text('Clôture du mois de septembre')).dy,
        lessThan(
          tester.getTopLeft(find.text('Bilans de mi-parcours à relire')).dy,
        ),
      );
    });

    testWidgets('768 : deux colonnes', (WidgetTester tester) async {
      await _monterAujourdhui(tester, taille: _tablette);
      expect(find.byKey(TableauAujourdhui.cleColonne(0)), findsOneWidget);
      expect(find.byKey(TableauAujourdhui.cleColonne(1)), findsOneWidget);
      expect(find.byKey(TableauAujourdhui.cleColonne(2)), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : une colonne, les sept blocs dans l ordre de la spec, '
        'la barre basse du Studio', (WidgetTester tester) async {
      await _monterAujourdhui(tester, taille: _mobile);
      expect(find.byKey(TableauAujourdhui.cleColonne(0)), findsOneWidget);
      expect(find.byKey(TableauAujourdhui.cleColonne(1)), findsNothing);
      expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
      final Finder defilante = find.byType(Scrollable).first;
      double? precedent;
      for (final String titre in _titresBlocs()) {
        // Le titre du bloc, dans la colonne : ni l'indicateur ni la barre
        // basse, qui portent parfois le meme mot.
        final Finder f = find
            .descendant(
              of: find.byKey(TableauAujourdhui.cleColonne(0)),
              matching: find.text(titre),
            )
            .first;
        await tester.scrollUntilVisible(f, 200, scrollable: defilante);
        await tester.pumpAndSettle();
        // L'ordre se lit sur la position dans la colonne : chaque bloc
        // est sous le precedent (mesure dans le repere du contenu).
        final RenderBox boite = tester.renderObject<RenderBox>(f);
        final RenderBox colonne = tester.renderObject<RenderBox>(
          find.byKey(TableauAujourdhui.cleColonne(0)),
        );
        final double y = boite.localToGlobal(Offset.zero, ancestor: colonne).dy;
        if (precedent != null) expect(y, greaterThan(precedent), reason: titre);
        precedent = y;
      }
      expect(tester.takeException(), isNull);
    });

    for (final Size taille in <Size>[_mobile, _bureau]) {
      testWidgets('${taille.width.toInt()}, texte x2, sombre : rien ne '
          'deborde', (WidgetTester tester) async {
        await _monterAujourdhui(
          tester,
          taille: taille,
          echelleTexte: 2,
          luminosite: Brightness.dark,
        );
        expect(find.byType(TableauAujourdhui), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${taille.width.toInt()}, arabe (RTL) : la meme '
          'composition, en miroir', (WidgetTester tester) async {
        await _monterAujourdhui(tester, taille: taille, langue: AppLocale.ar);
        expect(
          Directionality.of(tester.element(find.byType(TableauAujourdhui))),
          TextDirection.rtl,
        );
        expect(find.text(t.com.studio.aujourdhui.blocs.aTraiter), findsWidgets);
        expect(t.com.studio.aujourdhui.blocs.aTraiter, 'للمعالجة اليوم');
        if (taille == _bureau) {
          // En arabe, la premiere colonne est a droite.
          expect(
            tester.getTopLeft(find.byKey(TableauAujourdhui.cleColonne(0))).dx,
            greaterThan(
              tester.getTopLeft(find.byKey(TableauAujourdhui.cleColonne(2))).dx,
            ),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('R-COM-08 : une ligne de canal absent n est jamais rendue', () {
    testWidgets('le port de demonstration ne la rend pas', (
      WidgetTester tester,
    ) async {
      final List<ActiviteStudio> lignes = await _activiteDemo().activites();
      expect(
        lignes.any((ActiviteStudio a) => a.objet.id == canalPriveAbsentDemo),
        isFalse,
      );
      await _monterAujourdhui(tester);
      expect(find.text('Budget confidentiel du trimestre'), findsNothing);
      expect(find.textContaining('Direction stratégique'), findsNothing);
    });

    testWidgets('un serveur defaillant qui la laisse passer : l ecran la '
        'retire seul', (WidgetTester tester) async {
      final _FausseActivite port = _FausseActivite(
        lignes: fixturesActiviteStudioDemo(maintenantTest),
      );
      await _monterAujourdhui(tester, activite: port);
      expect(find.text('Budget confidentiel du trimestre'), findsNothing);
      expect(find.textContaining('Direction stratégique'), findsNothing);
      expect(find.text('Samira vous a mentionnée'), findsOneWidget);
    });
  });

  group('Etats (spec section 25)', () {
    testWidgets("Aujourd'hui vide : la phrase de la spec, brouillons et "
        'acces rapides gardes, aucun indicateur', (WidgetTester tester) async {
      await _monterAujourdhui(
        tester,
        situation: SituationDemoStudio.aujourdhuiVide,
      );
      expect(find.byKey(TableauAujourdhui.cleEtat), findsOneWidget);
      expect(find.text(t.com.studio.aujourdhui.videTitre), findsOneWidget);
      expect(find.text(t.com.studio.vide), findsOneWidget);
      expect(find.text('Aucune activité à traiter ici.'), findsOneWidget);
      expect(find.byKey(TableauAujourdhui.cleIndicateurs), findsNothing);
      expect(find.byType(StatTile), findsNothing);
      expect(find.byKey(TableauAujourdhui.cleBrouillons), findsOneWidget);
      expect(find.text(t.com.studio.brouillons.vide), findsOneWidget);
      expect(find.byKey(TableauAujourdhui.cleAcces), findsOneWidget);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 vide : rien ne deborde', (WidgetTester tester) async {
      await _monterAujourdhui(
        tester,
        situation: SituationDemoStudio.aujourdhuiVide,
        taille: _mobile,
        echelleTexte: 2,
      );
      expect(find.text(t.com.studio.vide), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chargement : le squelette, puis le contenu', (
      WidgetTester tester,
    ) async {
      final _FausseActivite port = _FausseActivite(
        lignes: fixturesActiviteStudioDemo(maintenantTest),
        attente: Completer<void>(),
      );
      await _monterAujourdhui(tester, activite: port, stabiliser: false);
      expect(find.byKey(VueEtatCommunication.cleChargement), findsOneWidget);
      expect(find.byKey(TableauAujourdhui.cleIndicateurs), findsNothing);
      port.attente!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(VueEtatCommunication.cleChargement), findsNothing);
      expect(find.byKey(TableauAujourdhui.cleIndicateurs), findsOneWidget);
    });

    testWidgets('erreur : « Reessayer » relit, puis le contenu', (
      WidgetTester tester,
    ) async {
      final _FausseActivite port = _FausseActivite(
        lignes: fixturesActiviteStudioDemo(maintenantTest),
        erreur: Exception('reseau'),
      );
      await _monterAujourdhui(tester, activite: port);
      final e = t.com.socle.composants.etats;
      expect(find.text(e.erreurTitre), findsOneWidget);
      // L'erreur ne vide pas le reste : brouillons et acces restent.
      expect(find.byKey(TableauAujourdhui.cleAcces), findsOneWidget);
      port.erreur = null;
      await tester.tap(find.text(e.reessayer));
      await tester.pumpAndSettle();
      expect(port.lectures, 2);
      expect(find.text(e.erreurTitre), findsNothing);
      expect(find.text('Samira vous a mentionnée'), findsOneWidget);
    });

    testWidgets('hors ligne : le bandeau ; le contenu deja lu reste', (
      WidgetTester tester,
    ) async {
      await _monterAujourdhui(tester, horsLigne: true);
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsOneWidget);
      expect(find.text('Samira vous a mentionnée'), findsOneWidget);
    });

    testWidgets('hors ligne et lecture en echec : la connexion, avec '
        '« Reessayer »', (WidgetTester tester) async {
      await _monterAujourdhui(
        tester,
        activite: _FausseActivite(erreur: Exception('reseau')),
        horsLigne: true,
      );
      expect(
        find.descendant(
          of: find.byKey(TableauAujourdhui.cleEtat),
          matching: find.text(t.com.socle.composants.etats.reessayer),
        ),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.composants.etats.erreurTitre), findsNothing);
    });

    testWidgets('sans port branche (production) : « pas encore disponible », '
        'sans Reessayer ni ligne inventee', (WidgetTester tester) async {
      await monterStudio(tester, port: portDemo(), depart: Routes.adminStudio);
      final e = t.com.socle.composants.etats;
      expect(find.text(e.indisponibleTitre), findsOneWidget);
      expect(find.text(e.reessayer), findsNothing);
      expect(find.byType(StatTile), findsNothing);
      // Les acces rapides menent a des modules livres, ils restent.
      expect(find.byKey(TableauAujourdhui.cleAcces), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('le port neutre leve CapaciteIndisponible COM-BR-15', () async {
      const ActiviteStudioIndisponible port = ActiviteStudioIndisponible();
      await expectLater(
        port.activites(),
        throwsA(predicate((Object e) => e.toString().contains('COM-BR-15'))),
      );
      await expectLater(
        port.marquerLu('x'),
        throwsA(predicate((Object e) => e.toString().contains('COM-BR-15'))),
      );
    });
  });

  group("Le rangement d'Aujourd'hui", () {
    ActiviteStudio ligne(
      String id, {
      TypeActivite type = TypeActivite.changementModule,
      NiveauAttention niveau = NiveauAttention.information,
      bool actionRequise = false,
      DateTime? echeance,
      int ilYa = 0,
    }) => ActiviteStudio(
      id: id,
      type: type,
      module: ModuleCanonique.classes,
      libelle: id,
      survenueLe: maintenantTest.subtract(Duration(minutes: ilYa)),
      objet: ObjetLie(type: TypeObjetLie.classe, id: id, libelle: id),
      niveau: niveau,
      actionRequise: actionRequise,
      echeance: echeance,
    );

    test('chaque ligne va dans une seule rubrique', () {
      expect(
        ligne(
          'u',
          niveau: NiveauAttention.urgent,
          echeance: maintenantTest,
        ).rubrique,
        RubriqueAujourdhui.aTraiter,
      );
      expect(
        ligne(
          'd',
          type: TypeActivite.decisionDemandee,
          actionRequise: true,
        ).rubrique,
        RubriqueAujourdhui.decisions,
      );
      expect(
        ligne('m', type: TypeActivite.mention).rubrique,
        RubriqueAujourdhui.mentions,
      );
      expect(
        ligne('r', type: TypeActivite.reponse).rubrique,
        RubriqueAujourdhui.mentions,
      );
      expect(
        ligne('e', echeance: maintenantTest, actionRequise: true).rubrique,
        RubriqueAujourdhui.echeances,
      );
      expect(
        ligne('a', actionRequise: true).rubrique,
        RubriqueAujourdhui.aTraiter,
      );
      expect(ligne('x').rubrique, RubriqueAujourdhui.activite);
      final List<ActiviteStudio> toutes = fixturesActiviteStudioDemo(
        maintenantTest,
      );
      final Map<RubriqueAujourdhui, List<ActiviteStudio>> rangees =
          rangerActivites(toutes);
      expect(rangees.keys, RubriqueAujourdhui.values);
      expect(
        rangees.values.fold<int>(
          0,
          (int n, List<ActiviteStudio> l) => n + l.length,
        ),
        toutes.length,
      );
    });

    test('ordre : le plus pressant, puis le plus recent', () {
      final List<ActiviteStudio> r = rangerActivites(<ActiviteStudio>[
        ligne('ancien', actionRequise: true, ilYa: 60),
        ligne('recent', actionRequise: true, ilYa: 5),
        ligne('urgent', niveau: NiveauAttention.urgent, ilYa: 120),
      ])[RubriqueAujourdhui.aTraiter]!;
      expect(r.map((ActiviteStudio a) => a.id), <String>[
        'urgent',
        'recent',
        'ancien',
      ]);
    });

    test('une action requise se montre au moins « Action requise »', () {
      final ActiviteStudio a = ligne('a', actionRequise: true);
      expect(a.indicateur.niveau, NiveauAttention.actionRequise);
      expect(a.indicateur.nonLus, 1);
      expect(a.marqueeLue().indicateur.nonLus, 0);
    });

    test("une ligne d'un canal hors de la liste ouverte est retiree", () {
      final ActiviteStudio canal = ActiviteStudio(
        id: 'c',
        type: TypeActivite.mention,
        module: ModuleCanonique.studio,
        libelle: 'c',
        survenueLe: maintenantTest,
        objet: ObjetLie(type: TypeObjetLie.canal, id: 'secret', libelle: 's'),
      );
      expect(activitesRendues(<ActiviteStudio>[canal], <String>{}), isEmpty);
      expect(
        activitesRendues(<ActiviteStudio>[canal], <String>{'secret'}),
        hasLength(1),
      );
      // Sans liste lue, le serveur fait foi.
      expect(activitesRendues(<ActiviteStudio>[canal], null), hasLength(1));
    });

    test('libelle et icone de chaque module, legende sans destination', () {
      for (final ModuleCanonique m in ModuleCanonique.values) {
        expect(libelleModule(m), isNotEmpty);
      }
      final ActiviteStudio finance = fixturesActiviteStudioDemo(maintenantTest)
          .firstWhere((ActiviteStudio a) => a.id == 'act-paiement');
      expect(
        legendeActivite(finance),
        contains(
          t.com.studio.aujourdhui.seTraiteDans(
            module: t.com.studio.aujourdhui.modules.finance,
          ),
        ),
      );
    });
  });
}
