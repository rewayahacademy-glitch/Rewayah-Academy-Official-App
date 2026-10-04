// Le support des tests COM-STU-1 et COM-STU-2 : la vraie `StudioPage` sous un
// routeur minimal (`/admin`, `/admin/studio`, `/admin/studio/canaux/:canalId`
// et les modules canoniques qu'Aujourd'hui ouvre, chacun une page temoin qui
// dit son chemin et son argument), dans
// le vrai theme, a une taille, une langue, une echelle de texte et un reseau
// donnes ; et un port double qui sait echouer, attendre ou laisser passer un
// canal absent (pour prouver la defense de surface, R-COM-08).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';

import '../../support/harnais.dart';

/// L'heure fixe des tests.
final DateTime maintenantTest = DateTime.utc(2026, 10, 4, 12);

/// Le port de demonstration, a l'heure fixe.
StudioDemo portDemo({
  SituationDemoStudio situation = SituationDemoStudio.normale,
}) => StudioDemo(situation: situation, maintenant: maintenantTest);

/// Les modules canoniques qu'Aujourd'hui peut ouvrir, montes comme pages
/// temoins.
const List<String> modulesTemoins = <String>[
  Routes.adminPersonnesDossiers,
  Routes.adminOperationsGroupes,
  Routes.adminOperationsDemandes,
  Routes.adminCommunicationsAnnonces,
  Routes.adminCommunicationsMessages,
];

/// Le texte d'une page temoin : son chemin et son argument de navigation.
String temoinModule(String chemin, Object? argument) =>
    'module:$chemin:${argument ?? '-'}';

/// L'adresse de la vue des canaux (Aujourd'hui est l'accueil du Studio).
final String adresseCanaux = adresseVueStudio(VueStudio.canaux);

/// Monte la vraie `StudioPage` sur [depart], et rend son routeur.
///
/// [enregistres] : nul, le port neutre de production (indisponible) ; sinon
/// le double en memoire. [activite] : nul, le port neutre de production
/// (indisponible). [brouillons] : nul, une memoire de session neuve (le
/// comportement de production).
Future<GoRouter> monterStudio(
  WidgetTester tester, {
  required PortStudio port,
  String? depart,
  PortElementsEnregistres? enregistres,
  PortActiviteStudio? activite,
  PortBrouillons? brouillons,
  Size taille = const Size(1440, 900),
  AppLocale langue = AppLocale.fr,
  double echelleTexte = 1,
  Brightness luminosite = Brightness.light,
  bool horsLigne = false,
  bool stabiliser = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final GoRouter routeur = GoRouter(
    initialLocation: depart ?? adresseCanaux,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.admin,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('accueil-admin')),
      ),
      GoRoute(
        path: Routes.adminStudio,
        builder: (BuildContext _, GoRouterState _) => const StudioPage(),
      ),
      GoRoute(
        path: '${Routes.adminStudioCanaux}/:canalId',
        builder: (BuildContext _, GoRouterState etat) =>
            StudioPage(canalId: etat.pathParameters['canalId']),
      ),
      for (final String chemin in modulesTemoins)
        GoRoute(
          path: chemin,
          builder: (BuildContext _, GoRouterState etat) =>
              Scaffold(body: Text(temoinModule(chemin, etat.extra))),
        ),
    ],
  );
  addTearDown(routeur.dispose);
  final PortElementsEnregistres? memoire = enregistres;
  final PortActiviteStudio? activiteDonnee = activite;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        portStudioProvider.overrideWithValue(port),
        if (memoire != null)
          portElementsEnregistresProvider.overrideWithValue(memoire),
        if (activiteDonnee != null)
          portActiviteStudioProvider.overrideWithValue(activiteDonnee),
        portBrouillonsProvider.overrideWithValue(
          brouillons ?? BrouillonsMemoire(),
        ),
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

