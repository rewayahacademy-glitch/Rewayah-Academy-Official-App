// COM-ANN-2 : le publieur d'annonce unique (`AnnouncementPublisher`, spec
// section 20). Cinq etapes (quatre sans la capacite de programmer), une seule
// action pleine a la fois, « Publiée » seulement apres l'accuse du serveur,
// la meme cle d'idempotence a chaque nouvelle tentative, l'enseignant limite
// a sa Classe. Rendu verifie a 390, 768 et 1440, et en arabe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/com_annonces/publier_annonce_classe_page.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';

import '../../support/garde_interface.dart';
import 'admin_banc.dart';
import 'faux_annonces.dart';

Finder get _action => find.byKey(PublieurAnnonce.cleAction);

String _libelleAction(WidgetTester tester) {
  final Finder texte = find.descendant(
    of: _action,
    matching: find.byType(Text),
  );
  return tester.widget<Text>(texte.first).data ?? '';
}

Future<void> _ecrire(WidgetTester tester, String titre, String texte) async {
  await tester.enterText(find.byKey(PublieurAnnonce.cleTitre), titre);
  await tester.enterText(find.byKey(PublieurAnnonce.cleTexte), texte);
  await tester.pumpAndSettle();
}

Future<void> _continuer(WidgetTester tester) => taper(tester, _action);

// L'identifiant de l'audience n'est pas celui de la Classe (COM-BR-10) :
// l'ecran de l'enseignant la retrouve par `classeId`.
const CibleAnnonce _nour = CibleAnnonce(
  id: 'audience-classe-an-nour',
  libelle: 'Classe An-Nour',
  nature: NatureCible.classe,
  classeId: ClassesDemoAnnonces.nour,
);

List<Override> _surFaux(
  FauxAnnonces faux, {
  Set<CapaciteCommunication> capacites = const <CapaciteCommunication>{
    CapaciteCommunication.publierAnnonce,
  },
}) => <Override>[
  portAnnoncesProvider.overrideWithValue(faux),
  portCapacitesCommunicationsProvider.overrideWithValue(
    CapacitesCommunicationsFixes(capacites),
  ),
];

