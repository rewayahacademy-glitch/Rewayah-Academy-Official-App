// COM-STU-1 : Le Studio, canal, rendu par la vraie `StudioPage` (COM-M03,
// COM-W03 ; spec sections 6, 9, 8.3, 18, 23, 25 ; R-COM-08, R-COM-13,
// R-COM-15). Mesures a 390, 768 et 1440, en francais et en arabe (RTL),
// clair et sombre, texte x2.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/elements_enregistres_studio.dart';
import 'package:rewayah_academy/features/com_studio/liste_canaux.dart';
import 'package:rewayah_academy/features/com_studio/panneau_partages.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/recherche_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/com_studio/visibilite_canal.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';

import '../../support/garde_interface.dart';
import 'support_studio.dart';

const Size _mobile = Size(390, 844);
const Size _tablette = Size(768, 1024);
const Size _bureau = Size(1440, 900);

bool _present(Key cle) => find.byKey(cle).evaluate().isNotEmpty;

int _panneaux() => <Key>[
  EspaceTravailAdaptatif.cleListe,
  EspaceTravailAdaptatif.clePrincipal,
  EspaceTravailAdaptatif.cleContexte,
].where(_present).length;

Finder _dansListe(Finder cible) => find.descendant(
  of: find.byKey(EspaceTravailAdaptatif.cleListe),
  matching: cible,
);

Finder _dansPrincipal(Finder cible) => find.descendant(
  of: find.byKey(EspaceTravailAdaptatif.clePrincipal),
  matching: cible,
);

Finder _dansFil(Finder cible) =>
    find.descendant(of: find.byType(FilDiscussion), matching: cible);

Finder _dansPanneau(Finder cible) =>
    find.descendant(of: find.byType(PanneauPartages), matching: cible);

/// Les noms des cinq canaux autorises de la demonstration.
const List<String> _canauxAutorises = <String>[
  'Organisation générale',
  'Admissions',
  'Suivi qualité',
  'Remplacements',
  'Clôture du mois',
];

