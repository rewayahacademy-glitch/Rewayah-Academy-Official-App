// ADM-CAHIER-LECTURE : la direction lit les cahiers d'une classe, en lecture
// seule, avec l'etiquette « Interne, jamais montre a la famille », puis ouvre
// l'apercu familial. Tous les etats : chargement, contenu, vide, erreur, hors
// ligne, indisponible, refuse. Aucune route nouvelle : des feuilles.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart'
    show horsLigneProvider;
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_groupes/apercu_familial.dart';
import 'package:rewayah_academy/features/admin_groupes/cahiers_classe.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/ped_apres/faux_partage_pedagogique.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

final c = t.admin.groupes.cahiers;

class _EnseignantInterdit implements ServiceEnseignant {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('aucune ecriture de cahier : ${invocation.memberName}');
}

FauxPartagePedagogique _serveur({int taillePage = 25}) =>
    FauxPartagePedagogique(taillePage: taillePage)
      ..rapports[('s1', 'e1')] = RapportSim()
      ..rapports[('s2', 'e1')] = RapportSim(autoPartage: false)
      ..rapports[('s1', 'e2')] = RapportSim()
      ..rapports[('s3', 'e3')] = RapportSim(confirme: false);

List<Override> _s(PortPartagePedagogique port, {bool horsLigne = false}) =>
    <Override>[
      portPartagePedagogiqueProvider.overrideWithValue(port),
      sansPersonneConnectee(),
      serviceEnseignantProvider.overrideWithValue(_EnseignantInterdit()),
      if (horsLigne)
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
    ];

Future<void> _monter(
  WidgetTester tester,
  Widget enfant,
  PortPartagePedagogique port, {
  Size taille = const Size(900, 2400),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool horsLigne = false,
  bool attendre = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Directionality(
        textDirection: direction,
        child: Builder(
          builder: (BuildContext ctx) => MediaQuery(
            data: MediaQuery.of(ctx)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: enfant,
              ),
            ),
          ),
        ),
      ),
      surcharges: _s(port, horsLigne: horsLigne),
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  }
}

