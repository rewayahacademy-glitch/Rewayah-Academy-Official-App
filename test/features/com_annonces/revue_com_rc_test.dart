// COM-RC, lot B (revue croisee COM-R du 05/10) : annonces, notifications et
// Administration des communications.
//
// - R-06 : sur telephone, aucune ligne de notification n'est inerte.
// - R-09 : a texte agrandi, un indicateur par rangee et la date au-dessus du
//   titre ; la date a un quart de la largeur sur telephone.
// - R-15 : « Administration des communications », une seule pastille
//   « Démonstration » par page.
// - R-24 : squelette pendant le chargement des annonces de Classe, hors
//   ligne suivi (`ref.watch`), un echec hors ligne dit comme tel.
//
// Chaque test dit sa contre-preuve : ce qui echouait avant la correction.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_planifiees.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/com_studio/aujourdhui_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/notifications/detail_notification.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart'
    show dateCourte;

import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';
import '../com_studio/support_studio.dart';
import '../historique/support_historique.dart';
import 'admin_banc.dart';
import 'faux_annonces.dart';

/// Des notifications en memoire.
class _Notifications implements PortNotifications {
  _Notifications({this.rendues = const <NotificationTuteur>[], this.erreur});

  final List<NotificationTuteur> rendues;
  final Exception? erreur;

  @override
  Future<List<NotificationTuteur>> liste() async {
    if (erreur case final Exception e) throw e;
    return rendues;
  }

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      rendues.where((NotificationTuteur n) => n.id == id).firstOrNull;
}

/// Un reseau dont l'etat change pendant le test.
class _ReseauPilote implements ServiceReseau {
  final StreamController<bool> _flux = StreamController<bool>.broadcast();

  void poser(bool horsLigne) => _flux.add(horsLigne);

  @override
  Stream<bool> horsLigne() async* {
    yield false;
    yield* _flux.stream;
  }
}

/// Des annonces dont la lecture d'une Classe n'aboutit jamais.
class _AnnoncesEnAttente extends FauxAnnonces {
  final Completer<AnnoncesDeLaClasse> _jamais = Completer<AnnoncesDeLaClasse>();

  @override
  Future<AnnoncesDeLaClasse> annoncesDeClasse(String classeId) =>
      _jamais.future;
}

final DateTime _hier = DateTime.now().subtract(const Duration(days: 1));

Future<void> _ouvrirNotifications(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(t.commun.entete.notifications).first);
  await stabiliser(tester);
}

Finder _vue(EtatCommunication etat) => find.byWidgetPredicate(
  (Widget w) => w is VueEtatCommunication && w.etat == etat,
);

Widget _ligne(NotificationTuteur n, double echelle) => MediaQuery(
  data: MediaQueryData(
    size: const Size(320, 844),
    textScaler: TextScaler.linear(echelle),
  ),
  child: Scaffold(
    body: SingleChildScrollView(
      child: LigneNotification(notification: n, onPress: () {}),
    ),
  ),
);

