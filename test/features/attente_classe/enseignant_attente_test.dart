// SUIVI-ATTENTE (S4, S5) : le cote de l'enseignant.
//
// - « Ce que les familles voient de vous » : le reglage de visibilite, les deux
//   pays choisis dans la liste, le mot, l'enregistrement et son echec ;
// - « Me presenter » : le message deja redige (masculin ou feminin selon le
//   titre), modifiable ; un message par famille ou eleve adulte par les
//   Messages existants ; jamais la direction ; jamais deux fois a la meme
//   famille (celle qui a deja un echange ne le recoit pas, la cle de chaque
//   envoi est la meme a chaque essai) ; vide, erreur, echec partiel ;
// - l'entree dans Mes classes : seulement les classes recentes, seulement
//   quand les Messages sont branches.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/features/attente_classe/entree_presentation_classes.dart';
import 'package:rewayah_academy/features/attente_classe/me_presenter_page.dart';
import 'package:rewayah_academy/features/attente_classe/presentation_familles_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import '../com_messages/support_messages.dart';

class _PortPresentation implements PortPresentationEnseignant {
  _PortPresentation(this.initial, {this.echec = false});

  PresentationAuxFamilles initial;
  bool echec;
  final List<({bool montre, String? origine, String? residence, String? mot})>
  appels = <({bool montre, String? origine, String? residence, String? mot})>[];

  @override
  Future<PresentationAuxFamilles> lire() async => initial;

