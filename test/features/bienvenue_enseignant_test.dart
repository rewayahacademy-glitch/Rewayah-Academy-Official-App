import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/bienvenue_page.dart';
import 'package:rewayah_academy/features/disponibilites/grille_semaine.dart';

import '../support/harnais.dart';

/// Une destination-temoin, pour mesurer ou une action mene vraiment.
GoRoute _temoin(String chemin, String texte) => GoRoute(
  path: chemin,
  builder: (BuildContext _, GoRouterState _) =>
      Scaffold(body: Text(texte)),
);

/// Une session d'enseignant resolue, dont seul le statut varie.
SessionState _session(AccountStatus? statut) => SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 'ens-1',
  accountStatus: statut,
  lectureProfil: LectureProfil.presente,
);

/// Monte `ENS-01` sur un telephone, avec trois destinations-temoins.
///
/// **La bienvenue n'est pas une destination** : elle vit hors des trois branches
/// de la coquille de l'enseignant, donc sans barre de navigation. Ses sorties
/// sont sur l'ecran ou elles ne sont nulle part -- c'est ce que le routeur-temoin
/// permet de mesurer.
Future<void> _monter(
  WidgetTester tester, {
  String? prenom = 'Aicha',
  bool enChargement = false,
  bool echecProfil = false,
  AccountStatus? statut = AccountStatus.active,
  bool horsLigne = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final Completer<ProfilEnseignant?> jamais = Completer<ProfilEnseignant?>();

  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.enseignantBienvenue,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.enseignantBienvenue,
          builder: (BuildContext _, GoRouterState _) =>
              const BienvenueEnseignantPage(),
        ),
        _temoin(Routes.enseignantCreneaux, 'creneaux'),
        _temoin(Routes.enseignantJournee, 'journee'),
        _temoin(Routes.attente, 'portail'),
      ],
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_session(statut)),
        ),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        profilEnseignantProvider.overrideWith((_) {
          if (echecProfil) {
            throw StateError('lecture refusee');
          }
          if (enChargement) {
            // Sans delai, le faux resout son futur dans la micro-tache que le
            // premier `pump` vide, et l'etat de chargement n'existe jamais.
            return jamais.future;
          }
          return ProfilEnseignant(prenom: prenom ?? '', identifiant: 'RA-0007');
        }),
      ],
    ),
  );
}