/// L'adresse courante du routeur (chemin et parametres).
String adresseCourante(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.toString();

/// Le chemin courant du routeur.
String cheminCourant(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

/// Un canal simple pour les doubles.
Canal canalSimple({
  String id = 'c1',
  String nom = 'Coordination',
  VisibiliteCanal visibilite = VisibiliteCanal.visible,
  SectionStudio section = SectionStudio.organisation,
  bool ecrire = true,
  String texte = 'Bonjour, le planning est en ligne.',
}) {
  const Participant soi = Participant(
    id: 'soi',
    nomAffiche: 'Nadia',
    estSoi: true,
  );
  const Participant autre = Participant(
    id: 'autre',
    nomAffiche: 'Mariam',
    fonction: 'Coordination',
  );
  return Canal(
    resume: ResumeCanal(
      id: id,
      nom: nom,
      section: section,
      visibilite: visibilite,
      dernierMessageLe: maintenantTest,
    ),
    membres: const <Participant>[soi, autre],
    messages: <MessageCommunication>[
      MessageCommunication(
        id: '$id-m1',
        auteur: autre,
        texte: texte,
        envoyeLe: maintenantTest.subtract(const Duration(hours: 1)),
      ),
    ],
    capacites: ecrire ? const <CapaciteCanal>{CapaciteCanal.ecrire} : const {},
  );
}

/// Un port double, reglable : contenu, echecs, attente, et un port qui
/// laisse passer un canal absent (un serveur defaillant).
class FauxStudio implements PortStudio {
  /// Cree le port.
  FauxStudio({
    List<Canal> canaux = const <Canal>[],
    this.erreurListe,
    this.erreurCanal,
    this.attenteListe,
    this.partagesRendus,
  }) : _canaux = <String, Canal>{for (final Canal c in canaux) c.id: c};

  final Map<String, Canal> _canaux;

  /// L'erreur rendue par `canaux()`, tant qu'elle n'est pas retiree.
  Exception? erreurListe;

  /// L'erreur rendue par `canal()`.
  Exception? erreurCanal;

  /// Retient `canaux()` jusqu'a sa completion.
  Completer<void>? attenteListe;

  /// Les partages rendus pour tout canal ; nul, aucun.
  PartagesCanal? partagesRendus;

  /// Le nombre de lectures de la liste.
  int lecturesListe = 0;

  /// Les envois recus.
  final List<(String, String, String)> envois = <(String, String, String)>[];

  @override
  Future<List<ResumeCanal>> canaux() async {
    lecturesListe++;
    final Completer<void>? attente = attenteListe;
    if (attente != null) await attente.future;
    final Exception? e = erreurListe;
    if (e != null) throw e;
    // Volontairement sans filtre : un canal absent passe, l'ecran doit le
    // retirer seul.
    return <ResumeCanal>[for (final Canal c in _canaux.values) c.resume];
  }

  @override
  Future<Canal?> canal(String canalId) async {
    final Exception? e = erreurCanal;
    if (e != null) throw e;
    return _canaux[canalId];
  }

  @override
  Future<PartagesCanal> partages(String canalId) async =>
      partagesRendus ?? PartagesCanal.aucun;

  @override
  Future<ResultatsStudio> rechercher(String texte) async => ResultatsStudio(
    canaux: <ResumeCanal>[for (final Canal c in _canaux.values) c.resume],
    messages: <MessageTrouve>[
      for (final Canal c in _canaux.values)
        for (final MessageCommunication m in c.messages)
          MessageTrouve(canal: c.resume, message: m),
    ],
  );

  @override
  Future<void> marquerLu(String canalId) async {}

  /// Retient chaque envoi jusqu'a sa completion (l'envoi est compte des
  /// son depart).
  Completer<void>? attenteEnvoi;

  @override
  Future<void> envoyer(String canalId, String texte, String cle) async {
    envois.add((canalId, texte, cle));
    final Completer<void>? attente = attenteEnvoi;
    if (attente != null) await attente.future;
  }
}

/// Tous les textes rendus a l'ecran, champs compris.
List<String> textesRendus(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(find.byType(Text)))
    w.data ?? w.textSpan?.toPlainText() ?? '',
  for (final EditableText w in tester.widgetList<EditableText>(
    find.byType(EditableText),
  ))
    w.controller.text,
];
