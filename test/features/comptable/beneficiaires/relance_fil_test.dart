// CPT-COM (R-FIN-20, CPT-BR-11, contrat C-12) : « Relancer » du Comptable
// ouvre le fil metier « Profil de paiement » de Communications V1
// (`PortMessagesMetier.filPourObjet(TypeObjetLie.profilPaiement, id)`), le
// message modele §27.3 prerempli comme brouillon du fil, rien d'envoye sans
// « Envoyer ». Aucune messagerie Finance (R-FIN-21) : aucun autre port.
//
// Couvre : le contrat additif (valeur `profilPaiement`, repli sur `autre`),
// le parcours depuis le profil (routeur de production), les etats de la
// relance (chargement, indisponible, echec, refus, objet etranger), le
// brouillon deja en cours garde, les etats de la page du fil, et le
// parcours dans la VRAIE coquille du Comptable (route de demonstration).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_beneficiaires_paiement.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/fil_contextuel.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/elements_enregistres_studio.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/fil_profil_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/profil_paiement_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/beneficiaires_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../../../capture/outil_capture.dart' show fixerVueCapture, stabiliser;
import '../../../router/support_routeur.dart' show sessionActive;
import '../../../support/garde_interface.dart';
import '../../../support/harnais.dart';

const String _ens01 = ProfilsBeneficiairesDemo.modifieRecemment;

/// Ce que rend `filPourObjet` dans un test.
enum _Mode { normal, indisponible, echec, refuse, jamais, autreObjet }

/// Les Messages de demonstration, qui comptent les fils demandes et peuvent
/// echouer de chaque facon.
class _Messages extends MessagesMetierDemo {
  _Messages({this.mode = _Mode.normal})
    : super.surObjets(aOuvrir: conversationsProfilPaiementDemo());

  final _Mode mode;
  final List<(TypeObjetLie, String)> appels = <(TypeObjetLie, String)>[];

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) {
    appels.add((type, objetId));
    return switch (mode) {
      _Mode.normal => super.filPourObjet(type, objetId),
      _Mode.indisponible => Future<FilMetier?>.error(
        const CapaciteIndisponible('COM-BR-01'),
      ),
      _Mode.echec => Future<FilMetier?>.error(StateError('reseau')),
      _Mode.refuse => Future<FilMetier?>.value(),
      _Mode.jamais => Completer<FilMetier?>().future,
      // Un fil rendu pour un AUTRE objet : jamais montre a sa place.
      _Mode.autreObjet => super.filPourObjet(type, 'ens-02'),
    };
  }
}

List<Override> _surcharges(
  PortMessagesMetier messages, {
  bool horsLigne = false,
  PortBrouillons? brouillons,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(sessionActive(AppRole.accountant)),
  ),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  portBeneficiairesPaiementProvider.overrideWithValue(
    const BeneficiairesPaiementDemo(),
  ),
  portMessagesMetierProvider.overrideWithValue(messages),
  capacitesCommunicationProvider.overrideWith(
    (Ref _) => const CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.ecrireDansFil,
    }).capacites(),
  ),
  if (brouillons != null) portBrouillonsProvider.overrideWithValue(brouillons),
];

/// Les routes de production du profil et de son fil.
final List<RouteBase> _routes = <RouteBase>[
  GoRoute(
    path: Routes.comptableBeneficiairePour(':beneficiaireId'),
    builder: (BuildContext _, GoRouterState etat) => ProfilPaiementPage(
      beneficiaireId: etat.pathParameters['beneficiaireId']!,
    ),
    routes: <RouteBase>[
      GoRoute(
        path: 'fil',
        builder: (BuildContext _, GoRouterState etat) => FilProfilPaiementPage(
          beneficiaireId: etat.pathParameters['beneficiaireId']!,
        ),
      ),
    ],
  ),
];

Future<void> _monter(
  WidgetTester tester,
  List<Override> surcharges, {
  String? depart,
  Size taille = const Size(390, 1800),
  double texte = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart ?? Routes.comptableBeneficiairePour(_ens01),
      routes: _routes,
      surcharges: surcharges,
      echelle: texte,
    ),
  );
  await stabiliser(tester);
}

