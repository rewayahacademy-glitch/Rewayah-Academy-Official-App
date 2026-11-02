// NOTIFS-L6 (pilote, 02/11/2026 ; demande du directeur du 02/11 :
// « C'est pas tout qui doit etre affiche en permanence, pour qu'il tombe sur
// la priorite ») : la page Notifications refaite comme une liste.
//
// Ce que prouvent ces tests :
//   * trois sections, dans l'ordre : « A faire » (geste en attente, lue ou
//     non), « Nouvelles » (non lues), « Plus anciennes » (lues, repliees sous
//     les priorites) ;
//   * ouvrir la page ne marque rien comme lu ;
//   * les repetitions du meme evenement le meme jour tiennent en une ligne
//     (« 3 fois ») ;
//   * « Voir plus » montre 20 lignes de plus, puis demande la page suivante
//     des lues a la source (jamais une lecture sans fin) ;
//   * « Ecarter », dans le menu « ... » d'une ligne « A faire ».
//   * l'adaptateur Supabase lit `geste_requis`, `ecartee_le`, `geste_fait_le`
//     et pose la cle de regroupement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show ClocheNotifications;
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../router/support_routeur.dart';
import '../historique/support_historique.dart';

final DateTime _maintenant = DateTime.now();

/// Une source paginee, qui sait ecarter et tout marquer lu.
class _Source
    implements
        PortNotifications,
        PortLectureNotifications,
        PortLectureGroupeeNotifications,
        PortPagesNotifications,
        PortEcartNotifications {
  _Source(this.tete, {this.suite = const <NotificationTuteur>[]});

  List<NotificationTuteur> tete;
  final List<NotificationTuteur> suite;
  final List<String> ecartees = <String>[];
  int pagesDemandees = 0;
  int marquagesGroupes = 0;

  @override
  Future<List<NotificationTuteur>> liste() async => tete;

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      tete.where((NotificationTuteur n) => n.id == id).firstOrNull;

  @override
  Future<void> marquerLue(String id) async {
    tete = <NotificationTuteur>[
      for (final NotificationTuteur n in tete) n.id == id ? n.marqueeLue() : n,
    ];
  }

  @override
  Future<void> marquerToutesLues() async {
    marquagesGroupes++;
    tete = <NotificationTuteur>[
      for (final NotificationTuteur n in tete) n.marqueeLue(),
    ];
  }

  @override
  Future<List<NotificationTuteur>> lues({
    required DateTime avant,
    int limite = PortPagesNotifications.taillePage,
  }) async {
    pagesDemandees++;
    return suite
        .where((NotificationTuteur n) => n.date.isBefore(avant))
        .take(limite)
        .toList();
  }

  @override
  Future<void> ecarter(String id) async {
    ecartees.add(id);
    tete = <NotificationTuteur>[
      for (final NotificationTuteur n in tete)
        if (n.id != id) n,
    ];
  }
}

NotificationTuteur _n(
  String id, {
  required Duration ilYa,
  bool lue = true,
  bool geste = false,
  String? cle,
  String titre = 'Une classe vient d\'être créée.',
  String? evenement,
}) => NotificationTuteur(
  id: id,
  titre: titre,
  date: _maintenant.subtract(ilYa),
  lue: lue,
  niveau: lue ? NiveauAttention.information : NiveauAttention.aLire,
  gesteEnAttente: geste,
  cleRegroupement: cle,
  evenement: evenement,
);

Finder _ligne(String id) => find.byKey(ValueKey<String>('notification-$id'));

