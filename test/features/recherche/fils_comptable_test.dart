// RECHERCHE D4, partie « fils » du comptable (08/11/2026) : le comptable cherche
// ses fils « Profil de paiement » dans la recherche de PRODUCTION.
//
// Avant : `moteursRechercheProduction` ne servait aucun domaine au comptable
// (pas de loupe). Maintenant : un seul moteur, sur les Messages metier que
// l'application lit deja ; le serveur ne rend au comptable que les fils
// « Profil de paiement » de l'equipe (`com_est_partie`) ; le resultat ouvre le
// fil du beneficiaire (`Routes.comptableFilProfilPaiementPour`), un ecran qui a
// une vraie source. Ni encaissements (CPT-BR-07, aucune source serveur), ni
// Studio.
//
// Chaque controle ci-dessous echoue sur `main` d'avant ce lot (comptable non
// servi, aucune destination de fil pour lui).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/fil_profil_paiement_page.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;
import 'package:rewayah_academy/features/recherche/entree_recherche.dart';
import 'package:rewayah_academy/features/recherche/moteurs_production.dart';
import 'package:rewayah_academy/features/recherche/resolveur_cible.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../../teaching_core/a/faux/faux_groupes.dart' show FauxPortGroupes;
import '../../teaching_core/h/faux/faux_ports_externes.dart' show FauxRoster;
import '../com_messages/support_messages.dart';

const ContexteRecherche _comptable = ContexteRecherche(
  espace: EspaceRecherche.comptable,
);

ResumeFil _resume(
  String id,
  TypeObjetLie type,
  String objetId,
  String libelle,
) {
  return ResumeFil(
    id: id,
    objet: ObjetLie(type: type, id: objetId, libelle: libelle),
    interlocuteurs: const <Participant>[
      Participant(id: 'p-fatima', nomAffiche: 'Fatima Diallo'),
    ],
  );
}

/// Trois fils vus du serveur : celui du comptable (profil de paiement), et deux
/// que le comptable ne devrait jamais lire (classe, candidature).
FauxMessagesMetier _messages({Exception? panne}) => FauxMessagesMetier(
  resumesEnPlus: <ResumeFil>[
    _resume('f-paie', TypeObjetLie.profilPaiement, 'b-1', 'Profil de paiement'),
    _resume('f-classe', TypeObjetLie.classe, 'c-1', 'Classe An-Nour'),
    _resume('f-cand', TypeObjetLie.candidature, 'k-1', 'Candidature de Fatima'),
  ],
)..erreurListe = panne;

/// La production pour un conteneur nu : le branchement reel + des ports qui
/// rendent ce qu'on leur donne.
List<Override> _production(FauxMessagesMetier messages) => <Override>[
  ..._surRouteur(messages),
  portGroupesProvider.overrideWithValue(const FauxPortGroupes()),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  portCatalogueProvider.overrideWithValue(CatalogueLocal()),
];

/// Sur le vrai routeur, le harnais pose deja les ports des classes : on n'y
/// ajoute que le branchement et les Messages.
List<Override> _surRouteur(FauxMessagesMetier messages) => <Override>[
  moteursRechercheProvider.overrideWith(moteursRechercheProduction),
  portMessagesMetierProvider.overrideWithValue(messages),
  portRosterEnseignantProvider.overrideWithValue(FauxRoster()),
];