void main() {
  group('R-06 : aucune ligne de notification inerte sur telephone', () {
    testWidgets('390 : une notification sans destination ni texte ouvre son '
        'detail', (WidgetTester tester) async {
      // Contre-preuve : avant R-06, cette ligne n'etait pas une cible
      // (`onPress` nul), sans chevron ni explication.
      await monterHistorique(
        tester,
        autres: <Override>[
          portNotificationsProvider.overrideWithValue(
            _Notifications(
              rendues: <NotificationTuteur>[
                NotificationTuteur(
                  id: 'seule',
                  titre: 'Votre planning de la semaine prochaine a changé',
                  date: _hier,
                ),
              ],
            ),
          ),
        ],
      );
      await _ouvrirNotifications(tester);
      final Finder ligne = find.byKey(
        const ValueKey<String>('notification-seule'),
      );
      expect(tester.widget<LigneNotification>(ligne).onPress, isNotNull);
      await tester.tap(ligne);
      await stabiliser(tester);
      expect(find.byType(DetailNotification), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('R-24 : notifications hors ligne', () {
    testWidgets('un echec hors ligne se dit hors ligne, pas comme une erreur', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : avant R-24, l'echec rendait l'erreur generique.
      await monterHistorique(
        tester,
        horsLigne: true,
        autres: <Override>[
          portNotificationsProvider.overrideWithValue(
            _Notifications(erreur: Exception('reseau')),
          ),
        ],
      );
      await _ouvrirNotifications(tester);
      expect(_vue(EtatCommunication.horsLigne), findsOneWidget);
      expect(find.text(t.commun.etats.echecServeur.titre), findsNothing);
    });
  });

  group('R-09 : texte agrandi et largeur de la date', () {
    final NotificationTuteur n = NotificationTuteur(
      id: 'n',
      titre: 'Compte rendu de la séance disponible',
      date: _hier,
    );

    testWidgets('320, texte x2 : la date passe au-dessus du titre, aucun '
        'debordement', (WidgetTester tester) async {
      // Contre-preuve : avant R-09, la date gardait 38 % de la largeur et le
      // titre se coupait au milieu des mots.
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(hote(_ligne(n, 2)));
      await tester.pumpAndSettle();
      expect(find.byKey(LigneNotification.cleDateAuDessus), findsOneWidget);
      verifierAucunMotCoupe(tester, find.byType(LigneNotification));
      expect(
        tester.getBottomLeft(find.text(n.titre)).dy,
        greaterThan(tester.getBottomLeft(find.text(dateCourteTest(n))).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390, texte x1 : date et titre cote a cote', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hote(_ligne(n, 1)));
      await tester.pumpAndSettle();
      expect(find.byKey(LigneNotification.cleDateAuDessus), findsNothing);
    });

    test('la date prend un quart sur telephone, 30 % au-dela', () {
      // Contre-preuve : 0,38 sous la largeur d'un dialogue.
      expect(LigneNotification.largeurDateNotification(358), 0.25);
      expect(
        LigneNotification.largeurDateNotification(AppPage.largeurDialogue),
        0.3,
      );
    });
  });

  group('R-15 : titre de la spec, une seule pastille par page', () {
    // Le titre de la page, tel que `PageShell` le recoit.
    String titre(WidgetTester tester) =>
        tester.widget<PageShell>(find.byType(PageShell).first).titre!;
    // Le paragraphe du titre de la page.
    Finder paragrapheTitre(WidgetTester tester) => find
        .descendant(
          of: find.byType(PageShell).first,
          matching: find.text(titre(tester)),
        )
        .first;

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} : « Administration des '
          'communications » (ou son repli, jamais coupe), une pastille '
          '« Démonstration »', (WidgetTester tester) async {
        // Contre-preuve : avant R-15, le titre etait « Communications » et la
        // pastille etait repetee quatre fois.
        await monterAdministration(tester, taille: taille);
        final String lu = titre(tester);
        expect(find.text('Communications'), findsNothing);
        if (taille.width >= 1440) {
          expect(lu, 'Administration des communications');
        } else {
          // La police des tests dessine chaque glyphe sur un cadratin : a
          // 390, « Administration » n'y tient pas et le titre se replie sur
          // l'onglet ; avec la police reelle, il tient.
          expect(lu, anyOf('Administration des communications', 'Annonces'));
        }
        verifierAucunMotCoupe(tester, paragrapheTitre(tester));
        expect(find.byKey(MarqueDemonstration.cle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('320, texte x2 : le titre se replie sans mot coupe, une '
        'tuile par rangee (R-09), aucun debordement', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : avant R-09, deux tuiles par rangee coupaient les
      // mots a 320 et texte x2, et le titre se coupait (« Communicatio/ns »).
      await monterAdministration(
        tester,
        taille: const Size(320, 844),
        echelleTexte: 2,
      );
      expect(tester.takeException(), isNull);
      final List<double> gauches = <double>[
        for (final Element e in find.byType(StatTile).evaluate())
          tester.getTopLeft(find.byWidget(e.widget)).dx,
      ];
      expect(gauches, hasLength(4));
      expect(gauches.toSet(), hasLength(1));
      expect(titre(tester), 'Annonces');
      verifierAucunMotCoupe(tester, paragrapheTitre(tester));
      verifierAucunMotCoupe(tester, find.byType(StatTile));
    });
  });

  group('R-09 : Aujourd hui du Studio, texte agrandi', () {
    testWidgets('320, texte x2 : un indicateur par rangee', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : avant R-09, deux indicateurs par rangee.
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.adminStudio,
        activite: ActiviteStudioDemo(
          situation: SituationDemoStudio.normale,
          maintenant: maintenantTest,
        ),
        brouillons: brouillonsStudioDemo(SituationDemoStudio.normale),
        taille: const Size(320, 844),
        echelleTexte: 2,
      );
      final Finder tuiles = find.descendant(
        of: find.byKey(TableauAujourdhui.cleIndicateurs),
        matching: find.byType(StatTile),
      );
      final List<double> gauches = <double>[
        for (int i = 0; i < 4; i++) tester.getTopLeft(tuiles.at(i)).dx,
      ];
      expect(gauches.toSet(), hasLength(1));
      verifierAucunMotCoupe(tester, tuiles);
    });
  });

  group('R-24 : annonces de Classe et Administration', () {
    testWidgets('chargement : la section et un squelette', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : avant R-24, l'emplacement ne rendait rien.
      await tester.pumpWidget(
        hote(
          const Scaffold(body: AnnoncesDeClasse(classeId: 'c1')),
          surcharges: <Override>[
            portAnnoncesProvider.overrideWithValue(_AnnoncesEnAttente()),
          ],
        ),
      );
      await tester.pump();
      expect(find.byKey(AnnoncesDeClasse.cleChargement), findsOneWidget);
      expect(find.text(t.com.annonces.section), findsOneWidget);
    });

    testWidgets('echec hors ligne : l etat hors ligne, pas l erreur', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : avant R-24, toujours l'erreur generique.
      await tester.pumpWidget(
        hote(
          const Scaffold(body: AnnoncesDeClasse(classeId: 'c1')),
          surcharges: <Override>[
            portAnnoncesProvider.overrideWithValue(
              FauxAnnonces(erreur: Exception('reseau')),
            ),
            serviceReseauProvider.overrideWithValue(
              FauxServiceReseau(horsLigneRendu: true),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(_vue(EtatCommunication.horsLigne), findsOneWidget);
      expect(_vue(EtatCommunication.erreur), findsNothing);
    });

    testWidgets('Administration : la connexion qui tombe change l etat sans '
        'relecture (ref.watch)', (WidgetTester tester) async {
      // Contre-preuve : avant R-24, `ref.read` : l'etat restait « erreur »
      // jusqu'a la prochaine reconstruction.
      final _ReseauPilote reseau = _ReseauPilote();
      final FauxAnnonces annonces = FauxAnnonces()
        ..erreurAdministration = Exception('refus');
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: SingleChildScrollView(
              child: SectionAnnoncesAdministration(etat: EtatAnnonce.publiee),
            ),
          ),
          surcharges: <Override>[
            portAnnoncesProvider.overrideWithValue(annonces),
            serviceReseauProvider.overrideWithValue(reseau),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(_vue(EtatCommunication.horsLigne), findsNothing);
      reseau.poser(true);
      await tester.pumpAndSettle();
      expect(_vue(EtatCommunication.horsLigne), findsOneWidget);
    });
  });
}

/// La date courte d'une ligne, telle que la ligne l'ecrit.
String dateCourteTest(NotificationTuteur n) => dateCourte(n.date.toLocal());
