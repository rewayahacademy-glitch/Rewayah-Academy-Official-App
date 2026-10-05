import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bento_tile.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_demandes/demandes_page.dart';

import '../support/harnais.dart';

/// Une fenetre haute : une demande porte son constat, la feuille de regles de
/// l'eleve et les deux verdicts, et un `ListView` ne construit pas ce qui n'est
/// pas visible. Sans elle, le test mesure la hauteur du viewport.
void _fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Demande _demande({
  String id = 'req1',
  SorteDemande sorte = SorteDemande.regle,
  String prenom = 'Aissatou',
  CleRegle? cle = CleRegle.dureeSeance,
  int? valeur = 30,
  DateTime? creee,
}) => Demande(
  id: id,
  sorte: sorte,
  sujetId: 'e1',
  sujetPrenom: prenom,
  sujetIdentifiant: 'STUDENT-AD-000001',
  motif: 'Elle decroche apres quarante minutes.',
  roleDemandeur: AppRole.guardian,
  cleRegle: cle,
  valeurDemandee: valeur,
  creeeLe: creee ?? DateTime(2026, 9, 6, 9),
);

/// Les regles d'un eleve : deux au defaut de la plateforme, une surchargee.
FauxServiceRegles _regles() =>
    FauxServiceRegles()
      ..parProfil['e1'] = <RegleProfil>[
        RegleProfil(
          cle: CleRegle.dureeSeance,
          valeurEffective: 45,
          valeurPlateforme: 60,
          surchargeId: 'ovr1',
          motif: 'Enfant de six ans.',
          poseeLe: DateTime(2026, 8, 20),
        ),
        const RegleProfil(
          cle: CleRegle.minimumPayable,
          valeurEffective: 45,
          valeurPlateforme: 45,
        ),
        const RegleProfil(
          cle: CleRegle.pauseEntreCours,
          valeurEffective: 30,
          valeurPlateforme: 30,
        ),
      ];

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAdmin admin,
  FauxServiceRegles? regles,
}) async {
  await tester.pumpWidget(
    hote(
      const DemandesPage(),
      surcharges: <Override>[
        serviceAdminProvider.overrideWithValue(admin),
        serviceReglesProvider.overrideWithValue(regles ?? _regles()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la premiere lecture montre un squelette', (
    WidgetTester tester,
  ) async {
    final Completer<List<Demande>> reponse = Completer<List<Demande>>();

    await tester.pumpWidget(
      hote(
        const DemandesPage(),
        surcharges: <Override>[
          serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
          serviceReglesProvider.overrideWithValue(_regles()),
          demandesProvider.overrideWith((_) => reponse.future),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(Skeleton), findsOneWidget);
    expect(find.text(t.commun.chargement), findsNothing);

    reponse.complete(const <Demande>[]);
    await tester.pumpAndSettle();
  });

  group('ADM-06 : une demande a la fois, et le verdict en dernier', () {
    testWidgets('une seule demande est presentee, jamais une grille', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..file = <Demande>[
            _demande(),
            _demande(id: 'req2', prenom: 'Moussa'),
          ],
      );

      expect(find.text('Aissatou'), findsOneWidget);
      expect(find.text('Moussa'), findsNothing);
      expect(find.text(t.admin.demandes.restantes(n: 2)), findsOneWidget);
    });

    testWidgets('le constat, puis les regles, puis le jugement', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      await _monter(
        tester,
        admin: FauxServiceAdmin()..file = <Demande>[_demande()],
      );

      // Meme ordre qu'a `ADM-02` : ce qui permet de juger est au-dessus du
      // jugement, et la feuille de regles en fait partie.
      final double yConstat = tester
          .getTopLeft(find.text(t.admin.demandes.reclame))
          .dy;
      final double yRegles = tester
          .getTopLeft(
            find.text(t.admin.demandes.feuille(dePrenom: deDevant('Aissatou'))),
          )
          .dy;
      final double yVerdict = tester
          .getTopLeft(find.text(t.admin.demandes.verdict))
          .dy;

      expect(yConstat, lessThan(yRegles));
      expect(yRegles, lessThan(yVerdict));
    });

    testWidgets('la demande dit qui, quand, sur qui et ce qu elle reclame', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      await _monter(
        tester,
        admin: FauxServiceAdmin()..file = <Demande>[_demande()],
      );

      expect(
        find.text(
          t.admin.demandes.faitePar(
            date: '06/09/2026',
            role: t.admin.demandes.roleGuardian,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          t.admin.demandes.reclameRegle(
            regle: t.admin.demandes.regleDuree,
            valeur: '30',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Elle decroche apres quarante minutes.'),
        findsOneWidget,
      );
    });

    testWidgets('accorder ne demande pas de motif', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      final FauxServiceAdmin admin = FauxServiceAdmin()
        ..file = <Demande>[_demande()];
      await _monter(tester, admin: admin);

      await tester.tap(
        find.widgetWithText(ActionPrincipale, t.admin.demandes.accorder),
      );
      await tester.pumpAndSettle();

      expect(admin.verdicts, hasLength(1));
      expect(admin.verdicts.single.demandeId, 'req1');
      expect(admin.verdicts.single.accepte, isTrue);
      expect(admin.verdicts.single.motif, isNull);
    });

    testWidgets('un refus sans motif ne part pas', (WidgetTester tester) async {
      _fenetreHaute(tester);
      final FauxServiceAdmin admin = FauxServiceAdmin()
        ..file = <Demande>[_demande()];
      await _monter(tester, admin: admin);

      await tester.tap(
        find.widgetWithText(ActionPrincipale, t.admin.demandes.refuser),
      );
      await tester.pumpAndSettle();

      // La base refuse aussi un verdict negatif sans motif : l'ecran ne fait
      // que l'annoncer plus tot.
      expect(find.text(t.admin.demandes.motifRequis), findsOneWidget);
      final Finder refuser = find.widgetWithText(
        ActionPrincipale,
        t.admin.demandes.refuser,
      );
      expect(tester.widget<ActionPrincipale>(refuser).onPress, isNull);

      await tester.enterText(
        find.byType(TextField),
        'La duree actuelle a ete posee la semaine derniere.',
      );
      await tester.pumpAndSettle();
      await tester.tap(refuser);
      await tester.pumpAndSettle();

      expect(admin.verdicts.single.accepte, isFalse);
      expect(
        admin.verdicts.single.motif,
        'La duree actuelle a ete posee la semaine derniere.',
      );
    });

    testWidgets('une file vide est une invitation, pas un ecran mort', (
      WidgetTester tester,
    ) async {
      await _monter(tester, admin: FauxServiceAdmin());

      expect(find.text(t.admin.demandes.aucune), findsOneWidget);
      expect(find.text(t.admin.demandes.aucuneDetail), findsOneWidget);
    });

    testWidgets('une panne laisse reessayer', (WidgetTester tester) async {
      await _monter(
        tester,
        admin: FauxServiceAdmin()..erreurFile = StateError('reseau'),
      );

      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    // EA-HORS-LIGNE-1b : une panne quelconque, en ligne, n'est pas « Pas de
    // reseau », et une file qui n'a pas charge n'a rien de consultable.
    testWidgets(
      'une panne dit que la file n a pas charge, pas « Pas de reseau »',
      (WidgetTester tester) async {
        await _monter(
          tester,
          admin: FauxServiceAdmin()..erreurFile = StateError('reseau'),
        );

        expect(find.text(t.admin.demandes.erreurFile), findsOneWidget);
        expect(find.textContaining(t.reseau.horsLigne), findsNothing);
        expect(find.textContaining('consultable'), findsNothing);
      },
    );
  });

  group('La feuille de regles : la plateforme et l applique, cote a cote', () {
    testWidgets('les deux valeurs sont lisibles sans calcul mental', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      await _monter(
        tester,
        admin: FauxServiceAdmin()..file = <Demande>[_demande()],
      );

      // 60 minutes pour la plateforme, 45 pour cette eleve : l'ecart se voit,
      // il ne se deduit pas.
      //
      // La recherche est bornee a la tuile de la duree. Une recherche globale
      // trouverait « Appliquee : 45 min » DEUX fois, la duree de cette eleve et
      // le minimum payable de la plateforme valant tous deux 45 : elle
      // mesurerait alors la page, pas la regle.
      final Finder tuileDuree = find
          .ancestor(
            of: find.text(t.admin.demandes.regleDuree),
            matching: find.byType(BentoTile),
          )
          .first;
      final Finder plateforme = find.descendant(
        of: tuileDuree,
        matching: find.text(
          t.admin.demandes.plateforme(
            valeur: t.admin.demandes.minutes(valeur: '60'),
          ),
        ),
      );
      final Finder effective = find.descendant(
        of: tuileDuree,
        matching: find.text(
          t.admin.demandes.effective(
            valeur: t.admin.demandes.minutes(valeur: '45'),
          ),
        ),
      );
      expect(plateforme, findsOneWidget);
      expect(effective, findsOneWidget);

      // « Cote a cote » se mesure : meme ligne, la plateforme a gauche.
      //
      // Les CENTRES, pas les sommets : la valeur surchargee est ecrite dans un
      // style plus gros que celle de la plateforme, donc son sommet est un
      // pixel plus haut alors que les deux sont bien sur la meme ligne.
      expect(tester.getCenter(plateforme).dy, tester.getCenter(effective).dy);
      expect(
        tester.getTopLeft(plateforme).dx,
        lessThan(tester.getTopLeft(effective).dx),
      );
      expect(
        find.text(
          t.admin.demandes.surchargeDepuis(
            date: '20/08/2026',
            motif: 'Enfant de six ans.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la cloture n est proposee que la ou il y a une surcharge', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      await _monter(
        tester,
        admin: FauxServiceAdmin()..file = <Demande>[_demande()],
      );

      // Trois regles, une seule surchargee : un bouton de cloture sur les
      // autres echouerait apres le geste, et un bouton qui echoue apres le
      // geste coute plus cher qu'un bouton absent.
      expect(find.text(t.admin.demandes.changer), findsNWidgets(3));
      expect(find.text(t.admin.demandes.clore), findsOneWidget);
      expect(find.text(t.admin.demandes.sansSurcharge), findsNWidgets(2));
    });

    testWidgets('la mesure inverse : sans aucune surcharge, aucune cloture', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      await _monter(
        tester,
        admin: FauxServiceAdmin()..file = <Demande>[_demande()],
        regles: FauxServiceRegles()
          ..parProfil['e1'] = const <RegleProfil>[
            RegleProfil(
              cle: CleRegle.dureeSeance,
              valeurEffective: 60,
              valeurPlateforme: 60,
            ),
          ],
      );

      expect(find.text(t.admin.demandes.changer), findsOneWidget);
      expect(find.text(t.admin.demandes.clore), findsNothing);
    });

    testWidgets('les surcharges closes restent lisibles sous la valeur', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      await _monter(
        tester,
        admin: FauxServiceAdmin()..file = <Demande>[_demande()],
        regles: _regles()
          ..historiqueParProfil['e1'] = <SurchargeClose>[
            SurchargeClose(
              id: 'ovr0',
              cle: CleRegle.dureeSeance,
              valeur: 30,
              motif: 'Essai a la rentree.',
              poseeLe: DateTime(2026, 7, 1),
              closeLe: DateTime(2026, 8, 20),
              motifCloture: 'remplacee : Enfant de six ans.',
            ),
          ],
      );

      // Une regle ne se supprime pas : « la seance durait 30 minutes ce
      // jour-la » doit se verifier six mois plus tard.
      expect(find.text(t.admin.demandes.historique), findsOneWidget);
      expect(
        find.text(
          t.admin.demandes.historiqueLigne(
            valeur: t.admin.demandes.minutes(valeur: '30'),
            debut: '01/07/2026',
            fin: '20/08/2026',
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('Une regle se change a la volee, sans qu une demande existe', () {
    testWidgets('la pause se pose alors qu aucune demande ne la vise', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      final FauxServiceRegles regles = _regles();

      // La feuille seule, sans aucune demande : c'est exactement le second
      // chemin de l'ADR-017, une demande n'etant que le premier.
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: FeuilleRegles(profilId: 'e1', prenom: 'Aissatou'),
          ),
          surcharges: <Override>[
            serviceReglesProvider.overrideWithValue(regles),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Le troisieme « Changer » est celui de la pause entre deux cours.
      await tester.tap(find.text(t.admin.demandes.changer).at(2));
      await tester.pumpAndSettle();

      expect(
        find.text(
          t.admin.demandes.poserTitre(
            regle: t.admin.demandes.reglePause,
            prenom: 'Aissatou',
          ),
        ),
        findsOneWidget,
      );

      final Finder poser = find.widgetWithText(
        ActionPrincipale,
        t.admin.demandes.poserEnvoyer,
      );
      // Une regle sans motif ne se relit pas six mois plus tard : la base la
      // refuse, et l'ecran ne fait pas semblant.
      expect(tester.widget<ActionPrincipale>(poser).onPress, isNull);

      await tester.tap(find.text(t.admin.demandes.minutes(valeur: '45')));
      await tester.enterText(
        find.byType(TextField),
        'Trajet entre deux cours.',
      );
      await tester.pumpAndSettle();
      await tester.tap(poser);
      await tester.pumpAndSettle();

      expect(regles.posees, hasLength(1));
      expect(regles.posees.single.profilId, 'e1');
      expect(regles.posees.single.cle, CleRegle.pauseEntreCours);
      expect(regles.posees.single.valeur, 45);
      expect(regles.posees.single.motif, 'Trajet entre deux cours.');
    });

    testWidgets('une cloture exige son motif, comme une pose', (
      WidgetTester tester,
    ) async {
      _fenetreHaute(tester);
      final FauxServiceRegles regles = _regles();

      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: FeuilleRegles(profilId: 'e1', prenom: 'Aissatou'),
          ),
          surcharges: <Override>[
            serviceReglesProvider.overrideWithValue(regles),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.admin.demandes.clore));
      await tester.pumpAndSettle();

      final Finder clore = find.widgetWithText(
        ActionPrincipale,
        t.admin.demandes.cloreEnvoyer,
      );
      expect(tester.widget<ActionPrincipale>(clore).onPress, isNull);

      await tester.enterText(
        find.byType(TextField),
        'Elle a grandi, retour a la duree commune.',
      );
      await tester.pumpAndSettle();
      await tester.tap(clore);
      await tester.pumpAndSettle();

      expect(regles.closes, <String>['ovr1']);
      // La surcharge se clot, elle ne se supprime pas : aucun appel de pose ne
      // l'accompagne.
      expect(regles.posees, isEmpty);
    });
  });
}
