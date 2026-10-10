// Le banc des tests de la Communaute enseignants (COM-COMU-1) : la VRAIE
// coquille de l'enseignant (`NavShell`, destinations de
// `destinationsPour(AppRole.teacher)`) et la VRAIE page, sous un routeur
// minimal, avec des doubles en memoire (aucun port reseau).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/communications/port_pieces_jointes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_communaute/communaute_page.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import '../../support/harnais.dart';

/// Le texte de la page d'Aujourd'hui du banc.
const String texteJourneeBanc = 'Aujourd hui du banc';

/// Ce que le banc a monte, pour les verifications.
class BancCommunaute {
  /// Cree le banc.
  BancCommunaute({
    required this.port,
    required this.moderation,
    required this.enregistres,
    required this.routeur,
  });

  /// La Communaute en memoire.
  final PortCommunaute port;

  /// La moderation.
  final PortModeration moderation;

  /// Les elements enregistres.
  final PortElementsEnregistres enregistres;

  /// Le routeur.
  final GoRouter routeur;

  /// La memoire, quand le port en est une.
  CommunauteMemoire get memoire => port as CommunauteMemoire;
}

/// Une Communaute en memoire sur les donnees de la demonstration.
CommunauteMemoire memoireDemo({
  bool vide = false,
  bool echecLecture = false,
  bool echecEnvoi = false,
  CapacitesCommunaute capacites = const CapacitesCommunaute(
    peutPublier: true,
    peutRepondre: true,
  ),
}) => CommunauteMemoire(
  categories: DonneesCommunauteDemo.categories,
  publications: vide
      ? const <PublicationCommunaute>[]
      : DonneesCommunauteDemo.publications(),
  reponses: vide
      ? const <String, List<ReponseCommunaute>>{}
      : DonneesCommunauteDemo.reponses(),
  soi: DonneesCommunauteDemo.soi,
  capacitesRendues: capacites,
  echecLecture: echecLecture,
  echecEnvoi: echecEnvoi,
  maintenant: () => DonneesCommunauteDemo.maintenant,
);

/// Fixe la vue logique, a densite 1.
void fixerTaille(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Monte la Communaute dans la coquille enseignant.
Future<BancCommunaute> monterCommunaute(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  PortCommunaute? port,
  PortModeration? moderation,
  PortElementsEnregistres? enregistres,
  ChoixPieceCommunaute? choix,
  String? publicationId,
  bool horsLigne = false,
  Brightness luminosite = Brightness.light,
  double echelleTexte = 1,
  bool arabe = false,
  List<Override> autres = const <Override>[],
}) async {
  fixerTaille(tester, taille);
  final PortCommunaute p = port ?? memoireDemo();
  final PortModeration m = moderation ?? ModerationDemo();
  final PortElementsEnregistres e =
      enregistres ??
      ElementsEnregistresMemoire(
        maintenant: () => DonneesCommunauteDemo.maintenant,
      );
  if (arabe) {
    // La traduction arabe est chargee a la demande : hors de l'horloge
    // simulee du test.
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  }
  final List<Destination> destinations = destinationsPour(
    role: AppRole.teacher,
    mode: InterfaceMode.standard,
  );
  Widget coquille(Widget page) => NavShell(
    destinations: destinations,
    indexActif: 0,
    libellesDansLeRail: true,
    onAller: (String _) {},
    child: page,
  );
  final String depart = publicationId == null
      ? Routes.enseignantCommunaute
      : Routes.enseignantPublicationPour(publicationId);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.enseignantJournee,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text(texteJourneeBanc)),
      ),
      GoRoute(
        path: Routes.enseignantCommunaute,
        builder: (BuildContext _, GoRouterState _) =>
            coquille(const CommunautePage()),
        routes: <RouteBase>[
          GoRoute(
            path: ':publicationId',
            builder: (BuildContext _, GoRouterState etat) => coquille(
              CommunautePage(
                publicationId: etat.pathParameters['publicationId'],
              ),
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
        // Une session d'enseignant resolue : les brouillons de session y
        // sont attaches (`portBrouillonsProvider`).
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(
            const SessionState(
              resolue: true,
              role: AppRole.teacher,
              profileId: 'enseignant-banc',
              accountStatus: AccountStatus.active,
              lectureProfil: LectureProfil.presente,
            ),
          ),
        ),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        portCommunauteProvider.overrideWithValue(p),
        portModerationProvider.overrideWithValue(m),
        portElementsEnregistresProvider.overrideWithValue(e),
        portPolitiquePiecesJointesProvider.overrideWithValue(
          const PolitiquePiecesJointesDemo(),
        ),
        choixPieceCommunauteProvider.overrideWithValue(
          choix ?? const ChoixPieceDemo(),
        ),
        horlogeCommunauteProvider.overrideWithValue(
          () => DonneesCommunauteDemo.maintenant,
        ),
        ...autres,
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: luminosite == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: (arabe ? AppLocale.ar : AppLocale.fr).flutterLocale,
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
  await tester.pumpAndSettle();
  return BancCommunaute(
    port: p,
    moderation: m,
    enregistres: e,
    routeur: routeur,
  );
}

/// Touche [cible] apres l'avoir rendue visible, et laisse tout se poser.
Future<void> taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Choisit une categorie : segment visible, ou menu deroulant quand les
/// sections ne tiennent pas (`SelecteurSection`, ONGLETS-1).
Future<void> choisirCategorie(WidgetTester tester, String libelle) async {
  final Finder dans = find.descendant(
    of: find.byKey(SelecteurCategories.cle),
    matching: find.text(libelle),
  );
  if (dans.evaluate().isNotEmpty) {
    await taper(tester, dans.first);
    return;
  }
  await taper(tester, find.byKey(SelecteurCategories.cle));
  await taper(tester, find.text(libelle).last);
}

/// Demonte l'arbre : les minuteries des blocs asynchrones s'arretent.
Future<void> demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
