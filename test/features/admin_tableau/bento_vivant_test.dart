// VIVANT : le haut de l'accueil de la direction en bento vivant.
//
// Donnees reelles uniquement : une case sans lecture ne s'affiche pas. Une
// case qui porte un nombre ouvre la liste deja filtree, a son adresse (contrat de
// navigation §2). La phrase de Praxis suit des regles ecrites.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/creneaux_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/vivant/niveau_eau.dart';
import 'package:rewayah_academy/core/vivant/praxis_vivant.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/admin_tableau/activite_recente.dart';
import 'package:rewayah_academy/features/admin_tableau/bento_vivant.dart';
import 'package:rewayah_academy/features/admin_tableau/dernier_non_lu.dart';
import 'package:rewayah_academy/features/admin_tableau/phrase_praxis.dart';
import 'package:rewayah_academy/features/admin_tableau/pile_pieces.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/alertes/section_alertes.dart';
import 'package:rewayah_academy/features/com_messages/non_lus_messages.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

final DateTime _maintenant = DateTime(2026, 11, 20, 9);

AttentesRecrutement _attentes({int creneaux = 0}) => AttentesRecrutement(
  parEtat: <EtatCandidature, Attente>{
    EtatCandidature.aCompleter: Attente(
      nombre: 40,
      plusAncien: DateTime(2026, 11, 2, 9),
    ),
    EtatCandidature.enExamen: Attente(
      nombre: 12,
      plusAncien: DateTime(2026, 11, 17, 9),
    ),
    EtatCandidature.entretienAPlanifier: Attente(
      nombre: 5,
      plusAncien: DateTime(2026, 11, 18, 9),
    ),
  },
  pieceAValider: Attente(nombre: 3, plusAncien: DateTime(2026, 11, 19, 9)),
  creneauxOuverts: creneaux,
);

const IndicateursAdmin _indicateurs = IndicateursAdmin(
  dossiersEnAttente: 0,
  foyersSansEnseignant: 2,
  rapportsManquants: 1,
  incidents24h: 0,
  comptesEchus: 0,
  demandesEnAttente: 4,
);

/// Une page de la liste des candidatures : des personnes fictives, avec leur
/// derniere activite (en jours avant [_maintenant]).
PageCandidatures _pageListe(
  List<(String, String, int)> personnes, {
  int? total,
}) => PageCandidatures.depuisJson(<String, Object?>{
  'total': total ?? personnes.length,
  'page': 1,
  'taillePage': 50,
  'lignes': <Object?>[
    for (final (String ref, String nom, int jours) in personnes)
      <String, Object?>{
        'id': 'id-$ref',
        'reference': ref,
        'nomComplet': nom,
        'issue': 'en_cours',
        'paysResidence': 'GN',
        'derniereActivite': _maintenant
            .subtract(Duration(days: jours))
            .toUtc()
            .toIso8601String(),
      },
  ],
});

/// Les trois personnes de la file des pieces, dans l'ordre du serveur
/// (PE-LISTE-CANDIDATURES : tri `ancienne`, la plus ancienne activite
/// d'abord).
const List<(String, String, int)> _troisPieces = <(String, String, int)>[
  ('RA-26-6031', 'Essai Modele', 3),
  ('RA-26-5920', 'Exemple Fictif', 1),
  ('RA-26-4817', 'Personne De Test', 0),
];

List<Override> _surcharges({
  AttentesRecrutement? attentes,
  EtatFileCourriels? courriels,
  int messages = 0,
  IndicateursAdmin indicateurs = _indicateurs,
  List<(String, String, int)> pieces = _troisPieces,
  int? totalPieces,
  Map<EtatCandidature, PageCandidatures> files =
      const <EtatCandidature, PageCandidatures>{},
  FauxServiceJournal? journal,
  List<DossierAValider> dossiers = const <DossierAValider>[],
}) => <Override>[
  serviceAdminProvider.overrideWithValue(
    FauxServiceAdmin()..indicateursRendus = indicateurs,
  ),
  serviceValidationProvider.overrideWithValue(
    FauxServiceValidation()..file = dossiers,
  ),
  if (journal != null) serviceJournalProvider.overrideWithValue(journal),
  if (attentes != null) ...<Override>[
    attentesRecrutementProvider.overrideWith((_) async => attentes),
    // Deux creneaux libres demain, un reserve apres-demain (qui ne compte
    // pas), aucun les autres jours.
    creneauxDirectionProvider.overrideWith(
      (_) async => <CreneauDirection>[
        for (final (int, int, EtatCreneau) c in <(int, int, EtatCreneau)>[
          (1, 10, EtatCreneau.libre),
          (1, 15, EtatCreneau.libre),
          (2, 10, EtatCreneau.reserve),
        ])
          CreneauDirection(
            id: 'c${c.$1}-${c.$2}',
            cote: 'male',
            debut: DateTime(2026, 11, 20 + c.$1, c.$2),
            fin: DateTime(2026, 11, 20 + c.$1, c.$2 + 1),
            langues: const <String>['fr'],
            participants: 1,
            fondateurs: 1,
            etat: c.$3,
          ),
      ],
    ),
    pageCandidaturesProvider(requetePieces)
        .overrideWith((_) async => _pageListe(pieces, total: totalPieces)),
    for (final MapEntry<EtatCandidature, PageCandidatures> f in files.entries)
      pageCandidaturesProvider(requeteEtat(f.key))
          .overrideWith((_) async => f.value),
  ],
  dernierNonLuProvider.overrideWith(
    (_) async => messages > 0 ? ('Personne De Test', 'Premiere ligne') : null,
  ),
  if (courriels != null)
    etatFileCourrielsProvider.overrideWith((_) async => courriels),
  nonLusMessagesProvider.overrideWith((_) async => messages),
];

