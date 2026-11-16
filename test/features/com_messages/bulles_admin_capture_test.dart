// COM-MSG-2 (K-07) : les entrees reelles des Messages metier de
// l'Administration, TAPEES depuis la vraie coquille admin et la vraie
// application (demonstration admin, aucun serveur) :
//
// - l'onglet Messages de l'Administration des communications
//   (`/admin/operations/communications/messages`), atteint par la ligne
//   « Communications » du tableau de bord puis l'onglet ; on y lit les fils
//   du controleur sur sa mission (paire Controleur / Administration) ;
// - « Ecrire a ... » dans le detail d'un dossier (Personnes, puis la ligne
//   du dossier).
//
// Operations reste le domaine allume : aucun neuvieme domaine (Q4).
//
// Depuis COM-FUS, le routeur monte `MessagesAdminPage` sur la route de
// l'onglet et sur `/:filId` : les tests K-07 parcourent la vraie coquille
// jusqu'au fil. La page est aussi prouvee montee seule, sur les memes
// adresses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/ligne_conversation.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/dossiers_demo.dart';
import '../../support/demo/mode_demonstration.dart';
import '../../support/demo/repere_demonstration.dart';
import 'support_messages.dart';

const Participant _rachid = Participant(
  id: 'p-rachid',
  nomAffiche: 'M. Rachid',
  fonction: 'Contrôleur pédagogique',
);
const Participant _omar = Participant(
  id: 'p-omar',
  nomAffiche: 'Omar Haddad',
  fonction: "Enseignant en cours d'inscription",
);

/// Le dossier d'Omar dans la demonstration admin.
const String _dossierOmar = DonneesDossiersDemo.enseignantNominal;

ObjetLie _mission() => ObjetLie(
  type: TypeObjetLie.mission,
  id: 'mission-12-11',
  libelle: 'Visite de contrôle, Classe An-Nour',
);
ObjetLie _dossier() => ObjetLie(
  type: TypeObjetLie.dossier,
  id: _dossierOmar,
  libelle: "Dossier d'Omar Haddad",
);

FauxMessagesMetier _port() => FauxMessagesMetier(
  fils: <FilMetier>[
    filAvec(
      id: 'fil-mission',
      autre: _rachid,
      objets: <ObjetLie>[_mission()],
      texte: 'La séance a commencé avec huit minutes de retard.',
      attention: const IndicateurAttention(nonLus: 1),
    ),
    filAvec(
      id: 'fil-dossier-omar',
      autre: _omar,
      objets: <ObjetLie>[_dossier()],
      texte: 'Bonjour, voici la pièce demandée.',
    ),
  ],
  conversations: <String, List<ConversationPossible>>{
    cleObjet(TypeObjetLie.dossier, _dossierOmar): <ConversationPossible>[
      ConversationPossible(interlocuteur: _omar, objet: _dossier()),
    ],
  },
  filsParObjet: <String, String>{
    cleObjet(TypeObjetLie.dossier, _dossierOmar): 'fil-dossier-omar',
  },
);

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  Size taille = const Size(1440, 900),
  PortMessagesMetier? port,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portMessagesMetierProvider.overrideWithValue(port ?? _port()),
        capaciteEcrireOuverteTest,
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(Routes.admin);
  await _stabiliser(tester);
  return routeur;
}

/// Du tableau de bord a l'onglet Messages : la ligne « Communications »,
/// puis l'onglet.
Future<void> _ouvrirOngletMessages(WidgetTester tester) async {
  final Finder ligne = find.byKey(
    const ValueKey<String>('tableau-communications'),
  );
  // NAV-SOUS-LIENS (14/11/2026) : sur ordinateur, l'Accueil n'a plus ses
  // cartes outils ; Communications est un sous-lien d'Operations dans le
  // panneau.
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  if (ligne.evaluate().isEmpty && barre.evaluate().isNotEmpty) {
    await tester.tap(
      find.descendant(
        of: barre,
        matching: find.text(AdminDomaine.operations.libelle),
      ),
    );
    await _stabiliser(tester);
    await tester.tap(
      find.descendant(
        of: barre,
        matching: find.text(t.com.socle.navigation.communications),
      ),
    );
    await _stabiliser(tester);
  } else {
    await tester.scrollUntilVisible(
      ligne,
      200,
      scrollable: find
          .descendant(
            of: find.byType(TableauDeBordPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await _stabiliser(tester);
    await tester.tap(ligne);
    await _stabiliser(tester);
  }
  // Sur telephone, la sous-navigation est un menu (ONGLETS-1) : il s'ouvre
  // sur la section courante.
  final Finder onglet = find.text(t.com.socle.navigation.ongletMessages);
  if (onglet.evaluate().isEmpty) {
    // Le menu de la sous-navigation, pas le titre de la page (qui peut se
    // replier sur le nom de l'onglet, revue COM-R R-15).
    await tester.tap(
      find
          .descendant(
            of: find.byType(SousNavigationDomaine),
            matching: find.text(t.com.socle.navigation.ongletAnnonces),
          )
          .first,
    );
    await _stabiliser(tester);
  }
  await tester.tap(onglet.last);
  await _stabiliser(tester);
}

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final String ouvert in <String>['liste', 'fil']) {
      testWidgets('bulles-admin-1440-fr-clair-$ouvert', (
        WidgetTester tester,
      ) async {
        await _monter(tester);
        await _ouvrirOngletMessages(tester);
        if (ouvert == 'fil') {
          await tester.tap(find.byType(LigneConversation).first);
          await tester.pumpAndSettle();
        }
        await capturerVue(
          tester,
          'BULLES-MESSAGERIE/bulles-admin-1440-fr-clair-$ouvert',
        );
      });
    }
  }, skip: sautSansCapture);
}
