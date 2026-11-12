import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/port_support.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/i18n/villes_fuseau.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/profil/service_declaration.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/deconnexion.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/page_compte.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/features/compte/lignes_compte.dart';
import 'package:rewayah_academy/features/compte/mes_donnees_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/declaration_choix.dart';
import 'package:rewayah_academy/features/profil_enseignant/feuille_fuseau.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../support/harnais.dart';
import '../support/horloge_fictive.dart';

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

  /// Les fuseaux demandes (FUSEAU-IDENTITE-PRO), dans l'ordre.
  final List<String> fuseaux = <String>[];

  /// Ce que la prochaine ecriture doit jeter.
  Object? erreurAJeter;

  @override
  Future<void> declarer({
    String? pays,
    List<String>? langues,
    String? fuseau,
  }) async {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    if (fuseau != null) {
      fuseaux.add(fuseau);
      return;
    }
    ecritures.add((pays: pays, langues: langues));
  }
}

/// Un profil enseignant complet, pret a l'emploi.
ProfilEnseignant _profilDeTest({
  String prenom = 'Aicha',
  String identifiant = 'RA-ENS-0007',
  String? pays = 'GN',
  // Des codes de `langues_cours` et une saisie libre, comme la base les
  // porte (CAND-Q15, lot langue).
  List<String> langues = const <String>['francais', 'Arabe'],
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
  Future<List<LangueCours>> Function()? referentiel,
  List<Override> extra = const <Override>[],
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
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
        baseLocaleEnMemoire(),
        serviceDeclarationProvider.overrideWithValue(declaration),
        // FORM-L8 : les langues se cochent parmi celles que l'academie publie,
        // et le profil les nomme par ce referentiel.
        referentielLanguesProvider.overrideWith(
          (_) =>
              referentiel?.call() ??
              Future<List<LangueCours>>.value(const <LangueCours>[
                LangueCours(code: 'poular', nom: 'Poular'),
                LangueCours(code: 'francais', nom: 'Français'),
              ]),
        ),
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
        ...extra,
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
  // PROFILS P3 : la declaration s'ouvre par la ligne « Identité
  // professionnelle » du Compte ; on l'ouvre si la ligne cherchee n'est pas la.
  if (find.text(titre).evaluate().isEmpty &&
      find.byKey(ProfilEnseignantPage.identiteKey).evaluate().isNotEmpty) {
    await _ouvrir(tester, ProfilEnseignantPage.identiteKey);
  }
  final Finder cible = find.text(titre);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// PROFILS P3 : ouvre la page d'une ligne du Compte (identite
/// professionnelle, contrats).
Future<void> _ouvrir(WidgetTester tester, Key ligne) async {
  await tester.ensureVisible(find.byKey(ligne));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ligne));
  await tester.pumpAndSettle();
}

