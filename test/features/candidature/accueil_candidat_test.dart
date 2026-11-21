// ACCUEIL-CANDIDAT (PARCOURS-ENSEIGNANT, vague 2 ; directeur, 19 et
// 20/11/2026) : l'accueil du candidat enseignant.
//
// PE-B4 : trois onglets (Dossier, Messages, Academie), l'onglet dans
// l'adresse, l'annonce en une ligne qui se ferme puis reste rangee dans
// Academie. PE-B5 : la ligne d'etapes, UN seul « a faire maintenant », « rien
// a faire », les lignes qui se deplient. PE-A6 : l'ecran qui explique le
// retrait, puis la reprise pendant 7 jours.
//
// Captures (sautees sans CAPTURE_DIR) :
// CAPTURE_DIR=docs/current/captures/E2E flutter test --no-pub
//   test/features/candidature/accueil_candidat_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/ma_candidature_fil.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/features/candidature/a_savoir_candidat.dart';
import 'package:rewayah_academy/features/candidature/accueil_candidat.dart';
import 'package:rewayah_academy/features/candidature/annonces_candidat.dart';
import 'package:rewayah_academy/features/candidature/carte_reprise.dart';
import 'package:rewayah_academy/features/candidature/ligne_etapes.dart';
import 'package:rewayah_academy/features/candidature/messages_candidat.dart';
import 'package:rewayah_academy/features/candidature/onglet_academie.dart';
import 'package:rewayah_academy/features/candidature/onglet_dossier.dart';
import 'package:rewayah_academy/features/candidature/portail_candidature.dart';
import 'package:rewayah_academy/features/candidature/reprise_candidature.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_recues.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces_direction.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/com_messages/fil_en_place.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../com_messages/support_messages.dart';
import 'hote_candidature.dart';

Finder _texte(String t) => find.text(t);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Touche [f] apres l'avoir amene a l'ecran (la barre du bas peut le couvrir).
Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Un fil d'annonces en memoire, qui note les annonces comptees « vues ».
class _Fil extends AnnoncesDirectionIndisponibles {
  _Fil({
    this.recues = const <AnnonceRecue>[],
    this.erreur,
    this.jamais = false,
  });

  List<AnnonceRecue> recues;
  final Exception? erreur;

  /// Vrai : la lecture ne repond jamais (etat de chargement).
  final bool jamais;
  final List<String> vues = <String>[];

  @override
  Future<List<AnnonceRecue>> mesAnnonces() async {
    if (jamais) {
      return Future<List<AnnonceRecue>>.delayed(const Duration(days: 1));
    }
    final Exception? e = erreur;
    if (e != null) throw e;
    return recues;
  }

  @override
  Future<void> marquerVue(String id) async {
    vues.add(id);
    recues = <AnnonceRecue>[
      for (final AnnonceRecue a in recues)
        if (a.id == id)
          AnnonceRecue(
            id: a.id,
            titre: a.titre,
            texte: a.texte,
            publieeLe: a.publieeLe,
            vue: true,
          )
        else
          a,
    ];
  }
}

/// Le port de la reprise, en memoire.
class _Reprise implements PortRepriseCandidature {
  _Reprise(this.lue, {this.erreurLecture});

  RepriseCandidature? lue;
  final Object? erreurLecture;
  Object? erreurReprise;
  final List<(int, String)> reprises = <(int, String)>[];

  /// Le nombre de lectures servies.
  int lectures = 0;

  @override
  Future<RepriseCandidature> lire() async {
    lectures++;
    final Object? e = erreurLecture;
    // Volontairement un Object, comme le vrai client.
    // ignore: only_throw_errors
    if (e != null) throw e;
    return lue!;
  }

  @override
  Future<void> reprendre({
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    reprises.add((versionAttendue, cleIdempotence));
    final Object? e = erreurReprise;
    // ignore: only_throw_errors
    if (e != null) throw e;
  }
}

final DateTime _le = DateTime.utc(2026, 11, 18, 9);

final AnnonceRecue _annonce = AnnonceRecue(
  id: 'a1',
  titre: 'Les entretiens ouvrent lundi',
  texte: 'Des créneaux seront proposés ici dès lundi matin.',
  publieeLe: _le,
);

const CandidatureDossier _enExamen = CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.enExamen,
  version: 4,
);

const CandidatureDossier _retiree = CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.enExamen,
  issue: IssueCandidature.retiree,
  version: 6,
);

const CandidatureDossier _salle2 = CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.verifications,
  etat: EtatCandidature.entretienAPlanifier,
  version: 7,
);

RepriseCandidature _repriseOuverte({int jours = 7}) => RepriseCandidature(
  retiree: true,
  possible: true,
  delaiJours: jours,
  retireeLe: DateTime(2026, 11, 20, 18, 42),
  // Une limite qui n'est pas a l'heure ronde : l'ecran dit le jour ET
  // l'heure exacts rendus par le serveur.
  repriseJusquAu: DateTime(2026, 11, 27, 18, 42),
);

/// Les messages du candidat, qui se lisent : apres `marquerLu`, la liste des
/// fils rend 0 message non lu pour ce fil (comme le serveur).
class _MessagesQuiSeLisent extends FauxMessagesMetier {
  _MessagesQuiSeLisent({required super.fils, required super.conversations});

  final List<String> lus = <String>[];

  @override
  Future<void> marquerLu(String filId) async {
    lus.add(filId);
  }

  @override
  Future<List<ResumeFil>> fils() async => <ResumeFil>[
    for (final ResumeFil f in await super.fils())
      lus.contains(f.id)
          ? ResumeFil(
              id: f.id,
              objet: f.objet,
              interlocuteurs: f.interlocuteurs,
              apercu: f.apercu,
              dernierMessageLe: f.dernierMessageLe,
            )
          : f,
  ];
}

const RepriseCandidature _enCours = RepriseCandidature(
  retiree: false,
  possible: false,
  delaiJours: 7,
);

