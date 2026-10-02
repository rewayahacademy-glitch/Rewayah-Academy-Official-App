// EA-10 : la recharge du foyer, atteinte depuis la VRAIE coquille adulte
// (K-07) : on tape la VRAIE destination « Mon espace », la VRAIE ligne « Ma
// famille », la VRAIE ligne « Paiements du foyer », puis le VRAI bouton
// « Recharger ». Un, plusieurs ou tous les beneficiaires, une offre par
// beneficiaire lue dans les donnees (F11), le recapitulatif separe et le
// total tels que rendus (F12), « Modifier » sans perte, et un paiement qui
// s'arrete sur un etat honnete (F13). Puis les etats : chargement, erreur,
// hors ligne, indisponible, vide, remise rendue, coupure (D5), double envoi.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/soldes_foyer.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart'
    show paiementsFoyerKey;
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

const String _mamadou = DonneesAdulteDemo.mamadouId;
const String _mariama = DonneesAdulteDemo.mariamaId;
const String _aicha = DonneesAdulteDemo.aichaId;
const String _oumar = DonneesAdulteDemo.oumarId;
const String _offreA = 'demo-offre-a';
const String _offreB = 'demo-offre-b';

void main() {
  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<GoRouter> monterCoquille(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoAdulte('dev'),
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
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return routeur;
  }

  Future<void> taper(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> choisir(WidgetTester tester, String id, String offre) async {
    await taper(tester, find.byKey(RechargeFoyerPage.caseDe(id)));
    await taper(tester, find.byKey(RechargeFoyerPage.offreDe(id, offre)));
  }

  ActionPrincipale bouton(WidgetTester tester, Key cle) =>
      tester.widget<ActionPrincipale>(find.byKey(cle));

  bool coche(WidgetTester tester, String id) =>
      tester.widget<Checkbox>(find.byKey(RechargeFoyerPage.caseDe(id))).value ??
      false;

  Finder dans(Key parent, Finder f) =>
      find.descendant(of: find.byKey(parent), matching: f);

  /// Aucun chiffre economique invente (F12), aucun moyen de paiement (F13),
  /// aucune Classe (F6), jamais « admin » (K-53.6), jamais un succes.
  void rienDInvente() {
    for (final Pattern interdit in <Pattern>[
      '%',
      '=',
      'Visa',
      '4242',
      RegExp('pack', caseSensitive: false),
      RegExp('admin', caseSensitive: false),
      RegExp('réussi', caseSensitive: false),
      RegExp('budget', caseSensitive: false),
      DonneesAdulteDemo.classeTitulaire,
      'Classe',
    ]) {
      expect(find.textContaining(interdit), findsNothing, reason: '$interdit');
    }
  }

  testWidgets('Mon espace > Ma famille > Paiements du foyer > Recharger, '
      'tapes : choix, verification, Modifier sans perte, etat honnete', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));

    await tester.tap(find.text(t.adulte.nav.monEspace).first);
    await tester.pumpAndSettle();
    await taper(
      tester,
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.maFamille),
      ),
    );
    await taper(
      tester,
      find.descendant(
        of: find.byKey(paiementsFoyerKey),
        matching: find.text(t.adulte.famille.paiementsFoyer),
      ),
    );
    await taper(tester, find.byKey(SoldesFoyerSection.rechargerKey));

    // Etape 1, « Nouvelle recharge » (planche 4.2).
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    expect(find.byType(PaiementsComptePage), findsNothing);
    expect(find.text(t.adulte.recharge.titre), findsOneWidget);
    expect(find.text(t.commun.etape.sur(n: 1, total: 2)), findsOneWidget);
    // Une ligne par beneficiaire autorise, sa photo ou ses initiales (K-44),
    // son solde tel que rendu, une case.
    for (final (String id, String prenom, String solde)
        in <(String, String, String)>[
          (_mamadou, 'Mamadou', '120 unités'),
          (_mariama, 'Mariama', '80 unités'),
          (_aicha, 'Aïcha', '15 unités'),
          (_oumar, 'Oumar', '0 unité'),
        ]) {
      expect(find.text(prenom), findsOneWidget, reason: prenom);
      expect(find.text(solde), findsOneWidget, reason: solde);
      expect(coche(tester, id), isFalse, reason: prenom);
    }
    expect(
      find.descendant(
        of: find.byType(GroupeReglages),
        matching: find.byType(PhotoEleve),
      ),
      findsNWidgets(4),
    );
    // Aucune offre proposee d'avance (F11), aucun bouton actif sans choix,
    // et la phrase qui dit pourquoi.
    expect(find.byType(ChoiceCardGroup), findsNothing);
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNull);
    expect(find.text(t.adulte.recharge.raisonAucun), findsOneWidget);
    expect(find.byType(ActionPrincipale), findsOneWidget);
    rienDInvente();

    // Mamadou coche : ses offres apparaissent, aucune n'est choisie.
    await taper(tester, find.byKey(RechargeFoyerPage.caseDe(_mamadou)));
    expect(coche(tester, _mamadou), isTrue);
    expect(find.byType(ChoiceCardGroup), findsOneWidget);
    expect(
      find.text(t.adulte.recharge.offrePour(prenom: 'Mamadou')),
      findsOneWidget,
    );
    // Les offres telles que rendues (planche 4.3), sans « Autre ».
    expect(find.text('5,00 €'), findsOneWidget);
    expect(find.text('10,00 €'), findsOneWidget);
    expect(find.text('120 unités'), findsNWidgets(2));
    expect(find.text(t.choix.autre), findsNothing);
    expect(find.text(t.adulte.recharge.raisonOffre), findsOneWidget);
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNull);

    await taper(
      tester,
      find.byKey(RechargeFoyerPage.offreDe(_mamadou, _offreB)),
    );
    expect(find.byKey(RechargeFoyerPage.raisonKey), findsNothing);
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNotNull);
    await choisir(tester, _aicha, _offreA);
    expect(find.byType(ChoiceCardGroup), findsNWidgets(2));

    // « Verifier la recharge » : etape 2 (planche 4.3).
    await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    expect(find.text(t.adulte.recharge.verifierTitre), findsOneWidget);
    expect(find.text(t.commun.etape.sur(n: 2, total: 2)), findsOneWidget);
    expect(find.text(t.adulte.recharge.recapitulatif), findsOneWidget);
    // Une ligne par beneficiaire choisi, separee (F11) : qui recoit, montant
    // paye, solde attribue, statut ; aucune remise rendue, aucune ligne.
    for (final (String id, String prenom, String montant, String solde)
        in <(String, String, String, String)>[
          (_mamadou, 'Mamadou', '10,00 €', '120 unités'),
          (_aicha, 'Aïcha', '5,00 €', '60 unités'),
        ]) {
      final Key ligne = RechargeFoyerPage.ligneDe(id);
      expect(dans(ligne, find.text(prenom)), findsOneWidget);
      expect(dans(ligne, find.byType(PhotoEleve)), findsOneWidget);
      expect(dans(ligne, find.text(montant)), findsOneWidget);
      expect(dans(ligne, find.text(solde)), findsOneWidget);
      expect(
        dans(ligne, find.text(DonneesAdulteDemo.statutAvantPaiement)),
        findsOneWidget,
      );
      expect(dans(ligne, find.byType(LigneCleValeur)), findsNWidgets(3));
    }
    expect(find.byKey(RechargeFoyerPage.ligneDe(_mariama)), findsNothing);
    expect(find.byKey(RechargeFoyerPage.ligneDe(_oumar)), findsNothing);
    expect(find.textContaining('Remise'), findsNothing);
    // Le total rendu, et « Payer {total} » au bord de fin, 16 sous le total.
    expect(
      dans(RechargeFoyerPage.totalKey, find.text('15,00 €')),
      findsOneWidget,
    );
    final Finder payer = find.byKey(RechargeFoyerPage.payerKey);
    expect(
      dans(
        RechargeFoyerPage.payerKey,
        find.text(t.adulte.recharge.payer(montant: '15,00 €')),
      ),
      findsOneWidget,
    );
    final Finder total = find.byKey(RechargeFoyerPage.totalKey);
    expect(
      tester.getTopLeft(payer).dy - tester.getBottomLeft(total).dy,
      AppSpacing.lg,
    );
    expect(
      tester.getTopRight(payer).dx,
      moreOrLessEquals(tester.getTopRight(total).dx, epsilon: 0.5),
    );
    expect(find.byType(ActionPrincipale), findsOneWidget);
    rienDInvente();

    // « Modifier » sur la ligne d'Aicha : l'etape 1, sans rien perdre.
    await taper(tester, find.byKey(RechargeFoyerPage.modifierDe(_aicha)));
    expect(find.text(t.adulte.recharge.titre), findsOneWidget);
    expect(coche(tester, _mamadou), isTrue);
    expect(coche(tester, _aicha), isTrue);
    expect(coche(tester, _mariama), isFalse);
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNotNull);
    // Aicha passe a l'autre offre : le recapitulatif suit.
    await taper(tester, find.byKey(RechargeFoyerPage.offreDe(_aicha, _offreB)));
    await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    expect(
      dans(RechargeFoyerPage.ligneDe(_aicha), find.text('10,00 €')),
      findsOneWidget,
    );
    expect(
      dans(RechargeFoyerPage.totalKey, find.text('20,00 €')),
      findsOneWidget,
    );

    // Payer : un etat honnete, jamais « reussi » (F13).
    await taper(tester, find.byKey(RechargeFoyerPage.payerKey));
    expect(
      find.text(t.adulte.recharge.paiementIndisponibleTitre),
      findsOneWidget,
    );
    expect(
      find.text(t.adulte.recharge.paiementIndisponiblePhrase),
      findsOneWidget,
    );
    expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
    expect(find.byKey(RechargeFoyerPage.modifierDe(_aicha)), findsNothing);
    rienDInvente();
    await taper(tester, find.text(t.adulte.recharge.revenirPaiements));
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byType(FoyerPage), findsNothing);
  });

  testWidgets('tous les beneficiaires : « Tout selectionner », puis « Tout '
      'deselectionner » ; le retour de l\'etape 1 rend les paiements', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.recharge));
    final Finder lien = find.byKey(RechargeFoyerPage.toutSelectionnerKey);
    expect(
      find.descendant(
        of: lien,
        matching: find.text(t.adulte.recharge.toutSelectionner),
      ),
      findsOneWidget,
    );
    // Le lien est au-dessus de la liste (UX_REVIEW_07 ligne 15 b).
    expect(
      tester.getBottomLeft(lien).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(GroupeReglages)).dy),
    );
    await taper(tester, lien);
    for (final String id in <String>[_mamadou, _mariama, _aicha, _oumar]) {
      expect(coche(tester, id), isTrue);
    }
    expect(find.byType(ChoiceCardGroup), findsNWidgets(4));
    expect(find.text(t.adulte.recharge.toutDeselectionner), findsOneWidget);
    // Rien n'est reparti : sans offre pour chacun, le bouton attend.
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNull);
    for (final String id in <String>[_mamadou, _mariama, _aicha, _oumar]) {
      await taper(tester, find.byKey(RechargeFoyerPage.offreDe(id, _offreA)));
    }
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNotNull);
    await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    for (final String id in <String>[_mamadou, _mariama, _aicha, _oumar]) {
      expect(find.byKey(RechargeFoyerPage.ligneDe(id)), findsOneWidget);
    }
    // Le second adulte : ses initiales, jamais une photo rendue (Q4).
    final PhotoEleve photo = tester.widget<PhotoEleve>(
      dans(RechargeFoyerPage.ligneDe(_mariama), find.byType(PhotoEleve)),
    );
    expect(photo.cleAvatar, isNull);
    expect(
      dans(RechargeFoyerPage.totalKey, find.text('20,00 €')),
      findsOneWidget,
    );
    // Retour de l'etape 2 : l'etape 1 ; puis tout deselectionne.
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(RechargeFoyerPage.toutSelectionnerKey));
    expect(find.byType(ChoiceCardGroup), findsNothing);
    expect(find.text(t.adulte.recharge.raisonAucun), findsOneWidget);
    // Retour de l'etape 1 : les paiements du foyer.
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(PaiementsComptePage), findsOneWidget);
  });

  testWidgets('erreur reseau de la demonstration : « Le paiement n\'a pas ete '
      'confirme », rien de plus (D5), « Payer » reste', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.recharge,
        etat: EtatDemoAdulte.erreurReseau,
      ),
    );
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    await choisir(tester, _oumar, _offreA);
    await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    await taper(tester, find.byKey(RechargeFoyerPage.payerKey));
    expect(find.text(t.adulte.recharge.paiementEchecTitre), findsOneWidget);
    expect(find.text(t.adulte.recharge.paiementEchecPhrase), findsOneWidget);
    expect(find.textContaining("n'a pas été payé"), findsNothing);
    expect(find.textContaining("n'est pas parti"), findsNothing);
    expect(bouton(tester, RechargeFoyerPage.payerKey).onPress, isNotNull);
    rienDInvente();
  });

  testWidgets('double soumission de la demonstration : le bouton attend, '
      'puis l\'etat honnete', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.recharge,
        etat: EtatDemoAdulte.doubleSoumission,
      ),
    );
    await choisir(tester, _aicha, _offreA);
    await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    await tester.tap(find.byKey(RechargeFoyerPage.payerKey));
    await tester.pump();
    expect(bouton(tester, RechargeFoyerPage.payerKey).enCours, isTrue);
    // Un second appui pendant l'attente ne change rien.
    await tester.tap(find.byKey(RechargeFoyerPage.payerKey));
    await tester.pump();
    expect(bouton(tester, RechargeFoyerPage.payerKey).enCours, isTrue);
    await tester.pump(latenceSimulee);
    await tester.pumpAndSettle();
    expect(
      find.text(t.adulte.recharge.paiementIndisponibleTitre),
      findsOneWidget,
    );
  });

  testWidgets('le second adulte n\'atteint jamais la recharge (F7)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.recharge,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.byType(RechargeFoyerPage), findsNothing);
    expect(find.text('Aïcha'), findsNothing);
  });

  group('etats de la recharge', () {
    const List<BeneficiaireRecharge> exemple = <BeneficiaireRecharge>[
      BeneficiaireRecharge(
        id: 'b1',
        prenom: 'Yusuf',
        soldeRendu: 'solde rendu',
        offres: <OffreRecharge>[
          OffreRecharge(id: 'o1', libelle: 'offre rendue', detail: 'detail'),
        ],
      ),
    ];

    Future<void> monter(
      WidgetTester tester, {
      PortRechargeFoyer? port,
      Stream<bool>? horsLigne,
      VoidCallback? onTerminee,
    }) async {
      taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _page(
          horsLigne: horsLigne ?? Stream<bool>.value(false),
          overrides: <Override>[
            if (port != null) portRechargeFoyerProvider.overrideWithValue(port),
          ],
          child: RechargeFoyerPage(
            onAbandon: () {},
            onTerminee: onTerminee ?? () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    EtatSysteme? etat(WidgetTester tester) {
      final Iterable<EtatSysteme> e = tester.widgetList<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      return e.isEmpty ? null : e.first;
    }

    Future<void> jusquAuRecapitulatif(WidgetTester tester) async {
      await choisir(tester, 'b1', 'o1');
      await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    }

    testWidgets('chargement : le squelette, sans faux nom ni bouton', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(
        lecture: Completer<List<BeneficiaireRecharge>>(),
      );
      await monter(tester, port: port);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.adulte.recharge.titre), findsOneWidget);
      expect(find.byKey(RechargeFoyerPage.verifierKey), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('erreur : dite, avec « Reessayer », qui relit', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(erreurLecture: StateError('panne'));
      await monter(tester, port: port);
      await tester.pumpAndSettle();
      expect(etat(tester)?.nature, NatureEtat.echecServeur);
      expect(find.byKey(RechargeFoyerPage.verifierKey), findsNothing);
      final int avant = port.lectures;
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await tester.pumpAndSettle();
      expect(port.lectures, avant + 1);
    });

    testWidgets('hors ligne : dit comme tel', (WidgetTester tester) async {
      await monter(
        tester,
        port: _Port(erreurLecture: StateError('coupure')),
        horsLigne: Stream<bool>.value(true),
      );
      await tester.pumpAndSettle();
      expect(etat(tester)?.nature, NatureEtat.horsLigne);
    });

    testWidgets('indisponible : le port reel, la dependance EA-BR-24', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      await tester.pumpAndSettle();
      final EtatSysteme? e = etat(tester);
      expect(e?.nature, NatureEtat.indisponible);
      expect(e?.dependance, 'EA-BR-24');
      expect(e?.titre, t.adulte.recharge.indisponibleTitre);
      expect(find.byKey(RechargeFoyerPage.verifierKey), findsNothing);
    });

    testWidgets('vide : aucun beneficiaire, aucun bouton', (
      WidgetTester tester,
    ) async {
      await monter(tester, port: _Port(liste: const <BeneficiaireRecharge>[]));
      await tester.pumpAndSettle();
      expect(etat(tester)?.nature, NatureEtat.aucunResultat);
      expect(
        find.text(t.adulte.paiements.aucunBeneficiaireTitre),
        findsOneWidget,
      );
      expect(find.byKey(RechargeFoyerPage.verifierKey), findsNothing);
    });

    testWidgets('hors ligne a l\'etape 1 : rien ne part, la raison dite', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        port: _Port(liste: exemple),
        horsLigne: Stream<bool>.value(true),
      );
      await tester.pumpAndSettle();
      await choisir(tester, 'b1', 'o1');
      expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNull);
      expect(find.text(t.adulte.recharge.horsLigneVerifier), findsOneWidget);
    });

    testWidgets('verification manquee : dite, les choix gardes', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        port: _Port(liste: exemple, erreurVerification: true),
      );
      await tester.pumpAndSettle();
      await jusquAuRecapitulatif(tester);
      expect(
        find.text(t.adulte.recharge.verificationEchecTitre),
        findsOneWidget,
      );
      expect(find.text(t.adulte.recharge.titre), findsOneWidget);
      expect(coche(tester, 'b1'), isTrue);
      expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNotNull);
    });

    testWidgets('remise rendue : sa ligne, avec SON libelle ; total rendu', (
      WidgetTester tester,
    ) async {
      await monter(tester, port: _Port(liste: exemple, remise: true));
      await tester.pumpAndSettle();
      await jusquAuRecapitulatif(tester);
      final Key ligne = RechargeFoyerPage.ligneDe('b1');
      expect(dans(ligne, find.text('libelle du serveur')), findsOneWidget);
      expect(dans(ligne, find.text('remise rendue')), findsOneWidget);
      expect(dans(ligne, find.byType(LigneCleValeur)), findsNWidgets(4));
      expect(
        dans(RechargeFoyerPage.totalKey, find.text('total rendu')),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne a l\'etape 2 : « Payer » inactif, la raison dite', (
      WidgetTester tester,
    ) async {
      final StreamController<bool> reseau = StreamController<bool>();
      addTearDown(reseau.close);
      await monter(
        tester,
        port: _Port(liste: exemple),
        horsLigne: reseau.stream,
      );
      reseau.add(false);
      await tester.pumpAndSettle();
      await jusquAuRecapitulatif(tester);
      expect(bouton(tester, RechargeFoyerPage.payerKey).onPress, isNotNull);
      reseau.add(true);
      await tester.pumpAndSettle();
      expect(bouton(tester, RechargeFoyerPage.payerKey).onPress, isNull);
      expect(find.text(t.adulte.recharge.horsLignePayer), findsOneWidget);
    });

    testWidgets('double envoi : le bouton attend, un seul paiement part, la '
        'meme cle a la nouvelle tentative', (WidgetTester tester) async {
      final _Port port = _Port(liste: exemple, paiementSuspendu: true);
      await monter(tester, port: port);
      await tester.pumpAndSettle();
      await jusquAuRecapitulatif(tester);
      await tester.tap(find.byKey(RechargeFoyerPage.payerKey));
      await tester.pump();
      await tester.tap(find.byKey(RechargeFoyerPage.payerKey));
      await tester.pump();
      expect(port.cles, hasLength(1));
      expect(bouton(tester, RechargeFoyerPage.payerKey).enCours, isTrue);
      // La reponse est perdue : D5, puis une nouvelle tentative, meme cle.
      port.reponse.completeError(StateError('coupure'));
      await tester.pumpAndSettle();
      expect(find.text(t.adulte.recharge.paiementEchecTitre), findsOneWidget);
      port.paiementSuspendu = false;
      await taper(tester, find.byKey(RechargeFoyerPage.payerKey));
      expect(port.cles, hasLength(2));
      expect(port.cles.toSet(), hasLength(1));
    });

    testWidgets('etat rendu par le serveur : affiche tel quel, sans succes '
        'local, et le seul retour', (WidgetTester tester) async {
      bool termine = false;
      await monter(
        tester,
        port: _Port(liste: exemple),
        onTerminee: () => termine = true,
      );
      await tester.pumpAndSettle();
      await jusquAuRecapitulatif(tester);
      await taper(tester, find.byKey(RechargeFoyerPage.payerKey));
      expect(find.text('etat redige par le serveur'), findsOneWidget);
      expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
      expect(find.byType(ActionPrincipale), findsOneWidget);
      await taper(tester, find.text(t.adulte.recharge.revenirPaiements));
      expect(termine, isTrue);
    });
  });
}