Future<void> _ouvrirCentre(
  WidgetTester tester,
  PortNotifications port, {
  Size taille = const Size(390, 844),
}) async {
  await monterHistorique(
    tester,
    taille: taille,
    autres: <Override>[portNotificationsProvider.overrideWithValue(port)],
  );
  await tester.tap(find.byType(ClocheNotifications).first);
  await stabiliser(tester);
  expect(find.byType(NotificationsPage), findsOneWidget);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('NOTIFS-L6 : les sections, pures', () {
    test(
      '« A faire » d abord, lue ou non ; puis les non lues ; puis les lues',
      () {
        final SectionsNotifications s = SectionsNotifications.depuis(
          <NotificationTuteur>[
            _n('lue', ilYa: const Duration(hours: 1)),
            _n('nouvelle', ilYa: const Duration(hours: 2), lue: false),
            _n('geste-lu', ilYa: const Duration(days: 3), geste: true),
          ],
        );
        expect(s.aFaire.single.tete.id, 'geste-lu');
        expect(s.nouvelles.single.tete.id, 'nouvelle');
        expect(s.anciennes.single.tete.id, 'lue');
      },
    );

    test('les repetitions du meme jour se regroupent, pas celles de la '
        'veille ni sans cle', () {
      final DateTime midi = DateTime(
        _maintenant.year,
        _maintenant.month,
        _maintenant.day,
        12,
      );
      NotificationTuteur a(String id, DateTime quand, String? cle) =>
          NotificationTuteur(
            id: id,
            titre: 'Un paiement arrive à échéance.',
            date: quand,
            lue: false,
            cleRegroupement: cle,
          );
      final List<GroupeNotifications> g = regrouperNotifications(
        <NotificationTuteur>[
          a('r1', midi.add(const Duration(hours: 2)), 'paiement_relance|/r|'),
          a('r2', midi.add(const Duration(hours: 1)), 'paiement_relance|/r|'),
          a('r3', midi, 'paiement_relance|/r|'),
          a(
            'veille',
            midi.subtract(const Duration(days: 1)),
            'paiement_relance|/r|',
          ),
          a('sans-cle-1', midi, null),
          a('sans-cle-2', midi, null),
        ],
      );
      expect(g.map((GroupeNotifications x) => x.nombre), <int>[3, 1, 1, 1]);
      expect(g.first.tete.id, 'r1');
    });
  });

  group('NOTIFS-L6 : la page', () {
    testWidgets('ouvrir la page ne marque rien ; les sections dans l ordre ; '
        'les anciennes repliees sous les priorites', (
      WidgetTester tester,
    ) async {
      final _Source source = _Source(<NotificationTuteur>[
        _n('lue', ilYa: const Duration(hours: 1)),
        _n('nouvelle', ilYa: const Duration(hours: 2), lue: false),
        _n('geste', ilYa: const Duration(days: 3), geste: true),
      ]);
      await _ouvrirCentre(tester, source);
      expect(source.marquagesGroupes, 0);
      expect(find.text(t.notifications.sectionAFaire), findsWidgets);
      expect(find.text(t.notifications.sectionNouvelles), findsOneWidget);
      expect(
        tester.getTopLeft(_ligne('geste')).dy,
        lessThan(tester.getTopLeft(_ligne('nouvelle')).dy),
      );
      // Replies : la lue n'est pas montree tant qu'on n'ouvre pas.
      expect(_ligne('lue'), findsNothing);
      await _toucher(tester, find.byKey(NotificationsPage.cleAnciennes));
      expect(_ligne('lue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('trois repetitions du meme jour : une ligne « 3 fois »', (
      WidgetTester tester,
    ) async {
      final _Source source = _Source(<NotificationTuteur>[
        for (int i = 0; i < 3; i++)
          _n(
            'relance-$i',
            ilYa: Duration(minutes: 10 + i),
            lue: false,
            cle: 'paiement_relance|/tuteur/foyer/recharge|',
            titre: 'Un paiement arrive à échéance.',
          ),
      ]);
      await _ouvrirCentre(tester, source);
      expect(_ligne('relance-0'), findsOneWidget);
      expect(_ligne('relance-1'), findsNothing);
      expect(
        find.textContaining(t.notifications.repetitions(n: 3)),
        findsOneWidget,
      );
    });

    testWidgets('« Voir plus » : 20 de plus, puis la page suivante de la '
        'source', (WidgetTester tester) async {
      final List<NotificationTuteur> tete = <NotificationTuteur>[
        for (int i = 0; i < 20; i++) _n('t$i', ilYa: Duration(hours: i + 1)),
      ];
      final List<NotificationTuteur> suite = <NotificationTuteur>[
        for (int i = 0; i < 5; i++) _n('s$i', ilYa: Duration(days: 30 + i)),
      ];
      final _Source source = _Source(tete, suite: suite);
      await _ouvrirCentre(tester, source);
      // Aucune priorite : les anciennes sont ouvertes d'office.
      expect(_ligne('t0'), findsOneWidget);
      expect(_ligne('t19'), findsOneWidget);
      expect(_ligne('s0'), findsNothing);
      await _toucher(tester, find.byKey(NotificationsPage.cleVoirPlus));
      expect(source.pagesDemandees, 1);
      expect(_ligne('s0'), findsOneWidget);
      expect(_ligne('s4'), findsOneWidget);
      // Moins de 20 : il n'y en a plus, « Voir plus » disparait.
      expect(find.byKey(NotificationsPage.cleVoirPlus), findsNothing);
    });

    testWidgets('« Ecarter » dans le menu d une ligne « A faire »', (
      WidgetTester tester,
    ) async {
      final _Source source = _Source(<NotificationTuteur>[
        _n('geste', ilYa: const Duration(hours: 1), geste: true, lue: false),
        _n('nouvelle', ilYa: const Duration(hours: 2), lue: false),
      ]);
      await _ouvrirCentre(tester, source);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('notification-menu-geste')),
      );
      expect(find.byType(MenuActions), findsWidgets);
      await _toucher(tester, find.text(t.notifications.ecarter).last);
      expect(source.ecartees, <String>['geste']);
      expect(_ligne('geste'), findsNothing);
      expect(find.byKey(NotificationsPage.cleAFaire), findsNothing);
    });
  });

  group(
    'NOTIFS-L6, reprise du pilote (02/11) : 10 nouvelles et un seul signe',
    () {
      testWidgets('« Nouvelles » : 10 lignes, puis 10 de plus', (
        WidgetTester tester,
      ) async {
        final _Source source = _Source(<NotificationTuteur>[
          for (int i = 0; i < 25; i++)
            _n('n$i', ilYa: Duration(hours: i + 1), lue: false),
        ]);
        await _ouvrirCentre(tester, source, taille: const Size(1440, 900));
        expect(_ligne('n9'), findsOneWidget);
        expect(_ligne('n10'), findsNothing);
        await _toucher(
          tester,
          find.byKey(NotificationsPage.cleVoirPlusNouvelles),
        );
        expect(_ligne('n19'), findsOneWidget);
        expect(_ligne('n20'), findsNothing);
        await _toucher(
          tester,
          find.byKey(NotificationsPage.cleVoirPlusNouvelles),
        );
        expect(_ligne('n24'), findsOneWidget);
        expect(
          find.byKey(NotificationsPage.cleVoirPlusNouvelles),
          findsNothing,
        );
      });

      testWidgets('le badge ne vit que sur « A faire », avec le mot du geste ; '
          '« Non lue » seul ailleurs', (WidgetTester tester) async {
        final _Source source = _Source(<NotificationTuteur>[
          _n(
            'relance',
            ilYa: const Duration(minutes: 5),
            lue: false,
            geste: true,
            evenement: 'paiement_relance',
          ),
          _n('nouvelle', ilYa: const Duration(hours: 1), lue: false),
        ]);
        await _ouvrirCentre(tester, source);
        expect(
          find.descendant(
            of: _ligne('relance'),
            matching: find.text(t.notifications.gesteRecharger),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _ligne('nouvelle'),
            matching: find.byType(BadgeNonLu),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: _ligne('nouvelle'),
            matching: find.textContaining(t.notifications.nonLue),
          ),
          findsOneWidget,
        );
        // Le lecteur d'ecran entend aussi un seul signe.
        final String phrase = LigneNotification.phraseSemantique(
          source.tete.last,
        );
        expect(phrase, contains(t.notifications.nonLueSemantique));
        expect(phrase, isNot(contains(t.com.socle.composants.badge.aLire)));
      });

      test('le mot du geste, par evenement', () {
        String mot(String e) => LigneNotification.libelleGeste(
          _n('x', ilYa: Duration.zero, geste: true, evenement: e),
        );
        final m = t.notifications;
        expect(mot('paiement_relance'), m.gesteRecharger);
        expect(mot('acces_suspendu_paiement'), m.gesteRecharger);
        expect(mot('remplacement_propose'), m.gestePrendreSeance);
        expect(mot('remplacement_pre_alerte'), m.gestePrendreSeance);
        expect(mot('demande_presentation'), m.gesteRepondre);
        expect(mot('controle_mission_attribuee'), m.gesteObserver);
        expect(mot('litige_ouvert'), m.gesteTraiterContestation);
        expect(mot('classe_creee'), m.sectionAFaire);
      });
    },
  );

  group('NOTIFS-L6 : l adaptateur Supabase', () {
    Map<String, dynamic> ligne({
      Object? gesteRequis,
      Object? ecartee,
      Object? fait,
    }) => <String, dynamic>{
      'id': 'x',
      'evenement': 'paiement_relance',
      'params': <String, dynamic>{'classe': 'Classe A'},
      'destination': '/tuteur/foyer/recharge',
      'cree_le': '2026-11-02T08:00:00Z',
      'lu_le': '2026-11-02T09:00:00Z',
      'geste_requis': ?gesteRequis,
      'ecartee_le': ?ecartee,
      'geste_fait_le': ?fait,
    };

    test('geste requis, ni fait ni ecarte : « A faire », meme lue', () {
      final NotificationTuteur n = notificationDepuis(
        ligne(gesteRequis: true),
        titrePour: contenuNotificationPour,
      );
      expect(n.lue, isTrue);
      expect(n.gesteEnAttente, isTrue);
      expect(n.aFaire, isTrue);
      expect(
        n.cleRegroupement,
        'paiement_relance|/tuteur/foyer/recharge|Classe A',
      );
    });

    test('ecartee, ou geste fait, ou colonnes absentes : pas « A faire »', () {
      for (final Map<String, dynamic> l in <Map<String, dynamic>>[
        ligne(gesteRequis: true, ecartee: '2026-11-02T10:00:00Z'),
        ligne(gesteRequis: true, fait: '2026-11-02T10:00:00Z'),
        ligne(),
      ]) {
        expect(
          notificationDepuis(l, titrePour: contenuNotificationPour).aFaire,
          isFalse,
        );
      }
    });
  });
}