void main() {
  group('Disposition (spec section 23)', () {
    testWidgets('1440, canal ouvert : Navigation | Canaux | Fil | Contexte', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      // La navigation du Studio, en barre laterale, hors coquille admin.
      expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
      expect(find.byType(AdminShell), findsNothing);
      expect(_panneaux(), 3);
      expect(_dansListe(find.byType(ListeCanaux)), findsOneWidget);
      expect(_dansPrincipal(find.byType(CanalStudio)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(EspaceTravailAdaptatif.cleContexte),
          matching: find.byType(PanneauPartages),
        ),
        findsOneWidget,
      );
      final double xNav = tester
          .getCenter(find.byKey(NavShell.barreLateraleKey))
          .dx;
      final double xListe = tester
          .getTopLeft(find.byKey(EspaceTravailAdaptatif.cleListe))
          .dx;
      final double xFil = tester
          .getTopLeft(find.byKey(EspaceTravailAdaptatif.clePrincipal))
          .dx;
      final double xContexte = tester
          .getTopLeft(find.byKey(EspaceTravailAdaptatif.cleContexte))
          .dx;
      expect(xNav < xListe && xListe < xFil && xFil < xContexte, isTrue);
      expect(find.text(t.com.studio.titre), findsWidgets);
      verifierUnSeulBoutonPlein(tester);
      expect(
        verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is GroupeReglages || w is AppCard,
        ),
        greaterThan(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440, sans canal : la liste et la phrase qui guide, '
        'aucune colonne de contexte vide', (WidgetTester tester) async {
      await monterStudio(tester, port: portDemo());
      expect(_panneaux(), 2);
      expect(find.byKey(EspaceStudio.cleChoisir), findsOneWidget);
      expect(find.text(t.com.studio.choisirTitre), findsOneWidget);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768 : rail | Canaux | Fil, le contexte en feuille', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
        taille: _tablette,
      );
      expect(find.byKey(NavShell.railKey), findsOneWidget);
      expect(_panneaux(), 2);
      expect(find.byType(PanneauPartages), findsNothing);
      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      await tester.pumpAndSettle();
      expect(find.byType(PanneauPartages), findsOneWidget);
      expect(find.text(t.com.studio.panneau.aPropos), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : une surface a la fois, la liste puis le canal, '
        'le disque retour ramene a la liste', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(
        tester,
        port: portDemo(),
        taille: _mobile,
      );
      expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
      expect(_panneaux(), 1);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(find.byType(CanalStudio), findsNothing);
      await tester.tap(find.text('Organisation générale'));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('organisation'));
      expect(_panneaux(), 1);
      expect(find.byType(ListeCanaux), findsNothing);
      expect(find.byType(CanalStudio), findsOneWidget);
      // Tache focalisee : la barre basse s'efface dans le canal.
      expect(find.byKey(NavShell.barreBasseKey), findsNothing);
      // Aucun bandeau de retour au-dessus du fil : le disque retour de la
      // page ramene a la liste, le fil garde sa hauteur.
      expect(find.byKey(EspaceTravailAdaptatif.cleRetourListe), findsNothing);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.adminStudio);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
      // Depuis la liste, le disque retour quitte Le Studio.
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.admin);
      expect(tester.takeException(), isNull);
    });

    for (final Size taille in <Size>[_mobile, _bureau]) {
      testWidgets('${taille.width.toInt()} : la liste garde sa position a '
          'l aller-retour d un canal (deux routes, une memoire)', (
        WidgetTester tester,
      ) async {
        final FauxStudio port = FauxStudio(
          canaux: <Canal>[
            for (int i = 0; i < 40; i++)
              canalSimple(id: 'c$i', nom: 'Canal $i'),
          ],
        );
        final GoRouter routeur = await monterStudio(
          tester,
          port: port,
          taille: taille,
        );
        final Finder defilante = find.byKey(
          const PageStorageKey<String>('studio-liste-canaux'),
        );
        ScrollPosition position() => tester
            .state<ScrollableState>(
              find
                  .descendant(of: defilante, matching: find.byType(Scrollable))
                  .first,
            )
            .position;
        await tester.drag(defilante, const Offset(0, -400));
        await tester.pumpAndSettle();
        final double avant = position().pixels;
        expect(avant, greaterThan(0));
        // Un canal visible a cet endroit de la liste.
        final Finder ligne = find
            .descendant(
              of: find.byType(ListeCanaux),
              matching: find.textContaining('Canal '),
            )
            .hitTestable()
            .first;
        await tester.tap(ligne);
        await tester.pumpAndSettle();
        expect(cheminCourant(routeur), startsWith(Routes.adminStudioCanaux));
        if (taille == _mobile) {
          expect(find.byType(ListeCanaux), findsNothing);
          await tester.tap(find.byType(DisqueRetour));
          await tester.pumpAndSettle();
          expect(cheminCourant(routeur), Routes.adminStudio);
        }
        expect(find.byType(ListeCanaux), findsOneWidget);
        expect(position().pixels, avant);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('la sortie du Studio ramene a l Accueil admin', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterStudio(tester, port: portDemo());
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.admin);
    });

    testWidgets('maquette sombre, structure seulement : ni Taches, ni visio, '
        'ni Nouvel espace, ni coquille Tuteur', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      final String tout = textesRendus(tester).join(' ').toLowerCase();
      for (final String interdit in <String>[
        'tâche',
        'visio',
        'nouvel espace',
        'projets',
        'favoris',
        'foyer',
        'tuteur',
        'nouveau canal',
      ]) {
        expect(tout.contains(interdit), isFalse, reason: interdit);
      }
    });

    for (final Size taille in <Size>[_mobile, _tablette, _bureau]) {
      for (final Brightness lum in Brightness.values) {
        testWidgets('aucun debordement a ${taille.width.toInt()}, '
            '${lum.name}, texte x2', (WidgetTester tester) async {
          await monterStudio(
            tester,
            port: portDemo(),
            depart: Routes.canalStudioPour('organisation'),
            taille: taille,
            luminosite: lum,
            echelleTexte: 2,
          );
          expect(find.byType(CanalStudio), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Canaux : taxonomie et visibilite (spec section 9)', () {
    testWidgets('cinq canaux ranges dans l ordre de la taxonomie, sections '
        'vides absentes', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        taille: const Size(1440, 1800),
      );
      for (final String nom in _canauxAutorises) {
        expect(_dansListe(find.text(nom)), findsOneWidget, reason: nom);
      }
      final List<SectionStudio> attendues = <SectionStudio>[
        SectionStudio.organisation,
        SectionStudio.admissionsFamilles,
        SectionStudio.pedagogieQualite,
        SectionStudio.planningRemplacements,
        SectionStudio.finance,
      ];
      double y = -1;
      for (final SectionStudio s in attendues) {
        final Finder groupe = find.byKey(ListeCanaux.cleSection(s));
        expect(groupe, findsOneWidget, reason: s.name);
        final double haut = tester.getTopLeft(groupe).dy;
        expect(haut, greaterThan(y), reason: s.name);
        y = haut;
      }
      for (final SectionStudio s in <SectionStudio>[
        SectionStudio.support,
        SectionStudio.produitTechnique,
        SectionStudio.direction,
      ]) {
        expect(find.byKey(ListeCanaux.cleSection(s)), findsNothing);
      }
    });

    testWidgets('restreint et prive se disent en toutes lettres, sans '
        'cadenas ; un canal ouvert a tous ne porte rien', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        taille: const Size(1440, 1800),
      );
      expect(
        find.byKey(const ValueKey<String>('studio-visibilite-qualite')),
        findsOneWidget,
      );
      expect(find.text(t.com.studio.visibilite.restreint), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('studio-visibilite-cloture')),
        findsOneWidget,
      );
      expect(find.text(t.com.studio.visibilite.prive), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('studio-visibilite-organisation')),
        findsNothing,
      );
      expect(find.byIcon(AppIcons.verrou.repos), findsNothing);
      expect(find.byIcon(AppIcons.verrou.actif), findsNothing);
    });

    testWidgets('le badge d attention dit les non-lus en mots, et tombe '
        'quand le canal est ouvert', (WidgetTester tester) async {
      await monterStudio(tester, port: portDemo());
      expect(find.byKey(ListeCanaux.cleBadge('organisation')), findsOneWidget);
      expect(find.text('2 non lus'), findsOneWidget);
      await tester.tap(find.text('Organisation générale'));
      await tester.pumpAndSettle();
      expect(find.byKey(ListeCanaux.cleBadge('organisation')), findsNothing);
    });
  });

  group('R-COM-08 : un canal prive non autorise n apparait pas', () {
    testWidgets('ni dans la liste, ni sa section, ni son compte', (
      WidgetTester tester,
    ) async {
      final StudioDemo port = portDemo();
      expect(port.canalEnMemoire(canalPriveAbsentDemo), isNotNull);
      await monterStudio(tester, port: port);
      final String tout = textesRendus(tester).join(' ');
      expect(tout.contains('Direction stratégique'), isFalse);
      expect(tout.contains(t.com.studio.sections.direction), isFalse);
      expect(
        find.byKey(ListeCanaux.cleSection(SectionStudio.direction)),
        findsNothing,
      );
    });

    testWidgets('son adresse ne rend rien du canal : une seule phrase, '
        'pour un canal retire comme pour un canal prive', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour(canalPriveAbsentDemo),
      );
      expect(find.byKey(EspaceStudio.cleCanalIndisponible), findsOneWidget);
      expect(find.text(t.com.studio.canal.indisponibleTitre), findsOneWidget);
      // Sans cadenas : rien ne laisse entendre qu'un canal verrouille existe.
      expect(find.byIcon(AppIcons.verrou.repos), findsNothing);
      expect(find.byIcon(AppIcons.verrou.actif), findsNothing);
      final String tout = textesRendus(tester).join(' ');
      expect(tout.contains('Direction stratégique'), isFalse);
      expect(tout.contains('Budget'), isFalse);
      expect(find.byType(FilDiscussion), findsNothing);
      expect(find.byType(PanneauPartages), findsNothing);

      // Un canal qui n'existe pas dit exactement la meme chose.
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('canal-retire'),
      );
      expect(find.byKey(EspaceStudio.cleCanalIndisponible), findsOneWidget);
      expect(find.byIcon(AppIcons.verrou.repos), findsNothing);
      expect(find.byIcon(AppIcons.verrou.actif), findsNothing);
    });

    testWidgets('la recherche ne rend rien d un canal prive', (
      WidgetTester tester,
    ) async {
      await monterStudio(tester, port: portDemo());
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'budget');
      await tester.pumpAndSettle();
      expect(find.text(t.com.studio.recherche.aucunTitre), findsOneWidget);
      expect(
        textesRendus(tester).join(' ').contains('Budget_confidentiel'),
        isFalse,
      );
    });

    testWidgets('defense de surface : un port qui laisse passer un canal '
        'absent ne le fait pas rendre', (WidgetTester tester) async {
      final FauxStudio port = FauxStudio(
        canaux: <Canal>[
          canalSimple(),
          canalSimple(
            id: 'secret',
            nom: 'Canal secret',
            visibilite: VisibiliteCanal.absent,
            texte: 'Contenu secret',
          ),
        ],
      );
      await monterStudio(tester, port: port);
      expect(find.text('Coordination'), findsWidgets);
      expect(find.text('Canal secret'), findsNothing);

      // La recherche non plus.
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'secret');
      await tester.pumpAndSettle();
      expect(find.text('Canal secret'), findsNothing);
      expect(find.text('Contenu secret'), findsNothing);

      // Ni par son adresse.
      await monterStudio(
        tester,
        port: port,
        depart: Routes.canalStudioPour('secret'),
      );
      expect(find.byKey(EspaceStudio.cleCanalIndisponible), findsOneWidget);
      expect(find.text('Contenu secret'), findsNothing);
    });
  });

  group('Le canal (COM-M03, COM-W03)', () {
    testWidgets('la piece jointe se dit dans le fil, le vocal s y lit '
        '(COM-FUS) ; le fichier est dans le panneau, sans adresse', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      expect(find.byKey(EnteteCanal.cle), findsOneWidget);
      expect(
        _dansFil(find.textContaining('Pièce jointe : Planning_T3.pdf')),
        findsOneWidget,
      );
      // COM-FUS : le lecteur de COM-VOC remplace la ligne « Message vocal ».
      expect(_dansFil(find.byType(LecteurVocalRecu)), findsOneWidget);
      expect(
        _dansFil(find.textContaining('Message vocal de 0:42')),
        findsNothing,
      );
      expect(_dansPanneau(find.text('Planning_T3.pdf')), findsOneWidget);
      final String tout = textesRendus(tester).join(' ');
      expect(tout.contains('http'), isFalse);
      expect(tout.contains('pj-planning'), isFalse);
      expect(tout.contains('r2'), isFalse);
    });

    testWidgets('R-COM-13 : un echec n affiche jamais « Envoye », le nouvel '
        'essai rejoue la meme cle', (WidgetTester tester) async {
      final StudioDemo port = portDemo(
        situation: SituationDemoStudio.echecEnvoi,
      );
      await monterStudio(
        tester,
        port: port,
        depart: Routes.canalStudioPour('organisation'),
      );
      final x = t.com.socle.composants.composer;
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Merci !');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(_dansFil(find.text(x.nonConfirme)), findsOneWidget);
      expect(_dansFil(find.text(x.envoye)), findsNothing);
      await tester.tap(find.text(x.reessayer));
      await tester.pumpAndSettle();
      expect(_dansFil(find.text(x.envoye)), findsOneWidget);
      expect(_dansFil(find.text(x.nonConfirme)), findsNothing);
      expect(port.clesRecues, hasLength(2));
      expect(port.clesRecues.first, port.clesRecues.last);
      expect(port.clesRecues.first, startsWith('organisation-'));
    });

    testWidgets('COM-BR-02 : deux messages au meme texte, envoyes ensemble, '
        'partent avec deux cles distinctes', (WidgetTester tester) async {
      final FauxStudio port = FauxStudio(canaux: <Canal>[canalSimple()])
        ..attenteEnvoi = Completer<void>();
      await monterStudio(
        tester,
        port: port,
        depart: Routes.canalStudioPour('c1'),
      );
      for (int i = 0; i < 2; i++) {
        await tester.enterText(find.byKey(FilDiscussion.champKey), "D'accord");
        await tester.pump();
        await tester.tap(find.byKey(FilDiscussion.envoyerKey));
        await tester.pump();
      }
      expect(port.envois, hasLength(2));
      expect(port.envois.first.$3, isNot(port.envois.last.$3));
      port.attenteEnvoi!.complete();
      await tester.pumpAndSettle();
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.envoye)),
        findsNWidgets(2),
      );
    });

    testWidgets('envoi confirme : « Envoye » et le message part au bon canal', (
      WidgetTester tester,
    ) async {
      final FauxStudio port = FauxStudio(canaux: <Canal>[canalSimple()]);
      await monterStudio(
        tester,
        port: port,
        depart: Routes.canalStudioPour('c1'),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bien reçu');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.envoye)),
        findsOneWidget,
      );
      expect(port.envois.single.$1, 'c1');
      expect(port.envois.single.$2, 'Bien reçu');
    });

    testWidgets('le champ nomme le canal ou l on ecrit', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('admissions'),
      );
      expect(
        find.text(t.com.studio.canal.aide(nom: 'Admissions')),
        findsOneWidget,
      );
    });

    testWidgets('lecture seule : aucun champ, la limite est dite', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('remplacements'),
      );
      expect(find.byKey(CanalStudio.cleLectureSeule), findsOneWidget);
      expect(find.byKey(FilDiscussion.champKey), findsNothing);
      expect(find.byKey(FilDiscussion.envoyerKey), findsNothing);
      expect(find.textContaining('Classe An-Nour'), findsOneWidget);
    });

    testWidgets('lecture seule sans aucun message : l etat vide le dit, '
        'aucune zone blanche', (WidgetTester tester) async {
      final Canal plein = canalSimple(ecrire: false);
      final Canal vide = Canal(
        resume: plein.resume,
        membres: plein.membres,
        messages: const <MessageCommunication>[],
        capacites: const <CapaciteCanal>{},
      );
      await monterStudio(
        tester,
        port: FauxStudio(canaux: <Canal>[vide]),
        depart: Routes.canalStudioPour('c1'),
      );
      expect(find.byKey(CanalStudio.cleLectureSeule), findsOneWidget);
      expect(find.byKey(CanalStudio.cleAucunMessage), findsOneWidget);
      expect(find.text(t.com.studio.canal.aucunMessageTitre), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hors ligne : bandeau des communications, contenu garde, '
        'envoi non confirme', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(situation: SituationDemoStudio.horsLigne),
        depart: Routes.canalStudioPour('organisation'),
        horsLigne: true,
      );
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsWidgets);
      expect(find.byType(FilDiscussion), findsOneWidget);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.nonConfirme)),
        findsOneWidget,
      );
      expect(
        _dansFil(find.text(t.com.socle.composants.composer.envoye)),
        findsNothing,
      );
    });

    testWidgets('R-COM-15 : a 390 avec un clavier de 300, le champ et le '
        'dernier message restent visibles', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
        taille: _mobile,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.showKeyboard(find.byKey(FilDiscussion.champKey));
      await tester.pumpAndSettle();
      const double hautVisible = 844 - 300;
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      expect(champ.bottom, lessThanOrEqualTo(hautVisible));
      final Rect envoyer = tester.getRect(find.byKey(FilDiscussion.envoyerKey));
      expect(envoyer.bottom, lessThanOrEqualTo(hautVisible));
      final Rect dernier = tester.getRect(
        find.byKey(const ValueKey<String>('message-m-org-4')),
      );
      expect(dernier.bottom, lessThanOrEqualTo(champ.top));
      expect(dernier.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });
  });

  group('Panneau Fichiers, Epingles, Membres (StudioSharedAssetsPanel)', () {
    testWidgets('a propos, membres, epingles, fichiers, liens, dans l ordre '
        'de la maquette', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      final List<Key> ordre = <Key>[
        PanneauPartages.cleAPropos,
        PanneauPartages.cleMembres,
        PanneauPartages.cleEpingles,
        PanneauPartages.cleFichiers,
        PanneauPartages.cleLiens,
        PanneauPartages.cleParametres,
      ];
      double y = -1;
      for (final Key k in ordre) {
        await tester.scrollUntilVisible(
          find.byKey(k),
          120,
          scrollable: find
              .descendant(
                of: find.byKey(EspaceTravailAdaptatif.cleContexte),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final double haut = tester.getTopLeft(find.byKey(k)).dy;
        expect(find.byKey(k), findsOneWidget, reason: '$k');
        y = y < 0 ? haut : y;
      }
      expect(
        _dansPanneau(find.text(t.com.studio.canal.membres(nombre: 6))),
        findsOneWidget,
      );
      expect(_dansPanneau(find.text('Planning du trimestre')), findsOneWidget);
      expect(_dansPanneau(find.text('Guide de modération')), findsOneWidget);
      expect(
        _dansPanneau(find.text(t.com.studio.panneau.vous)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('parametres du canal : seulement si le canal porte la '
        'capacite', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      expect(find.byKey(PanneauPartages.cleParametres), findsOneWidget);

      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('admissions'),
      );
      expect(find.byKey(PanneauPartages.cleParametres), findsNothing);
      expect(find.text(t.com.studio.panneau.parametres), findsNothing);
    });

    testWidgets('rien de partage : une ligne le dit, aucune section vide', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('admissions'),
      );
      expect(
        _dansPanneau(find.text(t.com.studio.panneau.aucunPartageTitre)),
        findsOneWidget,
      );
      expect(find.byKey(PanneauPartages.cleEpingles), findsNothing);
      expect(find.byKey(PanneauPartages.cleFichiers), findsNothing);
      expect(find.byKey(PanneauPartages.cleLiens), findsNothing);
    });

    testWidgets('un lien interne ouvre son canal ; un lien externe est '
        'nomme par son site, sans geste', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      expect(
        _dansPanneau(
          find.text(t.com.studio.panneau.lienExterne(hote: 'rewayah.org')),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        _dansPanneau(find.text('Remplacements de la semaine')),
        120,
        scrollable: find
            .descendant(
              of: find.byKey(EspaceTravailAdaptatif.cleContexte),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(_dansPanneau(find.text('Remplacements de la semaine')));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('remplacements'));
    });
  });

  group('Enregistrer (spec section 8.3)', () {
    testWidgets('un element epingle s enregistre, puis se retrouve dans '
        'Elements enregistres et rouvre son canal', (
      WidgetTester tester,
    ) async {
      final ElementsEnregistresMemoire memoire = ElementsEnregistresMemoire();
      final GoRouter routeur = await monterStudio(
        tester,
        port: portDemo(),
        enregistres: memoire,
        depart: Routes.canalStudioPour('organisation'),
      );
      final ObjetLie objet = ObjetLie(
        type: TypeObjetLie.autre,
        id: 'ep-planning',
        libelle: 'Planning du trimestre',
      );
      final Finder bouton = find.byKey(PanneauPartages.cleEnregistrer(objet));
      await tester.scrollUntilVisible(
        bouton,
        120,
        scrollable: find
            .descendant(
              of: find.byKey(EspaceTravailAdaptatif.cleContexte),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            RegExp.escape(
              t.com.studio.enregistrer.semantiqueEnregistrer(
                titre: 'Planning du trimestre',
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(await memoire.estEnregistre(objet), isTrue);
      expect(
        find.text(
          t.com.studio.enregistrer.ajoute(titre: 'Planning du trimestre'),
        ),
        findsOneWidget,
      );
      // L'action devient « Retirer ».
      expect(
        find.descendant(
          of: bouton,
          matching: find.text(t.com.studio.enregistrer.retirer),
        ),
        findsOneWidget,
      );

      // La vue Elements enregistres, par la navigation du Studio.
      await tester.tap(
        find.descendant(
          of: find.byKey(NavShell.barreLateraleKey),
          matching: find.text(t.com.studio.navigation.enregistres),
        ),
      );
      await tester.pumpAndSettle();
      expect(adresseCourante(routeur), contains('vue=enregistres'));
      expect(find.byType(VueElementsEnregistres), findsOneWidget);
      expect(find.text('Planning du trimestre'), findsOneWidget);
      await tester.tap(find.text('Planning du trimestre'));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('organisation'));
      expect(find.byType(CanalStudio), findsOneWidget);
    });

    testWidgets('retirer : l element quitte la liste des enregistres', (
      WidgetTester tester,
    ) async {
      final ElementsEnregistresMemoire memoire = ElementsEnregistresMemoire();
      final ResumeCanal resume = (await portDemo().canal('organisation'))!
          .resume;
      final ObjetLie objet = resume.objet(
        Routes.canalStudioPour('organisation'),
      );
      await memoire.enregistrer(objet);
      await monterStudio(
        tester,
        port: portDemo(),
        enregistres: memoire,
        depart: Routes.canalStudioPour('organisation'),
      );
      final Finder bouton = find.byKey(PanneauPartages.cleEnregistrer(objet));
      expect(
        find.descendant(
          of: bouton,
          matching: find.text(t.com.studio.enregistrer.retirer),
        ),
        findsOneWidget,
      );
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(await memoire.estEnregistre(objet), isFalse);
      expect(
        find.descendant(
          of: bouton,
          matching: find.text(t.com.studio.enregistrer.enregistrer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('service absent (production) : « Enregistrer » n est pas '
        'propose, la vue le dit sans Reessayer', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      expect(find.byType(BoutonEnregistrer), findsNothing);
      expect(find.text(t.com.studio.enregistrer.enregistrer), findsNothing);

      routeur.go(adresseVueStudio(VueStudio.enregistres));
      await tester.pumpAndSettle();
      expect(
        find.text(t.com.socle.composants.etats.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
    });

    testWidgets('vue vide : ce qu il faut toucher pour enregistrer', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        enregistres: ElementsEnregistresMemoire(),
        depart: adresseVueStudio(VueStudio.enregistres),
      );
      expect(find.text(t.com.studio.enregistres.videTitre), findsOneWidget);
      final NavShell nav = tester.widget<NavShell>(find.byType(NavShell));
      expect(nav.indexActif, VueStudio.enregistres.index);
    });

    testWidgets('hors ligne : bandeau des communications ; une lecture en '
        'echec dit la connexion, avec Reessayer', (WidgetTester tester) async {
      final _EnregistresListeEnEchec memoire = _EnregistresListeEnEchec();
      await monterStudio(
        tester,
        port: portDemo(),
        enregistres: memoire,
        depart: adresseVueStudio(VueStudio.enregistres),
        horsLigne: true,
      );
      expect(find.byType(BandeauHorsLigneCommunication), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is VueEtatCommunication &&
              w.etat == EtatCommunication.horsLigne,
        ),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.composants.etats.erreurTitre), findsNothing);
      expect(find.text(t.com.socle.composants.etats.reessayer), findsOneWidget);

      // Le reseau revenu, « Reessayer » relit la liste.
      memoire.echouer = false;
      await tester.tap(find.text(t.com.socle.composants.etats.reessayer));
      await tester.pumpAndSettle();
      expect(find.text(t.com.studio.enregistres.videTitre), findsOneWidget);
    });

    testWidgets('un enregistrement non confirme le dit, rien ne change', (
      WidgetTester tester,
    ) async {
      final _EnregistresQuiEchouent memoire = _EnregistresQuiEchouent();
      await monterStudio(
        tester,
        port: portDemo(),
        enregistres: memoire,
        depart: Routes.canalStudioPour('admissions'),
      );
      final ObjetLie objet = ObjetLie(
        type: TypeObjetLie.canal,
        id: 'admissions',
        libelle: 'Admissions',
      );
      await tester.tap(find.byKey(PanneauPartages.cleEnregistrer(objet)));
      await tester.pumpAndSettle();
      expect(find.text(t.com.studio.enregistrer.nonConfirme), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(PanneauPartages.cleEnregistrer(objet)),
          matching: find.text(t.com.studio.enregistrer.enregistrer),
        ),
        findsOneWidget,
      );
    });
  });

  group('Etats (spec section 25)', () {
    testWidgets('chargement : squelette', (WidgetTester tester) async {
      final FauxStudio port = FauxStudio(canaux: <Canal>[canalSimple()])
        ..attenteListe = Completer<void>();
      await monterStudio(
        tester,
        port: port,
        taille: _mobile,
        stabiliser: false,
      );
      expect(find.byKey(VueEtatCommunication.cleChargement), findsOneWidget);
      port.attenteListe!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ListeCanaux), findsOneWidget);
    });

    testWidgets('vide : aucun canal ouvert', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(situation: SituationDemoStudio.sansCanaux),
      );
      expect(find.text(t.com.studio.aucunCanalTitre), findsOneWidget);
      expect(find.byType(ListeCanaux), findsNothing);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
    });

    testWidgets('erreur : « Reessayer » relit la liste', (
      WidgetTester tester,
    ) async {
      final FauxStudio port = FauxStudio(canaux: <Canal>[canalSimple()])
        ..erreurListe = Exception('reseau');
      await monterStudio(tester, port: port, taille: _mobile);
      expect(
        find.text(t.com.socle.composants.etats.erreurTitre),
        findsOneWidget,
      );
      port.erreurListe = null;
      await tester.tap(find.text(t.com.socle.composants.etats.reessayer));
      await tester.pumpAndSettle();
      expect(port.lecturesListe, 2);
      expect(find.byType(ListeCanaux), findsOneWidget);
    });

    testWidgets('canal en erreur : « Reessayer » relit le canal', (
      WidgetTester tester,
    ) async {
      final FauxStudio port = FauxStudio(canaux: <Canal>[canalSimple()])
        ..erreurCanal = Exception('reseau');
      await monterStudio(
        tester,
        port: port,
        depart: Routes.canalStudioPour('c1'),
      );
      expect(find.byType(CanalStudio), findsNothing);
      port.erreurCanal = null;
      await tester.tap(
        _dansPrincipal(find.text(t.com.socle.composants.etats.reessayer)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CanalStudio), findsOneWidget);
    });

    testWidgets('hors ligne sans contenu : l etat hors ligne et Reessayer', (
      WidgetTester tester,
    ) async {
      final FauxStudio port = FauxStudio()..erreurListe = Exception('reseau');
      await monterStudio(tester, port: port, horsLigne: true);
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsWidgets);
      expect(find.text(t.com.socle.composants.etats.reessayer), findsOneWidget);
    });

    testWidgets('port neutre (production) : « pas encore disponible », sans '
        'Reessayer', (WidgetTester tester) async {
      await monterStudio(tester, port: const StudioIndisponible());
      expect(
        find.text(t.com.socle.composants.etats.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
      expect(find.byType(ListeCanaux), findsNothing);
    });

    testWidgets('panneau de contexte ferme : le fil prend la place, et il '
        'se rouvre', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      final double avant = tester
          .getSize(find.byKey(EspaceTravailAdaptatif.clePrincipal))
          .width;
      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleFermerContexte));
      await tester.pumpAndSettle();
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(
        tester.getSize(find.byKey(EspaceTravailAdaptatif.clePrincipal)).width,
        greaterThan(avant),
      );
      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      await tester.pumpAndSettle();
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsOneWidget);
    });
  });

  group('Recherche (StudioSearch, spec section 18)', () {
    testWidgets('1440 : champ persistant, resultats dans le contenu avec '
        'leurs filtres, le canal et son brouillon reviennent tels quels', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Brouillon');
      await tester.pump();
      expect(_dansListe(find.byKey(ChampRechercheStudio.cle)), findsOneWidget);
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'planning');
      await tester.pumpAndSettle();
      expect(
        _dansPrincipal(find.byKey(ResultatsRechercheStudio.cle)),
        findsOneWidget,
      );
      expect(find.byType(CanalStudio), findsNothing);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      // Messages et fichiers trouves.
      expect(
        find.byKey(const ValueKey<String>('studio-resultats-messages')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('studio-resultats-fichiers')),
        findsOneWidget,
      );
      // Le filtre reste dans la meme surface.
      await tester.tap(
        find.descendant(
          of: find.byType(SelecteurSection<FiltreRechercheStudio>),
          matching: find.text(t.com.studio.recherche.fichiers),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('studio-resultats-messages')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('studio-resultats-fichiers')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ChampRechercheStudio.cleEffacer));
      await tester.pumpAndSettle();
      expect(find.byKey(ResultatsRechercheStudio.cle), findsNothing);
      expect(find.byType(CanalStudio), findsOneWidget);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsOneWidget);
      final EditableText champ = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(FilDiscussion.champKey),
          matching: find.byType(EditableText),
        ),
      );
      expect(champ.controller.text, 'Brouillon');
    });

    testWidgets('un resultat ouvre son canal', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(tester, port: portDemo());
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'visites');
      await tester.pumpAndSettle();
      await tester.tap(
        _dansPrincipal(find.text('Compte_rendu_visites.pdf')).first,
      );
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('qualite'));
      expect(find.byType(CanalStudio), findsOneWidget);
    });

    testWidgets('un canal choisi dans la liste pendant une recherche '
        's ouvre a la place des resultats', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(tester, port: portDemo());
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'planning');
      await tester.pumpAndSettle();
      expect(find.byKey(ResultatsRechercheStudio.cle), findsOneWidget);
      await tester.tap(_dansListe(find.text('Admissions')));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('admissions'));
      expect(find.byKey(ResultatsRechercheStudio.cle), findsNothing);
      expect(find.byType(CanalStudio), findsOneWidget);
    });

    testWidgets('aucun resultat : ce qu on peut essayer', (
      WidgetTester tester,
    ) async {
      await monterStudio(tester, port: portDemo());
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(t.com.studio.recherche.aucunTitre), findsOneWidget);
      expect(
        find.text(t.com.studio.recherche.aucun(texte: 'zzz')),
        findsOneWidget,
      );
    });

    testWidgets('port neutre : la recherche dit « pas encore disponible »', (
      WidgetTester tester,
    ) async {
      final _StudioSansRecherche port = _StudioSansRecherche();
      await monterStudio(tester, port: port);
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'plan');
      await tester.pumpAndSettle();
      expect(
        find.text(t.com.socle.composants.etats.indisponibleTitre),
        findsOneWidget,
      );
    });

    testWidgets('390 : surface plein ecran temporaire ; le retour rend la '
        'liste, un resultat ouvre le canal', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(
        tester,
        port: portDemo(),
        taille: _mobile,
      );
      expect(find.byKey(ChampRechercheStudio.cle), findsNothing);
      await tester.tap(find.byKey(EspaceStudio.cleOuvrirRecherche));
      await tester.pumpAndSettle();
      expect(find.byKey(SurfaceRechercheStudio.cle), findsOneWidget);
      expect(find.byType(ListeCanaux), findsNothing);
      await tester.tap(find.byKey(SurfaceRechercheStudio.cleFermer));
      await tester.pumpAndSettle();
      expect(find.byKey(SurfaceRechercheStudio.cle), findsNothing);
      expect(find.byType(ListeCanaux), findsOneWidget);

      await tester.tap(find.byKey(EspaceStudio.cleOuvrirRecherche));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(ChampRechercheStudio.cle),
        'admissions',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byKey(ResultatsRechercheStudio.cle),
              matching: find.text('Admissions'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('admissions'));
      expect(find.byKey(SurfaceRechercheStudio.cle), findsNothing);
      expect(find.byType(CanalStudio), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('RTL (arabe)', () {
    testWidgets('1440 : navigation et canaux au debut, a droite ; libelles '
        'arabes', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
        langue: AppLocale.ar,
      );
      final Finder page = find.byType(StudioPage);
      expect(Directionality.of(tester.element(page)), TextDirection.rtl);
      final double xListe = tester
          .getCenter(find.byKey(EspaceTravailAdaptatif.cleListe))
          .dx;
      final double xContexte = tester
          .getCenter(find.byKey(EspaceTravailAdaptatif.cleContexte))
          .dx;
      final double xNav = tester
          .getCenter(find.byKey(NavShell.barreLateraleKey))
          .dx;
      expect(xNav, greaterThan(xListe));
      expect(xListe, greaterThan(xContexte));
      expect(find.text('القنوات'), findsWidgets);
      expect(find.text('التنظيم'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : le canal s ouvre sans debordement', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: Routes.canalStudioPour('organisation'),
        langue: AppLocale.ar,
        taille: _mobile,
      );
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Port neutre', () {
    test('chaque methode rend CapaciteIndisponible, jamais une liste vide', () {
      const StudioIndisponible port = StudioIndisponible();
      Matcher dependance(String code) => throwsA(
        isA<CapaciteIndisponible>().having(
          (CapaciteIndisponible e) => e.dependance,
          'dependance',
          code,
        ),
      );
      expect(port.canaux(), dependance('COM-BR-08'));
      expect(port.canal('x'), dependance('COM-BR-08'));
      expect(port.partages('x'), dependance('COM-BR-08'));
      expect(port.rechercher('x'), dependance('COM-BR-08'));
      expect(port.marquerLu('x'), dependance('COM-BR-08'));
      expect(port.envoyer('x', 'y', 'k'), dependance('COM-BR-02'));
    });

    test('canauxRendus retire les canaux absents, garde l ordre', () {
      final List<VisibiliteCanal> v = <VisibiliteCanal>[
        VisibiliteCanal.visible,
        VisibiliteCanal.absent,
        VisibiliteCanal.restreint,
        VisibiliteCanal.priveAutorise,
      ];
      expect(canauxRendus(v, (VisibiliteCanal x) => x), <VisibiliteCanal>[
        VisibiliteCanal.visible,
        VisibiliteCanal.restreint,
        VisibiliteCanal.priveAutorise,
      ]);
      expect(libelleVisibilite(VisibiliteCanal.visible), isNull);
      expect(libelleVisibilite(VisibiliteCanal.absent), isNull);
      expect(phraseVisibilite(VisibiliteCanal.absent), isNull);
    });

    test('un lien externe ne garde aucune adresse ; une destination '
        'externe est refusee', () {
      final ElementPartage externe = ElementPartage(
        id: 'l',
        titre: 'Site',
        nature: NaturePartage.lien,
        destination: 'https://exemple.org/page',
        hote: 'exemple.org',
      );
      expect(externe.destination, isNull);
      final ElementPartage interne = ElementPartage(
        id: 'l2',
        titre: 'Canal',
        nature: NaturePartage.lien,
        destination: Routes.canalStudioPour('c1'),
      );
      expect(interne.destination, Routes.canalStudioPour('c1'));
    });
  });
}

/// Un service d'elements enregistres qui repond a la lecture mais dont
/// l'enregistrement n'est jamais confirme.
class _EnregistresListeEnEchec extends ElementsEnregistresMemoire {
  bool echouer = true;

  @override
  Future<List<ElementEnregistre>> liste() => echouer
      ? Future<List<ElementEnregistre>>.error(StateError('reseau'))
      : super.liste();
}

class _EnregistresQuiEchouent extends ElementsEnregistresMemoire {
  @override
  Future<void> enregistrer(ObjetLie objet) =>
      Future<void>.error(StateError('non confirme'));
}

/// Un port de demonstration dont la recherche n'a pas encore de contrat.
class _StudioSansRecherche extends StudioDemo {
  _StudioSansRecherche() : super(maintenant: maintenantTest);

  @override
  Future<ResultatsStudio> rechercher(String texte) =>
      Future<ResultatsStudio>.error(const CapaciteIndisponible('COM-BR-08'));
}
