// Le support des tests COM-MSG-1 : la vraie `MessagesPage` sous un routeur
// minimal (liste `/tuteur/messages`, fil `/tuteur/messages/:filId`), dans le
// vrai theme, a une taille, une langue, une echelle de texte et un reseau
// donnes ; et un port double qui sait echouer, attendre ou refuser.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/harnais.dart';

/// La capacite `ecrireDansFil` ouverte (COM-BR-16), comme la demonstration :
/// le port de production est neutre et ferme tout.
final Override capaciteEcrireOuverteTest = portCapacitesCommunicationsProvider
    .overrideWithValue(
      const CapacitesCommunicationsFixes(<CapaciteCommunication>{
        CapaciteCommunication.ecrireDansFil,
      }),
    );

/// L'heure fixe des tests.
final DateTime maintenantTest = DateTime.utc(2026, 10, 4, 12);

/// Le chemin de la liste dans le routeur des tests.
const String cheminListeTest = '/tuteur/messages';

/// Le chemin ou mene le retour de la liste.
const String cheminRacineTest = '/tuteur';

/// Le chemin d'un fil dans le routeur des tests.
String cheminFilTest(String filId) => '$cheminListeTest/$filId';

/// Le port de demonstration pour [role], a l'heure fixe.
MessagesMetierDemo portDemo(
  RoleDemoCommunications role, {
  SituationDemoMessages situation = SituationDemoMessages.normale,
}) => MessagesMetierDemo(
  role: role,
  situation: situation,
  maintenant: maintenantTest,
);

/// Monte la vraie `MessagesPage` sur [depart], et rend son routeur. Sans
/// [ecritureOuverte], le port des capacites reste celui de production
/// (neutre, tout ferme : COM-BR-16).
Future<GoRouter> monterMessages(
  WidgetTester tester, {
  required PortMessagesMetier port,
  String depart = cheminListeTest,
  Size taille = const Size(1440, 900),
  AppLocale langue = AppLocale.fr,
  double echelleTexte = 1,
  Brightness luminosite = Brightness.light,
  bool horsLigne = false,
  bool ecritureOuverte = true,
  List<Override> surcharges = const <Override>[],
  bool stabiliser = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: cheminRacineTest,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('racine-du-role')),
      ),
      GoRoute(
        path: '/tuteur/classes/:id',
        builder: (BuildContext _, GoRouterState etat) =>
            Scaffold(body: Text('classe-${etat.pathParameters['id']}')),
      ),
      GoRoute(
        path: cheminListeTest,
        builder: (BuildContext _, GoRouterState _) =>
            const MessagesPage(cheminRetour: cheminRacineTest),
        routes: <RouteBase>[
          GoRoute(
            path: ':filId',
            builder: (BuildContext _, GoRouterState etat) => MessagesPage(
              filId: etat.pathParameters['filId'],
              cheminRetour: cheminListeTest,
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        portMessagesMetierProvider.overrideWithValue(port),
        if (ecritureOuverte) capaciteEcrireOuverteTest,
        ...surcharges,
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: luminosite == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelleTexte)),
            child: app!,
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  if (stabiliser) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return routeur;
}

/// L'adresse courante du routeur.
String cheminCourant(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

/// Un port double, reglable : contenu, echecs, attente, refus.
class FauxMessagesMetier implements PortMessagesMetier {
  /// Cree le port.
  FauxMessagesMetier({
    List<FilMetier> fils = const <FilMetier>[],
    this.erreurListe,
    this.erreurFil,
    this.attenteListe,
    this.filSousUnAutreId,
    this.resumesEnPlus = const <ResumeFil>[],
  }) : _fils = <String, FilMetier>{for (final FilMetier f in fils) f.id: f};

  final Map<String, FilMetier> _fils;

  /// Des resumes rendus en plus des fils (objets interdits ici).
  final List<ResumeFil> resumesEnPlus;

  /// L'erreur rendue par `fils()`, tant qu'elle n'est pas retiree.
  Exception? erreurListe;

  /// L'erreur rendue par `fil()`.
  Exception? erreurFil;

  /// Retient `fils()` jusqu'a sa completion.
  Completer<void>? attenteListe;

  /// Rendu par `fil()` quel que soit l'identifiant demande.
  FilMetier? filSousUnAutreId;

  /// Le nombre de lectures de la liste.
  int lecturesListe = 0;

  /// Les envois recus.
  final List<(String, String, String)> envois = <(String, String, String)>[];

  @override
  Future<List<ResumeFil>> fils() async {
    lecturesListe++;
    final Completer<void>? attente = attenteListe;
    if (attente != null) await attente.future;
    final Exception? e = erreurListe;
    if (e != null) throw e;
    return <ResumeFil>[
      for (final FilMetier f in _fils.values)
        ResumeFil(
          id: f.id,
          objet: f.objet,
          interlocuteurs: f.interlocuteurs,
          apercu: f.messages.isEmpty ? null : f.messages.last.texte,
          dernierMessageLe: f.messages.isEmpty
              ? null
              : f.messages.last.envoyeLe,
          attention: f.attention,
        ),
      ...resumesEnPlus,
    ];
  }

  @override
  Future<FilMetier?> fil(String filId) async {
    final Exception? e = erreurFil;
    if (e != null) throw e;
    return filSousUnAutreId ?? _fils[filId];
  }

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) async =>
      null;

  @override
  Future<void> marquerLu(String filId) async {}

  @override
  Future<void> envoyer(String filId, String texte, String cle) async {
    envois.add((filId, texte, cle));
  }
}

/// Un fil simple pour les doubles : un interlocuteur, une Classe, un
/// message.
FilMetier filSimple({
  String id = 'fil-1',
  bool ecrire = true,
  String? destinationClasse,
  bool classeAccessible = true,
  String texte = 'Bonjour, voici une question sur la séance.',
}) {
  const Participant soi = Participant(
    id: 'soi',
    nomAffiche: 'Ahmed',
    estSoi: true,
  );
  const Participant autre = Participant(
    id: 'autre',
    nomAffiche: 'Mme Mariam',
    fonction: 'Enseignante de la Classe An-Nour',
  );
  return FilMetier(
    id: id,
    contexte: <ElementContexteFil>[
      ElementContexteFil(
        objet: ObjetLie(
          type: TypeObjetLie.classe,
          id: 'an-nour',
          libelle: 'Classe An-Nour',
          destination: destinationClasse,
        ),
        accessible: classeAccessible,
      ),
    ],
    participants: const <Participant>[soi, autre],
    messages: <MessageCommunication>[
      MessageCommunication(
        id: '$id-m1',
        auteur: autre,
        texte: texte,
        envoyeLe: maintenantTest.subtract(const Duration(hours: 1)),
      ),
    ],
    capacites: ecrire ? const <CapaciteFil>{CapaciteFil.ecrire} : const {},
  );
}

/// Tous les textes rendus a l'ecran.
List<String> textesRendus(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(find.byType(Text)))
    w.data ?? w.textSpan?.toPlainText() ?? '',
  for (final EditableText w in tester.widgetList<EditableText>(
    find.byType(EditableText),
  ))
    w.controller.text,
];
