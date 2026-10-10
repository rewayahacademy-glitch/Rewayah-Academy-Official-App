// EA-PL parcours : « Ajouter ma famille » (doc section 4, recette section
// 21) depuis la VRAIE coquille de demonstration (/demo/adulte, adulte seul),
// vrais boutons tapes (K-07) ; la page en arabe (RTL) ; le libelle genre de
// l'invitation (doc section 2).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

void main() {
  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<GoRouter> monter(
    WidgetTester tester,
    String depart, {
    Locale? locale,
  }) async {
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
            locale: locale ?? AppLocale.fr.flutterLocale,
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

  Future<void> taper(WidgetTester tester, Finder cible) async {
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
    await tester.tap(cible);
    await tester.pumpAndSettle();
  }

  testWidgets('adulte seul : Ajouter ma famille, inviter, envoyer, revenir ; '
      'Mon espace dit Ma famille, le profil eleve est intact', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    // Avant : le profil eleve de Mamadou, ses paiements personnels.
    expect(find.text('Mamadou Diallo'), findsOneWidget);
    expect(find.text(t.adulte.monEspace.paiements), findsOneWidget);

    await taper(tester, find.text(t.adulte.famille.ajouter));
    expect(find.byType(AjouterMaFamillePage), findsOneWidget);
    // Doc section 4, mot pour mot.
    expect(
      find.text(
        'Vous pouvez ajouter vos enfants et inviter un conjoint ou une '
        'conjointe à rejoindre votre forfait famille. Votre espace élève '
        'reste inchangé.',
      ),
      findsOneWidget,
    );
    // Titulaire homme : « Inviter ma conjointe » (doc section 2).
    expect(find.text(t.adulte.invitation.titreElle), findsOneWidget);
    expect(find.text(t.adulte.famille.inscrireEnfant), findsOneWidget);

    await taper(tester, find.byKey(AjouterMaFamillePage.inviterKey));
    expect(find.byType(InviterConjointPage), findsOneWidget);
    await tester.enterText(
      find.byKey(InviterConjointPage.prenomKey),
      'Mariama',
    );
    await tester.enterText(
      find.byKey(InviterConjointPage.courrielKey),
      'mariama@example.com',
    );
    await tester.pump();
    await taper(tester, find.byKey(InviterConjointPage.verifierKey));
    await taper(tester, find.byKey(InviterConjointPage.envoyerKey));
    // L'ecran « Invitation envoyee » existant.
    expect(find.byKey(InviterConjointPage.envoyeeKey), findsOneWidget);

    await taper(tester, find.byKey(InviterConjointPage.revenirKey));
    // Ma famille du foyer nouveau : l'invitation envoyee, aucun enfant
    // invente.
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(find.text(t.adulte.famille.place.invitationEnvoyee), findsWidgets);
    expect(find.text('Aïcha'), findsNothing);
    expect(find.text('Oumar'), findsNothing);

    await taper(
      tester,
      find.byKey(const ValueKey<String>('retour-mon-espace')),
    );
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    expect(find.text(t.adulte.famille.maFamille), findsOneWidget);
    expect(find.text(t.adulte.famille.ajouter), findsNothing);
    // Le profil eleve, inchange : la meme identite, une seule fois, ses
    // paiements personnels.
    expect(find.text('Mamadou Diallo'), findsOneWidget);
    expect(find.text(t.adulte.monEspace.paiements), findsOneWidget);
    expect(
      routeur.routerDelegate.currentConfiguration.uri.queryParameters['foyer'],
      'nouveau',
    );
    // Sa classe, inchangee.
    await taper(tester, find.text(t.adulte.nav.maClasse).first);
    expect(find.byType(MaClasseAdultePage), findsOneWidget);
    expect(
      find.textContaining(DonneesAdulteDemo.pageRepriseTitulaire),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('adulte seul : Inscrire un enfant ouvre le formulaire commun ; '
      'abandonner ramene a Ajouter ma famille', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.ajouterMaFamille,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    await taper(tester, find.byKey(AjouterMaFamillePage.inscrireEnfantKey));
    expect(find.byType(FormulaireProfilEleve), findsOneWidget);
    await taper(tester, find.byType(DisqueRetour).first);
    expect(find.byType(AjouterMaFamillePage), findsOneWidget);
  });

  testWidgets('adulte seul : Inscrire un enfant jusqu\'au resultat, puis Mon '
      'espace ; aucun foyer cree', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    await taper(tester, find.text(t.adulte.famille.ajouter));
    await taper(tester, find.byKey(AjouterMaFamillePage.inscrireEnfantKey));
    expect(find.byType(FormulaireProfilEleve), findsOneWidget);
    await taper(tester, find.text(t.foyer.ajout.pourQui.enfantTitre));
    await taper(tester, find.byKey(FormulaireProfilEleve.actionKey));
    await tester.enterText(
      find.byKey(FormulaireProfilEleve.prenomKey),
      'Yusuf',
    );
    await tester.enterText(find.byKey(FormulaireProfilEleve.nomKey), 'Diallo');
    await taper(tester, find.byKey(FormulaireProfilEleve.ageChoixKey(8)));
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(FormulaireProfilEleve.actionKey));

    expect(
      find.byKey(const ValueKey<String>('demo-profil-non-cree')),
      findsOneWidget,
    );
    expect(find.text(t.adulte.famille.profilNonCreePhraseSeul), findsOneWidget);
    expect(find.text(t.adulte.famille.profilNonCreePhrase), findsNothing);
    final Finder retour = find.text(t.adulte.famille.retourMonEspace);
    expect(retour, findsOneWidget);
    expect(find.text(t.adulte.invitation.revenirMaFamille), findsNothing);

    await taper(tester, retour);
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    expect(find.text(t.adulte.famille.ajouter), findsOneWidget);
    expect(find.text('Yusuf'), findsNothing);
    // Aucun foyer cree : la demonstration n'envoie rien.
    expect(
      routeur.routerDelegate.currentConfiguration.uri.queryParameters
          .containsKey('foyer'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  for (final EtatDemoAdulte etat in <EtatDemoAdulte>[
    EtatDemoAdulte.conjointQuitte,
    EtatDemoAdulte.conjointRetire,
  ]) {
    testWidgets('second adulte non rattache (${etat.name}) : un etat honnete '
        'et son retour, jamais une phrase qui promet une action absente', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      await monter(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: etat,
          vue: VueDemoAdulte.secondAdulte,
        ),
      );
      await taper(tester, find.text(t.adulte.famille.ajouter));
      expect(find.byType(AjouterMaFamillePage), findsNothing);
      expect(find.text(t.adulte.famille.ajouterPhrase), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('demo-ajouter-famille-indisponible')),
        findsOneWidget,
      );
      expect(find.text(t.adulte.famille.indisponibleTitre), findsOneWidget);
      await taper(tester, find.text(t.adulte.famille.retourMonEspace));
      expect(find.byType(MonEspaceAdultePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('390 : les deux actions empilees a la meme largeur, calees au '
      'bord de fin, la sortie avant la poursuite', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.ajouterMaFamille,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    final Rect inscrire = tester.getRect(
      find.byKey(AjouterMaFamillePage.inscrireEnfantKey),
    );
    final Rect inviter = tester.getRect(
      find.byKey(AjouterMaFamillePage.inviterKey),
    );
    final Rect phrase = tester.getRect(
      find.text(t.adulte.famille.ajouterPhrase),
    );
    expect(inviter.bottom, lessThanOrEqualTo(inscrire.top));
    expect(inviter.width, closeTo(inscrire.width, 0.5));
    expect(inviter.right, closeTo(inscrire.right, 0.5));
    expect(inscrire.right, closeTo(phrase.right, 1));
    // Les actions sont dans la carte, sous la phrase (police de test : la
    // rangee sur une ligne est couverte par rangee_actions_test.dart).
    expect(
      find.ancestor(
        of: find.byKey(AjouterMaFamillePage.inscrireEnfantKey),
        matching: find.byType(AppCard),
      ),
      findsOneWidget,
    );
  });

  testWidgets('la fleche revient a Mon espace', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.ajouterMaFamille,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    await taper(tester, find.byType(DisqueRetour).first);
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    expect(find.text(t.adulte.famille.ajouter), findsOneWidget);
  });

  testWidgets('libelle genre : homme -> conjointe, femme -> conjoint', (
    WidgetTester tester,
  ) async {
    expect(
      AjouterMaFamillePage.libelleInviter(placeFeminine: true),
      'Inviter ma conjointe',
    );
    expect(
      AjouterMaFamillePage.libelleInviter(placeFeminine: false),
      'Inviter mon conjoint',
    );
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.ajouterMaFamille,
        etat: EtatDemoAdulte.adulteSeul,
      ),
    );
    expect(find.text('Inviter ma conjointe'), findsOneWidget);
    expect(find.text('Inviter mon conjoint'), findsNothing);
    routeur.go(
      adresseDemoAdulte(
        EcranDemoAdulte.ajouterMaFamille,
        etat: EtatDemoAdulte.adulteSeul,
        genre: GenreTitulaireDemo.femme,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Inviter mon conjoint'), findsOneWidget);
    expect(find.text('Inviter ma conjointe'), findsNothing);
    // Le formulaire ouvert suit le meme genre.
    await taper(tester, find.byKey(AjouterMaFamillePage.inviterKey));
    expect(
      tester
          .widget<InviterConjointPage>(find.byType(InviterConjointPage))
          .placeFeminine,
      isFalse,
    );
  });

  testWidgets('RTL (ar) : la page en miroir, actions au bord de fin', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 900));
    await monter(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.ajouterMaFamille,
        etat: EtatDemoAdulte.adulteSeul,
      ),
      locale: AppLocale.ar.flutterLocale,
    );
    final Finder page = find.byType(AjouterMaFamillePage);
    expect(page, findsOneWidget);
    expect(Directionality.of(tester.element(page)), TextDirection.rtl);
    final Rect inscrire = tester.getRect(
      find.byKey(AjouterMaFamillePage.inscrireEnfantKey),
    );
    final Rect inviter = tester.getRect(
      find.byKey(AjouterMaFamillePage.inviterKey),
    );
    final Rect phrase = tester.getRect(
      find.text(t.adulte.famille.ajouterPhrase),
    );
    // Contrat B en miroir : la secondaire avant la poursuite (a sa droite,
    // ou au-dessus quand la rangee passe a la ligne), toutes deux calees au
    // bord de fin, a gauche, dans la colonne de la phrase.
    expect(
      inviter.left >= inscrire.right - 1 || inviter.bottom <= inscrire.top,
      isTrue,
    );
    expect(inscrire.left, closeTo(phrase.left, 1));
    if (inviter.bottom <= inscrire.top) {
      expect(inviter.left, closeTo(phrase.left, 1));
    }
    expect(inviter.right, lessThanOrEqualTo(phrase.right + 1));
    expect(tester.takeException(), isNull);
  });
}
