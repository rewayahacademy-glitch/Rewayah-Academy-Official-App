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

import '../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';

/// Une destination-temoin, pour mesurer ou une action mene vraiment.
GoRoute _temoin(String chemin, String texte) => GoRoute(
  path: chemin,
  builder: (BuildContext _, GoRouterState _) => Scaffold(body: Text(texte)),
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
  PrerequisEnseignant? prerequis,
  ThemeMode themeMode = ThemeMode.light,
  InterfaceMode interface = InterfaceMode.standard,
  TextDirection? direction,
  double echelle = 1,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final Completer<ProfilEnseignant?> jamais = Completer<ProfilEnseignant?>();

  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.enseignantBienvenue,
      mode: interface,
      themeMode: themeMode,
      direction: direction,
      echelle: echelle,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.enseignantBienvenue,
          builder: (BuildContext _, GoRouterState _) =>
              const BienvenueEnseignantPage(),
        ),
        _temoin(Routes.enseignantCreneaux, 'creneaux'),
        _temoin(Routes.enseignantJournee, 'journee'),
        _temoin(Routes.attente, 'portail'),
        _temoin(Routes.enseignantProfil, 'profil'),
      ],
      surcharges: <Override>[
        prerequisEnseignantProvider.overrideWithValue(prerequis),
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

    // EN-6 : la prose « cinq enfants ou six adultes » est retiree (E6,
    // 00_MAQUETTES planche 1 R2) ; ce test remplace « les trois pas ».
    testWidgets('la prose des groupes de cinq ou six n existe plus', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('cinq enfants'), findsNothing);
      expect(find.textContaining('six adultes'), findsNothing);
    });
  });

  group('ENS-01 : « A completer » et le premier manque (EN-6)', () {
    testWidgets('sans prerequis rendus, aucune carte n est inventee', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.bienvenue.aCompleter), findsNothing);
      expect(find.text(t.enseignant.bienvenue.declarer), findsOneWidget);
    });

    testWidgets('photo manquante : compteur en texte, lignes faites absentes', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        prerequis: const PrerequisEnseignant(
          photo: false,
          langues: true,
          fuseau: true,
          disponibilites: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.bienvenue.aCompleter), findsOneWidget);
      expect(
        find.text(t.enseignant.bienvenue.compteur(fait: 3, total: 4)),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.bienvenue.prerequisLangues), findsNothing);
      expect(find.text(t.enseignant.bienvenue.prerequisFuseau), findsNothing);
      expect(find.text(t.enseignant.bienvenue.prerequisPhoto), findsOneWidget);
      expect(find.text(t.enseignant.bienvenue.ctaPhoto), findsOneWidget);
    });

    testWidgets('informations a verifier : le bouton mene au profil', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        prerequis: const PrerequisEnseignant(
          photo: true,
          langues: true,
          fuseau: false,
          disponibilites: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.enseignant.bienvenue.ctaInformations));
      await tester.pumpAndSettle();
      expect(find.text('profil'), findsOneWidget);
    });

    testWidgets('tout est complet : « Voir ma journee », une seule sortie', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        prerequis: const PrerequisEnseignant(
          photo: true,
          langues: true,
          fuseau: true,
          disponibilites: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.bienvenue.aCompleter), findsNothing);
      expect(find.text(t.enseignant.bienvenue.prerequisPhoto), findsNothing);
      expect(find.text(t.enseignant.bienvenue.versJournee), findsNothing);
      await tester.tap(find.text(t.enseignant.bienvenue.ctaJournee));
      await tester.pumpAndSettle();
      expect(find.text('journee'), findsOneWidget);
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

      // Texte E1 valide le 02/10/2026 : l'enregistrement et la visite de
      // controle sont dits dans le meme paragraphe, puis qui peut ecouter.
      expect(find.text(t.contrat.e1.quoi), findsOneWidget);
      expect(find.text(t.contrat.a3.qui), findsOneWidget);
      expect(find.text(t.contrat.pointEnregistrement), findsNothing);
    });
  });

  group('ENS-01 : elle conduit a ENS-06, elle ne le refait pas', () {
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
      // EA-HL-DOUBLE-1 (reprise) : la note dit ce qui ne peut pas se faire ;
      // le bandeau seul dit « hors ligne ».
      expectHorsLigneUneFois();
      expect(find.text(t.enseignant.bienvenue.declarer), findsOneWidget);
    });
  });

  // EA-HL-DOUBLE-1 (reprise) : captures de preuve, hors ligne, la note dit
  // ce qui ne peut pas se faire, le bandeau seul dit le reseau. Sautees sans
  // CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, Size) cas in <(String, Size)>[
      ('390_clair', const Size(390, 844)),
      ('320_clair', const Size(320, 900)),
      ('1440_clair', const Size(1440, 900)),
    ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _monter(tester, horsLigne: true);
        tester.view.physicalSize = cas.$2;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(t.enseignant.bienvenue.horsLigne), findsOneWidget);
        expectHorsLigneUneFois();
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_bienvenue_${cas.$1}')}',
        );
      });
    }
  });
  // EA-HL-DOUBLE-1d (vu sur la capture) : a 320 texte x2, « Bienvenue, »
  // ne tenait pas en titre et se coupait. Le titre borne son echelle.
  // JONCTION-LIGNES-1 : mesure avec les polices du depot. La police de test
  // donne a chaque glyphe une largeur d'1 em : le texte A3 valide mot pour
  // mot (JUR-APP-1, « l'enregistrement. ») n'y tient a aucune echelle.
  group('320 texte x2, polices du depot', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 texte x2 ${sens.name} : aucun mot coupe', (
        WidgetTester tester,
      ) async {
        await _monter(tester, direction: sens, echelle: 2);
        tester.view.physicalSize = const Size(320, 1800);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
      });
    }
  });

  // EA-HL-DOUBLE-1d : sombre, Interface guidee et 320 texte x2 en LTR et
  // RTL de la bienvenue hors ligne (revue EA-HL-DOUBLE-1c-R, mineur 2).
  // Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1d', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, Size, ThemeMode, InterfaceMode, TextDirection, double)
        cas
        in <(String, Size, ThemeMode, InterfaceMode, TextDirection, double)>[
          (
            '390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            TextDirection.ltr,
            1,
          ),
          (
            '390_guidee',
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            TextDirection.ltr,
            1,
          ),
          (
            '320x2_clair',
            const Size(320, 1800),
            ThemeMode.light,
            InterfaceMode.standard,
            TextDirection.ltr,
            2,
          ),
          (
            '320x2_rtl_clair',
            const Size(320, 1800),
            ThemeMode.light,
            InterfaceMode.standard,
            TextDirection.rtl,
            2,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _monter(
          tester,
          horsLigne: true,
          themeMode: cas.$3,
          interface: cas.$4,
          direction: cas.$5,
          echelle: cas.$6,
        );
        tester.view.physicalSize = cas.$2;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(t.enseignant.bienvenue.horsLigne), findsOneWidget);
        expectHorsLigneUneFois();
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1d_bienvenue_${cas.$1}')}',
        );
      });
    }
  });
}
