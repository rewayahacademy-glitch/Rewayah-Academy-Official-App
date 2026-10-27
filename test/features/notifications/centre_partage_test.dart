// COM-ANN-1 : le centre de notifications partage (spec Communications V1,
// sections 13.1, 13.2 et 18), sur le VRAI routeur du tuteur : la cloche est
// TOUCHEE depuis l'Accueil, puis filtres, niveaux dits par du texte, detail,
// lecture enregistree, et R-COM-12 (la notification d'annonce mene a
// l'annonce, puis a sa Classe). A 390, 768 et 1440, et en arabe (RTL).
// Donnees : doubles de test, aucun Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';
import 'package:rewayah_academy/features/com_annonces/carte_annonce_classe.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/notifications/detail_notification.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../../fixtures/tuteur/faux_capacites.dart';
import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../com_annonces/faux_annonces.dart';
import '../com_annonces/support_annonces.dart';

final DateTime _maintenant = DateTime.now();

/// Le catalogue du tuteur : une urgence (plus ancienne qu'une autre, pour
/// prouver qu'elle passe en tete), une annonce de Classe, une action
/// requise, une mention, une notification lue a destination.
List<NotificationTuteur> _catalogue() => <NotificationTuteur>[
  NotificationTuteur(
    id: 'n-annonce',
    titre: 'Récitation de fin de trimestre',
    date: _maintenant.subtract(const Duration(hours: 1)),
    type: TypeNotification.annonceClasse,
    niveau: NiveauAttention.aLire,
    lue: false,
    annonceId: 'an1',
  ),
  NotificationTuteur(
    id: 'n-urgent',
    titre: 'La séance de ce soir est annulée',
    date: _maintenant.subtract(const Duration(hours: 2)),
    type: TypeNotification.changementSeance,
    niveau: NiveauAttention.urgent,
    lue: false,
    texte: 'La séance est reportée à jeudi, même heure.',
  ),
  NotificationTuteur(
    id: 'n-action',
    titre: 'Réponse attendue pour Yasmine',
    date: _maintenant.subtract(const Duration(days: 1)),
    type: TypeNotification.reponseAttendue,
    niveau: NiveauAttention.actionRequise,
    lue: false,
    texte: 'Répondez depuis l’Espace Classe.',
  ),
  NotificationTuteur(
    id: 'n-mention',
    titre: 'Nouveau message de l’enseignante',
    date: _maintenant.subtract(const Duration(days: 2)),
    type: TypeNotification.messageMetier,
    niveau: NiveauAttention.aLire,
    lue: false,
    mention: true,
    destination: Routes.tuteurSuivi,
  ),
  NotificationTuteur(
    id: 'n-lue',
    titre: 'Compte rendu de la séance disponible',
    date: _maintenant.subtract(const Duration(days: 3)),
    destination: Routes.tuteurSuivi,
  ),
];

FauxAnnonces _annonces() => FauxAnnonces(
  parClasse: <String, List<AnnonceClasse>>{
    classeA: <AnnonceClasse>[
      annonceDeTest(
        classeId: classeA,
        destination: Routes.classePour(classeA, eleveId: eleveA1),
      ),
    ],
  },
);

Future<
  ({GoRouter routeur, FauxNotifications notifications, FauxAnnonces annonces})
>
_monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  List<NotificationTuteur>? notifications,
  FauxAnnonces? annonces,
  bool echecLecture = false,
}) async {
  final FauxNotifications port = FauxNotifications(
    notifications: notifications ?? _catalogue(),
    echecLecture: echecLecture,
  );
  final FauxAnnonces portAnnonces = annonces ?? _annonces();
  final GoRouter routeur = await monterTuteurAnnonces(
    tester,
    depart: Routes.tuteurAccueil,
    taille: taille,
    autres: <Override>[
      portNotificationsProvider.overrideWithValue(port),
      portAnnoncesProvider.overrideWithValue(portAnnonces),
    ],
  );
  // La cloche dit ses non-lus (« Notifications, n non lues ») depuis la fiche
  // du 27/10 : on la touche par son type.
  await tester.tap(find.byType(ClocheNotifications).first);
  await stabiliser(tester);
  expect(lieu(routeur), Routes.tuteurNotifications);
  return (routeur: routeur, notifications: port, annonces: portAnnonces);
}

