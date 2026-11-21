// CLOCHE-C : le montage de la cloche sur le vrai routeur (coquille du tuteur),
// ses faux ports et des donnees de demonstration (aucun nom de personne).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/notifications/cloche/annonces_cloche.dart';
import 'package:rewayah_academy/features/notifications/non_lues.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../capture/outil_capture.dart' show cadreCapture;
import '../classe_tuteur/support_classe.dart';

/// L'instant de reference des donnees : samedi 21 novembre 2026, 19:30 UTC.
final DateTime instantCloche = DateTime.utc(2026, 11, 21, 19, 30);

/// Comment le faux port des notifications repond.
enum ModeNotifs { donnees, echec, attente, indisponible }

/// Le faux port des notifications de la cloche.
class FauxNotifsCloche
    implements
        PortNotifications,
        PortLectureNotifications,
        PortLectureGroupeeNotifications {
  /// Cree le port.
  FauxNotifsCloche(this.notifications, {this.mode = ModeNotifs.donnees});

  /// Les notifications rendues.
  List<NotificationTuteur> notifications;

  /// Le mode de reponse.
  ModeNotifs mode;

  /// Les identifiants marques lus.
  final List<String> lues = <String>[];

  /// Le nombre de « Tout marquer comme lu ».
  int toutesLues = 0;

  @override
  Future<List<NotificationTuteur>> liste() => switch (mode) {
    ModeNotifs.donnees => Future<List<NotificationTuteur>>.value(notifications),
    ModeNotifs.echec => Future<List<NotificationTuteur>>.error(
      StateError('serveur'),
    ),
    ModeNotifs.attente => Completer<List<NotificationTuteur>>().future,
    ModeNotifs.indisponible => Future<List<NotificationTuteur>>.error(
      const CapaciteIndisponible('test'),
    ),
  };

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      notifications.where((NotificationTuteur n) => n.id == id).firstOrNull;

  @override
  Future<void> marquerLue(String id) async {
    lues.add(id);
    notifications = <NotificationTuteur>[
      for (final NotificationTuteur n in notifications)
        n.id == id ? n.marqueeLue() : n,
    ];
  }

  @override
  Future<void> marquerToutesLues() async {
    toutesLues++;
    notifications = <NotificationTuteur>[
      for (final NotificationTuteur n in notifications) n.marqueeLue(),
    ];
  }
}

/// La fausse source des annonces, qui sait fermer (le contrat du lot
/// ANNONCES-SERVEUR).
class FausseSourceAnnonces implements SourceAnnoncesCloche {
  /// Cree la source.
  FausseSourceAnnonces(
    this.annonces, {
    this.fermeture = true,
    this.echecFermeture = false,
    this.echec = false,
    this.suiteBloquee = false,
  });

  /// Vrai pour que la page suivante ne reponde jamais (« Voir plus » en
  /// cours, captures).
  final bool suiteBloquee;

  /// Les annonces de la personne.
  List<AnnonceCloche> annonces;

  /// Vrai si la source sait fermer.
  final bool fermeture;

  /// Vrai pour qu'une fermeture echoue.
  bool echecFermeture;

  /// Vrai pour que la lecture echoue.
  bool echec;

  /// Les fermetures recues, puis les reouvertures.
  final List<String> fermees = <String>[];
  final List<String> rouvertes = <String>[];

  /// Les annonces comptees vues.
  final List<String> vues = <String>[];

  @override
  bool get fermetureServie => fermeture;

  @override
  Future<PageAnnoncesCloche> page({
    int limite = SourceAnnoncesCloche.taillePage,
    DateTime? avant,
    bool fermees = false,
  }) async {
    if (echec) throw StateError('serveur');
    if (suiteBloquee && avant != null) {
      return Completer<PageAnnoncesCloche>().future;
    }
    return decouperPage(
      <AnnonceCloche>[
        for (final AnnonceCloche a in annonces)
          if (fermees || !a.fermee) a,
      ],
      limite: limite,
      avant: avant,
    );
  }

  @override
  Future<void> fermer(String id) async {
    if (echecFermeture) throw StateError('serveur');
    fermees.add(id);
    annonces = <AnnonceCloche>[
      for (final AnnonceCloche a in annonces)
        a.id == id ? a.avecFermee(true) : a,
    ];
  }

  @override
  Future<void> rouvrir(String id) async {
    rouvertes.add(id);
    annonces = <AnnonceCloche>[
      for (final AnnonceCloche a in annonces)
        a.id == id ? a.avecFermee(false) : a,
    ];
  }

  @override
  Future<void> marquerVue(String id) async => vues.add(id);
}