const Widget _liste = FeuilleCahiersClasse(classeId: 'c1');
const Widget _cahier = FeuilleCahierAdmin(seanceId: 's1', eleveId: 'e1');

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('la liste des cahiers d une classe', () {
    testWidgets('contenu : une ligne par cahier, son etat, lecture seule, '
        'aucun bouton plein', (WidgetTester tester) async {
      await _monter(tester, _liste, _serveur());
      expect(find.text(c.aide), findsOneWidget);
      expect(find.text('Yusuf'), findsNWidgets(2));
      expect(find.text('Mariam'), findsOneWidget);
      expect(find.text('Adam'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('chargement : squelette', (WidgetTester tester) async {
      final FauxPartagePedagogique s = _serveur();
      final Completer<void> porte = Completer<void>();
      s.portes['comptesRendusClasse'] = porte;
      await _monter(tester, _liste, s, attendre: false);
      await tester.pump();
      expect(find.byType(Skeleton), findsWidgets);
      porte.complete();
      await tester.pumpAndSettle();
      expect(find.text('Mariam'), findsOneWidget);
    });

    testWidgets('vide : une phrase honnete', (WidgetTester tester) async {
      await _monter(tester, _liste, FauxPartagePedagogique());
      expect(find.text(c.vide), findsOneWidget);
    });

    testWidgets('filtre par etat : le serveur filtre, la liste suit', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique s = _serveur();
      await _monter(tester, _liste, s);
      await tester.tap(find.text(c.filtre));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(libelleEtatDiffusion(EtatDiffusion.nonValide)).last,
      );
      await tester.pumpAndSettle();
      expect(s.demandesCahiers.last.$2, EtatDiffusion.nonValide);
      expect(find.text('Adam'), findsOneWidget);
      expect(find.text('Mariam'), findsNothing);
    });

    testWidgets('grande classe : pages serveur, aucune copie en double', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique s = _serveur(taillePage: 2);
      await _monter(tester, _liste, s);
      expect(find.text(c.plus), findsOneWidget);
      await tester.tap(find.text(c.plus));
      await tester.pumpAndSettle();
      expect(s.demandesCahiers.map((e) => e.$1), <int>[1, 2]);
      expect(find.text('Adam'), findsOneWidget);
      expect(find.text(c.plus), findsNothing);
      expect(find.text('Yusuf'), findsNWidgets(2));
    });

    testWidgets('erreur : phrase et Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique s = _serveur()
        ..erreurs['comptesRendusClasse'] = StateError('reseau');
      await _monter(tester, _liste, s);
      expect(find.text(t.admin.groupes.partage.illisible), findsOneWidget);
      s.erreurs.clear();
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(find.text('Mariam'), findsOneWidget);
    });

    testWidgets('hors ligne : la phrase le dit', (WidgetTester tester) async {
      final FauxPartagePedagogique s = _serveur()
        ..erreurs['comptesRendusClasse'] = StateError('reseau');
      await _monter(tester, _liste, s, horsLigne: true);
      expect(find.text(t.admin.groupes.partage.horsLigne), findsOneWidget);
    });

    testWidgets('production : indisponible, sans Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _liste, const PartagePedagogiqueIndisponible());
      expect(find.text(t.admin.groupes.partage.indisponible), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('refuse : phrase, aucune donnee', (WidgetTester tester) async {
      final FauxPartagePedagogique s = _serveur()
        ..erreurs['comptesRendusClasse'] = const PermissionInsuffisante('x');
      await _monter(tester, _liste, s);
      expect(find.text(t.admin.groupes.partage.refuse), findsOneWidget);
      expect(find.text('Yusuf'), findsNothing);
    });
  });

  group('le cahier en lecture seule', () {
    testWidgets('evaluation, details internes etiquetes, aucune action de '
        'modification', (WidgetTester tester) async {
      final FauxPartagePedagogique s = _serveur();
      await _monter(tester, _cahier, s);
      expect(find.text(c.lectureSeule), findsOneWidget);
      expect(find.text(c.evaluation), findsOneWidget);
      expect(find.text(c.detailsInternes), findsOneWidget);
      expect(find.text(c.interne), findsOneWidget);
      expect(find.text('NOTE INTERNE : parents difficiles'), findsOneWidget);
      // Meme pour la direction : jamais un autre eleve, jamais la paie.
      expect(find.textContaining('AUTRE ELEVE'), findsNothing);
      expect(find.textContaining('PAIE'), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      expect(find.byType(TextField), findsNothing);
      // La lecture est journalisee cote serveur (oracle du double).
      expect(s.lecturesJournalisees, <(String, String)>[('s1', 'e1')]);
    });

    testWidgets('l etiquette « Interne » vient avant les details internes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _cahier, _serveur());
      final double etiquette = tester.getTopLeft(find.text(c.interne)).dy;
      final double premiere = tester
          .getTopLeft(find.textContaining('NOTE INTERNE'))
          .dy;
      expect(etiquette, lessThan(premiere));
    });

    testWidgets('aucune copie du texte interne vers l apercu familial', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique s = _serveur();
      await _monter(
        tester,
        const FeuilleApercuFamilial(seanceId: 's1', eleveId: 'e1'),
        s,
      );
      for (final String n in s.rapports[('s1', 'e1')]!.interne) {
        expect(find.textContaining(n), findsNothing);
      }
      final ApercuAdmin a = await s.apercuFamilial(
        seanceId: 's1',
        eleveId: 'e1',
      );
      expect(a.apercu, isA<CompteRenduFamille>());
    });

    testWidgets('le lien ouvre l apercu familial (publier / revoquer)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _cahier, _serveur());
      await tester.tap(find.text(c.apercu));
      await tester.pumpAndSettle();
      expect(find.byType(FeuilleApercuFamilial), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is ActionPrincipale &&
              w.libelle == t.admin.groupes.partage.revoquer,
        ),
        findsOneWidget,
      );
    });

    testWidgets('cahier non valide : dit, et lisible', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const FeuilleCahierAdmin(seanceId: 's3', eleveId: 'e3'),
        _serveur(),
      );
      expect(find.text(c.nonValide), findsOneWidget);
    });

    testWidgets('sans detail interne ni evaluation : phrases honnetes', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique s = _serveur();
      s.rapports[('s1', 'e1')]!
        ..interne.clear()
        ..contenu = const CompteRenduFamille(etat: EtatCompteRendu.partage);
      await _monter(tester, _cahier, s);
      expect(find.text(c.aucuneEvaluation), findsOneWidget);
      expect(find.text(c.aucunInterne), findsOneWidget);
    });

    testWidgets('erreur, refus et production : etats dits, aucune donnee', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique s = _serveur()
        ..erreurs['lireCahierAdmin'] = const PermissionInsuffisante('x');
      await _monter(tester, _cahier, s);
      expect(find.text(t.admin.groupes.partage.refuse), findsOneWidget);
      expect(find.text(c.interne), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _monter(tester, _cahier, const PartagePedagogiqueIndisponible());
      expect(find.text(t.admin.groupes.partage.indisponible), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final FauxPartagePedagogique e = _serveur()
        ..erreurs['lireCahierAdmin'] = StateError('x');
      await _monter(tester, _cahier, e);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('un autre role ne lit rien : le serveur refuse, l ecran n a '
        'aucune donnee a montrer', (WidgetTester tester) async {
      final FauxPartagePedagogique s = _serveur()
        ..erreurs['lireCahierAdmin'] = const PermissionInsuffisante('role');
      await _monter(tester, _cahier, s);
      expect(find.textContaining('NOTE INTERNE'), findsNothing);
      expect(s.lecturesJournalisees, isEmpty);
    });
  });

  group('A18 : 320 a 1440, texte x2, RTL', () {
    for (final double largeur in <double>[320, 390, 768, 1440]) {
      for (final TextDirection d in TextDirection.values) {
        testWidgets('$largeur px, texte x2, ${d.name}', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            _cahier,
            _serveur(),
            taille: Size(largeur, 3200),
            echelle: 2,
            direction: d,
          );
          expect(tester.takeException(), isNull);
          verifierUnSeulBoutonPlein(tester, maximum: 0);
          verifierAucunMotCoupe(tester, find.byType(FeuilleCahierAdmin));
          await tester.pumpWidget(const SizedBox());
          await _monter(
            tester,
            _liste,
            _serveur(),
            taille: Size(largeur, 3200),
            echelle: 2,
            direction: d,
          );
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byType(FeuilleCahiersClasse));
        });
      }
    }
  });

  test('l etiquette utilise l elision pour le titre', () {
    expect(c.titreCahier(dePrenom: deDevant('Aicha')), contains('d'));
  });
}
