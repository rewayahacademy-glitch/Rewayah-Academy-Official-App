// Le banc des tests de l'Administration des communications (COM-ANN-2) : la
// VRAIE coquille Admin (`AdminShell`, domaine Operations) et la VRAIE page,
// sous un routeur minimal aux adresses reelles des trois onglets, avec des
// doubles en memoire (aucun port reseau). Le publieur de l'enseignant se
// monte seul, sur son adresse reelle.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/file_moderation.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/com_annonces/port_regles_audience.dart';
import 'package:rewayah_academy/features/com_annonces/publier_annonce_classe_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';

import '../../support/harnais.dart';

/// L'instant de reference des tests : samedi 4 octobre 2026, 9 h (local).
final DateTime maintenantBanc = DateTime(2026, 10, 4, 9);

/// Le texte de l'Espace Classe du banc (retour du publieur enseignant).
const String texteEspaceClasse = 'Espace Classe du banc';

/// Le texte d'une destination ouverte depuis la moderation.
const String texteContexte = 'Contexte du banc';

/// Les annonces de demonstration de l'Administration, sur l'instant du banc.
AnnoncesDemonstration annoncesBanc({
  List<CibleAnnonce>? cibles,
  bool echecPublication = false,
}) {
  final administration = annoncesAdministrationDemo(maintenantBanc);
  return AnnoncesDemonstration(
    const {},
    cibles: cibles ?? ciblesDemo(),
    publiees: administration.publiees,
    planifiees: administration.planifiees,
    maintenant: () => maintenantBanc,
    echecPublication: echecPublication,
  );
}

/// Les doubles de demonstration sauf les annonces, que le test pose
/// lui-meme (`portAnnoncesProvider`) : a la racine, les lectures derivees
/// suivent les ports.
List<Override> surchargesDemoSansAnnonces({
  PortModeration? moderation,
  Set<CapaciteCommunication> capacites = capacitesDemoAdministration,
}) => <Override>[
  portReglesAudienceProvider.overrideWithValue(const ReglesAudienceDemo()),
  portModerationProvider.overrideWithValue(
    moderation ?? ModerationAdministrationDemo(maintenant: maintenantBanc),
  ),
  moderationDemonstrationProvider.overrideWithValue(true),
  portCapacitesCommunicationsProvider.overrideWithValue(
    CapacitesCommunicationsFixes(capacites),
  ),
];

/// Fixe la vue logique, a densite 1.
void fixerTaille(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Monte l'application de test sur [depart], avec [surcharges].
Future<GoRouter> _monter(
  WidgetTester tester, {
  required String depart,
  required List<Override> surcharges,
  required Size taille,
  required bool horsLigne,
  required bool arabe,
  required Brightness luminosite,
  required double echelleTexte,
}) async {
  fixerTaille(tester, taille);
  if (arabe) {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  }
  Widget coquille(OngletCommunications onglet) => AdminShell(
    domaines: domainesAdmin(voitDirection: false),
    domaineActif: AdminDomaine.operations,
    onAller: (String _) {},
    onCompte: () {},
    child: AdministrationCommunicationsPage(
      onglet: onglet,
      horloge: () => maintenantBanc,
    ),
  );
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.adminCommunicationsAnnonces,
        builder: (BuildContext _, GoRouterState _) =>
            coquille(OngletCommunications.annonces),
      ),
      GoRoute(
        path: Routes.adminCommunicationsModeration,
        builder: (BuildContext _, GoRouterState _) =>
            coquille(OngletCommunications.moderation),
      ),
      GoRoute(
        path: Routes.adminCommunicationsMessages,
        builder: (BuildContext _, GoRouterState _) =>
            coquille(OngletCommunications.messages),
      ),
      GoRoute(
        path: Routes.publierAnnoncePour(':groupeId'),
        builder: (BuildContext _, GoRouterState etat) =>
            PublierAnnonceClassePage(
              groupeId: etat.pathParameters['groupeId'] ?? '',
              horloge: () => maintenantBanc,
            ),
      ),
      GoRoute(
        path: Routes.groupePour(':groupeId'),
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text(texteEspaceClasse)),
      ),
      GoRoute(
        path: Routes.demoCommunications,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text(texteContexte)),
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
        ...surcharges,
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
  return routeur;
}

/// Monte l'Administration des communications sur [onglet]. Sans
/// [surcharges], les doubles de demonstration ([surchargesAdministrationDemo])
/// ; avec `neutre: true`, aucun double : les ports de production.
Future<GoRouter> monterAdministration(
  WidgetTester tester, {
  OngletCommunications onglet = OngletCommunications.annonces,
  Size taille = const Size(1440, 900),
  List<Override>? surcharges,
  AnnoncesDemonstration? annonces,
  PortModeration? moderation,
  PortReglesAudience? regles,
  Set<CapaciteCommunication> capacites = capacitesDemoAdministration,
  bool neutre = false,
  bool horsLigne = false,
  bool arabe = false,
  Brightness luminosite = Brightness.light,
  double echelleTexte = 1,
}) => _monter(
  tester,
  depart: switch (onglet) {
    OngletCommunications.annonces => Routes.adminCommunicationsAnnonces,
    OngletCommunications.moderation => Routes.adminCommunicationsModeration,
    OngletCommunications.messages => Routes.adminCommunicationsMessages,
  },
  surcharges:
      surcharges ??
      (neutre
          ? const <Override>[]
          : surchargesAdministrationDemo(
              annonces: annonces ?? annoncesBanc(),
              moderation:
                  moderation ??
                  ModerationAdministrationDemo(maintenant: maintenantBanc),
              regles: regles ?? const ReglesAudienceDemo(),
              capacites: capacites,
            )),
  taille: taille,
  horsLigne: horsLigne,
  arabe: arabe,
  luminosite: luminosite,
  echelleTexte: echelleTexte,
);

/// Monte le publieur de l'enseignant pour la Classe [classeId].
Future<GoRouter> monterPublierClasse(
  WidgetTester tester, {
  String classeId = ClassesDemoAnnonces.nour,
  Size taille = const Size(390, 844),
  List<Override>? surcharges,
  AnnoncesDemonstration? annonces,
  Set<CapaciteCommunication> capacites = const <CapaciteCommunication>{
    CapaciteCommunication.publierAnnonce,
  },
  bool neutre = false,
  bool horsLigne = false,
  bool arabe = false,
  double echelleTexte = 1,
}) => _monter(
  tester,
  depart: Routes.publierAnnoncePour(classeId),
  surcharges:
      surcharges ??
      (neutre
          ? const <Override>[]
          : surchargesAdministrationDemo(
              annonces:
                  annonces ??
                  annoncesBanc(
                    cibles: <CibleAnnonce>[
                      for (final CibleAnnonce c in ciblesDemo())
                        if (c.classeId == ClassesDemoAnnonces.nour) c,
                    ],
                  ),
              moderation: ModerationAdministrationDemo(
                maintenant: maintenantBanc,
              ),
              capacites: capacites,
            )),
  taille: taille,
  horsLigne: horsLigne,
  arabe: arabe,
  luminosite: Brightness.light,
  echelleTexte: echelleTexte,
);

/// Touche [cible] apres l'avoir rendue visible, et laisse tout se poser.
Future<void> taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Demonte l'arbre : les minuteries des blocs asynchrones s'arretent.
Future<void> demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
