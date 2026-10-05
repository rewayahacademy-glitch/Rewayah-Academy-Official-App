import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/profil/service_declaration.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../support/harnais.dart';

/// La declaration du profil, en memoire.
///
/// **Le seul faux ecrit hors du harnais de ce lot**, parce qu'il n'y en avait
/// aucun : `ServiceDeclarationEnseignant` nait avec `ENS-05`. Sa promotion dans
/// `test/support/harnais.dart` est demandee dans `CONTRACT_REQUEST_E.md` --
/// le harnais appartient a l'Agent Z, et un agent metier ne l'ouvre pas.
class _FauxDeclaration implements ServiceDeclarationEnseignant {
  /// Les ecritures demandees, dans l'ordre. C'est par elles qu'un test verifie
  /// **quels champs** partent, et surtout lesquels ne partent pas.
  final List<({String? pays, List<String>? langues})> ecritures =
      <({String? pays, List<String>? langues})>[];

  /// Ce que la prochaine ecriture doit jeter.
  Object? erreurAJeter;

  @override
  Future<void> declarer({String? pays, List<String>? langues}) async {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    ecritures.add((pays: pays, langues: langues));
  }
}

/// Un profil enseignant complet, pret a l'emploi.
ProfilEnseignant _profilDeTest({
  String prenom = 'Aicha',
  String identifiant = 'RA-ENS-0007',
  String? pays = 'GN',
  List<String> langues = const <String>['Français', 'Arabe'],
  int? plafondHeures = 20,
  AccountStatus? statutCompte = AccountStatus.active,
  VerificationEnseignant? verification = VerificationEnseignant.validee,
}) => ProfilEnseignant(
  prenom: prenom,
  identifiant: identifiant,
  pays: pays,
  langues: langues,
  plafondHeures: plafondHeures,
  statutCompte: statutCompte,
  verification: verification,
);

/// Une session d'enseignant resolue, dont seul le statut varie.
SessionState _session(AccountStatus? statut) => SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 'ens-1',
  accountStatus: statut,
  lectureProfil: LectureProfil.presente,
);

/// Ce que le montage rend a un cas de test.
typedef _Monte = ({FauxServiceAuth auth, _FauxDeclaration declaration});

/// Ce que chaque cas de test partage : un telephone, et rien de reel derriere.
///
/// **390 x 844 toujours, et jamais la surface de `flutter_test`.** C'est la que
/// l'enseignant travaille, et c'est la seule taille ou l'invariant de cet ecran
/// -- la deconnexion atteignable -- veut dire quelque chose : le pied de
/// coquille qui portait « Compte » n'est rendu qu'a partir de 600.
Future<_Monte> _monter(
  WidgetTester tester, {
  ProfilEnseignant? profil,
  bool profilAbsent = false,
  bool echecProfil = false,
  AccountStatus? statutSession = AccountStatus.active,
  List<Acceptation> acceptations = const <Acceptation>[],
  bool echecAcceptations = false,
  bool horsLigne = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final FauxServiceAuth auth = FauxServiceAuth();
  final _FauxDeclaration declaration = _FauxDeclaration();
  // Une future qui ne se resout jamais : c'est le seul moyen de regarder l'ecran
  // PENDANT son chargement. Un faux qui repond tout de suite resout son futur
  // dans la micro-tache que le premier `pump` vide, et l'etat de chargement
  // n'existe alors jamais.
  final Completer<ProfilEnseignant?> jamais = Completer<ProfilEnseignant?>();

  await tester.pumpWidget(
    hote(
      const ProfilEnseignantPage(),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_session(statutSession)),
        ),
        serviceAuthProvider.overrideWithValue(auth),
        serviceDeclarationProvider.overrideWithValue(declaration),
        servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        profilEnseignantProvider.overrideWith((_) {
          if (echecProfil) {
            throw StateError('lecture refusee');
          }
          if (profilAbsent) {
            return null;
          }
          return profil ?? jamais.future;
        }),
        acceptationsProvider.overrideWith((_) {
          if (echecAcceptations) {
            throw StateError('lecture refusee');
          }
          return acceptations;
        }),
      ],
    ),
  );
  return (auth: auth, declaration: declaration);
}

