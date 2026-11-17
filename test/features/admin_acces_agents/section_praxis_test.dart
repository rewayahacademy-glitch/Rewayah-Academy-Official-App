// PX-3 : la section « Praxis » de « Acces des agents IA ».
//
// Ce que les cas prouvent (sur le vrai widget, la base est un double) :
//  - les reglages (allume, autonome, plafond) sont des gestes SENSIBLES : ils
//    attendent le serveur, puis l'etat est relu (une reponse perdue ne laisse
//    pas l'ecran dire autre chose que la base) ;
//  - un refus du serveur faute de double verification se dit par la phrase
//    vraie et le chemin, jamais par « connexion » ;
//  - le secret d'une cle ne s'affiche qu'une fois ; il disparait au clic sur
//    « J'ai copie la cle » et ne reapparait jamais dans la liste ;
//  - la revocation exige un motif ;
//  - les etats loading, content, empty, error et offline ;
//  - le journal ne montre que ce que Praxis a envoye, par pages.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/service_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/features/admin_acces_agents/choix_conversations_essai.dart';
import 'package:rewayah_academy/features/admin_acces_agents/section_praxis.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../support/faux_service_praxis.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Les conversations de la messagerie de la direction, doubles.
List<ResumeFil> _fils(int n) => <ResumeFil>[
  for (int i = 0; i < n; i++)
    ResumeFil(
      id: 'f$i',
      objet: ObjetLie(
        type: TypeObjetLie.dossier,
        id: 'o$i',
        libelle: 'Dossier $i',
      ),
      interlocuteurs: <Participant>[
        Participant(
          id: 'p$i',
          nomAffiche: i == 2 ? 'Bilal Haddad' : 'Amina Diallo $i',
          fonction: 'Parent',
        ),
      ],
      apercu: 'Bonjour $i',
    ),
];

class _PortFils extends MessagesMetierIndisponibles {
  const _PortFils(this._fils);
  final List<ResumeFil>? _fils;

  @override
  Future<List<ResumeFil>> fils() => _fils == null
      ? Future<List<ResumeFil>>.error(Exception('panne'))
      : Future<List<ResumeFil>>.value(_fils);
}

