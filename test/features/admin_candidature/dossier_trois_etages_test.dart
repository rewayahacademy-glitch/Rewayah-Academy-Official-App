// BE-DOSSIER (directeur, 16/11/2026) : le dossier en trois etages. Un test par
// ligne du cahier `CAHIER-BE-DOSSIER.md`, plus les cas de refus.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_entretien_direction.dart';
import 'package:rewayah_academy/core/candidature/photo_dossier_candidat.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_entretiens_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
import 'package:rewayah_academy/features/candidature/libelles_parcours.dart'
    show libelleHeure;
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart'
    show ConversationEnPlace;

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser, monterRecrutement;
import 'hote_candidature.dart';

FauxCandidaturesDirection _port(
  DetailCandidature detail, {
  CapacitesCandidatures capacites = capacitesGestes,
  Map<String, MoyensConfirmes> moyens = const <String, MoyensConfirmes>{
    'SN': MoyensConfirmes(
      virementBancaire: true,
      operateurs: <OperateurPaiement>[
        OperateurPaiement(code: 'orange_money', nom: 'Orange Money'),
      ],
    ),
  },
}) => FauxCandidaturesDirection(
  capacitesRendues: capacites,
  details: <DetailCandidature>[detail],
  moyens: moyens,
);

List<ControleCandidature> _controles({
  bool paiement = true,
  bool accords = true,
  bool entretien = true,
  bool piece = true,
}) => <ControleCandidature>[
  ControleCandidature(nom: 'paiement_compatible', valeur: paiement),
  ControleCandidature(nom: 'accords_signes', valeur: accords),
  ControleCandidature(nom: 'cadre_religieux', valeur: accords),
  ControleCandidature(nom: 'entretien_conclu', valeur: entretien),
  ControleCandidature(nom: 'piece_validee', valeur: piece),
];

/// Le port des entretiens, sans aucun entretien : la ligne « Entretien »
/// existe seulement quand le serveur le sert (jamais de texte technique).
class _EntretiensVide implements PortEntretiensDirection {
  @override
  Future<List<EntretienCandidature>> entretiens(String candidatureId) async =>
      const <EntretienCandidature>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _monter(
  WidgetTester tester, {
  required FauxCandidaturesDirection port,
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  TextDirection? direction,
  List<Override> surcharges = const <Override>[],
}) => monterCandidature(
  tester,
  port: port,
  horsLigne: horsLigne,
  largeur: largeur,
  hauteur: hauteur,
  direction: direction,
  surcharges: <Override>[
    portEntretiensDirectionProvider.overrideWithValue(_EntretiensVide()),
    ...surcharges,
  ],
  // Ces tests regardent le dossier tel qu'il s'ouvre : replie.
  ouvrirRubriques: false,
);

Future<void> _tapper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await laisser(tester, fois: 2);
  await tester.tap(f, warnIfMissed: false);
  await laisser(tester);
}

String _texte(WidgetTester tester) => <String>[
  for (final Element e in find.byType(Text).evaluate())
    if ((e.widget as Text).data case final String d) d,
].join('\n');

