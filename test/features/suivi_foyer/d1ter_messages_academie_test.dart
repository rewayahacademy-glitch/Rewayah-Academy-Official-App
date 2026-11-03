// D1-ter (03/11/2026) : la carte « Messages de l'académie », sur ports fictifs.
//
// Ce que le test prouve :
// - l'adaptateur lit la vue et ecarte une ligne illisible, un message vide et
//   toute securite d'un enfant, meme si le serveur la rendait ;
// - la carte n'est posee qu'avec au moins un message : rien sans port, rien
//   sans message, et jamais en Interface guidee ;
// - elle dit, pour le tuteur, « Messages de l'académie sur <prénom> », la
//   nature, la date et le message ; pour l'eleve adulte, « Messages de
//   l'académie » ; jamais la note interne (le modele ne la porte pas) ;
// - une lecture en echec le dit, avec « Réessayer » ;
// - la notification dit le prenom, jamais le message ;
// - 320 px a 200 % et 1440 px en sombre, sans debordement.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/suivi/messages_academie_supabase.dart';
import 'package:rewayah_academy/core/suivi/port_messages_academie.dart';
import 'package:rewayah_academy/core/tc_parcours/libelles_parcours.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';
import 'package:rewayah_academy/features/suivi_foyer/carte_messages_academie.dart';

ResumeFamilleSignalement _message() => ResumeFamilleSignalement(
  concernId: 'c-1',
  categorie: CategorieSignalement.pedagogique,
  message: 'Yasmine gagnerait a relire la sourate avant le cours.',
  transmisA: CibleTransmission.tuteurDuMineur,
  transmisLeUtc: DateTime.utc(2030, 1, 9, 12),
);

class _Messages implements PortMessagesAcademie {
  _Messages({this.messages, this.echec = false});

  final List<ResumeFamilleSignalement>? messages;
  final bool echec;
  final List<String?> lectures = <String?>[];

  @override
  Future<List<ResumeFamilleSignalement>> pourEleve(String? eleveId) async {
    lectures.add(eleveId);
    if (echec) throw StateError('lecture');
    return messages ?? <ResumeFamilleSignalement>[_message()];
  }
}

