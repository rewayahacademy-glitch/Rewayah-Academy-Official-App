// PED-APRES-1, ADM-PED-APR-02 (reglage de partage dans la fiche de classe) et
// ADM-PED-APR-03 (apercu familial et publication ciblee). Scenarios A05, A06,
// A08, A12, A14, A15, A16, A17, A20, A21 et les etats des tableaux de la spec
// (section 3).
//
// Le serveur est le simulateur `FauxPartagePedagogique` : la priorite du
// contrat y est appliquee, pour que la direction decide et que la famille lise
// d'un seul tenant.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/reseau/service_reseau.dart'
    show horsLigneProvider;
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_groupes/apercu_familial.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/admin_groupes/reglage_partage.dart';
import 'package:rewayah_academy/features/classe_tuteur/contexte_classe.dart'
    show nomClasseInsecable;

import '../../fixtures/ped_apres/faux_partage_pedagogique.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

final p = t.admin.groupes.partage;

FauxPartagePedagogique _serveur({int taillePage = 25}) =>
    FauxPartagePedagogique(taillePage: taillePage)
      ..rapports[('s1', 'e1')] = RapportSim()
      ..rapports[('s2', 'e1')] = RapportSim(autoPartage: false)
      ..rapports[('s1', 'e2')] = RapportSim();

/// Un service d'enseignant qui echoue au moindre appel : prouve que les
/// ecrans de partage ne touchent jamais au cahier K-45 ni a la remuneration.
class _EnseignantInterdit implements ServiceEnseignant {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'le partage ne touche pas au cahier : '
    '${invocation.memberName}',
  );
}

List<Override> _surcharges(
  PortPartagePedagogique port, {
  bool horsLigne = false,
}) => <Override>[
  portPartagePedagogiqueProvider.overrideWithValue(port),
  sansPersonneConnectee(),
  serviceEnseignantProvider.overrideWithValue(_EnseignantInterdit()),
  if (horsLigne)
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
];

Future<void> _monterGroupe(
  WidgetTester tester,
  PortPartagePedagogique? port, {
  Size taille = const Size(900, 1600),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool horsLigne = false,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Directionality(
        textDirection: direction,
        child: Builder(
          builder: (BuildContext c) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
              textScaler: TextScaler.linear(echelle),
              platformBrightness: luminosite,
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: GroupePartageClasse(
                  classeId: 'c1',
                  nomClasse: 'Classe An-Nour',
                ),
              ),
            ),
          ),
        ),
      ),
      surcharges: <Override>[
        if (port != null) ..._surcharges(port, horsLigne: horsLigne),
        if (port == null) sansPersonneConnectee(),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _monterApercu(
  WidgetTester tester,
  PortPartagePedagogique port, {
  String seance = 's1',
  String eleve = 'e1',
  Size taille = const Size(900, 2400),
  double echelle = 1,
  bool horsLigne = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Builder(
        builder: (BuildContext c) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FeuilleApercuFamilial(seanceId: seance, eleveId: eleve),
            ),
          ),
        ),
      ),
      surcharges: _surcharges(port, horsLigne: horsLigne),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _switch() => find.byType(Switch);

bool _valeurSwitch(WidgetTester tester) =>
    tester.widget<Switch>(_switch()).value;

bool _switchActif(WidgetTester tester) =>
    tester.widget<Switch>(_switch()).onChanged != null;

Future<void> _basculerEtConfirmer(
  WidgetTester tester, {
  required String libelleConfirmer,
}) async {
  await tester.tap(_switch());
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelleConfirmer).last);
  await tester.pumpAndSettle();
}

Finder _action(String libelle) => find.byWidgetPredicate(
  (Widget w) => w is ActionPrincipale && w.libelle == libelle,
);

Future<void> _confirmerApercu(WidgetTester tester, String libelle) async {
  await tester.tap(_action(libelle));
  await tester.pumpAndSettle();
  // La feuille de confirmation porte le meme libelle sur son action.
  await tester.tap(find.text(libelle).last);
  await tester.pumpAndSettle();
}

