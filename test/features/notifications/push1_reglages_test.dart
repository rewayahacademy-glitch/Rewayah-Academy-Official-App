// PUSH-1 (07/11/2026) : les Reglages des notifications sur l'appareil.
//
// Ce que le test prouve :
//   - l'autorisation du navigateur n'est JAMAIS demandee a l'ouverture, seulement
//     apres le geste « Recevoir les notifications sur cet appareil », et
//     l'abonnement est ensuite inscrit sur le serveur ;
//   - un refus du navigateur se dit, sans inscription ;
//   - retirer l'appareil, couper une categorie ;
//   - les cinq etats : chargement, contenu, vide (compte sans push), erreur,
//     hors ligne ; iPhone hors ecran d'accueil ; un seul bouton plein ;
//   - la cle publique n'est lue que si l'appareil peut s'abonner ;
//   - les quatorze evenements nouveaux ont un texte et un geste, sans nom ;
//     la finance du comptable se lit comme celle de la direction ;
//   - les destinations nouvelles s'ouvrent.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/push/bandeau_invitation_push.dart';
import 'package:rewayah_academy/core/push/invitation_push.dart';
import 'package:rewayah_academy/core/push/port_push.dart';
import 'package:rewayah_academy/core/push/reglages_push.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';
import 'package:rewayah_academy/features/notifications/reglages_push.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

class _Navigateur implements NavigateurPush {
  _Navigateur(this.etatActuel, {this.refus});

  EtatAppareilPush etatActuel;
  RefusActivation? refus;
  final List<String> journal = <String>[];

  @override
  Future<EtatAppareilPush> etat() async => etatActuel;

  @override
  Future<String?> adresse() async =>
      etatActuel == EtatAppareilPush.actif ? 'https://push.test/moi' : null;

  @override
  Future<AbonnementNavigateur> activer(String clePublique) async {
    journal.add('activer:$clePublique');
    final RefusActivation? r = refus;
    if (r != null) throw ActivationRefusee(r);
    etatActuel = EtatAppareilPush.actif;
    return const AbonnementNavigateur(
      endpoint: 'https://push.test/moi',
      p256dh: 'cle',
      auth: 'secret',
    );
  }

  @override
  Future<String?> desactiver() async {
    journal.add('desactiver');
    etatActuel = EtatAppareilPush.inactif;
    return 'https://push.test/moi';
  }

  bool geste = false;

  @override
  Future<bool> besoinGeste() async => geste;

  @override
  String get appareil => 'Android';
}

class _Serveur implements PortPush {
  _Serveur({this.autorise = true, this.echec = false});

  bool autorise;
  bool echec;
  bool inscrit = false;
  int clesLues = 0;
  Completer<void>? attente;
  final Map<CategoriePush, bool> categories = <CategoriePush, bool>{
    for (final CategoriePush c in CategoriePush.values) c: true,
  };
  final List<String> journal = <String>[];

  @override
  Future<ReglagesPushServeur> reglages({String? adresse}) async {
    await attente?.future;
    if (echec) throw StateError('lecture');
    return ReglagesPushServeur(
      autorise: autorise,
      cetAppareil: inscrit && adresse != null,
      appareils: inscrit ? 1 : 0,
      categories: Map<CategoriePush, bool>.of(categories),
    );
  }

  @override
  Future<String> clePublique() async {
    clesLues++;
    return 'CLE-PUBLIQUE';
  }

  @override
  Future<void> inscrire(
    AbonnementNavigateur abonnement, {
    String? appareil,
  }) async {
    journal.add('inscrire:${abonnement.endpoint}:$appareil');
    inscrit = true;
  }

  @override
  Future<void> desinscrire(String adresse) async {
    journal.add('desinscrire:$adresse');
    inscrit = false;
  }

  @override
  Future<void> reglerCategorie(
    CategoriePush categorie, {
    required bool actif,
  }) async {
    journal.add('categorie:${categorie.name}:$actif');
    categories[categorie] = actif;
  }
}