Future<void> _monter(
  WidgetTester tester, {
  PortMessagesAcademie? port,
  String? prenom = 'Yasmine',
  InterfaceMode mode = InterfaceMode.standard,
  Size taille = const Size(1440, 2000),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portMessagesAcademieProvider.overrideWithValue(port),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(mode, luminosite),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: enfant!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarteMessagesAcademie(eleveId: 'e-1', prenom: prenom),
            ),
          ),
        ),
      ),
    ),
  );
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final m = t.d1ter.messages;

  group('adaptateur', () {
    test('lit la vue, ecarte l illisible et la securite d un enfant', () {
      final List<ResumeFamilleSignalement> l = messagesAcademieDepuisJson(
        <dynamic>[
          <String, dynamic>{
            'id': 'c-1',
            'categorie': 'presence',
            'family_summary': '  Un message  ',
            'transmis_le': '2030-01-09T12:00:00+00:00',
            'transmis_a': 'tuteur_du_mineur',
          },
          <String, dynamic>{
            'id': 'c-2',
            'categorie': 'securite_enfant',
            'family_summary': 'jamais',
          },
          <String, dynamic>{
            'id': 'c-3',
            'categorie': 'pedagogique',
            'family_summary': '   ',
          },
          <String, dynamic>{'id': 'c-4', 'categorie': 'inconnue'},
          'pas une ligne',
        ],
      );
      expect(l, hasLength(1));
      expect(l.single.message, 'Un message');
      expect(l.single.categorie, CategorieSignalement.presence);
      expect(l.single.transmisLeUtc, DateTime.utc(2030, 1, 9, 12));
      expect(messagesAcademieDepuisJson(null), isEmpty);
    });

    test('ne lit aucune colonne de note interne', () {
      expect(colonnesMessagesAcademie, isNot(contains('internal')));
      expect(
        colonnesMessagesAcademie.split(',').map((String c) => c.trim()),
        <String>[
          'id',
          'categorie',
          'family_summary',
          'transmis_le',
          'transmis_a',
        ],
      );
    });
  });

  group('carte', () {
    testWidgets('sans port, rien', (WidgetTester tester) async {
      await _monter(tester);
      expect(
        find.byKey(const ValueKey<String>('messages-academie')),
        findsNothing,
      );
    });

    testWidgets('sans message, rien', (WidgetTester tester) async {
      await _monter(
        tester,
        port: _Messages(messages: const <ResumeFamilleSignalement>[]),
      );
      expect(
        find.byKey(const ValueKey<String>('messages-academie')),
        findsNothing,
      );
    });

    testWidgets('en Interface guidee, jamais, et rien n est lu', (
      WidgetTester tester,
    ) async {
      final _Messages port = _Messages();
      await _monter(tester, port: port, mode: InterfaceMode.enfant);
      expect(
        find.byKey(const ValueKey<String>('messages-academie')),
        findsNothing,
      );
      expect(find.textContaining('sourate'), findsNothing);
      expect(port.lectures, isEmpty);
    });

    testWidgets('le tuteur lit le titre, la nature, la date et le message', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Messages());
      expect(find.text(m.titre(prenom: 'Yasmine')), findsOneWidget);
      expect(find.text(m.intro(prenom: 'Yasmine')), findsOneWidget);
      expect(
        find.text(
          libelleCategorieSignalement(CategorieSignalement.pedagogique),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('relire la sourate'), findsOneWidget);
      expect(find.textContaining('Transmis le'), findsOneWidget);
    });

    testWidgets('l eleve adulte lit « Messages de l académie »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Messages(), prenom: null);
      expect(find.text(m.titreSoi), findsOneWidget);
      expect(find.text(m.introSoi), findsOneWidget);
    });

    testWidgets('une lecture en echec le dit, avec Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Messages(echec: true));
      expect(
        find.byKey(const ValueKey<String>('messages-academie-erreur')),
        findsOneWidget,
      );
      expect(find.text(m.erreur), findsOneWidget);
    });

    for (final (String nom, Size taille, double echelle, Brightness l)
        in <(String, Size, double, Brightness)>[
          ('320 px, texte a 200 %', const Size(320, 3000), 2, Brightness.light),
          ('1440 px, sombre', const Size(1440, 2000), 1, Brightness.dark),
        ]) {
      testWidgets('lisible : $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          port: _Messages(),
          taille: taille,
          echelle: echelle,
          luminosite: l,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(m.titre(prenom: 'Yasmine')), findsOneWidget);
      });
    }
  });

  group('notification', () {
    tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

    test('le prenom, jamais le message', () {
      expect(
        contenuNotificationPour(
          'message_academie_eleve',
          const <String, dynamic>{'prenom': 'Yasmine', 'portee': 'foyer'},
        ).titre,
        t.d1ter.notifications.messageEnfant(prenom: 'Yasmine'),
      );
      expect(
        contenuNotificationPour(
          'message_academie_eleve',
          const <String, dynamic>{'portee': 'soi'},
        ).titre,
        t.d1ter.notifications.messageSoi,
      );
      expect(
        contenuNotificationPour(
          'message_academie_eleve',
          const <String, dynamic>{},
        ).titre,
        t.d1ter.notifications.message,
      );
    });

    test('l adaptateur garde le prenom pour la phrase, rien d autre', () {
      final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
        <String, dynamic>{
          'id': 'n-1',
          'evenement': 'message_academie_eleve',
          'params': <String, dynamic>{
            'eleve_id': 'e-1',
            'prenom': 'Yasmine',
            'portee': 'foyer',
          },
          'destination': '/tuteur/suivi',
          'cree_le': '2030-01-09T12:00:00Z',
          'lu_le': null,
        },
      ], titrePour: contenuNotificationPour);
      expect(liste, hasLength(1));
      expect(
        liste.single.titre,
        t.d1ter.notifications.messageEnfant(prenom: 'Yasmine'),
      );
    });

    test('en arabe', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      expect(
        contenuNotificationPour(
          'message_academie_eleve',
          const <String, dynamic>{'prenom': 'Yasmine', 'portee': 'foyer'},
        ).titre,
        contains('الإدارة'),
      );
    });
  });
}