Finder _ligne(String id) => find.byKey(ValueKey<String>('notification-$id'));

/// Choisit un filtre comme une personne : sur le controle segmente s'il
/// tient, sinon par le menu deroulant que `SelecteurSection` lui substitue
/// (libelles trop larges pour leur part, telephone).
Future<void> _filtrer(WidgetTester tester, String libelle) async {
  final Finder menu = find.descendant(
    of: find.byKey(NotificationsPage.cleFiltres),
    matching: find.byType(MenuFiltre<FiltreNotifications>),
  );
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await stabiliser(tester);
    await tester.tap(find.text(libelle).last);
  } else {
    await tester.tap(
      find.descendant(
        of: find.byKey(NotificationsPage.cleFiltres),
        matching: find.text(libelle),
      ),
    );
  }
  await stabiliser(tester);
}

/// Touche [cible] apres l'avoir amenee a l'ecran.
Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await stabiliser(tester);
}

/// Les quatre libelles de filtre, lisibles a l'ecran : en ligne, ou dans la
/// liste du menu ouvert.
Future<void> _verifierQuatreFiltres(WidgetTester tester) async {
  final f = t.notifications.filtres;
  final Finder menu = find.descendant(
    of: find.byKey(NotificationsPage.cleFiltres),
    matching: find.byType(MenuFiltre<FiltreNotifications>),
  );
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await stabiliser(tester);
  }
  for (final String libelle in <String>[
    f.toutes,
    f.nonLues,
    f.mentions,
    f.actionRequise,
  ]) {
    expect(find.text(libelle), findsWidgets, reason: libelle);
  }
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(find.text(f.toutes).last);
    await stabiliser(tester);
  }
}