  @override
  Future<void> regler({
    required bool montre,
    String? paysOrigine,
    String? paysResidence,
    String? mot,
  }) async {
    if (echec) throw StateError('refus du serveur');
    appels.add((
      montre: montre,
      origine: paysOrigine,
      residence: paysResidence,
      mot: mot,
    ));
  }
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Choisit un pays dans la feuille : la liste est longue, on amene la ligne a
/// l'ecran avant de la toucher.
Future<void> _taperPays(WidgetTester tester, String code) async {
  await tester.ensureVisible(_cle('presentation-pays-$code'));
  await tester.pump();
  await tester.tap(_cle('presentation-pays-$code'));
}

Future<void> _page(
  WidgetTester tester,
  _PortPresentation port, {
  double largeur = 390,
  double echelle = 1,
}) => monterRecrutement(
  tester,
  chemin: '/enseignant/profil/presentation',
  ecran: (_) => const PresentationFamillesPage(),
  autres: <String>['/enseignant/profil'],
  surcharges: <Override>[
    portPresentationEnseignantProvider.overrideWithValue(port),
  ],
  largeur: largeur,
  echelle: echelle,
);

// --- Me presenter -----------------------------------------------------------

const String _groupe = 'g1';

ConversationPossible _conv(
  String id, {
  NatureInterlocuteur nature = NatureInterlocuteur.famille,
  String? filId,
}) => ConversationPossible(
  interlocuteur: Participant(id: id, nomAffiche: 'Famille $id'),
  nature: nature,
  filId: filId,
  objet: ObjetLie(
    type: TypeObjetLie.classe,
    id: _groupe,
    libelle: 'Classe Al-Fatiha',
  ),
);

GroupeEnseignant _classe({DateTime? creeLe}) => GroupeEnseignant(
  id: _groupe,
  libelle: 'Classe Al-Fatiha',
  type: TypePublicGroupe.enfant,
  seuilMax: 5,
  creneau: const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
  nbMembres: 3,
  creeLe: creeLe ?? DateTime.now(),
);

List<Override> _surchargesPresenter(
  FauxMessagesMetier port, {
  String? titre = 'sayyid',
  List<GroupeEnseignant>? classes,
}) => <Override>[
  portMessagesMetierProvider.overrideWithValue(port),
  groupesEnseignantProvider.overrideWith(
    (Ref _) async => classes ?? <GroupeEnseignant>[_classe()],
  ),
  profilEnseignantProvider.overrideWith(
    (Ref _) async => ProfilEnseignant(
      prenom: 'Ibrahim',
      identifiant: 'RA-ENS-1',
      titre: titre,
    ),
  ),
];

FauxMessagesMetier _portMessages({List<ConversationPossible>? conversations}) {
  final List<ConversationPossible> liste =
      conversations ??
      <ConversationPossible>[
        _conv('a'),
        _conv('b'),
        _conv('c', filId: 'fil-existant'),
        _conv('admin', nature: NatureInterlocuteur.administration),
      ];
  return FauxMessagesMetier(
    fils: <FilMetier>[
      filSimple(id: 'fil-a'),
      filSimple(id: 'fil-b'),
      filSimple(id: 'fil-existant'),
    ],
    conversations: <String, List<ConversationPossible>>{
      cleObjet(TypeObjetLie.classe, _groupe): liste,
    },
    filsParConversation: <String, String>{
      _conv('a').cle: 'fil-a',
      _conv('b').cle: 'fil-b',
      _conv('c').cle: 'fil-existant',
    },
  );
}

Future<void> _presenter(
  WidgetTester tester,
  FauxMessagesMetier port, {
  String? titre = 'sayyid',
  double largeur = 390,
  double echelle = 1,
}) => monterRecrutement(
  tester,
  chemin: '/enseignant/classes/:groupeId/presentation',
  depart: '/enseignant/classes/$_groupe/presentation',
  ecran: (s) => MePresenterPage(groupeId: s.pathParameters['groupeId']!),
  autres: <String>['/enseignant/classes'],
  surcharges: _surchargesPresenter(port, titre: titre),
  largeur: largeur,
  echelle: echelle,
);

String _texteChamp(WidgetTester tester) =>
    tester.widget<TextField>(_cle('presenter-texte')).controller!.text;

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  group('ce que les familles voient de l\'enseignant (S4)', () {
    testWidgets(
      'pas encore confirme : on le dit, les champs attendent le oui',
      (WidgetTester tester) async {
        await _page(
          tester,
          _PortPresentation(
            const PresentationAuxFamilles(montre: false, confirme: false),
          ),
        );
        expect(_cle('presentation-non-confirme'), findsOneWidget);
        expect(_cle('presentation-origine'), findsNothing);
        expect(_cle('presentation-mot'), findsNothing);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets(
      'je montre : deux pays choisis dans la liste, un mot, enregistre',
      (WidgetTester tester) async {
        final _PortPresentation port = _PortPresentation(
          const PresentationAuxFamilles(montre: false, confirme: false),
        );
        await _page(tester, port);
        await tester.tap(_cle('presentation-montrer'));
        await laisser(tester);
        expect(_cle('presentation-origine'), findsOneWidget);
        // Le pays d'origine : on le choisit, on ne le saisit pas.
        await tester.tap(_cle('presentation-origine'));
        await laisser(tester);
        await _taperPays(tester, 'GN');
        await laisser(tester);
        expect(find.text('Guinée'), findsOneWidget);
        await tester.tap(_cle('presentation-residence'));
        await laisser(tester);
        await _taperPays(tester, 'FR');
        await laisser(tester);
        expect(find.text('France'), findsOneWidget);
        await tester.enterText(
          _cle('presentation-mot'),
          '  Heureux de vous retrouver.  ',
        );
        await tester.ensureVisible(_cle('presentation-enregistrer'));
        await tester.tap(_cle('presentation-enregistrer'));
        await laisser(tester);
        expect(port.appels, hasLength(1));
        expect(port.appels.single.montre, isTrue);
        expect(port.appels.single.origine, 'GN');
        expect(port.appels.single.residence, 'FR');
        expect(port.appels.single.mot, 'Heureux de vous retrouver.');
        expect(
          find.text(t.suiviAttente.presentation.enregistre),
          findsOneWidget,
        );
      },
    );

    testWidgets('je refuse : seul le choix part', (WidgetTester tester) async {
      final _PortPresentation port = _PortPresentation(
        const PresentationAuxFamilles(
          montre: true,
          confirme: true,
          paysOrigine: 'GN',
        ),
      );
      await _page(tester, port);
      expect(_cle('presentation-non-confirme'), findsNothing);
      await tester.tap(_cle('presentation-montrer'));
      await laisser(tester);
      expect(_cle('presentation-origine'), findsNothing);
      await tester.tap(_cle('presentation-enregistrer'));
      await laisser(tester);
      expect(port.appels.single.montre, isFalse);
    });

    testWidgets('un pays se retire : « Ne pas renseigner »', (
      WidgetTester tester,
    ) async {
      final _PortPresentation port = _PortPresentation(
        const PresentationAuxFamilles(
          montre: true,
          confirme: true,
          paysOrigine: 'GN',
          paysResidence: 'FR',
        ),
      );
      await _page(tester, port);
      await tester.tap(_cle('presentation-residence'));
      await laisser(tester);
      await _taperPays(tester, 'aucun');
      await laisser(tester);
      expect(
        find.text(t.suiviAttente.presentation.nonRenseigne),
        findsOneWidget,
      );
      await tester.ensureVisible(_cle('presentation-enregistrer'));
      await tester.tap(_cle('presentation-enregistrer'));
      await laisser(tester);
      expect(port.appels.single.origine, 'GN');
      expect(port.appels.single.residence, isNull);
    });

    testWidgets('refus du serveur : on le dit (K-59), rien n\'est affirme', (
      WidgetTester tester,
    ) async {
      final _PortPresentation port = _PortPresentation(
        const PresentationAuxFamilles(montre: true, confirme: true),
        echec: true,
      );
      await _page(tester, port);
      await tester.ensureVisible(_cle('presentation-enregistrer'));
      await tester.tap(_cle('presentation-enregistrer'));
      await laisser(tester);
      expect(find.text(t.suiviAttente.presentation.erreur), findsOneWidget);
      expect(find.text(t.suiviAttente.presentation.enregistre), findsNothing);
    });

    for (final (String nom, double largeur, double echelle)
        in <(String, double, double)>[
          ('320 px, texte x2', 320, 2),
          ('1440 px', 1440, 1),
        ]) {
      testWidgets('$nom : aucun debordement, aucun mot coupe', (
        WidgetTester tester,
      ) async {
        await _page(
          tester,
          _PortPresentation(
            const PresentationAuxFamilles(
              montre: true,
              confirme: false,
              paysOrigine: 'GN',
              paysResidence: 'FR',
              mot: 'Un mot de présentation un peu long pour la mesure.',
            ),
          ),
          largeur: largeur,
          echelle: echelle,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });

  group('Me presenter (S5)', () {
    testWidgets('le message est deja redige, a son titre, avec la classe', (
      WidgetTester tester,
    ) async {
      await _presenter(tester, _portMessages());
      expect(
        _texteChamp(tester),
        t.suiviAttente.mePresenter.messageSayyid(
          nom: 'Ibrahim',
          classe: 'Classe Al-Fatiha',
        ),
      );
      expect(_cle('presenter-rappel'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('une enseignante : le message est au feminin', (
      WidgetTester tester,
    ) async {
      await _presenter(tester, _portMessages(), titre: 'sayyida');
      expect(
        _texteChamp(tester),
        t.suiviAttente.mePresenter.messageSayyida(
          nom: 'Ibrahim',
          classe: 'Classe Al-Fatiha',
        ),
      );
    });

    testWidgets(
      'un message par famille, jamais la direction, jamais deux fois',
      (WidgetTester tester) async {
        final FauxMessagesMetier port = _portMessages();
        await _presenter(tester, port);
        // La famille c a deja un echange : elle ne recoit pas la presentation.
        expect(
          find.text(t.suiviAttente.mePresenter.dejaEcrit(n: 1)),
          findsOneWidget,
        );
        await tester.tap(_cle('presenter-envoyer'));
        await laisser(tester);
        expect(port.envois, hasLength(2));
        expect(port.envois.map((e) => e.$1).toSet(), <String>{
          'fil-a',
          'fil-b',
        });
        expect(port.envois.map((e) => e.$2).toSet(), hasLength(1));
        expect(
          port.envois.map((e) => e.$3).toSet(),
          hasLength(2),
          reason: 'une cle d\'idempotence par famille',
        );
        expect(
          port.conversationsDemandees.any((String c) => c.contains('admin')),
          isFalse,
        );
        expect(
          port.conversationsDemandees.any((String c) => c.contains(':c')),
          isFalse,
        );
        expect(
          find.text(t.suiviAttente.mePresenter.envoye(n: 2)),
          findsOneWidget,
        );
        expect(_cle('presenter-envoyer'), findsNothing);
      },
    );

    testWidgets('le message modifie part tel qu\'il est ecrit', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = _portMessages();
      await _presenter(tester, port);
      await tester.enterText(
        _cle('presenter-texte'),
        'Bonjour, je me présente.',
      );
      await tester.tap(_cle('presenter-envoyer'));
      await laisser(tester);
      expect(port.envois.map((e) => e.$2).toSet(), <String>{
        'Bonjour, je me présente.',
      });
    });

    testWidgets('un message vide ne part pas', (WidgetTester tester) async {
      final FauxMessagesMetier port = _portMessages();
      await _presenter(tester, port);
      await tester.enterText(_cle('presenter-texte'), '   ');
      await tester.tap(_cle('presenter-envoyer'));
      await laisser(tester);
      expect(port.envois, isEmpty);
      expect(find.text(t.suiviAttente.mePresenter.vide), findsOneWidget);
    });

    testWidgets('aucune famille ne peut recevoir : etat vide', (
      WidgetTester tester,
    ) async {
      await _presenter(
        tester,
        _portMessages(conversations: const <ConversationPossible>[]),
      );
      expect(find.text(t.suiviAttente.mePresenter.aucune), findsOneWidget);
      expect(_cle('presenter-envoyer'), findsNothing);
    });

    testWidgets('lecture en erreur : on le dit, on peut reessayer', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = _portMessages()
        ..erreurConversations = Exception('panne');
      await _presenter(tester, port);
      expect(find.text(t.suiviAttente.mePresenter.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets(
      'echec partiel : on le dit, et le nouvel essai garde la meme cle',
      (WidgetTester tester) async {
        final _PortEchecUneFois port = _PortEchecUneFois(_portMessages());
        await _presenter(tester, port.interne, titre: 'sayyid');
        // On remplace le port par le double qui echoue une fois.
        await monterRecrutement(
          tester,
          chemin: '/enseignant/classes/:groupeId/presentation',
          depart: '/enseignant/classes/$_groupe/presentation',
          ecran: (s) =>
              MePresenterPage(groupeId: s.pathParameters['groupeId']!),
          autres: <String>['/enseignant/classes'],
          surcharges: _surchargesPresenter(port),
        );
        await tester.tap(_cle('presenter-envoyer'));
        await laisser(tester);
        expect(find.text(t.suiviAttente.mePresenter.echec), findsOneWidget);
        expect(_cle('presenter-envoyer'), findsOneWidget);
        await tester.ensureVisible(_cle('presenter-envoyer'));
        await tester.tap(_cle('presenter-envoyer'));
        await laisser(tester);
        expect(
          find.text(t.suiviAttente.mePresenter.envoye(n: 2)),
          findsOneWidget,
        );
        // La famille « a », deja servie au premier essai, n'est pas renvoyee :
        // chaque famille recoit le message une seule fois.
        expect(port.envois.map((e) => e.$1).toList()..sort(), <String>[
          'fil-a',
          'fil-b',
        ]);
      },
    );

    for (final (String nom, double largeur, double echelle)
        in <(String, double, double)>[
          ('320 px, texte x2', 320, 2),
          ('1440 px', 1440, 1),
        ]) {
      testWidgets('$nom : aucun debordement, aucun mot coupe', (
        WidgetTester tester,
      ) async {
        await _presenter(
          tester,
          _portMessages(),
          largeur: largeur,
          echelle: echelle,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        verifierEcranSansMotCoupe(
          tester,
          exceptions: <String>{
            messagePresentation(
              titre: 'sayyid',
              nom: 'Ibrahim',
              classe: 'Classe Al-Fatiha',
            ),
          },
        );
      });
    }
  });

  group('l\'entree dans Mes classes', () {
    Future<void> entree(
      WidgetTester tester, {
      required List<Override> surcharges,
    }) => monterRecrutement(
      tester,
      chemin: '/enseignant/classes',
      ecran: (_) => const Scaffold(
        body: SingleChildScrollView(child: EntreePresentationClasses()),
      ),
      autres: <String>['/enseignant/classes/:groupeId/presentation'],
      surcharges: surcharges,
    );

    testWidgets('une classe recente : la ligne ouvre « Me presenter »', (
      WidgetTester tester,
    ) async {
      await entree(tester, surcharges: _surchargesPresenter(_portMessages()));
      expect(_cle('presenter-ligne-$_groupe'), findsOneWidget);
      await tester.tap(_cle('presenter-ligne-$_groupe'));
      await laisser(tester);
      expect(
        find.text('temoin:/enseignant/classes/:groupeId/presentation'),
        findsOneWidget,
      );
    });

    testWidgets('une classe de plus de 30 jours : rien', (
      WidgetTester tester,
    ) async {
      await entree(
        tester,
        surcharges: _surchargesPresenter(
          _portMessages(),
          classes: <GroupeEnseignant>[
            _classe(
              creeLe: DateTime.now().subtract(
                const Duration(minutes: 60 * 24 * 40),
              ),
            ),
          ],
        ),
      );
      expect(_cle('presenter-ligne-$_groupe'), findsNothing);
    });

    testWidgets(
      'Messages pas branches : rien (aucun bouton qui ne peut aboutir)',
      (WidgetTester tester) async {
        await entree(
          tester,
          surcharges: <Override>[
            groupesEnseignantProvider.overrideWith(
              (Ref _) async => <GroupeEnseignant>[_classe()],
            ),
          ],
        );
        expect(_cle('presenter-ligne-$_groupe'), findsNothing);
      },
    );
  });
}

/// Un port qui echoue au premier envoi de la famille « b », puis reussit.
class _PortEchecUneFois extends FauxMessagesMetier {
  _PortEchecUneFois(FauxMessagesMetier base)
    : interne = base,
      super(
        fils: <FilMetier>[
          filSimple(id: 'fil-a'),
          filSimple(id: 'fil-b'),
        ],
        conversations: base.conversations,
        filsParConversation: base.filsParConversation,
      );

  final FauxMessagesMetier interne;
  bool _dejaEchoue = false;

  @override
  Future<void> envoyer(String filId, String texte, String cle) async {
    if (filId == 'fil-b' && !_dejaEchoue) {
      _dejaEchoue = true;
      throw StateError('coupure');
    }
    await super.envoyer(filId, texte, cle);
  }
}