/// Les dossiers d'identite de la capture : deux enseignants fictifs.
List<DossierAValider> _dossiersCapture() => <DossierAValider>[
  for (final (String, String, int) d in <(String, String, int)>[
    ('d1', 'Exemple', 6),
    ('d2', 'Essai', 2),
  ])
    DossierAValider(
      documentId: d.$1,
      profilId: 'p-${d.$1}',
      type: TypePiece.carteIdentite,
      cleObjet: 'p/${d.$1}.webp',
      deposeLe: _maintenant.subtract(Duration(days: d.$3)),
      prenom: d.$2,
      nom: 'Fictif',
      identifiantImmuable: 'TEACHER-EF-00000${d.$3}',
      role: AppRole.teacher,
    ),
];

/// Le journal de la capture : trois changements recents.
FauxServiceJournal _journalCapture() => FauxServiceJournal()
  ..entreesEnBase = <EntreeJournal>[
    for (final (int, String, String?, int) e in <(int, String, String?, int)>[
      (3, 'kyc_decision', 'Exemple Fictif', 1),
      (2, 'demande_creee', 'Essai Modele', 3),
      (1, 'regle_posee', null, 20),
    ])
      EntreeJournal(
        id: e.$1,
        survenuLe: _maintenant.subtract(Duration(hours: e.$4)),
        typeEvenement: e.$2,
        tableVisee: 'profiles',
        acteur: e.$3 == null ? null : 'a${e.$1}',
        nomActeur: e.$3,
        details: const <String, dynamic>{},
      ),
  ];

/// Les files des etats de la capture, lues en entier (cinq et douze
/// personnes) : leurs plus anciens ont un visage.
Map<EtatCandidature, PageCandidatures> _filesCapture() =>
    <EtatCandidature, PageCandidatures>{
      EtatCandidature.enExamen: _pageListe(<(String, String, int)>[
        for (int i = 0; i < 12; i++)
          ('RA-26-70${10 + i}', _noms[i % _noms.length], i),
      ]),
      EtatCandidature.entretienAPlanifier: _pageListe(<(String, String, int)>[
        for (int i = 0; i < 5; i++)
          ('RA-26-80${10 + i}', _noms[(i + 3) % _noms.length], i),
      ]),
    };

const List<String> _noms = <String>[
  'Personne De Test',
  'Exemple Fictif',
  'Essai Modele',
  'Candidat Type',
  'Dossier Demo',
  'Nom Invente',
];

Future<void> _vivre(WidgetTester tester, [int images = 40]) async {
  for (int i = 0; i < images; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _page() => TableauDeBordPage(horloge: () => _maintenant);

/// La page dans un routeur minimal : toute autre adresse s'affiche en texte.
Widget _routant(List<Override> surcharges) => hoteRoutant(
  depart: '/',
  surcharges: surcharges,
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (_, _) => _page()),
    GoRoute(
      path: '/admin/:reste(.*)',
      builder: (_, GoRouterState etat) =>
          Scaffold(body: Text('ALLE ${etat.uri}')),
    ),
  ],
);