Future<void> _monter(
  WidgetTester tester,
  FauxServicePraxis faux, {
  List<Override> en = const <Override>[],
  Size taille = const Size(1440, 3000),
  List<ResumeFil>? fils,
  bool panne = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const Scaffold(body: SingleChildScrollView(child: SectionPraxis())),
      surcharges: <Override>[
        servicePraxisProvider.overrideWithValue(faux),
        portMessagesMetierProvider.overrideWithValue(
          _PortFils(panne ? null : (fils ?? _fils(4))),
        ),
        ...en,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  group('contenu', () {
    testWidgets('reglages, cles et journal sont lus et rendus', (tester) async {
      final FauxServicePraxis faux = FauxServicePraxis(
        pages: <List<LigneJournalPraxis>>[
          <LigneJournalPraxis>[
            ligneJournalFictive(5),
            ligneJournalFictive(4, issue: 'plafond_fil', extrait: null),
          ],
        ],
      );
      await _monter(tester, faux);
      expect(find.text(t.admin.praxis.titre), findsWidgets);
      expect(find.text(t.admin.praxis.allumeNon), findsOneWidget);
      expect(find.text(t.admin.praxis.autonomeNon), findsOneWidget);
      expect(find.textContaining('prx_1a2b3c4d'), findsWidgets);
      expect(find.text(t.admin.praxis.etatRevoquee), findsWidgets);
      expect(find.text(t.admin.praxis.envoye), findsWidgets);
      expect(
        find.text(
          t.admin.praxis.refuseCause(cause: t.admin.praxis.cause.plafondFil),
        ),
        findsWidgets,
      );
      // Jamais le secret, jamais une empreinte, dans aucune ligne.
      expect(find.textContaining(RegExp(r'prx_[0-9a-f]{20}')), findsNothing);
    });

    testWidgets('pouls : aucun passage note, la phrase le dit', (tester) async {
      await _monter(tester, FauxServicePraxis());
      expect(find.byKey(ClesPraxis.poulsAucun), findsOneWidget);
      expect(find.text(t.admin.praxis.routine.aucun), findsOneWidget);
      expect(find.byKey(ClesPraxis.pouls), findsNothing);
    });

    testWidgets('pouls : le dernier passage, son issue et ses compteurs', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis(
        etat: EtatPraxis(
          actif: true,
          autonome: true,
          envoisParHeure: 30,
          cles: const <ClePraxis>[],
          derniereRoutine: TirRoutinePraxis(
            termineLe: DateTime(2026, 11, 17, 9, 14),
            issue: 'erreur',
            filsLus: 7,
            messagesEnvoyes: 4,
            passesEquipe: 2,
            refus: 1,
            note: 'Plafond atteint',
          ),
        ),
      );
      await _monter(tester, faux);
      expect(find.byKey(ClesPraxis.pouls), findsOneWidget);
      expect(find.byKey(ClesPraxis.poulsAucun), findsNothing);
      expect(
        find.textContaining(t.admin.praxis.routine.issueErreur),
        findsWidgets,
      );
      expect(
        find.text(
          t.admin.praxis.routine.compteurs(
            lus: '7',
            envoyes: '4',
            passes: '2',
            refus: '1',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Plafond atteint'), findsOneWidget);
    });

    testWidgets('pouls : un serveur sans la migration ne casse rien', (
      tester,
    ) async {
      expect(TirRoutinePraxis.depuisJson(null), isNull);
      expect(TirRoutinePraxis.depuisJson('x'), isNull);
      expect(TirRoutinePraxis.depuisJson(<String, dynamic>{}), isNull);
      const Map<String, dynamic> brut = <String, dynamic>{
        'actif': true,
        'autonome': true,
        'cles': <dynamic>[],
      };
      expect(EtatPraxis.depuisJson(brut).derniereRoutine, isNull);
    });

    testWidgets('chargement : un squelette, puis le contenu', (tester) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      tester.view.physicalSize = const Size(1440, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const Scaffold(body: SingleChildScrollView(child: SectionPraxis())),
          surcharges: <Override>[servicePraxisProvider.overrideWithValue(faux)],
        ),
      );
      // Avant la fin de la premiere lecture : pas encore de reglages.
      expect(find.text(t.admin.praxis.allumeNon), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text(t.admin.praxis.allumeNon), findsOneWidget);
    });

    testWidgets('vide : aucune cle, aucun envoi', (tester) async {
      await _monter(
        tester,
        FauxServicePraxis(
          etat: const EtatPraxis(
            actif: false,
            autonome: false,
            envoisParHeure: 30,
            cles: <ClePraxis>[],
          ),
        ),
      );
      expect(find.text(t.admin.praxis.cleVide), findsOneWidget);
      expect(find.text(t.admin.praxis.journalVide), findsOneWidget);
    });

    testWidgets('erreur : une phrase, et Reessayer relit', (tester) async {
      final FauxServicePraxis faux = FauxServicePraxis(
        erreurEtat: Exception('panne'),
      );
      await _monter(tester, faux);
      expect(find.text(t.admin.praxis.erreur), findsOneWidget);
      faux.erreurEtat = null;
      await _presser(tester, find.text(t.commun.reessayer).first);
      expect(find.text(t.admin.praxis.allumeNon), findsOneWidget);
    });

    testWidgets('hors ligne : le bloc dit ce qui manque', (tester) async {
      await _monter(
        tester,
        FauxServicePraxis(erreurEtat: Exception('reseau')),
        en: <Override>[
          horsLigneProvider.overrideWith((ref) => Stream<bool>.value(true)),
        ],
      );
      expect(find.text(t.admin.praxis.horsLigne), findsOneWidget);
    });

    testWidgets('erreur du journal seul : les reglages restent', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxServicePraxis(erreurJournal: Exception('panne')),
      );
      expect(find.text(t.admin.praxis.allumeNon), findsOneWidget);
      expect(find.text(t.admin.praxis.journalErreur), findsOneWidget);
    });
  });

  group('reglages (gestes sensibles)', () {
    testWidgets('allumer : le serveur est appele, puis l etat est relu', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesPraxis.interrupteur));
      expect(faux.appels, contains('regler:true:null:null'));
      expect(find.text(t.admin.praxis.allumeOui), findsOneWidget);
      expect(find.text(t.admin.praxis.reglageFait), findsOneWidget);
      // L'etat a ete relu apres le geste.
      expect(
        faux.appels.indexOf('regler:true:null:null') <
            faux.appels.lastIndexOf('etat'),
        isTrue,
      );
    });

    testWidgets('autonome : autoriser puis revenir au mode dirige', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesPraxis.autonome));
      expect(faux.appels, contains('regler:null:true:null'));
      expect(find.text(t.admin.praxis.autonomeOui), findsOneWidget);
      await _presser(tester, find.byKey(ClesPraxis.autonome));
      expect(faux.appels, contains('regler:null:false:null'));
    });

    testWidgets(
      'plafond : hors bornes refuse avant le serveur, valide envoye',
      (tester) async {
        final FauxServicePraxis faux = FauxServicePraxis();
        await _monter(tester, faux);
        await tester.enterText(find.byKey(ClesPraxis.champPlafond), '121');
        await _presser(tester, find.byKey(ClesPraxis.fixerPlafond));
        expect(find.text(t.admin.praxis.plafondInvalide), findsOneWidget);
        expect(faux.appels.where((a) => a.startsWith('regler')), isEmpty);
        await tester.enterText(find.byKey(ClesPraxis.champPlafond), '45');
        await _presser(tester, find.byKey(ClesPraxis.fixerPlafond));
        expect(faux.appels, contains('regler:null:null:45'));
        expect(
          find.text(t.admin.praxis.plafondDetail(nombre: 45)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'donnees reelles : fermees au depart, la phrase d\'avertissement',
      (tester) async {
        final FauxServicePraxis faux = FauxServicePraxis();
        await _monter(tester, faux);
        expect(find.text(t.admin.praxis.donnees.fermees), findsOneWidget);
        expect(find.byKey(ClesPraxis.avertissementDonnees), findsOneWidget);
        expect(find.text(t.admin.praxis.donnees.avertissement), findsOneWidget);
        // Une action sensible : elle attend le serveur, puis l'etat est relu.
        await _presser(tester, find.byKey(ClesPraxis.donneesReelles));
        expect(faux.appels, contains('donnees:true'));
        expect(find.text(t.admin.praxis.donnees.ouvertes), findsOneWidget);
        await _presser(tester, find.byKey(ClesPraxis.donneesReelles));
        expect(faux.appels, contains('donnees:false'));
        expect(find.text(t.admin.praxis.donnees.fermees), findsOneWidget);
      },
    );

    testWidgets('donnees reelles : refus faute de double verification', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis()..refusDroit = true;
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesPraxis.donneesReelles));
      expect(find.text(t.admin.praxis.doubleVerification), findsOneWidget);
      expect(find.text(t.admin.praxis.donnees.fermees), findsOneWidget);
    });

    testWidgets('essai : on coche des conversations, dix au plus, puis fin', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      expect(find.text(t.admin.praxis.essaiVide), findsOneWidget);
      expect(find.byKey(ClesPraxis.finEssai), findsNothing);
      expect(
        find.text(t.admin.praxis.essaiChoisies(nombre: 0)),
        findsOneWidget,
      );
      // La liste est celle de la messagerie : meme titre que `LigneFil`.
      expect(find.textContaining('Amina Diallo'), findsWidgets);
      await _presser(tester, find.byKey(ClesChoixEssai.case_('f1')));
      await _presser(tester, find.byKey(ClesChoixEssai.case_('f2')));
      expect(
        find.text(t.admin.praxis.essaiChoisies(nombre: 2)),
        findsOneWidget,
      );
      await _presser(tester, find.byKey(ClesPraxis.fixerEssai));
      expect(faux.appels, contains('essai:f1,f2'));
      expect(find.text(t.admin.praxis.essaiActif(nombre: 2)), findsOneWidget);
      // Toucher la ligne coche aussi.
      await _presser(tester, find.byKey(const ValueKey<String>('ligne-f3')));
      expect(
        find.text(t.admin.praxis.essaiChoisies(nombre: 3)),
        findsOneWidget,
      );
      // Fin de l'essai : une liste vide.
      await _presser(tester, find.byKey(ClesPraxis.finEssai));
      expect(faux.appels, contains('essai:'));
      expect(find.text(t.admin.praxis.essaiVide), findsOneWidget);
      expect(find.byKey(ClesPraxis.finEssai), findsNothing);
    });

    testWidgets('essai : la onzieme conversation est refusee, rien d envoye', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux, fils: _fils(12));
      for (int i = 0; i < 11; i++) {
        await _presser(tester, find.byKey(ClesChoixEssai.case_('f$i')));
      }
      expect(find.text(t.admin.praxis.essaiTrop(nombre: 10)), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w.key == ClesChoixEssai.case_('f10'),
        ),
        findsOneWidget,
      );
      await _presser(tester, find.byKey(ClesPraxis.fixerEssai));
      final List<String> envois = faux.appels
          .where((String x) => x.startsWith('essai:'))
          .toList();
      expect(envois, hasLength(1));
      expect(envois.single.substring(6).split(',').length, 10);
    });

    testWidgets('essai : la recherche affine, comme dans les Messages', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      await tester.enterText(find.byType(TextField).at(1), 'Bilal');
      await tester.pumpAndSettle();
      expect(find.byKey(ClesChoixEssai.case_('f1')), findsNothing);
      expect(find.byKey(ClesChoixEssai.case_('f2')), findsOneWidget);
    });

    testWidgets('essai : aucune conversation, la phrase dit quoi faire', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux, fils: <ResumeFil>[]);
      expect(find.text(t.admin.praxis.essaiAucune), findsOneWidget);
    });

    testWidgets('essai : la liste ne se lit pas, une phrase et Reessayer', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux, panne: true);
      expect(find.text(t.admin.praxis.essaiListeErreur), findsOneWidget);
    });

    testWidgets('essai : refus faute de double verification, la phrase vraie', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis()..refusDroit = true;
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesChoixEssai.case_('f1')));
      await _presser(tester, find.byKey(ClesPraxis.fixerEssai));
      expect(find.text(t.admin.praxis.doubleVerification), findsOneWidget);
      expect(find.text(t.admin.praxis.essaiVide), findsOneWidget);
    });

    testWidgets('refus faute de double verification : la phrase vraie', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis()..refusDroit = true;
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesPraxis.interrupteur));
      expect(find.text(t.admin.praxis.doubleVerification), findsOneWidget);
      // L'etat n'a pas bouge : toujours eteint.
      expect(find.text(t.admin.praxis.allumeNon), findsOneWidget);
    });

    testWidgets('reponse perdue : non confirme, l etat est relu', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis()
        ..erreurEcriture = Exception('reseau coupe');
      await _monter(tester, faux);
      final int avant = faux.appels.where((a) => a == 'etat').length;
      await _presser(tester, find.byKey(ClesPraxis.interrupteur));
      expect(find.text(t.admin.praxis.erreurReglage), findsOneWidget);
      expect(faux.appels.where((a) => a == 'etat').length, greaterThan(avant));
    });
  });

  group('cles', () {
    testWidgets('le nom est obligatoire : la raison, pas un bouton grise', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      await _presser(tester, find.byKey(ClesPraxis.emettre));
      expect(find.text(t.admin.praxis.manqueLibelle), findsOneWidget);
      expect(faux.appels.where((a) => a.startsWith('emettre')), isEmpty);
    });

    testWidgets('emission : le secret est montre une fois, puis disparait', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      await tester.enterText(
        find.byType(TextField).at(2),
        'Conversation du soir',
      );
      await _presser(tester, find.byKey(ClesPraxis.emettre));
      final String secret = 'prx_${'ab12' * 16}';
      expect(find.text(t.admin.praxis.cleEmise), findsOneWidget);
      expect(find.text(secret), findsOneWidget);
      expect(
        find.text('https://exemple.test/functions/v1/praxis-mcp'),
        findsOneWidget,
      );
      // La nouvelle cle est dans la liste par son prefixe, sans le secret.
      await _presser(tester, find.byKey(ClesPraxis.termine));
      expect(find.text(secret), findsNothing);
      expect(find.text(t.admin.praxis.cleEmise), findsNothing);
      expect(find.textContaining(secret), findsNothing);
      expect(find.textContaining('Conversation du soir'), findsWidgets);
    });

    testWidgets('l usage routine part avec la bonne valeur', (tester) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      await tester.enterText(find.byType(TextField).at(2), 'Routine');
      await _presser(
        tester,
        find.widgetWithText(FilterPill, t.admin.praxis.usageRoutine),
      );
      await _presser(tester, find.byKey(ClesPraxis.emettre));
      expect(
        faux.appels.any((a) => a.startsWith('emettre:Routine:routine:')),
        isTrue,
      );
    });

    testWidgets('refus faute de double verification a l emission', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis()..refusDroit = true;
      await _monter(tester, faux);
      await tester.enterText(find.byType(TextField).at(2), 'Test');
      await _presser(tester, find.byKey(ClesPraxis.emettre));
      expect(find.text(t.admin.praxis.doubleVerification), findsOneWidget);
      expect(find.text(t.admin.praxis.cleEmise), findsNothing);
    });

    testWidgets('revoquer : le motif est obligatoire', (tester) async {
      final FauxServicePraxis faux = FauxServicePraxis();
      await _monter(tester, faux);
      await _presser(tester, find.text(t.admin.praxis.revoquer).first);
      await _presser(tester, find.byKey(ClesPraxis.confirmerRevocation));
      expect(find.text(t.admin.praxis.manqueMotif), findsOneWidget);
      expect(faux.appels.where((a) => a.startsWith('revoquer')), isEmpty);
      await tester.enterText(
        find.byType(TextField).last,
        'Clé copiée par erreur',
      );
      await _presser(tester, find.byKey(ClesPraxis.confirmerRevocation));
      expect(faux.appels, contains('revoquer:c1:Clé copiée par erreur'));
      expect(find.text(t.admin.praxis.revoquee), findsOneWidget);
    });
  });

  group('journal', () {
    testWidgets('par pages : « Voir les envois plus anciens » ajoute', (
      tester,
    ) async {
      final FauxServicePraxis faux = FauxServicePraxis(
        pages: <List<LigneJournalPraxis>>[
          <LigneJournalPraxis>[
            ligneJournalFictive(30, extrait: 'Premier envoi récent'),
          ],
          <LigneJournalPraxis>[
            ligneJournalFictive(10, extrait: 'Envoi plus ancien'),
          ],
        ],
      );
      await _monter(tester, faux);
      expect(find.textContaining('Premier envoi récent'), findsWidgets);
      expect(find.textContaining('Envoi plus ancien'), findsNothing);
      await _presser(tester, find.byKey(ClesPraxis.suiteJournal));
      expect(find.textContaining('Envoi plus ancien'), findsWidgets);
      expect(find.textContaining('Premier envoi récent'), findsWidgets);
      // La derniere page n'a plus de suite.
      expect(find.byKey(ClesPraxis.suiteJournal), findsNothing);
    });

    testWidgets('une annonce se dit annonce', (tester) async {
      await _monter(
        tester,
        FauxServicePraxis(
          pages: <List<LigneJournalPraxis>>[
            <LigneJournalPraxis>[
              ligneJournalFictive(
                7,
                outil: 'annoncer',
                extrait: 'Rentrée des classes',
              ),
            ],
          ],
        ),
      );
      expect(find.text(t.admin.praxis.quoiAnnonce), findsWidgets);
    });
  });

  group('gardes d\'interface (K-55, K-56) sur la section rendue', () {
    for (final Size taille in const <Size>[Size(320, 5000), Size(1440, 5000)]) {
      for (final double echelle in const <double>[1, 2]) {
        testWidgets(
          '${taille.width.toInt()} px, texte x${echelle.toInt()} : aucune '
          'carte collee, aucun bouton plein, aucun debordement',
          (tester) async {
            tester.view.physicalSize = taille;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              ProviderScopeAvecSection(
                faux: FauxServicePraxis(
                  pages: <List<LigneJournalPraxis>>[
                    <LigneJournalPraxis>[
                      ligneJournalFictive(3),
                      ligneJournalFictive(
                        2,
                        issue: 'plafond_fil',
                        extrait: null,
                      ),
                    ],
                  ],
                ),
                echelle: echelle,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            verifierUnSeulBoutonPlein(tester, maximum: 0);
            final int vues = verifierAucuneCarteCollee(
              tester,
              // Les trois cartes de la section ; l'ecart entre les cartes que
              // pose la collection partagee (12) n'est pas le sien.
              estCarte: ClesPraxis.estCarte,
            );
            expect(vues, greaterThanOrEqualTo(2));
          },
        );
      }
    }
  });
}

/// La section seule, a l'echelle de texte demandee.
class ProviderScopeAvecSection extends StatelessWidget {
  /// Cree l'hote.
  const ProviderScopeAvecSection({
    required this.faux,
    required this.echelle,
    super.key,
  });

  /// Le service double.
  final FauxServicePraxis faux;

  /// L'echelle du texte.
  final double echelle;

  @override
  Widget build(BuildContext context) => hote(
    Builder(
      builder: (BuildContext c) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(echelle)),
        child: const Scaffold(
          body: SingleChildScrollView(child: SectionPraxis()),
        ),
      ),
    ),
    surcharges: <Override>[servicePraxisProvider.overrideWithValue(faux)],
  );
}
