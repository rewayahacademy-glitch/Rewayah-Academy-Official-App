// COM-ANN-2, puis ANNONCES-SIMPLES (directeur, 14/11/2026) : le publieur
// d'annonce unique, sur UN seul ecran (il avait cinq etapes). La direction :
// « A qui » (publics du serveur, nombre sous chacun), le message, un seul
// bouton « Envoyer a N personnes », une confirmation qui repete le public et
// le nombre. L'enseignant : sa Classe, sans choix. « Publiée » seulement
// apres l'accuse du serveur, la meme cle d'idempotence a chaque nouvelle
// tentative. Rendu verifie a 390, 768 et 1440, et en arabe.

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
import 'package:rewayah_academy/features/com_annonces/port_annonces_direction.dart';
import 'package:rewayah_academy/features/com_annonces/publier_annonce_classe_page.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';

import '../../support/demo/communications/com_annonces_demo.dart';
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

Future<void> _agir(WidgetTester tester) => taper(tester, _action);

Future<void> _ecrireTexte(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(PublieurAnnonce.cleTexte), texte);
  await tester.pumpAndSettle();
}

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

  group('Enseignant : le meme publieur, sur un seul ecran, limite a sa Classe', () {
    testWidgets('390 : un seul ecran, audience fixee, Publiee apres l accuse', (
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
      final s = t.com.annonces.simple;
      // Plus aucune etape : un seul ecran.
      expect(find.text(t.commun.etape.sur(n: 1, total: 4)), findsNothing);
      expect(find.byKey(PublieurAnnonce.cleTitre), findsOneWidget);
      expect(find.byKey(PublieurAnnonce.cleTexte), findsOneWidget);
      // L'audience est la Classe, sans choix de public.
      expect(
        find.text(s.classeContexte(cible: 'Classe An-Nour')),
        findsOneWidget,
      );
      expect(find.byType(ChoiceCardGroup), findsNothing);
      // Sans la capacite de programmer, ni courriel : aucune option.
      expect(find.byKey(PublieurAnnonce.cleProgrammer), findsNothing);
      expect(find.byKey(PublieurAnnonce.cleCourriel), findsNothing);
      expect(_libelleAction(tester), s.publierDans(cible: 'Classe An-Nour'));
      verifierUnSeulBoutonPlein(tester);

      // Message manquant : le publieur le dit, rien ne part.
      await _agir(tester);
      expect(find.text(s.manqueTexte), findsOneWidget);
      expect(annonces.parCle, isEmpty);

      // Le titre est facultatif : la premiere ligne sert de titre.
      await _ecrireTexte(tester, 'Sortie de fin d annee\nRendez-vous a 9 h.');
      expect(find.text(p.publiee), findsNothing);
      await _agir(tester);
      expect(find.text(p.publiee), findsOneWidget);
      expect(_libelleAction(tester), p.terminer);
      expect(annonces.parCle, hasLength(1));
      expect(annonces.publiees.first.titre, 'Sortie de fin d annee');
      expect(annonces.publiees.first.cible.nature, NatureCible.classe);
      expect(annonces.publiees.first.cible.classeId, ClassesDemoAnnonces.nour);
      verifierUnSeulBoutonPlein(tester);

      await _agir(tester);
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

    testWidgets('une audience d une autre nature n est jamais proposee', (
      WidgetTester tester,
    ) async {
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
      await _agir(tester);
      expect(find.text(p.nonConfirmee), findsOneWidget);
      expect(find.text(p.publiee), findsNothing);
      expect(_libelleAction(tester), p.reessayer);
      verifierUnSeulBoutonPlein(tester);

      faux.erreurPublication = null;
      await _agir(tester);
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
      await _agir(tester);
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

    testWidgets('pendant l envoi, le retour ne quitte pas', (
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
      await tester.ensureVisible(_action);
      await tester.tap(_action);
      await tester.pump();
      expect(find.text(t.com.annonces.publieur.enCours), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pump();
      // Toujours sur le publieur : l'accuse est attendu.
      expect(find.text(texteEspaceClasse), findsNothing);
      accuse.complete();
      await tester.pumpAndSettle();
      expect(find.text(t.com.annonces.publieur.publiee), findsOneWidget);
    });

    testWidgets('apres un envoi non confirme, le message est fige', (
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
      await _agir(tester);
      expect(find.text(t.com.annonces.publieur.nonConfirmee), findsOneWidget);
      // Une coquille corrigee tirerait une nouvelle cle : le champ est fige.
      expect(
        tester.widget<TextField>(find.byKey(PublieurAnnonce.cleTexte)).readOnly,
        isTrue,
      );
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
      await _agir(tester);
      final p = t.com.annonces.publieur;
      expect(find.text(p.indisponible), findsOneWidget);
      expect(find.text(p.publiee), findsNothing);
      expect(_libelleAction(tester), p.terminer);
      await _agir(tester);
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
      await _agir(tester);
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
      expect(find.text(t.com.annonces.simple.message), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('Direction : publics du serveur, un seul ecran', () {
    for (final Size taille in const <Size>[
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      testWidgets(
        '${taille.width.toInt()} : publics, nombre, confirmation, Planifiee',
        (WidgetTester tester) async {
          final AnnoncesDemonstration annonces = annoncesBanc();
          final AnnoncesDirectionDemonstration direction =
              AnnoncesDirectionDemonstration(annonces);
          await monterAdministration(
            tester,
            taille: taille,
            annonces: annonces,
            direction: direction,
          );
          final p = t.com.annonces.publieur;
          final s = t.com.annonces.simple;
          await taper(
            tester,
            find.byKey(AdministrationCommunicationsPage.cleNouvelle),
          );
          // Un seul ecran : « A qui », le message, les options repliees.
          expect(find.text(t.commun.etape.sur(n: 1, total: 5)), findsNothing);
          expect(find.text(s.aQui), findsOneWidget);
          for (final PublicAnnonce pub in publicsDemo) {
            expect(
              find.byKey(PublieurAnnonce.clePublic(pub.code)),
              findsOneWidget,
            );
          }
          // Le nombre sous chaque public vient du serveur.
          expect(find.text(s.personnes(n: 127)), findsOneWidget);
          final Switch programmer = tester.widget<Switch>(
            find.byKey(PublieurAnnonce.cleProgrammer),
          );
          final Switch courriel = tester.widget<Switch>(
            find.byKey(PublieurAnnonce.cleCourriel),
          );
          expect(programmer.value, isFalse);
          expect(courriel.value, isFalse);
          // L'apercu a cote, sur ordinateur seulement.
          expect(
            find.byKey(PublieurAnnonce.cleApercu),
            taille.width >= 1440 ? findsOneWidget : findsNothing,
          );
          verifierUnSeulBoutonPlein(tester);

          // Rien de choisi : la phrase le dit, rien ne part.
          await _agir(tester);
          expect(find.text(s.manquePublic), findsOneWidget);

          await taper(
            tester,
            find.byKey(PublieurAnnonce.clePublic(CodesPublics.candidats)),
          );
          expect(_libelleAction(tester), s.envoyerA(n: 127));
          await _ecrireTexte(tester, 'Les entretiens reprennent mardi.');

          // Programmer : trois moments proposes, jamais saisis.
          await taper(tester, find.byKey(PublieurAnnonce.cleProgrammer));
          await taper(
            tester,
            find.byKey(PublieurAnnonce.cleQuand('creneau-0')),
          );
          expect(_libelleAction(tester), s.programmerPour(n: 127));
          // Le courriel : combien et en combien de jours.
          await taper(tester, find.byKey(PublieurAnnonce.cleCourriel));
          expect(find.text(s.courrielUnJour(adresses: '127')), findsOneWidget);

          // La confirmation repete le public et le nombre.
          await _agir(tester);
          expect(find.text(s.confirmerTitre), findsOneWidget);
          expect(
            find.textContaining(
              s.confirmerTexte(n: 127, publics: s.publics.candidats),
            ),
            findsOneWidget,
          );
          expect(annonces.planifiees, hasLength(lessThan(99)));
          final int avant = direction.parCle.length;
          await taper(tester, find.byKey(PublieurAnnonce.cleConfirmer));
          expect(direction.parCle.length, avant + 1);
          expect(direction.dernierEnvoi!.publics, <String>{
            CodesPublics.candidats,
          });
          expect(direction.dernierEnvoi!.courriel, isTrue);
          expect(direction.dernierEnvoi!.titre, isEmpty);
          final DateTime prevue = DateTime(2026, 10, 5, 8);
          expect(
            annonces.planifiees.any(
              (AnnonceAdministration a) =>
                  a.titre == 'Les entretiens reprennent mardi.' &&
                  a.le == prevue.toUtc(),
            ),
            isTrue,
          );
          expect(find.byKey(PublieurAnnonce.cleMessage), findsOneWidget);
          expect(_libelleAction(tester), p.terminer);

          // Terminer : retour a l'onglet.
          await _agir(tester);
          expect(
            find.byKey(AdministrationCommunicationsPage.cleIndicateurs),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('revenir au message n envoie rien', (
      WidgetTester tester,
    ) async {
      final AnnoncesDemonstration annonces = annoncesBanc();
      final AnnoncesDirectionDemonstration direction =
          AnnoncesDirectionDemonstration(annonces);
      await monterAdministration(
        tester,
        annonces: annonces,
        direction: direction,
      );
      await taper(
        tester,
        find.byKey(AdministrationCommunicationsPage.cleNouvelle),
      );
      await taper(
        tester,
        find.byKey(PublieurAnnonce.clePublic(CodesPublics.familles)),
      );
      await _ecrireTexte(tester, 'Pas de cours lundi.');
      await _agir(tester);
      await taper(tester, find.text(t.com.annonces.simple.revenir));
      expect(direction.parCle, isEmpty);
      expect(find.byKey(PublieurAnnonce.cleTexte), findsOneWidget);
    });

    testWidgets('un public vide ne s envoie pas : la phrase dit pourquoi', (
      WidgetTester tester,
    ) async {
      final AnnoncesDemonstration annonces = annoncesBanc();
      await monterAdministration(
        tester,
        taille: const Size(390, 844),
        annonces: annonces,
        direction: AnnoncesDirectionDemonstration(
          annonces,
          publicsOuverts: const <PublicAnnonce>[
            PublicAnnonce(code: CodesPublics.candidatsAdmis, destinataires: 0),
            PublicAnnonce(code: CodesPublics.familles, destinataires: 3),
          ],
        ),
      );
      await taper(
        tester,
        find.byKey(AdministrationCommunicationsPage.cleNouvelle),
      );
      await taper(
        tester,
        find.byKey(PublieurAnnonce.clePublic(CodesPublics.candidatsAdmis)),
      );
      expect(find.text(t.com.annonces.simple.videPersonne), findsOneWidget);
      // Le bouton n'est pas grise : il n'est pas rendu.
      expect(_action, findsNothing);
    });

    testWidgets('le retour rend l onglet', (WidgetTester tester) async {
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

    for (final (bool sombre, bool arabe) in const <(bool, bool)>[
      (false, true),
      (true, false),
    ]) {
      testWidgets('390 et 1440, ${arabe ? 'arabe' : 'francais'}, '
          '${sombre ? 'sombre' : 'clair'} : un seul bouton plein', (
        WidgetTester tester,
      ) async {
        for (final Size taille in const <Size>[
          Size(390, 844),
          Size(1440, 900),
        ]) {
          await monterAdministration(
            tester,
            taille: taille,
            arabe: arabe,
            luminosite: sombre ? Brightness.dark : Brightness.light,
          );
          await taper(
            tester,
            find.byKey(AdministrationCommunicationsPage.cleNouvelle),
          );
          await taper(
            tester,
            find.byKey(PublieurAnnonce.clePublic(CodesPublics.tous)),
          );
          verifierUnSeulBoutonPlein(tester);
          expect(tester.takeException(), isNull);
          await demonter(tester);
        }
      });
    }
  });
}