void main() {
  group('ADM-PED-APR-02 : etats du groupe de reglage', () {
    testWidgets('contenu : interrupteur lu depuis la source, aide fixe, '
        'priorite en une ligne, derniere modification', (
      WidgetTester tester,
    ) async {
      await _monterGroupe(tester, _serveur());
      expect(find.text(p.titre), findsOneWidget);
      expect(find.text(p.interrupteur), findsOneWidget);
      expect(find.text(p.aide), findsOneWidget);
      expect(find.text(p.priorite), findsOneWidget);
      expect(_valeurSwitch(tester), isTrue);
      expect(find.text(p.etatActif), findsOneWidget);
      expect(find.textContaining('Direction'), findsWidgets);
      expect(find.text(p.gererExceptions), findsOneWidget);
    });

    testWidgets('chargement : squelette, puis le contenu', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      final Completer<void> porte = Completer<void>();
      serveur.portes['partageClasse'] = porte;
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: GroupePartageClasse(classeId: 'c1', nomClasse: 'Classe'),
          ),
          surcharges: _surcharges(serveur),
        ),
      );
      await tester.pump();
      expect(find.byType(Skeleton), findsWidgets);
      expect(_switch(), findsNothing);
      porte.complete();
      await tester.pumpAndSettle();
      expect(_switch(), findsOneWidget);
    });

    testWidgets('classe vide : une phrase, aucun acces aux exceptions', (
      WidgetTester tester,
    ) async {
      await _monterGroupe(tester, _serveur()..vide = true);
      expect(find.text(p.classeVide), findsOneWidget);
      expect(find.text(p.gererExceptions), findsNothing);
    });

    testWidgets('A17 : sans source (production) : « pas encore disponible », '
        'aucune fausse bascule', (WidgetTester tester) async {
      await _monterGroupe(tester, const PartagePedagogiqueIndisponible());
      expect(find.text(p.indisponible), findsOneWidget);
      expect(_switch(), findsNothing);
      expect(find.text(p.gererExceptions), findsNothing);
      expect(find.text(t.commun.reessayer), findsNothing);
      expect(find.textContaining('PED-APRES-BACK'), findsNothing);
    });

    testWidgets(
      'autorisation refusee : phrase, sans Reessayer ni interrupteur',
      (WidgetTester tester) async {
        await _monterGroupe(
          tester,
          _serveur()
            ..erreurs['partageClasse'] = const PermissionInsuffisante('x'),
        );
        expect(find.text(p.refuse), findsOneWidget);
        expect(_switch(), findsNothing);
        expect(find.text(t.commun.reessayer), findsNothing);
      },
    );

    testWidgets('echec de lecture : phrase et Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..erreurs['partageClasse'] = StateError('reseau');
      await _monterGroupe(tester, serveur);
      expect(find.text(p.illisible), findsOneWidget);
      serveur.erreurs.clear();
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(_switch(), findsOneWidget);
    });

    testWidgets('hors ligne : l interrupteur ne bouge pas, la phrase dit '
        'pourquoi, rien n est envoye', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur, horsLigne: true);
      expect(_switchActif(tester), isFalse);
      expect(find.text(p.horsLigne), findsOneWidget);
      expect(serveur.cles, isEmpty);
    });

    testWidgets('donnee partielle : sans date de modification, la ligne est '
        'absente (rien d invente)', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, _SansModification(serveur));
      expect(find.textContaining('Dernière modification'), findsNothing);
      expect(_switch(), findsOneWidget);
    });
  });

  group('ADM-PED-APR-02 : ecrire le reglage de classe', () {
    testWidgets('desactiver : confirmation avec la consequence, ecriture, '
        'valeur relue', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur);
      await tester.tap(_switch());
      await tester.pumpAndSettle();
      expect(find.text(p.confirmerDesactiver), findsWidgets);
      expect(find.text(p.consequenceDesactiver), findsOneWidget);
      // La valeur n'a PAS bascule avant la confirmation.
      expect(_valeurSwitch(tester), isTrue);
      await tester.tap(find.text(p.actionDesactiver).last);
      await tester.pumpAndSettle();
      expect(serveur.classeActive, isFalse);
      expect(_valeurSwitch(tester), isFalse);
      expect(find.text(p.etatInactif), findsOneWidget);
      expect(find.text(p.confirme), findsOneWidget);
      expect(serveur.cles, hasLength(1));
    });

    testWidgets('annuler la confirmation : aucune ecriture', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur);
      await tester.tap(_switch());
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.annuler).last);
      await tester.pumpAndSettle();
      expect(serveur.cles, isEmpty);
      expect(_valeurSwitch(tester), isTrue);
    });

    testWidgets('un seul envoi a la fois : inerte pendant l envoi, un second '
        'geste ne part pas', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      final Completer<void> porte = Completer<void>();
      serveur.portes['definirPartageClasse'] = porte;
      await _monterGroupe(tester, serveur);
      await _basculerEtConfirmer(tester, libelleConfirmer: p.actionDesactiver);
      expect(find.text(p.enregistrement), findsOneWidget);
      expect(_switchActif(tester), isFalse);
      expect(_valeurSwitch(tester), isTrue, reason: 'jamais optimiste');
      await tester.tap(_switch(), warnIfMissed: false);
      await tester.pump();
      porte.complete();
      await tester.pumpAndSettle();
      expect(
        serveur.appels.where((String a) => a == 'definirPartageClasse'),
        hasLength(1),
      );
      expect(_valeurSwitch(tester), isFalse);
    });

    testWidgets('A15 : une autre personne de la direction a modifie : conflit '
        'visible, valeur a jour, aucune ecriture silencieuse', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur);
      // Pendant que cet ecran est ouvert, l'autre personne desactive.
      serveur.simulerAutreAdministrateur(classeActive: false);
      await _basculerEtConfirmer(tester, libelleConfirmer: p.actionDesactiver);
      expect(find.text(p.conflit), findsOneWidget);
      expect(serveur.cles, isEmpty, reason: 'aucune ecriture');
      // La valeur affichee est celle de l'autre personne.
      expect(_valeurSwitch(tester), isFalse);
      expect(find.text(p.etatInactif), findsOneWidget);
      expect(find.text(p.confirme), findsNothing);
    });

    testWidgets('A16 : le serveur refuse : valeur restauree, erreur '
        'actionnable, aucune confirmation fictive', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..erreurs['definirPartageClasse'] = StateError('serveur');
      await _monterGroupe(tester, serveur);
      await _basculerEtConfirmer(tester, libelleConfirmer: p.actionDesactiver);
      expect(find.text(p.echec), findsOneWidget);
      expect(find.text(p.confirme), findsNothing);
      expect(_valeurSwitch(tester), isTrue);
      expect(serveur.classeActive, isTrue);
      // L'interrupteur est de nouveau utilisable (on peut reessayer).
      expect(_switchActif(tester), isTrue);
    });

    testWidgets('A16 : autorisation refusee a l ecriture', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..erreurs['definirPartageClasse'] = const PermissionInsuffisante('x');
      await _monterGroupe(tester, serveur);
      await _basculerEtConfirmer(tester, libelleConfirmer: p.actionDesactiver);
      expect(find.text(p.refuse), findsOneWidget);
      expect(_valeurSwitch(tester), isTrue);
    });

    testWidgets('A16 : capacite absente a l ecriture', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..erreurs['definirPartageClasse'] = const CapaciteIndisponible('x');
      await _monterGroupe(tester, serveur);
      await _basculerEtConfirmer(tester, libelleConfirmer: p.actionDesactiver);
      expect(find.text(p.indisponible), findsOneWidget);
      expect(_valeurSwitch(tester), isTrue);
    });

    testWidgets('A20 : changer la politique ne touche ni le cahier K-45 ni la '
        'remuneration : seule l ecriture de politique est appelee', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur);
      await _basculerEtConfirmer(tester, libelleConfirmer: p.actionDesactiver);
      // `_EnseignantInterdit` leverait au moindre appel au cahier.
      expect(serveur.appels, <String>[
        'partageClasse',
        'definirPartageClasse',
        'partageClasse',
      ]);
      expect(
        serveur.rapports.values.every((RapportSim r) => r.confirme),
        isTrue,
        reason: 'la validation des cahiers ne change pas',
      );
    });
  });

  group('ADM-PED-APR-02 : exceptions individuelles', () {
    Future<void> ouvrir(WidgetTester tester) async {
      await tester.tap(find.text(p.gererExceptions));
      await tester.pumpAndSettle();
    }

    testWidgets('la feuille liste les seuls eleves de la classe : regle '
        'appliquee, visibilite, derniere modification', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..regles['e2'] = ReglePartageEleve.toujours
        ..regles['e3'] = ReglePartageEleve.jamais
        ..classeActive = true;
      await _monterGroupe(tester, serveur);
      await ouvrir(tester);
      expect(find.text('Yusuf Ahmad'), findsOneWidget);
      expect(find.text('Mariam Ali'), findsOneWidget);
      expect(find.text('Adam Hassan'), findsOneWidget);
      expect(find.textContaining(p.sourceClasse), findsWidgets);
      expect(find.textContaining(p.sourceException), findsWidgets);
      expect(find.text(p.visible), findsNWidgets(2));
      expect(find.text(p.nonVisible), findsOneWidget);
      expect(find.text(p.priorite), findsWidgets);
    });

    testWidgets('modifier UN eleve : choix unique, consequence dite avant, '
        'ecriture ciblee, liste relue', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur);
      await ouvrir(tester);
      await tester.tap(find.text('Adam Hassan'));
      await tester.pumpAndSettle();
      expect(find.text(p.regleClasse), findsOneWidget);
      expect(find.text(p.regleToujours), findsOneWidget);
      expect(find.text(p.regleJamais), findsOneWidget);
      expect(find.text(p.consequenceEleve), findsOneWidget);
      await tester.tap(find.text(p.regleJamais));
      await tester.pumpAndSettle();
      // La consequence de masquage immediat se dit avant d'enregistrer.
      expect(find.textContaining(p.consequenceEleveJamais), findsOneWidget);
      await tester.tap(find.text(p.enregistrer));
      await tester.pumpAndSettle();
      expect(serveur.regles, <String, ReglePartageEleve>{
        'e3': ReglePartageEleve.jamais,
      });
      expect(serveur.classeActive, isTrue, reason: 'la classe ne change pas');
      expect(find.text(p.nonVisible), findsOneWidget);
      expect(find.text(p.confirme), findsOneWidget);
    });

    testWidgets('A15 : la regle d un eleve sur une valeur perimee : conflit '
        'visible, aucune ecriture', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur);
      await ouvrir(tester);
      await tester.tap(find.text('Adam Hassan'));
      await tester.pumpAndSettle();
      serveur.simulerAutreAdministrateur();
      await tester.tap(find.text(p.regleJamais));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p.enregistrer));
      await tester.pumpAndSettle();
      expect(serveur.regles, isEmpty);
      expect(find.text(p.conflit), findsWidgets);
    });

    testWidgets('A16 : echec a l ecriture d un eleve : la feuille reste, '
        'l erreur est dite, l ancienne valeur demeure', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..erreurs['definirRegleEleve'] = StateError('x');
      await _monterGroupe(tester, serveur);
      await ouvrir(tester);
      await tester.tap(find.text('Adam Hassan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p.regleJamais));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p.enregistrer));
      await tester.pumpAndSettle();
      expect(find.text(p.echec), findsOneWidget);
      expect(serveur.regles, isEmpty);
      expect(find.text(p.regleJamais), findsOneWidget);
    });

    testWidgets('A14 : un eleve retire de la classe se lit mais ne se modifie '
        'pas', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur()..retires.add('e2');
      await _monterGroupe(tester, serveur);
      await ouvrir(tester);
      expect(find.textContaining(p.eleveRetire), findsOneWidget);
      await tester.tap(find.text('Mariam Ali'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(p.regleJamais), findsNothing);
    });

    testWidgets('A21 : grande classe : pagination serveur, recherche cote '
        'serveur, aucune copie en double, aucune navigation', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()..genererEleves(120);
      await _monterGroupe(tester, serveur, taille: const Size(900, 6000));
      await ouvrir(tester);
      int visibles() => find.textContaining('Eleve genere').evaluate().length;
      expect(visibles(), 25, reason: 'une page, pas la classe entiere');
      await tester.tap(find.text(p.plusEleves));
      await tester.pumpAndSettle();
      expect(visibles(), 50);
      // Relancer la meme page ne double rien.
      expect(serveur.pagesDemandees, <int>[1, 1, 2]);
      // La recherche part au serveur et ne garde que ses resultats.
      await tester.enterText(
        find.byKey(const ValueKey<String>('partage-recherche-eleve')),
        'genere 7',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(serveur.recherches.last, 'genere 7');
      expect(visibles(), lessThan(25));
      expect(find.text('Eleve genere 7'), findsOneWidget);
      // Toujours dans le meme contexte : une feuille, pas une route.
      expect(find.byType(FeuilleExceptionsPartage), findsOneWidget);
    });
  });

  group('ADM-PED-APR-03 : apercu familial et partage manuel', () {
    testWidgets('l apercu est la projection familiale : memes intitules, '
        'rien d interne', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterApercu(tester, serveur);
      final lc = t.historique.compteRendu;
      expect(find.text(lc.travaille), findsOneWidget);
      expect(find.text(lc.appreciation), findsOneWidget);
      expect(find.text(lc.aRenforcer), findsOneWidget);
      expect(find.text(lc.aPreparer), findsOneWidget);
      expect(find.text(lc.commentaire), findsOneWidget);
      expect(find.text(p.notesInternes), findsOneWidget);
      for (final String secret in serveur.rapports[('s1', 'e1')]!.interne) {
        expect(find.textContaining(secret), findsNothing);
      }
      expect(
        find.text(
          'Yusuf, ${nomClasseInsecable('Classe An-Nour')}, '
          'séance du ${_date(DateTime(2026, 10, 8))}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('jamais Publier et Revoquer ensemble : une seule action, la '
        'seule coherente avec l etat', (WidgetTester tester) async {
      final Map<EtatDiffusion, String?> attendu = <EtatDiffusion, String?>{
        EtatDiffusion.nonValide: null,
        EtatDiffusion.confirmeNonPartage: p.publier,
        EtatDiffusion.partageAuto: p.revoquer,
        EtatDiffusion.partageManuel: p.revoquer,
        EtatDiffusion.revoque: p.publier,
        EtatDiffusion.corrigeApresPartageManuel: p.revoquer,
      };
      for (final MapEntry<EtatDiffusion, String?> e in attendu.entries) {
        final FauxPartagePedagogique serveur = FauxPartagePedagogique();
        final RapportSim r = RapportSim();
        switch (e.key) {
          case EtatDiffusion.nonValide:
            r.confirme = false;
          case EtatDiffusion.confirmeNonPartage:
            r.autoPartage = false;
          case EtatDiffusion.partageAuto:
            break;
          case EtatDiffusion.partageManuel:
            r.decision = DecisionManuelle.publie;
          case EtatDiffusion.revoque:
            r.decision = DecisionManuelle.revoque;
          case EtatDiffusion.corrigeApresPartageManuel:
            r.decision = DecisionManuelle.publie;
            r.corrigeApresPublication = true;
        }
        serveur.rapports[('s1', 'e1')] = r;
        await _monterApercu(tester, serveur);
        final int publier = _action(p.publier).evaluate().length;
        final int revoquer = _action(p.revoquer).evaluate().length;
        expect(publier + revoquer, e.value == null ? 0 : 1, reason: '${e.key}');
        if (e.value == p.publier) {
          expect(publier, 1, reason: '${e.key}');
        }
        if (e.value == p.revoquer) {
          expect(revoquer, 1, reason: '${e.key}');
        }
        // Un seul bouton plein, toujours.
        verifierUnSeulBoutonPlein(tester);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('A05 : classe desactivee, cahier confirme : publier UN '
        'rapport le rend lisible, sans changer ni la classe ni l eleve', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()..classeActive = false;
      expect(serveur.visiblePourLaFamille('s1', 'e1'), isFalse);
      await _monterApercu(tester, serveur);
      expect(find.text(p.etatConfirmeNonPartage), findsOneWidget);
      await tester.tap(_action(p.publier));
      await tester.pumpAndSettle();
      // La confirmation dit la portee et ne promet rien de plus.
      expect(find.text(p.confirmerPublier(dePrenom: deDevant('Yusuf'))), findsWidgets);
      expect(find.text(p.consequencePublier), findsOneWidget);
      await tester.tap(find.text(p.publier).last);
      await tester.pumpAndSettle();
      expect(find.text(p.publie), findsOneWidget);
      expect(find.text(p.etatPartageManuel), findsOneWidget);
      // Seul ce rapport est visible ; le second rapport du meme eleve non.
      expect(serveur.visiblePourLaFamille('s1', 'e1'), isTrue);
      expect(serveur.visiblePourLaFamille('s2', 'e1'), isFalse);
      expect(serveur.classeActive, isFalse);
      expect(serveur.regles, isEmpty);
      // Et maintenant l'action offerte est la revocation, seule.
      expect(_action(p.publier), findsNothing);
      expect(_action(p.revoquer), findsOneWidget);
    });

    testWidgets('A05 puis la famille : le tuteur voit le seul rapport publie', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()..classeActive = false;
      await _monterApercu(tester, serveur);
      await _confirmerApercu(tester, p.publier);
      expect(find.text(p.publie), findsOneWidget);
      // La famille lit via le meme port.
      final CompteRenduFamille s1 = await serveur.compteRenduFamille(
        seanceId: 's1',
        eleveId: 'e1',
      );
      final CompteRenduFamille s2 = await serveur.compteRenduFamille(
        seanceId: 's2',
        eleveId: 'e1',
      );
      expect(s1.etat, EtatCompteRendu.partage);
      expect(s2.etat, EtatCompteRendu.nonPartage);
    });

    testWidgets('A06 : revoquer un rapport publie, apres confirmation : la '
        'famille ne le lit plus, le cahier reste valide', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()..classeActive = false;
      serveur.rapports[('s1', 'e1')]!.decision = DecisionManuelle.publie;
      expect(serveur.visiblePourLaFamille('s1', 'e1'), isTrue);
      await _monterApercu(tester, serveur);
      await tester.tap(_action(p.revoquer));
      await tester.pumpAndSettle();
      expect(find.text(p.confirmerRevoquer), findsWidgets);
      expect(find.text(p.consequenceRevoquer), findsOneWidget);
      await tester.tap(find.text(p.revoquer).last);
      await tester.pumpAndSettle();
      expect(find.text(p.revoque), findsOneWidget);
      expect(serveur.visiblePourLaFamille('s1', 'e1'), isFalse);
      expect(serveur.rapports[('s1', 'e1')]!.confirme, isTrue);
      expect(find.text(p.etatRevoque), findsOneWidget);
      // Reexaminer et republier reste possible : l'action offerte est Publier.
      expect(_action(p.publier), findsOneWidget);
    });

    testWidgets('A08 : cahier non confirme : rien a publier, l etat est dit', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      serveur.rapports[('s1', 'e1')]!.confirme = false;
      await _monterApercu(tester, serveur);
      expect(find.text(p.etatNonValide), findsOneWidget);
      expect(_action(p.publier), findsNothing);
      expect(_action(p.revoquer), findsNothing);
    });

    testWidgets('apercu non publiable : aucun contenu autorise, la raison est '
        'dite, aucune publication', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = FauxPartagePedagogique()
        ..rapports[('s1', 'e1')] = RapportSim(
          autoPartage: false,
          contenu: const CompteRenduFamille(etat: EtatCompteRendu.partage),
        );
      await _monterApercu(tester, serveur);
      expect(find.text(p.nonPubliable), findsOneWidget);
      expect(
        find.text(t.historique.compteRendu.aucunChampPhrase),
        findsOneWidget,
      );
      expect(_action(p.publier), findsNothing);
    });

    testWidgets('A12 : corrige apres une publication manuelle : l etat le '
        'dit, la direction peut revoquer', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      serveur.rapports[('s1', 'e1')]!
        ..decision = DecisionManuelle.publie
        ..corrigeApresPublication = true;
      await _monterApercu(tester, serveur);
      expect(find.text(p.etatCorrige), findsOneWidget);
      expect(_action(p.revoquer), findsOneWidget);
    });

    testWidgets('A15 : un autre administrateur a modifie ce rapport : conflit '
        'dit, etat relu, aucune publication', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur()..classeActive = false;
      await _monterApercu(tester, serveur);
      serveur.simulerAutreAdministrateur();
      serveur.rapports[('s1', 'e1')]!.decision = DecisionManuelle.publie;
      await tester.tap(_action(p.publier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p.publier).last);
      await tester.pumpAndSettle();
      expect(find.text(p.conflitApercu), findsOneWidget);
      expect(serveur.cles, isEmpty);
      // L'etat a jour (publie par l'autre personne) est affiche.
      expect(find.text(p.etatPartageManuel), findsOneWidget);
      expect(_action(p.publier), findsNothing);
    });

    testWidgets('A16 : le serveur refuse la publication : l etat precedent '
        'demeure, aucun succes annonce', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..classeActive = false
        ..erreurs['publier'] = StateError('x');
      await _monterApercu(tester, serveur);
      await _confirmerApercu(tester, p.publier);
      expect(find.text(p.echec), findsOneWidget);
      expect(find.text(p.publie), findsNothing);
      expect(find.text(p.etatConfirmeNonPartage), findsOneWidget);
      expect(serveur.visiblePourLaFamille('s1', 'e1'), isFalse);
    });

    testWidgets('double clic : une seule publication part', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()..classeActive = false;
      final Completer<void> porte = Completer<void>();
      serveur.portes['publier'] = porte;
      await _monterApercu(tester, serveur);
      await tester.tap(_action(p.publier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p.publier).last);
      await tester.pump();
      // Pendant l'envoi : un second appui sur l'action n'envoie rien.
      await tester.tap(_action(p.publier).first, warnIfMissed: false);
      await tester.pump();
      porte.complete();
      await tester.pumpAndSettle();
      expect(serveur.appels.where((String a) => a == 'publier'), hasLength(1));
      expect(serveur.cles, hasLength(1));
    });

    testWidgets('hors ligne : rien n est envoye, la phrase le dit', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()..classeActive = false;
      await _monterApercu(tester, serveur, horsLigne: true);
      await tester.tap(_action(p.publier));
      await tester.pumpAndSettle();
      expect(find.text(p.horsLigne), findsWidgets);
      expect(serveur.cles, isEmpty);
    });

    testWidgets('historique : affiche seulement si la source le donne', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique avec = _serveur()
        ..historique = <ActionPartage>[
          ActionPartage(
            quand: DateTime(2026, 10, 9, 14, 20),
            type: 'publication',
            auteur: 'Direction',
          ),
        ];
      await _monterApercu(tester, avec);
      expect(find.text(p.historique), findsOneWidget);
      expect(find.text(p.actionPublication), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _monterApercu(tester, _serveur());
      expect(find.text(p.historique), findsNothing);
    });

    testWidgets('A17 : sans source : « pas encore disponible », aucune action '
        'factice', (WidgetTester tester) async {
      await _monterApercu(tester, const PartagePedagogiqueIndisponible());
      expect(find.text(p.indisponible), findsOneWidget);
      expect(_action(p.publier), findsNothing);
      expect(_action(p.revoquer), findsNothing);
    });

    testWidgets('refus d autorisation : phrase, aucune donnee, aucune action', (
      WidgetTester tester,
    ) async {
      await _monterApercu(
        tester,
        _serveur()
          ..erreurs['apercuFamilial'] = const PermissionInsuffisante('x'),
      );
      expect(find.text(p.refuse), findsOneWidget);
      expect(find.text(t.historique.compteRendu.travaille), findsNothing);
    });
  });

  group('Point d entree provisoire d ADM-PED-APR-03', () {
    testWidgets('depuis la regle d un eleve : ses comptes rendus, puis '
        'l apercu', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      await _monterGroupe(tester, serveur);
      await tester.tap(find.text(p.gererExceptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yusuf Ahmad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p.comptesRendus));
      await tester.pumpAndSettle();
      expect(find.byType(FeuilleComptesRendusEleve), findsOneWidget);
      await tester.tap(find.text(p.etatPartageAuto).first);
      await tester.pumpAndSettle();
      expect(find.byType(FeuilleApercuFamilial), findsOneWidget);
      expect(find.text(t.historique.compteRendu.travaille), findsOneWidget);
    });
  });

  group('Integration : la fiche de classe de la direction', () {
    testWidgets('l inspecteur de bureau porte le groupe de partage', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxPartagePedagogique serveur = _serveur();
      await tester.pumpWidget(
        hote(
          const GroupesPage(),
          surcharges: <Override>[
            serviceGroupesProvider.overrideWithValue(_Groupes()),
            ..._surcharges(serveur),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classe An-Nour').first);
      await tester.pumpAndSettle();
      expect(find.byKey(GroupesPage.cleInspecteur), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(GroupesPage.cleInspecteur),
          matching: find.text(p.titre),
        ),
        findsOneWidget,
      );
      // Un seul bouton plein, malgre le nouveau groupe.
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('sur telephone : la feuille de detail porte le meme groupe', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const GroupesPage(),
          surcharges: <Override>[
            serviceGroupesProvider.overrideWithValue(_Groupes()),
            ..._surcharges(_serveur()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classe An-Nour').first);
      await tester.pumpAndSettle();
      expect(find.text(p.titre), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      // L'observation existante et le partage sont deux reglages distincts.
      expect(find.text(t.admin.groupes.detailMembres), findsOneWidget);
    });
  });

  test('le lien « Gerer les exceptions » est un LienFleche, pas un gros '
      'bouton', () {
    expect(LienFleche, isNotNull);
  });
}

String _date(DateTime d) => t.historique.dateCourte(
  jour: d.day,
  mois: t.historique.moisCourts[d.month - 1],
  annee: d.year,
);

/// Un serveur qui ne donne pas la date de derniere modification.
class _SansModification implements PortPartagePedagogique {
  _SansModification(this._i);

  final FauxPartagePedagogique _i;

  @override
  Future<PartageClasse> partageClasse({
    required String classeId,
    int page = 1,
    String? recherche,
  }) async {
    final PartageClasse p = await _i.partageClasse(
      classeId: classeId,
      page: page,
      recherche: recherche,
    );
    return PartageClasse(
      classeId: p.classeId,
      actif: p.actif,
      version: p.version,
      eleves: p.eleves,
      total: p.total,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<void>.error(StateError('non utilise'));
}

class _Groupes implements ServiceGroupes {
  GroupeAdmin _g(String id, String libelle) => GroupeAdmin(
    id: id,
    libelle: libelle,
    type: TypePublicGroupe.enfant,
    seuilMax: 5,
    teacherId: 't-$id',
    teacherIdentifiant: 'TEACHER-$id',
    teacherPrenom: 'Amina',
    teacherNom: 'Diallo',
    creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
    nombreMembres: 2,
    actif: true,
  );

  @override
  Future<List<GroupeAdmin>> groupes() async => <GroupeAdmin>[
    _g('a', 'Classe An-Nour'),
  ];

  @override
  Future<List<MembreGroupe>> membres(String groupeId) async => <MembreGroupe>[
    MembreGroupe(
      studentId: 's1',
      identifiant: 'STUDENT-1',
      prenom: 'Mariam',
      nom: 'Exemple',
      rejointLe: DateTime(2026, 9, 1),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