Finder _rubrique(RubriqueDossierCode c) => find.byKey(RubriqueDossier.cleDe(c));

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('etage 1 : en haut, fixe', () {
    testWidgets('nom, reference, photo, situation en une phrase', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest(paiement: EtatVersement.compatible)),
      );
      expect(find.text('Amina Diallo'), findsWidgets);
      expect(find.text('CAND‑0000C1'), findsOneWidget);
      expect(find.byKey(EtageUnDossier.cle), findsOneWidget);
      // Qui doit agir, et sur quoi.
      expect(
        find.text(
          t.recrutement.dossier3.situation.vous(
            geste: t.admin.candidatures.gestes.admettre,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('« Il reste : ... » dit ce qui reste a faire, en verbes', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(
          detailTest(
            paiement: EtatVersement.compatible,
            controles: _controles(entretien: false),
          ),
        ),
      );
      final Finder reste = find.byKey(EtageUnDossier.cleReste);
      expect(reste, findsOneWidget);
      final String phrase = (tester.widget(reste) as dynamic).texte as String;
      // Des verbes, pas des etats qui se liraient comme faits.
      expect(
        phrase,
        contains(t.recrutement.dossier3.situation.aFaire.entretien_conclu),
      );
      expect(phrase, startsWith('Il reste'));
      expect(
        phrase,
        isNot(contains(t.admin.candidatures.controles.noms.entretienConclu)),
      );
      expect(find.textContaining('Ce qui bloque'), findsNothing);
      // Plus de bloc « Ce qui bloque » : un titre de section de moins.
      expect(find.byKey(BlocBlocages.cle), findsNothing);
    });

    testWidgets('en attente de la personne : elle seule est nommee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest(etat: EtatCandidature.aCompleter)),
      );
      expect(
        find.descendant(
          of: find.byKey(EtageUnDossier.cle),
          matching: find.text(t.admin.candidatures.detail.enAttentePersonne),
        ),
        findsOneWidget,
      );
    });
  });

  /// Les lignes du tableau de synthese, dans l'ordre : libelle puis valeur.
  List<(String, String)> lignesDeSynthese(WidgetTester tester) {
    final List<String> textes = <String>[
      for (final Element e
          in find
              .descendant(
                of: find.byKey(ResumeDossier.cleTableau),
                matching: find.byType(TexteSansCoupure),
              )
              .evaluate())
        (e.widget as TexteSansCoupure).texte,
    ];
    return <(String, String)>[
      for (int i = 0; i + 1 < textes.length; i += 2) (textes[i], textes[i + 1]),
    ];
  }

  /// Les lignes du profil, sur la carte du haut : libelle puis valeur.
  List<(String, String)> lignesDeProfil(WidgetTester tester) {
    final List<String> textes = <String>[
      for (final Element e
          in find
              .descendant(
                of: find.byKey(EtageUnDossier.cleProfil),
                matching: find.byType(Text),
              )
              .evaluate())
        if ((e.widget as Text).data case final String d) d,
    ];
    return <(String, String)>[
      for (int i = 0; i + 1 < textes.length; i += 2) (textes[i], textes[i + 1]),
    ];
  }

  group('etage 2 : la synthese en tableau', () {
    final s = t.recrutement.dossier3.synthese;
    final String sep = t.admin.candidatures.historique.separateur;

    testWidgets(
      'un libelle court, une valeur en mots-cles, une ligne par critere',
      (WidgetTester tester) async {
        await _monter(tester, port: _port(detailTest()));
        expect(find.byKey(ResumeDossier.cleTableau), findsOneWidget);
        expect(find.byType(Table), findsWidgets);
        // Langues, memorisation et ijaza sont sur la carte de profil.
        expect(lignesDeProfil(tester), <(String, String)>[
          (s.langues, <String>['Poular', 'Français', 'Wolof'].join(sep)),
          (s.memorisation, s.memorisationValeurs.de_10_a_29_juz),
          (s.ijaza, s.ijazaValeurs.pret_test),
        ]);
        expect(lignesDeSynthese(tester), <(String, String)>[
          (
            s.disponibilites,
            // Les jours sur une ligne, les heures en plage sur la suivante.
            '${<String>[s.jours.j1, s.jours.j3].join(sep)}\n'
                '${libelleHeure(18)} – ${libelleHeure(19)}',
          ),
          (
            s.versement,
            <String>[
              'Sénégal',
              t.admin.candidatures.moyens.virement,
              'Orange Money',
            ].join(sep),
          ),
          (
            s.public,
            <String>[s.publicValeurs.k1013, s.publicValeurs.adultes].join(sep),
          ),
        ]);
      },
    );

    testWidgets(
      'jamais la phrase du candidat, ni texte technique, ni compteur',
      (WidgetTester tester) async {
        await _monter(tester, port: _port(detailTest()));
        final String texte = lignesDeSynthese(tester)
            .map(((String, String) l) => '${l.$1} ${l.$2}')
            .join('\n');
        // La phrase du questionnaire (« J'ai memorise de 10 a 29 juz... »)
        // n'est pas dans la synthese.
        expect(texte, isNot(contains("J'ai mémorisé")));
        expect(texte, isNot(contains('mais je peux passer')));
        expect(texte, isNot(contains('Moyens indiqu')));
        expect(texte, isNot(contains('salle-examen')));
        expect(_texte(tester), isNot(contains('salle-examen')));
        expect(
          _texte(tester),
          isNot(
            contains(
              t.admin.candidatures.detail.reponsesVersion(
                version: 'salle-examen-1',
              ),
            ),
          ),
        );
      },
    );

    testWidgets('sans nom de moyen : le pays et le virement, jamais un code', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest(), moyens: const <String, MoyensConfirmes>{}),
      );
      final Map<String, String> m = <String, String>{
        for (final (String, String) l in lignesDeSynthese(tester)) l.$1: l.$2,
      };
      expect(
        m[s.versement],
        <String>['Sénégal', t.admin.candidatures.moyens.virement].join(sep),
      );
      expect(_texte(tester), isNot(contains('orange_money')));
    });

    testWidgets(
      'une valeur longue passe a la ligne, jamais tronquee en silence',
      (WidgetTester tester) async {
        await _monter(tester, port: _port(detailTest()), largeur: 320);
        for (final Element e
            in find
                .descendant(
                  of: find.byKey(ResumeDossier.cleTableau),
                  matching: find.byType(TexteSansCoupure),
                )
                .evaluate()) {
          final TexteSansCoupure w = e.widget as TexteSansCoupure;
          expect(w.maxLignes, isNull, reason: w.texte);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'en arabe, le tableau se retourne et les chiffres restent latins',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(
          tester,
          port: _port(detailTest()),
          direction: TextDirection.rtl,
        );
        final Rect tableau = tester.getRect(
          find.byKey(ResumeDossier.cleTableau),
        );
        final Finder libelle = find.descendant(
          of: find.byKey(ResumeDossier.cleTableau),
          matching: find.text(t.recrutement.dossier3.synthese.disponibilites),
        );
        expect(libelle, findsWidgets);
        // Le libelle est au bord de debut : a droite en arabe.
        expect(
          tester.getRect(libelle.first).right,
          greaterThan(tableau.center.dx),
        );
        final String valeurs = lignesDeSynthese(tester)
            .map(((String, String) l) => l.$2)
            .join('\n');
        expect(valeurs, contains('13'));
        expect(valeurs, contains('18'));
        expect(valeurs, isNot(contains('١')));
        // Les valeurs a chiffres sont isolees dans leur sens de lecture.
        expect(valeurs, contains('\u2068'));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('accords : emplacement de la majorite', () {
    Future<void> monterCorps(WidgetTester tester, {String? majorite}) async {
      final DetailCandidature detail = detailTest(
        paiement: EtatVersement.compatible,
        controles: _controles(),
      );
      await monterRecrutement(
        tester,
        chemin: '/corps',
        ecran: (_) => Scaffold(
          body: SingleChildScrollView(
            child: CorpsDossier(
              plan: PlanDossier(
                detail: detail,
                capacites: capacitesGestes,
                horsLigne: false,
              ),
              deuxColonnes: false,
              onGeste: (GesteCandidature _) {},
              onDemanderElement: (String _) {},
              onOuvrirDossier: () {},
              onEntretien: (String _) {},
              onOuvrirConversation: (ConversationEnPlace _) {},
              ligneMajorite: majorite,
            ),
          ),
        ),
        surcharges: <Override>[
          portCandidaturesDirectionProvider.overrideWithValue(_port(detail)),
        ],
        hauteur: 3000,
      );
    }

    testWidgets('sans phrase (champ pas encore servi) : rien', (
      WidgetTester tester,
    ) async {
      await monterCorps(tester);
      expect(find.byKey(CorpsDossier.cleMajorite), findsNothing);
    });

    testWidgets('avec une phrase : elle est dans la ligne Accords', (
      WidgetTester tester,
    ) async {
      await monterCorps(tester, majorite: 'Phrase de majorite');
      expect(
        find.descendant(
          of: find.byKey(RubriqueDossier.cleDe(RubriqueDossierCode.accords)),
          matching: find.byKey(CorpsDossier.cleMajorite),
        ),
        findsOneWidget,
      );
    });
  });

  group('etage 3 : les rubriques', () {
    testWidgets('repliees au depart, chacune avec sa pastille', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(
          detailTest(
            paiement: EtatVersement.compatible,
            piece: EtatPiece.deposee,
            controles: _controles(),
          ),
        ),
      );
      for (final RubriqueDossierCode c in <RubriqueDossierCode>[
        RubriqueDossierCode.piece,
        RubriqueDossierCode.versement,
        RubriqueDossierCode.accords,
        RubriqueDossierCode.langues,
        RubriqueDossierCode.entretien,
        RubriqueDossierCode.responsable,
        RubriqueDossierCode.contact,
        RubriqueDossierCode.historique,
      ]) {
        expect(_rubrique(c), findsOneWidget, reason: c.name);
      }
      // Replies : seules celles de beaucoup d'informations (historique,
      // reponses detaillees, autres competences) ; le contenu n'est pas
      // construit. Les autres sont affichees d'emblee, sans fleche.
      expect(find.byKey(BlocHistorique.cle), findsNothing);
      for (final RubriqueDossierCode c in <RubriqueDossierCode>[
        RubriqueDossierCode.piece,
        RubriqueDossierCode.versement,
        RubriqueDossierCode.entretien,
        RubriqueDossierCode.responsable,
        RubriqueDossierCode.contact,
      ]) {
        expect(
          find.byKey(RubriqueDossier.cleContenu(c)),
          findsOneWidget,
          reason: '${c.name} affichee d\'emblee',
        );
        expect(
          find.byKey(RubriqueDossier.cleEntete(c)),
          findsNothing,
          reason: '${c.name} sans repli',
        );
      }
      expect(
        find.byKey(RubriqueDossier.cleContenu(RubriqueDossierCode.langues)),
        findsNothing,
      );
      // Pastilles : bon, a voir, manque.
      String pastille(RubriqueDossierCode c) =>
          (tester.widget(
                find.byKey(RubriqueDossier.clePastille(c)),
              ) as dynamic).libelle
              as String;
      final p = t.recrutement.dossier3.pastille;
      expect(pastille(RubriqueDossierCode.versement), p.bon);
      expect(pastille(RubriqueDossierCode.piece), p.aVoir);
      // Le responsable ne « manque » jamais : pas de pastille.
      expect(
        find.byKey(
          RubriqueDossier.clePastille(RubriqueDossierCode.responsable),
        ),
        findsNothing,
      );
      expect(
        find.byKey(RubriqueDossier.clePastille(RubriqueDossierCode.contact)),
        findsNothing,
      );
    });

    testWidgets('l\'entretien ne « manque » que quand il est du', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(
          detailTest(controles: _controles(entretien: false, piece: true)),
        ),
      );
      // Avant la Salle de verification et d'entretien : pas encore du.
      expect(
        find.byKey(RubriqueDossier.clePastille(RubriqueDossierCode.entretien)),
        findsNothing,
      );
      await _monter(
        tester,
        port: _port(
          detailTest(
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
            controles: _controles(entretien: false),
          ),
        ),
      );
      expect(
        find.byKey(RubriqueDossier.clePastille(RubriqueDossierCode.entretien)),
        findsOneWidget,
      );
    });

    testWidgets('« Contrôles » disparait comme bloc', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest(controles: _controles())));
      expect(find.byKey(BlocControles.cle), findsNothing);
      expect(find.text(t.admin.candidatures.detail.controles), findsNothing);
    });

    testWidgets(
      'la rubrique qui bloque s\'ouvre d\'elle-meme, pas les autres',
      (WidgetTester tester) async {
        await _monter(
          tester,
          port: _port(
            detailTest(
              paiement: EtatVersement.compatible,
              controles: _controles(accords: false),
            ),
          ),
        );
        // Les accords bloquent : ils s'ouvrent (leurs lignes de controle).
        expect(find.byType(LigneControleDossier), findsWidgets);
        // L'historique, lui, reste replie.
        expect(find.byKey(BlocHistorique.cle), findsNothing);
      },
    );

    testWidgets('toucher une rubrique l\'ouvre, puis la referme', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()));
      final Finder entete = find.byKey(
        RubriqueDossier.cleEntete(RubriqueDossierCode.historique),
      );
      await _tapper(tester, entete);
      expect(find.byKey(BlocHistorique.cle), findsOneWidget);
      await _tapper(tester, entete);
      expect(find.byKey(BlocHistorique.cle), findsNothing);
    });

    testWidgets('le geste est a cote de sa rubrique, replie, et il marche', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()));
      // Versement a verifier : confirmer ou ecarter le moyen, sans ouvrir.
      final Finder confirmer = find.byKey(
        const ValueKey<String>('rubrique-geste-confirmerMoyenPaiement'),
      );
      expect(confirmer, findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('rubrique-geste-infirmerMoyenPaiement'),
        ),
        findsOneWidget,
      );
      await _tapper(tester, confirmer);
      expect(find.byKey(FeuilleGeste.cleValider), findsOneWidget);
    });

    testWidgets('« demander une precision » est a cote de chaque groupe', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()));
      for (final String code in <String>[
        'langues',
        'recitation',
        'disponibilites',
        'publics',
      ]) {
        expect(
          find.byKey(ValueKey<String>('rubrique-demander-$code')),
          findsOneWidget,
          reason: code,
        );
      }
      await _tapper(
        tester,
        find.byKey(const ValueKey<String>('rubrique-demander-langues')),
      );
      // La feuille du complement s'ouvre, l'element deja coche.
      expect(find.byKey(FeuilleGeste.cleValider), findsOneWidget);
    });

    testWidgets('un geste que le serveur ne propose pas n\'a pas de lien', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(
          detailTest(),
          capacites: const CapacitesCandidatures(
            peutLire: true,
            genreLecteurConnu: true,
            peutDecider: true,
            gestes: <String, bool>{'mettreEnPause': true},
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey<String>('rubrique-geste-confirmerMoyenPaiement'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('rubrique-demander-langues')),
        findsNothing,
      );
    });

    testWidgets('hors ligne : aucun lien de geste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()), horsLigne: true);
      expect(
        find.byKey(
          const ValueKey<String>('rubrique-geste-confirmerMoyenPaiement'),
        ),
        findsNothing,
      );
      expect(find.byKey(BarreDecisionDossier.cleMenu), findsNothing);
    });

    testWidgets('responsable : le nom quand le serveur le rend', (
      WidgetTester tester,
    ) async {
      final DetailCandidature d = detailTest(responsableId: 'r1');
      await _monter(
        tester,
        port: _port(
          DetailCandidature(
            ligne: d.ligne,
            version: d.version,
            documents: d.documents,
            provenance: d.provenance,
            responsableNom: 'Sayyida Mariam',
          ),
        ),
      );
      expect(find.text('Sayyida Mariam'), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.detail.responsableDesigne),
        findsNothing,
      );
    });

    testWidgets('responsable sans nom rendu : « designe », sans inventer', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest(responsableId: 'r1')));
      expect(
        find.text(t.admin.candidatures.detail.responsableDesigne),
        findsOneWidget,
      );
    });

    testWidgets(
      'historique : les dates et la provenance vivent ici, sans texte technique',
      (WidgetTester tester) async {
        await _monter(tester, port: _port(detailTest()));
        await _tapper(
          tester,
          find.byKey(RubriqueDossier.cleEntete(RubriqueDossierCode.historique)),
        );
        expect(find.byType(LignesDatesDossier), findsOneWidget);
        expect(_texte(tester), isNot(contains('salle-examen')));
      },
    );
  });

  group('ouvrir ou fermer une rubrique : la page ne saute pas', () {
    double hautDuTitre(WidgetTester tester, RubriqueDossierCode c) =>
        tester.getTopLeft(find.byKey(RubriqueDossier.cleEntete(c))).dy;

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    testWidgets(
      'le titre touche reste a la meme place, a l\'ouverture et a la fermeture',
      (WidgetTester tester) async {
        await _monter(tester, port: _port(detailTest()), hauteur: 800);
        const RubriqueDossierCode cible = RubriqueDossierCode.historique;
        final Finder entete = find.byKey(RubriqueDossier.cleEntete(cible));
        final double repliee = position(tester).maxScrollExtent;

        // Ouverture : le titre touche ne bouge pas, image par image ; le
        // contenu s'ouvre dessous.
        await tester.ensureVisible(entete);
        await laisser(tester, fois: 2);
        final double avant = hautDuTitre(tester, cible);
        await tester.tap(entete, warnIfMissed: false);
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 30));
          expect(
            (hautDuTitre(tester, cible) - avant).abs(),
            lessThan(1),
            reason: 'ouverture, image $i',
          );
        }
        await laisser(tester);
        expect(find.byKey(RubriqueDossier.cleContenu(cible)), findsOneWidget);
        final double ouverte = position(tester).maxScrollExtent;
        expect(ouverte, greaterThan(repliee));

        // Fermeture : la page se raccourcit, elle s'arrete au dernier contenu.
        // Aucune place n'est gardee : elle revient a la longueur d'avant.
        await tester.tap(entete, warnIfMissed: false);
        await laisser(tester);
        expect(find.byKey(RubriqueDossier.cleContenu(cible)), findsNothing);
        expect(position(tester).maxScrollExtent, closeTo(repliee, 1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'la hauteur s\'anime : une image du milieu est entre replie et deplie',
      (WidgetTester tester) async {
        await _monter(tester, port: _port(detailTest()));
        const RubriqueDossierCode c = RubriqueDossierCode.historique;
        final Finder rubrique = find.byKey(RubriqueDossier.cleDe(c));
        final double replie = tester.getSize(rubrique).height;
        await _tapper(tester, find.byKey(RubriqueDossier.cleEntete(c)));
        final double deplie = tester.getSize(rubrique).height;
        expect(deplie, greaterThan(replie));

        await tester.tap(
          find.byKey(RubriqueDossier.cleEntete(c)),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final double milieu = tester.getSize(rubrique).height;
        expect(milieu, lessThan(deplie));
        expect(milieu, greaterThan(replie));
        await laisser(tester);
        expect(tester.getSize(rubrique).height, replie);
      },
    );
  });

  group('largeurs des pliables : 360, 673, 884, 1366', () {
    for (final double largeur in <double>[360, 673, 884, 1366]) {
      testWidgets(
        '$largeur : aucun debordement, rubriques ouvertes comprises',
        (WidgetTester tester) async {
          await _monter(
            tester,
            port: _port(detailTest(paiement: EtatVersement.compatible)),
            largeur: largeur,
            hauteur: 900,
          );
          expect(tester.takeException(), isNull);
          await ouvrirToutesLesRubriques(tester);
          expect(tester.takeException(), isNull);
          final bool deux = largeur >= 840;
          final double xEtage = tester
              .getTopLeft(find.byKey(EtageUnDossier.cle))
              .dx;
          final double xRubriques = tester
              .getTopLeft(find.byKey(CorpsDossier.cle))
              .dx;
          if (deux) {
            expect(xRubriques, greaterThan(xEtage + 200), reason: '$largeur');
          } else {
            expect(
              (xRubriques - xEtage).abs(),
              lessThan(40),
              reason: '$largeur',
            );
          }
        },
      );
    }

    testWidgets(
      'changer de largeur a la volee, plie vers deplie et retour, sans erreur',
      (WidgetTester tester) async {
        await _monter(
          tester,
          port: _port(detailTest(paiement: EtatVersement.compatible)),
          largeur: 360,
          hauteur: 900,
        );
        await ouvrirToutesLesRubriques(tester);
        for (final double largeur in <double>[
          360,
          673,
          884,
          1366,
          884,
          673,
          360,
        ]) {
          tester.view.physicalSize = Size(largeur, 900);
          await laisser(tester, fois: 3);
          expect(tester.takeException(), isNull, reason: 'a $largeur');
          // Le dossier est toujours la, ses rubriques ouvertes le restent.
          expect(find.byKey(EtageUnDossier.cle), findsOneWidget);
          expect(find.byKey(ResumeDossier.cle), findsOneWidget);
          expect(
            find.byKey(
              RubriqueDossier.cleContenu(RubriqueDossierCode.historique),
            ),
            findsOneWidget,
            reason: 'a $largeur',
          );
        }
      },
    );
  });

  group('la photo s\'affiche quand on la touche', () {
    final List<Override> surcharges = <Override>[
      portPhotoDossierProvider.overrideWithValue(_Photo()),
      portPhotosProvider.overrideWithValue(const _Photos()),
      imagePieceProvider.overrideWithValue((Uri _) => MemoryImage(_pixel)),
    ];

    testWidgets('un toucher : plein ecran, sans bouton « voir en grand »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()), surcharges: surcharges);
      expect(find.byKey(EtageUnDossier.clePhoto), findsOneWidget);
      expect(find.byKey(EtageUnDossier.clePhotoEnGrand), findsNothing);
      await _tapper(tester, find.byKey(EtageUnDossier.clePhoto));
      expect(find.byKey(EtageUnDossier.clePhotoEnGrand), findsOneWidget);
      // Fermeture par le retour.
      final NavigatorState nav = tester.state(find.byType(Navigator).last);
      await nav.maybePop();
      await laisser(tester);
      expect(find.byKey(EtageUnDossier.clePhotoEnGrand), findsNothing);
    });

    testWidgets('aucun bouton « voir en grand » : le mot n\'existe pas', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()), surcharges: surcharges);
      expect(_texte(tester).toLowerCase(), isNot(contains('en grand')));
    });
  });

  group('barre de decision : sous le resume, rien de fixe', () {
    testWidgets('accepter, demander, refuser : les trois, a la fois', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest(paiement: EtatVersement.compatible)),
      );
      expect(find.byKey(BarreDecisionDossier.cle), findsOneWidget);
      for (final GesteCandidature g in <GesteCandidature>[
        GesteCandidature.admettreVerifications,
        GesteCandidature.demanderComplement,
        GesteCandidature.refuser,
      ]) {
        expect(find.byKey(BarreDecisionDossier.cleBouton(g)), findsOneWidget);
      }
    });

    testWidgets(
      'un geste qui ne peut pas aboutir n\'est pas rendu : une phrase dit pourquoi',
      (WidgetTester tester) async {
        await _monter(
          tester,
          port: _port(detailTest(etat: EtatCandidature.aCompleter)),
        );
        // La personne doit repondre : accepter et demander ne sont pas rendus.
        for (final GesteCandidature g in <GesteCandidature>[
          GesteCandidature.admettreVerifications,
          GesteCandidature.demanderComplement,
        ]) {
          expect(find.byKey(BarreDecisionDossier.cleBouton(g)), findsNothing);
        }
        expect(
          find.byKey(
            BarreDecisionDossier.cleRaison(
              GesteCandidature.admettreVerifications,
            ),
          ),
          findsOneWidget,
        );
        expect(_texte(tester), contains(t.recrutement.dossier3.raison.attente));
        // Refuser reste permis : il est rendu.
        expect(
          find.byKey(BarreDecisionDossier.cleBouton(GesteCandidature.refuser)),
          findsOneWidget,
        );
      },
    );

    testWidgets('juste sous le resume, et rien de colle en bas', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest(paiement: EtatVersement.compatible)),
      );
      final double resume = tester
          .getBottomLeft(find.byKey(ResumeDossier.cle))
          .dy;
      final double barre = tester
          .getTopLeft(find.byKey(BarreDecisionDossier.cle))
          .dy;
      final double rubriques = tester
          .getTopLeft(find.byKey(CorpsDossier.cle))
          .dy;
      expect(barre, greaterThanOrEqualTo(resume));
      expect(rubriques, greaterThan(barre));
      // Aucune zone d'action collee : la page defile en entier.
      expect(find.byKey(PageShell.zoneActionKey), findsNothing);
    });

    testWidgets('Accepter nomme ce qui manque quand un controle bloque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(
          detailTest(
            controles: _controles(paiement: false),
            paiement: EtatVersement.compatible,
          ),
          capacites: const CapacitesCandidatures(
            peutLire: true,
            genreLecteurConnu: true,
            peutDecider: true,
            gestes: <String, bool>{'refuser': true, 'demanderComplement': true},
          ),
        ),
      );
      expect(
        _texte(tester),
        contains(
          t.recrutement.dossier3.raison.manque(
            liste: t.recrutement.paiement.compatible,
          ),
        ),
      );
    });

    testWidgets('en pause : lever la pause reste visible, pas dans un menu', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest(enPause: true)));
      expect(
        find.byKey(BarreDecisionDossier.cleBouton(GesteCandidature.leverPause)),
        findsOneWidget,
      );
    });

    testWidgets('sans le droit de decider : aucun bouton, la phrase le dit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(
          detailTest(),
          capacites: const CapacitesCandidatures(
            peutLire: true,
            genreLecteurConnu: true,
          ),
        ),
      );
      for (final GesteCandidature g in <GesteCandidature>[
        GesteCandidature.admettreVerifications,
        GesteCandidature.demanderComplement,
        GesteCandidature.refuser,
      ]) {
        expect(find.byKey(BarreDecisionDossier.cleBouton(g)), findsNothing);
      }
      expect(_texte(tester), contains(t.recrutement.dossier3.raison.droit));
    });

    testWidgets('hors ligne : une note, aucun geste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()), horsLigne: true);
      expect(find.text(t.admin.candidatures.erreurs.horsLigne), findsWidgets);
      expect(
        find.byKey(BarreDecisionDossier.cleBouton(GesteCandidature.refuser)),
        findsNothing,
      );
    });

    testWidgets('un seul bouton plein, la barre comprise', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest(paiement: EtatVersement.compatible)),
      );
      final int pleins = find
          .byWidgetPredicate(
            (Widget w) =>
                w.runtimeType.toString() == 'ActionPrincipale' &&
                (w as dynamic).niveau.toString().endsWith('principale'),
          )
          .evaluate()
          .length;
      expect(pleins, 1);
    });
  });

  group(
    'messages : le bandeau « pas en direct » reste dans la conversation',
    () {
      testWidgets('absent de la page, replie', (WidgetTester tester) async {
        await _monter(tester, port: _port(detailTest()));
        expect(find.text(t.com.messages.direct.horsDirect), findsNothing);
      });
    },
  );

  group('ordinateur : etages 1 et 2 a gauche, rubriques a droite', () {
    testWidgets('deux colonnes, une seule barre de defilement', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest()),
        largeur: 1366,
        hauteur: 768,
      );
      final Rect etage1 = tester.getRect(find.byKey(EtageUnDossier.cle));
      final Rect etage2 = tester.getRect(find.byKey(ResumeDossier.cle));
      final Rect rubriques = tester.getRect(find.byKey(CorpsDossier.cle));
      expect(etage1.right, lessThanOrEqualTo(rubriques.left));
      expect(etage2.right, lessThanOrEqualTo(rubriques.left));
      // Une seule zone verticale qui defile : celle de la page.
      final int verticaux = find
          .byType(Scrollable)
          .evaluate()
          .where(
            (Element e) =>
                (e as StatefulElement).state is ScrollableState &&
                ((e.state as ScrollableState).widget.axisDirection ==
                        AxisDirection.down ||
                    (e.state as ScrollableState).widget.axisDirection ==
                        AxisDirection.up),
          )
          .length;
      expect(verticaux, 1);
    });

    testWidgets('en arabe, de droite a gauche : rien ne deborde', (
      WidgetTester tester,
    ) async {
      await LocaleSettings.setLocale(AppLocale.ar);
      await _monter(
        tester,
        port: _port(detailTest(paiement: EtatVersement.compatible)),
        largeur: 360,
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(EtageUnDossier.cle), findsOneWidget);
      expect(find.byKey(BarreDecisionDossier.cle), findsOneWidget);
    });
  });

  group('plan : ce que le dossier decide de montrer', () {
    PlanDossier plan(DetailCandidature d, {bool horsLigne = false}) =>
        PlanDossier(
          detail: d,
          capacites: capacitesGestes,
          horsLigne: horsLigne,
        );

    test('la rubrique qui bloque : la premiere dans l\'ordre d\'affichage', () {
      final PlanDossier p = plan(
        detailTest(controles: _controles(entretien: false, paiement: false)),
      );
      expect(p.rubriqueQuiBloque, RubriqueDossierCode.versement);
    });

    test('aucun controle rendu : aucune rubrique ne s\'ouvre', () {
      expect(plan(detailTest()).rubriqueQuiBloque, isNull);
    });

    test('la prochaine action sans fente reste dans la barre', () {
      final PlanDossier p = plan(detailTest(enPause: true));
      expect(p.principalHorsFentes, GesteCandidature.leverPause);
      expect(p.gestesDuMenu(), isNot(contains(GesteCandidature.leverPause)));
    });

    test('les gestes de rubrique ne vont pas dans le menu', () {
      final PlanDossier p = plan(detailTest());
      expect(
        p.gestesDuMenu(),
        isNot(contains(GesteCandidature.confirmerMoyenPaiement)),
      );
      expect(
        p.gestesDuMenu(),
        isNot(contains(GesteCandidature.definirResponsable)),
      );
    });
  });
}

class _Photo implements PortPhotoDossier {
  @override
  Future<PhotoDossier> lire(String candidatureId) async => PhotoDossier(
    seau: 'photos_enseignants',
    cle: 'p1/1.jpg',
    figeeLe: DateTime.utc(2026, 11, 7, 9, 30),
  );
}

class _Photos extends PhotosNeutres {
  const _Photos();

  @override
  Future<String> urlSignee(String seau, String cle) async =>
      'https://photos.exemple/$seau/$cle';
}

/// Un PNG transparent de 1 x 1.
final Uint8List _pixel = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
  0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);
