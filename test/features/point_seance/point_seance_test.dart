// POINT-DE-SEANCE (lot 6) : la page du point de fin de seance et l'historique
// des seances, sur le VRAI routeur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/point_seance/point_seance_supabase.dart';
import 'package:rewayah_academy/core/point_seance/port_point_seance.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/point_seance/historique_seances.dart';
import 'package:rewayah_academy/features/point_seance/point_seance_page.dart';

import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../historique/support_historique.dart';
import 'faux_point_seance.dart';

List<Override> _avec(FauxPointSeance faux) => <Override>[
  portPointSeanceProvider.overrideWithValue(faux),
  horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(false)),
];

Future<void> _ouvrir(
  WidgetTester tester,
  FauxPointSeance faux, {
  Size taille = const Size(390, 1600),
  double echelle = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  await monterRouteur(
    tester,
    Routes.pointSeancePour('s1'),
    source: FausseSourceSession(sessionActive(AppRole.teacher)),
    taille: taille,
    echelle: echelle,
    themeMode: theme,
    surcharges: _avec(faux),
  );
  await stabiliser(tester);
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  group('Point de fin de seance : la page', () {
    testWidgets('sans toucher pour l\'eleve tire, aucun bouton d\'envoi', (
      WidgetTester tester,
    ) async {
      final FauxPointSeance faux = FauxPointSeance(point: pointAFaireBrut());
      await _ouvrir(tester, faux);
      expect(find.byType(PointSeancePage), findsOneWidget);
      expect(find.text(t.pointSeance.titre), findsOneWidget);
      // L'eleve tire n'a pas de defaut : le bouton n'est pas rendu (jamais
      // grise), une phrase dit ce qui manque.
      expect(_cle('point-seance-envoyer'), findsNothing);
      expect(_cle('point-seance-manque-tire'), findsOneWidget);
      expect(
        find.text(t.pointSeance.manqueTire(prenom: 'Aïcha')),
        findsOneWidget,
      );
      // Les autres presents sont « A suivi » ; l'absente n'est pas au point.
      expect(find.text('Bilal'), findsOneWidget);
      expect(find.text('Chams'), findsOneWidget);
      expect(find.text('Dalia'), findsNothing);
      expect(_cle('point-seance-hors-point'), findsOneWidget);
      expect(faux.envois, isEmpty);
    });

    testWidgets(
      'un toucher pour l\'eleve tire, un pour « A renforcer », envoi',
      (WidgetTester tester) async {
        final FauxPointSeance faux = FauxPointSeance(point: pointAFaireBrut());
        await _ouvrir(tester, faux);
        await tester.tap(
          find.descendant(
            of: _cle('point-seance-choix-e1'),
            matching: find.text(t.pointSeance.acquis),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: _cle('point-seance-choix-e2'),
            matching: find.text(t.pointSeance.aRenforcer),
          ),
        );
        await tester.pump();
        expect(_cle('point-seance-manque-tire'), findsNothing);
        verifierUnSeulBoutonPlein(tester);
        verifierAucuneCarteCollee(tester, estCarte: (Widget w) => w is AppCard);
        await tester.ensureVisible(_cle('point-seance-envoyer'));
        await tester.tap(_cle('point-seance-envoyer'));
        await stabiliser(tester);
        expect(faux.envois.single, <String, ReponsePoint>{
          'e1': ReponsePoint.acquis,
          'e2': ReponsePoint.aRenforcer,
          'e3': ReponsePoint.aSuivi,
        });
        expect(faux.notes.single, isNull);
        // Apres l'envoi : confirme, corrigible, et le chemin vers le cahier.
        expect(_cle('point-seance-envoye'), findsOneWidget);
        expect(find.text(t.pointSeance.envoyeTitre), findsOneWidget);
        expect(_cle('point-seance-vers-cahier'), findsOneWidget);
        expect(
          find.widgetWithText(ActionPrincipale, t.pointSeance.corriger),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '« Pas eu le temps de l\'ecouter » envoie le point d\'un toucher',
      (WidgetTester tester) async {
        final FauxPointSeance faux = FauxPointSeance(point: pointAFaireBrut());
        await _ouvrir(tester, faux);
        await tester.ensureVisible(_cle('point-seance-pas-eu-le-temps'));
        await tester.tap(_cle('point-seance-pas-eu-le-temps'));
        await stabiliser(tester);
        expect(faux.envois.single['e1'], ReponsePoint.pasEcoute);
      },
    );

    testWidgets('un refus du serveur dit quoi faire', (
      WidgetTester tester,
    ) async {
      final FauxPointSeance faux = FauxPointSeance(
        point: pointAFaireBrut(envoye: true),
        refus: RefusPoint.delaiDepasse,
      );
      await _ouvrir(tester, faux);
      await tester.ensureVisible(_cle('point-seance-envoyer'));
      await tester.tap(_cle('point-seance-envoyer'));
      await stabiliser(tester);
      expect(find.text(t.pointSeance.refusDelai), findsWidgets);
      expect(faux.envois, isEmpty);
    });

    testWidgets('lecture en echec : la panne se dit, avec « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, FauxPointSeance(erreurLecture: true));
      expect(_cle('point-seance-erreur'), findsOneWidget);
      expect(find.text(t.pointSeance.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('seance non terminee, puis aucun present', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        FauxPointSeance(
          point: pointAFaireBrut()
            ..['tenue'] = false
            ..['eleves'] = <Object?>[],
        ),
      );
      expect(_cle('point-seance-non-tenue'), findsOneWidget);
      expect(_cle('point-seance-envoyer'), findsNothing);
    });

    testWidgets('aucun present : pas de point a faire', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        FauxPointSeance(point: pointAFaireBrut()..['eleves'] = <Object?>[]),
      );
      expect(_cle('point-seance-vide'), findsOneWidget);
    });

    for (final Size taille in const <Size>[Size(320, 2200), Size(1440, 1400)]) {
      for (final double echelle in const <double>[1, 2]) {
        for (final ThemeMode theme in const <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets(
            'gardes de rendu ${taille.width.toInt()} x$echelle ${theme.name}',
            (WidgetTester tester) async {
              await _ouvrir(
                tester,
                FauxPointSeance(point: pointAFaireBrut(envoye: true)),
                taille: taille,
                echelle: echelle,
                theme: theme,
              );
              expect(tester.takeException(), isNull);
              verifierUnSeulBoutonPlein(tester);
              verifierAucuneCarteCollee(
                tester,
                estCarte: (Widget w) => w is AppCard,
              );
              verifierSansChevauchement(tester, <Finder>[
                _cle('point-seance-tire'),
                _cle('point-seance-presents'),
                _cle('point-seance-envoyer'),
              ]);
            },
          );
        }
      }
    }
  });

  group('Point de fin de seance : rattrapage', () {
    testWidgets('« A terminer » montre la seance et ouvre la page', (
      WidgetTester tester,
    ) async {
      final FauxPointSeance faux = FauxPointSeance(
        point: pointAFaireBrut(),
        aFaireRendus: <PointAFaire>[
          PointAFaire(
            seanceId: 's1',
            classe: 'An-Nour',
            debut: DateTime(2026, 11, 12, 18),
          ),
        ],
      );
      await monterRouteur(
        tester,
        Routes.enseignantATerminer,
        source: FausseSourceSession(sessionActive(AppRole.teacher)),
        taille: const Size(390, 1200),
        surcharges: _avec(faux),
      );
      await stabiliser(tester);
      expect(_cle('a-terminer-vide'), findsNothing);
      expect(_cle('a-terminer-point-s1'), findsOneWidget);
      await tester.tap(_cle('a-terminer-point-s1'));
      await stabiliser(tester);
      expect(find.byType(PointSeancePage), findsOneWidget);
    });

    testWidgets('rien a faire : la liste reste vide', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.enseignantATerminer,
        source: FausseSourceSession(sessionActive(AppRole.teacher)),
        surcharges: _avec(FauxPointSeance()),
      );
      await stabiliser(tester);
      expect(_cle('a-terminer-vide'), findsOneWidget);
    });
  });

  group('Historique des seances : le hub', () {
    testWidgets('tuteur : a renforcer et travail, jamais la note', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        taille: const Size(390, 2400),
        autres: _avec(FauxPointSeance(historiqueRendu: historiqueBrut())),
      );
      await stabiliser(tester);
      expect(find.byKey(BlocHistoriqueSeances.contenuKey), findsOneWidget);
      expect(find.text(t.historiqueSeances.titre), findsOneWidget);
      expect(
        find.text(
          t.historiqueSeances.aRenforcerDepuis(
            numero: '12',
            mois: t.commun.dates.mois[10],
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Bilal confond'), findsNothing);
      expect(
        find.textContaining(t.historiqueSeances.deuxDeSuite),
        findsNothing,
      );
      expect(find.text(t.pointSeance.aRenforcer), findsNWidgets(2));
    });

    testWidgets('le serveur ne l\'ouvre pas (enfant de 6 a 9 ans) : rien', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.eleveSuivi,
        source: FausseSourceSession(sessionActive(AppRole.student)),
        taille: const Size(390, 2000),
        interface: InterfaceMode.enfant,
        surcharges: _avec(FauxPointSeance()),
      );
      await stabiliser(tester);
      expect(find.byType(BlocHistoriqueSeances), findsOneWidget);
      expect(find.text(t.historiqueSeances.titre), findsNothing);
      expect(find.byKey(BlocHistoriqueSeances.echecKey), findsNothing);
    });

    testWidgets('eleve de 10 ans et plus : son historique', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.eleveSuivi,
        source: FausseSourceSession(sessionActive(AppRole.student)),
        taille: const Size(390, 2400),
        surcharges: _avec(FauxPointSeance(historiqueRendu: historiqueBrut())),
      );
      await stabiliser(tester);
      expect(find.byKey(BlocHistoriqueSeances.contenuKey), findsOneWidget);
    });

    testWidgets('lecture en echec : une ligne le dit et relit au toucher', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        taille: const Size(390, 2400),
        autres: _avec(FauxPointSeance(erreurLecture: true)),
      );
      await stabiliser(tester);
      expect(find.byKey(BlocHistoriqueSeances.echecKey), findsOneWidget);
      expect(find.text(t.historiqueSeances.illisible), findsOneWidget);
    });
  });

  group('Point de fin de seance : contrat', () {
    test('la reponse du serveur se lit', () {
      final PointSeance p = PointSeance.depuisLecture(pointAFaireBrut())!;
      expect(p.eleves.first.tire, isTrue);
      expect(p.eleves.first.reponse, isNull);
      expect(p.eleves[1].reponse, ReponsePoint.aSuivi);
      expect(p.horsPoint.single.presence, PresencePoint.absente);
      expect(PointSeance.depuisLecture('x'), isNull);
      final HistoriqueSeances h = HistoriqueSeances.depuisLecture(
        historiqueBrut(academie: true),
      )!;
      expect(h.aRenforcer, isTrue);
      expect(h.deuxDeSuite, isTrue);
      expect(h.seances.first.note, isNotNull);
      expect(h.seances[1].reponse, isNull);
    });

    test('chaque refus du serveur a son motif', () {
      RefusPoint r(String m, [String? c]) =>
          PointSeanceSupabase.refusDepuis(c, m);
      expect(r('point de seance refuse', '42501'), RefusPoint.refuse);
      expect(
        r('point_seance_eleve_tire_sans_reponse'),
        RefusPoint.eleveTireSansReponse,
      );
      expect(r('point_seance_delai_depasse'), RefusPoint.delaiDepasse);
      expect(r('point_seance_seance_non_tenue'), RefusPoint.seanceNonTenue);
      expect(r('point_seance_eleve_absent'), RefusPoint.presentsChanges);
      expect(r('point_seance_aucun_present'), RefusPoint.aucunPresent);
      expect(r('autre'), RefusPoint.reseau);
    });
  });
}