/// Tape une ligne de reglage, apres l'avoir amenee dans le cadre.
///
/// Les lignes vivent dans le corps defilant, et a 390 x 844 le profil complet
/// depasse la hauteur d'un telephone : c'est normal pour une page de reglages,
/// et c'est justement pourquoi la **deconnexion** n'y est pas -- elle est dans la
/// zone collee, et se tape donc sans ce detour.
Future<void> _taperLigne(WidgetTester tester, String titre) async {
  final Finder cible = find.text(titre);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  group('ENS-05 : les six lectures du statut de compte', () {
    // Chaque valeur d'`AccountStatus`, plus le cas illisible. Le tableau est la
    // mesure : une valeur ajoutee a l'enumere sans phrase a l'ecran fait
    // echouer le cas qui lui correspond, et non une relecture.
    final List<({AccountStatus? statut, String attendu})> cas =
        <({AccountStatus? statut, String attendu})>[
          (
            statut: AccountStatus.active,
            attendu: t.enseignant.profil.compteValide,
          ),
          (
            statut: AccountStatus.provisionalActive,
            attendu: t.enseignant.profil.statutProvisoire,
          ),
          (
            statut: AccountStatus.pendingKyc,
            attendu: t.enseignant.profil.statutEnAttente,
          ),
          (
            statut: AccountStatus.disabled,
            attendu: t.enseignant.profil.statutSuspendu,
          ),
          (statut: null, attendu: t.enseignant.profil.statutInconnu),
        ];

    for (final ({AccountStatus? statut, String attendu}) c in cas) {
      testWidgets(
        '${c.statut?.valeurSql ?? 'illisible'} se dit en une phrase',
        (WidgetTester tester) async {
          await _monter(
            tester,
            profil: _profilDeTest(statutCompte: c.statut),
            statutSession: c.statut,
          );
          await tester.pumpAndSettle();

          expect(find.text(c.attendu), findsOneWidget);
        },
      );
    }

    testWidgets('un statut illisible ne se replie JAMAIS sur « verifie »', (
      WidgetTester tester,
    ) async {
      // C'est le mensonge d'interface que ce talon portait : il affirmait
      // « Compte enseignant verifie » en vert sans avoir rien lu.
      await _monter(
        tester,
        profil: _profilDeTest(statutCompte: null),
        statutSession: null,
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.compteValide), findsNothing);
      expect(find.text(t.enseignant.profil.statutInconnu), findsOneWidget);
    });

    testWidgets(
      'une divergence entre le statut affiche et celui du routeur se dit',
      (WidgetTester tester) async {
        // `account_status` est lu par deux chemins : la session gouverne la porte
        // du routeur, le profil alimente l'ecran. Rien ne garantit qu'ils soient
        // du meme instant, et l'enseignant ne doit pas decouvrir l'ecart en
        // butant sur un acces.
        await _monter(
          tester,
          profil: _profilDeTest(statutCompte: AccountStatus.active),
          statutSession: AccountStatus.pendingKyc,
        );
        await tester.pumpAndSettle();

        expect(find.text(t.enseignant.profil.statutDivergent), findsOneWidget);
      },
    );

    testWidgets('sans divergence, rien n est annonce', (
      WidgetTester tester,
    ) async {
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.statutDivergent), findsNothing);
    });
  });

  group('ENS-05 : la deconnexion, la seule chose qui doit toujours marcher', () {
    testWidgets('elle tient dans un telephone de 390 x 844, sans defiler', (
      WidgetTester tester,
    ) async {
      // L'invariant qui justifie cet ecran : « Compte » a quitte la barre, le
      // pied de coquille n'est rendu qu'a partir de 600, et une barre basse
      // Material 3 n'accepte aucune entree hors destination. Si ce rectangle
      // sort du cadre, un enseignant sur telephone n'a plus aucun chemin vers
      // la deconnexion.
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      final Rect zone = tester.getRect(find.text(t.compte.deconnexion));
      expect(zone.top, greaterThanOrEqualTo(0));
      expect(zone.bottom, lessThanOrEqualTo(844));
    });

    testWidgets('elle se confirme avant de partir', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();

      // La feuille est ouverte, et rien n'est encore parti.
      expect(
        find.text(t.enseignant.profil.deconnexionConsequence),
        findsOneWidget,
      );
      expect(monte.auth.deconnexions, 0);

      await tester.tap(find.text(t.enseignant.profil.deconnexionConfirmer));
      await tester.pumpAndSettle();

      expect(monte.auth.deconnexions, 1);
    });

    testWidgets('un renoncement ne deconnecte pas', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.annuler));
      await tester.pumpAndSettle();

      expect(monte.auth.deconnexions, 0);
    });

    testWidgets('elle survit a l echec de la lecture du profil', (
      WidgetTester tester,
    ) async {
      // La fiche l'exige mot pour mot : la deconnexion reste accessible meme si
      // tout le reste echoue. C'est pour cela qu'elle vit dans la zone d'action
      // collee et non dans le corps, qui est remplace par l'etat d'erreur.
      final _Monte monte = await _monter(tester, echecProfil: true);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.erreur), findsOneWidget);

      final Rect zone = tester.getRect(find.text(t.compte.deconnexion));
      expect(zone.bottom, lessThanOrEqualTo(844));

      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.enseignant.profil.deconnexionConfirmer));
      await tester.pumpAndSettle();

      expect(monte.auth.deconnexions, 1);
    });
  });

  group('ENS-05 : cinq etats d ecran', () {
    testWidgets('loading : un squelette, jamais un indicateur nu', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('content : les valeurs viennent du contrat, pas d un calcul', (
      WidgetTester tester,
    ) async {
      // Le talon d'avant ce lot refabriquait deux compteurs depuis
      // `seancesProvider` et `elevesEnAttenteProvider`, dont l'un dedupliquait
      // `seances.map(eleveId).toSet()` -- fragile depuis le pivot groupes, ou
      // `mes_seances_v` rend une ligne par eleve. Ces deux lectures ont disparu,
      // et leurs libelles avec elles.
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      expect(find.text('Aicha'), findsOneWidget);
      expect(find.text('RA-ENS-0007'), findsOneWidget);
      expect(find.text('GN'), findsOneWidget);
      expect(find.text('Français, Arabe'), findsOneWidget);
      expect(
        find.text(t.enseignant.profil.plafondValeur(nombre: 20)),
        findsOneWidget,
      );

      // Mesure sur le WIDGET et non sur une chaine : les quatre cles i18n de la
      // charge pedagogique n'ont plus d'appelant et peuvent disparaitre de
      // `fr.i18n.json` sans casser ce test.
      expect(
        find.byType(StatTile),
        findsNothing,
        reason:
            'Les deux compteurs fabriques du talon passaient par StatTile. La '
            'charge pedagogique est une donnee operationnelle : elle vit dans '
            'ENS-02 et ENS-06, que le protocole exclut du Profil.',
      );
    });

    testWidgets('empty : aucun profil enseignant, dit sans bouton trompeur', (
      WidgetTester tester,
    ) async {
      // Une lecture qui aboutit sans rien trouver n'est pas un echec : seule
      // l'academie peut creer une ligne `teacher_profiles`, donc aucune action
      // n'est proposee.
      await _monter(tester, profilAbsent: true);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.vide), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('error : une phrase et « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, echecProfil: true);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('offline : plus rien ne s edite, et on le dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, profil: _profilDeTest(), horsLigne: true);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.horsLigne), findsOneWidget);

      // Un bouton qui ne peut pas aboutir n'est pas rendu : la ligne redevient
      // une lecture. On le mesure par le geste, pas par l'apparence.
      await _taperLigne(tester, t.enseignant.profil.pays);
      expect(find.text(t.enseignant.profil.enregistrer), findsNothing);
    });
  });

  group('ENS-05 : le contrat, lisible pour toujours', () {
    testWidgets('les trois pieces signees se relisent apres validation', (
      WidgetTester tester,
    ) async {
      // Sans cette section, un enseignant valide ne peut plus les relire du
      // tout : `deciderRedirection` ferme `/attente/*` des que le compte
      // devient actif.
      await _monter(
        tester,
        profil: _profilDeTest(),
        acceptations: <Acceptation>[
          Acceptation(
            sorte: SorteContrat.contratEnseignant,
            version: '2026-09',
            accepteeLe: DateTime(2026, 9, 14),
          ),
          Acceptation(
            sorte: SorteContrat.accuseEnregistrementControle,
            version: '2026-09',
            accepteeLe: DateTime(2026, 9, 14),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.contratEnseignant), findsOneWidget);
      expect(find.text(t.enseignant.profil.contratAccuse), findsOneWidget);
      expect(
        find.text(
          t.enseignant.profil.contratDetail(
            version: '2026-09',
            date: '14/09/2026',
          ),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('aucune signature en base se dit, sans inventer un contrat', (
      WidgetTester tester,
    ) async {
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.contratAucun), findsOneWidget);
    });

    testWidgets('une section en echec laisse les autres lisibles', (
      WidgetTester tester,
    ) async {
      // La fiche l'ecrit ainsi : « phrase + Reessayer sur la section qui a
      // echoue, les autres restent lisibles ».
      final _Monte monte = await _monter(
        tester,
        profil: _profilDeTest(),
        echecAcceptations: true,
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.contratErreur), findsOneWidget);
      expect(find.text('RA-ENS-0007'), findsOneWidget);
      expect(find.text(t.enseignant.profil.compteValide), findsOneWidget);

      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.enseignant.profil.deconnexionConfirmer));
      await tester.pumpAndSettle();
      expect(monte.auth.deconnexions, 1);
    });
  });

  group('ENS-05 : ce que l enseignant declare, et ce qu il ne touche pas', () {
    testWidgets('modifier les langues n envoie QUE les langues', (
      WidgetTester tester,
    ) async {
      // La borne est en base -- `maj_profil_enseignant` ne nomme que trois
      // colonnes -- mais l'ecran ne doit pas non plus envoyer ce qu'il n'a pas
      // demande : un champ absent vaut « ne touche pas », jamais « efface ».
      final _Monte monte = await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      await _taperLigne(tester, t.enseignant.profil.langues);
      await tester.enterText(find.byType(TextField), 'Peul , Arabe,');
      await tester.tap(find.text(t.enseignant.profil.enregistrer));
      await tester.pumpAndSettle();

      expect(monte.declaration.ecritures, hasLength(1));
      expect(monte.declaration.ecritures.single.pays, isNull);
      expect(monte.declaration.ecritures.single.langues, <String>[
        'Peul',
        'Arabe',
      ]);
      expect(find.text(t.enseignant.profil.enregistre), findsOneWidget);
    });

    testWidgets('un echec d ecriture se dit, et ne ment pas sur la valeur', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();
      monte.declaration.erreurAJeter = StateError('refus du serveur');

      await _taperLigne(tester, t.enseignant.profil.pays);
      await tester.enterText(find.byType(TextField), 'SN');
      await tester.tap(find.text(t.enseignant.profil.enregistrer));
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.editionErreur), findsOneWidget);
      // L'ecran n'a aucun etat local de profil : il reaffiche ce que la lecture
      // rend, donc l'ancienne valeur.
      expect(find.text('GN'), findsOneWidget);
      expect(find.text('SN'), findsNothing);
    });

    testWidgets('le plafond hebdomadaire ne s edite pas', (
      WidgetTester tester,
    ) async {
      // Il est contractuel : la seule policy du titulaire sur
      // `teacher_profiles` est en SELECT, et `maj_profil_enseignant` ne le
      // nomme pas. Un champ grise qui refuserait en silence serait pire qu'une
      // lecture assumee.
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      await _taperLigne(tester, t.enseignant.profil.plafond);

      expect(find.text(t.enseignant.profil.enregistrer), findsNothing);
    });
  });

  group('ASSETS-DIR-1 : la politique de controle, rangee dans l espace '
      'enseignant', () {
    for (final bool echec in <bool>[false, true]) {
      testWidgets('le lien ouvre la politique (lecture des acceptations '
          '${echec ? 'en echec' : 'vide'})', (WidgetTester tester) async {
        await _monter(
          tester,
          profil: _profilDeTest(),
          echecAcceptations: echec,
        );
        await tester.pumpAndSettle();

        // Un texte fixe : lisible quel que soit l'etat des acceptations.
        await _taperLigne(tester, t.contrat.politique.lien);
        expect(find.text(t.contrat.politique.titre), findsOneWidget);
        expect(find.text(t.contrat.politique.s10.titre), findsOneWidget);
      });
    }
  });
}