/// Monte l'accueil d'un candidat sur `/attente` (ou [depart]).
Future<FauxServiceDossier> _accueil(
  WidgetTester tester,
  CandidatureDossier candidature, {
  FauxMaCandidature? port,
  _Fil? fil,
  _Reprise? reprise,
  String? idCandidature = '7c400000-0000-4000-8000-000000000101',
  bool horsLigne = false,
  Size taille = const Size(390, 844),
  TextDirection? direction,
  double echelle = 1,
  ThemeMode themeMode = ThemeMode.light,
  bool accordsFaits = true,
  bool pieceDeposee = true,
  String depart = Routes.attente,
  bool attendre = true,
  bool avecAvis = false,
  bool avecMessagerie = false,
  bool filOuvert = true,
  int nonLus = 2,
  bool lectureRemetAZero = false,
}) async {
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = etatCandidat(
      candidature: candidature,
      accordsFaits: accordsFaits,
      pieceDeposee: pieceDeposee,
    );
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      echelle: echelle,
      direction: direction,
      themeMode: themeMode,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) => avecAvis
              ? const Stack(
                  children: <Widget>[
                    AttentePage(),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SafeArea(child: BandeauAvisEphemere()),
                    ),
                  ],
                )
              : const AttentePage(),
        ),
        for (final String chemin in <String>[
          Routes.attenteAccords,
          Routes.attentePiece,
          Routes.attenteCadre,
          Routes.attenteCandidature,
          Routes.attenteEntretien,
        ])
          GoRoute(
            path: chemin,
            builder: (BuildContext _, GoRouterState _) =>
                Scaffold(body: Text('PAGE $chemin')),
          ),
      ],
      surcharges: <Override>[
        ...surchargesCandidature(
          port: port ?? FauxMaCandidature(),
          etat: dossier.etatRendu,
          dossier: dossier,
          horsLigne: horsLigne,
        ),
        portAnnoncesDirectionProvider.overrideWithValue(fil ?? _Fil()),
        portRepriseCandidatureProvider.overrideWithValue(
          reprise ??
              _Reprise(
                null,
                erreurLecture: const CapaciteIndisponible(dependanceReprise),
              ),
        ),
        lireMaCandidatureIdProvider.overrideWithValue(
          () async => idCandidature,
        ),
        // La messagerie servie : la conversation du candidat avec la
        // direction, deux messages a lire.
        if (avecMessagerie && idCandidature != null) ...<Override>[
          portMessagesMetierProvider.overrideWithValue(
            (lectureRemetAZero
                ? _MessagesQuiSeLisent.new
                : FauxMessagesMetier.new)(
              fils: <FilMetier>[
                if (filOuvert)
                  filAvec(
                    id: 'fil-cand',
                    autre: const Participant(
                      id: 'administration',
                      nomAffiche: 'Administration',
                      fonction: 'administration',
                    ),
                    objets: <ObjetLie>[
                      ObjetLie(
                        type: TypeObjetLie.candidature,
                        id: idCandidature,
                        libelle: 'Candidature',
                      ),
                    ],
                    attention: IndicateurAttention(nonLus: nonLus),
                    texte: 'Bonjour, votre dossier est bien reçu.',
                  ),
              ],
              conversations: <String, List<ConversationPossible>>{
                cleObjet(
                  TypeObjetLie.candidature,
                  idCandidature,
                ): <ConversationPossible>[
                  ConversationPossible(
                    interlocuteur: const Participant(
                      id: 'administration',
                      nomAffiche: 'Administration',
                      fonction: 'administration',
                    ),
                    nature: NatureInterlocuteur.administration,
                    objet: ObjetLie(
                      type: TypeObjetLie.candidature,
                      id: idCandidature,
                      libelle: 'Candidature',
                    ),
                    filId: filOuvert ? 'fil-cand' : null,
                    attention: IndicateurAttention(nonLus: nonLus),
                  ),
                ],
              },
            ),
          ),
          capaciteEcrireOuverteTest,
          baseLocaleEnMemoire(),
        ],
      ],
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return dossier;
}