/// Un port de recharge que le test pilote.
class _Port implements PortRechargeFoyer {
  _Port({
    this.liste = const <BeneficiaireRecharge>[],
    this.lecture,
    this.erreurLecture,
    this.erreurVerification = false,
    this.remise = false,
    this.paiementSuspendu = false,
  });

  final List<BeneficiaireRecharge> liste;
  final Completer<List<BeneficiaireRecharge>>? lecture;
  final Error? erreurLecture;
  final bool erreurVerification;
  final bool remise;
  bool paiementSuspendu;
  int lectures = 0;
  final List<String> cles = <String>[];
  final Completer<String> reponse = Completer<String>();

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() async {
    lectures++;
    final Completer<List<BeneficiaireRecharge>>? c = lecture;
    if (c != null) return c.future;
    final Error? e = erreurLecture;
    if (e != null) throw e;
    return liste;
  }

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) async {
    if (erreurVerification) throw StateError('coupure');
    return RecapitulatifRecharge(
      id: 'r1',
      total: 'total rendu',
      lignes: <LigneRecapitulatif>[
        for (final ChoixRecharge c in choix)
          LigneRecapitulatif(
            beneficiaireId: c.beneficiaireId,
            prenom: 'Yusuf',
            montantPaye: 'montant rendu',
            soldeAttribue: 'solde attribue',
            statut: 'statut rendu',
            remise: remise
                ? const RemiseRendue(
                    libelle: 'libelle du serveur',
                    valeur: 'remise rendue',
                  )
                : null,
          ),
      ],
    );
  }

  @override
  Future<String> payer({required String recapitulatifId, required String cle}) {
    cles.add(cle);
    if (paiementSuspendu) return reponse.future;
    return Future<String>.value('etat redige par le serveur');
  }
}

Widget _page({
  required Widget child,
  required Stream<bool> horsLigne,
  List<Override> overrides = const <Override>[],
}) => ProviderScope(
  overrides: <Override>[
    horsLigneProvider.overrideWith((Ref _) => horsLigne),
    ...overrides,
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    ),
  ),
);