/// PROFILS P3 : la confirmation commune de la ligne rouge du Compte.
String get _confirmer => t.compte.tuteur.deconnexion.confirmer;

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

          // PROFILS P3 : dans l'en-tete du Compte et sur la pastille.
          expect(find.text(c.attendu), findsWidgets);
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
      expect(find.text(t.enseignant.profil.statutInconnu), findsWidgets);
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
    // SANS-BARRE-FIXE : la deconnexion n'est plus collee en bas ; elle suit
    // le contenu dans le fil de la page (PLAN-TROIS-SALLES §2.2). Elle doit
    // toujours s'atteindre, en defilant, et tenir alors entiere.
    testWidgets('SANS-BARRE-FIXE : elle s atteint en defilant et tient '
        'entiere dans un telephone de 390 x 844', (WidgetTester tester) async {
      // L'invariant qui justifie cet ecran : « Compte » a quitte la barre, le
      // pied de coquille n'est rendu qu'a partir de 600, et une barre basse
      // Material 3 n'accepte aucune entree hors destination. Si ce rectangle
      // sort du cadre, un enseignant sur telephone n'a plus aucun chemin vers
      // la deconnexion.
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      expect(find.text(t.compte.deconnexion).hitTestable(), findsOneWidget);
      final Rect zone = tester.getRect(find.text(t.compte.deconnexion));
      expect(zone.top, greaterThanOrEqualTo(0));
      expect(zone.bottom, lessThanOrEqualTo(844));
    });

    testWidgets('elle se confirme avant de partir', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      // SANS-BARRE-FIXE : la deconnexion suit le contenu (PLAN-TROIS-SALLES
      // §2.2) ; on la fait venir dans la vue.
      await tester.ensureVisible(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();

      // La feuille est ouverte, et rien n'est encore parti.
      expect(
        find.text(t.compte.tuteur.deconnexion.consequence),
        findsOneWidget,
      );
      expect(monte.auth.deconnexions, 0);

      await tester.tap(find.text(_confirmer));
      await tester.pumpAndSettle();

      expect(monte.auth.deconnexions, 1);
    });

    testWidgets('un renoncement ne deconnecte pas', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      // SANS-BARRE-FIXE : la deconnexion suit le contenu (PLAN-TROIS-SALLES
      // §2.2) ; on la fait venir dans la vue.
      await tester.ensureVisible(find.text(t.compte.deconnexion));
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

      expect(find.text(t.compte.page.identiteEchec), findsOneWidget);

      await tester.ensureVisible(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      final Rect zone = tester.getRect(find.text(t.compte.deconnexion));
      expect(zone.bottom, lessThanOrEqualTo(844));

      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_confirmer));
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

    testWidgets('PROFILS P3 : la Bibliotheque n est plus dans le Profil, '
        'elle s ouvre en tete de Mes classes', (WidgetTester tester) async {
      // Elle a quitte le Profil (PROFILS P3, 11/11/2026) : la ligne vit en
      // tete de « Mes classes » (`EntreeBibliothequeMaClasse`, teste dans
      // test/features/enseignant_classes/bibliotheque_classes_test.dart).
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();
      expect(find.text(t.tc.bibliotheque.titre), findsNothing);
      expect(
        find.text(t.tc.bibliotheque.detail.entreeDetailEnseignant),
        findsNothing,
      );
    });

    testWidgets('content : les valeurs viennent du contrat, pas d un calcul', (
      WidgetTester tester,
    ) async {
      // Le talon d'avant ce lot refabriquait deux compteurs depuis
      // `seancesProvider` et un feed d'eleves en attente (retire, L3-02), dont l'un dedupliquait
      // `seances.map(eleveId).toSet()` -- fragile depuis le pivot groupes, ou
      // `mes_seances_v` rend une ligne par eleve. Ces deux lectures ont disparu,
      // et leurs libelles avec elles.
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      expect(find.text('Aicha'), findsOneWidget);
      expect(find.text('RA-ENS-0007'), findsOneWidget);
      // PROFILS P3 : le detail s'ouvre par la ligne « Identité
      // professionnelle ».
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);
      expect(find.text('GN'), findsOneWidget);
      expect(find.text('Français, Arabe'), findsOneWidget);
      expect(
        find.text(
          LibellesGroupe.valeurSeule(
            t.enseignant.profil.plafondValeur(nombre: 20),
          ),
        ),
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

      // PROFILS P3 : l'etat vide de l'en-tete du Compte.
      expect(find.text(t.compte.page.identiteVide), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
      expect(find.byKey(ProfilEnseignantPage.identiteKey), findsNothing);
    });

    testWidgets('error : une phrase et « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, echecProfil: true);
      await tester.pumpAndSettle();

      expect(find.text(t.compte.page.identiteEchec), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('offline : plus rien ne s edite, et on le dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, profil: _profilDeTest(), horsLigne: true);
      await tester.pumpAndSettle();
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);

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
      await _ouvrir(tester, ProfilEnseignantPage.contratsKey);

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
      await _ouvrir(tester, ProfilEnseignantPage.contratsKey);

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
      await _ouvrir(tester, ProfilEnseignantPage.contratsKey);

      expect(find.text(t.enseignant.profil.contratErreur), findsOneWidget);
      // Retour au Compte : le reste est lisible.
      Navigator.of(tester.element(find.text(t.enseignant.profil.contratErreur)))
          .pop();
      await tester.pumpAndSettle();
      expect(find.text('RA-ENS-0007'), findsOneWidget);
      expect(find.text(t.enseignant.profil.compteValide), findsWidgets);

      // SANS-BARRE-FIXE : la deconnexion suit le contenu (PLAN-TROIS-SALLES
      // §2.2) ; on la fait venir dans la vue.
      await tester.ensureVisible(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_confirmer));
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

      // FORM-L8 : les langues se cochent, la langue hors liste (« Arabe »)
      // reste cochee ; on decoche « Français » et on coche « Poular ». Les
      // cartes portent des noms, l'ecriture des codes (CAND-Q15).
      await _taperLigne(tester, t.enseignant.profil.langues);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(FeuilleLangues.carteKey('Français')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeuilleLangues.carteKey('Poular')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeuilleLangues.enregistrerKey));
      await tester.pumpAndSettle();

      expect(monte.declaration.ecritures, hasLength(1));
      expect(monte.declaration.ecritures.single.pays, isNull);
      expect(monte.declaration.ecritures.single.langues, <String>[
        'Arabe',
        'poular',
      ]);
      expect(find.text(t.enseignant.profil.enregistre), findsOneWidget);
    });

    testWidgets('un nom enregistre par un ancien client repart en code', (
      WidgetTester tester,
    ) async {
      // Avant la correction, le profil portait le nom. La feuille coche la
      // carte de sa langue, une seule fois, et l'enregistrement envoie le
      // code.
      final _Monte monte = await _monter(
        tester,
        profil: _profilDeTest(langues: const <String>['Français', 'Arabe']),
      );
      await tester.pumpAndSettle();
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);
      expect(find.text('Français, Arabe'), findsOneWidget);

      await _taperLigne(tester, t.enseignant.profil.langues);
      expect(find.byKey(FeuilleLangues.carteKey('Français')), findsOneWidget);
      await tester.tap(find.byKey(FeuilleLangues.enregistrerKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(monte.declaration.ecritures.single.langues, <String>[
        'francais',
        'Arabe',
      ]);
    });

    testWidgets('un echec d ecriture se dit, et ne ment pas sur la valeur', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();
      monte.declaration.erreurAJeter = StateError('refus du serveur');

      // FORM-L8 : le pays se choisit dans la liste. « GN », declare hors
      // liste, revient dans « Autre » ; on choisit le Senegal.
      await _taperLigne(tester, t.enseignant.profil.pays);
      await tester.ensureVisible(find.byKey(FeuillePays.carteKey('Sénégal')));
      await tester.tap(find.byKey(FeuillePays.carteKey('Sénégal')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(FeuillePays.enregistrerKey));
      await tester.tap(find.byKey(FeuillePays.enregistrerKey));
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.editionErreur), findsOneWidget);
      // L'ecran n'a aucun etat local de profil : il reaffiche ce que la lecture
      // rend, donc l'ancienne valeur.
      expect(find.text('GN'), findsOneWidget);
      expect(find.text('Sénégal'), findsNothing);
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

  group('ENS-05 : la ligne des langues ne montre jamais un code', () {
    testWidgets('referentiel en chargement : sa forme, pas les codes', (
      WidgetTester tester,
    ) async {
      final Completer<List<LangueCours>> jamais =
          Completer<List<LangueCours>>();
      await _monter(
        tester,
        profil: _profilDeTest(),
        referentiel: () => jamais.future,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(ProfilEnseignantPage.identiteKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(t.enseignant.profil.langues), findsOneWidget);
      expect(find.textContaining('francais'), findsNothing);
      expect(find.textContaining('Arabe'), findsNothing);
      expect(find.byType(Skeleton), findsOneWidget);
    });

    testWidgets('referentiel illisible : la ligne le dit, sans code', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        profil: _profilDeTest(),
        referentiel: () =>
            Future<List<LangueCours>>.error(StateError('panne reseau')),
      );
      await tester.pumpAndSettle();
      // Le reste du profil reste lisible.
      expect(find.text('RA-ENS-0007'), findsOneWidget);
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);

      expect(find.text(t.enseignant.profil.languesErreur), findsOneWidget);
      expect(find.textContaining('francais'), findsNothing);
    });

    testWidgets('referentiel illisible, en arabe : la ligne le dit en arabe', (
      WidgetTester tester,
    ) async {
      // Revue CAND-Q15 (lot langue) : la cle n'avait pas de traduction
      // arabe, et slang retombait sur la phrase francaise. Sans traduction,
      // `t` rend la meme chaine dans les deux langues : le `findsNothing`
      // sur le francais echoue.
      final String francais = AppLocale.fr
          .buildSync()
          .enseignant
          .profil
          .languesErreur;
      // L'arabe est une bibliotheque differee : il se charge hors du temps
      // simule du test.
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      await _monter(
        tester,
        profil: _profilDeTest(),
        referentiel: () =>
            Future<List<LangueCours>>.error(StateError('panne reseau')),
      );
      await tester.pumpAndSettle();
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);

      expect(find.text(t.enseignant.profil.languesErreur), findsOneWidget);
      expect(find.text(francais), findsNothing);
      expect(find.textContaining('francais'), findsNothing);
    });

    testWidgets('une langue retiree de l onboarding reste nommee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        profil: _profilDeTest(langues: const <String>['poular', 'Wolof']),
        referentiel: () async => const <LangueCours>[
          LangueCours(code: 'poular', nom: 'Poular', actif: false),
          LangueCours(code: 'francais', nom: 'Français'),
        ],
      );
      await tester.pumpAndSettle();
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);

      expect(find.text('Poular, Wolof'), findsOneWidget);
      expect(find.textContaining('poular'), findsNothing);
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

  group('PROFILS P3 : le Compte de l enseignant sur PageCompte', () {
    testWidgets('deconnexion avec un cahier non envoye : la question, et '
        'rien n est efface sans reponse', (WidgetTester tester) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      int vidages = 0;
      int remises = 0;
      await _monter(
        tester,
        profil: _profilDeTest(),
        extra: <Override>[
          deconnexionProvider.overrideWithValue(
            Deconnexion(
              auth: auth,
              rapportsRestants: () async => 1,
              viderAppareil: () async => vidages++,
              remiseAZero: () => remises++,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_confirmer));
      await tester.pumpAndSettle();

      // La question des cahiers non envoyes, et rien n'est encore fait.
      expect(
        find.text(t.compte.tuteur.deconnexion.rapportsQuestion),
        findsOneWidget,
      );
      expect((auth.deconnexions, vidages, remises), (0, 0, 0));

      // Annuler : rien n'est touche, la session reste ouverte.
      await tester.tap(find.text(t.compte.tuteur.deconnexion.rapportsAnnuler));
      await tester.pumpAndSettle();
      expect((auth.deconnexions, vidages, remises), (0, 0, 0));

      // Redemander, puis accepter la perte : la session se ferme.
      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_confirmer));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(t.compte.tuteur.deconnexion.rapportsConfirmer),
      );
      await tester.pumpAndSettle();
      expect(auth.deconnexions, 1);
      expect(vidages, 1);
    });

    testWidgets('la page se compose dans PageCompte, sections dans l ordre, '
        'version en bas', (WidgetTester tester) async {
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();

      expect(find.byType(PageCompte), findsOneWidget);
      final List<double> y = <double>[
        for (final SectionCompte s in <SectionCompte>[
          SectionCompte.monEspace,
          SectionCompte.paiements,
          SectionCompte.preferences,
          SectionCompte.compteSecurite,
          SectionCompte.aide,
        ])
          tester.getTopLeft(find.byKey(PageCompte.cleSection(s))).dy,
      ];
      for (int i = 1; i < y.length; i++) {
        expect(y[i], greaterThan(y[i - 1]));
      }
      // Lignes sobres : identite professionnelle et publication sont des
      // lignes de Mon espace ; aucun bouton plein de deconnexion.
      expect(
        find.descendant(
          of: find.byKey(PageCompte.cleSection(SectionCompte.monEspace)),
          matching: find.byKey(ProfilEnseignantPage.identiteKey),
        ),
        findsOneWidget,
      );
      // La politique de controle et le code de conduite sont dans Aide et
      // informations, pas dans Compte et securite.
      for (final Key k in <Key>[
        ProfilEnseignantPage.politiqueKey,
        ProfilEnseignantPage.codeConduiteKey,
      ]) {
        expect(
          find.descendant(
            of: find.byKey(PageCompte.cleSection(SectionCompte.aide)),
            matching: find.byKey(k),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: find.byKey(PageCompte.cleSection(SectionCompte.aide)),
          matching: find.text(t.compte.tuteur.aide.legal),
        ),
        findsOneWidget,
      );
      expect(find.byKey(PageCompte.versionKey), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(PageCompte.versionKey)).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(PageCompte.deconnecterKey)).dy,
        ),
      );
    });

    testWidgets('theme et langue a un geste (2 au plus)', (
      WidgetTester tester,
    ) async {
      // Le Compte est ouvert (1 geste depuis la barre) ; le theme et la
      // langue sont des lignes de Preferences, sur la page meme : 2 gestes.
      await _monter(tester, profil: _profilDeTest());
      await tester.pumpAndSettle();
      final Finder prefs = find.byKey(
        PageCompte.cleSection(SectionCompte.preferences),
      );
      expect(
        find.descendant(of: prefs, matching: find.text(t.compte.langue)),
        findsWidgets,
      );
    });

    for (final bool dispo in <bool>[true, false]) {
      testWidgets('Mes donnees selon la capacite ($dispo)', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          profil: _profilDeTest(),
          extra: <Override>[
            mesDonneesDisponiblesProvider.overrideWithValue(dispo),
          ],
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(RubriqueMesDonnees.ligneKey),
          dispo ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('Aide et contact : le canal publie, sinon pas de ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        profil: _profilDeTest(),
        extra: <Override>[
          canalAideCompteProvider.overrideWith(
            (_) async => const CanalSupport(
              nature: NatureCanalSupport.lien,
              adresse: 'https://exemple.invalid/aide',
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text(t.compte.tuteur.pageAide.canalLien), findsOneWidget);
    });
  });

  // FUSEAU-IDENTITE-PRO (garde-cap, 12/11/2026) : l'enseignant regle lui-meme
  // son fuseau dans « Identite professionnelle » ; la ligne ecrit le fuseau
  // (p_timezone), et un nom refuse par le serveur est dit.
  group('FUSEAU-IDENTITE-PRO : la ligne Fuseau', () {
    testWidgets('la valeur du serveur : « Riyadh · UTC+3 »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        profil: _profilDeTest(),
        extra: <Override>[
          monHorlogeDeTest(
            fuseau: 'Asia/Riyadh',
            decalage: const Duration(hours: 3),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);
      expect(
        find.descendant(
          of: find.byKey(cleLigneFuseau),
          matching: find.text(
            t.enseignant.profil.fuseauValeur(
              ville: villeDuFuseauLibelle('Asia/Riyadh'),
              decalage: '+3',
            ),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la ligne ecrit le fuseau, et seulement lui', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(
        tester,
        profil: _profilDeTest(),
        extra: <Override>[monHorlogeDeTest()],
      );
      await tester.pumpAndSettle();
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);
      await tester.ensureVisible(find.byKey(cleLigneFuseau));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(cleLigneFuseau));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(FeuilleFuseau.expertKey),
          matching: find.byType(EditableText),
        ),
        'Asia/Riyadh',
      );
      await tester.ensureVisible(find.byKey(FeuilleFuseau.enregistrerKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeuilleFuseau.enregistrerKey));
      await tester.pumpAndSettle();
      expect(monte.declaration.fuseaux, <String>['Asia/Riyadh']);
      expect(monte.declaration.ecritures, isEmpty);
      expect(find.text(t.enseignant.profil.enregistre), findsOneWidget);
    });

    testWidgets('un nom refuse par le serveur est dit, pas avale', (
      WidgetTester tester,
    ) async {
      final _Monte monte = await _monter(
        tester,
        profil: _profilDeTest(),
        extra: <Override>[monHorlogeDeTest()],
      );
      monte.declaration.erreurAJeter = const FuseauInconnu();
      await tester.pumpAndSettle();
      await _ouvrir(tester, ProfilEnseignantPage.identiteKey);
      await tester.ensureVisible(find.byKey(cleLigneFuseau));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(cleLigneFuseau));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(FeuilleFuseau.expertKey),
          matching: find.byType(EditableText),
        ),
        'Asia/Riad',
      );
      await tester.ensureVisible(find.byKey(FeuilleFuseau.enregistrerKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeuilleFuseau.enregistrerKey));
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.profil.fuseauInconnu), findsOneWidget);
      expect(find.byType(FeuilleFuseau), findsOneWidget);
      expect(find.text(t.enseignant.profil.enregistre), findsNothing);
    });
  });
}
