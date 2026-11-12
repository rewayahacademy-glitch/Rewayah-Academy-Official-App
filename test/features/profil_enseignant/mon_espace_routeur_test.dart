// CRASH-MON-ESPACE (garde-cap, 12/11/2026) : en production (train 5b),
// toucher une ligne de « Mon espace » du Compte de l'enseignant faisait
// planter toute l'application. Les tests du Compte montaient la page SEULE,
// jamais a travers le vrai routeur et la coquille de l'enseignant : c'est le
// trou que ce fichier ferme. Chaque ligne s'ouvre ici depuis `/enseignant/profil`
// sur le routeur de l'application, et doit montrer sa page sans exception.
// Donnees fictives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/port_accord_publication.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/lignes_compte.dart';
import 'package:rewayah_academy/features/compte/securite_page.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/accord_publication_profil.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';
import 'package:rewayah_academy/features/revenus_enseignant/revenus_enseignant_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';
import '../../support/horloge_fictive.dart';

class _Identite implements PortIdentiteTitulaire {
  @override
  Future<IdentiteTitulaire> lire() async => const IdentiteTitulaire(
    prenom: 'Aicha',
    nom: 'Diallo',
    courriel: 'enseignante@test.invalid',
    methodeConnexion: MethodeConnexion.lienCourriel,
    statut: AccountStatus.active,
  );

  @override
  Future<void> modifier({String? prenom, String? nom}) async {}
}

const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 'ens-1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

List<Override> _surcharges() => <Override>[
  sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
  referentielLanguesProvider.overrideWith(
    (Ref _) async => const <LangueCours>[],
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  profilEnseignantProvider.overrideWith(
    (Ref _) async => const ProfilEnseignant(
      prenom: 'Aicha',
      identifiant: 'RA-26-0007',
      pays: 'Guinée',
      langues: <String>[],
      statutCompte: AccountStatus.active,
    ),
  ),
  accordPublicationProvider.overrideWith(
    (Ref _) async =>
        const AccordPublication(versionCourante: 'v1', enCours: false),
  ),
  portIdentiteTitulaireProvider.overrideWithValue(_Identite()),
  monHorlogeDeTest(fuseau: 'Africa/Conakry', decalage: Duration.zero),
];

/// Monte l'application sur son VRAI routeur, a l'adresse du Compte.
Future<GoRouter> _monter(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            routeur.go(Routes.enseignantProfil);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              // Comme `RewayahApp` : le plan du fil d'Ariane au-dessus de
              // toute page. Sans lui, `PageShell` ne demande jamais sa
              // position dans la pile, et le gel ne se voit pas.
              builder: (BuildContext _, Widget? rendu) => ContexteFilAriane(
                plan: planFilPour(_session),
                child: rendu ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

/// Les lignes du Compte, et la page que chacune doit ouvrir.
final List<(String, Key, Finder Function())> _lignes =
    <(String, Key, Finder Function())>[
      (
        'Identite professionnelle',
        ProfilEnseignantPage.identiteKey,
        () => find.text(t.enseignant.profil.pays),
      ),
      (
        'Publication sur le site',
        ProfilEnseignantPage.publicationKey,
        () => find.byType(CarteAccordPublication),
      ),
      (
        'Mes disponibilites',
        ProfilEnseignantPage.disponibilitesKey,
        () => find.byType(CreneauxPage),
      ),
      (
        'Mes revenus',
        ProfilEnseignantPage.revenusKey,
        () => find.byType(RevenusEnseignantPage),
      ),
      (
        'Contrats',
        ProfilEnseignantPage.contratsKey,
        () => find.text(t.enseignant.profil.contratSection),
      ),
      (
        'Informations personnelles',
        cleLigneInformationsCompte,
        () => find.byType(InformationsComptePage),
      ),
      (
        'Methode de connexion',
        cleLigneConnexionCompte,
        () => find.byType(SecuriteComptePage),
      ),
    ];

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final Size taille in <Size>[
    const Size(390, 2400),
    const Size(1440, 1600),
  ]) {
    for (final (String nom, Key cle, Finder Function() cible) in _lignes) {
      testWidgets(
        '${taille.width.toInt()} : « $nom » s ouvre a travers le vrai '
        'routeur, sans planter',
        (WidgetTester tester) async {
          await _monter(tester, taille);
          expect(find.byType(ProfilEnseignantPage), findsOneWidget);
          final Finder ligne = find.byKey(cle);
          await tester.ensureVisible(ligne);
          await tester.pumpAndSettle();
          await tester.tap(ligne);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(cible(), findsWidgets);
        },
      );
    }
  }
}