void main() {
  group('PhrasePraxis : les regles', () {
    test('des entretiens a planifier sans creneau passent avant tout', () {
      final PhrasePraxis p = PhrasePraxis.depuis(
        calme: false,
        entretiensAPlanifier: 5,
        creneauxOuverts: 0,
        pieces: 30,
        demandes: 50,
      );
      expect(p, const PhrasePraxis(SujetPraxis.creneaux, 5));
      expect(p.humeur, HumeurPraxis.soucieux);
      expect(p.texte, t.admin.tableau.vivant.praxisCreneaux(n: 5));
    });

    test('avec un creneau ouvert, la plus grande file parle', () {
      expect(
        PhrasePraxis.depuis(
          calme: false,
          entretiensAPlanifier: 5,
          creneauxOuverts: 2,
          pieces: 3,
          dossiers: 1,
          demandes: 9,
          messages: 4,
        ),
        const PhrasePraxis(SujetPraxis.demandes, 9),
      );
    });

    test('a egalite : pieces, dossiers, demandes, messages', () {
      expect(
        PhrasePraxis.depuis(
          calme: false,
          pieces: 2,
          dossiers: 2,
          demandes: 2,
          messages: 2,
        ).sujet,
        SujetPraxis.pieces,
      );
    });

    test('creneaux non lus : jamais le blocage des creneaux', () {
      expect(
        PhrasePraxis.depuis(calme: false, entretiensAPlanifier: 5).sujet,
        SujetPraxis.silence,
      );
    });

    test('rien ne bloque : il le dit', () {
      final PhrasePraxis p = PhrasePraxis.depuis(
        calme: true,
        pieces: 0,
        dossiers: 0,
        demandes: 0,
        messages: 0,
      );
      expect(p.sujet, SujetPraxis.calme);
      expect(p.texte, t.admin.tableau.calme);
      expect(p.humeur, HumeurPraxis.heureux);
    });

    test('autre chose attend ailleurs : il se tait', () {
      final PhrasePraxis p = PhrasePraxis.depuis(calme: false, demandes: 0);
      expect(p.sujet, SujetPraxis.silence);
      expect(p.texte, isNull);
    });
  });

  group('Adresses filtrees', () {
    test('un etat : en cours, hors pause, dans l adresse', () {
      final Uri u = Uri.parse(
        adresseCandidaturesFiltree(filtreEtat(EtatCandidature.enExamen)),
      );
      expect(u.path, Routes.adminPersonnesCandidatures);
      expect(u.queryParameters, <String, String>{
        'etat': 'enExamen',
        'issue': 'enCours',
        'pause': 'non',
      });
    });

    test('les pieces a valider', () {
      final Uri u = Uri.parse(adresseCandidaturesFiltree(filtrePieces));
      expect(u.queryParameters, <String, String>{
        'issue': 'enCours',
        'pause': 'non',
        'piece': 'oui',
      });
    });
  });

  group('Tableau de bord : le bento vivant', () {
    testWidgets('sans lecture du recrutement : Praxis seul, aucune case '
        'inventee', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(hote(_page(), surcharges: _surcharges()));
      await _vivre(tester);
      expect(find.byKey(BentoVivant.cleHeros), findsOneWidget);
      expect(find.byType(PraxisVivant), findsOneWidget);
      expect(find.byKey(BentoVivant.clePieces), findsNothing);
      expect(find.byKey(BentoVivant.cleMessages), findsNothing);
      expect(find.byKey(BentoVivant.cleCourriels), findsNothing);
      expect(find.byType(ParcoursCandidats), findsNothing);
      expect(find.byType(NiveauEau), findsNothing);
      // 4 demandes a trancher : la plus grande file lue.
      expect(
        find.text(t.admin.tableau.vivant.praxisDemandes(n: 4)),
        findsOneWidget,
      );
      expect(find.text(t.admin.tableau.vivant.bonjour), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('avec les lectures : chaque case porte son vrai nombre', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(
            attentes: _attentes(),
            courriels: const EtatFileCourriels(
              parJour: 900,
              partis24h: 412,
              enAttente: 0,
              joursEstimes: 0,
            ),
            messages: 7,
          ),
        ),
      );
      await _vivre(tester);
      Finder dans(Key cle, String texte) =>
          find.descendant(of: find.byKey(cle), matching: find.text(texte));
      expect(dans(BentoVivant.clePieces, '3'), findsOneWidget);
      expect(dans(BentoVivant.cleMessages, '7'), findsOneWidget);
      expect(dans(BentoVivant.cleCourriels, '412'), findsOneWidget);
      expect(
        dans(
          BentoVivant.cleCourriels,
          t.admin.tableau.vivant.courrielsSur(max: 900),
        ),
        findsOneWidget,
      );
      expect(
        dans(BentoVivant.cleEtat(EtatCandidature.aCompleter), '40'),
        findsOneWidget,
      );
      expect(
        dans(BentoVivant.cleEtat(EtatCandidature.enExamen), '12'),
        findsOneWidget,
      );
      // Etat sans personne : un zero lu, jamais absent.
      expect(
        dans(BentoVivant.cleEtat(EtatCandidature.entretienPlanifie), '0'),
        findsOneWidget,
      );
      // Le blocage : 5 entretiens a planifier, aucun creneau. Dit par
      // Praxis et par la case, avec des mots (jamais la couleur seule).
      expect(
        find.text(t.admin.tableau.vivant.praxisCreneaux(n: 5)),
        findsOneWidget,
      );
      expect(
        dans(
          BentoVivant.cleEtat(EtatCandidature.entretienAPlanifier),
          t.admin.candidatures.attentes.aucunCreneau,
        ),
        findsOneWidget,
      );
      // Large comme son groupe : 40 personnes prennent plus de place que 12.
      expect(
        tester
            .getSize(
              find.byKey(BentoVivant.cleEtat(EtatCandidature.aCompleter)),
            )
            .width,
        greaterThan(
          tester
              .getSize(
                find.byKey(BentoVivant.cleEtat(EtatCandidature.enExamen)),
              )
              .width,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('rien ne bloque : Praxis le dit, une seule fois', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(
            indicateurs: const IndicateursAdmin(
              dossiersEnAttente: 0,
              foyersSansEnseignant: 0,
              rapportsManquants: 0,
              incidents24h: 0,
              comptesEchus: 0,
              demandesEnAttente: 0,
            ),
          ),
        ),
      );
      await _vivre(tester);
      expect(find.text(t.admin.tableau.calme), findsOneWidget);
    });

    testWidgets('compteurs en erreur : la phrase et « Reessayer », pas de '
        'Praxis qui parlerait sans chiffres', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: <Override>[
            serviceAdminProvider.overrideWithValue(
              FauxServiceAdmin()..erreurIndicateurs = StateError('panne'),
            ),
            serviceValidationProvider.overrideWithValue(
              FauxServiceValidation(),
            ),
            nonLusMessagesProvider.overrideWith((_) async => 0),
          ],
        ),
      );
      await _vivre(tester);
      expect(find.byType(BentoVivant), findsNothing);
      expect(find.text(t.admin.tableau.compteursErreur), findsOneWidget);
    });

    for (final (Key, String, String) cas in <(Key, String, String)>[
      (
        // La carte du dessus : la plus ancienne de la file, lue en entier.
        CasePieces.cleCarte,
        'carte de la pile (le dossier de la personne, dans sa file)',
        '/admin/personnes/candidatures/RA-26-6031?issue=enCours&pause=non&piece=oui&depuis=liste',
      ),
      (
        CasePieces.cleNombre,
        'nombre des pieces (la file)',
        '/admin/personnes/candidatures?issue=enCours&pause=non&piece=oui',
      ),
      (
        BentoVivant.cleEtat(EtatCandidature.enExamen),
        'etat en examen',
        '/admin/personnes/candidatures?etat=enExamen&issue=enCours&pause=non',
      ),
      (BentoVivant.cleMessages, 'messages', Routes.adminCommunicationsMessages),
      (BentoVivant.cleCourriels, 'courriels', Routes.adminOperationsCourriels),
      (BentoVivant.cleDossiers, 'dossiers', Routes.adminPersonnesDossiers),
      (BentoVivant.cleDemandes, 'demandes', Routes.adminOperationsDemandes),
      (BentoVivant.cleEleves, 'eleves', Routes.adminOperationsRegroupements),
      (BentoVivant.cleCahiers, 'cahiers', Routes.adminPedagogieQualite),
      (
        BentoVivant.cleIncidents,
        'incidents',
        Routes.adminSecuriteAuditIncidents,
      ),
      (BentoVivant.cleEchus, 'acces echus', Routes.adminPersonnesComptesEchus),
    ]) {
      testWidgets('toucher la case ${cas.$2} ouvre ${cas.$3}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 1600), 1);
        await tester.pumpWidget(
          _routant(
            _surcharges(
              attentes: _attentes(),
              courriels: const EtatFileCourriels(
                parJour: 900,
                partis24h: 412,
                enAttente: 0,
                joursEstimes: 0,
              ),
              messages: 7,
            ),
          ),
        );
        await _vivre(tester);
        await tester.ensureVisible(find.byKey(cas.$1));
        await _vivre(tester, 5);
        await tester.tap(find.byKey(cas.$1));
        await _vivre(tester, 10);
        expect(find.text('ALLE ${cas.$3}'), findsOneWidget);
        // L'adresse du routeur dit la page et son filtre : un rechargement
        // rend le meme ecran (contrat §5).
        final BuildContext contexte = tester.element(
          find.text('ALLE ${cas.$3}'),
        );
        expect(
          GoRouter.of(contexte).routerDelegate.currentConfiguration.uri
              .toString(),
          cas.$3,
        );
      });
    }

    testWidgets('les gestes de Praxis : creneaux, pieces, messages', (
      WidgetTester tester,
    ) async {
      final v = t.admin.tableau.vivant;
      for (final (String, String) cas in <(String, String)>[
        (v.ouvrirCreneaux, Routes.adminPersonnesCreneauxEntretien),
        (
          v.verifierPieces(n: 3),
          '/admin/personnes/candidatures?issue=enCours&pause=non&piece=oui',
        ),
        (v.repondreMessages(n: 7), Routes.adminCommunicationsMessages),
      ]) {
        fixerVueCapture(tester, const Size(1440, 1600), 1);
        await tester.pumpWidget(
          _routant(
            _surcharges(
              attentes: _attentes(),
              courriels: const EtatFileCourriels(
                parJour: 900,
                partis24h: 412,
                enAttente: 0,
                joursEstimes: 0,
              ),
              messages: 7,
            ),
          ),
        );
        await _vivre(tester);
        await tester.tap(find.text(cas.$1));
        await _vivre(tester, 10);
        expect(find.text('ALLE ${cas.$2}'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('la semaine des creneaux : sept jours, pleins seulement ou un '
        'creneau est libre', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(_page(), surcharges: _surcharges(attentes: _attentes())),
      );
      await _vivre(tester);
      for (int i = 0; i < 7; i++) {
        expect(find.byKey(BentoVivant.cleJour(i)), findsOneWidget);
      }
      Finder nombre(int jour, String n) => find.descendant(
        of: find.byKey(BentoVivant.cleJour(jour)),
        matching: find.text(n),
      );
      // Demain : deux creneaux libres. Apres-demain : un creneau reserve, qui
      // ne compte pas. Aujourd'hui : rien.
      expect(nombre(1, '2'), findsOneWidget);
      expect(nombre(2, '1'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.cleJour(0)),
          matching: find.byType(Text),
        ),
        findsOneWidget,
        reason: 'un jour vide ne porte que sa lettre',
      );
    });

    testWidgets('sans lecture du recrutement : ni semaine ni geste invente', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(hote(_page(), surcharges: _surcharges()));
      await _vivre(tester);
      expect(find.byKey(BentoVivant.cleJour(0)), findsNothing);
      expect(find.text(t.admin.tableau.vivant.ouvrirCreneaux), findsNothing);
      expect(find.byKey(BentoVivant.cleCadenas), findsNothing);
    });

    testWidgets('le cadenas ferme le passage tant qu aucun creneau n est '
        'ouvert', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(_page(), surcharges: _surcharges(attentes: _attentes())),
      );
      await _vivre(tester);
      final Rect cadenas = tester.getRect(find.byKey(BentoVivant.cleCadenas));
      expect(
        cadenas.left,
        greaterThanOrEqualTo(
          tester
              .getRect(
                find.byKey(
                  BentoVivant.cleEtat(EtatCandidature.entretienAPlanifier),
                ),
              )
              .right,
        ),
      );
      expect(
        cadenas.right,
        lessThanOrEqualTo(
          tester
              .getRect(
                find.byKey(
                  BentoVivant.cleEtat(EtatCandidature.entretienPlanifie),
                ),
              )
              .left,
        ),
      );
      // Ferme : il dit le blocage et mene la ou les creneaux s'ouvrent.
      expect(
        find.bySemanticsLabel(
          '${t.admin.candidatures.attentes.aucunCreneau} '
          '${t.admin.tableau.vivant.ouvrirCreneaux}',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(attentes: _attentes(creneaux: 2)),
        ),
      );
      await _vivre(tester);
      // Des creneaux existent : le cadenas reste, ouvert, et le dit avec des
      // mots (jamais la couleur seule) ; plus aucun geste « Ouvrir ».
      expect(find.byKey(BentoVivant.cleCadenas), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.cleCadenas),
          matching: find.bySemanticsLabel(
            t.admin.candidatures.attentes.creneauxOuverts(n: 2),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(t.admin.tableau.vivant.ouvrirCreneaux), findsNothing);
    });

    testWidgets('une seule page : ni titre d ecran ni liste de raccourcis sur '
        'ordinateur, aucun nombre affiche deux fois', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1800), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(
            attentes: _attentes(),
            courriels: const EtatFileCourriels(
              parJour: 900,
              partis24h: 412,
              enAttente: 0,
              joursEstimes: 0,
            ),
            messages: 7,
          ),
        ),
      );
      await _vivre(tester);
      expect(find.text(t.admin.tableau.titre), findsNothing);
      expect(find.text(t.admin.tableau.sousTitre), findsNothing);
      expect(find.text(t.admin.tableau.outilsTraitement), findsNothing);
      // Chaque libelle de compteur une fois, dans sa case.
      for (final (Key, String, String) cas in <(Key, String, String)>[
        (BentoVivant.cleDossiers, t.admin.tableau.dossiers, '0'),
        (BentoVivant.cleDemandes, t.admin.tableau.demandes, '4'),
        (BentoVivant.cleEleves, t.admin.tableau.foyers, '2'),
        (BentoVivant.cleCahiers, t.admin.tableau.rapports, '1'),
        (BentoVivant.cleIncidents, t.admin.tableau.incidents, '0'),
        (BentoVivant.cleEchus, t.admin.tableau.comptes, '0'),
      ]) {
        expect(find.text(cas.$2), findsOneWidget);
        expect(
          find.descendant(of: find.byKey(cas.$1), matching: find.text(cas.$3)),
          findsOneWidget,
        );
      }
      // La personne de la file des pieces, et le dernier message non lu.
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.clePieces),
          matching: find.text('Personne De Test'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.cleMessages),
          matching: find.text('Personne De Test · Premiere ligne'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ActiviteRecente), findsOneWidget);
      expect(find.text(t.admin.tableau.vivant.activiteTitre), findsOneWidget);
      expect(find.byKey(BentoVivant.cleDate), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('au telephone : les destinations sans autre entree restent, '
        'dans une case d outils ; plus de liste a part, pas de date', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(400, 4000), 1);
      await tester.pumpWidget(hote(_page(), surcharges: _surcharges()));
      await _vivre(tester);
      final Finder outils = find.byKey(BentoVivant.cleOutils);
      expect(outils, findsOneWidget);
      // Chaque destination d'avant a encore son entree, dans la case.
      for (final String libelle in <String>[
        t.admin.tableau.outilsTraitement,
        t.admin.tableau.outilsRegroupements,
        t.admin.tableau.outilsOffres,
        t.avis.admin.outil,
        t.courriels.admin.outil,
        t.admin.tableau.outilsPilotage,
        t.admin.tableau.outilsPlanning,
        t.admin.groupes.titre,
        t.com.socle.navigation.communications,
        t.admin.tableau.outilsComptes,
        t.admin.tableau.outilsAccesAgents,
      ]) {
        expect(
          find.descendant(of: outils, matching: find.text(libelle)),
          findsOneWidget,
          reason: libelle,
        );
      }
      // Plus de liste de reglages sous la grille, ni de descriptions.
      expect(find.byType(SettingRow), findsNothing);
      expect(find.text(t.admin.tableau.outilsTraitementDetail), findsNothing);
      expect(find.byKey(BentoVivant.cleDate), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('au telephone : les E-mails ne sont pas repetes dans les '
        'outils quand leur case est lue', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(400, 4000), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(
            courriels: const EtatFileCourriels(
              parJour: 900,
              partis24h: 412,
              enAttente: 0,
              joursEstimes: 0,
            ),
          ),
        ),
      );
      await _vivre(tester);
      expect(find.byKey(BentoVivant.cleCourriels), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.cleOutils),
          matching: find.text(t.courriels.admin.outil),
        ),
        findsNothing,
      );
    });

    testWidgets('sur ordinateur : ni case d outils ni section d alertes sans '
        'alerte (source absente)', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(_page(), surcharges: _surcharges(attentes: _attentes())),
      );
      await _vivre(tester);
      expect(find.byKey(BentoVivant.cleOutils), findsNothing);
      // La source des alertes n'est pas ouverte : rien sur l'accueil (la
      // page des alertes dit cet etat), jamais une carte « pas encore
      // disponibles ».
      expect(find.byType(SectionAlertes), findsNothing);
      expect(find.text(t.alertes.indisponibleTitre), findsNothing);
      expect(find.text(t.alertes.titre), findsNothing);
    });

    group('la pile des pieces', () {
      Future<void> monter(
        WidgetTester tester, {
        List<(String, String, int)> pieces = _troisPieces,
        int? total,
        int nombre = 3,
        bool routant = false,
      }) async {
        fixerVueCapture(tester, const Size(1440, 1600), 1);
        final List<Override> surcharges = _surcharges(
          attentes: AttentesRecrutement(
            pieceAValider: Attente(
              nombre: nombre,
              plusAncien: DateTime(2026, 11, 17, 9),
            ),
            creneauxOuverts: 2,
          ),
          pieces: pieces,
          totalPieces: total,
        );
        await tester.pumpWidget(
          routant
              ? _routant(surcharges)
              : hote(_page(), surcharges: surcharges),
        );
        await _vivre(tester);
      }

      Finder carte(String nom) => find.descendant(
        of: find.byKey(CasePieces.cleCarte),
        matching: find.text(nom),
      );

      testWidgets('la plus ancienne est sur le dessus (tri du serveur)', (
        WidgetTester tester,
      ) async {
        await monter(tester);
        // Le serveur rend la plus ancienne d'abord (tri `ancienne`) ; la pile
        // garde son ordre : 3 jours, puis 1 jour, puis aujourd'hui.
        expect(carte('Essai Modele'), findsOneWidget);
        expect(
          find.text(t.admin.tableau.vivant.piecePosition(rang: 1, total: 3)),
          findsOneWidget,
        );
        expect(find.text(t.admin.tableau.vivant.piecesAide), findsOneWidget);
      });

      testWidgets('file plus longue que la page lue : la plus ancienne reste '
          'dessus, le nombre est celui du serveur', (
        WidgetTester tester,
      ) async {
        await monter(tester, total: 80, nombre: 80);
        // PE-LISTE-CANDIDATURES : le serveur trie toute la file ; la premiere
        // page commence par les plus anciennes, quelle que soit sa longueur.
        expect(carte('Essai Modele'), findsOneWidget);
        expect(find.text(t.admin.tableau.vivant.piecesAide), findsOneWidget);
        // Le nombre est celui du serveur, pas celui des cartes lues.
        expect(
          find.descendant(
            of: find.byKey(CasePieces.cleNombre),
            matching: find.text('80'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('glisser la carte : la suivante monte, rien n est decide '
          'ni ouvert', (WidgetTester tester) async {
        await monter(tester, routant: true);
        await tester.drag(
          find.byKey(CasePieces.cleCarte),
          const Offset(200, 0),
        );
        await _vivre(tester, 30);
        expect(carte('Exemple Fictif'), findsOneWidget);
        expect(
          find.text(t.admin.tableau.vivant.piecePosition(rang: 2, total: 3)),
          findsOneWidget,
        );
        // Toujours sur l'accueil : feuilleter n'ouvre et ne decide rien.
        expect(find.textContaining('ALLE'), findsNothing);
        expect(find.byType(BentoVivant), findsOneWidget);
      });

      testWidgets('les fleches feuillettent aussi (clavier, lecteur d ecran)', (
        WidgetTester tester,
      ) async {
        await monter(tester);
        await tester.tap(
          find.bySemanticsLabel(t.admin.tableau.vivant.pieceSuivante),
        );
        await _vivre(tester, 30);
        expect(carte('Exemple Fictif'), findsOneWidget);
        await tester.tap(
          find.bySemanticsLabel(t.admin.tableau.vivant.piecePrecedente),
        );
        await _vivre(tester, 30);
        expect(carte('Essai Modele'), findsOneWidget);
      });

      testWidgets('toucher la carte ouvre le dossier de CETTE personne', (
        WidgetTester tester,
      ) async {
        await monter(tester, routant: true);
        await tester.drag(
          find.byKey(CasePieces.cleCarte),
          const Offset(-200, 0),
        );
        await _vivre(tester, 30);
        // La carte dit ce qu'elle ouvre, et pour qui.
        expect(
          find.bySemanticsLabel(
            RegExp(
              '^${RegExp.escape(t.admin.tableau.vivant.ouvrirDossierDe(deNom: "d'Exemple Fictif"))}',
            ),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(CasePieces.cleCarte));
        await _vivre(tester, 10);
        expect(
          find.text(
            'ALLE /admin/personnes/candidatures/RA-26-5920'
            '?issue=enCours&pause=non&piece=oui&tri=ancienne&depuis=liste',
          ),
          findsOneWidget,
        );
      });

      testWidgets('une seule piece : la carte, sans fleches', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          pieces: const <(String, String, int)>[
            ('RA-26-4817', 'Personne De Test', 0),
          ],
          nombre: 1,
        );
        expect(carte('Personne De Test'), findsOneWidget);
        expect(
          find.bySemanticsLabel(t.admin.tableau.vivant.pieceSuivante),
          findsNothing,
        );
        expect(find.text(t.admin.tableau.vivant.pieceAide), findsOneWidget);
      });

      testWidgets('aucune piece : le zero et une phrase, pas de pile', (
        WidgetTester tester,
      ) async {
        await monter(tester, nombre: 0);
        expect(find.byKey(CasePieces.cleCarte), findsNothing);
        expect(find.text(t.admin.tableau.vivant.piecesVide), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(CasePieces.cleNombre),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
      });
    });

    group('les visages du parcours', () {
      testWidgets('les trois premieres lignes de la file triee par anciennete '
          'ont un visage, quel que soit le nombre ; une file non lue n en a '
          'pas', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(1440, 1600), 1);
        await tester.pumpWidget(
          hote(
            _page(),
            surcharges: _surcharges(
              attentes: _attentes(),
              files: <EtatCandidature, PageCandidatures>{
                // Quatre personnes, dans l'ordre du serveur (la plus ancienne
                // d'abord) : les trois premieres ont un visage.
                EtatCandidature.enExamen: _pageListe(<(String, String, int)>[
                  ('RA-26-7002', 'Ancienne Fictive', 9),
                  ('RA-26-7003', 'Milieu Fictif', 4),
                  ('RA-26-7004', 'Autre Fictif', 2),
                  ('RA-26-7001', 'Recente Fictive', 0),
                ]),
                // Quarante personnes, la page n'en rend que deux : le serveur
                // a trie toute la file, ce sont les deux plus anciennes ;
                // elles ont un visage (avant le tri du serveur, aucune).
                EtatCandidature.aCompleter: _pageListe(<(String, String, int)>[
                  ('RA-26-7101', 'Page Une', 30),
                  ('RA-26-7102', 'Page Deux', 20),
                ], total: 40),
              },
            ),
          ),
        );
        await _vivre(tester);
        final Finder visages = find.byKey(
          ParcoursCandidats.cleVisages(EtatCandidature.enExamen),
        );
        expect(visages, findsOneWidget);
        expect(
          <String>[
            for (final AvatarNom a in tester.widgetList<AvatarNom>(
              find.descendant(of: visages, matching: find.byType(AvatarNom)),
            ))
              a.prenom,
          ]..sort(),
          <String>['Ancienne Fictive', 'Autre Fictif', 'Milieu Fictif'],
        );
        final Finder visagesLongs = find.byKey(
          ParcoursCandidats.cleVisages(EtatCandidature.aCompleter),
        );
        expect(visagesLongs, findsOneWidget);
        expect(
          <String>[
            for (final AvatarNom a in tester.widgetList<AvatarNom>(
              find.descendant(
                of: visagesLongs,
                matching: find.byType(AvatarNom),
              ),
            ))
              a.prenom,
          ],
          <String>['Page Une', 'Page Deux'],
        );
        expect(
          find.byKey(
            ParcoursCandidats.cleVisages(EtatCandidature.entretienAPlanifier),
          ),
          findsNothing,
          reason: 'file non lue : aucun visage invente',
        );
      });
    });

    testWidgets('« Ce qui a changé » en echec : une phrase calme et '
        '« Réessayer », jamais l encre d alerte', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      final FauxServiceJournal journal = FauxServiceJournal()
        ..erreurEntrees = StateError('panne');
      await tester.pumpWidget(
        hote(_page(), surcharges: _surcharges(journal: journal)),
      );
      await _vivre(tester);
      final Text phrase = tester.widget<Text>(
        find.byKey(ActiviteRecente.cleEchec),
      );
      expect(phrase.data, t.admin.tableau.activite.erreur);
      final BuildContext contexte = tester.element(
        find.byKey(ActiviteRecente.cleEchec),
      );
      final AppPalette palette = AppPalette.of(contexte);
      expect(
        phrase.style?.color,
        palette.inkMuted.applyTo(const TextStyle()).color,
      );
      expect(
        phrase.style?.color,
        isNot(palette.inkAlert.applyTo(const TextStyle()).color),
      );
      // « Réessayer » relit ; les cases gardent leurs nombres.
      journal.erreurEntrees = null;
      await tester.tap(find.text(t.commun.reessayer));
      await _vivre(tester, 10);
      expect(find.byKey(ActiviteRecente.cleEchec), findsNothing);
      expect(find.text(t.admin.tableau.activite.vide), findsOneWidget);
    });

    testWidgets('Praxis est entier, assis sur le bord de sa case, et parle '
        'tant que sa phrase s ecrit', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(_page(), surcharges: _surcharges(attentes: _attentes())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      await tester.pump(const Duration(milliseconds: 32));
      PraxisVivant praxis() =>
          tester.widget<PraxisVivant>(find.byType(PraxisVivant));
      expect(praxis().assis, isTrue);
      expect(praxis().parle, isTrue, reason: 'la phrase s ecrit');
      await _vivre(tester);
      expect(praxis().parle, isFalse, reason: 'la phrase est ecrite');
      // La ligne d'assise de son dessin est le bord haut de la case.
      final Rect heros = tester.getRect(find.byKey(BentoVivant.cleHeros));
      final Rect corps = tester.getRect(find.byType(PraxisVivant));
      expect(
        corps.top + PraxisVivant.assisePour(praxis().taille),
        closeTo(heros.top, 0.5),
      );
      // Ses pieds pendent sous le bord.
      expect(corps.bottom, greaterThan(heros.top + 16));
      expect(praxis().humeur, HumeurPraxis.soucieux);
    });

    testWidgets('« Reduire les effets » : plus aucun mouvement, toute '
        'l information reste', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        EffetsReduits(
          actifs: true,
          child: hote(
            _page(),
            surcharges: _surcharges(
              attentes: _attentes(),
              courriels: const EtatFileCourriels(
                parJour: 900,
                partis24h: 412,
                enAttente: 0,
                joursEstimes: 0,
              ),
              messages: 7,
            ),
          ),
        ),
      );
      await _vivre(tester, 10);
      expect(
        SchedulerBinding.instance.transientCallbackCount,
        0,
        reason: 'ni eau, ni points, ni Praxis : aucun ticker',
      );
      // La phrase est la, entiere ; les nombres, le cadenas et l'eau aussi.
      expect(
        find.text(t.admin.tableau.vivant.praxisCreneaux(n: 5)),
        findsOneWidget,
      );
      expect(find.byKey(BentoVivant.cleCadenas), findsOneWidget);
      expect(find.byType(NiveauEau), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.cleEtat(EtatCandidature.aCompleter)),
          matching: find.text('40'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    for (final (double, String) cas in <(double, String)>[
      (1440, 'quatre colonnes'),
      (820, 'deux colonnes'),
      (400, 'une colonne'),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas.$1.round()} points, ${sens.name} : ${cas.$2}, '
            'rien ne deborde', (WidgetTester tester) async {
          fixerVueCapture(tester, Size(cas.$1, 4200), 1);
          await tester.pumpWidget(
            hoteRoutant(
              depart: '/',
              direction: sens,
              surcharges: _surcharges(
                attentes: _attentes(),
                courriels: const EtatFileCourriels(
                  parJour: 900,
                  partis24h: 412,
                  enAttente: 0,
                  joursEstimes: 0,
                ),
                messages: 7,
              ),
              routes: <RouteBase>[
                GoRoute(path: '/', builder: (_, _) => _page()),
              ],
            ),
          );
          await _vivre(tester);
          expect(tester.takeException(), isNull);
          final Rect heros = tester.getRect(find.byKey(BentoVivant.cleHeros));
          final Rect pieces = tester.getRect(find.byKey(BentoVivant.clePieces));
          if (cas.$1 >= 1440) {
            // Meme rang ; la grille se retourne en arabe.
            expect(pieces.top, heros.top);
            if (sens == TextDirection.ltr) {
              expect(pieces.left, greaterThan(heros.right));
            } else {
              expect(pieces.right, lessThan(heros.left));
            }
          } else {
            expect(pieces.top, greaterThanOrEqualTo(heros.bottom));
          }
          // Praxis est assis sur le bord de sa case, du cote de la fin.
          final Rect praxis = tester.getRect(find.byType(PraxisVivant));
          expect(praxis.top, lessThan(heros.top));
          expect(praxis.bottom, greaterThan(heros.top));
          if (sens == TextDirection.ltr) {
            expect(praxis.center.dx, greaterThan(heros.center.dx));
          } else {
            expect(praxis.center.dx, lessThan(heros.center.dx));
          }
        });
      }
    }
  });

  group(
    'Capture : PE-VIVANT accueil de la direction',
    skip: sautSansCapture,
    () {
      setUpAll(() async {
        await chargerPolicesDuDepot();
        // L'arabe est charge a la demande : une fois ici, hors du temps
        // simule d'un test.
        await LocaleSettings.setLocale(AppLocale.ar);
        LocaleSettings.setLocaleSync(AppLocale.fr);
      });
      tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      for (final (Size, ThemeMode, AppLocale, String) cas
          in <(Size, ThemeMode, AppLocale, String)>[
            (
              const Size(1440, 1500),
              ThemeMode.light,
              AppLocale.fr,
              'accueil_1440_clair',
            ),
            (
              const Size(1440, 1500),
              ThemeMode.dark,
              AppLocale.fr,
              'accueil_1440_sombre',
            ),
            (
              const Size(820, 2300),
              ThemeMode.light,
              AppLocale.fr,
              'accueil_820_clair',
            ),
            (
              const Size(820, 2300),
              ThemeMode.dark,
              AppLocale.fr,
              'accueil_820_sombre',
            ),
            (
              const Size(400, 3900),
              ThemeMode.light,
              AppLocale.fr,
              'accueil_400_clair',
            ),
            (
              const Size(400, 3900),
              ThemeMode.dark,
              AppLocale.fr,
              'accueil_400_sombre',
            ),
            (
              const Size(400, 3900),
              ThemeMode.light,
              AppLocale.ar,
              'accueil_400_arabe',
            ),
          ]) {
        testWidgets(cas.$4, (WidgetTester tester) async {
          LocaleSettings.setLocaleSync(cas.$3);
          fixerVueCapture(tester, cas.$1, 1);
          await tester.pumpWidget(
            hoteCapture(
              _page(),
              themeMode: cas.$2,
              surcharges: _surcharges(
                attentes: _attentes(),
                courriels: const EtatFileCourriels(
                  parJour: 900,
                  partis24h: 412,
                  enAttente: 0,
                  joursEstimes: 0,
                ),
                messages: 7,
                files: _filesCapture(),
                journal: _journalCapture(),
                dossiers: _dossiersCapture(),
                indicateurs: const IndicateursAdmin(
                  dossiersEnAttente: 2,
                  foyersSansEnseignant: 2,
                  rapportsManquants: 1,
                  incidents24h: 0,
                  comptesEchus: 0,
                  demandesEnAttente: 4,
                ),
              ),
            ),
          );
          // Assez d'images pour que Praxis soit pose, la phrase ecrite et
          // qu'aucun clin d'oeil ne soit en cours.
          await _vivre(tester, 80);
          debugPrint('PNG ${await capturer(tester, cas.$4)}');
        });
      }
    },
  );
}