void main() {
  group('creneauxProgrammation', () {
    test('demain matin, demain soir, lundi suivant', () {
      // Mercredi 7 octobre 2026.
      final List<DateTime> c = creneauxProgrammation(DateTime(2026, 10, 7, 15));
      expect(c, <DateTime>[
        DateTime(2026, 10, 8, 8),
        DateTime(2026, 10, 8, 18),
        DateTime(2026, 10, 12, 8),
      ]);
    });

    test('demain lundi : le lundi d apres, jamais deux fois le meme jour', () {
      // Dimanche 4 octobre 2026.
      final List<DateTime> c = creneauxProgrammation(DateTime(2026, 10, 4, 9));
      expect(c.first, DateTime(2026, 10, 5, 8));
      expect(c.last, DateTime(2026, 10, 12, 8));
    });
  });

  group('Enseignant : le meme publieur, limite a sa Classe', () {
    testWidgets('390 : quatre etapes, audience fixee, Publiee apres l accuse', (
      WidgetTester tester,
    ) async {
      final AnnoncesDemonstration annonces = annoncesBanc(
        cibles: <CibleAnnonce>[
          for (final CibleAnnonce c in ciblesDemo())
            if (c.classeId == ClassesDemoAnnonces.nour) c,
        ],
      );
      final GoRouter routeur = await monterPublierClasse(
        tester,
        annonces: annonces,
      );
      final p = t.com.annonces.publieur;
      // Sans la capacite de programmer : pas d'etape de date.
      expect(find.text(t.commun.etape.sur(n: 1, total: 4)), findsOneWidget);
      expect(find.text(p.etapes.contenu), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);

      // Contenu manquant : le publieur le dit, il ne passe pas.
      await _continuer(tester);
      expect(find.text(p.manqueContenu), findsOneWidget);
      expect(find.text(t.commun.etape.sur(n: 1, total: 4)), findsOneWidget);

      await _ecrire(tester, 'Sortie de fin d annee', 'Texte de la sortie.');
      await _continuer(tester);
      // L'audience est la Classe, sans choix.
      expect(find.text(p.etapes.audience), findsOneWidget);
      expect(
        find.text(p.contexte.audienceFixee(cible: 'Classe An-Nour')),
        findsOneWidget,
      );
      expect(find.byType(ChoiceCardGroup), findsNothing);
      expect(find.text(p.nature.toutes), findsNothing);

      await _continuer(tester);
      expect(find.byKey(PublieurAnnonce.cleApercu), findsOneWidget);
      expect(find.text('Sortie de fin d annee'), findsOneWidget);
      expect(find.text(p.apercu.diffusionMaintenant), findsOneWidget);

      await _continuer(tester);
      expect(find.text(t.commun.etape.sur(n: 4, total: 4)), findsOneWidget);
      expect(_libelleAction(tester), p.publier);
      // Rien n'est publie avant l'accuse.
      expect(find.text(p.publiee), findsNothing);
      verifierUnSeulBoutonPlein(tester);

      await _continuer(tester);
      expect(find.text(p.publiee), findsOneWidget);
      expect(_libelleAction(tester), p.terminer);
      expect(annonces.parCle, hasLength(1));
      expect(annonces.publiees.first.cible.nature, NatureCible.classe);
      expect(annonces.publiees.first.cible.classeId, ClassesDemoAnnonces.nour);

      await _continuer(tester);
      expect(find.text(texteEspaceClasse), findsOneWidget);
      expect(
        routeur.state.uri.path,
        '/enseignant/groupe/${ClassesDemoAnnonces.nour}',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('une autre Classe, ouverte par URL : sans la capacite de '
        'publier, aucun publieur (revue COM-R, R-20)', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : avant R-20, l'adresse directe rendait le chargement
      // du publieur sans lire `CapaciteAnnonces.publier`.
      await monterPublierClasse(tester, classeId: 'classe-d-un-autre');
      final p = t.com.annonces.publieur;
      expect(find.byKey(PublierAnnonceClassePage.cleRefusee), findsOneWidget);
      expect(find.text(p.classeRefuseeTitre), findsOneWidget);
      expect(find.text(p.aucuneCibleTitre), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(_action, findsNothing);
    });

    testWidgets('une audience d une autre nature n est jamais proposee', (
      WidgetTester tester,
    ) async {
      // Le serveur rendrait par erreur une audience globale sous le meme
      // identifiant : l'ecran de l'enseignant ne la retient pas.
      final FauxAnnonces faux =
          FauxAnnonces(
              capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
            )
            ..cibles = const <CibleAnnonce>[
              CibleAnnonce(
                id: ClassesDemoAnnonces.nour,
                libelle: 'Toute l ecole',
                nature: NatureCible.toutes,
              ),
            ];
      await monterPublierClasse(tester, surcharges: _surFaux(faux));
      expect(
        find.text(t.com.annonces.publieur.aucuneCibleTitre),
        findsOneWidget,
      );
    });

    testWidgets('production : pas encore disponible, le retour reste', (
      WidgetTester tester,
    ) async {
      await monterPublierClasse(tester, neutre: true);
      expect(find.text(t.com.annonces.publieur.indisponible), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await taper(tester, find.byType(DisqueRetour));
      expect(find.text(texteEspaceClasse), findsOneWidget);
    });

    testWidgets('echec : pas encore confirmee, meme cle au nouvel essai', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux =
          FauxAnnonces(
              capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
            )
            ..cibles = const <CibleAnnonce>[_nour]
            ..erreurPublication = Exception('accuse perdu');
      await monterPublierClasse(tester, surcharges: _surFaux(faux));
      final p = t.com.annonces.publieur;
      await _ecrire(tester, 'Titre', 'Texte');
      await _continuer(tester);
      await _continuer(tester);
      await _continuer(tester);
      await _continuer(tester);
      expect(find.text(p.nonConfirmee), findsOneWidget);
      expect(find.text(p.publiee), findsNothing);
      expect(_libelleAction(tester), p.reessayer);
      verifierUnSeulBoutonPlein(tester);

      faux.erreurPublication = null;
      await _continuer(tester);
      expect(find.text(p.publiee), findsOneWidget);
      expect(faux.publications, hasLength(2));
      expect(faux.publications[0].$2, faux.publications[1].$2);
    });

    testWidgets('audience a identifiant propre : retenue par sa Classe', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux = FauxAnnonces(
        capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
      )..cibles = const <CibleAnnonce>[_nour];
      await monterPublierClasse(tester, surcharges: _surFaux(faux));
      final p = t.com.annonces.publieur;
      expect(find.text(p.aucuneCibleTitre), findsNothing);
      await _ecrire(tester, 'Titre', 'Texte');
      for (int i = 0; i < 4; i++) {
        await _continuer(tester);
      }
      expect(find.text(p.publiee), findsOneWidget);
      expect(faux.publications.single.$1.cible.id, _nour.id);
    });

    testWidgets('une audience d une autre Classe n est jamais retenue', (
      WidgetTester tester,
    ) async {
      // Le serveur rendrait par erreur la Classe d'un autre sous l'identifiant
      // de cette Classe : `classeId` ne correspond pas, rien n'est propose.
      final FauxAnnonces faux =
          FauxAnnonces(
              capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
            )
            ..cibles = const <CibleAnnonce>[
              CibleAnnonce(
                id: ClassesDemoAnnonces.nour,
                libelle: 'Classe Al-Fajr',
                nature: NatureCible.classe,
                classeId: ClassesDemoAnnonces.fajr,
              ),
            ];
      await monterPublierClasse(tester, surcharges: _surFaux(faux));
      expect(
        find.text(t.com.annonces.publieur.aucuneCibleTitre),
        findsOneWidget,
      );
    });

    testWidgets('pendant l envoi, le retour ne rouvre pas le contenu', (
      WidgetTester tester,
    ) async {
      final Completer<void> accuse = Completer<void>();
      final FauxAnnonces faux =
          FauxAnnonces(
              capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
            )
            ..cibles = const <CibleAnnonce>[_nour]
            ..attente = accuse.future;
      await monterPublierClasse(tester, surcharges: _surFaux(faux));
      await _ecrire(tester, 'Titre', 'Texte');
      for (int i = 0; i < 3; i++) {
        await _continuer(tester);
      }
      await tester.tap(_action);
      await tester.pump();
      expect(find.text(t.com.annonces.publieur.enCours), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pump();
      // Toujours a la publication : rien n'est modifiable pendant l'envoi.
      expect(find.text(t.commun.etape.sur(n: 4, total: 4)), findsOneWidget);
      expect(find.text(texteEspaceClasse), findsNothing);
      accuse.complete();
      await tester.pumpAndSettle();
      expect(find.text(t.com.annonces.publieur.publiee), findsOneWidget);
    });

    testWidgets('apres un envoi non confirme, le retour sort sans republier', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux =
          FauxAnnonces(
              capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
            )
            ..cibles = const <CibleAnnonce>[_nour]
            ..erreurPublication = Exception('accuse perdu');
      await monterPublierClasse(tester, surcharges: _surFaux(faux));
      await _ecrire(tester, 'Titre', 'Texte');
      for (int i = 0; i < 4; i++) {
        await _continuer(tester);
      }
      expect(find.text(t.com.annonces.publieur.nonConfirmee), findsOneWidget);
      // Le retour ne rouvre pas le contenu (une coquille corrigee tirerait
      // une nouvelle cle) : il quitte le publieur.
      await taper(tester, find.byType(DisqueRetour));
      expect(find.byKey(PublieurAnnonce.cleTitre), findsNothing);
      expect(find.text(texteEspaceClasse), findsOneWidget);
      expect(faux.publications, hasLength(1));
    });

    testWidgets('publication sans contrat : rien a reessayer, Terminer', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux =
          FauxAnnonces(
              capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
            )
            ..cibles = const <CibleAnnonce>[_nour]
            ..erreurPublication = const CapaciteIndisponible('COM-BR-10');
      await monterPublierClasse(tester, surcharges: _surFaux(faux));
      await _ecrire(tester, 'Titre', 'Texte');
      for (int i = 0; i < 4; i++) {
        await _continuer(tester);
      }
      final p = t.com.annonces.publieur;
      expect(find.text(p.indisponible), findsOneWidget);
      expect(find.text(p.publiee), findsNothing);
      expect(_libelleAction(tester), p.terminer);
      await _continuer(tester);
      expect(find.text(texteEspaceClasse), findsOneWidget);
    });

    testWidgets('hors ligne : la phrase dit de se reconnecter', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux =
          FauxAnnonces(
              capacites: const <CapaciteAnnonces>{CapaciteAnnonces.publier},
            )
            ..cibles = const <CibleAnnonce>[_nour]
            ..erreurPublication = Exception('reseau');
      await monterPublierClasse(
        tester,
        surcharges: _surFaux(faux),
        horsLigne: true,
      );
      await _ecrire(tester, 'Titre', 'Texte');
      for (int i = 0; i < 4; i++) {
        await _continuer(tester);
      }
      expect(find.text(t.com.annonces.publieur.horsLigne), findsOneWidget);
      expect(find.text(t.com.annonces.publieur.publiee), findsNothing);
    });

    testWidgets('arabe, de droite a gauche, 390 et texte x2', (
      WidgetTester tester,
    ) async {
      await monterPublierClasse(tester, arabe: true, echelleTexte: 2);
      expect(
        Directionality.of(tester.element(find.byKey(PublieurAnnonce.cleTitre))),
        TextDirection.rtl,
      );
      expect(find.text(t.com.annonces.publieur.etapes.contenu), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Administration : audiences choisies et programmation', () {
    for (final Size taille in const <Size>[
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      testWidgets(
        '${taille.width.toInt()} : cinq etapes, Planifiee confirmee',
        (WidgetTester tester) async {
          final AnnoncesDemonstration annonces = annoncesBanc();
          await monterAdministration(
            tester,
            taille: taille,
            annonces: annonces,
          );
          final p = t.com.annonces.publieur;
          await taper(
            tester,
            find.byKey(AdministrationCommunicationsPage.cleNouvelle),
          );
          expect(find.text(t.commun.etape.sur(n: 1, total: 5)), findsOneWidget);
          await _ecrire(tester, 'Reprise des cours', 'Les cours reprennent.');
          await _continuer(tester);

          // L'audience se choisit, chaque option dit sa consequence.
          expect(find.byType(ChoiceCardGroup), findsOneWidget);
          expect(find.text(p.nature.toutes), findsOneWidget);
          await _continuer(tester);
          expect(find.text(p.manqueAudience), findsOneWidget);
          await taper(
            tester,
            find.byKey(PublieurAnnonce.cleCible('demo-familles')),
          );
          await _continuer(tester);

          // La date de diffusion : des creneaux proposes, jamais saisis.
          expect(find.text(p.etapes.programmation), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          await taper(
            tester,
            find.byKey(PublieurAnnonce.cleQuand('creneau-0')),
          );
          await _continuer(tester);
          expect(
            find.textContaining(
              p.apercu.diffusionLe(date: '', heure: '').split(' ').first,
            ),
            findsWidgets,
          );

          await _continuer(tester);
          expect(find.text(t.commun.etape.sur(n: 5, total: 5)), findsOneWidget);
          expect(_libelleAction(tester), p.programmer);
          verifierUnSeulBoutonPlein(tester);
          await _continuer(tester);
          final DateTime prevue = DateTime(2026, 10, 5, 8);
          expect(
            annonces.planifiees.any(
              (AnnonceAdministration a) =>
                  a.titre == 'Reprise des cours' && a.le == prevue.toUtc(),
            ),
            isTrue,
          );
          expect(find.byKey(PublieurAnnonce.cleMessage), findsOneWidget);
          expect(_libelleAction(tester), p.terminer);

          // Terminer : retour a l'onglet, la nouvelle annonce y est.
          await _continuer(tester);
          expect(
            find.byKey(AdministrationCommunicationsPage.cleIndicateurs),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text('Reprise des cours'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('Reprise des cours'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('le retour de la premiere etape rend l onglet', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester);
      await taper(
        tester,
        find.byKey(AdministrationCommunicationsPage.cleNouvelle),
      );
      expect(find.byKey(PublieurAnnonce.cleTitre), findsOneWidget);
      await taper(tester, find.byType(DisqueRetour));
      expect(find.byKey(PublieurAnnonce.cleTitre), findsNothing);
      expect(
        find.byKey(AdministrationCommunicationsPage.cleNouvelle),
        findsOneWidget,
      );
    });
  });
}