String _adresse(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(AccueilCandidat))).state.uri
        .toString();

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PE-B4 : trois onglets', () {
    testWidgets('Dossier, Messages, Academie : la barre de l application', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire());
      final NavShell coquille = tester.widget<NavShell>(find.byType(NavShell));
      expect(coquille.destinations.map((Destination d) => d.libelle), <String>[
        t.recrutement.accueil.onglets.dossier,
        t.recrutement.accueil.onglets.messages,
        t.recrutement.accueil.onglets.academie,
      ]);
      expect(coquille.indexActif, 0);
      expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
      expect(
        find.byKey(AccueilCandidat.cleOnglet(OngletCandidat.dossier)),
        findsOneWidget,
      );
    });

    testWidgets('a 1440 : la colonne de navigation, pas la barre basse', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        taille: const Size(1440, 900),
      );
      expect(find.byKey(NavShell.barreBasseKey), findsNothing);
      expect(find.byType(NavShell), findsOneWidget);
      final Rect titre = tester.getRect(_cle('portail-titre'));
      expect(titre.width, lessThan(900));
    });

    testWidgets('l onglet est dans l adresse ; recharger rend le meme ecran', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire());
      expect(_adresse(tester), Routes.attente);
      await versOnglet(tester, t.recrutement.accueil.onglets.academie);
      expect(_adresse(tester), '${Routes.attente}?onglet=academie');
      expect(
        find.byKey(AccueilCandidat.cleOnglet(OngletCandidat.academie)),
        findsOneWidget,
      );
      expect(_cle('portail-titre'), findsNothing);
      await versOnglet(tester, t.recrutement.accueil.onglets.messages);
      expect(_adresse(tester), '${Routes.attente}?onglet=messages');
      await versOnglet(tester, t.recrutement.accueil.onglets.dossier);
      expect(_adresse(tester), Routes.attente);
      expect(_cle('portail-titre'), findsOneWidget);
    });

    testWidgets('une adresse ouvre directement son onglet', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        depart: '${Routes.attente}?onglet=academie',
      );
      expect(
        tester.widget<NavShell>(find.byType(NavShell)).indexActif,
        OngletCandidat.academie.index,
      );
      expect(find.byKey(OngletAcademie.cleReglages), findsOneWidget);
    });

    testWidgets('une valeur inconnue du parametre ouvre Dossier', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        depart: '${Routes.attente}?onglet=inconnu',
      );
      expect(_cle('portail-titre'), findsOneWidget);
    });

    testWidgets('Messages : la conversation, ou la phrase quand elle manque', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire(), idCandidature: null);
      await versOnglet(tester, t.recrutement.accueil.onglets.messages);
      expect(find.byKey(AccueilCandidat.cleMessagesVide), findsOneWidget);
      expect(_texte(t.recrutement.accueil.messages.vide), findsOneWidget);
    });

    testWidgets('Messages : conversation pas encore ouverte, l intro et '
        'l entree existante', (WidgetTester tester) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        avecMessagerie: true,
        filOuvert: false,
      );
      await versOnglet(tester, t.recrutement.accueil.onglets.messages);
      expect(_texte(t.recrutement.accueil.messages.intro), findsOneWidget);
      expect(find.byKey(AccueilCandidat.cleMessagesVide), findsNothing);
      // L'entree des Messages existante : la conversation avec la direction.
      expect(find.byKey(EntreeMessagesContexte.cleObjet), findsOneWidget);
      expect(find.byKey(FilEnPlace.cle), findsNothing);
    });

    testWidgets('Messages : conversation ouverte, le fil en place, sans '
        'quitter l accueil', (WidgetTester tester) async {
      await _accueil(tester, candidatureAFaire(), avecMessagerie: true);
      await versOnglet(tester, t.recrutement.accueil.onglets.messages);
      expect(find.byKey(FilEnPlace.cle), findsOneWidget);
      expect(_texte('Bonjour, votre dossier est bien reçu.'), findsOneWidget);
      expect(_adresse(tester), '${Routes.attente}?onglet=messages');
      // Le champ du fil reste au-dessus de la barre du bas.
      final Rect barre = tester.getRect(find.byKey(NavShell.barreBasseKey));
      final Rect champ = tester.getRect(find.byType(EditableText).last);
      expect(champ.bottom, lessThanOrEqualTo(barre.top));
    });

    testWidgets('la barre : le nombre de messages recus non lus, seul, sur '
        'Messages', (WidgetTester tester) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        avecMessagerie: true,
        nonLus: 3,
      );
      final Finder pastille = find.byKey(
        NavShell.cleCompteur(OngletCandidat.messages.chemin),
      );
      expect(pastille, findsOneWidget);
      expect(
        find.descendant(of: pastille, matching: find.text('3')),
        findsOneWidget,
      );
      expect(find.byKey(NavShell.cleCompteur(Routes.attente)), findsNothing);
      expect(
        find.byKey(NavShell.cleCompteur(OngletCandidat.academie.chemin)),
        findsNothing,
      );
    });

    testWidgets('la barre : lire la conversation remet le nombre a zero', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        avecMessagerie: true,
        nonLus: 3,
        lectureRemetAZero: true,
      );
      final Finder pastille = find.byKey(
        NavShell.cleCompteur(OngletCandidat.messages.chemin),
      );
      expect(
        find.descendant(of: pastille, matching: find.text('3')),
        findsOneWidget,
      );
      // Ouvrir la rubrique Messages ouvre la conversation, qui se marque lue.
      await versOnglet(tester, t.recrutement.accueil.onglets.messages);
      expect(find.byKey(FilEnPlace.cle), findsOneWidget);
      final _MessagesQuiSeLisent port = ProviderScope.containerOf(
        tester.element(find.byType(AccueilCandidat)),
      ).read(portMessagesMetierProvider) as _MessagesQuiSeLisent;
      expect(port.lus, <String>['fil-cand']);
      // Le nombre est relu : plus de pastille, plus rien dans la voix.
      expect(pastille, findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp(t.recrutement.accueil.messages.nonLus(n: 3)),
        ),
        findsNothing,
      );
      // Revenir a Dossier ne la fait pas revenir.
      await versOnglet(tester, t.recrutement.accueil.onglets.dossier);
      expect(pastille, findsNothing);
    });

    testWidgets('la barre : aucun message non lu, aucune pastille', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        avecMessagerie: true,
        nonLus: 0,
      );
      expect(
        find.byKey(NavShell.cleCompteur(OngletCandidat.messages.chemin)),
        findsNothing,
      );
    });

    testWidgets('Messages : trois rubriques ; la rubrique est dans l adresse', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire());
      await versOnglet(tester, t.recrutement.accueil.onglets.messages);
      final s = t.recrutement.accueil.messages.sections;
      expect(find.byType(SelecteurMessages), findsOneWidget);
      final SelecteurSection<SectionMessages> selecteur = tester
          .widget<SelecteurSection<SectionMessages>>(
            find.byType(SelecteurSection<SectionMessages>),
          );
      // Trois rubriques, dans l'ordre (le rendu segmente ou en menu depend
      // de la place : la police des tests est plus large).
      expect(
        selecteur.sections.map((Segment<SectionMessages> g) => g.libelle),
        <String>[s.messages, s.annonces, s.savoir],
      );
      selecteur.onChange(SectionMessages.savoir);
      await tester.pumpAndSettle();
      expect(
        _adresse(tester),
        '${Routes.attente}?onglet=messages&section=savoir',
      );
      expect(find.byKey(ASavoirCandidat.cle), findsOneWidget);
      // Rien n'est invente : chaque emplacement attend la direction.
      final a = t.recrutement.accueil.academie;
      for (final EmplacementSavoir e in EmplacementSavoir.values) {
        expect(find.byKey(ASavoirCandidat.cleEmplacement(e)), findsOneWidget);
      }
      // LETTRE-SERVEUR : la ligne de la paie est retiree, la lettre la dit.
      expect(
        EmplacementSavoir.values.map((EmplacementSavoir e) => e.name),
        <String>['cours', 'entretiens'],
      );
      expect(_texte(a.cours), findsOneWidget);
      expect(_texte(a.entretiens), findsOneWidget);
      expect(_texte(a.bientot), findsNWidgets(2));
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('Messages : la rubrique Annonces', () {
    AnnonceRecue annonce(String id, {bool vue = false, int jours = 0}) =>
        AnnonceRecue(
          id: id,
          titre: 'Annonce $id',
          texte: 'Le texte entier de l annonce $id.',
          publieeLe: _le.subtract(Duration(days: jours)),
          vue: vue,
        );

    testWidgets('une grille ; « Nouvelle » sur ce qui n a pas ete vu', (
      WidgetTester tester,
    ) async {
      final _Fil fil = _Fil(
        recues: <AnnonceRecue>[
          annonce('a1'),
          annonce('a2', vue: true, jours: 1),
          annonce('a3', jours: 2),
        ],
      );
      await _accueil(
        tester,
        candidatureAFaire(),
        fil: fil,
        depart: '${Routes.attente}?onglet=messages&section=annonces',
      );
      expect(find.byKey(AnnoncesCandidat.cleGrille), findsOneWidget);
      // La plus recente sur toute la largeur, les suivantes en deux colonnes.
      final Rect r1 = tester.getRect(
        find.byKey(AnnoncesCandidat.cleCarte('a1')),
      );
      final Rect r2 = tester.getRect(
        find.byKey(AnnoncesCandidat.cleCarte('a2')),
      );
      final Rect r3 = tester.getRect(
        find.byKey(AnnoncesCandidat.cleCarte('a3')),
      );
      expect(r2.top, r3.top);
      expect(r1.width, greaterThan(r2.width * 1.8));
      expect(r3.top - r1.bottom, greaterThanOrEqualTo(16));
      expect(find.byKey(AnnoncesCandidat.clePastille('a1')), findsOneWidget);
      expect(find.byKey(AnnoncesCandidat.clePastille('a2')), findsNothing);
      expect(find.byKey(AnnoncesCandidat.clePastille('a3')), findsOneWidget);
      expect(_texte(t.com.annonces.fil.nouvelle), findsNWidgets(2));
      // « Urgent » : le serveur ne rend aucune priorite, rien n'est devine.
      expect(_texte(t.com.socle.composants.badge.urgent), findsNothing);
      expect(fil.vues, isEmpty);
    });

    testWidgets('toucher une carte ouvre l annonce entiere et la compte vue', (
      WidgetTester tester,
    ) async {
      final _Fil fil = _Fil(recues: <AnnonceRecue>[annonce('a1')]);
      await _accueil(
        tester,
        candidatureAFaire(),
        fil: fil,
        depart: '${Routes.attente}?onglet=messages&section=annonces',
      );
      await _toucher(tester, find.byKey(AnnoncesCandidat.cleCarte('a1')));
      expect(fil.vues, <String>['a1']);
      expect(_texte('Le texte entier de l annonce a1.'), findsWidgets);
    });

    testWidgets('sans annonce : la phrase', (WidgetTester tester) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        depart: '${Routes.attente}?onglet=messages&section=annonces',
      );
      expect(find.byKey(AnnoncesCandidat.cleVide), findsOneWidget);
    });

    testWidgets('en chargement : le squelette', (WidgetTester tester) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        fil: _Fil(jamais: true),
        depart: '${Routes.attente}?onglet=messages&section=annonces',
        attendre: false,
      );
      await tester.pump();
      expect(find.byKey(AnnoncesCandidat.cleVide), findsNothing);
      expect(find.byKey(AnnoncesCandidat.cleGrille), findsNothing);
      // Purge le minuteur de la lecture qui ne repond pas.
      await tester.pump(const Duration(days: 2));
    });

    testWidgets('en echec : une phrase vraie et Reessayer', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        fil: _Fil(erreur: Exception('panne')),
        depart: '${Routes.attente}?onglet=messages&section=annonces',
      );
      expect(find.byKey(AnnoncesCandidat.cleGrille), findsNothing);
      expect(_texte(t.commun.etats.actions.reessayer), findsOneWidget);
    });
  });

  group('PE-B4 : l annonce en une ligne', () {
    testWidgets('une annonce nouvelle : une ligne, pas une carte', (
      WidgetTester tester,
    ) async {
      final _Fil fil = _Fil(recues: <AnnonceRecue>[_annonce]);
      await _accueil(tester, candidatureAFaire(), fil: fil);
      expect(find.byKey(AnnonceEnLigne.cle), findsOneWidget);
      // Le fil complet n'est plus sur l'onglet Dossier.
      expect(find.byKey(AnnoncesRecues.cle), findsNothing);
      expect(find.textContaining(_annonce.titre), findsOneWidget);
      expect(_texte(_annonce.texte), findsNothing);
      // Elle n'est pas comptee « vue » tant qu'elle n'est ni fermee ni lue.
      expect(fil.vues, isEmpty);
      expect(
        tester.getSize(find.byKey(AnnonceEnLigne.cle)).height,
        lessThan(80),
      );
    });

    testWidgets('fermee : comptee vue, un avis le dit, rangee dans Annonces', (
      WidgetTester tester,
    ) async {
      final _Fil fil = _Fil(recues: <AnnonceRecue>[_annonce]);
      await _accueil(tester, candidatureAFaire(), fil: fil, avecAvis: true);
      await tester.tap(find.byKey(AnnonceEnLigne.cleFermer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(AnnonceEnLigne.cle), findsNothing);
      expect(fil.vues, <String>['a1']);
      expect(_texte(t.recrutement.accueil.annonce.rangee), findsOneWidget);
      // L'avis part seul.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await versOnglet(tester, t.recrutement.accueil.onglets.messages);
      tester
          .widget<SelecteurSection<SectionMessages>>(
            find.byType(SelecteurSection<SectionMessages>),
          )
          .onChange(SectionMessages.annonces);
      await tester.pumpAndSettle();
      expect(find.byKey(AnnoncesCandidat.cleCarte('a1')), findsOneWidget);
      expect(find.byKey(AnnoncesCandidat.clePastille('a1')), findsNothing);
      // De retour sur Dossier : plus de ligne.
      await versOnglet(tester, t.recrutement.accueil.onglets.dossier);
      expect(find.byKey(AnnonceEnLigne.cle), findsNothing);
    });

    testWidgets('toucher la ligne ouvre la rubrique Annonces', (
      WidgetTester tester,
    ) async {
      final _Fil fil = _Fil(recues: <AnnonceRecue>[_annonce]);
      await _accueil(tester, candidatureAFaire(), fil: fil);
      await tester.tap(find.textContaining(_annonce.titre));
      await tester.pumpAndSettle();
      expect(
        _adresse(tester),
        '${Routes.attente}?onglet=messages&section=annonces',
      );
      expect(find.byKey(AnnoncesCandidat.cleCarte('a1')), findsOneWidget);
      expect(find.byKey(AnnoncesCandidat.clePastille('a1')), findsOneWidget);
    });

    testWidgets('une annonce deja vue : aucune ligne', (
      WidgetTester tester,
    ) async {
      final _Fil fil = _Fil(
        recues: <AnnonceRecue>[
          AnnonceRecue(
            id: 'a1',
            titre: _annonce.titre,
            texte: _annonce.texte,
            publieeLe: _le,
            vue: true,
          ),
        ],
      );
      await _accueil(tester, candidatureAFaire(), fil: fil);
      expect(find.byKey(AnnonceEnLigne.cle), findsNothing);
    });

    testWidgets('Academie : partager, reglages replies, deconnexion', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire());
      await versOnglet(tester, t.recrutement.accueil.onglets.academie);
      // Les annonces et « A savoir » sont dans Messages.
      expect(find.byKey(AnnoncesCandidat.cleGrille), findsNothing);
      expect(find.byKey(ASavoirCandidat.cle), findsNothing);
      // La langue et le retrait sont dans un reglage, replie.
      expect(_cle('retrait-lien'), findsNothing);
      expect(find.byKey(OngletAcademie.cleReglagesOuverts), findsNothing);
      await toucherCle(tester, 'academie-reglages');
      expect(find.byKey(OngletAcademie.cleReglagesOuverts), findsOneWidget);
      expect(_texte(t.compte.langue), findsOneWidget);
      expect(_cle('retrait-lien'), findsOneWidget);
      // La deconnexion reste visible, sans deplier.
      expect(find.byKey(OngletAcademie.cleDeconnexion), findsOneWidget);
    });
  });

  group('PE-B5 : l etat du dossier', () {
    testWidgets('la ligne d etapes : trois stations, l etape et son nom', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire());
      for (int i = 1; i <= 3; i++) {
        expect(find.byKey(LigneEtapes.cleStation(i)), findsOneWidget);
      }
      expect(
        _texte(t.recrutement.accueil.etapes.position(n: 1, total: 3)),
        findsOneWidget,
      );
      // A cote de la position : l'etat de la candidature, sans second titre
      // (pilote, 20/11/2026). Le nom de l'etape et ce qui s'y passe se
      // deplient au toucher.
      expect(
        tester.widget<Text>(find.byKey(StatutCandidature.titreKey)).data,
        t.recrutement.portail.aCompleterTitre,
      );
      expect(find.byKey(LigneEtapes.cleDetail), findsNothing);
      await tester.tap(find.byKey(LigneEtapes.cleStation(1)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(EnteteSalle.salleKey)).data,
        t.recrutement.sallesCandidat.candidature,
      );
      expect(_texte(t.recrutement.accueil.etapes.detail1), findsOneWidget);
    });

    testWidgets('maquette : l annonce au-dessus du titre ; une ligne du '
        'dossier sans icone ni chevron ; aucun titre de section', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        fil: _Fil(recues: <AnnonceRecue>[_annonce]),
      );
      expect(
        tester.getTopLeft(find.byKey(AnnonceEnLigne.cle)).dy,
        lessThan(tester.getTopLeft(find.byKey(OngletDossier.cleTitre)).dy),
      );
      // « Nouveau : … » ; le titre est isole pour le sens de lecture.
      expect(
        tester.widget<Text>(find.textContaining(_annonce.titre)).data,
        startsWith(t.recrutement.accueil.annonce.ligne(titre: '').trimRight()),
      );
      final Finder ligne = find.byKey(OngletDossier.cleLigne('piece'));
      expect(
        find.descendant(of: ligne, matching: find.byType(Icon)),
        findsNothing,
      );
      expect(_texte(t.recrutement.accueil.lignes.titre), findsNothing);
      expect(_texte(t.recrutement.portail.listeTitre), findsNothing);
    });

    testWidgets('toucher une station dit ce qui s y passe', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire());
      await tester.tap(find.byKey(LigneEtapes.cleStation(2)));
      await tester.pumpAndSettle();
      expect(_texte(t.recrutement.accueil.etapes.detail2), findsOneWidget);
      expect(_texte(t.recrutement.sallesCandidat.connaissance), findsOneWidget);
      expect(
        _texte(t.recrutement.accueil.etapes.position(n: 2, total: 3)),
        findsOneWidget,
      );
    });

    testWidgets('Praxis : une seule information, un fait du dossier ; rien '
        'quand il n y a rien a dire', (WidgetTester tester) async {
      // Deux elements restent : il le dit.
      await _accueil(
        tester,
        candidatureAFaire(),
        accordsFaits: false,
        pieceDeposee: false,
      );
      expect(find.byKey(PraxisDuDossier.cle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(PraxisDuDossier.cle),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      // Une candidature retiree : il n'a rien a dire, il n'est pas la.
      await _accueil(tester, _retiree, reprise: _Reprise(_repriseOuverte()));
      expect(find.byKey(PraxisDuDossier.cle), findsNothing);
    });

    testWidgets('un seul « a faire maintenant », avec son seul bouton', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        candidatureAFaire(),
        accordsFaits: false,
        pieceDeposee: false,
      );
      expect(find.byKey(OngletDossier.cleAFaire), findsOneWidget);
      expect(find.byKey(OngletDossier.cleRien), findsNothing);
      expect(_texte(t.recrutement.accueil.aFaire.titre), findsOneWidget);
      expect(_texte(t.recrutement.accueil.aFaire.accords), findsOneWidget);
      // Un seul bouton : le premier element a faire, pas un par ligne.
      expect(find.byType(ActionPrincipale), findsOneWidget);
      expect(_texte(t.attente.lireEtAccepter), findsOneWidget);
      expect(_texte(t.attente.deposerLaPiece), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      expect(
        _texte(t.recrutement.accueil.etapes.ensuiteACompleter),
        findsOneWidget,
      );
      // Le bouton ouvre la page de l'element.
      await _toucher(tester, _texte(t.attente.lireEtAccepter));
      expect(_texte('PAGE ${Routes.attenteAccords}'), findsOneWidget);
    });

    testWidgets('rien a faire : la phrase, aucun bouton', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, _enExamen);
      expect(find.byKey(OngletDossier.cleRien), findsOneWidget);
      expect(find.byKey(OngletDossier.cleAFaire), findsNothing);
      expect(_texte(t.recrutement.accueil.aFaire.rienTitre), findsOneWidget);
      expect(_texte(t.recrutement.accueil.aFaire.rien), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsNothing);
      expect(
        _texte(t.recrutement.accueil.etapes.ensuiteEnExamen),
        findsOneWidget,
      );
    });

    testWidgets('une ligne se deplie au toucher et dit ce qu elle est', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire(), pieceDeposee: false);
      expect(find.byKey(OngletDossier.cleDetail('piece')), findsNothing);
      await toucherCle(tester, 'dossier-ligne-piece');
      await tester.pumpAndSettle();
      expect(find.byKey(OngletDossier.cleDetail('piece')), findsOneWidget);
      expect(_texte(t.recrutement.accueil.lignes.pieceDetail), findsOneWidget);
      // Elle se replie.
      await toucherCle(tester, 'dossier-ligne-piece');
      await tester.pumpAndSettle();
      expect(find.byKey(OngletDossier.cleDetail('piece')), findsNothing);
    });

    testWidgets('salle 2 : accords et piece faits, « choisir mon entretien »', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, _salle2);
      expect(find.byKey(OngletDossier.cleAFaire), findsOneWidget);
      expect(_texte(t.recrutement.accueil.aFaire.entretien), findsOneWidget);
      expect(
        _texte(t.recrutement.accueil.etapes.position(n: 2, total: 3)),
        findsOneWidget,
      );
      await _toucher(tester, _texte(t.recrutement.entretien.portailChoisir));
      expect(_texte('PAGE ${Routes.attenteEntretien}'), findsOneWidget);
    });

    testWidgets('salle 2, accords a faire : ils passent avant l entretien', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, _salle2, accordsFaits: false);
      expect(_texte(t.recrutement.accueil.aFaire.accords), findsOneWidget);
      // L'entretien garde son entree, en lien discret : il n'est pas
      // « a faire maintenant », et n'ajoute aucun bouton.
      expect(
        tester.widget(find.byKey(EnteteSalle.entretienKey)),
        isA<LienFleche>(),
      );
      expect(find.byType(ActionPrincipale), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('relecture en echec : ce qui est montre reste, et le dit', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = await _accueil(tester, _enExamen);
      expect(find.byKey(OngletDossier.clePerime), findsNothing);
      dossier.erreurAJeter = Exception('panne');
      await _toucher(tester, find.byKey(OngletDossier.cleActualiser));
      expect(find.byKey(OngletDossier.clePerime), findsOneWidget);
      expect(_texte(t.recrutement.accueil.etat.perime), findsOneWidget);
      expect(_texte(t.recrutement.portail.enExamenTitre), findsOneWidget);
      // « Reessayer » relit ; la lecture revenue, l'avis part.
      dossier.erreurAJeter = null;
      await _toucher(tester, _texte(t.commun.reessayer));
      expect(find.byKey(OngletDossier.clePerime), findsNothing);
    });

    testWidgets('relecture en echec hors connexion : la phrase le dit', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = await _accueil(
        tester,
        _enExamen,
        horsLigne: true,
      );
      dossier.erreurAJeter = Exception('panne');
      await _toucher(tester, find.byKey(OngletDossier.cleActualiser));
      expect(_texte(t.recrutement.accueil.etat.horsLigne), findsOneWidget);
    });

    for (final Size taille in const <Size>[Size(320, 640), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        testWidgets(
          'aucun debordement a ${taille.width.toInt()}, texte x$echelle, '
          'arabe, sombre',
          (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
            await _accueil(
              tester,
              candidatureAFaire(complement: <String>['publics']),
              fil: _Fil(recues: <AnnonceRecue>[_annonce]),
              taille: taille,
              echelle: echelle,
              direction: TextDirection.rtl,
              themeMode: ThemeMode.dark,
              accordsFaits: false,
            );
            expect(tester.takeException(), isNull);
            await toucherCle(tester, 'dossier-ligne-accords');
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final String onglet in <String>[
              t.recrutement.accueil.onglets.messages,
              t.recrutement.accueil.onglets.academie,
            ]) {
              await versOnglet(tester, onglet);
              expect(tester.takeException(), isNull);
            }
            await toucherCle(tester, 'academie-reglages');
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('effets reduits : tout est pose d emblee, rien ne manque', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _accueil(
        tester,
        candidatureAFaire(),
        fil: _Fil(recues: <AnnonceRecue>[_annonce]),
        accordsFaits: false,
        attendre: false,
      );
      // Deux images suffisent : aucun mouvement n'est en cours.
      await tester.pump();
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(find.byKey(OngletDossier.cleAFaire), findsOneWidget);
      expect(find.byKey(AnnonceEnLigne.cle), findsOneWidget);
      expect(find.byKey(LigneEtapes.cleStation(3)), findsOneWidget);
      await toucherCle(tester, 'dossier-ligne-accords');
      await tester.pump();
      expect(find.byKey(OngletDossier.cleDetail('accords')), findsOneWidget);
    });

    testWidgets('au repos, plus aucune image n est produite', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, candidatureAFaire(), accordsFaits: false);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('PE-A6 : le retrait qui se defait', () {
    testWidgets('l ecran explique le retrait avant le geste, avec le delai', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await _accueil(
        tester,
        candidatureAFaire(),
        port: port,
        reprise: _Reprise(_enCours),
      );
      await versLeRetrait(tester);
      await toucherCle(tester, 'retrait-lien');
      final e = t.recrutement.accueil.retrait;
      expect(_texte(t.recrutement.retrait.question), findsOneWidget);
      expect(find.textContaining(e.arret), findsOneWidget);
      expect(find.textContaining(e.rienEfface), findsOneWidget);
      expect(find.textContaining(e.reprise(n: 7)), findsOneWidget);
      expect(find.textContaining(e.apres), findsOneWidget);
      // Sans entretien planifie, aucun mot d'entretien.
      expect(find.textContaining(e.entretien), findsNothing);
      // « Non, je continue » ne retire rien.
      await tester.tap(_texte(e.garder));
      await tester.pumpAndSettle();
      expect(port.retraits, isEmpty);
    });

    testWidgets('un entretien planifie : l explication dit qu il est annule', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienPlanifie,
          version: 5,
        ),
        reprise: _Reprise(_enCours),
      );
      await versLeRetrait(tester);
      await toucherCle(tester, 'retrait-lien');
      expect(
        find.textContaining(t.recrutement.accueil.retrait.entretien),
        findsOneWidget,
      );
    });

    testWidgets('en pause : l explication dit que le retrait ne se defait pas '
        'par la personne, aucun delai promis', (WidgetTester tester) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await _accueil(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.aCompleter,
          enPause: true,
          version: 4,
        ),
        port: port,
        reprise: _Reprise(_enCours),
      );
      await versLeRetrait(tester);
      await toucherCle(tester, 'retrait-lien');
      final e = t.recrutement.accueil.retrait;
      expect(find.textContaining(e.pause), findsOneWidget);
      expect(find.textContaining(e.arret), findsOneWidget);
      expect(find.textContaining(e.reprise(n: 7)), findsNothing);
      expect(find.textContaining(e.apres), findsNothing);
      // Le texte d'avant (« Rien ne sera efface ») n'est dit nulle part.
      expect(find.textContaining('Rien ne sera effacé'), findsNothing);
      await tester.tap(_texte(e.garder));
      await tester.pumpAndSettle();
      expect(port.retraits, isEmpty);
    });

    testWidgets('en pause, confirme : l avis ne promet aucun delai, la carte '
        'ne propose pas la reprise et dit pourquoi', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      final _Reprise reprise = _Reprise(_enCours);
      final FauxServiceDossier dossier = await _accueil(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.aCompleter,
          enPause: true,
          version: 4,
        ),
        port: port,
        reprise: reprise,
        avecAvis: true,
      );
      await versLeRetrait(tester);
      await toucherCle(tester, 'retrait-lien');
      dossier.etatRendu = etatCandidat(
        candidature: port.candidatureApresRetrait,
      );
      // Ce que le serveur rend apres un retrait qui a leve la pause.
      reprise.lue = RepriseCandidature(
        retiree: true,
        possible: false,
        delaiJours: 7,
        retireeLe: DateTime(2026, 11, 20, 18, 42),
        raison: RaisonRepriseFermee.retraitEnPause,
      );
      await tester.tap(_texte(t.recrutement.accueil.retrait.confirmer).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(port.retraits, hasLength(1));
      expect(
        _texte(t.recrutement.accueil.retrait.faitSansDelai),
        findsOneWidget,
      );
      expect(_texte(t.recrutement.accueil.retrait.fait(n: 7)), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(_texte(t.recrutement.accueil.reprise.enPause), findsOneWidget);
      expect(find.byKey(CarteReprise.cleBouton), findsNothing);
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('la date limite : le jour et l heure du serveur, dans la '
        'langue de la personne (arabe)', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _accueil(
        tester,
        _retiree,
        reprise: _Reprise(_repriseOuverte()),
        direction: TextDirection.rtl,
      );
      final String phrase = tester
          .widget<Text>(find.byKey(CarteReprise.clePhrase))
          .data!;
      expect(phrase, contains('نوفمبر'));
      expect(phrase, contains('18:42'));
      expect(phrase, contains('27'));
      expect(phrase, contains('2026'));
      expect(phrase, isNot(contains('nov.')));
    });

    testWidgets('confirmer : un avis dit le delai, retour a Dossier, reprise', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      final _Reprise reprise = _Reprise(_enCours);
      final FauxServiceDossier dossier = await _accueil(
        tester,
        candidatureAFaire(),
        port: port,
        reprise: reprise,
        avecAvis: true,
      );
      await versLeRetrait(tester);
      await toucherCle(tester, 'retrait-lien');
      dossier.etatRendu = etatCandidat(
        candidature: port.candidatureApresRetrait,
      );
      reprise.lue = _repriseOuverte();
      await tester.tap(_texte(t.recrutement.accueil.retrait.confirmer).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(port.retraits, hasLength(1));
      // Jamais de silence : l'avis dit que c'est fait, et le delai.
      expect(_texte(t.recrutement.accueil.retrait.fait(n: 7)), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      // L'accueil est revenu a l'onglet Dossier, ou la reprise est proposee.
      expect(_adresse(tester), Routes.attente);
      expect(_texte(t.recrutement.portail.retireeTitre), findsOneWidget);
      expect(find.byKey(CarteReprise.cleBouton), findsOneWidget);
      // La limite exacte du serveur, au jour et a l'heure.
      expect(
        _texte(
          t.recrutement.accueil.reprise.possible(
            date: '27 nov. 2026',
            heure: '18:42',
          ),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('reprendre : le geste part avec la version, l etat est relu', (
      WidgetTester tester,
    ) async {
      final _Reprise reprise = _Reprise(_repriseOuverte());
      final FauxServiceDossier dossier = await _accueil(
        tester,
        _retiree,
        reprise: reprise,
        avecAvis: true,
      );
      expect(find.byKey(CarteReprise.cleBouton), findsOneWidget);
      // Le serveur reprend, puis le dossier le dit.
      dossier.etatRendu = etatCandidat(candidature: _enExamen);
      reprise.lue = _enCours;
      await tester.tap(find.byKey(CarteReprise.cleBouton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(reprise.reprises, hasLength(1));
      expect(reprise.reprises.single.$1, 6);
      expect(_texte(t.recrutement.accueil.reprise.faite), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(_texte(t.recrutement.portail.enExamenTitre), findsOneWidget);
      expect(find.byKey(CarteReprise.cleBouton), findsNothing);
    });

    for (final (
          String nom,
          RaisonRepriseFermee raison,
          String Function() phrase,
        )
        in <(String, RaisonRepriseFermee, String Function())>[
          (
            'delai passe',
            RaisonRepriseFermee.delaiDepasse,
            () => t.recrutement.accueil.reprise.delaiDepasse,
          ),
          (
            'retrait par la direction',
            RaisonRepriseFermee.retraitParLaDirection,
            () => t.recrutement.accueil.reprise.parDirection,
          ),
          (
            'un element a change',
            RaisonRepriseFermee.controles,
            () => t.recrutement.accueil.reprise.controles,
          ),
          (
            'retrait pendant une pause',
            RaisonRepriseFermee.retraitEnPause,
            () => t.recrutement.accueil.reprise.enPause,
          ),
          (
            'origine du retrait inconnue',
            RaisonRepriseFermee.origineInconnue,
            () => t.recrutement.accueil.reprise.origineInconnue,
          ),
        ]) {
      testWidgets('reprise fermee ($nom) : la raison, aucun bouton', (
        WidgetTester tester,
      ) async {
        await _accueil(
          tester,
          _retiree,
          reprise: _Reprise(
            RepriseCandidature(
              retiree: true,
              possible: false,
              delaiJours: 7,
              raison: raison,
            ),
          ),
        );
        expect(_texte(phrase()), findsOneWidget);
        expect(find.byKey(CarteReprise.cleBouton), findsNothing);
        expect(find.byType(ActionPrincipale), findsNothing);
      });
    }

    testWidgets('sans lecture du serveur : la phrase d avant, aucun bouton', (
      WidgetTester tester,
    ) async {
      await _accueil(tester, _retiree);
      expect(_texte(t.recrutement.portail.retiree), findsOneWidget);
      expect(find.byKey(CarteReprise.cleBouton), findsNothing);
    });

    for (final (String nom, Object erreur, String Function() message)
        in <(String, Object, String Function())>[
          (
            'conflit',
            const ConflitCandidature(9),
            () => t.recrutement.accueil.reprise.conflit,
          ),
          (
            'delai passe entre-temps',
            const RepriseFermee(RaisonRepriseFermee.delaiDepasse),
            () => t.recrutement.accueil.reprise.delaiDepasse,
          ),
          (
            'issue incertaine',
            const HorsLigneCandidature(),
            () => t.recrutement.accueil.reprise.incertain,
          ),
          (
            'capacite indisponible',
            const CapaciteIndisponible(dependanceReprise),
            () => t.recrutement.accueil.reprise.echec,
          ),
        ]) {
      testWidgets('reprise refusee ($nom) : une phrase, rien n est dit fait', (
        WidgetTester tester,
      ) async {
        final _Reprise reprise = _Reprise(_repriseOuverte())
          ..erreurReprise = erreur;
        await _accueil(tester, _retiree, reprise: reprise);
        await _toucher(tester, find.byKey(CarteReprise.cleBouton));
        expect(find.byKey(CarteReprise.cleMessage), findsOneWidget);
        expect(find.textContaining(message()), findsWidgets);
        expect(_texte(t.recrutement.portail.retireeTitre), findsOneWidget);
      });
    }

    testWidgets('issue incertaine : le second essai rejoue la meme cle', (
      WidgetTester tester,
    ) async {
      final _Reprise reprise = _Reprise(_repriseOuverte())
        ..erreurReprise = const HorsLigneCandidature();
      await _accueil(tester, _retiree, reprise: reprise);
      await _toucher(tester, find.byKey(CarteReprise.cleBouton));
      await _toucher(tester, find.byKey(CarteReprise.cleBouton));
      expect(reprise.reprises, hasLength(2));
      expect(reprise.reprises.last.$2, reprise.reprises.first.$2);
    });

    testWidgets('hors ligne : pas de bouton, une note qui dit quand', (
      WidgetTester tester,
    ) async {
      await _accueil(
        tester,
        _retiree,
        reprise: _Reprise(_repriseOuverte()),
        horsLigne: true,
      );
      expect(find.byKey(CarteReprise.cleBouton), findsNothing);
      expect(find.byKey(CarteReprise.cleHorsLigne), findsOneWidget);
    });

    test('la lecture du serveur : cle reprise de etat_dossier()', () {
      expect(
        RepriseCandidature.depuisJson(const <String, Object?>{'delaiJours': 7}),
        _enCours,
      );
      final RepriseCandidature ouverte = RepriseCandidature.depuisJson(
        const <String, Object?>{
          'delaiJours': 7,
          'retireeLe': '2026-11-20T10:00:00Z',
          'parLeCandidat': true,
          'repriseJusquAu': '2026-11-27T10:00:00Z',
          'possible': true,
        },
      );
      expect(ouverte.retiree, isTrue);
      expect(ouverte.possible, isTrue);
      expect(ouverte.raison, isNull);
      expect(ouverte.repriseJusquAu!.toUtc(), DateTime.utc(2026, 11, 27, 10));
      final RepriseCandidature fermee = RepriseCandidature.depuisJson(
        const <String, Object?>{
          'delaiJours': 7,
          'possible': false,
          'raison': 'delai_depasse',
        },
      );
      expect(fermee.retiree, isTrue);
      expect(fermee.possible, isFalse);
      expect(fermee.raison, RaisonRepriseFermee.delaiDepasse);
      // Une raison inconnue de cette version : la suite est la meme.
      expect(
        RepriseCandidature.depuisJson(const <String, Object?>{
          'delaiJours': 7,
          'possible': false,
          'raison': 'autre',
        }).raison,
        RaisonRepriseFermee.controles,
      );
      expect(
        () => RepriseCandidature.depuisJson(const <String, Object?>{}),
        throwsFormatException,
      );
    });
    testWidgets('relire le dossier relit aussi la reprise (le delai passe se '
        'voit sans rien invalider d autre)', (WidgetTester tester) async {
      final _Reprise reprise = _Reprise(_repriseOuverte());
      await _accueil(tester, _retiree, reprise: reprise);
      expect(find.byKey(CarteReprise.cleBouton), findsOneWidget);
      final int avant = reprise.lectures;
      // Entre-temps, le delai est passe cote serveur.
      reprise.lue = const RepriseCandidature(
        retiree: true,
        possible: false,
        delaiJours: 7,
        raison: RaisonRepriseFermee.delaiDepasse,
      );
      // Seul le dossier est invalide, comme le fait « tirer pour actualiser ».
      ProviderScope.containerOf(tester.element(find.byType(AccueilCandidat)))
          .invalidate(etatDossierProvider);
      await tester.pumpAndSettle();
      expect(reprise.lectures, avant + 1);
      expect(find.byKey(CarteReprise.cleBouton), findsNothing);
    });
  });

  // Captures R3 : CAPTURE_DIR=docs/current/captures/E2E.
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    const String d = 'pe-accueil-candidat';

    Future<void> monter(
      WidgetTester tester, {
      required AppLocale langue,
      required ThemeMode theme,
      required Size taille,
      CandidatureDossier? candidature,
      _Fil? fil,
      _Reprise? reprise,
      bool accordsFaits = true,
      bool pieceDeposee = true,
      bool horsLigne = false,
      String depart = Routes.attente,
      bool attendre = true,
    }) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      await _accueil(
        tester,
        candidature ?? candidatureAFaire(),
        fil:
            fil ??
            _Fil(
              recues: <AnnonceRecue>[
                // En arabe, une annonce ecrite en arabe (donnee fictive).
                if (langue == AppLocale.ar)
                  AnnonceRecue(
                    id: 'a1',
                    titre: 'تُفتح المقابلات يوم الاثنين',
                    texte: 'ستُعرض المواعيد هنا صباح الاثنين.',
                    publieeLe: _le,
                  )
                else
                  _annonce,
              ],
            ),
        reprise: reprise ?? _Reprise(_enCours),
        taille: taille,
        themeMode: theme,
        direction: langue == AppLocale.ar ? TextDirection.rtl : null,
        accordsFaits: accordsFaits,
        pieceDeposee: pieceDeposee,
        horsLigne: horsLigne,
        depart: depart,
        attendre: attendre,
        avecAvis: true,
        avecMessagerie: true,
      );
    }

    // L'etat du dossier, comme la maquette : telephone, clair et sombre,
    // francais et arabe.
    for (final (AppLocale langue, String l) in <(AppLocale, String)>[
      (AppLocale.fr, 'fr'),
      (AppLocale.ar, 'ar'),
    ]) {
      for (final (ThemeMode theme, String th) in <(ThemeMode, String)>[
        (ThemeMode.light, 'clair'),
        (ThemeMode.dark, 'sombre'),
      ]) {
        testWidgets('dossier 390 $l $th', (WidgetTester tester) async {
          await monter(
            tester,
            langue: langue,
            theme: theme,
            taille: const Size(390, 844),
            accordsFaits: false,
          );
          await capturerVue(tester, '$d/dossier-390-$l-$th');
          if (l == 'fr' && th == 'clair') {
            // La fin du defilement : la derniere ligne se lit en entier,
            // au-dessus de la barre.
            await tester.drag(
              find.byKey(OngletDossier.cleAFaire),
              const Offset(0, -2000),
            );
            await tester.pumpAndSettle();
            await capturerVue(tester, '$d/dossier-390-fin-de-page');
          }
        });
      }
    }

    for (final (Size taille, String s) in <(Size, String)>[
      (const Size(390, 844), '390'),
      (const Size(1440, 900), '1440'),
    ]) {
      testWidgets('trois onglets $s', (WidgetTester tester) async {
        await monter(
          tester,
          langue: AppLocale.fr,
          theme: ThemeMode.light,
          taille: taille,
          accordsFaits: false,
        );
        await capturerVue(tester, '$d/onglet-dossier-$s');
        await versOnglet(tester, t.recrutement.accueil.onglets.messages);
        await capturerVue(tester, '$d/onglet-messages-$s');
        await versOnglet(tester, t.recrutement.accueil.onglets.academie);
        await capturerVue(tester, '$d/onglet-academie-$s');
      });
    }

    // Les trois rubriques de Messages (directeur, 20/11/2026) : le premier
    // etat de chacune, francais et arabe, au telephone.
    for (final (AppLocale langue, String l) in <(AppLocale, String)>[
      (AppLocale.fr, 'fr'),
      (AppLocale.ar, 'ar'),
    ]) {
      testWidgets('rubriques de Messages 390 $l', (WidgetTester tester) async {
        final bool ar = langue == AppLocale.ar;
        AnnonceRecue annonce(
          String id,
          String titre,
          String texte,
          int jours, {
          bool vue = false,
        }) => AnnonceRecue(
          id: id,
          titre: titre,
          texte: texte,
          publieeLe: _le.subtract(Duration(days: jours)),
          vue: vue,
        );
        // Donnees fictives.
        final _Fil fil = _Fil(
          recues: <AnnonceRecue>[
            if (ar) ...<AnnonceRecue>[
              annonce(
                'a1',
                'تُفتح المقابلات يوم الاثنين',
                'ستُعرض المواعيد هنا صباح الاثنين.',
                0,
              ),
              annonce(
                'a2',
                'تذكير بالوثائق',
                'تأكد من إرسال وثيقة الهوية قبل المقابلة.',
                2,
              ),
              annonce(
                'a3',
                'أهلًا بالمترشحين الجدد',
                'شكرًا لاهتمامكم بالتدريس في الأكاديمية.',
                5,
                vue: true,
              ),
            ] else ...<AnnonceRecue>[
              annonce(
                'a1',
                'Les entretiens ouvrent lundi',
                'Des créneaux seront proposés ici dès lundi matin.',
                0,
              ),
              annonce(
                'a2',
                'Rappel sur les pièces',
                'Vérifiez que votre pièce d’identité est envoyée avant l’entretien.',
                2,
              ),
              annonce(
                'a3',
                'Bienvenue aux nouveaux candidats',
                'Merci de votre intérêt pour l’enseignement à l’académie.',
                5,
                vue: true,
              ),
            ],
          ],
        );
        for (final (SectionMessages section, String nom)
            in <(SectionMessages, String)>[
              (SectionMessages.messages, 'messages'),
              (SectionMessages.annonces, 'annonces'),
              (SectionMessages.savoir, 'savoir'),
            ]) {
          await monter(
            tester,
            langue: langue,
            theme: ThemeMode.light,
            taille: const Size(390, 844),
            fil: fil,
            depart: AccueilCandidat.cheminMessages(section),
          );
          await capturerVue(tester, '$d/rubrique-$nom-390-$l');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    }

    testWidgets('etats', (WidgetTester tester) async {
      const Size tel = Size(390, 844);
      // Contenu, une ligne depliee.
      await monter(
        tester,
        langue: AppLocale.fr,
        theme: ThemeMode.light,
        taille: tel,
        pieceDeposee: false,
      );
      await toucherCle(tester, 'dossier-ligne-piece');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(OngletDossier.cleDetail('piece')));
      await tester.pumpAndSettle();
      await capturerVue(tester, '$d/etat-contenu-ligne-depliee');
    });

    // Praxis s'endort apres vingt secondes sans geste (regle de la brique) :
    // les autres captures, prises apres l'attente du banc, le montrent
    // endormi. Celle-ci le montre a l'arrivee, eveille.
    testWidgets('dossier a l arrivee, Praxis eveille', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        langue: AppLocale.fr,
        theme: ThemeMode.light,
        taille: const Size(390, 844),
        accordsFaits: false,
        attendre: false,
      );
      await tester.pump();
      // Deux secondes et demie : tout est pose, Praxis est eveille.
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(PraxisDuDossier.cle), findsOneWidget);
      await capturerVue(tester, '$d/dossier-390-arrivee-praxis');
      await tester.pumpAndSettle();
    });

    testWidgets('etat rien a faire', (WidgetTester tester) async {
      await monter(
        tester,
        langue: AppLocale.fr,
        theme: ThemeMode.light,
        taille: const Size(390, 844),
        candidature: _enExamen,
        fil: _Fil(),
      );
      await capturerVue(tester, '$d/etat-rien-a-faire');
    });

    testWidgets('etat erreur et hors connexion', (WidgetTester tester) async {
      for (final (bool horsLigne, String nom) in <(bool, String)>[
        (false, 'etat-erreur'),
        (true, 'etat-hors-connexion'),
      ]) {
        final FauxServiceDossier dossier = await _accueil(
          tester,
          _enExamen,
          horsLigne: horsLigne,
        );
        dossier.erreurAJeter = Exception('panne');
        await _toucher(tester, find.byKey(OngletDossier.cleActualiser));
        // La phrase qui dit l'etat est en haut de la page : on la montre.
        await tester.ensureVisible(find.byKey(OngletDossier.clePerime));
        await tester.pumpAndSettle();
        await capturerVue(tester, '$d/$nom');
        // Chaque etat a son hote : le suivant repart d'un arbre vide.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('etat vide (Annonces)', (WidgetTester tester) async {
      await monter(
        tester,
        langue: AppLocale.fr,
        theme: ThemeMode.light,
        taille: const Size(390, 844),
        fil: _Fil(),
        depart: AccueilCandidat.cheminMessages(SectionMessages.annonces),
      );
      await capturerVue(tester, '$d/etat-vide-annonces');
    });

    testWidgets('annonce longue ouverte', (WidgetTester tester) async {
      // Donnee fictive : un texte long, coupe dans la carte, entier une fois
      // la carte touchee.
      final _Fil fil = _Fil(
        recues: <AnnonceRecue>[
          AnnonceRecue(
            id: 'long',
            titre: 'Comment se passent les entretiens',
            texte: List<String>.filled(
              6,
              'Chaque entretien dure une trentaine de minutes, en visio, avec '
              'une personne de la direction.',
            ).join(' '),
            publieeLe: _le,
          ),
        ],
      );
      await monter(
        tester,
        langue: AppLocale.fr,
        theme: ThemeMode.light,
        taille: const Size(390, 844),
        fil: fil,
        depart: AccueilCandidat.cheminMessages(SectionMessages.annonces),
      );
      await capturerVue(tester, '$d/annonce-longue-carte');
      await _toucher(tester, find.byKey(AnnoncesCandidat.cleCarte('long')));
      await capturerVue(tester, '$d/annonce-longue-ouverte');
    });

    testWidgets('etat chargement (Annonces)', (WidgetTester tester) async {
      await monter(
        tester,
        langue: AppLocale.fr,
        theme: ThemeMode.light,
        taille: const Size(390, 844),
        fil: _Fil(jamais: true),
        depart: AccueilCandidat.cheminMessages(SectionMessages.annonces),
        attendre: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await capturerVue(tester, '$d/etat-chargement-annonces');
      await tester.pump(const Duration(days: 2));
    });

    testWidgets('parcours du retrait', (WidgetTester tester) async {
      final FauxMaCandidature port = FauxMaCandidature();
      final _Reprise reprise = _Reprise(_enCours);
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
      final FauxServiceDossier dossier = await _accueil(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienPlanifie,
          version: 5,
        ),
        port: port,
        reprise: reprise,
        avecAvis: true,
      );
      await versOnglet(tester, t.recrutement.accueil.onglets.academie);
      await toucherCle(tester, 'academie-reglages');
      await tester.ensureVisible(_cle('retrait-lien'));
      await tester.pumpAndSettle();
      await capturerVue(tester, '$d/retrait-1-reglages');
      await toucherCle(tester, 'retrait-lien');
      await capturerVue(tester, '$d/retrait-2-explication');
      dossier.etatRendu = etatCandidat(
        candidature: const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
          issue: IssueCandidature.retiree,
          version: 6,
        ),
      );
      reprise.lue = _repriseOuverte();
      await tester.tap(_texte(t.recrutement.accueil.retrait.confirmer).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await capturerVue(tester, '$d/retrait-3-retiree-avis');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await capturerVue(tester, '$d/retrait-4-reprise-proposee');
      dossier.etatRendu = etatCandidat(candidature: _salle2);
      reprise.lue = _enCours;
      await tester.tap(find.byKey(CarteReprise.cleBouton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await capturerVue(tester, '$d/retrait-5-reprise-faite');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('reprise fermee apres 7 jours', (WidgetTester tester) async {
      await monter(
        tester,
        langue: AppLocale.fr,
        theme: ThemeMode.light,
        taille: const Size(390, 844),
        candidature: _retiree,
        fil: _Fil(),
        reprise: _Reprise(
          const RepriseCandidature(
            retiree: true,
            possible: false,
            delaiJours: 7,
            raison: RaisonRepriseFermee.delaiDepasse,
          ),
        ),
      );
      await capturerVue(tester, '$d/retrait-6-delai-passe');
    });
  }, skip: sautSansCapture);
}