/// Les notifications de demonstration, dans la langue courante des donnees.
List<NotificationTuteur> notifsDemo({
  bool arabe = false,
}) => <NotificationTuteur>[
  NotificationTuteur(
    id: 'n1',
    titre: arabe
        ? 'دفعة شهر ديسمبر منتظرة'
        : 'Le paiement de décembre est attendu',
    texte: arabe
        ? 'اشحن الرصيد لتبقى الحصص محجوزة.'
        : 'Rechargez pour garder les séances réservées.',
    date: instantCloche.subtract(const Duration(minutes: 27)),
    destination: Routes.tuteurFoyerRecharge,
    niveau: NiveauAttention.actionRequise,
    lue: false,
    gesteEnAttente: true,
    evenement: 'paiement_relance',
  ),
  NotificationTuteur(
    id: 'n2',
    titre: arabe ? 'السبت 21 نوفمبر، 15:00' : 'samedi 21 novembre, 15:00',
    texte: arabe
        ? 'الموعد الجديد قريبًا.'
        : 'Le nouvel horaire arrive bientôt.',
    date: instantCloche.subtract(const Duration(hours: 4)),
    type: TypeNotification.changementSeance,
    lue: false,
  ),
  NotificationTuteur(
    id: 'n3',
    titre: arabe ? 'الجمعة 20 نوفمبر، 21:00' : 'vendredi 20 novembre, 21:00',
    date: instantCloche.subtract(const Duration(days: 1)),
    type: TypeNotification.changementSeance,
  ),
  NotificationTuteur(
    id: 'n4',
    titre: arabe
        ? 'انتهت حصة الفصل: حضر 1 من 3'
        : 'Séance terminée : 1 présent sur 3',
    date: instantCloche.subtract(const Duration(days: 2)),
  ),
];

/// Les annonces de demonstration.
List<AnnonceCloche> annoncesDemo({bool arabe = false}) => <AnnonceCloche>[
  AnnonceCloche(
    id: 'a1',
    titre: arabe
        ? 'دليل المعلم متاح في التطبيق'
        : "Le guide de l'enseignant est dans l'application",
    texte: arabe
        ? 'فيه كل ما يخص الحصص والمكافأة وقواعد الأكاديمية. https://exemple.org/guide'
        : "Tout sur les séances, la rémunération et les règles de l'académie. https://exemple.org/guide",
    publieeLe: instantCloche.subtract(const Duration(hours: 1)),
    traduite: !arabe,
    titreOriginal: arabe ? null : 'دليل المعلم متاح في التطبيق',
    texteOriginal: arabe ? null : 'فيه كل ما يخص الحصص والمكافأة وقواعد الأكاديمية. https://exemple.org/guide',
    langueOriginale: 'ar',
  ),
  AnnonceCloche(
    id: 'a2',
    titre: arabe ? 'عطلة نهاية السنة' : "Vacances de fin d'année",
    texte: arabe
        ? 'تتوقف الحصص من 24 ديسمبر إلى 2 يناير.'
        : 'Les séances s’arrêtent du 24 décembre au 2 janvier.',
    publieeLe: instantCloche.subtract(const Duration(days: 3)),
    vue: true,
  ),
];

/// Monte la coquille du tuteur sur le vrai routeur, a [taille], et rend le
/// routeur. Le cadre [cadreCapture] entoure toute l'application (captures).
Future<GoRouter> monterCloche(
  WidgetTester tester, {
  required PortNotifications port,
  required SourceAnnoncesCloche source,
  Size taille = const Size(390, 844),
  double densite = 1,
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
  bool horsLigne = false,
  String depart = Routes.tuteurAccueil,
  List<Override> autres = const <Override>[],
}) async {
  tester.view.physicalSize = taille * densite;
  tester.view.devicePixelRatio = densite;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesClasse(),
        portNotificationsProvider.overrideWithValue(port),
        sourceAnnoncesClocheProvider.overrideWithValue(source),
        horlogeNotificationsProvider.overrideWithValue(() => instantCloche),
        // Un navigateur : les liens des annonces deviennent un bouton.
        ouvreurOngletProvider.overrideWithValue((Uri _) => true),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ...autres,
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: theme,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (BuildContext contexte, Widget? app) => MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: app!,
                ),
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await pas(tester);
  routeur.go(depart);
  await pas(tester);
  return routeur;
}

/// Laisse passer les animations sans exiger qu'elles s'arretent.
Future<void> pas(WidgetTester tester, {int fois = 10}) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Touche la cloche de l'en-tete.
Future<void> ouvrirLaCloche(WidgetTester tester) async {
  await tester.tap(find.byType(ClocheCoquille).first);
  await pas(tester);
}