void main() {
  group('Centre partage : filtres et niveaux', () {
    testWidgets('390 : quatre filtres visibles, l urgence en tete, chaque '
        'niveau dit par un mot', (WidgetTester tester) async {
      await _monter(tester);
      expect(find.byType(SelecteurSection<FiltreNotifications>), findsOne);
      await _verifierQuatreFiltres(tester);
      // L'urgence non lue passe avant l'annonce, pourtant plus recente.
      expect(
        tester.getTopLeft(_ligne('n-urgent')).dy,
        lessThan(tester.getTopLeft(_ligne('n-annonce')).dy),
      );
      // Les niveaux sont des MOTS, avec leur icone (jamais la couleur seule).
      final b = t.com.socle.composants.badge;
      expect(
        find.descendant(of: _ligne('n-urgent'), matching: find.text(b.urgent)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _ligne('n-action'),
          matching: find.text(b.actionRequise),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _ligne('n-annonce'), matching: find.text(b.aLire)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _ligne('n-mention'),
          matching: find.text(b.mention),
        ),
        findsOneWidget,
      );
      // Information lue : aucun badge, aucun « Non lue ».
      expect(
        find.descendant(of: _ligne('n-lue'), matching: find.byType(BadgeNonLu)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _ligne('n-lue'),
          matching: find.textContaining(t.notifications.nonLue),
        ),
        findsNothing,
      );
      // Le type et « Non lue » sont dits sur la ligne.
      expect(
        find.descendant(
          of: _ligne('n-annonce'),
          matching: find.text(
            '${t.notifications.types.annonceClasse} · '
            '${t.notifications.nonLue}',
          ),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chaque filtre retient ce qu il dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final f = t.notifications.filtres;

      await _filtrer(tester, f.nonLues);
      for (final String id in <String>[
        'n-annonce',
        'n-urgent',
        'n-action',
        'n-mention',
      ]) {
        expect(_ligne(id), findsOneWidget, reason: id);
      }
      expect(_ligne('n-lue'), findsNothing);

      await _filtrer(tester, f.mentions);
      expect(_ligne('n-mention'), findsOneWidget);
      expect(_ligne('n-annonce'), findsNothing);
      expect(_ligne('n-urgent'), findsNothing);

      // Action requise : l'action requise et l'urgence, rien d'autre.
      await _filtrer(tester, f.actionRequise);
      expect(_ligne('n-action'), findsOneWidget);
      expect(_ligne('n-urgent'), findsOneWidget);
      expect(_ligne('n-annonce'), findsNothing);
      expect(_ligne('n-mention'), findsNothing);
      expect(_ligne('n-lue'), findsNothing);

      await _filtrer(tester, f.toutes);
      expect(_ligne('n-lue'), findsOneWidget);
    });

    testWidgets('un filtre vide le dit, et « Voir toutes » le relache', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        notifications: <NotificationTuteur>[
          NotificationTuteur(id: 'seule', titre: 'Lue', date: _maintenant),
        ],
      );
      await _filtrer(tester, t.notifications.filtres.mentions);
      expect(find.text(t.notifications.filtreVideTitre), findsOneWidget);
      expect(_ligne('seule'), findsNothing);
      await _toucher(tester, find.text(t.notifications.voirToutes));
      expect(_ligne('seule'), findsOneWidget);
      expect(find.text(t.notifications.filtreVideTitre), findsNothing);
    });

    testWidgets('la ligne dit au lecteur d ecran son type, « non lue », son '
        'niveau et la mention', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _monter(tester);
      final String phrase = LigneNotification.phraseSemantique(
        _catalogue().firstWhere((NotificationTuteur n) => n.id == 'n-mention'),
      );
      expect(phrase, contains(t.notifications.types.messageMetier));
      expect(phrase, contains(t.notifications.nonLueSemantique));
      expect(phrase, contains(t.com.socle.composants.badge.mentionSemantique));
      expect(find.bySemanticsLabel(phrase), findsOneWidget);
      semantique.dispose();
    });
  });

  group('Revue COM-ANN-1 : le niveau Information est dit', () {
    testWidgets('la phrase du lecteur d ecran dit « Information » quand '
        'aucun badge n est rendu', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _monter(tester);
      final NotificationTuteur lue = _catalogue().firstWhere(
        (NotificationTuteur n) => n.id == 'n-lue',
      );
      final String phrase = LigneNotification.phraseSemantique(lue);
      expect(phrase, contains(t.com.socle.composants.badge.information));
      expect(find.bySemanticsLabel(phrase), findsOneWidget);
      // Une notification qui a un badge garde la phrase du badge, sans
      // « Information » en plus.
      final String urgente = LigneNotification.phraseSemantique(
        _catalogue().firstWhere((NotificationTuteur n) => n.id == 'n-urgent'),
      );
      expect(
        urgente,
        isNot(contains(t.com.socle.composants.badge.information)),
      );
      semantique.dispose();
    });

    testWidgets('1440 : le detail ecrit « Information » en texte neutre, '
        'sans pastille', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(1440, 900));
      await _toucher(tester, _ligne('n-lue'));
      final Finder detail = find.byKey(NotificationsPage.cleDetail);
      final Finder typeNiveau = find.descendant(
        of: detail,
        matching: find.byKey(DetailNotification.cleTypeNiveau),
      );
      expect(typeNiveau, findsOneWidget);
      expect(
        tester.widget<Text>(typeNiveau).data,
        contains(t.com.socle.composants.badge.information),
      );
      expect(
        find.descendant(of: detail, matching: find.byType(BadgeNonLu)),
        findsNothing,
      );
      // Une urgence garde son badge, et « Information » n'est pas ecrit.
      await _toucher(tester, _ligne('n-urgent'));
      expect(
        find.descendant(of: detail, matching: find.byType(BadgeNonLu)),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(typeNiveau).data,
        isNot(contains(t.com.socle.composants.badge.information)),
      );
    });
  });

  group('Revue COM-ANN-1 : lecture de l annonce en echec', () {
    testWidgets('la notification lue est relue ; seule l annonce est dite '
        'non confirmee', (WidgetTester tester) async {
      final FauxAnnonces annonces = _annonces()..echecLecture = true;
      final (routeur: _, :FauxNotifications notifications, annonces: _) =
          await _monter(tester, annonces: annonces);
      await _toucher(tester, _ligne('n-annonce'));
      expect(notifications.lues, <String>['n-annonce']);
      expect(annonces.lues, isEmpty);
      expect(find.text(t.notifications.lectureNonConfirmee), findsOneWidget);
      await _toucher(tester, find.byType(DisqueRetour));
      // La lecture de la notification est enregistree : la liste relue ne
      // la dit plus « Non lue ».
      expect(
        find.descendant(
          of: _ligne('n-annonce'),
          matching: find.textContaining(t.notifications.nonLue),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Centre partage : telephone, une surface a la fois', () {
    testWidgets('R-COM-12 : la notification d annonce ouvre l annonce, puis '
        'sa Classe ; la lecture est enregistree', (WidgetTester tester) async {
      final (:GoRouter routeur, :FauxNotifications notifications, :annonces) =
          await _monter(tester);

      await _toucher(tester, _ligne('n-annonce'));
      // Toujours le centre, mais le detail seul : l'annonce entiere.
      expect(lieu(routeur), Routes.tuteurNotifications);
      expect(find.byType(CarteAnnonceClasse), findsOneWidget);
      expect(find.text(texteLong), findsOneWidget);
      expect(find.byKey(NotificationsPage.cleFiltres), findsNothing);
      expect(notifications.lues, <String>['n-annonce']);
      expect(annonces.lues, <String>['an1']);
      // Le detail est complet : pas de « Lire l'annonce en entier ».
      expect(find.byKey(CarteAnnonceClasse.cleLire), findsNothing);

      await _toucher(tester, find.byKey(CarteAnnonceClasse.cleOuvrirClasse));
      expect(lieu(routeur), Routes.classePour(classeA, eleveId: eleveA1));
      // L'Espace Classe montre la meme annonce, dans son emplacement.
      expect(find.byType(AnnoncesDeClasse), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('annonce-an1')), findsOneWidget);
      // On est dans la Classe : pas de second « Ouvrir la Classe ».
      expect(find.byKey(CarteAnnonceClasse.cleOuvrirClasse), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le retour du detail ramene a la liste, puis a l Accueil', (
      WidgetTester tester,
    ) async {
      final (:GoRouter routeur, notifications: _, annonces: _) = await _monter(
        tester,
      );
      await _toucher(tester, _ligne('n-urgent'));
      expect(find.byType(DetailNotification), findsOneWidget);
      expect(
        find.text('La séance est reportée à jeudi, même heure.'),
        findsOneWidget,
      );
      expect(_ligne('n-annonce'), findsNothing);

      await _toucher(tester, find.byType(DisqueRetour));
      expect(lieu(routeur), Routes.tuteurNotifications);
      expect(find.byType(DetailNotification), findsNothing);
      expect(_ligne('n-annonce'), findsOneWidget);

      await _toucher(tester, find.byType(DisqueRetour));
      expect(lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('la lecture relue : la notification n est plus « non lue »', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _toucher(tester, _ligne('n-urgent'));
      await _toucher(tester, find.byType(DisqueRetour));
      // L'urgence lue reste dite (niveau qui demande quelque chose), mais
      // elle n'est plus « Non lue » et ne passe plus avant l'annonce.
      expect(
        find.descendant(
          of: _ligne('n-urgent'),
          matching: find.textContaining(t.notifications.nonLue),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _ligne('n-urgent'),
          matching: find.text(t.com.socle.composants.badge.urgent),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(_ligne('n-annonce')).dy,
        lessThan(tester.getTopLeft(_ligne('n-urgent')).dy),
      );
    });

    testWidgets('une lecture non confirmee garde « Non lue » et le dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, echecLecture: true);
      await _toucher(tester, _ligne('n-urgent'));
      expect(find.text(t.notifications.lectureNonConfirmee), findsOneWidget);
      await _toucher(tester, find.byType(DisqueRetour));
      expect(
        find.descendant(
          of: _ligne('n-urgent'),
          matching: find.textContaining(t.notifications.nonLue),
        ),
        findsOneWidget,
      );
    });

    testWidgets('une notification a destination l ouvre directement', (
      WidgetTester tester,
    ) async {
      final (:GoRouter routeur, :FauxNotifications notifications, annonces: _) =
          await _monter(tester);
      await _toucher(tester, _ligne('n-mention'));
      expect(lieu(routeur), Routes.tuteurSuivi);
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      expect(notifications.lues, <String>['n-mention']);
    });

    testWidgets('768 : toujours une seule colonne (tablette etroite)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(768, 1024));
      expect(find.byKey(NotificationsPage.cleDetail), findsNothing);
      await _toucher(tester, _ligne('n-annonce'));
      expect(find.byType(CarteAnnonceClasse), findsOneWidget);
      expect(_ligne('n-urgent'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Centre partage : ordinateur, liste et detail', () {
    testWidgets('1440 : liste et detail cote a cote, dans la coquille du '
        'role ; le detail suit la ligne choisie', (WidgetTester tester) async {
      final (:GoRouter routeur, notifications: _, annonces: _) = await _monter(
        tester,
        taille: const Size(1440, 900),
      );
      expect(find.byType(NavShell), findsOneWidget);
      final Finder detail = find.byKey(NotificationsPage.cleDetail);
      final Finder liste = find.byKey(NotificationsPage.cleListe);
      expect(detail, findsOneWidget);
      expect(
        find.descendant(
          of: detail,
          matching: find.text(t.notifications.detail.choisirTitre),
        ),
        findsOneWidget,
      );
      // Cote a cote : le detail commence apres la fin de la liste.
      expect(
        tester.getTopLeft(detail).dx,
        greaterThan(tester.getTopRight(liste).dx),
      );

      await _toucher(tester, _ligne('n-annonce'));
      expect(lieu(routeur), Routes.tuteurNotifications);
      expect(
        find.descendant(of: detail, matching: find.byType(CarteAnnonceClasse)),
        findsOneWidget,
      );
      // La liste reste visible a cote.
      expect(_ligne('n-urgent'), findsOneWidget);

      // Une notification a destination s'ouvre aussi en detail, avec son
      // lien ; le lien mene a la page concernee.
      await _toucher(tester, _ligne('n-mention'));
      expect(
        find.descendant(
          of: detail,
          matching: find.text('Nouveau message de l’enseignante'),
        ),
        findsOneWidget,
      );
      await _toucher(tester, find.byKey(DetailNotification.cleOuvrir));
      expect(lieu(routeur), Routes.tuteurSuivi);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 : la ligne choisie est annoncee « selectionnee »', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _monter(tester, taille: const Size(1440, 900));
      await _toucher(tester, _ligne('n-urgent'));
      expect(
        tester.widget<LigneNotification>(_ligne('n-urgent')).selectionnee,
        isTrue,
      );
      expect(
        tester.widget<LigneNotification>(_ligne('n-annonce')).selectionnee,
        isFalse,
      );
      semantique.dispose();
    });
  });

  group('Centre partage : arabe (RTL)', () {
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} : filtres et niveaux en arabe, de '
          'droite a gauche, sans debordement', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(tester, taille: taille);
        expect(
          Directionality.of(tester.element(find.byType(NotificationsPage))),
          TextDirection.rtl,
        );
        // Titre, filtre courant et type en arabe ; les quatre filtres aussi.
        expect(find.text('الإشعارات'), findsWidgets);
        expect(find.text('الكل'), findsWidgets);
        expect(find.textContaining('إعلان الفصل'), findsWidgets);
        await _verifierQuatreFiltres(tester);
        expect(t.notifications.filtres.nonLues, 'غير المقروءة');
        // La date est au debut de la ligne : en RTL, a droite du filet, et
        // le titre a sa gauche.
        final Finder ligne = _ligne('n-lue');
        final Finder titre = find.descendant(
          of: ligne,
          matching: find.text('Compte rendu de la séance disponible'),
        );
        final Finder filet = find.descendant(
          of: ligne,
          matching: find.byType(VerticalDivider),
        );
        expect(
          tester.getCenter(titre).dx,
          lessThan(tester.getCenter(filet).dx),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