Future<void> _monter(
  WidgetTester tester,
  _Navigateur navigateur,
  _Serveur serveur, {
  bool horsLigne = false,
  double largeur = 390,
}) async {
  tester.view.physicalSize = Size(largeur, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[ReglagesPushVue(), ActionReglagesPush()],
          ),
        ),
      ),
      surcharges: <Override>[
        navigateurPushProvider.overrideWithValue(navigateur),
        portPushProvider.overrideWithValue(serveur),
        horsLigneProvider.overrideWith(
          (Ref ref) => Stream<bool>.value(horsLigne),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('PUSH-1 : autorisation apres un geste', () {
    testWidgets('rien n\'est demande a l\'ouverture ; le geste demande puis '
        'inscrit', (WidgetTester tester) async {
      final _Navigateur nav = _Navigateur(EtatAppareilPush.inactif);
      final _Serveur serveur = _Serveur();
      await _monter(tester, nav, serveur);

      expect(nav.journal, isEmpty, reason: 'aucune demande a l\'ouverture');
      expect(find.text(t.push1.reglages.appareilInactif), findsOneWidget);
      expect(nav.journal, isEmpty);
      expect(find.byKey(ReglagesPushVue.cleActiver), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);

      await tester.tap(find.byKey(ReglagesPushVue.cleActiver));
      await tester.pumpAndSettle();

      expect(nav.journal, <String>['activer:CLE-PUBLIQUE']);
      expect(serveur.journal, <String>[
        'inscrire:https://push.test/moi:Android',
      ]);
      expect(find.text(t.push1.reglages.active), findsOneWidget);
      expect(find.byKey(ReglagesPushVue.cleDesactiver), findsOneWidget);
      expect(find.text(t.push1.reglages.appareilActif), findsOneWidget);
    });

    testWidgets('un refus du navigateur se dit, sans inscription', (
      WidgetTester tester,
    ) async {
      final _Navigateur nav = _Navigateur(
        EtatAppareilPush.inactif,
        refus: RefusActivation.refuse,
      );
      final _Serveur serveur = _Serveur();
      await _monter(tester, nav, serveur);
      await tester.tap(find.byKey(ReglagesPushVue.cleActiver));
      await tester.pumpAndSettle();
      expect(serveur.journal, isEmpty);
      expect(find.text(t.push1.reglages.refuse), findsOneWidget);
    });

    testWidgets('retirer l\'appareil : le navigateur puis le serveur', (
      WidgetTester tester,
    ) async {
      final _Navigateur nav = _Navigateur(EtatAppareilPush.actif);
      final _Serveur serveur = _Serveur()..inscrit = true;
      await _monter(tester, nav, serveur);
      expect(serveur.clesLues, 0, reason: 'actif : la cle n\'est pas lue');
      await tester.tap(find.byKey(ReglagesPushVue.cleDesactiver));
      await tester.pumpAndSettle();
      expect(nav.journal, <String>['desactiver']);
      expect(serveur.journal, <String>['desinscrire:https://push.test/moi']);
      expect(find.text(t.push1.reglages.desactive), findsOneWidget);
    });

    testWidgets('couper une categorie la regle sur le serveur', (
      WidgetTester tester,
    ) async {
      final _Serveur serveur = _Serveur();
      await _monter(tester, _Navigateur(EtatAppareilPush.inactif), serveur);
      for (final CategoriePush c in CategoriePush.values) {
        expect(find.byKey(ReglagesPushVue.cleCategorie(c)), findsOneWidget);
      }
      await tester.tap(
        find.byKey(ReglagesPushVue.cleCategorie(CategoriePush.paiements)),
      );
      await tester.pumpAndSettle();
      expect(serveur.journal, <String>['categorie:paiements:false']);
    });
  });

  group('PUSH-1 : les etats', () {
    testWidgets('chargement', (WidgetTester tester) async {
      final _Serveur serveur = _Serveur()..attente = Completer<void>();
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: Column(
              children: <Widget>[ReglagesPushVue(), ActionReglagesPush()],
            ),
          ),
          surcharges: <Override>[
            navigateurPushProvider.overrideWithValue(
              _Navigateur(EtatAppareilPush.inactif),
            ),
            portPushProvider.overrideWithValue(serveur),
            horsLigneProvider.overrideWith(
              (Ref ref) => Stream<bool>.value(false),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Skeleton), findsWidgets);
      serveur.attente!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
    });

    testWidgets('vide : un compte sans push (enfant, inactif)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _Navigateur(EtatAppareilPush.inactif),
        _Serveur(autorise: false),
      );
      expect(
        find.text(t.push1.reglages.compteNonAutoriseTitre),
        findsOneWidget,
      );
      expect(find.byKey(ReglagesPushVue.cleActiver), findsNothing);
    });

    testWidgets('erreur : une phrase et Reessayer', (
      WidgetTester tester,
    ) async {
      final _Serveur serveur = _Serveur(echec: true);
      await _monter(tester, _Navigateur(EtatAppareilPush.inactif), serveur);
      expect(find.text(t.push1.reglages.erreur), findsOneWidget);
      serveur.echec = false;
      await tester.tap(find.text(t.commun.etats.actions.reessayer).first);
      await tester.pumpAndSettle();
      expect(find.byKey(ReglagesPushVue.cleActiver), findsOneWidget);
    });

    testWidgets('hors ligne', (WidgetTester tester) async {
      await _monter(
        tester,
        _Navigateur(EtatAppareilPush.inactif),
        _Serveur(),
        horsLigne: true,
      );
      expect(find.text(t.push1.reglages.horsLigne), findsOneWidget);
      expect(find.byKey(ReglagesPushVue.cleActiver), findsNothing);
    });

    testWidgets('iPhone hors ecran d\'accueil : la marche a suivre, sans '
        'bouton', (WidgetTester tester) async {
      final _Serveur serveur = _Serveur();
      await _monter(
        tester,
        _Navigateur(EtatAppareilPush.iosEcranAccueil),
        serveur,
      );
      expect(find.text(t.push1.reglages.iosEcranAccueil), findsOneWidget);
      expect(find.byKey(ReglagesPushVue.cleActiver), findsNothing);
      expect(serveur.clesLues, 0);
    });

    testWidgets('bureau 1440 : un seul bouton plein', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _Navigateur(EtatAppareilPush.inactif),
        _Serveur(),
        largeur: 1440,
      );
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('PUSH-1 : les evenements nouveaux', () {
    const List<String> nouveaux = <String>[
      'admission_recue',
      'candidature_enseignant_a_examiner',
      'demande_horaire_recue',
      'creneau_personnalise_demande',
      'piece_identite_deposee',
      'signalement_eleve_recu',
      'suppression_compte_demandee',
      'remplacement_personne_en_salle',
      'paiement_echoue',
      'versement_coordonnees_a_valider',
      'versement_coordonnees_validees',
      'remboursement_demande',
      'remboursement_echec',
      'cahier_en_retard',
    ];

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      test('chacun a son texte (${langue.languageCode})', () async {
        await LocaleSettings.setLocale(langue);
        for (final String e in nouveaux) {
          final String titre = contenuNotificationPour(
            e,
            const <String, dynamic>{'portee': 'direction'},
          ).titre;
          expect(titre, isNot(t.notifications.evenements.inconnu), reason: e);
          expect(titre, isNot(contains('admin')), reason: e);
          expect(titre, isNot(contains('groupe')), reason: e);
        }
        await LocaleSettings.setLocale(AppLocale.fr);
      });
    }

    test('la finance du comptable se lit comme celle de la direction', () {
      for (final String e in <String>[
        'litige_ouvert',
        'litige_clos',
        'remboursement_effectue',
        'paiement_echoue',
      ]) {
        expect(
          contenuNotificationPour(e, const <String, dynamic>{
            'portee': 'comptable',
          }).titre,
          contenuNotificationPour(e, const <String, dynamic>{
            'portee': 'direction',
          }).titre,
          reason: e,
        );
      }
      expect(
        contenuNotificationPour('paiement_echoue', const <String, dynamic>{
          'portee': 'foyer',
        }).titre,
        t.push1.evenements.paiementEchoue,
      );
    });

    test('le geste attendu se nomme', () {
      NotificationTuteur n(String e, String destination) => NotificationTuteur(
        id: e,
        titre: e,
        date: DateTime.utc(2026, 11, 7),
        destination: destination,
        evenement: e,
        gesteEnAttente: true,
      );
      expect(
        LigneNotification.libelleGeste(
          n('admission_recue', '/admin/personnes/demandes'),
        ),
        t.push1.gestes.examiner,
      );
      expect(
        LigneNotification.libelleGeste(
          n('paiement_echoue', '/tuteur/foyer/recharge'),
        ),
        t.notifications.gesteRecharger,
      );
      expect(
        LigneNotification.libelleGeste(
          n('paiement_echoue', '/comptable/tresorerie/paiements-familles'),
        ),
        t.push1.gestes.voirPaiement,
      );
      expect(
        LigneNotification.libelleGeste(
          n('titulaire_en_retard', '/admin/operations/planning'),
        ),
        t.push1.gestes.trouverRemplacant,
      );
    });

    test('les destinations nouvelles s\'ouvrent', () {
      for (final String d in <String>[
        '/admin/personnes/candidatures',
        '/admin/personnes/demandes',
        '/admin/operations/demandes',
        '/admin/personnes/dossiers',
        '/admin/alertes',
        '/admin/personnes/suppressions',
        '/admin/finance/paiements',
        '/comptable/tresorerie/paiements-familles',
        '/comptable/paiements/beneficiaires',
        '/compte/paiements-recus',
      ]) {
        expect(destinationNotificationAutorisee(d), isTrue, reason: d);
      }
    });
  });

  test('deconnexion : l\'appareil abonne est retire du navigateur puis du '
      'serveur', () async {
    final _Navigateur actif = _Navigateur(EtatAppareilPush.actif);
    final _Serveur serveur = _Serveur()..inscrit = true;
    await desactiverPushSiPossible(actif, serveur);
    expect(actif.journal, <String>['desactiver']);
    expect(serveur.journal, <String>['desinscrire:https://push.test/moi']);
  });

  test('lireReglagesPush : la cle n\'est lue que si l\'appareil peut '
      's\'abonner', () async {
    final _Serveur refuse = _Serveur(autorise: false);
    await lireReglagesPush(_Navigateur(EtatAppareilPush.inactif), refuse);
    expect(refuse.clesLues, 0);
    final _Serveur ouvert = _Serveur();
    final EtatReglagesPush e = await lireReglagesPush(
      _Navigateur(EtatAppareilPush.inactif),
      ouvert,
    );
    expect(ouvert.clesLues, 1);
    expect(e.clePublique, 'CLE-PUBLIQUE');
    expect(e.actif, isFalse);
  });

  group('NOTIF-DEFAUT : la demande de premiere connexion', () {
    ProviderContainer conteneur(_Navigateur nav, _Serveur serveur) {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          navigateurPushProvider.overrideWithValue(nav),
          portPushProvider.overrideWithValue(serveur),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() => effacerMemoireAppareil(cleMemoireInvitationPush));

    test('Chrome et Edge : la demande part au chargement, une seule fois, '
        'sans fenetre', () async {
      final _Navigateur nav = _Navigateur(EtatAppareilPush.inactif);
      final _Serveur serveur = _Serveur();
      final ProviderContainer c = conteneur(nav, serveur);
      await c.read(invitationPushProvider.notifier).verifier();
      expect(nav.journal, <String>['activer:CLE-PUBLIQUE']);
      expect(serveur.inscrit, isTrue);
      expect(c.read(invitationPushProvider).visible, isFalse);
      expect(lireMemoireAppareil(cleMemoireInvitationPush), isNotNull);
      // Une autre ouverture : plus de demande.
      final ProviderContainer autre = conteneur(
        _Navigateur(EtatAppareilPush.inactif),
        _Serveur(),
      );
      await autre.read(invitationPushProvider.notifier).verifier();
      expect(autre.read(invitationPushProvider).visible, isFalse);
    });

    test('un refus est retenu : on ne redemande plus', () async {
      final _Navigateur nav = _Navigateur(
        EtatAppareilPush.inactif,
        refus: RefusActivation.refuse,
      );
      final ProviderContainer c = conteneur(nav, _Serveur());
      await c.read(invitationPushProvider.notifier).verifier();
      expect(lireMemoireAppareil(cleMemoireInvitationPush), isNotNull);
      final _Navigateur nav2 = _Navigateur(EtatAppareilPush.inactif);
      final ProviderContainer c2 = conteneur(nav2, _Serveur());
      await c2.read(invitationPushProvider.notifier).verifier();
      expect(nav2.journal, isEmpty);
    });

    test('Safari, iOS, Firefox : une fenetre, et la demande ne part qu\'au '
        'toucher d\'Activer', () async {
      final _Navigateur nav = _Navigateur(EtatAppareilPush.inactif)
        ..geste = true;
      final _Serveur serveur = _Serveur();
      final ProviderContainer c = conteneur(nav, serveur);
      final InvitationPush i = c.read(invitationPushProvider.notifier);
      await i.verifier();
      expect(c.read(invitationPushProvider).visible, isTrue);
      expect(nav.journal, isEmpty);
      expect(lireMemoireAppareil(cleMemoireInvitationPush), isNull);
      await i.activer();
      expect(nav.journal, <String>['activer:CLE-PUBLIQUE']);
      expect(serveur.inscrit, isTrue);
      expect(c.read(invitationPushProvider).visible, isFalse);
      expect(lireMemoireAppareil(cleMemoireInvitationPush), isNotNull);
    });

    test('« Plus tard » est retenu', () async {
      final _Navigateur nav = _Navigateur(EtatAppareilPush.inactif)
        ..geste = true;
      final ProviderContainer c = conteneur(nav, _Serveur());
      final InvitationPush i = c.read(invitationPushProvider.notifier);
      await i.verifier();
      i.plusTard();
      expect(c.read(invitationPushProvider).visible, isFalse);
      expect(nav.journal, isEmpty);
      expect(lireMemoireAppareil(cleMemoireInvitationPush), isNotNull);
    });

    test('rien a demander : compte sans push, blocage deja choisi, iPhone '
        'pas installe, appareil deja abonne', () async {
      for (final (_Navigateur nav, _Serveur serveur)
          in <(_Navigateur, _Serveur)>[
            (_Navigateur(EtatAppareilPush.inactif), _Serveur(autorise: false)),
            (_Navigateur(EtatAppareilPush.refuse), _Serveur()),
            (_Navigateur(EtatAppareilPush.iosEcranAccueil), _Serveur()),
            (_Navigateur(EtatAppareilPush.nonPrisEnCharge), _Serveur()),
            (_Navigateur(EtatAppareilPush.actif), _Serveur()..inscrit = true),
          ]) {
        final ProviderContainer c = conteneur(nav, serveur);
        await c.read(invitationPushProvider.notifier).verifier();
        expect(nav.journal, isEmpty);
        expect(c.read(invitationPushProvider).visible, isFalse);
      }
    });

    test('serveur injoignable : rien n\'est retenu, on redemandera', () async {
      final ProviderContainer c = conteneur(
        _Navigateur(EtatAppareilPush.inactif),
        _Serveur(echec: true),
      );
      await c.read(invitationPushProvider.notifier).verifier();
      expect(lireMemoireAppareil(cleMemoireInvitationPush), isNull);
    });

    testWidgets('la fenetre : titre, Activer, Plus tard ; un seul bouton '
        'plein', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final _Navigateur nav = _Navigateur(EtatAppareilPush.inactif)
        ..geste = true;
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: Column(children: <Widget>[BandeauInvitationPush()]),
          ),
          surcharges: <Override>[
            navigateurPushProvider.overrideWithValue(nav),
            portPushProvider.overrideWithValue(_Serveur()),
          ],
        ),
      );
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(BandeauInvitationPush)),
      );
      await c.read(invitationPushProvider.notifier).verifier();
      await tester.pumpAndSettle();
      expect(find.text(t.push1.invitation.titre), findsOneWidget);
      expect(find.text(t.push1.invitation.activer), findsOneWidget);
      expect(find.text(t.push1.invitation.plusTard), findsOneWidget);
      await tester.tap(find.byKey(BandeauInvitationPush.cleActiver));
      await tester.pumpAndSettle();
      expect(nav.journal, <String>['activer:CLE-PUBLIQUE']);
      expect(find.text(t.push1.invitation.titre), findsNothing);
    });
  });
}