void main() {
  group('ENS-01 : la bienvenue accueille un dossier valide', () {
    testWidgets('elle nomme la personne et dit ou en est son dossier', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.bienvenue.salutation(prenom: 'Aicha')),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.bienvenue.dossierValide), findsOneWidget);
    });

    testWidgets('sans prenom lisible, elle reste une bienvenue', (
      WidgetTester tester,
    ) async {
      // Elle ne fabrique pas un nom, et elle ne devient pas une erreur pour
      // autant : ce qu'elle a a dire ne depend pas du prenom.
      await _monter(tester, prenom: null);
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.bienvenue.salutationSansNom),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.bienvenue.declarer), findsOneWidget);
    });

    testWidgets('les trois pas suivants sont dits, dans l ordre', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pumpAndSettle();

      for (final String pas in <String>[
        t.enseignant.bienvenue.pas1,
        t.enseignant.bienvenue.pas2,
        t.enseignant.bienvenue.pas3,
      ]) {
        expect(find.text(pas), findsOneWidget);
      }
    });
  });

  group('ADR-011 : les deux dispositifs sont dits, en clair', () {
    testWidgets('l enregistrement audio ET la visite de controle', (
      WidgetTester tester,
    ) async {
      // La base ne connait qu'UNE acceptation pour les deux
      // (`recording_and_control_notice`) : les rendre separement opposables
      // demanderait une valeur de `contract_kind` de plus, donc une migration
      // (`CONTRACT_REQUEST_E.md`). Tant que c'est le cas, la seule garantie
      // tenable est que les deux points soient DITS, chacun pour lui-meme.
      await _monter(tester);
      await tester.pumpAndSettle();

      expect(find.text(t.contrat.pointEnregistrement), findsOneWidget);
      expect(find.text(t.contrat.pointControle), findsOneWidget);
    });
  });

  group('ENS-01 : elle conduit a ENS-06, elle ne le refait pas', () {
    testWidgets('aucune grille de semaine n est rendue ici', (
      WidgetTester tester,
    ) async {
      // Deux grilles jumelles finiraient par diverger : la declaration des
      // disponibilites vit dans `ENS-06`, et la bienvenue n'y touche pas.
      await _monter(tester);
      await tester.pumpAndSettle();

      expect(find.byType(GrilleSemaine), findsNothing);
    });

    testWidgets('l action principale mene aux creneaux', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.enseignant.bienvenue.declarer));
      await tester.pumpAndSettle();

      expect(find.text('creneaux'), findsOneWidget);
    });

    testWidgets('une seconde sortie evite le cul-de-sac', (
      WidgetTester tester,
    ) async {
      // La bienvenue n'a aucune barre de navigation : sans cette sortie, un
      // enseignant qui ne veut pas declarer ses heures tout de suite serait
      // coince sur l'ecran.
      await _monter(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.enseignant.bienvenue.versJournee));
      await tester.pumpAndSettle();

      expect(find.text('journee'), findsOneWidget);
    });

    testWidgets('les deux sorties tiennent dans un telephone, sans defiler', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pumpAndSettle();

      for (final String libelle in <String>[
        t.enseignant.bienvenue.declarer,
        t.enseignant.bienvenue.versJournee,
      ]) {
        final Rect zone = tester.getRect(find.text(libelle));
        expect(zone.top, greaterThanOrEqualTo(0));
        expect(zone.bottom, lessThanOrEqualTo(844));
      }
    });
  });

  group('ENS-01 : un dossier qui n est pas valide ne se fait pas feliciter', () {
    for (final AccountStatus? statut in <AccountStatus?>[
      AccountStatus.pendingKyc,
      AccountStatus.disabled,
      null,
    ]) {
      testWidgets(
        '${statut?.valeurSql ?? 'illisible'} renvoie au portail d attente',
        (WidgetTester tester) async {
          // Un statut absent ou illisible n'ouvre pas la bienvenue : on ne
          // laisse jamais passer par defaut ce qu'on n'a pas su lire.
          await _monter(tester, statut: statut);
          await tester.pumpAndSettle();

          expect(
            find.text(t.enseignant.bienvenue.dossierIncomplet),
            findsOneWidget,
          );
          expect(
            find.text(t.enseignant.bienvenue.salutationSansNom),
            findsNothing,
          );
          expect(find.text(t.enseignant.bienvenue.dossierValide), findsNothing);

          await tester.tap(find.text(t.enseignant.bienvenue.versAttente));
          await tester.pumpAndSettle();
          expect(find.text('portail'), findsOneWidget);
        },
      );
    }

    testWidgets('un acces provisoire accueille, comme un compte actif', (
      WidgetTester tester,
    ) async {
      // ADR-014 : acces complet, profil a completer sous trente jours, aucune
      // coupure automatique. Le refuser ici serait fermer une porte que la base
      // laisse ouverte.
      await _monter(tester, statut: AccountStatus.provisionalActive);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.bienvenue.dossierValide), findsOneWidget);
    });
  });

  group('ENS-01 : ses cinq etats', () {
    testWidgets('loading : un squelette, jamais un indicateur nu', (
      WidgetTester tester,
    ) async {
      await _monter(tester, enChargement: true);
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('error : une phrase, « Reessayer », et les sorties intactes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, echecProfil: true);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.bienvenue.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      // L'onboarding ne se bloque pas sur une lecture de prenom en echec.
      expect(find.text(t.enseignant.bienvenue.declarer), findsOneWidget);
    });

    testWidgets('offline : la limite est dite AVANT le geste', (
      WidgetTester tester,
    ) async {
      // Naviguer aboutit toujours ; poser un creneau, non. On le dit avant,
      // plutot que de laisser la grille echouer apres.
      await _monter(tester, horsLigne: true);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.bienvenue.horsLigne), findsOneWidget);
      expect(find.text(t.enseignant.bienvenue.declarer), findsOneWidget);
    });
  });
}
