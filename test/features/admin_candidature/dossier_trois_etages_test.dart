// BE-DOSSIER (directeur, 16/11/2026) : le dossier en trois etages. Un test par
// ligne du cahier `CAHIER-BE-DOSSIER.md`, plus les cas de refus.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/photo_dossier_candidat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
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
  surcharges: surcharges,
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

  group('etage 2 : le resume', () {
    testWidgets('cinq lignes au plus, et rien de technique', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(detailTest()));
      final Finder resume = find.byKey(ResumeDossier.cle);
      expect(resume, findsOneWidget);
      final r = t.recrutement.dossier3.resume;
      final String texte = <String>[
        for (final Element e
            in find
                .descendant(of: resume, matching: find.byType(RichText))
                .evaluate())
          (e.widget as RichText).text.toPlainText(),
      ].join('\n');
      // Cinq lignes au plus : une ligne de texte par reponse.
      expect(
        find
            .descendant(of: resume, matching: find.byType(MergeSemantics))
            .evaluate()
            .length,
        lessThanOrEqualTo(5),
      );
      for (final String cle in <String>[
        r.langues,
        r.niveau,
        r.disponibilites,
        r.versement,
        r.public,
      ]) {
        expect(texte, contains(cle));
      }
      // Versement : le pays et les moyens nommes, sans compteur.
      expect(texte, contains('${r.versement}\u00a0: '));
      expect(
        texte,
        isNot(contains(t.admin.candidatures.detail.moyensIndiques(n: 1))),
      );
      expect(texte, contains('Orange Money'));
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
    });
  });

  group('etage 2 : le versement sans nom de moyen', () {
    testWidgets('le pays seulement, jamais un compteur ni un code', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(detailTest(), moyens: const <String, MoyensConfirmes>{}),
      );
      final String texte = <String>[
        for (final Element e
            in find
                .descendant(
                  of: find.byKey(ResumeDossier.cle),
                  matching: find.byType(RichText),
                )
                .evaluate())
          (e.widget as RichText).text.toPlainText(),
      ].join('\n');
      expect(texte, contains('Sénégal'));
      expect(texte, isNot(contains('Moyens indiqu')));
      expect(texte, isNot(contains('orange_money')));
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
        RubriqueDossierCode.photo,
        RubriqueDossierCode.piece,
        RubriqueDossierCode.versement,
        RubriqueDossierCode.accords,
        RubriqueDossierCode.langues,
        RubriqueDossierCode.entretien,
        RubriqueDossierCode.messages,
        RubriqueDossierCode.responsable,
        RubriqueDossierCode.contact,
        RubriqueDossierCode.historique,
      ]) {
        expect(_rubrique(c), findsOneWidget, reason: c.name);
      }
      // Repliees : le contenu d'une rubrique n'est pas construit.
      expect(find.byKey(BlocHistorique.cle), findsNothing);
      expect(find.byKey(BlocContact.cle), findsNothing);
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
      await _tapper(
        tester,
        find.byKey(RubriqueDossier.cleEntete(RubriqueDossierCode.responsable)),
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
      await _tapper(
        tester,
        find.byKey(RubriqueDossier.cleEntete(RubriqueDossierCode.responsable)),
      );
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