Future<void> _relancer(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ProfilPaiementPage.relancerKey));
  await tester.tap(find.byKey(ProfilPaiementPage.relancerKey));
  await stabiliser(tester);
}

String get _nom => SocleComptableDemo.enseignants.first.nom;

Finder _etat(EtatCommunication etat) => find.byWidgetPredicate(
  (Widget w) => w is VueEtatCommunication && w.etat == etat,
);

/// Le texte du champ du fil.
String _champ(WidgetTester tester) => tester
    .widget<EditableText>(
      find
          .descendant(
            of: find.byType(FilContextuel),
            matching: find.byType(EditableText),
          )
          .first,
    )
    .controller
    .text;

void main() {
  group('contrat C-12 : TypeObjetLie.profilPaiement', () {
    test(
      'la chaine du contrat, et toute valeur inconnue retombe sur autre',
      () {
        expect(TypeObjetLie.profilPaiement.name, 'profilPaiement');
        expect(
          TypeObjetLie.depuis('profilPaiement'),
          TypeObjetLie.profilPaiement,
        );
        expect(TypeObjetLie.depuis('classe'), TypeObjetLie.classe);
        for (final String? inconnue in <String?>[
          null,
          '',
          'ProfilPaiement',
          'facture',
        ]) {
          expect(TypeObjetLie.depuis(inconnue), TypeObjetLie.autre);
        }
      },
    );

    test('libelle, icone, fil metier et element enregistre', () {
      expect(
        libelleTypeObjet(TypeObjetLie.profilPaiement),
        'Profil de paiement',
      );
      expect(iconeTypeObjet(TypeObjetLie.profilPaiement), AppIcons.paiements);
      expect(typesObjetsFilMetier, contains(TypeObjetLie.profilPaiement));
      expect(
        libelleTypeEnregistre(TypeObjetLie.profilPaiement),
        t.com.studio.enregistres.types.element,
      );
    });
  });

  group('Relancer depuis le profil (CPT-BR-11)', () {
    testWidgets('ouvre le fil « Profil de paiement », message modele §27.3 '
        'prerempli, rien n est envoye', (WidgetTester tester) async {
      final _Messages messages = _Messages();
      await _monter(tester, _surcharges(messages));
      await _relancer(tester);

      // Deux lectures du MEME fil canonique : la relance, puis la page du
      // fil ; jamais un autre objet, jamais un autre port.
      expect(messages.appels, <(TypeObjetLie, String)>[
        (TypeObjetLie.profilPaiement, _ens01),
        (TypeObjetLie.profilPaiement, _ens01),
      ]);
      expect(find.byType(FilProfilPaiementPage), findsOneWidget);
      expect(find.byType(FilContextuel), findsOneWidget);
      expect(
        find.text(t.comptable.beneficiaires.profil.filTitre),
        findsWidgets,
      );
      // L'objet du fil, rendu par le port : « Profil de paiement », sans
      // repeter le nom de l'interlocuteur, deja en tete du fil.
      expect(
        find.textContaining(
          t.comptable.beneficiaires.profilTitre,
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining(
          t.comptable.beneficiaires.profil.carteTitre(nom: _nom),
          findRichText: true,
        ),
        findsNothing,
      );
      expect(_champ(tester), t.comptable.beneficiaires.profil.messageModele);
      // D5 : rien n'est parti sans « Envoyer ».
      expect(messages.clesRecues, isEmpty);
      expect(messages.filEnMemoire('fil-$_ens01')!.messages, isEmpty);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('« Envoyer » envoie le message modele dans CE fil', (
      WidgetTester tester,
    ) async {
      final _Messages messages = _Messages();
      await _monter(tester, _surcharges(messages));
      await _relancer(tester);
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await stabiliser(tester);
      expect(messages.clesRecues, hasLength(1));
      expect(
        messages.filEnMemoire('fil-$_ens01')!.messages.single.texte,
        t.comptable.beneficiaires.profil.messageModele,
      );
    });

    testWidgets('un brouillon deja en cours n est jamais ecrase', (
      WidgetTester tester,
    ) async {
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      await brouillons.enregistrer(cleBrouillonFil('fil-$_ens01'), 'Mon texte');
      await _monter(tester, _surcharges(_Messages(), brouillons: brouillons));
      await _relancer(tester);
      expect(find.byType(FilProfilPaiementPage), findsOneWidget);
      expect(_champ(tester), 'Mon texte');
    });

    testWidgets('chargement : le bouton tourne, un second appui ne relance '
        'pas', (WidgetTester tester) async {
      final _Messages messages = _Messages(mode: _Mode.jamais);
      await _monter(tester, _surcharges(messages));
      await _relancer(tester);
      final Finder bouton = find.byKey(ProfilPaiementPage.relancerKey);
      expect(
        find.descendant(
          of: bouton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(bouton, warnIfMissed: false);
      await tester.pump();
      expect(messages.appels, hasLength(1));
      expect(find.byType(FilProfilPaiementPage), findsNothing);
    });

    testWidgets('hors ligne : la phrase dit le reseau, aucun fil ouvert', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _surcharges(_Messages(mode: _Mode.echec), horsLigne: true),
      );
      await _relancer(tester);
      expect(find.byType(FilProfilPaiementPage), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(ProfilPaiementPage.retourKey)).data,
        t.comptable.beneficiaires.profil.erreurHorsLigne,
      );
      expect(find.byKey(ProfilPaiementPage.relancerKey), findsOneWidget);
    });

    for (final (_Mode mode, String Function() phrase) cas
        in <(_Mode, String Function())>[
          (
            _Mode.indisponible,
            () => t.comptable.beneficiaires.profil.erreurIndisponible,
          ),
          (_Mode.echec, () => t.comptable.beneficiaires.profil.erreurAction),
          (
            _Mode.refuse,
            () => t.comptable.beneficiaires.profil.relanceRefusee(nom: _nom),
          ),
          (
            _Mode.autreObjet,
            () => t.comptable.beneficiaires.profil.relanceRefusee(nom: _nom),
          ),
        ]) {
      testWidgets('${cas.$1.name} : la phrase le dit, aucun fil ouvert', (
        WidgetTester tester,
      ) async {
        await _monter(tester, _surcharges(_Messages(mode: cas.$1)));
        await _relancer(tester);
        expect(find.byType(FilProfilPaiementPage), findsNothing);
        final Text retour = tester.widget<Text>(
          find.byKey(ProfilPaiementPage.retourKey),
        );
        expect(retour.data, cas.$2());
        // Le bouton reste la, pret pour un nouvel essai.
        expect(find.byKey(ProfilPaiementPage.relancerKey), findsOneWidget);
      });
    }
  });

  group('Page du fil « Profil de paiement »', () {
    String depart() => Routes.comptableFilProfilPaiementPour(_ens01);

    testWidgets('chargement', (WidgetTester tester) async {
      await _monter(
        tester,
        _surcharges(_Messages(mode: _Mode.jamais)),
        depart: depart(),
      );
      expect(_etat(EtatCommunication.chargement), findsOneWidget);
    });

    testWidgets('indisponible (production) : sans « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _surcharges(const MessagesMetierIndisponibles()),
        depart: depart(),
      );
      expect(_etat(EtatCommunication.indisponible), findsOneWidget);
      expect(find.byType(FilContextuel), findsNothing);
    });

    testWidgets('erreur : « Reessayer » relit le fil', (
      WidgetTester tester,
    ) async {
      final _Messages messages = _Messages(mode: _Mode.echec);
      await _monter(tester, _surcharges(messages), depart: depart());
      expect(_etat(EtatCommunication.erreur), findsOneWidget);
      await tester.tap(find.text(t.commun.reessayer).first);
      await stabiliser(tester);
      expect(messages.appels, hasLength(2));
    });

    testWidgets('hors ligne : le bandeau des Communications et l etat', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _surcharges(_Messages(mode: _Mode.echec), horsLigne: true),
        depart: depart(),
      );
      expect(find.byType(BandeauHorsLigneCommunication), findsOneWidget);
      expect(_etat(EtatCommunication.horsLigne), findsOneWidget);
    });

    testWidgets('refuse ou autre objet : rien du fil n est rendu', (
      WidgetTester tester,
    ) async {
      for (final _Mode mode in <_Mode>[_Mode.refuse, _Mode.autreObjet]) {
        await _monter(
          tester,
          _surcharges(_Messages(mode: mode)),
          depart: depart(),
        );
        expect(_etat(EtatCommunication.permissionRefusee), findsOneWidget);
        expect(find.byType(FilContextuel), findsNothing);
        expect(find.textContaining(_nom), findsNothing);
      }
    });

    testWidgets('320 a texte x2 : sans exception, un seul bouton plein', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _surcharges(_Messages()),
        depart: depart(),
        taille: const Size(320, 640),
        texte: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(FilContextuel), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('Vraie coquille du Comptable (route de demonstration)', () {
    // Chaque parcours part d'une session de demonstration vierge : aucun
    // brouillon ni message herite d'un autre test (revue CPT-COM).
    setUp(reinitialiserDemoBeneficiaires);

    Future<void> monterCoquille(WidgetTester tester, Size taille) async {
      fixerVueCapture(tester, taille, 1);
      await tester.pumpWidget(
        hoteRoutant(
          depart: adresseDemoComptable(EcranDemoComptable.profilPaiement),
          routes: routesDemoComptable('staging'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavShell), findsOneWidget);
    }

    Future<void> relancerCoquille(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(ProfilPaiementPage.relancerKey));
      await tester.tap(find.byKey(ProfilPaiementPage.relancerKey));
      await tester.pumpAndSettle();
    }

    final CleBrouillon cleDemo = cleBrouillonFil('fil-$_ens01');

    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets(
        '${taille.width.toInt()} : « Relancer » arrive dans le fil « Profil '
        'de paiement », barre du Comptable gardee',
        (WidgetTester tester) async {
          // Session vierge : c'est CE parcours qui preremplit le champ.
          expect(
            await sessionFilsDemoBeneficiaires.brouillons.lire(cleDemo),
            isNull,
          );
          await monterCoquille(tester, taille);
          await relancerCoquille(tester);

          expect(find.byType(FilProfilPaiementPage), findsOneWidget);
          expect(find.byType(ProfilPaiementPage), findsNothing);
          expect(find.byType(NavShell), findsOneWidget);
          expect(find.byType(FilContextuel), findsOneWidget);
          expect(
            _champ(tester),
            t.comptable.beneficiaires.profil.messageModele,
          );
          expect(
            (await sessionFilsDemoBeneficiaires.brouillons.lire(cleDemo))
                ?.texte,
            t.comptable.beneficiaires.profil.messageModele,
          );
          // Aucune exception, debordement compris.
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('un message envoye dans le fil de demonstration y est encore '
        'au retour', (WidgetTester tester) async {
      await monterCoquille(tester, const Size(390, 844));
      await relancerCoquille(tester);
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(FilDiscussion.cleAucunMessage), findsNothing);

      // Un nouvel ecran de demonstration (nouvelle portee) : le fil garde
      // son message.
      await tester.pumpWidget(const SizedBox.shrink());
      await monterCoquille(tester, const Size(390, 844));
      await relancerCoquille(tester);
      expect(find.byType(FilContextuel), findsOneWidget);
      expect(find.byKey(FilDiscussion.cleAucunMessage), findsNothing);
      expect(
        sessionFilsDemoBeneficiaires.messages
            .filEnMemoire('fil-$_ens01')!
            .messages,
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    });

    test(
      'reinitialiserDemoBeneficiaires repart d une session vierge',
      () async {
        final SessionFilsDemoBeneficiaires avant = sessionFilsDemoBeneficiaires;
        await avant.brouillons.enregistrer(cleDemo, 'texte');
        reinitialiserDemoBeneficiaires();
        expect(identical(sessionFilsDemoBeneficiaires, avant), isFalse);
        expect(
          await sessionFilsDemoBeneficiaires.brouillons.lire(cleDemo),
          isNull,
        );
      },
    );
  });
}