Future<ProviderContainer> _conteneur(List<Override> surcharges) async {
  final ProviderContainer c = ProviderContainer(overrides: surcharges);
  addTearDown(c.dispose);
  return c;
}

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('le moteur de production, pour le comptable', () {
    test('le comptable est servi, et par ses seuls fils', () async {
      final ProviderContainer c = await _conteneur(_production(_messages()));
      final PortRecherche port = c.read(portRechercheProvider);
      expect((await port.portees(_comptable)).toSet(), <DomaineRecherche>{
        DomaineRecherche.fils,
      });
      expect(
        await c.read(rechercheServieProvider(EspaceRecherche.comptable).future),
        isTrue,
      );
    });

    test('un fil « Profil de paiement » est trouve par le nom de la personne ; '
        'seul ce type est rendu', () async {
      final ProviderContainer c = await _conteneur(_production(_messages()));
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.fils,
            requete: 'fatima',
            contexte: _comptable,
          );
      expect(r, isA<ReponseOk>());
      final List<ResultatRecherche> elements = (r as ReponseOk).elements;
      // Les fils de classe et de candidature portent aussi « Fatima » : le
      // comptable ne les recoit jamais.
      expect(elements, hasLength(1));
      expect(elements.single.titre, 'Profil de paiement');
      expect(elements.single.cible.kind, KindCible.fil);
    });

    test('le resultat porte l\'identifiant du beneficiaire et ouvre SON fil, '
        'un ecran qui a une source', () async {
      final ProviderContainer c = await _conteneur(_production(_messages()));
      final ReponseOk r =
          await c
                  .read(portRechercheProvider)
                  .rechercher(
                    domaine: DomaineRecherche.fils,
                    requete: 'fatima',
                    contexte: _comptable,
                  )
              as ReponseOk;
      final CibleRecherche cible = r.elements.single.cible;
      expect(cible.reference, 'b-1', reason: 'l\'objet du fil, pas le fil');
      expect(
        cheminPourCible(cible, EspaceRecherche.comptable),
        Routes.comptableFilProfilPaiementPour('b-1'),
      );
      expect(
        Routes.comptableFilProfilPaiementPour('b-1'),
        '/comptable/paiements/beneficiaires/b-1/fil',
      );
    });

    test(
      'les autres espaces gardent la reference du fil et leurs adresses',
      () {
        const CibleRecherche cible = CibleRecherche(
          kind: KindCible.fil,
          reference: 'f-1',
        );
        expect(
          cheminPourCible(cible, EspaceRecherche.famille),
          Routes.tuteurFilPour('f-1'),
        );
        expect(
          cheminPourCible(cible, EspaceRecherche.enseignant),
          Routes.enseignantFilPour('f-1'),
        );
        expect(
          cheminPourCible(cible, EspaceRecherche.administration),
          Routes.adminFilPour('f-1'),
        );
      },
    );

    test(
      'une panne de la lecture des fils est une panne, jamais un vide',
      () async {
        final ProviderContainer c = await _conteneur(
          _production(_messages(panne: Exception('lecture refusee'))),
        );
        final ReponseDomaine r = await c
            .read(portRechercheProvider)
            .rechercher(
              domaine: DomaineRecherche.fils,
              requete: 'fatima',
              contexte: _comptable,
            );
        expect(r, isA<ReponseEchec>());
      },
    );

    test('un nom sans fil est un vide confirme', () async {
      final ProviderContainer c = await _conteneur(_production(_messages()));
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.fils,
            requete: 'zzzzzz',
            contexte: _comptable,
          );
      expect(r, isA<ReponseOk>());
      expect((r as ReponseOk).elements, isEmpty);
    });

    test('ni encaissements ni Studio : aucun domaine « finances », aucun '
        'canal', () async {
      final ProviderContainer c = await _conteneur(_production(_messages()));
      final PortRecherche port = c.read(portRechercheProvider);
      expect(
        await port.portees(_comptable),
        isNot(contains(DomaineRecherche.finances)),
      );
      final ReponseDomaine r = await port.rechercher(
        domaine: DomaineRecherche.finances,
        requete: 'fatima',
        contexte: _comptable,
      );
      // Un domaine non servi n'est pas interroge comme un vide : il refuse.
      expect(r, isA<ReponseEchec>());
    });
  });

  group('sur le vrai routeur, le comptable', () {
    testWidgets('a la loupe, trouve le fil, et l\'ouvre', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.recherche,
        source: FausseSourceSession(sessionActive(AppRole.accountant)),
        surcharges: _surRouteur(_messages()),
      );
      await _chercher(tester, 'fatima');
      expect(find.text('Profil de paiement'), findsOneWidget);
      expect(find.text('Classe An-Nour'), findsNothing);
      expect(find.text('Candidature de Fatima'), findsNothing);
      expect(find.text(t.recherche.etats.vide.titre), findsNothing);

      await tester.tap(find.text('Profil de paiement'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        routeur
            .routerDelegate
            .currentConfiguration
            .matches
            .last
            .matchedLocation,
        Routes.comptableFilProfilPaiementPour('b-1'),
      );
      expect(find.byType(FilProfilPaiementPage), findsOneWidget);
    });

    testWidgets('la loupe de son espace existe sur sa page d\'accueil', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.comptable,
        source: FausseSourceSession(sessionActive(AppRole.accountant)),
        surcharges: _surRouteur(_messages()),
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
    });

    testWidgets('un fil de candidature qui porte le meme nom n\'apparait pas', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.recherche,
        source: FausseSourceSession(sessionActive(AppRole.accountant)),
        surcharges: _surRouteur(_messages()),
      );
      await _chercher(tester, 'candidature');
      expect(find.text('Candidature de Fatima'), findsNothing);
    });
  });
}
