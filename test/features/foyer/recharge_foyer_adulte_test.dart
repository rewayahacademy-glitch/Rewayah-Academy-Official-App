// EA-10 : la recharge du foyer, atteinte depuis la VRAIE coquille adulte
// (K-07) : on tape la VRAIE destination « Mon espace », la VRAIE ligne « Ma
// famille », la VRAIE ligne « Paiements du foyer », puis le VRAI bouton
// « Recharger ». Un, plusieurs ou tous les beneficiaires, un montant par
// beneficiaire choisi parmi ceux que les donnees proposent (FI-7, guide V4
// §5.3 ; le montant de la demonstration EA reprend le prix de chaque offre),
// le recapitulatif separe et le total tels que rendus (F12), « Modifier »
// sans perte, le moyen de paiement web seul, et un paiement qui s'arrete sur
// un etat honnete (F13). Puis les etats : chargement, erreur,
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
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
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

  /// Le montant de la demonstration qui reprend le prix de [offre] : le
  /// premier montant propose (offre A) ou le second (offre B).
  Future<void> montant(WidgetTester tester, String id, String offre) async {
    for (int i = 0; i < (offre == _offreB ? 2 : 1); i++) {
      await taper(tester, find.byKey(RechargeFoyerPage.plusDe(id)));
    }
  }

  Future<void> choisir(WidgetTester tester, String id, String offre) async {
    await taper(tester, find.byKey(RechargeFoyerPage.caseDe(id)));
    await montant(tester, id, offre);
  }

  bool actif(WidgetTester tester, Key cle) =>
      find.byKey(cle).evaluate().isNotEmpty &&
      tester.widget<BoutonIcone>(find.byKey(cle)).onPress != null;

  ActionPrincipale bouton(WidgetTester tester, Key cle) =>
      tester.widget<ActionPrincipale>(find.byKey(cle));

  bool coche(WidgetTester tester, String id) =>
      tester.widget<Checkbox>(find.byKey(RechargeFoyerPage.caseDe(id))).value ??
      false;

  Finder dans(Key parent, Finder f) =>
      find.descendant(of: find.byKey(parent), matching: f);

  /// Aucun chiffre economique invente (F12), aucune carte enregistree ni
  /// rail de magasin (guide V4 §1.6), aucune Classe (F6), jamais « admin »
  /// (K-53.6), jamais un succes.
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
      RegExp('App Store', caseSensitive: false),
      RegExp('Play', caseSensitive: false),
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
    await taper(tester, find.byKey(PaiementsComptePage.rechargerKey));

    // Etape 1, « Nouvelle recharge » (planche 4.2).
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    expect(find.byType(PaiementsComptePage), findsNothing);
    expect(find.text(t.adulte.recharge.titre), findsOneWidget);
    expect(find.text(t.commun.etape.sur(n: 1, total: 2)), findsOneWidget);
    // Une ligne par beneficiaire autorise, sa photo ou ses initiales (K-44),
    // son solde tel que rendu, une case.
    for (final (String id, String prenom, String solde)
        in <(String, String, String)>[
          (_mamadou, 'Mamadou', t.adulte.demo.donnees.soldeTitulaire),
          (_mariama, 'Mariama', t.adulte.demo.donnees.soldeSecondAdulte),
          (_aicha, 'Aïcha', t.adulte.demo.donnees.soldeAicha),
          (_oumar, 'Oumar', t.adulte.demo.donnees.soldeOumar),
        ]) {
      expect(find.text(prenom), findsOneWidget, reason: prenom);
      expect(find.text(solde), findsOneWidget, reason: solde);
      expect(coche(tester, id), isFalse, reason: prenom);
    }
    expect(
      find.descendant(
        of: find.byKey(RechargeFoyerPage.profilsKey),
        matching: find.byType(PhotoEleve),
      ),
      findsNWidgets(4),
    );
    // Aucun montant choisi d'avance (F11) : chaque montant est desactive
    // tant que son profil n'est pas coche (guide V4 §5.3), aucun bouton
    // actif sans choix, et la phrase qui dit pourquoi.
    for (final String id in <String>[_mamadou, _mariama, _aicha, _oumar]) {
      expect(actif(tester, RechargeFoyerPage.plusDe(id)), isFalse);
      expect(actif(tester, RechargeFoyerPage.moinsDe(id)), isFalse);
    }
    expect(find.byKey(RechargeFoyerPage.repartitionKey), findsOneWidget);
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNull);
    expect(find.text(t.adulte.recharge.raisonAucun), findsOneWidget);
    expect(find.byType(ActionPrincipale), findsOneWidget);
    rienDInvente();

    // Mamadou coche : son montant s'active, aucun n'est choisi.
    await taper(tester, find.byKey(RechargeFoyerPage.caseDe(_mamadou)));
    expect(coche(tester, _mamadou), isTrue);
    expect(actif(tester, RechargeFoyerPage.plusDe(_mamadou)), isTrue);
    expect(actif(tester, RechargeFoyerPage.moinsDe(_mamadou)), isFalse);
    expect(actif(tester, RechargeFoyerPage.plusDe(_mariama)), isFalse);
    expect(find.text(t.adulte.demo.donnees.soldeTitulaire), findsOneWidget);
    // Le montant de Mamadou dans SA ligne, avant la ligne suivante.
    final Finder ligneMamadou = find.byKey(
      RechargeFoyerPage.profilDe(_mamadou),
    );
    expect(
      find.descendant(
        of: ligneMamadou,
        matching: find.byKey(RechargeFoyerPage.plusDe(_mamadou)),
      ),
      findsOneWidget,
    );
    expect(
      tester.getBottomLeft(ligneMamadou).dy,
      lessThan(
        tester.getTopLeft(find.byKey(RechargeFoyerPage.caseDe(_mariama))).dy,
      ),
    );
    expect(find.text(t.choix.autre), findsNothing);
    expect(find.text(t.adulte.recharge.raisonMontant), findsOneWidget);
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNull);

    // Deux pas : le second montant propose ; un pas en arriere puis en avant
    // le garde, et « plus » s'arrete au dernier montant rendu.
    await montant(tester, _mamadou, _offreB);
    // Le prix de la demonstration EA reste MARQUE « (démonstration) » des
    // l'etape 1, comme au recapitulatif : jamais un prix nu (F12, revue
    // EA-R m4).
    expect(
      dans(
        RechargeFoyerPage.montantDe(_mamadou),
        find.text(t.adulte.demo.donnees.prixOffreB),
      ),
      findsOneWidget,
    );
    for (final Montant prix in <Montant>[
      DonneesAdulteDemo.montantOffreA,
      DonneesAdulteDemo.montantOffreB,
    ]) {
      expect(find.text(formaterMontant(prix)), findsNothing, reason: '$prix');
    }
    expect(actif(tester, RechargeFoyerPage.plusDe(_mamadou)), isFalse);
    expect(actif(tester, RechargeFoyerPage.moinsDe(_mamadou)), isTrue);
    expect(find.byKey(RechargeFoyerPage.raisonKey), findsNothing);
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNotNull);
    await choisir(tester, _aicha, _offreA);
    expect(
      dans(
        RechargeFoyerPage.montantDe(_aicha),
        find.text(t.adulte.demo.donnees.prixOffreA),
      ),
      findsOneWidget,
    );
    expect(
      find.text(formaterMontant(DonneesAdulteDemo.montantOffreA)),
      findsNothing,
    );

    // « Verifier la recharge » : etape 2 (planche 4.3).
    await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    expect(find.text(t.adulte.recharge.verifierTitre), findsOneWidget);
    expect(find.text(t.commun.etape.sur(n: 2, total: 2)), findsOneWidget);
    expect(find.text(t.adulte.recharge.recapitulatif), findsOneWidget);
    // Une ligne par beneficiaire choisi, separee (F11) : qui recoit, montant
    // paye, solde attribue, statut ; aucune remise rendue, aucune ligne.
    for (final (String id, String prenom, String montant, String solde)
        in <(String, String, String, String)>[
          (
            _mamadou,
            'Mamadou',
            t.adulte.demo.donnees.prixOffreB,
            'Solde de démonstration B',
          ),
          (
            _aicha,
            'Aïcha',
            t.adulte.demo.donnees.prixOffreA,
            'Solde de démonstration A',
          ),
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
    // Le total rendu et la repartition, le seul moyen de paiement web, et
    // « Payer {total} » au bord de fin, 16 sous le moyen de paiement.
    expect(
      dans(
        RechargeFoyerPage.totalKey,
        find.text(t.adulte.demo.donnees.totalRecharge15),
      ),
      findsOneWidget,
    );
    final Finder payer = find.byKey(RechargeFoyerPage.payerKey);
    expect(
      dans(
        RechargeFoyerPage.payerKey,
        find.text(
          t.adulte.recharge.payer(
            montant: t.adulte.demo.donnees.totalRecharge15,
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      dans(
        RechargeFoyerPage.totalKey,
        find.text(t.adulte.recharge.repartition),
      ),
      findsOneWidget,
    );
    expect(find.byType(LigneMoyenPaiement), findsOneWidget);
    expect(
      tester.widget<LigneMoyenPaiement>(find.byType(LigneMoyenPaiement)).rail,
      RailPaiement.webStripe,
    );
    final Finder moyen = find.byKey(RechargeFoyerPage.moyenKey);
    expect(
      tester.getTopLeft(payer).dy - tester.getBottomLeft(moyen).dy,
      AppSpacing.lg,
    );
    expect(
      tester.getTopRight(payer).dx,
      moreOrLessEquals(tester.getTopRight(moyen).dx, epsilon: 0.5),
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
    // Aicha passe au montant suivant : le recapitulatif suit.
    await taper(tester, find.byKey(RechargeFoyerPage.plusDe(_aicha)));
    await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
    expect(
      dans(
        RechargeFoyerPage.ligneDe(_aicha),
        find.text(t.adulte.demo.donnees.prixOffreB),
      ),
      findsOneWidget,
    );
    expect(
      dans(
        RechargeFoyerPage.totalKey,
        find.text(t.adulte.demo.donnees.totalRecharge20),
      ),
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
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(RechargeFoyerPage.profilsKey)).dy,
      ),
    );
    await taper(tester, lien);
    for (final String id in <String>[_mamadou, _mariama, _aicha, _oumar]) {
      expect(coche(tester, id), isTrue);
    }
    expect(find.text(t.adulte.recharge.toutDeselectionner), findsOneWidget);
    // Chaque montant actif, dans la ligne de son profil, avant la suivante.
    final List<String> ordre = <String>[_mamadou, _mariama, _aicha, _oumar];
    for (int i = 0; i < ordre.length; i++) {
      expect(actif(tester, RechargeFoyerPage.plusDe(ordre[i])), isTrue);
      final Finder ligne = find.byKey(RechargeFoyerPage.profilDe(ordre[i]));
      expect(
        find.descendant(
          of: ligne,
          matching: find.byKey(RechargeFoyerPage.montantDe(ordre[i])),
        ),
        findsOneWidget,
      );
      if (i + 1 < ordre.length) {
        expect(
          tester.getBottomLeft(ligne).dy,
          lessThan(
            tester
                .getTopLeft(find.byKey(RechargeFoyerPage.caseDe(ordre[i + 1])))
                .dy,
          ),
        );
      }
    }
    // Rien n'est reparti : sans montant pour chacun, le bouton attend.
    expect(bouton(tester, RechargeFoyerPage.verifierKey).onPress, isNull);
    for (final String id in <String>[_mamadou, _mariama, _aicha, _oumar]) {
      await montant(tester, id, _offreA);
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
      dans(
        RechargeFoyerPage.totalKey,
        find.text(t.adulte.demo.donnees.totalRecharge20),
      ),
      findsOneWidget,
    );
    // Retour de l'etape 2 : l'etape 1 ; puis tout deselectionne.
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(RechargeFoyerPage.toutSelectionnerKey));
    for (final String id in <String>[_mamadou, _mariama, _aicha, _oumar]) {
      expect(actif(tester, RechargeFoyerPage.plusDe(id)), isFalse);
    }
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
    // Les choix ne se modifient plus : une autre cle pourrait payer deux fois.
    expect(find.byKey(RechargeFoyerPage.modifierDe(_oumar)), findsNothing);
    rienDInvente();
    // Le retour mene aux paiements du foyer, ou l'on verifie.
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byType(RechargeFoyerPage), findsNothing);
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
        montantsProposes: <Montant>[Montant(1000, 'USD')],
      ),
    ];

    Future<void> monter(
      WidgetTester tester, {
      PortRechargeFoyer? port,
      Stream<bool>? horsLigne,
      VoidCallback? onTerminee,
      ValueChanged<String>? onPaye,
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
            onPaye: onPaye ?? (String _) {},
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
      await choisir(tester, 'b1', _offreA);
      await taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
      // « Payer » sous le moyen de paiement : amene a l'ecran.
      final Finder payer = find.byKey(RechargeFoyerPage.payerKey);
      if (payer.evaluate().isNotEmpty) {
        await tester.ensureVisible(payer);
        await tester.pumpAndSettle();
      }
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
      await choisir(tester, 'b1', _offreA);
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

    testWidgets('coupure au paiement avec perte du reseau : D5 seul, jamais '
        '« Rien n\'est payé » ; ni Modifier ni retour aux choix, meme cle', (
      WidgetTester tester,
    ) async {
      final StreamController<bool> reseau = StreamController<bool>();
      addTearDown(reseau.close);
      final _Port port = _Port(liste: exemple, paiementSuspendu: true);
      bool termine = false;
      await monter(
        tester,
        port: port,
        horsLigne: reseau.stream,
        onTerminee: () => termine = true,
      );
      reseau.add(false);
      await tester.pumpAndSettle();
      await jusquAuRecapitulatif(tester);
      await tester.tap(find.byKey(RechargeFoyerPage.payerKey));
      await tester.pump();
      // Le reseau tombe pendant le paiement, et l'appel echoue avec lui.
      reseau.add(true);
      port.reponse.completeError(StateError('coupure'));
      await tester.pumpAndSettle();
      expect(find.text(t.adulte.recharge.paiementEchecTitre), findsOneWidget);
      expect(find.text(t.adulte.recharge.paiementEchecPhrase), findsOneWidget);
      expect(find.text(t.adulte.recharge.horsLignePayer), findsOneWidget);
      expect(find.textContaining("Rien n'est payé"), findsNothing);
      expect(find.textContaining("n'a pas été payé"), findsNothing);
      expect(bouton(tester, RechargeFoyerPage.payerKey).onPress, isNull);
      expect(find.byKey(RechargeFoyerPage.modifierDe('b1')), findsNothing);
      // Le retour ne rouvre pas les choix : il mene aux paiements du foyer.
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(termine, isTrue);
      expect(find.text(t.adulte.recharge.paiementEchecTitre), findsOneWidget);
      // Le reseau revient : la nouvelle tentative reprend la meme cle.
      reseau.add(false);
      await tester.pumpAndSettle();
      port.paiementSuspendu = false;
      await taper(tester, find.byKey(RechargeFoyerPage.payerKey));
      expect(port.cles, hasLength(2));
      expect(port.cles.toSet(), hasLength(1));
    });

    testWidgets('commande rendue par le serveur (FI-8) : son resultat '
        's ouvre, sans succes local ni second paiement', (
      WidgetTester tester,
    ) async {
      final List<String> commandes = <String>[];
      await monter(
        tester,
        port: _Port(liste: exemple),
        onPaye: commandes.add,
      );
      await tester.pumpAndSettle();
      await jusquAuRecapitulatif(tester);
      await taper(tester, find.byKey(RechargeFoyerPage.payerKey));
      expect(commandes, <String>['commande rendue par le serveur']);
      expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
      expect(find.text(t.adulte.recharge.commandeRendue), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsOneWidget);
      // Revenu sur cette page, le seul geste est le suivi de la commande.
      await taper(tester, find.byKey(RechargeFoyerPage.suivreKey));
      expect(commandes, hasLength(2));
      expect(commandes.toSet(), hasLength(1));
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
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(StateError('EA-10'));

  @override
  Future<RecapitulatifRecharge> verifierMontants(
    List<MontantRecharge> choix,
  ) async {
    if (erreurVerification) throw StateError('coupure');
    return RecapitulatifRecharge(
      id: 'r1',
      total: 'total rendu',
      lignes: <LigneRecapitulatif>[
        for (final MontantRecharge c in choix)
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
    return Future<String>.value('commande rendue par le serveur');
  }

  @override
  Future<SuiviPaiement> suivre(String commandeId) =>
      Future<SuiviPaiement>.error(StateError('FI-8'));
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
